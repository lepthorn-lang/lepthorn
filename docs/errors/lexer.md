# Lexer Messages (LEC1xxx)

The lexer turns the source text into tokens. It has two messages. Both
are printed on standard output. `LEC1001` stops the program;
`LEC1002` does not. Like every error found before the program runs,
each message starts with the file and line, and the line itself is
printed below it.

## LEC1001: unterminated comment

A `(*` comment was opened and never closed. Comments nest, so every
`(*` needs its own `*)`.

```lepthorn
(* outer
   (* inner *)
ensure x = 10
```

```text
main.lep:1: LEC1001: unterminated comment
    (* outer
```

The line is where the comment that is never closed starts.

This is an error: the program does not run, and `eval`, `check`,
`compile` and `run` exit with status 1.

**Fix:** add the missing `*)`.

## LEC1002: `//` comments are not supported

Lepthorn has one kind of comment, `(* ... *)`. A `//` prints this
message. The rest of that line is skipped and the program still runs.
Every `//` in the file is reported, not only the first.

```lepthorn
// this is not a comment
ensure x = 10
```

```text
main.lep:1: LEC1002: '//' line comments are not supported - use (* ... *) instead
    // this is not a comment
```

**Fix:** write the comment as `(* ... *)`.
