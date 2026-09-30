# Lepthorn compiler tasks.
#
# Every build has two stages. Stage 1: the lepthornc installed on the
# system (found on PATH) builds this source into build/stage1/. Stage 2:
# that stage-1 compiler builds the source again. So the result is always
# made by a compiler built from this same source, never by an older one.
# A stage is skipped when its output is newer than every file in src/,
# manifest.lepm and the compiler that builds it; `just clean` forces all.
#
# Settings, all optional:
#   LEPTHORNC          the installed compiler (default: lepthornc on PATH)
#   LEPTHORN_PREFIX    where to install (default: /usr/local, so /usr/local/bin)
#   LEPTHORN_SYSROOT   where the other libc lives, for --target builds
# The same names work on the command line, e.g. `just sysroot=/opt/musl musl`.

lepthornc := env("LEPTHORNC", "lepthornc")
prefix := env("LEPTHORN_PREFIX", "/usr/local")
sysroot := env("LEPTHORN_SYSROOT", "")
bindir := prefix / "bin"
stage1 := "build/stage1/bin/lepthornc"

# `fresh OUT FILE...` succeeds when OUT exists and nothing in src/,
# manifest.lepm or the given files is newer than it
fresh := 'fresh() { out="$1"; shift; [ -x "$out" ] && [ -z "$(find src manifest.lepm "$@" -newer "$out" -print -quit)" ]; }; '

export LEPTHORN_SYSROOT := sysroot

# list the recipes
default:
    @just --list

# stage 1: the installed compiler builds this source
stage1:
    @{{fresh}} if fresh {{stage1}} "$(command -v {{lepthornc}})"; then echo "stage 1 is up to date"; else echo "stage 1: {{lepthornc}} builds {{stage1}}"; {{lepthornc}} build --release -o {{stage1}}; fi

# debug build by stage 1: build/debug/bin/lepthornc
build: stage1
    @{{fresh}} if fresh build/debug/bin/lepthornc {{stage1}}; then echo "stage 2 (debug) is up to date"; else echo "stage 2: stage 1 builds the debug compiler"; {{stage1}} build; fi

# release build by stage 1: build/release/bin/lepthornc
release: stage1
    @{{fresh}} if fresh build/release/bin/lepthornc {{stage1}}; then echo "stage 2 (release) is up to date"; else echo "stage 2: stage 1 builds the release compiler"; {{stage1}} build --release; fi

# glibc build (dynamic) by stage 1: build/release/x86_64-linux-gnu/bin/lepthornc
gnu: stage1
    @{{fresh}} if fresh build/release/x86_64-linux-gnu/bin/lepthornc {{stage1}}; then echo "glibc build is up to date"; else {{stage1}} build --release --target x86_64-linux-gnu; fi

# musl build (static) by stage 1: build/release/x86_64-linux-musl/bin/lepthornc
musl: stage1
    @{{fresh}} if fresh build/release/x86_64-linux-musl/bin/lepthornc {{stage1}}; then echo "musl build is up to date"; else {{stage1}} build --release --target x86_64-linux-musl; fi

# both libc builds
targets: gnu musl

# run the tests with the new compiler
test: release
    build/release/bin/lepthornc test

# the new compiler rebuilds itself; both must match
fixed-point: release
    build/release/bin/lepthornc build --release
    cmp build/release/bin/lepthornc build/release/rebuild/bin/lepthornc
    @echo "fixed point: build/release/bin/lepthornc rebuilds itself identically"

# check the new compiler and copy it to bin/lepthornc
promote: release
    build/release/bin/lepthornc promote --release

# copy bin/lepthornc to the system (asks for sudo when the directory needs it)
install:
    if [ -w "{{bindir}}" ]; then install -m 755 bin/lepthornc "{{bindir}}/lepthornc"; else sudo install -m 755 bin/lepthornc "{{bindir}}/lepthornc"; fi
    @echo "installed {{bindir}}/lepthornc"
    @"{{bindir}}/lepthornc" version

# remove the installed compiler
uninstall:
    if [ -w "{{bindir}}" ]; then rm -f "{{bindir}}/lepthornc"; else sudo rm -f "{{bindir}}/lepthornc"; fi

# build, check, promote to bin/, then install on the system
update: promote install

# the full check from a clean tree
verify:
    rm -rf build
    {{lepthornc}} build --release -o {{stage1}}
    {{stage1}} build --release
    build/release/bin/lepthornc test
    build/release/bin/lepthornc build --release
    cmp build/release/bin/lepthornc build/release/rebuild/bin/lepthornc
    {{stage1}} build --release --target x86_64-linux-gnu
    {{stage1}} build --release --target x86_64-linux-musl
    build/release/x86_64-linux-musl/bin/lepthornc test --target x86_64-linux-musl
    @echo "verified: two-stage build, tests pass, the compiler rebuilds itself identically, glibc and musl builds done"

# remove build/
clean:
    rm -rf build
