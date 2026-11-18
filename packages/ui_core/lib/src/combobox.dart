/// A combobox, headless: a text field whose typing filters a list of
/// options below (or above) it. Opened before the words are edited (by Down,
/// a press, focus), the list shows every option with the chosen one
/// highlighted; once the user edits the words, it shows those they match.
/// Up and Down move a highlight through the options and round past the ends
/// (Page Up and Down, and Ctrl or Cmd with an arrow, jump), passing over a
/// disabled one; on a closed list they open it without moving. Enter takes
/// the highlighted option, Escape hides the list, a tap takes an option;
/// Home, End and letters stay with the text. The highlight scrolls into view
/// and a screen reader hears it, and hears whether the typing found
/// anything. Built on the widgets layer's [RawAutocomplete].
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/option_list.dart';

/// The field, as [DesignCombobox.fieldBuilder] gets it: wire [controller]
/// and [focusNode] to the look's text input, and [submit] to its
/// `onEditingComplete` (and give it no `onSubmitted`; see [submit]).
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

  /// Takes the highlighted option (a tag input adds the words as a tag too,
  /// a command palette runs the highlighted command): the input's
  /// `onEditingComplete`, as `onEditingComplete: field.submit`, with no
  /// `onSubmitted`.
  ///
  /// The field keeps the focus after Enter that way, ready for the next
  /// words. With `onSubmitted`, Flutter restarts the text input's
  /// connection after Enter; on the web the restarted input never takes the
  /// browser's focus, and letters stop reaching a field that still looks
  /// focused.
  final VoidCallback submit;
}

/// Paints the field.
typedef DesignComboboxFieldBuilder = Widget Function(
  BuildContext context,
  DesignComboboxField field,
);

/// Paints one option for its [states]: [WidgetState.focused] while it is
/// highlighted (the keyboard's place in the list), [WidgetState.selected]
/// when it is the combobox's value, [WidgetState.disabled] when it cannot be
/// taken, and a pointer's hovered and pressed.
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

/// A search that failed, as a combobox's or a tag input's `errorBuilder`
/// gets it: paint a message and a "Try again"
/// ([DesignLocalizations.retryButtonLabel]) that calls [retry], lit while
/// [focused].
///
/// ```dart
/// DesignSearchError(error: StateError('offline'), retry: () {})
/// ```
@immutable
class DesignSearchError {
  /// A search that threw [error].
  const DesignSearchError({
    required this.error,
    this.stackTrace,
    required this.retry,
    this.focused = false,
  });

  /// What the search threw.
  final Object error;

  /// Where it threw, when known.
  final StackTrace? stackTrace;

  /// Runs the search again for the same words.
  final VoidCallback retry;

  /// Whether the keys are on "Try again" (Down from the field moves there,
  /// Enter then runs [retry]): paint it as a highlighted option.
  final bool focused;
}

/// Paints a failed search ([error]) in the list's surface.
typedef DesignSearchErrorBuilder = Widget Function(
  BuildContext context,
  DesignSearchError error,
);

String _string(Object option) => option.toString();

/// Stands in the options while nothing matches, so the list stays open to say so.
class _NoMatch {
  const _NoMatch();
}

const Object _noMatch = _NoMatch();

/// Stands in the options while a search's states show (loading, failed,
/// found): the list stays open and paints them itself.
class _Searching {
  const _Searching();
}

const Object _searching = _Searching();

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
/// DesignCombobox<String>(options: const ['Apple', 'Pear'], fieldBuilder: (context, field) => EditableText(controller: field.controller, focusNode: field.focusNode, style: const TextStyle(), cursorColor: const Color(0xFF000000), backgroundCursorColor: const Color(0xFF808080), onEditingComplete: field.submit), optionBuilder: (context, option, states) => Text(option))
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
    this.isOptionEnabled,
    this.highlightFollowsPointer = false,
    this.requireSelection = false,
    this.controller,
    this.focusNode,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.mostSpace,
    this.optionsMaxHeight = 300,
    this.semanticLabel,
    this.emptyBuilder,
    this.debounceDuration,
    this.loadingBuilder,
    this.errorBuilder,
  }) : assert(optionsMaxHeight > 0);

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
  /// is not being edited, as its text. A list opened while the field shows
  /// it lists every option, its highlight on this one.
  final T? value;

  /// Whether an option can be taken; null: all can. A disabled option shows
  /// [WidgetState.disabled]; the highlight passes over it, and neither a tap
  /// nor Enter takes it.
  final bool Function(T option)? isOptionEnabled;

  /// Whether the pointer moves the highlight. Off (the default), they are
  /// two places: the pointer's option shows [WidgetState.hovered] and the
  /// keys' [WidgetState.focused], for a look that paints them apart. On, a
  /// pointer moving over an option that can be taken highlights it (no
  /// option shows [WidgetState.hovered]), the keys go on from there, and the
  /// highlight stays where it is when the pointer leaves the list, as in a
  /// native menu.
  final bool highlightFollowsPointer;

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

  /// Where the list opens. By default it uses the side of the field with
  /// more available space, accounting for the on-screen keyboard.
  final OptionsViewOpenDirection optionsViewOpenDirection;

  /// The list's greatest height; past it, it scrolls.
  final double optionsMaxHeight;

  /// What a screen reader calls the list.
  final String? semanticLabel;

  /// Says that nothing matches, in the list's surface, while the field holds
  /// text no option fits. Null: the list just closes.
  final WidgetBuilder? emptyBuilder;

  /// How long typing rests before [search] runs: a search per pause, not
  /// per letter. Null (the default) runs it at every change. Filtering
  /// [options] never waits.
  final Duration? debounceDuration;

  /// Says that [search] is finding options, in the list's surface, while its
  /// future is pending (and while [debounceDuration] runs); a screen reader
  /// hears [DesignLocalizations.loadingLabel] as it appears. Null (the
  /// default): the options found last stay until the new ones come.
  final WidgetBuilder? loadingBuilder;

  /// Says that [search] failed, in the list's surface, with a way to try
  /// again ([DesignSearchError.retry]; Down moves the keys there, Enter
  /// runs it); a screen reader hears
  /// [DesignLocalizations.searchFailedMessage] as it appears, and the focus
  /// stays in the field. Null (the default): the list closes and the error
  /// goes to [FlutterError.reportError].
  final DesignSearchErrorBuilder? errorBuilder;

  @override
  State<DesignCombobox<T>> createState() => _DesignComboboxState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<DesignComboboxFieldBuilder>.has(
          'fieldBuilder',
          fieldBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<DesignOptionBuilder<T>>.has(
          'optionBuilder',
          optionBuilder,
        ),
      )
      ..add(
        IterableProperty<T>('options', options, defaultValue: const <Never>[]),
      )
      ..add(ObjectFlagProperty<DesignOptionSearch<T>>.has('search', search))
      ..add(
        ObjectFlagProperty<String Function(T option)>.has(
          'displayStringForOption',
          displayStringForOption,
        ),
      )
      ..add(
        ObjectFlagProperty<DesignListSurfaceBuilder>.has(
          'surfaceBuilder',
          surfaceBuilder,
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<bool Function(T option)>.has(
          'isOptionEnabled',
          isOptionEnabled,
        ),
      )
      ..add(
        FlagProperty(
          'highlightFollowsPointer',
          value: highlightFollowsPointer,
          ifTrue: 'highlightFollowsPointer',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'requireSelection',
          value: requireSelection,
          ifTrue: 'requireSelection',
          defaultValue: false,
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
      ..add(
        EnumProperty<OptionsViewOpenDirection>(
          'optionsViewOpenDirection',
          optionsViewOpenDirection,
          defaultValue: OptionsViewOpenDirection.mostSpace,
        ),
      )
      ..add(
        DoubleProperty('optionsMaxHeight', optionsMaxHeight, defaultValue: 300),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(ObjectFlagProperty<WidgetBuilder>.has('emptyBuilder', emptyBuilder))
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<WidgetBuilder>.has('loadingBuilder', loadingBuilder),
      )
      ..add(
        ObjectFlagProperty<DesignSearchErrorBuilder>.has(
          'errorBuilder',
          errorBuilder,
        ),
      );
  }
}

class _DesignComboboxState<T extends Object> extends State<DesignCombobox<T>> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  final DesignListKeys _keys = DesignListKeys();
  // The text of the option last taken from the list.
  String? _taken;
  // The query of the options the autocomplete was last asked for.
  String _query = '';
  // What a search finds for no query: every option, as it says.
  List<T>? _all;
  // The search's states, when the list shows them.
  final DesignSearchRun<T> _run = DesignSearchRun<T>();

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
    if (value != oldWidget.value) _taken = null;
    if (value != oldWidget.value && !_focus.hasFocus) {
      _controller.text = value == null
          ? ''
          : widget.displayStringForOption(value);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _run.dispose();
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

  // Whether the user has edited the words: they are neither the value's nor
  // the option last taken's own. Until then the list shows every option.
  bool get _edited {
    final text = _controller.text;
    final value = widget.value;
    return text.trim().isNotEmpty &&
        text != _taken &&
        (value == null || text != widget.displayStringForOption(value));
  }

  Iterable<T> _filter(String text) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options.where(
      (o) => widget.displayStringForOption(o).toLowerCase().contains(query),
    );
  }

  // Whether the list shows the search's states itself: loading or failed.
  bool get _live =>
      widget.search != null &&
      (widget.loadingBuilder != null || widget.errorBuilder != null);

  Iterable<Object> _orNoMatch(String query, Iterable<T> found) {
    if (query.isEmpty && widget.search != null) _all = found.toList();
    return found.isEmpty &&
            widget.emptyBuilder != null &&
            query.trim().isNotEmpty
        ? const [_noMatch]
        : found;
  }

  FutureOr<Iterable<Object>> _matches(TextEditingValue value) {
    final query = _edited ? value.text : '';
    _query = query;
    final search = widget.search;
    if (search == null) return _orNoMatch(query, _filter(query));
    final debounce = widget.debounceDuration;
    if (_live) {
      // A failure the list cannot show is reported.
      unawaited(
        _run.run(
          query,
          search,
          debounce: debounce,
          report: widget.errorBuilder == null,
        ),
      );
      return const [_searching];
    }
    return _run
        .run(query, search, debounce: debounce, report: true)
        .then((found) => _orNoMatch(query, found ?? const []));
  }

  // What the open list shows: every option until the words are edited (the
  // autocomplete keeps the matches of the words last edited, past a choice),
  // then the matches.
  List<T> _shown(Iterable<Object> matches) {
    final found = matches.cast<T>().toList();
    if (_edited || _query.trim().isEmpty) return found;
    return widget.search == null ? widget.options.toList() : (_all ?? found);
  }

  bool _enabled(T option) => widget.isOptionEnabled?.call(option) ?? true;

  // Where an opened list's highlight starts: on the value, while the words
  // are its own; else on the first option that can be taken.
  int _start(List<T> shown) {
    final value = widget.value;
    if (value != null && !_edited) {
      final i = shown.indexOf(value);
      if (i >= 0 && _enabled(shown[i])) return i;
    }
    return shown.indexWhere(_enabled);
  }

  void _take(T option, AutocompleteOnSelected<Object> select) {
    if (!_enabled(option)) return;
    _taken = widget.displayStringForOption(option);
    _keys.closed();
    select(DesignPick(option));
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Object>(
      textEditingController: _controller,
      focusNode: _focus,
      optionsBuilder: _matches,
      // Enter on "no matches" leaves the words as they are and takes nothing.
      displayStringForOption: (option) => switch (option) {
        DesignPick(:final option) => widget.displayStringForOption(option as T),
        _ when identical(option, _noMatch) || identical(option, _searching) =>
          _controller.text,
        _ => widget.displayStringForOption(option as T),
      },
      optionsViewOpenDirection: widget.optionsViewOpenDirection,
      onSelected: (option) {
        final taken = option is DesignPick ? option.option : option;
        if (!identical(taken, _noMatch) && !identical(taken, _searching)) {
          widget.onSelected?.call(taken as T);
        }
      },
      // The field's nodes as the look builds them: RawAutocomplete's
      // OverlayPortal annotates its child, and without explicit child nodes
      // the field's node would merge into that annotation and stretch over
      // the whole field view (its label and helper with it).
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          Semantics(
            explicitChildNodes: true,
            // ui_core's keys over the autocomplete's: they wrap, open a
            // closed list without moving, and pass over disabled options.
            child: _keys.field(
              controller,
              widget.fieldBuilder(
                context,
                DesignComboboxField(
                  controller: controller,
                  focusNode: focusNode,
                  submit: () {
                    if (!_keys.submit()) onSubmitted();
                  },
                ),
              ),
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) {
        if (options.length == 1 && identical(options.single, _searching)) {
          return DesignSearchScope(
            run: _run,
            child: ListenableBuilder(
              listenable: _run,
              builder: (context, _) => _searchView(context, onSelected),
            ),
          );
        }
        return _list(context, onSelected, options);
      },
    );
  }

  // A search's states, as the list shows them.
  Widget _searchView(
    BuildContext context,
    AutocompleteOnSelected<Object> onSelected,
  ) {
    // A search the list's closing dropped runs again as it opens: pending.
    final pending = _run.loading || _run.dropped;
    final loading = widget.loadingBuilder;
    if (pending && loading != null) {
      return designSearchLoading(context, loading, widget.surfaceBuilder);
    }
    final error = _run.error;
    final failed = widget.errorBuilder;
    if (error != null && failed != null && !pending) {
      return DesignSearchFailure(
        keys: _keys,
        error: error,
        stackTrace: _run.stackTrace,
        retry: _run.retry,
        builder: failed,
        surfaceBuilder: widget.surfaceBuilder,
      );
    }
    final options = error != null && !pending
        ? const <Object>[]
        : _orNoMatch(_run.query, _run.found).toList();
    if (options.isEmpty) {
      // Nothing to show: the list closes, after this frame (a failure with
      // no errorBuilder was reported).
      if (!pending) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Unless a search started since.
          if (context.mounted && !_run.loading && !_run.dropped) {
            _keys.hide();
          }
        });
      }
      return const SizedBox.shrink();
    }
    return _list(context, onSelected, options);
  }

  // The list of [options] (or the words that none match).
  Widget _list(
    BuildContext context,
    AutocompleteOnSelected<Object> onSelected,
    Iterable<Object> options,
  ) {
    if (options.length == 1 && identical(options.single, _noMatch)) {
      final said = Semantics(
        container: true,
        liveRegion: true,
        child: widget.emptyBuilder!(context),
      );
      return widget.surfaceBuilder?.call(context, said) ?? said;
    }
    final shown = _shown(options);
    return DesignOptionList<T>(
      keys: _keys,
      options: shown,
      start: _start(shown),
      onSelected: (option) => _take(option, onSelected),
      value: widget.value,
      isOptionEnabled: widget.isOptionEnabled,
      highlightFollowsPointer: widget.highlightFollowsPointer,
      displayStringForOption: widget.displayStringForOption,
      optionBuilder: widget.optionBuilder,
      surfaceBuilder: widget.surfaceBuilder,
      maxHeight: widget.optionsMaxHeight,
      semanticLabel: widget.semanticLabel,
    );
  }
}
