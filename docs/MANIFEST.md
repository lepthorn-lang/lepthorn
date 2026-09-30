# manifest.lepm

Every project has a `manifest.lepm` in its root directory. It names the
project, its programs and libraries, its tests, its build profiles and
the systems it can be built for. How to use a project is in
[PROJECTS.md](PROJECTS.md).

## Format

```toml
[Section]
    key = "value"
    list_key = ["a", "b"]
```

- A line in square brackets starts a section. Every `key = value` line
  after it belongs to that section, until the next one.
- A value is quoted text, or a list of quoted texts.
- Indentation and blank lines do not matter.
- A line starting with `#` or `//` is a comment.
- Section and key names must be spelled exactly as below. A wrong name
  is an error, with its line number:

```text
lepthornc: manifest.lepm:3: unknown key verison in [Package] (keys: name version description authors license license_file readme repository homepage)
```

## Sections

### [Package] (exactly one)

| Key | Required | Meaning |
|---|---|---|
| `name` | yes | the project name: letters, digits, `_`, `.`, `-` |
| `version` | yes | the version, e.g. `"1.0.0"` |
| `description` | no | one line about the project |
| `authors` | no | a list, e.g. `["Ali Zain"]` |
| `license` | no | an SPDX expression: `"Apache-2.0"`, `"MIT"`, `"MIT OR Apache-2.0"` |
| `license_file` | no | the license text, e.g. `"LICENSE"`; the file must exist |
| `readme` | no | e.g. `"README.md"`; the file must exist |
| `repository` | no | where the source lives |
| `homepage` | no | the project's web page |

`license` is checked as an SPDX expression: license names joined by
`AND` and `OR` (in capitals), `WITH` for an exception, and parentheses.
The names themselves are not checked against the SPDX list.

### [Target] (one or more)

| Key | Required | Meaning |
|---|---|---|
| `name` | yes | the program or library name |
| `kind` | yes | `"bin"` for a program, `"library"` for a library |
| `source` | yes | the main source file, e.g. `"src/main.lep"`; it must exist |

A `bin` target builds `build/<profile>/bin/<name>`. A `library` target
builds `build/<profile>/lib/lib<name>.so` and `lib<name>.a`. Two
targets cannot have the same name.

### [Test] (at most one)

| Key | Meaning |
|---|---|
| `tests` | the directory whose `.lep` files are the tests; default `"tests/"` |

### [Profile] (any number)

| Key | Required | Meaning |
|---|---|---|
| `name` | yes | the profile name; the output goes to `build/<name>/` |
| `optimization` | yes | `"none"`, `"O0"`, `"O1"`, `"O2"`, `"O3"`, `"Os"` or `"Oz"` |

`debug` (`none`) and `release` (`O2`) exist even when they are not
declared. A declared profile with the same name replaces them. Pick a
profile with `--release` or `--profile <name>`.

### [Target_Platform] (any number)

| Key | Required | Meaning |
|---|---|---|
| `triple` | yes | the system: `"x86_64-linux-gnu"` or `"x86_64-linux-musl"` |
| `libc` | yes | `"glibc"` or `"musl"`; it must match the triple |
| `link` | no | `"static"` or `"dynamic"`; default static for musl, dynamic for glibc |
| `libraries` | no | extra libraries to link, e.g. `["m"]`; `m` is always linked |

Pick a platform with `--target <triple>`. When the manifest declares any
platforms, `--target` must be one of them. When it declares none, both
triples above can be used. Only x86-64 Linux is supported.

## No paths to your machine

Every path in the manifest is relative to the project directory. An
absolute path (`/home/...`, `/usr/...`) or `~` is an error.

The manifest never names Clang or a libc directory. `lepthornc` finds
them when it runs: Clang from `--cc`, `LEPTHORN_CLANG`, `LEPTHORN_CC`
or `PATH`, and the other libc from `LEPTHORN_SYSROOT` or next to Clang.
See [BUILDING.md](BUILDING.md).

`lepthornc resolve manifest.lepm` (or just `lepthornc resolve` inside
the project) shows what the manifest means on the current machine:

```text
package: lepthornc 1.0.0
description: The native compiler for Lepthorn.
authors: Ali Zain
license: Apache-2.0 (LICENSE)
readme: README.md
target: lepthornc (bin) src/main.lep
tests: tests/ (23 files)
profile: debug -O0
profile: release -O2
platform: x86_64-linux-gnu glibc dynamic -lm
platform: x86_64-linux-musl musl static -lm
clang: clang -> /usr/bin/clang
host: x86_64-redhat-linux-gnu (glibc)
```

## A full example

This is the compiler's own manifest:

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

## The older flat form

Older projects used a flat form with no sections. It is still read:

```text
project = "rover"
version = "0.1.0"
kind = "application"
entry = "src/main.lep"
tests = "tests"
```

It means one `[Package]`, one `[Target]` (`application` becomes `bin`)
and a `[Test]`. New projects use sections.
