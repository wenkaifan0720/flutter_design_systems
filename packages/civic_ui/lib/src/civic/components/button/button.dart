import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

enum _Kind { primary, secondary, start }

/// A button that says what happens next: a face with slightly rounded
/// corners on a solid bottom edge of a deeper tone, which a press sinks
/// onto. The unnamed constructor is the page's one action (Continue, Send
/// application), solid in the action colour; [CivicButton.secondary] is an
/// action beside it, a face of the action's tint with its words in the
/// action colour and no stroke round it; [CivicButton.start] begins a
/// service.
///
/// [isDestructiveAction] draws it in the error colour, for a button that
/// confirms or starts a loss: solid in a dialog, the error's tint
/// (secondary) on a page, never as a page's loudest thing. Below 600 wide it spans its
/// column, as a phone's action does; from 600 it keeps the width of its
/// words; [expand] says otherwise. A
/// pointer over it deepens its face; a keyboard focus floods the face
/// yellow and turns its edge to the ink bar.
///
/// Reads [CivicStyle]'s fill, foreground, edge, side (a stroke round the
/// face, none by default), padding, minimumSize (a face never stands lower than its 48
/// points), textStyle and iconSize:
/// its `style:` first, then its kind's theme
/// ([CivicThemeData.primaryButtonStyle], [CivicThemeData.secondaryButtonStyle],
/// [CivicThemeData.startButtonStyle], [CivicThemeData.destructiveButtonStyle]).
/// Its corners, its solid edge and the focus flood are the look's and take
/// no style.
///
/// ```dart
/// CivicButton(
///   onPressed: () => Navigator.of(context).pushNamed('/check'),
///   child: const Text('Continue'),
/// )
/// ```
class CivicButton extends StatelessWidget {
  /// The page's action.
  const CivicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructiveAction = false,
    this.icon,
    this.expand,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
  }) : _kind = _Kind.primary;

  /// The page's action from its words alone: `CivicButton.label('Continue',
  /// onPressed: ...)` is `CivicButton(child: Text('Continue'), ...)`. What
  /// generated code writes, where the words are all it has.
  CivicButton.label(
    String label, {
    super.key,
    required this.onPressed,
    this.isDestructiveAction = false,
    this.icon,
    this.expand,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
  }) : child = Text(label),
       _kind = _Kind.primary;

  /// An action beside the page's one: Save and come back later, Cancel.
  const CivicButton.secondary({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructiveAction = false,
    this.icon,
    this.expand,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
  }) : _kind = _Kind.secondary;

  /// The start of a service, larger, with an arrow: Start now.
  const CivicButton.start({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon = LucideIcons.arrowRight,
    this.expand,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
  }) : isDestructiveAction = false,
       _kind = _Kind.start;

  final _Kind _kind;

  /// Called on a press; null disables the button.
  final VoidCallback? onPressed;

  /// The words: what happens next.
  final Widget child;

  /// Whether the button confirms a loss: drawn in the error colour.
  final bool isDestructiveAction;

  /// A glyph after the words; the start button's arrow turns with the
  /// reading direction.
  final IconData? icon;

  /// Whether the button spans its column; null spans it below 600 wide and
  /// keeps the width of its words from 600, even in a column that
  /// stretches its children.
  final bool? expand;

  /// Overrides for this button's look.
  final CivicStyle? style;

  /// {@template civic.focusNode}
  /// The focus node, which the caller disposes; null makes one of its own.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template civic.autofocus}
  /// Whether it takes the focus when it first appears.
  /// {@endtemplate}
  final bool autofocus;

  /// {@template civic.statesController}
  /// The states it is drawn in, as Flutter's buttons take them: add
  /// [WidgetState.focused] to show its focus without a keyboard (a
  /// specimen). The caller disposes it; null keeps its own.
  /// {@endtemplate}
  final WidgetStatesController? statesController;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 1024;
    final stretch = expand ?? width < CivicLayout.medium;
    final start = _kind == _Kind.start;
    final height = start ? 56.0 : CivicMetrics.controlHeight;
    // Spans a bounded column without a LayoutBuilder, so a dialog or a row
    // can still measure the button by its words.
    return _Stretch(
      stretch: stretch,
      child: DesignTapTarget(
        child: DesignPressable(
          onPressed: onPressed,
          focusNode: focusNode,
          autofocus: autofocus,
          statesController: statesController,
          mouseCursor: onPressed == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          builder: (context, states, _) {
            final kind = isDestructiveAction
                ? t.destructiveButtonStyle
                : switch (_kind) {
                    _Kind.primary => t.primaryButtonStyle,
                    _Kind.secondary => t.secondaryButtonStyle,
                    _Kind.start => t.startButtonStyle,
                  };
            final so = DesignStyleOf([style, kind], states);
            final disabled = states.contains(WidgetState.disabled);
            final secondary = _kind == _Kind.secondary;
            // A secondary button is a tint of its words' colour (the
            // action's, or the error's when it destroys) on a deeper tint's
            // edge, with no stroke round it.
            Color tint(Color c, double a) =>
                Color.alphaBlend(c.withValues(alpha: a), t.background);
            final (fill, ink, edge) = disabled
                ? (t.disabledFill, t.textDisabled, t.rule)
                : secondary && isDestructiveAction
                ? (
                    tint(t.danger, t.isDark ? 0.2 : 0.12),
                    t.danger,
                    tint(t.danger, t.isDark ? 0.45 : 0.4),
                  )
                : isDestructiveAction
                ? (t.danger, t.onDanger, t.dangerEdge)
                : secondary
                ? (t.secondaryFill, t.onSecondary, t.secondaryEdge)
                : (t.action, t.onAction, t.actionEdge);
            final pressed = states.contains(WidgetState.pressed) ? 1.0 : 0.0;
            final focused = states.contains(WidgetState.focused) ? 1.0 : 0.0;
            final hovered = states.contains(WidgetState.hovered) ? 1.0 : 0.0;
            final words = (start ? text.headingM : text.button).merge(
              so.textStyle,
            );
            final padding =
                so.padding(Directionality.of(context)) ??
                EdgeInsets.symmetric(
                  horizontal: start ? CivicSpacing.s24 : CivicSpacing.s20,
                );
            // The face's room over and under the words grows with them, so
            // large words never run edge to edge.
            final room =
                CivicSpacing.s8 *
                MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.75);
            final asked = so.minimumSize;
            final min = Size(
              asked?.width ?? 0,
              math.max(asked?.height ?? 0, height),
            );
            return CivicSpringValue(
              value: hovered,
              spring: CivicMotion.press,
              effects: true,
              builder: (context, hover, _) => CivicSpringValue(
                value: pressed,
                spring: CivicMotion.press,
                builder: (context, press, _) => CivicSpringValue(
                  value: focused,
                  spring: CivicMotion.focus,
                  effects: true,
                  builder: (context, focus, _) {
                    // A pointer over it deepens its face (by night, lifts it):
                    // a solid face a clear step darker, a tinted one a step
                    // toward its edge.
                    final rest = so.fill ?? fill;
                    final over = secondary
                        ? Color.lerp(rest, so.edge ?? edge, 0.45)!
                        : t.isDark
                        ? Color.lerp(rest, const Color(0xFFFFFFFF), 0.25)!
                        : Color.lerp(rest, const Color(0xFF000000), 0.35)!;
                    final face = disabled
                        ? rest
                        : Color.lerp(rest, over, hover)!;
                    // By day a solid face's edge deepens with it, so the
                    // deeper face still stands on a darker edge.
                    final base = so.edge ?? edge;
                    final under = disabled || secondary || t.isDark
                        ? base
                        : Color.lerp(
                            base,
                            const Color(0xFF000000),
                            0.5 * hover,
                          )!;
                    final fg = Color.lerp(
                      so.foreground ?? ink,
                      t.onFocus,
                      focus,
                    )!;
                    final label = Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: CivicSpacing.s8,
                      children: [
                        Flexible(
                          child: DesignCapCenter(
                            capHeightFactor: context.civicText.capHeight,
                            child: DefaultTextStyle(
                              style: words.copyWith(color: fg),
                              textAlign: TextAlign.center,
                              child: child,
                            ),
                          ),
                        ),
                        if (icon != null)
                          // The start's arrow points the way the words read.
                          Transform.flip(
                            flipX:
                                start &&
                                Directionality.of(context) == TextDirection.rtl,
                            child: Icon(
                              icon,
                              size: so.iconSize ?? (start ? 28 : 22),
                              color: fg,
                              applyTextScaling: true,
                            ),
                          ),
                      ],
                    );
                    return CustomPaint(
                      painter: CivicFacePainter(
                        fill: face,
                        edgeColor: under,
                        edgeHeight: CivicMetrics.bar,
                        press: press,
                        focus: focus,
                        focusColor: t.focus,
                        barColor: t.onFocus,
                        side: disabled ? null : so.side,
                        radius: CivicMetrics.corner,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: min.width,
                          minHeight: min.height,
                        ),
                        child: Padding(
                          // The words stand on the face, above the edge, and
                          // sink with it.
                          padding: EdgeInsets.only(
                            top: CivicMetrics.bar * press,
                            bottom: CivicMetrics.bar * (1 - press),
                          ),
                          child: Padding(
                            padding: padding.add(
                              EdgeInsets.symmetric(vertical: room),
                            ),
                            child: Center(
                              widthFactor: 1,
                              heightFactor: 1,
                              child: label,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<_Kind>('kind', _kind))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      )
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('expand', expand, defaultValue: null))
      ..add(DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<WidgetStatesController>(
          'statesController',
          statesController,
          defaultValue: null,
        ),
      );
  }
}

/// Gives its child the whole of a bounded width when [stretch]; otherwise
/// lets it keep its own width at the start of a column that would stretch
/// it. Every other constraint, and every measure, passes through.
class _Stretch extends SingleChildRenderObjectWidget {
  const _Stretch({required this.stretch, super.child});

  final bool stretch;

  @override
  _RenderStretch createRenderObject(BuildContext context) =>
      _RenderStretch(stretch, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderStretch renderObject) =>
      renderObject
        ..stretch = stretch
        ..direction = Directionality.of(context);
}

class _RenderStretch extends RenderShiftedBox {
  _RenderStretch(this._stretch, this._direction) : super(null);

  bool _stretch;
  set stretch(bool value) {
    if (value == _stretch) return;
    _stretch = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints constraints) => _stretch
      ? (constraints.hasBoundedWidth
            ? constraints.tighten(width: constraints.maxWidth)
            : constraints)
      : constraints.copyWith(minWidth: 0);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => constraints
      .constrain(child?.getDryLayout(_inner(constraints)) ?? Size.zero);

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => child?.getDryBaseline(_inner(constraints), baseline);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(child.size);
    final spare = size.width - child.size.width;
    (child.parentData! as BoxParentData).offset = Offset(
      _direction == TextDirection.rtl ? spare : 0,
      0,
    );
  }
}
