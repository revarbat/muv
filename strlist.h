#ifndef STRLIST_H
#define STRLIST_H

struct strlist {
    const char** list;
    short count;
    short cmax;
};

void strlist_init(struct strlist *l);
void strlist_free(struct strlist *l);
void strlist_clear(struct strlist *l);
void strlist_add(struct strlist *l, const char *s);
void strlist_pop(struct strlist *l);
int strlist_find(struct strlist *l, const char *s);
char *strlist_join(struct strlist *l, const char *s, int start, int end);
char *strlist_wrap(struct strlist *l, int start, int end);
void strlist_reverse(struct strlist *l);
char *strlist_wrapit(const char *pfx, struct strlist *l, const char *sfx);

#endif

/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
