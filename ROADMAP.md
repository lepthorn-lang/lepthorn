# Lepthorn roadmap

This file tracks the Lepthorn compiler, `lepthornc`, and the steps
toward a Lepthorn release.

## Design principles: ROMANCE

Every language decision is checked against these seven rules:

- **R**eliability before release.
- **O**rder in every operation.
- **M**eaning in every measurement.
- **A**ccuracy in every algorithm.
- **N**o silent failure.
- **C**orrectness in every calculation.
- **E**ngineering for every machine.

## Direction

- Native code close to the machine, and as fast as Rust.
- No pointers and no borrows in user code.
- No garbage collector: no collector threads and no stop-the-world
  pauses. Memory and resources are released at points the program
  makes clear.
- A small core. Engines and libraries (ROS 2 among them) are built on
  top of it, not inside the compiler.

## Completed features: lepthornc 1.0.0

1. Complete LLVM native code generation written in Lepthorn.
2. All values use a 64-bit representation, with the runtime written in LLVM IR without C.
3. Self-hosted compiler that can rebuild itself and produce an identical binary.
4. One official compiler: the `lepthornc` installed on the system. `just install` replaces it only after the new compiler rebuilds itself into an identical binary. No bootstrap compiler is required, and the repository keeps no compiler binary.
5. Support for glibc and musl, including static and dynamic builds.
6. Automatic detection of project paths, Clang, and system libraries.
7. `justfile` for common development commands, with a tool check and a two-stage compiler build.
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
20. Support for `choose` and `case` statements, on numbers with units, text, and true/false.
21. Support for `every` loops.
22. Support for `take` and `read` input operations.
23. Correct `not` operator precedence.
24. Support for multi-line function calls and literals.
25. `loop_hz 100Hz` as well as `loop_hz(100)`.
26. `stop` and `next` outside a loop are errors before the program runs.
27. Errors found before the program runs show the file, the line, and the source line.
28. `lepthornc help`, and `lepthornc resolve` for a whole project.

## Remaining work

- Runtime hardening: memory is never freed (no garbage collector).
- Portability: only x86-64 Linux; other architectures/OSes need their
  system constants. Verified with Clang 22.1.8, glibc 2.43, musl 1.2.5.
- `parallel` has no OS threads in compiled programs; `watch`/`interrupt`
  run their body once.
- Unit mismatches (for example `2kg + 3m`) are found while the program
  runs, not before. The program then prints an error but keeps running
  with the value 0, and exits with status 0.
- Under `eval`, deep recursion stops before a depth of 10000.
- `ensure` does not lock array items or shape fields.
- More conformance tests, especially error paths.
- Keep `README.md`, this file and the docs in step with the compiler.

## Next steps toward a Lepthorn release

### Phase 0
*Complete the core grammar and syntax*
1. Finalize the core language grammar.
2. Define clear rules for all language features.
3. Make syntax and behavior consistent.
4. Lock the core language specification before adding new features.
5. Check every rule against ROMANCE.

Covers:
1. Final lexical rules
2. Nested comments
3. Identifiers and reserved words
4. Literals
5. ensure/suppose
6. Functions and return behavior
7. Control flow
8. Loops and timing syntax
9. Concurrency syntax
10. Collections
11. Parser diagnostics
12. CTV rules
13. Native/eval conformance tests
14. Documentation synchronization
15. ROMANCE written into the spec, and `lepthornc romance`, a command
    that prints the seven rules (a command, not a keyword).
16. `error "message"`: stops the current path with a clear runtime
    error and a non-zero exit status. The message must be Text.
17. Decide before the grammar is locked:
    - the syntax for a block that releases its memory and resources
      when it ends (not `use`, which already means "include a file");
    - whether to add sized number types (`i32`, `u8`, `f64`) and
      typed parameters, needed for FFI;
    - error codes: `LEC` for compiler errors, `LER` for runtime and
      real-time errors (today runtime errors are `LEC80xx`).

### Phase 1
*Units, dimensions and quantities complete: unit awareness everywhere*
1. Units
2. Dimensions
3. Quantities
4. Arithmetic and unit algebra
5. Unit mismatches found before the program runs (CTV).
6. A unit mismatch found while running stops the program, instead of
   going on with the value 0.
7. Comparisons check units: `1kg < 2m` is an error (today it gives
   `true`).
8. Units checked everywhere a value goes: function parameters and
   return values, array items, shape fields, `take`/`read` input,
   `choose`, `every` and `loop_hz`.
9. Conversion and display for every supported unit.
10. Native/eval conformance tests for units.

### Phase 2
*Memory, resource and real-time correctness model*

#### 2A. Zero-GC memory model
1. No garbage collector, no collector threads, no stop-the-world
   pauses.
2. Memory is freed (today it never is), at fixed points: when a scope
   or region ends.
3. Region (arena) allocation, with bounded memory use for real-time
   code.
4. No pointers and no borrows for the user; the compiler does the
   bookkeeping.

#### 2B. Resource model
1. Files, sockets, device handles and ROS 2 handles are released in a
   fixed order when their block ends.
2. A resource that is not released, or used after release, is an
   error.

#### 2C. Real-time correctness
1. `every` and `loop_hz` keep exact timing (fixed release points, no
   drift), measured and tested.
2. `deadline` and `timeout` are checked and reported correctly.
3. `parallel` runs on real OS threads in compiled programs, with
   `priority`, `atomic` and `shared`.
4. `watch` and `interrupt` run on real events.
5. No hidden allocation inside `loop_hz` or `deadline`: allocation
   there is a compile error, unless the code says so with an
   `allow allocation` block.
6. `error CODE "message"` with fixed codes (for example
   `SENSOR_STALE`, `DEADLINE_MISSED`, `ACTUATOR_RANGE`).
7. `on error` handlers that run a fixed fallback (for example a safe
   stop), with no hidden stack unwinding.
8. Deterministic behavior: the same input gives the same output, in
   eval and native alike.

### Phase 3
*Stable native ABI and FFI*
1. `extern` declarations for C functions.
2. C-compatible integer and float types.
3. Opaque handles for foreign objects (no raw pointers for the user).
4. C-compatible struct layout.
5. Static and dynamic linking.
6. Foreign error codes turned into Lepthorn errors.

### Phase 4A and Phase 4B (in parallel)
Both need Phase 3 and can be done at the same time.

#### Phase 4A
*Engines: UPE, UME, UMEE (Unified Mechanical Engineering Engine), etc.*

#### Phase 4B
*ROS 2: ros2::init, node, spin*

ROS 2 support is a separate official library, `ros2`, not part of the
compiler. It wraps the ROS 2 C API (`rcl`), which sits on `rmw` and
DDS. A Lepthorn node is a normal native program, built in a ROS 2
package and started with `ros2 run`. The user sees only the Lepthorn
API (`ros2::init`, `ros2::node`, `ros2::spin`, `ros2::spin_once`,
`ros2::shutdown`); the raw `rcl` calls stay inside the library.

### Phase 5
*Publisher/subscriber support*

### Phase 6
*Units-aware ROS message wrappers*

A publisher for `Velocity` rejects a value in `kg` before the program
runs. Plain ROS messages are converted to typed values explicitly.
Data from the network is checked (unit, frame, range, age) before the
control code uses it.

### Phase 7
*QoS, timing, deterministic executor support*

Typed QoS settings (reliability, history, depth, deadline). A
deterministic executor (`rclc`-style) for hard real-time code; the
standard ROS 2 executor is not treated as real-time.

### Phase 8
*Services/actions/parameters/TF2*

Also lifecycle nodes, launch files, diagnostics and rosbag.

### Phase 9
*ament/CMake/package integration*

`package.xml` and `CMakeLists.txt` with an ament bridge first; later
perhaps a `lepthornc ros2 build` command. Built with `colcon build`.

### Phase 10
*Autonomous ROS 2 demonstration*

A simulated differential-drive robot: IMU and odometry in, a 100 Hz
Lepthorn PID controller, `/cmd_vel` out, and a safe stop when sensor
data is stale or out of range.
