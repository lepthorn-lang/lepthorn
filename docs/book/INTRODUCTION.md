# Chapter 1: Getting Started

This chapter shows how to set up the compiler, write your first
Lepthorn programs, and make a project. For what Lepthorn is and why it
exists, read [../INTRODUCTION.md](../INTRODUCTION.md) first.

## What you need

- an x86-64 Linux computer
- Clang (`clang --version` should work)
- a C library: glibc (most Linux systems) or musl (Alpine and others)

## Get the compiler

The compiler is one file, `lepthornc`. Lepthorn is written in Lepthorn,
so you need a `lepthornc` binary to start: copy one from a machine that
has it (the static musl build runs on any x86-64 Linux) and install it:

```sh
sudo install -m 755 lepthornc /usr/local/bin/
```

After that, `just install` in the compiler's repository builds the
compiler from source and installs the new one.

Check that it works:

```sh
lepthornc version
```

```text
lepthornc 1.0.0
Lepthorn Programming Language
```

## Your first program

Make a file called `hello.lep`:

```lepthorn
show "Hello from Lepthorn"
```

Run it:

```sh
lepthornc run hello.lep
```

```text
Hello from Lepthorn
```

`run` compiles the program to a native program and then runs it. You
can also run it without compiling:

```sh
lepthornc eval hello.lep
```

Both give the same result. To only make the program file, use
`lepthornc compile hello.lep`; this writes `./hello`.

## Values and units

```lepthorn
ensure mass = 2kg
suppose speed = 3mps
speed = speed + 1mps
show "mass:" mass "speed:" speed
```

```text
mass: 2 kg speed: 4 m/s
```

- `ensure` makes a value you cannot change later.
- `suppose` makes a value you can change.
- `show` prints its values on one line, separated by spaces.
- A number can end with a unit: `2kg`, `10ms`, `3mps`.

Units are kept through calculations:

```lepthorn
ensure distance = 100m
ensure time = 8s
show distance / time
show force::gravity(10kg)
```

```text
12.5 m/s
98.0665 kg·m/s² (N)
```

## Decisions and loops

```lepthorn
ensure battery = 65

when battery > 80
    show "full"
otherwise when battery > 20
    show "ok"
otherwise
    show "low"
done()

suppose count = 0
repeat 3
    count += 1
    show "count:" count
done()
```

```text
ok
count: 1
count: 2
count: 3
```

Every block ends with `done()`.

## Functions

```lepthorn
make area(width, height)
    done(width * height)
done()

show area(3m, 4m)
```

```text
12 m²
```

`done(value)` returns a value from a function.

## Comments

```lepthorn
(* This is a comment.
   (* Comments can be nested. *) *)
show "ok"
```

`//` is not a comment in Lepthorn.

## Your first project

A project is a directory with a `manifest.lepm` file, a `src/` directory
and a `tests/` directory. Make one:

```sh
lepthornc new rover
cd rover
lepthornc build
lepthornc test
```

`build` writes the program to `build/debug/bin/rover`. `build --release`
writes an optimised one to `build/release/bin/rover`. `test` compiles
and runs every file in `tests/` and checks its output against the
`.out` file next to it.

The project's `manifest.lepm`:

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

For a program that runs on any Linux system, build a static musl
program:

```sh
lepthornc build --release --target x86_64-linux-musl
```

## Next

- [../USAGE.md](../USAGE.md) lists every command and option.
- [../PROJECTS.md](../PROJECTS.md) explains projects, tests and libraries.
- [../SPEC.md](../SPEC.md) describes the whole language.
- [../DATATYPES.md](../DATATYPES.md) describes values and units.
- The `examples/` directory has a program for each feature.
