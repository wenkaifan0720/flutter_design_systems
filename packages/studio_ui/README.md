# studio_ui

Studio is a Flutter design system for audio and media apps. It includes transport controls, faders, meters, charts, and a full set of navigation and form widgets in coordinated light and dark themes.

![Roomtone, Studio's example podcast app, by day: its home at 1440 px beside the same page on a 390 px phone](https://raw.githubusercontent.com/wenkaifan0720/flutter_design_systems/main/packages/studio_ui/screenshots/hero_home_day.webp)

**[Live gallery](https://wenkaifan0720.github.io/flutter_design_systems/studio/)** · [Docs](https://wenkaifan0720.github.io/flutter_design_systems/docs/looks/studio/) · [API reference](https://pub.dev/documentation/studio_ui/latest/) · [All the looks](https://wenkaifan0720.github.io/flutter_design_systems/)

## Getting started

The example below uses `MaterialApp` from `material_ui`. Add both packages, then load the bundled fonts before the first frame.

```sh
flutter pub add studio_ui material_ui
```

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

`StudioHost` installs the theme, chassis and toast overlay. Add `studioPageTransitions` to a Material theme to use Studio's transitions and the iOS back gesture.

### CupertinoApp and WidgetsApp

`StudioHost` goes in the builder of any app widget. With `CupertinoApp` from `cupertino_ui`:

```dart
CupertinoApp(
  builder: (context, child) => StudioHost(child: child!),
  home: const LibraryPage(),
)
```

With Flutter's `WidgetsApp`, which has no page route of its own, give it one:

```dart
WidgetsApp(
  color: const Color(0xFF2B2D30),
  builder: (context, child) => StudioHost(child: child!),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: const LibraryPage(),
)
```

With a router (go_router, say), return a `StudioPage` from a route's `pageBuilder` for Studio's transition.

## Building a screen

Use `StudioAppShell` with `StudioTab` destinations for top-level navigation. The shell uses a bottom key bank below 600 logical pixels, a rail from 600, and a side panel from 1024. A `StudioScreen` arranges the app bar, body and optional footer. Use `StudioDisplay` for readable content on smooth glass.

A form's everyday parts take `value` and `onChanged`; a null `onChanged` or `onPressed` turns a part off.

```dart
Column(
  children: [
    StudioTextField(labelText: 'Episode title', onChanged: (v) => title = v),
    StudioSelect<String>(
      labelText: 'Quality',
      value: quality,
      items: const [
        StudioSelectItem(value: 'high', label: 'High'),
        StudioSelectItem(value: 'low', label: 'Low'),
      ],
      onChanged: (v) => setState(() => quality = v),
    ),
    StudioSwitch(
      value: notify,
      onChanged: (v) => setState(() => notify = v),
      semanticLabel: 'New episodes',
    ),
    StudioButton.lit('Publish', onPressed: publish),
  ],
)
```

For a destructive confirmation, pass `isAlert: true` to `showStudioDialog` and mark the act that destroys:

```dart
final discard = await showStudioDialog<bool>(
  context: context,
  isAlert: true,
  builder: (context) => StudioDialog(
    title: 'Discard this take?',
    content: const Text('The 4 minutes you recorded will be gone.'),
    actions: [
      StudioButton('Keep', onPressed: () => Navigator.pop(context, false)),
      StudioButton.lit(
        'Discard',
        isDestructiveAction: true,
        onPressed: () => Navigator.pop(context, true),
      ),
    ],
  ),
);
```

## Customizing Studio

Set the indicator and panel finish with `StudioThemeData.from`, and hand `StudioHost` a theme for each brightness:

```dart
StudioHost(
  theme: StudioThemeData.from(indicator: const Color(0xFF4FD1C5)),
  darkTheme: StudioThemeData.from(
    indicator: const Color(0xFF4FD1C5),
    brightness: Brightness.dark,
  ),
  child: child!,
)
```

The corners, the light from the top and the depths of the metal stay Studio's. Set a component style such as `buttonStyle` or `textFieldStyle` on the theme to apply it throughout an app, or pass a `StudioStyle` to an individual widget. Its state properties can change with focus, selection or a press.

`textureStrength` controls the grain on metal surfaces. High-contrast mode removes the grain. Build custom controls with the same materials using `StudioSurface`, `StudioFace`, `StudioLamp` and `StudioReadout`.

## Accessibility

Every part reads to a screen reader with its role and name; an icon key takes a `tooltip` for its name. The keyboard's focus lights the part's lamp or edge and shows for the keyboard only. Tab visits a key bank, a tab bar or a set of radios once, and the arrows move within it. A dialog keeps focus inside and returns it to its opener. Text scales to 200%: labels wrap and keys grow. Motion runs on springs through ui_core's `RawMotionPolicy`, which honours Reduce Motion, and high-contrast mode takes the grain off the metal.

## Languages and right to left

Labels the parts say themselves (Cancel, Search, a picker's months) come from ui_core's `RawWidgetsLocalizations`, in 30 languages, and follow the app's locale with nothing to set up. Studio's own counts come from `StudioLocalizations`, in English; for another language, extend `DefaultStudioLocalizations` and add a delegate for it to `localizationsDelegates`. In a right-to-left locale every layout mirrors, and the charts write Arabic-Indic digits in Arabic.

## Requirements

Flutter 3.47.0 or later. Studio runs on Android, iOS, the web, macOS, Windows and Linux.

## Fonts

Studio bundles Barlow and Noto Sans Arabic under the SIL Open Font License 1.1. Chart labels use Noto Sans Arabic for Arabic letters and digits that Barlow lacks. Both licenses are included in `assets/fonts/LICENSES/`.
