# gloss_ui

Gloss is a skeuomorphic Flutter component library with glazed buttons, recessed fields, and porcelain panels.
It includes forms, navigation, calendars, charts, dialogs, and matching light and dark themes.

![Gloss's Today screen on a desk at 1440 and on a phone at 390, by day](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/gloss_ui/screenshots/hero.webp)

**[Live gallery](https://wenkaifan0720.github.io/flutter_design_systems/gloss/)** · [API reference](https://pub.dev/documentation/gloss_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/)

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
You can also install the theme with the builder of a `CupertinoApp` or `WidgetsApp`.

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

## Platforms

Gloss supports Android, iOS, web, macOS, Windows, and Linux.

## Accessibility

Use Tab to reach a control and the arrow keys to move within tabs, ratings, and wheels.
Keyboard focus sharpens the reflection on a glazed control. On a recessed field, the light catches its inner edge. Charts expose values to screen readers and scale axis labels with
system text size. Dialogs, sheets, tabs, and toasts respect reduced motion.

## Right to left and languages

Controls follow the ambient `Directionality`. Add `DesignLocalizations.delegate` to your app for
localized control labels. Use `glossPlural` for phrases that depend on a count.

## Licence

The package uses the BSD 3-Clause License. Plus Jakarta Sans uses the SIL Open Font License 1.1.
Lucide icons use the ISC and MIT licenses. Full notices are in `THIRD_PARTY_NOTICES/`.
