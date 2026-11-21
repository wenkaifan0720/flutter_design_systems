/// Getting around: the title line, tabs, the window list at a phone's foot,
/// the side pane at a desk, and the status line.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/pointer.dart';
import '../internal/shell_face.dart';
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
/// tab, a current window. A press ([press]) tints the whole cell and
/// leaves the words whole, as a pressed segment does. The keyboard's focus
/// ([cursor]) is the cursor over it; on the chosen one ([chosen]) hollow,
/// its inverse cleared.
class _Inverse extends StatelessWidget {
  const _Inverse({
    required this.amount,
    required this.child,
    this.press = 0,
    this.cursor = 0,
    this.chosen = false,
    this.hovered = false,
    this.fill,
    this.ink,
  });

  final double amount;
  final double press;
  final double cursor;
  final bool chosen;
  final Widget child;
  final Color? fill;
  final Color? ink;

  /// Whether a pointer is over it: the words of one not chosen take the
  /// accent, its cells as they were.
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final ground = fill ?? theme.foreground;
    final words = ink ?? (hovered && !chosen ? theme.accent : theme.foreground);
    return CustomPaint(
      painter: _FillFromFoot(
        // The press: the words' ink at 30% over the whole cell, under the
        // inverse a choice grows in.
        tint: chosen || press <= 0
            ? null
            : words.withValues(alpha: words.a * 0.3 * press.clamp(0, 1)),
        color: chosen
            ? ground.withValues(alpha: ground.a * (1 - cursor.clamp(0, 1)))
            : ground,
        amount: amount,
      ),
      child: TermCursorCells(
        focus: cursor,
        hollow: chosen,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: termCursorInk(
              theme,
              Color.lerp(words, theme.background, amount)!,
              cursor,
              hollow: chosen,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FillFromFoot extends CustomPainter {
  const _FillFromFoot({required this.color, required this.amount, this.tint});

  final Color color;
  final double amount;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (tint case final tint?) {
      canvas.drawRect(Offset.zero & size, Paint()..color = tint);
    }
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
      old.color != color || old.amount != amount || old.tint != tint;
}

/// A tab bar: each tab its number and its label, `1 steps  2 log  3 env`,
/// the chosen one in inverse video. The number is the key that picks it
/// (with Alt), and the app binds it. Under the pointer a tab's words take
/// the accent; the cursor is the keyboard's alone.
///
/// The behaviour is ui_core's [RawTabBar]: the bar is one tab stop, on
/// the chosen tab, the arrows move along it (mirrored right to left), Home
/// and End go to the ends, and a tab is chosen as the keys reach it; a
/// screen reader hears each tab and its place ("Tab 2 of 3"). Terminal
/// paints the tabs, and a bar wider than its line scrolls, `‹` and `›`
/// marking what is past either end.
///
/// ```dart
/// TermTabBar(
///   tabs: const ['steps', 'log', 'env'],
///   selectedIndex: tab,
///   onTap: (index) => setState(() => tab = index),
/// )
/// ```
class TermTabBar extends StatefulWidget {
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

  /// Called with the tab pressed, or reached by the arrows; null: the tabs
  /// take no presses.
  final ValueChanged<int>? onTap;

  /// Whether each tab shows its number.
  final bool showNumbers;

  @override
  State<TermTabBar> createState() => _TermTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

class _TermTabBarState extends State<TermTabBar> with TickerProviderStateMixin {
  late RawTabController _controller = _make();

  RawTabController _make() => RawTabController(
    length: widget.tabs.length,
    initialIndex: widget.selectedIndex,
    dampingRatio: TermMotion.move.dampingRatio,
    stiffness: TermMotion.move.stiffness,
    vsync: this,
  )..addListener(_chosen);

  @override
  void didUpdateWidget(TermTabBar old) {
    super.didUpdateWidget(old);
    if (widget.tabs.length != _controller.length) {
      final gone = _controller..removeListener(_chosen);
      _controller = _make();
      WidgetsBinding.instance.addPostFrameCallback((_) => gone.dispose());
    } else if (_controller.index != widget.selectedIndex) {
      _controller.index = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_chosen)
      ..dispose();
    super.dispose();
  }

  // The bar chose a tab (a press, an arrow): the app hears it; an app that
  // keeps its own choice puts the bar back.
  void _chosen() {
    final i = _controller.index;
    if (i == widget.selectedIndex) return;
    widget.onTap?.call(i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.index != widget.selectedIndex) {
        _controller.index = widget.selectedIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final enabled = widget.onTap != null;
    final style = widget.style;
    return _MarkedScroll(
      child: RawTabBar(
        controller: _controller,
        isScrollable: true,
        tabs: [
          for (final label in widget.tabs)
            RawTab(label: label, enabled: enabled),
        ],
        tabBuilder: (context, tab, details) {
          final i = details.index;
          final states = details.states;
          final own = TermStyleOf([style, theme.tabBarStyle], states);
          final face = TermTapTarget(
            child: TermStateSprings(
              pressed: states.contains(WidgetState.pressed),
              focused: states.contains(WidgetState.focused),
              builder: (context, press, focus) => TermSpring(
                target: i == _controller.index ? 1 : 0,
                token: TermMotion.move,
                spatial: true,
                // The keyboard's focus is the cursor over the tab; the keys
                // choose as they move, so it stands on the chosen tab,
                // hollow: its inverse cleared, its end cells in the accent.
                builder: (context, t, _) => _Inverse(
                  amount: t,
                  press: press,
                  cursor: focus,
                  chosen: i == _controller.index,
                  hovered: termHovered(states),
                  fill: own.fill,
                  ink: own.foreground,
                  child: SizedBox(
                    height: grid.lineHeight,
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: cw),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.showNumbers) ...[
                            Text(
                              '${i + 1}',
                              style: theme.textStyle.copyWith(
                                color: termCursorInk(
                                  theme,
                                  Color.lerp(
                                    theme.accent,
                                    theme.background,
                                    t,
                                  )!,
                                  focus,
                                  hollow: i == _controller.index,
                                ),
                              ),
                            ),
                            SizedBox(width: cw),
                          ],
                          Text(tab.label, maxLines: 1, softWrap: false),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          // A cell of ground between tabs, as between words.
          return i == 0
              ? face
              : Padding(
                  padding: EdgeInsetsDirectional.only(start: cw),
                  child: face,
                );
        },
      ),
    );
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
    Widget face(int i, String text, Set<WidgetState> states) =>
        TermStateSprings(
          pressed: states.contains(WidgetState.pressed),
          focused: states.contains(WidgetState.focused),
          builder: (context, press, focus) => TermSpring(
            target: i == selectedIndex ? 1 : 0,
            token: TermMotion.move,
            spatial: true,
            builder: (context, t, _) => Center(
              // The keyboard's focus: the cursor over the window, hollow
              // on the current one.
              child: _Inverse(
                amount: t,
                press: press,
                cursor: focus,
                chosen: i == selectedIndex,
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
        );
    // In TermScaffold's shell, its destinations stand in the windows'
    // places: the shell presses them and gives them their keys.
    final shell = TermShellDestinations.maybeOf(context);
    Widget item(int i, String text) => shell != null
        ? TermShellFace(
            face: (context, states) => face(i, text, states),
            child: shell[i],
          )
        : RawButton(
            onPressed: onDestinationSelected == null
                ? null
                : () => onDestinationSelected!(i),
            selected: i == selectedIndex,
            semanticSelected: i == selectedIndex,
            semanticLabel: destinations[i].label,
            mouseCursor: onDestinationSelected == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            builder: (context, states, _) => face(i, text, states),
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
            if (roomy) {
              // The room left over, in whole cells, so every name starts
              // on the character grid: shared evenly between the two ends
              // and the names. The odd cells go to the ends first, a pair
              // at a time, then between the names from the outside in; a
              // last single one to the middle, or (no middle) the end. So
              // the first name never stands against the screen's edge
              // while there is a cell to spare, and the line stays even.
              final spare = c.maxWidth.isFinite
                  ? grid.colsIn(c.maxWidth - wide.fold(0.0, (a, w) => a + w))
                  : 0;
              // Gap g stands before name g; gap n is the end's.
              final gaps = List.filled(n + 1, spare ~/ (n + 1));
              var odd = spare % (n + 1);
              for (var g = 0; odd >= 2 && g < n - g; g++, odd -= 2) {
                gaps[g]++;
                gaps[n - g]++;
              }
              if (odd > 0) gaps[n.isEven ? n ~/ 2 : n]++;
              int gap(int g) => gaps[g];
              return Row(
                children: [
                  for (var i = 0; i < n; i++) ...[
                    SizedBox(width: grid.cols(gap(i))),
                    SizedBox(
                      width: wide[i],
                      height: lines,
                      child: item(i, words(i)),
                    ),
                  ],
                ],
              );
            }
            // Wrap labeled targets onto whole lines as text grows. Keep
            // their widths stable when a different destination is selected.
            return Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < n; i++)
                  SizedBox(
                    width: math.min(wide[i], c.maxWidth),
                    height: lines,
                    child: item(i, words(i)),
                  ),
              ],
            );
          },
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
/// [children] under them (a project list, a session).
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
    // In TermScaffold's shell, its destinations stand in the rows' places:
    // the shell presses them and gives them their keys; each row paints in
    // the shell's states.
    final shell = TermShellDestinations.maybeOf(context);
    Widget row(int i, {required bool pressable}) => TermListTile(
      leading: destinations[i].glyph == null
          ? null
          : ExcludeSemantics(child: Text(destinations[i].glyph!)),
      title: Text(destinations[i].label),
      trailing: destinations[i].shortcut != null && termKeysShown(context)
          ? TermKey.of(destinations[i].shortcut!)
          : destinations[i].badge == null
          ? null
          : Text(destinations[i].badge!, style: theme.dimStyle),
      selected: i == selectedIndex,
      style: TermStyle(fill: rows.fill, foreground: rows.foreground),
      onTap: !pressable || onDestinationSelected == null
          ? null
          : () => onDestinationSelected!(i),
    );
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
                if (shell != null)
                  TermShellFace(
                    face: (context, states) => TermFaceStates(
                      states: states,
                      child: row(i, pressable: false),
                    ),
                    child: shell[i],
                  )
                else
                  row(i, pressable: true),
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

/// One stretch of a [TermStatusLine]: words, in an optional [color].
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

/// Marks the sideways scroll in [child] (a row that runs past its line) as
/// a multiplexer marks a window list longer than its status line: a dim
/// `‹` or `›` at the edge that has more beyond it.
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
            widget.child,
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
