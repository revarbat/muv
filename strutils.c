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
appendstr(char *s1, const char *s2)
{
    size_t len1 = strlen(s1);
    size_t len2 = strlen(s2);
    s1 = (char*)realloc(s1, len1 + len2 + 2);
    if (len1 != 0 && len2 != 0) {
        if (lastlen(s1) + firstlen(s2) > 60) {
            strcat(&s1[len1], "\n");
        } else if (lastlen(s1) > 0 && firstlen(s2) > 0) {
            strcat(&s1[len1], " ");
        }
    }
    strcat(&s1[len1], s2);
    return s1;
}



char *
savefmt(const char *fmt, ...)
{
    va_list aptr;
    size_t buflen = 128;
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
appendfmt(char *s, const char *fmt, ...)
{
    va_list aptr;
    size_t buflen = 128;
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

    s = appendstr(s, buf);
    free(buf);

    return s;
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



char *
format_muv_str(const char *s)
{
    const char *p;
    char *out;
    char *p2;
    size_t len;
    for (len = 3, p = s; *p; len++, p++) {
        switch (*p) {
            case '\\':
            case '"':
            case '\n':
            case '\r':
            case '\b':
                len++;
                break;
        }
    }
    out = (char*)malloc(len);
    p2 = out;
    *p2++ = '\"';
    for (p = s; *p; p++) {
        switch (*p) {
            case '\\':
            case '\"':
                *p2++ = '\\';
                *p2++ = *p;
                break;
            case '\r':
            case '\n':
                *p2++ = '\\';
                *p2++ = 'r';
                break;
            case '\033':
                *p2++ = '\\';
                *p2++ = '[';
                break;
            default:
                *p2++ = *p;
                break;
        }
    }
    *p2++ = '\"';
    *p2++ = '\0';
    return out;
}


size_t
firstlen(const char *s)
{
    size_t len = 0;
    while (*s) {
        if (*s == '\n') {
            return len;
        } else {
            len++;
        }
        s++;
    }
    return len;
}


size_t
lastlen(const char *s)
{
    size_t len = 0;
    while (*s) {
        if (*s == '\n') {
            len = 0;
        } else {
            len++;
        }
        s++;
    }
    return len;
}


size_t
linecount(const char *s)
{
    size_t len = 1;
    while (*s) {
        if (*s == '\n') {
            len++;
        }
        s++;
    }
    return len;
}


char *
wrapit(const char *pfx, const char *s, const char *sfx)
{
    char *out;
    if (linecount(s) > 1 || strlen(pfx) + strlen(s) + strlen(sfx) > 60) {
        char *ind = indent(s);
        out = savefmt("%s\n%s\n%s", pfx, ind, sfx);
        free(ind);
    } else {
        out = savefmt("%s %s %s", pfx, s, sfx);
    }
    return out;
}


char *
wrapit2(const char *pfx, const char *s, const char *mid, const char *s2, const char *sfx)
{
    char *out;
    if (linecount(s) > 1 || linecount(s2) > 1 || strlen(pfx) + strlen(s) + strlen(mid) + strlen(s2) + strlen(sfx) > 60) {
        char *ind = indent(s);
        char *ind2 = indent(s2);
        out = savefmt("%s\n%s\n%s\n%s\n%s", pfx, ind, mid, ind2, sfx);
        free(ind);
        free(ind2);
    } else {
        out = savefmt("%s %s %s", pfx, s, sfx);
    }
    return out;
}


void getset_free(struct gettersetter *x)
{
    if (x->get) {
        free((char*)x->get);
        x->get = NULL;
    }
    if (x->set) {
        free((char*)x->set);
        x->set = NULL;
    }
    if (x->del) {
        free((char*)x->del);
        x->del = NULL;
    }
    if (x->call) {
        free((char*)x->call);
        x->call = NULL;
    }
    if (x->oper_pre) {
        free((char*)x->oper_pre);
        x->oper_pre = NULL;
    }
    if (x->oper_post) {
        free((char*)x->oper_post);
        x->oper_post = NULL;
    }
}



/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */

