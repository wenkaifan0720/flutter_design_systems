// The input rows the shared inventory adds: a password field, an input group, a multi-select, a range
// slider, a calendar and a date range, and a wheel picker. Each stands
// on the look's own parts: the text field's inked frame, the slider's rail and knob, the date picker's caption cells,
// the menu's raised face.
import 'package:flutter/foundation.dart';
import 'package:ui_core/ui_core.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart'
    show InputBorder, InputDecoration, Material, MaterialType, TextField, Theme;
import 'package:flutter/semantics.dart' show SemanticsValidationResult;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../component_themes.dart';
import '../controls.dart';
import '../internal/cap_label.dart';
import '../internal/field_icon.dart';
import '../internal/lamp_line.dart';
import '../internal/list_open.dart';
import '../internal/lettering.dart'
    show comicCalendarScaleMost, comicDisplayFor;
import '../internal/pop.dart';
import '../internal/track.dart';
import '../editing.dart';
import '../glyphs.dart';
import '../localizations.dart';
import '../pickers.dart' show ComicDatePicker;
import '../press.dart';
import '../raised.dart';
import '../slider.dart' show ComicSlider;
import '../styled.dart';
import '../theme.dart';
import '../internal/style_guard.dart';
import '../knobs.dart' show ComicSpace;

// ---------------------------------------------------------------------------------------------------------------------
// The text field's parts, shared by the rows that hold an editor inside a frame of their own.

Color _inputInk(ComicColors c) => c.dark ? c.text : c.onPaper;

TextStyle _inputText(ComicThemeData t) =>
    t.type.text(16, 1.3, weight: FontWeight.w600, color: _inputInk(t.colors));

/// The text field's inked frame for [states]: popped off its print while anything inside has focus, the
/// danger tone when wrong, half strength when disabled. With [bleed] the child spans the frame's width, rim and all,
/// and keeps its parts off the rim itself (a tag input's editor, which a suggestion list opens from).
Widget _fieldFrame(
  BuildContext context,
  Set<WidgetState> states,
  Widget child, {
  EdgeInsetsGeometry? padding,
  bool bleed = false,
}) {
  final t = ComicTheme.of(context), c = t.colors;
  final look = comicStyleOf([t.textFieldTheme], states);
  final error =
          states.contains(WidgetState.error) || comicFieldInError(context),
      focused = states.contains(WidgetState.focused);
  final shape = look.shape ?? t.shapes.small;
  final rim = comicRim(t, look, error ? c.tones.danger : c.nightLine);
  return ComicScreened(
    on: states.contains(WidgetState.disabled),
    child: ComicHighlight(
      states: {if (focused) WidgetState.focused},
      shape: shape,
      wash: false,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: look.fill ?? (c.dark ? c.card : c.control),
          shape: shape.copyWith(side: rim),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              ComicTapTarget.targetOf(context),
              t.density.height(48),
            ),
          ),
          child: Padding(
            // Its words on the field's keyline, the rim counted in.
            padding: () {
              final inset =
                  (padding ??
                          EdgeInsets.symmetric(
                            horizontal: comicFieldWordsAt(t) - rim.strokeInset,
                          ))
                      .add(shape.copyWith(side: rim).dimensions);
              return bleed
                  ? inset
                        .resolve(Directionality.of(context))
                        .copyWith(left: 0, right: 0)
                  : inset;
            }(),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: IconTheme.merge(
                data: IconThemeData(color: _inputInk(c), size: 18),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The label above, and the help or the error below, as the text field lays them.
Widget _fieldColumn(
  ComicThemeData t, {
  required Widget child,
  String? label,
  String? helper,
  String? error,
  Widget Function(Widget line)? failureLine,
}) {
  final c = t.colors;
  Widget? wrong;
  if (error != null) {
    final line = Semantics(
      container: true,
      liveRegion: true,
      child: Text(error, style: t.type.small.copyWith(color: c.tones.danger)),
    );
    wrong = failureLine?.call(line) ?? line;
  }
  return Semantics(
    validationResult: error == null
        ? SemanticsValidationResult.none
        : SemanticsValidationResult.invalid,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          ExcludeSemantics(child: Text(label, style: t.type.title)),
          const SizedBox(height: ComicSpace.close),
        ],
        child,
        if (error != null || helper != null) ...[
          const SizedBox(height: ComicSpace.close),
          error == null
              ? ExcludeSemantics(
                  child: Text(
                    helper!,
                    style: t.type.small.copyWith(color: c.textSecondary),
                  ),
                )
              : wrong!,
        ],
      ],
    ),
  );
}

/// The text field's editor without its frame: the frame is the row's own.
class ComicBareEditor extends StatelessWidget {
  /// Creates a [ComicBareEditor].
  const ComicBareEditor({
    super.key,
    required this.focusNode,
    this.controller,
    this.hint,
    this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.keyboardType,
    this.inputFormatters,
    this.autofocus = false,
  });

  /// The editor's focus.
  final FocusNode focusNode;

  /// The editor's text.
  final TextEditingController? controller;

  /// [hint]: the prompt. [semanticLabel]: its spoken name. [semanticHint]: what a screen reader hears after the name.
  final String? hint, semanticLabel, semanticHint;

  /// Whether it takes input.
  final bool enabled;

  /// [onChanged]: told each edit. [onSubmitted]: told the keyboard's done.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// In place of Flutter's own finish to the keyboard's done, which drops the focus: an editor that takes one value
  /// after another (a tag input's) keeps it with `() {}`.
  final VoidCallback? onEditingComplete;

  /// The keyboard the platform shows.
  final TextInputType? keyboardType;

  /// Filters applied to each edit.
  final List<TextInputFormatter>? inputFormatters;

  /// {@macro comic.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final style = _inputText(t);
    final words =
        MediaQuery.textScalerOf(context).scale(style.fontSize ?? 16) *
        (style.height ?? 1.3);
    final reach = math.max(0.0, (ComicTapTarget.targetOf(context) - words) / 2);
    return Semantics(
      label: semanticLabel ?? hint,
      hint: semanticHint ?? (semanticLabel == null ? null : hint),
      // A tag input's editor reads whether its list shows.
      expanded: ComicListOpen.maybeOf(context),
      // Its capitals on its line's middle, as the text field's.
      child: CapLabel(
        display: false,
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            autofocus: autofocus,
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onEditingComplete: onEditingComplete,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: style,
            cursorColor: _inputInk(c),
            contextMenuBuilder: ComicTextContextMenu.editable,
            selectionControls: ComicTextSelectionControls.forPlatform(
              Theme.of(context).platform,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hint: hint == null
                  ? null
                  : ExcludeSemantics(
                      child: Text(
                        hint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.copyWith(
                          color: c.dark ? c.textSecondary : c.hint,
                        ),
                      ),
                    ),
              contentPadding: EdgeInsets.symmetric(vertical: reach),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<FocusNode>('focusNode', focusNode))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(StringProperty('semanticHint', semanticHint, defaultValue: null))
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'enabled: false',
          defaultValue: true,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

/// A focus node the caller may hold, else the row's own.
mixin _OwnedFocus<W extends StatefulWidget> on State<W> {
  final FocusNode _owned = FocusNode();
  FocusNode? get callerFocus;
  FocusNode get focus => callerFocus ?? _owned;

  @override
  void dispose() {
    _owned.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------------------------------------------------

/// A password field with a visibility button that preserves the caret position.
/// When [hideOnBlur] is true, leaving the field hides the password.
///
/// ```dart
/// ComicPasswordField(labelText: 'Password', controller: password, onSubmitted: (_) => signIn())
/// ```
class ComicPasswordField extends StatefulWidget {
  /// Creates a [ComicPasswordField].
  const ComicPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.hideOnBlur = false,
    this.autofillHints = const [AutofillHints.password],
    this.textInputAction,
    this.showLabel,
    this.hideLabel,
    this.autofocus = false,
  });

  /// The caller-owned text.
  final TextEditingController? controller;

  /// The caller-owned focus.
  final FocusNode? focusNode;

  /// [labelText]: its name, above the frame. [hintText]: the placeholder. [helperText]: the help under it. [errorText]: what is
  /// wrong, in the help's place.
  final String? labelText, hintText, helperText, errorText;

  /// Whether it takes input.
  final bool enabled;

  /// [onChanged]: each edit. [onSubmitted]: the keyboard's done.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// Hides a shown password again when focus leaves the field.
  final bool hideOnBlur;

  /// What the platform's autofill offers.
  final Iterable<String>? autofillHints;

  /// The keyboard's action.
  final TextInputAction? textInputAction;

  /// Overrides the toggle's localized names, shown and hidden.
  final String? showLabel, hideLabel;

  /// {@macro comic.autofocus}
  final bool autofocus;

  @override
  State<ComicPasswordField> createState() => _ComicPasswordFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'enabled: false',
          defaultValue: true,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        FlagProperty(
          'hideOnBlur',
          value: hideOnBlur,
          ifTrue: 'hideOnBlur',
          defaultValue: false,
        ),
      )
      ..add(
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: const [AutofillHints.password],
        ),
      )
      ..add(
        EnumProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('showLabel', showLabel, defaultValue: null))
      ..add(StringProperty('hideLabel', hideLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

class _ComicPasswordFieldState extends State<ComicPasswordField>
    with _OwnedFocus<ComicPasswordField> {
  @override
  FocusNode? get callerFocus => widget.focusNode;

  @override
  Widget build(BuildContext context) {
    return RawPasswordReveal(
      focusNode: focus,
      hideOnBlur: widget.hideOnBlur,
      showLabel:
          widget.showLabel ??
          RawWidgetsLocalizations.of(context).showPasswordLabel,
      hideLabel:
          widget.hideLabel ??
          RawWidgetsLocalizations.of(context).hidePasswordLabel,
      builder: (context, password) => ComicTextField(
        autofocus: widget.autofocus,
        controller: widget.controller,
        focusNode: focus,
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        errorText: widget.errorText,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        keyboardType: TextInputType.visiblePassword,
        obscureText: password.obscured,
        // The reveal is a toggle button, read on its own node: a button, selected while the password shows, as
        // IconButton(isSelected:) is.
        trailing: MergeSemantics(
          child: Semantics(
            button: true,
            selected: !password.obscured,
            child: ComicIconButton(
              password.obscured ? ComicGlyphs.show : ComicGlyphs.hide,
              style: comicInFieldIcon,
              targetAlignment: AlignmentDirectional.centerEnd,
              semanticLabel: password.toggleLabel,
              onPressed: widget.enabled ? password.toggle : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// A text field with optional leading and trailing widgets in a shared frame.
/// The frame highlights when a child has focus. Tapping the frame or a
/// noninteractive accessory focuses the text field.
///
/// ```dart
/// ComicInputGroup(labelText: 'Weight', leading: const [Icon(ComicGlyphs.search)], trailing: const [Text('kg')], keyboardType: TextInputType.number)
/// ```
class ComicInputGroup extends StatefulWidget {
  /// Creates a [ComicInputGroup].
  const ComicInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.leading = const [],
    this.trailing = const [],
    this.autofocus = false,
  });

  /// The caller-owned text.
  final TextEditingController? controller;

  /// The caller-owned focus.
  final FocusNode? focusNode;

  /// [labelText]: its name, above the frame. [hintText]: the placeholder. [helperText]: the help under it. [errorText]: what is
  /// wrong, in the help's place.
  final String? labelText, hintText, helperText, errorText;

  /// Whether it takes input.
  final bool enabled;

  /// [onChanged]: each edit. [onSubmitted]: the keyboard's done.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// The keyboard asked for.
  final TextInputType? keyboardType;

  /// Formatters on the text.
  final List<TextInputFormatter>? inputFormatters;

  /// Add-ons before the field and after it, in reading order: a glyph, a unit's words, a button.
  final List<Widget> leading, trailing;

  /// {@macro comic.autofocus}
  final bool autofocus;

  @override
  State<ComicInputGroup> createState() => _ComicInputGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'enabled: false',
          defaultValue: true,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<Widget>('leading', leading, defaultValue: const []),
      )
      ..add(
        IterableProperty<Widget>('trailing', trailing, defaultValue: const []),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

class _ComicInputGroupState extends State<ComicInputGroup>
    with _OwnedFocus<ComicInputGroup> {
  @override
  FocusNode? get callerFocus => widget.focusNode;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    Widget addOn(Widget part) => DefaultTextStyle.merge(
      style: t.type.body.copyWith(
        color: c.dark ? c.textSecondary : c.onPaper,
        fontWeight: FontWeight.w800,
      ),
      child: part,
    );
    return _fieldColumn(
      t,
      label: widget.labelText,
      helper: widget.helperText,
      error: widget.errorText,
      child: RawInputGroup(
        focusNode: focus,
        enabled: widget.enabled,
        isError: widget.errorText != null,
        builder: (context, states, child) => _fieldFrame(
          context,
          states,
          child,
          padding: EdgeInsetsDirectional.only(
            start: widget.leading.isEmpty ? 18.5 : 12,
            end: widget.trailing.isEmpty ? 18.5 : 6,
          ),
        ),
        child: Row(
          children: [
            for (final part in widget.leading) ...[
              addOn(part),
              const SizedBox(width: ComicSpace.close),
            ],
            Expanded(
              child: ComicBareEditor(
                autofocus: widget.autofocus,
                focusNode: focus,
                controller: widget.controller,
                semanticLabel: widget.labelText,
                hint: widget.hintText,
                semanticHint: widget.errorText ?? widget.helperText,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
              ),
            ),
            for (final part in widget.trailing) ...[
              const SizedBox(width: ComicSpace.close),
              addOn(part),
            ],
          ],
        ),
      ),
    );
  }
}

/// Several values chosen as tags in the text field's frame, with an editor after them that suggests more as you
/// type, on the menu's raised face. Down or Up opens the suggestions (every option not yet chosen, until words are
/// typed), and the keys wrap at their ends; Enter takes the lit suggestion (or, with [onCreate], the typed words);
/// Backspace on an empty editor steps onto the tags, and Backspace or Delete removes one. The behaviour is the design
/// kit's `RawTagInput`.
///
/// ```dart
/// ComicMultiSelect<String>(labelText: 'Genres', values: genres, options: const ['Noir', 'Western', 'Horror'], onChanged: (next) => setState(() => genres = next))
/// ```
class ComicMultiSelect<T extends Object> extends StatefulWidget {
  /// Creates a [ComicMultiSelect].
  const ComicMultiSelect({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.displayStringForOption,
    this.onCreate,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.maxTags,
    this.isOptionEnabled,
    this.focusNode,
    this.autofocus = false,
  });

  /// The chosen values, in order.
  final List<T> values;

  /// The new list after a tag is added or removed.
  final ValueChanged<List<T>> onChanged;

  /// What typing suggests (less what is chosen).
  final Iterable<T> options;

  /// Finds suggestions for the typed words, in place of filtering [options]. Only the latest words' answer shows;
  /// while it is on its way the list says it is looking, and if it throws, the list says the search failed and offers
  /// Try again, the editor keeping the focus.
  final FutureOr<Iterable<T>> Function(String query)? search;

  /// How long typing rests before [search] runs: one search a pause, not one a letter. Null runs it at every change.
  final Duration? debounceDuration;

  /// A value's words; `toString` when null.
  final String Function(T value)? displayStringForOption;

  /// Makes a value of typed words, or null to refuse them; null takes suggestions only.
  final T? Function(String text)? onCreate;

  /// [labelText]: its name, above the frame. [hintText]: the placeholder in the typing row while it is empty, under the
  /// chosen tags too, until [maxTags] are chosen. [helperText]: the help under it. [errorText]: what is wrong, in the
  /// help's place.
  final String? labelText, hintText, helperText, errorText;

  /// Whether it takes input.
  final bool enabled;

  /// The most tags it takes; null for no limit.
  final int? maxTags;

  /// Whether a suggestion can be taken; null: all can. One that cannot shows in the secondary ink, and the keys, the
  /// pointer and Enter pass over it.
  final bool Function(T option)? isOptionEnabled;

  /// The editor's caller-owned focus.
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
  final bool autofocus;

  @override
  State<ComicMultiSelect<T>> createState() => _ComicMultiSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<List<T>>>.has('onChanged', onChanged),
      )
      ..add(IterableProperty<T>('options', options, defaultValue: const []))
      ..add(
        ObjectFlagProperty<FutureOr<Iterable<T>> Function(String query)>.has(
          'search',
          search,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'enabled: false',
          defaultValue: true,
        ),
      )
      ..add(IntProperty('maxTags', maxTags, defaultValue: null))
      ..add(
        ObjectFlagProperty<bool Function(T option)>.has(
          'isOptionEnabled',
          isOptionEnabled,
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
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

class _ComicMultiSelectState<T extends Object>
    extends State<ComicMultiSelect<T>>
    with _OwnedFocus<ComicMultiSelect<T>> {
  @override
  FocusNode? get callerFocus => widget.focusNode;

  String _words(T value) =>
      widget.displayStringForOption?.call(value) ?? value.toString();

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final words = ComicLocalizations.of(context);
    final input = ListenableBuilder(
      listenable: focus,
      builder: (context, _) {
        final states = <WidgetState>{
          if (focus.hasFocus) WidgetState.focused,
          if (widget.errorText != null) WidgetState.error,
          if (!widget.enabled) WidgetState.disabled,
        };
        final style = comicStyleOf([t.textFieldTheme], states);
        final tagInset =
            comicRim(t, style, t.colors.nightLine).strokeInset +
            ComicSpace.close;
        final tagShape = comicInsetShape(
          style.shape ?? t.shapes.small,
          tagInset,
        );
        return RawTagInput<T>(
          values: widget.values,
          onChanged: widget.onChanged,
          options: widget.options,
          search: widget.search,
          debounceDuration: widget.debounceDuration,
          loadingBuilder: widget.search == null
              ? null
              : (context) => comicSearchNote(
                  context,
                  RawWidgetsLocalizations.of(context).loadingLabel,
                ),
          errorBuilder: widget.search == null
              ? null
              : (context, failure) => comicSearchFailed(context, failure),
          displayStringForOption: _words,
          onCreate: widget.onCreate,
          maxTags: widget.maxTags,
          isOptionEnabled: widget.isOptionEnabled,
          // Keyboard and pointer share one active option.
          highlightFollowsPointer: true,
          focusNode: focus,
          semanticLabel: widget.labelText,
          deleteLabel: words.delete,
          // The list starts on the field's face, which the focus lifts toward the start.
          surfaceBuilder: (_, list) =>
              comicListOnLiftedField(context, ComicRaisedFrame(child: list)),
          // Its options' words start on the field's words.
          optionBuilder: (context, option, states) => ComicMenuRowFace(
            states: states,
            label: _words(option),
            start: comicFieldListWords(t),
          ),
          tagBuilder: (context, value, tag) => _ComicTag(
            shape: tagShape,
            label: _words(value),
            focused: tag.focused,
            onRemove: widget.enabled ? tag.onDeleted : null,
          ),
          // The editor spans the face, its words on the field's keyline, so the suggestions open from the face's leading
          // edge at its width (the list stands under the editor).
          fieldBuilder: (context, field) => Padding(
            padding: EdgeInsets.symmetric(horizontal: comicFieldWordsAt(t)),
            child: ComicListOpen(
              open: field.isOpen,
              child: ComicBareEditor(
                focusNode: field.focusNode,
                autofocus: widget.autofocus,
                controller: field.controller,
                semanticLabel: widget.labelText,
                // The typing row says what it takes, under the tags too, so it doesn't read as an empty band.
                hint:
                    widget.maxTags == null ||
                        widget.values.length < widget.maxTags!
                    ? widget.hintText
                    : null,
                semanticHint: widget.errorText ?? widget.helperText,
                enabled: widget.enabled,
                // Enter adds a tag and the editor keeps the focus for the next, as a tag input's does. The add runs here, with
                // no onSubmitted: a field told of a submit that keeps its focus has its text input restarted, and in a
                // browser the restarted input takes no typing.
                onEditingComplete: field.submit,
              ),
            ),
          ),
          layoutBuilder: (context, tags, field) => _fieldFrame(
            context,
            states,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tags.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tagInset,
                      ComicSpace.close,
                      tagInset,
                      0,
                    ),
                    // The chosen stand close apart face to face, run under run too, their targets reaching into
                    // the room between (ui_core's RawChipGroup): in a Wrap each target's slack stood between.
                    child: RawChipGroup(
                      spacing: ComicSpace.close,
                      runSpacing: ComicSpace.close,
                      children: tags,
                    ),
                  ),
                field,
              ],
            ),
            bleed: true,
          ),
        );
      },
    );
    // The field takes its column's width, as a text field does.
    return comicDropdownWidth(
      context,
      _fieldColumn(
        t,
        label: widget.labelText,
        helper: widget.helperText,
        error: widget.errorText,
        child: widget.enabled
            ? input
            : IgnorePointer(child: ExcludeFocus(child: input)),
      ),
    );
  }
}

/// One chosen value: the chip's inked tab with a cross the pointer takes (the keyboard's Backspace and the screen
/// reader's action are the tag input's own).
class _ComicTag extends StatelessWidget {
  const _ComicTag({
    required this.shape,
    required this.label,
    required this.focused,
    this.onRemove,
  });

  final OutlinedBorder shape;

  final String label;
  final bool focused;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    return ComicHighlight(
      states: {if (focused) WidgetState.focused},
      shape: shape,
      wash: false,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: c.caption,
          shape: shape.copyWith(side: BorderSide(color: c.nightLine, width: 2)),
        ),
        child: Padding(
          // The words stand as far in from the start as the cross's ink from the end: the cross is a 14 glyph in a
          // 32 key, fine in from the rim.
          padding: const EdgeInsetsDirectional.only(
            start: ComicSpace.fine + (32 - 14) / 2,
            end: ComicSpace.fine,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // On one line, ended with an ellipsis where it outgrows its field, as Material's chips' labels: at 300%
              // text in a desk column a long tag overflowed its row.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.type.text(
                    14,
                    1.2,
                    weight: FontWeight.w800,
                    color: c.onCaption,
                  ),
                ),
              ),
              ExcludeSemantics(
                child: ExcludeFocus(
                  child: RawButton(
                    onPressed: onRemove,
                    enableFeedback: false,
                    mouseCursor: onRemove == null
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    builder: (context, states, _) => SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        ComicGlyphs.close,
                        size: 14,
                        color: c.onCaption,
                      ),
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

// ---------------------------------------------------------------------------------------------------------------------

/// A slider with two handles that select the ends of a range.
/// Pressing or dragging the track moves the nearest handle. Each handle has
/// its own keyboard focus and screen-reader label.
///
/// ```dart
/// ComicRangeSlider(label: 'Price', values: const RawRangeValues(20, 80), max: 100, onChanged: (next) => setState(() => price = next))
/// ```
class ComicRangeSlider extends StatelessWidget {
  /// Creates a [ComicRangeSlider]. Null [onChanged] disables it.
  const ComicRangeSlider({
    super.key,
    required this.label,
    required this.values,
    this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.valueLabel,
    this.startLabel,
    this.endLabel,
    this.quiet = false,
    this.rowWidth = 240,
  }) : assert(
         divisions == null || divisions > 0,
         'a range slider has at least one division',
       );

  /// Its name, above the rail.
  final String label;

  /// The span.
  final RawRangeValues values;

  /// The new span; null disables it.
  final ValueChanged<RawRangeValues>? onChanged;

  /// [min]: the least value. [max]: the greatest.
  final double min, max;

  /// How many steps it snaps to; null: none.
  final int? divisions;

  /// A value's words; a whole number when null.
  final String Function(double value)? valueLabel;

  /// What a screen reader calls the lower knob and the upper one.
  final String? startLabel, endLabel;

  /// Hides the label and the figures, keeping them for a screen reader.
  final bool quiet;

  /// Its width in a row that gives it none.
  final double rowWidth;

  String _words(double value) =>
      valueLabel?.call(value) ?? value.round().toString();

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final live = onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final look = comicStyleOf(
      [t.sliderTheme],
      {if (!live) WidgetState.disabled},
    );
    final slider = RawRangeSlider(
      values: values,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      semanticFormatterCallback: _words,
      startLabel: startLabel ?? ComicLocalizations.of(context).rangeFrom(label),
      endLabel: endLabel ?? ComicLocalizations.of(context).rangeTo(label),
      trackBuilder: (context, track) => SizedBox(
        height: 8,
        width: double.infinity,
        child: CustomPaint(
          painter: _RailInk(
            from: track.start,
            to: track.end,
            rtl: rtl,
            rail: c.track,
            fill: look.fill ?? (live ? c.primaryText : c.textSecondary),
            rim: comicRim(t, look, c.nightLine, 2),
            shape: look.shape ?? t.shapes.capsule,
          ),
        ),
      ),
      thumbBuilder: (context, index, states) =>
          _Knob(states: states, enabled: live),
      // The track stands the slider's inset in from each end, as ComicSlider's: the held knob's width, its height the
      // row's target. A press or a drag anywhere on the track moves the nearer knob, so the narrower box takes nothing
      // from the target.
      thumbSize: Size(2 * ComicSlider.inset, ComicTapTarget.targetOf(context)),
    );
    return LimitedBox(
      maxWidth: rowWidth,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: quiet ? label : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!quiet)
              Semantics(
                container: true,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: ComicSpace.near,
                  runSpacing: ComicSpace.tight,
                  children: [
                    Text(label, style: t.type.title),
                    ExcludeSemantics(
                      child: Text(
                        '${_words(values.start)} – ${_words(values.end)}',
                        // A numeric interval reads from its lower to its upper endpoint.
                        textDirection: TextDirection.ltr,
                        style: t.type.body,
                      ),
                    ),
                  ],
                ),
              ),
            slider,
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<RawRangeValues>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<RawRangeValues>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(DoubleProperty('min', min, defaultValue: 0))
      ..add(DoubleProperty('max', max, defaultValue: 1))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(
        ObjectFlagProperty<String Function(double value)>.has(
          'valueLabel',
          valueLabel,
        ),
      )
      ..add(StringProperty('startLabel', startLabel, defaultValue: null))
      ..add(StringProperty('endLabel', endLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'quiet',
          value: quiet,
          ifTrue: 'quiet',
          defaultValue: false,
        ),
      )
      ..add(DoubleProperty('rowWidth', rowWidth, defaultValue: 240));
  }
}

/// The slider's knob: a caption-filled disc inked round, a size larger while it is dragged, popped under the
/// keyboard's focus.
class _Knob extends StatelessWidget {
  /// Creates a [_Knob].
  const _Knob({required this.states, this.enabled = true});

  /// The handle's states.
  final Set<WidgetState> states;

  /// Whether the handle takes input.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final held = states.contains(WidgetState.pressed);
    final size = held ? 24.0 : 22.0;
    final shape = t.shapes.full.copyWith(
      side: BorderSide(color: c.nightLine, width: 2.5),
    );
    return Center(
      child: ComicHighlight(
        states: states,
        shape: t.shapes.full,
        wash: false,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: enabled ? c.caption : c.unlit,
              shape: shape,
            ),
          ),
        ),
      ),
    );
  }
}

class _RailInk extends CustomPainter {
  _RailInk({
    required this.from,
    required this.to,
    required this.rtl,
    required this.rail,
    required this.fill,
    required this.rim,
    required this.shape,
  });

  final double from, to;
  final bool rtl;
  final Color rail, fill;
  final BorderSide rim;
  final OutlinedBorder shape;

  @override
  void paint(Canvas canvas, Size size) {
    // The track's box stands the knob's inset in from each end; the rail's ink reaches the slider's edges, as
    // ComicSlider's does, its rim inside them.
    final reach = ComicSlider.inset - rim.width / 2;
    final rect = Rect.fromLTRB(-reach, 0, size.width + reach, size.height);
    final path = shape.getOuterPath(rect);
    final paint = Paint();
    canvas.drawPath(path, paint..color = rail);
    canvas.save();
    canvas.clipPath(path);
    final a = (rtl ? 1 - to : from) * size.width,
        b = (rtl ? 1 - from : to) * size.width;
    canvas.drawRect(Rect.fromLTRB(a, 0, b, size.height), paint..color = fill);
    canvas.restore();
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim.width
        ..color = rim.color,
    );
  }

  @override
  bool shouldRepaint(_RailInk old) =>
      old.from != from ||
      old.to != to ||
      old.rtl != rtl ||
      old.rail != rail ||
      old.fill != fill ||
      old.rim != rim ||
      old.shape != shape;
}

// ---------------------------------------------------------------------------------------------------------------------

String _locale(BuildContext context) {
  final locale = Localizations.maybeLocaleOf(context)?.toString() ?? 'en_US';
  // intl knows only en_US until the app loads its date data (Comic's delegate does, as Flutter's global ones do);
  // before then asking after any other locale throws, so the dates read in English.
  try {
    return DateFormat.localeExists(locale) ? locale : 'en_US';
  } on Exception {
    return 'en_US';
  }
}

/// A calendar for selecting a day, a range of dates or several days.
/// The controller sets the selection mode. Arrow keys move by day or week,
/// Page Up and Page Down move by month, and Home and End move to the bounds
/// of the week.
///
/// ```dart
/// ComicCalendar(controller: calendar, onChanged: (day) => setState(() {}))
/// ```
class ComicCalendar extends StatelessWidget {
  /// Creates a [ComicCalendar].
  const ComicCalendar({
    super.key,
    required this.controller,
    this.onChanged,
    this.months = 1,
    this.firstWeekday = DateTime.monday,
    this.autofocus = false,
  });

  /// The calendar's month, focus and choice.
  final RawCalendarController controller;

  /// Called with the chosen day after each choice (the [controller] holds the selection); null disables the
  /// calendar.
  final ValueChanged<DateTime>? onChanged;

  /// How many months show side by side (they wrap on a narrow screen).
  final int months;

  /// The first column, Monday as 1 and Sunday as 7.
  final int firstWeekday;

  /// Takes the keyboard's focus on first build.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final words = ComicLocalizations.of(context);
    final locale = _locale(context);
    final calendar = RawCalendarDatePicker(
      controller: controller,
      onChanged: onChanged,
      months: months,
      firstWeekday: firstWeekday,
      autofocus: autofocus,
      showOutsideDays: false,
      minDayWidth: ComicTapTarget.targetOf(context),
      dayLabel: (day) => DateFormat.yMMMMEEEEd(locale).format(day),
      monthLabel: (month) => DateFormat.yMMMM(locale).format(month),
      weekdayLabel: (weekday) => words.weekdaysShort[(weekday - 1) % 7],
      headerBuilder: (context, header) => Row(
        children: [
          ComicIconButton(
            Directionality.of(context) == TextDirection.rtl
                ? ComicGlyphs.chevronRight
                : ComicGlyphs.chevronLeft,
            semanticLabel: RawWidgetsLocalizations.of(context)
                .previousMonthTooltip,
            // The arrows stand on the header's keylines, their targets growing inward.
            targetAlignment: AlignmentDirectional.centerStart,
            onPressed: header.previous,
          ),
          // The month's name grows at most twice, as Material's calendar header: larger, it broke mid-word.
          Expanded(
            child: Semantics(
              header: true,
              liveRegion: true,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: comicCalendarScaleMost,
                child: Text(
                  header.label,
                  style: t.type.title,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          ComicIconButton(
            Directionality.of(context) == TextDirection.rtl
                ? ComicGlyphs.chevronLeft
                : ComicGlyphs.chevronRight,
            semanticLabel: RawWidgetsLocalizations.of(context).nextMonthTooltip,
            targetAlignment: AlignmentDirectional.centerEnd,
            onPressed: header.next,
          ),
        ],
      ),
      // An initial shrinks to its cell less a hair each side, so two never touch however large the reader's text.
      weekdayBuilder: (context, weekday, label) => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: ComicSpace.close,
          horizontal: ComicSpace.fine,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            // At most twice their size, as Material's calendar: larger, seven initials fill a phone's row and touch.
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: comicCalendarScaleMost),
            style: t.type.small,
          ),
        ),
      ),
      monthsBuilder: (context, months) => Wrap(
        spacing: ComicSpace.room,
        runSpacing: ComicSpace.gap,
        children: [
          for (final month in months)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ComicDatePicker.maxWidth,
              ),
              child: month,
            ),
        ],
      ),
      // A day's number grows at most twice, as Material's calendar on a phone: larger, it filled its cell to the rules.
      dayBuilder: (context, day, states) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: comicCalendarScaleMost,
        child: _CalendarDay(
          day: day,
          states: states,
          firstWeekday: firstWeekday,
        ),
      ),
    );
    return onChanged != null
        ? calendar
        : ComicScreened(
            on: true,
            child: IgnorePointer(child: ExcludeFocus(child: calendar)),
          );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawCalendarController>('controller', controller),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
      )
      ..add(IntProperty('months', months, defaultValue: 1))
      ..add(
        IntProperty(
          'firstWeekday',
          firstWeekday,
          defaultValue: DateTime.monday,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

/// One day of a [ComicCalendar]: the date picker's cell. A chosen day, or a span's end, wears the caption fill and a
/// heavy rim; a day inside the span the reader's tint; today a dot under its number. Every day reserves the heavy rim,
/// so a choice never moves the rows.
class _CalendarDay extends StatelessWidget {
  /// Creates a [_CalendarDay].
  const _CalendarDay({
    required this.day,
    required this.states,
    required this.firstWeekday,
  });

  /// The day's facts.
  final RawCalendarDayDetails day;

  /// Its press states.
  final Set<WidgetState> states;

  /// The day the calendar's weeks start on, which sets the day's column.
  final int firstWeekday;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final end = day.selected || day.isRangeStart || day.isRangeEnd;
    final between = !end && (day.inRange || day.inPreview);
    // A lit day's contour is the ink on its lamp: the night line's cream stood 1.2:1 on the yellow. At night the
    // night line is laid over its outer edge, where the ink was lost on the page (comicLampNightLine).
    final rim = end
        ? BorderSide(color: c.onCaption, width: 2.5)
        : BorderSide.none;
    final shape = t.shapes.small;
    // A resting day draws its share of the month's rules (_DayRule): two days side by side, or one over another, meet
    // on one rule. Each drew its whole outline, two rules deep where days met.
    final last = DateTime(day.date.year, day.date.month + 1, 0).day;
    final column = (day.date.weekday - firstWeekday) % 7;
    final rules = end || !day.inMonth
        ? null
        : _DayRule(
            shape: shape,
            color: c.divider,
            after: column < 6 && day.date.day < last,
            below: day.date.day + 7 <= last,
            direction: Directionality.of(context),
          );
    // Every day keeps the room its old outline took, so the numbers stand where they stood.
    final reserve = end
        ? 2.5
        : day.inMonth
        ? 1.0
        : 0.0;
    final ink = end
        ? c.onCaption
        : day.inMonth
        ? c.text
        : c.textSecondary;
    return ComicScreened(
      on: !day.enabled,
      child: ComicHighlight(
        states: states,
        shape: shape,
        // The cell is every day's face, whatever it draws: a plain day's faint rule cannot show it in pixels, and
        // ui_core's row check read a span's end inside its heavy rim, 2.5 px short of the days beside it.
        child: RawKeylineFace(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: end
                  ? c.caption
                  : between
                  ? c.currentUserTint
                  : null,
              shape: shape.copyWith(side: rim),
            ),
            child: CustomPaint(
              foregroundPainter: rules,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: ShapeDecoration(
                  shape: shape.copyWith(
                    side: end ? comicLampNightLine(c) : BorderSide.none,
                  ),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: ComicDatePicker.dayWidth,
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(2.5 - reserve + 4),
                  // The number alone sets the cell, its capitals on the middle, so today (and its dot, laid over the
                  // cell under the number) stands as tall as every day beside it (ui_core's DesignRowCheck).
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // A number never breaks: large text that outgrows the cell shrinks it whole.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CapLabel(
                          display: false,
                          child: Text(
                            day.label,
                            maxLines: 1,
                            softWrap: false,
                            style: t.type.body.copyWith(
                              color: ink,
                              fontWeight: end ? FontWeight.w800 : null,
                            ),
                          ),
                        ),
                      ),
                      if (day.isToday)
                        Positioned(
                          bottom: -3,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: ink,
                              shape: t.shapes.full,
                            ),
                            child: const SizedBox(width: 4, height: 4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A resting day's share of its month's rules: its outline in the theme's shape, laid inside its edges, less its end
/// and its foot where a day of the month follows there (that day's start or top is the rule between them). So two days
/// meet on one rule, and the month's outer edges are each a day's own.
class _DayRule extends CustomPainter {
  _DayRule({
    required this.shape,
    required this.color,
    required this.after,
    required this.below,
    required this.direction,
  });

  final OutlinedBorder shape;
  final Color color;

  /// Whether a day of the month follows at the day's end, and under it.
  final bool after, below;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final rtl = direction == TextDirection.rtl;
    // Where a day follows, the outline runs on under that day's rule and is
    // cut at this day's edge: its top and start reach the next day's whole,
    // so the rules cross unbroken, and no rule is laid over another.
    final outline = Rect.fromLTRB(
      rtl && after ? -1 : 0,
      0,
      !rtl && after ? size.width + 1 : size.width,
      below ? size.height + 1 : size.height,
    );
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawPath(
        shape.getOuterPath(outline.deflate(.5), textDirection: direction),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_DayRule oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.after != after ||
      oldDelegate.below != below ||
      oldDelegate.direction != direction;
}

/// A span of days on a [ComicCalendar] in range mode, with the span written above it. The first press starts it, the
/// second ends it; [onChanged] hears a whole span.
///
/// ```dart
/// ComicDateRangePicker(firstDate: DateTime(2026), lastDate: DateTime(2027), value: stay, onChanged: (next) => setState(() => stay = next))
/// ```
class ComicDateRangePicker extends StatefulWidget {
  /// Creates a [ComicDateRangePicker].
  const ComicDateRangePicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.onChanged,
    this.months = 1,
    this.currentDate,
    this.firstWeekday = DateTime.monday,
  });

  /// [firstDate]: the earliest day it takes. [lastDate]: the latest.
  final DateTime firstDate, lastDate;

  /// The span.
  final RawDateRange? value;

  /// Hears a whole span; null disables it.
  final ValueChanged<RawDateRange>? onChanged;

  /// How many months show side by side.
  final int months;

  /// Overrides the device's today.
  final DateTime? currentDate;

  /// The first column, Monday as 1.
  final int firstWeekday;

  @override
  State<ComicDateRangePicker> createState() => _ComicDateRangePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('firstDate', firstDate))
      ..add(DiagnosticsProperty<DateTime>('lastDate', lastDate))
      ..add(
        DiagnosticsProperty<RawDateRange>('value', value, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<RawDateRange>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(IntProperty('months', months, defaultValue: 1))
      ..add(
        DiagnosticsProperty<DateTime>(
          'currentDate',
          currentDate,
          defaultValue: null,
        ),
      )
      ..add(
        IntProperty(
          'firstWeekday',
          firstWeekday,
          defaultValue: DateTime.monday,
        ),
      );
  }
}

class _ComicDateRangePickerState extends State<ComicDateRangePicker> {
  late RawCalendarController _calendar = _make();

  RawCalendarController _make() => RawCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: RawCalendarMode.range,
    selectedRange: widget.value,
    initialMonth: widget.value?.start,
    currentDate: widget.currentDate,
  );

  @override
  void didUpdateWidget(ComicDateRangePicker old) {
    super.didUpdateWidget(old);
    if (widget.firstDate != old.firstDate ||
        widget.lastDate != old.lastDate ||
        (widget.value != old.value &&
            widget.value != _calendar.selectedRange)) {
      _calendar.dispose();
      _calendar = _make();
    }
  }

  @override
  void dispose() {
    _calendar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final full = DateFormat.yMMMd(_locale(context));
    final short = DateFormat.MMMd(_locale(context));
    final span = _calendar.selectedRange;
    final end = span?.end;
    // Material's range picker's rule: the start drops its year when the end shares it, the end when both are this
    // year's ("Nov 9 – Nov 13"), so the span stays on one line of the heading.
    final year = (widget.currentDate ?? DateTime.now()).year;
    final words = span == null
        ? ComicLocalizations.of(context).chooseDate
        : '${(end == null || end.year == span.start.year ? short : full).format(span.start)} – '
              '${end == null ? '…' : (end.year == span.start.year && end.year == year ? short : full).format(end)}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(words, style: comicDisplayFor(words, t.type.section)),
        ),
        const SizedBox(height: ComicSpace.close),
        ComicCalendar(
          controller: _calendar,
          months: widget.months,
          firstWeekday: widget.firstWeekday,
          onChanged: widget.onChanged == null
              ? null
              : (_) {
                  setState(() {});
                  final next = _calendar.selectedRange;
                  if (next != null && next.isComplete) {
                    widget.onChanged?.call(next);
                  }
                },
        ),
      ],
    );
  }
}

/// Raises a [ComicDateRangePicker] in the dialog and returns the confirmed span, or null on dismissal.
///
/// ```dart
/// final stay = await showComicDateRangePicker(context, firstDate: DateTime(2026), lastDate: DateTime(2027));
/// ```
Future<RawDateRange?> showComicDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  RawDateRange? value,
  DateTime? currentDate,
  String? title,
  String? confirmText,
  String? cancelText,
}) {
  var picked = value;
  return showComicDialog<RawDateRange>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => ComicDialog(
        title: title ?? ComicLocalizations.of(context).chooseDate,
        content: [
          ComicDateRangePicker(
            firstDate: firstDate,
            lastDate: lastDate,
            value: picked,
            currentDate: currentDate,
            onChanged: (span) => setState(() => picked = span),
          ),
        ],
        actions: [
          ComicButton(
            cancelText ?? RawWidgetsLocalizations.of(context).cancelButtonLabel,
            onPressed: () => Navigator.pop(context),
          ),
          ComicButton.filled(
            confirmText ?? ComicLocalizations.of(context).choose,
            size: ComicButtonSize.small,
            onPressed: picked == null
                ? null
                : () => Navigator.pop(context, picked),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------------------------------------

/// One value off a turning drum, on ui_core's [RawPicker]: the rows roll past a caption band that holds the
/// chosen one. A drag or a fling turns it; Up and Down step it, Page Up and Down by five, Home and End to the ends, and
/// typing jumps to a value's words; a screen reader hears it as an adjustable value.
///
/// ```dart
/// ComicWheelPicker<int>(semanticLabel: 'Copies', values: const [1, 2, 3, 4, 5], value: copies, labelOf: (n) => '$n', onChanged: (n) => setState(() => copies = n))
/// ```
class ComicWheelPicker<T> extends StatefulWidget {
  /// Creates a [ComicWheelPicker]. Null [onChanged] disables it.
  const ComicWheelPicker({
    super.key,
    required this.semanticLabel,
    required this.values,
    required this.value,
    required this.labelOf,
    this.onChanged,
    this.itemExtent = 44,
    this.visible = 5,
    this.focusNode,
    this.autofocus = false,
  }) : assert(visible > 0 && visible % 2 == 1);

  /// What it picks, for a screen reader.
  final String semanticLabel;

  /// The values on the drum, in order.
  final List<T> values;

  /// The chosen value (one of [values]).
  final T value;

  /// A value's words.
  final String Function(T value) labelOf;

  /// Each newly centred value; null disables it.
  final ValueChanged<T>? onChanged;

  /// A row's height.
  final double itemExtent;

  /// How many rows show (odd: one in the band, the rest around it).
  final int visible;

  /// The caller-owned focus.
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
  final bool autofocus;

  @override
  State<ComicWheelPicker<T>> createState() => _ComicWheelPickerState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IterableProperty<T>('values', values))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(
        ObjectFlagProperty<String Function(T value)>.has('labelOf', labelOf),
      )
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(DoubleProperty('itemExtent', itemExtent, defaultValue: 44))
      ..add(IntProperty('visible', visible, defaultValue: 5))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

/// The height of a wheel row's line of words at 1x: 18 px at a line height of 1.2.
const double _wheelLine = 18 * 1.2;

class _ComicWheelPickerState<T> extends State<ComicWheelPicker<T>>
    with _OwnedFocus<ComicWheelPicker<T>> {
  @override
  FocusNode? get callerFocus => widget.focusNode;

  int get _index => math.max(0, widget.values.indexOf(widget.value));

  // ui_core's picker owns its column's focus: the caller's node stands round it and hands focus in.
  void _handIn(bool focused) {
    if (!focused || !focus.hasPrimaryFocus) return;
    for (final node in focus.descendants) {
      if (node.canRequestFocus && !node.skipTraversal) {
        node.requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final live = widget.onChanged != null;
    final frame = t.shapes.medium;
    final band = t.shapes.small;
    final picker = RawPicker(
      columns: (_) => [
        RawPickerColumn(
          itemCount: widget.values.length,
          itemLabel: (i) => widget.labelOf(widget.values[i]),
          semanticLabel: widget.semanticLabel,
        ),
      ],
      selection: [_index],
      onChanged: live
          ? (selection) {
              if (selection.first != _index) {
                widget.onChanged!(widget.values[selection.first]);
              }
            }
          : null,
      itemExtent: widget.itemExtent,
      visibleItemCount: widget.visible,
      // Comic's drum: a wider wheel than iOS's, unsqueezed, the rows off the band faded back.
      diameterRatio: 1.8,
      squeeze: 1,
      overAndUnderCenterOpacity: .6,
      autofocus: widget.autofocus,
      itemBuilder: (context, row) => Center(
        child: Text(
          row.label,
          maxLines: 1,
          // A row's words grow with the reader's text until their line fills the row (twice their size at the
          // default 44): larger, the rows would overlap and the band would cut the chosen one, so they stop there.
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: math.max(1, widget.itemExtent / _wheelLine)),
          style: t.type.text(
            18,
            1.2,
            weight: FontWeight.w800,
            color: row.selected ? c.onCaption : c.text,
          ),
        ),
      ),
      columnBuilder: (context, column, wheel) => ComicHighlight(
        states: {
          for (final state in const [WidgetState.focused, WidgetState.hovered])
            if (column.states.contains(state)) state,
        },
        shape: frame,
        wash: false,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(
            shape: frame.copyWith(
              side: BorderSide(color: c.nightLine, width: 2.5),
            ),
          ),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: c.dark ? c.card : c.control,
              shape: frame,
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: frame),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ComicSpace.close,
                    ),
                    child: SizedBox(
                      height: widget.itemExtent,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: c.caption,
                          shape: band.copyWith(
                            side: BorderSide(color: c.onCaption, width: 2.5),
                          ),
                        ),
                        // At night the night line round the lamp's ink, which the page swallowed.
                        child: DecoratedBox(
                          position: DecorationPosition.foreground,
                          decoration: ShapeDecoration(
                            shape: band.copyWith(side: comicLampNightLine(c)),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  wheel,
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // A picker's width at the start of a wider column, as the date picker's: its chosen band never spans a desktop
    // column.
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ComicDatePicker.maxWidth),
        child: Focus(
          focusNode: focus,
          skipTraversal: true,
          includeSemantics: false,
          onFocusChange: _handIn,
          child: LimitedBox(
            maxWidth: 200,
            child: ComicScreened(on: !live, child: picker),
          ),
        ),
      ),
    );
  }
}

/// A one-time code, one inked box a digit, with the platform's one-time-code autofill. A paste fills it, a long press or
/// a secondary click offers Paste, and a screen reader hears one field.
///
/// ```dart
/// ComicInputOtp(labelText: 'Verification code', length: 6, onCompleted: verify)
/// ```
class ComicInputOtp extends StatefulWidget {
  /// Creates a code input of [length] boxes.
  const ComicInputOtp({
    super.key,
    this.style,
    required this.labelText,
    this.length = 6,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.onCompleted,
    this.onEditingComplete,
    this.decorate,
    this.failureLine,
    this.inputFormatters = const [],
    this.autofillHints = const [AutofillHints.oneTimeCode],
  }) : assert(length > 0);

  /// Its visible and spoken label.
  final String labelText;

  /// How many digits.
  final int length;

  /// Holds the digits, when the caller does.
  final TextEditingController? controller;

  /// Told each edit.
  final ValueChanged<String>? onChanged;

  /// Told the keyboard's done.
  final ValueChanged<String>? onSubmitted;

  /// What is wrong, under the boxes.
  final String? errorText;

  /// Whether it takes input.
  final bool enabled;

  /// The input's focus.
  final FocusNode? focusNode;

  /// Whether it asks for focus when it first appears.
  final bool autofocus;

  /// The keyboard's action key.
  final TextInputAction textInputAction;

  /// Told once each time every box is filled.
  final ValueChanged<String>? onCompleted;

  /// Called when editing is completed.
  final VoidCallback? onEditingComplete;

  /// Wraps the input, for application semantics.
  final Widget Function(Widget input)? decorate;

  /// Wraps the error line.
  final Widget Function(Widget line)? failureLine;

  /// Filters applied before the digits-only rule.
  final List<TextInputFormatter> inputFormatters;

  /// What the platform may fill it with.
  final Iterable<String> autofillHints;

  /// {@macro comic.style}
  final ComicStyle? style;

  @override
  State<ComicInputOtp> createState() => _ComicInputOtpState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(IntProperty('length', length, defaultValue: 6))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'enabled: false',
          defaultValue: true,
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
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      )
      ..add(
        EnumProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: TextInputAction.done,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onCompleted',
          onCompleted,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        ObjectFlagProperty<Widget Function(Widget input)>.has(
          'decorate',
          decorate,
        ),
      )
      ..add(
        ObjectFlagProperty<Widget Function(Widget line)>.has(
          'failureLine',
          failureLine,
        ),
      )
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: const [],
        ),
      )
      ..add(
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: const [AutofillHints.oneTimeCode],
        ),
      )
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
      );
  }
}

class _ComicInputOtpState extends State<ComicInputOtp> {
  late RawOtpController _code = _make();

  RawOtpController _make() =>
      RawOtpController(length: widget.length, text: widget.controller);

  @override
  void didUpdateWidget(ComicInputOtp old) {
    super.didUpdateWidget(old);
    if (old.length != widget.length ||
        !identical(old.controller, widget.controller)) {
      final stale = _code;
      _code = _make();
      // The field lets go of the old controller while it updates, after this.
      WidgetsBinding.instance.addPostFrameCallback((_) => stale.dispose());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Widget _box(BuildContext context, RawOtpSlot slot) {
    final t = ComicTheme.of(context), c = t.colors;
    final live = slot.active && slot.focused;
    final look = comicStyleOf(
      [widget.style, t.textFieldTheme],
      {
        if (live) WidgetState.focused,
        if (slot.isError) WidgetState.error,
        if (!slot.enabled) WidgetState.disabled,
      },
    );
    final rim = comicRim(
      t,
      look,
      slot.isError || comicFieldInError(context) ? c.tones.danger : c.nightLine,
    );
    final shape = look.shape ?? t.shapes.small;
    // The box taking the next character wears the look's ring, as a text field does.
    return ComicScreened(
      on: !slot.enabled,
      child: ComicHighlight(
        states: {if (live) WidgetState.focused},
        shape: shape,
        wash: false,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: look.fill ?? (c.dark ? c.card : c.control),
            shape: shape.copyWith(side: rim),
          ),
          child: SizedBox(
            height: math.max(
              ComicTapTarget.targetOf(context),
              t.density.height(52),
            ),
            child: Center(
              child: slot.filled
                  ? Text(slot.character, style: _inputText(t))
                  : live
                  ? SizedBox(
                      width: 2,
                      height: 22,
                      child: ColoredBox(color: _inputInk(c)),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final field = RawOtpField(
      controller: _code,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      isError: widget.errorText != null,
      semanticLabel: widget.labelText,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      contextMenuBuilder: (_, anchors, items) => ComicTextContextMenu(
        anchors: anchors,
        buttonItems: ComicTextContextMenu.labelled(context, items),
      ),
      layoutBuilder: (context, slots) => Row(
        children: [
          for (final (i, slot) in slots.indexed) ...[
            if (i > 0) const SizedBox(width: ComicSpace.close),
            Expanded(child: slot),
          ],
        ],
      ),
      slotBuilder: _box,
    );
    return _fieldColumn(
      t,
      label: widget.labelText,
      error: widget.errorText,
      failureLine: widget.failureLine,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.length * 60.0),
          child: widget.decorate?.call(field) ?? field,
        ),
      ),
    );
  }
}
