import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../inset/inset.dart';
import '../../internal/underline.dart';

/// Help a reader may need and most will not, folded under its [title]: a
/// small triangle and the title as an underlined link; a press opens the
/// [child] beneath it on the inset rule, the triangle turning down. A
/// pointer over the title or a press on it thickens its line, as a link's;
/// a keyboard focus lays the title on the yellow plate over the ink bar.
///
/// Put the help in sight when most readers need it: a fold hides it.
///
/// Reads [CivicStyle]'s foreground (the title and triangle, by state) and
/// textStyle (the title): its `style:`, then [CivicThemeData.detailsStyle].
/// The focus plate is the look's.
///
/// ```dart
/// CivicDetails(
///   title: 'Help with proof of address',
///   child: Text('A council tax bill or a tenancy agreement from the last '
///       'three months.'),
/// )
/// ```
class CivicDetails extends StatefulWidget {
  /// Help folded under [title].
  const CivicDetails({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.focusNode,
    this.style,
  });

  /// What the help is about: "Help with proof of address".
  final String title;

  /// The help.
  final Widget child;

  /// Whether it opens unfolded.
  final bool initiallyExpanded;

  /// Called with whether it is open as it opens or closes.
  final ValueChanged<bool>? onExpansionChanged;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Overrides for this fold's look.
  final CivicStyle? style;

  @override
  State<CivicDetails> createState() => _CivicDetailsState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(
        FlagProperty(
          'initiallyExpanded',
          value: initiallyExpanded,
          ifTrue: 'initially expanded',
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onExpansionChanged',
          onExpansionChanged,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicDetailsState extends State<CivicDetails> {
  late bool _open = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _open = !_open);
    widget.onExpansionChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final summary = TapTargetPadding(
      alignment: AlignmentDirectional.centerStart,
      child: RawButton(
        onPressed: _toggle,
        focusNode: widget.focusNode,
        expanded: _open,
        semanticLabel: widget.title,
        excludeSemantics: true,
        mouseCursor: SystemMouseCursors.click,
        builder: (context, states, _) => CivicSpringValue(
          value: states.contains(WidgetState.focused) ? 1 : 0,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, focus, _) {
            final so = DesignStyleOf(
              [widget.style, t.detailsStyle],
              {...states, if (_open) WidgetState.selected},
            );
            // A pointer over the title, or a press on it, thickens its
            // underline and deepens its colour as a link's; a press takes it
            // the rest of the way to the ink.
            final held = states.contains(WidgetState.pressed);
            final over = held || states.contains(WidgetState.hovered);
            final ink = Color.lerp(
              Color.lerp(
                so.foreground ?? t.action,
                t.textPrimary,
                held ? 1 : (over ? 0.45 : 0),
              ),
              t.onFocus,
              focus,
            )!;
            return CustomPaint(
              painter: CivicFacePainter(
                fill: t.focus.withValues(alpha: 0),
                edgeColor: t.onFocus,
                edgeHeight: 0,
                press: 0,
                focus: focus,
                focusColor: t.focus,
                barColor: t.focusBar,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: CivicMetrics.bar),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: CivicSpacing.s8,
                  children: [
                    CivicSpringValue(
                      value: _open ? 1 : 0,
                      spring: CivicMotion.state,
                      builder: (context, turn, _) => Transform.rotate(
                        // Closed it points the reading way; open, down.
                        angle: (rtl ? -1 : 1) * turn * math.pi / 2,
                        // It grows with the title's words.
                        child: CustomPaint(
                          size: Size.square(
                            MediaQuery.textScalerOf(context).scale(_triangle),
                          ),
                          painter: _Triangle(color: ink, rtl: rtl),
                        ),
                      ),
                    ),
                    Flexible(
                      child: CivicUnderlined(
                        style: text.body
                            .merge(so.textStyle)
                            .copyWith(
                              color: ink,
                              decoration: TextDecoration.underline,
                              decorationThickness: over ? 3 : 1.2,
                              decorationColor: Color.lerp(
                                ink,
                                t.onFocus.withValues(alpha: 0),
                                focus,
                              ),
                            ),
                        child: Text(widget.title),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: summary),
        CivicSpringValue(
          value: _open ? 1 : 0,
          spring: CivicMotion.panel,
          child: Padding(
            padding: const EdgeInsets.only(top: CivicSpacing.s8),
            child: CivicInset(child: widget.child),
          ),
          builder: (context, reveal, help) {
            final shown = reveal.clamp(0.0, 1.0);
            if (!_open && shown < 0.001) return const SizedBox.shrink();
            // Closing, the help is gone to a screen reader and the keys
            // at once; only its picture folds away.
            return ExcludeFocus(
              excluding: !_open,
              child: ExcludeSemantics(
                excluding: !_open,
                child: ClipRect(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    heightFactor: shown,
                    child: help,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static const double _triangle = 12;
}

class _Triangle extends CustomPainter {
  const _Triangle({required this.color, required this.rtl});

  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = rtl
        ? (Path()
            ..moveTo(w, 0)
            ..lineTo(0, h / 2)
            ..lineTo(w, h))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(w, h / 2)
            ..lineTo(0, h));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Triangle old) => old.color != color || old.rtl != rtl;
}
