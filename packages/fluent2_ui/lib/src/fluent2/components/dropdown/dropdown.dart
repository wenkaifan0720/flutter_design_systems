import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/measure.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../input/field_core.dart';
import '../pressable/pressable.dart';
import '../sheet.dart';

/// One option of a listbox, Fluent's `Option`: the [value] it stands for,
/// its [label], a glyph before it ([icon]), a [secondary] word at its end;
/// a disabled one ([enabled] false) is drawn in the disabled ink and never
/// chosen.
///
/// ```dart
/// Fluent2Option('design', 'Design review', icon: Fluent2Icons.people)
/// ```
@immutable
class Fluent2Option<T> {
  /// An option for [value], labelled [label].
  const Fluent2Option(
    this.value,
    this.label, {
    this.icon,
    this.secondary,
    this.enabled = true,
  });

  /// The value the option stands for.
  final T value;

  /// The option's words.
  final String label;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// Quieter words at the option's end; null shows none.
  final String? secondary;

  /// False draws the option disabled; it cannot be chosen.
  final bool enabled;
}

class _Picked<T> {
  const _Picked(this.value);

  final T value;
}

/// The chevron's size and its room before it, by field size (Fluent's
/// expand icon: 16, 20, 24, 2 or 6 after the words).
(IconData, double, double) _chevron(Fluent2InputSize size) => switch (size) {
  Fluent2InputSize.small => (
    Fluent2Icons.chevronDown16,
    16,
    Fluent2Spacing.xxs,
  ),
  Fluent2InputSize.medium => (Fluent2Icons.chevronDown, 20, Fluent2Spacing.xxs),
  Fluent2InputSize.large => (
    Fluent2Icons.chevronDown,
    24,
    Fluent2Spacing.sNudge,
  ),
};

/// Fluent 2's Dropdown: a field-faced button (32 tall, 12 in at its start
/// and 10 at its end, at least 250 wide where there is room) saying the
/// chosen option's label, or its [placeholder] in the fourth ink, before
/// the down chevron in the accessible stroke; it opens the listbox of
/// [options] (one chosen, its check before it): on the desktop the
/// popover under the field (`shadow16`, 4 round its rows), on a phone a
/// bottom sheet headed by [label]. A choice calls [onChanged]; null draws
/// it disabled. Enter, Space and the down arrow open it, the arrows move
/// through the list, Escape closes it.
///
/// ```dart
/// Fluent2Select<String>(label: 'Channel', prompt: 'Choose a channel', value: channel, options: const [Fluent2Option('general', 'General'), Fluent2Option('design', 'Design')], onChanged: (v) => setState(() => channel = v))
/// ```
class Fluent2Select<T> extends StatefulWidget {
  /// A select of [options] showing [value].
  const Fluent2Select({
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.prompt,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
    this.invalid = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The options, in order.
  final List<Fluent2Option<T>> options;

  /// The chosen option's value; null shows the prompt.
  final T? value;

  /// Called with the value of the option chosen; null puts it out of use.
  final ValueChanged<T>? onChanged;

  /// The spoken name and the phone sheet's title; null takes the
  /// enclosing field's label.
  final String? label;

  /// The words before anything is chosen; null is "Select an option" in the
  /// app's language.
  final String? prompt;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// Whether it shows Fluent's invalid state, its edge in the danger colour.
  final bool invalid;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  State<Fluent2Select<T>> createState() => _Fluent2SelectState<T>();
}

class _Fluent2SelectState<T> extends State<Fluent2Select<T>> {
  final _portal = OverlayPortalController();
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'dropdown'));
  List<FocusNode> _nodes = const [];

  void _fit() {
    final n = widget.options.length;
    if (_nodes.length == n) return;
    for (final node in _nodes.skip(n)) {
      node.dispose();
    }
    _nodes = [
      for (var i = 0; i < n; i++)
        i < _nodes.length ? _nodes[i] : FocusNode(debugLabel: 'option $i'),
    ];
  }

  @override
  void dispose() {
    _ownFocus?.dispose();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  String? get _name =>
      widget.label ?? Fluent2FieldScope.maybeOf(context)?.label;

  String get _prompt =>
      widget.prompt ?? Fluent2Localizations.of(context).selectAnOption;

  void _open() {
    if (!Fluent2Layout.popsOver(context)) {
      _sheet();
      return;
    }
    if (_portal.isShowing) {
      _close(refocus: true);
      return;
    }
    setState(_portal.show);
    final at = widget.options.indexWhere((o) => o.value == widget.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _nodes.isEmpty) return;
      _nodes[at < 0 ? 0 : at].requestFocus();
    });
  }

  void _close({required bool refocus}) {
    if (_portal.isShowing) setState(_portal.hide);
    if (refocus) _focus.requestFocus();
  }

  void _pick(T value) {
    _close(refocus: true);
    if (value != widget.value) widget.onChanged?.call(value);
  }

  Future<void> _sheet() async {
    final picked = await Fluent2Sheet.show<_Picked<T>>(
      context,
      title: _name ?? _prompt,
      builder: (sheetContext) => [
        for (final o in widget.options)
          Fluent2OptionRow(
            label: o.label,
            icon: o.icon,
            secondary: o.secondary,
            selected: o.value == widget.value,
            onPressed: o.enabled
                ? () => Navigator.of(sheetContext).pop(_Picked<T>(o.value))
                : null,
          ),
      ],
    );
    if (!mounted || picked == null) return;
    if (picked.value != widget.value) widget.onChanged?.call(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    _fit();
    final t = context.fluent2Theme;
    final c = t.colors;
    final live = widget.onChanged != null;
    final m = Fluent2FieldMetrics.of(widget.size);
    final (glyph, glyphSize, glyphGap) = _chevron(widget.size);
    final chosen = widget.options.where((o) => o.value == widget.value);
    final selected = chosen.isEmpty ? null : chosen.first;
    // Dropdown's button: small 8 / 6, medium 12 / 10, large 18 / 12.
    final (start, end) = switch (widget.size) {
      Fluent2InputSize.small => (Fluent2Spacing.s, Fluent2Spacing.sNudge),
      Fluent2InputSize.medium => (Fluent2Spacing.m, Fluent2Spacing.mNudge),
      Fluent2InputSize.large => (18.0, Fluent2Spacing.m),
    };
    final type = Fluent2FieldMetrics.typeOf(t, widget.size);
    final open = _portal.isShowing;
    // From 600 it keeps its own width, its widest option's (its list
    // matches it, as Fluent's listbox matches its button): never the
    // column's or the page's.
    final content =
        2 +
        start +
        fluent2WordsWidth(context, [
          _prompt,
          for (final o in widget.options) o.label,
        ], type) +
        glyphGap +
        glyphSize +
        end;
    return fluent2KeepsOwnWidth(
      context,
      content: content,
      child: Fluent2FieldPopover(
        controller: _portal,
        onDismiss: () => _close(refocus: _nodes.any((n) => n.hasFocus)),
        popover: (context) => Fluent2PopoverSurface(
          child: FocusTraversalGroup(
            child: Fluent2ListboxColumn(
              children: [
                for (var i = 0; i < widget.options.length; i++)
                  Fluent2OptionRow(
                    label: widget.options[i].label,
                    icon: widget.options[i].icon,
                    secondary: widget.options[i].secondary,
                    selected: widget.options[i].value == widget.value,
                    focusNode: _nodes[i],
                    onPressed: widget.options[i].enabled
                        ? () => _pick(widget.options[i].value)
                        : null,
                  ),
              ],
            ),
          ),
        ),
        child: Fluent2HitSlop(
          child: Fluent2FieldButton(
            autofocus: widget.autofocus,
            onOpen: live ? _open : null,
            label: _name ?? _prompt,
            value: selected?.label,
            hint: Fluent2Localizations.of(context).opensList,
            expanded: open,
            focusNode: _focus,
            builder: (context, focused, pressed) => Fluent2FieldFrame(
              appearance: widget.appearance,
              focused: focused || open,
              enabled: live,
              invalid:
                  widget.invalid ||
                  (Fluent2FieldScope.maybeOf(context)?.invalid ?? false),
              pressed: pressed,
              cursor: SystemMouseCursors.click,
              minHeight: m.height,
              padding: EdgeInsetsDirectional.only(start: start, end: end),
              child: Row(
                children: [
                  Expanded(
                    child: fluent2CapCentred(
                      Text(
                        selected?.label ?? _prompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.c(
                          !live
                              ? c.neutralForegroundDisabled
                              : selected == null
                              ? fluent2PlaceholderInk(t, widget.appearance)
                              : c.neutralForeground1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: glyphGap),
                  Icon(
                    glyph,
                    size: glyphSize,
                    color: live
                        ? c.neutralStrokeAccessible
                        : c.neutralForegroundDisabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fluent 2's Combobox: a text field with the down chevron at its end
/// whose typed words filter the listbox of [options] under it (the
/// popover, on a phone too, so the keyboard stays up); the arrows move the
/// active option (the focus ring on it), Enter or a press chooses it and
/// the field then says its label; Escape closes the list, and leaving the
/// field puts back the chosen label. A choice calls [onChanged]; null
/// draws it disabled. Read as a text field named [label].
///
/// ```dart
/// Fluent2Combobox<String>(label: 'Assignee', hint: 'Type a name', value: owner, options: [for (final p in people) Fluent2Option(p.id, p.name)], onChanged: (v) => setState(() => owner = v))
/// ```
class Fluent2Combobox<T> extends StatefulWidget {
  /// A combobox of [options]: a field that filters them as the user types.
  const Fluent2Combobox({
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
    this.invalid = false,
    this.empty,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The options, in order.
  final List<Fluent2Option<T>> options;

  /// The chosen option's value; null leaves the field empty.
  final T? value;

  /// Called with the value of the option chosen; null puts it out of use.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls the field; null reads the surrounding form
  /// field's label.
  final String? label;

  /// The words shown while it is empty.
  final String? hint;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// Whether it shows Fluent's invalid state, its edge in the danger colour.
  final bool invalid;

  /// What the list says when nothing matches the typed words; null is
  /// [DesignLocalizations.noResultsLabel].
  final String? empty;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  State<Fluent2Combobox<T>> createState() => _Fluent2ComboboxState<T>();
}

class _Fluent2ComboboxState<T> extends State<Fluent2Combobox<T>> {
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'combobox'));
  final _text = TextEditingController();

  Fluent2Option<T>? get _chosen {
    for (final o in widget.options) {
      if (o.value == widget.value) return o;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
  }

  @override
  void didUpdateWidget(Fluent2Combobox<T> old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_refresh);
      _focus.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_refresh);
    _ownFocus?.dispose();
    _text.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _take(Fluent2Option<T> o) {
    if (!o.enabled) {
      // The list wrote the disabled option's words in; put the choice back.
      final words = _chosen?.label ?? '';
      _text.value = TextEditingValue(
        text: words,
        selection: TextSelection.collapsed(offset: words.length),
      );
      return;
    }
    if (o.value != widget.value) widget.onChanged?.call(o.value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final scope = Fluent2FieldScope.maybeOf(context);
    final live = widget.onChanged != null;
    final m = Fluent2FieldMetrics.of(widget.size);
    final (glyph, glyphSize, glyphGap) = _chevron(widget.size);
    final type = Fluent2FieldMetrics.typeOf(t, widget.size);
    final (start, end) = switch (widget.size) {
      Fluent2InputSize.small => (Fluent2Spacing.s, Fluent2Spacing.sNudge),
      Fluent2InputSize.medium => (Fluent2Spacing.m, Fluent2Spacing.mNudge),
      Fluent2InputSize.large => (18.0, Fluent2Spacing.m),
    };
    // From 600 it keeps its own width, its widest option's, and its list
    // matches it.
    final content =
        2 +
        start +
        fluent2WordsWidth(context, [
          ?widget.hint,
          for (final o in widget.options) o.label,
        ], type) +
        glyphGap +
        glyphSize +
        end;
    return fluent2KeepsOwnWidth(
      context,
      content: content,
      child: DesignCombobox<Fluent2Option<T>>(
        options: widget.options,
        value: _chosen,
        onSelected: _take,
        displayStringForOption: (o) => o.label,
        requireSelection: true,
        controller: _text,
        focusNode: _focus,
        semanticLabel: widget.label ?? scope?.label,
        emptyBuilder: (context) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Fluent2Spacing.s,
            vertical: Fluent2Spacing.sNudge,
          ),
          child: Text(
            widget.empty ?? DesignLocalizations.of(context).noResultsLabel,
            style: t.body1.c(t.textTertiary),
          ),
        ),
        surfaceBuilder: (context, list) => Padding(
          padding: const EdgeInsets.only(top: Fluent2Spacing.xs),
          child: Fluent2PopoverSurface(child: list),
        ),
        optionBuilder: (context, o, states) => Fluent2OptionFace(
          label: o.label,
          icon: o.icon,
          secondary: o.secondary,
          selected: states.contains(WidgetState.selected),
          highlighted: states.contains(WidgetState.focused),
          states: o.enabled ? states : {...states, WidgetState.disabled},
        ),
        fieldBuilder: (context, field) => Fluent2HitSlop(
          child: Fluent2FieldFrame(
            appearance: widget.appearance,
            focused: _focus.hasFocus,
            enabled: live,
            invalid: widget.invalid || (scope?.invalid ?? false),
            minHeight: m.height,
            padding: EdgeInsetsDirectional.only(start: start, end: end),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: widget.label ?? scope?.label,
                    child: Fluent2FieldEditor(
                      autofocus: widget.autofocus,
                      controller: field.controller,
                      focusNode: field.focusNode,
                      enabled: live,
                      onSubmitted: (_) => field.submit(),
                      style: type.c(
                        live
                            ? c.neutralForeground1
                            : c.neutralForegroundDisabled,
                      ),
                      hint: widget.hint,
                      hintStyle: type.c(
                        live
                            ? fluent2PlaceholderInk(t, widget.appearance)
                            : c.neutralForegroundDisabled,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: glyphGap),
                // The pointer's way to the list: the field holds the keyboard
                // and speaks for it, so the chevron is no tab stop or node.
                ExcludeFocus(
                  child: ExcludeSemantics(
                    child: Fluent2Pressable(
                      semantics: false,
                      onPressed: live
                          ? () => field.focusNode.hasFocus
                                ? field.focusNode.unfocus()
                                : field.focusNode.requestFocus()
                          : null,
                      child: Icon(
                        glyph,
                        size: glyphSize,
                        color: live
                            ? c.neutralStrokeAccessible
                            : c.neutralForegroundDisabled,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
