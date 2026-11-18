import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/list_option.dart';
import '../../internal/paint.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// One answer from a long list, found by typing: a [CivicTextField] whose
/// words narrow the [options] in a list under the box, floating on a
/// hairline and a soft shadow, as a select's list is: the chosen row on
/// the inset rule in the action colour, bold and ticked, a row under the
/// pointer grey. The arrow keys walk the list, the row reached lies on the
/// yellow plate, Enter or a press takes it, Escape closes the list; after
/// Enter the box keeps the focus, and typing goes on in it. A screen reader
/// hears the row reached and how many matched. When nothing
/// matches the list says so ("No results").
///
/// Given a [search] in place of [options] (a register looked up as the
/// reader types), the list says "Loading" while it looks, in words: nothing
/// spins. When the search fails it says so, with "Try again" under it: Down
/// reaches it, Enter or a press runs the search again. A screen reader
/// hears each as it appears. ui_core's [DesignCombobox] runs the search.
///
/// Use it where a select would hold too many answers to scan (a country,
/// a street, a school); use [CivicRadioGroup] for a few.
///
/// The box reads [CivicStyle] as [CivicTextField] does: [style], then
/// [CivicThemeData.textFieldStyle]. The list is the look's, as the
/// select's is.
///
/// ```dart
/// CivicCombobox<String>(
///   labelText: 'Street',
///   options: streets,
///   onSelected: (value) => setState(() => street = value),
/// )
/// ```
class CivicCombobox<T extends Object> extends StatelessWidget {
  /// A box that finds an answer from [options].
  const CivicCombobox({
    super.key,
    this.options = const [],
    this.search,
    this.displayStringForOption,
    this.value,
    this.onSelected,
    this.labelText,
    this.helperText,
    this.errorText,
    this.hintText,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.style,
  });

  /// The answers typing narrows, when there is no [search].
  final Iterable<T> options;

  /// Finds the answers for the words typed, in place of narrowing
  /// [options]: a register looked up as the reader types.
  final DesignOptionSearch<T>? search;

  /// An answer's words; null says its `toString`.
  final String Function(T option)? displayStringForOption;

  /// The answer chosen, ticked in the list.
  final T? value;

  /// Called with an answer as it is chosen.
  final ValueChanged<T>? onSelected;

  /// What the box asks.
  final String? labelText;

  /// How to answer.
  final String? helperText;

  /// What to fix; null while the answer is fine.
  final String? errorText;

  /// Shown in the box while it is empty.
  final String? hintText;

  /// The words typed; the combobox's own when null, and never disposed
  /// when given.
  final TextEditingController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Whether it takes input.
  final bool enabled;

  /// Overrides for the box's look.
  final CivicStyle? style;

  String _say(T option) =>
      displayStringForOption?.call(option) ?? option.toString();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DesignCombobox<T>(
      options: options,
      search: search,
      displayStringForOption: _say,
      value: value,
      onSelected: onSelected,
      controller: controller,
      focusNode: focusNode,
      semanticLabel: labelText,
      optionsMaxHeight: _listMost,
      fieldBuilder: (context, field) => CivicTextField(
        controller: field.controller,
        focusNode: field.focusNode,
        labelText: labelText,
        helperText: helperText,
        errorText: errorText,
        hintText: hintText,
        enabled: enabled,
        textInputAction: TextInputAction.done,
        // The return key takes the lit answer and the field keeps the
        // focus: taken in onEditingComplete, with no onSubmitted, so
        // Flutter never restarts the field's text input (in a browser the
        // restarted input would take no more typing).
        onEditingComplete: field.submit,
        style: style,
      ),
      surfaceBuilder: (context, list) => Padding(
        padding: const EdgeInsets.only(top: CivicSpacing.s8),
        child: DecoratedBox(
          decoration: civicFloating(
            face: t.background,
            hairline: t.rule,
            dark: t.isDark,
          ),
          child: Padding(
            padding: const EdgeInsets.all(CivicMetrics.edge - 1),
            child: list,
          ),
        ),
      ),
      emptyBuilder: (context) =>
          _Note(DesignLocalizations.of(context).noResultsLabel),
      // The words say it is looking: nothing spins.
      loadingBuilder: (context) =>
          _Note(DesignLocalizations.of(context).loadingLabel),
      errorBuilder: (context, failure) {
        final words = DesignLocalizations.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The list's own node says it as it appears.
            ExcludeSemantics(
              child: _Note(words.searchFailedMessage, color: t.danger),
            ),
            DesignPressable(
              onPressed: failure.retry,
              semanticLabel: words.retryButtonLabel,
              builder: (context, states, _) => CivicListOption(
                label: words.retryButtonLabel,
                chosen: false,
                hovered: states.contains(WidgetState.hovered),
                pressed: states.contains(WidgetState.pressed),
                focused: failure.focused,
              ),
            ),
          ],
        );
      },
      optionBuilder: (context, option, states) => CivicListOption(
        label: _say(option),
        chosen: states.contains(WidgetState.selected),
        hovered: states.contains(WidgetState.hovered),
        pressed: states.contains(WidgetState.pressed),
        focused: states.contains(WidgetState.focused),
      ),
    );
  }

  /// The tallest the list stands: five rows and a half, so a reader sees
  /// there is more.
  static const double _listMost = CivicMetrics.controlHeight * 5.5;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(ObjectFlagProperty<DesignOptionSearch<T>>.has('search', search))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
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
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

// A line of words in the list where its options would be: no matches, the
// search looking, or its failure.
class _Note extends StatelessWidget {
  const _Note(this.words, {this.color});

  final String words;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    // As wide as the list (the field's width), its words at the start.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicSpacing.s12,
          vertical: CivicSpacing.s12,
        ),
        child: Text(
          words,
          style: context.civicText.body.copyWith(
            color: color ?? t.textSecondary,
          ),
        ),
      ),
    );
  }
}
