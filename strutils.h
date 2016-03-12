#ifndef STRUTILS_H
#define STRUTILS_H

#include <stdarg.h>
#include <stdlib.h>

int endswith(const char *s, const char *s2);
char *savestring(const char *);
char *savefmt(const char *fmt, ...);
char *appendstr(char *s, ...);
char *appendfmt(char *s, const char *fmt, ...);
char *indent(const char *);
char *format_muv_str(const char *);
size_t firstlen(const char *);
size_t lastlen(const char *);
size_t linecount(const char *);
char *wrapit(const char *pfx, const char *s, const char *sfx);
char *wrapit2(const char *pfx, const char *s, const char *mid, const char *s2, const char *sfx);

typedef struct accessor_t {
    const char *get;
    const char *set;
    const char *del;
    const char *call;
    const char *oper_pre;
    const char *oper_post;
} accessor;

void getset_free(accessor *x);


#endif
/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */

