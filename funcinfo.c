#include <stdlib.h>
#include <string.h>

#include "funcinfo.h"
#include "strutils.h"


void
funcinfo_free(struct funcinfo_t *l)
{
    free((void*) l->name);
    free((void*) l->code);
}


void
funclist_init(struct funclist *l)
{
    l->count = 0;
    l->cmax = 8;
    l->list = (struct funcinfo_t*)malloc(sizeof(struct funcinfo_t) * l->cmax);
}


void
funclist_free(struct funclist *l)
{
    for (int i = 0; i < l->count; i++) {
        funcinfo_free(&l->list[i]);
    }
    free(l->list);
    l->list = 0;
    l->count = 0;
    l->cmax = 0;
}


void
funclist_add(struct funclist *l, const char *name, const char *code, int argcnt, int retcnt, int hasvarargs)
{
    struct funcinfo_t *p;
    if (l->count >= l->cmax) {
        l->cmax += (l->cmax < 4096)? l->cmax : 4096;
        l->list = (struct funcinfo_t*)realloc(l->list, sizeof(struct funcinfo_t) * l->cmax);
    }
    p = &l->list[l->count];
    p->name = savestring(name);
    p->code = savestring(code);
    p->expects = argcnt;
    p->returns = retcnt;
    p->hasvarargs = hasvarargs;
    l->count++;
}


struct funcinfo_t *
funclist_find(struct funclist *l, const char *s)
{
    for (int i = 0; i < l->count; i++) {
        if (!strcmp(l->list[i].name, s)) {
            return &l->list[i];
        }
    }
    return NULL;
}


/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
