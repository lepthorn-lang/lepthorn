# How Features Are Added

Every change to Lepthorn, small or large, goes through three steps, in
this order: plan, think through the effects, then build and check. The
first two are written down before any code is written.

## 1. Plan

- Say in one sentence what the feature does and who needs it.
- Write the exact syntax, in the style of [GRAMMAR.md](GRAMMAR.md).
- Write what it means: how it runs, what errors it can give, and how it
  works with units and the other kinds of values.
- Write what it does not do. Anything left for later is named, not
  quietly dropped.

## 2. Think through the effects

Before writing code, check how the feature affects the rest of the
language:

- **Grammar:** does it make any existing code mean something else, or
  make the parser unsure which rule to use? Does it change precedence?
- **Values and units:** does it add a new kind of value, or a new way
  for values or units to not match?
- **Where it belongs:** in the core language, or in a library?
- **Small targets:** could it work later on a microcontroller with no
  operating system and no heap? If not, say so now.
- **Existing code:** does it change what any example, test or document
  says? If so, update them in the same change.
- **Tests:** which tests are added, including at least one that shows
  the new error really happens.

## 3. Build and check

- Build the whole feature. No placeholders and no silent "not done
  yet" paths: if a part is left out, it gives a clear error and is
  written down.
- Run it. Build the compiler, run the examples and the tests
  (`lepthornc test`), and run at least one program that should fail.
  Record what really happened, not what was expected.
- When the compiler itself changes, rebuild it with itself and check
  that the rebuild is identical (`just verify`).
- Only after it works, make it faster or cleaner.
- Update the documents that describe it in the same change.

## Why this order

When code is written first and the design is explained afterwards,
features tend to work for the example that started them and break
somewhere else: a unit case nobody tried, a grammar rule that reads
two ways, something that can never run on a small device. Planning
first finds these problems on paper, where they are cheap to fix.
