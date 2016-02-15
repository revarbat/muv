%{

#define MAXIDENTLEN 128
#define STRBUFSIZ 2048

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

FILE *yyin=NULL;
FILE *outf;
int yylineno = 1;

int yylex(void);
void yyerror(char *s);

static int stringoff;
static char varsbuf[STRBUFSIZ];

char *savefmt(const char *fmt, ...);
char *savestring(const char *);
char *indent(const char *);

struct gettersetter {
    const char *get;
    const char *set;
    const char *del;
};

void getset_free(struct gettersetter *x);

struct str_list {
    const char** list;
    short count;
    short cmax;
} lvars_list, sconst_list, fvars_list, vardecl_list, inits_list, using_list;

void strlist_init(struct str_list *l);
void strlist_free(struct str_list *l);
void strlist_clear(struct str_list *l);
void strlist_add(struct str_list *l, const char *s);
void strlist_pop(struct str_list *l);
int strlist_find(struct str_list *l, const char *s);
char *strlist_join(struct str_list *l, const char *s, int start, int end);
char *strlist_wrap(struct str_list *l, int start, int end);

struct prim_info_t {
    const char *name;
    const char *code;
    short expects;
    short returns;
    short hasvarargs;
};

void priminfo_free(struct prim_info_t *l);

struct prim_list_t {
    struct prim_info_t* list;
    short count;
    short cmax;
} funcs_list;

void funclist_init(struct prim_list_t *l);
void funclist_free(struct prim_list_t *l);
void funclist_add(struct prim_list_t *l, const char *name, const char *code, int argcnt, int retcnt, int hasvarargs);
struct prim_info_t *funclist_find(struct prim_list_t *l, const char *s);

struct prim_info_t *prim_lookup(const char*s);

/* compiler state exception flag */
%}


%union {
    int token;
    char *str;
    int num_int;
    double num_float;
    struct str_list list;
    struct prim_info_t prim;
    struct gettersetter getset;
}


%token <num_int> INTEGER
%token <prim> PRIMITIVE DECLARED_FUNC
%token <str> FLOAT STR IDENT VAR
%token <str> DECLARED_VAR DECLARED_CONST
%token <token> IF ELSE FUNC RETURN TRY CATCH
%token <token> SWITCH USING CASE DEFAULT
%token <token> DO WHILE FOR IN
%token <token> UNTIL CONTINUE BREAK
%token <token> TOP PUSH MUF DEL
%token <token> BOOLTRUE BOOLFALSE
%token <token> UNARY EXTERN VOID SINGLE MULTIPLE

%right THEN ELSE
%left ',' KEYVAL
%right ASGN PLUSASGN MINUSASGN MULTASGN DIVASGN MODASGN BITLEFTASGN BITRIGHTASGN BITANDASGN BITORASGN BITXORASGN
%left DECR INCR
%right '?' ':'
%left OR XOR
%left AND
%left BITOR
%left BITXOR
%left BITAND
%left EQ NEQ
%left GT GTE LT LTE
%left BITLEFT BITRIGHT
%left PLUS MINUS
%left MULT DIV MOD
%right UNARY NOT BITNOT
%left '[' ']' '(' ')' INSERT

%type <str> globalstatement funcdef
%type <str> proposed_funcname good_proposed_funcname bad_proposed_funcname
%type <prim> function
%type <getset> lvalue
%type <str> undeclared_function
%type <str> proposed_varname good_proposed_varname bad_proposed_varname
%type <str> variable undeclared_variable
%type <str> externdef statement statements paren_expr
%type <str> comma_expr comma_expr_or_null
%type <str> function_call primitive_call expr subscripts
%type <str> lvardef lvarlist fvardef fvarlist
%type <str> using_clause case_clause case_clauses default_clause
%type <list> arglist arglist_or_null dictlist argvarlist
%type <num_int> ret_count_type opt_varargs

%start program

%%

program: /* nothing */ { }
    | program globalstatement { fprintf(outf, "%s\n", $2);  free($2); }
    | program funcdef { fprintf(outf, "%s\n", $2);  free($2); }
    | program externdef { }
    ;

globalstatement:
      VAR lvarlist ';' { $$ = $2; }
    | MUF '(' STR ')' ';' { $$ = $3; }
    ;

lvardef: proposed_varname {
            $$ = savefmt("lvar %s\n", $1);
            strlist_add(&lvars_list, $1);
            free($1);
        }
    | proposed_varname ASGN expr {
            $$ = savefmt("lvar %s\n", $1);
            strlist_add(&lvars_list, $1);
            char *init = savefmt("%s %s !", $3, $1);
            strlist_add(&inits_list, init);
            free(init);
            free($1);
            free($3);
        }
    ;

lvarlist: lvardef { $$ = $1; }
    | lvarlist ',' lvardef { $$ = savefmt("%s\n%s", $1, $3); free($1); free($3); }
    ;

funcdef: FUNC proposed_funcname '(' argvarlist opt_varargs ')' {
        /* Mid-rule action to make sure function is declared
         * before statements, to allow possible recursion. */
        funclist_add(&funcs_list, $2, $2, $4.count - ($5?1:0), 1, $5);
    } '{' statements '}' {
        char *body = indent($9);
        char *vars = strlist_join(&$4, " ", 0, -1);
        char *decls = strlist_join(&vardecl_list, "", 0, -1);
        char *idecls = indent(decls);
        free(decls);
        $$ = savefmt(": %s[ %s -- ret ]\n%s%s 0\n;\n\n", $2, vars, idecls, body);
        free(idecls);
        free($2);
        strlist_free(&$4);
        free($9);
        free(body);
        free(vars);
        strlist_clear(&fvars_list);
        strlist_clear(&vardecl_list);
    } ;

externdef: EXTERN ret_count_type proposed_funcname '(' argvarlist opt_varargs ')' ';' {
        funclist_add(&funcs_list, $3, $3, $5.count - ($6?1:0), $2, $6);
        free($3);
        strlist_free(&$5);
        strlist_clear(&fvars_list);
        strlist_clear(&vardecl_list);
    } ;

bad_proposed_funcname: DECLARED_VAR { $$ = $1; }
    | DECLARED_CONST { $$ = $1; }
    | DECLARED_FUNC { $$ = savestring($1.name); }
    ;

good_proposed_funcname: IDENT { $$ = $1; }
    | PRIMITIVE { $$ = savestring($1.name); } /* allow overriding primitives */
    ;

proposed_funcname:
      good_proposed_funcname { $$ = $1; }
    | bad_proposed_funcname {
        char buf[1024];
        snprintf(buf, sizeof(buf), "Indentifier '%s' already declared", $1);
        yyerror(buf);
        YYERROR;
    }
    ;

undeclared_function: IDENT { $$ = $1; }
    | DECLARED_VAR { $$ = $1; }
    | DECLARED_CONST { $$ = $1; }
    ;

function: DECLARED_FUNC { $$ = $1; }
    | undeclared_function {
            char buf[1024];
            snprintf(buf, sizeof(buf), "Undeclared function '%s'", $1);
            yyerror(buf);
            YYERROR;
        }
    ;

bad_proposed_varname: DECLARED_VAR { $$ = $1; }
    | DECLARED_CONST { $$ = $1; }
    | DECLARED_FUNC { $$ = savestring($1.name); }
    ;

good_proposed_varname: IDENT { $$ = $1; }
    | PRIMITIVE { $$ = savestring($1.name); } /* allow overriding primitives */
    ;

proposed_varname: good_proposed_varname { $$ = $1; }
    | bad_proposed_varname {
        char buf[1024];
        snprintf(buf, sizeof(buf), "Indentifier '%s' already declared", $1);
        yyerror(buf);
        YYERROR;
    }
    ;

undeclared_variable: IDENT { $$ = $1; }
    | DECLARED_FUNC { $$ = savestring($1.name); }
    | PRIMITIVE { $$ = savestring($1.name); }
    ;

variable: DECLARED_VAR { $$ = $1; }
    | undeclared_variable {
            char buf[1024];
            $$ = $1;
            snprintf(buf, sizeof(buf), "Undeclared variable '%s'", $1);
            yyerror(buf);
            YYERROR;
        }
    ;

ret_count_type:
      VOID { $$ = 0; }
    | SINGLE  { $$ = 1; }
    | MULTIPLE { $$ = 999; }
    ;

opt_varargs: /* nothing */ { $$ = 0; }
    | MULT { $$ = 1; }
    ;

argvarlist:
    /* nothing */ { strlist_init(&$$); }
    | proposed_varname {
            strlist_init(&$$);
            strlist_add(&$$, $1);
            strlist_add(&fvars_list, $1);
            free($1);
        }
    | argvarlist ',' proposed_varname {
            $$ = $1;
            strlist_add(&$$, $3);
            strlist_add(&fvars_list, $3);
            free($3);
        }
    ;

statement: ';' { $$ = savestring(""); }
    | comma_expr ';' { $$ = savefmt("%s pop", $1); free($1); }
    | RETURN ';' { $$ = savestring("0 exit"); }
    | RETURN expr ';' { $$ = savefmt("%s exit", $2); free($2); }
    | BREAK ';' { $$ = savestring("break"); }
    | CONTINUE ';' { $$ = savestring("continue"); }
    | VAR fvarlist ';' { $$ = $2; }
    | IF paren_expr statement %prec THEN {
            char *body = indent($3);
            $$ = savefmt("%s if\n%s\nthen", $2, body);
            free($2); free($3);
            free(body);
        }
    | IF paren_expr statement ELSE statement {
            char *ifbody = indent($3);
            char *elsebody = indent($5);
            $$ = savefmt("%s if\n%s\nelse\n%s\nthen", $2, ifbody, elsebody);
            free($2); free($3); free($5);
            free(ifbody); free(elsebody);
        }
    | WHILE paren_expr statement {
            char *cond = indent($2);
            char *body = indent($3);
            $$ = savefmt("begin\n%s\nwhile\n%s\nrepeat", cond, body);
            free($2); free($3);
            free(cond); free(body);
        }
    | UNTIL paren_expr statement {
            char *cond = indent($2);
            char *body = indent($3);
            $$ = savefmt("begin\n%s not\nwhile\n%s\nrepeat", cond, body);
            free($2); free($3);
            free(cond); free(body);
        }
    | DO statement WHILE paren_expr ';' {
            char *body = indent($2);
            char *cond = indent($4);
            $$ = savefmt("begin\n%s\n(conditional follows)\n%s not\nuntil", body, cond);
            free($2); free($4);
            free(cond); free(body);
        }
    | DO statement UNTIL paren_expr ';' {
            char *body = indent($2);
            char *cond = indent($4);
            $$ = savefmt("begin\n%s\n(conditional follows)\n%s\nuntil", body, cond);
            free($2); free($4);
            free(cond); free(body);
        }
    | FOR '(' comma_expr_or_null ';' comma_expr_or_null ';' comma_expr_or_null ')' statement {
            char *cond = indent($5);
            char *next = indent($7);
            char *body = indent($9);
            $$ = savefmt("%s pop\nbegin\n%s\nwhile\n%s\n%s pop\nrepeat", $3, cond, body, next);
            free($3); free($5); free($7); free($9);
            free(cond); free(next); free(body);
        }
    | FOR '(' variable IN expr ')' statement {
            char *body = indent($7);
            $$ = savefmt("%s\nforeach %s ! pop\n%s\nrepeat", $5, $3, body);
            free($3); free($5); free($7);
            free(body);
        }
    | FOR '(' variable KEYVAL variable IN expr ')' statement {
            char *body = indent($9);
            $$ = savefmt("%s\nforeach %s ! %s !\n%s\nrepeat", $7, $5, $3, body);
            free($3); free($5); free($7); free($9);
            free(body);
        }
    | TRY statement CATCH '(' ')' statement {
            char *trybody = indent($2);
            char *catchbody = indent($6);
            $$ = savefmt("0 try\n%s\ncatch pop\n%s\nendcatch", trybody, catchbody);
            free($2); free($6);
            free(trybody);
            free(catchbody);
        }
    | TRY statement CATCH '(' variable ')' statement {
            char *trybody = indent($2);
            char *catchbody = indent($7);
            $$ = savefmt("0 try\n%s\ncatch_detailed %s !\n%s\nendcatch", trybody, $5, catchbody);
            free($2); free($5); free($7);
            free(trybody);
            free(catchbody);
        }
    | SWITCH '(' expr using_clause ')' '{' case_clauses default_clause '}' {
            char *exp = indent($3);
            char *body = indent($7);
            char *dflt = indent($8);
            $$ = savefmt("0 begin pop (switch)\n%s\n%s%srepeat pop", exp, body, dflt);
            strlist_pop(&using_list);
            free(exp); free(dflt); free(body);
            free($3); free($4); free($7); free($8);
        }
    | '{' statements '}' { $$ = $2; }
    ;

using_clause: /* nothing */ {
            $$ = savestring("=");
            strlist_add(&using_list, $$);
        }
    | USING PRIMITIVE {
            if ($2.expects != 2) {
                yyerror("Using clause expects instruction or function that takes 2 args.");
                YYERROR;
            }
            $$ = savestring($2.name);
            if (!strcmp($$, "stringcmp")) {
                strlist_add(&using_list, "stringcmp not");
            } else if (!strcmp($$, "strcmp")) {
                strlist_add(&using_list, "strcmp not");
            } else {
                strlist_add(&using_list, $$);
            }
        }
    | USING function {
            if ($2.expects != 2) {
                yyerror("Using clause expects instruction or function that takes 2 args.");
                YYERROR;
            }
            $$ = savestring($2.name);
            strlist_add(&using_list, $2.name);
        }
    ;

case_clauses: case_clause { $$ = $1; }
    | case_clauses case_clause { $$ = savefmt("%s%s", $1, $2); free($1); free($2); }
    ;

case_clause: CASE paren_expr statement {
        char *body = indent($3);
        const char *comp = using_list.list[using_list.count-1];
        $$ = savefmt("(case)\ndup %s %s if\n%s break\nthen\n", $2, comp, body);
        free(body);
        free($2); free($3);
    } ;

default_clause: /* nothing */ { $$ = savestring("break\n"); }
    | DEFAULT statement { $$ = savefmt("(default)\n%s break\n", $2); free($2); }
    ;

paren_expr: '(' expr ')' { $$ = $2; } ;

statements: /* nothing */ { $$ = savestring(""); }
    | statements statement {
            if (*$1) {
                $$ = savefmt("%s\n%s", $1, $2);
            } else {
                $$ = $2;
            }
        }
    ;

comma_expr_or_null: /* nothing */ { $$ = savestring(""); }
    | comma_expr { $$ = $1; }
    ;

comma_expr: expr { $$ = $1; }
    | comma_expr ',' expr { $$ = savefmt("%s pop\n%s", $1, $3); free($1); free($3); }
    ;

function_call: function '(' arglist_or_null ')' {
        if ($1.hasvarargs) {
            if ($3.count < $1.expects) {
                char buf[1024];
                snprintf(buf, sizeof(buf),
                    "Function '%s' expects at least %d args, but was provided %d args",
                    $1.name, $1.expects, $3.count
                );
                strlist_free(&$3);
                yyerror(buf);
                YYERROR;
            }
        } else {
            if ($3.count != $1.expects) {
                char buf[1024];
                snprintf(buf, sizeof(buf),
                    "Function '%s' expects %d args, but was provided %d args",
                    $1.name, $1.expects, $3.count
                );
                strlist_free(&$3);
                yyerror(buf);
                YYERROR;
            }
        }
        if ($1.hasvarargs) {
            char* fargs = strlist_wrap(&$3, 0, $1.expects);
            char* vargs = strlist_join(&$3, "\n", $1.expects, -1);
            char* ivargs = indent(vargs);
            $$ = savefmt("%s%s{%s\n}list %s", fargs, (*fargs? " ":""), ivargs, $1.code);
            free(fargs);
            free(vargs);
            free(ivargs);
        } else {
            char* funcargs = strlist_wrap(&$3, 0, -1);
            $$ = savefmt("%s%s%s", funcargs, (*funcargs?" ":""), $1.code);
            free(funcargs);
        }
        strlist_free(&$3);
    } ;

primitive_call:
      TOP { $$ = savestring(""); }
    | PUSH '(' arglist ')' { $$ = strlist_wrap(&$3, 0, -1); strlist_free(&$3); }
    | MUF '(' STR ')' { $$ = $3; }
    | DEL '(' lvalue ')' { $$ = savefmt("%s 0", $3.del); getset_free(&$3); }
    | PRIMITIVE '(' arglist_or_null ')' {
            if ($3.count != $1.expects) {
                char buf[1024];
                snprintf(buf, sizeof(buf),
                    "Built-in primitive '%s' expects %d args, but was provided %d args",
                    $1.name, $1.expects, $3.count
                );
                strlist_free(&$3);
                yyerror(buf);
                YYERROR;
            }
            char *args = strlist_wrap(&$3, 0, -1);
            if ($1.returns == 0) {
                $$ = savefmt("%s%s%s 0", args, (*args?" ":""), $1.code);
            } else if ($1.returns == 1) {
                $$ = savefmt("%s%s%s", args, (*args?" ":""), $1.code);
            } else {
                $$ = savefmt("{ %s%s%s }list", args, (*args?" ":""), $1.code);
            }
            free(args);
            strlist_free(&$3);
        }
    ;

lvalue: variable {
            $$.get = savefmt("%s @", $1);
            $$.set = savefmt("%s !", $1);
            $$.del = savefmt("0 %s !", $1);
            free($1);
        }
    | variable '[' expr ']' {
            $$.get = savefmt("%s @ %s []", $1, $3);
            $$.set = savefmt("%s @ %s ->[] %s !", $1, $3, $1);
            $$.del = savefmt("%s @ %s array_delitem %s !", $1, $3, $1);
            free($1); free($3);
        }
    | variable '[' expr ']' '[' subscripts {
            $$.get = savefmt("%s @ { %s %s }list array_nested_get", $1, $3, $6);
            $$.set = savefmt("%s @ { %s %s }list array_nested_set %s !", $1, $3, $6, $1);
            $$.del = savefmt("%s @ { %s %s }list array_nested_del %s !", $1, $3, $6, $1);
            free($1); free($3); free($6);
        }
    ;

subscripts: expr ']' { $$ = $1; }
    | subscripts '[' expr ']' { $$ = savefmt("%s %s", $1, $3); free($1); free($3); }
    ;

expr: INTEGER { $$ = savefmt("%d", $1); }
    | '#' MINUS INTEGER { $$ = savefmt("#-%d", $3); }
    | '#' INTEGER { $$ = savefmt("#%d", $2); }
    | FLOAT { $$ = $1; }
    | STR { $$ = savefmt("\"%s\"", $1); free($1); }
    | BOOLTRUE { $$ = savestring("1"); }
    | BOOLFALSE { $$ = savestring("0"); }
    | DECLARED_CONST { $$ = $1; }
    | paren_expr { $$ = $1; }
    | function_call { $$ = $1; }
    | primitive_call { $$ = $1; }
    | lvalue { $$ = savestring($1.get); getset_free(&$1); }
    | INSERT { $$ = savestring("{ }list"); }
    | '[' arglist_or_null ']' {
            char *items = strlist_wrap(&$2, 0, -1);
            char *body = indent(items);
            if ($2.count == 0) {
                $$ = savestring("{ }list");
            } else {
                $$ = savefmt("{\n%s\n}list", body);
            }
            free(body); free(items);
            strlist_free(&$2);
        }
    | '[' dictlist ']' {
            char *items = strlist_wrap(&$2, 0, -1);
            char *body = indent(items);
            $$ = savefmt("{\n%s}dict", body);
            free(body); free(items);
            strlist_free(&$2);
        }
    | PLUS expr   %prec UNARY { $$ = $2; }
    | MINUS expr  %prec UNARY { $$ = savefmt("0 %s -", $2); free($2); }
    | NOT expr    %prec UNARY { $$ = savefmt("%s not", $2); free($2); }
    | BITNOT expr %prec UNARY { $$ = savefmt("%s -1 bitxor", $2); free($2); }
    | BITAND function %prec UNARY { $$ = savefmt("'%s", $2.name); }
    | INCR lvalue %prec UNARY { $$ = savefmt("%s 1 + dup %s", $2.get, $2.set); getset_free(&$2); }
    | DECR lvalue %prec UNARY { $$ = savefmt("%s 1 - dup %s", $2.get, $2.set); getset_free(&$2); }
    | lvalue INCR { $$ = savefmt("%s dup 1 + %s", $1.get, $1.set); getset_free(&$1); }
    | lvalue DECR { $$ = savefmt("%s dup 1 - %s", $1.get, $1.set); getset_free(&$1); }
    | expr PLUS expr  { $$ = savefmt("%s %s +", $1, $3); free($1); free($3); }
    | expr MINUS expr { $$ = savefmt("%s %s -", $1, $3); free($1); free($3); }
    | expr MULT expr  { $$ = savefmt("%s %s *", $1, $3); free($1); free($3); }
    | expr DIV expr   { $$ = savefmt("%s %s /", $1, $3); free($1); free($3); }
    | expr MOD expr   { $$ = savefmt("%s %s %%", $1, $3); free($1); free($3); }
    | expr EQ expr    { $$ = savefmt("%s %s =", $1, $3); free($1); free($3); }
    | expr NEQ expr   { $$ = savefmt("%s %s = not", $1, $3); free($1); free($3); }
    | expr LT expr    { $$ = savefmt("%s %s <", $1, $3); free($1); free($3); }
    | expr GT expr    { $$ = savefmt("%s %s >", $1, $3); free($1); free($3); }
    | expr LTE expr   { $$ = savefmt("%s %s <=", $1, $3); free($1); free($3); }
    | expr GTE expr   { $$ = savefmt("%s %s >=", $1, $3); free($1); free($3); }
    | expr AND expr   { $$ = savefmt("%s %s and", $1, $3); free($1); free($3); }
    | expr OR expr    { $$ = savefmt("%s %s or", $1, $3); free($1); free($3); }
    | expr XOR expr   { $$ = savefmt("%s %s xor", $1, $3); free($1); free($3); }
    | expr BITOR expr    { $$ = savefmt("%s %s bitor", $1, $3); free($1); free($3); }
    | expr BITXOR expr   { $$ = savefmt("%s %s bitxor", $1, $3); free($1); free($3); }
    | expr BITAND expr   { $$ = savefmt("%s %s bitand", $1, $3); free($1); free($3); }
    | expr BITLEFT expr  { $$ = savefmt("%s %s bitshift", $1, $3); free($1); free($3); }
    | expr BITRIGHT expr { $$ = savefmt("%s 0 %s - bitshift", $1, $3); free($1); free($3); }
    | lvalue ASGN expr        { $$ = savefmt("%s\ndup %s", $3, $1.set); getset_free(&$1); free($3); }
    | lvalue INSERT ASGN expr { $$ = savefmt("%s\ndup %s []<-\n%s", $4, $1.get, $1.set); getset_free(&$1); free($4); }
    | lvalue PLUSASGN expr   { $$ = savefmt("%s\n%s +\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue MINUSASGN expr  { $$ = savefmt("%s\n%s -\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue MULTASGN expr   { $$ = savefmt("%s\n%s *\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue DIVASGN expr    { $$ = savefmt("%s\n%s /\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue MODASGN expr    { $$ = savefmt("%s\n%s %%\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue BITORASGN expr  { $$ = savefmt("%s\n%s bitor\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue BITXORASGN expr { $$ = savefmt("%s\n%s bitxor\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue BITANDASGN expr { $$ = savefmt("%s\n%s bitand\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue BITLEFTASGN expr { $$ = savefmt("%s\n%s bitshift\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | lvalue BITRIGHTASGN expr { $$ = savefmt("%s\n0 %s - bitshift\ndup %s", $1.get, $3, $1.set); getset_free(&$1); free($3); }
    | expr '?' expr ':' expr { $$ = savefmt("%s if %s else %s then", $1, $3, $5); free($1); free($3); free($5); }
    ;

arglist_or_null: /* nothing */ { strlist_init(&$$); }
    | arglist { $$ = $1; }
    ;

arglist:
      expr { strlist_init(&$$); strlist_add(&$$, $1); free($1); }
    | arglist ',' expr { $$ = $1;  strlist_add(&$$, $3); free($3); }
    ;

dictlist:
      expr KEYVAL expr {
            char *vals = savefmt("%s %s\n", $1, $3);
            strlist_init(&$$);
            strlist_add(&$$, vals);
            free(vals);
            free($1); free($3);
        }
    | dictlist ',' expr KEYVAL expr {
            char *vals = savefmt("%s %s\n", $3, $5);
            $$ = $1;
            strlist_add(&$$, vals);
            free(vals);
            free($3); free($5);
        }
    ;

fvardef: proposed_varname {
            char *vardecl = savefmt("var %s\n", $1);
            $$ = savestring("");
            strlist_add(&fvars_list, $1);
            strlist_add(&vardecl_list, vardecl);
            free(vardecl);
            free($1);
        }
    | proposed_varname ASGN expr {
            char *vardecl = savefmt("var %s\n", $1);
            $$ = savefmt("%s %s !", $3, $1);
            strlist_add(&fvars_list, $1);
            strlist_add(&vardecl_list, vardecl);
            free(vardecl);
            free($1);
            free($3);
        }
    ;

fvarlist: fvardef { $$ = $1; }
    | fvarlist ',' fvardef { $$ = savefmt("%s\n%s", $1, $3); free($1); free($3); }
    ;

%%


void getset_free(struct gettersetter *x)
{
    free((char*)x->get);
    free((char*)x->set);
    free((char*)x->del);
    x->get = NULL;
    x->set = NULL;
    x->del = NULL;
}


void
strlist_init(struct str_list *l)
{
    l->count = 0;
    l->cmax = 8;
    l->list = (const char**)malloc(sizeof(const char*) * l->cmax);
}


void
strlist_free(struct str_list *l)
{
    for (int i = 0; i < l->count; i++) {
        free((void*) l->list[i]);
    }
    free(l->list);
    l->list = 0;
    l->count = 0;
    l->cmax = 0;
}


void
strlist_clear(struct str_list *l)
{
    strlist_free(l);
    strlist_init(l);
}


void
strlist_add(struct str_list *l, const char *s)
{
    if (l->count >= l->cmax) {
        l->cmax += (l->cmax < 4096)? l->cmax : 4096;
        l->list = (const char**)realloc(l->list, sizeof(const char*) * l->cmax);
    }
    l->list[l->count++] = savestring(s);
}


void
strlist_pop(struct str_list *l)
{
    if (l->count > 0) {
        free((void*) l->list[--l->count]);
    }
}


int
strlist_find(struct str_list *l, const char *s)
{
    for (int i = 0; i < l->count; i++) {
        if (!strcmp(l->list[i], s)) {
            return i;
        }
    }
    return -1;
}


char *
strlist_join(struct str_list *l, const char *s, int start, int end)
{
    char *buf;
    const char *ptr;
    char *ptr2;
    int i;
    size_t totlen = 0;
    if (end == -1) {
        end = l->count;
    }
    for (i = start; i < l->count && i < end; i++) {
        for (ptr = l->list[i]; *ptr++; totlen++);
    }
    totlen += strlen(s) * l->count;
    ptr2 = buf = (char*)malloc(totlen+1);
    for (i = start; i < l->count && i < end; i++) {
        if (i > 0) {
            for(ptr = s; *ptr; ) *ptr2++ = *ptr++;
        }
        for(ptr = l->list[i]; *ptr; ) *ptr2++ = *ptr++;
    }
    *ptr2 = '\0';
    return buf;
}


char *
strlist_wrap(struct str_list *l, int start, int end)
{
    char *buf;
    const char *ptr;
    char *ptr2;
    int i;
    size_t totlen = 0;
    size_t currlen = 0;
    if (end == -1) {
        end = l->count;
    }
    for (i = start; i < l->count && i < end; i++) {
        for (ptr = l->list[i]; *ptr++; totlen++);
    }
    totlen += l->count;
    ptr2 = buf = (char*)malloc(totlen+1);
    for (i = start; i < l->count && i < end; i++) {
        if (i > 0) {
            if (currlen > 0) {
                if (currlen + strlen(l->list[i]) > 80) {
                    *ptr2++ = '\n';
                    currlen = 0;
                } else {
                    *ptr2++ = ' ';
                    currlen++;
                }
            }
        }
        for(ptr = l->list[i]; *ptr; ) {
            if (*ptr == '\n') {
                currlen = 0;
            } else {
                currlen++;
            }
            *ptr2++ = *ptr++;
        }
    }
    *ptr2 = '\0';
    return buf;
}


void
priminfo_free(struct prim_info_t *l)
{
    free((void*) l->name);
    free((void*) l->code);
}


void
funclist_init(struct prim_list_t *l)
{
    l->count = 0;
    l->cmax = 8;
    l->list = (struct prim_info_t*)malloc(sizeof(struct prim_info_t) * l->cmax);
}


void
funclist_free(struct prim_list_t *l)
{
    for (int i = 0; i < l->count; i++) {
        priminfo_free(&l->list[i]);
    }
    free(l->list);
    l->list = 0;
    l->count = 0;
    l->cmax = 0;
}


void
funclist_add(struct prim_list_t *l, const char *name, const char *code, int argcnt, int retcnt, int hasvarargs)
{
    struct prim_info_t *p;
    if (l->count >= l->cmax) {
        l->cmax += (l->cmax < 4096)? l->cmax : 4096;
        l->list = (struct prim_info_t*)realloc(l->list, sizeof(struct prim_info_t) * l->cmax);
    }
    p = &l->list[l->count];
    p->name = savestring(name);
    p->code = savestring(code);
    p->expects = argcnt;
    p->returns = retcnt;
    p->hasvarargs = hasvarargs;
    l->count++;
}


struct prim_info_t *
funclist_find(struct prim_list_t *l, const char *s)
{
    for (int i = 0; i < l->count; i++) {
        if (!strcmp(l->list[i].name, s)) {
            return &l->list[i];
        }
    }
    return NULL;
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
        "break",     BREAK,     -1,
        "case",      CASE,      -1,
        "catch",     CATCH,     -1,
        "continue",  CONTINUE,  -1,
        "default",   DEFAULT,   -1,
        "del",       DEL,       -1,
        "do",        DO,        -1,
        "else",      ELSE,      -1,
        "extern",    EXTERN,    -1,
        "false",     BOOLFALSE, -1,
        "for",       FOR,       -1,
        "func",      FUNC,      -1,
        "if",        IF,        -1,
        "in",        IN,        -1,
        "muf",       MUF,       -1,
        "multiple",  MULTIPLE,  -1,
        "push",      PUSH,      -1,
        "return",    RETURN,    -1,
        "single",    SINGLE,    -1,
        "switch",    SWITCH,    -1,
        "top",       TOP,       -1,
        "true",      BOOLTRUE,  -1,
        "try",       TRY,       -1,
        "until",     UNTIL,     -1,
        "using",     USING,     -1,
        "var",       VAR,       -1,
        "void",      VOID,      -1,
        "while",     WHILE,     -1,
        0, 0, 0
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



int
yylex()
{
    char in[BUFSIZ];
    char *p = in;
    int c, digit;
    struct prim_info_t* pinfo;
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
            char uc = toupper(c);
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
                *p++ = c;
            } while (isdigit(c));
        }
        *(--p) = '\0';
        (void)ungetc(c,yyin);
        yylval.str = savestring(in);
        return FLOAT;
    }

    /* handle keywords or idents/builtins */
    if (isalpha(c) || c == '_' || c == '.') {
        int cnt = 0;
        int rv;
        int bltin;

        while ((c = fgetc(yyin)) != EOF && (isalnum(c) || c == '_' || c == '?')) {
            if (++cnt + 1 >= MAXIDENTLEN) {
                yyerror("identifier too long");
            }
            *p++ = c;
        }

        (void)ungetc(c, yyin);

        *p = '\0';

        /* Program flow keywords are inviolate and take priority. */
        if ((rv = lookup(in, &bltin)) != -1) {
            return(rv);
        }

        /* Function local variable take precendence over globals */
        if (strlist_find(&fvars_list, in) >= 0) {
            yylval.str = savestring(in);
            return DECLARED_VAR;
        }
        if (strlist_find(&lvars_list, in) >= 0) {
            yylval.str = savestring(in);
            return DECLARED_VAR;
        }

        /* Declared functions should override primitives. */
        pinfo = funclist_find(&funcs_list, in);
        if (pinfo) {
            yylval.prim = *pinfo;
            return DECLARED_FUNC;
        }

        /* Server constants */
        if (strlist_find(&sconst_list, in) >= 0) {
            yylval.str = savestring(in);
            return DECLARED_CONST;
        }

        /* primitives match after everything else. */
        if ((pinfo = prim_lookup(in))) {
            yylval.prim = *pinfo;
            return PRIMITIVE;
        }

        /* If identifier isn't already claimed, return as an undeclared identifier. */
        yylval.str = savestring(in);
        return IDENT;
    }

    /* handle quoted strings */
    if (c == '"') {
        int cnt = 0;
        int quot = c;

        /* strip start quote by resetting ptr */
        p = in;

        /* match quoted strings */
        while ((c = fgetc(yyin)) != EOF && c != quot) {
            if (!isascii(c)) {
                continue;
            }

            if (++cnt + 1 >= sizeof(in)) {
                yyerror("string too long");
            }

            /* we have to guard the line count */
            if (c == '\n') {
                yylineno++;
            }

            if (c == '\\') {
                *p++ = c;
                cnt++;
                c = fgetc(yyin);
            }

            *p++ = c;
        }

        if (c == EOF) {
            yyerror("EOF in quoted string");
        }

        *p = '\0';

        yylval.str = savestring(in);
        return(STR);
    }

    switch(c) {
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

        case '*':
            c = fgetc(yyin);
            if (c == '=') {
                return MULTASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return MULT;

        case '/':
            c = fgetc(yyin);
            if (c == '=') {
                return DIVASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return DIV;

        case '%':
            c = fgetc(yyin);
            if (c == '=') {
                return MODASGN;
            } else {
                (void)ungetc(c,yyin);
            }
            return MOD;

        case '~':
            return BITNOT;

        case '=':
            c = fgetc(yyin);
            if (c == '=') {
                return EQ;
            } else if (c == '>') {
                return KEYVAL;
            } else {
                (void)ungetc(c,yyin);
            }
            return ASGN;

        case '!':
            c = fgetc(yyin);
            if (c == '=') {
                return NEQ;
            } else {
                (void)ungetc(c,yyin);
            }
            return NOT;

        case '[':
            c = fgetc(yyin);
            if (c == ']') {
                return INSERT;
            } else {
                (void)ungetc(c,yyin);
            }
            return '[';
    }

    /* punt */
    if (c == '\n') {
        yylineno++;
    }
    return(c);
}



char *
savestring(const char *arg)
{
    char *tmp = (char *)malloc(strlen(arg) + 1);
    strcpy(tmp, arg);
    return(tmp);
}



char *
savefmt(const char *fmt, ...)
{
    va_list aptr;
    char buf[STRBUFSIZ];

    va_start(aptr, fmt);
    vsprintf(buf, fmt, aptr);
    va_end(aptr);

    return savestring(buf);
}



char *
indent(const char *arg)
{
    const int indentlen = 4;
    char *buf;
    const char *ptr;
    char *ptr2;
    int i, lines;

    if (!arg || !*arg) {
        return savestring("");
    }
    for (ptr = arg, lines = 1; *ptr; ptr++) {
        if (*ptr == '\n') {
            lines++;
        }
    }
    buf = (char *)malloc(strlen(arg) + 1 + indentlen*lines);
    ptr = arg;
    ptr2 = buf;
    while (*ptr) {
        for (i = 0; *ptr != '\n' && i < indentlen; i++) {
            *ptr2++ = ' ';
        }
        while (*ptr) {
            *ptr2++ = *ptr;
            if (*ptr++ == '\n') break;
        }
    }
    *ptr2 = '\0';
    return buf;
}



void
yyerror(char *arg)
{
    fprintf(stderr, "%s in line %d\n", arg, yylineno);
}



struct prim_info_t prims_list[] = {
    { "throw",             "abort",             1,  0,  0},
    { "abort",             "abort",             1,  0,  0},

    { "awake?",            "awake?",            1,  1,  0},
    { "online",            "online_array",      0,  1,  0},
    { "online_array",      "online_array",      0,  1,  0},

    { "conboot",           "conboot",           1,  1,  0},
    { "concount",          "concount",          0,  1,  0},
    { "condbref",          "condbref",          1,  1,  0},
    { "condescr",          "condescr",          1,  1,  0},
    { "conhost",           "conhost",           1,  1,  0},
    { "conidle",           "conidle",           1,  1,  0},
    { "connotify",         "connotify",         2,  0,  0},
    { "contime",           "contime",           1,  1,  0},
    { "conuser",           "conuser",           1,  1,  0},

    { "descr",             "descr",             0,  1,  0},
    { "descr_array",       "descr_array",       1,  1,  0},
    { "descr_setuser",     "descr_setuser",     3,  1,  0},
    { "descrboot",         "descrboot",         1,  1,  0},
    { "descrbufsize",      "descrbufsize",      1,  1,  0},
    { "descrcon",          "descrcon",          1,  1,  0},
    { "descrdbref",        "descrdbref",        1,  1,  0},
    { "descrflush",        "descrflush",        1,  0,  0},
    { "descrhost",         "descrhost",         1,  1,  0},
    { "descridle",         "descridle",         1,  1,  0},
    { "descriptors",       "descriptors pop",   1, 99,  0},
    { "descrleastidle",    "descrleastidle",    1,  1,  0},
    { "descrmostidle",     "descrmostidle",     1,  1,  0},
    { "descrnotify",       "descrnotify",       2,  0,  0},
    { "descrsecure?",      "descrsecure?",      1,  1,  0},
    { "descrtime",         "descrtime",         1,  1,  0},
    { "descruser",         "descruser",         1,  1,  0},
    { "firstdescr",        "firstdescr",        1,  1,  0},
    { "lastdescr",         "lastdescr",         1,  1,  0},
    { "nextdescr",         "nextdescr",         1,  1,  0},

    { "call",              "call",              1, 99,  0},
    { "call_public",       "call",              2, 99,  0},
    { "cancall",           "cancall?",          2,  1,  0},
    { "interp",            "interp",            3,  1,  0},

    { "event_count",       "event_count",       0,  1,  0},
    { "event_exists",      "event_exists",      1,  1,  0},
    { "event_wait",        "event_wait",        0,  2,  0},
    { "event_waitfor",     "event_waitfor",     1,  2,  0},
    { "event_send",        "event_send",        3,  0,  0},
    { "timer_start",       "timer_start",       2,  0,  0},
    { "timer_stop",        "timer_stop",        1,  0,  0},
    { "watchpid",          "watchpid",          1,  0,  0},

    { "tell",              "me @ swap notify",  1,  0,  0},
    { "notify",            "notify",            2,  0,  0},
    { "notify_except",     "notify_except",     3,  0,  0},
    { "notify_exclude", "swap array_explode dup 2 + rotate notify_exclude",  3,  0,  0},
    { "array_notify",      "array_notify",      2,  0,  0},
    { "user_log",          "user_log",          1,  0,  0},
    { "read",              "read",              0,  1,  0},
    { "tread",             "tread",             1,  2,  0},
    { "read_wants_blanks", "read_wants_blanks", 0,  0,  0},

    { "atoi",              "atoi",              1,  1,  0},
    { "ctoi",              "ctoi",              1,  1,  0},
    { "int",               "int",               1,  1,  0},
    { "intostr",           "intostr",           1,  1,  0},
    { "itoc",              "itoc",              1,  1,  0},
    { "stod",              "stod",              1,  1,  0},
    { "dbref",             "dbref",             1,  1,  0},

    { "prog",              "prog",              0,  1,  0},
    { "trig",              "trig",              0,  1,  0},
    { "caller",            "caller",            0,  1,  0},

    { "address?",          "address?",          1,  1,  0},
    { "array?",            "array?",            1,  1,  0},
    { "dbref?",            "dbref?",            1,  1,  0},
    { "dictionary?",       "dictionary?",       1,  1,  0},
    { "float?",            "float?",            1,  1,  0},
    { "int?",              "int?",              1,  1,  0},
    { "lock?",             "lock?",             1,  1,  0},
    { "number?",           "number?",           1,  1,  0},
    { "string?",           "string?",           1,  1,  0},

    { "explode",           "explode_array",     2,  1,  0},
    { "instr",             "instr",             2,  1,  0},
    { "instring",          "instring",          2,  1,  0},
    { "midstr",            "midstr",            3,  1,  0},
    { "rinstr",            "rinstr",            2,  1,  0},
    { "rinstring",         "rinstring",         2,  1,  0},
    { "rsplit",            "rsplit",            2,  2,  0},
    { "smatch",            "smatch",            2,  1,  0},
    { "split",             "split",             2,  2,  0},
    { "strcat",            "strcat",            2,  1,  0},
    { "strcmp",            "strcmp",            2,  1,  0},
    { "strcut",            "strcut",            2,  2,  0},
    { "stringcmp",         "stringcmp",         2,  1,  0},
    { "stringpfx",         "stringpfx",         2,  1,  0},
    { "strip",             "strip",             1,  1,  0},
    { "striplead",         "striplead",         1,  1,  0},
    { "striptail",         "striptail",         1,  1,  0},
    { "strlen",            "strlen",            1,  1,  0},
    { "strmatch",          "strmatch",          2,  1,  0},
    { "strncmp",           "strncmp",           3,  1,  0},
    { "subst",             "subst",             3,  1,  0},
    { "tolower",           "tolower",           1,  1,  0},
    { "toupper",           "toupper",           1,  1,  0},

    { "strencrypt",        "strencrypt",        2,  1,  0},
    { "strdecrypt",        "strdecrypt",        2,  1,  0},

    { "regexp",            "regexp",            3,  2,  0},
    { "regsub",            "regsub",            4,  1,  0},

    { "locked?",           "locked?",           2,  1,  0},
    { "parselock",         "parselock",         1,  1,  0},
    { "unparselock",       "unparselock",       1,  1,  0},
    { "prettylock",        "prettylock",        1,  1,  0},
    { "testlock",          "testlock",          2,  1,  0},
    { "setlockstr",        "setlockstr",        2,  1,  0},
    { "getlockstr",        "getlockstr",        1,  1,  0},

    { "array_fmtstrings",  "array_fmtstrings",  2,  1,  0},
    { "pronoun_sub",       "pronoun_sub",       2,  1,  0},
    { "tokensplit",        "tokensplit",        3,  3,  0},

    { "textattr",          "textattr",          2,  1,  0},
    { "ansi_strip",        "ansi_strip",        1,  1,  0},
    { "ansi_strlen",       "ansi_strlen",       1,  1,  0},
    { "ansi_strcut",       "ansi_strcut",       2,  2,  0},
    { "ansi_midstr",       "ansi_midstr",       3,  1,  0},

    { "getseed",           "getseed",           0,  1,  0},
    { "setseed",           "setseed",           1,  0,  0},
    { "srand",             "srand",             0,  1,  0},
    { "frand",             "frand",             0,  1,  0},
    { "random",            "random",            0,  1,  0},
    { "gaussian",          "gaussian",          2,  1,  0},

    { "abs",               "abs",               1,  1,  0},
    { "ceil",              "ceil",              1,  1,  0},
    { "floor",             "floor",             1,  1,  0},
    { "fmod",              "fmod",              2,  1,  0},
    { "modf",              "modf",              1,  2,  0},
    { "sign",              "sign",              1,  1,  0},

    { "sqrt",              "sqrt",              1,  1,  0},
    { "pow",               "pow",               2,  1,  0},
    { "log",               "log",               1,  1,  0},
    { "exp",               "exp",               1,  1,  0},
    { "log10",             "log10",             1,  1,  0},
    { "exp10",             "exp10",             1,  1,  0},

    { "sin",               "sin",               1,  1,  0},
    { "cos",               "cos",               1,  1,  0},
    { "tan",               "tan",               1,  1,  0},
    { "asin",              "asin",              1,  1,  0},
    { "acos",              "acos",              1,  1,  0},
    { "atan",              "atan",              1,  1,  0},
    { "atan2",             "atan2",             2,  1,  0},

    { "diff3",             "diff3",             6,  3,  0},
    { "dist3d",            "dist3d",            3,  1,  0},
    { "xyz_to_polar",      "xyz_to_polar",      3,  3,  0},
    { "polar_to_xyz",      "polar_to_xyz",      3,  3,  0},

    { "clear",             "clear",             0,  0,  0},
    { "clear_error",       "clear_error",       1,  1,  0},
    { "error?",            "error?",            0,  1,  0},
    { "error_bit",         "error_bit",         1,  1,  0},
    { "error_name",        "error_name",        1,  1,  0},
    { "error_num",         "error_num",         0,  1,  0},
    { "error_str",         "error_str",         1,  1,  0},
    { "is_set?",           "is_set?",           1,  1,  0},
    { "set_error",         "set_error",         1,  1,  0},

    { "array_keys",        "{ swap array_keys pop }list",  2,  1,  0},
    { "array_vals",        "{ swap array_vals pop }list",  2,  1,  0},

    { "array_appenditem",   "array_appenditem",   2,  1,  0},
    { "array_compare",      "array_compare",      2,  1,  0},
    { "array_cut",          "array_cut",          2,  2,  0},
    { "array_delitem",      "array_delitem",      2,  1,  0},
    { "array_delrange",     "array_delrange",     3,  1,  0},
    { "array_diff",         "array_diff",         2,  1,  0},
    { "array_excludeval",   "array_excludeval",   2,  1,  0},
    { "array_extract",      "array_extract",      2,  1,  0},
    { "array_findval",      "array_findval",      2,  1,  0},
    { "array_first",        "array_first",        1,  2,  0},
    { "array_getrange",     "array_getrange",     2,  1,  0},
    { "array_insertitem",   "array_insertitem",   3,  1,  0},
    { "array_insertrange",  "array_insertrange",  3,  1,  0},
    { "array_interpret",    "array_interpret",    1,  1,  0},
    { "array_intersect",    "array_intersect",    2,  1,  0},
    { "array_join",         "array_join",         2,  1,  0},
    { "array_last",         "array_last",         1,  2,  0},
    { "array_matchkey",     "array_matchkey",     2,  1,  0},
    { "array_matchval",     "array_matchval",     2,  1,  0},
    { "array_nested_del",   "array_nested_del",   2,  1,  0},
    { "array_nested_get",   "array_nested_get",   2,  1,  0},
    { "array_nested_set",   "array_nested_set",   3,  1,  0},
    { "array_next",         "array_next",         2,  2,  0},
    { "array_prev",         "array_prev",         2,  2,  0},
    { "array_reverse",      "array_reverse",      1,  1,  0},
    { "array_setrange",     "array_setrange",     3,  1,  0},
    { "array_sort",         "array_sort",         2,  1,  0},
    { "array_sort_indexed", "array_sort_indexed", 3,  1,  0},
    { "array_union",        "array_union",        2,  1,  0},

    { "dbtop",             "dbtop",             0,  1,  0},
    { "dbcmp",             "dbcmp",             2,  1,  0},
    { "unparseobj",        "unparseobj",        1,  1,  0},
    { "owner",             "owner",             1,  1,  0},
    { "setown",            "setown",            2,  0,  0},
    { "location",          "location",          1,  1,  0},
    { "moveto",            "moveto",            2,  0,  0},
    { "contents",          "contents",          1,  1,  0},
    { "contents_array",    "contents_array",    1,  1,  0},
    { "exits",             "exits",             1,  1,  0},
    { "exits_array",       "exits_array",       1,  1,  0},
    { "next",              "next",              1,  1,  0},
    { "nextowned",         "nextowned",         1,  1,  0},
    { "findnext",          "findnext",          4,  1,  0},
    { "nextentrance",      "nextentrance",      2,  1,  0},
    { "controls",          "controls",          2,  1,  0},

    { "copyobj",           "copyobj",           1,  1,  0},
    { "copyplayer",        "copyplayer",        3,  1,  0},
    { "toadplayer",        "toadplayer",        2,  0,  0},
    { "newplayer",         "newplayer",         2,  1,  0},
    { "newroom",           "newroom",           2,  1,  0},
    { "newobject",         "newobject",         2,  1,  0},
    { "newexit",           "newexit",           2,  1,  0},
    { "newprogram",        "newprogram",        2,  1,  0},
    { "recycle",           "recycle",           1,  0,  0},

    { "ignoring?",         "ignoring?",         2,  1,  0},
    { "ignore_add",        "ignore_add",        2,  0,  0},
    { "ignore_del",        "ignore_del",        2,  0,  0},
    { "array_get_ignorelist", "array_get_ignorelist", 1, 1, 0},

    { "match",             "match",             1,  1,  0},
    { "rmatch",            "rmatch",            2,  1,  0},
    { "pmatch",            "pmatch",            1,  1,  0},
    { "part_pmatch",       "part_pmatch",       1,  1,  0},

    { "name_ok?",          "name_ok?",          1,  1,  0},
    { "pname_ok?",         "pname_ok?",         1,  1,  0},
    { "ext_name_ok?",      "ext_name_ok?",      2,  1,  0},

    { "pennies",           "pennies",           1,  1,  0},
    { "addpennies",        "addpennies",        2,  0,  0},
    { "movepennies",       "movepennies",       3,  0,  0},

    { "checkpassword",     "checkpassword",     2,  1,  0},
    { "newpassword",       "newpassword",       2,  0,  0},
    { "set",               "set",               2,  0,  0},
    { "flag?",             "flag?",             2,  1,  0},
    { "mlevel",            "mlevel",            1,  1,  0},

    { "ok?",               "ok?",               1,  1,  0},
    { "player?",           "player?",           1,  1,  0},
    { "room?",             "room?",             1,  1,  0},
    { "thing?",            "thing?",            1,  1,  0},
    { "exit?",             "exit?",             1,  1,  0},
    { "program?",          "program?",          1,  1,  0},

    { "sysparm",           "sysparm",           1,  1,  0},
    { "sysparm_array",     "sysparm_array",     1,  1,  0},
    { "setsysparm",        "setsysparm",        2,  0,  0},

    { "desc",              "desc",              1,  1,  0},
    { "drop",              "drop",              1,  1,  0},
    { "fail",              "fail",              1,  1,  0},
    { "name",              "name",              1,  1,  0},
    { "odrop",             "odrop",             1,  1,  0},
    { "ofail",             "ofail",             1,  1,  0},
    { "osucc",             "osucc",             1,  1,  0},
    { "setdesc",           "setdesc",           2,  0,  0},
    { "setdrop",           "setdrop",           2,  0,  0},
    { "setfail",           "setfail",           2,  0,  0},
    { "setname",           "setname",           2,  0,  0},
    { "setodrop",          "setodrop",          2,  0,  0},
    { "setofail",          "setofail",          2,  0,  0},
    { "setosucc",          "setosucc",          2,  0,  0},
    { "setsucc",           "setsucc",           2,  0,  0},
    { "succ",              "succ",              1,  1,  0},
    { "truename",          "truename",          1,  1,  0},

    { "getlink",           "getlink",           1,  1,  0},
    { "setlink",           "setlink",           2,  0,  0},
    { "getlinks",          "getlinks pop",      1, 99,  0},
    { "getlinks_array",    "getlinks_array",    1,  1,  0},
    { "setlinks_array",    "setlinks_array",    2,  0,  0},
    { "entrances_array",   "entrances_array",   1,  1,  0},
    { "timestamps",        "timestamps",        1,  4,  0},
    { "timestamps",        "timestamps",        1,  4,  0},
    { "stats",             "stats",             1,  7,  0},
    { "objmem",            "objmem",            1,  1,  0},
    { "objmem",            "objmem",            1,  1,  0},

    { "addprop",            "addprop",            4,  0,  0},
    { "array_filter_flags", "array_filter_flags", 2,  1,  0},
    { "array_filter_prop",  "array_filter_prop",  3,  1,  0},
    { "array_get_propdirs", "array_get_propdirs", 2,  1,  0},
    { "array_get_proplist", "array_get_proplist", 2,  1,  0},
    { "array_get_propvals", "array_get_propvals", 2,  1,  0},
    { "array_get_reflist",  "array_get_reflist",  2,  1,  0},
    { "array_put_proplist", "array_put_proplist", 3,  0,  0},
    { "array_put_propvals", "array_put_propvals", 3,  0,  0},
    { "array_put_reflist",  "array_put_reflist",  3,  0,  0},
    { "blessprop",          "blessprop",          2,  0,  0},
    { "envprop",            "envprop",            2,  2,  0},
    { "envpropstr",         "envpropstr",         2,  2,  0},
    { "getprop",            "getprop",            2,  1,  0},
    { "getpropfval",        "getpropfval",        2,  1,  0},
    { "getpropstr",         "getpropstr",         2,  1,  0},
    { "getpropval",         "getpropval",         2,  1,  0},
    { "blessed?",           "blessed?",           2,  1,  0},
    { "propdir?",           "propdir?",           2,  1,  0},
    { "nextprop",           "nextprop",           2,  1,  0},
    { "parseprop",          "parseprop",          4,  1,  0},
    { "parsepropex",        "parsepropex",        4,  2,  0},
    { "reflist_add",        "reflist_add",        3,  0,  0},
    { "reflist_del",        "reflist_del",        3,  0,  0},
    { "reflist_find",       "reflist_find",       3,  1,  0},
    { "reflist_get",        "array_get_reflist",  2,  1,  0},
    { "reflist_put",        "array_put_reflist",  3,  0,  0},
    { "remove_prop",        "remove_prop",        2,  0,  0},
    { "setprop",            "setprop",            3,  0,  0},
    { "unblessprop",        "unblessprop",        2,  0,  0},

    { "time",               "time",               0,  3,  0},
    { "date",               "date",               0,  3,  0},
    { "datetime",           "time date",          0,  6,  0},
    { "systime",            "systime",            0,  1,  0},
    { "systime_precise",    "systime_precise",    0,  1,  0},
    { "gmtoffset",          "gmtoffset",          0,  1,  0},
    { "timesplit",          "timesplit",          1,  8,  0},
    { "timefmt",            "timefmt",            2,  1,  0},
    { "sleep",              "sleep",              1,  0,  0},

    { "mode",               "mode",               0,  1,  0},
    { "setmode",            "setmode",            1,  0,  0},
    { "preempt",            "preempt",            0,  0,  0},
    { "foreground",         "foreground",         0,  0,  0},
    { "background",         "background",         0,  0,  0},
    { "queue",              "queue",              3,  1,  0},
    { "fork",               "fork",               0,  1,  0},
    { "kill",               "kill",               1,  1,  0},
    { "pid",                "pid",                0,  1,  0},
    { "ispid?",             "ispid?",             1,  1,  0},
    { "getpids",            "getpids",            1,  1,  0},
    { "getpidinfo",         "getpidinfo",         1,  1,  0},
    { "instances",          "instances",          1,  1,  0},
    { "compile",            "compile",            2,  1,  0},
    { "uncompile",          "uncompile",          1,  0,  0},
    { "compiled?",          "compiled?",          1,  1,  0},
    { "program_getlines",   "program_getlines",   3,  1,  0},
    { "program_setlines",   "program_setlines",   2,  0,  0},

    { "mcp_register",       "mcp_register",       3,  0,  0},
    { "mcp_register_event", "mcp_register_event", 3,  0,  0},
    { "mcp_bind",           "mcp_bind",           3,  0,  0},
    { "mcp_supports",       "mcp_supports",       2,  1,  0},
    { "mcp_send",           "mcp_send",           4,  0,  0},

    { "gui_available",      "gui_available",      1,  1,  0},
    { "gui_dlog_create",    "gui_dlog_create",    4,  1,  0},
    { "gui_dlog_simple",    "gui_dlog_simple",    2,  1,  0},
    { "gui_dlog_helper",    "gui_dlog_helper",    3,  1,  0},
    { "gui_dlog_show",      "gui_dlog_show",      1,  0,  0},
    { "gui_dlog_close",     "gui_dlog_close",     1,  0,  0},
    { "gui_ctrl_create",    "gui_ctrl_create",    4,  0,  0},
    { "gui_ctrl_command",   "gui_ctrl_command",   4,  0,  0},
    { "gui_values_get",     "gui_values_get",     1,  1,  0},
    { "gui_value_get",      "gui_value_get",      2,  1,  0},
    { "gui_value_set",      "gui_value_set",      3,  0,  0},

    { "debug_on",           "debug_on",           0,  0,  0},
    { "debug_off",          "debug_off",          0,  0,  0},
    { "debug_line",         "debug_line",         0,  0,  0},
    { "debugger_break",     "debugger_break",     0,  0,  0},

    { "version",            "version",            0,  1,  0},
    { "force",              "force",              2,  0,  0},
    { "force_level",        "force_level",        0,  1,  0},

    {0, 0, 0, 0, 0}
};


struct prim_info_t *
prim_lookup(const char*s)
{
    int i;
    for (i = 0; prims_list[i].name; i++) {
        if (!strcmp(prims_list[i].name, s)) {
            return &prims_list[i];
        }
    }
    return NULL;
}



int
process_file(const char *filename, const char *progname)
{
    int res = 0;
    if (progname) {
        /* Strip leading directory names. */
        const char *ptr = filename;
        while (*ptr) {
            if (*ptr == '/' || *ptr == '\\') {
                filename = ++ptr;
            } else {
                ptr++;
            }
        }
        fprintf(outf, "@program %s\n", progname);
        fprintf(outf, "1 99999 d\n1 i\n");
        fprintf(outf, "( Generated from %s by the MUV compiler. )\n", filename);
        fprintf(outf, "(   https://github.com/revarbat/muv )\n\n");
    }
    strlist_init(&inits_list);
    strlist_init(&using_list);
    strlist_init(&lvars_list);
    strlist_init(&sconst_list);
    strlist_init(&fvars_list);
    strlist_init(&vardecl_list);
    funclist_init(&funcs_list);

    /* Declare some utility commands. */
    funclist_add(&funcs_list, "cat", "array_interpret", 0, 1, 1);
    funclist_add(&funcs_list, "array_make", "", 0, 1, 1);
    funclist_add(&funcs_list, "array_dict_make", "{ swap array_explode pop }dict", 0, 1, 1);
    funclist_add(&funcs_list, "fmtstring", "\n2 try\n    array_explode 1 + rotate fmtstring\n    abort\ncatch\nendcatch", 1, 1, 1),
    funclist_add(&funcs_list, "fmttell", "\n2 try\n    array_explode 1 + rotate fmtstring\n    me @ swap notify\n    \"\" abort\ncatch pop\nendcatch 0", 1, 1, 1),
    funclist_add(&funcs_list, "execute", "{ rot rot array_explode 1 + rotate execute }list", 1, 1, 1),

    /* End of compiler defined funcs */
    funclist_add(&funcs_list, " ", "", 0, 0, 0),

    /* Reserve standard global vars. */
    strlist_add(&lvars_list, "me");
    strlist_add(&lvars_list, "loc");
    strlist_add(&lvars_list, "trigger");
    strlist_add(&lvars_list, "command");

    /* Server defined constants. */
    strlist_add(&sconst_list, "pr_mode");
    strlist_add(&sconst_list, "fg_mode");
    strlist_add(&sconst_list, "bg_mode");
    strlist_add(&sconst_list, "c_datum");
    strlist_add(&sconst_list, "c_menu");
    strlist_add(&sconst_list, "c_label");
    strlist_add(&sconst_list, "c_image");
    strlist_add(&sconst_list, "c_hrule");
    strlist_add(&sconst_list, "c_vrule");
    strlist_add(&sconst_list, "c_button");
    strlist_add(&sconst_list, "c_checkbox");
    strlist_add(&sconst_list, "c_radiobtn");
    strlist_add(&sconst_list, "c_edit");
    strlist_add(&sconst_list, "c_multiedit");
    strlist_add(&sconst_list, "c_combobox");
    strlist_add(&sconst_list, "c_listbox");
    strlist_add(&sconst_list, "c_spinner");
    strlist_add(&sconst_list, "c_scale");
    strlist_add(&sconst_list, "c_frame");
    strlist_add(&sconst_list, "c_notebook");

    res = yyparse();
    if (res == 2) {
        yyerror("Out of Memory");
    }

    if (res == 0) {
        char *inits = strlist_join(&inits_list, "\n", 0, -1);
        char *inits2 = indent(inits);
        const char *mainfunc = funcs_list.list[funcs_list.count-1].name;
        const char *initfunc;
        mainfunc = indent(mainfunc);
        initfunc = savefmt(": __start\n%s%s%s\n;\n", inits2, ((*inits2 && *mainfunc)?"\n":""), mainfunc);
        fprintf(outf, "%s", initfunc);;
        free(inits);
        free(inits2);
        free((void*)mainfunc);
        free((void*)initfunc);
    }

    strlist_free(&inits_list);
    strlist_free(&using_list);
    strlist_free(&lvars_list);
    strlist_free(&sconst_list);
    strlist_free(&fvars_list);
    strlist_free(&vardecl_list);
    funclist_free(&funcs_list);
    if (progname) {
        fprintf(outf, ".\nc\nq\n");
    }
    fclose(yyin);

    return res;
}


void
usage(const char* execname)
{
    fprintf(stderr, "Usage: %s [-h] [-w PROGNAME] [-o OUTFILE] FILE\n", execname);
}


int
main(int argc, char **argv)
{
    int res;
    const char *execname = argv[0];
    const char *filename = "STDIN";
    const char *progname = NULL;

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
            if (argc > 1) {
                usage(execname);
                exit(-3);
            }
            yyin = fopen(argv[0], "r");
            filename = argv[0];
            break;
        }
        argc--; argv++;
    }

    res = process_file(filename, progname);
    return -res;
}

/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */

