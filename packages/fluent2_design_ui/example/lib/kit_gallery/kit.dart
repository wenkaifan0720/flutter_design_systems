/// Shared host for the Fluent 2 gallery's demo screens and component
/// specimens, and the sample owner, tabs and people they show (a small
/// team's workspace, Northwind).
///
/// Every demo renders inside the environment a Fluent 2 page gets live: a
/// MaterialApp under [Fluent2Host], themed by the preset the lab applied
/// (theme.dart's [kitPreset]), with the appearance pinned explicitly
/// because the preview host ignores the shell's simulated platform
/// brightness, and the owner's account ([kitInes]) above the navigator as
/// an app mounts it.
///
/// Demos import ONLY the Fluent 2 barrel, this file, Flutter and the packages
/// Fluent 2 depends on.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import 'theme.dart';

export 'northwind.dart' show KitNorthwind, KitNorthwindRoot;
export 'photo.dart' show kitPhoto;

/// A demo screen: a scrolling nav root titled [title], with labelled
/// sections, one per variant or state. [footer] pins a widget under the
/// scroll; [body] replaces the sections for demos that own their layout.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
  Widget? body,
  Widget? footer,
}) {
  assert(body == null || sections.isEmpty, 'sections or body, not both');
  return _kitApp(
    brightness: brightness,
    home: Fluent2Scaffold(
      topBar: Fluent2AppBar(title: title),
      footer: footer,
      body:
          body ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in sections) ...[
                section,
                const Fluent2Gap(Fluent2Spacing.xxl),
              ],
            ],
          ),
    ),
  );
}

/// A demo that is its own whole surface (a route stack): the themed app
/// around exactly the widget the demo builds.
Widget kitSurface({required Brightness brightness, required Widget child}) =>
    _kitApp(brightness: brightness, home: child);

/// The preset the gallery shows: [kitPreset] unless the example app's
/// band picks another.
String kitShownPreset = kitPreset;

/// The themes the gallery shows, by appearance: the shown preset's, unless
/// the package's example app (its Customize panel) or a test gives its own.
Fluent2ThemeData Function(Brightness brightness)? kitShownTheme;

/// The reading direction the gallery shows: left to right unless the example
/// app's band (or a test) picks right to left.
TextDirection kitShownDirection = TextDirection.ltr;

/// The text scale the gallery shows: the platform's unless the example app's
/// link asks for one (`text=200`).
double? kitShownTextScale;

/// The shown preset's theme in [brightness], for demos that mount their own
/// host (a [Fluent2Preview]).
Fluent2ThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    Fluent2ThemeData.preset(kitShownPreset, brightness);

Widget _kitApp({required Brightness brightness, required Widget home}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Northwind',
      builder: (context, child) => Directionality(
        textDirection: kitShownDirection,
        child: _kitTextScale(
          context,
          Fluent2Host(
            light: kitTheme(Brightness.light),
            darkData: kitTheme(Brightness.dark),
            brightness: brightness,
            child: Fluent2AccountScope(
              account: kitInes,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      home: home,
    );

/// A variant's name in words, as a page shows it: `extraLarge` reads
/// "Extra large", `subtleCircular` "Subtle circular".
String kitSay(Enum value) {
  final words = value.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => ' ${m[0]!.toLowerCase()}',
  );
  return words[0].toUpperCase() + words.substring(1);
}

/// One labelled variant band inside a demo screen. Its repaint boundary,
/// keyed `kit-section/<label>`, is what a section's golden captures.
Widget kitSection(String label, {required List<Widget> children}) =>
    RepaintBoundary(
      key: ValueKey('kit-section/$label'),
      child: Builder(
        builder: (context) {
          final t = context.fluent2Theme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: t.caption1Strong.c(t.textSecondary)),
              const Fluent2Gap(Fluent2Spacing.m),
              for (final child in children) ...[
                child,
                const Fluent2Gap(Fluent2Spacing.m),
              ],
            ],
          );
        },
      ),
    );

/// A row of demo children that wraps instead of overflowing the phone.
Widget kitRow(List<Widget> children) => Wrap(
  spacing: Fluent2Spacing.m,
  runSpacing: Fluent2Spacing.m,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

/// A demo that is its own routed app (a shell over a go_router): the
/// themed app around [router], the owner's account above it.
Widget kitRouterApp({
  required Brightness brightness,
  required RouterConfig<Object> router,
}) => MaterialApp.router(
  debugShowCheckedModeBanner: false,
  title: 'Northwind',
  routerConfig: router,
  builder: (context, child) => Directionality(
    textDirection: kitShownDirection,
    child: _kitTextScale(
      context,
      Fluent2Host(
        light: kitTheme(Brightness.light),
        darkData: kitTheme(Brightness.dark),
        brightness: brightness,
        child: Fluent2AccountScope(
          account: kitInes,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  ),
);

/// [child] as a route of [register] draws it (a pushed page's bar, a sheet
/// page's head), for a still that stands on no route of its own.
Widget kitInRegister(RoutePresentation register, Widget child) =>
    RoutePresentationScope(presentation: register, child: child);

/// Northwind's four root tabs, regular glyphs at rest and filled ones
/// selected, as Fluent's navigation draws them.
const List<Fluent2NavItem> kitTabs = [
  Fluent2NavItem(Fluent2Icons.home, 'Home', null, Fluent2Icons.homeFilled),
  Fluent2NavItem(Fluent2Icons.chat, 'Chat', null, Fluent2Icons.chatFilled),
  Fluent2NavItem(
    Fluent2Icons.calendarLtr,
    'Calendar',
    null,
    Fluent2Icons.calendarLtrFilled,
  ),
  Fluent2NavItem(Fluent2Icons.folder, 'Files', null, Fluent2Icons.folderFilled),
];

/// The owner, as the chrome draws her. Her profile and notifications are
/// pages the gallery doesn't have, so they open nothing; they're still
/// given, as an app gives them, so the avatar and the bell draw live.
const kitInes = Fluent2Account(
  name: 'Ines Duarte',
  initials: 'ID',
  meta: 'ines@northwind.example',
  unread: 3,
  onProfile: _openNothing,
  onNotifications: _openNothing,
);

void _openNothing(BuildContext context) {}

/// The people the demos name.
const List<Fluent2AvatarPerson> kitPeople = [
  Fluent2AvatarPerson('Ines Duarte'),
  Fluent2AvatarPerson('Kai Tanaka'),
  Fluent2AvatarPerson('Mara Okafor'),
  Fluent2AvatarPerson('Tomas Lindqvist'),
  Fluent2AvatarPerson('Priya Raman'),
  Fluent2AvatarPerson('Noor Haddad'),
];

/// Where a component specimen sits on its stage (the specimen's `frame` in
/// metadata.yaml names the same band): the bottom or top edge, a band
/// across the middle, or the whole phone.
class KitFrame {
  const KitFrame.bottom(double this.height) : _place = _KitPlace.bottom;
  const KitFrame.top(double this.height) : _place = _KitPlace.top;
  const KitFrame.band(double this.height) : _place = _KitPlace.band;
  const KitFrame.screen() : height = null, _place = _KitPlace.screen;

  /// The band's height in logical px; null for the whole phone.
  final double? height;
  final _KitPlace _place;
}

enum _KitPlace { bottom, top, band, screen }

/// The stage a component specimen renders on: the host themed by [style] (a
/// preset resolved at runtime, so one compile draws every preset) in
/// [brightness], on the page ground, the owner's account above it, with
/// [child] placed by [frame]. A specimen builder never names a style: the
/// stage decides it.
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Northwind',
  builder: (context, home) => Directionality(
    textDirection: kitShownDirection,
    child: _kitTextScale(
      context,
      Fluent2Host(
        light: Fluent2ThemeData.preset(style, Brightness.light),
        darkData: Fluent2ThemeData.preset(style, Brightness.dark),
        brightness: brightness,
        child: Fluent2AccountScope(
          account: kitInes,
          child: home ?? const SizedBox.shrink(),
        ),
      ),
    ),
  ),
  home: _KitStage(frame: frame, child: child),
);

class _KitStage extends StatelessWidget {
  const _KitStage({required this.frame, required this.child});

  final KitFrame frame;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.fluent2Theme.background,
    child: switch (frame._place) {
      _KitPlace.bottom => Stack(
        fit: StackFit.expand,
        children: [Positioned(left: 0, right: 0, bottom: 0, child: child)],
      ),
      _KitPlace.top => Stack(
        fit: StackFit.expand,
        children: [Positioned(left: 0, right: 0, top: 0, child: child)],
      ),
      // A band sits on the page's own gutter, as it would in a body.
      _KitPlace.band => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Fluent2ChromeMetrics.gutter,
          ),
          child: child,
        ),
      ),
      _KitPlace.screen => child,
    },
  );
}

/// [child] at the gallery's shown text scale, when a link asks for one.
Widget _kitTextScale(BuildContext context, Widget child) {
  final scale = kitShownTextScale;
  if (scale == null) return child;
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child,
  );
}
