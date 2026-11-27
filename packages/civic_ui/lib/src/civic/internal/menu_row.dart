import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'corners.dart';
import 'paint.dart';
import 'spring.dart';

/// One row of a menu Civic opens (a menu's, a split button's, a command
/// palette's), each state its own and none read as another, as an open
/// list's options are:
///
/// * a pointer over it: the row greys between the panel's edges (a press a
///   step deeper);
/// * the keyboard's: the yellow plate over the ink bar, the look's focus;
/// * one that destroys something says so in the error colour;
/// * one that cannot be chosen, in the disabled words.
///
/// Every change moves on Civic's springs. Plumbing; pages never place one.
class CivicMenuRow extends StatelessWidget {
  /// A row saying [label] in [states].
  const CivicMenuRow({
    super.key,
    required this.label,
    required this.states,
    this.icon,
    this.glyphColumn = false,
    this.trailing,
    this.destructive = false,
    this.style,
  });

  /// What it does.
  final String label;

  /// Its pressable's states.
  final Set<WidgetState> states;

  /// A glyph before the words.
  final IconData? icon;

  /// Whether its list has glyphs: one without [icon] keeps the glyph's
  /// column empty, so every row's words start on one line.
  final bool glyphColumn;

  /// Words at its end in the quieter colour (a shortcut, a count).
  final String? trailing;

  /// Whether it destroys something: its words in the error colour.
  final bool destructive;

  /// The menu's style ([CivicThemeData.menuStyle] under it): foreground,
  /// padding and textStyle, by state.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([style, t.menuStyle], states);
    final disabled = states.contains(WidgetState.disabled);
    final focused = !disabled && states.contains(WidgetState.focused);
    final wash = disabled
        ? 0.0
        : states.contains(WidgetState.pressed)
        ? 0.8
        : states.contains(WidgetState.hovered)
        ? 0.5
        : 0.0;
    final rest = disabled
        ? t.textDisabled
        : so.foreground ?? (destructive ? t.danger : t.textPrimary);
    final quiet = disabled ? t.textDisabled : t.textSecondary;
    return CivicSpringValue(
      value: wash,
      spring: CivicMotion.press,
      effects: true,
      builder: (context, w, _) => CivicSpringValue(
        value: focused ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) {
          final grey = Color.lerp(t.surface, t.rule, w.clamp(0.5, 0.8))!;
          final fill = Color.lerp(
            t.background,
            grey,
            (w / 0.5).clamp(0.0, 1.0),
          )!;
          final ink = Color.lerp(rest, t.onFocus, focus)!;
          return CustomPaint(
            painter: CivicFacePainter(
              fill: fill,
              edgeColor: t.onFocus,
              edgeHeight: 0,
              press: 0,
              focus: focus,
              focusColor: t.focus,
              barColor: t.focusBar,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CivicMetrics.controlHeight,
              ),
              child: Padding(
                padding:
                    so.padding(Directionality.of(context)) ??
                    const EdgeInsets.symmetric(
                      horizontal: CivicSpacing.s16,
                      vertical: CivicSpacing.s8,
                    ),
                child: Row(
                  spacing: CivicSpacing.s12,
                  children: [
                    if (icon case final glyph?)
                      Icon(glyph, size: 24, color: ink, applyTextScaling: true)
                    else if (glyphColumn)
                      const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        label,
                        style: text.body
                            .merge(so.textStyle)
                            .copyWith(color: ink),
                      ),
                    ),
                    if (trailing case final words?)
                      Text(
                        words,
                        style: text.bodySmall.copyWith(
                          color: Color.lerp(quiet, t.onFocus, focus),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The panel a menu's rows stand on: the page's face (by night the raised
/// band) floating on a hairline and the soft shadow, as an open list does,
/// [minWidth] to [maxWidth] wide. Its rows reach the panel's edges.
class CivicMenuPanel extends StatelessWidget {
  /// A panel round [child].
  const CivicMenuPanel({
    super.key,
    required this.child,
    this.style,
    this.minWidth = 200,
    this.maxWidth = 320,
  });

  /// The rows.
  final Widget child;

  /// The menu's style ([CivicThemeData.menuStyle] under it): fill and edge.
  final CivicStyle? style;

  /// The least it stands.
  final double minWidth;

  /// The widest it stands.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf([style, t.menuStyle], const {});
    const inset = 1.0;
    final face = so.fill ?? (t.isDark ? t.surface : t.background);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: civicFloating(
          face: face,
          hairline: so.edge ?? t.rule,
          dark: t.isDark,
          shape: civicShape(t, so, RawCorner.small),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: CivicSpacing.s4,
            horizontal: inset,
          ),
          // As wide as its widest row, within its bounds; the rows take the
          // panel's face for their page.
          child: ClipRect(
            child: CivicTheme(
              data: t.copyWith(background: face),
              child: IntrinsicWidth(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rise of an anchored surface: a fade and 8 of travel from the side it
/// opens on, on [animation] (Reduce Motion's quick fade under it).
Widget civicRise({
  required Animation<double> animation,
  required bool fromAbove,
  required Widget child,
}) => AnimatedBuilder(
  animation: animation,
  builder: (context, surface) {
    final p = animation.value.clamp(0.0, 1.0);
    final d = (1 - p) * CivicSpacing.s8;
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, fromAbove ? -d : d),
        child: surface,
      ),
    );
  },
  child: child,
);
