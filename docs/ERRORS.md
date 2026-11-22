# Errors

Every error has a code and a message. Codes that start with `LEC` are
found **before** the program runs; codes that start with `LER` are
found **while** it runs.

```text
main.lep:3: LEC3101: `+` needs the same unit on both sides, got kg and m
    ensure d = 2kg + 3m

lepthorn: runtime error: LER3002: index 5 is out of bounds for an array of length 3
```

## Look up a code

```sh
lepthornc explain LEC3101     # one error: its message and how to fix it
lepthornc explain             # every error, one per line
```

```text
LEC3101: unit_mismatch
message: `{1}` needs the same unit on both sides, got {2} and {3}
fix:     Make both sides the same kind of quantity, or convert one of them.
```

`{1}`, `{2}`, ... are filled in with the names and units of your
program.

## The code ranges

| Codes | Found by | What happens |
|---|---|---|
| `LEC1xxx` | the lexer, reading the text | the program does not run (`LEC1002` is only a message) |
| `LEC2xxx` | the parser, the grammar | the program does not run |
| `LEC30xx` | the checker: names, `ensure`, loops, `choose`, `loop_hz` | the program does not run |
| `LEC31xx` | the checker: units | the program does not run |
| `LEC7xxx` | the code generator | no program is written |
| `LER1xxx` | values and operators | the program stops, exit status 1 |
| `LER2xxx` | units and physics functions | the program stops, exit status 1 |
| `LER3xxx` | arrays, shapes, collections, text | the program stops, exit status 1 |
| `LER4xxx` | input (`take`, `read`) | the program stops, exit status 1 |
| `LER5xxx` | functions and `choose` | the program stops, exit status 1 |
| `LER6xxx` | timing (`deadline`, `timeout`) | a warning; the program goes on |
| `LER9xxx` | a bug in the compiler itself | the program stops; please report it |

Errors before running print every mistake with its file and line, then
nothing runs. Errors while running print
`lepthorn: runtime error: CODE: message` on standard error.

## Where the errors live

All errors are in one place, `src/core/errors/`, one file per group:

| File | Codes |
|---|---|
| `lexer_errors.lep` | `LEC1xxx` |
| `parser_errors.lep` | `LEC2xxx` |
| `checker_errors.lep` | `LEC30xx` |
| `unit_errors.lep` | `LEC31xx`, `LER2xxx` |
| `codegen_errors.lep` | `LEC7xxx` |
| `runtime_errors.lep` | `LER1xxx`, `LER3xxx`-`LER5xxx`, `LER9xxx` |
| `realtime_errors.lep` | `LER6xxx` |

`registrar.lep` keeps the list. The checker, the interpreter, the code
generator and the run-time code of every compiled program all take
their messages from it, so the interpreter and a compiled program
always print the same text.

## Add an error

One line in the file of its group:

```lepthorn
add_error(list, "LEC3101", "unit_mismatch",
    "`{1}` needs the same unit on both sides, got {2} and {3}",
    "Make both sides the same kind of quantity, or convert one of them.")
```

| Part | Meaning |
|---|---|
| code | the next free code in the group's range |
| name | how the compiler's code asks for it |
| message | what is printed; `{1}`, `{2}`, ... are filled in |
| help | one line on how to fix it, shown by `lepthornc explain` |

Then use it by name:

```lepthorn
ctv_error(sink, node.pos, error_line("unit_mismatch", [op, a, b]))
```

- In the run-time code (`src/codegen/cg_rt_*.lep`):
  `rt_error(ctx, "f_dimfail", "unit_mismatch_run", ["%s", "%s", "%s"])`.
  Each `{n}` becomes the printf format given (`%s`, `%lld`).
- A code or a name used twice stops the compiler, so every error stays
  unique.

## File error numbers

The `file::` functions do not stop the program when they fail. They
set a number, which `file::error()` returns. It is 0 after a call that
worked.

| Number | Meaning |
|---|---|
| `8001` | the file does not exist |
| `8002` | permission denied |
| `8003` | the file already exists |
| `8004` | the handle is not open (never opened, or closed) |
| `8005` | no space left on the device |
| `8006` | the file name is too long |
| `8007` | the open mode is not `r`, `w`, `a`, `r+` or `w+` |
| `8008` | opening or reading failed for another reason |
| `8009` | writing or closing failed for another reason |
| `8010` | the path is a directory |
| `8011` | a part of the path is not a directory |
| `8012` | too many files are open |

```lepthorn
ensure h = file::open("missing.txt", "r")
when file::error() != 0
    show "cannot open, code" file::error()
done()
```
