#include <stdlib.h>
#include <string.h>

#include "keyval.h"
#include "strutils.h"


void
keyval_free(struct keyval_t *x)
{
    free((void*)x->key);
    free((void*)x->val);
    x->key = NULL;
    x->val = NULL;
}



void
kvlist_init(struct kvlist *l)
{
    l->count = 0;
    l->cmax = 8;
    l->list = (struct keyval_t*)malloc(sizeof(struct keyval_t) * l->cmax);
}


void
kvlist_free(struct kvlist *l)
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
kvlist_add(struct kvlist *l, const char *k, const char *v)
{
    if (l->count >= l->cmax) {
        l->cmax += (l->cmax < 4096)? l->cmax : 4096;
        l->list = (struct keyval_t *)realloc(l->list, sizeof(struct keyval_t) * l->cmax);
    }
    l->list[l->count].key = savestring(k);
    l->list[l->count].val = savestring(v);
    l->count++;
}


const char*
kvlist_get(struct kvlist *l, const char *k)
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
kvmap_init(struct kvmap *m)
{
    int i;
    m->map = (struct kvlist*)malloc(HASHSIZE*sizeof(struct kvlist));
    m->count = 0;
    for (i = 0; i < HASHSIZE; i++) {
        kvlist_init(&m->map[i]);
    }
}


void
kvmap_free(struct kvmap *m)
{
    int i;
    for (i = 0; i < HASHSIZE; i++) {
        kvlist_free(&m->map[i]);
    }
    free(m->map);
    m->map = NULL;
}


void
kvmap_clear(struct kvmap *m)
{
    kvmap_free(m);
    kvmap_init(m);
}


void
kvmap_add(struct kvmap *m, const char *k, const char *v)
{
    unsigned long h = kvmap_hash(k) % HASHSIZE;
    return kvlist_add(&m->map[h], k, v);
}


const char *
kvmap_get(struct kvmap *m, const char *k)
{
    unsigned long h = kvmap_hash(k) % HASHSIZE;
    return kvlist_get(&m->map[h], k);
}



/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
