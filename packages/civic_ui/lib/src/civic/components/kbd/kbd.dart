import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../theme.dart';

/// A key on the keyboard, named in help and in a list of shortcuts: its
/// name in the mono face on a key cap, the band's grey with the solid
/// bottom edge a button stands on, so it reads as a key and never as a
/// button to press. Join keys pressed together with [CivicKbd.combination].
///
/// A screen reader hears the key's name: give [semanticLabel] where the
/// cap shows a symbol ("⌘" is "Command").
///
/// Reads [CivicStyle]'s fill, foreground, edge, padding and textStyle: its
/// `style:`, then [CivicThemeData.kbdStyle].
///
/// ```dart
/// Text.rich(TextSpan(children: [
///   const TextSpan(text: 'Press '),
///   WidgetSpan(child: CivicKbd('Enter')),
///   const TextSpan(text: ' to continue.'),
/// ]))
/// ```
class CivicKbd extends StatelessWidget {
  /// A key saying [label].
  const CivicKbd(this.label, {super.key, this.semanticLabel, this.style})
    : keys = null;

  /// Keys pressed together, joined by a plus: `CivicKbd.combination(['Ctrl',
  /// 'K'])`.
  const CivicKbd.combination(
    List<String> this.keys, {
    super.key,
    this.semanticLabel,
    this.style,
  }) : label = '';

  /// The key's name.
  final String label;

  /// The keys of a combination, in the order they are pressed.
  final List<String>? keys;

  /// What a screen reader hears; null: the key's name (and a combination's
  /// names joined by a plus).
  final String? semanticLabel;

  /// Overrides for the caps' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final keys = this.keys;
    if (keys == null) {
      return Semantics(
        label: semanticLabel ?? label,
        child: ExcludeSemantics(child: _Cap(label, style: style)),
      );
    }
    final t = context.civicTheme;
    final words = context.civicText.bodySmall.copyWith(color: t.textSecondary);
    return Semantics(
      label: semanticLabel ?? keys.join(' + '),
      child: ExcludeSemantics(
        // A shortcut reads as the keyboard writes it, left to right, in
        // every language.
        child: Wrap(
          textDirection: TextDirection.ltr,
          spacing: CivicSpacing.s4,
          runSpacing: CivicSpacing.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (i, k) in keys.indexed) ...[
              if (i > 0) Text('+', style: words),
              _Cap(k, style: style),
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
      ..add(StringProperty('label', label, defaultValue: ''))
      ..add(IterableProperty<String>('keys', keys, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _Cap extends StatelessWidget {
  const _Cap(this.label, {this.style});

  final String label;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = DesignStyleOf([style, t.kbdStyle], const {});
    const edge = 2.0;
    final cap = Color.lerp(t.surface, t.rule, 0.25)!;
    return CustomPaint(
      painter: CivicFacePainter(
        fill: so.fill ?? cap,
        edgeColor: so.edge ?? t.rule,
        edgeHeight: edge,
        press: 0,
        focus: 0,
        focusColor: t.focus,
        barColor: t.focusBar,
        radius: CivicMetrics.corner,
      ),
      child: Padding(
        padding:
            (so.padding(Directionality.of(context)) ??
                    const EdgeInsets.symmetric(
                      horizontal: CivicSpacing.s8,
                      vertical: 2,
                    ))
                .add(const EdgeInsets.only(bottom: edge)),
        child: Text(
          label,
          style: context.civicText.code
              .copyWith(
                fontSize: context.civicText.bodySmall.fontSize,
                height: 1.3,
                color: t.textPrimary,
              )
              .merge(so.textStyle)
              .copyWith(color: so.foreground ?? t.textPrimary),
        ),
      ),
    );
  }
}
