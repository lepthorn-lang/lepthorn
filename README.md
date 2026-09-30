# Lepthorn

> Code that knows its physics, timing, and limits.

Lepthorn is a correctness-first systems programming language for
engineering, scientific, real-time, embedded, robotics and autonomous
systems. It is for software where a wrong result, a unit mistake, a bad
memory access or a late answer can make a real machine fail.


```lepthorn
ensure mass = 25kg
suppose force = force::gravity(mass)
show "Force is:" force
```

```text
Force is: 245.166 kg·m/s² (N)
```

`25kg` is a mass. Lepthorn keeps the unit through every calculation and
prints the result with its unit.

## Principles

- **Correctness first.** Code that breaks the language's rules is
  rejected, not run with a guessed meaning.
- **Physical quantities.** Units and dimensions are part of the core
  language.
- **Memory safety.** No pointers in user code, checked array access,
  and no "unsafe" escape hatch.
- **Real-time.** Timing is part of the language: `every`, `loop_hz`,
  `deadline`, `timeout`, `parallel`, `priority`, `atomic`, `shared`.
- **Native code.** Programs compile to native code through LLVM.
- **A small core.** Maths, physics, engineering and autonomous-system
  features live in engines and libraries, not in the core.

Lepthorn is not a language for web sites, mobile apps, databases or
business software. It is for software that controls machines.

## Status

`lepthornc 1.0.0 (self-hosted, native)`: the compiler is written in
Lepthorn and compiles itself. It needs no OCaml, no C source, no seed
and no bootstrap compiler.

Working today: variables with units, text and true/false, all
operators, `when`/`choose`/`repeat`, `every`/`loop_hz`/`deadline`/
`timeout`, functions and recursion, `shape` records, arrays, Queue,
Stack, RingBuffer, files, projects, tests, libraries, and native
programs for glibc and musl Linux. `lepthornc eval` runs the same
programs without compiling, with the same results.

Not done yet: unit checks before the program runs (units are checked
while it runs), real threads, the engines beyond a few functions, and
targets other than x86-64 Linux. The details are in
[docs/INTRODUCTION.md](docs/INTRODUCTION.md).

## Quick start

You need x86-64 Linux, Clang, and glibc or musl.

```sh
sudo just install                     # installs bin/lepthornc to /usr/local/bin
lepthornc version
lepthornc eval examples/gravity.lep   # run a program
lepthornc run examples/gravity.lep    # compile it natively, then run it

lepthornc new rover                   # make a project
cd rover
lepthornc build
lepthornc test
```

## Documentation

| Document | What is in it |
|---|---|
| [docs/INTRODUCTION.md](docs/INTRODUCTION.md) | the goals of the language, and what works today |
| [docs/book/INTRODUCTION.md](docs/book/INTRODUCTION.md) | first steps |
| [docs/USAGE.md](docs/USAGE.md) | every command and option |
| [docs/PROJECTS.md](docs/PROJECTS.md) | making, building and testing a project; libraries |
| [docs/MANIFEST.md](docs/MANIFEST.md) | the `manifest.lepm` file |
| [docs/BUILDING.md](docs/BUILDING.md) | building the compiler itself; glibc and musl |
| [docs/SPEC.md](docs/SPEC.md) | the whole language |
| [docs/GRAMMAR.md](docs/GRAMMAR.md) | the exact syntax |
| [docs/DATATYPES.md](docs/DATATYPES.md) | values, units and printing |
| [docs/DATATYPES_SPEC.md](docs/DATATYPES_SPEC.md) | the planned type system |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | how the compiler works inside |
| [docs/METHODOLOGY.md](docs/METHODOLOGY.md) | how features are added |
| [docs/errors/](docs/errors/) | every error code |
| [examples/](examples/) | a program for each feature |

## License

Apache License 2.0 (`SPDX-License-Identifier: Apache-2.0`). See
[LICENSE](LICENSE).
