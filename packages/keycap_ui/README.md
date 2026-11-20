# keycap_ui

Keycap is a Flutter widget library that draws an app's controls as keycaps on a mechanical keyboard. Keys are sculpted, with their walls showing round a dished top face, and they travel down when pressed. Choices latch. Lists, cards and fields sit in wells cut into the case. It includes forms, navigation, dialogs, sheets and toasts in light and dark colourways.

## Getting started

Add the packages for the Material example below.

```sh
flutter pub add keycap_ui material_ui
```

Load the bundled Rubik font before calling `runApp`. Place `KeycapHost` in the application builder so pages and overlays share the same theme. The host also works with `CupertinoApp` and `WidgetsApp`.

```dart
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await keycapLoadFonts();
  runApp(
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(builders: keycapPageTransitions),
      ),
      builder: (context, child) => KeycapHost(child: child!),
      home: KeycapScreen(
        topBar: const KeycapAppBar(title: 'Notes'),
        body: Center(
          child: KeycapButton.accent(onPressed: () {}, child: const Text('New note')),
        ),
      ),
    ),
  );
}
```

`keycapPageTransitions` gives every platform Keycap's page change: the new page comes a short way in from the reading end and settles while the page beneath steps back and dims. On iOS it keeps the swipe back from the screen's edge.

## Keys

Each kind of key has its own constructor and its own component theme:

- `KeycapButton`: a light key for a neutral action.
- `KeycapButton.modifier`: a darker key for a secondary action.
- `KeycapButton.accent`: the coloured key for the screen's main action. With `isDestructiveAction: true` it is the danger key a confirming dialog ends with; on a page, a destructive `KeycapButton` keeps its plastic and prints its words in the danger colour.
- `KeycapButton.text`: words printed on the case, with no key under them.
- `KeycapIconButton`: a square key. Give it `selected` and it latches.

## Navigation

`KeycapScaffold` shows the places in a row at the foot below 600 logical pixels, in a rail from 600 and in a side column from 1024. Pass the current place in `selectedIndex` and update it in `onSelected`. The current place is a darker key latched under its legend.

## Theming

`KeycapHost` follows the platform brightness. For a brand, wrap the app in `KeycapTheme` and pass `KeycapThemeData.from`, which moulds the accent key in the brand colour and keeps every legend readable:

```dart
final theme = KeycapThemeData.from(
  brightness: Brightness.light,
  accent: const Color(0xFF16807A),
  fontFamily: 'Inter',
);
```

Set a part's defaults on the theme (`buttonStyle`, `selectStyle`, `wellStyle` and the rest) or pass a `KeycapStyle` to one control. `KeycapThemeData.density` takes `KeycapDensity.compact` or `comfortable`; by default it follows the platform. The cap, the well and the panel are public: `KeycapCap`, `KeycapWell` and `KeycapPanel`.
