# Lepthorn roadmap

This file tracks the Lepthorn compiler, `lepthornc`, and the steps
toward a Lepthorn release.

## Design philosophy: ROMANCE

Every language decision is checked against these seven rules:

- **R**eliability before release.
- **O**rder in every operation.
- **M**eaning in every measurement.
- **A**ccuracy in every algorithm.
- **N**o silent failure.
- **C**orrectness in every calculation.
- **E**ngineering for every machine.

## Direction

- Native code close to the machine, with performance as a primary
  design goal comparable to systems languages such as Rust.
- No pointers and no borrows in user code.
- No garbage collector: no collector threads and no stop-the-world
  pauses. Memory and resources are reclaimed at explicit points the
  program makes clear.
- A small core. Engines and libraries, including ROS 2, are built on
  top of the core, not inside the compiler.

## Completed features: lepthornc 1.0.0

1. Complete LLVM native code generation written in Lepthorn.
2. All values use a 64-bit representation, with the runtime written
   in LLVM IR without C.
3. Self-hosted compiler that can rebuild itself and produce an
   identical binary.
4. One official compiler: the `lepthornc` installed on the system.
   `just install` replaces it only after the new compiler rebuilds
   itself into an identical binary. No bootstrap compiler is required,
   and the repository keeps no compiler binary.
5. Support for glibc and musl, including static and dynamic builds.
6. Automatic detection of project paths, Clang, and system libraries.
7. `justfile` for common development commands, with a tool check and
   a two-stage compiler build.
8. `manifest.lepm` for project settings, packages, build targets,
   tests, profiles, and platforms.
9. Strict manifest validation with clear error messages and line
   numbers.
10. Released under the Apache-2.0 license.
11. Built-in interpreter (`eval`) that follows the same rules as
    compiled programs.
12. Built-in testing with `lepthornc test`, including compiler
    rebuild verification.
13. Support for displaying multiple values with `show`, including
    their units.
14. Unicode unit formatting by default, with optional ASCII output.
15. Support for environment variables using `sys::setenv`.
16. Commands for creating projects, building programs, and running
    tests.
17. Support for creating applications and libraries.
18. Support for shared (`.so`) and static (`.a`) libraries.
19. Support for bitwise operators.
20. Support for `choose` and `case` statements, on numbers with
    units, text, and true/false.
21. Support for `every` loops.
22. Support for `take` and `read` input operations.
23. Correct `not` operator precedence.
24. Support for multi-line function calls and literals.
25. `loop_hz 100Hz` as well as `loop_hz(100)`.
26. `stop` and `next` outside a loop are errors before the program
    runs.
27. Errors found before the program runs show the file, the line,
    and the source line.
28. `lepthornc help`, and `lepthornc resolve` for a whole project.

## Remaining work

- Runtime hardening: memory is not yet reclaimed. Lepthorn has no
  garbage collector, but it also does not yet provide a complete
  explicit ownership or region-based release model.
- Portability: only x86-64 Linux; other architectures and operating
  systems need their system constants. Verified with Clang 22.1.8,
  glibc 2.43, and musl 1.2.5.
- `parallel` has no OS threads in compiled programs;
  `watch` and `interrupt` run their body once.
- Units are checked before running where they can be known (numbers
  with units, variables, `*` and `/`, function calls). Input, shape
  fields, array items and collections are checked while running; a
  mismatch there stops the program.
- Under `eval`, deep recursion stops before a depth of 10000.
- `ensure` does not lock array items or shape fields.
- More conformance tests, especially error paths.
- Keep `README.md`, this file, and the documentation in step with
  the compiler.

## Next steps toward a Lepthorn release

### Phase 0
*Complete the core grammar, syntax, and design principles*

1. Finalize the core language grammar.
2. Define clear rules for all language features.
3. Make syntax and behavior consistent.
4. Lock the core language specification before adding new features.
5. Check every rule against ROMANCE.

Covers:

1. Final lexical rules and nested comments.
2. Numbers. Every number has a value and one of four kinds:
   - **Dimensioned quantity**: a value with a unit (`23kg`, `23m`,
     `23s`, `23A`). `1m` and `100cm` have the same dimension and
     convert to each other.
   - **Dimensionless value**: all SI exponents are 0; the SI unit is
     1. A plain `23` is dimensionless and never becomes a mass or a
     length by itself. `10m / 2m` is dimensionless.
   - **Semantic scalar**: dimensionless, but with its own meaning, so
     two semantic scalars do not mix freely. Examples include ratio,
     probability, and angle (`rad`, `deg`).
   - **Machine value**: not a physical quantity. Examples include
     index, count, bit mask, register value, and address
     (`23u32`, `23usize`, `0x12345`).
3. Identifiers and reserved words.
4. Literals.
5. `ensure` and `suppose`.
6. Functions and return behavior.
7. Control flow.
8. Loops and timing syntax.
9. Concurrency syntax.
10. Collections.
11. Parser diagnostics.
12. Compile-time validation rules.
13. Native and eval conformance tests.
14. Documentation synchronization.
15. ROMANCE written into the specification, and `lepthornc romance`,
    a command that prints the seven rules. It is a command, not a
    keyword.
16. `error "message"`: stops the current path with a clear runtime
    error and a non-zero exit status. It is allowed only inside a
    function, task, or block. The message must be Text. The same
    input always produces the same error, so behavior is
    deterministic. `logical_error` is not a keyword.
    Two forms: `error "message"` is a generic runtime error, and
    `error CODE "message"` uses a fixed error code (Phase 2C). CODE
    must be a known error name.
17. Decide before the grammar is locked, but do not necessarily
    implement yet:
    - The syntax for a block that reclaims memory and releases
      resources when it ends. `use` already means "include a file,"
      so it will not be used for this purpose.
    - The syntax for machine values (`23u32`, `23usize`, `0x12345`)
      and sized types (`i32`, `u8`, `f64`) needed for FFI.
    - Whether function parameters can name their kind, for example
      `mass: Mass`, or whether the checker infers it.
    - Error-code naming: `LEC` for errors found before the program
      runs and `LER` for errors while it runs. Done: every error is
      in `src/core/errors/`, and `lepthornc explain CODE` shows it.
18. `use` lines are found only outside comments and texts, so a
    comment that talks about `use "file.lep"` never pulls in a file.
    Done.
19. Tests written in the code itself, the way Rust has `#[test]` and
    `assert_eq!`: a way to name a test and check a value inside a
    `.lep` file (for example `expect add(2kg, 3kg) == 5kg`), run by
    `lepthornc test`. Then most tests need no `.out` file.

### Phase 1
*Units, dimensions, and quantities complete: unit awareness everywhere*

1. Units, with each group in its own folder under
   `src/core/units/`:
   - `general_units/` for SI units.
   - `IEEE/` for IEEE units.
   - `American/` for United States customary units.
2. Dimensions.
3. Quantities.
4. Arithmetic and unit algebra.
5. Unit mismatches found before the program runs through compile-time
   validation (`src/core/ctv/checker.lep`). Done for numbers with
   units, variables, `*` and `/`, and function calls. Still to do:
   array items (an array of lengths keeps the unit of its items) and
   shape fields (a field keeps the unit it was built with), then
   input.
6. A unit mismatch found while running stops the program instead of
   continuing with the value 0. Done.
7. Comparisons check units. For example, `1kg < 2m` is an error.
   Done.
8. Units are checked everywhere a value goes: function parameters and
   return values, array items, shape fields, `take` and `read` input,
   `choose`, `every`, and `loop_hz`.
9. Conversion and display for every supported unit.
10. Engine functions declare what they take and give. For example,
    `force::gravity` takes a Mass and gives a Force.
    `force::gravity(10m)` is an error before the program runs.
    A plain number is still allowed as a factor: `mass * 9.81` is a
    mass. The error occurs only when a value is used where a different
    kind is declared.
11. Dimensions are checked at compile time and cost nothing at run
    time. A unit is retained at run time only where it is needed:
    printing, input, dynamic values, and error messages.
12. Native and eval conformance tests for units.

### Phase 2
*Memory, resource, and real-time correctness model*

#### 2A. Zero-GC memory model

1. No garbage collector, no collector threads, and no stop-the-world
   pauses.
2. Memory is reclaimed at explicit scope or region boundaries.
3. Region-based allocation, with bounded memory use for real-time
   code.
4. No raw pointers or borrows are exposed in user-level Lepthorn
   code. The compiler performs the bookkeeping. The FFI and ROS 2
   layers may use opaque handles inside the library.

#### 2B. Resource model

1. Files, sockets, device handles, and ROS 2 handles are released in
   a fixed order when their block ends.
2. A resource that is not released, or is used after release, is an
   error.

#### 2C. Real-time correctness

1. `every` and `loop_hz` use fixed release points and are measured
   for period stability, drift, and deadline behavior.
2. `deadline` and `timeout` are checked and reported correctly.
3. `parallel` runs on real OS threads in compiled programs, with
   `priority`, `atomic`, and `shared`.
4. `watch` and `interrupt` run on real events.
5. No hidden allocation is allowed inside `loop_hz` or `deadline`.
   Allocation there is a compile error unless the code explicitly
   allows it with an `allow allocation` block.
6. `error CODE "message"` uses fixed error codes:
   - `SENSOR_STALE`
   - `SENSOR_INVALID`
   - `SENSOR_UNAVAILABLE`
   - `ACTUATOR_RANGE`
   - `ACTUATOR_UNAVAILABLE`
   - `DEADLINE_MISSED`
   - `TIMEOUT`
   - `RESOURCE_EXHAUSTED`
   - `BOUNDS_VIOLATION`
   - `UNIT_MISMATCH`
   - `CONCURRENCY_VIOLATION`
7. `on error` handlers run a fixed fallback action, such as a safe
   stop. There is no hidden stack unwinding; control moves to the
   handler in a fixed, known way.

   First rule: `on error` catches errors in its enclosing `realtime`
   block, runs a fixed fallback action, and then stops the task.
   Still to decide: which codes it catches, whether it can fail
   itself, whether it can resume normal running, whether handlers can
   be nested, and whether it may allocate.

   Example:

   ```
   realtime
       on error
           actuator::safe_stop()
       done()
       loop_hz 100Hz
           ensure sample = sensor::read()
           when sample.age > 50ms
               error SENSOR_STALE "sensor data is older than 50ms"
           done()
           control::step(sample)
       done()
   done()
   ```

   A runtime error prints its code, message, task, and action:

   ```
   LER6101: SENSOR_STALE
   message: sensor data is older than 50ms
   task: control_loop
   action: safe_stop
   ```
8. A missed deadline becomes a `DEADLINE_MISSED` error. Today it is
   only a warning, `LER6001`. The check happens right after the loop
   body ends and before the next release point, using a monotonic
   clock. A miss runs the nearest `on error` handler; it never
   continues silently. Build the recovery grammar only after its
   behavior is written down exactly.
9. Deterministic behavior: the same input gives the same output in
   both eval and native execution.

### Phase 3
*Stable native ABI and FFI*

1. `extern` declarations for C functions.
2. C-compatible integer and floating-point types.
3. Opaque handles for foreign objects. No raw pointers are exposed to
   the user.
4. C-compatible struct layout.
5. Static and dynamic linking.
6. Foreign error codes are translated into Lepthorn errors.

### Phase 4A and Phase 4B
*Run in parallel; both require Phase 3*

#### Phase 4A
*Engines: UPE, UME, UMEE, and related engineering engines*

UPE, UME, UMEE, and related engines are separate libraries built on
the Lepthorn core.

#### Phase 4B
*ROS 2 foundation: `ros2::init`, `ros2::node`, `ros2::spin`*

ROS 2 support is a separate official library named `ros2`, not part
of the compiler. It wraps the ROS 2 C API (`rcl`), which sits above
`rmw` and DDS.

A Lepthorn node is a normal native program, built in a ROS 2 package
and started with `ros2 run`. The user sees only the Lepthorn API:

- `ros2::init`
- `ros2::shutdown`
- `ros2::node`
- `ros2::spin`
- `ros2::spin_once`

Raw `rcl` calls remain inside the library.

The ROS 2 source is cloned only to study the `rcl` API, the build
system and the examples. Small local patches are allowed for
experiments (a C probe for `rcl_init` and `rcl_node_init`, debug
logs, link flags), but the final product has no ROS 2 patch: the
`ros2` library uses only the public `rcl` API and links against an
installed ROS 2. `rcl`, `rmw`, DDS and the ROS 2 executor are never
changed.

First milestone: a Lepthorn node publishes `Hello from Lepthorn` on a
topic, and the standard ROS 2 `listener` receives it.

### Phase 5
*Publisher and subscriber support*

Implement ROS 2 publishers and subscribers through the Lepthorn
`ros2` library. First only simple messages (`std_msgs/String`,
`Float64`, `Int32`, `Bool`), then `geometry_msgs/Twist`, `Vector3`,
`sensor_msgs/Imu` and `nav_msgs/Odometry`.

### Phase 6
*Units-aware ROS message wrappers*

A publisher for `Velocity` rejects a value in `kg` before the program
runs. Plain ROS messages are converted to typed Lepthorn values
explicitly.

Data received from the network is checked before control code uses
it:

```text
ROS message
 |
 v
deserialize
 |
 v
validate message type
 |
 v
validate units
 |
 v
validate frame
 |
 v
validate timestamp and age
 |
 v
validate numeric range
 |
 v
convert to trusted Lepthorn quantity
 |
 v
control logic
```

### Phase 7
*QoS, timing, and deterministic executor support*

Provide typed QoS settings:

- Reliability
- History
- Depth
- Deadline

Provide a deterministic executor, in the style of `rclc`, for hard
real-time code. The standard ROS 2 executor is not assumed to provide
hard real-time guarantees. Deterministic running comes from this
separate executor.

### Phase 8
*Services, actions, parameters, and TF2*

Also include lifecycle nodes, launch files, diagnostics, and rosbag
support.

### Phase 9
*ament and CMake package integration*

Provide `package.xml` and `CMakeLists.txt` with an ament bridge first.
Later, possibly provide a `lepthornc ros2 build` command. Build with:

```
colcon build
```

### Phase 10
*Autonomous ROS 2 demonstration*

Build a simulated differential-drive robot:

- IMU and odometry input.
- A 100 Hz Lepthorn PID controller.
- `/cmd_vel` output.
- A safe stop when sensor data is stale or out of range.
