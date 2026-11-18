# appliance_ui

A Flutter design system shaped like a calm household device: warm moulded plastic under one light, crisp seams, one
signal orange and lamps that say what is on.

![Larder, Appliance's example shop, by day: its home page at 1440 px beside the same page on a 390 px phone](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/appliance_ui/screenshots/hero_home_day.webp)

**[Live gallery](https://wenkaifan0720.github.io/flutter_design_systems/appliance/)** · [API reference](https://pub.dev/documentation/appliance_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/)

## Install

```sh
flutter pub add appliance_ui material_ui
```

`material_ui` is Flutter's Material library as a package (Flutter 3.50 deprecates `package:flutter/material.dart` for
it). The quick start uses its `MaterialApp` as the app around Appliance. Appliance's own parts are plain widgets, so
they run as well under a `CupertinoApp` or a `WidgetsApp`.

## Quick start

`ApplianceHost` is the install: put it in your app's `builder:` (under a `MaterialApp`, a `CupertinoApp` or a
`WidgetsApp`), and load the bundled face before the first frame.

```dart
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await applianceLoadFonts();
  runApp(
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(builders: appliancePageTransitions),
      ),
      builder: (context, child) => ApplianceHost(child: child!),
      home: ApplianceScreen(
        topBar: const ApplianceAppBar(title: 'Basket'),
        body: Center(child: ApplianceButton.filled('Checkout', onPressed: () {})),
      ),
    ),
  );
}
```

## What it is

Warm-white moulded plastic (a warm grey by night) in
three depths under one light from the top: smooth faceplates seated in a finely grained housing at crisp parting
lines, keys that stand up and sink when pressed, wells that sink in. One signal orange for the main key, the lamps
and the focus bezel. Small lamps say what is on. Selectors are mechanical: keys latch, a slide switch snaps to its
detent, a slide selector's block slides along its trough.

Take away the colour and the font and a settings form is still Appliance's: every row sits on a faceplate split by
hairline seams; a switch is a cap in a sunken slot, on at the end side with its lamp lit and its on bar showing; the
current place is a latched key with its lamp lit, never a tint; focus is a bezel 2 px outside the part, concentric
with it.

The parts take the parameters a Flutter developer expects: a press is `onPressed`, a row's tap `onTap`, a control is
`value` with `onChanged`, a destination is `selectedIndex` with `onSelected`, a null callback disables.

![By night: Larder's orders at 1440 px, the open order with its lamp-lit progress, beside the basket on a 390 px phone](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/appliance_ui/screenshots/night_orders_basket.webp)


## Set up

`ApplianceHost` follows the platform's day and night. To choose the theme yourself, put `ApplianceTheme` in your
app's `builder:` instead, under a `MaterialApp`, a `CupertinoApp` or a `WidgetsApp`; Appliance has no app widget of its
own. On a `MaterialApp`, give its theme `appliancePageTransitions` too, so its pages change in Appliance's way: the new page slides home a short way from the end side and seats at its
detent, the one beneath sliding back and dimming. On iOS the map keeps iOS's swipe back from the screen's edge.

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(builders: appliancePageTransitions),
  ),
  builder: (context, child) => ApplianceTheme(
    data: ApplianceThemeData.light(),
    child: ApplianceToaster(child: child!),
  ),
  home: const MyHome(),
);
```

`applianceLoadFonts()` before `runApp` loads the bundled face (Barlow) before the first frame, so the words never
flash in a fallback face.

A page is an `ApplianceScreen(topBar: ApplianceAppBar(title: 'Basket'), body: ...)`; its content stands on
faceplates (`AppliancePanel`, `ApplianceListGroup` of `ApplianceListTile`s). The app's places are an
`ApplianceScaffold`: the key strip under a phone's screen, the rail from 600 px, the moulded side panel from 1024.

## Make it yours

Every part takes `style:` (an `ApplianceStyle`, `WidgetStateProperty` per slot, as Material's `ButtonStyle`), over
its part theme on `ApplianceThemeData` (`buttonStyle`, `filledButtonStyle`, `textButtonStyle`, `iconButtonStyle`,
`textFieldStyle`, `selectStyle`, `menuStyle`, `toggleStyle`, `selectorStyle`, `stepperStyle`, `panelStyle`,
`listTileStyle`, `navigationStyle`, `dialogStyle`, `toastStyle`).

A brand recolours the finish and the signal, and keeps the contrast:

```dart
ApplianceThemeData.from(
  brightness: Brightness.light,
  finish: const Color(0xFFDDE7E1),
  signal: const Color(0xFF1F7A5C),
  fontFamily: 'MyFace',
);
```

The corners, the light and the three depths stay the look's. `ApplianceThemeData(texture: false)` takes the grain
off the housing; the platform's high contrast takes it off too and darkens every seam.

## Platforms

Pure Dart and Flutter, no plugins: Android, iOS, the web, macOS, Windows and Linux. Its tests run on macOS and on
Linux, and the live gallery is its example built for the web. The layouts follow the window, not the device: the key
strip under a phone's page, the rail from 600 px, the moulded side panel from 1024.

## Accessibility

Every part says what it is to a screen reader (a switch its label and state, a rating "Rating, 3 of 5", a chart its
summary). Appliance's touch floor is 48 px (`ApplianceThemeData.tapTargets`): its sheets and rating are held to it
by ui_core_test's tap-target check, and the rail to a pointer's. Focus is a bezel 2 px outside the part, concentric
with it. Tab moves between parts, the arrows along tabs and a rail, and Escape closes a dialog, a sheet or a menu. The platform's high contrast takes
the grain off the housing and darkens every seam.

## Right to left and languages

In a right-to-left app everything mirrors: the side panel, the slide switch's on side, a fader's lit part, a part-lit
star, a chart's readout. The words Appliance itself says (loading, try again, a chart's summary and its counts) come
from ui_core's localizations, in its 30 languages, plurals and all; an app's own words stay the app's.

## On ui_core

Appliance paints; [ui_core](https://pub.dev/packages/ui_core) behaves. Its tooltip, context menu, dialog and
sheets, tabs, rail and side panel, rating and charts stand on ui_core's: focus moves in and back, Escape closes,
the rail's places and the tabs are one tab stop the arrows move along, a sheet follows the finger down, and a
screen reader hears each as what it is (a dialog, a tab, "Rating, 3 of 5", a chart's summary in the reader's
language).

```dart
ApplianceListGroup(
  header: 'Notices',
  children: [
    ApplianceListTile(
      title: 'Order updates',
      trailing: ApplianceSwitch(value: on, onChanged: (v) => setState(() => on = v), semanticLabel: 'Order updates'),
    ),
  ],
);
```

## Licence

The code is MIT. Barlow is under the SIL Open Font License 1.1, and Lucide's icons under ISC and MIT
(THIRD_PARTY_NOTICES).
