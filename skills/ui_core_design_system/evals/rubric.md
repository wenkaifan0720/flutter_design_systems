# Scoring rubric

A candidate package is scored in two halves: **gates** a script measures
(`score.sh`), and **review** items a person (or a model given only the
pictures and the source) judges against the brief's laws. A pass needs every
gate and at least 80% of the review points.

## Gates (all must pass)

| # | Gate | Measured by | Pass |
|---|---|---|---|
| G1 | Builds clean | `dart format --set-exit-if-changed`, `dart analyze --fatal-infos` on the package and its example | 0 issues |
| G2 | Its own tests pass, leak-tracked | `flutter test --exclude-tags goldens`; `test/flutter_test_config.dart` enables `LeakTesting` | green, config present |
| G3 | Complete | `inventory.verify()` from `example/lib/inventory.dart` | no problem: every row present or absent with a reason |
| G4 | Coverage of the essentials | The rows ui_core marks M, C and S (all three references carry them) | every one present |
| G5 | Every part holds for every reader | `evals/sweep.dart` over every present entry: 390 and 1440 wide, day and night, LTR and RTL, 1x and 2x text; roles, field names, field semantics, tap targets (touch at 390, pointer at 1440), cursors, clips, broken words, overflows | 0 findings |
| G6 | Behaviour comes from ui_core | `lib` has no `FocusableActionDetector`, no `GestureDetector` with `onTap` that is the only press of a part, and every pressable uses `RawButton`, `RawRadio` or a `Raw*` behaviour | 0 hand-rolled presses |
| G7 | Its API is its own | The library re-exports ui_core with a `show` list only | no whole re-export |
| G8 | Documented | `dart doc --dry-run` | 0 warnings, 0 errors |
| G9 | Publishable | `dart pub publish --dry-run` | 0 warnings, or only the one asking for a homepage or repository the brief did not give |
| G10 | Production grade | `grep -rIniwE "todo\|fixme\|hack\|wip\|self-review\|round [0-9]+" lib test example/lib` | no hits |

## Review (100 points)

Score from the gallery shot in every state, day and night, at 390 and 1440
wide, LTR and RTL, and from mid-transition frames, read at full size beside
material_ui's matching parts at the same condition.

| # | Item | Points | Full marks when |
|---|---|---|---|
| R1 | Identity | 15 | The README's laws are specific, and every part visibly follows them; no part reads as a recoloured Material control; derived parts (date picker, toast, data table) look native to the language |
| R2 | Material truth | 15 | Every state does only what the material can; nothing added or sharpened to reach a contrast number; no outline at rest the material wouldn't have (high-contrast mode aside); disabled reads as unavailable, not gone |
| R3 | Focus | 10 | Keyboard focus in the look's material, visible (WCAG 2.4.7) and findable at a glance when set beside material_ui's same part at the same size and theme, day and night; no heavier than Material's 2 px indicator, or than the spec ring of the language the look follows; nothing added or sharpened to stand out; never a ring on a part that already changes its edge |
| R4 | Motion | 10 | Every state change animates on springs, interruptibly; route motion is the look's own; mid-transition frames show no snap, clip or stray shadow; Reduce Motion settles within 150 ms with no overshoot |
| R5 | Alignment | 10 | One control height per density; labels on their faces' middles; rows level; chosen fills cover their cells; nested corners concentric; dialog actions one height and stacking when they do not fit |
| R6 | Every size | 10 | A phone screen reads as a phone app and a desktop screen as a desktop app (rail or sidebar, menubar, context menu, shortcut labels); nothing stretches to its column from 600 px |
| R7 | Every reader | 10 | RTL mirrors with no left/right leak; 2x text holds everywhere; built-in words come from `RawWidgetsLocalizations`; dates and numbers follow the locale |
| R8 | API | 10 | Flutter's idioms (`value`/`onChanged`, owned or handed controllers, `style:`, `of`/`maybeOf`, `copyWith`/`lerp`), no positional booleans, names from the look's language |
| R9 | Adoptable | 10 | README with laws, install, setup under MaterialApp/CupertinoApp/WidgetsApp, five or more snippets, pictures, accessibility and languages, requirements; example `main.dart` under 150 lines; CHANGELOG |

Deduct the item's points in proportion to the parts that fail it; a fault a
person would see in normal use (a clipped label, a focus that cannot be
found, a control that jumps) costs at least half the item.

## Recording a run

For each brief record: the gates' results, the review score per item with
the pictures behind each deduction, the agent's wall time and tokens, and
every question the agent asked. A gate that fails because the skill was
unclear or wrong is a finding against the skill: note the page and line.
