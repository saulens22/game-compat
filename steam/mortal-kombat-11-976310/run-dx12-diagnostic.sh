#!/usr/bin/env bash
set -euo pipefail

APP_ID=976310
CASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$CASE_DIR/../../lib/steam-paths.sh"
STEAM_ROOT=$(resolve_steam_root)
GAME_DIR=${MK11_DIR:-"$STEAM_ROOT/steamapps/common/Mortal Kombat 11"}
EXE="$GAME_DIR/Binaries/Retail/MK11_DX12.exe"
PREFIX=${MK11_PREFIX:-"$STEAM_ROOT/steamapps/compatdata/$APP_ID"}

usage() {
    echo "Usage: $0 --proton PATH [--duration 10-300] [--startup-timeout SECONDS] [--warmup SECONDS] [--vkd3d-config VALUE] [--env NAME=VALUE] [--mangohud] [--label TEXT] [--yes|--no-stop]"
}

proton=''
duration=90
vkd3d_config=''
label='dx12'
use_mangohud=0
startup_timeout=180
warmup=300
extra_env=()
stop_game=1
assume_yes=0

while (($#)); do
    case "$1" in
        --proton) proton=${2:?}; shift 2 ;;
        --duration) duration=${2:?}; shift 2 ;;
        --startup-timeout) startup_timeout=${2:?}; shift 2 ;;
        --warmup) warmup=${2:?}; shift 2 ;;
        --vkd3d-config) vkd3d_config=${2:?}; shift 2 ;;
        --env) extra_env+=("${2:?}"); shift 2 ;;
        --mangohud) use_mangohud=1; shift ;;
        --label) label=${2:?}; shift 2 ;;
        --yes) assume_yes=1; shift ;;
        --no-stop) stop_game=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$proton" || ! -x "$proton/proton" ]]; then
    echo "--proton must name a compatibility-tool directory containing proton" >&2
    exit 2
fi
if [[ ! "$duration" =~ ^[0-9]+$ ]] || ((duration < 10 || duration > 300)); then
    echo "--duration must be an integer from 10 to 300 seconds" >&2
    exit 2
fi
if [[ ! "$startup_timeout" =~ ^[0-9]+$ ]] || ((startup_timeout < 30 || startup_timeout > 600)); then
    echo "--startup-timeout must be an integer from 30 to 600 seconds" >&2
    exit 2
fi
if [[ ! "$warmup" =~ ^[0-9]+$ ]] || ((warmup < 0 || warmup > 600)); then
    echo "--warmup must be an integer from 0 to 600 seconds" >&2
    exit 2
fi
for assignment in "${extra_env[@]}"; do
    if [[ ! "$assignment" =~ ^[A-Za-z_][A-Za-z0-9_]*=.*$ ]]; then
        echo "--env requires NAME=VALUE, got: $assignment" >&2
        exit 2
    fi
done
if [[ ! -f "$EXE" ]]; then
    echo "DX12 executable not found: $EXE" >&2
    exit 1
fi
mkdir -p "$PREFIX"
if pgrep -x 'MK11_DX12.exe' >/dev/null || pgrep -x 'MK11.exe' >/dev/null; then
    echo "MK11 is already running; refusing to mix runs" >&2
    exit 1
fi

if ((stop_game)); then
    echo "WARNING: this bounded diagnostic will terminate the MK11 process after $duration measured seconds."
    echo 'It may use SIGKILL only if the game ignores SIGTERM.'
    if ((assume_yes == 0)); then
        if [[ -t 0 ]]; then
            read -r -p 'Continue and allow the diagnostic to stop MK11? [y/N] ' answer
            [[ $answer == [yY] || $answer == [yY][eE][sS] ]] || { echo 'Cancelled.'; exit 0; }
        else
            echo 'Non-interactive use requires --yes, or use --no-stop to leave the game running.' >&2
            exit 2
        fi
    fi
else
    echo 'NOTICE: --no-stop selected; the diagnostic will leave MK11 and its Proton launcher running.'
fi

timestamp=$(date '+%Y%m%d-%H%M%S')
safe_label=${label//[^a-zA-Z0-9._-]/_}
run_dir="$CASE_DIR/logs/runs/$timestamp-$safe_label"
mkdir -p "$run_dir"
if ((use_mangohud)); then
    mkdir -p "$run_dir/mangohud"
fi

version=$(tr '\n' ' ' < "$proton/version" 2>/dev/null || basename "$proton")
steam_line="PROTON_LOG=1 PROTON_LOG_DIR=$run_dir VKD3D_DEBUG=info"
if [[ -n "$vkd3d_config" ]]; then
    steam_line+=" VKD3D_CONFIG=$vkd3d_config"
fi
for assignment in "${extra_env[@]}"; do
    steam_line+=" $assignment"
done
if ((use_mangohud)); then
    log_duration=$((duration > 15 ? duration - 10 : duration))
    mangohud_config="gpu_stats,gpu_temp,gpu_core_clock,gpu_power,cpu_stats,ram,vram,fps,frametime,frame_timing,engine_version,vulkan_driver,present_mode,display_server,refresh_rate,log_duration=$log_duration,output_folder=$run_dir/mangohud"
    steam_line+=" MANGOHUD=1 MANGOHUD_CONFIG=\"$mangohud_config\""
fi
steam_line+=' %command%'

{
    echo "timestamp_start=$(date --iso-8601=seconds)"
    echo "duration_requested=$duration"
    echo "startup_timeout=$startup_timeout"
    echo "post_swapchain_warmup=$warmup"
    echo "renderer=DX12"
    echo "executable=$EXE"
    echo "proton_path=$proton"
    echo "proton_version=$version"
    echo "prefix=$PREFIX"
    echo "vkd3d_config=$vkd3d_config"
    printf 'extra_env=%s\n' "${extra_env[*]}"
    echo "mangohud=$use_mangohud"
    echo "steam_launch_options=$steam_line"
} > "$run_dir/metadata.txt"

echo "Run directory: $run_dir"
echo "Complete equivalent Steam launch-options line:"
echo "$steam_line"

env_args=(
    "STEAM_COMPAT_CLIENT_INSTALL_PATH=$STEAM_ROOT"
    "STEAM_COMPAT_DATA_PATH=$PREFIX"
    "SteamAppId=$APP_ID"
    "SteamGameId=$APP_ID"
    'PROTON_LOG=1'
    "PROTON_LOG_DIR=$run_dir"
    'VKD3D_DEBUG=info'
)
if [[ -n "$vkd3d_config" ]]; then
    env_args+=("VKD3D_CONFIG=$vkd3d_config")
fi
env_args+=("${extra_env[@]}")
if ((use_mangohud)); then
    env_args+=('MANGOHUD=1' "MANGOHUD_CONFIG=$mangohud_config")
fi

env "${env_args[@]}" "$proton/proton" waitforexitandrun "$EXE" \
    >"$run_dir/launcher.stdout.log" 2>"$run_dir/launcher.stderr.log" &
launcher_pid=$!

cleanup() {
    if ((stop_game)) && kill -0 "$launcher_pid" 2>/dev/null; then
        kill -TERM "$launcher_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

game_pid=''
for _ in $(seq 1 30); do
    game_pid=$(pgrep -n -x 'MK11_DX12.exe' || true)
    [[ -n "$game_pid" ]] && break
    kill -0 "$launcher_pid" 2>/dev/null || break
    sleep 1
done

if [[ -z "$game_pid" ]]; then
    echo "MK11_DX12.exe did not appear" | tee -a "$run_dir/result.txt"
    wait "$launcher_pid" || true
    echo "timestamp_end=$(date --iso-8601=seconds)" >> "$run_dir/metadata.txt"
    exit 1
fi

echo "game_pid=$game_pid" >> "$run_dir/metadata.txt"

swapchain_ready=0
for _ in $(seq 1 "$startup_timeout"); do
    if rg -q 'dxgi_vk_swap_chain_init: Creating swapchain' "$run_dir/steam-$APP_ID.log" 2>/dev/null; then
        swapchain_ready=1
        break
    fi
    kill -0 "$game_pid" 2>/dev/null || break
    sleep 1
done
if ((swapchain_ready == 0)); then
    echo "readiness=swapchain_not_seen" >> "$run_dir/result.txt"
    if ((stop_game)); then
        kill -TERM "$game_pid" 2>/dev/null || true
        wait "$launcher_pid" || true
    else
        echo 'termination=left_running_by_request' >> "$run_dir/result.txt"
        trap - EXIT INT TERM
    fi
    echo "timestamp_end=$(date --iso-8601=seconds)" >> "$run_dir/metadata.txt"
    exit 1
fi
echo "timestamp_swapchain=$(date --iso-8601=seconds)" >> "$run_dir/metadata.txt"

# MK11 creates its DX12 swapchain well before the intro movies and main menu.
# Keep the game alive through that phase; only then begin the measurement timer.
warmup_end=$((SECONDS + warmup))
while ((SECONDS < warmup_end)) && kill -0 "$game_pid" 2>/dev/null; do
    sleep 1
done
if ! kill -0 "$game_pid" 2>/dev/null; then
    echo "readiness=game_exited_during_post_swapchain_warmup" >> "$run_dir/result.txt"
    wait "$launcher_pid" || true
    echo "timestamp_end=$(date --iso-8601=seconds)" >> "$run_dir/metadata.txt"
    exit 1
fi

window_id=$(xdotool search --onlyvisible --pid "$game_pid" 2>/dev/null | tail -n 1 || true)
if [[ -z "$window_id" ]]; then
    echo "readiness=visible_window_not_found_after_warmup" >> "$run_dir/result.txt"
    if ((stop_game)); then
        kill -TERM "$game_pid" 2>/dev/null || true
        wait "$launcher_pid" || true
    else
        echo 'termination=left_running_by_request' >> "$run_dir/result.txt"
        trap - EXIT INT TERM
    fi
    echo "timestamp_end=$(date --iso-8601=seconds)" >> "$run_dir/metadata.txt"
    exit 1
fi
echo "window_id=$window_id" >> "$run_dir/metadata.txt"
echo "timestamp_ready=$(date --iso-8601=seconds)" >> "$run_dir/metadata.txt"

if ((use_mangohud)); then
    # MK11's XWayland window normally has focus after swapchain creation.
    # Trigger MangoHud's default logging hotkey at the start of the measured window.
    if [[ -n "$window_id" ]]; then
        xdotool windowactivate --sync "$window_id" key Shift_L+F2 || true
    else
        echo "mangohud_hotkey=window_not_found" >> "$run_dir/result.txt"
        xdotool key Shift_L+F2 || true
    fi
    sleep 1
fi

echo 'timestamp,pid,elapsed_s,state,cpu_percent,mem_percent,pstate,power_w,graphics_mhz,memory_mhz,gpu_percent,gpu_memory_percent,vram_mib,temp_c,pcie_gen,pcie_width' > "$run_dir/telemetry.csv"

end=$((SECONDS + duration))
while ((SECONDS < end)) && kill -0 "$game_pid" 2>/dev/null; do
    process=$(ps -p "$game_pid" -o pid=,etimes=,stat=,%cpu=,%mem= | xargs)
    gpu=$(nvidia-smi --query-gpu=pstate,power.draw,clocks.gr,clocks.mem,utilization.gpu,utilization.memory,memory.used,temperature.gpu,pcie.link.gen.current,pcie.link.width.current --format=csv,noheader,nounits | sed 's/, /,/g')
    IFS=' ' read -r pid elapsed state cpu mem <<< "$process"
    echo "$(date --iso-8601=seconds),$pid,$elapsed,$state,$cpu,$mem,$gpu" >> "$run_dir/telemetry.csv"
    sleep 5
done

if ((stop_game)) && kill -0 "$game_pid" 2>/dev/null; then
    echo 'termination=SIGTERM' >> "$run_dir/result.txt"
    kill -TERM "$game_pid" 2>/dev/null || true
    for _ in $(seq 1 5); do
        kill -0 "$game_pid" 2>/dev/null || break
        sleep 1
    done
    if kill -0 "$game_pid" 2>/dev/null; then
        echo 'termination_fallback=SIGKILL' >> "$run_dir/result.txt"
        kill -KILL "$game_pid" 2>/dev/null || true
    fi
elif ! kill -0 "$game_pid" 2>/dev/null; then
    echo 'termination=game_exited_before_deadline' >> "$run_dir/result.txt"
else
    echo 'termination=left_running_by_request' >> "$run_dir/result.txt"
fi

if ((stop_game)); then
    wait "$launcher_pid" || true
fi
trap - EXIT INT TERM
echo "timestamp_end=$(date --iso-8601=seconds)" >> "$run_dir/metadata.txt"

journalctl -k -b --since "@$(( $(date +%s) - duration - 45 ))" --no-pager \
    | rg -i 'nvrm|xid|gpu|drm|fault|segfault|error' > "$run_dir/kernel-gpu-errors.log" || true

echo "Completed: $run_dir"
