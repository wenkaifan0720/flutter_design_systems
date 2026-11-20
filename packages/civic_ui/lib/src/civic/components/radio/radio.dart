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
/// group is one stop for Tab, as a browser's radios and Flutter's
/// `RadioGroup` are: Tab and Shift+Tab come to the chosen answer (the first,
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
    final answers = <T, CivicRadio<T>>{
      for (final child in children)
        if (child is CivicRadio<T>) child.value: child,
    };
    assert(
      answers.length == children.whereType<CivicRadio<T>>().length,
      'Each CivicRadio in a group needs its own value.',
    );
    final onChanged = widget.onChanged;
    return DesignField(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: onChanged != null,
      builder: (context, parts) => CivicFieldFrame(
        parts: parts,
        isPageHeading: widget.isPageHeading,
        isLegend: true,
      ),
      child: _CivicRadioScope<T>(
        groupValue: widget.groupValue,
        onChanged: onChanged,
        // Flutter's RadioGroup, through ui_core: one Tab stop at the chosen
        // answer (the first that can be chosen, while none is), and the
        // arrow keys choose as they move.
        child: DesignRadioGroup<T>(
          options: answers.keys.toList(),
          value: widget.groupValue,
          onChanged: onChanged == null ? null : (value) => onChanged(value),
          isEnabled: (value) => answers[value]!.enabled,
          focusNodeFor: (value) => answers[value]!.focusNode,
          itemBuilder: (context, value, node, select) => _CivicRadioSlot(
            focusNode: node,
            select: select,
            child: answers[value]!,
          ),
          layoutBuilder: (context, items) {
            // The answers in their places, the dividers between them.
            var next = 0;
            final laidOut = [
              for (final child in children)
                child is CivicRadio<T> ? items[next++] : child,
            ];
            // In an app the answers stand on a card, each a row; on the site
            // they stand on the page.
            return CivicCardScope.cards(context)
                ? CivicOptionCard(children: laidOut)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    spacing: CivicSpacing.s4,
                    children: laidOut,
                  );
          },
        ),
      ),
    );
  }
}

class _CivicRadioScope<T> extends InheritedWidget {
  const _CivicRadioScope({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  @override
  bool updateShouldNotify(_CivicRadioScope<T> old) =>
      groupValue != old.groupValue || onChanged != old.onChanged;
}

/// The focus node and the press the group gives one answer.
class _CivicRadioSlot extends InheritedWidget {
  const _CivicRadioSlot({
    required this.focusNode,
    required this.select,
    required super.child,
  });

  final FocusNode focusNode;
  final VoidCallback? select;

  @override
  bool updateShouldNotify(_CivicRadioSlot old) =>
      focusNode != old.focusNode || select != old.select;
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
    final slot = context.dependOnInheritedWidgetOfExactType<_CivicRadioSlot>();
    final chosen = scope?.groupValue == widget.value;
    final change = scope?.onChanged;
    // In its group, the answer takes the group's node (this radio's own
    // focusNode, when it has one). The group says whether it can be chosen;
    // a press tells the group's onChanged even when it is already chosen.
    final node = slot?.focusNode ?? widget.focusNode ?? (_own ??= FocusNode());
    final open = slot != null
        ? slot.select != null
        : change != null && widget.enabled;
    final VoidCallback? press = open && change != null
        ? () => change(widget.value)
        : null;
    // Space presses the answer as Enter does, the chosen one too: the
    // group's own Space only chooses an answer not yet chosen.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: CivicOptionRow(
        styles: [widget.style, context.civicTheme.radioStyle],
        mark: chosen ? CivicMark.dot : CivicMark.none,
        round: true,
        checked: chosen,
        inMutuallyExclusiveGroup: true,
        labelText: widget.labelText,
        helperText: widget.helperText,
        focusNode: node,
        autofocus: widget.autofocus,
        onPressed: press,
      ),
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
