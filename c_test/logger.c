#include "logger.h"
#include <stdarg.h>
#include <time.h>

LogLevel MINIMUM_LOG_LEVEL = LOG_LEVEL_INFO;

//colors :)
#define CLR_RESET   "\x1b[0m"
#define CLR_DEBUG   "\x1b[36m" // Cyan
#define CLR_INFO    "\x1b[32m" // Green
#define CLR_WARN    "\x1b[33m" // Yellow
#define CLR_ERROR   "\x1b[31m" // Red

void log_message(LogLevel level, const char *file, int line, const char *format, ...) {

    //return if 
    if (level < MINIMUM_LOG_LEVEL) {
        return;
    }

    //basically if err it comes out of errout
    FILE *stream = (level >= LOG_LEVEL_WARN) ? stderr : stdout;

    //timestamp
    time_t now = time(NULL);
    struct tm *t = localtime(&now);
    char time_buf[26];
    strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S", t);

    //level to string labels and colors
    const char *level_str = "INFO";
    const char *color = CLR_INFO;
    switch (level) {
        case LOG_LEVEL_DEBUG: level_str = "DEBUG"; color = CLR_DEBUG; break;
        case LOG_LEVEL_WARN:  level_str = "WARN";  color = CLR_WARN;  break;
        case LOG_LEVEL_ERROR: level_str = "ERROR"; color = CLR_ERROR; break;
        default: break;
    }

    //prefixes
    fprintf(stream, "%s [%s%s%s] (%s:%d): ", time_buf, color, level_str, CLR_RESET, file, line);

    //vfprintf magic
    va_list args;
    va_start(args, format);
    vfprintf(stream, format, args);
    va_end(args);

    //new line & clean buffer
    fprintf(stream, "\n");
    fflush(stream);
}

// 482 ts --> 772 ts
