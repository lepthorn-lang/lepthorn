# lepthornc roadmap

The full phase history is in `lepthorn/docs/ROADMAP.md` (repository
root). This file tracks the canonical compiler only.

# Completed Features — lepthornc 1.0.0

1. Complete LLVM native code generation written in Lepthorn.
2. All values use a 64-bit representation, with the runtime written in LLVM IR without C.
3. Self-hosted compiler that can rebuild itself and produce an identical binary.
4. One official compiler, `bin/lepthornc`, with verified updates using `promote`. No bootstrap compiler is required.
5. Support for glibc and musl, including static and dynamic builds.
6. Automatic detection of project paths, Clang, and system libraries.
7. `justfile` for common development commands.
8. `manifest.lepm` for project settings, packages, build targets, tests, profiles, and platforms.
9. Strict manifest validation with clear error messages and line numbers.
10. Released under the Apache-2.0 license.
11. Built-in interpreter (`eval`) that follows the same rules as compiled programs.
12. Built-in testing with `lepthornc test`, including compiler rebuild verification.
13. Support for displaying multiple values with `show`, including their units.
14. Unicode unit formatting by default, with optional ASCII output.
15. Support for environment variables using `sys::setenv`.
16. Commands for creating projects, building programs, and running tests.
17. Support for creating applications and libraries.
18. Support for shared (`.so`) and static (`.a`) libraries.
19. Support for bitwise operators.
20. Support for `choose` and `case` statements.
21. Support for `every` loops.
22. Support for `take` and `read` input operations.
23. Correct `not` operator precedence.
24. Support for multi-line function calls and literals.

## Remaining work

- Runtime hardening: memory is never freed (no garbage collector).
- Portability: only x86-64 Linux; other architectures/OSes need their
  system constants. Verified with Clang 22.1.8, glibc 2.43, musl 1.2.5.
- `parallel` has no OS threads in compiled programs; `watch`/`interrupt`
  run their body once.
- More conformance tests, especially error paths.
- Keep `README.md`, this file, `lepthorn/docs/ROADMAP.md`

# Next Steps Toward Lepthorn Release

# Phase 0  
*Lepthorn Core grammar and semantics locked*
1. Finalize the core language grammar.
2. Define clear rules for all language features.
3. Make syntax and behavior consistent.
4. Lock the core language specification before adding new features.
# Phase 1
*Units, dimensions, quantities complete* 
1. Final lexical rules
2. Nested comments
3. identifiers and reserved words
4. literals
5. units
6. dimensions
7. quantities
8. arithmetic/unit algebra
9. ensure/suppose
10. functions and return behavior
11. control flow
12. loops and timing syntax
13. concurrency syntax
14. collections
15. parser diagnostics
16. CTV rules
17. native/eval conformance tests
18. documentation synchronization

# Phase 2
*Memory/resource/real-time correctness model*
#Phase 3  
*Stable native ABI and FFI*

#Phase 4
*engines: UPE, UME, UMEE, etc*
#Phase 4B  
*ros2::init, node, spin*
#Phase 5  
*Publisher/subscriber support*
#Phase 6
*Units-aware ROS message wrappers*
#Phase 7
*QoS, timing, deterministic executor support*
#Phase 8
*Services/actions/parameters/TF2*
#Phase 9  
*ament/CMake/package integration*
# Phase 10 
*Autonomous ROS 2 demonstration*
