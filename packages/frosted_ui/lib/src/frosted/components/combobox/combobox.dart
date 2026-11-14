import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/bare_field.dart';
import '../../internal/cap.dart';
import '../../internal/face.dart';
import '../../internal/panel.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../forms/forms.dart';
import '../pressable/pressable.dart';
import '../../internal/measure.dart';

String _plain(Object option) => '$option';

// ---------------------------------------------------------------------------
// Combobox
// ---------------------------------------------------------------------------

/// A text field that narrows a list as you type and takes one of its
/// [options] (Material's Autocomplete, shadcn's Combobox): the field in
/// [FrostedTextField]'s well with a chevron at its end, the matches on the
/// look's panel under it (above when there is no room), each a row that
/// lights under the arrow keys and the pointer, the chosen one checked;
/// words no option fits say so on the panel.
/// Return or a press takes the lit row; Escape closes the list. With
/// [requireSelection] text that is not an option is put back. [search]
/// fetches matches from elsewhere (a server). ui_core's [DesignCombobox] is
/// the behaviour.
///
/// ```dart
/// FrostedCombobox<String>(label: 'Country', options: countries, value: country, onSelected: (v) => setState(() => country = v))
/// ```
class FrostedCombobox<T extends Object> extends StatelessWidget {
  /// A combobox named [label] over [options].
  const FrostedCombobox({
    required this.label,
    this.options = const [],
    this.search,
    this.value,
    this.onSelected,
    this.displayString = _plain,
    this.hint,
    this.helper,
    this.error,
    this.requireSelection = false,
    this.controller,
    this.focusNode,
    this.maxListHeight = 300,
    this.autofocus = false,
    super.key,
  });

  /// The field's name, over its well.
  final String label;

  /// What it offers.
  final Iterable<T> options;

  /// Fetches the matches for a query, in place of filtering [options].
  final FutureOr<Iterable<T>> Function(String query)? search;

  /// The chosen option.
  final T? value;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// An option's words.
  final String Function(T option) displayString;

  /// The placeholder.
  final String? hint;

  /// The help line under the well.
  final String? helper;

  /// What is wrong, in place of the help line.
  final String? error;

  /// Whether only an option may stand in the field.
  final bool requireSelection;

  /// The text's controller, when the caller holds it.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// The tallest the list stands before it scrolls.
  final double maxListHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // A select's measure: its column on a phone, at most 320 from 600 up.
    return FrostedControlMeasure(
      child: DesignCombobox<T>(
        options: options,
        search: search,
        value: value,
        onSelected: onSelected,
        displayStringForOption: displayString,
        requireSelection: requireSelection,
        controller: controller,
        focusNode: focusNode,
        optionsMaxHeight: maxListHeight,
        semanticLabel: label,
        fieldBuilder: (context, field) => FrostedTextField(
          autofocus: autofocus,
          label: label,
          controller: field.controller,
          focusNode: field.focusNode,
          onSubmitted: (_) => field.submit(),
          hint: hint,
          helper: helper,
          error: error,
          trailing: ExcludeSemantics(
            child: Icon(
              FrostedGlyphs.chevronDown,
              size: FrostedIconSize.i18,
              color: t.colorScheme.textTertiary,
            ),
          ),
        ),
        optionBuilder: (context, option, states) =>
            FrostedPanelRow(label: displayString(option), states: states),
        surfaceBuilder: (context, list) => FrostedPanel(child: list),
        emptyBuilder: (context) => Padding(
          padding: const EdgeInsets.all(FrostedSpacing.s24),
          child: Text(
            DesignLocalizations.of(context).noResultsLabel,
            textAlign: TextAlign.center,
            style: t.textTheme.titleMedium.c(t.colorScheme.textTertiary),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multi-select
// ---------------------------------------------------------------------------

/// Several of a list's [options] taken as chips in one well (shadcn's
/// multi-select, a tag input): each chosen value a chip with its own ✕,
/// the text after them narrowing the list under the well. Return or a
/// press takes the lit option; Backspace in an empty field lights the last
/// chip and a second removes it; the arrow keys walk the chips. With
/// [onCreate] what is typed becomes a value of its own (a new tag); [maxTags]
/// stops taking more. ui_core's [DesignTagInput] is the behaviour.
///
/// ```dart
/// FrostedMultiSelect<String>(label: 'Tags', options: tags, values: chosen, onChanged: (v) => setState(() => chosen = v))
/// ```
class FrostedMultiSelect<T extends Object> extends StatefulWidget {
  /// A multi-select named [label] holding [values].
  const FrostedMultiSelect({
    required this.label,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.displayString = _plain,
    this.onCreate,
    this.maxTags,
    this.hint,
    this.helper,
    this.error,
    this.focusNode,
    this.maxListHeight = 300,
    this.autofocus = false,
    super.key,
  });

  /// The field's name, over its well.
  final String label;

  /// What is chosen, in order.
  final List<T> values;

  /// Called with the values after a change.
  final ValueChanged<List<T>> onChanged;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// What it offers.
  final Iterable<T> options;

  /// Fetches the matches for a query, in place of filtering [options].
  final FutureOr<Iterable<T>> Function(String query)? search;

  /// A value's words.
  final String Function(T value) displayString;

  /// Turns typed text into a value of its own; null takes only [options].
  final T? Function(String text)? onCreate;

  /// The most values it takes.
  final int? maxTags;

  /// The placeholder, while nothing is typed.
  final String? hint;

  /// The help line under the well.
  final String? helper;

  /// What is wrong, in place of the help line.
  final String? error;

  /// The field's focus.
  final FocusNode? focusNode;

  /// The tallest the list stands before it scrolls.
  final double maxListHeight;

  @override
  State<FrostedMultiSelect<T>> createState() => _FrostedMultiSelectState<T>();
}

class _FrostedMultiSelectState<T extends Object>
    extends State<FrostedMultiSelect<T>> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(FrostedMultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _own)?.removeListener(_changed);
      _focus.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final error = widget.error;
    final helper = widget.helper;
    // A select's measure: its column on a phone, at most 320 from 600 up.
    return FrostedControlMeasure(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.fieldLabelGap,
        children: [
          FrostedFieldLabel(widget.label),
          DesignTagInput<T>(
            values: widget.values,
            onChanged: widget.onChanged,
            options: widget.options,
            search: widget.search,
            displayStringForOption: widget.displayString,
            onCreate: widget.onCreate,
            maxTags: widget.maxTags,
            focusNode: _focus,
            optionsMaxHeight: widget.maxListHeight,
            semanticLabel: widget.label,
            deleteLabel: words.remove,
            fieldBuilder: (context, field) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: FrostedBareField(
                controller: field.controller,
                focusNode: field.focusNode,
                autofocus: widget.autofocus,
                label: widget.label,
                hint: widget.values.isEmpty ? widget.hint : null,
                onSubmitted: (_) => field.submit(),
              ),
            ),
            layoutBuilder: (context, tags, field) => ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FrostedChromeMetrics.field,
              ),
              child: FrostedWell(
                focused: _focus.hasFocus,
                error: error != null,
                padding: const EdgeInsets.symmetric(
                  horizontal: FrostedSpacing.s10,
                  vertical: FrostedSpacing.s8,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wrap(
                    spacing: FrostedSpacing.s6,
                    runSpacing: FrostedSpacing.s6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [...tags, field],
                  ),
                ),
              ),
            ),
            tagBuilder: (context, value, tag) {
              final name = widget.displayString(value);
              final type = t.textTheme.labelLarge;
              final chip = FrostedFace(
                material: FrostedMaterial.paint,
                radius: BorderRadius.circular(FrostedCorners.r10),
                color: tag.focused
                    ? t.colorScheme.accentSubtle
                    : t.glass.fillHigh,
                ring: tag.focused ? t.colorScheme.accent : t.glass.edge,
                padding: const EdgeInsetsDirectional.only(
                  start: FrostedSpacing.s10,
                ).resolve(Directionality.of(context)),
                // Large text grows the tag by its words' extra line: held
                // to its 28 remover, at 200% the words stood out of the
                // glass above and below (self-review round 5).
                child: SizedBox(
                  height: frostedGrownHeight(context, 28, type),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: type.c(t.colorScheme.textPrimary)),
                      FrostedPressable(
                        onPressed: tag.onDeleted,
                        label: '${words.remove} $name',
                        radius: FrostedCorners.r10,
                        builder: (context, states, _) => SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(
                            FrostedGlyphs.close,
                            size: 14,
                            color: states.contains(WidgetState.hovered)
                                ? t.colorScheme.textPrimary
                                : t.colorScheme.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              return chip;
            },
            optionBuilder: (context, option, states) => FrostedPanelRow(
              label: widget.displayString(option),
              states: states,
            ),
            surfaceBuilder: (context, list) => FrostedPanel(child: list),
          ),
          if (error != null)
            FrostedFieldHint(error, error: true)
          else if (helper != null)
            FrostedFieldHint(helper),
        ],
      ),
    );
  }
}
