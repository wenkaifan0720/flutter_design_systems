# Brief 2: graphic, Fair

A loud design, where character must not cost usability.

## The brief, as given to the agent

> Build `fair`, a Flutter app for a two-day small-press fair's programme,
> with a design of its own on ui_core ^0.6.1, in the language of two-colour
> risograph printing: fluorescent pink and teal spot colours (and where they
> overprint, the colour they make), on off-white paper by day and on black by
> night; thick rounded type; shapes cut as if stencilled; a slight
> registration offset as the design's signature, used where it carries
> meaning (a pressed part's inks come into register). Motion is snappy, with a
> little overshoot where the material would bounce. The app runs on phones and
> on tablets held either way. Use the `ui_core_design_system` skill.
>
> Screens: **Programme**, tabs for the two days, sessions by time, a search
> field that filters them; each session row has a star to add it to the
> visitor's plan. **Session**: its title, room, time, speakers and words, a
> key to add it to the plan or take it out, and a share menu (Copy link,
> Email). **My plan**: the starred sessions in time order; taking one out
> shows an Undo toast; an empty plan says how to fill it. A setting on My plan
> turns reminders on, with a select for how long before (5, 10 or 15
> minutes).
>
> Deliver the app at `fair/`, its design in `lib/design/`. Its
> > `lib/screens.dart` defines `final Map<String, WidgetBuilder> screens` (each
> > screen by name, ready to pump with sample data) and
> > `Widget designHost(BuildContext context, Widget child, Brightness brightness)`
> > (the design's theme, and whatever the screens read, round `child`, as the
> > app's `MaterialApp.builder` puts it). Its tests run leak-tracked. Finish
> > when the skill's checks pass and you have read every picture.

## What a pass looks like

- Every gate in [rubric.md](rubric.md), and 80 or more review points.
- The offset and the overprint are the identity, but never behind words:
  text stays sharp, in register, at 4.5:1 over its worst ground.
- States are expressed in ink: focus as an ink change, not a ring; pressed
  distinct from focus and hover; the star's two states read at a glance.
- The overshoot is spatial only and disappears under Reduce Motion, and
  colour changes still settle within 150 ms there.
- The search field, the select and the menu look printed, not like Material
  with pink.

## Which checks score it

| What | Gate or item |
|---|---|
| Every screen at every size, for every reader | G3 (2x text is where stencilled shapes clip) |
| Ink states, no added rings | R2, R3 |
| Overshoot and Reduce Motion | R4 |
| Character without cost | R1 against R7 and R8: a part that is striking but hard to read or use loses R1's points too |
