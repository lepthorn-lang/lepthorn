# Code Generation Errors (LEC7xxx)

These come from `lepthornc compile`, `run` and `build`, when a program
passed the verifier but cannot be turned into native code. The compiler
prints `lepthornc: compilation failed`, exits with status 1, and writes
no program. Each error is one line: `LEC7nnn: codegen error: <what>`.

Most of these are also caught earlier by the verifier (`LEC3001`).

## LEC7001: unsupported construct

An unknown unit on a number, `stop` or `next` outside a loop (normally
caught first by the verifier), or an unknown operator or node (only
possible through a parser bug).

```lepthorn
ensure d = 5furlong
```

```text
LEC7001: codegen error: unknown unit suffix 'furlong'
```

**Fix:** use a unit from the table in [../DATATYPES.md](../DATATYPES.md),
or move `stop`/`next` into a loop.

## LEC7002: unknown builtin

A `name::function(...)` call that is not a built-in function.

```lepthorn
show math::sqrt(2)
```

```text
LEC7002: codegen error: unknown builtin 'math::sqrt'
```

**Fix:** check the list of built-in functions in [../SPEC.md](../SPEC.md).

## LEC7003: undefined function or wrong number of arguments

A call to a function that does not exist, or with the wrong number of
arguments.

```text
LEC7003: codegen error: add expects 2 argument(s), got 3
```

## LEC7004: wrong number of arguments to a builtin

```lepthorn
ensure r = ring::create()
```

```text
LEC7004: codegen error: ring::create expects 1 argument(s), got 0
```

## LEC7006: wrong use of a shape

Building a shape that was never declared, leaving out a field, naming a
field the shape does not have, or reading `.field` when no shape has
that field.

```lepthorn
shape Point
    x: Number
    y: Number
done()
ensure p = Point(x = 1)
```

```text
LEC7006: codegen error: shape 'Point' construction is missing field 'y'
```

## LEC7009: undeclared variable

A variable used in a function that is not a parameter, a local
variable, or a `shared` variable.

```text
LEC7009: codegen error: undefined variable 'speed'
```

## Codes no longer used

`LEC7005`, `LEC7007` and `LEC7008` described limits of an older code
generator. They are not reported any more and will not be reused.
