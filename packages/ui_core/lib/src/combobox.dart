/// A combobox, headless: a text field whose typing filters a list of
/// options below (or above) it. Up and Down move a highlight through the
/// options (Page Up and Down, and Ctrl or Cmd with an arrow, jump), Enter
/// takes the highlighted one, Escape hides the list, a tap takes an option.
/// The highlight scrolls into view and a screen reader hears it, and hears
/// whether the typing found anything. Built on the widgets layer's
/// [RawAutocomplete].
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'internal/option_list.dart';

/// The field, as [DesignCombobox.fieldBuilder] gets it: wire [controller]
/// and [focusNode] to the look's text input, and [submit] to its
/// `onSubmitted`.
@immutable
class DesignComboboxField {
  /// The field's wiring.
  const DesignComboboxField({
    required this.controller,
    required this.focusNode,
    required this.submit,
  });

  /// The text the field edits: the caller's when it gave one, else the
  /// combobox's own. The field never disposes it.
  final TextEditingController controller;

  /// The field's focus, owned as [controller] is.
  final FocusNode focusNode;

  /// Takes the highlighted option: call it from the input's `onSubmitted`.
  final VoidCallback submit;
}

/// Paints the field.
typedef DesignComboboxFieldBuilder = Widget Function(
  BuildContext context,
  DesignComboboxField field,
);

/// Paints one option for its [states]: [WidgetState.focused] while it is
/// highlighted (the keyboard's place in the list), [WidgetState.selected]
/// when it is the combobox's value, and a pointer's hovered and pressed.
typedef DesignOptionBuilder<T> = Widget Function(
  BuildContext context,
  T option,
  Set<WidgetState> states,
);

/// Paints the list's surface around [list] (a panel, its shadow).
typedef DesignListSurfaceBuilder = Widget Function(
  BuildContext context,
  Widget list,
);

/// Searches for the options matching [query].
typedef DesignOptionSearch<T> = FutureOr<Iterable<T>> Function(String query);

String _string(Object option) => option.toString();

/// Stands in the options while nothing matches, so the list stays open to say so.
class _NoMatch {
  const _NoMatch();
}

const Object _noMatch = _NoMatch();

/// A text field that suggests options as you type.
///
/// Give it [options] to filter (case-insensitively, by
/// [displayStringForOption]) or
/// a [search] that finds them. The look paints the field ([fieldBuilder]),
/// each option ([optionBuilder]) and the list's surface
/// ([surfaceBuilder]); the combobox moves the highlight, scrolls it into
/// view, takes a choice, and announces.
///
/// ```dart
/// DesignCombobox<String>(options: const ['Apple', 'Pear'], fieldBuilder: (context, field) => EditableText(controller: field.controller, focusNode: field.focusNode, style: const TextStyle(), cursorColor: const Color(0xFF000000), backgroundCursorColor: const Color(0xFF808080), onSubmitted: (_) => field.submit()), optionBuilder: (context, option, states) => Text(option))
/// ```
class DesignCombobox<T extends Object> extends StatefulWidget {
  /// A combobox over [options] or [search].
  const DesignCombobox({
    super.key,
    required this.fieldBuilder,
    required this.optionBuilder,
    this.options = const [],
    this.search,
    this.displayStringForOption = _string,
    this.surfaceBuilder,
    this.onSelected,
    this.value,
    this.requireSelection = false,
    this.controller,
    this.focusNode,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.down,
    this.optionsMaxHeight = 300,
    this.semanticLabel,
    this.emptyBuilder,
  });

  /// Paints the field.
  final DesignComboboxFieldBuilder fieldBuilder;

  /// Paints one option.
  final DesignOptionBuilder<T> optionBuilder;

  /// The options typing filters, when there is no [search].
  final Iterable<T> options;

  /// Finds the options for a query, in place of filtering [options].
  final DesignOptionSearch<T>? search;

  /// An option's text: what the filter matches and the field shows once it
  /// is taken.
  final String Function(T option) displayStringForOption;

  /// Paints the list's surface; null shows the bare list.
  final DesignListSurfaceBuilder? surfaceBuilder;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// The option taken, shown as [WidgetState.selected] and, when the field
  /// is not being edited, as its text.
  final T? value;

  /// Whether leaving the field puts back [value]'s text (empty with no
  /// value), so the field never holds text that is not an option: a
  /// searchable select.
  final bool requireSelection;

  /// The field's text, when the caller holds it. The caller disposes it;
  /// null: the combobox makes its own and disposes it.
  final TextEditingController? controller;

  /// The field's focus, when the caller holds it. The caller disposes it;
  /// null: the combobox makes its own and disposes it.
  final FocusNode? focusNode;

  /// Whether the list opens below the field (the default) or above it.
  final OptionsViewOpenDirection optionsViewOpenDirection;

  /// The list's greatest height; past it, it scrolls.
  final double optionsMaxHeight;

  /// What a screen reader calls the list.
  final String? semanticLabel;

  /// Says that nothing matches, in the list's surface, while the field holds
  /// text no option fits. Null: the list just closes.
  final WidgetBuilder? emptyBuilder;

  @override
  State<DesignCombobox<T>> createState() => _DesignComboboxState<T>();
}

class _DesignComboboxState<T extends Object> extends State<DesignCombobox<T>> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'DesignCombobox'));

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
    final value = widget.value;
    if (value != null) _controller.text = widget.displayStringForOption(value);
  }

  @override
  void didUpdateWidget(DesignCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_focusChanged);
      _focus.addListener(_focusChanged);
    }
    final value = widget.value;
    if (value != oldWidget.value && !_focus.hasFocus) {
      _controller.text = value == null
          ? ''
          : widget.displayStringForOption(value);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (_focus.hasFocus || !widget.requireSelection) return;
    final value = widget.value;
    final text = value == null ? '' : widget.displayStringForOption(value);
    if (_controller.text != text) _controller.text = text;
  }

  FutureOr<Iterable<T>> _find(TextEditingValue value) {
    final search = widget.search;
    if (search != null) return search(value.text);
    final query = value.text.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options.where(
      (o) => widget.displayStringForOption(o).toLowerCase().contains(query),
    );
  }

  FutureOr<Iterable<Object>> _matches(TextEditingValue value) {
    Iterable<Object> orNoMatch(Iterable<T> found) =>
        found.isEmpty &&
            widget.emptyBuilder != null &&
            value.text.trim().isNotEmpty
        ? const [_noMatch]
        : found;
    final found = _find(value);
    return found is Future<Iterable<T>>
        ? found.then(orNoMatch)
        : orNoMatch(found);
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Object>(
      textEditingController: _controller,
      focusNode: _focus,
      optionsBuilder: _matches,
      // Enter on "no matches" leaves the words as they are and takes nothing.
      displayStringForOption: (option) => identical(option, _noMatch)
          ? _controller.text
          : widget.displayStringForOption(option as T),
      optionsViewOpenDirection: widget.optionsViewOpenDirection,
      onSelected: (option) {
        if (!identical(option, _noMatch)) widget.onSelected?.call(option as T);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          widget.fieldBuilder(
            context,
            DesignComboboxField(
              controller: controller,
              focusNode: focusNode,
              submit: onSubmitted,
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) {
        if (options.length == 1 && identical(options.single, _noMatch)) {
          final said = Semantics(
            container: true,
            liveRegion: true,
            child: widget.emptyBuilder!(context),
          );
          return widget.surfaceBuilder?.call(context, said) ?? said;
        }
        return DesignOptionList<T>(
          options: options.cast<T>().toList(),
          onSelected: onSelected,
          value: widget.value,
          displayStringForOption: widget.displayStringForOption,
          optionBuilder: widget.optionBuilder,
          surfaceBuilder: widget.surfaceBuilder,
          maxHeight: widget.optionsMaxHeight,
          semanticLabel: widget.semanticLabel,
        );
      },
    );
  }
}
