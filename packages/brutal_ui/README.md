# brutal_ui

A Flutter design system with its make-up off. Heavy black rules, square corners, a hard offset shadow under what you
can press, cells that share their rules like a table you can see, and one flat colour block a screen. Plain on the
surface, exact underneath: everything sits on one 4 px grid and one 2 px rule.

Take away the colour and the font and a settings form is still Brutal's: every control is drawn in the same 2 px
rule with square corners; what you can press stands on the same hard 4 px shadow and slides into it when pressed;
rows, segments, tabs and navigation are cells that share their rules; keyboard focus is a second square rule 2 px
outside the face and its shadow.

The parts take the parameters a Flutter developer expects: a press is `onPressed`, a row's tap `onTap`, a control is
`value` with `onChanged`, a destination is `selectedIndex` with `onSelected`, a null callback disables.

## Install

```yaml
dependencies:
  brutal_ui: ^{{version}}
```

## Use

`BrutalTheme` is the install. Put it in your app's `builder:`, under a `MaterialApp`, a `CupertinoApp` or a
`WidgetsApp`; Brutal has no app widget of its own. On a `MaterialApp`, give its theme `brutalPageTransitions` too, so
its pages change in Brutal's way.

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(builders: brutalPageTransitions),
  ),
  builder: (context, child) => BrutalTheme(
    data: BrutalThemeData.light(),
    child: BrutalToaster(child: child!),
  ),
  home: const MyHome(),
);
```

Load the face before the first frame so the web never shows a fallback: `await brutalLoadFonts();` in `main`.

An app with places can take the frame whole: `BrutalHost` in the `builder:` (the theme by day and night, the toaster and
the paper), `BrutalAppShell` round the root with its `BrutalTab`s and one `BrutalShellAction`, and one `BrutalScreen` a
page, which lays the margins, the column, the bar, the footer and the keyboard.

```dart
BrutalAppShell(
  tabs: const [BrutalTab(LucideIcons.house, 'Home'), BrutalTab(LucideIcons.ticket, 'Tickets')],
  selectedIndex: index,
  onSelected: (i) => setState(() => index = i),
  child: BrutalScreen(
    topBar: const BrutalAppBar(title: 'Tonight'),
    footer: BrutalButton.filled('Buy tickets', onPressed: buy),
    body: const Text('Low Tide, doors at 19:00.'),
  ),
);
```

Pages change in Brutal's way: a page pushed over another slides a short way (24 px) in from the end side over the page
it covers, which stays put, and stops dead; going back is the reverse; switching between places changes nothing but the
place. On iOS a swipe from the screen's leading edge pops the page too: iOS keeps that swipe in Cupertino's own page
change, which Brutal's push replaces, so `brutalPageTransitions` wraps its iOS entry in ui_core's
`DesignSwipeBackPageTransitionsBuilder`: while a finger drives the swipe the page follows it and the one under it
shows; otherwise Brutal's push and pop play. `BrutalPage` does this for a router's pages, and with `BrutalTheme`
(or `BrutalHost`) in the app's `builder:` so does a `MaterialPageRoute` from `material_ui`, the material library Brutal
is built on. An app on Flutter's own `MaterialApp`, whose `MaterialPageRoute` reads only the app's theme, gives Brutal's
change to that theme with `brutalPageTransitions`, as in Use above: one map fits Flutter's `ThemeData` and material_ui's.

Back closes what stands over a page before it goes back a page: Android's system back takes an open menu, a select's
or a combobox's list, a popover or a date picker away first, the innermost first, as it does a dialog or a sheet (focus
goes back to what opened it; a field's list leaves the keyboard in the field), and the next back goes back a page.
Under a pointer the controls stand
at the platform's density (40 px on a desktop, 48 on a phone), and everything a pointer presses takes the keyboard too.

## Make it yours

Three layers, each over the last: the brand, a kind of part across the app, one part. Each takes only what keeps the
look: colours, padding, sizes and type, never a radius, a blur or a soft shadow.

```dart
// The brand: your signal colour (its words picked black or white at 4.5:1),
// a heavier rule (2 to 4 px) and a deeper shadow (2 to 8 px).
final theme = BrutalThemeData.from(signal: const Color(0xFF2F5BFF)).copyWith(
  borderWidth: 3,
  shadowOffset: 6,
  // Every primary button.
  filledButtonStyle: const BrutalStyle(
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 28)),
    minimumSize: WidgetStatePropertyAll(Size(0, 56)),
  ),
);

// One button.
BrutalButton.filled(
  'Buy tickets',
  onPressed: buy,
  style: const BrutalStyle(fill: WidgetStatePropertyAll(Color(0xFFFFD23F))),
);
```

Every part takes `style:` and reads its slot in the theme (`BrutalThemeData.chipStyle`, `.dialogStyle` and so on);
each part's documentation says which of the style's fields it reads. `typeface:` sets the face for every part and the
Material theme under them; give the family's cap height so words sit centred in their cells.

A pointer over a part changes nothing but the cursor: hover is a desktop's wash, not Brutal's. The hovered state still
reaches every style, and a value left null falls through to the next layer, so a hover takes one line:

```dart
BrutalStyle(
  fill: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.hovered) ? const Color(0xFFFFF4C2) : null,
  ),
);
```

In an open list the pointer and the keyboard are one place. A menu (`BrutalMenu`, a menu bar's, a split button's), a
select's list and the combobox's and tag input's options light one row with a square line inside it: the pointer's
move takes the keyboard to its row, and the keys move on from there. A menu opened by a click lights no row until the
pointer moves onto one or a key is pressed (the first Down lights the first row); one opened by Enter, Space or Down
lights its first row. A list opened by a touch lights a row once a mouse or trackpad moves onto one, though the
platform shows no keyboard focus after a touch.

## Licence

The code is MIT. Space Grotesk is under the SIL Open Font License 1.1, and Lucide's icons under ISC and MIT
(THIRD_PARTY_NOTICES).
