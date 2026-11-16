import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/field_frame.dart';
import '../../internal/option.dart';
import '../../theme.dart';

/// A question with one answer: its [labelText] asks it (on a question page,
/// as the page's heading with [isPageHeading]), its [CivicRadio]s are the
/// answers, each with a hint where the words alone don't decide it. The
/// arrow keys move the choice, as a browser's radios do.
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
  /// The answer the arrow keys just chose, which takes the focus with it.
  final _CivicRadioFocus _focus = _CivicRadioFocus();

  List<T> get _values => [
    for (final c in widget.children)
      if (c is CivicRadio<T>) c.value,
  ];

  void _step(int by) {
    final change = widget.onChanged;
    final values = _values;
    if (change == null || values.isEmpty) return;
    final current = widget.groupValue;
    final at = current == null ? -1 : values.indexOf(current);
    final next = (at + by) % values.length;
    final value = values[next < 0 ? next + values.length : next];
    _focus.target = value;
    _focus.pending = true;
    change(value);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final labelText = widget.labelText;
    final helperText = widget.helperText;
    final errorText = widget.errorText;
    final isPageHeading = widget.isPageHeading;
    final groupValue = widget.groupValue;
    final onChanged = widget.onChanged;
    final children = widget.children;
    return DesignField(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      mergeSemantics: false,
      enabled: onChanged != null,
      builder: (context, parts) => CivicFieldFrame(
        parts: parts,
        isPageHeading: isPageHeading,
        isLegend: true,
      ),
      child: _CivicRadioScope<T>(
        groupValue: groupValue,
        onChanged: onChanged,
        focus: _focus,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(1),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(-1),
            SingleActivator(
              rtl
                  ? LogicalKeyboardKey.arrowLeft
                  : LogicalKeyboardKey.arrowRight,
            ): () =>
                _step(1),
            SingleActivator(
              rtl
                  ? LogicalKeyboardKey.arrowRight
                  : LogicalKeyboardKey.arrowLeft,
            ): () =>
                _step(-1),
          },
          // In an app the answers stand on a card, each a row; on the site
          // they stand on the page.
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
    );
  }
}

/// Where the focus goes after the arrow keys choose.
class _CivicRadioFocus {
  Object? target;
  bool pending = false;
}

class _CivicRadioScope<T> extends InheritedWidget {
  const _CivicRadioScope({
    required this.groupValue,
    required this.onChanged,
    required this.focus,
    required super.child,
  });

  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final _CivicRadioFocus focus;

  @override
  bool updateShouldNotify(_CivicRadioScope<T> old) =>
      groupValue != old.groupValue || onChanged != old.onChanged;
}

/// One answer of a [CivicRadioGroup]: a 40-point circle, the words beside
/// it, a hint under them. The chosen one shows a solid dot.
///
/// Reads [CivicStyle]'s fill (the circle), foreground (the dot and the
/// words), edge (the circle's edge) and textStyle (the words): its
/// `style:`, then [CivicThemeData.radioStyle]. The circle's size and the
/// focus ring are the look's.
class CivicRadio<T> extends StatefulWidget {
  /// An answer.
  const CivicRadio({
    super.key,
    required this.value,
    required this.labelText,
    this.helperText,
    this.enabled = true,
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
    final scope = context
        .dependOnInheritedWidgetOfExactType<_CivicRadioScope<T>>();
    assert(scope != null, 'A CivicRadio stands in a CivicRadioGroup.');
    final chosen = scope?.groupValue == widget.value;
    final change = scope?.onChanged;
    final focus = scope?.focus;
    if (chosen &&
        focus != null &&
        focus.pending &&
        focus.target == widget.value) {
      // The arrow keys chose this answer: the focus follows the choice.
      focus.pending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _node.requestFocus();
      });
    }
    return CivicOptionRow(
      styles: [widget.style, context.civicTheme.radioStyle],
      mark: chosen ? CivicMark.dot : CivicMark.none,
      round: true,
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      labelText: widget.labelText,
      helperText: widget.helperText,
      focusNode: _node,
      autofocus: widget.autofocus,
      onPressed: change == null || !widget.enabled
          ? null
          : () => change(widget.value),
    );
  }
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
