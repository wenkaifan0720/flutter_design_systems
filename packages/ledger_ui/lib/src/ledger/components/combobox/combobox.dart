/// A field that suggests as it is typed in, in Ledger's hand, over ui_core's
/// [DesignCombobox].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/option_paper.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// A payee, a category or a shop typed in and taken from what it suggests:
/// a Ledger field on its rule, the chevron at its end, and under it, as
/// soon as it has focus, the matching [options] on the select's raised
/// paper, 48 a line, a hairline between, the [value] on the menu's paper,
/// its words semibold and ticked in the accent. A pointer underlines a
/// line's words and the keyboard's line doubles the rule under them, on
/// that line alone. Up and down walk the list, Enter takes the line,
/// Escape closes it; with nothing matching the paper says so. [labelOf]
/// words each option (its `toString` otherwise) and [noteOf] puts a note
/// at its end (a count, a balance). [requireSelection] holds the field to
/// an option, giving back the chosen words on blur. With a [search] in
/// place of [options] (a payee looked up as it is typed), the paper says
/// it is looking while the search runs, and when it fails says so with a
/// "Try again" line the keys reach with Down, as ui_core's combobox runs
/// it; [debounceDuration] waits for the typing to rest.
///
/// ```dart
/// LedgerCombobox<String>(label: 'Payee', options: const ['Blue Fern Café', 'Corner Market'], onSelected: (v) {})
/// ```
class LedgerCombobox<T extends Object> extends StatelessWidget {
  /// A field named [label] suggesting from [options].
  const LedgerCombobox({
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.value,
    this.labelOf,
    this.noteOf,
    this.onSelected,
    this.requireSelection = false,
    this.controller,
    this.focusNode,
    this.enabled = true,
    super.key,
  });

  /// What it suggests from, when there is no [search].
  final Iterable<T> options;

  /// Finds the options for the words typed, in place of filtering
  /// [options]; it may take time and fail.
  final DesignOptionSearch<T>? search;

  /// How long typing rests before [search] runs; null: at every change.
  final Duration? debounceDuration;

  /// The small capitals over the line.
  final String? label;

  /// Words in the third ink while it is empty.
  final String? hint;

  /// The note under the rule.
  final String? helper;

  /// What is wrong, in the vermilion; it replaces [helper].
  final String? error;

  /// The option taken, ticked on the paper.
  final T? value;

  /// Each option's words; null: its `toString`.
  final String Function(T option)? labelOf;

  /// A note at an option's end, in the mono; null: none.
  final String? Function(T option)? noteOf;

  /// Called with an option when one is taken.
  final ValueChanged<T>? onSelected;

  /// Whether the words must be an option's.
  final bool requireSelection;

  /// Its words; null: its own.
  final TextEditingController? controller;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// Whether it takes words.
  final bool enabled;

  String _words(T option) => labelOf?.call(option) ?? option.toString();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('labelOf', labelOf));
    properties.add(ObjectFlagProperty<Object?>.has('noteOf', noteOf));
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(ObjectFlagProperty<DesignOptionSearch<T>>.has('search', search))
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(
        FlagProperty(
          'requireSelection',
          value: requireSelection,
          ifTrue: 'requireSelection',
        ),
      )
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
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return DesignCombobox<T>(
      options: options,
      search: search,
      debounceDuration: debounceDuration,
      // The pointer's mark (an underline) and the keyboard's (the double
      // rule) differ on purpose, and only the chosen option stands on the
      // menu's paper, ticked: a pointer leaves the keyboard's place alone.
      highlightFollowsPointer: false,
      value: value,
      displayStringForOption: _words,
      onSelected: onSelected,
      requireSelection: requireSelection,
      controller: controller,
      focusNode: focusNode,
      semanticLabel: label,
      optionsMaxHeight: _paper,
      fieldBuilder: (context, field) => LedgerTextField(
        controller: field.controller,
        focusNode: field.focusNode,
        label: label,
        hint: hint,
        helper: helper,
        error: error,
        enabled: enabled,
        // Enter takes the lit option and the field keeps the focus: in
        // onEditingComplete, never onSubmitted, whose submit restarts the text input of a field that
        // keeps the focus (a browser's then takes no typing).
        onEditingComplete: field.submit,
        trailing: ExcludeSemantics(
          child: Icon(
            LucideIcons.chevronsUpDown,
            size: _glyph,
            color: enabled ? t.textSecondary : t.textTertiary,
          ),
        ),
      ),
      optionBuilder: (context, option, states) => LedgerOptionRow(
        label: _words(option),
        note: noteOf?.call(option),
        states: states,
      ),
      surfaceBuilder: ledgerOptionPaper,
      // "No results" on the same paper at the field's width, as its options
      // stand: a slip as wide as its words read as a different list.
      emptyBuilder: (context) => SizedBox(
        width: double.infinity,
        child: LedgerNoOption(DesignLocalizations.of(context).noResultsLabel),
      ),
      // Looking, and a failed look, on the same paper at the same width.
      loadingBuilder: (context) => SizedBox(
        width: double.infinity,
        child: LedgerNoOption(DesignLocalizations.of(context).loadingLabel),
      ),
      errorBuilder: (context, failed) {
        final words = DesignLocalizations.of(context);
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: LedgerNoOption(words.searchFailedMessage),
              ),
              // "Try again" stands as an option: lit as the keys' line
              // while they are on it, underlined under the pointer.
              DesignPressable(
                onPressed: failed.retry,
                semanticLabel: words.retryButtonLabel,
                builder: (context, states, _) => LedgerOptionRow(
                  label: words.retryButtonLabel,
                  states: {
                    ...states.where((s) => s != WidgetState.focused),
                    if (failed.focused) WidgetState.focused,
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // The paper five lines tall at most; the chevron 18.
  static const double _paper = 5 * 48 + 8;
  static const double _glyph = 18;
}
