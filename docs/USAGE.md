# Using lepthornc

`lepthornc` is the Lepthorn compiler. One program does everything: it
compiles, runs, checks, builds projects and runs tests.

## Running one file

```sh
lepthornc eval hello.lep       # run it in the interpreter
lepthornc run hello.lep        # compile it to native code, then run it
lepthornc compile hello.lep    # compile it; writes ./hello
lepthornc check hello.lep      # check it without running it
lepthornc resolve hello.lep    # print the source with every `use` pulled in
```

`eval` and `run` give the same output and the same exit status. `run`
puts its program in `build/run/` in the current directory.

A program that reads input with `take` or `read` waits for you to type.
To give the input in advance, pipe it in:

```sh
echo "40kg" | lepthornc eval examples/16_take_input.lep
```

## Working in a project

A project is a directory with a `manifest.lepm` (see
[PROJECTS.md](PROJECTS.md) and [MANIFEST.md](MANIFEST.md)). These
commands find the project by looking for `manifest.lepm` in the current
directory and then upward, so they work from any directory inside it.

```sh
lepthornc new rover            # make a new project (a program)
lepthornc new mathlib --lib    # make a new library project
lepthornc build                # build every target
lepthornc build --release      # build with optimisation
lepthornc test                 # run the tests
lepthornc promote --release    # copy a checked build to bin/
lepthornc resolve               # show what manifest.lepm means on this machine
```

## All commands

| Command | What it does |
|---|---|
| `compile <file>` | compile one file to a native program |
| `run <file>` | compile one file, then run it |
| `eval <file>` | run one file in the interpreter |
| `check <file>` | lex, parse and check one file, without running it |
| `resolve <file.lep>` | print the source with every `use` included |
| `resolve [manifest.lepm]` | show what the project's manifest means on this machine: settings, targets, the Clang in use, the system's libc. With no file, the nearest `manifest.lepm` is used |
| `build` | build the project's targets |
| `test` | run the project's tests |
| `promote` | copy the project's built programs to `bin/` |
| `new <name> [--lib]` | make a new project |
| `version` | print the version |
| `help` | print the list of commands |

`lepthornc help` (or `-h`, `--help`) prints the commands and options.

## Options

| Option | Used with | Meaning |
|---|---|---|
| `-o <path>` | `compile`, `build` | where to write the program |
| `--release` | `compile`, `run`, `build`, `test`, `promote` | the `release` profile (`-O2`) |
| `--profile <name>` | `build`, `test`, `promote` | any profile from the manifest; the default is `debug` (`-O0`) |
| `--target <triple>` | `compile`, `run`, `build`, `test`, `promote` | `x86_64-linux-gnu` or `x86_64-linux-musl` |
| `--bin <name>`, `--lib <name>` | `build`, `promote` | only this target |
| `--emit-llvm` | `compile`, `build` | keep the `.ll` file next to the program |
| `--cc <program>` | every command | the Clang to use |
| `--ascii` | `run`, `eval`, `test` | print units in ASCII |
| `--unicode` | `run`, `eval` | print units in Unicode (the default) |

## How errors look

Errors found before the program runs (lexer, parser and verifier) start
with the file and line, and show the line below:

```text
main.lep:2: LEC2001: expected a value, found the end of the line
    show speed +
```

When the error is in a file pulled in with `use`, that file is named:

```text
src/physics/drag.lep:14: LEC3001: undeclared variable 'area'
    done(0.5 * rho * v * v * area)
```

Every error in the program is printed, not only the first, and nothing
runs. The codes are explained in [errors/](errors/). Errors while the
program runs (`LEC8xxx`) are printed as
`lepthorn: runtime error: <message>`.

## How units are printed

Units are printed in Unicode by default:

```text
Force is: 245.166 kg·m/s² (N)
```

With `--ascii`, or with the environment variable `LEPTHORN_OUTPUT=ascii`:

```text
Force is: 245.166 kg*m/s^2 (N)
```

Only the way the unit is written changes, never the value. Compiled
programs read `LEPTHORN_OUTPUT` themselves, every time they print a
unit. Details are in [DATATYPES.md](DATATYPES.md).

## Exit status

| Status | Meaning |
|---|---|
| 0 | it worked |
| 1 | the program failed, or had errors in it |
| 2 | wrong command, wrong option, or wrong configuration |

A compiled program exits with its own status: 0 at the end, 1 after a
runtime error, or the number given to `sys::exit`.

## Environment variables

| Variable | Meaning |
|---|---|
| `LEPTHORN_OUTPUT` | `ascii` prints units in ASCII; anything else, or unset, prints Unicode |
| `LEPTHORN_CLANG` | the Clang to use (checked before `LEPTHORN_CC`) |
| `LEPTHORN_CC` | the Clang to use |
| `LEPTHORN_SYSROOT` | where the other libc lives, for `--target` builds |
| `LEPTHORNC` | set by `lepthornc test`: the compiler running the tests |

If no Clang variable is set, `lepthornc` uses `clang` from your `PATH`.
