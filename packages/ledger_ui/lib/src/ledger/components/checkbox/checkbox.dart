import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// The box a [LedgerCheckbox] and a [LedgerRadio] stand in: the mark
/// alone, or the mark and its words on one line of the control height
/// (48 at [LedgerDensity.standard]), the whole line one target.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.mark,
    required this.onTap,
    required this.label,
    required this.semanticLabel,
    required this.checked,
    required this.mixed,
    required this.radio,
    required this.isError,
    required this.focusNode,
    required this.autofocus,
    required this.radius,
  });

  final Widget mark;
  final VoidCallback? onTap;
  final String? label;
  final String? semanticLabel;
  final bool checked;
  final bool mixed;
  final bool radio;
  final bool isError;
  final FocusNode? focusNode;
  final bool autofocus;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final live = onTap != null;
    final words = label;
    final Widget face;
    if (words == null) {
      face = mark;
    } else {
      face = SizedBox(
        height: t.density.height(_line),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _gap,
          children: [
            mark,
            Flexible(
              child: Text(
                words,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.body
                    .line(20)
                    .copyWith(leadingDistribution: TextLeadingDistribution.even)
                    .colored(live ? t.textPrimary : t.textTertiary),
              ),
            ),
          ],
        ),
      );
    }
    final control = LedgerPressable(
      onTap: onTap,
      label: semanticLabel ?? words,
      checked: mixed ? null : checked,
      mixed: mixed,
      inMutuallyExclusiveGroup: radio,
      isError: isError,
      focusNode: focusNode,
      autofocus: autofocus,
      radius: words == null ? radius : t.smallRadius,
      child: face,
    );
    final drawn = Opacity(opacity: live ? 1 : _off, child: control);
    return words == null ? LedgerHitSlop(child: drawn) : drawn;
  }

  static const double _line = 48;
  static const double _gap = 12;
  static const double _off = .45;
}

/// A checkbox: a 20 square ringed in the ink, filled with the ink and
/// ticked in the paper when [value] is true, a dash when it is null (with
/// [tristate]). With a [label] the words stand after it on one line, and the
/// line is the target. [isError] rings it in the danger red; a null
/// [onChanged] disables it.
///
/// ```dart
/// LedgerCheckbox(value: true, label: 'Email me a receipt', onChanged: (v) {})
/// ```
class LedgerCheckbox extends StatelessWidget {
  /// A checkbox at [value], changed by [onChanged].
  const LedgerCheckbox({
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.label,
    this.semanticLabel,
    this.isError = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(tristate || value != null);

  /// Ticked, not, or (with [tristate]) partly.
  final bool? value;

  /// Called with the next value; null disables it.
  final ValueChanged<bool?>? onChanged;

  /// Whether it passes through a partly-ticked state (null).
  final bool tristate;

  /// Its words, after it on its line.
  final String? label;

  /// The spoken name, when the words are not it (or there are none).
  final String? semanticLabel;

  /// Whether what it holds is wrong.
  final bool isError;

  /// The checkbox's focus; never disposed when given.
  final FocusNode? focusNode;

  /// Whether it takes the focus when it first stands.
  final bool autofocus;

  void _next() {
    final next = switch (value) {
      false => true,
      true => tristate ? null : false,
      null => false,
    };
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final on = value ?? true;
    final ring = isError ? t.danger : t.borderStrong;
    // The box fills with ink and its mark inks in, in Ledger's one motion.
    final mark = LedgerFace(
      style: LedgerFaceStyle(
        ink: on ? t.background : t.background.withValues(alpha: 0),
        ground: BoxDecoration(
          color: on ? (isError ? t.danger : t.textPrimary) : t.surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: on ? const Color(0x00000000) : ring,
            width: 1.5,
          ),
        ),
      ),
      builder: (context, s, _) => Container(
        width: _size,
        height: _size,
        decoration: s.ground,
        // No mark at all once it has faded out: an empty box carries none.
        child: s.ink.a == 0
            ? null
            : Icon(
                value == null ? LucideIcons.minus : LucideIcons.check,
                size: 14,
                color: s.ink,
              ),
      ),
    );
    return _Choice(
      mark: mark,
      onTap: onChanged == null ? null : _next,
      label: label,
      semanticLabel: semanticLabel,
      checked: value ?? false,
      mixed: value == null,
      radio: false,
      isError: isError,
      focusNode: focusNode,
      autofocus: autofocus,
      radius: _radius,
    );
  }

  static const double _size = 20;
  static const double _radius = 4;
}

/// A radio: a 20 ring in the ink, an ink dot in it when [value] is the
/// [groupValue]. With a [label] the words stand after it on one line, and
/// the line is the target. A null [onChanged] disables it; with
/// [toggleable] a press on the chosen one clears the choice (null).
///
/// ```dart
/// LedgerRadio<String>(value: 'monthly', groupValue: plan, label: 'Monthly', onChanged: (v) {})
/// ```
class LedgerRadio<T> extends StatelessWidget {
  /// A radio for [value] of the set at [groupValue].
  const LedgerRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.toggleable = false,
    this.label,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What choosing it sets.
  final T value;

  /// The group's chosen value.
  final T? groupValue;

  /// Called with [value] when it is chosen; null disables it.
  final ValueChanged<T?>? onChanged;

  /// Whether a press on the chosen one clears the choice.
  final bool toggleable;

  /// Its words, after it on its line.
  final String? label;

  /// The spoken name, when the words are not it (or there are none).
  final String? semanticLabel;

  /// The radio's focus; never disposed when given.
  final FocusNode? focusNode;

  /// Whether it takes the focus when it first stands.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final on = value == groupValue;
    final mark = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: t.surface,
        shape: BoxShape.circle,
        border: Border.all(color: t.borderStrong, width: 1.5),
      ),
      alignment: Alignment.center,
      // The dot inks in where it stands (and fades when another is chosen).
      child: LedgerEase(
        value: on ? 1 : 0,
        builder: (context, ink, dot) => Opacity(opacity: ink, child: dot),
        child: Container(
          width: _dot,
          height: _dot,
          decoration: BoxDecoration(
            color: t.textPrimary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
    final change = onChanged;
    return _Choice(
      mark: mark,
      onTap: change == null
          ? null
          : () {
              if (!on) {
                change(value);
              } else if (toggleable) {
                change(null);
              }
            },
      label: label,
      semanticLabel: semanticLabel,
      checked: on,
      mixed: false,
      radio: true,
      isError: false,
      focusNode: focusNode,
      autofocus: autofocus,
      radius: _size / 2,
    );
  }

  static const double _size = 20;
  static const double _dot = 10;
}
