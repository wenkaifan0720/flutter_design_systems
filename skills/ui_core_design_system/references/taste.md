# Taste: the rules a good design keeps

A design is judged by its weakest screen. These rules turn taste into
decisions you can check: each says what to do, why, and how to tell.

## 1. Identity comes first

**Derive every part from the design's laws** (SKILL.md, step 1). A part the
language never had (a date picker for a 1990s desktop, a toast for paper)
is designed as the language would have grown to meet it.

*Why:* parts derived from shared laws read as one hand; parts copied from
Material with new colours read as Material.

*Check:* for any part, you can name the law it follows. A Material control
in the design's colours is the failure: a slider's thumb, a checkbox's tick
and a dialog's frame are where taste shows. Search `lib/design` for each
colour a law gives a meaning to (an accent kept for the main action, a tone
for danger) and read every use: each carries that meaning and no other.

**Name the language.** Follow an established language faithfully (keep its
proportions, idioms and behaviour), or make one of your own that is
distinct and good. Half-faithful is neither.

**Identity over pedantry.** Every part carries the style's core concept (a
neumorphic surface is extruded from its ground, a brutalist one is a hard
block with a hard shadow). Beyond that, prefer the plainer answer.

## 2. Material is the bar, not the target

**No part is harder to use than Material's at the same condition**: the
same width, text size, direction and state. The design need not do better
than Material; it must not do worse. Where Material also breaks (3x text in
a fixed-height app bar), it is not the design's fault; where only the
design breaks, it is. Where Material caps text growth (app bars, tabs,
chips), cap it the same; elsewhere grow as Material grows.

**Usability first.** No effect that makes a part harder to use ships,
however characteristic.

## 3. States keep the material

**A state only does what the material physically can.** Glass clears or
frosts; it does not grow a blue edge. An inset well stays inset. Paper takes
ink, not light. Lower visibility than Material is acceptable when the
material says so; nothing is added to reach a contrast number: no ring, no
paint the material cannot have, no shadow made crisper than its own.

**No outline at rest the material would not have**, such as a printed edge
on a moulded checkbox; high-contrast mode is the exception.

**Every state is distinct.** Rest, hover, focus, pressed, disabled,
selected, error and busy each differ from rest; pressed differs from hover
and from focus.

**Focus is drawn in the material, not with an extra outline**: a rule that
darkens and thickens, a shadow that deepens, a surface that rises, ink and
ground that swap. A ring stays only where the ring *is* the language
(Material's ring, Fluent's double stroke, a classic desktop's dotted
rectangle). Focus is quiet: no heavier than Material's 2 px field outline (a
1 px rule grows to 2 px; a rule already 2 px or heavier grows by at most
1 px and shows the rest in ink). Never stack a halo on a ring, or a ring on
a part that already changes its edge for focus. It is still findable at a
glance, day and night, at 1x and 2x, not by hue alone, and never covers the
part's words. Focus is stronger than hover; a focused field is findable with
the caret off.

**No hover wash by default.** Outside Material-like designs, a pointer over
a part shows the click cursor and, at most, a quiet change the material
allows. Keep the overlay slot in the part's style so a screen can add one.

**A disabled part looks unavailable, not just quieter.** Take away what
says "press me": a raised key loses its height, a lit face goes out, a filled
button takes the ground's colour with muted words. Keep the words legible.

*Check:* crop each state of every part the screens use, day and night, and
name the material behaviour each one shows. A disabled and an enabled main
button side by side: a person tells which one acts without reading either.

## 4. Motion

**Every state change animates continuously:** a press sinks, a check draws,
a thumb travels, a colour turns. One mechanism (a face that springs), on the
design's tokens, calm and interruptible: a press released half-way turns
back from where it stands.

**The design owns its route motion**: its page push and pop, its dialog's
arrival, its sheet's rise. The iOS edge swipe still pops a page.

**Reduce Motion:** nothing overshoots, bounces or travels far; effects
settle within 150 ms (`RawMotionPolicy`); a long travel becomes a fade.

**Judge in motion, not only at rest.** Faults hide between states: a sheet's
shadow while it rises, a selection sliding between tabs, a carousel's
corners mid-swipe. Look at frames mid-way.

## 5. Alignment and size

**One control height per density.** A button, a field, a select and a
segmented control that can share a row stand at the same height, a dialog's
buttons included.

**Content is centred by construction**, never nudged by padding until it
looks right: `RawControlBox` for the box, `RawCapCenter` with the family's
factor for one-line labels, even leading. Glyphs sit on the middle of the
capitals beside them; rows centre their children.

**From 600 px wide, controls keep their own width**: a button, a stepper or
a segmented control its content's; a select and a combobox the width of
their label and widest option, so neither jumps as the choice changes. A
text field fills what it is given, and a form sets one width for its
fields. Content keeps a readable column (about 640 px) on a wide screen.

**Chosen fills cover the whole cell.** A chosen day, segment, tab or row
fills its cell edge to edge, concentric with its container's corners
(inner radius = outer radius − inset).

**Containers don't nest in their own kind, and pad evenly.** No card in a
card or well in a well: the inner one goes flat (a divider, a heading,
space). A container pads its content the same on every side, on the grid;
a list that runs edge to edge inside it takes none.

*Check:* measure edges at native size before judging; `DesignLabelCheck`
measures a label's ink on its face.

## 6. Parts of one kind read as one family

A reader learns a design from its first screen and expects the rest to keep
its word. Faults here sit between two parts that should match and don't:
judge them in pairs, side by side.

**A select and a combobox are one kind of field.** Both stand on the text
field's face, at its height, and end in the same sign that a list opens.
Their open lists are the field's own: drawn in its material, edge and
corner, opaque enough that the page's words never show through, the chosen
row marked one way and the highlighted row one way in every list (a
select's, a combobox's, a menu's), neither in the main action's accent.

*Why:* a combobox drawn as a bare box gives no sign of its list; a select
drawn as a key reads as a button; two marks for one meaning read as two
meanings.

*Check:* a text field, a select and a combobox in one form differ only in
their words and end sign; open each list and a menu: one material, one kind
of row.

**A chosen row is filled to its end.** Its fill runs under its trailing
controls to the row's edge, and its words keep their insets chosen or not.

**The error state is the empty state's sibling.** The loading, empty, error
and success views of one region share a frame, a layout and the palette: a
glyph, a heading, a sentence, an action. The error differs by its glyph,
words and the danger tone only.

**A state never outshines the act.** A chosen segment, tab or chip never
takes the material of the screen's main action. *Check:* a form with a
segmented control and its Save button: Save is the most prominent face.

**Destructive actions take the destructive tone wherever they appear** (a
menu's Delete, a dialog's Discard, a button). Only the tone changes: it is
reached, pressed and read as any other.

## 7. Restraint

**Shapes that make sense, no gimmicks.** Each part's shape follows from the
laws: a radio is round in every corner family, a switch reads as a switch.
Icon keys of one kind share one shape. When in doubt, the plainer answer
wins.

**No pattern behind words.** Texture and grain stop where text starts.
Text keeps 4.5:1 over its worst background.

**Build what the screens need.** A part no screen uses is not built; a
setting nobody asked for is not offered.

## 8. Every screen the app runs on

**Widths:** lay out for the widths the app runs at (a phone app at 360 to
430, a tablet at 768 to 1024 either way up, a desktop or web app from
1024). A phone screen reads as a phone app, a desktop screen as a desktop
app: an app that runs on a desktop gets the desktop's parts where it needs
them (a context menu, shortcut labels, a split view).

**Pickers fit the screen they open on.** On a phone a calendar's seven
columns fit at the phone's width and it opens where its whole height fits;
on a desktop it keeps its own width beside its field. A date picker marks
today.

**Platform idioms:** the iOS edge swipe pops a page; Android back closes the
top sheet, menu or dialog before it pops; right-click and Shift+F10 open
context menus on a desktop; shortcut labels say ⌘ on Apple platforms and
Ctrl elsewhere.

## 9. Every reader

**Right to left:** `EdgeInsetsDirectional`, `AlignmentDirectional`,
`PositionedDirectional` and start and end everywhere; mirror directional
icons, sliders, progress and swipes; light and shadows mirror too.

**Text size:** every screen holds at twice the text size with no overflow
and no clipped descender; fixed-height parts grow, or cap where Material
caps.

**Scripts:** set `fontFamilyFallback` so Arabic, Hebrew, CJK and Devanagari
render. Never fetch whole Noto CJK families at run time; rely on the
platform's fallback or bundle a subset.

**Words and numbers:** every word a part says comes from
`RawWidgetsLocalizations` or the app's localizations; dates, times and
numbers follow the locale (Arabic-Indic digits in Arabic), never
`toString()`.

**Semantics:** each part is heard as Flutter's own widget is heard (role,
name, value, state); checkables never also say "button".
