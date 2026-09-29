# Grammar

This is the full syntax that `lepthornc` accepts today. It is taken from
the lexer (`src/core/lang_syntax/data_types.lep`) and the parser
(`src/core/lang_syntax/parser.lep`). What each part means is in
[SPEC.md](SPEC.md).

## Notation

```text
a | b        a or b
[ a ]        a is optional
{ a }        a, zero or more times
'x'          the exact characters x
NAME         a token from the lexical grammar
```

## Lexical grammar

A source file is UTF-8 text. Lines end with LF (`\n`). A CR (`\r`) is
not skipped, so files with Windows line endings do not parse.

```text
LETTER      = 'a'..'z' | 'A'..'Z' | '_'
DIGIT       = '0'..'9'
IDENT       = LETTER { LETTER | DIGIT }
NUMBER      = DIGIT { DIGIT } [ '.' DIGIT { DIGIT } ] [ UNIT ]
UNIT        = LETTER { LETTER }              (no space before it)
STRING      = '"' { any character except '"' } '"'
NEWLINE     = '\n'
```

- A number starts with a digit. `.5` is not a number; write `0.5`.
  There is no exponent form (`1e3`); write `1000`.
- The unit is the letters right after the digits: `25kg`, `10ms`,
  `9.81mps`. The unit must be in the unit table (see
  [DATATYPES.md](DATATYPES.md)). A unit cannot contain `/` or digits,
  so `9.81m/s` is the number `9.81m` divided by the variable `s`.
- A string ends at the next `"`. It can cover several lines. There are
  no escape sequences: `\n` is a backslash and an `n`. To get a quote
  or a newline, use `text::from_code(34)` or `text::from_code(10)`.
- Spaces and tabs between tokens are ignored.

### Comments

```text
COMMENT     = '(*' { any text or COMMENT } '*)'
```

Comments nest: `(* a (* b *) c *)` is one comment. A comment that is
never closed gives `LEC1001`.

`//` is not a comment in Lepthorn. The lexer prints `LEC1002`, skips to
the end of the line, and goes on.

### Line breaks

A NEWLINE ends a statement. Blank lines and comment lines are skipped.
Inside `( )` or `[ ]` a line break is ignored, so a call or a list can
cover several lines:

```lepthorn
ensure drone = Drone(
    name = "scout",
    mass = 1.2kg
)
```

There are no semicolons.

### Keywords

```text
ensure   suppose   show     take     read     done
make     shape     when     otherwise
repeat   until     stop     next     choose   case
every    loop_hz   wait     deadline timeout
parallel priority  sync     atomic   shared
watch    interrupt
true     false     and      or       not
```

Keywords cannot be used as names.

Three pieces are joined into one token by the lexer:

```text
ENSURE_BLOCK   = 'ensure' '!'           (spaces allowed between)
SUPPOSE_BLOCK  = 'suppose' '!'
DONE_EMPTY     = 'done' '(' ')'         (spaces allowed inside)
```

`done()` closes a block. `done(expr)` returns a value from a function.

### Symbols

```text
(  )  [  ]  ,  .  :  ::  =
+  -  *  /  %  **
==  !=  <  >  <=  >=
&  |  ^  ~  <<  >>
+=  -=  *=  /=  %=  **=  &=  |=  ^=  <<=  >>=
```

## Program

```text
program     = { item }
item        = function | shape_decl | statement | NEWLINE
```

`make` and `shape` are only allowed at the top level. There are no
nested functions.

### use

`use` lines are handled before lexing. Each one is replaced by the text
of the file it names, and each file is included only once.

```text
use_line    = 'use' '"' path '"'            (relative to this file)
            | 'use' IDENT { '::' IDENT }     (from src/ in the project)
```

`use a::b::c` loads `src/a/b/c/module.lep` if it exists, otherwise
`src/a/b/c.lep`.

## Declarations

```text
function    = 'make' IDENT '(' [ IDENT { ',' IDENT } ] ')' NEWLINE
                  block
              DONE_EMPTY

shape_decl  = 'shape' IDENT NEWLINE
                  { IDENT ':' IDENT NEWLINE }
              DONE_EMPTY
```

A shape field is `name: Type`. The type name is read but not checked.

## Blocks

```text
block       = { statement | NEWLINE }
```

A block ends at the token that closes it (`done()`, `otherwise`,
`until` or `case`, depending on the statement).

## Statements

```text
statement   = 'ensure' IDENT '=' expr
            | 'suppose' IDENT '=' expr
            | 'shared' 'ensure' IDENT '=' expr
            | 'shared' 'suppose' IDENT '=' expr
            | [ 'shared' ] ENSURE_BLOCK NEWLINE decl_lines DONE_EMPTY
            | [ 'shared' ] SUPPOSE_BLOCK NEWLINE decl_lines DONE_EMPTY
            | IDENT '=' expr
            | IDENT compound_op expr
            | IDENT '.' IDENT '=' expr
            | IDENT '[' expr ']' '=' expr
            | call
            | 'show' expr { expr }
            | 'take' IDENT
            | 'read' IDENT
            | when_stmt
            | repeat_stmt
            | choose_stmt
            | 'stop'
            | 'next'
            | 'done' '(' expr ')'
            | 'every' expr NEWLINE block DONE_EMPTY
            | 'loop_hz' '(' expr ')' NEWLINE block DONE_EMPTY
            | 'wait' expr
            | 'deadline' expr NEWLINE block DONE_EMPTY
            | 'timeout' expr NEWLINE block DONE_EMPTY
            | 'parallel' NEWLINE { task | NEWLINE } DONE_EMPTY
            | 'atomic' NEWLINE block DONE_EMPTY
            | 'sync'
            | 'watch' expr NEWLINE block DONE_EMPTY
            | 'interrupt' '(' IDENT ')' NEWLINE block DONE_EMPTY

decl_lines  = { IDENT '=' expr NEWLINE | NEWLINE }

compound_op = '+=' | '-=' | '*=' | '/=' | '%=' | '**='
            | '&=' | '|=' | '^=' | '<<=' | '>>='

when_stmt   = 'when' expr NEWLINE block when_tail
when_tail   = 'otherwise' 'when' expr NEWLINE block when_tail
            | 'otherwise' NEWLINE block DONE_EMPTY
            | DONE_EMPTY

repeat_stmt = 'repeat' NEWLINE block DONE_EMPTY
            | 'repeat' NEWLINE block 'until' expr NEWLINE DONE_EMPTY
            | 'repeat' expr NEWLINE block DONE_EMPTY

choose_stmt = 'choose' expr NEWLINE
                  { 'case' STRING NEWLINE block | NEWLINE }
                  [ 'otherwise' NEWLINE block ]
              DONE_EMPTY

task        = 'priority' expr NEWLINE block DONE_EMPTY
            | statement
```

Notes:

- `x += e` means `x = x + e`. The same goes for every compound
  operator.
- `case` labels must be quoted text.
- Only a plain name can be indexed or have a field: `a[i]`, `p.x`. You
  cannot write `a[i][j]`, `p.pos.x` or `list[0].x`. Read the inner value
  into its own name first.

## Expressions

From lowest to highest precedence:

```text
expr        = or_expr
or_expr     = and_expr { 'or' and_expr }
and_expr    = not_expr { 'and' not_expr }
not_expr    = 'not' not_expr | bit_expr
bit_expr    = cmp_expr { ( '&' | '|' | '^' | '<<' | '>>' ) cmp_expr }
cmp_expr    = add_expr [ ( '==' | '!=' | '<' | '>' | '<=' | '>=' ) add_expr ]
add_expr    = mul_expr { ( '+' | '-' ) mul_expr }
mul_expr    = pow_expr { ( '*' | '/' | '%' ) pow_expr }
pow_expr    = unary [ '**' pow_expr ]
unary       = 'not' unary | '~' unary | primary
primary     = NUMBER
            | STRING
            | 'true' | 'false'
            | IDENT
            | IDENT '.' IDENT
            | IDENT '[' expr ']'
            | call
            | IDENT '(' IDENT '=' expr { ',' IDENT '=' expr } ')'
            | '[' [ expr { ',' expr } ] ']'
            | '(' expr ')'

call        = IDENT '(' [ expr { ',' expr } ] ')'
            | IDENT '::' IDENT '(' [ expr { ',' expr } ] ')'
```

Notes:

- `+ - * / %`, the bitwise operators, `and` and `or` group left to
  right. `**` groups right to left: `2 ** 3 ** 2` is `2 ** 9`.
- A comparison cannot be chained: write `a < b and b < c`, not
  `a < b < c`.
- The bitwise operators are below the comparisons, unlike C. So
  `a & b == c` means `a & (b == c)`, which is an error at run time
  because `&` needs numbers.
- `not` is low: `not a == b` means `not (a == b)`.
- `Name(field = value, ...)` builds a shape. The parser tells it apart
  from a call by the `=` after the first name.
- `and` and `or` always evaluate both sides.

## Things the grammar does not have

- Unary minus or plus. Write `0 - x` for a plain number. For a value
  with a unit, the zero needs the same unit: `0m - 5m`.
- Escape sequences in strings.
- `//` comments, semicolons, `++` and `--`.
- Typed declarations such as `ensure mass : Mass = 10kg`.
- Nested functions, lambdas, methods (`q.push(x)`), or function
  overloading.
- Chained indexing or field access (`a[0][1]`, `a.b.c`).

### A trap with show

`show` takes several expressions side by side, separated only by
spaces. An expression that starts with `(` or `[` right after another
one is read as a new argument:

```lepthorn
suppose grid = [[1, 2], [3, 4]]
show grid[1][1]       (* prints "[3, 4] [1]": two arguments *)
```
