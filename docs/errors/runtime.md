# Runtime Errors (LEC8xxx)

These happen while the program runs. Compiled programs and
`lepthornc eval` share one runtime, so they fail the same way.

## How a runtime error looks

Most runtime errors stop the program. They print one line on standard
error, and the program exits with status 1:

```text
lepthorn: runtime error: Division by zero
```

A few do not stop the program:

| Code | Printed on | What happens |
|---|---|---|
| `LEC8025` | standard output | the result is 0 and the program goes on |
| `LEC8027` | standard output | the result is 0 and the program goes on |
| `LEC8016`, `LEC8017` | standard error | a warning; the program goes on |
| `LEC8001`-`LEC8012` | nothing | returned by `file::error()` |

## Codes

### LEC8001-LEC8012: file errors

The `file::` functions do not stop the program when they fail. They set
an error code, which `file::error()` returns. It is 0 after a call that
worked.

| Code | Meaning |
|---|---|
| `8001` | the file does not exist |
| `8002` | permission denied |
| `8003` | the file already exists |
| `8004` | the handle is not open (never opened, or closed) |
| `8005` | no space left on the device |
| `8006` | the file name is too long |
| `8007` | the open mode is not `r`, `w`, `a`, `r+` or `w+` |
| `8008` | opening or reading failed for another reason |
| `8009` | writing or closing failed for another reason |
| `8010` | the path is a directory |
| `8011` | a part of the path is not a directory |
| `8012` | too many files are open |

```lepthorn
ensure h = file::open("missing.txt", "r")
when file::error() != 0
    show "cannot open, code" file::error()
done()
```

### LEC8013: index out of bounds

```lepthorn
ensure a = [1, 2, 3]
show a[5]
```

```text
lepthorn: runtime error: LEC8013: index 5 is out of bounds for an array of length 3
```

Under `lepthornc eval` the message has an extra `LEC8028: ` before
`LEC8013`. This difference is a known bug.

### LEC8014: collection is full

`queue::enqueue` on a full Queue, or `stack::push` on a full Stack.
(`ring::write` never fails; it drops the oldest item.)

```text
lepthorn: runtime error: LEC8014: queue::enqueue: Queue is full
```

### LEC8015: collection is empty

`ring::get`, `queue::dequeue`, `queue::front`, `stack::pop` or
`stack::peek` on an empty collection.

```text
lepthorn: runtime error: LEC8015: ring::get: RingBuffer is empty
```

### LEC8016: deadline missed

The body of a `deadline` block took longer than its budget. The body
always runs to the end; this is only a warning.

```text
lepthorn: warning: LEC8016 Deadline Missed - took 0.005s, budget 0.001s
```

### LEC8017: timeout expired

A `wait` inside a `timeout` block gave up, or the block took longer than
the timeout. This is only a warning.

```text
lepthorn: warning: LEC8017 Timeout Expired
```

### LEC8025: unit mismatch

`+`, `-` or `%` got values with different units. The result is 0 and
the program goes on.

```lepthorn
show 1kg + 1m
```

```text
LEC8025: runtime error: dimension mismatch in +
0
```

### LEC8026: unknown unit

A number literal with a unit that is not in the unit table. The
compiler reports this before running (`LEC7001`); `lepthornc eval`
stops with this (the extra `LEC8028: ` is a known bug):

```text
lepthorn: runtime error: LEC8028: LEC8026: unknown unit suffix 'furlong'
```

When `take` reads an unknown unit, the program stops with
`unknown unit suffix 'furlong'`.

### LEC8027: exponent with a unit

The right side of `**` has a unit. The result is 0 and the program goes
on.

```text
LEC8027: runtime error: exponent must be dimensionless
```

### LEC8028: sys::fail

`sys::fail(reason)` stops the program on purpose.

```lepthorn
sys::fail("sensor not found")
```

```text
lepthorn: runtime error: LEC8028: sensor not found
```

## Errors without a code

These also stop the program, with exit status 1:

| Message | Cause |
|---|---|
| `Division by zero`, `Modulo by zero` | `/` or `%` by 0 |
| `` `+` requires both operands to be quantities ... `` | an operator got the wrong kind of value, e.g. a number and a Boolean |
| `` `==` requires both operands to be the same kind of value ... `` | comparing values of different kinds |
| `` `and` requires both operands to be Boolean `` | also `or` and `not` |
| `` `when` condition must be Boolean ... `` | also `until` and `wait` |
| `` `&` requires dimensionless whole-number operands `` | a bitwise operator got a unit or a fraction |
| `` `**`: a dimensioned base requires a whole-number exponent ... `` | e.g. `(2m) ** 0.5` |
| `` `choose` subject must be Text `` | |
| `... must be a dimensionless Number ...` | an index, count or capacity with a unit |
| `ring::peek: index ... is out of bounds ...` | |
| `... capacity must be a positive whole Number ...` | `ring::create(0)` and similar |
| `f: maximum recursion depth (10000) exceeded` | a function called itself too deeply |
| `f: this function never reaches done(value) ...` | using the result of a function that returns nothing |
| `` `every` requires a time (e.g. 10ms) or frequency (e.g. 100Hz) quantity `` | |
| `loop_hz: frequency must be greater than zero` | |
| `force::gravity: argument must have mass dimension [kg]` | and the other physics functions |
| `` `take`: could not parse input '...' `` | `take` read something that is not a number |
| `end of input` | `take` or `read` at the end of input |
| `out of memory` | |
