import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_center.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// A choice token: a pill ringed in the rule on the raised paper, 32 tall
/// (4 off each density step, as the controls beside it step),
/// its [label] in the mono medium; the chosen one is set in the ink with
/// the paper's words. An [icon] stands before the words and a [count] (how
/// many things it matches) after them, in the mono. A null [onTap] shows it
/// without letting it change. Says its label, its count and whether it is
/// chosen. Set several in a [LedgerChipRow].
///
/// ```dart
/// LedgerChip('Groceries', count: 12, selected: filter == 'Groceries', onTap: () => pick('Groceries'))
/// ```
class LedgerChip extends StatelessWidget {
  /// A chip worded [label].
  const LedgerChip(
    this.label, {
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
    this.style,
    super.key,
  }) : assert(count == null || count >= 0);

  /// The chip's words.
  final String label;

  /// Whether it is the chosen one.
  final bool selected;

  /// What a press does; null shows it without letting it change.
  final VoidCallback? onTap;

  /// A glyph before the words, drawn at 14.
  final IconData? icon;

  /// How many things it matches, after the words.
  final int? count;

  /// This chip's look, over `components.chip`. It reads `fill`,
  /// `foreground`, `edge`, `side`, `overlay`, `shape`, `padding`,
  /// `minimumSize`, `textStyle` and `iconSize`; `selected` is among its
  /// states.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(IntProperty('count', count, defaultValue: null))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // Shown without letting it change, it is in pencil: the third ink.
    final ink = selected
        ? t.surface
        : onTap == null
        ? t.textTertiary
        : t.textSecondary;
    // The chosen fill and its ink come and go in Ledger's one motion.
    final face = Builder(
      builder: (context) {
        final so = LedgerStyleOf(
          [style, t.components.chip],
          {
            ...LedgerPressStates.of(context),
            if (selected) WidgetState.selected,
            if (onTap == null) WidgetState.disabled,
          },
        );
        final least = so.minimumSize;
        return LedgerFace(
          style: so.dress(
            LedgerFaceStyle(
              ink: ink,
              quiet: selected
                  ? t.surface.withValues(alpha: _countOnInk)
                  : t.textTertiary,
              ground: BoxDecoration(
                color: selected ? t.textPrimary : t.surface,
                borderRadius: BorderRadius.circular(t.controlRadius),
                border: Border.all(color: selected ? t.textPrimary : t.border),
              ),
            ),
          ),
          builder: (context, s, _) {
            final words = so.words(
              t.meta.medium.sized(11).line(_labelLine).tracked(.02),
              s.ink,
            );
            return Container(
              height: math.max(heightOf(t), least?.height ?? 0),
              constraints: BoxConstraints(minWidth: least?.width ?? 0),
              padding:
                  so.padding(Directionality.of(context)) ??
                  EdgeInsetsDirectional.only(
                    start: icon == null ? _pad : _padGlyph,
                    end: count == null ? _pad : _padGlyph,
                  ),
              decoration: s.ground,
              // Its own width under a loose one: a Container's alignment would
              // stretch it.
              child: Center(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: _gap,
                  children: [
                    if (icon != null)
                      Icon(
                        icon,
                        size: so.iconSize ?? LedgerIconSize.i14,
                        color: s.ink,
                      ),
                    ledgerCapCenter(
                      words,
                      Text(label, softWrap: false, style: words),
                    ),
                    if (count != null)
                      ledgerCapCenter(
                        t.meta,
                        Text(
                          '$count',
                          softWrap: false,
                          style: t.meta
                              .sized(11)
                              .line(_labelLine)
                              .colored(s.quiet ?? t.textTertiary),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return TapTargetPadding(
      child: LedgerPressable(
        onTap: onTap,
        label: label,
        value: count == null ? null : '$count',
        selected: selected,
        radius: t.controlRadius,
        child: face,
      ),
    );
  }

  // DERIVED from the filter pill (`.filter`: 32 tall, 0 13, 500 11/30).
  /// How tall a chip's face stands at [t]'s density: 32 at standard, 4 off
  /// each step, never under 24.
  static double heightOf(LedgerThemeData t) =>
      t.density.height(_height, floor: _floor);

  static const double _height = 32;
  static const double _floor = 24;
  // The words on a line of their own, inside the pill: RawCapCenter sets
  // their capitals on its middle, and the ring stays out of their box.
  static const double _labelLine = 16;
  static const double _pad = 12;
  static const double _padGlyph = 10;
  static const double _gap = 6;
  static const double _countOnInk = .72;
}

/// Chips set in a row that wraps rather than overflows, 6 apart each way,
/// naming the set to a screen reader by [label]. Each chip keeps its own
/// press and lays out at the tap floor; the row only lays them out and holds
/// them together.
///
/// ```dart
/// LedgerChipRow(label: 'Categories', children: [for (final c in categories) LedgerChip(c.name, count: c.count, selected: picked.contains(c), onTap: () => toggle(c))])
/// ```
class LedgerChipRow extends StatelessWidget {
  /// A wrapping row of [children], named [label].
  const LedgerChipRow({required this.children, this.label, super.key});

  /// The chips, usually [LedgerChip]s.
  final List<Widget> children;

  /// What the set chooses, spoken before its chips.
  final String? label;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Wrap(
      spacing: _gap,
      runSpacing: _gap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    ),
  );

  // DERIVED from `.filters`, 6 apart.
  static const double _gap = 6;
}
