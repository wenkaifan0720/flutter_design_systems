# Taste: the rules a good look keeps

A design system is a choice of taste, not of app type: whoever picks a look
must be able to build any app on it, and every screen must still be that
look. These rules turn taste into decisions you can check. Each says what to
do, why, and how to tell.

## 1. Identity comes first

**Write the look's laws, then derive every part from them.** Four to eight
lines: what a surface is made of, how that material shows action, pressure,
choice, focus, disablement and error, its type, its one control height, its
corners and its motion. A part the language never had (a date picker for a
1990s desktop, a toast for paper) is designed as the language would have
evolved to meet today's needs, from the laws.

*Why:* a look is judged by its weakest screen. Parts derived from shared laws
read as one hand; parts copied from Material with new colours read as
Material.

*Check:* for any part, you can name the law it follows. A Material control
in the look's colours is the failure: a slider's thumb, a checkbox's tick and
a dialog's frame are where taste shows.

**Name the language.** Either follow an established language faithfully
(say which, and keep its proportions, idioms and behaviour), or make one of
your own that is distinct and good. Half-faithful is neither.

**Identity over pedantry.** Every part carries the style's core concept (a
neumorphic surface is extruded from its ground, a brutalist one is a hard
block with a hard shadow). Beyond that, prefer the plainer answer.

## 2. Material is the bar, not the target

**Judge against material_ui and cupertino_ui at the same condition.** Put
the same part from Material and from the look side by side at the same width,
text size, direction and state. The look need not do better than Material;
it must not do worse.

*Why:* teams adopt a look only if it is at least as dependable as what they
leave. A case where Material also breaks (a 3x text size in a fixed-height
app bar) is not the look's fault; a case where only the look breaks is.

*Check:* where Material caps text growth (app bars, tabs, chips), cap it the
same; elsewhere the look grows like Material.

## 3. States keep the material

**A state only does what the material physically can.** Glass clears or
frosts; it does not grow a blue edge. An inset well stays inset when focused.
Paper takes ink, not light. Lower visibility than Material is acceptable when
the material says so; nothing is added or sharpened to reach a contrast
number: no ring, no paint the material cannot have, no shadow made crisper
or heavier than the material's own.

**No outline at rest the material would not have.** A part keeps no outline
at rest that its material wouldn't have, such as a printed edge on a moulded
checkbox; high-contrast mode is the exception.

**Every state is distinct.** Rest, hover, focus, pressed, disabled, selected,
error and busy each differ from rest. Pressed differs from hover and from
focus. Disabled reads as unavailable without becoming invisible.

*Check:* crop each state of eleven parts (button, row, chip, toggle, slider,
menu row, field, card, tab, checkbox, switch), day and night, at 1440 wide,
and name the material behaviour each one shows.

## 4. Focus speaks the look's language

**Show keyboard focus in the look's material, not with an extra outline.**
A rule that darkens and thickens, a shadow that deepens, a surface that
rises, a lamp that lights, ink and ground that swap. A ring stays only where
the ring *is* the language (Material's focus ring, Fluent's double stroke, a
classic desktop's dotted rectangle).

**Focus is quiet.** It reads clearly at no more weight than Material's own
indicator (a 2 px outline on fields). A look that follows a language whose
spec ring is heavier keeps that ring: Material 3 Expressive's 3 dp ring with
a 2 dp offset. Never stack a halo on a ring, or a ring on a part that already
changes its edge for focus (a field's rule or underline).

**Focus is visible and findable.** Keyboard focus must be visible (WCAG
2.4.7) and findable at a glance in the look's material. Judge it side by side
with the same part in material_ui at the same size and theme, day and night,
at 1x and 2x text. Lower visibility than Material is fine where the material
is quieter; nothing is added or sharpened to reach a contrast number. Do not
rely on hue alone; never cover the part's words.

**Keyboard focus is stronger than hover; pressed is distinct from both.**
Focus animates in and out like every other state. A focused text field is
findable at a glance with the caret off; a release never makes focus weaker
than the one before.

```dart
// Keyboard focus is the look's own rule, darker and twice as heavy: no
// ring is added round the part.
rule: states.contains(WidgetState.focused)
    ? c.ink
    : look.edge ?? (filled ? tone : c.rule),
ruleWidth: states.contains(WidgetState.focused) ? 2 : 1,
```

## 5. Hover and press

**No hover wash by default.** Outside Material-like looks, a pointer over a
part shows the click cursor and, at most, a quiet change the material allows.
Keep the overlay slot in the part's style so an app can add one.

**A press shows at once for a mouse** and after `kPressTimeout` for a touch
that might start a scroll; do not add delays of your own. Highlights leave
with the pointer.

## 6. Motion

**Every state change animates continuously:** a press sinks, a check draws,
a thumb travels, a colour turns. One mechanism per look (a face that springs,
for example), on the look's own tokens, calm and interruptible: a press
released half-way turns back from where it stands, with no jump.

**Each look owns its route motion**: its page push and pop, its dialog's
arrival, its sheet's rise. The iOS edge swipe still pops a page.

**Reduce Motion:** nothing overshoots, bounces or travels far; effects settle
within 150 ms. Follow `DesignMotionPolicy` (spatial springs critically
damped, effects a short fade); swap a long travel (a page sliding across) for
a fade.

**Judge in motion, not only at rest.** Faults hide between states: a
carousel's corners mid-swipe, a range picker's preview past the hovered day,
a sheet's shadow while it rises, a selection sliding between tabs. Look at
frames mid-way, not only the settled ends.

## 7. Alignment and size

**One control height per size and density.** A button, a field, a select, a
segmented control and a stepper that can share a row stand at the same
height, dialog buttons included. Pin Material's `VisualDensity` under the
look so a platform's density cannot shift parts that use Material pieces, and
check the compact (desktop) density as well as the standard one.

**Content is centred by construction.** `DesignControlBox` for the box,
`DesignCapCenter` with the family's factor for one-line labels, even leading
for every label. Glyphs sit on the middle of the capitals beside them. Rows
centre their children; never bottom-align a row of controls.

**From 600 px wide, controls do not stretch** to their column: a button, a
stepper or a segmented control keeps its content's width; a select and a
combobox keep the width of their label and widest option, so neither jumps
as the choice changes. A text field fills what it is given, and a form sets
one width for all its fields.

**Chosen fills cover the whole cell.** A chosen day, segment, tab or row
fills its cell edge to edge; nested shapes are concentric with their
container's corners (inner radius = outer radius − inset).

**Dialog actions stack when they do not fit**, the confirming action on top,
each as wide as the dialog (ui_core stacks them; the look widens them), with
a gap on the look's grid between the words and the actions.

*Check:* measure edges at native size before judging; `DesignLabelCheck`,
`DesignRowCheck` and `DesignKeylineCheck` measure what the eye compares.

## 8. Parts of one kind read as one family

A reader learns a look from its first screen and expects the rest to keep
its word. Faults here are rarely in one part; they sit between two parts
that should match and don't. Judge these in pairs, side by side.

**A select and a combobox are one kind of field.** Both stand on the text
field's face, at its height, and end in the same sign that a list opens (a
chevron, or what the language uses for it).

*Why:* a combobox drawn as a bare text box gives no sign that it offers a
list; a select drawn as a raised key reads as a button. Two kinds of field
for one kind of choice read as two kinds of thing.

*Check:* a text field, a select and a combobox in one form, at the form's
width, differ only in their words and their end sign; a select and a
combobox offering one list, left to choose their own width, are one width,
whatever is chosen.

**An open list is its field's own.** It is drawn in the field's material,
edge and corner; it is opaque enough that the page's words never show
through it (a glass look frosts a list more than a card, never less); it
covers what lies beneath, with nothing poking out at its corners. Every
list of the look (a select's, a combobox's, a menu's) marks the chosen row
one way and the highlighted row one way, and neither in the accent kept for
the screen's main action.

*Why:* a hairline panel under a heavily ruled field reads as some other
part; two marks for one meaning read as two meanings; a highlight in the
action colour reads as a second action, or as a heading that splits the
list.

*Check:* open a select, a combobox and a menu in one form: three panels,
one material, one kind of row.

**A chosen row is filled to its end.** A selected row's fill runs under its
trailing controls (a "…" button, a chevron) to the row's edge, and they
stand on the fill in the fill's colours. Its words keep their place:
the same insets chosen or not.

*Why:* a fill that stops before a trailing button leaves a notch that reads
as a separate cell; words that jump when chosen read as a different row.

*Check:* a list whose chosen row has a trailing button, at 390 and 1440
wide, left to right and right to left.

**A disabled part looks unavailable, not just quieter.** Take away what
says "press me" in the material: a raised key loses its height, a lit face
goes out, a filled button takes the ground's colour with muted words. Keep
its words legible; add no lock glyph or strike.

*Why:* a disabled primary button that keeps its full body beside a live one
invites presses that do nothing.

*Check:* a disabled and an enabled primary button side by side: a person
can tell which one acts without reading either.

**The error state is the empty state's sibling.** The loading, empty,
error and success views of one region share a frame, a layout and the
palette: a glyph, a heading, a sentence, an action ("Try again" from
`RawWidgetsLocalizations.retryButtonLabel`). The error differs by its glyph,
its words and the look's danger tone, never by being another kind of part
or by a colour from outside the palette.

*Why:* a failed list that stands bare where the empty one stands framed
looks like a broken page, not a message.

*Check:* the empty and the error state side by side, at the same size.

**A state never outshines the act.** A chosen segment, tab or chip is a
state: it never takes the material of the screen's main action (the
brightest key, the accent fill).

*Why:* the eye goes first to the most prominent face; when that is a state,
the act gets lost.

*Check:* a form with a segmented control and its Save button: Save is the
most prominent face.

**Destructive actions take the destructive tone wherever they appear.** A
Delete in a menu (`RawMenuEntry.isDestructiveAction`), a Discard in a dialog
(`RawDialogAction.isDestructiveAction`), a destructive button. Only the tone
changes: it is reached, pressed and read as any other. In a dialog, focus
starts on the safe action, so Enter never confirms a loss.

*Why:* a Delete set exactly like Rename is pressed by mistake.

*Check:* a row's menu with Rename and Delete; a dialog asking "Discard
changes?" with Cancel, Discard and Save.

**Dialogs take a list of actions.** A general dialog takes as many actions
as Material's `AlertDialog` does (three is common: Save, Discard, Cancel),
in a row while they fit and stacked when they don't: the confirming action
on top, every action one height and as wide as the dialog.

*Why:* a dialog that takes only two makes every app build its own; a stack
of three widths reads as three unrelated buttons.

*Check:* a three-action dialog at 390 wide and at twice the text size.

**Containers don't nest in their own kind, and pad evenly.** No card in a
card, framed group in a framed panel, or well in a well of the same look:
the inner one goes flat (a divider, a section header, space). A container
pads its content the same on every side, on the look's grid; a list that
runs edge to edge inside it takes no padding at all.

*Why:* double edges and lopsided insets are the first things a designer
reads as unfinished.

*Check:* a settings card holding a list section; measure every container's
four insets.

## 9. Restraint

**Shapes that make sense, no gimmicks.** Each part's shape follows from the
laws: a radio is round in every corner family, a switch reads as a switch.
When in doubt, the plainer answer wins.

**No pattern behind words.** Texture, grain and pattern stop where text
starts. Text keeps 4.5:1 over its worst background.

**Usability first.** No effect that makes a part harder to use ships, however
characteristic. Every release is compared with the previous one, in motion
and at rest; a regression a person can see blocks the release.

## 10. Every screen and every platform

**Every width:** 390, 768, 1024 and 1440 (and 1920). A phone reads as a
phone app, a desktop as a desktop app: keep desktop parts in every look
(menubar, command palette, tree, split view, context menu, shortcut labels).

**Pickers fit the screen they open on.** On a phone a date picker's seven
columns fit inside its dialog or sheet at 390 wide, and it opens where its
whole height fits (below its field if it can, above if that fits more, else
in a sheet); on a desktop it keeps its own width beside its field and never
spans the window. A date or time picker takes a `today` and marks it.

**Platform idioms:** the iOS edge back-swipe pops a page; Android back
closes the top sheet, menu or dialog before it pops; desktop right-click and
Shift+F10 open context menus where the language has them; shortcut labels say
⌘ on Apple platforms and Ctrl elsewhere; pointer controls take compact
density.

## 11. Every reader

**Right to left:** use `EdgeInsetsDirectional`, `AlignmentDirectional`,
`PositionedDirectional` and start/end in every API; mirror directional icons,
sliders, progress and swipes.

**Text size:** every part holds at twice the text size with no overflow and
no clipped descender; fixed-height parts grow, or cap where Material caps.

**Scripts:** the look works with any reasonable font; set
`fontFamilyFallback` so Arabic, Hebrew, CJK and Devanagari render; shortcut
symbols (⌘⌥⇧⌃) have glyphs.

**Words:** every word a part says comes from `RawWidgetsLocalizations` or the
look's own localizations; dates, times and numbers follow the locale (digits,
order, first day of the week).

**Numbers:** a part that prints a number (a stepper's value, a chart's axis,
a badge's count) formats it for the locale, or with a formatter the app
passes, never with `toString()`: an Arabic page shows Arabic-Indic digits
throughout. A chart takes a value formatter so the app can name its unit,
draws an all-zero series on a sensible scale (0 to 4, not -1 to 1 or tenths
with no unit), and mirrors with the page.

**Semantics:** each part is heard as Flutter's own widget is heard (role,
name, value, state); checkables never also say "button".

## 12. An API Flutter developers already know

- `value` and `onChanged`; a null callback disables the part.
- An optional controller and focus node: own one only when none is handed
  in, never dispose a handed one, swap it in `didUpdateWidget`.
- Flutter's names for Flutter's ideas (`onPressed`, `isSelected`,
  `semanticLabel`, `style`); widget slots (`Widget? leading`) rather than
  strings where content varies; directional types.
- An immutable theme with `copyWith`, `lerp`, `==`, `hashCode` and
  `debugFillProperties`, read with `of` and `maybeOf`, carried by an
  `InheritedTheme`.
- Overlays, shortcuts and actions through Flutter's `Overlay`, `Shortcuts`
  and `Actions`; semantics through `Semantics`.
- `const` constructors, `super.key`, no positional `bool`, every controller
  and animation disposed.
- Each look's API is its own: names and parameters come from its language,
  not from a shared vocabulary across looks.
- A field's words are strings named as `InputDecoration` names them:
  `labelText`, `hintText`, `helperText`, `errorText`. In Flutter `label`,
  `hint`, `helper` and `error` are `Widget` slots; a `String label` on a
  field reads as the wrong kind of slot.
- Null disables. A part with no callback (`onPressed: null`,
  `onChanged: null`) is turned off and looks it; no separate `enabled` flag
  is needed where a callback says it.
- A change of behaviour that `dart fix` can't rewrite fails to compile, so
  no app keeps the old behaviour without knowing. Make the new callback
  required but nullable, as `ElevatedButton.onPressed` is: every caller
  names it, and null still disables.
- Breaking changes go out together, in one release, each with a `dart fix`
  entry (`lib/fix_data.yaml`) for what a rename or a moved parameter can
  express, and a CHANGELOG line for what it can't. Keep the old names as
  deprecated aliases for that release where they still mean the same.

## 13. Customisable within the principles

Customisation goes as far as Material's and no further than the laws allow:

- a style per part (`style:` taking the look's `DesignStyle`), for the slots
  that mean something in the material;
- a component theme slot per part in the theme data;
- theme-wide knobs the look decides on (accent, corner, density);
- the type family. A look works in any family the app loads, as Material
  does: its sizes, weights and cap-height factor are set for its default,
  and a family the look names but does not bundle falls back to one it can
  rely on (Roboto), with the README saying how to supply the intended one.

A customisation that breaks a law (a hard ring on glass, a gradient on a flat
look) is not offered. Values that differ only in tokens are presets of one
look, not separate looks.

## 14. Production grade

- Only what a user needs in `lib`, `test` and `example`: no working notes,
  dates, review names, codenames or to-dos. Test files are named for what
  they check.
- Every public member documented in plain words; `dart doc` clean.
- The analyzer clean with strict options; every test leak-tracked.
- A README with install, setup under `MaterialApp`, `CupertinoApp` and
  `WidgetsApp`, everyday snippets, pictures, accessibility and languages, and
  requirements. A CHANGELOG of short present-tense lines naming the API.
- The library re-exports only the ui_core types its signatures use.
