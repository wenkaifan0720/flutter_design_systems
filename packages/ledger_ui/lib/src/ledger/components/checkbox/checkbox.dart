import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../style.dart';
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
    this.live,
    this.press,
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

  // Whether it can be pressed; null: while [onTap] is set.
  final bool? live;

  // Its control over the face, when not a [LedgerPressable] on [onTap] (a
  // radio's [LedgerRadioPress]): given the face, the words for a screen
  // reader and the corner of its press.
  final Widget Function(Widget face, String? label, double radius)? press;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final live = this.live ?? onTap != null;
    final words = label;
    final Widget face;
    if (words == null) {
      face = mark;
    } else {
      // The line is the density's height at least; words that wrap (a long
      // label, large text) grow it rather than being cut, 4 clear of the
      // next line's words.
      face = ConstrainedBox(
        constraints: BoxConstraints(minHeight: t.density.height(_line)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: _gap,
            children: [
              mark,
              Flexible(
                child: Text(
                  words,
                  style: t.body
                      .line(20)
                      .copyWith(
                        leadingDistribution: TextLeadingDistribution.even,
                      )
                      .colored(live ? t.textPrimary : t.textTertiary),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final corner = words == null ? radius : t.smallRadius;
    final control =
        press?.call(face, semanticLabel ?? words, corner) ??
        LedgerPressable(
          onTap: onTap,
          label: semanticLabel ?? words,
          checked: mixed ? null : checked,
          mixed: mixed,
          inMutuallyExclusiveGroup: radio,
          isError: isError,
          focusNode: focusNode,
          autofocus: autofocus,
          radius: corner,
          child: face,
        );
    final drawn = Opacity(opacity: live ? 1 : _off, child: control);
    // A bare mark stands on its column's start keyline, its target growing
    // toward the end.
    return words == null
        ? TapTargetPadding(
            alignment: AlignmentDirectional.centerStart,
            child: drawn,
          )
        : drawn;
  }

  static const double _line = 48;
  static const double _gap = 12;
  static const double _off = .45;
}

/// A checkbox: a 20 square ringed in the ink, filled with the ink and
/// ticked in the paper when [value] is true, a dash when it is null (with
/// [tristate]). With a [label] the words stand after it on its line (two or
/// more when they wrap), and the line is the target. [isError] rings it in the danger red; a null
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
    this.style,
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

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// This box's look, over `components.checkbox`. It reads `fill`,
  /// `foreground` (the mark), `edge`, `side`, `overlay`, `shape`,
  /// `minimumSize` (the box's side) and `iconSize` (the mark's); a ticked
  /// or mixed box is `selected`, an error one `error`.
  final LedgerStyle? style;

  void _next() {
    final next = switch (value) {
      false => true,
      true => tristate ? null : false,
      null => false,
    };
    onChanged!(next);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<bool?>>.has('onChanged', onChanged))
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'isError'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final on = value ?? true;
    final ring = isError ? t.danger : t.borderStrong;
    // The box fills with ink and its mark inks in, in Ledger's one motion.
    final mark = Builder(
      builder: (context) {
        final so = LedgerStyleOf(
          [style, t.components.checkbox],
          {
            ...LedgerPressStates.of(context),
            if (value ?? true) WidgetState.selected,
            if (isError) WidgetState.error,
            if (onChanged == null) WidgetState.disabled,
          },
        );
        final side = so.minimumSize?.shortestSide ?? _size;
        return LedgerFace(
          style: so.dress(
            LedgerFaceStyle(
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
          ),
          builder: (context, s, _) => Container(
            width: side,
            height: side,
            decoration: s.ground,
            // No mark at all once it has faded out: an empty box carries none.
            child: s.ink.a == 0
                ? null
                : Icon(
                    value == null ? LucideIcons.minus : LucideIcons.check,
                    size: so.iconSize ?? 14,
                    color: s.ink,
                  ),
          ),
        );
      },
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
/// group's choice. With a [label] the words stand after it on one line, and
/// the line is the target; with [toggleable] a press on the chosen one
/// clears the choice (null).
///
/// Under a RadioGroup it is one of the group's radios, as Flutter's Radio
/// is: the group holds the choice and takes it, Tab reaches the group at its
/// choice and the arrows move and choose (with ui_core's
/// RadioGroupKeyboardFix inside the group). Alone, [groupValue] is the
/// choice and [onChanged] takes it; a null [onChanged] disables it.
///
/// Built on Flutter's RawRadio.
///
/// ```dart
/// LedgerRadio<String>(value: 'monthly', groupValue: plan, label: 'Monthly', onChanged: (v) {})
/// ```
class LedgerRadio<T> extends StatelessWidget {
  /// A radio for [value], of the RadioGroup above it or of the set at
  /// [groupValue].
  const LedgerRadio({
    required this.value,
    this.groupValue,
    this.onChanged,
    this.enabled,
    this.toggleable = false,
    this.label,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What choosing it sets.
  final T value;

  /// The set's chosen value, for a radio under no RadioGroup.
  final T? groupValue;

  /// Called with [value] when it is chosen, for a radio under no
  /// RadioGroup; null disables it.
  final ValueChanged<T?>? onChanged;

  /// Whether it can be chosen; null: under a RadioGroup it can, alone while
  /// [onChanged] is set.
  final bool? enabled;

  /// Whether a press on the chosen one clears the choice.
  final bool toggleable;

  /// Its words, after it on its line.
  final String? label;

  /// The spoken name, when the words are not it (or there are none).
  final String? semanticLabel;

  /// The radio's focus; never disposed when given.
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(
        DiagnosticsProperty<T>('groupValue', groupValue, defaultValue: null),
      )
      ..add(ObjectFlagProperty<ValueChanged<T?>>.has('onChanged', onChanged))
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: null))
      ..add(FlagProperty('toggleable', value: toggleable, ifTrue: 'toggleable'))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final group = RadioGroup.maybeOf<T>(context);
    final RadioGroupRegistry<T> registry =
        group ?? _Alone<T>(groupValue, onChanged ?? (_) {});
    final live = enabled ?? (group != null || onChanged != null);
    final on = value == registry.groupValue;
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
    return _Choice(
      mark: mark,
      onTap: null,
      live: live,
      press: (face, label, radius) => LedgerRadioPress<T>(
        value: value,
        enabled: live,
        registry: registry,
        toggleable: toggleable,
        label: label,
        radius: radius,
        focusNode: focusNode,
        autofocus: autofocus,
        child: face,
      ),
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

// The group of a radio under no RadioGroup: its own [groupValue] and
// [onChanged].
class _Alone<T> extends RadioGroupRegistry<T> {
  _Alone(this.groupValue, this.onChanged);

  @override
  final T? groupValue;

  @override
  final ValueChanged<T?> onChanged;

  @override
  void registerClient(RadioClient<T> radio) {}

  @override
  void unregisterClient(RadioClient<T> radio) {}
}
