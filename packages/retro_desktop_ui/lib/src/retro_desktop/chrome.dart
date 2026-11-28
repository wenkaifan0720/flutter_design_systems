// The machine around the windows: the menu bar, the phone's strip, the desk's strip and marks, and the screen that puts any
// page on a desktop so that it has a window and that window is active.
import 'package:flutter/foundation.dart';

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'press.dart';
import 'component_themes.dart';
import 'internal/caps.dart';
import 'internal/face.dart';

import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

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
import 'places.dart';
import 'tokens.dart';

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size, defaultValue: 16));
  }
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
        padding: const EdgeInsets.symmetric(
          horizontal: RetroDesktopSpacing.s8 + RetroDesktopSpacing.px,
        ),
        child: Center(widthFactor: 1, child: child),
      ),
    );
    if (onPressed == null) return KeyedSubtree(key: cellKey, child: cell);
    final shape = RetroDesktopTheme.of(context).shapes.small;
    return RetroDesktopPressable(
      button: true,
      selected: on,
      label: label,
      key: cellKey,
      onPressed: onPressed,
      // The cells stand side by side across the bar, the bar's edges at their
      // top and foot: the ring keeps inside the cell, in the words' ink on the
      // chosen place's highlight, so it shows whole and crosses no neighbour.
      builder: (context, states) => retroDesktopJoinedRing(
        shape: shape,
        insideColor: on ? c.onHighlight : null,
        child: cell,
      ),
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
    this.places,
  });
  final String brand;

  /// The places come from the scope as it holds them, so a copy of this file keeps the scope's own item type.
  final RetroDesktopChromeScope? chrome;
  final int active;
  final List<RetroDesktopUtility> utility;
  final String? who;
  final RetroDesktopAppAction? action;
  final Widget? leading;
  final List<Widget> actions;

  /// The shell's places, built by `RawAdaptiveShell` (each presses and speaks), in place of the scope's.
  final Widget? places;
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
    final menu = t.textTheme.chrome;
    Widget? fact(RetroDesktopUtility u) {
      final icon = u.icon == null
          ? null
          : Icon(u.icon, size: 15, color: u.highlighted ? c.highlight : c.text);
      if (!t.desk && icon != null) return _MenuCell(child: icon);
      return _MenuCell(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: RetroDesktopSpacing.s6),
            ],
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
          const SizedBox(width: RetroDesktopSpacing.s6),
          Flexible(
            child: Text(
              brand,
              style: t.textTheme.pixel(17, 16),
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
        padding: const EdgeInsetsDirectional.only(
          start: RetroDesktopSpacing.s6,
          end: RetroDesktopSpacing.s8 + RetroDesktopSpacing.px,
        ),
        child: name,
      ),
      if (places != null)
        places!
      else if (t.desk)
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
          onPressed: action!.onPressed,
          child: Icon(
            action!.icon,
            size: 15,
            color: action!.accent ? c.highlight : c.text,
          ),
        ),
      if (who != null)
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: RetroDesktopSpacing.s8 + RetroDesktopSpacing.px,
            end: RetroDesktopSpacing.s4,
          ),
          child: Center(child: RetroDesktopMonogram(who!)),
        ),
    ];
    return RetroDesktopPixelPaint(
      painter: _BarPainter(c),
      child: Padding(
        padding: EdgeInsets.only(top: top, bottom: RetroDesktopSpacing.px),
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
    final line = c.brightness == Brightness.dark
        ? const Color(0xFF000000)
        : c.bevelDarker;
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
  }) : assert(selectedIndex >= 0);

  /// The items displayed in their supplied order.
  final List<RetroDesktopNavItem> items;

  /// Reports the index of the navigation destination activated.
  final ValueChanged<int>? onDestinationSelected;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// The app's one act, a square button in the middle of the strip.
  final RetroDesktopAppAction? action;

  /// {@macro retro_desktop.style}
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
            component: t.navigationBarTheme.over(
              RetroDesktopStyle(
                textStyle: WidgetStatePropertyAll(t.textTheme.pixel(16, 14)),
                minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: RetroDesktopSpacing.s2,
              vertical: RetroDesktopSpacing.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon),
                const SizedBox(height: RetroDesktopSpacing.s4),
                Text(item.short, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
    Widget actionButton(RetroDesktopAppAction a) => RetroDesktopIconButton(
      a.icon,
      semanticLabel: a.label,
      key: a.key,
      onPressed: a.onPressed,
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
    // Notices stand above the bar (ui_core's RawToasterKeepClear), and follow it as it comes and goes.
    return RawToasterKeepClear(
      child: Semantics(
        container: true,
        child: retroDesktopFace(
          states: const {},
          style: style,
          component: t.navigationBarTheme.over(
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
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RetroDesktopNavItem>('items', items))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: 0))
      ..add(
        DiagnosticsProperty<RetroDesktopAppAction>(
          'action',
          action,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
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
    // Its rule at its end, beside the next module (its padding's end side).
    final r = px.snap(Offset.zero & s);
    final w = px.hairX;
    px.lit(r, () {
      px.fillExact(r.right - w, r.top, r.right, r.bottom, c.control);
      px.bevel(
        Rect.fromLTRB(r.left, r.top, r.right - w, r.bottom),
        c.bevelLight,
        c.bevelDark,
      );
    });
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

  /// {@macro retro_desktop.style}
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
            padding: const EdgeInsets.symmetric(
              vertical: RetroDesktopSpacing.px,
            ),
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
                              const SizedBox(width: RetroDesktopSpacing.s6),
                            ],
                            Text(
                              m.text,
                              style: t.textTheme.chrome,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RetroDesktopStripItem>('items', items))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

// --- An app's tabs, page and shell. ---

/// One tab as an app declares it: its glyph, its label and a key on its hit target, for a test to find and press it.
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

/// The app's one act beside its places (add, write, capture): a square button in the middle of the phone's strip and
/// an icon at the menu bar's end on a desk, lit in the highlight when [accent] is on.
///
/// ```dart
/// RetroDesktopAppAction(icon: RetroDesktopGlyphs.plus, label: 'Add', onPressed: add)
/// ```
@immutable
/// The app's frame: its places and its pages, at every width, through ui_core's `RawAdaptiveShell`. Under
/// [retroDesktopDeskWidth] the places stand in the phone's strip at the foot ([RetroDesktopNavigationBar]'s raised
/// buttons, the current one lit like a pressed key), the [action] a square button in its middle, and each page draws its
/// own menu bar with the app's [brand]; on a desk the places are the menu bar's menus beside the [brand], the [action],
/// [utility] and [initials] at its end, and each page's own bar stands under it with its way back, its subtitle and its
/// actions. [modeForWidth] moves that width; a rail or a sidebar shows the strip's buttons down the start. A screen
/// reader hears the places as tabs, the current one selected; the arrows move along them, Enter or Space chooses one,
/// and F6 moves to the page. Notices stand above the strip.
///
/// [RetroDesktopAppShell.branches] keeps a stack of pages for each place: a page pushed on one
/// (`Navigator.of(context).push`) keeps the menu bar while the phone's strip steps away, and back pops it.
/// [RetroDesktopAppShell] stands round the app's own [body] (an `IndexedStack`, a router's shell), and
/// [showNavigation] hides the strip.
///
/// ```dart
/// RetroDesktopAppShell.branches(brand: 'Shelf', destinations: const [RetroDesktopNavItem(label: 'Books', short: 'Books', icon: RetroDesktopGlyphs.folder), RetroDesktopNavItem(label: 'Settings', short: 'Settings', icon: RetroDesktopGlyphs.settings)], selectedIndex: place, onDestinationSelected: (index) => setState(() => place = index), branches: [(context) => const Text('Books'), (context) => const Text('Settings')])
/// ```
class RetroDesktopAppShell extends StatelessWidget {
  /// The app's places round its own [body].
  const RetroDesktopAppShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required Widget this.body,
    this.brand,
    this.action,
    this.utility = const [],
    this.initials,
    this.modeForWidth = RetroDesktopAppShell.modeFor,
    this.showNavigation = true,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false;

  /// The app's places, each with a stack of pages of its own, starting on its [branches] page.
  const RetroDesktopAppShell.branches({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.brand,
    this.action,
    this.utility = const [],
    this.initials,
    this.modeForWidth = RetroDesktopAppShell.modeFor,
    this.showNavigation = true,
  }) : body = null;

  /// Retro Desktop's places for a shell [width] wide: the phone's strip under [retroDesktopDeskWidth], where the look
  /// lays a phone's page, and the menu bar from there, where it lays a desk.
  static RawNavigationMode modeFor(double width) =>
      width < retroDesktopDeskWidth
      ? RawNavigationMode.bar
      : RawNavigationMode.top;

  /// The app's places, in order: each one's `label` names it in the menu bar and to a screen reader, its `short`
  /// under its glyph in the strip; [onDestinationSelected] chooses it (its own `onPressed` is not called).
  final List<RetroDesktopNavItem> destinations;

  /// The place shown.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The app's own pages ([RetroDesktopAppShell]); null for [RetroDesktopAppShell.branches].
  final Widget? body;

  /// Each place's first page ([RetroDesktopAppShell.branches]); null round a [body].
  final List<WidgetBuilder>? branches;

  /// The places' navigators, to push onto one from outside it (a notification opening a page).
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place's first page.
  final RawBranchBackBehavior backBehavior;

  /// Whether the phone's strip steps away while a page is pushed over a place's first page; the menu bar stays.
  final bool hideBarOnPush;

  /// The app's name, after the system mark at the menu bar's start.
  final String? brand;

  /// The app's one act.
  final RetroDesktopAppAction? action;

  /// Small facts at the menu bar's end (synced, an hour).
  final List<RetroDesktopUtility> utility;

  /// The account's two letters, at the menu bar's end.
  final String? initials;

  /// How the places show for the shell's width: [modeFor] by default.
  final RawNavigationModeForWidth modeForWidth;

  /// Whether the phone's strip shows: false while a page of the app's own covers a place's first page.
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final places = [
      for (final d in destinations)
        RawNavigationDestination(
          label: d.badgeLabel == null ? d.label : '${d.label}, ${d.badgeLabel}',
          icon: d.icon,
        ),
    ];
    Widget destination(
      BuildContext context,
      RawNavigationDestination place,
      RawDestinationDetails details,
    ) {
      final item = destinations[details.index];
      return KeyedSubtree(
        key: item.key,
        child: details.mode == RawNavigationMode.top
            ? _MenuPlace(item: item, states: details.states)
            : _StripPlace(
                item: item,
                states: details.states,
                wide: details.mode == RawNavigationMode.sidebar,
              ),
      );
    }

    Widget navigation(BuildContext context, RawNavigationDetails details) =>
        switch (details.mode) {
          RawNavigationMode.top => _MenuBar(
            brand: brand ?? '',
            action: action,
            utility: utility,
            who: initials,
            places: details.group(
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: details.destinations,
              ),
            ),
          ),
          RawNavigationMode.bar => _ShellStrip(
            details: details,
            action: action,
          ),
          RawNavigationMode.rail || RawNavigationMode.sidebar => _ShellColumn(
            details: details,
            action: action,
            width: details.mode == RawNavigationMode.rail ? 96 : 220,
          ),
        };
    final branches = this.branches;
    final c = RetroDesktopTheme.of(context).colors;
    return ColoredBox(
      color: c.desktop,
      child: RetroDesktopChromeScope(
        brand: brand ?? '',
        nav: destinations,
        active: selectedIndex,
        action: action,
        utility: utility,
        initials: initials,
        shellDrawn: true,
        child: branches == null
            ? RawAdaptiveShell(
                destinations: places,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinationBuilder: destination,
                navigationBuilder: navigation,
                modeForWidth: modeForWidth,
                showNavigation: showNavigation,
                body: body!,
              )
            : RawAdaptiveShell.branches(
                destinations: places,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinationBuilder: destination,
                navigationBuilder: navigation,
                modeForWidth: modeForWidth,
                showNavigation: showNavigation,
                hideBarOnPush: hideBarOnPush,
                backBehavior: backBehavior,
                navigatorKeys: navigatorKeys,
                branches: branches,
              ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RetroDesktopNavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(IntProperty('branches', branches?.length, defaultValue: null))
      ..add(
        IterableProperty<GlobalKey<NavigatorState>>(
          'navigatorKeys',
          navigatorKeys,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<RawBranchBackBehavior>(
          'backBehavior',
          backBehavior,
          defaultValue: RawBranchBackBehavior.firstDestination,
        ),
      )
      ..add(
        FlagProperty(
          'hideBarOnPush',
          value: hideBarOnPush,
          ifTrue: 'bar hidden on push',
        ),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        DiagnosticsProperty<RetroDesktopAppAction>(
          'action',
          action,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<RetroDesktopUtility>(
          'utility',
          utility,
          defaultValue: const [],
        ),
      )
      ..add(StringProperty('initials', initials, defaultValue: null))
      ..add(
        ObjectFlagProperty<RawNavigationModeForWidth>(
          'modeForWidth',
          modeForWidth,
          ifPresent: modeForWidth == RetroDesktopAppShell.modeFor
              ? null
              : 'custom',
        ),
      )
      ..add(
        FlagProperty(
          'showNavigation',
          value: showNavigation,
          ifFalse: 'navigation hidden',
          defaultValue: true,
        ),
      );
  }
}

// A place in the menu bar: its label, in the highlight while it is the current one; the keyboard's ring inside the cell.
class _MenuPlace extends StatelessWidget {
  const _MenuPlace({required this.item, required this.states});
  final RetroDesktopNavItem item;
  final Set<WidgetState> states;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final on = states.contains(WidgetState.selected);
    final menu = t.textTheme.chrome;
    return retroDesktopJoinedRing(
      shape: t.shapes.small,
      focused: states.contains(WidgetState.focused),
      insideColor: on ? c.onHighlight : null,
      child: _MenuCell(
        on: on,
        child: RetroDesktopCaps(
          style: menu,
          Text(
            item.label,
            style: menu.copyWith(color: on ? c.onHighlight : c.text),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}

// A place in the strip: a raised button, its glyph over its short name, lit like a pressed key while it is the current
// one; in a sidebar its glyph beside its name.
class _StripPlace extends StatelessWidget {
  const _StripPlace({
    required this.item,
    required this.states,
    this.wide = false,
  });
  final RetroDesktopNavItem item;
  final Set<WidgetState> states;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final words = Text(
      wide ? item.label : item.short,
      textAlign: wide ? TextAlign.start : TextAlign.center,
      maxLines: wide ? 1 : null,
      overflow: wide ? TextOverflow.ellipsis : null,
    );
    return retroDesktopFace(
      states: states,
      component: t.navigationBarTheme.over(
        RetroDesktopStyle(
          textStyle: WidgetStatePropertyAll(t.textTheme.pixel(16, 14)),
          minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: wide ? RetroDesktopSpacing.s10 : RetroDesktopSpacing.s2,
        vertical: RetroDesktopSpacing.s4,
      ),
      child: wide
          ? Row(
              children: [
                Icon(item.icon),
                const SizedBox(width: RetroDesktopSpacing.s8),
                Expanded(child: words),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon),
                const SizedBox(height: RetroDesktopSpacing.s4),
                words,
              ],
            ),
    );
  }
}

// The shell's strip at a phone's foot: the places' buttons across it, the act a square button over a gap in their
// middle, outside the tab bar a screen reader hears (which holds the places alone). Notices stand above it.
class _ShellStrip extends StatelessWidget {
  const _ShellStrip({required this.details, required this.action});
  final RawNavigationDetails details;
  final RetroDesktopAppAction? action;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final act = action;
    final count = details.destinations.length;
    final middle = (count + 1) ~/ 2;
    final slots = act == null ? count : count + 1;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (act != null && i == middle) const Spacer(),
          Expanded(child: details.destinations[i]),
        ],
        if (act != null && middle >= count) const Spacer(),
      ],
    );
    return RawToasterKeepClear(
      child: retroDesktopFace(
        states: const {},
        component: t.navigationBarTheme.over(
          RetroDesktopStyle(fill: WidgetStatePropertyAll(c.platinum)),
        ),
        scale: RetroDesktopFaceScale.surface,
        padding: EdgeInsets.fromLTRB(
          8,
          7,
          8,
          8 + MediaQuery.paddingOf(context).bottom,
        ),
        // On a wide screen the places keep a phone's spacing, centred, rather than each spreading over the screen.
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 168.0 * slots),
            child: act == null
                ? details.group(row)
                : LayoutBuilder(
                    builder: (context, box) {
                      final slot = box.maxWidth / slots;
                      return Stack(
                        alignment: AlignmentDirectional.centerStart,
                        children: [
                          details.group(row),
                          PositionedDirectional(
                            start: slot * middle,
                            width: slot,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: RetroDesktopIconButton(
                                act.icon,
                                semanticLabel: act.label,
                                key: act.key,
                                onPressed: act.onPressed,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

// A rail or a sidebar, when an app's modeForWidth picks one: the strip's buttons down the start on the platinum
// surface, the act at the head.
class _ShellColumn extends StatelessWidget {
  const _ShellColumn({
    required this.details,
    required this.action,
    required this.width,
  });
  final RawNavigationDetails details;
  final RetroDesktopAppAction? action;
  final double width;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final act = action;
    return SizedBox(
      width: width,
      child: retroDesktopFace(
        states: const {},
        component: t.navigationBarTheme.over(
          RetroDesktopStyle(fill: WidgetStatePropertyAll(c.platinum)),
        ),
        scale: RetroDesktopFaceScale.surface,
        padding: EdgeInsets.fromLTRB(
          8,
          8 + MediaQuery.paddingOf(context).top,
          8,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (act != null) ...[
              Center(
                child: RetroDesktopIconButton(
                  act.icon,
                  semanticLabel: act.label,
                  key: act.key,
                  onPressed: act.onPressed,
                ),
              ),
              const SizedBox(height: RetroDesktopSpacing.s12),
            ],
            details.group(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: RetroDesktopSpacing.s6,
                children: details.destinations,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A page's fact in its own bar under the shell's menu bar: its glyph, then its words.
class _PageFact extends StatelessWidget {
  const _PageFact(this.fact);
  final RetroDesktopUtility fact;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final style = t.textTheme.meta;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: RetroDesktopSpacing.s8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fact.icon != null) ...[
            Icon(
              fact.icon,
              size: 15,
              color: fact.highlighted ? c.highlight : c.text,
            ),
            const SizedBox(width: RetroDesktopSpacing.s4),
          ],
          Text(fact.text, style: style, maxLines: 1, softWrap: false),
        ],
      ),
    );
  }
}

/// A page: the menu bar over a desktop of windows. [body] is usually a `RetroDesktopDesktop`, which says which window is active.
/// Anything else is put in a window of its own, titled from [appBar], and that window is the active one: a page can't come out
/// with no window or no hero. A pushed page keeps its way back at the menu bar's start. In a sheet there is no desktop: the
/// sheet is the window.
///
/// ```dart
/// RetroDesktopScaffold(appBar: RetroDesktopAppBar(title: 'Today'), body: RetroDesktopDesktop(active: 'Today', tiles: [RetroDesktopWindowColumn(span: 8, windows: [RetroDesktopWindow(title: 'Today', child: hero)]), RetroDesktopWindowColumn(span: 4, windows: [RetroDesktopWindow(title: 'Recent', child: list)])]))
/// ```
class RetroDesktopScaffold extends StatelessWidget {
  /// Creates a [RetroDesktopScaffold].
  const RetroDesktopScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.scrollController,
    this.initials,
    this.utility = const [],
  });

  /// The main content shown beneath the heading.
  final Widget body;

  /// Usually a `RetroDesktopAppBar`: the title of the window a plain [body] goes in, and a pushed page's way back. Anything else
  /// stands over the page as given.
  final Widget? appBar;

  /// What stands fixed at a pushed page's foot: the one action.
  final Widget? footer;

  /// False: [body] takes the height left and scrolls itself.
  final bool scroll;

  /// [body] takes the page's whole width, with no window and no inset.
  final bool fullBleed;

  /// An optional externally owned scroll controller.
  final ScrollController? scrollController;

  /// The account's two letters, at the menu bar's end (under a [RetroDesktopAppShell] on a desk, at the end of the
  /// page's own bar; the shell's [RetroDesktopAppShell.initials] stand in its menu bar).
  final String? initials;

  /// Small facts at the menu bar's end (under a [RetroDesktopAppShell] on a desk, at the end of the page's own bar).
  final List<RetroDesktopUtility> utility;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final chrome = RetroDesktopChromeScope.maybeOf(context);
    final presentation = RoutePresentation.of(context);
    final sheet = presentation == RoutePresentation.sheet;
    final bar = appBar is RetroDesktopAppBar
        ? appBar! as RetroDesktopAppBar
        : null;
    if (sheet) return _sheetBody(context, t);

    final leading =
        bar?.leading ??
        (presentation == RoutePresentation.root
            ? null
            : RetroDesktopAppBar.autoLeading(context));
    final actions = bar?.actions ?? const <Widget>[];
    final who = initials ?? chrome?.initials;
    final facts = [...?chrome?.utility, ...utility];
    // Under a RetroDesktopAppShell on a desk the shell draws the menu bar: the page's own bar stands under it with its
    // way back, its title and subtitle, its actions and its facts, when it has any of them.
    final underShell = chrome != null && chrome.shellDrawn && t.desk;
    // The scaffold draws the page's window unless the page brings its own (a window or a desk of them) or none: its
    // subtitle then stands in the window's info strip, under its title, as a Finder window's count did.
    final drawsWindow =
        !fullBleed &&
        body is! RetroDesktopWindow &&
        body is! RetroDesktopDesktop;
    final barSubtitle = drawsWindow ? null : bar?.subtitle;
    // On a desk, where the page's window stands: the page's bar and its footer keep to it.
    final (double, double) Function(double width)? column = fullBleed
        ? null
        : !scroll
        ? (w) => (RetroDesktopSpacing.s24, w - RetroDesktopSpacing.s24)
        : body is RetroDesktopDesktop
        ? (w) => _pageColumn(w, span: 12)
        : _pageColumn;
    final showBar =
        chrome != null ||
        leading != null ||
        actions.isNotEmpty ||
        who != null ||
        facts.isNotEmpty;
    final Widget? head;
    if (underShell) {
      final own =
          leading != null ||
          actions.isNotEmpty ||
          initials != null ||
          utility.isNotEmpty ||
          barSubtitle != null;
      final pageBar = RetroDesktopAppBar(
        // The window the scaffold draws carries the page's title in its title bar: the bar over it says it once.
        title: drawsWindow ? null : bar?.title,
        subtitle: barSubtitle,
        leading: leading,
        style: bar?.style,
        actions: [
          ...actions,
          for (final u in utility) _PageFact(u),
          if (initials != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: RetroDesktopSpacing.s8,
              ),
              child: Center(child: RetroDesktopMonogram(initials!)),
            ),
        ],
      );
      head = !own
          ? null
          : column == null
          ? pageBar
          : LayoutBuilder(
              builder: (context, box) {
                final (start, end) = column(box.maxWidth);
                return _PageInset(
                  width: box.maxWidth,
                  start: start,
                  end: end,
                  child: pageBar,
                );
              },
            );
    } else {
      head = !showBar
          ? null
          : _MenuBar(
              brand: chrome?.brand ?? '',
              chrome: chrome,
              active: chrome?.active ?? 0,
              action: chrome?.action,
              who: who,
              utility: facts,
              leading: leading,
              actions: actions,
            );
    }
    final other = bar == null ? appBar : null;
    final windowTitle = bar?.title ?? chrome?.brand ?? '';

    final Widget content;
    if (!scroll || fullBleed && !scroll) {
      // The window fills what's left, for a body that scrolls itself.
      content = fullBleed
          ? body
          : Padding(
              padding: t.desk
                  ? const EdgeInsets.all(RetroDesktopSpacing.s24)
                  : const EdgeInsets.all(RetroDesktopSpacing.s12),
              child: RetroDesktopWindowScope(
                active: true,
                compact: true,
                child: body is RetroDesktopWindow
                    ? body
                    : RetroDesktopWindow(
                        title: windowTitle,
                        info: bar?.subtitle,
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
                      RetroDesktopWindow(
                        title: windowTitle,
                        info: bar?.subtitle,
                        child: body,
                      ),
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
        ? const EdgeInsets.fromLTRB(
            RetroDesktopSpacing.s16,
            RetroDesktopSpacing.s14,
            RetroDesktopSpacing.s16,
            RetroDesktopSpacing.s18,
          )
        : const EdgeInsets.fromLTRB(
            RetroDesktopSpacing.s12,
            RetroDesktopSpacing.s12,
            RetroDesktopSpacing.s12,
            RetroDesktopSpacing.s18,
          );
    final inner = fullBleed ? body : Padding(padding: inset, child: body);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?appBar,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('scroll', value: scroll, ifFalse: 'scroll: false'))
      ..add(FlagProperty('fullBleed', value: fullBleed, ifTrue: 'fullBleed'))
      ..add(
        DiagnosticsProperty<ScrollController>(
          'scrollController',
          scrollController,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('initials', initials, defaultValue: null))
      ..add(
        IterableProperty<RetroDesktopUtility>(
          'utility',
          utility,
          defaultValue: const [],
        ),
      );
  }
}

/// Where a page's window stands across a desk [width], counted as the desk's tiles count it: 24 in from the start, [span]
/// of 12 columns on a grid at most 1680 wide with 24 between columns.
(double, double) _pageColumn(double width, {int span = 8}) {
  const pad = 24.0, gutter = 24.0, most = 1680.0;
  final grid = math.min(width - 2 * pad, most);
  final unit = (grid + gutter) / 12;
  return (pad, (pad + span * unit - gutter).roundToDouble());
}

/// The page's column on a desk, for the page's own bar under the shell's menu bar: its way back starts where the window
/// does, its actions end where it ends.
class _PageInset extends InheritedWidget {
  const _PageInset({
    required this.width,
    required this.start,
    required this.end,
    required super.child,
  });

  /// The bar's width, and where the window starts and ends across it.
  final double width, start, end;
  @override
  bool updateShouldNotify(_PageInset old) =>
      old.width != width || old.start != start || old.end != end;
}

class _Foot extends StatelessWidget {
  const _Foot({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    // Notices stand above a page's footer, as above the navigation bar.
    return RawToasterKeepClear(
      child: RetroDesktopPixelPaint(
        painter: _StripPainter(t.colors),
        child: SafeArea(
          top: false,
          child: !t.desk
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RetroDesktopSpacing.s12,
                    RetroDesktopSpacing.s10,
                    RetroDesktopSpacing.s12,
                    RetroDesktopSpacing.s10,
                  ),
                  // At its end, as on a desk and as a dialog's buttons stand at its end.
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    heightFactor: 1,
                    child: child,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RetroDesktopSpacing.s24,
                    vertical: RetroDesktopSpacing.s10,
                  ),
                  // At the strip's end, as a dialog's buttons stand at its end: a button its own width, a row of them
                  // at most 360. The strip runs the screen's width, so its buttons end where it ends, on the desk's
                  // margin; at the window's end they stood mid-strip on a wide desk.
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: child,
                    ),
                  ),
                ),
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

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  /// Whether the button closes its surface (a sheet) rather than going back.
  final bool close;

  /// {@macro retro_desktop.onPressed}
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final label = close
        ? RawWidgetsLocalizations.of(context).closeButtonLabel
        : RawWidgetsLocalizations.of(context).backButtonTooltip;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final inBar = context.getInheritedWidgetOfExactType<_InBar>() != null;
    final button = close
        ? RetroDesktopIconButton(
            RetroDesktopGlyphs.x,
            semanticLabel: label,
            style: style,
            onPressed: onPressed,
            size: inBar && t.desk
                ? RetroDesktopButtonSize.small
                : RetroDesktopButtonSize.medium,
          )
        : RetroDesktopIconButton.triangle(
            rtl ? AxisDirection.right : AxisDirection.left,
            semanticLabel: label,
            style: style,
            onPressed: onPressed,
            size: inBar && t.desk
                ? RetroDesktopButtonSize.small
                : RetroDesktopButtonSize.medium,
          );
    return button;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('close', value: close, ifTrue: 'close'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed));
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

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String? title;

  /// A line more about the page. In a [RetroDesktopScaffold] it stands in the info strip under the page window's title
  /// (a page that brings its own window gives it `info` there); under the shell's menu bar on a desk, when the page
  /// brings its own windows, in the page's bar under its title.
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
    // Under the shell's menu bar on a desk, the page's bar keeps to the page's window: its way back starts where the
    // window starts.
    final column = context.dependOnInheritedWidgetOfExactType<_PageInset>();
    // Counted from the bar's edges: inside its rim the room is that much narrower on each side.
    Widget onColumn(Widget row) => column == null
        ? row
        : LayoutBuilder(
            builder: (context, box) {
              final rim = (column.width - box.maxWidth) / 2;
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  start: math.max(0, column.start - rim),
                  end: math.max(0, column.width - column.end - rim),
                ),
                child: row,
              );
            },
          );
    return retroDesktopFace(
      states: const {},
      style: style,
      scale: RetroDesktopFaceScale.surface,
      component: t.appBarTheme.over(
        RetroDesktopStyle(fill: WidgetStatePropertyAll(t.colors.platinumLight)),
      ),
      padding: EdgeInsets.zero,
      child: onColumn(
        Padding(
          padding: t.density.apply(
            EdgeInsetsDirectional.only(
              start: column != null
                  ? 0
                  : exit == null
                  ? 12
                  : 2,
              end: column != null ? 0 : 8,
              top: 2,
              bottom: 3,
            ),
            Directionality.of(context),
          ),
          child: Row(
            children: [
              // An icon-only way back fills its box to its edge, so it stands 8 clear of the title; a worded button
              // keeps its own room.
              if (exit != null) ...[
                exit,
                if (exit is RetroDesktopBackButton ||
                    exit is RetroDesktopIconButton)
                  const SizedBox(width: RetroDesktopSpacing.s8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: t.textTheme.sub
                            .merge(words)
                            .copyWith(color: ink),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: t.textTheme.meta
                            .merge(words)
                            .copyWith(color: ink),
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
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null));
  }
}

/// A one-line text field the generated stubs draw; `RetroDesktopTextField` is the same box with more to say.
///
/// ```dart
/// RetroDesktopInput(key: const ValueKey('name'), hintText: 'Your name', onChanged: (text) {})
/// ```
class RetroDesktopInput extends StatelessWidget {
  /// Creates a [RetroDesktopInput].
  const RetroDesktopInput({
    super.key,
    this.style,
    this.labelText,
    this.focusNode,
    this.autofocus = false,
    this.hintText,
    this.controller,
    String? initialValue,
    @Deprecated('Use initialValue.') String? initial,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  }) : initialValue = initialValue ?? initial;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  /// The visible or accessible name of this part.
  final String? labelText;

  /// {@macro retro_desktop.focusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  /// Whether the part accepts user interaction.
  final bool enabled;

  /// Placeholder text shown while the input has no value.
  final String? hintText;

  /// The first words when no controller supplies them (Flutter's `TextFormField.initialValue`).
  final String? initialValue;

  /// The first words when no controller supplies them.
  @Deprecated('Use initialValue.')
  String? get initial => initialValue;

  /// {@template retro_desktop.controller}
  /// An optional externally owned controller; the caller disposes it.
  /// {@endtemplate}
  final TextEditingController? controller;

  /// {@template retro_desktop.onChanged}
  /// Reports the value selected by the user; null prevents changes.
  /// {@endtemplate}
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the entered text.
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => RetroDesktopTextField(
    enabled: enabled,
    style: style,
    labelText: labelText,
    focusNode: focusNode,
    autofocus: autofocus,
    hintText: hintText,
    controller: controller,
    initialValue: initialValue,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('initialValue', initialValue, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      );
  }
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
/// RetroDesktopMedia(slotId: 'workshop-bench', aspect: 4 / 3, semanticLabel: 'The bench')
/// ```
class RetroDesktopMedia extends StatelessWidget {
  /// Creates a [RetroDesktopMedia].
  const RetroDesktopMedia({
    super.key,
    this.style,
    required this.slotId,
    this.aspect = 4 / 3,
    this.semanticLabel,
    this.fit = BoxFit.cover,
    this.width,
    this.bare = false,
  });

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  /// The stable identity used to match this chrome slot.
  final String slotId;

  /// The width-to-height ratio of the content.
  final double aspect;

  /// The visible or accessible name of this part.
  final String? semanticLabel;

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
      image: semanticLabel != null,
      label: semanticLabel,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('slotId', slotId))
      ..add(DoubleProperty('aspect', aspect, defaultValue: 4 / 3))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(EnumProperty<BoxFit>('fit', fit, defaultValue: BoxFit.cover))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(FlagProperty('bare', value: bare, ifTrue: 'bare'));
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

  /// {@macro retro_desktop.style}
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

  /// {@macro retro_desktop.onPressed}
  final VoidCallback? onPressed;

  /// {@template retro_desktop.ownFocusNode}
  /// The focus node this part uses; when null it makes and disposes its own.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
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
        padding: const EdgeInsets.all(RetroDesktopSpacing.px),
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
                semanticLabel: title,
                bare: true,
              ),
            RetroDesktopGrow(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RetroDesktopSpacing.s8 + RetroDesktopSpacing.px,
                  RetroDesktopSpacing.s8,
                  RetroDesktopSpacing.s8 + RetroDesktopSpacing.px,
                  RetroDesktopSpacing.s10,
                ),
                child: RetroDesktopColumn(
                  gap: 2,
                  children: [
                    Text(title, style: t.textTheme.row),
                    if (subtitle != null)
                      Text(subtitle!, style: t.textTheme.meta),
                    if (figure != null || trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: RetroDesktopSpacing.s6,
                        ),
                        child: RetroDesktopSplit(
                          start: figure == null
                              ? const SizedBox.shrink()
                              : Text(figure!, style: t.textTheme.small),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('slotId', slotId, defaultValue: null))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(StringProperty('figure', figure, defaultValue: null))
      ..add(DoubleProperty('aspect', aspect, defaultValue: 4 / 3))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
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
    final name = title ?? RawWidgetsLocalizations.of(context).loadingLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RetroDesktopSpacing.s24),
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
                    const SizedBox(height: RetroDesktopSpacing.s10),
                    Text(
                      name,
                      style: t.textTheme.head,
                      textAlign: TextAlign.center,
                    ),
                    if (message != null)
                      Text(
                        message!,
                        style: t.textTheme.body,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(top: RetroDesktopSpacing.s16),
                  child: Center(child: action),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('message', message, defaultValue: null));
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
      padding: const EdgeInsets.all(RetroDesktopSpacing.s12),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onRetry', onRetry));
  }
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
    if (_painter?.colors != widget.colors || _painter?.ratio != ratio) {
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
      colors != old.colors || ratio != old.ratio;

  void dispose() {
    _image?.dispose();
    _image = null;
  }
}
