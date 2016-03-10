#include <stdlib.h>
#include <string.h>

#include "keyval.h"
#include "strutils.h"


void
keyval_free(keyval *x)
{
    free((void*)x->key);
    free((void*)x->val);
    x->key = NULL;
    x->val = NULL;
}



void
kvlist_init(kvlist *l)
{
    l->count = 0;
    l->cmax = 8;
    l->list = (keyval*)malloc(sizeof(keyval) * l->cmax);
}


void
kvlist_free(kvlist *l)
{
    for (int i = 0; i < l->count; i++) {
        keyval_free(&l->list[i]);
    }
    free(l->list);
    l->list = NULL;
    l->count = 0;
    l->cmax = 0;
}


void
kvlist_add(kvlist *l, const char *k, const char *v)
{
    if (l->count >= l->cmax) {
        l->cmax += (l->cmax < 4096)? l->cmax : 4096;
        l->list = (keyval *)realloc(l->list, sizeof(keyval) * l->cmax);
    }
    l->list[l->count].key = savestring(k);
    l->list[l->count].val = savestring(v);
    l->count++;
}


const char*
kvlist_get(kvlist *l, const char *k)
{
    for (int i = 0; i < l->count; i++) {
        if (!strcmp(l->list[i].key, k)) {
            return l->list[i].val;
        }
    }
    return NULL;
}



unsigned long
kvmap_hash(const char*s)
{
    // Based on Dan Bernstein's djb2
    unsigned long h = 5381;

    while (*s)
        h = ((h << 5) + h) + *s++;

    return h;
}


void
kvmap_init(kvmap *m)
{
    int i;
    m->map = (kvlist*)malloc(HASHSIZE*sizeof(kvlist));
    m->count = 0;
    for (i = 0; i < HASHSIZE; i++) {
        kvlist_init(&m->map[i]);
    }
}


void
kvmap_free(kvmap *m)
{
    int i;
    for (i = 0; i < HASHSIZE; i++) {
        kvlist_free(&m->map[i]);
    }
    free(m->map);
    m->map = NULL;
}


void
kvmap_clear(kvmap *m)
{
    kvmap_free(m);
    kvmap_init(m);
}


void
kvmap_add(kvmap *m, const char *k, const char *v)
{
    unsigned long h = kvmap_hash(k) % HASHSIZE;
    kvlist_add(&m->map[h], k, v);
}


const char *
kvmap_get(kvmap *m, const char *k)
{
    unsigned long h = kvmap_hash(k) % HASHSIZE;
    return kvlist_get(&m->map[h], k);
}



void
kvmaplist_init(kvmaplist *l)
{
    l->count = 0;
    l->cmax = 8;
    l->list = (kvmap *)malloc(sizeof(kvmap) * l->cmax);
}


void
kvmaplist_free(kvmaplist *l)
{
    for (int i = 0; i < l->count; i++) {
        kvmap_free(&l->list[i]);
    }
    free(l->list);
    l->list = NULL;
    l->count = 0;
    l->cmax = 0;
}


void
kvmaplist_add(kvmaplist *l)
{
    if (l->count >= l->cmax) {
        l->cmax += (l->cmax < 4096)? l->cmax : 4096;
        l->list = (kvmap *)realloc(l->list, sizeof(kvmap) * l->cmax);
    }
    kvmap_init(&l->list[l->count]);
    l->count++;
}


void
kvmaplist_pop(kvmaplist *l)
{
    if (l->count > 0) {
        kvmap_free(&l->list[--l->count]);
    }
}


kvmap *
kvmaplist_top(kvmaplist *l)
{
    return (l->count > 0)? &l->list[l->count-1] : NULL;
}


const char*
kvmaplist_find(kvmaplist *l, const char *name)
{
    for (int i = l->count; i-->0; ) {
        const char *cp = kvmap_get(&l->list[i], name);
        if (cp) return cp;
    }
    return NULL;
}



/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
