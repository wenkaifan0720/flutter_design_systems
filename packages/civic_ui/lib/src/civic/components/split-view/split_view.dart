import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../link/link.dart';

/// Two panes side by side (or stacked, [axis] vertical) with a divider a
/// reader drags to share the room: a rule down a 24-wide gutter and, on
/// it, a grip 24 by 48 with three lines on it, square at the corners. A
/// pointer over the grip darkens its edge; a drag fills it in ink; a
/// keyboard focus lays it on the yellow plate with the thick dark bar
/// along its end, and the arrow keys move it (Enter folds the first pane
/// away and back). A screen reader hears a slider with the first pane's
/// share. ui_core's [RawSplitView], Civic's painting.
///
/// Side by side in less than 600 of room, where two panes are too narrow
/// to read, it shows one at a time: [first], or with [showSecond] [second]
/// under a back link that calls [onBack] (the list, then its record). The
/// panes cross on Civic's panel spring, the hidden one keeping its state
/// (its scroll, its fields), and the keyboard's focus moves to the back
/// link.
///
/// Reads [CivicStyle]'s fill (the grip, by state) and foreground (its
/// lines and edge): its `style:`, then [CivicThemeData.splitViewStyle].
///
/// ```dart
/// CivicSplitView(
///   first: Text('Your applications'),
///   second: Text('Resident permit, Zone B'),
///   minFirst: 160,
///   minSecond: 240,
/// )
/// ```
class CivicSplitView extends StatelessWidget {
  /// [first] and [second] with a divider between them.
  const CivicSplitView({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = 0.5,
    this.onChanged,
    this.minFirst = 0,
    this.minSecond = 0,
    this.semanticLabel,
    this.focusNode,
    this.showSecond = false,
    this.onBack,
    this.backLabel,
    this.style,
  });

  /// The first pane (the start one, or the top).
  final Widget first;

  /// The second pane.
  final Widget second;

  /// Whether the panes stand side by side (horizontal) or stacked.
  final Axis axis;

  /// The first pane's share of the room; null: the view's own, from
  /// [initialFraction].
  final double? fraction;

  /// The first pane's share at first when [fraction] is null.
  final double initialFraction;

  /// Called with the first pane's share as the divider moves.
  final ValueChanged<double>? onChanged;

  /// The first pane's least extent.
  final double minFirst;

  /// The second pane's least extent.
  final double minSecond;

  /// What a screen reader calls the divider; null: ui_core's
  /// "Resize panes".
  final String? semanticLabel;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Whether, in less than 600 of room, the view shows [second] rather
  /// than [first]. Side by side it changes nothing.
  final bool showSecond;

  /// Called by the back link over [second] in less than 600 of room (the
  /// caller sets [showSecond] false); null: no back link.
  final VoidCallback? onBack;

  /// The back link's words; null: "Back" in the reader's language.
  final String? backLabel;

  /// Overrides for this view's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) return _split(context);
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < CivicLayout.medium
          ? _OnePane(
              first: first,
              second: second,
              showSecond: showSecond,
              onBack: onBack,
              backLabel: backLabel,
            )
          : _split(context),
    );
  }

  Widget _split(BuildContext context) {
    final t = context.civicTheme;
    return RawSplitView(
      first: first,
      second: second,
      axis: axis,
      fraction: fraction,
      initialFraction: initialFraction,
      onChanged: onChanged,
      minFirst: minFirst,
      minSecond: minSecond,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      dividerThickness: _gutter,
      hitExtent: _gutter,
      dividerBuilder: (context, states, axis) =>
          _Divider(states: states, axis: axis, style: style, theme: t),
    );
  }

  static const double _gutter = 24;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('axis', axis, defaultValue: Axis.horizontal))
      ..add(DoubleProperty('fraction', fraction, defaultValue: null))
      ..add(DoubleProperty('minFirst', minFirst, defaultValue: 0))
      ..add(DoubleProperty('minSecond', minSecond, defaultValue: 0))
      ..add(FlagProperty('showSecond', value: showSecond, ifTrue: 'showSecond'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onBack', onBack))
      ..add(StringProperty('backLabel', backLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// One pane at a time: [first], or [second] under its back link, crossing
/// on the panel spring.
class _OnePane extends StatefulWidget {
  const _OnePane({
    required this.first,
    required this.second,
    required this.showSecond,
    required this.onBack,
    required this.backLabel,
  });

  final Widget first;
  final Widget second;
  final bool showSecond;
  final VoidCallback? onBack;
  final String? backLabel;

  @override
  State<_OnePane> createState() => _OnePaneState();
}

class _OnePaneState extends State<_OnePane> {
  final _back = FocusNode(debugLabel: 'CivicSplitView back');

  @override
  void didUpdateWidget(_OnePane old) {
    super.didUpdateWidget(old);
    // Shown the record, the keyboard starts at its way back.
    if (widget.showSecond && !old.showSecond && widget.onBack != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _back.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final back = widget.onBack;
    final shownSecond = widget.showSecond;
    final along = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final record = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (back != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CivicBackLink(
              onPressed: back,
              label: widget.backLabel,
              focusNode: _back,
            ),
          ),
          const SizedBox(height: CivicSpacing.s16),
        ],
        Expanded(child: widget.second),
      ],
    );
    return CivicSpringValue(
      value: shownSecond ? 1 : 0,
      spring: CivicMotion.panel,
      builder: (context, v, _) {
        // The pane coming in slides a little from the side it leads to,
        // the one going out fades toward the other.
        Widget pane(Widget child, double shown, double shift, bool on) =>
            Visibility(
              // The pane coming in is there from its first frame, so the
              // focus can reach it.
              visible: on || shown > 0.001,
              maintainState: true,
              child: IgnorePointer(
                ignoring: !on,
                child: ExcludeFocus(
                  excluding: !on,
                  child: ExcludeSemantics(
                    excluding: !on,
                    child: Opacity(
                      opacity: shown.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(along * shift, 0),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
        return Stack(
          fit: StackFit.expand,
          children: [
            pane(widget.first, 1 - v, -CivicSpacing.s32 * v, !shownSecond),
            pane(record, v, CivicSpacing.s32 * (1 - v), shownSecond),
          ],
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({
    required this.states,
    required this.axis,
    required this.style,
    required this.theme,
  });

  final Set<WidgetState> states;
  final Axis axis;
  final CivicStyle? style;
  final CivicThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final so = DesignStyleOf([style, t.splitViewStyle], states);
    final across = axis == Axis.horizontal;
    final held = states.contains(WidgetState.pressed);
    final over = held || states.contains(WidgetState.hovered);
    return CivicSpringValue(
      value: held ? 1 : 0,
      spring: CivicMotion.press,
      builder: (context, fill, _) => CivicSpringValue(
        value: over ? 1 : 0,
        spring: CivicMotion.press,
        builder: (context, edge, _) => CivicSpringValue(
          value: states.contains(WidgetState.focused) ? 1 : 0,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, focus, _) {
            final ink =
                so.foreground ??
                Color.lerp(t.textSecondary, t.textPrimary, edge)!;
            final face = Color.lerp(
              Color.lerp(so.fill ?? t.background, ink, fill)!,
              t.focus,
              focus,
            )!;
            final lines = Color.lerp(
              Color.lerp(ink, t.background, fill)!,
              t.onFocus,
              focus,
            )!;
            // The rule strengthens to the words' ink, by day and by night.
            final rule = Color.lerp(t.rule, t.textPrimary, focus)!;
            return Stack(
              alignment: Alignment.center,
              children: [
                // The rule down the gutter.
                SizedBox(
                  width: across ? CivicMetrics.edge : double.infinity,
                  height: across ? double.infinity : CivicMetrics.edge,
                  child: ColoredBox(color: rule),
                ),
                SizedBox(
                  width: across ? _Grip.breadth : _Grip.length,
                  height: across ? _Grip.length : _Grip.breadth,
                  child: CustomPaint(
                    painter: _Grip(
                      face: face,
                      edge: Color.lerp(ink, t.onFocus, focus)!,
                      lines: lines,
                      bar: t.focusBar.withValues(alpha: focus),
                      across: across,
                      rtl: Directionality.of(context) == TextDirection.rtl,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Grip extends CustomPainter {
  const _Grip({
    required this.face,
    required this.edge,
    required this.lines,
    required this.bar,
    required this.across,
    required this.rtl,
  });

  static const double breadth = 24;
  static const double length = 48;

  final Color face;
  final Color edge;
  final Color lines;
  final Color bar;
  final bool across;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas.drawRect(box, Paint()..color = face);
    canvas.drawRect(
      box.deflate(CivicMetrics.edge / 2),
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = CivicMetrics.edge,
    );
    // The focus's thick dark bar along the grip's end edge (its bottom
    // when the panes are stacked).
    if (bar.a > 0) {
      final b = CivicMetrics.bar;
      canvas.drawRect(
        across
            ? (rtl
                  ? Rect.fromLTWH(0, 0, b, size.height)
                  : Rect.fromLTWH(size.width - b, 0, b, size.height))
            : Rect.fromLTWH(0, size.height - b, size.width, b),
        Paint()..color = bar,
      );
    }
    final p = Paint()
      ..color = lines
      ..strokeWidth = CivicMetrics.edge;
    final c = box.center;
    for (final d in const [-6.0, 0.0, 6.0]) {
      if (across) {
        canvas.drawLine(c + Offset(-5, d), c + Offset(5, d), p);
      } else {
        canvas.drawLine(c + Offset(d, -5), c + Offset(d, 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Grip old) =>
      old.face != face ||
      old.edge != edge ||
      old.lines != lines ||
      old.bar != bar ||
      old.across != across ||
      old.rtl != rtl;
}
