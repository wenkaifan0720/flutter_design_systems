import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/field_frame.dart';
import '../../internal/option.dart';
import '../../theme.dart';

/// A question with one answer: its [labelText] asks it (on a question page,
/// as the page's heading with [isPageHeading]), its [CivicRadio]s are the
/// answers, each with a hint where the words alone don't decide it. The
/// group is Flutter's `RadioGroup`, one stop for Tab, as a browser's
/// radios are: Tab and Shift+Tab come to the chosen answer (the first,
/// while none is) and leave the group, and the arrow keys move the choice
/// between the answers that can be chosen, Left and Right swapped right to
/// left.
///
/// ```dart
/// CivicRadioGroup<String>(
///   labelText: 'What kind of vehicle is the permit for?',
///   isPageHeading: true,
///   groupValue: vehicle,
///   onChanged: (value) => setState(() => vehicle = value),
///   children: const [
///     CivicRadio(value: 'car', labelText: 'Car or van'),
///     CivicRadio(
///       value: 'motorcycle',
///       labelText: 'Motorcycle',
///       helperText: 'Includes mopeds and scooters.',
///     ),
///   ],
/// )
/// ```
class CivicRadioGroup<T> extends StatefulWidget {
  /// A question with one answer.
  const CivicRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.children,
    this.labelText,
    this.helperText,
    this.errorText,
    this.isPageHeading = false,
  });

  /// The answer chosen; null while none is.
  final T? groupValue;

  /// Called with an answer as it is chosen; null disables the group.
  final ValueChanged<T?>? onChanged;

  /// The answers: [CivicRadio]s, and [CivicRadioDivider]s between them.
  final List<Widget> children;

  /// The question: the group's name.
  final String? labelText;

  /// How to answer.
  final String? helperText;

  /// What to fix; null while the answer is fine.
  final String? errorText;

  /// Whether the question is the page's heading.
  final bool isPageHeading;

  @override
  State<CivicRadioGroup<T>> createState() => _CivicRadioGroupState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<T>('groupValue', groupValue, defaultValue: null),
      )
      ..add(ObjectFlagProperty<ValueChanged<T?>>.has('onChanged', onChanged))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'isPageHeading',
          value: isPageHeading,
          ifTrue: 'page heading',
        ),
      );
  }
}

class _CivicRadioGroupState<T> extends State<CivicRadioGroup<T>> {
  @override
  Widget build(BuildContext context) {
    final children = widget.children;
    assert(() {
      final values = [
        for (final child in children)
          if (child is CivicRadio<T>) child.value,
      ];
      return values.toSet().length == values.length;
    }(), 'Each CivicRadio in a group needs its own value.');
    final onChanged = widget.onChanged;
    return RawInputDecorator(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: onChanged != null,
      builder: (context, parts) => CivicFieldFrame(
        parts: parts,
        isPageHeading: widget.isPageHeading,
        isLegend: true,
      ),
      // Flutter's radio group: one Tab stop (the chosen answer, else the
      // first), the arrows moving and choosing. ui_core's keyboard fix inside
      // it gives the group its Tab stop when the chosen answer can't be
      // chosen, and swaps Left and Right right to left, until Flutter's own
      // fixes do.
      child: RadioGroup<T>(
        groupValue: widget.groupValue,
        onChanged: onChanged ?? _none,
        child: RadioGroupKeyboardFix<T>(
          child: _CivicRadioGroupEnabled(
            enabled: onChanged != null,
            // In an app the answers stand on a card, each a row; on the site
            // they stand on the page, a divider where the page put one.
            child: CivicCardScope.cards(context)
                ? CivicOptionCard(children: children)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    spacing: CivicSpacing.s4,
                    children: children,
                  ),
          ),
        ),
      ),
    );
  }

  static void _none(Object? _) {}
}

/// One answer of a [CivicRadioGroup]: a 40-point circle, the words beside
/// it, a hint under them. The chosen one shows a solid dot.
///
/// Reads [CivicStyle]'s fill (the circle), foreground (the dot and the
/// words), edge (the circle's edge) and textStyle (the words): its
/// `style:`, then [CivicThemeData.radioStyle]. The circle's size and the
/// focus ring are the look's.
///
/// [CivicRadioGroup]'s example puts a set of them in a group.
class CivicRadio<T> extends StatefulWidget {
  /// An answer.
  const CivicRadio({
    super.key,
    required this.value,
    required this.labelText,
    this.helperText,
    this.enabled = true,
    this.toggleable = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// What choosing it gives the group.
  final T value;

  /// The words.
  final String labelText;

  /// A hint under the words.
  final String? helperText;

  /// Whether it can be chosen.
  final bool enabled;

  /// Whether a press, Enter or Space on it while it is chosen clears the
  /// choice, as Flutter's `Radio.toggleable`: the group's `onChanged` hears
  /// null. Otherwise the chosen answer stays chosen.
  final bool toggleable;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for this answer's look.
  final CivicStyle? style;

  @override
  State<CivicRadio<T>> createState() => _CivicRadioState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(StringProperty('labelText', labelText))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('toggleable', value: toggleable, ifTrue: 'toggleable'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicRadioState<T> extends State<CivicRadio<T>> {
  FocusNode? _own;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = RadioGroup.maybeOf<T>(context);
    assert(registry != null, 'A CivicRadio stands in a CivicRadioGroup.');
    final label = widget.labelText;
    final helper = widget.helperText;
    // One node for the answer: RawRadio's (checked, one of a group, its focus
    // and its tap), with the words and the hint.
    return MergeSemantics(
      child: RawRadio<T>(
        value: widget.value,
        mouseCursor: WidgetStateMouseCursor.clickable,
        toggleable: widget.toggleable,
        focusNode: _node,
        autofocus: widget.autofocus,
        groupRegistry: registry,
        enabled: widget.enabled && _CivicRadioGroupEnabled.of(context),
        builder: (context, radio) => Semantics(
          label: label,
          hint: helper,
          child: ExcludeSemantics(
            // All of it takes a press, its gaps too, as RawRadio's
            // detector finds only what the face paints.
            child: Listener(
              behavior: HitTestBehavior.opaque,
              child: CivicOptionFace(
                // RawRadio's states, and pressed while a press is down on it.
                states: {
                  ...radio.states,
                  if (radio.downPosition != null) WidgetState.pressed,
                },
                mark: radio.value ?? false ? CivicMark.dot : CivicMark.none,
                round: true,
                styles: [widget.style, context.civicTheme.radioStyle],
                labelText: label,
                helperText: helper,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Whether the group round an answer takes a choice (its onChanged given).
class _CivicRadioGroupEnabled extends InheritedWidget {
  const _CivicRadioGroupEnabled({required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_CivicRadioGroupEnabled>()
          ?.enabled ??
      true;

  @override
  bool updateShouldNotify(_CivicRadioGroupEnabled old) =>
      enabled != old.enabled;
}

/// The word between a group's answers and the one that stands apart from
/// them ("or", in the reader's language, passed by the page).
class CivicRadioDivider extends StatelessWidget {
  /// A divider saying [label].
  const CivicRadioDivider({super.key, required this.label});

  /// The word.
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s4),
    child: SizedBox(
      width: 40,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.civicText.body,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
  }
}
