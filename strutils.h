#ifndef STRUTILS_H
#define STRUTILS_H

#include <stdarg.h>
#include <stdlib.h>

char *savefmt(const char *fmt, ...);
char *savestring(const char *);
char *indent(const char *);
char *format_muv_str(const char *);

struct gettersetter {
    const char *get;
    const char *set;
    const char *del;
    const char *call;
    const char *oper_pre;
    const char *oper_post;
};

void getset_free(struct gettersetter *x);


#endif
/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */

