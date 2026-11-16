# civic_ui

A Flutter design system for public services, where the job is that anyone, on any device, in a hurry or with a
disability, can finish the task. One thing per page. Large type in Atkinson Hyperlegible Next, drawn so that letters
people confuse look different, on short lines. One accent for each job: blue to act, red for an error, green for done,
yellow for where the keyboard is. White cards on a cool ground, no strokes round them, corners a little rounded; the
strong ink edge is a field's alone, and only what floats casts a soft shadow.

On a phone and a tablet it is an app: its own top bar with the way back and the page's place, lists as rows on cards
(each pressed whole, a chevron at its end, its status under its title), the page's action kept at its foot while the
page scrolls, the places along the bottom on a phone and in a rail on a tablet, a tablet's list and the open record
side by side. From 1024 wide it is the service's site: the masthead, the side navigation, one measured column.

Its three moves:

- **The focus bar.** Wherever the keyboard is, it shows: a button or a link floods yellow over a thick ink bar, a box
  to write in keeps its white inside a yellow ring around a doubled edge.
- **The question page.** One question per page, asked in the heading, its answers under it with their hints, a back
  link above and a button that says what happens next.
- **The answers summary.** Before anything is sent, every answer is set out to check, each with a Change link that a
  screen reader hears in full ("Change date of birth").

Errors are said in words twice: in a summary at the top of the page, which takes the focus and links to each field,
and at the field, which stands on the error rule. Every part works at 200% text, right to left, with a screen reader
and with the keyboard alone; targets are 48 points for a finger and 24 for a pointer at the least.

The parts take the parameters a Flutter developer expects: a press is `onPressed`, a row's tap `onTap`, a control is
`value` with `onChanged`, a destination is `selectedIndex` with `onDestinationSelected`, a field has `labelText`,
`helperText`, `errorText` and `hintText`, and a null callback disables.

## Install

```yaml
dependencies:
  civic_ui: ^0.1.0
```

## Use

`CivicTheme` is the whole install. Put it in your app's `builder:`, under a `MaterialApp`, a `CupertinoApp` or a
`WidgetsApp`; Civic has no app widget of its own. Put `CivicToaster` under it to show toasts. On a `MaterialApp`, put
`civicPageTransitions` in its theme too, so every page it pushes changes as Civic's do (nothing travels) on every
platform. On iOS the map keeps the swipe back from the screen's leading edge round Civic's page change, as
`CivicPageRoute` does; an app that builds a map of its own wraps its iOS entry the same way:

```dart
const Map<TargetPlatform, PageTransitionsBuilder> transitions = {
  TargetPlatform.android: CivicPageTransitions(),
  // iOS's swipe back from the screen's edge, round Civic's page change.
  TargetPlatform.iOS: DesignSwipeBackPageTransitionsBuilder(CivicPageTransitions()),
  TargetPlatform.macOS: CivicPageTransitions(),
  // ...
};
```

`designSwipeBack(map)` does the same to a map built at run time.

```dart
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await civicLoadFonts(); // the first frame is set in Civic's faces
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(builders: civicPageTransitions),
    ),
    builder: (context, child) => CivicTheme(
      data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? CivicThemeData.dark()
          : CivicThemeData.light(),
      child: CivicToaster(child: child!),
    ),
    home: const VehiclePage(),
  );
}

class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  String? _vehicle;

  @override
  Widget build(BuildContext context) => CivicScaffold(
    topBar: const CivicTopBar(title: 'Parking permits'),
    body: CivicPageBody(
      backLink: CivicBackLink(onPressed: () => Navigator.of(context).maybePop()),
      caption: 'Step 1 of 3',
      children: [
        CivicRadioGroup<String>(
          labelText: 'What kind of vehicle is the permit for?',
          isPageHeading: true,
          groupValue: _vehicle,
          onChanged: (value) => setState(() => _vehicle = value),
          children: const [
            CivicRadio(value: 'car', labelText: 'Car or van'),
            CivicRadio(
              value: 'motorcycle',
              labelText: 'Motorcycle',
              helperText: 'Includes mopeds and scooters.',
            ),
          ],
        ),
        const SizedBox(height: 40),
        CivicButton(onPressed: () {}, child: const Text('Continue')),
      ],
    ),
  );
}
```

## Make it yours

Civic keeps what makes it trustworthy: the yellow focus over a thick ink bar, the fields' 2 pt ink edges, large type, and tap
targets of 48 for a finger and 24 for a pointer. Inside that, your service's colours, face and spacing are yours.

Your brand. Each colour is held to 7:1 against the page, darkened by day and lightened by night, its hue kept
(#0A7D4F becomes about #086640 by day and #0FB673 by night):

```dart
CivicTheme(
  data: CivicThemeData.from(
    brightness: Brightness.light,
    action: const Color(0xFF0A7D4F),
    fontFamily: 'Inter', // reaches every part and Flutter's own widgets
  ),
  child: child,
)
```

Every primary button, through its slot in the theme (each part has one, and each kind of button its own):

```dart
CivicThemeData.light().copyWith(
  primaryButtonStyle: const CivicStyle(
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 40)),
  ),
)
```

One button, through its `style:`, which wins over the theme:

```dart
CivicButton.secondary(
  style: CivicStyle(fill: WidgetStatePropertyAll(context.civicTheme.surface)),
  onPressed: () {},
  child: const Text('Save and come back later'),
)
```

A part's documentation says which slots it reads. Your own part can wear the look with `CivicFace` (a button's face
on its solid edge) and `CivicWell` (a field's box), which bring the focus with them.

## Words

Civic's parts take their own words (Back, Close) from ui_core's localizations, in 30 languages. The words of your
service (Continue, There is a problem, Step 1 of 3, Change) are yours to give, in your reader's language.

## Licences

Civic's code is MIT. Its faces are under the SIL Open Font License 1.1: Atkinson Hyperlegible Next and Mono (Braille
Institute of America) and Noto Sans Arabic (the Noto Project Authors); see `THIRD_PARTY_NOTICES/`. Its glyphs are
Lucide's (ISC). The patterns of public-service design it follows are widely shared; no code, tokens or assets of any
design system were taken.
