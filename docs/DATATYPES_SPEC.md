# Planned Type System

**This is a plan. Almost none of it is built.** What works today is in
[DATATYPES.md](DATATYPES.md). This document describes where the type
system is meant to go, so that new features fit one design.

## The idea: small for the user, richer inside

The programmer should only have to know three basic types:

| Type | Holds | Example |
|---|---|---|
| `Number` | whole numbers and fractions, with or without a unit | `21`, `9.80665`, `25kg` |
| `Text` | any text, one character or many | `"A"`, `"scout"` |
| `Boolean` | true or false | `true` |

Inside, the compiler would use more precise types, chosen by fixed
rules and never by guessing:

```text
What the programmer writes:   Number   Text   Boolean
What the compiler works with: Integer  Float  Fixed  Decimal
                              Quantity Vector Matrix Tensor
What the machine stores:      bits8  bits16  bits32  bits64
```

For example, `25` would be an Integer inside, `9.81` a Float or
Decimal, and `25kg` a Quantity. If a rule cannot pick one answer, that
is a compile error, not a silent default.

Today every Number is a 64-bit float, with an optional unit.

## Engineering types

Named physical quantities, all built on the unit system:

```text
Force   Velocity   Acceleration   Energy   Power
Voltage   Current   Pressure   Temperature
```

The unit system already works (see [DATATYPES.md](DATATYPES.md)). The
plan adds names for these quantities, more units (volt, ampere,
kelvin, ...), and checking units before the program runs.

Planned rules:

- Units are converted automatically only between units of the same
  quantity: `10km + 500m` is fine, `10kg + 5m` is a compile error.
- A file may start with `units SI`. SI is the default.

## Mathematics types

```text
Scalar   Vector   Matrix   Tensor   Complex   Quaternion   Polynomial
```

Today only 3-part vectors and 3×3 rotation matrices exist, with no
arithmetic.

## System types

For low-level and hardware code:

```text
Pointer   Address   Handle   Process   Thread   Task   Device   File
```

Fixed-width types, for registers and ports, where the exact size
matters:

```text
bits8      bits16      bits32      bits64
register8  register16  register32  register64
port8      port16      port32
```

```lepthorn
register32 UART = 0x10000000     (* planned syntax, does not parse today *)
```

Today only file handles exist.

## Autonomous-system types

Types for robots and vehicles:

```text
Sensor   Actuator   Motor   Camera   Lidar   GPS   IMU
```

How these relate to lower-level hardware types (GPIO, PWM, UART, SPI,
I2C, CAN) is not decided yet.

## Collections

The core collections are final and all exist today:

```text
Array   Queue   Stack   RingBuffer   (and shapes, for records)
```

They have a fixed size or capacity, which suits real-time code.
General collections such as Map, HashMap, Set or a growable List will
not be added to the core language. A project that needs one can build
it in Lepthorn code.

## Order of work

The types build on each other, so they are added in this order:

1. the basic types and units (done)
2. checking types and units before the program runs
3. engineering types
4. mathematics types
5. system and fixed-width types
6. autonomous-system types

Each step gets its own design note before it is built (see
[METHODOLOGY.md](METHODOLOGY.md)).
