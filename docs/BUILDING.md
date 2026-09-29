# Building Lepthorn

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

## What you need

- x86-64 Linux
- Clang (tested with 22.1.8; version 15 or newer should work)
- glibc or musl (tested with glibc 2.43 and musl 1.2.5)
- `just`, if you want to use the `justfile` (not required)

Nothing else: no OCaml, no C source, no network.

## Build the compiler

From the repository root:

```sh
bin/lepthornc build --release        # makes build/release/bin/lepthornc
build/release/bin/lepthornc test     # the new compiler passes the tests
bin/lepthornc promote --release      # checks it, then copies it to bin/lepthornc
```

`promote` refuses a compiler that does not rebuild itself exactly.
Right after the compiler's source has changed, the new build was made
by the older compiler, so it is not yet exact. `promote` then rebuilds
it with itself, and promotes that rebuild once it reproduces itself.

## Check that it rebuilds itself

```sh
rm -rf build
bin/lepthornc test
bin/lepthornc build --release
build/release/bin/lepthornc test
build/release/bin/lepthornc build --release
cmp build/release/bin/lepthornc build/release/rebuild/bin/lepthornc
```

`cmp` prints nothing when the two files are identical. When a compiler
would write over its own file, it writes to
`build/<profile>/rebuild/bin/` instead, so the two can be compared.
The tests `compiler_self_build` and `rebuild_fixed_point` in
`lepthornc test` do the same check.

## glibc and musl

```sh
bin/lepthornc build --release --target x86_64-linux-gnu
bin/lepthornc build --release --target x86_64-linux-musl
```

These write `build/release/x86_64-linux-gnu/bin/lepthornc` and
`build/release/x86_64-linux-musl/bin/lepthornc`. The musl compiler is
linked statically and runs on any x86-64 Linux, including Alpine.

## How tools are found

`lepthornc` has no built-in paths. It finds everything when it runs:

| What | Where it comes from |
|---|---|
| the project | the nearest `manifest.lepm`, from the current directory upward |
| Clang | `--cc`, else `LEPTHORN_CLANG`, else `LEPTHORN_CC`, else `clang` on `PATH` |
| the system's libc | Clang's own target (`clang -print-target-triple`) |
| the other libc | `LEPTHORN_SYSROOT`, else `<Clang's directory>/../<triple>` |
| its own path (for tests) | how it was started (`argv[0]`), then `PATH` |

The other libc's library files are looked for in `lib64`, `lib`,
`usr/lib64` and `usr/lib` under that directory. For example, when Clang
is `/usr/bin/clang`, musl is looked for in `/usr/x86_64-linux-musl`.

`lepthornc manifest` prints what it found on the current machine.

## Install

`lepthornc` is one file. Copy it to a directory on your `PATH`:

```sh
just install     # copies bin/lepthornc to $LEPTHORN_BINDIR, or ~/.local/bin
```

or `cp bin/lepthornc ~/.local/bin/`.

## The justfile

The `justfile` runs `lepthornc` from your `PATH`, or the one named in
`LEPTHORNC`.

| Recipe | What it does |
|---|---|
| `just build` | debug build |
| `just release` | release build |
| `just gnu`, `just musl`, `just targets` | release builds for glibc, musl, or both |
| `just test` | run the tests |
| `just fixed-point` | release build, then check that it rebuilds itself |
| `just promote` | release build, then promote it to `bin/` |
| `just install` | copy `bin/lepthornc` to the install directory |
| `just update` | promote, then install |
| `just verify` | the full check above, plus both targets |
| `just clean` | remove `build/` |

## Adding a built-in function the compiler uses

The compiler is written in Lepthorn, so when its own source starts using
a new built-in function, the running compiler does not know that
function yet. This takes two builds:

1. Copy the source somewhere else and replace the new function's uses
   with an existing one. Build that copy with `bin/lepthornc`.
2. Use the compiler from step 1 to build the real source.
3. `promote` as usual.

How the compiler works inside is described in
[ARCHITECTURE.md](ARCHITECTURE.md).
