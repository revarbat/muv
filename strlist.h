#ifndef STRLIST_H
#define STRLIST_H

typedef struct strlist_t {
    const char** list;
    short count;
    short cmax;
} strlist;

void strlist_init(strlist *l);
void strlist_free(strlist *l);
void strlist_clear(strlist *l);
void strlist_add(strlist *l, const char *s);
void strlist_pop(strlist *l);
int strlist_find(strlist *l, const char *s);
const char *strlist_top(strlist *l);
char *strlist_join(strlist *l, const char *s, int start, int end);
char *strlist_wrap(strlist *l, int start, int end);
void strlist_reverse(strlist *l);
char *strlist_wrapit(const char *pfx, strlist *l, const char *sfx);

#endif

/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
