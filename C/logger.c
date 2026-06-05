#include <stdio.h>
#include <stdarg.h>
#include <time.h>

/* ANSI colors */
#define RESET  "\x1b[0m"
#define RED    "\x1b[31m"
#define GREEN  "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE   "\x1b[34m"
#define MAGENTA "\x1b[35m"
#define CYAN   "\x1b[36m"

typedef enum {
    LOG_INFO,
    LOG_WARN,
    LOG_ERROR,
    LOG_DEBUG
} LogLevel;

static void time_now(char *buf, size_t sz) {
    time_t t = time(NULL);
    struct tm *tm_info = localtime(&t);
    strftime(buf, sz, "%H:%M:%S", tm_info);
}

void log_msg(LogLevel level, const char *fmt, ...) {
    char timebuf[16];
    time_now(timebuf, sizeof(timebuf));

    const char *color;
    const char *label;

    switch (level) {
        case LOG_INFO:  color = GREEN;  label = "INFO";  break;
        case LOG_WARN:  color = YELLOW; label = "WARN";  break;
        case LOG_ERROR: color = RED;    label = "ERROR"; break;
        case LOG_DEBUG: color = CYAN;   label = "DEBUG"; break;
        default:         color = RESET;  label = "LOG";   break;
    }

    printf("%s[%s] %s%s%s: ", BLUE, timebuf, color, label, RESET);

    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);

    printf("\n");
}