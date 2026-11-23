# material_expressive_ui

Material 3 Expressive components for Flutter. The package includes spring-animated buttons, form fields, pickers, charts and adaptive navigation. Its shapes, colour schemes and motion follow the AndroidX Compose implementation.

![Material Expressive gallery and Trip planner](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/material_expressive_ui/screenshots/hero.png)

**[Live gallery](https://wenkaifan0720.github.io/flutter_design_systems/material_expressive/)** · [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/material_expressive/) · [API reference](https://pub.dev/documentation/material_expressive_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/)

## Install

```sh
flutter pub add material_expressive_ui material_ui
```

`material_ui` is the Material library the set-up below imports for its `MaterialApp` (Flutter 3.50 deprecates `package:flutter/material.dart`). One import brings the components, their themes and ui_core, which the package re-exports:

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
```

## Set up

Load the bundled fonts before the first frame and put `ExpressiveTheme` in the app's `builder`, so routes, dialogs and menus share the theme.

```dart
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await expressiveLoadFonts();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: expressivePageTransitions,
      ),
    ),
    localizationsDelegates: const [
      DefaultRawWidgetsLocalizations.delegate,
      ExpressiveLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    builder: (context, child) => ExpressiveTheme(
      data: ExpressiveThemeData.grove(MediaQuery.platformBrightnessOf(context)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => ColoredBox(
        color: context.expressiveTheme.colors.surface,
        child: Center(
          child: ExpressiveFilledButton('Book a table', onPressed: () {}),
        ),
      ),
    ),
  );
}
```

Under a `CupertinoApp` (from `cupertino_ui`) it is the same `builder:`. A field is Flutter's Material text field underneath, so the app lists Material's localizations too:

```dart
CupertinoApp(
  localizationsDelegates: const [
    DefaultMaterialLocalizations.delegate,
    DefaultCupertinoLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  builder: (context, child) => ExpressiveTheme(
    data: ExpressiveThemeData.grove(MediaQuery.platformBrightnessOf(context)),
    child: child!,
  ),
  home: const TripsPage(),
);
```

And under a bare `WidgetsApp`, which asks for its colour and how to build a route:

```dart
WidgetsApp(
  color: const Color(0xFF2E7D5B),
  localizationsDelegates: const [
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  builder: (context, child) => ExpressiveTheme(
    data: ExpressiveThemeData.grove(MediaQuery.platformBrightnessOf(context)),
    child: child!,
  ),
  pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
  home: const TripsPage(),
);
```

## Everyday parts

Buttons take their label first, and a null `onPressed` disables them:

```dart
ExpressiveFilledButton('Save trip', onPressed: save);
ExpressiveTextButton('Cancel', onPressed: null); // disabled
```

Inputs take `value` and `onChanged`, as Flutter's do:

```dart
ExpressiveTextField(labelText: 'Trip name', onChanged: (name) => draft = name);

ExpressiveSelect<String>(
  labelText: 'Project',
  options: const [
    ExpressiveSelectOption('studio', 'Open studio'),
    ExpressiveSelectOption('launch', 'Spring launch'),
  ],
  value: project,
  onChanged: (value) => setState(() => project = value),
);

ExpressiveSwitch(
  value: reminders,
  onChanged: (on) => setState(() => reminders = on),
  semanticLabel: 'Reminders',
);
```

A dialog's actions stand in one row while they fit and stack, the confirm on top, when they don't. A destructive action takes the `error` role:

```dart
final discard = await showExpressiveDialog<bool>(
  context: context,
  builder: (context) => const ExpressiveDialog(
    title: 'Unsaved changes',
    text: 'Save your changes before leaving this trip?',
    actions: [
      ExpressiveDialogAction('Cancel'),
      ExpressiveDialogAction('Discard', value: true, isDestructiveAction: true),
      ExpressiveDialogAction('Save', value: false, filled: true),
    ],
  ),
);
```

Menus open from the control that raised them, and a destructive item reads as a loss:

```dart
showExpressiveMenu(
  context,
  entries: [
    ExpressiveMenuItem('Rename', onPressed: rename),
    ExpressiveMenuItem(
      'Delete',
      icon: ExpressiveSymbols.delete,
      isDestructiveAction: true,
      onPressed: delete,
    ),
  ],
);
```

## Themes

Choose a preset with `ExpressiveThemeData.preset(id, brightness)` or derive a colour scheme with `ExpressiveThemeData.from(seed: brand, brightness: brightness)`. The presets provide light, dark and high-contrast colours. Pass `contrastLevel: 1` for a high-contrast preset.

| Preset | Seed | Variant | Motion |
|---|---|---|---|
| `baseline` | #6750A4 | tonal spot | expressive |
| `slate` | #52667A | neutral | standard |
| `bloom` | #B5487A | vibrant | expressive |
| `grove` | #2E7D5B | tonal spot | expressive |
| `ember` | #C25A1F | expressive | expressive |

Widgets read their theme from `context.expressiveTheme`. Use `copyWith` to set density, typography, shapes, motion or a component theme. An individual widget's `style` overrides the component theme for that widget. A `WidgetStateProperty` can vary a colour or shape for focus, selection and other states. The colour roles, shapes and motion stay Material's: a theme changes their values, not what each role is for.

## Navigation

Import `package:material_expressive_ui/material_expressive_host.dart` for `ExpressiveHost`, adaptive app navigation and page transitions. `ExpressiveShellScaffold` places destinations in a bottom bar on phones and a rail on wider screens. `ExpressivePage`, `ExpressiveSheetPage` and `ExpressiveFullScreenDialogPage` work with the Navigator pages API.

## Accessibility and languages

- Every control is reachable with Tab and works with Enter or Space. Selects, comboboxes and menus take the arrow keys, Home and End, and Escape closes them and gives the focus back to what opened them. A radio group or a one-choice segmented button is one Tab stop.
- Touch targets are at least 48 dp, as Material's are. Text scales with the platform setting, and the parts Material caps (a date picker's month label at 2×) are capped the same way.
- The layout follows `Directionality`, so a right-to-left app mirrors its rows, menus and navigation.
- Use `ExpressiveLocalizations` for component text and `RawWidgetsLocalizations` for shared actions. Both include English defaults, and `ExpressiveLocalizations.delegate` takes every locale. Supply delegates for your app's other languages. Until you do, a time picker's words come from `RawWidgetsLocalizations`, which ui_core speaks in 30 languages.
- Give icon-only controls a `semanticLabel`, and give a rating a name such as “Rate this trip”, so a screen reader announces it in context.

## Custom components

To adapt a component, copy its source into your app and import `package:material_expressive_ui/material_expressive_parts.dart` for its drawing and animation helpers. Check copied components when updating the package because these helpers may change between releases.

## Example

The example app includes a Trip planner and an interactive component gallery. Switch between light and dark themes, change text size, or try right-to-left layout from the gallery settings. Run it from the repository with `cd example` and `flutter run`.

## Requirements

Flutter 3.47 or later (Dart 3.13). The package depends on ui_core ^0.4.1 and re-exports it, so `RawWidgetsLocalizations` and the `Raw*` parts come with the one import.

## Licences

The package is BSD-3-Clause. Roboto Flex and Jost use the SIL Open Font License 1.1. Material Symbols Rounded and the AndroidX graphics-shapes port use Apache 2.0. The `material_new_shapes` port uses the MIT licence. Notices ship in `LICENSE` and `THIRD_PARTY_NOTICES/`.

This is an independent implementation of Material 3 Expressive.
