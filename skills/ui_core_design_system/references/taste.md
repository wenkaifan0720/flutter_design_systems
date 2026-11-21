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
the material says so; adding a ring or a paint the material cannot have, to
reach a contrast ratio, is not.

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
indicator (a 2 px outline on fields). Never stack a halo on a ring, or a ring
on a part that already changes its edge for focus (a field's rule or
underline).

**Focus is findable.** The focused part differs from the unfocused one over
an area at least a 2 px perimeter's size, with at least 3:1 contrast between
the focused and unfocused pixels (WCAG 2.4.11 and 2.4.13), day and night, at
1x and 2x text. Do not rely on hue alone; never cover the part's words.

**Keyboard focus is stronger than hover; pressed is distinct from both.**
Focus animates in and out like every other state.

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

**From 600 px wide, controls do not stretch** to their column: a select, a
button, a stepper or a segmented control keeps its content's width (a field
may fill a form column).

**Chosen fills cover the whole cell.** A chosen day, segment, tab or row
fills its cell edge to edge; nested shapes are concentric with their
container's corners (inner radius = outer radius − inset).

**Dialog actions stack when they do not fit**, the confirming action on top,
each as wide as the dialog.

*Check:* measure edges at native size before judging; `DesignLabelCheck`,
`DesignRowCheck` and `DesignKeylineCheck` measure what the eye compares.

## 8. Restraint

**Shapes that make sense, no gimmicks.** Each part's shape follows from the
laws: a radio is round in every corner family, a switch reads as a switch.
When in doubt, the plainer answer wins.

**No pattern behind words.** Texture, grain and pattern stop where text
starts. Text keeps 4.5:1 over its worst background.

**Usability first.** No effect that makes a part harder to use ships, however
characteristic. Every release is compared with the previous one, in motion
and at rest; a regression a person can see blocks the release.

## 9. Every screen and every platform

**Every width:** 390, 768, 1024 and 1440 (and 1920). A phone reads as a
phone app, a desktop as a desktop app: keep desktop parts in every look
(menubar, command palette, tree, split view, context menu, shortcut labels).

**Platform idioms:** the iOS edge back-swipe pops a page; Android back
closes the top sheet, menu or dialog before it pops; desktop right-click and
Shift+F10 open context menus where the language has them; shortcut labels say
⌘ on Apple platforms and Ctrl elsewhere; pointer controls take compact
density.

## 10. Every reader

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

**Semantics:** each part is heard as Flutter's own widget is heard (role,
name, value, state); checkables never also say "button".

## 11. An API Flutter developers already know

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

## 12. Customisable within the principles

Customisation goes as far as Material's and no further than the laws allow:

- a style per part (`style:` taking the look's `DesignStyle`), for the slots
  that mean something in the material;
- a component theme slot per part in the theme data;
- theme-wide knobs the look decides on (accent, corner, density).

A customisation that breaks a law (a hard ring on glass, a gradient on a flat
look) is not offered. Values that differ only in tokens are presets of one
look, not separate looks.

## 13. Production grade

- Only what a user needs in `lib`, `test` and `example`: no working notes,
  dates, review names, codenames or to-dos. Test files are named for what
  they check.
- Every public member documented in plain words; `dart doc` clean.
- The analyzer clean with strict options; every test leak-tracked.
- A README with install, setup under `MaterialApp`, `CupertinoApp` and
  `WidgetsApp`, everyday snippets, pictures, accessibility and languages, and
  requirements. A CHANGELOG of short present-tense lines naming the API.
- The library re-exports only the ui_core types its signatures use.
