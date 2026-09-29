# How the Compiler Works

`lepthornc` is written in Lepthorn and compiles itself. One program
does all the work:

```text
source files
  -> use: pull all files into one text
  -> lexer: text to tokens
  -> parser: tokens to a syntax tree
  -> verifier: check names, assignments and calls
  -> either  code generator: LLVM IR (.ll), then clang: program, .so or .a
     or      interpreter: run the tree directly (lepthornc eval)
```

## Source files (`src/`)

| Directory | What it does |
|---|---|
| `core/lang_syntax/` | `data_types.lep`: tokens and the lexer. `parser.lep`: the parser, which builds the syntax tree. |
| `core/ast/` | The tree node (`Node`) and the list that holds all nodes. Nodes point to each other by position in that list. |
| `core/ctv/` | The verifier: undeclared names, changes to `ensure` variables, unknown functions, argument counts, `shared` changes outside `atomic`. |
| `core/units/` | The unit table: each unit's dimension and its scale to SI. |
| `runtime/` | `primitives.lep`: records for functions and shapes. `interpreter.lep`: `lepthornc eval`. |
| `codegen/` | `cg_core`, `cg_expr`, `cg_stmt`, `cg_program`: syntax tree to LLVM IR. `cg_rt_*.lep`: the runtime, written as LLVM IR text and put into every compiled program. |
| `driver/` | `manifest.lep`: reads and checks `manifest.lepm`. `driver.lep`: the commands, `use` handling, profiles, targets, and calling clang. |
| `main.lep` | Pulls in everything and calls `lepthornc_main()`. |

Project commands (`build`, `test`, `promote`, `manifest`) first move to
the project root: the nearest directory, from the current one upward,
that has a `manifest.lepm`.

## Values

Every Lepthorn value is one 64-bit word, both in compiled programs and
in the interpreter:

| Value | Stored as |
|---|---|
| Number with no unit | its IEEE-754 bits plus 2^49 |
| `false`, `true` | 6, 7 |
| "no value" (a function that ended without `done(value)`) | 10 |
| anything else | a pointer to an object on the heap; the object starts with its kind |

The heap kinds are Text, Number with a unit (value plus 8 exponents),
shape, array, RingBuffer, Queue, Stack, file handle, Vector and Matrix.

Because every value has the same form, the code generator does not need
to know a value's type in advance. The runtime checks the kind when an
operation needs it. Shape fields are stored in the order they are
declared; a field is found through a table made for each program.

## Code generation

- Each `make` function becomes an LLVM function `@lf.<name>` that takes
  and returns 64-bit values. Each local variable has one slot on the
  stack.
- The call depth is counted and limited to 10000.
- The top-level statements become `main`. In a library they become
  `<name>_init`, and every function is also exported as
  `<name>_<function>`.
- `when` and loops become plain LLVM blocks and jumps.
- Each function is written to the `.ll` file as soon as it is made. Text
  constants, tables and the runtime come at the end.

## The runtime

The runtime is written as LLVM IR by the files `cg_rt_core`, `cg_rt_ops`,
`cg_rt_data`, `cg_rt_text`, `cg_rt_show` and `cg_rt_io`. It contains:

- memory: a simple allocator that never frees
- numbers, units and all operators
- shapes, arrays and the collections
- `text::`, `file::` and `sys::` functions
- printing (units in Unicode or ASCII, see [DATATYPES.md](DATATYPES.md))
- timing (`every`, `loop_hz`, `wait`, `deadline`, `timeout`), input,
  and the physics functions

It only calls libc and libm. The Linux constants it needs (open flags,
the layout of `stat` and `dirent`, error numbers) are in `cg_rt_io.lep`.
glibc and musl use the same ones on x86-64.

## The interpreter

`lepthornc eval` walks the same syntax tree. The program's values are
real runtime values inside the interpreter, so `a + b` in the program
is done by the same runtime code that compiled programs use. Shapes and
arrays are modelled separately so their fields and items can be
changed. Timing statements use the language's own `loop_hz`, `every`,
`wait`, `deadline` and `timeout`. `lepthornc test` checks that `eval`
and compiled programs give the same output.

## Building the compiler

The compiler is built by `bin/lepthornc`. There is no seed file and no
separate bootstrap compiler.

- `bin/lepthornc build --release` writes `build/release/bin/lepthornc`.
- When a compiler would write over its own file, it writes
  `build/<profile>/rebuild/bin/lepthornc` instead. So after
  `build/release/bin/lepthornc build --release`, `cmp` can compare the
  two. They must be the same, byte for byte.
- `lepthornc promote --release` copies the release build to
  `bin/lepthornc`, but only if it rebuilds itself exactly. If it was
  built by an older compiler, promote rebuilds it with itself first and
  promotes that rebuild once it reproduces itself.
- The IR always says `source_filename = "lepthorn"`, so the program does
  not depend on the directory it was built in.
- `--target <triple>` writes to `build/<profile>/<triple>/`. The target
  comes from the manifest's `[Target_Platform]` sections, or one of the
  two built-in ones. The system's own libc is found from
  `clang -print-target-triple`. For the other libc, the compiler looks
  for its files in `LEPTHORN_SYSROOT`, or next to clang
  (`<clang's dir>/../<triple>`), and checks for `crt1.o`.
- The profile (`--release`, `--profile <name>`, default `debug`) sets the
  optimisation level: a `[Profile]` section, or the built-in debug
  (`-O0`) and release (`-O2`).
- Clang is `--cc`, else `LEPTHORN_CLANG`, else `LEPTHORN_CC`, else
  `clang` on `PATH`. Programs are linked with `-lm` plus the target's
  `libraries`.
- The tests `compiler_self_build` and `rebuild_fixed_point` do the same
  rebuild checks inside `lepthornc test`. They find the compiler under
  test through the `LEPTHORNC` environment variable.

Adding a built-in function that the compiler's own source uses takes
two builds. The running compiler does not know the new function yet, so
first build a copy of the source where those uses are replaced, then
use that compiler to build the real source.
