#ifndef KEYVAL_H
#define KEYVAL_H

#define HASHSIZE 1021 /* prime */


typedef struct keyval_t {
    const char *key;
    const char *val;
} keyval;

void keyval_free(keyval *x);

typedef struct kvlist_t {
    struct keyval_t* list;
    short count;
    short cmax;
} kvlist;

void kvlist_init(kvlist *l);
void kvlist_free(kvlist *l);
void kvlist_add(kvlist *l, const char *k, const char *v);
const char*kvlist_get(kvlist *l, const char *k);

typedef struct kvmap_t {
    kvlist* map;
    short count;
    short cmax;
} kvmap;

void kvmap_init(kvmap *m);
void kvmap_free(kvmap *m);
void kvmap_clear(kvmap *m);
void kvmap_add(kvmap *m, const char *k, const char *v);
const char *kvmap_get(kvmap *m, const char *k);

typedef struct kvmaplist_t {
    kvmap* list;
    short count;
    short cmax;
} kvmaplist;

void kvmaplist_init(kvmaplist *l);
void kvmaplist_free(kvmaplist *l);
void kvmaplist_add(kvmaplist *l);
void kvmaplist_pop(kvmaplist *l);
kvmap *kvmaplist_top(kvmaplist *l);
const char* kvmaplist_find(kvmaplist *l, const char *name);


#endif
/* vim: set ts=4 list_w=4 et ai hlsearch nowrap : */
