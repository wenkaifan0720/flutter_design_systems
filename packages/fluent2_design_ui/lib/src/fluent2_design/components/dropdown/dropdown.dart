import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/search_states.dart';
import '../../internal/list_keys.dart';
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

/// An option's glyph in the list, and the face's column for it.
const double _optionGlyph = 20;

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
/// chosen option's label, or its [prompt] in the fourth ink, before the
/// down chevron in the accessible stroke; where the options carry glyphs,
/// the chosen one's glyph before its words, its column kept while the
/// prompt shows, so the words stand where the list's do. It opens the
/// listbox of [options] (the chosen one in the brand's fill, its pill and
/// check): on a tablet, the desktop or under a pointer the popover under
/// the field (`shadow16`, 4 round its rows), the field's width or its
/// widest option's, its rows a finger's tall under a finger; on a phone a
/// bottom sheet headed by [label]. A choice calls [onChanged]; null draws it
/// disabled. Enter, Space and the down arrow open it, the arrows move
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
    this.style,
    super.key,
  });

  /// This field's own look, slot by slot, over the text field theme
  /// ([Fluent2ThemeData.textFieldTheme]): the slots [Fluent2FieldFrame]
  /// names.
  final Fluent2Style? style;

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

  /// {@macro fluent2.appearance}
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// {@macro fluent2.invalid}
  final bool invalid;

  /// {@macro fluent2.focusNode}
  final FocusNode? focusNode;

  /// {@macro fluent2.autofocus}
  final bool autofocus;

  @override
  State<Fluent2Select<T>> createState() => _Fluent2SelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
    );
    properties
      ..add(IterableProperty<Fluent2Option<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>?>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('prompt', prompt, defaultValue: null))
      ..add(
        EnumProperty<Fluent2InputAppearance>(
          'appearance',
          appearance,
          defaultValue: Fluent2InputAppearance.outline,
        ),
      )
      ..add(
        EnumProperty<Fluent2InputSize>(
          'size',
          size,
          defaultValue: Fluent2InputSize.medium,
        ),
      )
      ..add(FlagProperty('invalid', value: invalid, ifTrue: 'invalid'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
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
    _focusFirst();
  }

  // Once the list shows, focus on its chosen option, else its first in use.
  void _focusFirst() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _nodes.isEmpty) return;
      _nodes[fluent2FirstFocus(
            _enabled,
            widget.options.indexWhere((o) => o.value == widget.value),
          )]
          .requestFocus();
    });
  }

  List<bool> get _enabled => [for (final o in widget.options) o.enabled];

  // The list's keys round [list]: the arrows, Home and End, typed letters.
  Widget _keys(Widget list) => Fluent2ListKeys(
    nodes: _nodes,
    labels: [for (final o in widget.options) o.label],
    enabled: _enabled,
    child: list,
  );

  void _close({required bool refocus}) {
    if (_portal.isShowing) setState(_portal.hide);
    if (refocus) _focus.requestFocus();
  }

  void _pick(T value) {
    _close(refocus: true);
    if (value != widget.value) widget.onChanged?.call(value);
  }

  Future<void> _sheet() async {
    _focusFirst();
    final picked = await Fluent2Sheet.show<_Picked<T>>(
      context,
      title: _name ?? _prompt,
      builder: (sheetContext) => [
        _keys(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                Fluent2OptionRow(
                  label: widget.options[i].label,
                  icon: widget.options[i].icon,
                  secondary: widget.options[i].secondary,
                  selected: widget.options[i].value == widget.value,
                  focusNode: _nodes[i],
                  onPressed: widget.options[i].enabled
                      ? () =>
                            Navigator.of(sheetContext)
                                .pop(_Picked<T>(widget.options[i].value))
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
    if (!mounted || picked == null) return;
    if (picked.value != widget.value) widget.onChanged?.call(picked.value);
  }

  // The list's width for its widest option on one line: the listbox's 4
  // and its hairline each side, the row's 6 and 8, the check 16 and 6, a
  // glyph 20 and 4, the words, and a second word 8 after them.
  double _listNeed(BuildContext context, Fluent2ThemeData t) {
    var widest = 0.0;
    for (final o in widget.options) {
      final words =
          (o.icon == null ? 0 : _optionGlyph + Fluent2Spacing.xs) +
          fluent2WordsWidth(context, [o.label], t.body1) +
          (o.secondary == null
              ? 0
              : Fluent2Spacing.s +
                    fluent2WordsWidth(context, [o.secondary!], t.caption1));
      if (words > widest) widest = words;
    }
    return 2 * (Fluent2Spacing.xs + Fluent2Stroke.thin) +
        Fluent2Spacing.sNudge +
        16 +
        Fluent2Spacing.sNudge +
        widest +
        Fluent2Spacing.s;
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
    // Options with glyphs: the face keeps the list's glyph column, so its
    // words stand where the list's do and stay put as a choice fills it.
    final glyphs = widget.options.any((o) => o.icon != null);
    const glyphRoom = _optionGlyph + Fluent2Spacing.xs;
    // A route pushed over this one's: its list closes, the focus the route's.
    final covered = !(ModalRoute.isCurrentOf(context) ?? true);
    // From 600 it keeps its own width, its widest option's (its list
    // matches it, as Fluent's listbox matches its button): never the
    // column's or the page's.
    final content =
        2 +
        start +
        (glyphs ? glyphRoom : 0) +
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
        // The field's width, wider only for its widest option.
        minWidth: open ? _listNeed(context, t) : 0,
        // Back to the field from its list, unless a route now covers it.
        onDismiss: () =>
            _close(refocus: !covered && _nodes.any((n) => n.hasFocus)),
        popover: (context) => Fluent2PopoverSurface(
          child: _keys(
            FocusTraversalGroup(
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
        ),
        child: DesignTapTarget(
          minSize: Fluent2Layout.tapFloorOf(context),
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
              style: widget.style,
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
                  if (glyphs) ...[
                    SizedBox(
                      width: _optionGlyph,
                      child: selected?.icon == null
                          ? null
                          : Icon(
                              selected!.icon,
                              size: _optionGlyph,
                              color: live
                                  ? c.neutralForeground1
                                  : c.neutralForegroundDisabled,
                            ),
                    ),
                    const SizedBox(width: Fluent2Spacing.xs),
                  ],
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
/// popover, on a phone too, so the keyboard stays up). Down or Up opens
/// the list on the chosen option (else the first in use), every option
/// listed until the words are edited; the arrows then move the active
/// option (the focus ring on it) round the list, past an option out of
/// use; Enter or a press chooses it and the field then says its label;
/// Escape closes the list, and leaving the field puts back the chosen
/// label. An app's [search] can find the options instead, the list saying
/// "Loading" while it runs and offering "Try again" when it fails. A choice
/// calls [onChanged]; null draws it disabled. Read as a text field named [label].
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
    this.style,
    this.search,
    this.debounceDuration,
    super.key,
  });

  /// This field's own look, slot by slot, over the text field theme
  /// ([Fluent2ThemeData.textFieldTheme]): the slots [Fluent2FieldFrame]
  /// names.
  final Fluent2Style? style;

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

  /// {@macro fluent2.appearance}
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// {@macro fluent2.invalid}
  final bool invalid;

  /// What the list says when nothing matches the typed words; null is
  /// [DesignLocalizations.noResultsLabel].
  final String? empty;

  /// {@macro fluent2.focusNode}
  final FocusNode? focusNode;

  /// {@macro fluent2.autofocus}
  final bool autofocus;

  /// Finds the options for the typed words, in place of filtering
  /// [options]: an app's own search, at once or on its way. Only the latest
  /// words' answer shows. While it is on its way the list shows a spinner and
  /// "Loading"; when it throws, the list says the search failed and offers
  /// "Try again", which Down reaches, the field keeping the focus.
  final FutureOr<Iterable<Fluent2Option<T>>> Function(String query)? search;

  /// How long typing rests before [search] runs: one search a pause, not
  /// one a letter. Null runs it at every change.
  final Duration? debounceDuration;

  @override
  State<Fluent2Combobox<T>> createState() => _Fluent2ComboboxState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
    );
    properties
      ..add(IterableProperty<Fluent2Option<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>?>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(
        EnumProperty<Fluent2InputAppearance>(
          'appearance',
          appearance,
          defaultValue: Fluent2InputAppearance.outline,
        ),
      )
      ..add(
        EnumProperty<Fluent2InputSize>(
          'size',
          size,
          defaultValue: Fluent2InputSize.medium,
        ),
      )
      ..add(FlagProperty('invalid', value: invalid, ifTrue: 'invalid'))
      ..add(StringProperty('empty', empty, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        ObjectFlagProperty<
          FutureOr<Iterable<Fluent2Option<T>>> Function(String query)?
        >.has('search', search),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      );
  }
}

class _Fluent2ComboboxState<T> extends State<Fluent2Combobox<T>> {
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'combobox'));
  final _text = TextEditingController();

  // The option last chosen, which a search may have found outside
  // [Fluent2Combobox.options].
  Fluent2Option<T>? _taken;

  Fluent2Option<T>? get _chosen {
    for (final o in widget.options) {
      if (o.value == widget.value) return o;
    }
    final taken = _taken;
    return taken != null && taken.value == widget.value ? taken : null;
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
    _taken = o;
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
        isOptionEnabled: (o) => o.enabled,
        // Fluent paints the pointer's row (a neutral fill) and the keys' (the
        // focus ring) apart, and neither looks like the chosen option, so each
        // keeps its own.
        highlightFollowsPointer: false,
        displayStringForOption: (o) => o.label,
        requireSelection: true,
        search: widget.search,
        debounceDuration: widget.debounceDuration,
        loadingBuilder: widget.search == null ? null : fluent2SearchLoading,
        errorBuilder: widget.search == null ? null : fluent2SearchFailed,
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
          states: states,
        ),
        fieldBuilder: (context, field) => Fluent2FieldFrame(
          appearance: widget.appearance,
          style: widget.style,
          focused: _focus.hasFocus,
          enabled: live,
          // ui_core's combobox keeps the field's node its own; the frame
          // makes it the frame's size, as a text field's is.
          textNode: true,
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
                    // The keyboard's done (Enter) takes the active option;
                    // the field keeps the focus, as a select's does, and its
                    // text input (no onSubmitted: see onEditingComplete).
                    onEditingComplete: field.submit,
                    style: type.c(
                      live ? c.neutralForeground1 : c.neutralForegroundDisabled,
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
    );
  }
}
