// The page's chrome. A desktop stands on a 272 flush pilaster (brand, act, places, the page's sets, a foot) and a 12-column main; a phone
// has the brand or a way back at the top and a raised tab bar whose current tab is pressed with the pigment in its glyph.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

import 'chrome_items.dart';
import 'glyphs.dart';

import 'controls.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'shapes.dart';
import 'localizations.dart';
import 'frames.dart';
import 'internal/geometry.dart';
import 'heads.dart';
import 'layout.dart';
import 'ornaments.dart';
import 'theme.dart';
import 'host.dart';
import 'internal/cap_label.dart';

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.size = 18});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: EdgeInsets.symmetric(horizontal: size > 18 ? 6 : 5),
      // A capsule of the pigment, round for one figure, as every badge in the look is: a 6 corner on 18 px read as a
      // square chip. Flat on the bar (a part on a part is a plain step), its face the pigment.
      decoration: BoxDecoration(
        color: c.pigment,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: neumorphicLabel(
        Text(
          text,
          textAlign: TextAlign.center,
          style: t.textTheme.micro.copyWith(
            color: c.onPigment,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// The brand: the raised dimple with its point of pigment, and the wordmark.
///
/// ```dart
/// NeumorphicBrandRow('Your home')
/// ```
class NeumorphicBrandRow extends StatelessWidget {
  /// Creates a [NeumorphicBrandRow].
  const NeumorphicBrandRow(this.name, {super.key, this.mark});

  /// An app's own picture or logo in the brand slot.
  final Widget? mark;

  /// The name displayed for this item.
  final String name;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicFitRow(
      fill: 1,
      gap: 10,
      shrink: true,
      children: [
        mark ?? const NeumorphicBrandMark(),
        // A wordmark keeps its one line: where it doesn't fit (a phone's top with three keys) it scales down whole,
        // never breaking inside the word.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            name,
            maxLines: 1,
            softWrap: false,
            style: t.textTheme.text(
              20,
              26,
              weight: FontWeight.w800,
              tracking: -.02,
            ),
          ),
        ),
      ],
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter(this.c, this.flat, this.rule, {this.rtl = false});
  final NeumorphicColors c;
  final bool flat;

  /// Whether the rail stands at the right, its page to its left. The light stays the room's, top left: the rail's
  /// left edge, toward the page, is its lit side, and its right edge, at the window, its shaded one.
  final bool rtl;

  /// The trailing crease's width; zero leaves the cast shadow alone to part the rail from the page.
  final double rule;
  @override
  void paint(Canvas canvas, Size s) {
    final box = Offset.zero & s;
    if (!flat) {
      // The rail casts its shade away from the light, to the right. At the left of the window that falls on the
      // page; at its right it falls off the window, and toward the page it casts the light instead, as any raised
      // part does on its lit side: its blurred shade leaked onto the page there, a dark band against the light.
      canvas.save();
      canvas.clipRect(
        rtl
            ? Rect.fromLTRB(-64, 0, s.width, s.height)
            : Rect.fromLTRB(0, 0, s.width + 64, s.height),
      );
      canvas.drawRect(
        box.shift(Offset(rtl ? -16 : 16, 0)),
        Paint()
          ..color = rtl ? c.highlight : c.shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.restore();
    }
    canvas.drawRect(
      box,
      Paint()..shader = cssLinear(box, 90, [c.faceStart, c.faceEnd]),
    );
    if (!flat && rule > 0) {
      // The shaded edge's crease; at the right, the lit edge toward the page also takes its catch-light, so the
      // rail parts from the page by its light.
      canvas.drawRect(
        Rect.fromLTWH(s.width - rule, 0, rule, s.height),
        neumorphicFillPaint(c.crease),
      );
      if (rtl) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, rule, s.height),
          neumorphicFillPaint(c.rim),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RailPainter o) =>
      o.c != c || o.flat != flat || o.rule != rule || o.rtl != rtl;
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.item, required this.on, this.style});
  final NeumorphicNavItem item;
  final bool on;
  final NeumorphicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context), c = t.colors;
    return NeumorphicTap(
      onPressed: item.onPressed,
      label: item.label,
      selected: on,
      style: style,
      themeStyle: t.segmentedButtonTheme,
      child: Builder(
        builder: (context) {
          final states = {
            ...NeumorphicStatesScope.of(context),
            if (on) WidgetState.selected,
          };
          final look = NeumorphicStyleOf([
            style,
            t.segmentedButtonTheme,
          ], states);
          final row = Row(
            children: [
              Icon(
                item.icon,
                size: look.iconSize ?? 20,
                color: look.foreground ?? (on ? c.pigment : c.inkSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: neumorphicLabel(
                  Text(
                    item.label,
                    style: t.textTheme.body
                        .copyWith(
                          fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                          color: on ? c.ink : c.inkSecondary,
                        )
                        .merge(look.textStyle)
                        .copyWith(color: look.foreground),
                  ),
                ),
              ),
              if (item.badge != null)
                _Badge(item.badge!, size: 22)
              else if (item.count != null)
                Text(
                  item.count!,
                  style: t.textTheme.micro
                      .copyWith(fontWeight: FontWeight.w700)
                      .tabular
                      .merge(look.textStyle)
                      .copyWith(color: look.foreground),
                ),
            ],
          );
          final pad = t.density.padding(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          );
          final styled =
              !(style?.isEmpty ?? true) || !t.segmentedButtonTheme.isEmpty;
          return ConstrainedBox(
            key: item.key,
            constraints: BoxConstraints(minHeight: t.density.height(48)),
            child: on || styled
                ? NeumorphicSurface(
                    cast: on
                        ? NeumorphicSurfaceLevel.groove
                        : NeumorphicSurfaceLevel.part,
                    style: style,
                    themeStyle: t.segmentedButtonTheme,
                    states: states,
                    padding: pad,
                    child: row,
                  )
                : Padding(padding: pad, child: row),
          );
        },
      ),
    );
  }
}

/// The pilaster: flush with the page's edge, the height of the page, square, since it's part of the wall.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.brand,
    required this.nav,
    required this.active,
    this.action,
    this.rail = const [],
    this.foot = const [],
  });
  final NeumorphicBrand brand;
  final List<NeumorphicNavItem> nav;
  final int active;
  final Widget? action;
  final List<Widget> rail, foot;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return CustomPaint(
      painter: _RailPainter(
        t.colors,
        NeumorphicFlatScope.of(context),
        neumorphicRuleWidth,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
      child: LayoutBuilder(
        builder: (context, box) => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: NeumorphicColumn(
                  gap: 28,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: NeumorphicBrandRow(brand.name, mark: brand.mark),
                    ),
                    ?action,
                    if (nav.isNotEmpty)
                      NeumorphicColumn(
                        gap: 6,
                        children: [
                          for (var i = 0; i < nav.length; i++)
                            _NavRow(item: nav[i], on: i == active),
                        ],
                      ),
                    ...rail,
                    // The foot stands at the bottom of the wall.
                    const NeumorphicGrow(child: SizedBox.shrink()),
                    ...foot,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A section of the pilaster: a small label over its parts.
///
/// ```dart
/// NeumorphicRailSet(label: 'People', children: [NeumorphicWhoRow(initials: 'MA', name: 'A name', isFirst: true)])
/// ```
class NeumorphicRailSet extends StatelessWidget {
  /// Creates a [NeumorphicRailSet].
  const NeumorphicRailSet({
    super.key,
    this.label,
    this.trailing,
    this.gap = 10,
    required this.children,
  });

  /// The text identifying this item or control.
  final String? label;

  /// Optional content at the end of the section heading.
  final Widget? trailing;

  /// Space between adjacent children, in logical pixels.
  final double gap;

  /// The content widgets, in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicColumn(
      gap: gap,
      children: [
        if (label != null)
          trailing == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(label!, style: t.textTheme.micro),
                )
              : NeumorphicSplit(
                  start: Text(label!, style: t.textTheme.micro),
                  end: trailing!,
                ),
        ...children,
      ],
    );
  }
}

/// One place of a list on the pilaster: an LED if it's live, a name, a figure. The current one is pressed.
///
/// ```dart
/// NeumorphicRailLink(label: 'A place', figure: '21.0', live: true, selected: true, onPressed: () {})
/// ```
class NeumorphicRailLink extends StatelessWidget {
  /// Creates a [NeumorphicRailLink].
  const NeumorphicRailLink({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.label,
    this.figure,
    this.live = false,
    this.selected = false,
    this.onPressed,
    this.style,
  });

  /// Face, words and spacing before the navigation component theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// The formatted value to display.
  final String? figure;

  /// Whether to emphasize the active state with the pigment colour.
  final bool live;

  /// Whether this item is selected.
  final bool selected;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicTap(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: label,
      selected: selected,
      style: style,
      themeStyle: t.segmentedButtonTheme,
      radius: NeumorphicRadii.chip,
      child: Builder(
        builder: (context) {
          final look = NeumorphicStyleOf(
            [style, t.segmentedButtonTheme],
            {
              ...NeumorphicStatesScope.of(context),
              if (selected) WidgetState.selected,
            },
          );
          final row = Row(
            children: [
              SizedBox(
                width: 7,
                child: live ? const NeumorphicLed(size: 7) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: neumorphicLabel(
                  Text(
                    label,
                    style: t.textTheme.caption
                        .copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: selected
                              ? t.colors.ink
                              : t.colors.inkSecondary,
                        )
                        .merge(look.textStyle)
                        .copyWith(color: look.foreground),
                  ),
                ),
              ),
              if (figure != null)
                neumorphicLabel(
                  Text(
                    figure!,
                    style: t.textTheme.micro
                        .copyWith(fontWeight: FontWeight.w700)
                        .tabular
                        .merge(look.textStyle)
                        .copyWith(color: look.foreground),
                  ),
                ),
            ],
          );
          final pad =
              look.padding(Directionality.of(context)) ??
              t.density.padding(
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              );
          final face =
              selected ||
              look.fill != null ||
              look.side != null ||
              look.edge != null ||
              look.shape != null;
          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                t.density.height(38),
                look.minimumSize?.height ?? 0,
              ),
              minWidth: look.minimumSize?.width ?? 0,
            ),
            child: face
                ? NeumorphicSurface(
                    cast: selected
                        ? NeumorphicSurfaceLevel.groove
                        : NeumorphicSurfaceLevel.part,
                    style: style,
                    themeStyle: t.segmentedButtonTheme,
                    states: {if (selected) WidgetState.selected},
                    radius: NeumorphicRadii.chip,
                    padding: pad,
                    child: row,
                  )
                : Padding(padding: pad, child: row),
          );
        },
      ),
    );
  }
}

/// Permanent side navigation, using the same softly lit rail as a wide screen.
///
/// ```dart
/// NeumorphicNavigationDrawer(items: destinations, selectedIndex: selected, onDestinationSelected: open)
/// ```
class NeumorphicNavigationDrawer extends StatelessWidget {
  /// Creates a [NeumorphicNavigationDrawer].
  const NeumorphicNavigationDrawer({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.style,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.label,
    this.width = 280,
  });

  /// Destination faces and labels, before segmentedButtonTheme.
  final NeumorphicStyle? style;

  /// The navigation destinations, in display order.
  final List<NeumorphicNavItem> items;

  /// The zero-based index of the selected item.
  final int selectedIndex;

  /// Reports the zero-based index of an activated destination.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional content above the destinations.
  final Widget? header;

  /// Optional content below the destinations.
  final Widget? footer;

  /// An accessible name for this navigation region.
  final String? label;

  /// The preferred width in logical pixels.
  final double width;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final rows = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _NavRow(
              style: style,
              item: NeumorphicNavItem(
                label: items[i].label,
                icon: items[i].icon,
                short: items[i].short,
                count: items[i].count,
                badge: items[i].badge,
                key: items[i].key,
                onPressed: onDestinationSelected == null
                    ? items[i].onPressed
                    : () => onDestinationSelected!(i),
              ),
              on: i == selectedIndex,
            ),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label ?? NeumorphicLocalizations.of(context).mainNavigation,
      child: SizedBox(
        width: width,
        child: CustomPaint(
          painter: _RailPainter(
            t.colors,
            NeumorphicFlatScope.of(context),
            neumorphicRuleWidth,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final head = header == null
                    ? const SizedBox.shrink()
                    : Padding(padding: const EdgeInsets.all(20), child: header);
                final foot = footer == null
                    ? const SizedBox.shrink()
                    : Padding(padding: const EdgeInsets.all(20), child: footer);
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
                    ),
                    child: NeumorphicColumn(
                      children: [
                        head,
                        rows,
                        NeumorphicGrow(child: foot),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Side navigation for a tablet: the drawer's softly lit rail, narrow, each destination a tab of the phone's bar
/// stood in a column (its glyph and its short name, the current one pressed with the pigment in its glyph). For a
/// desktop's labelled list, use [NeumorphicNavigationDrawer].
///
/// ```dart
/// NeumorphicNavigationRail(items: destinations, selectedIndex: selected, onDestinationSelected: open)
/// ```
class NeumorphicNavigationRail extends StatelessWidget {
  /// Creates a [NeumorphicNavigationRail].
  const NeumorphicNavigationRail({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.leading,
    this.trailing,
    this.label,
    this.width = 88,
    this.style,
  });

  /// Destination faces and labels, before segmentedButtonTheme.
  final NeumorphicStyle? style;

  /// The navigation destinations, in display order.
  final List<NeumorphicNavItem> items;

  /// The zero-based index of the selected item.
  final int selectedIndex;

  /// Reports the zero-based index of an activated destination.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional content above the destinations (a menu key, a mark).
  final Widget? leading;

  /// Optional content at the rail's foot.
  final Widget? trailing;

  /// An accessible name for this navigation region.
  final String? label;

  /// The rail's width in logical pixels.
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label ?? NeumorphicLocalizations.of(context).mainNavigation,
      child: SizedBox(
        width: width,
        child: CustomPaint(
          painter: _RailPainter(
            t.colors,
            NeumorphicFlatScope.of(context),
            neumorphicRuleWidth,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
          child: SafeArea(
            right: false,
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 16,
                    ),
                    child: NeumorphicColumn(
                      gap: 0,
                      children: [
                        if (leading != null) ...[
                          Center(child: leading),
                          const SizedBox(height: 16),
                        ],
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _Tab(
                            style: style,
                            item: items[i],
                            on: i == selectedIndex,
                            onPressed: onDestinationSelected == null
                                ? null
                                : () => onDestinationSelected!(i),
                          ),
                        ],
                        if (trailing != null)
                          NeumorphicGrow(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: trailing,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The phone's tab bar: raised, its shoulders on the slab's radius. The current tab is pressed with the pigment in its glyph and heavier
/// words, so it reads with no shadow. The app's act stands in the middle as a small pigment key.
///
/// ```dart
/// NeumorphicNavigationBar(items: const [NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house)], onDestinationSelected: (index) {})
/// ```
class NeumorphicNavigationBar extends StatelessWidget {
  /// Creates a [NeumorphicNavigationBar].
  const NeumorphicNavigationBar({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.style,
    this.onDestinationSelected,
    this.action,
    this.header,
  });

  /// Destination faces and labels, before segmentedButtonTheme.
  final NeumorphicStyle? style;

  /// What stands over the tabs in the same slab: a screen's own foot (a cart's total and its act). Two bars at the foot
  /// are cast as one piece, one light and one shadow; a second slab on the tab bar stacked its shadow on it.
  final Widget? header;

  /// The navigation destinations, in display order.
  final List<NeumorphicNavItem> items;

  /// The zero-based index of the selected item.
  final int selectedIndex;

  /// Reports the zero-based index of an activated destination.
  final ValueChanged<int>? onDestinationSelected;

  /// An optional prominent action placed among the destinations.
  final ShellAction? action;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final tabs = Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom > 26 ? bottom : 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            if (action != null && i == (items.length + 1) ~/ 2) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _ActKey(action: action!),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: _Tab(
                style: style,
                item: items[i],
                on: i == selectedIndex,
                onPressed: onDestinationSelected == null
                    ? null
                    : () => onDestinationSelected!(i),
              ),
            ),
          ],
        ],
      ),
    );
    return CustomPaint(
      painter: _TabBarPainter(
        c,
        NeumorphicFlatScope.of(context),
        t.shapes.corner(NeumorphicRadii.slab),
      ),
      child: header == null
          ? tabs
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: header,
                ),
                tabs,
              ],
            ),
    );
  }
}

class _TabBarPainter extends CustomPainter {
  _TabBarPainter(this.c, this.flat, this.border);
  final NeumorphicRoundedBorder border;
  final NeumorphicColors c;
  final bool flat;
  @override
  void paint(Canvas canvas, Size s) {
    final box = Offset.zero & s;
    final shape = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          box,
          topLeft: Radius.circular(border.radius),
          topRight: Radius.circular(border.radius),
        ),
      );
    if (!flat) {
      // The bar's top edge faces the light: it casts the light up the page, as a raised part's lit side does, and
      // parts from the page by it. A dark shade cast upward was against the light, and floated the bar over the page
      // at rest (laws 2 and 6).
      canvas.drawPath(
        shape.shift(const Offset(0, -10)),
        Paint()
          ..color = c.highlight
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
      );
    }
    canvas.drawPath(
      shape,
      Paint()
        ..isAntiAlias = true
        ..shader = cssLinear(box, 180, [c.faceStart, c.faceEnd]),
    );
    if (!flat) {
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(box.inflate(4))
          ..addPath(shape, const Offset(0, 1)),
        neumorphicFillPaint(c.rim),
      );
      canvas.restore();
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, s.width, 1),
        neumorphicFillPaint(c.quiet),
      );
    }
  }

  @override
  bool shouldRepaint(_TabBarPainter o) =>
      o.c != c || o.flat != flat || o.border != border;
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.on,
    this.onPressed,
    this.style,
  });
  final VoidCallback? onPressed;
  final NeumorphicNavItem item;
  final bool on;
  final NeumorphicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context), c = t.colors;
    return NeumorphicTap(
      label: item.label,
      semanticValue: item.badgeLabel ?? item.badge,
      key: item.key,
      onPressed: onPressed ?? item.onPressed,
      selected: on,
      style: style,
      themeStyle: t.segmentedButtonTheme,
      child: Builder(
        builder: (context) {
          final states = {
            ...NeumorphicStatesScope.of(context),
            if (on) WidgetState.selected,
          };
          final look = NeumorphicStyleOf([
            style,
            t.segmentedButtonTheme,
          ], states);
          final column = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    item.icon,
                    size: look.iconSize ?? 22,
                    color: look.foreground ?? (on ? c.pigment : c.inkTertiary),
                  ),
                  // Held by its foot on the icon's shoulder, so a larger text grows it up and away from the icon: held
                  // by its top, twice the text hung it down over the whole icon.
                  if (item.badge != null)
                    PositionedDirectional(
                      bottom: (look.iconSize ?? 22) - 14,
                      start: 12,
                      child: _Badge(item.badge!),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // A tab's word grows with the text only so far, as a platform's tab bar's does: at twice the size it
              // broke mid-word in its cell (Hom/e, Devi/ces). Its name is spoken whole at any size. Still wider than
              // its cell (five tabs on a phone), the word scales down whole: faded at its end it read 'Account' cut.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: neumorphicLabel(
                    Text(
                      item.short ?? item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: t.textTheme.micro
                          .copyWith(
                            fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                            color: on ? c.ink : c.inkTertiary,
                          )
                          .merge(look.textStyle)
                          .copyWith(color: look.foreground),
                    ),
                  ),
                ),
              ),
            ],
          );
          // A word keeps a breath from its well's walls: 2 in, at large text 'Account' ran from wall to wall.
          final pad = t.density.padding(const EdgeInsets.fromLTRB(6, 8, 6, 6));
          final styled =
              !(style?.isEmpty ?? true) || !t.segmentedButtonTheme.isEmpty;
          return on || styled
              ? NeumorphicSurface(
                  cast: on
                      ? NeumorphicSurfaceLevel.groove
                      : NeumorphicSurfaceLevel.part,
                  style: style,
                  themeStyle: t.segmentedButtonTheme,
                  states: states,
                  padding: pad,
                  child: Center(heightFactor: 1, child: column),
                )
              : Padding(
                  padding: pad,
                  child: Center(heightFactor: 1, child: column),
                );
        },
      ),
    );
  }
}

/// The app's act as a small round key: the pigment when it's the app's invitation, a plain moulded key otherwise.
class _ActKey extends StatelessWidget {
  const _ActKey({required this.action});
  final ShellAction action;
  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    return NeumorphicTap(
      key: action.key,
      onPressed: () => action.onPressed(context),
      label: action.label,
      round: true,
      // A plain key sinks through one depth under a press, as every moulded part does.
      pressRelief: action.accent,
      child: action.accent
          ? neumorphicOwnSize(
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.pigment, c.pigmentDk],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, size: 20, color: c.onPigment),
              ),
            )
          : neumorphicOwnSize(
              width: 44,
              height: 44,
              child: Builder(
                builder: (context) => NeumorphicSurface(
                  cast:
                      NeumorphicStatesScope.of(context)
                          .contains(WidgetState.pressed)
                      ? NeumorphicSurfaceLevel.groove
                      : NeumorphicSurfaceLevel.part,
                  round: true,
                  child: Center(
                    child: Icon(action.icon, size: 20, color: c.ink),
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
/// NeumorphicTab(NeumorphicGlyphs.house, 'Today', ValueKey('open-today'))
/// ```
@immutable
class NeumorphicTab {
  /// Creates a [NeumorphicTab].
  const NeumorphicTab(this.icon, this.label, [this.key]);

  /// The glyph displayed with the content.
  final IconData icon;

  /// The text identifying this item or control.
  final String label;

  /// The identity of this item when building its widget.
  final Key? key;
}

/// A page. On a desktop it stands beside the pilaster, its body on the 12-column main; on a phone a root stands under the brand, a pushed
/// page under its [topBar]; in a sheet, the sheet's own head. [body] is usually `NeumorphicSections(children: [...])`.
///
/// ```dart
/// NeumorphicScaffold(topBar: NeumorphicAppBar(title: 'A page'), body: NeumorphicSections(children: [NeumorphicRow(spans: const [7, 5], children: [a, b])]))
/// ```
class NeumorphicScaffold extends StatelessWidget {
  /// Creates a [NeumorphicScaffold].
  const NeumorphicScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.scrollController,
    this.rail = const [],
    this.railFoot = const [],
    this.railAct,
    this.lead,
    this.actions = const [],
  });

  /// The main page content.
  final Widget body;

  /// Usually `NeumorphicAppBar`: a pushed page's way back and title, a root's page head.
  final Widget? topBar;

  /// What stands fixed at a pushed page's foot (the one action).
  final Widget? footer;

  /// False: [body] takes the height left and scrolls itself.
  final bool scroll;

  /// [body] takes the page's whole width, with no column and no inset.
  final bool fullBleed;

  /// An optional externally owned controller for the page scroll view.
  final ScrollController? scrollController;

  /// What this page stands on the pilaster, under the nav: `NeumorphicRailSet`s. A desktop only; what a phone needs of it, the page shows itself.
  final List<Widget> rail;

  /// What stands at the pilaster's foot, at the bottom of the wall.
  final List<Widget> railFoot;

  /// A wide act above the nav, on the pilaster. If it's there, it's the page's one act on a desktop.
  final Widget? railAct;

  /// What stands in the brand's place at a phone's top: a way back, on a page that's a root of its tab and also a child of another.
  final Widget? lead;

  /// At the end of the phone's top, by the brand: a chip, monograms, a round key.
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final chrome = NeumorphicChromeScope.maybeOf(context);
    final register = RoutePresentation.of(context);
    final sheet = register == RoutePresentation.sheet;
    final root = register == RoutePresentation.root;
    final showRail = t.desk && chrome != null && !sheet;
    final phoneRoot = !t.desk && chrome != null && root;
    final inset = sheet
        ? const EdgeInsets.fromLTRB(20, 14, 20, 24)
        : t.desk
        ? const EdgeInsets.fromLTRB(48, 40, 48, 56)
        : EdgeInsets.fromLTRB(20, phoneRoot ? 12 : 16, 20, 32);
    final barAbove = topBar != null && (!root || sheet);
    final barInside = topBar != null && !barAbove;
    final column = fullBleed
        ? body
        : Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1264),
              // The page holds its cards and heads to its margins (ui_core's keyline check).
              child: DesignKeylineRegion(
                label: 'page',
                child: Padding(
                  padding: inset,
                  child: barInside
                      ? NeumorphicColumn(gap: 28, children: [topBar!, body])
                      : body,
                ),
              ),
            ),
          );
    final phoneHead = phoneRoot
        ? Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 12,
              20,
              0,
            ),
            child: _PhoneTop(brand: chrome.brand, lead: lead, actions: actions),
          )
        : null;
    final Widget content;
    if (scroll) {
      content = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: t.desk),
        child: SingleChildScrollView(
          controller: scrollController,
          child: NeumorphicColumn(children: [?phoneHead, column]),
        ),
      );
    } else {
      final head = [
        ?phoneHead,
        if (barInside)
          Padding(
            padding: EdgeInsets.fromLTRB(inset.left, inset.top, inset.right, 0),
            child: topBar,
          ),
      ];
      final below = fullBleed
          ? body
          : DesignKeylineRegion(
              label: 'page',
              child: Padding(padding: inset, child: body),
            );
      // The head stands above the page and is painted after it: the casts of its keys fall over the page's wall. In a
      // column the page, painted second, cut them off along a straight line.
      content = head.isEmpty
          ? below
          : CustomMultiChildLayout(
              delegate: _HeadOverPage(),
              children: [
                LayoutId(id: _HeadOverPage.page, child: below),
                LayoutId(
                  id: _HeadOverPage.head,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: head,
                  ),
                ),
              ],
            );
    }
    final page = Column(
      mainAxisSize: sheet ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (barAbove) topBar!,
        sheet ? Flexible(child: content) : Expanded(child: content),
        if (footer != null)
          CustomPaint(
            painter: _TabBarPainter(
              t.colors,
              NeumorphicFlatScope.of(context),
              t.shapes.corner(NeumorphicRadii.slab),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: t.desk && !sheet
                    ? Align(
                        alignment: AlignmentDirectional.centerEnd,
                        heightFactor: 1,
                        child: SizedBox(width: 360, child: footer!),
                      )
                    : footer!,
              ),
            ),
          ),
      ],
    );
    return ColoredBox(
      color: t.colors.ground,
      // The pilaster and the page are two traversal groups: Tab walks the pilaster, then the page from its top, and never
      // jumps across between rows that happen to stand level (a page's second field beside a pilaster's place).
      child: showRail
          ? Stack(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 272),
                  child: FocusTraversalGroup(child: page),
                ),
                // Second in the tree, so its shadow falls over the page's wall.
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: 272,
                  child: FocusTraversalGroup(
                    child: _Rail(
                      brand: chrome.brand,
                      nav: chrome.nav,
                      active: chrome.active,
                      action:
                          railAct ??
                          (chrome.action == null
                              ? null
                              : _WideAct(action: chrome.action!)),
                      rail: rail,
                      foot: railFoot,
                    ),
                  ),
                ),
              ],
            )
          : page,
    );
  }
}

class _WideAct extends StatelessWidget {
  const _WideAct({required this.action});
  final ShellAction action;
  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: action.key,
    child: action.accent
        ? NeumorphicButton.filled(
            action.label ?? '',
            icon: action.icon,
            wide: true,
            onPressed: () => action.onPressed(context),
          )
        : NeumorphicButton(
            action.label ?? '',
            icon: action.icon,
            wide: true,
            onPressed: () => action.onPressed(context),
          ),
  );
}

/// A column of a head over a page, painted page first: the head's height from the head, the page the rest.
class _HeadOverPage extends MultiChildLayoutDelegate {
  _HeadOverPage();

  static const Object head = 'head', page = 'page';

  @override
  void performLayout(Size size) {
    final top = layoutChild(
      head,
      BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: size.height,
      ),
    ).height;
    positionChild(head, Offset.zero);
    layoutChild(
      page,
      BoxConstraints.tight(Size(size.width, math.max(0, size.height - top))),
    );
    positionChild(page, Offset(0, top));
  }

  @override
  bool shouldRelayout(_HeadOverPage oldDelegate) => false;
}

class _PhoneTop extends StatelessWidget {
  const _PhoneTop({required this.brand, this.lead, required this.actions});
  final NeumorphicBrand brand;
  final Widget? lead;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final words =
        lead ??
        (brand.name.isEmpty
            ? const NeumorphicBrandMark()
            : NeumorphicBrandRow(brand.name, mark: brand.mark));
    if (actions.isEmpty) return words;
    return NeumorphicFitRow(
      fill: 0,
      gap: 10,
      fillShare: .3,
      children: [
        words,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              actions[i],
            ],
          ],
        ),
      ],
    );
  }
}

/// A page's sections, one under another on the page's gap: 28, the air a soft shadow needs.
///
/// ```dart
/// NeumorphicSections(children: [NeumorphicPageHead(title: 'A page'), NeumorphicRow(spans: const [7, 5], children: [a, b])])
/// ```
class NeumorphicSections extends StatelessWidget {
  /// Creates a [NeumorphicSections].
  const NeumorphicSections({super.key, required this.children, this.gap = 28});

  /// The content widgets, in reading order.
  final List<Widget> children;

  /// Space between adjacent children, in logical pixels.
  final double gap;
  @override
  Widget build(BuildContext context) =>
      NeumorphicColumn(gap: gap, children: children);
}

/// The way out of a pushed page or a sheet: a round moulded key.
///
/// ```dart
/// NeumorphicBackButton(onPressed: () {})
/// ```
class NeumorphicBackButton extends StatelessWidget {
  /// Creates a [NeumorphicBackButton].
  const NeumorphicBackButton({super.key, this.close = false, this.onPressed});

  /// Whether to present a close glyph instead of a back arrow.
  final bool close;

  /// Called when the item is activated.
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => NeumorphicRoundButton(
    close
        ? NeumorphicGlyphs.x
        // Back points to where the line starts: left, or right in a right-to-left app.
        : Directionality.of(context) == TextDirection.rtl
        ? NeumorphicGlyphs.chevronRight
        : NeumorphicGlyphs.chevronLeft,
    iconSize: 20,
    label: close
        ? NeumorphicLocalizations.of(context).close
        : NeumorphicLocalizations.of(context).back,
    onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
  );
}

/// A page's head: on a root, the page's title; on a pushed page or a sheet, the route's way out and its title, at most two actions at the end.
/// A page never authors its own back or close: leave [leading] unset, or pass [autoLeading] to key it.
///
/// ```dart
/// NeumorphicAppBar(title: 'A page', leading: NeumorphicAppBar.autoLeading(context, key: const ValueKey('back')))
/// ```
class NeumorphicAppBar extends StatelessWidget {
  /// Creates a [NeumorphicAppBar].
  const NeumorphicAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  /// The primary heading.
  final String? title;

  /// Secondary information displayed beside the heading.
  final String? subtitle;

  /// Optional content before the main text.
  final Widget? leading;

  /// Actions displayed after the title.
  final List<Widget> actions;

  /// The route's own exit: the way back on a pushed page, the close on a sheet, nothing on a root.
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    final register = RoutePresentation.of(context);
    if (register == RoutePresentation.root) return null;
    return NeumorphicBackButton(
      key: key,
      close: register == RoutePresentation.sheet,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final exit = leading ?? autoLeading(context);
    final end = actions.isEmpty
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions[i],
              ],
            ],
          );
    if (exit == null) {
      if (title == null) {
        return end == null
            ? const SizedBox.shrink()
            : Align(
                alignment: AlignmentDirectional.centerEnd,
                heightFactor: 1,
                child: end,
              );
      }
      return NeumorphicPageHead(
        title: title!,
        subtitle: subtitle,
        trailing: end,
      );
    }
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: t.desk
            ? const EdgeInsets.fromLTRB(48, 16, 48, 0)
            : const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: [
            exit,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The bar's title is the page's heading, as Material's app bar says it: a reader jumps to it, and the
                  // keys round it are a bar's, not a stepper's.
                  if (title != null)
                    Semantics(
                      header: true,
                      child: neumorphicLabel(
                        Text(title!, style: t.textTheme.title),
                      ),
                    ),
                  if (subtitle != null)
                    Text(subtitle!, style: t.textTheme.caption),
                ],
              ),
            ),
            if (end != null) ...[const SizedBox(width: 10), end],
          ],
        ),
      ),
    );
  }
}

/// A one-line text field the generated stubs draw; [NeumorphicTextField] is the same field with more to say.
///
/// ```dart
/// NeumorphicInput(key: const ValueKey('name'), hint: 'A name', onChanged: (text) {})
/// ```
class NeumorphicInput extends StatelessWidget {
  /// Creates a [NeumorphicInput].
  const NeumorphicInput({
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.style,
  });

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  /// Placeholder text shown when the input is empty.
  final String? hint;

  /// The initial text when no controller is supplied.
  final String? initialValue;

  /// An optional externally owned text controller.
  final TextEditingController? controller;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the current text.
  final ValueChanged<String>? onSubmitted;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => NeumorphicTextField(
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
    hint: hint,
    controller: controller,
    initialValue: initialValue,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}

/// A photograph from a declared media slot, on the control radius; until it loads, or if it never does, the plaster one step off the
/// card with the look's mark pressed into it: it stays dark at night, so a shelf of them isn't a wall of lit blocks. It takes the
/// width it's given and sets its height by [aspect]. A piece with no photograph of its own is drawn, not missed: [glyph] puts its
/// sign on a raised cap in the same well, so a shelf of them reads as things and not as holes. Keep the missing state for one.
///
/// ```dart
/// NeumorphicMedia(slotId: 'item-1', aspect: 1, label: 'A piece')
/// ```
///
/// ```dart
/// NeumorphicMedia(glyph: NeumorphicGlyphs.lamp, label: 'A lamp')
/// ```
class NeumorphicMedia extends StatelessWidget {
  /// Creates a [NeumorphicMedia].
  const NeumorphicMedia({
    super.key,
    this.slotId,
    this.image,
    this.child,
    this.glyph,
    this.aspect = 4 / 3,
    this.label,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
  }) : assert(aspect > 0);

  /// A directly supplied picture. The child takes precedence when both are given.
  final ImageProvider? image;

  /// Custom picture content, using the same frame as a photo.
  final Widget? child;

  /// A declared media slot.
  final String? slotId;

  /// The piece's sign, drawn in place of a photograph.
  final IconData? glyph;

  /// The width divided by the height of the media or placeholder.
  final double aspect;

  /// The text identifying this item or control.
  final String? label;

  /// How the image is fitted into its allotted area.
  final BoxFit fit;

  /// Which part of the image remains visible when cropped.
  final AlignmentGeometry alignment;

  /// Only for a thumbnail in a row: 48 to 96. Anywhere else it takes the width it's given.
  final double? width;
  @override
  Widget build(BuildContext context) {
    final small = width != null && width! < 72;
    // The mark grows with the frame: a fixed one in a wide picture read as a stray dot, not as a picture missing.
    Widget mark() => small
        ? const Center(child: NeumorphicMark(size: 24))
        : LayoutBuilder(
            builder: (context, box) => Center(
              child: NeumorphicMark(
                size: (box.biggest.shortestSide * .3).clamp(40.0, 104.0),
              ),
            ),
          );
    final picture = Semantics(
      image: label != null,
      label: label,
      child: AspectRatio(
        aspectRatio: aspect,
        child: NeumorphicSurface(
          cast: NeumorphicSurfaceLevel.well,
          radius: NeumorphicRadii.control,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              NeumorphicTheme.of(context).shapes
                  .corner(NeumorphicRadii.control)
                  .radius,
            ),
            child:
                child ??
                (image != null
                    ? Image(
                        image: image!,
                        fit: fit,
                        alignment: alignment,
                        errorBuilder: (_, _, _) => mark(),
                        frameBuilder: (context, picture, frame, synchronous) =>
                            frame == null ? mark() : picture,
                      )
                    : glyph != null
                    ? _GlyphArt(glyph!, small: small)
                    : slotId == null
                    ? mark()
                    : MediaSlotImage(
                        slotId: slotId!,
                        fallback: mark(),
                        fit: fit,
                      )),
          ),
        ),
      ),
    );
    return width == null
        ? NeumorphicFill(maxWidth: 720, child: picture)
        : neumorphicOwnSize(width: width, child: picture);
  }
}

/// A picture over its words, on a slab: one piece of a collection, a place, a person. The picture is your media slot, or the piece's
/// [glyph] when it has no photograph. Lay them out in `NeumorphicGridOf`, or a `NeumorphicRow` of `[4, 4, 4]`.
///
/// ```dart
/// NeumorphicPictureCard(slotId: 'item-1', title: 'First piece', subtitle: 'Kind A', trailing: const NeumorphicTag('New'), onPressed: open)
/// ```
///
/// ```dart
/// NeumorphicPictureCard(glyph: NeumorphicGlyphs.armchair, title: 'A chair', figure: '62')
/// ```
class NeumorphicPictureCard extends StatelessWidget {
  /// Creates a [NeumorphicPictureCard].
  const NeumorphicPictureCard({
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.style,
    this.slotId,
    this.glyph,
    required this.title,
    this.subtitle,
    this.figure,
    this.trailing,
    this.aspect = 4 / 3,
    this.onPressed,
  });

  /// A declared media slot.
  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The media slot identifier used to resolve a supplied image.
  final String? slotId;

  /// The piece's sign, drawn in place of a photograph.
  final IconData? glyph;

  /// The primary heading.
  final String title;

  /// Secondary information displayed beside the heading.
  final String? subtitle;

  /// A number that belongs to the piece.
  final String? figure;

  /// A `NeumorphicTag` or `NeumorphicStatus`.
  final Widget? trailing;

  /// The width divided by the height of the media or placeholder.
  final double aspect;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final card = NeumorphicSlab(
      style: style,
      padding: const EdgeInsets.all(12),
      child: NeumorphicColumn(
        children: [
          NeumorphicMedia(
            slotId: slotId,
            glyph: glyph,
            aspect: aspect,
            label: title,
          ),
          // The words start where the picture does: one keyline down the card.
          NeumorphicGrow(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
              child: NeumorphicColumn(
                children: [
                  Text(title, style: t.textTheme.title),
                  if (subtitle != null)
                    Text(subtitle!, style: t.textTheme.caption),
                  if (figure != null || trailing != null) ...[
                    const SizedBox(height: 8),
                    NeumorphicSplit(
                      start: figure == null
                          ? const SizedBox.shrink()
                          : Text(figure!, style: t.textTheme.value.tabular),
                      end: trailing ?? const SizedBox.shrink(),
                      gap: 8,
                      runGap: 6,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return NeumorphicFill(
      maxWidth: 480,
      child: onPressed == null
          ? card
          : NeumorphicTap(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: onPressed,
              label: title,
              child: card,
            ),
    );
  }
}

/// A piece drawn by its sign: a raised cap in the well with the glyph printed on it, in ink. A thumbnail keeps only the glyph.
class _GlyphArt extends StatelessWidget {
  const _GlyphArt(this.glyph, {this.small = false});
  final IconData glyph;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    if (small) {
      return Center(child: Icon(glyph, size: 22, color: c.inkSecondary));
    }
    return LayoutBuilder(
      builder: (context, box) {
        final cap = math.min(112.0, box.maxHeight * .56).floorToDouble();
        return Center(
          child: neumorphicOwnSize(
            width: cap,
            height: cap,
            child: NeumorphicSurface(
              cast: NeumorphicSurfaceLevel.part,
              round: true,
              child: Center(
                child: Icon(glyph, size: cap * .44, color: c.inkSecondary),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// While a page's data is on its way: the look's mark, quietly.
///
/// ```dart
/// NeumorphicLoadingState(label: 'Loading rooms')
/// ```
class NeumorphicLoadingState extends StatelessWidget {
  /// Creates a [NeumorphicLoadingState].
  const NeumorphicLoadingState({super.key, this.label});

  /// An accessible description of the pending operation.
  final String? label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label ?? NeumorphicLocalizations.of(context).loading,
    child: const Center(
      child: Padding(padding: EdgeInsets.all(40), child: NeumorphicMark()),
    ),
  );
}

/// When a page's data could not load: what happened, and a way to try again.
///
/// ```dart
/// NeumorphicErrorState(title: 'Could not load', message: 'Check your connection.', onRetry: retry)
/// ```
class NeumorphicErrorState extends StatelessWidget {
  /// Creates a [NeumorphicErrorState].
  const NeumorphicErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
  });

  /// The primary heading.
  final String title;

  /// The explanatory message.
  final String? message;

  /// Called when the retry action is activated.
  final VoidCallback? onRetry;

  /// The retry action's words; null: Try again.
  final String? retryLabel;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NeumorphicMark(),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: t.textTheme.value),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: t.textTheme.caption,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              Center(
                widthFactor: 1,
                child: NeumorphicButton(
                  retryLabel ?? NeumorphicLocalizations.of(context).tryAgain,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
