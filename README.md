# Lepthorn

A programming language for engineering and real-time software: robots,
drones, vehicles, control loops, and science and engineering
calculations.

In Lepthorn a number can carry a unit, and the unit stays with it
through every calculation:

```lepthorn
shape Drone
    name: Text
    mass: Number
    thrust: Number
done()

make lift_margin(d)
    done(d.thrust - force::gravity(d.mass))
done()

ensure scout = Drone(name = "scout", mass = 1.2kg, thrust = 20N)
show "lift margin:" lift_margin(scout)
```

```text
lift margin: 8.23202 kg·m/s² (N)
```

This repository holds `lepthornc`, the Lepthorn compiler. It is written
in Lepthorn.

## Self-hosting

Lepthorn is self-hosted and natively compiled. The canonical compiler,
`bin/lepthornc`, is written in Lepthorn and compiles the Lepthorn
compiler source directly. Normal development and release builds do not
need OCaml, C source, a repository seed, or a separate bootstrap
compiler. The compiler can rebuild itself and produce an equivalent
native compiler binary. Separate target builds are supported for glibc
and musl systems.

There is no way to build the compiler on a machine that has no Lepthorn
compiler at all. This was removed on purpose: a new machine gets
Lepthorn by copying a `lepthornc` binary.

## What works today

- variables: `ensure` (cannot change), `suppose` (can change),
  `ensure!`/`suppose!` blocks, `shared`
- numbers with units, text, true/false
- arithmetic, comparison, logic and bitwise operators
- `when`/`otherwise`, `choose`/`case`, `repeat` (forever, N times,
  until), `stop`, `next`
- `every` and `loop_hz` loops on a fixed timing grid, `wait`,
  `deadline`, `timeout`
- functions with recursion
- `shape` records, arrays, RingBuffer, Queue, Stack
- files, environment, running commands
- `show`, `take`, `read`
- projects, tests, and libraries (`.so` and `.a`)
- native programs for glibc and musl Linux systems, and an interpreter
  (`lepthornc eval`) that gives the same results

## Not done yet

- checking units and types before the program runs (units are checked
  while it runs)
- real threads: `parallel` runs its tasks one after another; `watch`
  and `interrupt` run their body once
- unary minus, escape sequences in text
- vector and matrix arithmetic, trigonometry
- freeing memory: a program's memory is never freed while it runs
- targets other than x86-64 Linux, microcontrollers, hardware access

## Building Lepthorn

You need x86-64 Linux, Clang, and glibc or musl. It has been tested
with Clang 22.1.8, glibc 2.43 and musl 1.2.5. Clang 15 or newer should
work. Nothing else is needed: no OCaml, no C source, no network. `just`
is optional.

```sh
bin/lepthornc build --release        # makes build/release/bin/lepthornc
build/release/bin/lepthornc test     # the new compiler passes the tests
bin/lepthornc promote --release      # checks it, then copies it to bin/lepthornc
```

`promote` refuses a compiler that does not rebuild itself exactly.
Right after the compiler's source has changed, the new build was made
by the older compiler; `promote` then rebuilds it with itself and
promotes that rebuild once it reproduces itself.

To check by hand that the compiler rebuilds itself exactly:

```sh
rm -rf build
bin/lepthornc test
bin/lepthornc build --release
build/release/bin/lepthornc test
build/release/bin/lepthornc build --release
cmp build/release/bin/lepthornc build/release/rebuild/bin/lepthornc   # no output: identical
```

When a compiler would write over its own file, it writes to
`build/<profile>/rebuild/bin/` instead, so the two can be compared.
`lepthornc test` runs the same check (`compiler_self_build`,
`rebuild_fixed_point`).

### glibc and musl

```sh
bin/lepthornc build --release --target x86_64-linux-gnu    # build/release/x86_64-linux-gnu/bin/lepthornc
bin/lepthornc build --release --target x86_64-linux-musl   # build/release/x86_64-linux-musl/bin/lepthornc
```

musl programs are linked statically and run on any x86-64 Linux. glibc
programs are linked dynamically. Without `--target`, programs are built
for the libc that this system's Clang uses.

The compiler finds everything when it runs. It has no built-in paths:

- the project: the nearest `manifest.lepm`, from the current directory
  upward; every path in it is relative to that directory
- Clang: `--cc <program>`, else `LEPTHORN_CLANG`, else `LEPTHORN_CC`,
  else `clang` on `PATH`
- the system's libc: from `clang -print-target-triple`
- the other libc: `LEPTHORN_SYSROOT`, else `<clang's dir>/../<target>`
  (for example `/usr/x86_64-linux-musl` when Clang is `/usr/bin/clang`);
  its libraries are looked for in `lib64`, `lib`, `usr/lib64` and
  `usr/lib`

`lepthornc manifest` shows what all of this is on the current machine.

### Installing

`lepthornc` is one file. Copy it to a directory on your `PATH`:

```sh
just install     # copies bin/lepthornc to $LEPTHORN_BINDIR, or ~/.local/bin
```

The `justfile` runs `lepthornc` from `PATH` (or `LEPTHORNC`):
`just release`, `just gnu`, `just musl`, `just test`, `just fixed-point`,
`just promote`, `just install`, `just update` (promote, then install),
`just verify` (the full check above, plus both targets), `just clean`.

## Commands

```text
lepthornc compile <file.lep> [-o <out>] [--release] [--target <t>] [--emit-llvm]
lepthornc run <file.lep> [--release] [--target <t>] [--ascii]   compile, then run
lepthornc eval <file.lep> [--ascii]   run without compiling
lepthornc check <file.lep>        check only
lepthornc resolve <file.lep>      print the source with every use pulled in

in a project (the nearest manifest.lepm, from here upward):
lepthornc build [--release | --profile <p>] [--target <t>] [--bin <n> | --lib <n>]
                [-o <out>] [--emit-llvm]
lepthornc test [--release | --profile <p>] [--target <t>] [--ascii]
lepthornc promote [--release | --profile <p>] [--target <t>] [--bin <n>]
lepthornc manifest                show what manifest.lepm resolves to
lepthornc new <name> [--lib]      make a new project (a program, or a library)
lepthornc version
```

Every command also takes `--cc <program>`. Exit status: 0 success,
1 failure, 2 wrong command or configuration. `--release` means
`--profile release`; the default profile is `debug`.

## Build layout

```text
bin/<name>                          promoted programs (bin/lepthornc is the compiler)
build/
├── debug/                          lepthornc build             (-O0)
│   ├── bin/<name>                  kind = "bin"
│   └── lib/lib<name>.so .a         kind = "library"
├── release/                        lepthornc build --release   (-O2)
│   ├── bin/<name>
│   ├── lib/lib<name>.so .a
│   ├── rebuild/bin/<name>          a compiler's rebuild of itself
│   ├── x86_64-linux-gnu/bin/...    --target x86_64-linux-gnu
│   └── x86_64-linux-musl/bin/...   --target x86_64-linux-musl
└── <profile>/...                   --profile <profile>
```

`build/` only holds generated files. `rm -rf build` is always safe.

## manifest.lepm

A project is a directory with a `manifest.lepm`. This is the compiler's
own:

```toml
[Package]
    name = "lepthornc"
    version = "1.0.0"
    description = "The native compiler for Lepthorn."
    authors = ["Ali Zain"]
    license = "Apache-2.0"
    license_file = "LICENSE"
    readme = "README.md"

[Target]
    name = "lepthornc"
    kind = "bin"
    source = "src/main.lep"

[Test]
    tests = "tests/"

[Profile]
    name = "debug"
    optimization = "none"

[Profile]
    name = "release"
    optimization = "O2"

[Target_Platform]
    triple = "x86_64-linux-gnu"
    libc = "glibc"
    link = "dynamic"
    libraries = ["m"]

[Target_Platform]
    triple = "x86_64-linux-musl"
    libc = "musl"
    link = "static"
    libraries = ["m"]
```

Each `key = value` line belongs to the `[Section]` above it. Values are
quoted text or lists of quoted text. A line starting with `#` or `//`
is a comment. An unknown section or key is an error with its line
number.

| Section | Keys |
|---|---|
| `[Package]` (one) | `name`, `version` (required); `description`, `authors` (list), `license` (an SPDX expression such as `Apache-2.0` or `MIT OR Apache-2.0`), `license_file`, `readme` (these two must exist), `repository`, `homepage` |
| `[Target]` (one or more) | `name`, `kind` (`bin` or `library`), `source`. `build` builds every target; `--bin <name>` or `--lib <name>` picks one |
| `[Test]` (at most one) | `tests`: the directory whose `*.lep` files are the tests (default `tests/`) |
| `[Profile]` | `name`, `optimization` (`none`, `O0` to `O3`, `Os`, `Oz`). `debug` (none) and `release` (O2) exist without being declared |
| `[Target_Platform]` | `triple` (x86-64 Linux), `libc` (`glibc` or `musl`, must match the triple), `link` (`static` or `dynamic`; default static for musl, dynamic for glibc), `libraries` (extra `-l` names; `m` is always linked). When any are declared, `--target` must be one of them |

There is no toolchain section. Clang is found when the compiler runs,
never named in the manifest. The older flat form (`project`, `kind`,
`entry` with no sections) is still read.

### Libraries

A `library` target builds a shared library (`.so`) and a static archive
(`.a`) instead of a program. There is no `main`. Every function is
exported as `<name>_<function>`, taking and returning 64-bit Lepthorn
values, and `<name>_init()` runs the library's top-level statements. In
these values a Number is its IEEE-754 bits plus 2^49, `true` and
`false` are 7 and 6, and anything else is a pointer.
`lepthornc new <name> --lib` makes a library project with a test.

### Tests

`lepthornc test` compiles each test and also runs it with `eval`. A test
passes when the program exits with the expected status (`<test>.exit`
next to it, default 0), prints exactly `<test>.out` when that file
exists, and `eval` gives the same output and status. `<test>.in`, if
present, is given to both as input. Tests always run with Unicode unit
output (or ASCII with `--ascii`), whatever the environment says, and
they can find the compiler that runs them in `LEPTHORNC`.

## Unit display

Units are printed SI style, in Unicode by default:

| | Unicode (default) | ASCII |
|---|---|---|
| force | `392.266 kg·m/s² (N)` | `392.266 kg*m/s^2 (N)` |
| pressure | `392.266 kg/(m·s²) (Pa)` | `392.266 kg/(m*s^2) (Pa)` |
| frequency | `0.5 s⁻¹ (Hz)` | `0.5 s^-1 (Hz)` |
| energy | `1176.8 kg·m²/s² (J)` | `1176.8 kg*m^2/s^2 (J)` |

For terminals, logs or tools that cannot show UTF-8, use
`LEPTHORN_OUTPUT=ascii`, or `--ascii` on `lepthornc run`, `eval` and
`test`. A program reads this setting each time it prints a unit, so
`sys::setenv("LEPTHORN_OUTPUT", "ascii")` changes it from inside the
program. Only the way the unit is written changes, never the value.

## Where Lepthorn is going

These are plans, not features:

- checking units and types before the program runs
- libraries grouped by topic: a mathematics engine (vectors, matrices,
  tensors), a physics engine, an engineering engine (control, robotics,
  signals), and later real-time, autonomous-systems and AI engines
- typed declarations, such as `ensure mass : Mass = 10kg`
- real threads, fixed-width integer types, and hardware access for
  microcontrollers

Lepthorn is not trying to replace Rust, C++, Python, ROS 2, AUTOSAR or
PX4. The question it explores is what changes when units, timing and
engineering calculations are part of the language itself.

## Documentation

- [docs/INTRODUCTION.md](docs/INTRODUCTION.md): what Lepthorn is and why
- [docs/book/INTRODUCTION.md](docs/book/INTRODUCTION.md): getting started
- [docs/SPEC.md](docs/SPEC.md): the whole language
- [docs/GRAMMAR.md](docs/GRAMMAR.md): the exact syntax
- [docs/DATATYPES.md](docs/DATATYPES.md): values, units and printing
- [docs/DATATYPES_SPEC.md](docs/DATATYPES_SPEC.md): the planned type system
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): how the compiler works
- [docs/METHODOLOGY.md](docs/METHODOLOGY.md): how features are added
- [docs/errors/](docs/errors/): every error code
- `examples/`: a program for each feature

## License

Apache-2.0. See [LICENSE](LICENSE).
