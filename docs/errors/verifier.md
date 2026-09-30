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
| `` `stop` used outside a loop `` | `stop` is not inside `repeat`, `every` or `loop_hz` |
| `` `next` used outside a loop `` | the same for `next` |
| `loop_hz expects a positive frequency in Hz, got 0Hz` | a literal frequency of 0 |
| `loop_hz expects a frequency in Hz, got 10ms; for a period use every 10ms` | a time where a frequency is needed |
| `loop_hz expects a frequency in Hz, got 100; write loop_hz 100Hz or loop_hz(100)` | a plain number without brackets |
| `loop_hz(n) takes a plain number of times per second, got 100Hz; ...` | a unit inside the brackets |
| `` `choose`: case labels must all be the same kind - ... `` | e.g. `case 1` and `case "b"` in one `choose` |
| `` `choose`: case 1 appears twice `` | the same label twice |

Example:

```lepthorn
ensure x = 5
x = 6
```

```text
main.lep:2: LEC3001: cannot reassign 'x' - declared with ensure (immutable)
    x = 6
```

A loop in the caller does not count for `stop` and `next` inside a
function: the function's own body must have the loop.

A function can only see its own parameters, its own variables and
`shared` variables. Using a top-level variable inside a function gives
`undeclared variable`. Make the variable `shared`, or pass it as an
argument.

The verifier does not check units or kinds of values yet. Those are
checked while the program runs (see [runtime.md](runtime.md)).
