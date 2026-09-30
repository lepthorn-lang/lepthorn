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

## Install the compiler first

The compiler is built with the `lepthornc` installed on your system, not
with the file in the repository. The repository's `bin/lepthornc` is the
copy you install from. Install it once:

```sh
sudo just install        # copies bin/lepthornc to /usr/local/bin/lepthornc
lepthornc version
```

Without `just`: `sudo install -m 755 bin/lepthornc /usr/local/bin/`.

To install somewhere else, set `LEPTHORN_PREFIX`: with
`LEPTHORN_PREFIX=$HOME/.local just install` it goes to
`~/.local/bin/lepthornc`, and no `sudo` is needed. Make sure that
directory is on your `PATH`, and that no older `lepthornc` comes before
it on the `PATH` (`which lepthornc` shows which one runs).

## Build the compiler: always two stages

A compiler build has two stages:

1. **Stage 1:** the `lepthornc` installed on the system builds this
   source into `build/stage1/bin/lepthornc`.
2. **Stage 2:** that stage-1 compiler builds the source again, into
   `build/release/bin/lepthornc`.

So the compiler you get is always made by a compiler built from the
same source. The code generator and runtime inside it are the new ones,
even when the installed compiler is older.

With `just`, every build recipe does both stages. A stage is skipped
when its output is already newer than every file in `src/`,
`manifest.lepm` and the compiler that builds it, so running
`just test` and then `just promote` does not build the compiler twice.
`just clean` removes `build/` and forces a full build.

```sh
just release          # stage 1, then stage 2: build/release/bin/lepthornc
just test             # the same, then runs the tests with the new compiler
just promote          # the same, then checks it and copies it to bin/lepthornc
sudo just install     # installs bin/lepthornc on the system
```

`just update` does `promote` and then `install` (it asks for `sudo` at
the end). By hand:

```sh
lepthornc build --release -o build/stage1/bin/lepthornc    # stage 1
build/stage1/bin/lepthornc build --release                 # stage 2
build/release/bin/lepthornc test
build/release/bin/lepthornc promote --release
sudo just install
```

`promote` refuses a compiler that does not rebuild itself exactly. A
stage-2 compiler always passes this, because it was built by a compiler
made from the same source.

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
| the other libc | `LEPTHORN_SYSROOT`, else `<Clang's directory>/../<triple>` |
| its own path (for tests) | how it was started (`argv[0]`), then `PATH` |

The other libc's library files are looked for in `lib64`, `lib`,
`usr/lib64` and `usr/lib` under that directory. For example, when Clang
is `/usr/bin/clang`, musl is looked for in `/usr/x86_64-linux-musl`.

`lepthornc resolve` prints what it found on the current machine.

## The justfile

The `justfile` runs the `lepthornc` on your `PATH`. Three settings
change what it does. Set them in the environment, or on the command
line (`just sysroot=/opt/musl musl`):

| Setting | Environment variable | Default |
|---|---|---|
| `lepthornc` | `LEPTHORNC` | `lepthornc` on `PATH` |
| `prefix` | `LEPTHORN_PREFIX` | `/usr/local` (installs to `/usr/local/bin`) |
| `sysroot` | `LEPTHORN_SYSROOT` | empty: the compiler finds the other libc itself |

| Recipe | What it does |
|---|---|
| `just stage1` | stage 1 only: the installed compiler builds `build/stage1/bin/lepthornc` |
| `just build` | stage 1, then a debug build |
| `just release` | stage 1, then a release build |
| `just gnu`, `just musl`, `just targets` | stage 1, then release builds for glibc, musl, or both |
| `just test` | release build, then run the tests with it |
| `just fixed-point` | release build, then check that it rebuilds itself |
| `just promote` | release build, then promote it to `bin/` |
| `just install` | copy `bin/lepthornc` to `<prefix>/bin`, with `sudo` if needed |
| `just uninstall` | remove `<prefix>/bin/lepthornc` |
| `just update` | promote, then install |
| `just verify` | from a clean `build/`: both stages, tests, the rebuild check, both targets, and the musl tests |
| `just clean` | remove `build/` |

## When stage 1 fails: new syntax or built-ins in the compiler

The compiler is written in Lepthorn. When its own source starts using a
new built-in function or new syntax, the installed compiler does not
know it yet, so it cannot build stage 1. Then:

1. Copy the source somewhere outside the repository, and in the copy
   write those few places the old way.
2. Build the copy with the installed compiler. This is stage 1.
3. Use it to build the real source (stage 2), then `promote` and
   install as usual.

After that, the installed compiler knows the new feature and the normal
two-stage build works again.

How the compiler works inside is described in
[ARCHITECTURE.md](ARCHITECTURE.md).
