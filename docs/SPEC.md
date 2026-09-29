# Lepthorn Language Specification

This document describes the Lepthorn language as `lepthornc` 1.0.0
implements it. The exact syntax is in [GRAMMAR.md](GRAMMAR.md). The
values and their units are described in more detail in
[DATATYPES.md](DATATYPES.md).

Every example here was run with `lepthornc`. Where the language is
still missing something, this document says so.

## 1. Programs

A program is one `.lep` file, plus the files it pulls in with `use`.
Statements run from top to bottom. There is no `main` function: the
top-level statements are the program.

```lepthorn
ensure mass = 25kg
show "weight:" force::gravity(mass)
```

```text
weight: 245.166 kg·m/s² (N)
```

A program can be run two ways:

- `lepthornc run file.lep` compiles it to a native program and runs
  it. `lepthornc compile file.lep` only compiles it.
- `lepthornc eval file.lep` runs it in the interpreter, without making
  a program.

Both ways give the same output and the same exit status. The test
runner checks this.

### Source text

- One statement per line. A line break ends a statement. There are no
  semicolons.
- Inside `( )` and `[ ]` a line break does not end the statement.
- Comments are `(* ... *)` and can nest.
- `//` is not a comment. The lexer prints `LEC1002`, skips the rest of
  the line and goes on.
- Indentation does not matter to the compiler. Blocks end with
  `done()`. The examples indent by four spaces.

### use

```lepthorn
use "helpers.lep"
use physics::drag
```

`use "path"` includes a file, relative to the file that has the `use`.
`use a::b` includes `src/a/b/module.lep`, or `src/a/b.lep`, from the
project root (the current directory for a single file). Each file is
included once, even if several files use it. Functions can be used
before or after the place where they are written.

## 2. Values

Every value has one of these kinds:

| Kind | Example | How it shows |
|---|---|---|
| Number | `42`, `2.5`, `25kg`, `10ms` | `42`, `25 kg` |
| Text | `"drone"` | `drone` |
| Boolean | `true`, `false` | `true` |
| Array | `[1, 2, 3]` | `[1, 2, 3]` |
| shape value | `Point(x = 1m, y = 2m)` | `Point(x = 1 m, y = 2 m)` |
| RingBuffer, Queue, Stack | `ring::create(8)` | `RingBuffer[2/8]` (count/capacity) |
| file handle | `file::open("log.txt", "w")` | `Handle(w, open)` |
| Vector | `vector(1m, 2m, 3m)` | `(1 m, 2 m, 3 m)` |
| Matrix | `matrix::rotationZ(90degree)` | `[[a, b, c], [d, e, f], [g, h, i]]` |

`sys::kind(v)` gives the kind as text: `Number`, `Text`, `Boolean`,
`Array`, the shape's name, `RingBuffer`, `Queue`, `Stack`, `Handle`,
`Vector` or `Matrix`.

Numbers are 64-bit floating point. A number can have a unit. The unit
is kept through every calculation (section 4).

Arrays, shape values and collections are shared, not copied. If two
names hold the same array, or a function gets an array as an argument,
a change through one name is seen through the other.

There is no `null`. Every variable gets a value when it is declared.

## 3. Variables

### ensure and suppose

```lepthorn
ensure gravity = 9.80665mps / 1s    (* cannot change *)
suppose speed = 0mps                (* can change *)
speed = 12mps
speed += 3mps
```

- `ensure name = value` makes a variable that cannot be given a new
  value.
- `suppose name = value` makes a variable that can.
- `name = value` gives an existing `suppose` variable a new value. It
  never makes a new variable.
- `name op= value` is short for `name = name op value`. The operators
  are `+= -= *= /= %= **= &= |= ^= <<= >>=`.
- `ensure` only stops the name from getting a new value. The items of
  an `ensure` array and the fields of an `ensure` shape can still be
  changed: with `ensure p = Point(...)`, `p.x = 1m` is allowed.

These mistakes stop the program before it runs (`LEC3001`):

- using a name that was never declared,
- assigning to a name that was never declared,
- assigning to an `ensure` variable.

### Block declarations

```lepthorn
ensure!
    name = "scout"
    max_speed = 12mps
done()

suppose!
    x = 1
    y = 30
    x = x + y      (* x is already declared here, so this is an assignment *)
done()
```

`ensure!` declares every line as an `ensure` variable. `suppose!`
declares a name the first time it appears. A later line with the same
name is an assignment.

### Scope

- Top-level variables belong to the top-level code.
- A function sees only its own parameters and its own variables. It
  does not see the caller's variables or the top-level variables.
- A variable declared inside a `when` or a loop stays visible until the
  end of the function (or of the top-level code).
- `shared` variables are the exception. They are visible everywhere,
  including inside every function.

### shared

```lepthorn
shared ensure gain = 1.5
shared suppose counter = 0

make bump()
    atomic
        counter = counter + 1
    done()
done()
```

`shared ensure` and `shared suppose` work like `ensure` and `suppose`,
but every function can use the variable. `shared ensure!` and
`shared suppose!` blocks also work.

Inside a `parallel` block, a `shared suppose` variable may only be
changed inside `atomic`. Otherwise the verifier stops the program
(`LEC3001`).

## 4. Numbers and units

A number can end with a unit: `25kg`, `2.8kN`, `10ms`, `90degree`. There
is no space between the number and the unit. The unit table:

| Unit | Means |
|---|---|
| `kg`, `g`, `t` | kilogram, gram, tonne |
| `m`, `km`, `cm`, `mm` | metre, kilometre, centimetre, millimetre |
| `s`, `ms`, `min`, `h` | second, millisecond, minute, hour |
| `N`, `kN`, `MN` | newton, kilonewton, meganewton |
| `mps` | metre per second |
| `Hz`, `kHz` | hertz, kilohertz |
| `rad`, `degree`, `deg` | radian, degree |

Every number is stored in SI base units. `2.8kN` is stored as 2800 N,
`90degree` as 1.5708 rad, `5000g` as 5 kg. So `5000g == 5kg` is `true`.

Units combine when you multiply and divide:

```lepthorn
ensure distance = 100m
ensure time = 20s
show distance / time           (* 5 m/s *)
show 40kg * 9.80665m / 1s / 1s (* 392.266 kg·m/s² (N) *)
```

Rules:

- `+`, `-` and `%` need both sides to have the same unit.
- `*` and `/` accept any units and combine them.
- `**` needs an exponent with no unit. A number with a unit may only be
  raised to a whole number: `(2m) ** 2` is `4 m²`.
- Comparisons need both sides to have the same unit.

**Unit mistakes are found while the program runs, not before.** When
`+`, `-` or `%` get different units, the program prints `LEC8025`, uses
0 as the result, and keeps going:

```lepthorn
ensure a = 5kg
ensure b = 3m
suppose c = a + b
show "c:" c
```

```text
LEC8025: runtime error: dimension mismatch in +
c: 0
```

An exponent with a unit (`2 ** 1m`) gives `LEC8027` and works the same
way. Checking units before the program runs is not done yet.

How units are printed is described in [DATATYPES.md](DATATYPES.md).

## 5. Operators

From lowest to highest precedence:

| Level | Operators | Operands |
|---|---|---|
| 1 | `or` | Boolean |
| 2 | `and` | Boolean |
| 3 | `not` | Boolean |
| 4 | `& \| ^ << >>` | whole numbers with no unit |
| 5 | `== != < > <= >=` | see below |
| 6 | `+ -` | numbers (same unit), or two Texts for `+` |
| 7 | `* / %` | numbers |
| 8 | `**` | numbers |
| 9 | `~` (bitwise not) | whole number with no unit |

- `+` on two Texts joins them: `"a" + "b"` is `"ab"`.
- `==` and `!=` work on two numbers with the same unit, two Texts, two
  Booleans, or two values of the same shape (field by field). Other
  pairs stop the program with an error.
- `< > <= >=` work on two numbers with the same unit or on two Texts
  (compared byte by byte).
- `and`, `or` and `not` need Booleans. Both sides of `and` and `or` are
  always evaluated.
- Dividing by zero (`/` or `%`) stops the program.
- The bitwise operators treat the numbers as 64-bit integers. Shifts
  use the low 6 bits of the right side.
- There is no unary minus. Write `0 - x`, or `0m - x` when `x` has a
  unit. There is no `++` or `--`.

Parentheses group: `(a + b) * c`.

## 6. Output and input

### show

```lepthorn
show "speed:" speed "at" time
```

`show` prints its arguments on one line, separated by one space, and
ends the line. Arguments are written next to each other, with no
commas.

### take and read

```lepthorn
take mass       (* prints "take mass: " and reads a number *)
read pilot      (* prints "read pilot: " and reads a line of text *)
```

`take` reads one line and turns it into a number, with an optional
unit (`40kg`). If the line is not a number, the program stops.
`read` reads one line as Text. Both declare the variable (as `suppose`)
if it does not exist yet. At the end of input the program stops with
`end of input`.

## 7. Decisions

### when

```lepthorn
when battery > 80
    show "full"
otherwise when battery > 20
    show "ok"
otherwise
    show "low"
done()
```

The condition must be a Boolean. There can be any number of
`otherwise when` parts and at most one `otherwise`.

### choose

```lepthorn
choose mode
case "AUTO"
    show "autonomous"
case "MANUAL"
    show "manual"
otherwise
    show "unknown mode"
done()
```

The value after `choose` must be Text. Each `case` label must be quoted
text. The first matching case runs. `otherwise` runs when no case
matches. There is no fall-through.

## 8. Loops

```lepthorn
repeat                  (* forever, until stop *)
    ...
done()

repeat 3                (* 3 times *)
    ...
done()

repeat                  (* at least once, until the condition is true *)
    ...
until x == 4
done()
```

- `repeat N` needs a number with no unit. A fraction is cut down:
  `repeat 2.5` runs twice.
- `stop` leaves the innermost loop.
- `next` skips to the next round of the innermost loop.
- `stop` or `next` outside a loop is an error when compiling
  (`LEC7001`). `eval` ignores it; that difference is a known bug.

### every and loop_hz

```lepthorn
every 10ms
    ticks += 1
    when ticks >= 4
        stop
    done()
done()

loop_hz(50)
    ...
done()
```

`every` runs its body again and again, once per period. The period is
a time (`10ms`) or a frequency (`100Hz`). `loop_hz(n)` is the same with
a frequency given as a plain number. The start times stay on a fixed
grid: if the body takes longer one time, the next start is not moved
later. Use `stop` to leave these loops.

## 9. Functions

```lepthorn
make factorial(n)
    when n <= 1
        done(1)
    done()
    done(n * factorial(n - 1))
done()

show "factorial(5):" factorial(5)
```

- `make name(params)` declares a function. It must be at the top level.
- `done(value)` returns a value. It leaves the function from inside any
  number of `when` blocks and loops.
- A function that ends without `done(value)` returns nothing. Calling
  it as a statement is fine. Using its result as a value stops the
  program with an error.
- A call must pass exactly as many arguments as the function has
  parameters (`LEC3001`).
- Functions can call themselves and each other. The call depth is
  limited to 10000; going deeper stops the program.
- There are no nested functions, no lambdas and no overloading.

## 10. Shapes

A shape is a record with named fields.

```lepthorn
shape Point
    x: Number
    y: Number
done()

suppose p = Point(x = 1m, y = 2m)
p.x = 5m
show p          (* Point(x = 5 m, y = 2 m) *)
show p.x        (* 5 m *)
```

- Shapes are declared at the top level. The type after each field name
  is not checked; any value can go in any field.
- Every field must be given when the shape is built, and no other
  field names are allowed.
- A field can hold any value, including another shape or an array.
- Two shape values are equal when they are the same shape and every
  field is equal.
- Only `name.field` works. `a.b.c` does not; read `a.b` into a name
  first.
- There are no methods. Use functions that take the shape as an
  argument.

## 11. Arrays

```lepthorn
suppose scores = [70, 85, 90]
scores[1] = 88
show scores[1] length(scores)   (* 88 3 *)
```

- Indexes start at 0 and must be whole numbers.
- An index outside the array stops the program (`LEC8013`).
- The size is fixed. There is no push or append. Use a Queue, Stack or
  RingBuffer when the number of items changes.
- An array can hold values of different kinds, including other arrays.
- `a[i][j]` does not work. Read `a[i]` into a name first.

## 12. Collections

The collections are used through functions, not methods. Each one has
a fixed capacity, set when it is created.

| Function | Result |
|---|---|
| `ring::create(n)` | a RingBuffer that holds up to `n` items |
| `ring::write(r, v)` | adds `v`; when full, drops the oldest item first |
| `ring::get(r)` | removes and returns the oldest item |
| `ring::peek(r, i)` | the item at position `i`, 0 = oldest, without removing it |
| `ring::size(r)`, `ring::is_empty(r)`, `ring::is_full(r)` | count, Booleans |
| `ring::clear(r)` | removes every item |
| `queue::create(n)` | a Queue (first in, first out) |
| `queue::enqueue(q, v)`, `queue::dequeue(q)`, `queue::front(q)` | add, remove, look |
| `queue::size`, `queue::is_empty`, `queue::is_full` | count, Booleans |
| `stack::create(n)` | a Stack (last in, first out) |
| `stack::push(s, v)`, `stack::pop(s)`, `stack::peek(s)` | add, remove, look |
| `stack::size`, `stack::is_empty`, `stack::is_full` | count, Booleans |

Adding to a full Queue or Stack stops the program (`LEC8014`). Taking
from an empty one stops the program (`LEC8015`). A RingBuffer never
fails on write.

Lepthorn has no map, set or growable list in the language. Build one in
Lepthorn code when you need it.

## 13. Built-in functions

### Text

| Function | Result |
|---|---|
| `text::length(t)` | number of bytes |
| `text::char_at(t, i)` | the byte at `i` as a one-byte Text |
| `text::slice(t, start, end)` | bytes from `start` up to, not including, `end` |
| `text::to_number(t)` | the number written in `t` |
| `text::from_number(n)` | a number written as Text |
| `text::from_code(c)` | a one-byte Text with byte value `c` (e.g. 34 is `"`, 10 is a newline) |
| `text::format(v)` | any value written the way `show` writes it |

Text is a sequence of bytes. Positions and lengths count bytes, so a
character such as `·` counts as 2.

### Files

| Function | Result |
|---|---|
| `file::open(path, mode)` | a handle; mode is `"r"`, `"w"`, `"a"`, `"r+"` or `"w+"` |
| `file::load(h, n)` | up to `n` bytes as Text |
| `file::write(h, text)` | number of bytes written, or -1 |
| `file::close(h)` | 0, or an error code |
| `file::exists(path)` | `true` if it is a file |
| `file::delete(path)` | 0, or an error code |
| `file::error()` | the error code of the last file call, 0 if it worked |

The file functions do not stop the program when they fail. Check
`file::error()`. The codes are in [errors/runtime.md](errors/runtime.md).

### System

| Function | Result |
|---|---|
| `sys::arg_count()`, `sys::arg(i)` | command-line arguments; `sys::arg(0)` is the program |
| `sys::getenv(name)` | an environment variable, or `""` |
| `sys::setenv(name, value)` | sets one; `true` if it worked |
| `sys::run(command)` | runs a shell command, returns its exit status |
| `sys::capture(command)` | runs a shell command, returns what it printed |
| `sys::exit(code)` | ends the program with that exit status |
| `sys::fail(reason)` | ends the program with `LEC8028: reason`, status 1 |
| `sys::cwd()`, `sys::chdir(path)` | current directory; change it (`true` if it worked) |
| `sys::is_dir(path)`, `sys::mkdir(path)` | Booleans |
| `sys::file_size(path)` | size in bytes, or -1 |
| `sys::realpath(path)` | the full path; the input unchanged if the path does not exist |
| `sys::list_dir(path)` | a RingBuffer of the names in a directory, sorted |
| `sys::now()` | seconds on a clock that only goes forward; use it to measure time, not as a date |
| `sys::kind(v)` | the kind of a value, as Text |

Under `lepthornc eval`, `sys::arg` sees the arguments of `lepthornc`
itself.

### Physics and maths

| Function | Result |
|---|---|
| `force::gravity(mass)` | mass × 9.80665 m/s² |
| `force::acceleration(force, mass)` | force ÷ mass |
| `motion::velocity(distance, time)` | distance ÷ time |
| `vector(x, y, z)` | a 3-part vector |
| `matrix::rotationZ(angle)` | a 3×3 rotation matrix around Z |
| `length(array)` | number of items |

The physics functions check the units of their arguments and stop the
program if they are wrong. Vectors and matrices can be built and shown,
but there is no arithmetic on them yet.

## 14. Timing and tasks

These statements are part of the language. In this version everything
runs on one thread.

| Statement | What it does |
|---|---|
| `wait 20ms` | sleeps for that time |
| `wait condition` | checks the Boolean again and again until it is `true` |
| `deadline 5ms ... done()` | runs the body; if it took longer, prints a warning (`LEC8016`) |
| `timeout 100ms ... done()` | runs the body; a `wait` inside gives up after that time with a warning (`LEC8017`) |
| `parallel ... done()` | runs each task in it, one after another, highest priority first (a task without `priority` counts as 0) |
| `priority n ... done()` | a task with a priority, inside `parallel` |
| `atomic ... done()` | runs the body; required around changes to `shared suppose` values inside `parallel` |
| `sync` | does nothing (nothing runs in the background) |
| `watch value ... done()` | runs the body once |
| `interrupt(name) ... done()` | runs the body once |

The warnings look like this and do not stop the program:

```text
lepthorn: warning: LEC8016 Deadline Missed - took 0.005s, budget 0.001s
```

Real threads, and running `watch`/`interrupt` bodies on real events,
are not done yet.

## 15. Errors

| Code | When | What happens |
|---|---|---|
| `LEC1001`, `LEC1002` | reading the source | message; see [errors/lexer.md](errors/lexer.md) |
| `LEC2001` | parsing | the program does not run |
| `LEC3001` | checking, before running | the program does not run |
| `LEC7xxx` | making native code | no program is written |
| runtime errors | while running | `lepthorn: runtime error: ...` on stderr, exit status 1 |

Error codes are listed in [docs/errors](errors/).

## 16. Not in the language yet

- checking units before the program runs
- typed declarations (`ensure mass : Mass = 10kg`)
- unary minus, escape sequences in text
- real threads; `watch` and `interrupt` on real events
- arithmetic on vectors and matrices, trigonometry
- fixed-width integer types, pointers, hardware registers
- freeing memory: memory is never freed while a program runs
- targets other than x86-64 Linux

The planned type system is described in
[DATATYPES_SPEC.md](DATATYPES_SPEC.md).
