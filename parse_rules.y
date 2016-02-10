%{

#define MAXIDENTLEN 128
#define STRBUFSIZ 2048

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <ctype.h>
#include <strings.h>

int yylex(void);
void yyerror(char *s);

static int stringoff;
static char varsbuf[STRBUFSIZ];

char *savefmt(const char *fmt, ...);
char *savestring(const char *);
char *indent(const char *);

struct gettersetter {
    char *get;
    char *set;
};

struct str_list {
    const char** list;
    short count;
    short cmax;
} lvars_list, fvars_list, inits_list;

void strlist_init(struct str_list *l);
void strlist_free(struct str_list *l);
void strlist_clear(struct str_list *l);
void strlist_add(struct str_list *l, const char *s);
int strlist_find(struct str_list *l, const char *s);
char *strlist_join(struct str_list *l, const char *s, int start, int end);

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
%token <str> STR IDENT DECLARED_VAR VAR
%token <token> IF ELSE FUNC RETURN TRY CATCH
%token <token> SWITCH CASE DEFAULT
%token <token> DO WHILE FOR IN
%token <token> UNTIL CONTINUE BREAK
%token <token> TOP PUSH MUF
%token <token> UNARY EXTERN VOID SINGLE MULTIPLE

%right THEN ELSE
%left ',' KEYVAL
%right ASGN PLUSASGN MINUSASGN MULTASGN DIVASGN MODASGN BITLEFTASGN BITRIGHTASGN BITANDASGN BITORASGN BITXORASGN
%left DECR INCR
/* %right '?' ':' */
%left OR
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
%left '[' ']' '(' ')'

%type <str> globalstatement funcdef
%type <str> proposed_funcname good_proposed_funcname bad_proposed_funcname
%type <prim> function
%type <getset> lvalue
%type <str> undeclared_function
%type <str> proposed_varname good_proposed_varname bad_proposed_varname
%type <str> variable undeclared_variable
%type <str> externdef statement statements paren_expr
%type <str> comma_expr comma_expr_or_null
%type <str> case_clause case_clauses default_clause
%type <str> function_call primitive_call expr subscripts
%type <str> lvardef lvarlist fvardef fvarlist
%type <list> arglist arglist_or_null argvarlist
%type <num_int> ret_count_type opt_varargs

%start program

%%

program: /* nothing */ { printf("$def cmp dup string? if strcmp not else = then\n"); }
    | program globalstatement { printf("%s\n", $2);  free($2); }
    | program funcdef { printf("%s\n", $2);  free($2); }
    | program externdef { }
    ;

globalstatement:
      VAR lvarlist ';' { $$ = $2; }
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
        $$ = savefmt(": %s[ %s -- ret ]\n%s 0\n;\n\n", $2, vars, body);
        free($2);
        strlist_free(&$4);
        free($9);
        free(body);
        free(vars);
        strlist_clear(&fvars_list);
    } ;

externdef: EXTERN ret_count_type proposed_funcname '(' argvarlist opt_varargs ')' ';' {
        funclist_add(&funcs_list, $3, $3, $5.count - ($6?1:0), $2, $6);
        free($3);
        strlist_free(&$5);
        strlist_clear(&fvars_list);
    } ;

bad_proposed_funcname: DECLARED_VAR { $$ = $1; }
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
    | SWITCH paren_expr '{' case_clauses default_clause '}' {
            char *exp = indent($2);
            char *body = indent($4);
            char *dflt = indent($5);
            $$ = savefmt("0 begin pop (switch)\n%s\n%s%srepeat pop", exp, body, dflt);
            free(exp); free(dflt); free(body);
            free($2); free($4); free($5);
        }
    | '{' statements '}' { $$ = $2; }
    ;

case_clause: CASE paren_expr statement {
        char *body = indent($3);
        $$ = savefmt("(case)\ndup %s cmp if\n%s break\nthen\n", $2, body);
        free(body);
        free($3); free($3);
    } ;

case_clauses: case_clause { $$ = $1; }
    | case_clauses case_clause { $$ = savefmt("%s%s", $1, $2); free($1); free($2); }
    ;

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
            char* fargs = strlist_join(&$3, " ", 0, $1.expects);
            char* vargs = strlist_join(&$3, " ", $1.expects, -1);
            $$ = savefmt("%s%s{ %s }list %s", fargs, (*fargs? " ":""), vargs, $1.code);
            free(fargs);
            free(vargs);
        } else {
            char* funcargs = strlist_join(&$3, " ", 0, -1);
            $$ = savefmt("%s %s", funcargs, $1.code);
            free(funcargs);
        }
        strlist_free(&$3);
    } ;

primitive_call:
      TOP { $$ = savestring(""); }
    | PUSH '(' arglist ')' { $$ = strlist_join(&$3, " ", 0, -1); strlist_free(&$3); }
    | MUF '(' STR ')' { $$ = $3; }
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
            char *args = strlist_join(&$3, " ", 0, -1);
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
            free($1);
        }
    | variable '[' expr ']' {
            $$.get = savefmt("%s @ %s []", $1, $3);
            $$.set = savefmt("%s @ %s ->[] %s !", $1, $3, $1);
            free($1); free($3);
        }
    | variable '[' expr ']' '[' subscripts {
            $$.get = savefmt("%s @ { %s %s }list array_nested_get", $1, $3, $6);
            $$.set = savefmt("%s @ { %s %s }list array_nested_set %s !", $1, $3, $6, $1);
            free($1); free($3); free($6);
        }
    ;

subscripts: expr ']' { $$ = $1; }
    | subscripts '[' expr ']' { $$ = savefmt("%s %s", $1, $3); free($1); free($3); }
    ;

expr: INTEGER { $$ = savefmt("%d", $1); }
    | '#' MINUS INTEGER { $$ = savefmt("#-%d", $3); }
    | '#' INTEGER { $$ = savefmt("#%d", $2); }
    | STR { $$ = savefmt("\"%s\"", $1); free($1); }
    | paren_expr { $$ = $1; }
    | function_call { $$ = $1; }
    | primitive_call { $$ = $1; }
    | lvalue { $$ = $1.get; free($1.set); }
    | '[' arglist_or_null ']' { char *items = strlist_join(&$2, " ", 0, -1); $$ = savefmt("{ %s }list", items); free(items); strlist_free(&$2); }
    | PLUS expr   %prec UNARY { $$ = $2; }
    | MINUS expr  %prec UNARY { $$ = savefmt("0 %s -", $2); free($2); }
    | NOT expr    %prec UNARY { $$ = savefmt("%s not", $2); free($2); }
    | BITNOT expr %prec UNARY { $$ = savefmt("%s -1 bitxor", $2); free($2); }
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
    | expr BITOR expr    { $$ = savefmt("%s %s bitor", $1, $3); free($1); free($3); }
    | expr BITXOR expr   { $$ = savefmt("%s %s bitxor", $1, $3); free($1); free($3); }
    | expr BITAND expr   { $$ = savefmt("%s %s bitand", $1, $3); free($1); free($3); }
    | expr BITLEFT expr  { $$ = savefmt("%s %s bitshift", $1, $3); free($1); free($3); }
    | expr BITRIGHT expr { $$ = savefmt("%s 0 %s - bitshift", $1, $3); free($1); free($3); }
    | INCR lvalue %prec UNARY { $$ = savefmt("%s 1 + dup %s", $2.get, $2.set); free($2.get); free($2.set); }
    | DECR lvalue %prec UNARY { $$ = savefmt("%s 1 - dup %s", $2.get, $2.set); free($2.get); free($2.set); }
    | lvalue INCR { $$ = savefmt("%s dup 1 + %s", $1.get, $1.set); free($1.get); free($1.set); }
    | lvalue DECR { $$ = savefmt("%s dup 1 - %s", $1.get, $1.set); free($1.get); free($1.set); }
    | lvalue ASGN expr       { $$ = savefmt("%s dup %s", $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue PLUSASGN expr   { $$ = savefmt("%s %s + dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue MINUSASGN expr  { $$ = savefmt("%s %s - dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue MULTASGN expr   { $$ = savefmt("%s %s * dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue DIVASGN expr    { $$ = savefmt("%s %s / dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue MODASGN expr    { $$ = savefmt("%s %s %% dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue BITORASGN expr  { $$ = savefmt("%s %s bitor dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue BITXORASGN expr { $$ = savefmt("%s %s bitxor dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue BITANDASGN expr { $$ = savefmt("%s %s bitand dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue BITLEFTASGN expr { $$ = savefmt("%s %s bitshift dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    | lvalue BITRIGHTASGN expr { $$ = savefmt("%s 0 %s - bitshift dup %s", $1.get, $3, $1.set); free($1.get); free($1.set); free($3); }
    /* | expr '?' expr ':' expr { $$ = savefmt("%s if %s else %s then", $1, $3, $5); free($1); free($3); free($5); } */
    ;


arglist_or_null: /* nothing */ { strlist_init(&$$); }
    | arglist { $$ = $1; }
    ;

arglist:
      expr { strlist_init(&$$); strlist_add(&$$, $1); free($1); }
    | arglist ',' expr { $$ = $1;  strlist_add(&$$, $3); free($3); }
    ;

fvardef: proposed_varname {
            $$ = savefmt("var %s", $1);
            strlist_add(&fvars_list, $1);
            free($1);
        }
    | proposed_varname ASGN expr {
            $$ = savefmt("%s var! %s", $3, $1);
            strlist_add(&fvars_list, $1);
            free($1);
            free($3);
        }
    ;

fvarlist: fvardef { $$ = $1; }
    | fvarlist ',' fvardef { $$ = savefmt("%s\n%s", $1, $3); free($1); free($3); }
    ;

%%


FILE *yyin=NULL;
int yylineno = 1;


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
    char totlen = 0;
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
        "do",        DO,        -1,
        "else",      ELSE,      -1,
        "extern",    EXTERN,    -1,
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
        "try",       TRY,       -1,
        "until",     UNTIL,     -1,
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
    int c;
    struct prim_info_t* pinfo;

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

        num = c - '0';
        while (isdigit(c = fgetc(yyin))) {
            num = (num * 10) + (c - '0');
        }

        (void)ungetc(c,yyin);
        if (c == '\n') {
            yylineno--;
        }

        yylval.num_int = num;
        return(INTEGER);
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
            if (c == '=') {
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
    { "throw",        "abort",         1,  0,  0},
    { "abort",        "abort",         1,  0,  0},
    { "array_notify", "array_notify",  2,  0,  0},
    { "awake?",       "awake?",        1,  1,  0},
    { "copyobj",      "copyobj",       1,  1,  0},
    { "intostr",      "intostr",       1,  1,  0},
    { "moveto",       "moveto",        2,  0,  0},
    { "name",         "name",          1,  1,  0},
    { "notify",       "notify",        2,  0,  0},
    { "online",       "online_array",  0,  1,  0},
    { "read",         "read",          0,  1,  0},
    { "setdesc",      "setdesc",       2,  0,  0},
    { "setname",      "setname",       2,  0,  0},
    { "strcat",       "strcat",        2,  1,  0},
    { "strcmp",       "strcmp",        2,  1,  0},
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
main()
{
    int res;
    yyin = stdin;

    strlist_init(&inits_list);
    strlist_init(&lvars_list);
    strlist_init(&fvars_list);
    funclist_init(&funcs_list);

    /* Reserve ME and LOC vars, even if they aren't really LVARS. */
    strlist_add(&lvars_list, "me");
    strlist_add(&lvars_list, "loc");

    res = yyparse();
    if (res == 2) {
        yyerror("Out of Memory");
    }

    char *inits = strlist_join(&inits_list, "\n", 0, -1);
    char *inits2 = indent(inits);
    char *mainfunc = indent(funcs_list.list[funcs_list.count-1].name);
    char *initfunc = savefmt(": __inits\n%s\n%s\n;\n\n", inits2, mainfunc);
    fprintf(stdout, "%s", initfunc);;
    free(inits);
    free(inits2);
    free(mainfunc);
    free(initfunc);

    strlist_free(&inits_list);
    strlist_free(&lvars_list);
    strlist_free(&fvars_list);
    funclist_free(&funcs_list);

    return -res;
}


