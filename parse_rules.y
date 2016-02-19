%{

#define MAXIDENTLEN 128

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "strlist.h"
#include "keyval.h"
#include "funcinfo.h"
#include "strutils.h"
#include "mufprims.h"


struct kvmap global_consts;
struct kvmap function_consts;
struct strlist lvars_list;
struct strlist fvars_list;
struct strlist vardecl_list;
struct strlist inits_list;
struct strlist using_list;
struct funclist funcs_list;

FILE *yyin=NULL;
FILE *outf;
int yylineno = 1;

int yylex(void);
int yyparse(void);
void yyerror(char *s);


/* compiler state exception flag */
%}


%union {
    int token;
    char *str;
    int num_int;
    double num_float;
    struct strlist list;
    struct keyval_t keyval;
    struct funcinfo_t prim;
    struct gettersetter getset;
}


%token <num_int> INTEGER
%token <prim> PRIMITIVE DECLARED_FUNC
%token <str> FLOAT STR IDENT VAR CONST
%token <str> DECLARED_VAR
%token <keyval> DECLARED_CONST
%token <token> IF ELSE UNLESS
%token <token> FUNC RETURN TRY CATCH
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
%type <str> externdef simple_statement statement statements paren_expr
%type <str> comma_expr comma_expr_or_null compr_loop compr_cond
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
    | CONST proposed_varname ASGN expr ';' {
            $$ = savestring("");
            kvmap_add(&global_consts, $2, $4);
            free($2); free($4);
        }
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
        kvmap_clear(&function_consts);
    } ;

externdef:
      EXTERN ret_count_type proposed_funcname '(' argvarlist opt_varargs ')' ';' {
            funclist_add(&funcs_list, $3, $3, $5.count - ($6?1:0), $2, $6);
            free($3);
            strlist_free(&$5);
            strlist_clear(&fvars_list);
            strlist_clear(&vardecl_list);
        }
    | EXTERN ret_count_type proposed_funcname '(' argvarlist opt_varargs ')' ASGN STR ';' {
            funclist_add(&funcs_list, $3, $9, $5.count - ($6?1:0), $2, $6);
            free($3);
            strlist_free(&$5);
            free($9);
            strlist_clear(&fvars_list);
            strlist_clear(&vardecl_list);
        }
    ;

bad_proposed_funcname: DECLARED_VAR { $$ = $1; }
    | DECLARED_CONST { $$ = savestring($1.key); keyval_free(&$1); }
    | DECLARED_FUNC { $$ = savestring($1.name); }
    ;

good_proposed_funcname: IDENT { $$ = $1; }
    | PRIMITIVE { $$ = savestring($1.name); } /* allow overriding primitives */
    ;

proposed_funcname:
      good_proposed_funcname { $$ = $1; }
    | bad_proposed_funcname {
        char buf[1024];
        snprintf(buf, sizeof(buf), "Indentifier '%s' already declared.", $1);
        yyerror(buf);
        YYERROR;
    }
    ;

undeclared_function: IDENT { $$ = $1; }
    | DECLARED_VAR { $$ = $1; }
    | DECLARED_CONST { $$ = savestring($1.key); keyval_free(&$1); }
    ;

function: DECLARED_FUNC { $$ = $1; }
    | undeclared_function {
            char buf[1024];
            snprintf(buf, sizeof(buf), "Undeclared function '%s'.", $1);
            yyerror(buf);
            YYERROR;
        }
    ;

bad_proposed_varname: DECLARED_VAR { $$ = $1; }
    | DECLARED_CONST { $$ = savestring($1.key); keyval_free(&$1); }
    | DECLARED_FUNC { $$ = savestring($1.name); }
    ;

good_proposed_varname: IDENT { $$ = $1; }
    | PRIMITIVE { $$ = savestring($1.name); } /* allow overriding primitives */
    ;

proposed_varname: good_proposed_varname { $$ = $1; }
    | bad_proposed_varname {
        char buf[1024];
        snprintf(buf, sizeof(buf), "Indentifier '%s' already declared.", $1);
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
            snprintf(buf, sizeof(buf), "Undeclared variable '%s'.", $1);
            yyerror(buf);
            YYERROR;
        }
    ;

ret_count_type:
      VOID { $$ = 0; }
    | SINGLE  { $$ = 1; }
    | MULTIPLE { $$ = 99; }
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

simple_statement:
      comma_expr { $$ = savefmt("%s pop", $1); free($1); }
    | RETURN { $$ = savestring("0 exit"); }
    | RETURN expr { $$ = savefmt("%s exit", $2); free($2); }
    | BREAK { $$ = savestring("break"); }
    | CONTINUE { $$ = savestring("continue"); }
    ;

statement: ';' { $$ = savestring(""); }
    | simple_statement ';' { $$ = $1; }
    | simple_statement IF paren_expr ';' {
            char *body = indent($1);
            $$ = savefmt("%s if\n%s\nthen", $3, body);
            free($1); free($3);
            free(body);
        }
    | simple_statement UNLESS paren_expr ';' {
            char *body = indent($1);
            $$ = savefmt("%s not if\n%s\nthen", $3, body);
            free($1); free($3);
            free(body);
        }
    | VAR fvarlist ';' { $$ = $2; }
    | CONST proposed_varname ASGN expr ';' {
            $$ = savestring("");
            kvmap_add(&function_consts, $2, $4);
            free($2); free($4);
        }
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
        char *basecall;
        if ($1.hasvarargs) {
            if ($3.count < $1.expects) {
                char buf[1024];
                snprintf(buf, sizeof(buf),
                    "Function '%s' expects at least %d args, but was provided %d args.",
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
                    "Function '%s' expects %d args, but was provided %d args.",
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
            basecall = savefmt("%s%s{%s\n}list %s", fargs, (*fargs? " ":""), ivargs, $1.code);
            free(fargs);
            free(vargs);
            free(ivargs);
        } else {
            char* funcargs = strlist_wrap(&$3, 0, -1);
            basecall = savefmt("%s%s%s", funcargs, (*funcargs?" ":""), $1.code);
            free(funcargs);
        }
        if ($1.returns == 0) {
            $$ = savefmt("%s 0", basecall);
        } else if ($1.returns == 1) {
            $$ = savestring(basecall);
        } else {
            $$ = savefmt("{ %s }list", basecall);
        }
        free(basecall);
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
                    "Built-in primitive '%s' expects %d args, but was provided %d args.",
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

compr_cond: /* nothing */ { $$ = savestring(""); }
    | IF paren_expr {
            $$ = savefmt("%s\nif", $2);
            free($2);
        }
    | UNLESS paren_expr {
            $$ = savefmt("%s\nnot if", $2);
            free($2);
        }
    ;

compr_loop:
      '(' variable IN expr ')' {
            $$ = savefmt("%s\nforeach %s ! pop", $4, $2);
            free($2); free($4);
        }
    | '(' variable KEYVAL variable IN expr ')' {
            $$ = savefmt("%s\nforeach %s ! %s !", $6, $4, $2);
            free($2); free($4);
        }
      
expr: INTEGER { $$ = savefmt("%d", $1); }
    | '#' MINUS INTEGER { $$ = savefmt("#-%d", $3); }
    | '#' INTEGER { $$ = savefmt("#%d", $2); }
    | FLOAT { $$ = $1; }
    | STR { $$ = savefmt("\"%s\"", $1); free($1); }
    | BOOLTRUE { $$ = savestring("1"); }
    | BOOLFALSE { $$ = savestring("0"); }
    | DECLARED_CONST { $$ = savestring($1.val); keyval_free(&$1); }
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
    | '[' expr FOR compr_loop compr_cond ']' {
            /* list comprehension */
            char *body = indent($2);
            if (*$5) {
                char *cond = indent($5);
                char *ibody = indent(body);
                $$ = savefmt("[] %s\n%s\n%s swap []<-\n    then\nrepeat", $4, cond, ibody);
                free(ibody);
                free(cond);
            } else {
                $$ = savefmt("[] %s\n%s swap []<-\nrepeat", $4, body);
            }
            free(body);
            free($2); free($4); free($5);
        }
    | '[' dictlist ']' {
            char *items = strlist_wrap(&$2, 0, -1);
            char *body = indent(items);
            $$ = savefmt("{\n%s}dict", body);
            free(body); free(items);
            strlist_free(&$2);
        }
    | '[' expr KEYVAL expr FOR compr_loop compr_cond ']' {
            /* list comprehension */
            char *kexpr = indent($2);
            char *vexpr = indent($4);
            if (*$7) {
                char *cond = indent($7);
                char *ikexpr = indent(kexpr);
                char *ivexpr = indent(vexpr);
                $$ = savefmt("[] %s\n%s\n%s swap\n%s ->[]\n    then\nrepeat", $6, cond, ivexpr, ikexpr);
                free(cond);
                free(ikexpr);
                free(ivexpr);
            } else {
                $$ = savefmt("[] %s\n%s swap\n%s ->[]\nrepeat", $6, vexpr, kexpr);
            }
            free(kexpr);
            free(vexpr);
            free($2); free($4); free($6); free($7);
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
        {"break",     BREAK,     -1},
        {"case",      CASE,      -1},
        {"catch",     CATCH,     -1},
        {"const",     CONST,     -1},
        {"continue",  CONTINUE,  -1},
        {"default",   DEFAULT,   -1},
        {"del",       DEL,       -1},
        {"do",        DO,        -1},
        {"else",      ELSE,      -1},
        {"extern",    EXTERN,    -1},
        {"false",     BOOLFALSE, -1},
        {"for",       FOR,       -1},
        {"func",      FUNC,      -1},
        {"if",        IF,        -1},
        {"in",        IN,        -1},
        {"muf",       MUF,       -1},
        {"multiple",  MULTIPLE,  -1},
        {"push",      PUSH,      -1},
        {"return",    RETURN,    -1},
        {"single",    SINGLE,    -1},
        {"switch",    SWITCH,    -1},
        {"top",       TOP,       -1},
        {"true",      BOOLTRUE,  -1},
        {"try",       TRY,       -1},
        {"unless",    UNLESS,    -1},
        {"until",     UNTIL,     -1},
        {"using",     USING,     -1},
        {"var",       VAR,       -1},
        {"void",      VOID,      -1},
        {"while",     WHILE,     -1},
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



int
yylex()
{
    char in[BUFSIZ];
    char *p = in;
    int c, digit;
    struct funcinfo_t* pinfo;
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
        const char *cp;

        while ((c = fgetc(yyin)) != EOF && (isalnum(c) || c == '_' || c == '?')) {
            if (++cnt + 1 >= MAXIDENTLEN) {
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

        /* function constants */
        cp = kvmap_get(&function_consts, in);
        if (cp) {
            yylval.keyval.key = savestring(in);
            yylval.keyval.val = savestring(cp);
            return DECLARED_CONST;
        }

        /* global constants */
        cp = kvmap_get(&global_consts, in);
        if (cp) {
            yylval.keyval.key = savestring(in);
            yylval.keyval.val = savestring(cp);
            return DECLARED_CONST;
        }

        /* primitives match after everything else. */
        if ((pinfo = funclookup(in))) {
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
                yyerror("string too long.");
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
            yyerror("EOF in quoted string.");
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



void
yyerror(char *arg)
{
    fprintf(stderr, "ERROR in line %d: %s\n", yylineno, arg);
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
    strlist_init(&fvars_list);
    strlist_init(&vardecl_list);
    funclist_init(&funcs_list);
    kvmap_init(&global_consts);
    kvmap_init(&function_consts);

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
    kvmap_add(&global_consts, "REG_ICASE",    "reg_icase");
    kvmap_add(&global_consts, "REG_ALL",      "reg_all");
    kvmap_add(&global_consts, "REG_EXTENDED", "reg_extended");
    kvmap_add(&global_consts, "PR_MODE",      "pr_mode");
    kvmap_add(&global_consts, "FG_MODE",      "fg_mode");
    kvmap_add(&global_consts, "BG_MODE",      "bg_mode");
    kvmap_add(&global_consts, "C_DATUM",      "c_datum");
    kvmap_add(&global_consts, "C_MENU",       "c_menu");
    kvmap_add(&global_consts, "C_LABEL",      "c_label");
    kvmap_add(&global_consts, "C_IMAGE",      "c_image");
    kvmap_add(&global_consts, "C_HRULE",      "c_hrule");
    kvmap_add(&global_consts, "C_VRULE",      "c_vrule");
    kvmap_add(&global_consts, "C_BUTTON",     "c_button");
    kvmap_add(&global_consts, "C_CHECKBOX",   "c_checkbox");
    kvmap_add(&global_consts, "C_RADIOBTN",   "c_radiobtn");
    kvmap_add(&global_consts, "C_EDIT",       "c_edit");
    kvmap_add(&global_consts, "C_MULTIEDIT",  "c_multiedit");
    kvmap_add(&global_consts, "C_COMBOBOX",   "c_combobox");
    kvmap_add(&global_consts, "C_LISTBOX",    "c_listbox");
    kvmap_add(&global_consts, "C_SPINNER",    "c_spinner");
    kvmap_add(&global_consts, "C_SCALE",      "c_scale");
    kvmap_add(&global_consts, "C_FRAME",      "c_frame");
    kvmap_add(&global_consts, "C_NOTEBOOK",   "c_notebook");

    res = yyparse();
    if (res == 2) {
        yyerror("Out of Memory.");
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
    strlist_free(&fvars_list);
    strlist_free(&vardecl_list);
    funclist_free(&funcs_list);
    kvmap_free(&global_consts);
    kvmap_free(&function_consts);

    if (progname) {
        fprintf(outf, ".\n");
        fprintf(outf, "c\n");
        fprintf(outf, "q\n");
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

