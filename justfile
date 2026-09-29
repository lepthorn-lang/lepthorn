# Lepthorn compiler tasks.
#
# Builds use the lepthornc installed on the system (found on PATH), not
# the copy in bin/. Settings, all optional:
#   LEPTHORNC          the compiler to use (default: lepthornc on PATH)
#   LEPTHORN_PREFIX    where to install (default: /usr/local, so /usr/local/bin)
#   LEPTHORN_SYSROOT   where the other libc lives, for --target builds
# The same names work on the command line, e.g. `just sysroot=/opt/musl musl`.

lepthornc := env("LEPTHORNC", "lepthornc")
prefix := env("LEPTHORN_PREFIX", "/usr/local")
sysroot := env("LEPTHORN_SYSROOT", "")
bindir := prefix / "bin"

export LEPTHORN_SYSROOT := sysroot

# list the recipes
default:
    @just --list

# debug build: build/debug/bin/lepthornc
build:
    {{lepthornc}} build

# release build for this system's libc: build/release/bin/lepthornc
release:
    {{lepthornc}} build --release

# glibc build (dynamic): build/release/x86_64-linux-gnu/bin/lepthornc
gnu:
    {{lepthornc}} build --release --target x86_64-linux-gnu

# musl build (static): build/release/x86_64-linux-musl/bin/lepthornc
musl:
    {{lepthornc}} build --release --target x86_64-linux-musl

# both libc builds
targets: gnu musl

# run the tests with the installed compiler
test:
    {{lepthornc}} test

# release build, then the release build rebuilds itself; both must match
fixed-point: release
    build/release/bin/lepthornc build --release
    cmp build/release/bin/lepthornc build/release/rebuild/bin/lepthornc
    @echo "fixed point: build/release/bin/lepthornc rebuilds itself identically"

# check the release build and copy it to bin/lepthornc
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
    {{lepthornc}} test
    {{lepthornc}} build --release
    build/release/bin/lepthornc test
    build/release/bin/lepthornc build --release
    cmp build/release/bin/lepthornc build/release/rebuild/bin/lepthornc
    {{lepthornc}} build --release --target x86_64-linux-gnu
    {{lepthornc}} build --release --target x86_64-linux-musl
    @echo "verified: tests pass, the compiler rebuilds itself identically, glibc and musl builds done"

# remove build/
clean:
    rm -rf build
