// The machine around the windows: the menu bar, the phone's strip, the desk's strip and marks, and the screen that puts any
// page on a desktop so that it has a window and that window is active.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'press.dart';
import 'component_themes.dart';
import 'internal/caps.dart';
import 'internal/face.dart';

import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'glyphs.dart';

import 'controls.dart';
import 'frames.dart';
import 'heads.dart';
import 'layout.dart';
import 'pixels.dart';
import 'tell.dart' show RetroDesktopCircularProgressIndicator;
import 'theme.dart';
import 'acts.dart' show RetroDesktopButton, RetroDesktopButtonSize;
import 'localizations.dart';
import 'host.dart';

/// A place in the app: a menu in the menu bar, a button in the phone's strip.
class RetroDesktopNavItem {
  /// Creates a [RetroDesktopNavItem].
  const RetroDesktopNavItem({
    required this.label,
    required this.short,
    required this.icon,
    this.onPressed,
    this.key,
    this.badgeLabel,
  });

  /// `label` in the menu bar; `short` under the icon in the strip.
  final String label, short;

  /// An optional count or status announced with the action.
  final String? badgeLabel;

  /// The glyph shown with the content.
  final IconData icon;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The walkthrough key on its hit target.
  final Key? key;
}

class _MarkPainter extends RetroDesktopPixelPainter {
  const _MarkPainter(this.c);
  final RetroDesktopColors c;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final u = s.width / 16;
    void box(double x, double y, double w, double h, Color color) =>
        px.fill(Rect.fromLTWH(x * u, y * u, w * u, h * u), color);
    box(0, 1, 11, 10, c.text);
    box(1, 2, 9, 8, c.paper);
    box(1, 2, 9, 2, c.textSecondary);
    box(5, 6, 11, 10, c.text);
    box(6, 7, 9, 8, c.paper);
    box(6, 7, 9, 2, c.textSecondary);
    box(8, 11, 5, 1, c.textSecondary);
    box(8, 13, 3, 1, c.textSecondary);
  }

  @override
  bool shouldRepaint(_MarkPainter o) => o.c != c;
}

/// The system's own mark: two windows, one in front. Beside the app's name, and while something loads.
///
/// ```dart
/// RetroDesktopSystemMark(size: 24)
/// ```
class RetroDesktopSystemMark extends StatelessWidget {
  /// Creates a [RetroDesktopSystemMark].
  const RetroDesktopSystemMark({super.key, this.size = 16});

  /// The size of the visible face; minimum interactive reach is retained.
  final double size;
  @override
  Widget build(BuildContext context) => retroDesktopOwnSize(
    width: size,
    height: size,
    child: RetroDesktopPixelPaint(
      painter: _MarkPainter(RetroDesktopTheme.of(context).colors),
    ),
  );
}

class _BarPainter extends RetroDesktopPixelPainter {
  const _BarPainter(this.c);
  final RetroDesktopColors c;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    final h = px.hair;
    px.fillExact(r.left, r.top, r.right, r.bottom, c.platinumLight);
    px.fillExact(r.left, r.top, r.right, r.top + h, c.bevelLight);
    px.fillExact(r.left, r.bottom - 2 * h, r.right, r.bottom - h, c.bevelDark);
    px.fillExact(r.left, r.bottom - h, r.right, r.bottom, c.outline);
  }

  @override
  bool shouldRepaint(_BarPainter o) => o.c != c;
}

class _InBar extends InheritedWidget {
  const _InBar({required super.child});
  @override
  bool updateShouldNotify(_InBar old) => false;
}

class _MenuCell extends StatelessWidget {
  const _MenuCell({
    required this.child,
    this.on = false,
    this.onPressed,
    this.label,
    this.cellKey,
  });
  final Widget child;
  final bool on;
  final VoidCallback? onPressed;
  final String? label;
  final Key? cellKey;
  @override
  Widget build(BuildContext context) {
    final c = RetroDesktopTheme.of(context).colors;
    final cell = DecoratedBox(
      decoration: ShapeDecoration(
        shape: RetroDesktopTheme.of(context).shapes.small,
        color: on ? c.highlight : const Color(0x00000000),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Center(widthFactor: 1, child: child),
      ),
    );
    if (onPressed == null) return KeyedSubtree(key: cellKey, child: cell);
    return RetroDesktopPressable(
      button: true,
      selected: on,
      label: label,
      key: cellKey,
      onPressed: onPressed,
      child: cell,
    );
  }
}

class _MenuBar extends StatelessWidget {
  const _MenuBar({
    required this.brand,
    this.chrome,
    this.active = 0,
    this.utility = const [],
    this.who,
    this.action,
    this.leading,
    this.actions = const [],
  });
  final String brand;

  /// The places come from the scope as it holds them, so a copy of this file keeps the scope's own item type.
  final RetroDesktopChromeScope? chrome;
  final int active;
  final List<RetroDesktopUtility> utility;
  final String? who;
  final ShellAction? action;
  final Widget? leading;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final nav = chrome?.nav ?? const [];
    final top = MediaQuery.paddingOf(context).top;
    final room = math.max(
      RetroDesktopReach.least(context),
      MediaQuery.textScalerOf(context).scale(18) + 8,
    );
    final menu = t.type.chrome;
    Widget? fact(RetroDesktopUtility u) {
      final icon = u.icon == null
          ? null
          : Icon(u.icon, size: 15, color: u.highlighted ? c.highlight : c.text);
      if (!t.desk && icon != null) return _MenuCell(child: icon);
      return _MenuCell(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 6)],
            RetroDesktopCaps(
              style: menu,
              Text(u.text, style: menu, maxLines: 1, softWrap: false),
            ),
          ],
        ),
      );
    }

    final name = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const RetroDesktopSystemMark(),
        if (brand.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              brand,
              style: t.type.pixel(17, 16),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
    final start = <Widget>[
      if (leading != null) _InBar(child: leading!),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 6, end: 9),
        child: name,
      ),
      if (t.desk)
        for (var i = 0; i < nav.length; i++)
          _MenuCell(
            cellKey: nav[i].key,
            on: i == active,
            label: nav[i].label,
            onPressed: nav[i].onPressed,
            child: RetroDesktopCaps(
              style: menu,
              Text(
                nav[i].label,
                style: menu.copyWith(
                  color: i == active ? c.onHighlight : c.text,
                ),
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
    ];
    final end = <Widget>[
      for (final u in utility) ?fact(u),
      for (final a in actions) _InBar(child: a),
      if (action != null && t.desk)
        _MenuCell(
          cellKey: action!.key,
          label: action!.label,
          onPressed: () => action!.onPressed(context),
          child: Icon(
            action!.icon,
            size: 15,
            color: action!.accent ? c.highlight : c.text,
          ),
        ),
      if (who != null)
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 9, end: 4),
          child: Center(child: RetroDesktopMonogram(who!)),
        ),
    ];
    return RetroDesktopPixelPaint(
      painter: _BarPainter(c),
      child: Padding(
        padding: EdgeInsets.only(top: top, bottom: 1),
        child: SizedBox(
          height: room,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: t.desk ? 10 : 6,
              end: t.desk ? 8 : 6,
            ),
            child: DefaultTextStyle(
              style: menu,
              child: RetroDesktopFitRow(
                fill: 0,
                gap: 0,
                fillShare: .4,
                children: [
                  // A bar too narrow for its menus cuts them off rather than overflow.
                  SizedBox(
                    height: room,
                    child: ClipRect(child: _StartRow(children: start)),
                  ),
                  if (end.isNotEmpty)
                    SizedBox(
                      height: room,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: end,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartRow extends StatelessWidget {
  const _StartRow({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => OverflowBox(
    alignment: AlignmentDirectional.centerStart,
    maxWidth: double.infinity,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _StripPainter extends RetroDesktopPixelPainter {
  const _StripPainter(this.c);
  final RetroDesktopColors c;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    final h = px.hair;
    px.fillExact(r.left, r.top, r.right, r.bottom, c.platinum);
    px.fillExact(r.left, r.top, r.right, r.top + h, c.outline);
    px.fillExact(r.left, r.top + h, r.right, r.top + 2 * h, c.bevelLight);
  }

  @override
  bool shouldRepaint(_StripPainter o) => o.c != c;
}

class _GripPainter extends RetroDesktopPixelPainter {
  const _GripPainter(this.c, {this.width = 4});
  final RetroDesktopColors c;
  final double width;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    px.bevel(Offset.zero & s, c.bevelLight, c.bevelDark);
    final line = c.dark ? const Color(0xFF000000) : c.bevelDarker;
    final h = px.hair;
    final x0 = px.x((s.width - width) / 2);
    final x1 = px.x((s.width + width) / 2);
    var y = px.y(s.height / 2 - 5);
    for (var i = 0; i < 3; i++) {
      px.fillExact(x0, y, x1, y + h, line);
      px.fillExact(x0, y + h, x1, y + 2 * h, c.bevelLight);
      y = px.y(s.height / 2 - 5 + (i + 1) * 4);
    }
  }

  @override
  bool shouldRepaint(_GripPainter o) => o.c != c || o.width != width;
}

/// The phone's strip of places at the foot of the screen: raised buttons, the current one lit like a pressed key. A desktop
/// keeps its places in the menu bar.
///
/// ```dart
/// RetroDesktopNavigationBar(items: const [RetroDesktopNavItem(label: 'Files', short: 'Files', icon: RetroDesktopGlyphs.folder)], onDestinationSelected: (_) {})
/// ```
class RetroDesktopNavigationBar extends StatelessWidget {
  /// Creates a [RetroDesktopNavigationBar].
  const RetroDesktopNavigationBar({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.action,
    this.onDestinationSelected,
    this.style,
  });

  /// The items displayed in their supplied order.
  final List<RetroDesktopNavItem> items;

  /// Reports the index of the navigation destination activated.
  final ValueChanged<int>? onDestinationSelected;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// An optional action shown beside the content.
  final ShellAction? action;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    Widget destination(RetroDesktopNavItem item, int index) =>
        RetroDesktopPressable(
          key: item.key,
          label: item.label,
          value: item.badgeLabel,
          selected: index == selectedIndex,
          onPressed: onDestinationSelected == null
              ? item.onPressed
              : () => onDestinationSelected!(index),
          builder: (context, states) => retroDesktopFace(
            states: states,
            style: style,
            component: t.navigationBarTheme.merge(
              RetroDesktopStyle(
                textStyle: WidgetStatePropertyAll(t.type.pixel(16, 14)),
                minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon),
                const SizedBox(height: 4),
                Text(item.short, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
    Widget actionButton(ShellAction a) => RetroDesktopIconButton(
      a.icon,
      label: a.label ?? RetroDesktopLocalizations.of(context).choose,
      key: a.key,
      onPressed: () => a.onPressed(context),
    );
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (action != null && i == (items.length + 1) ~/ 2) {
        children.add(actionButton(action!));
      }
      children.add(Expanded(child: destination(items[i], i)));
    }
    if (action != null && items.length <= 1) {
      children.add(actionButton(action!));
    }
    return Semantics(
      container: true,
      child: retroDesktopFace(
        states: const {},
        style: style,
        component: t.navigationBarTheme.merge(
          RetroDesktopStyle(fill: WidgetStatePropertyAll(c.platinum)),
        ),
        scale: RetroDesktopFaceScale.surface,
        padding: EdgeInsets.fromLTRB(
          8,
          7,
          8,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        // On a wide screen the destinations keep a phone's spacing, centred,
        // rather than each spreading a third of the screen.
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 168.0 * (items.length + (action == null ? 0 : 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// One module of a `RetroDesktopDeskStrip`.
class RetroDesktopStripItem {
  /// Creates a [RetroDesktopStripItem].
  const RetroDesktopStripItem(this.text, {this.icon, this.highlighted = false});

  /// The text displayed by this part.
  final String text;

  /// The glyph shown with the content.
  final IconData? icon;

  /// Whether this item receives the active highlight.
  final bool highlighted;
}

class _ModulePainter extends RetroDesktopPixelPainter {
  const _ModulePainter(this.c);
  final RetroDesktopColors c;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    final w = px.hairX;
    px.fillExact(r.right - w, r.top, r.right, r.bottom, c.control);
    px.bevel(
      Rect.fromLTRB(r.left, r.top, r.right - w, r.bottom),
      c.bevelLight,
      c.bevelDark,
    );
  }

  @override
  bool shouldRepaint(_ModulePainter o) => o.c != c;
}

/// A desktop's small live facts in a row of modules, flush to the screen's edge under the windows, ending in a grip. Three to
/// five. A phone hasn't the room: give the same facts to a window as well if they matter there.
///
/// ```dart
/// RetroDesktopDeskStrip(items: const [RetroDesktopStripItem('Sunrise 07:22', icon: RetroDesktopGlyphs.sunrise, highlighted: true), RetroDesktopStripItem('SW 24 km/h', icon: RetroDesktopGlyphs.wind)])
/// ```
class RetroDesktopDeskStrip extends StatelessWidget {
  /// Creates a [RetroDesktopDeskStrip].
  const RetroDesktopDeskStrip({super.key, required this.items, this.style});

  /// The items displayed in their supplied order.
  final List<RetroDesktopStripItem> items;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    // No shadow: the strip lies on the desk, and only a window casts one (the light law). It is as long as its modules
    // and ends at its grip tab, as the period's strip did: stretched across its column, the tab stood mid-way as a
    // stray mark before an empty run.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: retroDesktopFace(
        states: const {},
        component: t.toolbarTheme,
        style: style,
        scale: RetroDesktopFaceScale.surface,
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 25 * t.density.vertical),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final m in items)
                    RetroDesktopPixelPaint(
                      painter: _ModulePainter(c),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          9,
                          0,
                          11,
                          0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.icon != null) ...[
                              Icon(
                                m.icon,
                                size: 14,
                                color: m.highlighted
                                    ? c.highlight
                                    : c.textSecondary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              m.text,
                              style: t.type.chrome,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 13,
                    child: RetroDesktopPixelPaint(
                      painter: _GripPainter(c, width: 5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- What the generator's routes, previews and page stubs stand on. ---

/// One tab as a generated app declares it: its glyph, its label and the walkthrough key on its hit target.
///
/// ```dart
/// RetroDesktopTab(RetroDesktopGlyphs.calendarDays, 'Today', ValueKey('open-today'))
/// ```
@immutable
class RetroDesktopTab {
  /// Creates a [RetroDesktopTab].
  const RetroDesktopTab(this.icon, this.label, [this.key]);

  /// The glyph shown with the content.
  final IconData icon;

  /// The visible or accessible name of this part.
  final String label;

  /// The stable identity of this item.
  final Key? key;
}

/// A page: the menu bar over a desktop of windows. [body] is usually a `RetroDesktopDesktop`, which says which window is active.
/// Anything else is put in a window of its own, titled from [topBar], and that window is the active one: a page can't come out
/// with no window or no hero. A pushed page keeps its way back at the menu bar's start. In a sheet there is no desktop: the
/// sheet is the window.
///
/// ```dart
/// RetroDesktopScaffold(topBar: RetroDesktopAppBar(title: 'Today'), body: RetroDesktopDesktop(active: 'Today', tiles: [RetroDesktopWindowColumn(span: 8, windows: [RetroDesktopWindow(title: 'Today', child: hero)]), RetroDesktopWindowColumn(span: 4, windows: [RetroDesktopWindow(title: 'Recent', child: list)])]))
/// ```
class RetroDesktopScaffold extends StatelessWidget {
  /// Creates a [RetroDesktopScaffold].
  const RetroDesktopScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.scrollController,
    this.who,
    this.utility = const [],
  });

  /// The main content shown beneath the heading.
  final Widget body;

  /// Usually a `RetroDesktopAppBar`: the title of the window a plain [body] goes in, and a pushed page's way back. Anything else
  /// stands over the page as given.
  final Widget? topBar;

  /// What stands fixed at a pushed page's foot: the one action.
  final Widget? footer;

  /// False: [body] takes the height left and scrolls itself.
  final bool scroll;

  /// [body] takes the page's whole width, with no window and no inset.
  final bool fullBleed;

  /// An optional externally owned scroll controller.
  final ScrollController? scrollController;

  /// The account's two letters, at the menu bar's end.
  final String? who;

  /// Small facts at the menu bar's end.
  final List<RetroDesktopUtility> utility;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final chrome = RetroDesktopChromeScope.maybeOf(context);
    final presentation = RoutePresentation.of(context);
    final sheet = presentation == RoutePresentation.sheet;
    final bar = topBar is RetroDesktopAppBar
        ? topBar! as RetroDesktopAppBar
        : null;
    if (sheet) return _sheetBody(context, t);

    final leading =
        bar?.leading ??
        (presentation == RoutePresentation.root
            ? null
            : RetroDesktopAppBar.autoLeading(context));
    final actions = bar?.actions ?? const <Widget>[];
    final showBar =
        chrome != null ||
        leading != null ||
        actions.isNotEmpty ||
        who != null ||
        utility.isNotEmpty;
    final head = !showBar
        ? null
        : _MenuBar(
            brand: chrome?.brand ?? '',
            chrome: chrome,
            active: chrome?.active ?? 0,
            action: chrome?.action,
            who: who,
            utility: utility,
            leading: leading,
            actions: actions,
          );
    final other = bar == null ? topBar : null;
    final windowTitle = bar?.title ?? chrome?.brand ?? '';

    final Widget content;
    if (!scroll || fullBleed && !scroll) {
      // The window fills what's left, for a body that scrolls itself.
      content = fullBleed
          ? body
          : Padding(
              padding: t.desk
                  ? const EdgeInsets.all(24)
                  : const EdgeInsets.all(12),
              child: RetroDesktopWindowScope(
                active: true,
                compact: true,
                child: body is RetroDesktopWindow
                    ? body
                    : RetroDesktopWindow(
                        title: windowTitle,
                        fills: true,
                        child: body,
                      ),
              ),
            );
    } else {
      final Widget page = fullBleed
          ? body
          : switch (body) {
              RetroDesktopDesktop() => body,
              RetroDesktopWindow() => RetroDesktopDesktop(
                tiles: [
                  RetroDesktopWindowColumn(span: 8, windows: [body]),
                ],
              ),
              _ => RetroDesktopDesktop(
                tiles: [
                  RetroDesktopWindowColumn(
                    span: 8,
                    windows: [
                      RetroDesktopWindow(title: windowTitle, child: body),
                    ],
                  ),
                ],
              ),
            };
      content = _PageScroll(
        controller: scrollController,
        fill: t.desk && !fullBleed,
        child: page,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(child: _DesktopBackground(colors: c)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?head,
            ?other,
            Expanded(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // No soft shadow under the menu bar: the bar ends in its
                  // one-pixel rule, and the only shadow in the look is a
                  // window's hard one.
                  Positioned.fill(child: content),
                ],
              ),
            ),
            if (footer != null) _Foot(child: footer!),
          ],
        ),
      ],
    );
  }

  Widget _sheetBody(BuildContext context, RetroDesktopThemeData t) {
    final inset = t.desk
        ? const EdgeInsets.fromLTRB(16, 14, 16, 18)
        : const EdgeInsets.fromLTRB(12, 12, 12, 18);
    final inner = fullBleed ? body : Padding(padding: inset, child: body);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?topBar,
        Flexible(
          child: scroll
              ? ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: inner,
                  ),
                )
              : inner,
        ),
        if (footer != null) _Foot(child: footer!),
      ],
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopPixelPaint(
      painter: _StripPainter(t.colors),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: t.desk
              ? Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child: SizedBox(width: 360, child: child),
                )
              : child,
        ),
      ),
    );
  }
}

/// A page's scroll: on a desktop the windows are at least a screen tall, so they and the strip stand on the whole desk.
class _PageScroll extends StatefulWidget {
  const _PageScroll({required this.child, required this.fill, this.controller});
  final Widget child;
  final bool fill;
  final ScrollController? controller;
  @override
  State<_PageScroll> createState() => _PageScrollState();
}

class _PageScrollState extends State<_PageScroll> {
  ScrollController? _own;
  ScrollController get _controller =>
      widget.controller ?? (_own ??= ScrollController());
  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final scroller = LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        controller: _controller,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: widget.fill ? box.maxHeight : 0,
          ),
          child: widget.child,
        ),
      ),
    );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: t.desk
          ? RawScrollbar(
              controller: _controller,
              thumbColor: c.bevelDarker,
              thickness: 8,
              radius: Radius.zero,
              child: scroller,
            )
          : scroller,
    );
  }
}

/// The way out of a pushed page or a sheet: a raised triangle or cross. In the menu bar it's a small one, on a phone with
/// room around it for a thumb.
///
/// ```dart
/// RetroDesktopBackButton(onPressed: () => Navigator.maybePop(context))
/// ```
class RetroDesktopBackButton extends StatelessWidget {
  /// Creates a [RetroDesktopBackButton].
  const RetroDesktopBackButton({
    super.key,
    this.close = false,
    this.onPressed,
    this.style,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// Whether the button closes its surface (a sheet) rather than going back.
  final bool close;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final label = close
        ? DesignLocalizations.of(context).closeButtonLabel
        : DesignLocalizations.of(context).backButtonTooltip;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final inBar = context.getInheritedWidgetOfExactType<_InBar>() != null;
    final button = close
        ? RetroDesktopIconButton(
            RetroDesktopGlyphs.x,
            label: label,
            style: style,
            onPressed: onPressed,
            size: inBar && t.desk
                ? RetroDesktopButtonSize.small
                : RetroDesktopButtonSize.medium,
          )
        : RetroDesktopIconButton.triangle(
            rtl ? AxisDirection.right : AxisDirection.left,
            label: label,
            style: style,
            onPressed: onPressed,
            size: inBar && t.desk
                ? RetroDesktopButtonSize.small
                : RetroDesktopButtonSize.medium,
          );
    return button;
  }
}

/// What a page says about itself. Its [title] goes on the window a plain body stands in, and a sheet shows it as its head.
/// [leading] and [actions] stand in the menu bar. A page never authors its own back or close: leave [leading] unset, or pass
/// [autoLeading] to key it.
///
/// ```dart
/// RetroDesktopAppBar(title: 'Build plan', leading: RetroDesktopAppBar.autoLeading(context, key: const ValueKey('back')))
/// ```
class RetroDesktopAppBar extends StatelessWidget {
  /// Creates a [RetroDesktopAppBar].
  const RetroDesktopAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.style,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String? title;

  /// Secondary information displayed with the main content.
  final String? subtitle;

  /// Optional content before the main content in reading order.
  final Widget? leading;

  /// The actions displayed after the content.
  final List<Widget> actions;

  /// The route's own exit: the way back on a pushed page, the close on a sheet, nothing on a root.
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    final presentation = RoutePresentation.of(context);
    if (presentation == RoutePresentation.root) return null;
    return RetroDesktopBackButton(
      key: key,
      close: presentation == RoutePresentation.sheet,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final ink = RetroDesktopStyle.first(
      [style, t.appBarTheme],
      (s) => s.foreground,
      const {},
    );
    final words = RetroDesktopStyle.first(
      [style, t.appBarTheme],
      (s) => s.textStyle,
      const {},
    );
    final exit = leading ?? autoLeading(context);
    return retroDesktopFace(
      states: const {},
      style: style,
      scale: RetroDesktopFaceScale.surface,
      component: t.appBarTheme.merge(
        RetroDesktopStyle(fill: WidgetStatePropertyAll(t.colors.platinumLight)),
      ),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: t.density.apply(
          EdgeInsetsDirectional.only(
            start: exit == null ? 12 : 2,
            end: 8,
            top: 2,
            bottom: 3,
          ),
          Directionality.of(context),
        ),
        child: Row(
          children: [
            ?exit,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: t.type.sub.merge(words).copyWith(color: ink),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: t.type.meta.merge(words).copyWith(color: ink),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// A one-line text field the generated stubs draw; `RetroDesktopTextField` is the same box with more to say.
///
/// ```dart
/// RetroDesktopInput(key: const ValueKey('name'), hint: 'Your name', onChanged: (text) {})
/// ```
class RetroDesktopInput extends StatelessWidget {
  /// Creates a [RetroDesktopInput].
  const RetroDesktopInput({
    super.key,
    this.style,
    this.label,
    this.focusNode,
    this.autofocus = false,
    this.hint,
    this.controller,
    this.initial,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The visible or accessible name of this part.
  final String? label;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// Whether the part accepts user interaction.
  final bool enabled;

  /// Placeholder text shown while the input has no value.
  final String? hint;

  /// The initial value used when no external controller supplies one.
  final String? initial;

  /// An optional externally owned controller; the caller disposes it.
  final TextEditingController? controller;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the entered text.
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => RetroDesktopTextField(
    enabled: enabled,
    style: style,
    label: label,
    focusNode: focusNode,
    autofocus: autofocus,
    hint: hint,
    controller: controller,
    initial: initial,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}

class _PhotoEdge extends RetroDesktopPixelPainter {
  const _PhotoEdge(this.color, {this.onlyBottom = false});
  final Color color;
  final bool onlyBottom;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = Offset.zero & s;
    if (onlyBottom) {
      px.ruleAcross(0, s.width, s.height - 1, color);
    } else {
      px.frame(r, color);
    }
  }

  @override
  bool shouldRepaint(_PhotoEdge o) =>
      o.color != color || o.onlyBottom != onlyBottom;
}

/// A picture from a declared media slot, in a hairline frame; until it loads, or if it never does, a panel with the system's
/// mark, one step off the machine by day and dark at night, so pictures read as a set. It takes the width it's given and sets
/// its height by [aspect].
///
/// ```dart
/// RetroDesktopMedia(slotId: 'workshop-bench', aspect: 4 / 3, label: 'The bench')
/// ```
class RetroDesktopMedia extends StatelessWidget {
  /// Creates a [RetroDesktopMedia].
  const RetroDesktopMedia({
    super.key,
    this.style,
    required this.slotId,
    this.aspect = 4 / 3,
    this.label,
    this.fit = BoxFit.cover,
    this.width,
    this.bare = false,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The stable identity used to match this chrome slot.
  final String slotId;

  /// The width-to-height ratio of the content.
  final double aspect;

  /// The visible or accessible name of this part.
  final String? label;

  /// How the image fits inside its frame.
  final BoxFit fit;

  /// Only for a thumbnail in a row: 48 to 96. Anywhere else it takes the width it's given.
  final double? width;

  /// No hairline of its own: it stands against a frame's.
  final bool bare;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, t.cardTheme], get, const {});
    final border =
        slot((s) => s.side) ??
        BorderSide(
          color: slot((s) => s.edge) ?? c.control,
          width: t.strokes.regular,
        );
    final shape = (slot((s) => s.shape) ?? t.shapes.medium).copyWith(
      side: border,
    );
    final small = width != null && width! < 72;
    final fallback = ColoredBox(
      color: c.platinumDark,
      child: Center(child: RetroDesktopSystemMark(size: small ? 16 : 32)),
    );
    final picture = Semantics(
      image: label != null,
      label: label,
      child: AspectRatio(
        aspectRatio: aspect,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: bare
              ? BoxDecoration(border: Border(bottom: border))
              : ShapeDecoration(shape: shape),
          child: ClipPath(
            // Bare in a card, it meets the card's top corners concentrically.
            clipper: ShapeBorderClipper(
              shape: bare
                  ? retroDesktopEdgeShape(
                      context,
                      top: true,
                      bottom: false,
                      inset: 1,
                    )
                  : shape,
            ),
            child: MediaSlotImage(slotId: slotId, fallback: fallback, fit: fit),
          ),
        ),
      ),
    );
    return width == null
        ? RetroDesktopFill(maxWidth: 1200, child: picture)
        : retroDesktopOwnSize(width: width, child: picture);
  }
}

/// A picture over its words, the picture bleeding to a small raised frame: one piece of a collection, a place, a person. The
/// picture is your media slot. A piece with no picture of its own takes an [art] instead, drawn large in the picture's
/// place: never a shelf of missing pictures. Lay them out in `RetroDesktopGridOf`, inside a window.
///
/// ```dart
/// RetroDesktopPictureCard(slotId: 'item-1', title: 'First piece', subtitle: 'Oak', trailing: const RetroDesktopFlag('new'), onPressed: open)
/// ```
class RetroDesktopPictureCard extends StatelessWidget {
  /// Creates a [RetroDesktopPictureCard].
  const RetroDesktopPictureCard({
    super.key,
    this.style,
    this.slotId,
    this.art,
    required this.title,
    this.subtitle,
    this.figure,
    this.trailing,
    this.aspect = 4 / 3,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  }) : assert(slotId != null || art != null, 'a media slot or an art widget');

  /// A declared media slot.
  final String? slotId;

  /// Any image, SVG or drawing supplied by the app.
  final Widget? art;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String title;

  /// Secondary information displayed with the main content.
  final String? subtitle;

  /// A number that belongs to the piece, in the system face.
  final String? figure;

  /// A `RetroDesktopFlag` or `RetroDesktopChip`.
  final Widget? trailing;

  /// The width-to-height ratio of the content.
  final double aspect;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The focus node this part uses; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    Widget card(Set<WidgetState> states) => retroDesktopFace(
      states: states,
      component: t.cardTheme,
      style: style,
      scale: RetroDesktopFaceScale.surface,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: RetroDesktopColumn(
          children: [
            if (art case final drawn?)
              AspectRatio(
                aspectRatio: aspect,
                child: RetroDesktopPixelPaint(
                  painter: _PhotoEdge(t.colors.control, onlyBottom: true),
                  foreground: true,
                  // Concentric with the card where it meets its top corners.
                  child: Builder(
                    builder: (context) => ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: retroDesktopEdgeShape(
                          context,
                          top: true,
                          bottom: false,
                          inset: 1,
                        ),
                      ),
                      child: ColoredBox(color: t.colors.paper, child: drawn),
                    ),
                  ),
                ),
              )
            else
              RetroDesktopMedia(
                slotId: slotId!,
                aspect: aspect,
                label: title,
                bare: true,
              ),
            RetroDesktopGrow(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
                child: RetroDesktopColumn(
                  gap: 2,
                  children: [
                    Text(title, style: t.type.row),
                    if (subtitle != null) Text(subtitle!, style: t.type.meta),
                    if (figure != null || trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: RetroDesktopSplit(
                          start: figure == null
                              ? const SizedBox.shrink()
                              : Text(figure!, style: t.type.small),
                          end: trailing ?? const SizedBox.shrink(),
                          gap: 8,
                          runGap: 6,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onPressed == null) return card(const {});
    return RetroDesktopPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      button: true,
      label: title,
      onPressed: onPressed,
      builder: (context, states) => card(states),
    );
  }
}

/// While data loads: the busy pointer (the wristwatch, or Chisel's hourglass) turning over its name, with optional help
/// and action.
///
/// ```dart
/// RetroDesktopLoadingState(title: 'Opening documents')
/// ```
class RetroDesktopLoadingState extends StatelessWidget {
  /// Creates a [RetroDesktopLoadingState].
  const RetroDesktopLoadingState({
    super.key,
    this.title,
    this.message,
    this.action,
  });

  /// The heading displayed above the content.
  final String? title;

  /// The message displayed to the user.
  final String? message;

  /// An optional action shown beside the content.
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final name = title ?? DesignLocalizations.of(context).loadingLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The pointer the machine showed while it worked: the
                    // wristwatch, or Chisel's hourglass, turning. It says
                    // "busy" alone; a bar under it said it twice.
                    const ExcludeSemantics(
                      child: RetroDesktopCircularProgressIndicator(size: 32),
                    ),
                    const SizedBox(height: 10),
                    Text(name, style: t.type.head, textAlign: TextAlign.center),
                    if (message != null)
                      Text(
                        message!,
                        style: t.type.body,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(child: action),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// When a page's data could not load: an alert saying what happened, and a way to try again.
///
/// ```dart
/// RetroDesktopErrorState(title: 'Could not load', message: 'Check your connection.', onRetry: retry)
/// ```
class RetroDesktopErrorState extends StatelessWidget {
  /// Creates a [RetroDesktopErrorState].
  const RetroDesktopErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.action,
  });

  /// The heading displayed above the content.
  final String title;

  /// The message displayed to the user.
  final String? message;

  /// Called when the user activates the retry action.
  final VoidCallback? onRetry;

  /// An optional action shown beside the content.
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: RetroDesktopAlert(
          // In the window's content: no window's shadow.
          floating: false,
          icon: RetroDesktopGlyphs.circleAlert,
          title: title,
          body: message,
          actions: [
            ?action,
            if (onRetry != null)
              RetroDesktopButton(
                RetroDesktopLocalizations.of(context).tryAgain,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    ),
  );
}

// Cache the viewport weave as pixels: web engines can replay retained pictures
// on every frame, even when a repaint boundary keeps its display list.
class _DesktopBackground extends StatefulWidget {
  const _DesktopBackground({required this.colors});

  final RetroDesktopColors colors;

  @override
  State<_DesktopBackground> createState() => _DesktopBackgroundState();
}

class _DesktopBackgroundState extends State<_DesktopBackground> {
  _DesktopRasterPainter? _painter;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    if (_painter?.c != widget.colors || _painter?.ratio != ratio) {
      _painter?.dispose();
      _painter = _DesktopRasterPainter(widget.colors, ratio);
    }
    return CustomPaint(painter: _painter);
  }

  @override
  void dispose() {
    _painter?.dispose();
    super.dispose();
  }
}

class _DesktopRasterPainter extends RetroDesktopDeskPainter {
  _DesktopRasterPainter(super.c, this.ratio);

  final double ratio;
  ui.Image? _image;
  Size? _size;

  /// The most device pixels a cached desk spans each way: a desk as tall as a
  /// long page laid out whole (14,700 at a ratio of 3) is past what a GPU's
  /// render target holds, and is drawn as it is instead.
  static const _most = 8192;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (size.width * ratio > _most || size.height * ratio > _most) {
      dispose();
      _size = null;
      super.paint(canvas, size);
      return;
    }
    if (_image == null || _size != size) {
      _image?.dispose();
      final recorder = ui.PictureRecorder();
      final recording = Canvas(recorder)..scale(ratio);
      super.paint(recording, size);
      final picture = recorder.endRecording();
      _image = picture.toImageSync(
        (size.width * ratio).ceil(),
        (size.height * ratio).ceil(),
      );
      picture.dispose();
      _size = size;
    }
    canvas.drawImageRect(
      _image!,
      Rect.fromLTWH(0, 0, size.width * ratio, size.height * ratio),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _DesktopRasterPainter old) =>
      c != old.c || ratio != old.ratio;

  void dispose() {
    _image?.dispose();
    _image = null;
  }
}
