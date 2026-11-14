/// Shared host for the Minimal gallery's demo screens.
///
/// Every demo renders inside the same environment a Minimal page gets — a
/// MaterialApp under [MinimalHost], themed by the preset in theme.dart (which
/// the lab rewrites when a preset is picked) — with the appearance pinned
/// explicitly, because the preview host ignores the shell's simulated
/// platform brightness.
///
/// Demos import ONLY the Minimal barrel (plus this file and the icons), so
/// the gallery doubles as proof that the public API surface is sufficient
/// to author with.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'theme.dart';

export 'habit_form.dart' show KitNewHabitPage;
export 'habit_page.dart' show KitHabitPage;
export 'today_page.dart' show KitTodayPage;

/// A demo screen: a scrolling page of labeled sections, one per variant or
/// state, under a root [MinimalAppBar] titled [title]. [body] replaces the
/// sections for a demo that lays out its own page; [bottom] docks a footer
/// under the scroll (an action bar). [padding] and [scroll] pass to the
/// [MinimalScaffold]: a full-bleed demo passes `EdgeInsets.zero`, and one that
/// owns its scrolling (a `CustomScrollView` of slivers) `scroll: false`.
/// [grow] marks a [body] that lays out at its own height (a scroll view
/// that shrink-wraps on an example page): there it stands in a [KitPhone]
/// as tall as it is, never cut at a fixed window's foot.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
  Widget? body,
  Widget? bottom,
  EdgeInsets? padding,
  bool scroll = true,
  bool grow = false,
}) {
  assert(body == null || sections.isEmpty, 'sections or body, not both');
  if (kitEmbedded && body == null && bottom == null && scroll) {
    return KitEmbeddedScreen(title: title, sections: sections);
  }
  if (kitEmbedded && grow && body != null && bottom == null) {
    return KitPhone(
      title: title,
      padding: scroll ? padding ?? MinimalInsets.screen : EdgeInsets.zero,
      child: body,
    );
  }
  final app = _kitApp(
    brightness: brightness,
    home: MinimalScaffold(
      topBar: MinimalAppBar(title: title, subtitle: kitMeta),
      padding: padding,
      scroll: scroll,
      footer: bottom,
      body:
          body ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, section) in sections.indexed) ...[
                if (i > 0) const MinimalGap(MinimalSpacing.s32),
                section,
              ],
            ],
          ),
    ),
  );
  return kitEmbedded ? KitWindow(child: app) : app;
}

/// A demo that is its own whole surface (a shell with live tabs, a route
/// stack): the themed app around exactly the widget the demo builds. On an
/// example page it stands in a [KitWindow] under its [title], [height]
/// tall (a phone screen's by default).
Widget kitSurface({
  required Brightness brightness,
  required Widget child,
  String? title,
  double height = KitWindow.phone,
}) {
  final app = _kitApp(brightness: brightness, home: child);
  return kitEmbedded
      ? KitWindow(title: title, height: height, child: app)
      : app;
}

/// Set by the package example: a demo screen hands its sections to the
/// example's page (under the example's own bar and navigation) instead of
/// mounting an app of its own, and a demo that is its own surface shows in
/// a [KitWindow]. The standalone gallery leaves it false.
bool kitEmbedded = false;

/// A demo screen's sections on an example page: its title as the band's
/// heading, then the sections.
class KitEmbeddedScreen extends StatelessWidget {
  /// The sections of the demo titled [title].
  const KitEmbeddedScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  /// The demo's title, the band's heading.
  final String title;

  /// The demo's sections, in order.
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: t.h3)),
        const MinimalGap(MinimalSpacing.s16),
        for (final (i, section) in sections.indexed) ...[
          if (i > 0) const MinimalGap(MinimalSpacing.s24),
          section,
        ],
      ],
    );
  }
}

/// A demo that is its own app (a shell with its tabs, a route stack, a
/// whole screen), framed at a phone's height on an example page; under a
/// [KitDesk], a laptop window's: the whole column wide at [deskHeight].
/// With a [title] the window stands under it, headed as a demo's sections
/// are ([KitEmbeddedScreen]).
class KitWindow extends StatelessWidget {
  /// [child] in the window, [height] tall (a phone screen's by default).
  const KitWindow({
    super.key,
    required this.child,
    this.height = phone,
    this.title,
  });

  /// The demo's own app.
  final Widget child;

  /// The window's height.
  final double height;

  /// The demo's title, its heading over the window; null heads it with
  /// nothing.
  final String? title;

  /// A phone screen's height.
  static const double phone = 680;

  /// The widest a phone's window stands.
  static const double width = 430;

  /// The window's height under a [KitDesk]: a laptop window's.
  static const double deskHeight = 800;

  @override
  Widget build(BuildContext context) {
    final desk = KitDesk.of(context);
    final window = Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desk ? double.infinity : width),
        child: SizedBox(
          height: desk ? deskHeight : height,
          child: _KitFrame(child: child),
        ),
      ),
    );
    final title = this.title;
    if (title == null) return window;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.minimalTheme.h3),
        ),
        const MinimalGap(MinimalSpacing.s16),
        window,
      ],
    );
  }
}

/// A phone's screen as tall as what it shows: the demo's bar titled
/// [title], then [child] in [padding], in the window's frame on an example
/// page. For a demo screen whose page would run past a fixed window's foot:
/// the example page scrolls it instead, so nothing is cut.
class KitPhone extends StatelessWidget {
  /// [child] under the bar titled [title].
  const KitPhone({
    super.key,
    required this.title,
    required this.child,
    this.padding = MinimalInsets.screen,
  });

  /// The demo's title, on its bar.
  final String title;

  /// The page's body, at its own height.
  final Widget child;

  /// Space round [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: KitWindow.width),
      child: _KitFrame(
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MinimalAppBar(title: title, subtitle: kitMeta),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The window's frame: the ground, clipped to the large corner, its
/// hairline painted over what it holds.
class _KitFrame extends StatelessWidget {
  const _KitFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final frame = t.shapes.large.copyWith(
      side: BorderSide(color: t.border, width: t.hairline),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: t.background,
        shape: frame.copyWith(side: BorderSide.none),
      ),
      foregroundDecoration: ShapeDecoration(shape: frame),
      child: child,
    );
  }
}

/// A bordered stage of [height] that stands [page] on a real route: the
/// first page of its own navigator, or pushed over a blank one. The page is
/// clipped to the frame's corners and the hairline paints above it, so a
/// bar's own bottom rule and the frame's meet as one line.
class KitRouteFrame extends StatelessWidget {
  /// [page] on a route, in a frame [height] tall.
  const KitRouteFrame({
    super.key,
    required this.height,
    required this.page,
    this.pushed = false,
  });

  /// The frame's height.
  final double height;

  /// The page the route shows.
  final Widget page;

  /// Whether the page is pushed over another (so it shows Back).
  final bool pushed;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final radius = BorderRadius.circular(t.cardRadius);
    return Container(
      height: height,
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: t.border, width: t.hairline),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: Navigator(
            pages: [
              if (pushed) const MaterialPage<void>(child: SizedBox.expand()),
              MaterialPage<void>(child: page),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      ),
    );
  }
}

/// Set by the package example around an app screen on a wide page: the
/// [KitWindow]s under it stand as a laptop's window rather than a phone, so
/// the screen lays itself out for the width (the shell's rail, a sheet page
/// centred, master and detail side by side).
class KitDesk extends InheritedWidget {
  /// Marks the windows under [child] as a laptop's.
  const KitDesk({super.key, required super.child});

  /// Whether [context] stands under a [KitDesk].
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitDesk>() != null;

  @override
  bool updateShouldNotify(KitDesk oldWidget) => false;
}

/// The demo bar's meta: the system and the applied preset
/// (`minimal · ember`), for a demo that draws its own bar.
String get kitMeta => 'minimal · $kitPreset';

/// The theme the package example's Customize panel sets: the knobs over
/// the preset, in [brightness]. Null (the standalone gallery, and the
/// example until a knob moves) shows the preset as designed.
MinimalThemeData Function(Brightness brightness)? kitShownTheme;

/// The applied preset's theme in [brightness], for a demo that mounts its
/// own host or preview: [kitShownTheme]'s when set.
MinimalThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    MinimalThemeData.preset(kitPreset, brightness);

/// A demo's own app. Its locale would set the direction again under it
/// (English reads left to right), so it reads the way the page around it
/// does: right to left when the example is turned that way.
Widget _kitApp({required Brightness brightness, required Widget home}) =>
    Builder(
      builder: (page) {
        final direction = Directionality.maybeOf(page);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final host = MinimalHost(
              light: kitTheme(Brightness.light),
              dark: kitTheme(Brightness.dark),
              brightness: brightness,
              child: child ?? const SizedBox.shrink(),
            );
            return direction == null
                ? host
                : Directionality(textDirection: direction, child: host);
          },
          home: home,
        );
      },
    );

/// One labeled variant band inside a demo screen: the uppercase group
/// label, then its children with a row's breath between them.
Widget kitSection(String label, {required List<Widget> children}) => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: t.label),
        const MinimalGap(MinimalSpacing.s12),
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const MinimalGap(MinimalSpacing.s12),
          child,
        ],
      ],
    );
  },
);

/// A row of demo children that wraps instead of overflowing the phone.
Widget kitRow(List<Widget> children) => Wrap(
  spacing: MinimalSpacing.s8,
  runSpacing: MinimalSpacing.s8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

/// A list or strip that stands as it would on a full-bleed page
/// (`MinimalScaffold(padding: EdgeInsets.zero)`), by the kit's rule for a
/// list's rules. On a phone page, where the column spans the window but
/// for its gutters, [child] is laid out a gutter wider on each side, so its
/// rules run edge to edge. In a column narrower than the window (a laptop's
/// measure) it stands in the column: its rules stop on the column's
/// keylines, and nothing reaches into the page's gutter or meets the
/// sidebar's rule. A row inside pads its sides by [KitBleed.inset], so its
/// words stand on the column's keyline either way.
class KitBleed extends StatelessWidget {
  /// [child], edge to edge on a phone page, in the column otherwise.
  const KitBleed({super.key, required this.child});

  /// The list or strip.
  final Widget child;

  /// The side padding a row in a [KitBleed] takes: the gutter where the
  /// list runs edge to edge, none where it stands in the column. Outside
  /// one (a specimen on its stage), the gutter.
  static EdgeInsets inset(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KitBleedScope>()?.inset ??
      MinimalInsets.gutter;

  @override
  Widget build(BuildContext context) {
    final window = MediaQuery.sizeOf(context).width;
    return LayoutBuilder(
      builder: (context, column) {
        final wide = column.maxWidth + 2 * MinimalChromeMetrics.gutter;
        if (wide < window - 0.5) {
          return _KitBleedScope(inset: EdgeInsets.zero, child: child);
        }
        // Laid out a gutter wider on each side, centred: it paints past
        // the column's edges, while its own box keeps the column's width.
        return FractionallySizedBox(
          widthFactor: wide / column.maxWidth,
          child: _KitBleedScope(inset: MinimalInsets.gutter, child: child),
        );
      },
    );
  }
}

/// The side padding a [KitBleed] hands its rows.
class _KitBleedScope extends InheritedWidget {
  const _KitBleedScope({required this.inset, required super.child});

  final EdgeInsets inset;

  @override
  bool updateShouldNotify(_KitBleedScope oldWidget) => inset != oldWidget.inset;
}

/// A month's measure: seven 44 px days, the width a [MinimalCalendar]
/// keeps.
const double kitMonthWidth = 7 * MinimalLayout.minHitTarget;

/// [calendar] (an inline date picker, which would span a phone's column or
/// a control's 320) held to [kitMonthWidth] on its start, so every month on
/// a page shares its day columns and its arrows with a [MinimalCalendar]'s.
Widget kitMonth(Widget calendar) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: kitMonthWidth),
    child: calendar,
  ),
);

/// A line of explanation under a section, in the quiet ink.
Widget kitNote(String text) => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Text(text, style: t.bodySmall.c(t.mutedForeground));
  },
);

/// Where a catalog specimen sits on its stage — so also the part of the
/// phone the lab keeps of it (the specimen's `frame` in the module's
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

/// The stage a catalog specimen renders on
/// (docs/architecture/component-catalog.md): the host themed by [style] —
/// a preset resolved at runtime, so one compile draws every preset — in
/// [brightness], on the page ground, with [child] placed by [frame]. Edge
/// chrome docks on its edge, so a bar lays out over the real safe area.
///
/// A specimen builder never names a style: the stage decides it.
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, home) => MinimalHost(
    light: MinimalThemeData.preset(style, Brightness.light),
    dark: MinimalThemeData.preset(style, Brightness.dark),
    brightness: brightness,
    child: home ?? const SizedBox.shrink(),
  ),
  home: _KitStage(frame: frame, child: child),
);

class _KitStage extends StatelessWidget {
  const _KitStage({required this.frame, required this.child});

  final KitFrame frame;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.minimalTheme.background,
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
            horizontal: MinimalChromeMetrics.gutter,
          ),
          child: child,
        ),
      ),
      _KitPlace.screen => child,
    },
  );
}
