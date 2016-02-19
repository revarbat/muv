#ifndef FUNCINFO_H
#define FUNCINFO_H

struct funcinfo_t {
    const char *name;
    const char *code;
    short expects;
    short returns;
    short hasvarargs;
};

void funcinfo_free(struct funcinfo_t *l);

struct funclist {
    struct funcinfo_t* list;
    short count;
    short cmax;
};

void funclist_init(struct funclist *l);
void funclist_free(struct funclist *l);
void funclist_add(struct funclist *l, const char *name, const char *code, int argcnt, int retcnt, int hasvarargs);
struct funcinfo_t *funclist_find(struct funclist *l, const char *s);


#endif
/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
