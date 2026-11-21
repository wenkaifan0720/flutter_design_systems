# Brief 2, graphic: Riso

A loud look, where character must not cost usability.

## The brief, as given to the agent

> Build `riso_ui`, a Flutter design-system package on ui_core ^0.4.0, in the
> language of two-colour risograph printing: fluorescent pink and teal spot
> colours (and where they overprint, the colour they make), on off-white
> paper by day and on black by night; thick rounded type; shapes cut as if
> stencilled; a slight registration offset as the look's signature, used
> where it carries meaning (a pressed part's inks come into register).
> Motion is snappy, with a little overshoot where the material would bounce.
>
> It must be complete: every row of ui_core's inventory present, or absent
> with a designer's reason. Day and night themes; a compact density for
> desktop. Use the `ui_core_design_system` skill.
>
> Deliver the package at `riso_ui/` with an example app at `riso_ui/example/`
> whose `lib/inventory.dart` defines `final DesignInventory inventory` (the
> look's answers) and
> `Widget lookHost(BuildContext context, Widget child, Brightness brightness)`
> (the look's theme round `child`, as the app's `MaterialApp.builder` puts
> it). Finish when the skill's checks pass and you have read every picture.

## What a pass looks like

- Every gate in [rubric.md](rubric.md), and 80 or more review points.
- The offset and the overprint are the identity, but never behind words: text
  stays sharp, in register, at 4.5:1 over its worst ground. A grain or
  halftone texture, if any, stops where text starts.
- States are expressed in ink: focus as an ink change (a part printed in the
  other colour, or its inks coming into register), not a ring; pressed
  distinct from focus and hover.
- The overshoot is spatial only and disappears under Reduce Motion
  (critically damped), and colour changes still settle within 150 ms there.
- Derived parts (data table, date picker, command palette) look printed, not
  like Material with pink.

## Which checks score it

| What | Gate or item |
|---|---|
| Completeness, essentials | G3, G4 |
| Every reader at every size | G5 (2x text is where stencilled shapes clip) |
| Ink states, no added rings | R2, R3 |
| Overshoot and Reduce Motion | R4: its own in-motion and `disableAnimations` tests, plus mid-transition shots |
| Character without cost | R1 against R7 and R9: a part that is striking but hard to read or use loses R1's points too |
