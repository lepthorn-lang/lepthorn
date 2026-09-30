# Building Lepthorn

## Self-hosting

Lepthorn is self-hosted and natively compiled. The canonical compiler is
the `lepthornc` installed on your system. It is written in Lepthorn and
compiles the Lepthorn compiler source directly. Normal development and
release builds do not need OCaml, C source, a repository seed, or a
separate bootstrap compiler. The compiler can rebuild itself and produce
an equivalent native compiler binary. Separate target builds are
supported for glibc and musl systems.

This repository holds only the source, not a compiler binary. There is
no way to build the compiler on a machine that has no Lepthorn compiler
at all; this was removed on purpose. A new machine gets Lepthorn by
installing a `lepthornc` binary built on another machine. The static
musl build (`build/release/x86_64-linux-musl/bin/lepthornc`) runs on any
x86-64 Linux, so it is the one to copy.

## What you need

- x86-64 Linux
- Clang (tested with 22.1.8; version 15 or newer should work)
- glibc or musl (tested with glibc 2.43 and musl 1.2.5)
- a `lepthornc` installed on your `PATH`
- `just`, if you want to use the `justfile` (not required)

Nothing else: no OCaml, no C source, no network.

To install a `lepthornc` binary you were given:

```sh
sudo install -m 755 lepthornc /usr/local/bin/lepthornc
lepthornc version
```

Make sure no older `lepthornc` comes before it on your `PATH`
(`which lepthornc` shows which one runs).

## Build the compiler: always two stages

A compiler build has two stages:

1. **Stage 1:** the `lepthornc` installed on the system builds this
   source into `build/stage1/bin/lepthornc`.
2. **Stage 2:** that stage-1 compiler builds the source again, into
   `build/release/bin/lepthornc`.

So the compiler you get is always made by a compiler built from the
same source. The code generator and runtime inside it are the new ones,
even when the installed compiler is older.

With `just`, every build recipe first checks the tools, then does both
stages. A stage is skipped when its output is already newer than every
file in `src/`, `manifest.lepm`, the justfile and the compiler that
builds it, so running `just test` and then `just install` does not
build the compiler twice. `just clean` removes `build/` and forces a
full build.

```sh
just release          # check, stage 1, stage 2: build/release/bin/lepthornc
just test             # the same, then runs the tests with the new compiler
just install          # checks that it rebuilds itself, then copies it to /usr/local/bin
```

`just release` builds for this system's libc only (the one your Clang
uses). For glibc or musl by name, use `just gnu`, `just musl` or
`just targets` (see below).

`just release` prints one line per step:

```text
check     lepthornc  lepthornc 1.0.0 (/usr/local/bin/lepthornc)
check     clang      22.1.8 (/usr/bin/clang)
check     libc       glibc (x86_64-redhat-linux-gnu)
check     toolchain  builds and runs programs
stage 1   build/stage1/bin/lepthornc
stage 2   build/release/bin/lepthornc
ready     build/release/bin/lepthornc (glibc)
```

The check stops with a clear message when something is missing:
`lepthornc`, `clang` (LLVM), or, for `just gnu` and `just musl`, the
libc of that target. The compiler's own output is shown only when a
step fails. Errors in the compiler's source look like errors in any
program, with the file and line:

```text
src/core/ctv/ctv.lep:250: LEC2001: a statement cannot start with '+'
    ctv_error(sink, node.pos, "undeclared variable '" + node.op + "'") +
lepthornc: compilation failed
error: stage 1 failed: /usr/local/bin/lepthornc could not build this source (errors above)
```

`just install` asks for your password only for the copy, when the
install directory needs it. Run it as yourself, not with `sudo`, so the
files in `build/` stay yours.

By hand:

```sh
lepthornc build --release -o build/stage1/bin/lepthornc    # stage 1
build/stage1/bin/lepthornc build --release                 # stage 2
build/release/bin/lepthornc test
build/release/bin/lepthornc build --release                # rebuild check
cmp build/release/bin/lepthornc build/release/rebuild/bin/lepthornc
sudo install -m 755 build/release/bin/lepthornc /usr/local/bin/lepthornc
```

If the new source uses syntax or a built-in function that the installed
compiler does not know, stage 1 fails. See the last section of this
document for what to do then.

## Check that it rebuilds itself

```sh
just verify
```

or by hand:

```sh
rm -rf build
lepthornc build --release -o build/stage1/bin/lepthornc
build/stage1/bin/lepthornc build --release
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
just gnu      # stage 1, then build/release/x86_64-linux-gnu/bin/lepthornc
just musl     # stage 1, then build/release/x86_64-linux-musl/bin/lepthornc
```

By hand, after stage 1:

```sh
build/stage1/bin/lepthornc build --release --target x86_64-linux-gnu
build/stage1/bin/lepthornc build --release --target x86_64-linux-musl
```

The musl compiler is linked statically and runs on any x86-64 Linux,
including Alpine.

## How tools are found

`lepthornc` has no built-in paths. It finds everything when it runs:

| What | Where it comes from |
|---|---|
| the project | the nearest `manifest.lepm`, from the current directory upward |
| Clang | `--cc`, else `LEPTHORN_CLANG`, else `LEPTHORN_CC`, else `clang` on `PATH` |
| the system's libc | Clang's own target (`clang -print-target-triple`) |
| the other libc | `LEPTHORN_SYSROOT` (the justfile's `sysroot`), else `<Clang's directory>/../<triple>` |
| its own path (for tests) | how it was started (`argv[0]`), then `PATH` |

The other libc's library files are looked for in `lib64`, `lib`,
`usr/lib64` and `usr/lib` under that directory. For example, when Clang
is `/usr/bin/clang`, musl is looked for in `/usr/x86_64-linux-musl`.

`lepthornc resolve` prints what it found on the current machine.

## The justfile

The `justfile` starts with a settings block. Edit it once for your
system; nothing has to be set in the environment:

```just
sysroot := ""            # where the other libc lives, for --target builds
clang := ""              # the clang to use; empty means `clang` on PATH
lepthornc := "lepthornc" # the installed compiler that builds stage 1
prefix := "/usr/local"   # `just install` puts lepthornc in <prefix>/bin
```

| Setting | Default | When to change it |
|---|---|---|
| `sysroot` | empty: lepthornc looks next to clang | your system keeps the other libc somewhere else, e.g. `"/usr/lib/musl"` on Debian, Ubuntu or Arch with the musl package |
| `clang` | empty: `clang` on `PATH` | your clang has another name, e.g. `"clang-19"` |
| `lepthornc` | `lepthornc` on `PATH` | you want stage 1 built by another compiler |
| `prefix` | `/usr/local` | you want to install somewhere else, e.g. `"/home/you/.local"` (then no `sudo` is needed) |

The justfile hands `sysroot` and `clang` to lepthornc as
`LEPTHORN_SYSROOT` and `LEPTHORN_CLANG`. A setting can also be given
once on the command line: `just sysroot=/usr/lib/musl musl`. Changing
the justfile makes the next build start again from stage 1.

| Recipe | What it does |
|---|---|
| `just check` | check that `lepthornc`, `clang` (LLVM) and this system's libc work; every build runs it first |
| `just stage1` | stage 1 only: the installed compiler builds `build/stage1/bin/lepthornc` |
| `just build` | stage 1, then a debug build |
| `just release` | stage 1, then a release build for this system's libc |
| `just gnu`, `just musl`, `just targets` | check that the target's libc is installed, stage 1, then release builds for glibc, musl, or both |
| `just test` | release build, then run the tests with it |
| `just fixed-point` | release build, then check that it rebuilds itself |
| `just install` | release build, check that it rebuilds itself, then copy it to `<prefix>/bin` (with `sudo` only if needed) |
| `just uninstall` | remove `<prefix>/bin/lepthornc` |
| `just verify` | from a clean `build/`: both stages, tests, the rebuild check, both targets, and the musl tests |
| `just clean` | remove `build/` |

## When stage 1 fails: new syntax or built-ins in the compiler

The compiler is written in Lepthorn. When its own source starts using a
new built-in function or new syntax, the installed compiler does not
know it yet, so it cannot build stage 1. Then:

1. Copy the source somewhere outside the repository, and in the copy
   write those few places the old way.
2. Build the copy with the installed compiler. This is stage 1.
3. Use it to build the real source (stage 2), check it, and install it
   (`just lepthornc=<the stage-1 compiler> install`).

After that, the installed compiler knows the new feature and the normal
two-stage build works again.

How the compiler works inside is described in
[ARCHITECTURE.md](ARCHITECTURE.md).
