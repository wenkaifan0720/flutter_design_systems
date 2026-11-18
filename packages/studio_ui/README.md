# studio_ui

A Flutter design system that makes an app a piece of studio gear: brushed anodised panels, glass displays set into
them, and keys that latch and light up amber, by day and by night.

![Roomtone, Studio's example podcast app, by day: its home at 1440 px beside the same page on a 390 px phone](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/studio_ui/screenshots/hero_home_day.webp)

**[Live gallery](https://wenkaifan0720.github.io/flutter_design_systems/studio/)** · [API reference](https://pub.dev/documentation/studio_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/)

## Install

```sh
flutter pub add studio_ui material_ui
```

`material_ui` is Flutter's Material library as a package (Flutter 3.50 deprecates `package:flutter/material.dart` for
it); the quick start takes its `MaterialApp`. Studio itself needs no Material app.

## Quick start

`StudioHost` is the install: put it in your app's `builder:` (under a `MaterialApp`, a `CupertinoApp` or a
`WidgetsApp`) for the theme by day and by night, the toaster and the chassis, and load the bundled face before the
first frame.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await studioLoadFonts();
  runApp(
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(builders: studioPageTransitions),
      ),
      builder: (context, child) => StudioHost(child: child!),
      home: StudioScreen(
        topBar: const StudioAppBar(title: 'Library'),
        body: const StudioDisplay(child: Text('Rooms that sound right, 38 min.')),
        footer: StudioButton.lit('Publish', onPressed: () {}),
      ),
    ),
  );
}
```

## The look

Brushed anodised panels with machined edges, glass displays set into them, keys that latch and light, faders and
knobs with a real throw, segment meters behind dark glass. One light falls from the top. By day the gear stands in a bright room (silver panels, pale
displays); by night in low light (graphite panels, dark glass). The amber indicator is the one accent, and it means
something is on.

Take away the colour and the font and a settings form is still Studio's: every control is an object at one of three
depths (raised keys, flush panels, sunk glass) under the same light; a choice latches a key in and lights its lamp; a
switch throws a metal cap in a slot; focus is a ring 2 px outside the face.

The gear is the chrome. What people read sits on smooth glass in plain sentence case; only the engraved legends on the
panels are small capitals, and only in scripts that have them.

## Use

`StudioTheme` alone is the theme (`StudioHost` holds it with the toaster and the chassis). Put it in your app's
`builder:`, under a `MaterialApp`, a `CupertinoApp` or a `WidgetsApp`. On a `MaterialApp`, give its theme
`studioPageTransitions` too, so its pages change in Studio's way.

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(builders: studioPageTransitions),
  ),
  builder: (context, child) => StudioTheme(
    data: StudioThemeData.anodised(MediaQuery.platformBrightnessOf(context)),
    child: StudioToaster(child: child!),
  ),
  home: const MyHome(),
);
```

Load the face before the first frame so the web never shows a fallback: `await studioLoadFonts();` in `main`.

An app with places can take the frame whole: `StudioHost` in the `builder:` (the theme by day and night, the toaster and
the chassis), `StudioAppShell` round the root with its `StudioTab`s and one `StudioShellAction`, and one `StudioScreen`
a page, which lays the brushed panel, the margins, the column, the bar, the footer and the keyboard.

```dart
StudioAppShell(
  tabs: const [StudioTab(LucideIcons.house, 'Home'), StudioTab(LucideIcons.libraryBig, 'Library')],
  selectedIndex: index,
  onSelected: (i) => setState(() => index = i),
  action: StudioShellAction(icon: LucideIcons.mic, label: 'New recording', onPressed: (context) => record()),
  child: StudioScreen(
    topBar: const StudioAppBar(title: 'Library'),
    footer: StudioButton.lit('Publish', onPressed: publish),
    body: const StudioDisplay(child: Text('Rooms that sound right, 38 min.')),
  ),
);
```

The places stand as a key bank under 600 px, a rail to 1024 and a side panel past it (`StudioMetrics.tablet` and
`StudioMetrics.desk`); the act is the graphite floating key over the page's bottom end, which the screen keeps clear.

Pages change in Studio's way: a page slides a short way (40 px) in from the end side as a module slides into a rack,
and the page it covers dims; going back is the reverse. On iOS a swipe from the screen's leading edge pops the page:
`studioPageTransitions` wraps its iOS entry in ui_core's `DesignSwipeBackPageTransitionsBuilder`, so the page follows
the finger and the one under it shows. `StudioPage` does this for a router's pages, and `StudioSheetPage` raises a
routed sheet as `showStudioBottomSheet` does. Back closes what stands over a page (a select's list, a dialog, a sheet)
before it goes back a page.

Studio paints and ui_core behaves: dialogs and sheets run on ui_core's routes (focus in and back, Escape, a drawer a
finger drags down), the tabs and an app's places are one tab stop each with the arrows along them, and the wheels, the
rating, the tooltip and the search fields are ui_core's, under Studio's metal and glass. A question asked before
something is lost is an alert: `showStudioDialog(context: context, isAlert: true, builder: ...)`.

## Make it yours

Three layers, each over the last: the brand, a kind of part across the app, one part.

- **The brand.** `StudioThemeData.from(indicator: …, finish: …)` relights the lamps, the lit keys and the readouts and
  anodises the panels in your finish. Lit words are picked dark or light to stay at 4.5:1, and a lit legend on the metal
  is darkened by day until it reads. The corners, the light from the top and the three depths stay the look's.
- **A kind of part.** Every part has its slot on `StudioThemeData` (`buttonStyle`, `litButtonStyle`,
  `textFieldStyle`, `switchStyle`, …), each a `StudioStyle` of `WidgetStateProperty`s.
- **One part.** Every part takes `style:`.

`textureStrength` (0 to 1) sets how strongly the metal shows its brush; the brush always goes in high contrast. The
typeface is a `StudioTypeface`. The primitives the parts are drawn with are public: `StudioSurface`, `StudioFace`,
`AnimatedStudioSurface`, `StudioLamp`, `StudioReadout`, `StudioGroove`, `StudioLegend`.

## Fonts

Studio bundles Barlow (SIL Open Font License 1.1); the licence is in `assets/fonts/LICENSES/`.
