# Parser Errors (LEC2xxx)

## LEC2001: syntax error

The parser found a token where it cannot go. The program does not run.
All syntax errors in the file are printed, not only the first.

```lepthorn
show -5
```

```text
LEC2001: unexpected token '-' (OP)
```

Common causes:

| You wrote | Why it fails | Write instead |
|---|---|---|
| `show -5` | there is no unary minus | `show 0 - 5` |
| `show "a\"b"` | there are no escape sequences | `"a" + text::from_code(34) + "b"` |
| `show a, b` | `show` arguments are not separated by commas | `show a b` |
| `a < b < c` | comparisons cannot be chained | `a < b and b < c` |
| `ensure x = 5;` | there are no semicolons | `ensure x = 5` |

The exact syntax is in [../GRAMMAR.md](../GRAMMAR.md).
