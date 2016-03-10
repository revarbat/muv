#ifndef FUNCINFO_H
#define FUNCINFO_H

typedef struct funcinfo_t {
    const char *name;
    const char *code;
    short expects;
    short returns;
    short hasvarargs;
} funcinfo;

void funcinfo_free(funcinfo *l);

typedef struct funclist_t {
    funcinfo* list;
    short count;
    short cmax;
} funclist;

void funclist_init(funclist *l);
void funclist_free(funclist *l);
void funclist_add(funclist *l, const char *name, const char *code, int argcnt, int retcnt, int hasvarargs);
funcinfo *funclist_find(funclist *l, const char *s);


#endif
/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */
