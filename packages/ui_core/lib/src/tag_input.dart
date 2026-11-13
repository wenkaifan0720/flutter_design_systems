/// A multi-select tag input, headless: chosen values as tags beside a text
/// field that suggests more as you type (the combobox's keys: arrows, Enter,
/// Escape), free text made into a tag on Enter or a separator (a pasted
/// "a, b, c" makes three), Backspace on an empty field and Left at its start
/// to step onto the tags, Backspace or Delete on a tag to remove it.
library;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'combobox.dart';
import 'internal/option_list.dart';
import 'localizations.dart';

/// One tag, as [DesignTagInput.tagBuilder] gets it.
@immutable
class DesignTagDetails {
  /// A tag; the input makes these.
  const DesignTagDetails({
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
typedef DesignTagBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  DesignTagDetails tag,
);

/// Lays out the tags and the field (a wrap, by default).
typedef DesignTagLayoutBuilder = Widget Function(
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
/// DesignTagInput<String>(values: const ['red'], onChanged: (values) {}, onCreate: (text) => text, fieldBuilder: (context, field) => EditableText(controller: field.controller, focusNode: field.focusNode, style: const TextStyle(), cursorColor: const Color(0xFF000000), backgroundCursorColor: const Color(0xFF808080), onSubmitted: (_) => field.submit()), optionBuilder: (context, option, states) => Text(option), tagBuilder: (context, value, tag) => Text(value))
/// ```
class DesignTagInput<T extends Object> extends StatefulWidget {
  /// A tag input over [values].
  const DesignTagInput({
    super.key,
    required this.values,
    required this.onChanged,
    required this.fieldBuilder,
    required this.optionBuilder,
    required this.tagBuilder,
    this.options = const [],
    this.search,
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
  });

  /// The chosen values, in order.
  final List<T> values;

  /// Called with the new list when a tag is added or removed.
  final ValueChanged<List<T>> onChanged;

  /// Paints the field.
  final DesignComboboxFieldBuilder fieldBuilder;

  /// Paints one suggestion.
  final DesignOptionBuilder<T> optionBuilder;

  /// Paints one tag.
  final DesignTagBuilder<T> tagBuilder;

  /// What typing suggests (less what is chosen), when there is no
  /// [search].
  final Iterable<T> options;

  /// Finds suggestions for a query, in place of filtering [options].
  final DesignOptionSearch<T>? search;

  /// A value's text.
  final String Function(T value) displayStringForOption;

  /// Makes a value of free text, or null to refuse it; null for no free
  /// text (only suggestions are taken).
  final T? Function(String text)? onCreate;

  /// Lays out the tags and the field (a face round both, when the look
  /// draws one); the suggestions open from what it lays out.
  final DesignTagLayoutBuilder? layoutBuilder;

  /// Paints the suggestion list's surface.
  final DesignListSurfaceBuilder? surfaceBuilder;

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
  /// [DesignLocalizations.tagInputDeleteLabel].
  final String? deleteLabel;

  @override
  State<DesignTagInput<T>> createState() => _DesignTagInputState<T>();
}

String _string(Object value) => value.toString();

class _DesignTagInputState<T extends Object> extends State<DesignTagInput<T>> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  final List<FocusNode> _tagNodes = [];
  int? _focusedTag;
  bool _picked = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _field =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'DesignTagInput'));

  bool get _full =>
      widget.maxTags != null && widget.values.length >= widget.maxTags!;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_textChanged);
    _syncNodes();
  }

  @override
  void didUpdateWidget(DesignTagInput<T> oldWidget) {
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
    for (final node in _tagNodes) {
      node.dispose();
    }
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _syncNodes() {
    while (_tagNodes.length < widget.values.length) {
      _tagNodes.add(
        FocusNode(debugLabel: 'DesignTagDetails ${_tagNodes.length}'),
      );
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

  /// A value of [text]: a suggestion it names exactly, else [onCreate]'s.
  T? _valueOf(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    for (final option in widget.options) {
      if (widget.displayStringForOption(option).toLowerCase() ==
          t.toLowerCase()) {
        return option;
      }
    }
    return widget.onCreate?.call(t);
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
    pick();
    if (_picked) return;
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
                DesignLocalizations.of(context).tagInputDeleteLabel,
          ): () =>
              _remove(index),
        },
        child: widget.tagBuilder(
          context,
          value,
          DesignTagDetails(
            focused: _focusedTag == index,
            onDeleted: () => _remove(index),
            index: index,
          ),
        ),
      ),
    );
  }

  Future<Iterable<T>> _find(TextEditingValue value) async {
    if (_full) return const [];
    final search = widget.search;
    final Iterable<T> found;
    if (search != null) {
      found = await search(value.text);
    } else {
      final query = value.text.trim().toLowerCase();
      found = query.isEmpty
          ? widget.options
          : widget.options.where(
              (o) => widget
                  .displayStringForOption(o)
                  .toLowerCase()
                  .contains(query),
            );
    }
    return found.where((o) => !_has(o));
  }

  @override
  Widget build(BuildContext context) {
    final field = RawAutocomplete<T>(
      textEditingController: _controller,
      focusNode: _field,
      optionsBuilder: _find,
      displayStringForOption: widget.displayStringForOption,
      onSelected: (option) {
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
          child: widget.fieldBuilder(
            context,
            DesignComboboxField(
              controller: controller,
              focusNode: focusNode,
              submit: () => _submit(onSubmitted),
            ),
          ),
        );
        final tags = [
          for (var i = 0; i < widget.values.length; i++) _tag(context, i),
        ];
        return widget.layoutBuilder?.call(context, tags, field) ??
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [...tags, field],
            );
      },
      optionsViewBuilder: (context, onSelected, options) => DesignOptionList<T>(
        options: options.toList(),
        onSelected: onSelected,
        value: null,
        displayStringForOption: widget.displayStringForOption,
        optionBuilder: widget.optionBuilder,
        surfaceBuilder: widget.surfaceBuilder,
        maxHeight: widget.optionsMaxHeight,
        semanticLabel: widget.semanticLabel,
      ),
    );
    return field;
  }
}
