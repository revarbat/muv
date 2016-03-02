#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "strlist.h"
#include "strutils.h"


void
strlist_init(struct strlist *l)
{
    l->count = 0;
    l->cmax = 8;
    l->list = (const char**)malloc(sizeof(const char*) * l->cmax);
}


void
strlist_free(struct strlist *l)
{
    for (int i = 0; i < l->count; i++) {
        free((void*) l->list[i]);
    }
    free(l->list);
    l->list = NULL;
    l->count = 0;
    l->cmax = 0;
}


void
strlist_clear(struct strlist *l)
{
    strlist_free(l);
    strlist_init(l);
}


void
strlist_add(struct strlist *l, const char *s)
{
    if (l->count >= l->cmax) {
        l->cmax += (l->cmax < 4096)? l->cmax : 4096;
        l->list = (const char**)realloc(l->list, sizeof(const char*) * l->cmax);
    }
    l->list[l->count++] = savestring(s);
}


void
strlist_pop(struct strlist *l)
{
    if (l->count > 0) {
        free((void*) l->list[--l->count]);
    }
}


int
strlist_find(struct strlist *l, const char *s)
{
    for (int i = 0; i < l->count; i++) {
        if (!strcmp(l->list[i], s)) {
            return i;
        }
    }
    return -1;
}


char *
strlist_join(struct strlist *l, const char *s, int start, int end)
{
    char *buf;
    const char *ptr;
    char *ptr2;
    int i;
    size_t totlen = 0;
    if (end == -1) {
        end = l->count;
    }
    for (i = start; i < l->count && i < end; i++) {
        for (ptr = l->list[i]; *ptr++; totlen++);
    }
    totlen += strlen(s) * l->count;
    ptr2 = buf = (char*)malloc(totlen+1);
    for (i = start; i < l->count && i < end; i++) {
        if (i > start) {
            for(ptr = s; *ptr; ) *ptr2++ = *ptr++;
        }
        for(ptr = l->list[i]; *ptr; ) *ptr2++ = *ptr++;
    }
    *ptr2 = '\0';
    return buf;
}


char *
strlist_wrap(struct strlist *l, int start, int end)
{
    char *buf;
    const char *ptr;
    char *ptr2;
    int i;
    size_t totlen = 0;
    size_t currlen = 0;
    if (end == -1) {
        end = l->count;
    }
    for (i = start; i < l->count && i < end; i++) {
        for (ptr = l->list[i]; *ptr++; totlen++);
    }
    totlen += l->count;
    ptr2 = buf = (char*)malloc(totlen+1);
    for (i = start; i < l->count && i < end; i++) {
        if (i > start) {
            if (currlen > 0) {
                if (currlen + strlen(l->list[i]) > 60) {
                    *ptr2++ = '\n';
                    currlen = 0;
                } else {
                    *ptr2++ = ' ';
                    currlen++;
                }
            }
        }
        for(ptr = l->list[i]; *ptr; ) {
            if (*ptr == '\n') {
                currlen = 0;
            } else {
                currlen++;
            }
            *ptr2++ = *ptr++;
        }
    }
    *ptr2 = '\0';
    return buf;
}


void
strlist_reverse(struct strlist *l)
{
    int a, b;
    if (l->count < 1)
        return;
    a = 0;
    b = l->count-1;
    while (a < b) {
        const char *tmp = l->list[a];
        l->list[a] = l->list[b];
        l->list[b] = tmp;
        a++; b--;
    }
}



/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
