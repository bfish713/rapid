%{
    open Ast
%}

%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA
%token PLUS MINUS TIMES DIVIDE ASSIGN
%token EQ NEQ LT LEQ GT GEQ
%token RETURN IF ELSE FOR WHILE FUNC IN
%token PRINTLN PRINTF // LOG
// %token INT BOOL FLOAT STRING

%token <int> INT_VAL
%token <bool> BOOL_VAL
%token <string> ID TYPE STRING_LIT
%token EOF

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left TIMES DIVIDE

%start program
%type <Ast.program> program


%% /* Parser Rules */


primtype:
    | TYPE { string_to_t($1) }
    /* todo: add arrays and dicts to primtype */


/* Base level expressions of a program:
 * TODO: Classes */
program:
    | /* nothing */     { [], [] }
    | program stmt SEMI { ($2 :: fst $1), snd $1 }
    | program func_decl { fst $1, ($2 :: snd $1) }


/* TODO: allow user defined types */
datatype_list:
    | datatype_list COMMA primtype { $3 :: $1 }
    | primtype                 { [$1] }
    | /* nothing */            { [] }


return_type:
    /* TODO: allow user defined types */
    | primtype                { [$1] }
    | LPAREN datatype_list RPAREN { $2 }

/*var declarations can now be done inline*/
func_decl:
    // func w/ return types
    | FUNC ID LPAREN arguments RPAREN return_type LBRACE fstmt_list RBRACE
    {{
        fname = $2;
        formals = $4;
        return = $6;
        body = List.rev $8
    }}
    // func w/o return types
    | FUNC ID LPAREN arguments RPAREN LBRACE fstmt_list RBRACE
    {{
        fname = $2;
        formals = $4;
        return = [];
        body = List.rev $7
    }}
    /* TODO: unsafe functions */


arguments:
    | /* nothing */ { [] }
    | formal_list   { List.rev $1 }


formal_list:
    /* TODO: allow user defined types */
    | primtype ID                   { [$2] }
    | formal_list COMMA primtype ID { $4 :: $1 }


/* a tuple here of (primtype, ID) */
var_decl:
    | primtype ID             { ($1 , $2, None) }
    | primtype ID ASSIGN expr { ($1 , $2, Some($4)) }


stmt_list:
    | /* nothing */  { [] }
    | stmt_list stmt SEMI { $2 :: $1 }


fstmt_list:
    | /* nothing */         { [] }
    | fstmt_list func_stmt { $2 :: $1 }


func_stmt:
    | RETURN expr SEMI { Return($2) }
    | stmt SEMI        { FStmt($1) }


stmt:
    | expr     { Expr($1) }
    | print    { Output($1) }
    | var_decl { VarDecl($1) }
    | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([])) }
    | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7) }
    | FOR LPAREN expr_opt SEMI expr_opt SEMI expr_opt RPAREN stmt
        { For($3, $5, $7, $9) }
    | WHILE LPAREN expr RPAREN stmt { While($3, $5) }


print:
    | PRINTLN LPAREN expr print_list RPAREN { Println($3 :: $4) }
    | PRINTF LPAREN STRING_LIT print_list RPAREN { Printf($3, $4) }


print_list:
    | /* nothing */         { [] }
    | COMMA expr            { [$2] }
    | print_list COMMA expr { $3 :: $1 }


expr_opt:
    | /* nothing */ { Noexpr }
    | expr          { $1 }


lit:
    | INT_VAL          { IntLit($1) }
    | BOOL_VAL         { BoolVal($1) }
    | STRING_LIT       { StringLit($1)}


expr:
    | lit              { $1 }
    /* TODO add float handling */
    | ID               { Id($1) }
    | expr PLUS   expr { Binop($1, Add,   $3) }
    | expr MINUS  expr { Binop($1, Sub,   $3) }
    | expr TIMES  expr { Binop($1, Mult,  $3) }
    | expr DIVIDE expr { Binop($1, Div,   $3) }
    | expr EQ     expr { Binop($1, Equal, $3) }
    | expr NEQ    expr { Binop($1, Neq,   $3) }
    | expr LT     expr { Binop($1, Less,  $3) }
    | expr LEQ    expr { Binop($1, Leq,   $3) }
    | expr GT     expr { Binop($1, Greater,  $3) }
    | expr GEQ    expr { Binop($1, Geq,   $3) }
    | ID ASSIGN expr   { Assign($1, $3) }
    | ID LPAREN actuals_opt RPAREN { Call($1, $3) }
    | LPAREN expr RPAREN { $2 }


actuals_opt:
    | /* nothing */ { [] }
    | actuals_list  { List.rev $1 }


actuals_list:
    | expr                    { [$1] }
    | actuals_list COMMA expr { $3 :: $1 }

%%
