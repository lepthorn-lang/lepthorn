# Lepthorn compiler tasks.
#
# The lepthornc installed on the system builds the compiler; this
# repository keeps no compiler binary. Every build has two stages:
#   stage 1: the installed lepthornc builds this source into build/stage1/
#   stage 2: that stage-1 compiler builds the source again
# so the result is always made by a compiler built from this same source.
# Every build first runs `check`: lepthornc, clang (LLVM) and the libc
# must work. A stage is skipped when its output is newer than src/,
# manifest.lepm, this justfile and the compiler that builds it.
# `just release` builds for this system's libc only; `just gnu`,
# `just musl` and `just targets` build for a named libc.

# ------------------------------------------------------------------
# Settings: edit these for your system. Each can also be given once on
# the command line, e.g. `just sysroot=/usr/lib/musl musl`.
# ------------------------------------------------------------------

# Where the other libc lives, for --target builds (the one your system
# does not use). Leave empty to let lepthornc look next to clang.
# Examples: Fedora "/usr/x86_64-linux-musl" (found without setting it),
# Debian, Ubuntu and Arch with the musl package "/usr/lib/musl".
sysroot := ""

# The clang to use. Leave empty for `clang` on PATH. Example: "clang-19".
clang := ""

# The installed compiler that builds stage 1.
lepthornc := "lepthornc"

# `just install` puts the new lepthornc in <prefix>/bin.
prefix := "/usr/local"

# ------------------------------------------------------------------

# the recipes print their own error messages
set no-exit-message

# the settings reach lepthornc as environment variables
export LEPTHORN_SYSROOT := sysroot
export LEPTHORN_CLANG := clang

bindir := prefix / "bin"
stage1 := "build/stage1/bin/lepthornc"

# shell helpers for the recipes:
#   say LABEL TEXT           one status line
#   quiet CMD...             run CMD, print its output only when it fails
#   fresh OUT FILE...        OUT exists and nothing in src/, manifest.lepm,
#                            this justfile or FILE... is newer
#   stage2 COMPILER OUT ARG  stage 2: COMPILER build ARG..., unless fresh
#   libc TRIPLE / hostlibc   "glibc" or "musl"
sh := '''
say() { printf '%-9s %s\n' "$1" "$2"; }
quiet() { out=$("$@" 2>&1) || { st=$?; printf '%s\n' "$out"; return $st; }; }
fresh() { o="$1"; shift; [ -x "$o" ] && [ -z "$(find src manifest.lepm justfile "$@" -newer "$o" -print -quit)" ]; }
stage2() { c="$1"; o="$2"; shift 2; if fresh "$o" "$c"; then say "stage 2" "up to date ($o)"; else quiet "$c" build "$@" || { echo "error: stage 2 failed: stage 1 could not build this source (errors above)"; return 1; }; say "stage 2" "$o"; fi; }
libc() { case "$1" in *musl*) echo musl;; *) echo glibc;; esac; }
hostlibc() { libc "$("${LEPTHORN_CLANG:-clang}" -print-target-triple)"; }
'''

# list the recipes
default:
    @just --list --unsorted

# check that lepthornc, clang (LLVM) and this system's libc work
check:
    @{{sh}} \
    lc="$(command -v {{lepthornc}})" || { echo "error: {{lepthornc}} not found on PATH; install a lepthornc binary first (docs/BUILDING.md) or set lepthornc in the justfile"; exit 1; }; \
    say check "lepthornc  $({{lepthornc}} version | head -n 1) ($lc)"; \
    cc="${LEPTHORN_CLANG:-clang}"; \
    ccp="$(command -v "$cc")" || { echo "error: $cc not found; install clang (LLVM) or set clang in the justfile"; exit 1; }; \
    ver="$("$cc" --version | sed -n 's/.*clang version \([0-9][0-9.]*\).*/\1/p;q')"; \
    say check "clang      ${ver:-unknown version} ($ccp)"; \
    host="$("$cc" -print-target-triple)"; \
    say check "libc       $(libc "$host") ($host)"; \
    mkdir -p build/check; printf 'show "ok"\n' > build/check/check.lep; \
    { quiet {{lepthornc}} compile build/check/check.lep -o build/check/check && [ "$(build/check/check)" = ok ]; } || { echo "error: $lc could not build and run a test program with $cc (output above)"; exit 1; }; \
    say check "toolchain  builds and runs programs"

# check that the libc for a --target is installed
_target triple: check
    @{{sh}} \
    { quiet {{lepthornc}} compile build/check/check.lep -o build/check/check-{{triple}} --target {{triple}}; } || { echo "error: cannot build for {{triple}}: $(libc {{triple}}) not found (message above); install it or set sysroot in the justfile"; exit 1; }; \
    say check "$(printf '%-10s' "$(libc {{triple}})") found ({{triple}})"

# stage 1: the installed lepthornc builds build/stage1/bin/lepthornc
stage1: check
    @{{sh}} \
    lc="$(command -v {{lepthornc}})"; \
    if fresh {{stage1}} "$lc"; then say "stage 1" "up to date ({{stage1}})"; exit 0; fi; \
    quiet {{lepthornc}} build --release -o {{stage1}} || { echo "error: stage 1 failed: $lc could not build this source (errors above)"; exit 1; }; \
    say "stage 1" "{{stage1}} (built by $lc)"

# debug build for this system's libc: build/debug/bin/lepthornc
build: stage1
    @{{sh}} stage2 {{stage1}} build/debug/bin/lepthornc && say ready "build/debug/bin/lepthornc (debug, $(hostlibc): this system's libc)"

# release build for this system's libc only: build/release/bin/lepthornc
release: stage1
    @{{sh}} stage2 {{stage1}} build/release/bin/lepthornc --release && say ready "build/release/bin/lepthornc ($(hostlibc): this system's libc)"

# glibc build, dynamic: build/release/x86_64-linux-gnu/bin/lepthornc
gnu: (_target "x86_64-linux-gnu") stage1
    @{{sh}} o=build/release/x86_64-linux-gnu/bin/lepthornc; stage2 {{stage1}} $o --release --target x86_64-linux-gnu && say ready "$o (glibc, dynamic)"

# musl build, static: build/release/x86_64-linux-musl/bin/lepthornc
musl: (_target "x86_64-linux-musl") stage1
    @{{sh}} o=build/release/x86_64-linux-musl/bin/lepthornc; stage2 {{stage1}} $o --release --target x86_64-linux-musl && say ready "$o (musl, static, runs on any x86-64 Linux)"

# both libc builds
targets: gnu musl

# release build, then run the tests with it
test: release
    @build/release/bin/lepthornc test

# release build, then check that it rebuilds itself identically
fixed-point: release
    @{{sh}} \
    new=build/release/bin/lepthornc; again=build/release/rebuild/bin/lepthornc; \
    if [ "$again" -nt "$new" ] && cmp -s "$new" "$again"; then say check "fixed point: $new rebuilds itself identically"; exit 0; fi; \
    quiet "$new" build --release || { echo "error: $new could not rebuild itself (errors above)"; exit 1; }; \
    cmp -s "$new" "$again" || { echo "error: $new is not a fixed point: its rebuild $again differs"; exit 1; }; \
    say check "fixed point: $new rebuilds itself identically"

# release build, fixed-point check, then copy it to <prefix>/bin
install: fixed-point
    @{{sh}} \
    dest="{{bindir}}/lepthornc"; \
    if [ -w "{{bindir}}" ]; then install -Dm 755 build/release/bin/lepthornc "$dest"; \
    else say install "{{bindir}} is not writable, using sudo"; sudo install -Dm 755 build/release/bin/lepthornc "$dest"; fi \
    || { echo "error: could not write $dest"; exit 1; }; \
    say installed "$dest ($("$dest" version | head -n 1))"

# remove <prefix>/bin/lepthornc
uninstall:
    @{{sh}} \
    dest="{{bindir}}/lepthornc"; \
    if [ ! -e "$dest" ]; then say uninstall "nothing to remove: $dest does not exist"; exit 0; fi; \
    if [ -w "{{bindir}}" ]; then rm -f "$dest"; else sudo rm -f "$dest"; fi && say removed "$dest"

# the full check from an empty build/: stages, tests, fixed point, both libcs
verify: clean test fixed-point targets
    @{{sh}} \
    quiet build/release/x86_64-linux-musl/bin/lepthornc test --target x86_64-linux-musl || { echo "error: the tests failed with the musl compiler (output above)"; exit 1; }; \
    say check "the musl compiler passes the tests"; \
    say verified "two stages, tests, fixed point, glibc and musl builds"

# remove build/
clean:
    @{{sh}} if [ -e build ]; then rm -rf build && say clean "removed build/"; else say clean "nothing to remove"; fi
