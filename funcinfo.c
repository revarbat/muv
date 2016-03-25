#include <stdlib.h>
#include <string.h>

#include "funcinfo.h"
#include "strutils.h"


void
funcinfo_free(funcinfo *l)
{
    free((void*) l->name);
    free((void*) l->code);
}


void
funclist_init(funclist *l)
{
    l->count = 0;
    l->cmax = 8;
    l->list = (funcinfo*)malloc(sizeof(funcinfo) * l->cmax);
}


void
funclist_free(funclist *l)
{
    int i;
    for (i = 0; i < l->count; i++) {
        funcinfo_free(&l->list[i]);
    }
    free(l->list);
    l->list = 0;
    l->count = 0;
    l->cmax = 0;
}


void
funclist_add(funclist *l, const char *name, const char *code, int argcnt, int retcnt, int hasvarargs)
{
    funcinfo *p = funclist_find(l, name);
    if (p) {
        funcinfo_free(p);
    } else {
        if (l->count >= l->cmax) {
            l->cmax += (l->cmax < 4096)? l->cmax : 4096;
            l->list = (funcinfo*)realloc(l->list, sizeof(funcinfo) * l->cmax);
        }
        p = &l->list[l->count++];
    }
    p->name = savestring(name);
    p->code = savestring(code);
    p->expects = argcnt;
    p->returns = retcnt;
    p->hasvarargs = hasvarargs;
}


funcinfo *
funclist_find(funclist *l, const char *s)
{
    int i;
    for (i = 0; i < l->count; i++) {
        if (!strcmp(l->list[i].name, s)) {
            return &l->list[i];
        }
    }
    return NULL;
}


/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
