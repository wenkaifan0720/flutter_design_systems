# ledger_ui

A Flutter design system kept in ink. A private bank statement on warm paper: ink rules where other looks draw boxes,
dot leaders between a line's words and its figure, engraved figures for the amounts that matter and a mono for every
other amount, one green for the act and the money that came in, a vermilion for what went over. Five presets (quire,
terracotta, indigo, verdigris, carbon), each designed by day and by lamplight, at three densities.

Take away the colour and the font and a settings form is still Ledger's: its fields are written on a rule rather than
boxed, its rows are ruled lists, its sections head on an ink rule, its amounts hang on their decimal point. Its states
are said in the same rules and ink: keyboard focus is the accountant's double rule under a control, a pressed act sinks
into the paper like a stamp, a hovered row's dot leader inks in, a disabled act is written in pencil, and a page
waiting for its records draws a dot leader in, dot by dot.

![Home at 1440 by day](screenshots/home-1440-day.png)

The parts take the parameters a Flutter developer expects: a press is `onPressed`, a row's tap `onTap`, a control is
`value` with `onChanged`, a destination is `selectedIndex` with `onDestinationSelected`, a null callback disables.

## Install

```yaml
dependencies:
  ledger_ui: ^0.2.0
```

## Use

`LedgerTheme` is the whole install. Put it in your app's `builder:`, under a `MaterialApp`, a `CupertinoApp` or a
`WidgetsApp`; Ledger has no app widget of its own.

```dart
import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ledgerLoadFonts(); // the first frame is set in Ledger's faces
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    // Pages pushed in Ledger's motion, not the platform's slide or zoom.
    theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: ledgerPageTransitions)),
    builder: (context, child) => LedgerTheme(
      data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? LedgerThemeData.dark()
          : LedgerThemeData.light(),
      child: child!,
    ),
    home: const AccountsPage(),
  );
}
```

**Page motion.** A page pushed in Ledger is a leaf laid down: it fades in as it rises 8 points onto the page, in 200
ms, and a pop lifts it off the same way; under reduced motion it lands at once. A destination chosen from the side bar,
the rail or the tab bar is no push: it changes in place, and its selection lands in the same frame, so a page never
stands under another destination's mark. `LedgerTheme` and `LedgerHost` set the motion on the Material Ledger is
built on (`material_ui`), so a `LedgerPage` takes it, but Flutter's own `MaterialPageRoute` reads your app's
`ThemeData`: the `theme:` line above hands it `ledgerPageTransitions` (one map fits either Material's
`PageTransitionsTheme`), or the platform's slide or zoom flies the page in. On iOS the map keeps the swipe back from
the screen's leading edge round Ledger's push (ui_core's `DesignSwipeBackPageTransitionsBuilder`): the page follows
the finger, as on every iOS screen, and goes past half way or on a fling; a push and a pop are still the leaf.
Android's back closes what stands open over a page first (a select's list, a popover, a field's suggestions; a sheet
and a dialog are routes), then pops it.

Under a `CupertinoApp` or a `WidgetsApp` it is the same `builder:`; Ledger supplies the words Flutter's text field asks
Material for, so a field works under either. Every text under `LedgerTheme` falls back on Ledger's body style.

## Examples

A page is a `LedgerScreen` with its top bar and body:

```dart
LedgerScreen(
  topBar: const LedgerTopBar(title: 'Accounts'),
  body: LedgerSection(
    head: const LedgerHead('Everyday', note: 'Balance'),
    child: LedgerRows(
      children: [
        LedgerRow(
          leading: const LedgerGlyph(LucideIcons.wallet),
          title: 'Checking',
          subtitle: '··4821',
          subtitleMonospace: true,
          value: const LedgerAmount(6248.30),
          onTap: () => openAccount('checking'),
        ),
        LedgerRow(
          leading: const LedgerGlyph(LucideIcons.piggyBank),
          title: 'Savings',
          value: const LedgerAmount(18420.00),
          onTap: () => openAccount('savings'),
        ),
      ],
    ),
  ),
)
```

Buttons: `LedgerButton` is the ordinary act (ringed), `.filled` the page's one act in the green, `.ink` a firm act
filled with the ink, `.text` no frame; `isDestructiveAction: true` sets it in the vermilion.

```dart
LedgerButton.filled('Transfer', onPressed: transfer, expand: true);
LedgerButton('Cancel', onPressed: () => Navigator.pop(context));
```

A field is written on a rule; a select is a choice on the same rule:

```dart
LedgerTextField(label: 'Note', hint: 'What it is for', controller: note);

LedgerSelect<String>(
  label: 'Currency',
  value: currency,
  items: const [
    LedgerSelectItem(value: 'USD', label: 'US dollar'),
    LedgerSelectItem(value: 'EUR', label: 'Euro'),
  ],
  onChanged: (value) => setState(() => currency = value),
);
```

A dialog asks before an act and answers with the choice:

```dart
final confirmed = await LedgerDialog.show(
  context,
  title: 'Delete this entry?',
  body: 'It leaves your records for good.',
  type: LedgerDialogType.destructive,
  confirmLabel: 'Delete',
);
```

Navigation: `LedgerNavigationFrame` gives the window the navigation it earns, the tab bar under 600, the rail from 600
and the side bar with your wordmark from 1024.

```dart
LedgerNavigationFrame(
  destinations: const [
    LedgerNavItem(LucideIcons.house, 'Home'),
    LedgerNavItem(LucideIcons.list, 'Activity'),
    LedgerNavItem(LucideIcons.settings, 'Settings'),
  ],
  selectedIndex: tab,
  onDestinationSelected: (i) => setState(() => tab = i),
  brand: 'Quill',
  body: pages[tab],
);
```

| | |
|---|---|
| ![A transaction at 390 by day](screenshots/transaction-390-day.png) | ![Settings at 390 by lamplight](screenshots/settings-390-night.png) |

## Theme

`LedgerTheme.of(context)` (or `context.ledgerTheme`) returns the `LedgerThemeData` in scope: its colours, its type
(the serif for heads and figures, the sans for words, the mono for amounts), its density and its radii. Restyle a part
of the tree with a nested `LedgerTheme`; `AnimatedLedgerTheme` animates between two.

```dart
// A preset by its id, for the platform's brightness.
LedgerThemeData.preset('verdigris', Brightness.dark);

// Your own paper, ink and accent; the rest is derived from them, words held to 4.5:1 on every ground.
LedgerThemeData.from(
  paper: const Color(0xFFF4EFE6),
  ink: const Color(0xFF1F2A2E),
  accent: const Color(0xFF2F6B4F),
);

// Density: standard is the touch size (a 48 button, a 52 row), comfortable 4 off each, compact 8; the default is
// compact under a pointer and standard on touch. A tap target stays 44 at every density.
LedgerThemeData.light().copyWith(density: LedgerDensity.compact);
```

Change the accent with `from`, not `copyWith(accent:)`: `copyWith` changes the one role it is given, so the act would
turn your colour while money in, the washes and the seal stayed the old green.

The money tones carry meaning: `moneyIn` is the accent's green (money received), `over` the vermilion (spent past a
limit, and only then) and `move` a quiet ink (money moved between the owner's own accounts). `from` and the presets
keep them tied to the accent, the over colour and the ink. Given apart, they break the book: a red `moneyIn` reads
income as overspending.

Paper keeps a paper's corners: `cardRadius` stands from 0 to 22, `smallRadius` from 0 to 10 and `sheetRadius` from
0 to 28, the range Ledger's own presets span (quire's are 6, verdigris's the roundest), and a theme past them fails an
assert in debug builds, since a slip rounded like a pill reads as plastic, not paper. `controlRadius`, the corner of
what the hand holds, takes any value: round or square, a control is still Ledger's.

## How Ledger is built

The rules every part follows, so a part you add can follow them too:

- **One sheet of paper, ink on it.** Everything is drawn in rules, figures, type and engraved hatching; a box is drawn
  only where a rule cannot carry it.
- **Order comes from rules, not containers.** An ink rule heads a section, a hairline parts the rows, a dot leader
  ties a name to its figure, and figures hang on their decimal point.
- **Only paper rises.** A slip (a receipt, a dialog, a sheet, a menu, a toast) is a separate leaf laid on the page,
  its soft drop from one lamp overhead; the page's green act stands on it like a seal and sinks when pressed. Nothing
  else lifts: a control lies flat on the page.
- **Ink never lies over ink.** Marks stand side by side on their line, as signatures do on a form.
- **Colour is ink.** One green for the act and for money in, one vermilion for what went over, each also laid as a
  pale wash; the rest is the paper and three strengths of ink. No glass, no glow.
- **A state is written.** Keyboard focus is the double rule under a control, a press sinks like a stamp, a disabled
  act is in pencil, an error is the vermilion line, and waiting is a dot leader drawn in. In an open list the chosen
  option stands on the menu's paper, semibold and ticked in green; a pointer underlines an option's words and the
  keyboard doubles the rule under them, on the option's own row. A menu marks one row at a time, the one the pointer
  or the keys moved to last, and one a click opened marks none until either moves.
- **Motion is the pen's and the page's.** Every change of state moves from where it is to where it is going: ink fades
  in, a rule is drawn in, a figure re-inked, a leaf laid down or lifted, day fades to lamplight. Nothing rolls,
  springs or curves away, and with reduced motion on it changes at once. The one change that never moves is a
  destination chosen in the side bar, the rail or the tab bar: its mark lands with its page.

## The API, Flutter's way

Ledger's widgets take what Flutter's take: a value with `onChanged`, and a null callback disables a control (only
`LedgerTextField`, `LedgerSettingRow` and `LedgerSelectItem` keep an `enabled`, as `TextField`, `ListTile` and
`DropdownMenuItem` do). Every single control takes an optional `focusNode` and `autofocus`, and a widget that takes a
`TextEditingController` makes its own when none is given, keeps the words when you take yours back, and never disposes
one it was given. The theme is an immutable `LedgerThemeData` with `copyWith`, `lerp` and equality, read through an
inherited theme.

The ordinary parts (the buttons, the icon button, the fields, the chip, the checkbox, the switch, the segmented
control, the toggle group and the filters, the badge, the banner, the tooltip, the toast, the dialog and the slip)
each take a `style:`, a `LedgerStyle` (ui_core's `DesignStyle`, as Material's `ButtonStyle` is): its paper, ink,
rule, corners, padding, least size, words and glyph size, as far as the part draws them, each resolved for the
part's states. A field reads only its rule's ink, its paper, its padding and its words: it stays written on a rule,
never boxed. A `fill` holds in every state it is given for, so give a button's pressed shade too, or its press no
longer sinks. `LedgerThemeData`'s `components` sets one per part across the app, and a part's own `style:` goes over
it. The other parts (the select, the radio, the slider, the rows, the tabs, the bars and the sheet) take no `style:`
in 0.2.0; they follow the theme's roles, so a nested `LedgerTheme` restyles them.

```dart
// A ringed act inked in the green; switched off, it keeps its pencil.
final green = context.ledgerTheme.accentText;
final inGreen = WidgetStateProperty.resolveWith(
  (states) => states.contains(WidgetState.disabled) ? null : green,
);
LedgerButton(
  'Export',
  onPressed: export,
  style: LedgerStyle(edge: inGreen, foreground: inGreen),
)
```

Labels and glyphs are a `String` and an `IconData` where Flutter would take a `Widget`, as in
`LedgerButton.filled('Save', icon: LucideIcons.check)`. They stay so in 0.2.0; a later release adds an optional
`Widget` slot beside each, with the `String` made optional, so no call written now breaks.

## Change one component

Copy a component's file from `lib/src/ledger/` into your app, rename its class, and replace its `src/` imports with
one import of `package:ledger_ui/ledger_parts.dart`, which exports everything the components are drawn with (the
pressable, the rules, the leader, the engraving and the other helpers). The rest of your app stays on the package.

## Accessibility and languages

- **Screen readers.** Every control says its role, its label, its value and its state (checked, selected, on,
  expanded, disabled); rules, leaders and engravings are drawn, not spoken. The tests sweep every gallery page and
  every screen of the example for a label on each control's face, at each density, on a phone and on the desktop,
  and hold the main pages to Flutter's tap-target, label and text-contrast guidelines by day and by night.
- **Keyboard.** Everything works from the keyboard, in reading order (right to left too): Tab to move, Enter and
  Space to press, Down to open a select (its list opens on the chosen option; the arrow keys, Home, End and a
  letter move in it), the arrow keys on a slider, Escape to close. Focus is the double rule
  under the face (in an open list, under the option's words).
- **Targets and contrast.** A target of 44 at every density (a density shrinks the drawn face, never the reach);
  words at 4.5:1 or more on their paper, by day and by lamplight.
- **Large text.** Words follow the platform's text size to 200% (past it, a page stands at 200%): controls and
  rows grow taller rather than cut words, long labels wrap, a name and its value on a leader turn onto two lines,
  two acts side by side stack, dialogs and sheets scroll; a tab's name too wide for its column sets smaller on its
  line rather than lose its end; a seal pressed beside a memo's or a cheque's words is pressed under them; a chart's labels inside its plot and the months under it, set where the engraving
  puts them, grow to 130% (its key and day ruler to 200%, a day that would close up on its neighbour giving way; a
  screen reader reads the chart whole), as do a tag's word and a footnote's mark. Words set inside a fixed shape
  keep their size: the engraved figures, written or typed (already large; one wider than its column is set
  smaller), a wordmark, a monogram's initials, a seal's lettering, a card face's printing, a counter, a calendar's weekdays and
  day numbers, a time wheel's figures and a badge's count.
- **Reduced motion.** With the platform's reduced motion on, every change of state lands at once.
- **Right to left.** Under a right-to-left `Directionality` the layout mirrors: the side bar and the rail stand at
  the right, rows and fields read from the right, chevrons and arrows turn (a button's too), and switches, sliders,
  gauges and the stack bar run from the reading start. Amounts and counters stay left to right, as do a sum typed
  after its sign, an account's masked number, the time wheel's hour and minute and a cheque's foot line. A time, a
  mask or a sign inside a line of words follows the platform's bidirectional order, so English words under a
  right-to-left page can carry them to the far end; translated words read as written. The example's Settings has a right-to-left
  switch, and the gallery's `/#/settings?dir=rtl` opens it that way.
- **Other scripts.** Ledger's three faces are Latin. Arabic, Hebrew, Chinese, Japanese, Hindi or Thai falls back
  on the platform's fonts (on the web, Flutter's Noto fallback).
- **Words.** The words a part says by itself (Cancel, Close, Back, Delete, Clear, Search, Loading, Today, Previous
  month, Next month, Dismiss, Confirm, a carousel's, a table's and the toasts' spoken names) come from ui_core's
  `DesignLocalizations`, in 30 languages. English needs nothing set up; for the app's language, add
  `DesignLocalizations.delegate` to `localizationsDelegates` and list
  `supportedLocales: DesignLocalizations.supportedLocales`. To word one your own way, extend
  `DefaultDesignLocalizations`, override it, and add a delegate for your subclass. A text field's menu (Cut, Copy,
  Paste, Select all) and a sheet's spoken name are `material_ui`'s `MaterialLocalizations` (on iOS the menu is
  `cupertino_ui`'s `CupertinoLocalizations`). An app on Flutter's own `MaterialApp` with `flutter_localizations`
  gives Flutter's types, which those libraries cannot read, so Ledger loads `material_ui`'s and `cupertino_ui`'s own
  translations for the app's language itself whenever the app gives none of theirs, English for a language they do
  not know: never an error. Words the shared set does not have stay
  English, most of them a parameter you can word yourself: a dialog's Got it, a select's Choose one, Back to a page,
  the date picker's Hour and Minute, the composer's words and the charts' spoken names.
- **Dates and amounts.** Dates, times and amounts print in English with US dollars (`LedgerFormat`), whatever the
  locale.
- **Known limits.** The charts read left to right in any page, their labels, keys and rulers with them.

## Example

`example/` is Quill, a household ledger built on Ledger: its Home, the register, a new entry and Settings, moved
between by Ledger's own navigation, then the index of every part's page, in every preset, by day and by lamplight.

## Licences

The package is BSD-3-Clause. It bundles Instrument Serif, Inter Tight and IBM Plex Mono under the SIL Open Font
License 1.1, and depends on `lucide_icons_flutter` (Lucide, ISC; Feather, MIT). The notices are in `LICENSE` and
`THIRD_PARTY_NOTICES/`.
