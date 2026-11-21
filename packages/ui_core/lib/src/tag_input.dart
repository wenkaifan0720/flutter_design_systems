/// A multi-select tag input, headless: chosen values as tags beside a text
/// field that suggests more as you type (the combobox's keys: arrows that
/// wrap, pass over a disabled suggestion and open a closed list without
/// moving, Enter, Escape), free text made into a tag on Enter or a separator (a pasted
/// "a, b, c" makes three), Backspace on an empty field and Left at its start
/// to step onto the tags, Backspace or Delete on a tag to remove it.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'combobox.dart';
import 'internal/list_side.dart';
import 'internal/option_list.dart';
import 'localizations.dart';

/// One tag, as [RawTagInput.tagBuilder] gets it.
@immutable
class RawTagDetails {
  /// A tag; the input makes these.
  const RawTagDetails({
    required this.focused,
    required this.onDeleted,
    required this.index,
  });

  /// Whether the keyboard is on it (draw its focus ring).
  final bool focused;

  /// Removes it: for its remove control.
  final VoidCallback onDeleted;

  /// Its place among the tags.
  final int index;
}

/// Paints one tag.
typedef RawTagBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  RawTagDetails tag,
);

/// Lays out the tags and the field (a wrap, by default).
typedef RawTagLayoutBuilder = Widget Function(
  BuildContext context,
  List<Widget> tags,
  Widget field,
);

/// Values chosen as tags, with a field that suggests and makes more.
///
/// It holds no list of its own: [values] in, [onChanged] out. The look
/// paints each tag ([tagBuilder]), the field ([fieldBuilder]), each
/// suggestion ([optionBuilder]) and the layout ([layoutBuilder]). The
/// suggestions open from the whole layout (the face round the tags and the
/// field, when the layout draws one), as wide as it and on its leading
/// edge, not from the field after the tags.
///
/// ```dart
/// RawTagInput<String>(values: const ['red'], onChanged: (values) {}, onCreate: (text) => text, fieldBuilder: (context, field) => EditableText(controller: field.controller, focusNode: field.focusNode, style: const TextStyle(), cursorColor: const Color(0xFF000000), backgroundCursorColor: const Color(0xFF808080), onEditingComplete: field.submit), optionBuilder: (context, option, states) => Text(option), tagBuilder: (context, value, tag) => Text(value))
/// ```
class RawTagInput<T extends Object> extends StatefulWidget {
  /// A tag input over [values].
  const RawTagInput({
    super.key,
    required this.values,
    required this.onChanged,
    required this.fieldBuilder,
    required this.optionBuilder,
    required this.tagBuilder,
    this.options = const [],
    this.search,
    this.isOptionEnabled,
    this.highlightFollowsPointer = false,
    this.displayStringForOption = _string,
    this.onCreate,
    this.layoutBuilder,
    this.surfaceBuilder,
    this.maxTags,
    this.separators = const [','],
    this.controller,
    this.focusNode,
    this.optionsMaxHeight = 300,
    this.semanticLabel,
    this.deleteLabel,
    this.debounceDuration,
    this.loadingBuilder,
    this.errorBuilder,
  }) : assert(maxTags == null || maxTags > 0),
       assert(optionsMaxHeight > 0);

  /// The chosen values, in order.
  final List<T> values;

  /// Called with the new list when a tag is added or removed.
  final ValueChanged<List<T>> onChanged;

  /// Paints the field.
  final DesignComboboxFieldBuilder fieldBuilder;

  /// Paints one suggestion.
  final RawOptionBuilder<T> optionBuilder;

  /// Paints one tag.
  final RawTagBuilder<T> tagBuilder;

  /// What typing suggests (less what is chosen), when there is no
  /// [search].
  final Iterable<T> options;

  /// Finds suggestions for a query, in place of filtering [options].
  final DesignOptionSearch<T>? search;

  /// Whether a suggestion can be taken; null: all can. A disabled one shows
  /// [WidgetState.disabled]; the highlight passes over it, and neither a tap
  /// nor Enter takes it.
  final bool Function(T option)? isOptionEnabled;

  /// Whether the pointer moves the suggestions' highlight, as
  /// [RawCombobox.highlightFollowsPointer]; off: two places, the
  /// pointer's [WidgetState.hovered] and the keys' [WidgetState.focused].
  final bool highlightFollowsPointer;

  /// A value's text.
  final String Function(T value) displayStringForOption;

  /// Makes a value of free text, or null to refuse it; null for no free
  /// text (only suggestions are taken).
  final T? Function(String text)? onCreate;

  /// Lays out the tags and the field (a face round both, when the look
  /// draws one); the suggestions open from what it lays out.
  final RawTagLayoutBuilder? layoutBuilder;

  /// Paints the suggestion list's surface.
  final RawOptionsSurfaceBuilder? surfaceBuilder;

  /// The most tags it takes; null for no limit.
  final int? maxTags;

  /// Text that ends a tag as it is typed or pasted.
  final List<String> separators;

  /// The field's text, when the caller holds it. The caller disposes it;
  /// null: the tag input makes its own and disposes it.
  final TextEditingController? controller;

  /// The field's focus, when the caller holds it. The caller disposes it;
  /// null: the tag input makes its own and disposes it.
  final FocusNode? focusNode;

  /// The suggestion list's greatest height.
  final double optionsMaxHeight;

  /// What a screen reader calls the suggestions.
  final String? semanticLabel;

  /// The screen reader's action that removes a tag; null:
  /// [RawWidgetsLocalizations.tagInputDeleteLabel].
  final String? deleteLabel;

  /// How long typing rests before [search] runs: a search per pause, not
  /// per letter. Null (the default) runs it at every change. Filtering
  /// [options] never waits.
  final Duration? debounceDuration;

  /// Says that [search] is finding options, in the list's surface, while its
  /// future is pending (and while [debounceDuration] runs); a screen reader
  /// hears [RawWidgetsLocalizations.loadingLabel] as it appears. Null (the
  /// default): the options found last stay until the new ones come.
  final WidgetBuilder? loadingBuilder;

  /// Says that [search] failed, in the list's surface, with a way to try
  /// again ([RawSearchError.retry]; Down moves the keys there, Enter
  /// runs it); a screen reader hears
  /// [RawWidgetsLocalizations.searchFailedMessage] as it appears, and the focus
  /// stays in the field. Null (the default): the list closes and the error
  /// goes to [FlutterError.reportError].
  final RawSearchErrorBuilder? errorBuilder;

  @override
  State<RawTagInput<T>> createState() => _DesignTagInputState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<List<T>>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<DesignComboboxFieldBuilder>.has(
          'fieldBuilder',
          fieldBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawOptionBuilder<T>>.has(
          'optionBuilder',
          optionBuilder,
        ),
      )
      ..add(ObjectFlagProperty<RawTagBuilder<T>>.has('tagBuilder', tagBuilder))
      ..add(
        IterableProperty<T>('options', options, defaultValue: const <Never>[]),
      )
      ..add(ObjectFlagProperty<DesignOptionSearch<T>>.has('search', search))
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
        ObjectFlagProperty<String Function(T value)>.has(
          'displayStringForOption',
          displayStringForOption,
        ),
      )
      ..add(
        ObjectFlagProperty<T? Function(String text)>.has('onCreate', onCreate),
      )
      ..add(
        ObjectFlagProperty<RawTagLayoutBuilder>.has(
          'layoutBuilder',
          layoutBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawOptionsSurfaceBuilder>.has(
          'surfaceBuilder',
          surfaceBuilder,
        ),
      )
      ..add(IntProperty('maxTags', maxTags, defaultValue: null))
      ..add(
        IterableProperty<String>(
          'separators',
          separators,
          defaultValue: const [','],
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
        DoubleProperty('optionsMaxHeight', optionsMaxHeight, defaultValue: 300),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(StringProperty('deleteLabel', deleteLabel, defaultValue: null))
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
        ObjectFlagProperty<RawSearchErrorBuilder>.has(
          'errorBuilder',
          errorBuilder,
        ),
      );
  }
}

String _string(Object value) => value.toString();

/// Stands in the suggestions while a search's states show (loading, failed,
/// found): the list stays open and paints them itself.
class _Searching {
  const _Searching();
}

const Object _searching = _Searching();

class _DesignTagInputState<T extends Object> extends State<RawTagInput<T>> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  final List<FocusNode> _tagNodes = [];
  final DesignListKeys _keys = DesignListKeys();
  int? _focusedTag;
  bool _picked = false;
  // The search's states, when the list shows them.
  final DesignSearchRun<T> _run = DesignSearchRun<T>();
  // Whether the suggestions open above, below having too little room for
  // them (DesignListSide).
  bool _above = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _field =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'RawTagInput'));

  bool get _full =>
      widget.maxTags != null && widget.values.length >= widget.maxTags!;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_textChanged);
    _syncNodes();
  }

  @override
  void didUpdateWidget(RawTagInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_textChanged);
      _controller.addListener(_textChanged);
    }
    _syncNodes();
  }

  @override
  void dispose() {
    _controller.removeListener(_textChanged);
    _run.dispose();
    for (final node in _tagNodes) {
      node.dispose();
    }
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _syncNodes() {
    while (_tagNodes.length < widget.values.length) {
      _tagNodes.add(FocusNode(debugLabel: 'RawTagDetails ${_tagNodes.length}'));
    }
    while (_tagNodes.length > widget.values.length) {
      _tagNodes.removeLast().dispose();
    }
  }

  void _emit(List<T> next) => widget.onChanged(List.unmodifiable(next));

  bool _has(T value) => widget.values.contains(value);

  void _add(T value) {
    if (_has(value) || _full) return;
    _emit([...widget.values, value]);
  }

  void _remove(int index) {
    if (index < 0 || index >= widget.values.length) return;
    final hadFocus = _tagNodes[index].hasFocus;
    _emit([...widget.values]..removeAt(index));
    if (hadFocus) {
      // The tag before it, or the field when it was the first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (index > 0 && index - 1 < _tagNodes.length) {
          _tagNodes[index - 1].requestFocus();
        } else {
          _field.requestFocus();
        }
      });
    }
  }

  /// A value of [text]: a suggestion it names exactly, else [onCreate]'s;
  /// null for a disabled suggestion, named or made, so neither a separator,
  /// a paste nor Enter adds one.
  T? _valueOf(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    for (final option in widget.options) {
      if (widget.displayStringForOption(option).toLowerCase() ==
          t.toLowerCase()) {
        return _enabled(option) ? option : null;
      }
    }
    final made = widget.onCreate?.call(t);
    return made != null && widget.options.contains(made) && !_enabled(made)
        ? null
        : made;
  }

  void _textChanged() {
    final text = _controller.text;
    final separator = widget.separators.where(text.contains);
    if (separator.isEmpty ||
        (widget.onCreate == null && widget.options.isEmpty)) {
      return;
    }
    var parts = [text];
    for (final s in widget.separators) {
      parts = [for (final p in parts) ...p.split(s)];
    }
    // The text after the last separator is still being typed.
    final rest = parts.removeLast();
    final added = <T>[];
    for (final part in parts) {
      final value = _valueOf(part);
      if (value != null && !_has(value) && !added.contains(value)) {
        added.add(value);
      }
    }
    final room = widget.maxTags == null
        ? added.length
        : (widget.maxTags! - widget.values.length).clamp(0, added.length);
    if (room > 0) _emit([...widget.values, ...added.take(room)]);
    _controller.value = TextEditingValue(
      text: rest.trimLeft(),
      selection: TextSelection.collapsed(offset: rest.trimLeft().length),
    );
  }

  void _submit(VoidCallback pick) {
    _picked = false;
    final retries = _run.retries;
    if (!_keys.submit()) pick();
    // An option taken, or a failed search run again: no tag from the words.
    if (_picked || _run.retries != retries) return;
    final value = _valueOf(_controller.text);
    if (value != null && !_has(value) && !_full) {
      _add(value);
      _controller.clear();
    }
  }

  void _focusTag(int index) {
    if (index < 0 || index >= _tagNodes.length) return;
    _tagNodes[index].requestFocus();
  }

  KeyEventResult _fieldKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final selection = _controller.selection;
    final atStart =
        selection.isCollapsed && selection.baseOffset <= 0 ||
        _controller.text.isEmpty;
    if (!atStart || widget.values.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == LogicalKeyboardKey.backspace && _controller.text.isEmpty ||
        key == back) {
      _focusTag(widget.values.length - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _tagKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final before = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final after = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _remove(index);
      return KeyEventResult.handled;
    }
    if (key == before) {
      if (index > 0) _focusTag(index - 1);
      return KeyEventResult.handled;
    }
    if (key == after || key == LogicalKeyboardKey.escape) {
      if (key == after && index < widget.values.length - 1) {
        _focusTag(index + 1);
      } else {
        _field.requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _tag(BuildContext context, int index) {
    final value = widget.values[index];
    return Focus(
      key: ValueKey<Object>(value),
      focusNode: _tagNodes[index],
      skipTraversal: true,
      onFocusChange: (focused) => setState(
        () => _focusedTag = focused
            ? index
            : (_focusedTag == index ? null : _focusedTag),
      ),
      onKeyEvent: (node, event) => _tagKey(index, event),
      child: Semantics(
        container: true,
        customSemanticsActions: {
          CustomSemanticsAction(
            label:
                widget.deleteLabel ??
                RawWidgetsLocalizations.of(context).tagInputDeleteLabel,
          ): () =>
              _remove(index),
        },
        child: widget.tagBuilder(
          context,
          value,
          RawTagDetails(
            focused: _focusedTag == index,
            onDeleted: () => _remove(index),
            index: index,
          ),
        ),
      ),
    );
  }

  // Whether the list shows the search's states itself: loading or failed.
  bool get _live =>
      widget.search != null &&
      (widget.loadingBuilder != null || widget.errorBuilder != null);

  FutureOr<Iterable<Object>> _find(TextEditingValue value) {
    if (_full) return const [];
    final search = widget.search;
    if (search == null) {
      final query = value.text.trim().toLowerCase();
      final found = query.isEmpty
          ? widget.options
          : widget.options.where(
              (o) => widget
                  .displayStringForOption(o)
                  .toLowerCase()
                  .contains(query),
            );
      return found.where((o) => !_has(o));
    }
    final debounce = widget.debounceDuration;
    if (_live) {
      // A failure the list cannot show is reported.
      unawaited(
        _run.run(
          value.text,
          search,
          debounce: debounce,
          report: widget.errorBuilder == null,
        ),
      );
      return const [_searching];
    }
    return _run
        .run(value.text, search, debounce: debounce, report: true)
        .then((found) => (found ?? const []).where((o) => !_has(o)));
  }

  bool _enabled(T option) => widget.isOptionEnabled?.call(option) ?? true;

  @override
  Widget build(BuildContext context) {
    final field = RawAutocomplete<Object>(
      // Below the tags and the field, as a combobox's list, unless only
      // above has room for them.
      optionsViewOpenDirection: designListDirection(
        OptionsViewOpenDirection.down,
        flipped: _above,
      ),
      textEditingController: _controller,
      focusNode: _field,
      optionsBuilder: _find,
      displayStringForOption: (option) => identical(option, _searching)
          ? _controller.text
          : widget.displayStringForOption(
              (option is DesignPick ? option.option : option) as T,
            ),
      onSelected: (picked) {
        if (identical(picked, _searching)) return;
        final option = (picked is DesignPick ? picked.option : picked) as T;
        if (!_enabled(option)) return;
        _picked = true;
        _add(option);
        // After the autocomplete has set the text to the option's: clear it,
        // so the field is ready for the next tag and suggestions return.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.clear();
        });
      },
      // The tags and the field together, so the suggestions open from the
      // whole of it.
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        final field = Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: _fieldKey,
          // ui_core's keys over the autocomplete's, as RawCombobox's.
          child: _keys.field(
            controller,
            widget.fieldBuilder(
              context,
              DesignComboboxField(
                controller: controller,
                focusNode: focusNode,
                submit: () => _submit(onSubmitted),
              ),
            ),
          ),
        );
        final tags = [
          for (var i = 0; i < widget.values.length; i++) _tag(context, i),
        ];
        // Explicit child nodes, as RawCombobox's: the OverlayPortal's
        // annotation would otherwise stretch the field's node over the tags.
        return Semantics(
          explicitChildNodes: true,
          child:
              widget.layoutBuilder?.call(context, tags, field) ??
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [...tags, field],
              ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => DesignListSide(
        field: this.context,
        asked: OptionsViewOpenDirection.down,
        opensUp: _above,
        onFlip: (above) {
          if (mounted && above != _above) setState(() => _above = above);
        },
        child: options.length == 1 && identical(options.single, _searching)
            ? DesignSearchScope(
                run: _run,
                child: ListenableBuilder(
                  listenable: _run,
                  builder: (context, _) => _searchView(context, onSelected),
                ),
              )
            : _list(options.cast<T>().toList(), onSelected),
      ),
    );
    return field;
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
    final shown = error != null && !pending
        ? <T>[]
        : _run.found.where((o) => !_has(o)).toList();
    if (shown.isEmpty || _full) {
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
    return _list(shown, onSelected);
  }

  Widget _list(List<T> shown, AutocompleteOnSelected<Object> onSelected) {
    return DesignOptionList<T>(
      keys: _keys,
      options: shown,
      start: shown.indexWhere(_enabled),
      onSelected: (option) {
        if (!_enabled(option)) return;
        _keys.closed();
        onSelected(DesignPick(option));
      },
      value: null,
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
