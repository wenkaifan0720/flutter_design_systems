import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/face.dart';
import '../internal/shell_faces.dart';
import '../internal/state_face.dart';
import '../theme.dart';

/// One destination of the app's root, as generated apps declare a tab: its
/// glyph, the [label] the tab bar and the sidebar print (and speak) and the
/// walkthrough [key] set on its hit target, positionally. While current it
/// wears its [selectedIcon] (null keeps [icon]); its page stands on its
/// [ground] (the design kit's surface or media). As the bar's green disc
/// (the app's main act), the sidebar's green act says its [actLabel]
/// ([LedgerNavItem.act]).
///
/// ```dart
/// LedgerNavItem(LucideIcons.chartPie, 'Spending', ValueKey('open-spending'))
/// ```
@immutable
class LedgerNavItem {
  /// A destination with [icon] and [label].
  const LedgerNavItem(this.icon, this.label, [this.key])
    : selectedIcon = null,
      ground = ChromeGround.surface,
      actLabel = null;

  /// The app's main act as a tab (the green disc on a phone), whose act in
  /// the sidebar says [actLabel]: "Move money" where the disc is "Move".
  ///
  /// ```dart
  /// LedgerNavItem.act(LucideIcons.arrowRightLeft, 'Move', actLabel: 'Move money')
  /// ```
  const LedgerNavItem.act(
    this.icon,
    this.label, {
    required String this.actLabel,
    this.key,
  }) : selectedIcon = null,
       ground = ChromeGround.surface;

  /// The item a runtime [NavTab] asks for.
  LedgerNavItem.fromTab(NavTab tab)
    : icon = tab.icon,
      label = tab.label,
      selectedIcon = tab.selectedIcon,
      key = tab.key,
      ground = tab.ground,
      actLabel = null;

  /// The destination's glyph.
  final IconData icon;

  /// The destination's name, printed and spoken.
  final String label;

  /// The glyph while current; null keeps [icon].
  final IconData? selectedIcon;

  /// The walkthrough key set on its hit target.
  final Key? key;

  /// What its page stands on: the design kit's surface or media.
  final ChromeGround ground;

  /// The sidebar act's words when this item is the disc.
  final String? actLabel;
}

/// The phone's tab bar, as the source's `.tabbar` draws it: raised
/// paper 84 tall with a rule over it, five columns of a 22 glyph over its
/// name in the third ink (the current one in the ink, the green tick under
/// it), the middle destination drawn as the green disc ringed in the paper
/// (Move). The columns stand in one row hung from under the rule, as tall
/// as its tallest column and never shorter than the bar's room over its 22
/// foot, each column at the row's foot: the disc's column fills the bar
/// from its rule and the tabs end 7 over the bar's foot, where the
/// browser's grid sets them. A [ShellAction] given to the shell stands
/// as the disc instead, between the tabs. [accessory] rides 8 over the
/// bar. It is paper, opaque: the source frosts it, but a page scrolled
/// under glass smears through (no glass, no glow).
///
/// ```dart
/// LedgerNavBar(items: tabs, selectedIndex: 0, onDestinationSelected: select)
/// ```
class LedgerNavBar extends StatelessWidget {
  /// A tab bar of [items], [selectedIndex] current.
  const LedgerNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.action,
    this.accessory,
    super.key,
  });

  /// The destinations, in order.
  final List<LedgerNavItem> items;

  /// The index of the current destination.
  final int selectedIndex;

  /// Called with the index of the destination pressed.
  final ValueChanged<int> onDestinationSelected;

  /// The shell's act, drawn as the disc.
  final ShellAction? action;

  /// A widget riding 8 over the bar.
  final Widget? accessory;

  /// Which tab is the disc: the middle of five, when no act takes it.
  static int? discTab(int count, {required bool action}) =>
      !action && count == 5 ? 2 : null;

  /// Where an act's disc stands among the tabs: the middle.
  static int discAction(int count) => count ~/ 2;

  /// Whether a bar of [count] tabs (and the shell's act, with [action])
  /// raises the disc.
  static bool hasDisc(int count, {required bool action}) =>
      action || discTab(count, action: false) != null;

  /// The height of a tab's column in [context]: its glyph and the 6 under
  /// it (the disc and the 4 it leaves, with [disc]), its name's [lines] (set
  /// by [scaler], else the reader's), the 4 over the tick and the tick: 48,
  /// and 76 for the disc's.
  static double columnIn(
    BuildContext context, {
    required bool disc,
    int lines = 1,
    TextScaler? scaler,
  }) {
    final tab = context.ledgerTheme.tab;
    final line =
        (scaler ?? MediaQuery.textScalerOf(context)).scale(tab.fontSize!) *
        tab.height! *
        lines;
    return (disc
            ? LedgerChromeMetrics.disc +
                  LedgerChromeMetrics.tabGap -
                  LedgerChromeMetrics.discSink
            : LedgerChromeMetrics.tabGlyph + LedgerChromeMetrics.tabGap) +
        line +
        (LedgerChromeMetrics.tabGap - LedgerChromeMetrics.tickLift) +
        LedgerChromeMetrics.tick;
  }

  /// The band a bar of [count] tabs stands in over a device inset of
  /// [inset]: [heightIn], or its rule and its row where a larger text
  /// scale makes the row the taller. With the tabs' and the act's [labels]
  /// and the bar's [width] (the screen's when null), it counts the second
  /// line their names break onto at a large text size.
  static double bandIn(
    BuildContext context, {
    required double inset,
    required int count,
    required bool action,
    List<String> labels = const [],
    double? width,
  }) {
    final disc = hasDisc(count, action: action);
    final cells = count + (action ? 1 : 0);
    final names = labels.isEmpty || cells == 0
        ? null
        : _names(
            context,
            labels,
            ((width ?? MediaQuery.sizeOf(context).width) -
                    2 * LedgerChromeMetrics.tabBarSide) /
                cells,
          );
    final column = names == null || names.lines == 1
        ? columnIn(context, disc: disc)
        : columnIn(
            context,
            disc: disc,
            lines: names.lines,
            scaler: names.scaler,
          );
    return math.max(heightIn(inset), _rule + column);
  }

  /// The bar's height over a device inset of [inset]: 84, its 22 foot
  /// grown to the inset when the inset is larger.
  static double heightIn(double inset) =>
      LedgerChromeMetrics.tabBarHeight -
      LedgerChromeMetrics.tabBarFoot +
      math.max(LedgerChromeMetrics.tabBarFoot, inset);

  /// The rule over the bar, 1 (`border-top: 1px`).
  static const double _rule = 1;

  /// The text scaler every tab's name sets at, and its lines: the reader's
  /// size on one line while the widest of [labels] fits a column [column]
  /// wide with the least room between names ([_Tab._nameGap], grown as a
  /// word space grows). Past that, a name of two words breaks between them
  /// onto a second line, and the size shrinks only as far as the widest
  /// word needs (a one-word name's, whole), so a large text size still
  /// reads large; where no break would help, all set on one line at the
  /// size the widest name needs.
  static ({TextScaler scaler, int lines}) _names(
    BuildContext context,
    List<String> labels,
    double column,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    if (!column.isFinite || column <= 0) return (scaler: scaler, lines: 1);
    final style = context.ledgerTheme.tab;
    final room = column - scaler.scale(_Tab._nameGap);
    if (room <= 0) return (scaler: scaler, lines: 1);
    double width(String words) {
      final painter = TextPainter(
        text: TextSpan(text: words, style: style),
        textScaler: scaler,
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    var whole = 0.0;
    var broken = 0.0;
    for (final label in labels) {
      final w = width(label);
      whole = math.max(whole, w);
      final words = label.split(' ').where((w) => w.isNotEmpty).toList();
      broken = math.max(
        broken,
        w <= room || words.length < 2 ? w : words.map(width).reduce(math.max),
      );
    }
    if (whole <= room) return (scaler: scaler, lines: 1);
    if (broken < whole) {
      // A hair under the room, so a word set at the shrunk size never
      // breaks within itself.
      final fit = broken <= room ? 1.0 : (room - _wordSlack) / broken;
      return (scaler: fit >= 1 ? scaler : _ShrunkScaler(scaler, fit), lines: 2);
    }
    return (scaler: _ShrunkScaler(scaler, room / whole), lines: 1);
  }

  static const double _wordSlack = 1;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<LedgerNavItem>('items', items))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final inset = MediaQuery.paddingOf(context).bottom;
    final act = action;
    final disc = discTab(items.length, action: act != null);
    // Under [LedgerNavigationFrame] ui_core's shell presses the tabs (one
    // tab stop, the arrows along them, a tab bar to a screen reader) and
    // the bar paints them.
    final built = LedgerShellDestinations.maybeOf(context);
    _Tab tab(int i, {Set<WidgetState>? states}) => _Tab(
      key: items[i].key,
      icon: i == selectedIndex
          ? (items[i].selectedIcon ?? items[i].icon)
          : items[i].icon,
      label: items[i].label,
      selected: i == selectedIndex,
      disc: i == disc,
      states: states,
      onTap: states != null ? null : () => onDestinationSelected(i),
    );
    final cells = <Widget>[
      for (var i = 0; i < items.length; i++)
        if (built != null && i < built.length) built[i] else tab(i),
    ];
    if (act != null) {
      final press = _Tab(
        key: act.key,
        icon: act.icon,
        label: act.label ?? '',
        selected: false,
        disc: true,
        onTap: () => act.onPressed(context),
      );
      cells.insert(
        discAction(items.length),
        // ui_core's tab bar holds tabs alone: the frame speaks the act
        // beside it.
        built == null ? press : ExcludeSemantics(child: press),
      );
    }
    final ground = DecoratedBox(
      decoration: BoxDecoration(
        color: t.tabBarFill,
        border: Border(top: BorderSide(color: t.border)),
      ),
    );
    final height = heightIn(inset);
    final foot = math.max(LedgerChromeMetrics.tabBarFoot, inset);
    // The source's grid hangs its one row from under the rule: the row is
    // as tall as its tallest column (the disc's 76) and never shorter than
    // the room over the foot (61), and every column stands at the row's
    // foot. The disc's column so fills the bar from the rule, and the row
    // runs 15 into the 22 foot, the tabs ending 7 over the bar's foot. The
    // bar grows only where a larger text scale makes the row taller than
    // all of it.
    final bar = Stack(
      children: [
        Positioned.fill(child: ground),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LedgerChromeMetrics.tabBarSide,
              _rule,
              LedgerChromeMetrics.tabBarSide,
              0,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height - _rule - foot),
                // A name wider than its column at a large text size sets
                // smaller on its one line rather than lose its end; every
                // name sets at the size the widest needs, so the bar's
                // names stay one size (each shrinking to its own column
                // read as five sizes of type).
                child: LayoutBuilder(
                  builder: (context, row) {
                    final names = _names(context, [
                      for (final item in items) item.label,
                      ?act?.label,
                    ], row.maxWidth / cells.length);
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: names.scaler),
                      child: _NameLines(
                        lines: names.lines,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final cell in cells) Expanded(child: cell),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LedgerChromeMetrics.accessoryGap,
      children: [?accessory, bar],
    );
    if (built != null) {
      // ui_core's tab bar holds the tabs alone.
      return LedgerDestinationFaces(
        paint: (context, i, states) => tab(i, states: states),
        child: column,
      );
    }
    return Semantics(container: true, explicitChildNodes: true, child: column);
  }
}

/// One tab: its glyph (or the disc), its name, and the tick under it.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.disc,
    this.onTap,
    this.states,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool disc;

  /// Its own press; null where ui_core's shell presses it ([states]).
  final VoidCallback? onTap;

  /// The shell's press's states: its face alone, the focus rule under it
  /// while the keys hold it.
  final Set<WidgetState>? states;

  // The least room between two tabs' names.
  static const double _nameGap = 4;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final ink = selected || disc ? t.textPrimary : t.textTertiary;
    final Widget? mark;
    if (disc) {
      const d = LedgerChromeMetrics.disc;
      mark = Padding(
        // The disc stands 2 into the gap under it.
        padding: const EdgeInsets.only(
          bottom: LedgerChromeMetrics.tabGap - LedgerChromeMetrics.discSink,
        ),
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.accent,
            // The paper ring round the disc, over any drop a theme gives it
            // (Ledger's own give none), as CSS draws its first shadow
            // topmost (a BoxDecoration paints its last).
            boxShadow: [
              ...t.discShadow,
              BoxShadow(
                color: t.discRing,
                spreadRadius: LedgerChromeMetrics.discRing,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: LedgerChromeMetrics.tabGlyph,
            color: t.onAccent,
          ),
        ),
      );
    } else {
      mark = null;
    }
    // The chosen tab's ink and its green tick land at once, in the frame its
    // page does: a selection never trails the page it names.
    final face = LedgerFace(
      duration: Duration.zero,
      style: LedgerFaceStyle(
        ink: ink,
        ground: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? t.accent : null,
        ),
      ),
      builder: (context, s, _) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          mark ??
              Padding(
                padding: const EdgeInsets.only(
                  bottom: LedgerChromeMetrics.tabGap,
                ),
                child: Icon(
                  icon,
                  size: LedgerChromeMetrics.tabGlyph,
                  color: s.ink,
                ),
              ),
          // A name wider than its column at a large text size breaks
          // between its words ([_NameLines]) or sets smaller on its one
          // line rather than lose its end, never closer than [_nameGap] to
          // its neighbour's (a gap that grows with the words, as a word
          // space does).
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.textScalerOf(context).scale(_nameGap) / 2,
            ),
            child: _NameLines.of(context) > 1
                ? Text(
                    label,
                    maxLines: _NameLines.of(context),
                    textAlign: TextAlign.center,
                    style: t.tab.colored(s.ink),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: t.tab.colored(s.ink),
                    ),
                  ),
          ),
          // The tick stands 2 up into the 6 under the name.
          const SizedBox(
            height: LedgerChromeMetrics.tabGap - LedgerChromeMetrics.tickLift,
          ),
          Container(
            width: LedgerChromeMetrics.tick,
            height: LedgerChromeMetrics.tick,
            decoration: s.ground,
          ),
        ],
      ),
    );
    // Held, a tab's glyph and name deepen and its paper takes the ink; the
    // disc's green deepens as the primary act's does, its name under it
    // left on the bar's paper.
    final shell = states;
    if (shell != null) {
      return LedgerStateFace(
        states: shell,
        radius: t.smallRadius,
        washes: !disc,
        child: face,
      );
    }
    return DesignPressable(
      onPressed: onTap,
      semanticSelected: selected,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, child) => LedgerStateFace(
        states: states,
        radius: t.smallRadius,
        washes: !disc,
        child: child!,
      ),
      child: face,
    );
  }
}

/// The lines a bar's names may take: two where a name breaks between its
/// words at a large text size, else one.
class _NameLines extends InheritedWidget {
  const _NameLines({required this.lines, required super.child});

  final int lines;

  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_NameLines>()?.lines ?? 1;

  @override
  bool updateShouldNotify(_NameLines old) => old.lines != lines;
}

/// [base], every size times [factor]: the tab bar's names, set together at
/// the size the widest needs.
@immutable
class _ShrunkScaler extends TextScaler {
  const _ShrunkScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use, TextScaler requires it.
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _ShrunkScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
