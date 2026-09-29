# Introduction to Lepthorn

Lepthorn is a programming language for engineering and real-time
software: robots, drones, vehicles, control loops, sensors and motors,
and science and engineering calculations. It is made by Ali Zain.

It is not a general-purpose language for apps or websites.

## The main idea

In most languages a number is only a number. The language does not
know if `25` is a mass, a length or a time, so it cannot stop you from
adding a mass to a length. In control software, a mistake like that
gives a wrong answer with no warning.

In Lepthorn a number can carry a unit, and the unit stays with it:

```lepthorn
ensure mass = 25kg
show "weight:" force::gravity(mass)
```

```text
weight: 245.166 kg·m/s² (N)
```

Dividing a length by a time gives a speed. Multiplying a mass by an
acceleration gives a force. `2.8kN` is stored as 2800 newtons and
`90degree` as 1.5708 radians, so values in different units can be used
together safely.

Adding values of different kinds is reported:

```lepthorn
ensure a = 5kg
ensure b = 3m
suppose c = a + b
```

```text
LEC8025: runtime error: dimension mismatch in +
```

Today this check happens while the program runs. Checking units before
the program runs is the next big step.

## Who it is for

- engineers who write control or embedded software
- robotics, drone and vehicle developers
- mechanical, electrical, aerospace and mechatronics engineers
- people who write simulations and other science code

## The core ideas

1. **A number knows what it measures.** `25kg` is a mass everywhere it
   is used.
2. **Two kinds of variables.** `ensure` makes a value that cannot be
   changed. `suppose` makes one that can. Changing an `ensure` value is
   an error before the program runs.
3. **Physics reads like physics.** `force::gravity(mass)` and
   `motion::velocity(distance, time)` are grouped by topic.
4. **Code runs in order.** Every line runs when it is reached. Nothing
   is delayed or run lazily, so you know when each step happens.
5. **A small core.** The core language has numbers with units, text,
   true/false, a few fixed collections, records (`shape`), functions,
   and timing statements. Physics, robotics and other topics are meant
   to live in libraries.

## A short program

```lepthorn
shape Drone
    name: Text
    mass: Number
    thrust: Number
done()

make lift_margin(d)
    done(d.thrust - force::gravity(d.mass))
done()

ensure scout = Drone(name = "scout", mass = 1.2kg, thrust = 20N)
show "lift margin:" lift_margin(scout)
```

```text
lift margin: 8.23202 kg·m/s² (N)
```

## Where things stand

The compiler, `lepthornc`, is written in Lepthorn and compiles itself.
It turns a program into a native Linux program through LLVM and Clang,
and it can also run a program directly (`lepthornc eval`).

Working today:

- variables (`ensure`, `suppose`, `ensure!`, `suppose!`, `shared`)
- numbers with units, text, true/false
- arithmetic, comparison, logic and bitwise operators
- `when`/`otherwise`, `choose`/`case`, three kinds of `repeat`, `stop`,
  `next`
- `every` and `loop_hz` loops on a fixed timing grid, `wait`,
  `deadline`, `timeout`
- functions with recursion
- `shape` records, arrays, RingBuffer, Queue and Stack
- files, environment, running commands
- `show`, `take`, `read`
- projects with `manifest.lepm`, tests, and libraries (`.so`, `.a`)
- programs for glibc and musl Linux systems

Not done yet:

- checking units and types before the program runs
- real threads (`parallel` runs its tasks one after another)
- `watch` and `interrupt` on real events (they run their body once)
- unary minus, escape sequences in text
- vector and matrix arithmetic, trigonometry
- freeing memory while a program runs
- targets other than x86-64 Linux, microcontrollers, hardware access
- the planned engines for robotics, autonomous systems and AI

## Lepthorn and other languages

Lepthorn is not trying to replace Rust, C++, Python, ROS 2, AUTOSAR or
PX4. Those have mature tools that real vehicles and robots use today.
Rust and C++ already have unit-checking libraries, such as `uom` and
`mp-units`.

The question Lepthorn explores is different: what changes when units,
timing and engineering calculations are part of the language itself,
not a library you have to know about and add. That question is still
open.

## Where to go next

- [book/INTRODUCTION.md](book/INTRODUCTION.md): first steps with the
  compiler
- [SPEC.md](SPEC.md): the whole language
- [GRAMMAR.md](GRAMMAR.md): the exact syntax
- [DATATYPES.md](DATATYPES.md): values, units and printing
- [DATATYPES_SPEC.md](DATATYPES_SPEC.md): the planned type system
- [ARCHITECTURE.md](ARCHITECTURE.md): how the compiler works
- [METHODOLOGY.md](METHODOLOGY.md): how features are added
- [errors/](errors/): every error code
- `examples/`: programs you can run
