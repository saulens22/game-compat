#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <linux/joystick.h>
#include <linux/input.h>
#include <poll.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void stamp(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    fprintf(stderr, "%lld.%03ld ", (long long)now.tv_sec, now.tv_nsec / 1000000);
}

static int request_quit(const char *socket_path) {
    struct sockaddr_un address = {.sun_family = AF_UNIX};
    if (strlen(socket_path) >= sizeof(address.sun_path)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    strcpy(address.sun_path, socket_path);
    int fd = -1;
    for (int attempt = 0; attempt < 50; ++attempt) {
        fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
        if (fd < 0) return -1;
        if (connect(fd, (struct sockaddr *)&address, sizeof(address)) == 0) break;
        close(fd);
        fd = -1;
        struct timespec delay = {.tv_nsec = 10000000};
        nanosleep(&delay, NULL);
    }
    if (fd < 0) return -1;
    const char command[] = "{\"command\":[\"quit\"]}\n";
    ssize_t written = write(fd, command, sizeof(command) - 1);
    close(fd);
    return written == (ssize_t)(sizeof(command) - 1) ? 0 : -1;
}

int main(int argc, char **argv) {
    struct pollfd fds[32];
    int evdev[32];
    const char *device_paths[32];
    int count = 0;
    char *end = NULL;
    long target;

    if (argc < 4) {
        fprintf(stderr, "usage: %s PID MPV_SOCKET /dev/input/js...\n", argv[0]);
        return 2;
    }
    target = strtol(argv[1], &end, 10);
    if (!end || *end || target <= 1) return 2;

    for (int i = 3; i < argc && count < 32; ++i) {
        int fd = open(argv[i], O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (fd < 0) {
            fprintf(stderr, "controller-skip: open %s: %s\n", argv[i], strerror(errno));
            continue;
        }
        fds[count].fd = fd;
        fds[count].events = POLLIN;
        evdev[count] = strstr(argv[i], "/event") != NULL;
        device_paths[count] = argv[i];
        stamp();
        fprintf(stderr, "controller-skip: watching %s as %s\n", argv[i],
                evdev[count] ? "evdev" : "joystick");
        ++count;
    }
    if (!count) return 3;

    while (kill((pid_t)target, 0) == 0 || errno == EPERM) {
        int ready = poll(fds, (nfds_t)count, 250);
        if (ready < 0 && errno == EINTR) continue;
        if (ready < 0) return 4;
        for (int i = 0; i < count; ++i) {
            if (!(fds[i].revents & POLLIN)) continue;
            if (evdev[i]) {
                for (;;) {
                    struct input_event event;
                    ssize_t got = read(fds[i].fd, &event, sizeof(event));
                    if (got != sizeof(event)) break;
                    if (event.type == EV_KEY) {
                        stamp();
                        fprintf(stderr, "controller-skip: raw %s key code=%u value=%d\n",
                                device_paths[i], event.code, event.value);
                    }
                    if (event.type == EV_KEY && event.value == 1 &&
                        event.code >= BTN_JOYSTICK && event.code <= BTN_THUMBR) {
                        stamp();
                        fprintf(stderr, "controller-skip: quit request from evdev button %u\n", event.code);
                        return request_quit(argv[2]) == 0 ? 0 : 5;
                    }
                }
            } else {
                for (;;) {
                    struct js_event event;
                    ssize_t got = read(fds[i].fd, &event, sizeof(event));
                    if (got != sizeof(event)) break;
                    if ((event.type & JS_EVENT_BUTTON) && !(event.type & JS_EVENT_INIT)) {
                        stamp();
                        fprintf(stderr, "controller-skip: raw %s button=%u value=%d\n",
                                device_paths[i], event.number, event.value);
                    }
                    if (!(event.type & JS_EVENT_INIT) &&
                        (event.type & JS_EVENT_BUTTON) && event.value == 1) {
                        stamp();
                        fprintf(stderr, "controller-skip: quit request from joystick button %u\n", event.number);
                        return request_quit(argv[2]) == 0 ? 0 : 5;
                    }
                }
            }
        }
    }
    return 0;
}
