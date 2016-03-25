%{

#define MAX_IDENT_LEN 128
#define MAX_STR_LEN 1024
#define MAX_INCLUDE_LEVELS 64
#define FUNC_PREFIX "_"
#define VAR_PREFIX "_"

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "configs.h"
#include "strlist.h"
#include "keyval.h"
#include "funcinfo.h"
#include "strutils.h"


kvmap included_files;
strlist namespace_list;
strlist using_list;

strlist namespaces_active;
strlist inits_list;
funclist funcs_list;
funclist externs_list;
kvmap global_consts;
kvmap global_vars;

strlist vardecl_list;
kvmap scoping_vars_used;
kvmaplist scoping_consts;
kvmaplist scoping_vars;

FILE *yyin=NULL;
FILE *outf=NULL;
int yylineno = 1;
const char *yydirname = ".";
const char *yyfilename = "STDIN";
int yylex(void);
int yyparse(void);
void yyerror(char *s);

char *decl_new_variable(const char *name);

const char *includes_dir = MUV_INCLUDES_DIR;
int debugging_level = 0;
int do_optimize = 1;
int has_tuple_check = 0;
const char *tuple_check =
    ": tuple_check[ arr expect pos -- ]\n"
    "    arr @ array? not if\n"
    "        \"Cannot unpack from non-array in \" pos @ strcat abort\n"
    "    then\n"
    "    arr @ array_count expect @ = not if\n"
    "        \"Wrong number of values to unpack in \" pos @ strcat abort\n"
    "    then\n"
    ";\n";

struct bookmark_t {
    const char *dname;
    const char *fname;
    long pos;
    long lineno;
} bookmarks[MAX_INCLUDE_LEVELS];
int bookmark_count = 0;

int bookmark_push(const char *fname);
int bookmark_pop();


/* compiler state exception flag */
%}

%union {
    int token;
    char *str;
    int num_int;
    strlist list;
    keyval keyval;
    funcinfo prim;
    accessor getset;
}

%token <num_int> INTEGER
%token <prim> DECLARED_FUNC
%token <str> FLOAT STR IDENT VAR CONST
%token <keyval> DECLARED_CONST DECLARED_VAR
%token <token> INCLUDE UNARY NAMESPACE
%token <token> D_LANGUAGE D_INCLUDE D_AUTHOR
%token <token> D_VERSION D_LIBVERSION D_PRAGMA
%token <token> D_WARN D_ERROR D_NOTE D_ECHO
%token <token> IF ELSE UNLESS PUBLIC
%token <token> FUNC RETURN TRY CATCH
%token <token> SWITCH USING CASE DEFAULT
%token <token> DO WHILE UNTIL FOR BY
%token <token> CONTINUE BREAK
%token <token> TOP PUSH MUF DEL FMTSTRING
%token <token> EXTERN VOID SINGLE MULTIPLE

%right BARE ELSE SUFFIX
%left ',' KEYVAL
%right ASGN PLUSASGN MINUSASGN MULTASGN DIVASGN MODASGN BITLEFTASGN BITRIGHTASGN BITANDASGN BITORASGN BITXORASGN
%left DECR INCR
%right '?' ':'
%left OR XOR
%left AND
%left BITOR
%left BITXOR
%left BITAND
%left EQEQ NEQ STREQ
%left GT GTE LT LTE IN
%left BITLEFT BITRIGHT
%left PLUS MINUS
%left MULT DIV MOD
%right UNARY NOT BITNOT
%left '[' ']' '(' ')' APPEND DOT

%type <str> globalstatement ns_ident directive
%type <str> proposed_funcname maybe_bad_funcname
%type <str> proposed_varname maybe_bad_varname
%type <str> simple_statement statement statements paren_expr
%type <str> compr_loop compr_cond subscript
%type <str> function_call expr attribute settable
%type <str> using_clause case_clause case_clauses default_clause
%type <list> arglist arglist_or_null dictlist argvarlist
%type <list> index_parts tuple_parts
%type <getset> lvalue
%type <num_int> ret_count_type opt_varargs opt_public

%start program

%%

program: /* nothing */ { }
    | program globalstatement { if (outf) fprintf(outf, "%s", $2);  free($2); }
    | program nsdecl '{' program '}' {
            strlist_pop(&namespace_list);
        }
    ;

nsdecl: NAMESPACE ns_ident {
            char full[MAX_IDENT_LEN];
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                snprintf(full, sizeof(full), "%s::%s", ns, $2);
            } else {
                strcpy(full, $2);
            }
            strlist_add(&namespace_list, full);
        }
    ;

globalstatement:
      MUF '(' STR ')' ';' { $$ = savefmt("%s\n", $3); free($3); }
    | directive { $$ = $1; }
    | USING NAMESPACE ns_ident ';' {
            strlist_add(&namespaces_active, $3);
            $$ = savestring("");
            free($3);
        }
    | INCLUDE STR ';' {
            if (!bookmark_push($2))
                YYERROR;
            $$ = savestring("");
            free($2);
        }
    | CONST proposed_varname ASGN expr ';' {
            char *vname;
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                vname = savefmt("%s::%s", ns, $2);
            } else {
                vname = savestring($2);
            }
            $$ = savestring("");
            kvmap_add(&global_consts, vname, $4);
            free(vname);
            free($2); free($4);
        }
    | VAR proposed_varname ';' {
            char *vname;
            char *code;
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                vname = savefmt("%s::%s", ns, $2);
                code = savefmt("%s::%s", ns, $2);
            } else {
                vname = savestring($2);
                code = savefmt("%s%s", VAR_PREFIX, $2);
            }
            $$ = savefmt("lvar %s\n", code);
            kvmap_add(&global_vars, vname, code);
            free(vname);
            free($2);
        }
    | VAR proposed_varname ASGN expr ';' {
            char *vname, *code, *init;
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                vname = savefmt("%s::%s", ns, $2);
                code = savefmt("%s::%s", ns, $2);
            } else {
                vname = savestring($2);
                code = savefmt("%s%s", VAR_PREFIX, $2);
            }
            $$ = savefmt("lvar %s\n", code);
            kvmap_add(&global_vars, vname, code);
            init = savefmt("%s %s !", $4, code);
            strlist_add(&inits_list, init);
            free(init);
            free(vname);
            free($2);
            free($4);
        }
    | EXTERN su ret_count_type proposed_funcname '(' argvarlist opt_varargs ')' sd ';' {
            char *fname;
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                fname = savefmt("%s::%s", ns, $4);
            } else {
                fname = savestring($4);
            }
            funclist_add(&externs_list, fname, $4, $6.count - ($7?1:0), $3, $7);
            $$ = savestring("");
            free(fname);
            free($4);
            strlist_free(&$6);
            strlist_clear(&vardecl_list);
            kvmap_clear(&scoping_vars_used);
        }
    | EXTERN su ret_count_type proposed_funcname '(' argvarlist opt_varargs ')' ASGN STR sd ';' {
            char *fname;
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                fname = savefmt("%s::%s", ns, $4);
            } else {
                fname = savestring($4);
            }
            funclist_add(&externs_list, fname, $10, $6.count - ($7?1:0), $3, $7);
            $$ = savestring("");
            free(fname);
            free($4);
            strlist_free(&$6);
            free($10);
            strlist_clear(&vardecl_list);
            kvmap_clear(&scoping_vars_used);
        }
    | opt_public FUNC su proposed_funcname '(' argvarlist opt_varargs ')' {
            /* Mid-rule action to make sure function is declared
             * before statements, to allow possible recursion. */
            char *fname;
            char *code;
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                fname = savefmt("%s::%s", ns, $4);
                if ($1) {
                    char *p;
                    for (p = fname; *p; p++) {
                        if (*p == ':') *p = '_';
                    }
                }
                code = savestring(fname);
            } else {
                fname = savestring($4);
                if ($1) {
                    code = savestring($4);
                } else {
                    code = savefmt("%s%s", FUNC_PREFIX, $4);
                }
            }
            funclist_add(&funcs_list, fname, code, $6.count - ($7?1:0), 1, $7);
            free(fname);
            free(code);
            strlist_clear(&vardecl_list);
        } '{' statements '}' sd {
            char *fname;
            const char *ns = strlist_top(&namespace_list);
            char *body, *vars, *decls, *idecls;
            if (ns && *ns) {
                fname = savefmt("%s::%s", ns, $4);
                if ($1) {
                    char *p;
                    for (p = fname; *p; p++) {
                        if (*p == ':') *p = '_';
                    }
                }
            } else {
                if ($1) {
                    fname = savestring($4);
                } else {
                    fname = savefmt("%s%s", FUNC_PREFIX, $4);
                }
            }
            body = indent($11);
            vars = strlist_join(&$6, " ", 0, -1);
            decls = strlist_wrap(&vardecl_list, 0, -1);
            idecls = indent(decls);
            if (*idecls) {
                idecls = appendstr(idecls, "\n", NULL);
            }
            free(decls);
            if (endswith(body, " exit")) {
                body[strlen(body)-5] = '\0';
                $$ = savefmt(": %s[ %s -- ret ]\n%s%s\n;\n", fname, vars, idecls, body);
            } else {
                $$ = savefmt(": %s[ %s -- ret ]\n%s%s\n    0\n;\n", fname, vars, idecls, body);
            }
            if ($1) {
                $$ = appendfmt($$, "public %s\n", fname);
                $$ = appendfmt($$, "$libdef %s\n", fname);
            }
            strlist_clear(&vardecl_list);
            kvmap_clear(&scoping_vars_used);
            free(idecls);
            free(vars);
            free(body);
            free(fname);
            free($4);
            strlist_free(&$6);
            free($11);
        }
    ;

directive:
      D_LANGUAGE STR {
            if (strcmp($2, "muv")) {
                yyerror("Only $language \"muv\" allowed.");
                YYERROR;
            }
            $$ = savestring("");
            free($2);
        }
    | D_VERSION FLOAT { $$ = savefmt("$version %s\n", $2); free($2); }
    | D_LIBVERSION FLOAT { $$ = savefmt("$lib-version %s\n", $2); free($2); }
    | D_AUTHOR STR  { $$ = savefmt("$author %s\n", $2); free($2); }
    | D_NOTE STR  { $$ = savefmt("$note %s\n", $2); free($2); }
    | D_ECHO STR  { $$ = savefmt("$echo %s\n", $2); free($2); }
    | D_PRAGMA STR { $$ = savefmt("$pragma %s\n", $2); free($2); }
    | D_INCLUDE STR { $$ = savefmt("$include %s\n", $2); free($2); }
    | D_ERROR STR { yyerror($2); free($2); $$ = savestring(""); YYERROR; }
    | D_WARN STR {
            fprintf(stderr, "Warning in %s/%s:%d: %s\n", yydirname, yyfilename, yylineno, $2);
            $$ = savestring("");
            free($2);
        }
    ;

opt_public: /* nothing */ { $$ = 0; }
    | PUBLIC { $$ = 1; }
    ;

ns_ident: IDENT { $$ = savestring($1); }
    | DECLARED_VAR { $$ = savestring($1.key); keyval_free(&$1); }
    | DECLARED_CONST { $$ = savestring($1.key); keyval_free(&$1); }
    | DECLARED_FUNC { $$ = savestring($1.name); }
    ;

maybe_bad_funcname:
      DECLARED_VAR { $$ = savestring($1.key); keyval_free(&$1); }
    | DECLARED_CONST { $$ = savestring($1.key); keyval_free(&$1); }
    | DECLARED_FUNC { $$ = savestring($1.name); }
    ;

proposed_funcname: IDENT { $$ = $1; }
    | maybe_bad_funcname {
            char *vname;
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                vname = savefmt("%s%s::%s", VAR_PREFIX, ns, $1);
            } else {
                vname = savefmt("%s%s", VAR_PREFIX, $1);
            }
            if (
                kvmap_get(&global_consts, vname) ||
                kvmap_get(&global_vars, vname) ||
                funclist_find(&funcs_list, vname) ||
                funclist_find(&externs_list, vname)
            ) {
                char *err = savefmt("Indentifier '%s' already declared.", $1);
                yyerror(err);
                free(err);
                YYERROR;
            }
            free(vname);
            $$ = $1;
        }
    ;

maybe_bad_varname:
      DECLARED_VAR { $$ = savestring($1.key); keyval_free(&$1); }
    | DECLARED_CONST { $$ = savestring($1.key); keyval_free(&$1); }
    | DECLARED_FUNC { $$ = savestring($1.name); }
    ;

proposed_varname: IDENT { $$ = $1; }
    | maybe_bad_varname {
            char *vname;
            const char *ns = strlist_top(&namespace_list);
            if (ns && *ns) {
                vname = savefmt("%s%s::%s", VAR_PREFIX, ns, $1);
            } else {
                vname = savefmt("%s%s", VAR_PREFIX, $1);
            }
            if (
                kvmap_get(&global_consts, vname) ||
                kvmap_get(&global_vars, vname) ||
                funclist_find(&funcs_list, vname) ||
                funclist_find(&externs_list, vname)
            ) {
                char *err = savefmt("Indentifier '%s' already declared.", $1);
                yyerror(err);
                free(err);
                YYERROR;
            }
            free(vname);
            $$ = $1;
        }
    ;

ret_count_type:
      VOID { $$ = 0; }
    | SINGLE { $$ = 1; }
    | MULTIPLE { $$ = 99; }
    ;

opt_varargs: /* nothing */ { $$ = 0; }
    | MULT { $$ = 1; }
    ;

argvarlist: /* nothing */ { strlist_init(&$$); }
    | proposed_varname {
            char *vname = decl_new_variable($1);
            if (!vname) {
                char *err = savefmt("Indentifier '%s' already declared.", $1);
                yyerror(err);
                free(err);
                YYERROR;
            }
            strlist_init(&$$);
            strlist_add(&$$, vname);
            free(vname);
            free($1);
        }
    | argvarlist ',' proposed_varname {
            char *vname = decl_new_variable($3);
            if (!vname) {
                char *err = savefmt("Indentifier '%s' already declared.", $3);
                yyerror(err);
                free(err);
                YYERROR;
            }
            $$ = $1;
            strlist_add(&$$, vname);
            free(vname);
            free($3);
        }
    ;

su: /* nothing */ { /* scope up */ kvmaplist_add(&scoping_consts); kvmaplist_add(&scoping_vars); } ;

sd: /* nothing */ { /* scope down */ kvmaplist_pop(&scoping_consts); kvmaplist_pop(&scoping_vars); } ;

simple_statement:
      RETURN { $$ = savestring("0 exit"); }
    | RETURN expr { $$ = savefmt("%s exit", $2); free($2); }
    | BREAK { $$ = savestring("break"); }
    | CONTINUE { $$ = savestring("continue"); }
    | expr {
            if (!*$1) {
                $$ = savestring("");
            } else {
                char *out;
                struct optims_t {
                    const char *pat;
                    const char *repl;
                } optims[] = {
                    {"0 pop",           ""},
                    {"1 pop",           ""},
                    {"dup %1 ! pop",    "%1 !"},
                    {"%1 ! %1 @",       "dup %1 !"},
                    {"%1 @ %1 @ %1 @",  "%1 @ dup dup"},
                    {"%1 @ %1 @",       "%1 @ dup"},

                    {"%1 @ ++ dup %1 ! pop",  "%1 ++"},
                    {"%1 @ -- dup %1 ! pop",  "%1 --"},
                    {"%1 @ dup ++ %1 ! pop",  "%1 ++"},
                    {"%1 @ dup -- %1 ! pop",  "%1 --"},
                    {"%1 @ ++ dup %1 !",      "%1 ++ %1 @"},
                    {"%1 @ -- dup %1 !",      "%1 -- %1 @"},

                    {"dup 4 rotate 4 rotate ->[] %1 ! pop",              "rot rot ->[] %1 !"},
                    {"dup 4 rotate 4 rotate array_nested_set %1 ! pop",  "rot rot array_nested_set %1 !"},

                    {NULL, NULL}
                };
                out = savefmt("%s pop", $1);
                if (do_optimize) {
                    int i;
                    for (i = 0; optims[i].pat; i++) {
                        char *tmp = replace_words(out, optims[i].pat, optims[i].repl);
                        free(out);
                        out = tmp;
                    }
                }
                $$ = out;
            }
            free($1);
        }
    ;

statement: ';' { $$ = savestring(""); }
    | simple_statement ';' { $$ = $1; }
    | simple_statement IF paren_expr ';' {
            char *body = wrapit("if", $1, "then");
            $$ = appendstr(savestring($3), body, NULL);
            free($1); free($3);
            free(body);
        }
    | simple_statement UNLESS paren_expr ';' {
            char *body = wrapit("not if", $1, "then");
            $$ = appendstr(savestring($3), body, NULL);
            free($1); free($3);
            free(body);
        }
    | CONST proposed_varname ASGN expr ';' {
            $$ = savestring("");
            kvmap *m = kvmaplist_top(&scoping_consts);
            kvmap_add(m, $2, $4);
            free($2); free($4);
        }
    | IF paren_expr statement  %prec BARE {
            char *pfx = savefmt("%s if", $2);
            $$ = wrapit(pfx, $3, "then");
            free(pfx);
            free($2); free($3);
        }
    | IF paren_expr statement ELSE statement {
            char *pfx = savefmt("%s if", $2);
            $$ = wrapit2(pfx, $3, "else", $5, "then");
            free(pfx);
            free($2); free($3); free($5);
        }
    | WHILE su paren_expr statement sd {
            if (!strcmp($3, "1")) {
                $$ = wrapit("begin", $4, "repeat");
            } else {
                $$ = wrapit2("begin", $3, "while", $4, "repeat");
            }
            free($3); free($4);
        }
    | UNTIL su paren_expr statement sd {
            if (!strcmp($3, "0")) {
                $$ = wrapit("begin", $4, "repeat");
            } else {
                $3 = appendstr($3, "not", NULL);
                $$ = wrapit2("begin", $3, "while", $4, "repeat");
            }
            free($3); free($4);
        }
    | DO su statement WHILE paren_expr sd ';' {
            if (!strcmp($5, "1")) {
                $$ = wrapit("begin", $3, "repeat");
            } else {
                $3 = appendstr($3, $5, "not", NULL);
                $$ = wrapit("begin", $3, "until");
            }
            free($3); free($5);
        }
    | DO su statement UNTIL paren_expr sd ';' {
            if (!strcmp($5, "0")) {
                $$ = wrapit("begin", $3, "repeat");
            } else {
                $3 = appendstr($3, $5, NULL);
                $$ = wrapit("begin", $3, "until");
            }
            free($3); free($5);
        }
    | FOR '(' su settable IN expr KEYVAL expr ')' statement sd {
            char *pfx = appendstr(NULL, $6, $8, "1", "for", NULL);
            char *body = appendstr(NULL, $4, "\n", $10, NULL);
            $$ = wrapit(pfx, body, "repeat");
            free(body);
            free(pfx);
            free($4); free($6); free($8); free($10);
        }
    | FOR '(' su settable IN expr KEYVAL expr BY expr ')' statement sd {
            char *pfx = appendstr(NULL, $6, $8, $10, "for", NULL);
            char *body = appendstr(NULL, $4, "\n", $12, NULL);
            $$ = wrapit(pfx, body, "repeat");
            free(body);
            free(pfx);
            free($4); free($6); free($8); free($10);
        }
    | FOR '(' su settable IN expr ')' statement sd {
            char *pfx = appendstr(NULL, $6, "foreach", NULL);
            char *ind = appendstr(NULL, $4, "pop\n", $8, NULL);
            $$ = wrapit(pfx, ind, "repeat");
            free(ind);
            free(pfx);
            free($4); free($6); free($8);
        }
    | FOR '(' su settable KEYVAL settable IN expr ')' statement sd {
            char *pfx = appendstr(NULL, $8, "foreach", NULL);
            char *ind = appendstr(NULL, $6, $4, "\n", $10, NULL);
            $$ = wrapit(pfx, ind, "repeat");
            free(ind);
            free(pfx);
            free($4); free($6); free($8); free($10);
        }
    | TRY statement CATCH '(' ')' statement {
            $$ = wrapit2("0 try", $2, "catch pop", $6, "endcatch");
            free($2); free($6);
        }
    | TRY statement CATCH '(' su lvalue ')' statement sd {
            char *mid = savefmt("catch_detailed %s", $6.set);
            $$ = wrapit2("0 try", $2, mid, $8, "endcatch");
            free(mid);
            free($2); getset_free(&$6); free($8);
        }
    | SWITCH '(' expr using_clause ')' '{' case_clauses default_clause '}' {
            $3 = appendstr($3, "\n", $7, $8, NULL);
            $$ = wrapit("0 begin pop (switch)", $3, "repeat pop");
            strlist_pop(&using_list);
            free($3); free($4); free($7); free($8);
        }
    | '{' su statements sd '}' { $$ = $3; }
    ;

using_clause: /* nothing */ { $$ = savestring("="); strlist_add(&using_list, $$); }
    | USING MUF '(' STR ')' { $$ = savestring($4); strlist_add(&using_list, $$); free($4); }
    | USING EQEQ { $$ = savestring("="); strlist_add(&using_list, $$); }
    | USING NEQ { $$ = savestring("= not"); strlist_add(&using_list, $$); }
    | USING LT { $$ = savestring("<"); strlist_add(&using_list, $$); }
    | USING LTE { $$ = savestring("<="); strlist_add(&using_list, $$); }
    | USING GT { $$ = savestring(">"); strlist_add(&using_list, $$); }
    | USING GTE { $$ = savestring(">="); strlist_add(&using_list, $$); }
    | USING STREQ { $$ = savestring("strcmp not"); strlist_add(&using_list, $$); }
    | USING IN { $$ = savestring("swap array_findval"); strlist_add(&using_list, $$); }
    | USING DECLARED_FUNC {
            if ($2.expects != 2) {
                yyerror("Using clause expects instruction or function that takes 2 args.");
                YYERROR;
            }
            $$ = savestring($2.code);
            if (!strcmp($$, "stringcmp")) {
                strlist_add(&using_list, "stringcmp not");
            } else if (!strcmp($$, "strcmp")) {
                strlist_add(&using_list, "strcmp not");
            } else {
                strlist_add(&using_list, $2.code);
            }
        }
    ;

case_clauses: case_clause { $$ = $1; }
    | case_clauses case_clause { $$ = savefmt("%s%s", $1, $2); free($1); free($2); }
    ;

case_clause: CASE paren_expr statement {
        char *pfx = appendstr(NULL, "dup", $2, using_list.list[using_list.count-1], "if", NULL);
        $3 = appendstr($3, "break", NULL);
        $$ = wrapit(pfx, $3, "then\n");
        free(pfx);
        free($2); free($3);
    } ;

default_clause: /* nothing */ { $$ = savestring("break"); }
    | DEFAULT statement { $$ = savefmt("(default)\n%s break", $2); free($2); }
    ;

paren_expr: '(' expr ')' { $$ = $2; } ;

statements: /* nothing */ { $$ = savestring(""); }
    | statements statement {
            $$ = savestring($1);
            if (*$$ && *$2) {
                $$ = appendstr($$, "\n", NULL);
            }
            if (debugging_level > 0) {
                $$ = appendfmt($$, "\"%s:%d\" pop\n", yyfilename, yylineno);
            }
            $$ = appendfmt($$, "%s", $2);
        }
    ;

function_call: DECLARED_FUNC '(' arglist_or_null ')' {
        char *basecall;
        if ($1.hasvarargs) {
            if ($3.count < $1.expects) {
                char *err = savefmt(
                    "Function '%s' expects at least %d args, but was provided %d args.",
                    $1.name, $1.expects, $3.count
                );
                yyerror(err);
                strlist_free(&$3);
                free(err);
                YYERROR;
            }
        } else {
            if ($3.count != $1.expects) {
                char *err = savefmt(
                    "Function '%s' expects %d args, but was provided %d args.",
                    $1.name, $1.expects, $3.count
                );
                yyerror(err);
                strlist_free(&$3);
                free(err);
                YYERROR;
            }
        }
        if ($1.hasvarargs) {
            char *vargs = strlist_wrap(&$3, $1.expects, -1);
            char *vlist = wrapit("{", vargs, "}list");
            basecall = appendstr(strlist_wrap(&$3, 0, $1.expects), vlist, $1.code, NULL);
            free(vlist);
            free(vargs);
        } else {
            basecall = appendstr(strlist_wrap(&$3, 0, -1), $1.code, NULL);
        }
        if ($1.returns == 0) {
            $$ = savefmt("%s 0", basecall);
        } else if ($1.returns == 1) {
            $$ = savestring(basecall);
        } else {
            $$ = wrapit("{", basecall, "}list");
        }
        free(basecall);
        strlist_free(&$3);
    } ;

lvalue: IDENT {
            char *errstr = savefmt("Undeclared identifier '%s'.", $1);
            yyerror(errstr);
            free(errstr);
            YYERROR;
        }
    | VAR proposed_varname {
            char *vname = decl_new_variable($2);
            if (!vname) {
                char *err = savefmt("Indentifier '%s' already declared at this scope level.", $2);
                yyerror(err);
                free(err);
                YYERROR;
            }
            $$.get = savestring("");
            $$.set = savefmt("%s !", vname);
            $$.del = savefmt("0 %s !", vname);
            $$.oper_pre = savestring("0");
            $$.oper_post = savefmt("%s !", vname);
            $$.call = savestring("");
            free(vname);
        }
    | DECLARED_VAR  %prec BARE {
            $$.get = savefmt("%s @", $1.val);
            $$.set = savefmt("%s !", $1.val);
            $$.del = savefmt("0 %s !", $1.val);
            $$.oper_pre = savefmt("%s @", $1.val);
            $$.oper_post = savefmt("%s !", $1.val);
            $$.call = savefmt("%s\ndup address? if\n    execute\nelse\n    } popn \"Tried to execute a non-address in %s:%d\" abort\nthen", $$.get, yyfilename, yylineno);
            keyval_free(&$1);
        }
    | DECLARED_VAR index_parts  %prec SUFFIX {
            char *idx = strlist_wrap(&$2, 0, -1);
            char *idxlist = strlist_wrapit("{", &$2, "}list");
            if ($2.count == 1) {
                $$.get = savefmt("%s @ %s []", $1.val, idx);
                $$.set = savefmt("%s @ %s ->[] %s !", $1.val, idx, $1.val);
                $$.del = savefmt("%s @ %s array_delitem %s !", $1.val, idx, $1.val);
                $$.oper_pre = savefmt("%s @ %s over over []", $1.val, idx);
                $$.oper_post = savefmt("4 rotate 4 rotate ->[] %s !", $1.val);
            } else {
                $$.get = savefmt("%s @ %s array_nested_get", $1.val, idxlist);
                $$.set = savefmt("%s @ %s array_nested_set %s !", $1.val, idxlist, $1.val);
                $$.del = savefmt("%s @ %s array_nested_del %s !", $1.val, idxlist, $1.val);
                $$.oper_pre = savefmt("%s @ %s over over array_nested_get", $1.val, idxlist);
                $$.oper_post = savefmt("4 rotate 4 rotate array_nested_set %s !", $1.val);
            }
            $$.call = savefmt("%s\ndup address? if\n    execute\nelse\n    } popn \"Tried to execute a non-address in %s:%d\" abort\nthen", $$.get, yyfilename, yylineno);
            free(idx);
            free(idxlist);
            keyval_free(&$1);
            strlist_free(&$2);
        }
    ;

settable: lvalue { $$ = savestring($1.set); getset_free(&$1); }
    | LT tuple_parts GT {
            int i;
            if (debugging_level) {
                if (!has_tuple_check) {
                    if (outf) {
                        fprintf(outf, "%s", tuple_check);
                    }
                    has_tuple_check = 1;
                }
                $$ = savefmt("dup %d \"%s:%d\" tuple_check", $2.count, yyfilename, yylineno);
            } else {
                $$ = savestring("");
            }
            for (i = 0; i < $2.count; i++) {
                $$ = appendfmt($$, "dup %d [] %s", i, $2.list[i]);
            }
            $$ = appendstr($$, "pop", NULL);
            strlist_free(&$2);
        };

tuple_parts: lvalue {
            strlist_init(&$$);
            strlist_add(&$$, $1.set);
            getset_free(&$1);
        }
    | tuple_parts ',' lvalue {
            $$ = $1;
            strlist_add(&$$, $3.set);
            getset_free(&$3);
        }
    ;

index_parts:
      subscript { strlist_init(&$$); strlist_add(&$$, $1); free($1); }
    | attribute { strlist_init(&$$); strlist_add(&$$, $1); free($1); }
    | index_parts subscript { $$ = $1; strlist_add(&$$, $2); free($2); }
    | index_parts attribute { $$ = $1; strlist_add(&$$, $2); free($2); }
    ;

subscript: '[' expr ']' { $$ = $2; } ;

attribute: DOT IDENT     { $$ = format_muv_str($2);     free($2); }
    | DOT DECLARED_CONST { $$ = format_muv_str($2.key); keyval_free(&$2); }
    | DOT DECLARED_VAR   { $$ = format_muv_str($2.key); keyval_free(&$2); }
    | DOT DECLARED_FUNC  { $$ = format_muv_str($2.name); }
    ;

compr_cond: /* nothing */ { $$ = savestring(""); }
    | IF paren_expr {
            $$ = appendstr(NULL, $2, "if", NULL);
            free($2);
        }
    | UNLESS paren_expr {
            $$ = appendstr(NULL, $2, "not", "if", NULL);
            free($2);
        }
    ;

compr_loop:
      '(' settable IN expr KEYVAL expr ')' {
            char *ind = indent($2);
            $$ = appendstr(NULL, $4, $6, "1", "for\n", ind, NULL);
            free(ind);
            free($2); free($4); free($6);
        }
    | '(' settable IN expr KEYVAL expr BY expr ')' {
            char *ind = indent($2);
            $$ = appendstr(NULL, $4, $6, $8, "for\n", ind, NULL);
            free(ind);
            free($2); free($4); free($6);
        }
    | '(' settable IN expr ')' {
            char *ind = indent($2);
            $$ = appendstr(NULL, $4, "foreach\n", ind, "pop", NULL);
            free(ind);
            free($2); free($4);
        }
    | '(' settable KEYVAL settable IN expr ')' {
            char *set = appendstr(NULL, $4, $2, NULL);
            char *iset = indent(set);
            $$ = appendstr(NULL, $6, "foreach\n", iset, NULL);
            free(iset); free(set);
            free($2); free($4); free($6);
        }
    ;

expr: paren_expr { $$ = $1; }
    | INTEGER { $$ = savefmt("%d", $1); }
    | FLOAT { $$ = $1; }
    | STR { $$ = format_muv_str($1); free($1); }
    | '#' MINUS INTEGER { $$ = savefmt("#-%d", $3); }
    | '#' INTEGER { $$ = savefmt("#%d", $2); }
    | DECLARED_CONST { $$ = savestring($1.val); keyval_free(&$1); }
    | lvalue  %prec BARE { $$ = savestring($1.get); getset_free(&$1); }
    | lvalue '(' arglist_or_null ')'  %prec SUFFIX {
            char *body = appendstr(strlist_wrap(&$3, 0, -1), $1.call, NULL);
            $$ = appendstr(wrapit("{", body, "}list"), "dup array_count", "2 < if 0 [] then", NULL);
            free(body);
            getset_free(&$1);
            strlist_free(&$3);
        }
    | function_call { $$ = $1; }
    | TOP { $$ = savestring(""); }
    | PUSH '(' arglist ')' { strlist_add(&$3, "dup"), $$ = strlist_wrap(&$3, 0, -1); strlist_free(&$3); }
    | MUF '(' STR ')' { $$ = $3; }
    | DEL '(' lvalue ')' { $$ = savefmt("%s 0", $3.del); getset_free(&$3); }
    | FMTSTRING '(' arglist ')' {
            const char *ptr = $3.list[0];
            int expect = 0;
            while (*ptr) {
                if (*ptr == '%') {
                    ptr++;
                    if (!*ptr) {
                        break;
                    }
                    if (*ptr != '%') {
                        expect++;
                    }
                }
                ptr++;
            }
            if ($3.count != expect+1) {
                char *err = savefmt("fmtstring(fmt ...) format string expects %d args, but got %d.", expect, $3.count-1);
                yyerror(err);
                free(err);
                YYERROR;
            }
            strlist_reverse(&$3);
            $$ = appendstr(strlist_wrap(&$3, 0, -1), "fmtstring", NULL);
            strlist_free(&$3);
        }
    | expr '?' expr ':' expr { $$ = savefmt("%s if %s else %s then", $1, $3, $5); free($1); free($3); free($5); }
    | expr '[' expr ']' { $$ = savefmt("%s %s []", $1, $3); free($1); free($3); }
    | APPEND { $$ = savestring("{ }list"); }
    | '[' arglist_or_null ']' { $$ = strlist_wrapit("{", &$2, "}list"); strlist_free(&$2); }
    | '[' FOR compr_loop compr_cond expr ']' {
            /* list comprehension */
            char *body = appendstr(NULL, $5, "swap []<-", NULL);
            char *pfx;
            if (*$4) {
                char *cond = wrapit($4, body, "then");
                free(body);
                body = cond;
            }
            pfx = appendstr(NULL, "{ }list", $3, NULL);
            $$ = wrapit(pfx, body, "repeat");
            free(pfx);
            free(body);
            free($3); free($4); free($5);
        }
    | '[' dictlist ']' {
            /* dictionary initializer */
            if ($2.count == 0) {
                $$ = savestring("{ }dict");
            } else {
                $$ = strlist_wrapit("{", &$2, "}dict");
            }
            strlist_free(&$2);
        }
    | '[' FOR compr_loop compr_cond expr KEYVAL expr ']' {
            /* dictionary comprehension */
            char *body = appendstr(NULL, $7, "swap", $5, "->[]", NULL);
            char *pfx;
            if (*$4) {
                char *cond = wrapit($4, body, "then");
                free(body);
                body = cond;
            }
            pfx = appendstr(NULL, "{ }dict", $3, NULL);
            $$ = wrapit(pfx, body, "repeat");
            free(pfx); free(body);
            free($3); free($4); free($5); free($7);
        }
    | PLUS   expr  %prec UNARY { $$ = $2; }
    | MINUS  expr  %prec UNARY { if (isint($2)) $$ = savefmt("-%s", $2); else $$ = savefmt("0 %s -", $2); free($2); }
    | NOT    expr  %prec UNARY { $$ = appendstr(NULL, $2, "not", NULL); free($2); }
    | BITNOT expr  %prec UNARY { $$ = appendstr(NULL, $2, "-1", "bitxor", NULL); free($2); }
    | BITAND DECLARED_FUNC  %prec UNARY { $$ = savefmt("'%s%s", FUNC_PREFIX, $2.name); }
    | expr PLUS expr {
            if (!strcmp($3, "1")) {
                $$ = appendstr(NULL, $1, "++", NULL);
            } else {
                $$ = appendstr(NULL, $1, $3, "+", NULL);
            }
            free($1); free($3);
        }
    | expr MINUS expr {
            if (!strcmp($3, "1")) {
                $$ = appendstr(NULL, $1, "--", NULL);
            } else {
                $$ = appendstr(NULL, $1, $3, "-", NULL);
            }
            free($1); free($3);
        }
    | expr MULT expr  { $$ = appendstr(NULL, $1, $3, "*", NULL); free($1); free($3); }
    | expr DIV expr   { $$ = appendstr(NULL, $1, $3, "/", NULL); free($1); free($3); }
    | expr MOD expr   { $$ = appendstr(NULL, $1, $3, "%", NULL); free($1); free($3); }
    | expr IN expr    { $$ = appendstr(NULL, $3, $1, "array_findval", NULL); free($1); free($3); }
    | expr EQEQ expr  { $$ = appendstr(NULL, $1, $3, "=", NULL); free($1); free($3); }
    | expr NEQ expr   { $$ = appendstr(NULL, $1, $3, "= not", NULL); free($1); free($3); }
    | expr STREQ expr { $$ = appendstr(NULL, $1, $3, "strcmp", "not", NULL); free($1); free($3); }
    | expr LT expr    { $$ = appendstr(NULL, $1, $3, "<", NULL); free($1); free($3); }
    | expr GT expr    { $$ = appendstr(NULL, $1, $3, ">", NULL); free($1); free($3); }
    | expr LTE expr   { $$ = appendstr(NULL, $1, $3, "<=", NULL); free($1); free($3); }
    | expr GTE expr   { $$ = appendstr(NULL, $1, $3, ">=", NULL); free($1); free($3); }
    | expr AND expr {
            char *body = wrapit("dup if pop", $3, "then");
            $$ = appendstr(NULL, $1, body, 0);
            free(body); free($1); free($3);
        }
    | expr OR expr {
            char *body = wrapit("dup not if pop", $3, "then");
            $$ = appendstr(NULL, $1, body, 0);
            free(body); free($1); free($3);
        }
    | expr XOR expr      { $$ = appendstr(NULL, $1, $3, "xor", NULL); free($1); free($3); }
    | expr BITOR expr    { $$ = appendstr(NULL, $1, $3, "bitor", NULL); free($1); free($3); }
    | expr BITXOR expr   { $$ = appendstr(NULL, $1, $3, "bitxor", NULL); free($1); free($3); }
    | expr BITAND expr   { $$ = appendstr(NULL, $1, $3, "bitand", NULL); free($1); free($3); }
    | expr BITLEFT expr  { $$ = appendstr(NULL, $1, $3, "bitshift", NULL); free($1); free($3); }
    | expr BITRIGHT expr { $$ = appendstr(NULL, $1, "0", $3, "-", "bitshift", NULL); free($1); free($3); }
    | settable ASGN expr { $$ = appendstr(NULL, $3, "dup", $1, NULL); free($1); free($3); }
    | lvalue APPEND ASGN expr { $$ = appendstr(NULL, $1.oper_pre, $4, "swap", "[]<-", "dup", $1.oper_post, NULL); getset_free(&$1); }
    | lvalue PLUSASGN expr {
            if (!strcmp($3, "1")) {
                $$ = appendstr(NULL, $1.oper_pre, "++ dup", $1.oper_post, NULL);
            } else {
                $$ = appendstr(NULL, $1.oper_pre, $3, "+ dup", $1.oper_post, NULL);
            }
            getset_free(&$1); free($3);
        }
    | lvalue MINUSASGN expr {
            if (!strcmp($3, "1")) {
                $$ = appendstr(NULL, $1.oper_pre, "-- dup", $1.oper_post, NULL);
            } else {
                $$ = appendstr(NULL, $1.oper_pre, $3, "- dup", $1.oper_post, NULL);
            }
            getset_free(&$1); free($3);
        }
    | lvalue MULTASGN expr     { $$ = appendstr(NULL, $1.oper_pre, $3, "* dup",         $1.oper_post, NULL); getset_free(&$1); free($3); }
    | lvalue DIVASGN expr      { $$ = appendstr(NULL, $1.oper_pre, $3, "/ dup",         $1.oper_post, NULL); getset_free(&$1); free($3); }
    | lvalue MODASGN expr      { $$ = appendstr(NULL, $1.oper_pre, $3, "% dup",         $1.oper_post, NULL); getset_free(&$1); free($3); }
    | lvalue BITORASGN expr    { $$ = appendstr(NULL, $1.oper_pre, $3, "bitor dup",     $1.oper_post, NULL); getset_free(&$1); free($3); }
    | lvalue BITXORASGN expr   { $$ = appendstr(NULL, $1.oper_pre, $3, "bitxor dup",    $1.oper_post, NULL); getset_free(&$1); free($3); }
    | lvalue BITANDASGN expr   { $$ = appendstr(NULL, $1.oper_pre, $3, "bitand dup",    $1.oper_post, NULL); getset_free(&$1); free($3); }
    | lvalue BITLEFTASGN expr  { $$ = appendstr(NULL, $1.oper_pre, $3, "bitshift dup",  $1.oper_post, NULL); getset_free(&$1); free($3); }
    | lvalue BITRIGHTASGN expr { $$ = appendstr(NULL, $1.oper_pre, $3, "0 swap - bitshift dup", $1.oper_post, NULL); getset_free(&$1); free($3); }
    | lvalue INCR              { $$ = appendstr(NULL, $1.oper_pre, "dup ++", $1.oper_post, NULL); getset_free(&$1); }
    | lvalue DECR              { $$ = appendstr(NULL, $1.oper_pre, "dup --", $1.oper_post, NULL); getset_free(&$1); }
    | INCR lvalue  %prec UNARY { $$ = appendstr(NULL, $2.oper_pre, "++ dup", $2.oper_post, NULL); getset_free(&$2); }
    | DECR lvalue  %prec UNARY { $$ = appendstr(NULL, $2.oper_pre, "-- dup", $2.oper_post, NULL); getset_free(&$2); }
    ;

arglist_or_null: /* nothing */ { strlist_init(&$$); }
    | arglist { $$ = $1; }
    ;

arglist: expr { strlist_init(&$$); strlist_add(&$$, $1); free($1); }
    | arglist ',' expr { $$ = $1;  strlist_add(&$$, $3); free($3); }
    ;

dictlist: KEYVAL { strlist_init(&$$); }
    | expr KEYVAL expr {
            char *vals = savefmt("%s %s", $1, $3);
            strlist_init(&$$);
            strlist_add(&$$, vals);
            free(vals);
            free($1); free($3);
        }
    | dictlist ',' expr KEYVAL expr {
            char *vals = savefmt("%s %s", $3, $5);
            $$ = $1;
            strlist_add(&$$, vals);
            free(vals);
            free($3); free($5);
        }
    ;

%%



int
bookmark_push(const char *fname)
{
    char buf[1024];
    const char *ptr, *dirmk;
    char *ptr2;
    char *dir, *fil;
    FILE *f;

    /* If file to include starts with '!', it's a global include file. */
    if (*fname == '!') {
        fname++;
        snprintf(buf, sizeof(buf), "%s/", includes_dir);
    } else if (*fname != '/') {
        snprintf(buf, sizeof(buf), "%s/", yydirname);
    }

    /* find last '/' in path to file */
    for (ptr = dirmk = fname; *ptr; ptr++) {
        if (*ptr == '/') {
            dirmk = ptr;
        }
    }
    while (dirmk > fname && dirmk[-1] == '/')
        dirmk--;

    ptr = fname;
    ptr2 = buf;
    ptr2 += strlen(buf);
    while (ptr < dirmk)
        *ptr2++ = *ptr++;
    *ptr2 = '\0';
    dir = savestring(buf);

    while (*dirmk == '/')
        dirmk++;
    ptr2 = buf;
    while (*dirmk)
        *ptr2++ = *dirmk++;
    *ptr2 = '\0';
    fil = savestring(buf);

    if (*yyfilename) {
        snprintf(buf, sizeof(buf), "%s/%s", dir, fil);
    }

    if (kvmap_get(&included_files, buf)) {
        free(dir);
        free(fil);
        return 1;
    }

    f = *fil? fopen(buf, "r") : stdin;
    if (!f) {
        char *errstr = savefmt("Could not include file %s", buf);
        yyerror(errstr);
        free(errstr);
        free(dir);
        free(fil);
        return 0;
    }

    if (bookmark_count >= MAX_INCLUDE_LEVELS-1) {
        yyerror("Too many levels of includes!");
        free(dir);
        free(fil);
        return 0;
    }

    kvmap_add(&included_files, buf, buf);

    bookmarks[bookmark_count].dname = savestring(yydirname);
    bookmarks[bookmark_count].fname = savestring(yyfilename);
    bookmarks[bookmark_count].lineno = yylineno;
    if (yyin) {
        bookmarks[bookmark_count].pos = ftell(yyin);
    } else {
        bookmarks[bookmark_count].pos = 0;
    }
    bookmark_count++;

    if (yyin != NULL) {
        fclose(yyin);
    }
    yydirname = dir;
    yyfilename = fil;
    yyin = *yyfilename? f : stdin;
    yylineno = 1;

    return 1;
}


int
bookmark_pop()
{
    long pos;

    if (bookmark_count < 1) {
        return 0;
    }
    free((void*)yydirname);
    free((void*)yyfilename);
    bookmark_count--;
    yydirname = bookmarks[bookmark_count].dname;
    yyfilename = bookmarks[bookmark_count].fname;
    yylineno = bookmarks[bookmark_count].lineno;
    pos = bookmarks[bookmark_count].pos;

    fclose(yyin);
    if (*yyfilename) {
        char *fnam = savefmt("%s/%s", yydirname, yyfilename);
        yyin = fopen(fnam, "r");
        free(fnam);
        fseek(yyin, pos, SEEK_SET);
    } else {
        yyin = stdin;
    }

    return 1;
}


void
setyyinput(FILE *f)
{
    yyin = f;
}



static int
lookup(char *s, int *bval)
{
    int start = 0;
    int ret;

    static struct kwordz{
        char *kw;
        int rval;
        int bltin;  /* # of builtin if builtin */
    } keyz[] = {
        /* MUST BE IN LEXICAL SORT ORDER !!!!!! */
        {"$author",      D_AUTHOR,      -1},
        {"$echo",        D_ECHO,        -1},
        {"$error",       D_ERROR,       -1},
        {"$include",     D_INCLUDE,     -1},
        {"$language",    D_LANGUAGE,    -1},
        {"$libversion",  D_LIBVERSION,  -1},
        {"$note",        D_NOTE,        -1},
        {"$pragma",      D_PRAGMA,      -1},
        {"$version",     D_VERSION,     -1},
        {"$warn",        D_WARN,        -1},
        {"break",        BREAK,         -1},
        {"by",           BY,            -1},
        {"case",         CASE,          -1},
        {"catch",        CATCH,         -1},
        {"const",        CONST,         -1},
        {"continue",     CONTINUE,      -1},
        {"default",      DEFAULT,       -1},
        {"del",          DEL,           -1},
        {"do",           DO,            -1},
        {"else",         ELSE,          -1},
        {"eq",           STREQ,         -1},
        {"extern",       EXTERN,        -1},
        {"fmtstring",    FMTSTRING,     -1},
        {"for",          FOR,           -1},
        {"func",         FUNC,          -1},
        {"if",           IF,            -1},
        {"in",           IN,            -1},
        {"include",      INCLUDE,       -1},
        {"muf",          MUF,           -1},
        {"multiple",     MULTIPLE,      -1},
        {"namespace",    NAMESPACE,     -1},
        {"public",       PUBLIC,        -1},
        {"push",         PUSH,          -1},
        {"return",       RETURN,        -1},
        {"single",       SINGLE,        -1},
        {"switch",       SWITCH,        -1},
        {"top",          TOP,           -1},
        {"try",          TRY,           -1},
        {"unless",       UNLESS,        -1},
        {"until",        UNTIL,         -1},
        {"using",        USING,         -1},
        {"var",          VAR,           -1},
        {"void",         VOID,          -1},
        {"while",        WHILE,         -1},
        {NULL, 0, 0}
    };

    int end = (sizeof(keyz) / sizeof(struct kwordz)) - 2;
    int p = end / 2;

    *bval = -1;
    while (start <= end) {
        ret = strcmp(s, keyz[p].kw);
        if (ret == 0) {
            *bval = keyz[p].bltin;
            return(keyz[p].rval);
        }
        if (ret > 0) {
            start = p + 1;
        } else {
            end = p - 1;
        }
        p = start + ((end - start)/2);
    }
    return(-1);
}


const char *
lookup_namespaced_keyval(kvmap *m, const char *name)
{
    char full[MAX_IDENT_LEN];
    const char *ns;
    const char *cp;
    char *p;
    int i;
    for (i = namespaces_active.count; i-->0; ) {
        ns = namespaces_active.list[i];
        snprintf(full, sizeof(full), "%s::%s", ns, name);
        cp = kvmap_get(m, full);
        if (cp) {
            return cp;
        }
        for (p = full; *p; p++) {
            if (*p == ':') *p = '_';
        }
        cp = kvmap_get(m, full);
        if (cp) {
            return cp;
        }
    }
    for (i = namespace_list.count; i-->0; ) {
        ns = namespace_list.list[i];
        snprintf(full, sizeof(full), "%s::%s", ns, name);
        cp = kvmap_get(m, full);
        if (cp) {
            return cp;
        }
        for (p = full; *p; p++) {
            if (*p == ':') *p = '_';
        }
        cp = kvmap_get(m, full);
        if (cp) {
            return cp;
        }
    }
    snprintf(full, sizeof(full), "%s", name);
    cp = kvmap_get(m, full);
    if (cp) {
        return cp;
    }
    for (p = full; *p; p++) {
        if (*p == ':') *p = '_';
    }
    cp = kvmap_get(m, full);
    return cp;
}


funcinfo *
lookup_namespaced_func(funclist *l, const char *name)
{
    char full[MAX_IDENT_LEN];
    funcinfo *cp;
    const char *ns;
    char *p;
    int i;
    for (i = namespaces_active.count; i-->0; ) {
        ns = namespaces_active.list[i];
        snprintf(full, sizeof(full), "%s::%s", ns, name);
        cp = funclist_find(l, full);
        if (cp) {
            return cp;
        }
        for (p = full; *p; p++) {
            if (*p == ':') *p = '_';
        }
        cp = funclist_find(l, full);
        if (cp) {
            return cp;
        }
    }
    for (i = namespace_list.count; i-->0; ) {
        ns = namespace_list.list[i];
        snprintf(full, sizeof(full), "%s::%s", ns, name);
        cp = funclist_find(l, full);
        if (cp) {
            return cp;
        }
        for (p = full; *p; p++) {
            if (*p == ':') *p = '_';
        }
        cp = funclist_find(l, full);
        if (cp) {
            return cp;
        }
    }
    snprintf(full, sizeof(full), "%s", name);
    cp = funclist_find(l, full);
    if (cp) {
        return cp;
    }
    for (p = full; *p; p++) {
        if (*p == ':') *p = '_';
    }
    cp = funclist_find(l, full);
    return cp;
}


char*
decl_new_variable(const char *name)
{
    int i;
    char *vname;
    kvmap *m = kvmaplist_top(&scoping_vars);
    if (kvmap_get(m, name)) {
        return NULL;  /* Already declared at this scope! */
    }
    for (i = 1; i < 99; i++) {
        if (i > 1) {
            vname = savefmt("%s%s%d", VAR_PREFIX, name, i);
        } else {
            vname = savefmt("%s%s", VAR_PREFIX, name);
        }
        if (!kvmap_get(&scoping_vars_used, vname)) {
            char *vardecl = savefmt("var %s", vname);
            strlist_add(&vardecl_list, vardecl);
            free(vardecl);
            kvmap_add(m, name, vname);
            kvmap_add(&scoping_vars_used, vname, name);
            return vname;
        }
        free(vname);
    }
    return NULL;
}


int
yylex()
{
    char in[MAX_STR_LEN];
    char *p = in;
    int c, digit;
    int str_is_raw = 0;
    funcinfo* pinfo;
    short base = 10;

    do {
        /* skip whitespace */
        while (isspace(c = fgetc(yyin))) {
            if (c == '\n') {
                yylineno++;
            }
        }

        /* skip comments */
        if (c == '/') {
            c = fgetc(yyin);
            if (c == EOF) {
                return c;
            } else if (c == '/') {
                do {
                    c = fgetc(yyin);
                } while (c != EOF && c != '\n');
                if (c == '\n') {
                    yylineno++;
                }
            } else if (c == '*') {
                do {
                    do {
                        c = fgetc(yyin);
                        if (c == '\n') {
                            yylineno++;
                        }
                    } while (c != EOF && c != '*');
                    c = fgetc(yyin);
                    if (c == '*') {
                        (void)ungetc(c,yyin);
                    } else if (c == '\n') {
                        yylineno++;
                    }
                } while (c != EOF && c != '/');
                if (c == '/') {
                    c = fgetc(yyin);
                }
                if (c == '\n') {
                    yylineno++;
                }
            } else {
                (void)ungetc(c,yyin);
                c = '/';
            }
        }
    } while (isspace(c));

    /* handle EOF */
    if (c == EOF) {
        return c;
    }

    /* save current char - it is valuable */
    *p++ = c;

    /* handle INTEGER */
    if (isdigit(c)) {
        int num;

        if (c == '0') {
            c = fgetc(yyin);
            *p++ = c;
            if (!isdigit(c)) {
                switch (c) {
                    case 'x': base=16; break;
                    case 'd': base=10; break;
                    case 'o': base=8; break;
                    case 'b': base=2; break;
                    case '.': base=10; p--; (void)ungetc(c,yyin); break;
                    default: {
                        (void)ungetc(c,yyin);
                        yylval.num_int = 0;
                        return(INTEGER);
                    }
                }
                c = fgetc(yyin);
                *p++ = c;
            }
        }

        num = 0;
        while(1) {
            char uc;
            if (c == '_') {
                c = fgetc(yyin);
                continue;
            }
            uc = toupper(c);
            if (base == 10 && (uc == '.' || uc == 'E')) {
                break;
            }
            if (uc < '0' || (uc > '9' && uc < 'A') || uc > 'Z') {
                (void)ungetc(c,yyin);
                yylval.num_int = num;
                return(INTEGER);
            }
            if (uc > '9') {
                digit = uc - 'A' + 10;
            } else {
                digit = uc - '0';
            }
            if (digit >= base) {
                (void)ungetc(c,yyin);
                yylval.num_int = num;
                return(INTEGER);
            }
            num = (num * base) + digit;
            c = fgetc(yyin);
            *p++ = c;
        }
        if (c == '.') {
            do {
                c = fgetc(yyin);
                if (c == '_') {
                    continue;
                }
                *p++ = c;
            } while (isdigit(c));
        }
        if (toupper(c) == 'E') {
            c = fgetc(yyin);
            *p++ = c;
            if (c != '+' && c != '-' && !isdigit(c)) {
                *(--p) = '\0';
                (void)ungetc(c,yyin);
                yylval.str = savestring(in);
                return FLOAT;
            }
            do {
                c = fgetc(yyin);
                if (c == '_') {
                    continue;
                }
                *p++ = c;
            } while (isdigit(c));
        }
        *(--p) = '\0';
        (void)ungetc(c,yyin);
        yylval.str = savestring(in);
        return FLOAT;
    }

    if (c == 'r') {
        c = fgetc(yyin);
        if (c == '"' || c == '\'') {
            str_is_raw = 1;
        } else {
            (void)ungetc(c,yyin);
            c = 'r';
        }
    }

    /* handle keywords or idents/builtins */
    if (!str_is_raw && (isalpha(c) || c == '_' || c == '$')) {
        int cnt = 0;
        int rv;
        int bltin;
        const char *cp;

        for (;;) {
            c = fgetc(yyin);
            if (c == EOF) {
                break;
            }
            if (c == ':') {
                c = fgetc(yyin);
                if (c == ':') {
                    *p++ = c;
                    cnt++;
                } else {
                    (void)ungetc(c, yyin);
                    break;
                }
            } else if (!isalnum(c) && c != '_' && c != '?') {
                break;
            }
            if (++cnt + 1 >= MAX_IDENT_LEN) {
                yyerror("Identifier too long.");
            }
            *p++ = c;
        }

        (void)ungetc(c, yyin);

        *p = '\0';

        /* Program flow keywords are inviolate and take priority. */
        if ((rv = lookup(in, &bltin)) != -1) {
            return(rv);
        }

        /* Function local variables */
        cp = kvmaplist_find(&scoping_vars, in);
        if (cp) {
            yylval.keyval.key = savestring(in);
            yylval.keyval.val = savestring(cp);
            return DECLARED_VAR;
        }

        /* Function local constants */
        cp = kvmaplist_find(&scoping_consts, in);
        if (cp) {
            yylval.keyval.key = savestring(in);
            yylval.keyval.val = savestring(cp);
            return DECLARED_CONST;
        }

        /* Global variables */
        cp = lookup_namespaced_keyval(&global_vars, in);
        if (cp) {
            yylval.keyval.key = savestring(in);
            yylval.keyval.val = savestring(cp);
            return DECLARED_VAR;
        }

        /* Global constants */
        cp = lookup_namespaced_keyval(&global_consts, in);
        if (cp) {
            yylval.keyval.key = savestring(in);
            yylval.keyval.val = savestring(cp);
            return DECLARED_CONST;
        }

        /* Functions */
        pinfo = lookup_namespaced_func(&funcs_list, in);
        if (pinfo) {
            yylval.prim = *pinfo;
            return DECLARED_FUNC;
        }

        /* Externs. */
        pinfo = lookup_namespaced_func(&externs_list, in);
        if (pinfo) {
            yylval.prim = *pinfo;
            return DECLARED_FUNC;
        }

        /* If identifier isn't already claimed, return as an undeclared identifier. */
        yylval.str = savestring(in);
        return IDENT;
    }

    /* handle quoted strings */
    if (c == '"' || c == '\'') {
        int cnt = 0;
        int quot = c;
        int triplet = 0;

        /* strip start quote by resetting ptr */
        p = in;

        c = fgetc(yyin);
        if (c == quot) {
            c = fgetc(yyin);
            if (c == quot) {
                triplet = 1;
            } else {
                (void)ungetc(c,yyin);
                (void)ungetc(quot,yyin);
                c = quot;
            }
        } else {
            (void)ungetc(c,yyin);
        }

        /* match quoted strings */
        while ((c = fgetc(yyin)) != EOF) {

            if (c == quot) {
                if (!triplet) {
                    break;
                }
                c = fgetc(yyin);
                if (c == quot) {
                    c = fgetc(yyin);
                    if (c == quot) {
                        break;
                    }
                    (void)ungetc(c,yyin);
                    (void)ungetc(quot,yyin);
                } else {
                    (void)ungetc(c,yyin);
                }
                c = quot;
            }

            if (!isascii(c)) {
                continue;
            }

            if (++cnt + 1 >= sizeof(in)) {
                yyerror("string too long.");
            }

            /* we have to guard the line count */
            if (c == '\n') {
                yylineno++;
            }

            if (!str_is_raw && c == '\\') {
                c = fgetc(yyin);
                switch (c) {
                    case 'n':
                    case 'r':
                        c = '\n';
                        break;
                    case '[':
                    case 'e':
                        c = '\033';
                        break;
                    default:
                        break;
                }
            }
            *p++ = c;
        }

        if (c == EOF) {
            yyerror("EOF in quoted string.");
        }

        *p = '\0';

        yylval.str = savestring(in);
        return(STR);
    }

    switch(c) {
        case '!':
            c = fgetc(yyin);
            if (c == '=') {
                return NEQ;
            } else {
                (void)ungetc(c,yyin);
            }
            return NOT;

        case '%':
            c = fgetc(yyin);
            if (c == '=') {
                return MODASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return MOD;

        case '&':
            c = fgetc(yyin);
            if (c == '&') {
                return AND;
            } else if (c == '=') {
                return BITANDASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return BITAND;

        case '*':
            c = fgetc(yyin);
            if (c == '=') {
                return MULTASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return MULT;

        case '+':
            c = fgetc(yyin);
            if (c == '+') {
                return INCR;
            } else if (c == '=') {
                return PLUSASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return PLUS;

        case '-':
            c = fgetc(yyin);
            if (c == '-') {
                return DECR;
            } else if (c == '=') {
                return MINUSASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return MINUS;

        case '.':
            return DOT;

        case '/':
            c = fgetc(yyin);
            if (c == '=') {
                return DIVASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return DIV;

        case '<':
            c = fgetc(yyin);
            if (c == '<') {
                c = fgetc(yyin);
                if (c == '=') {
                    return BITLEFTASGN;
                } else {
                    (void)ungetc(c,yyin);
                }
                return BITLEFT;
            } else if (c == '=') {
                return LTE;
            } else {
                (void)ungetc(c,yyin);
            }
            return LT;

        case '=':
            c = fgetc(yyin);
            if (c == '=') {
                return EQEQ;
            } else if (c == '>') {
                return KEYVAL;
            } else {
                (void)ungetc(c,yyin);
            }
            return ASGN;

        case '>':
            c = fgetc(yyin);
            if (c == '>') {
                c = fgetc(yyin);
                if (c == '=') {
                    return BITRIGHTASGN;
                } else {
                    (void)ungetc(c,yyin);
                }
                return BITRIGHT;
            } else if (c == '=') {
                return GTE;
            } else {
                (void)ungetc(c,yyin);
            }
            return GT;

        case '[':
            c = fgetc(yyin);
            if (c == ']') {
                return APPEND;
            } else {
                (void)ungetc(c,yyin);
            }
            return '[';

        case '^':
            c = fgetc(yyin);
            if (c == '^') {
                return XOR;
            } else if (c == '=') {
                return BITXORASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return BITXOR;

        case '|':
            c = fgetc(yyin);
            if (c == '|') {
                return OR;
            } else if (c == '=') {
                return BITORASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return BITOR;

        case '~':
            return BITNOT;
    }

    /* punt */
    if (c == '\n') {
        yylineno++;
    }
    return(c);
}



void
yyerror(char *arg)
{
    fprintf(stderr, "ERROR in %s/%s:%d: %s\n", yydirname, yyfilename, yylineno, arg);
}



void
parser_data_init()
{
    funclist_init(&funcs_list);
    funclist_init(&externs_list);
    kvmap_init(&global_consts);
    kvmap_init(&global_vars);
    kvmap_init(&included_files);
    kvmap_init(&scoping_vars_used);
    kvmaplist_init(&scoping_consts);
    kvmaplist_init(&scoping_vars);
    strlist_init(&inits_list);
    strlist_init(&namespace_list);
    strlist_init(&namespaces_active);
    strlist_init(&using_list);
    strlist_init(&vardecl_list);

    /* Reserve standard global vars. */
    kvmap_add(&global_vars, "me", "me");
    kvmap_add(&global_vars, "loc", "loc");
    kvmap_add(&global_vars, "trigger", "trigger");
    kvmap_add(&global_vars, "command", "command");

    /* Global initializations */
    strlist_add(&inits_list, "\"me\" match me ! me @ location loc ! trig trigger !");

    /* Standard Primitives and Functions. */
    funclist_add(&externs_list, "abort",  "abort",            1, 0, 0);
    funclist_add(&externs_list, "throw",  "abort",            1, 0, 0);
    funclist_add(&externs_list, "tell",   "me @ swap notify", 1, 0, 0);
    funclist_add(&externs_list, "count",  "array_count",      1, 1, 0);
    funclist_add(&externs_list, "cat",    "array_interpret",  0, 1, 1);
    funclist_add(&externs_list, "haskey", "swap 1 array_make array_extract",  2, 1, 0);

    /* Global Consts. */
    kvmap_add(&global_consts, "true",    "1");
    kvmap_add(&global_consts, "false",   "0");
}



void
parser_data_free()
{
    funclist_free(&funcs_list);
    funclist_free(&externs_list);
    kvmap_free(&global_consts);
    kvmap_free(&global_vars);
    kvmap_free(&included_files);
    kvmap_free(&scoping_vars_used);
    kvmaplist_free(&scoping_consts);
    kvmaplist_free(&scoping_vars);
    strlist_free(&inits_list);
    strlist_free(&namespace_list);
    strlist_free(&namespaces_active);
    strlist_free(&using_list);
    strlist_free(&vardecl_list);
}



int
process_file(strlist *files, const char *progname)
{
    int res = 0;
    int filenum;

    if (progname && outf) {
        fprintf(outf, "@program %s\n", progname);
        fprintf(outf, "1 99999 d\n1 i\n");
    }

    if (files->count < 1) {
        strlist_add(files, "");
    }

    parser_data_init();
    for (filenum = 0; filenum < files->count; filenum++) {
        /* Get basename. */
        const char *fullname = files->list[filenum];
        const char *basename = fullname;
        const char *ptr = basename;
        while (*ptr) {
            if (*ptr == '/' || *ptr == '\\') {
                basename = ++ptr;
            } else {
                ptr++;
            }
        }

        yylineno = 1;
        yydirname = savestring(".");
        yyfilename = savestring(fullname);
        yyin = NULL;

        /* Open file, initialize file state info. */
        if (!bookmark_push(fullname)) {
            res = -3;
            break;
        }

        /* We don't actually need to pop the base bookmark. */
        bookmark_count--;

        if (outf) {
            if (*basename) {
                fprintf(outf, "( Generated from %s by the MUV compiler. )\n", basename);
            } else {
                fprintf(outf, "( Generated by the MUV compiler. )\n");
            }
            fprintf(outf, "(   https://github.com/revarbat/muv )\n");
        }

        do {
            res = yyparse();
            if (res == 2) {
                yyerror("Out of Memory.");
            }
            if (res != 0) {
                break;
            }
        } while (bookmark_pop());
        fclose(yyin);

        if (res != 0) {
            break;
        }
    }

    if (res == 0 && outf) {
        char *inits, *funcdef;
        if (funcs_list.count > 0) {
            strlist_add(&inits_list, funcs_list.list[funcs_list.count-1].code);
        }
        inits = strlist_join(&inits_list, "\n", 0, -1);
        funcdef = wrapit(": __start", inits, ";");
        fprintf(outf, "%s\n", funcdef);
        free(inits);
        free(funcdef);

        if (progname) {
            fprintf(outf, ".\n");
            fprintf(outf, "c\n");
            fprintf(outf, "q\n");
        }
    }

    parser_data_free();

    return res;
}


void
usage(const char* execname)
{
    fprintf(stderr, "Usage: %s [-h] [-d] [-w PROGNAME] [-o OUTFILE | -c] FILE ...\n", execname);
    fprintf(stderr, "     -h, --help          Show this help message.\n");
    fprintf(stderr, "     -d, --debug         Insert code to help debugging.\n");
    fprintf(stderr, "     -c, --check         Don't output code.  Just check for errors.\n");
    fprintf(stderr, "     -w PROGNAME\n");
    fprintf(stderr, "     --wrapper PROGNAME  Wrap code for upload into PROGNAME.\n");
    fprintf(stderr, "     -o FILE\n");
    fprintf(stderr, "     --outfile FILE      Save code to given file, not stdout.\n");
    fprintf(stderr, "     -I DIR\n");
    fprintf(stderr, "     --includes-dir DIR  Specify dir to pull system includes from.\n");
    fprintf(stderr, "     --no-optimization   Turns off code optimizations.\n");
}


int
main(int argc, char **argv)
{
    int res;
    const char *execname = argv[0];
    const char *progname = NULL;
    strlist files;

    strlist_init(&files);

    yyin = stdin;
    outf = stdout;

    argc--; argv++;
    while (argc > 0) {
        if (!strcmp(argv[0], "-w") || !strcmp(argv[0], "--wrapper")) {
            if (argc < 2) {
                usage(execname);
                exit(-3);
            }
            argc--; argv++;
            progname = argv[0];
        } else if (!strcmp(argv[0], "-c") || !strcmp(argv[0], "--check")) {
            outf = NULL;
        } else if (!strcmp(argv[0], "-d") || !strcmp(argv[0], "--debug")) {
            debugging_level++;
        } else if (!strcmp(argv[0], "--no-optimization")) {
            do_optimize = 0;
        } else if (!strcmp(argv[0], "-I") || !strcmp(argv[0], "--includes-dir")) {
            if (argc < 2) {
                usage(execname);
                exit(-3);
            }
            argc--; argv++;
            includes_dir = argv[0];
        } else if (!strcmp(argv[0], "-o") || !strcmp(argv[0], "--outfile")) {
            if (argc < 2) {
                usage(execname);
                exit(-3);
            }
            argc--; argv++;
            outf = fopen(argv[0], "w");
        } else if (!strcmp(argv[0], "-h") || !strcmp(argv[0], "--help")) {
            usage(execname);
            exit(0);
        } else if (argv[0][0] == '-') {
            usage(execname);
            exit(-3);
        } else {
            strlist_add(&files, argv[0]);
        }
        argc--; argv++;
    }

    res = process_file(&files, progname);
    return -res;
}

/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */

