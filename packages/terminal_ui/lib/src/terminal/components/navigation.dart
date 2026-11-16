/// Getting around: the title line, tabs, the window list at a phone's foot,
/// the side pane at a desk, and the status line.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/focus_block.dart';
import '../primitives/control.dart';
import '../primitives/spring.dart';
import '../style.dart';
import '../theme.dart';
import 'key_hint.dart';
import 'list_tile.dart';
import 'pane.dart';

/// A place the app's navigation goes: its [label], and the key that goes
/// there ([shortcut], shown beside it).
@immutable
class TermNavigationDestination {
  /// A destination called [label].
  const TermNavigationDestination({
    required this.label,
    this.glyph,
    this.shortcut,
    this.badge,
  });

  /// Its name.
  final String label;

  /// A glyph before the name in the side pane: `~`, `▶`, `≡`.
  final String? glyph;

  /// The key that goes there, written beside it.
  final SingleActivator? shortcut;

  /// A short count after the name (`3`), or null.
  final String? badge;
}

/// One cell of inverse video that grows in as [amount] goes to 1: a chosen
/// tab, a current window.
class _Inverse extends StatelessWidget {
  const _Inverse({
    required this.amount,
    required this.child,
    this.fill,
    this.ink,
  });

  final double amount;
  final Widget child;
  final Color? fill;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final ground = fill ?? theme.foreground;
    return CustomPaint(
      painter: _FillFromFoot(color: ground, amount: amount),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: Color.lerp(ink ?? theme.foreground, theme.background, amount),
        ),
        child: child,
      ),
    );
  }
}

class _FillFromFoot extends CustomPainter {
  const _FillFromFoot({required this.color, required this.amount});

  final Color color;
  final double amount;

  @override
  void paint(Canvas canvas, Size size) {
    final a = amount.clamp(0.0, 1.0);
    if (a <= 0) return;
    final h = size.height * a;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - h, size.width, h),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_FillFromFoot old) =>
      old.color != color || old.amount != amount;
}

/// A tab bar: each tab its number and its label, `1 steps  2 log  3 env`,
/// the chosen one in inverse video. The number is the key that picks it
/// (with Alt), and the app binds it.
///
/// ```dart
/// TermTabBar(
///   tabs: const ['steps', 'log', 'env'],
///   selectedIndex: tab,
///   onTap: (index) => setState(() => tab = index),
/// )
/// ```
class TermTabBar extends StatelessWidget {
  /// Tabs named [tabs].
  const TermTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.showNumbers = true,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.tabBarStyle]: `fill` (the
  /// current tab's inverse), `foreground` (a tab's words) and `edge` (the
  /// keyboard's block at a tab's start).
  final TermStyle? style;

  /// The tabs' labels.
  final List<String> tabs;

  /// The chosen tab.
  final int selectedIndex;

  /// Called with the tab pressed.
  final ValueChanged<int>? onTap;

  /// Whether each tab shows its number.
  final bool showNumbers;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final direction = Directionality.of(context);
    return _MarkedScroll(
      child: Semantics(
        container: true,
        role: SemanticsRole.tabBar,
        explicitChildNodes: true,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) SizedBox(width: cw),
              TermTapTarget(
                child: DesignPressable(
                  onPressed: onTap == null ? null : () => onTap!(i),
                  selected: i == selectedIndex,
                  tab: true,
                  semanticLabel: tabs[i],
                  excludeSemantics: true,
                  mouseCursor: onTap == null
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  builder: (context, states, _) {
                    final own = TermStyleOf([style, theme.tabBarStyle], states);
                    return TermStateSprings(
                      pressed: states.contains(WidgetState.pressed),
                      focused: states.contains(WidgetState.focused),
                      builder: (context, press, focus) => TermSpring(
                        target: i == selectedIndex ? 1 : 0,
                        token: TermMotion.move,
                        spatial: true,
                        builder: (context, t, _) => CustomPaint(
                          // The keyboard's focus: a block at the tab's start,
                          // as a list's row has it.
                          foregroundPainter: focus > 0
                              ? TermFocusBlockPainter(
                                  amount: focus,
                                  color: own.edge ?? theme.accent,
                                  cellWidth: cw,
                                  direction: direction,
                                )
                              : null,
                          child: _Inverse(
                            amount: (t + press * 0.5).clamp(0, 1),
                            fill: own.fill,
                            ink: own.foreground,
                            child: SizedBox(
                              height: grid.lineHeight,
                              child: Padding(
                                padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: cw,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (showNumbers) ...[
                                      ExcludeSemantics(
                                        child: Text(
                                          '${i + 1}',
                                          style: theme.textStyle.copyWith(
                                            color: Color.lerp(
                                              theme.accent,
                                              theme.background,
                                              t,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: cw),
                                    ],
                                    Text(tabs[i], maxLines: 1, softWrap: false),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// The title line at the top of a screen: [leading] (a back key), [title]
/// in bold, [subtitle] dim after it (a path: `atlas-api › runs`; on a
/// short line it keeps its last steps whole, `…#1481 › change`, and on one
/// too short for the title as well, the steps stand alone in its place,
/// so where you are stays), and [actions] at the end. One line under a pointer, two under a finger (its
/// buttons' floor), on the surface's ground with a rule under it.
///
/// ```dart
/// TermTopBar(
///   title: 'slipway',
///   subtitle: 'atlas-api › runs',
///   actions: [TermIconButton(glyph: '/', semanticLabel: 'Search', onPressed: () {})],
/// )
/// ```
class TermTopBar extends StatelessWidget {
  /// A title line.
  const TermTopBar({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.topBarStyle]: `fill` (the
  /// ground), `foreground` (the title) and `edge` (the rule under it).
  final TermStyle? style;

  /// Before the title: a back button.
  final Widget? leading;

  /// The screen's name, read as its heading.
  final String title;

  /// Where it is, dim: a path, a branch.
  final String? subtitle;

  /// Buttons at the end.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final height = grid.ceil(DesignTapTargets.of(context).floorOn()).height;
    final own = TermStyleOf([style, theme.topBarStyle], const {});
    final titleStyle = theme.boldStyle.copyWith(
      color: own.foreground ?? theme.accent,
    );
    return CustomPaint(
      painter: _GroundWithRule(
        ground: own.fill ?? theme.surface,
        rule: own.edge ?? theme.rule,
        stroke: termStroke(theme, grid),
      ),
      child: SizedBox(
        height: height < grid.lineHeight ? grid.lineHeight : height,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: cw),
          child: Row(
            children: [
              if (leading != null) ...[leading!, SizedBox(width: cw)],
              if (subtitle == null) ...[
                Flexible(
                  flex: 0,
                  child: Semantics(
                    container: true,
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                ),
                const Spacer(),
              ] else
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      // A path keeps its end, where you are: its last
                      // steps whole after the title while they fit, then
                      // the steps alone in the title's place, then the
                      // last step's end.
                      final words = subtitle!;
                      final steps = words.split(' › ');
                      final room = c.maxWidth + 0.5;
                      final titled = grid.widthOf(title) + cw;
                      final tails = [
                        for (var k = 0; k < steps.length; k++)
                          k == 0 ? words : '…${steps.sublist(k).join(' › ')}',
                      ];
                      String? shown;
                      var withTitle = true;
                      for (final tail in tails) {
                        if (titled + grid.widthOf(tail) <= room) {
                          shown = tail;
                          break;
                        }
                      }
                      if (shown == null) {
                        withTitle = false;
                        for (final tail in [...tails, steps.last]) {
                          if (grid.widthOf(tail) <= room) {
                            shown = tail;
                            break;
                          }
                        }
                      }
                      if (shown == null) {
                        var tail = '';
                        for (final ch
                            in steps.last.characters.toList().reversed) {
                          if (grid.widthOf('…$ch$tail') > room) break;
                          tail = '$ch$tail';
                        }
                        shown = '…${tail.trimLeft()}';
                      }
                      // Each step isolated, so a right-to-left app reads
                      // the steps from its start in their order whatever
                      // their words (a number, a Latin name): `runs ‹ #1481
                      // ‹ change` from the right, as every screen shows it;
                      // a cut stays at the reading start.
                      final cut = shown.startsWith('…');
                      final path = Text(
                        (cut ? '…' : '') +
                            (cut ? shown.substring(1) : shown)
                                .split(' › ')
                                .map((s) => '\u2068$s\u2069')
                                .join(' › '),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: withTitle ? theme.dimStyle : titleStyle,
                      );
                      if (!withTitle) {
                        return Semantics(
                          container: true,
                          header: true,
                          label: '$title, $words',
                          excludeSemantics: true,
                          child: path,
                        );
                      }
                      return Row(
                        children: [
                          Semantics(
                            container: true,
                            header: true,
                            child: Text(
                              title,
                              maxLines: 1,
                              softWrap: false,
                              style: titleStyle,
                            ),
                          ),
                          SizedBox(width: cw),
                          Expanded(
                            child: Semantics(
                              label: words,
                              excludeSemantics: true,
                              child: path,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              for (final action in actions) ...[SizedBox(width: cw), action],
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
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null));
  }
}

class _GroundWithRule extends CustomPainter {
  const _GroundWithRule({
    required this.ground,
    required this.rule,
    required this.stroke,
    this.top = false,
  });

  final Color ground;
  final Color rule;
  final double stroke;
  final bool top;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final y = top ? stroke / 2 : size.height - stroke / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = rule
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_GroundWithRule old) =>
      old.ground != ground ||
      old.rule != rule ||
      old.stroke != stroke ||
      old.top != top;
}

/// The navigation at a phone's foot, written as a terminal multiplexer lists
/// its windows: `1:home  2:runs*  3:deploy  4:config`, the current one in
/// inverse video and marked `*`, so it reads without colour too.
///
/// ```dart
/// TermNavigationBar(
///   destinations: const [
///     TermNavigationDestination(label: 'home'),
///     TermNavigationDestination(label: 'runs'),
///   ],
///   selectedIndex: 0,
///   onDestinationSelected: (index) {},
/// )
/// ```
class TermNavigationBar extends StatelessWidget {
  /// A window list over [destinations].
  const TermNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style,
  });

  /// Where it goes.
  final List<TermNavigationDestination> destinations;

  /// The current one.
  final int selectedIndex;

  /// Called with the destination pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// Overrides, over the theme's [TermThemeData.navigationBarStyle]: `fill`
  /// (the current item's inverse), `foreground` (the words) and `edge` (the
  /// rule over the bar).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final height = grid.ceil(DesignTapTargets.of(context).floorOn()).height;
    final lines = height < grid.lineHeight ? grid.lineHeight : height;
    final bar = TermStyleOf([style, theme.navigationBarStyle], const {});
    Widget item(int i, String text) => DesignPressable(
      onPressed: onDestinationSelected == null
          ? null
          : () => onDestinationSelected!(i),
      selected: i == selectedIndex,
      semanticSelected: i == selectedIndex,
      semanticLabel: destinations[i].label,
      mouseCursor: onDestinationSelected == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      builder: (context, states, _) => TermStateSprings(
        pressed: states.contains(WidgetState.pressed),
        focused: states.contains(WidgetState.focused),
        builder: (context, press, focus) => TermSpring(
          target: i == selectedIndex ? 1 : 0,
          token: TermMotion.move,
          spatial: true,
          builder: (context, t, _) => Center(
            child: CustomPaint(
              // The keyboard's focus: a block at the window's start, as a
              // list's row has it.
              foregroundPainter: focus > 0
                  ? TermFocusBlockPainter(
                      amount: focus,
                      color: theme.accent,
                      cellWidth: grid.cellWidth,
                      direction: Directionality.of(context),
                    )
                  : null,
              child: _Inverse(
                amount: (t + press * 0.5).clamp(0, 1),
                fill: TermStyleOf([
                  style,
                  theme.navigationBarStyle,
                ], states).fill,
                ink: TermStyleOf([
                  style,
                  theme.navigationBarStyle,
                ], states).foreground,
                child: SizedBox(
                  height: grid.lineHeight,
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: grid.cellWidth,
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        text,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return CustomPaint(
      painter: _GroundWithRule(
        ground: theme.surface,
        rule: bar.edge ?? theme.rule,
        stroke: termStroke(theme, grid),
        top: true,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: lines,
          // Every window by its name while the names have the room, each
          // as wide as its name and the room left over shared evenly round
          // them, the ends too, so the names stand evenly apart whatever
          // their lengths. On a line too narrow for that, as a
          // multiplexer's status line does, the others go by their number
          // and the current one keeps its name.
          child: LayoutBuilder(
            builder: (context, c) {
              final n = destinations.length;
              String words(int i) =>
                  '${i + 1}:${destinations[i].label}${i == selectedIndex ? '*' : ' '}';
              // A slot's name with the current one's mark, so a slot keeps
              // its width whichever is current.
              final wide = [
                for (var i = 0; i < n; i++)
                  grid.widthOf('${i + 1}:${destinations[i].label}*') +
                      grid.cols(2),
              ];
              final roomy =
                  !c.maxWidth.isFinite ||
                  wide.fold(0.0, (a, w) => a + w) <= c.maxWidth;
              final floor = grid
                  .ceil(DesignTapTargets.of(context).floorOn())
                  .width;
              double numbered(int i) =>
                  math.max(floor, grid.cols('${i + 1}'.length + 2));
              var others = 0.0;
              for (var i = 0; i < n; i++) {
                if (i != selectedIndex) others += numbered(i);
              }
              if (roomy) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < n; i++)
                      SizedBox(width: wide[i], child: item(i, words(i))),
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < n; i++)
                    if (i == selectedIndex)
                      Expanded(
                        child: item(
                          i,
                          grid.fit(
                            words(i),
                            c.maxWidth - others - grid.cols(2),
                          ),
                        ),
                      )
                    else
                      SizedBox(width: numbered(i), child: item(i, '${i + 1}')),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// The side pane at a desk: [destinations] as rows, each with its glyph and
/// key, the current one in inverse video, in a pane titled [title], with
/// [footer] rows under them (a project list, a session).
///
/// ```dart
/// TermSideBar(
///   title: 'slipway',
///   destinations: destinations,
///   selectedIndex: 0,
///   onDestinationSelected: (index) {},
/// )
/// ```
class TermSideBar extends StatelessWidget {
  /// A side pane over [destinations].
  const TermSideBar({
    super.key,
    this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.children = const [],
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.sideBarStyle]: `fill` (the
  /// current row's inverse) and `foreground` (the rows' words), and `edge`
  /// (the pane's lines).
  final TermStyle? style;

  /// The pane's title.
  final String? title;

  /// Where it goes.
  final List<TermNavigationDestination> destinations;

  /// The current one.
  final int selectedIndex;

  /// Called with the destination pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// More rows under the destinations.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final rows = TermStyle.layered([style, theme.sideBarStyle]);
    return Semantics(
      explicitChildNodes: true,
      child: TermPane(
        title: title,
        padding: TermInset.zero,
        style: TermStyle(edge: rows.edge),
        // Places past the bottom of a short window scroll; the frame stays.
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < destinations.length; i++)
                TermListTile(
                  leading: destinations[i].glyph == null
                      ? null
                      : ExcludeSemantics(child: Text(destinations[i].glyph!)),
                  title: Text(destinations[i].label),
                  trailing:
                      destinations[i].shortcut != null && termKeysShown(context)
                      ? TermKey.of(destinations[i].shortcut!)
                      : destinations[i].badge == null
                      ? null
                      : Text(destinations[i].badge!, style: theme.dimStyle),
                  selected: i == selectedIndex,
                  style: TermStyle(
                    fill: rows.fill,
                    foreground: rows.foreground,
                  ),
                  onTap: onDestinationSelected == null
                      ? null
                      : () => onDestinationSelected!(i),
                ),
              ...children,
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
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// One stretch of a [TermStatusLine]: words, an optional [tone] ink.
@immutable
class TermStatusSegment {
  /// A segment reading [text].
  const TermStatusSegment(this.text, {this.color, this.semanticLabel});

  /// Its words.
  final String text;

  /// Its ink; null: dim.
  final Color? color;

  /// What a screen reader hears in place of [text].
  final String? semanticLabel;
}

/// The status line at the foot of a screen: [mode] in a block of the
/// accent, then [segments] (the project, the branch, the counts), and at
/// the end the [keys] that work here, written `^K palette  ? help`. One
/// line, on the surface's ground.
///
/// ```dart
/// const TermStatusLine(
///   mode: 'RUNS',
///   segments: [TermStatusSegment('atlas-api'), TermStatusSegment('\u{E0A0} main')],
///   keys: [(keys: '^K', label: 'palette')],
/// )
/// ```
class TermStatusLine extends StatelessWidget {
  /// A status line.
  const TermStatusLine({
    super.key,
    this.mode,
    this.segments = const [],
    this.keys = const [],
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.statusLineStyle]: `fill`
  /// (the ground) and `foreground` (a segment's words without its own
  /// ink).
  final TermStyle? style;

  /// The mode or the screen, in a block of the accent.
  final String? mode;

  /// What is going on.
  final List<TermStatusSegment> segments;

  /// The keys that work here and what they do.
  final List<({String keys, String label})> keys;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final own = TermStyleOf([style, theme.statusLineStyle], const {});
    return ColoredBox(
      color: own.fill ?? theme.surface,
      child: SizedBox(
        height: grid.lineHeight,
        child: Row(
          children: [
            if (mode != null)
              ColoredBox(
                color: theme.accent,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: cw),
                  child: Text(
                    mode!,
                    maxLines: 1,
                    softWrap: false,
                    style: theme.boldStyle.copyWith(color: theme.onAccent),
                  ),
                ),
              ),
            // The segments that fit, whole, from the first: on a short
            // line the last ones go, as a multiplexer drops its right side,
            // rather than one cut through a character.
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  var room = c.maxWidth;
                  final shown = <TermStatusSegment>[];
                  for (final segment in segments) {
                    final w = cw + grid.widthOf(segment.text);
                    if (w > room + 0.5) break;
                    room -= w;
                    shown.add(segment);
                  }
                  // Measured on cells; where a face draws a glyph wider
                  // than its cell (a fallback for the branch mark), the
                  // line's end cuts it rather than overflowing.
                  return UnconstrainedBox(
                    alignment: AlignmentDirectional.centerStart,
                    constrainedAxis: Axis.vertical,
                    clipBehavior: Clip.hardEdge,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final segment in shown) ...[
                          SizedBox(width: cw),
                          Semantics(
                            label: segment.semanticLabel,
                            excludeSemantics: segment.semanticLabel != null,
                            child: Text(
                              segment.text,
                              maxLines: 1,
                              softWrap: false,
                              style: theme.textStyle.copyWith(
                                color:
                                    segment.color ??
                                    own.foreground ??
                                    theme.dim,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (termKeysShown(context))
              for (final key in keys) ...[
                SizedBox(width: cw),
                Text(
                  key.keys,
                  maxLines: 1,
                  softWrap: false,
                  textDirection: TextDirection.ltr,
                  style: theme.boldStyle,
                ),
                SizedBox(width: cw),
                Text(
                  key.label,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.dimStyle,
                ),
              ],
            SizedBox(width: cw),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('mode', mode, defaultValue: null));
  }
}

/// A row that scrolls sideways when it runs past its line, marked as a
/// multiplexer marks a window list longer than its status line: a dim `‹`
/// or `›` at the edge that has more beyond it.
class _MarkedScroll extends StatefulWidget {
  const _MarkedScroll({required this.child});

  final Widget child;

  @override
  State<_MarkedScroll> createState() => _MarkedScrollState();
}

class _MarkedScrollState extends State<_MarkedScroll> {
  bool _before = false;
  bool _after = false;

  bool _seen(ScrollMetrics m) {
    final before = m.extentBefore > 0.5;
    final after = m.extentAfter > 0.5;
    if (before != _before || after != _after) {
      setState(() {
        _before = before;
        _after = after;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    Widget mark(String glyph) => ExcludeSemantics(
      child: ColoredBox(
        color: theme.background,
        child: SizedBox(
          width: grid.cols(2),
          child: Center(child: Text(glyph, style: theme.dimStyle)),
        ),
      ),
    );
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _seen(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _seen(n.metrics),
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: widget.child,
            ),
            if (_before)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: mark('‹'),
              ),
            if (_after)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                child: mark('›'),
              ),
          ],
        ),
      ),
    );
  }
}
