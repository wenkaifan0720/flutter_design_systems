# Brief 1, plain: Grid

A quiet look, where restraint and alignment are the whole test.

## The brief, as given to the agent

> Build `grid_ui`, a Flutter design-system package on ui_core ^0.6.0, in the
> International Typographic Style: a strict 8 px grid, one sans-serif family
> (any the app loads; Inter by default), black and white with one red, flat
> surfaces with hairline rules, square corners, no shadows, no gradients.
> Hierarchy comes from size, weight and space alone. Motion is short and
> plain: colour and rule changes, no travel beyond a few pixels.
>
> It must be complete: every row of ui_core's inventory present, or absent
> with a designer's reason. Day and night themes; a compact density for
> desktop. Use the `ui_core_design_system` skill.
>
> Deliver the package at `grid_ui/` with an example app at `grid_ui/example/`
> whose `lib/inventory.dart` defines `final RawInventory inventory` (the
> look's answers) and
> `Widget lookHost(BuildContext context, Widget child, Brightness brightness)`
> (the look's theme round `child`, as the app's `MaterialApp.builder` puts
> it). Finish when the skill's checks pass and you have read every picture.

## What a pass looks like

- Every gate in [rubric.md](rubric.md), and 80 or more review points.
- Focus is a thicker black (by night white) rule on the part's own edge, or
  the red, never a ring outside a part that already has a rule; R3 is where
  this brief is most often lost.
- One control height (a multiple of 8) across button, field, select,
  segmented control and stepper; labels' capitals on the grid's centre line.
  R5 is scored strictly: a grid look that misaligns has no identity.
- Nothing stretches to its column from 600 px; tables keep a usable form at
  390 px.
- No decoration added to look "designed": no hover wash, no rounded corners
  on some parts and not others.

## Which checks score it

| What | Gate or item |
|---|---|
| Completeness, essentials | G3, G4 |
| Roles, targets, cursors, clips, overflow at every condition | G5 |
| Labels on their middles, rows level, widths | `DesignLabelCheck` in its tests; R5 (with ui_core_review's `DesignRowCheck`, `DesignWidthCheck`, `DesignKeylineCheck` if available) |
| Focus idiom and weight | R3 from Tab-focus shots of button, row, chip, toggle, slider, menu row, field, card |
| Restraint | R1, R2 |
