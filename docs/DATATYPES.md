# Data Types

This document describes the values a Lepthorn program can use today, how
units work, and how values are printed. The language rules are in
[SPEC.md](SPEC.md). The planned type system is in
[DATATYPES_SPEC.md](DATATYPES_SPEC.md).

Lepthorn has no type names in declarations. A variable gets its kind
from the value it holds:

```lepthorn
ensure mass = 25kg        (* a Number with a unit *)
ensure name = "scout"     (* Text *)
ensure ready = true       (* Boolean *)
```

## Number

A Number is a 64-bit floating point value. It can have a unit.

```lepthorn
ensure count = 42         (* no unit *)
ensure ratio = 0.75
ensure mass = 25kg
ensure delay = 10ms
```

Whole numbers and fractions are the same kind. There is no separate
integer type.

### Units

The unit goes right after the digits, with no space. These units are
known:

| Unit | Quantity | Stored as |
|---|---|---|
| `kg` | mass | 1 kg |
| `g` | mass | 0.001 kg |
| `t` | mass | 1000 kg |
| `m` | length | 1 m |
| `km` | length | 1000 m |
| `cm` | length | 0.01 m |
| `mm` | length | 0.001 m |
| `s` | time | 1 s |
| `ms` | time | 0.001 s |
| `min` | time | 60 s |
| `h` | time | 3600 s |
| `N` | force | 1 kg·m/s² |
| `kN` | force | 1000 kg·m/s² |
| `MN` | force | 1000000 kg·m/s² |
| `mps` | speed | 1 m/s |
| `Hz` | frequency | 1 s⁻¹ |
| `kHz` | frequency | 1000 s⁻¹ |
| `rad` | angle | 1 rad |
| `degree`, `deg` | angle | 0.0174533 rad (π/180) |

A unit that is not in the table is an error.

Every value is stored in SI base units: kilogram, metre, second and
radian. The unit is a list of powers of these base units, so a force
is kg¹·m¹·s⁻². That is why `2.8kN` shows as `2800 kg·m/s² (N)`, and why
`5000g == 5kg` is `true`.

The unit list also has places for ampere, kelvin, mole and candela, but
no literal uses them yet.

### Combining units

- `a * b` and `a / b` add or subtract the powers: `10m / 2s` is
  `5 m/s`, `40kg * 2m / 1s / 1s` is `80 kg·m/s² (N)`.
- `a + b`, `a - b` and `a % b` need the same unit on both sides.
- `a ** n` multiplies the powers by `n`. With a unit, `n` must be a
  whole number: `(3m) ** 2` is `9 m²`.
- Comparisons need the same unit on both sides.

If `+`, `-` or `%` get different units, the program prints `LEC8025`,
uses 0 as the result, and goes on. This check happens while the program
runs. It is not done before.

### Numbers used as whole numbers

Some places need a whole number with no unit: array indexes,
`repeat N`, collection capacities, `text::slice` positions, and the
bitwise operators. A fraction is cut down where a count is expected
(`repeat 2.5` runs twice). The bitwise operators stop the program if
the number is not whole.

The bitwise operators work on 64-bit integers:

```lepthorn
show 7 & 3  7 | 8  5 ^ 1  ~0  1 << 4  256 >> 2
```

```text
3 15 4 -1 16 64
```

## Text

Text is a sequence of bytes, written in double quotes. There is no
separate character type: a single character is a Text of length 1.

```lepthorn
ensure greeting = "Hello, " + "Lepthorn"
show greeting text::length(greeting)
```

```text
Hello, Lepthorn 15
```

- `+` joins two Texts. Any other arithmetic on Text is an error.
- `== != < > <= >=` compare Texts byte by byte.
- There are no escape sequences. `text::from_code(34)` gives a `"`,
  `text::from_code(10)` a newline.
- UTF-8 is allowed in literals, but lengths and positions count bytes.
- To turn a value into Text, use `text::format(v)` or, for a number,
  `text::from_number(n)`. To read a number from Text, use
  `text::to_number(t)`.

The other text functions are listed in [SPEC.md](SPEC.md).

## Boolean

`true` or `false`. Comparisons give Booleans. `when`, `until` and
`wait` need a Boolean condition.

```lepthorn
ensure heavy = 30kg > 25kg     (* true *)
show heavy and not false       (* true *)
```

## Array

An array has a fixed number of items, set by its literal.

```lepthorn
suppose masses = [10kg, 25kg, 4kg]
masses[2] = 5kg
show masses length(masses)
```

```text
[10 kg, 25 kg, 5 kg] 3
```

- Indexes start at 0. A wrong index stops the program with `LEC8013`.
- The items can be of any kind, and of different kinds.
- An array is shared, not copied: a function that changes an item of
  an array it was given changes the caller's array.

## Shapes

A shape is a record with named fields. It is declared once, at the top
level, and then built with `Name(field = value, ...)`.

```lepthorn
shape Drone
    name: Text
    mass: Number
    thrust: Number
done()

suppose d = Drone(name = "scout", mass = 1.2kg, thrust = 20N)
d.thrust = 22N
show d
```

```text
Drone(name = scout, mass = 1.2 kg, thrust = 22 kg·m/s² (N))
```

The type written after each field name is not checked. A shape value is
shared, not copied, like an array.

## RingBuffer, Queue and Stack

These hold a changing number of items, up to a fixed capacity. They are
used through `ring::`, `queue::` and `stack::` functions (listed in
[SPEC.md](SPEC.md)).

```lepthorn
ensure log = ring::create(3)
ring::write(log, 1)
ring::write(log, 2)
show log ring::peek(log, 0)
```

```text
RingBuffer[2/3] 1
```

They print as `Kind[count/capacity]`. The items can be of any kind.

## File handle

`file::open` returns a handle. It prints as `Handle(mode, open)` or
`Handle(mode, closed)`.

## Vector and Matrix

`vector(x, y, z)` makes a vector of three numbers. `matrix::rotationZ(a)`
makes a 3×3 rotation matrix. They can be printed and stored, but there
is no arithmetic on them yet.

```text
(1 m, 2 m, 3 m)
[[6.12323e-17, -1, 0], [1, 6.12323e-17, 0], [0, 0, 1]]
```

## How values are printed

`show` and `text::format` print values the same way:

| Value | Printed as |
|---|---|
| Number, no unit | at most 6 significant digits: `42`, `0.333333`, `1e+06` |
| Number with a unit | the number, a space, the unit: `25 kg` |
| Text | the text, no quotes |
| Boolean | `true` or `false` |
| Array | `[a, b, c]` |
| shape | `Name(field = value, ...)` |
| collection | `RingBuffer[2/8]`, `Queue[0/4]`, `Stack[1/2]` |

### How units are written

Units are written SI style, in Unicode by default:

| Value | Unicode (default) | ASCII |
|---|---|---|
| `392.266` N | `392.266 kg·m/s² (N)` | `392.266 kg*m/s^2 (N)` |
| `392.266` Pa | `392.266 kg/(m·s²) (Pa)` | `392.266 kg/(m*s^2) (Pa)` |
| `0.5` Hz | `0.5 s⁻¹ (Hz)` | `0.5 s^-1 (Hz)` |
| `1176.8` J | `1176.8 kg·m²/s² (J)` | `1176.8 kg*m^2/s^2 (J)` |
| `5` m/s | `5 m/s` | `5 m/s` |
| `25` kg | `25 kg` | `25 kg` |

The rules:

- the units with a positive power come first, joined by `·` (ASCII
  `*`), then `/` and the units with a negative power
- when more than one unit is under the `/`, they go in parentheses
- when no unit has a positive power, negative powers are used: `s⁻¹`
- powers other than 1 are written as superscripts (ASCII `^2`)
- when the unit has a common name, it follows in parentheses: `(N)`,
  `(J)`, `(Pa)`, `(W)`, `(Hz)`

To get ASCII, set `LEPTHORN_OUTPUT=ascii`, or pass `--ascii` to
`lepthornc run`, `eval` or `test`. A running program reads this setting
each time it prints a unit, so `sys::setenv("LEPTHORN_OUTPUT", "ascii")`
changes it from inside the program. Only the way the unit is written
changes, never the value.

## Input

`take name` reads a line and turns it into a Number. The line can have
a unit: `40kg`. `read name` reads a line as Text. Both print a prompt
first (`take name: `), and both stop the program at the end of input.
