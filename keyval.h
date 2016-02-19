#ifndef KEYVAL_H
#define KEYVAL_H

#define HASHSIZE 1021 /* prime */


struct keyval_t {
    const char *key;
    const char *val;
};

void keyval_free(struct keyval_t *x);

struct kvlist {
    struct keyval_t* list;
    short count;
    short cmax;
};

void kvlist_init(struct kvlist *l);
void kvlist_free(struct kvlist *l);
void kvlist_add(struct kvlist *l, const char *k, const char *v);
const char*kvlist_get(struct kvlist *l, const char *k);

struct kvmap {
    struct kvlist* map;
    short count;
    short cmax;
};

void kvmap_init(struct kvmap *m);
void kvmap_free(struct kvmap *m);
void kvmap_clear(struct kvmap *m);
void kvmap_add(struct kvmap *m, const char *k, const char *v);
const char *kvmap_get(struct kvmap *m, const char *k);

#endif
/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
