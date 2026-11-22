# gloss_ui

Gloss is a skeuomorphic Flutter component library with glazed buttons, recessed fields, and porcelain panels.
It includes forms, navigation, calendars, charts, dialogs, and matching light and dark themes.

![Gloss's Today screen on a desk at 1440 and on a phone at 390, by day](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/gloss_ui/screenshots/hero.webp)

**[Live gallery](https://wenkaifan0720.github.io/flutter_design_systems/gloss/)** · [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/gloss/) · [API reference](https://pub.dev/documentation/gloss_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/)

## Install

```sh
flutter pub add gloss_ui material_ui
```

The example uses `MaterialApp` from `material_ui`.

## Quick start

Load the bundled font before `runApp`. Wrap the navigator in `GlossTheme` using your app's
`builder` so routes and overlays share the same colors and typography. Add `GlossToaster` to show toasts.

```dart
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await glossLoadFonts();
  runApp(
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: glossPageTransitions,
        ),
      ),
      builder: (context, child) => GlossTheme(
        data: GlossThemeData.jade(MediaQuery.platformBrightnessOf(context)),
        child: GlossToaster(child: child!),
      ),
      home: const TodayPage(),
    ),
  );
}

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) => GlossScaffold(
    body: Center(
      child: GlossButton.filled('Start cooking', onPressed: () {}),
    ),
  );
}
```

`glossPageTransitions` supplies page transitions on each platform, including the iOS swipe-back gesture.

Under a `CupertinoApp` (from `cupertino_ui`, which an app adds itself) or a bare `WidgetsApp`, the theme goes in the
same place:

```dart
import 'package:cupertino_ui/cupertino_ui.dart';

CupertinoApp(
  builder: (context, child) => GlossTheme(
    data: GlossThemeData.light(),
    child: GlossToaster(child: child!),
  ),
  home: const TodayPage(),
);

WidgetsApp(
  color: const Color(0xFF2E9E7A),
  builder: (context, _) => GlossTheme(
    data: GlossThemeData.dark(),
    child: const GlossToaster(child: TodayPage()),
  ),
);
```

## Components

- **Forms** include text, password, search and tag fields, date and range pickers, switches, sliders and steppers.
- **Navigation** includes tabs, a bottom bar, a rail, and a sidebar. `GlossAppShell` selects a layout for the window width.
- **Data display** includes lists, tables, cards, sparklines, and line, area, bar and pie charts.
- **Overlays** include dialogs, sheets, menus, popovers, tooltips, and toasts.

The example app, Simmer, uses these widgets to plan meals, adjust recipe servings, and manage a shopping list.

![Simmer's recipe view and servings stepper on desktop and phone](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/gloss_ui/screenshots/recipe.webp)

## Customize the theme

Use `GlossThemeData.jade(Brightness.dark)` for the dark palette. Use `GlossThemeData.from(gel: color)`
for a custom primary color. The factory adjusts the gel color to keep its white label readable.
Theme defaults cover typography, density, and component styles. Widgets with a `style` parameter
can override them locally.

```dart
// A coral gel for the one action; its label stays readable.
final theme = GlossThemeData.from(gel: const Color(0xFFE4572E));

// The same theme, denser, for a desk app.
final dense = theme.copyWith(density: GlossDensity.compact);
```

## Platforms

Gloss supports Android, iOS, web, macOS, Windows, and Linux.

## Accessibility

Use Tab to reach a control and the arrow keys to move within tabs, ratings, and wheels.
Keyboard focus sharpens the reflection on a glazed control; a recessed field lights its rim jade. Charts expose values to screen readers and scale axis labels with
system text size. Dialogs, sheets, tabs, and toasts respect reduced motion.

## Right to left and languages

Controls follow the ambient `Directionality`. Add `RawWidgetsLocalizations.delegate` to your app for
control labels in ui_core's 30 languages. Use `glossPlural` for phrases that depend on a count.

## Requirements

Flutter 3.47.0 or later (Dart 3.13), on Android, iOS, web, macOS, Windows and Linux.

## Licence

The package uses the BSD 3-Clause License. Plus Jakarta Sans uses the SIL Open Font License 1.1.
Lucide icons use the ISC and MIT licenses. Full notices are in `THIRD_PARTY_NOTICES/`.
