# appliance_ui

Appliance is a Flutter widget library with moulded keys, indicator lamps and recessed displays. It includes forms, navigation, dialogs, pickers and interactive charts in light and dark themes.

![Larder, Appliance's example shop, by day: its home page at 1440 px beside the same page on a 390 px phone](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/appliance_ui/screenshots/hero_home_day.webp)

**[Docs and demo](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/appliance/)** · [Try it in Stint](https://wenkaifan0720.github.io/flutter_design_systems/docs/stint/?look=appliance) · [API reference](https://pub.dev/documentation/appliance_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/docs/)

## Getting started

```yaml
dependencies:
  appliance_ui: ^0.5.0
```

The smallest app: `ApplianceHost` in the app's `builder` gives everything under it Appliance's theme, by day and by night as the platform is.

```dart
import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

void main() => runApp(
  WidgetsApp(
    color: const Color(0xFFEE6A26),
    builder: (context, _) => ApplianceHost(
      child: Center(child: ApplianceButton.filled('Start', onPressed: () {})),
    ),
  ),
);
```

A fuller app on Material (`flutter pub add appliance_ui material_ui`) loads the bundled Barlow font before calling `runApp`, so the first frame is set in it, and places `ApplianceHost` in the application builder so pages and overlays share the same theme. The host also works with `CupertinoApp` and `WidgetsApp`.

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

Under `CupertinoApp` (from `cupertino_ui`) or Flutter's own `WidgetsApp`, the host goes in the same place:

```dart
CupertinoApp(
  builder: (context, child) => ApplianceHost(child: child!),
  home: const HomePage(),
);
```

```dart
WidgetsApp(
  color: const Color(0xFF1F7A5C),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  builder: (context, child) => ApplianceHost(child: child!),
  home: const HomePage(),
);
```

## Navigation

`ApplianceScaffold` shows a bottom bar below 600 logical pixels, a navigation rail from 600 pixels, and a side panel from 1024 pixels. Pass the current destination in `selectedIndex` and update it in `onSelected`. The bottom bar can use a second row when destination names need more space.

![By night: Larder's orders at 1440 px, the open order with its lamp-lit progress, beside the basket on a 390 px phone](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/appliance_ui/screenshots/night_orders_basket.webp)

## Everyday parts

Controls take a value and an `onChanged`, and buttons an `onPressed`; leave the callback null to disable one.

```dart
ApplianceTextField(labelText: 'Postcode', hintText: 'e.g. EH3 9DR', controller: postcode);

ApplianceSwitch(
  value: notify,
  onChanged: (value) => setState(() => notify = value),
  semanticLabel: 'Order updates',
);

ApplianceSegmentedButton<String>(
  segments: const [
    ApplianceSegment(value: 'grid', label: 'Grid'),
    ApplianceSegment(value: 'list', label: 'List'),
  ],
  value: view,
  onChanged: (value) => setState(() => view = value),
);

ApplianceListGroup(
  header: 'Account',
  children: [ApplianceListTile(title: 'Name', trailingText: 'Rosa Lind', onTap: () {})],
);

final remove = await showApplianceDialog<bool>(
  context: context,
  builder: (context) => const ApplianceDialog(title: 'Remove this item?'),
);

showApplianceToast(context, 'Added to basket', actionLabel: 'Undo', onAction: () {});

ApplianceBarChart(
  semanticLabel: 'Items by room',
  labels: const ['Kitchen', 'Hall'],
  series: const [ApplianceChartSeries('Items', [14, 6])],
);
```

## Theming

`ApplianceHost` follows the platform brightness. Appliance comes in six finishes, each by day and by night: `warm` (the default), `mint`, `butter`, `powder`, `blush` and `slate` (`ApplianceThemeData.presets`). Hand one to the host:

```dart
ApplianceHost(
  light: ApplianceThemeData.preset('mint', Brightness.light),
  dark: ApplianceThemeData.preset('mint', Brightness.dark),
  child: child!,
);
```

For a brand's own colours, pass the result of `ApplianceThemeData.from`: the plastic is moulded toward `finish` at the look's own tones, and `signal` is the main key, the lamps and the focus, its words a tone that reads on the housing and on every faceplate and key.

```dart
final theme = ApplianceThemeData.from(
  brightness: Brightness.light,
  finish: const Color(0xFFDDE7E1),
  signal: const Color(0xFF1F7A5C),
);
```

Use `theme.copyWith(texture: false)` for smooth housing. High-contrast mode also removes the grain. Set component defaults on the theme or pass an `ApplianceStyle` to an individual control.

## Accessibility and right to left

Every part follows the app’s text direction: under a right-to-left `Directionality` the navigation, list rows, sliders, steppers and arrows mirror, and the example shop’s settings can switch the direction. Tab moves between controls, arrow keys move between tabs and rail destinations, and Escape dismisses open menus and dialogs. Slider thumbs support keyboard input and screen readers. For values with units, pass `semanticFormatterCallback` to `ApplianceSlider` or `ApplianceRangeSlider`. Controls stand at ui_core's touch floor, 40 by 40, or an app's `RawTapTargetScope`. Below 600 wide the date pickers open their month in a sheet, as Material's open full width on a phone.

## Platforms and localization

Appliance supports Android, iOS, macOS, Windows, Linux and the web. Its menus, dialogs, charts and keyboard navigation use [ui_core](https://pub.dev/packages/ui_core). Register `RawWidgetsLocalizations.delegate` with your app’s localization delegates to translate the built-in control labels. Your app supplies its own destination names, button labels and messages.

## Requirements

Flutter 3.47.0 or later (Dart 3.13), on Android, iOS, web, macOS, Windows and Linux.

## License

The package uses the MIT license. Barlow uses the SIL Open Font License 1.1. See THIRD_PARTY_NOTICES for the font and icon licenses.
