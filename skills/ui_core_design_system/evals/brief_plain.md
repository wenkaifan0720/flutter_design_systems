# Brief 1: plain, Tally

A quiet design, where restraint and alignment are the whole test.

## The brief, as given to the agent

> Build `tally`, a Flutter app for logging a household's shared expenses,
> with a design of its own on ui_core ^0.6.0, in the International
> Typographic Style: a strict 8 px grid, one sans-serif family (Roboto, which
> Flutter ships), black and white with one red, flat surfaces with hairline
> rules, square corners, no shadows, no gradients. Hierarchy comes from size,
> weight and space alone. Motion is short and plain: colour and rule changes,
> no travel beyond a few pixels. Day and night; the app runs on phones and on
> tablets held either way. Use the `ui_core_design_system` skill.
>
> Screens: **Expenses**, the month's entries grouped by day with each day's
> total, tabs for this month and last, a key to add one; each row opens its
> expense and has a menu with Duplicate and Delete (Delete asks first, and an
> Undo toast follows). **Expense**, a form: the amount (required), what it was
> for, a category, who paid (one of the household's two people), the date, a
> switch to split it evenly, a note; leaving with changes asks whether to keep
> editing, discard or save. **Settings**: the currency, the appearance (day,
> night or the system's), and the two people's names.
>
> Deliver the app at `tally/`, its design in `lib/design/`. Its
> > `lib/screens.dart` defines `final Map<String, WidgetBuilder> screens` (each
> > screen by name, ready to pump with sample data) and
> > `Widget designHost(BuildContext context, Widget child, Brightness brightness)`
> > (the design's theme, and whatever the screens read, round `child`, as the
> > app's `MaterialApp.builder` puts it). Its tests run leak-tracked. Finish
> > when the skill's checks pass and you have read every picture.

## What a pass looks like

- Every gate in [rubric.md](rubric.md), and 80 or more review points.
- Focus is a thicker black (by night white) rule on the part's own edge, or
  the red, never a ring outside a part that already has a rule.
- One control height (a multiple of 8) across the button, the fields, the
  select and the segmented control; labels' capitals on the face's middle.
  R5 is scored strictly: a grid design that misaligns has no identity.
- From 600 px nothing stretches to its column; the form keeps one width.
- No decoration added to look "designed": no hover wash, no rounded corners
  on some parts and not others.

## Which checks score it

| What | Gate or item |
|---|---|
| Roles, targets, cursors, clips, overflow on every screen | G3 |
| Labels on their middles, rows level, widths | `DesignLabelCheck` in its tests; R5 |
| Focus idiom and weight | R3, from the focus pictures |
| The delete and discard flows | R8 |
| Restraint | R1, R2 |
