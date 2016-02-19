#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#include "strutils.h"


char *
savestring(const char *arg)
{
    char *tmp = (char *)malloc(strlen(arg) + 1);
    strcpy(tmp, arg);
    return(tmp);
}



char *
savefmt(const char *fmt, ...)
{
    va_list aptr;
    size_t buflen = 2048;
    char *buf = (char*)malloc(buflen);
    int len;

    va_start(aptr, fmt);
    len = vsnprintf(buf, buflen, fmt, aptr);
    va_end(aptr);

    if (len >= buflen-1) {
        buflen = len + 2;
        buf = (char*)realloc(buf, buflen);
        va_start(aptr, fmt);
        len = vsnprintf(buf, buflen, fmt, aptr);
        va_end(aptr);
    }

    return buf;
}



char *
indent(const char *arg)
{
    const int indentlen = 4;
    char *buf;
    const char *ptr;
    char *ptr2;
    int i, lines;

    if (!arg || !*arg) {
        return savestring("");
    }
    for (ptr = arg, lines = 1; *ptr; ptr++) {
        if (*ptr == '\n') {
            lines++;
        }
    }
    buf = (char *)malloc(strlen(arg) + 1 + indentlen*lines);
    ptr = arg;
    ptr2 = buf;
    while (*ptr) {
        for (i = 0; *ptr != '\n' && i < indentlen; i++) {
            *ptr2++ = ' ';
        }
        while (*ptr) {
            *ptr2++ = *ptr;
            if (*ptr++ == '\n') break;
        }
    }
    *ptr2 = '\0';
    return buf;
}



void getset_free(struct gettersetter *x)
{
    free((char*)x->get);
    free((char*)x->set);
    free((char*)x->del);
    x->get = NULL;
    x->set = NULL;
    x->del = NULL;
}



/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
