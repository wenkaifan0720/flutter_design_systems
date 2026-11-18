import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../../internal/underline.dart';

/// Words that go somewhere: underlined, in the action colour. A press
/// thickens the underline; a keyboard focus lays the words on the yellow
/// plate over the ink bar, in ink.
///
/// [semanticLabel] says the whole of it to a screen reader where the words
/// lean on what is beside them: a summary row's "Change" is "Change your
/// name".
///
/// Reads [CivicStyle]'s foreground (the ink at rest, by state) and
/// textStyle: its `style:`, then [CivicThemeData.linkStyle]. The underline,
/// the press that thickens it and the focus plate are the look's.
///
/// ```dart
/// CivicLink(
///   onPressed: () => openGuidance(),
///   child: const Text('Read the guidance on permit zones'),
/// )
/// ```
class CivicLink extends StatelessWidget {
  /// A link.
  const CivicLink({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.textStyle,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.style,
  }) : _ink = false;

  /// A link in the words' own ink rather than the action colour: a back
  /// link, a link in a footer.
  const CivicLink.quiet({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.textStyle,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.style,
  }) : _ink = true;

  final bool _ink;

  /// Called on a press; null leaves the words as plain words.
  final VoidCallback? onPressed;

  /// The words.
  final Widget child;

  /// What a screen reader says for it; null says [child]'s words.
  final String? semanticLabel;

  /// The words' style, over the body's; its colour, when it has one, is
  /// the link's ink at rest.
  final TextStyle? textStyle;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// {@macro civic.statesController}
  final WidgetStatesController? statesController;

  /// Overrides for this link's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DesignTapTarget(
      alignment: AlignmentDirectional.centerStart,
      child: DesignPressable(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        statesController: statesController,
        button: false,
        link: true,
        semanticLabel: semanticLabel,
        excludeSemantics: semanticLabel != null,
        mouseCursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) {
          final so = DesignStyleOf([style, t.linkStyle], states);
          final base = context.civicText.body
              .merge(so.textStyle)
              .merge(textStyle);
          final disabled = states.contains(WidgetState.disabled);
          // A colour in [textStyle] is the link's ink at rest.
          final ink = disabled
              ? t.textDisabled
              : textStyle?.color ??
                    so.foreground ??
                    (_ink ? t.textPrimary : t.action);
          // A pointer over it thickens the line under the words and deepens
          // their colour; a press takes them the rest of the way to the
          // ink, as a link held down does on a public service's page.
          final held = states.contains(WidgetState.pressed) ? 1.0 : 0.0;
          Color deep(double amount) =>
              Color.lerp(ink, t.textPrimary, 0.45 * amount + 0.55 * held)!;
          final touched =
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered);
          return CivicSpringValue(
            value: touched ? 1 : 0,
            spring: CivicMotion.press,
            builder: (context, press, _) => CivicSpringValue(
              value: states.contains(WidgetState.focused) ? 1 : 0,
              spring: CivicMotion.focus,
              effects: true,
              builder: (context, focus, _) => CustomPaint(
                painter: CivicFacePainter(
                  fill: t.focus.withValues(alpha: 0),
                  edgeColor: t.onFocus,
                  edgeHeight: 0,
                  press: 0,
                  focus: focus,
                  focusColor: t.focus,
                  barColor: t.focusBar,
                  outset: CivicMetrics.edge,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: CivicMetrics.bar),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: Color.lerp(deep(press), t.onFocus, focus),
                    ),
                    child: CivicUnderlined(
                      style: base.copyWith(
                        color: Color.lerp(deep(press), t.onFocus, focus),
                        decoration: disabled
                            ? TextDecoration.none
                            : TextDecoration.underline,
                        decorationColor: Color.lerp(
                          deep(press),
                          t.onFocus.withValues(alpha: 0),
                          focus,
                        ),
                        decorationThickness: 1.2 + 1.8 * press,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('quiet', value: _ink, ifTrue: 'quiet'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextStyle>(
          'textStyle',
          textStyle,
          defaultValue: null,
        ),
      )
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
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The way back, above a page's heading: a chevron and "Back" (in the
/// reader's language), in ink, underlined. The chevron points the way back
/// in either reading direction.
///
/// ```dart
/// CivicBackLink(onPressed: () => Navigator.of(context).maybePop())
/// ```
class CivicBackLink extends StatelessWidget {
  /// A back link.
  const CivicBackLink({
    super.key,
    required this.onPressed,
    this.label,
    this.focusNode,
  });

  /// Called on a press.
  final VoidCallback? onPressed;

  /// The words; null says "Back" in the reader's language.
  final String? label;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final words = label ?? DesignLocalizations.of(context).backButtonTooltip;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return CivicLink.quiet(
      onPressed: onPressed,
      focusNode: focusNode,
      textStyle: context.civicText.bodySmall.copyWith(color: t.textPrimary),
      semanticLabel: words,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s4,
        children: [
          Transform.flip(
            flipX: rtl,
            child: const Icon(
              LucideIcons.chevronLeft,
              size: 18,
              applyTextScaling: true,
            ),
          ),
          Text(words),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      );
  }
}
