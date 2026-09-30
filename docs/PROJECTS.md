# Projects

A project is a directory with a `manifest.lepm` file. It can hold
programs, libraries and tests. This document shows how to make one,
build it, test it and ship it. The manifest itself is described in
[MANIFEST.md](MANIFEST.md).

## Make a project

```sh
lepthornc new rover
cd rover
```

This makes:

```text
rover/
├── manifest.lepm       the project settings
├── README.md
├── src/
│   └── main.lep        the program
└── tests/
    ├── basic.lep       a test
    └── basic.out       what the test must print
```

`manifest.lepm`:

```toml
[Package]
    name = "rover"
    version = "0.1.0"

[Target]
    name = "rover"
    kind = "bin"
    source = "src/main.lep"

[Test]
    tests = "tests/"
```

For a library instead of a program:

```sh
lepthornc new mathlib --lib
```

This makes `src/lib.lep` and a target with `kind = "library"`.

## Build and run

```sh
lepthornc build                 # build/debug/bin/rover
./build/debug/bin/rover

lepthornc build --release       # build/release/bin/rover, optimised
```

For a quick run while you work, without building the whole project:

```sh
lepthornc run src/main.lep      # compile and run
lepthornc eval src/main.lep     # run in the interpreter
```

All project commands look for `manifest.lepm` in the current directory
and then upward, so they also work from inside `src/` or `tests/`.

## Split the code into files

Put the files under `src/` and pull them in with `use`:

```text
src/
├── main.lep
└── physics/
    ├── module.lep
    └── drag.lep
```

```lepthorn
use physics::drag         (* src/physics/drag.lep *)
use physics               (* src/physics/module.lep *)
use "helpers.lep"         (* relative to this file *)
```

Each file is included once, even when several files use it. A function
can be used before or after the place where it is written.

## Build output

```text
build/
├── debug/                          lepthornc build             (-O0)
│   ├── bin/<name>                  kind = "bin"
│   └── lib/lib<name>.so .a         kind = "library"
├── release/                        lepthornc build --release   (-O2)
│   ├── bin/<name>
│   ├── lib/lib<name>.so .a
│   ├── x86_64-linux-gnu/bin/...    --target x86_64-linux-gnu
│   └── x86_64-linux-musl/bin/...   --target x86_64-linux-musl
└── <profile>/...                   --profile <profile>
```

`build/` only holds generated files. `rm -rf build` is always safe.

When a project has several targets, `lepthornc build` builds all of
them. `--bin <name>` or `--lib <name>` builds one. `-o <path>` needs a
single target.

## glibc and musl

```sh
lepthornc build --release --target x86_64-linux-gnu
lepthornc build --release --target x86_64-linux-musl
```

A musl program is linked statically. It runs on any x86-64 Linux,
including systems without glibc. A glibc program is linked dynamically.
Without `--target`, programs are built for the libc that your Clang
uses.

To build for the other libc, its files must be installed. On Fedora,
for example, the musl packages put musl in `/usr/x86_64-linux-musl`,
next to Clang's `/usr/bin`, where `lepthornc` finds it. If it is
somewhere else, set `LEPTHORN_SYSROOT` to that directory (Debian,
Ubuntu and Arch with the musl package use `/usr/lib/musl`). In the
compiler's own repository, set `sysroot` in the justfile instead.

## Tests

`lepthornc test` runs every `.lep` file in the `[Test]` directory. For
each test it:

1. compiles it and runs the program,
2. runs it again with `eval`,
3. checks the exit status (0, or the number in `<test>.exit`),
4. checks the output against `<test>.out`, if that file exists,
5. checks that `eval` gave the same output and status.

`<test>.in`, if it exists, is given to the test as its input.

Tests always print units in Unicode (or ASCII with `lepthornc test
--ascii`), so a test's output does not change with your environment.
The compiler that runs the tests is in the environment variable
`LEPTHORNC`, so a test can run the compiler itself.

```text
test: basic ................... ok

1 passed; 0 failed
```

## Libraries

A target with `kind = "library"` builds a shared library and a static
archive:

```text
build/<profile>/lib/lib<name>.so
build/<profile>/lib/lib<name>.a
```

There is no `main`. Instead:

- `<name>_init()` runs the library's top-level statements. Call it once
  first.
- every `make` function is exported as `<name>_<function>`.

The functions take and return 64-bit Lepthorn values:

| Value | As a 64-bit number |
|---|---|
| Number without a unit | its IEEE-754 bits plus 2^49 |
| `true`, `false` | 7, 6 |
| anything else | a pointer to a Lepthorn object |

Calling `mathlib_twice(21)` from Python:

```python
import ctypes, struct
lib = ctypes.CDLL("./build/debug/lib/libmathlib.so")
lib.mathlib_init()
f = lib.mathlib_twice
f.restype = ctypes.c_uint64
f.argtypes = [ctypes.c_uint64]
enc = lambda d: struct.unpack("<Q", struct.pack("<d", d))[0] + (1 << 49)
dec = lambda v: struct.unpack("<d", struct.pack("<Q", v - (1 << 49)))[0]
print(dec(f(enc(21.0))))    # 42.0
```

## Install a program

`lepthornc promote` copies the built programs to `bin/` in the project:

```sh
lepthornc build --release
lepthornc promote --release     # build/release/bin/rover -> bin/rover
```

The compiler's own repository does not use `promote`: it installs the
new compiler on the system with `just install` (see
[BUILDING.md](BUILDING.md)).
