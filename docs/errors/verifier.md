# Verifier Errors (LEC3xxx)

After parsing, the verifier checks the whole program, including every
function body. If it finds a problem, the program does not run and no
native code is made. Every problem is printed, not only the first.

All verifier errors use the code `LEC3001`:

| Message | Cause |
|---|---|
| `undeclared variable 'x'` | `x` is used but never declared with `ensure`, `suppose`, `take`, `read`, or as a parameter |
| `assignment to undeclared variable 'x'` | `x = ...` without an earlier declaration |
| `cannot reassign 'x' - declared with ensure (immutable)` | `x` was declared with `ensure` |
| `call to undefined function 'f'` | there is no `make f(...)` |
| `wrong number of arguments in call to 'f'` | the call does not pass one argument per parameter |
| `'x' is a shared suppose value, reassigned inside parallel without atomic` | wrap the change in `atomic` |

Example:

```lepthorn
ensure x = 5
x = 6
```

```text
LEC3001: cannot reassign 'x' - declared with ensure (immutable)
```

A function can only see its own parameters, its own variables and
`shared` variables. Using a top-level variable inside a function gives
`undeclared variable`. Make the variable `shared`, or pass it as an
argument.

The verifier does not check units or kinds of values yet. Those are
checked while the program runs (see [runtime.md](runtime.md)).
