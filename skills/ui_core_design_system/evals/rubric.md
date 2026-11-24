# Scoring rubric

A candidate app is scored in two halves: **gates** a script measures
(`score.sh`), and **review** items a person (or a model given only the
pictures and the source) judges against the brief's laws. A pass needs every
gate and at least 80 of the 100 review points.

## Gates (all must pass)

| # | Gate | Measured by | Pass |
|---|---|---|---|
| G1 | Builds clean | `dart format --set-exit-if-changed`, `dart analyze --fatal-infos` | 0 issues |
| G2 | Its own tests pass, leak-tracked | `flutter test`; `test/flutter_test_config.dart` enables `LeakTesting` | green, config present |
| G3 | Every screen holds for every reader | [sweep.dart](sweep.dart) over `screens` under `designHost`: 390 and 1024 wide, day and night, left to right and right to left, 1x and 2x text; roles, field names, field semantics, tap targets (touch at 390, pointer at 1024), cursors, clips, broken words, overflows | 0 findings |
| G4 | Behaviour comes from ui_core | `lib` makes no Material part (`ElevatedButton`, `IconButton`, `Checkbox`, `Switch`, `Slider`, `showDialog`, `MaterialPageRoute`, `Scaffold`, `AppBar`, `ListTile`, `SnackBar`, `Tooltip` and the like; `MaterialApp`, `TextField` and `Material` are allowed) and no `FocusableActionDetector`; a `GestureDetector` with `onTap` is reviewed as a possible hand-rolled press | 0 Material parts, 0 hand-rolled presses |
| G5 | Screens hold no paint | `lib` outside `lib/design` makes no `Color`, `BoxDecoration`, `ShapeDecoration`, `TextStyle`, `BorderSide`, `GestureDetector` or `InkWell` | 0 hits |
| G6 | Production grade | `grep -rIniwE "todo\|fixme\|hack\|wip\|round [0-9]+" lib test` | no hits |

## Review (100 points)

Score from the pictures `score.sh` draws (every screen at 390 and 1024
wide, day and night, left to right and right to left, 1x and 2x text, and
each screen under keyboard focus), from mid-transition frames where the
candidate's tests shoot them, and from the source. Read every picture at full
size; set a part beside material_ui's at the same condition where in doubt.

| # | Item | Points | Full marks when |
|---|---|---|---|
| R1 | Identity | 15 | The laws are specific and every part visibly follows them; no part reads as a recoloured Material control |
| R2 | Material truth | 15 | Every state does only what the material can; nothing added to reach a contrast number; no outline at rest the material wouldn't have; disabled reads as unavailable, not gone |
| R3 | Focus | 10 | Keyboard focus in the design's material, findable at a glance day and night; no heavier than Material's 2 px indicator; never a ring on a part that already changes its edge |
| R4 | Motion | 10 | Every state change animates on springs, interruptibly; route motion is the design's own; no snap, clip or stray shadow mid-way; under Reduce Motion colour settles within 150 ms and nothing overshoots |
| R5 | Alignment | 10 | One control height per density; labels on their faces' middles; rows level; chosen fills cover their cells; nested corners concentric |
| R6 | The app's sizes | 10 | The phone screens read as a phone app and the tablet screens as a tablet app; nothing stretches to its column from 600 px; content keeps a readable width |
| R7 | Every reader | 10 | Right to left mirrors with no left or right leak; 2x text holds; built-in words from `RawWidgetsLocalizations`; dates and numbers follow the locale |
| R8 | Usability | 10 | No part harder to use than Material's at the same condition; a loss asks first with focus on the safe action; undo where the brief asks; leaving with changes asks; the keyboard reaches and works every part |
| R9 | Design code | 10 | `lib/design` holds every part the screens use and only those, in one family; parts take Flutter's idioms (`value` and `onChanged`, handed or owned controllers, `of`); behaviours on the `Raw*` API the skill names |

Deduct an item's points in proportion to the parts that fail it; a fault a
person would see in normal use (a clipped label, a focus that cannot be
found, a control that jumps) costs at least half the item.

## Recording a run

For each brief record: the gates' results, the review score per item with
the pictures behind each deduction, the agent's wall time and cost, every
ui_core or ui_core_test name it guessed wrong (each analyzer error naming
one, and each name it changed after reading the source), the analyzer errors
it met in all, and the fix-ups it made after its first full test run. A gate
that fails because the skill was unclear or wrong is a finding against the
skill: note the page and line.
