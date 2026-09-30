# Introduction to Lepthorn

> Code that knows its physics, timing, and limits.

Lepthorn is a correctness-first systems programming language for
engineering, scientific, real-time, embedded, robotics and autonomous
systems. It is made by Ali Zain.

It is for software where a wrong result, a bad memory access, a broken
physical model, a race between tasks, or a late result can make a real
machine fail.

Lepthorn cares about these kinds of correctness:

```text
memory       physical     timing        resources
concurrency  numbers      hardware-near execution
```

It is meant for:

- autonomous vehicles and robots
- drones and industrial robots
- real-time control systems
- embedded and microcontroller software
- engineering and scientific computation
- sensor and actuator processing
- machine and hardware control

It is not a language for web sites, mobile apps, databases or business
applications. It is for software that controls machines.

Each section below says what the language is meant to do, and what
works **today**.

## Correctness first

A program that breaks the language's rules is rejected. It is not
quietly run with a guessed meaning. "Correctness" does not mean that
every real-world property can be proved. It means that invalid,
unclear or unsupported code is not silently accepted.

**Today:** before a program runs, the checker rejects undeclared names,
changes to `ensure` values, unknown functions, wrong numbers of
arguments, `stop`/`next` outside a loop, and unprotected changes to
shared values inside `parallel`. While the program runs, wrong kinds of
values, array indexes out of range, division by zero and bad units in
physics functions stop the program with an error. Two unit mistakes are
reported but do not stop the program yet: `+`, `-` or `%` with
different units (`LEC8025`) and an exponent with a unit (`LEC8027`);
the result is 0.

## Memory safety

User code is meant to be memory safe with no "unsafe" escape hatch. User
code should never see:

```text
raw pointer access        pointer arithmetic
unchecked memory access   freeing memory twice
dangling references       memory corruption
```

Hardware access is meant to come through checked primitives, target
backends and typed libraries, not through unsafe blocks.

**Today:** the language has no pointers. Every array access is checked.
Memory cannot be freed by hand. The runtime never frees memory while a
program runs, so a long-running program that keeps making new values
keeps growing.

## Physical quantities

Units and dimensions are part of the core language:

```lepthorn
ensure mass = 25kg
ensure acceleration = 9.81mps / 1s
suppose force = mass * acceleration
show "Force is:" force
```

```text
Force is: 245.25 kg·m/s² (N)
```

Units are not only for physics. They are meant to cover electrical,
mechanical, aerospace, control and other quantities too. The core
language knows how units combine; engines provide the formulas.

**Today:** the units `kg g t m km cm mm s ms min h N kN MN mps Hz kHz
rad degree deg` can be written in numbers. Results are shown with the
right unit, including `J`, `W` and `Pa`. Units such as `A`, `K`, `V` and
`Ω` are planned. Unit mistakes are found while the program runs; finding
them before it runs is planned.

## Real-time execution

In a real-time system, a result is only correct if it comes in time. A
missed hard deadline can be a system failure. So timing is part of the
core language:

```text
every   loop_hz   deadline   timeout   wait
parallel   priority   atomic   shared
```

```lepthorn
suppose ticks = 0
loop_hz(100)
    ticks += 1
    when ticks >= 3
        stop
    done()
done()

deadline 5ms
    show "control step"
done()
```

A full control loop is meant to look like this (these libraries do not
exist yet):

```lepthorn
loop_hz 100Hz
    ensure position = sensor::read_position()
    ensure command = control::step(position)
    actuator::write(command)
done()
```

**Today:** `every` and `loop_hz` run on a fixed timing grid, and
`deadline` and `timeout` report late work. Everything runs on one
thread: `parallel` runs its tasks one after another, highest priority
first. `watch` and `interrupt` run their body once. Planned: real
threads, and analysis of bounded execution, memory use in loops,
scheduling, jitter and worst-case execution time.

## Native performance

Programs are compiled to native code, for systems where fast and
predictable execution matters.

The compiler is self-hosted: it is written in Lepthorn and compiles
itself, with no OCaml or C involved.

```text
Lepthorn source  ->  lepthornc (native)  ->  LLVM  ->  native program
```

**Today:** programs compile through LLVM and Clang to native x86-64
Linux programs, for glibc or musl. The same compiler can also run a
program directly (`lepthornc eval`), with the same results.

## A small core, and engines

The core language holds what every program needs: values, units,
variables, control flow, functions, records (`shape`), and a fixed set
of collections (`Array`, `Queue`, `Stack`, `RingBuffer`). General
collections such as maps and sets are not part of the core; libraries
can provide them.

Everything for a specific field goes into an engine:

| Engine | Topics |
|---|---|
| UME, Unified Mathematics Engine | vectors, matrices, trigonometry, numerical methods |
| UPE, Unified Physics Engine | force, motion, mass, energy, rotation, heat, fluids, collisions |
| UEE, Unified Engineering Engine | electrical systems, control, signal processing, mechanical and aerospace calculations |
| UAE, Unified Autonomous Systems Engine | sensors, actuators, world state, navigation, planning, robotics |

**Today:** a few functions exist: `force::gravity`,
`force::acceleration`, `motion::velocity`, `vector` and
`matrix::rotationZ`. Vectors and matrices cannot do arithmetic yet.
Names such as `circuit::ohms_law` or `control::pid` are examples of what
the engines will provide; they do not exist yet.

## Hardware direction

Kernel and driver code will not be built into the compiler. It will come
as Lepthorn libraries and target packages: kernel APIs, drivers, RTOS
integrations, board support, peripheral registers, sensor and actuator
interfaces.

The compiler is meant to reach below ordinary assembly-level
programming, through:

```text
target-specific native backends    machine-level IR
register-aware code generation     volatile operations
memory barriers                    atomic instructions
interrupt primitives               exact data layout
object and executable output
```

The planned backends:

```text
Lepthorn
  -> Lepthorn low-level IR
       -> LLVM backend        (today: the only backend)
       -> x86-64 backend
       -> RISC-V backend
       -> ARM backend
```

None of this needs an "unsafe" escape hatch for user code.

## What Lepthorn is and is not for

Lepthorn is not meant to be:

- a web development language
- a mobile app language
- a database-first language
- a general business application language
- a scripting language for every task

It is meant for autonomous machines, real-time engineering, robotics,
drones, embedded systems, control systems, scientific computation and
hardware-near software.

Its central question is:

> Can a systems language make physical, temporal, memory, resource and
> hardware correctness visible before a machine fails?

## Lepthorn and other languages

Lepthorn is not trying to replace Rust, C++, Python, ROS 2, AUTOSAR or
PX4. Those have mature tools that real vehicles and robots use today.
Rust has a well-tested memory safety model and qualified toolchains for
safety-critical work. Rust and C++ also have unit-checking libraries,
such as `uom` and `mp-units`.

Lepthorn asks a different question: what changes when units, timing and
engineering calculations are part of the language itself, instead of a
library you have to know about and add.

## Philosophy

Lepthorn does not try to be the best language for every kind of
software. It is for systems where:

- a wrong answer is dangerous
- a late answer is a wrong answer
- a unit mistake is not acceptable
- a memory error is not acceptable
- an uncontrolled resource is not acceptable
- unexpected timing is not acceptable

> Lepthorn is not designed to replace every programming language. It is
> designed to build the software that controls machines and systems
> where correctness matters.

## Where to go next

- [book/INTRODUCTION.md](book/INTRODUCTION.md): first steps
- [USAGE.md](USAGE.md): commands and options
- [PROJECTS.md](PROJECTS.md): making, building and testing projects
- [MANIFEST.md](MANIFEST.md): the `manifest.lepm` file
- [BUILDING.md](BUILDING.md): building the compiler itself
- [SPEC.md](SPEC.md): the whole language
- [GRAMMAR.md](GRAMMAR.md): the exact syntax
- [DATATYPES.md](DATATYPES.md): values, units and printing
- [DATATYPES_SPEC.md](DATATYPES_SPEC.md): the planned type system
- [ARCHITECTURE.md](ARCHITECTURE.md): how the compiler works
- [METHODOLOGY.md](METHODOLOGY.md): how features are added
- [errors/](errors/): every error code
- `examples/`: programs you can run
