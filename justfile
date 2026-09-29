# Lepthorn compiler tasks.
#
# The compiler used is `lepthornc` from PATH (put there by `just install`),
# or whatever LEPTHORNC names. The libc is found by lepthornc itself from
# clang; a target builds for a specific one. No paths outside this project
# are assumed: the install directory is LEPTHORN_BINDIR, else ~/.local/bin.

lepthornc := env("LEPTHORNC", "lepthornc")
bindir := env("LEPTHORN_BINDIR", home_directory() / ".local" / "bin")

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

# run tests/ with the compiler on PATH
test:
    {{lepthornc}} test

# release build, then the release build rebuilds itself; both must match
fixed-point: release
    build/release/bin/lepthornc build --release
    cmp build/release/bin/lepthornc build/release/rebuild/bin/lepthornc
    @echo "fixed point: build/release/bin/lepthornc rebuilds itself identically"

# verify the release build and make it the project's bin/lepthornc
promote: release
    build/release/bin/lepthornc promote --release

# copy bin/lepthornc to the install directory (on PATH)
install:
    mkdir -p "{{bindir}}"
    cp -f bin/lepthornc "{{bindir}}/lepthornc.new"
    mv -f "{{bindir}}/lepthornc.new" "{{bindir}}/lepthornc"
    @echo "installed {{bindir}}/lepthornc"

# build, fixed-point check, promote to bin/, install
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

clean:
    rm -rf build
