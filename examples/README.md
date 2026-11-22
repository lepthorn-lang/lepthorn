# Examples

Small programs, one idea each, to learn Lepthorn step by step. Read
them in order. Every file runs:

```sh
lepthornc eval examples/01_hello_text.lep     # run in the interpreter
lepthornc run examples/01_hello_text.lep      # compile, then run
```

`lepthornc test` runs all of them (they are listed in `manifest.lepm`)
and checks that the interpreter and the compiled program give the same
output. Three examples read input; their `.in` file holds the input
the test gives them.

## Basics

| File | What it shows |
|---|---|
| [01_hello_text](01_hello_text.lep) | the smallest program, `show` |
| [02_ensure_suppose](02_ensure_suppose.lep) | `ensure` (fixed) and `suppose` (can change) |
| [03_ensure_block](03_ensure_block.lep) | `ensure!` block: several fixed values at once |
| [04_suppose_block](04_suppose_block.lep) | `suppose!` block |
| [18_comments_and_lines](18_comments_and_lines.lep) | comments, nested comments, long lines over several lines |

## Numbers and units

| File | What it shows |
|---|---|
| [05_si_units](05_si_units.lep) | numbers with SI units |
| [06_dimension_composition](06_dimension_composition.lep) | `*` and `/` build new units |
| [19_units_and_conversion](19_units_and_conversion.lep) | every unit in the table, and how units convert |
| [20_unit_checking](20_unit_checking.lep) | how unit mistakes are found before and while running |
| [22_physics_engines](22_physics_engines.lep) | `force::`, `motion::`, `vector`, `matrix::` |

## Operators

| File | What it shows |
|---|---|
| [07_arithmetic_basic](07_arithmetic_basic.lep) | `+ - * /` |
| [08_mod_and_pow](08_mod_and_pow.lep) | `%` and `**` |
| [09_compound_assignment](09_compound_assignment.lep) | `+= -= *= /= %= **=` |
| [10_bitwise_ops](10_bitwise_ops.lep) | `& \| ^ ~ << >>` |
| [11_bitwise_compound](11_bitwise_compound.lep) | `&= \|= ^= <<= >>=` |
| [12_comparisons](12_comparisons.lep) | `== != < <= > >=` |
| [13_logical_ops](13_logical_ops.lep) | `and or not` |
| [14_text_concat](14_text_concat.lep) | `+` joins Text |
| [15_boolean_from_comparison](15_boolean_from_comparison.lep) | `true`, `false`, and Booleans from comparisons |

## Input

| File | What it shows |
|---|---|
| [16_take_input](16_take_input.lep) | `take`: read a number with a unit |
| [17_read_input](17_read_input.lep) | `read`: read a line of Text |

## Decisions and loops

| File | What it shows |
|---|---|
| [23_when_otherwise](23_when_otherwise.lep) | `when` and `otherwise` |
| [24_when_elseif_chain](24_when_elseif_chain.lep) | `otherwise when` chains |
| [29_choose_case](29_choose_case.lep) | `choose` and `case` |
| [41_choose_kinds](41_choose_kinds.lep) | `choose` on numbers with units, Text, and true/false |
| [25_repeat_counted](25_repeat_counted.lep) | `repeat 5` |
| [26_repeat_forever_stop](26_repeat_forever_stop.lep) | `repeat` and `stop` |
| [27_repeat_until](27_repeat_until.lep) | `repeat ... until` |
| [28_next_skip](28_next_skip.lep) | `next` |

## Functions, shapes and arrays

| File | What it shows |
|---|---|
| [31_functions_basic](31_functions_basic.lep) | `make` and `done(value)` |
| [32_functions_recursion](32_functions_recursion.lep) | recursion |
| [21_shapes](21_shapes.lep) | `shape`: records with named fields |
| [33_arrays_basic](33_arrays_basic.lep) | arrays, `length()` |
| [34_arrays_units_and_functions](34_arrays_units_and_functions.lep) | arrays with units, passed to functions |
| [43_use_files](43_use_files.lep) | `use`: functions in another file ([lib/robot_math.lep](lib/robot_math.lep)) |

## Collections, text, files and the system

| File | What it shows |
|---|---|
| [35_queue_stack_ringbuffer](35_queue_stack_ringbuffer.lep) | `queue::`, `stack::`, `ring::` |
| [39_text_primitives](39_text_primitives.lep) | `text::` functions |
| [36_file_io](36_file_io.lep) | `file::` functions |
| [42_system_functions](42_system_functions.lep) | `sys::` functions, measuring time |

## Time and tasks

| File | What it shows |
|---|---|
| [30_every_realtime](30_every_realtime.lep) | `every 10ms` |
| [38_concurrency_realtime](38_concurrency_realtime.lep) | `loop_hz`, `deadline`, `timeout`, `wait`, `watch`, `interrupt` |
| [37_concurrency_basic](37_concurrency_basic.lep) | `parallel`, `priority`, `shared`, `atomic` |
| [40_shared_variables](40_shared_variables.lep) | `shared` with `ensure!` / `suppose!` |
| [44_sync](44_sync.lep) | `sync`, and how `parallel` tasks end |

## Small tours

| File | What it shows |
|---|---|
| [basic](basic.lep) | units, shapes, functions, collections together |
| [arithmetic_and_blocks](arithmetic_and_blocks.lep) | blocks and arithmetic |
| [booleans_and_io](booleans_and_io.lep) | Booleans, Text and `read` |
| [control_flow](control_flow.lep) | all decisions and loops |
| [gravity](gravity.lep) | a two-line program |
