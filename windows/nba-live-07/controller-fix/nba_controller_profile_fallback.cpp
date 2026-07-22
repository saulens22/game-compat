#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

namespace {
FILE* log_file;
CRITICAL_SECTION log_lock;

void log(const char* format, ...) {
    EnterCriticalSection(&log_lock);
    if (log_file) {
        va_list args;
        va_start(args, format);
        vfprintf(log_file, format, args);
        va_end(args);
        fputc('\n', log_file);
        fflush(log_file);
    }
    LeaveCriticalSection(&log_lock);
}

bool readable(const void* pointer, size_t size = 1) {
    MEMORY_BASIC_INFORMATION info = {};
    if (!pointer || !VirtualQuery(pointer, &info, sizeof(info))) return false;
    if (info.State != MEM_COMMIT || (info.Protect & (PAGE_NOACCESS | PAGE_GUARD))) return false;
    const uintptr_t begin = reinterpret_cast<uintptr_t>(pointer);
    const uintptr_t end = reinterpret_cast<uintptr_t>(info.BaseAddress) + info.RegionSize;
    return begin + size >= begin && begin + size <= end;
}

const char* safe_string(const char* value) {
    return readable(value) ? value : (value ? "<unreadable>" : "<null>");
}

struct Detour {
    uint8_t* target;
    uint8_t original[16];
    size_t length;
    void* trampoline;
};

bool install_detour(Detour* detour, uintptr_t target, void* replacement,
                    size_t length, const uint8_t* expected) {
    if (length < 5 || length > sizeof(detour->original)) return false;
    detour->target = reinterpret_cast<uint8_t*>(target);
    detour->length = length;
    if (!readable(detour->target, length) || memcmp(detour->target, expected, length) != 0) {
        log("REFUSE target=%08lx executable bytes differ",
            static_cast<unsigned long>(target));
        return false;
    }

    memcpy(detour->original, detour->target, length);
    uint8_t* trampoline = static_cast<uint8_t*>(VirtualAlloc(
        nullptr, length + 5, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!trampoline) return false;
    memcpy(trampoline, detour->target, length);
    trampoline[length] = 0xe9;
    *reinterpret_cast<int32_t*>(trampoline + length + 1) =
        static_cast<int32_t>((detour->target + length) - (trampoline + length + 5));

    DWORD old_protection;
    if (!VirtualProtect(detour->target, length, PAGE_EXECUTE_READWRITE, &old_protection)) {
        return false;
    }
    memset(detour->target, 0x90, length);
    detour->target[0] = 0xe9;
    *reinterpret_cast<int32_t*>(detour->target + 1) =
        static_cast<int32_t>(reinterpret_cast<uint8_t*>(replacement) - (detour->target + 5));
    FlushInstructionCache(GetCurrentProcess(), detour->target, length);
    DWORD ignored;
    VirtualProtect(detour->target, length, old_protection, &ignored);
    detour->trampoline = trampoline;
    return true;
}

typedef const char* (__attribute__((thiscall)) *LookupFn)(void*, unsigned, const char*);
typedef unsigned char (__attribute__((thiscall)) *LoadFn)(void*, unsigned, const char*);
typedef unsigned char (__attribute__((thiscall)) *BindFn)(void*, const char*, const char*);
LookupFn original_lookup;
LoadFn original_load;
BindFn original_bind;
Detour lookup_detour = {};
Detour load_detour = {};
Detour bind_detour = {};

const char fallback_profile[] = "XboxWiredGamepad.jfg";

void log_associations(const char* phase, void* slot_object) {
    if (!readable(slot_object, 0x3c)) {
        log("ASSOCIATIONS %s slot_object=%p unreadable", phase, slot_object);
        return;
    }
    const uint32_t count = *reinterpret_cast<uint32_t*>(
        static_cast<uint8_t*>(slot_object) + 0x38);
    const uint32_t address = *reinterpret_cast<uint32_t*>(
        static_cast<uint8_t*>(slot_object) + 0x34);
    uint32_t* associations = reinterpret_cast<uint32_t*>(address);
    log("ASSOCIATIONS %s slot_object=%p association_count=%lu", phase, slot_object,
        static_cast<unsigned long>(count));
    if (!count || count > 32 || !readable(associations, count * sizeof(*associations))) return;
    for (uint32_t index = 0; index < count; ++index) {
        uint8_t* association = reinterpret_cast<uint8_t*>(associations[index]);
        if (!readable(association, 8)) continue;
        const uint16_t capacity = *reinterpret_cast<uint16_t*>(association + 4);
        const uint16_t bindings = *reinterpret_cast<uint16_t*>(association + 6);
        log("ASSOCIATIONS %s index=%lu capacity=%u bindings=%u", phase,
            static_cast<unsigned long>(index), capacity, bindings);
    }
}

const char* __attribute__((thiscall)) hook_lookup(
    void* self, unsigned slot, const char* device_name) {
    const char* result = original_lookup(self, slot, device_name);
    if (result) {
        log("LOOKUP slot=%u device=\"%s\" native=\"%s\" action=preserve",
            slot, safe_string(device_name), safe_string(result));
        return result;
    }

    // NBA's observed controller slots begin at 3. Slots 0-2 are reserved for
    // keyboard/mouse paths and must retain the game's original null behavior.
    if (slot >= 3 && readable(device_name) && device_name[0] != '\0') {
        log("LOOKUP slot=%u device=\"%s\" native=<null> fallback=\"%s\"",
            slot, safe_string(device_name), fallback_profile);
        return fallback_profile;
    }

    log("LOOKUP slot=%u device=\"%s\" native=<null> action=preserve",
        slot, safe_string(device_name));
    return nullptr;
}

unsigned char __attribute__((thiscall)) hook_load(
    void* self, unsigned slot, const char* profile) {
    log("LOAD begin slot=%u profile=\"%s\"", slot, safe_string(profile));
    const unsigned char result = original_load(self, slot, profile);
    log("LOAD end slot=%u profile=\"%s\" result=%u", slot, safe_string(profile), result);
    return result;
}

unsigned char __attribute__((thiscall)) hook_bind(
    void* slot_object, const char* action, const char* physical_input) {
    const unsigned char result = original_bind(slot_object, action, physical_input);
    log("BIND action=\"%s\" physical=\"%s\" result=%u",
        safe_string(action), safe_string(physical_input), result);
    log_associations("after-bind", slot_object);
    return result;
}

DWORD WINAPI install_thread(void*) {
    char module_path[MAX_PATH] = {};
    GetModuleFileNameA(nullptr, module_path, MAX_PATH);
    char* slash = strrchr(module_path, '\\');
    if (slash) *slash = '\0';
    char log_path[MAX_PATH] = {};
    snprintf(log_path, sizeof(log_path),
             "%s\\plugins\\nba-controller-profile-fallback.log", module_path);
    log_file = fopen(log_path, "w");
    log("NBA controller profile fallback v2");

    const uintptr_t base = reinterpret_cast<uintptr_t>(GetModuleHandleA(nullptr));
    if (base != 0x00400000) {
        log("REFUSE unsupported image base=%08lx", static_cast<unsigned long>(base));
        return 1;
    }

    char profile_path[MAX_PATH] = {};
    snprintf(profile_path, sizeof(profile_path),
             "%s\\interface\\configs\\%s", module_path, fallback_profile);
    const DWORD attributes = GetFileAttributesA(profile_path);
    if (attributes == INVALID_FILE_ATTRIBUTES || (attributes & FILE_ATTRIBUTE_DIRECTORY)) {
        log("REFUSE bundled fallback profile is missing");
        return 2;
    }

    const uint8_t expected[] = {0x51, 0x8b, 0x44, 0x24, 0x0c};
    if (!install_detour(&lookup_detour, 0x006588d0,
                        reinterpret_cast<void*>(hook_lookup), 5, expected)) {
        return 3;
    }
    original_lookup = reinterpret_cast<LookupFn>(lookup_detour.trampoline);
    const uint8_t expected_load[] = {0x56, 0x57, 0x8b, 0x7c, 0x24, 0x10};
    if (!install_detour(&load_detour, 0x0065fc90,
                        reinterpret_cast<void*>(hook_load), 6, expected_load)) {
        return 4;
    }
    original_load = reinterpret_cast<LoadFn>(load_detour.trampoline);
    const uint8_t expected_bind[] = {0x83, 0xec, 0x08, 0x53, 0x55};
    if (!install_detour(&bind_detour, 0x00659670,
                        reinterpret_cast<void*>(hook_bind), 5, expected_bind)) {
        return 5;
    }
    original_bind = reinterpret_cast<BindFn>(bind_detour.trampoline);
    log("READY fallback, loader, and binder hooks installed profile=\"%s\"",
        fallback_profile);
    return 0;
}
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(instance);
        InitializeCriticalSection(&log_lock);
        HANDLE thread = CreateThread(nullptr, 0, install_thread, nullptr, 0, nullptr);
        if (thread) CloseHandle(thread);
    }
    return TRUE;
}
