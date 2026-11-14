// The input rows the shared inventory adds: a password field, an input group, a multi-select, a range
// slider, a calendar and a date range, and a wheel picker. Each stands
// on the look's own parts: the text field's inked frame, the slider's rail and knob, the date picker's caption cells,
// the menu's raised face.
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

// ---------------------------------------------------------------------------------------------------------------------
// The text field's parts, shared by the rows that hold an editor inside a frame of their own.

Color _inputInk(ComicColors c) => c.dark ? c.text : c.onPaper;

TextStyle _inputText(ComicThemeData t) =>
    t.type.text(16, 1.3, weight: FontWeight.w600, color: _inputInk(t.colors));

/// The text field's inked frame for [states]: the look's focus ring outside it while anything inside has focus, the
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
  final look = ComicStyleOf([t.textFieldTheme], states);
  final error =
          states.contains(WidgetState.error) || comicFieldInError(context),
      focused = states.contains(WidgetState.focused);
  final shape = look.shape ?? t.shapes.small;
  final rim = comicRim(t, look, error ? c.tones.danger : c.nightLine);
  return Opacity(
    opacity: states.contains(WidgetState.disabled) ? .55 : 1,
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
          const SizedBox(height: 6),
        ],
        child,
        if (error != null || helper != null) ...[
          const SizedBox(height: 6),
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
    this.label,
    this.semanticHint,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.autofocus = false,
  });

  /// The editor's focus.
  final FocusNode focusNode;

  /// The editor's text.
  final TextEditingController? controller;

  /// [hint]: the prompt. [label]: its spoken name. [semanticHint]: what a screen reader hears after the name.
  final String? hint, label, semanticHint;

  /// Whether it takes input.
  final bool enabled;

  /// [onChanged]: told each edit. [onSubmitted]: told the keyboard's done.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// The keyboard the platform shows.
  final TextInputType? keyboardType;

  /// Filters applied to each edit.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the part asks for the focus when it first appears.
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
      label: label ?? hint,
      hint: semanticHint ?? (label == null ? null : hint),
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
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: style,
            cursorColor: _inputInk(c),
            contextMenuBuilder: ComicTextContextMenu.editable,
            selectionControls: ComicTextSelectionControls.of(
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

/// A password: the text field's frame with a show and hide control at its end that keeps the caret where it was. The
/// behaviour is the design kit's `DesignPasswordReveal`; with [hideOnBlur] a shown password hides again when focus
/// leaves.
///
/// ```dart
/// ComicPasswordField(label: 'Password', controller: password, onSubmitted: (_) => signIn())
/// ```
class ComicPasswordField extends StatefulWidget {
  /// Creates a [ComicPasswordField].
  const ComicPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
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

  /// [label]: its name, above the frame. [hint]: the placeholder. [helper]: the help under it. [error]: what is
  /// wrong, in the help's place.
  final String? label, hint, helper, error;

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

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  State<ComicPasswordField> createState() => _ComicPasswordFieldState();
}

class _ComicPasswordFieldState extends State<ComicPasswordField>
    with _OwnedFocus<ComicPasswordField> {
  @override
  FocusNode? get callerFocus => widget.focusNode;

  @override
  Widget build(BuildContext context) {
    return DesignPasswordReveal(
      focusNode: focus,
      hideOnBlur: widget.hideOnBlur,
      showLabel:
          widget.showLabel ?? DesignLocalizations.of(context).showPasswordLabel,
      hideLabel:
          widget.hideLabel ?? DesignLocalizations.of(context).hidePasswordLabel,
      builder: (context, password) => ComicTextField(
        autofocus: widget.autofocus,
        controller: widget.controller,
        focusNode: focus,
        label: widget.label,
        hint: widget.hint,
        helper: widget.helper,
        error: widget.error,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        keyboardType: TextInputType.visiblePassword,
        obscureText: password.obscured,
        trailing: Semantics(
          toggled: !password.obscured,
          child: ComicIconButton(
            password.obscured ? ComicGlyphs.show : ComicGlyphs.hide,
            style: comicInFieldIcon,
            label: password.toggleLabel,
            onPressed: widget.enabled ? password.toggle : null,
          ),
        ),
      ),
    );
  }
}

/// A field and its add-ons in one inked frame: a glyph or a unit before or after the words, a button at the end. The
/// frame lights while anything inside has focus, and a tap on it or a plain add-on puts the caret in the field (the
/// design kit's `DesignInputGroup`).
///
/// ```dart
/// ComicInputGroup(label: 'Weight', leading: const [Icon(ComicGlyphs.search)], trailing: const [Text('kg')], keyboardType: TextInputType.number)
/// ```
class ComicInputGroup extends StatefulWidget {
  /// Creates a [ComicInputGroup].
  const ComicInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
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

  /// [label]: its name, above the frame. [hint]: the placeholder. [helper]: the help under it. [error]: what is
  /// wrong, in the help's place.
  final String? label, hint, helper, error;

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

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  State<ComicInputGroup> createState() => _ComicInputGroupState();
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
      label: widget.label,
      helper: widget.helper,
      error: widget.error,
      child: DesignInputGroup(
        focusNode: focus,
        enabled: widget.enabled,
        isError: widget.error != null,
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
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ComicBareEditor(
                autofocus: widget.autofocus,
                focusNode: focus,
                controller: widget.controller,
                label: widget.label,
                hint: widget.hint,
                semanticHint: widget.error ?? widget.helper,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
              ),
            ),
            for (final part in widget.trailing) ...[
              const SizedBox(width: 10),
              addOn(part),
            ],
          ],
        ),
      ),
    );
  }
}

/// Several values chosen as tags in the text field's frame, with an editor after them that suggests more as you
/// type, on the menu's raised face. Enter takes the lit suggestion (or, with [onCreate], the typed words);
/// Backspace on an empty editor steps onto the tags, and Backspace or Delete removes one. The behaviour is the design
/// kit's `DesignTagInput`.
///
/// ```dart
/// ComicMultiSelect<String>(label: 'Genres', values: genres, options: const ['Noir', 'Western', 'Horror'], onChanged: (next) => setState(() => genres = next))
/// ```
class ComicMultiSelect<T extends Object> extends StatefulWidget {
  /// Creates a [ComicMultiSelect].
  const ComicMultiSelect({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.labelOf,
    this.onCreate,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.maxTags,
    this.focusNode,
    this.autofocus = false,
  });

  /// The chosen values, in order.
  final List<T> values;

  /// The new list after a tag is added or removed.
  final ValueChanged<List<T>> onChanged;

  /// What typing suggests (less what is chosen).
  final Iterable<T> options;

  /// Finds suggestions for the typed words, in place of filtering [options].
  final FutureOr<Iterable<T>> Function(String query)? search;

  /// A value's words; `toString` when null.
  final String Function(T value)? labelOf;

  /// Makes a value of typed words, or null to refuse them; null takes suggestions only.
  final T? Function(String text)? onCreate;

  /// [label]: its name, above the frame. [hint]: the placeholder while nothing is chosen. [helper]: the help under
  /// it. [error]: what is wrong, in the help's place.
  final String? label, hint, helper, error;

  /// Whether it takes input.
  final bool enabled;

  /// The most tags it takes; null for no limit.
  final int? maxTags;

  /// The editor's caller-owned focus.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  State<ComicMultiSelect<T>> createState() => _ComicMultiSelectState<T>();
}

class _ComicMultiSelectState<T extends Object>
    extends State<ComicMultiSelect<T>>
    with _OwnedFocus<ComicMultiSelect<T>> {
  @override
  FocusNode? get callerFocus => widget.focusNode;

  String _words(T value) => widget.labelOf?.call(value) ?? value.toString();

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final words = ComicLocalizations.of(context);
    final input = DesignTagInput<T>(
      values: widget.values,
      onChanged: widget.onChanged,
      options: widget.options,
      search: widget.search,
      displayStringForOption: _words,
      onCreate: widget.onCreate,
      maxTags: widget.maxTags,
      focusNode: focus,
      semanticLabel: widget.label,
      deleteLabel: words.delete,
      surfaceBuilder: (context, list) => ComicRaisedFrame(child: list),
      // Its options' words start on the field's .
      optionBuilder: (context, option, states) => ComicMenuRowFace(
        states: states,
        label: _words(option),
        start: comicFieldListWords(t),
      ),
      tagBuilder: (context, value, tag) => _ComicTag(
        label: _words(value),
        focused: tag.focused,
        onRemove: widget.enabled ? tag.onDeleted : null,
      ),
      // The editor spans the face, its words on the field's keyline, so the suggestions open from the face's leading
      // edge at its width (the list stands under the editor).
      fieldBuilder: (context, field) => Padding(
        padding: EdgeInsets.symmetric(horizontal: comicFieldWordsAt(t)),
        child: ComicBareEditor(
          focusNode: field.focusNode,
          autofocus: widget.autofocus,
          controller: field.controller,
          label: widget.label,
          hint: widget.values.isEmpty ? widget.hint : null,
          semanticHint: widget.error ?? widget.helper,
          enabled: widget.enabled,
          onSubmitted: (_) => field.submit(),
        ),
      ),
      layoutBuilder: (context, tags, field) => ListenableBuilder(
        listenable: focus,
        builder: (context, _) => _fieldFrame(
          context,
          {
            if (focus.hasFocus) WidgetState.focused,
            if (widget.error != null) WidgetState.error,
            if (!widget.enabled) WidgetState.disabled,
          },
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tags.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    comicFieldWordsAt(t),
                    8,
                    comicFieldWordsAt(t),
                    0,
                  ),
                  child: Wrap(spacing: 6, runSpacing: 6, children: tags),
                ),
              field,
            ],
          ),
          bleed: true,
        ),
      ),
    );
    // From 600 up the field keeps to its own width (at most 320) at its column's start.
    return comicDropdownWidth(
      context,
      _fieldColumn(
        t,
        label: widget.label,
        helper: widget.helper,
        error: widget.error,
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
  const _ComicTag({required this.label, required this.focused, this.onRemove});

  final String label;
  final bool focused;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final shape = t.shapes.small;
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
          padding: const EdgeInsetsDirectional.only(start: 10, end: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: t.type.text(
                  14,
                  1.2,
                  weight: FontWeight.w800,
                  color: c.onCaption,
                ),
              ),
              ExcludeSemantics(
                child: ExcludeFocus(
                  child: DesignPressable(
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

/// A span between two values on the slider's inked rail: two knobs that never cross, the stretch between them filled.
/// A press or a drag on the rail moves the nearer knob; each knob is its own labelled slider for the keyboard and a
/// screen reader (the design kit's `DesignRangeSlider`).
///
/// ```dart
/// ComicRangeSlider(label: 'Price', values: const DesignRangeValues(20, 80), max: 100, onChanged: (next) => setState(() => price = next))
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
  });

  /// Its name, above the rail.
  final String label;

  /// The span.
  final DesignRangeValues values;

  /// The new span; null disables it.
  final ValueChanged<DesignRangeValues>? onChanged;

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
    final look = ComicStyleOf(
      [t.sliderTheme],
      {if (!live) WidgetState.disabled},
    );
    final slider = DesignRangeSlider(
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
      thumbSize: const Size(2 * ComicSlider.inset, 44),
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
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(label, style: t.type.title),
                    ExcludeSemantics(
                      child: Text(
                        '${_words(values.start)} – ${_words(values.end)}',
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
}

/// The slider's knob: a caption-filled disc inked round, a size larger while it is dragged, ringed under the
/// keyboard's focus. For a design kit handle's builder.
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
    final rect = Offset.zero & size;
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
  return DateFormat.localeExists(locale) ? locale : 'en_US';
}

/// A month or two of the date picker's caption cells over a calendar the caller holds: one day, a span, or several
/// days, as the controller's mode says. Its days are the date picker's ([ComicDatePicker.dayWidth] square, a month at
/// most [ComicDatePicker.maxWidth] wide), and the days of the months either side stay blank, as the date picker's. A span's ends wear the caption fill and the days between the reader's tint.
/// The keys and the screen reader's grid are the design kit's `DesignCalendar` (arrows by day and week, Page Up and
/// Down by month, Home and End along the week).
///
/// ```dart
/// ComicCalendar(controller: DesignCalendarController(firstDate: DateTime(2026), lastDate: DateTime(2027)), onChanged: (day) => setState(() {}))
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
  final DesignCalendarController controller;

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
    final calendar = DesignCalendar(
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
            label: DesignLocalizations.of(context).previousMonthTooltip,
            onPressed: header.previous,
          ),
          Expanded(
            child: Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                header.label,
                style: t.type.title,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ComicIconButton(
            Directionality.of(context) == TextDirection.rtl
                ? ComicGlyphs.chevronLeft
                : ComicGlyphs.chevronRight,
            label: DesignLocalizations.of(context).nextMonthTooltip,
            onPressed: header.next,
          ),
        ],
      ),
      weekdayBuilder: (context, weekday, label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: t.type.small,
          ),
        ),
      ),
      monthsBuilder: (context, months) => Wrap(
        spacing: 24,
        runSpacing: 16,
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
      dayBuilder: (context, day, states) =>
          _CalendarDay(day: day, states: states),
    );
    return onChanged != null
        ? calendar
        : Opacity(
            opacity: .55,
            child: IgnorePointer(child: ExcludeFocus(child: calendar)),
          );
  }
}

/// One day of a [ComicCalendar]: the date picker's cell. A chosen day, or a span's end, wears the caption fill and a
/// heavy rim; a day inside the span the reader's tint; today a dot under its number. Every day reserves the heavy rim,
/// so a choice never moves the rows.
class _CalendarDay extends StatelessWidget {
  /// Creates a [_CalendarDay].
  const _CalendarDay({required this.day, required this.states});

  /// The day's facts.
  final DesignCalendarDay day;

  /// Its press states.
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final end = day.selected || day.isRangeStart || day.isRangeEnd;
    final between = !end && (day.inRange || day.inPreview);
    final rim = end
        ? BorderSide(color: c.nightLine, width: 2.5)
        : day.inMonth
        ? BorderSide(color: c.divider, width: 1)
        : BorderSide.none;
    final ink = end
        ? c.onCaption
        : day.inMonth
        ? c.text
        : c.textSecondary;
    final shape = t.shapes.small;
    return Opacity(
      opacity: day.enabled ? 1 : .45,
      child: ComicHighlight(
        states: states,
        shape: shape,
        // The cell is every day's face, whatever it draws: a plain day's faint rule cannot show it in pixels, and
        // ui_core's row check read a span's end inside its heavy rim, 2.5 px short of the days beside it.
        child: DesignKeylineFace(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: end
                  ? c.caption
                  : between
                  ? c.currentUserTint
                  : null,
              shape: shape.copyWith(side: rim),
            ),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: ComicDatePicker.dayWidth,
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.all(2.5 - rim.width + 4),
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
                        '${day.date.day}',
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
    );
  }
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
  final DesignDateRange? value;

  /// Hears a whole span; null disables it.
  final ValueChanged<DesignDateRange>? onChanged;

  /// How many months show side by side.
  final int months;

  /// Overrides the device's today.
  final DateTime? currentDate;

  /// The first column, Monday as 1.
  final int firstWeekday;

  @override
  State<ComicDateRangePicker> createState() => _ComicDateRangePickerState();
}

class _ComicDateRangePickerState extends State<ComicDateRangePicker> {
  late DesignCalendarController _calendar = _make();

  DesignCalendarController _make() => DesignCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: DesignCalendarMode.range,
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
        Semantics(liveRegion: true, child: Text(words, style: t.type.section)),
        const SizedBox(height: 8),
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
Future<DesignDateRange?> showComicDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DesignDateRange? value,
  DateTime? currentDate,
  String? title,
  String? confirm,
  String? cancel,
}) {
  var picked = value;
  return showComicDialog<DesignDateRange>(
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
            cancel ?? DesignLocalizations.of(context).cancelButtonLabel,
            onPressed: () => Navigator.pop(context),
          ),
          ComicButton.filled(
            confirm ?? ComicLocalizations.of(context).choose,
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

/// One value off a turning drum: the rows roll past a caption band that holds the chosen one. A drag or a fling turns
/// it, the arrows step it, and a screen reader hears it as an adjustable value.
///
/// ```dart
/// ComicWheelPicker<int>(label: 'Copies', values: const [1, 2, 3, 4, 5], value: copies, labelOf: (n) => '$n', onChanged: (n) => setState(() => copies = n))
/// ```
class ComicWheelPicker<T> extends StatefulWidget {
  /// Creates a [ComicWheelPicker]. Null [onChanged] disables it.
  const ComicWheelPicker({
    super.key,
    required this.label,
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
  final String label;

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

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  State<ComicWheelPicker<T>> createState() => _ComicWheelPickerState<T>();
}

class _ComicWheelPickerState<T> extends State<ComicWheelPicker<T>>
    with _OwnedFocus<ComicWheelPicker<T>> {
  @override
  FocusNode? get callerFocus => widget.focusNode;

  late final FixedExtentScrollController _wheel = FixedExtentScrollController(
    initialItem: math.max(0, widget.values.indexOf(widget.value)),
  );
  bool _focused = false, _hovered = false;

  int get _index => math.max(0, widget.values.indexOf(widget.value));

  @override
  void didUpdateWidget(ComicWheelPicker<T> old) {
    super.didUpdateWidget(old);
    if (_wheel.hasClients && _wheel.selectedItem != _index) {
      _wheel.jumpToItem(_index);
    }
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  void _step(int by) {
    final next = (_index + by).clamp(0, widget.values.length - 1);
    if (next == _index) return;
    widget.onChanged?.call(widget.values[next]);
  }

  KeyEventResult _keys(FocusNode node, KeyEvent event) {
    if (widget.onChanged == null ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _step(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _step(-1);
    } else if (key == LogicalKeyboardKey.home) {
      _step(-_index);
    } else if (key == LogicalKeyboardKey.end) {
      _step(widget.values.length - 1 - _index);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final live = widget.onChanged != null;
    final frame = t.shapes.medium;
    final band = t.shapes.small;
    final index = _index;
    final wheel = SizedBox(
      height: widget.itemExtent * widget.visible,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: widget.itemExtent,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: c.caption,
                    shape: band.copyWith(
                      side: BorderSide(color: c.nightLine, width: 2.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _wheel,
            itemExtent: widget.itemExtent,
            diameterRatio: 1.8,
            overAndUnderCenterOpacity: .6,
            physics: live
                ? const FixedExtentScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onSelectedItemChanged: live
                ? (i) {
                    if (i != _index) widget.onChanged!(widget.values[i]);
                  }
                : null,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.values.length,
              builder: (context, i) => Center(
                child: Text(
                  widget.labelOf(widget.values[i]),
                  maxLines: 1,
                  style: t.type.text(
                    18,
                    1.2,
                    weight: FontWeight.w800,
                    color: i == index ? c.onCaption : c.text,
                  ),
                ),
              ),
            ),
          ),
        ],
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
        child: _drum(live, index, frame, wheel),
      ),
    );
  }

  Widget _drum(bool live, int index, OutlinedBorder frame, Widget wheel) {
    final c = ComicTheme.of(context).colors;
    return Semantics(
      container: true,
      slider: true,
      label: widget.label,
      value: widget.labelOf(widget.value),
      enabled: live,
      increasedValue: live && index < widget.values.length - 1
          ? widget.labelOf(widget.values[index + 1])
          : null,
      decreasedValue: live && index > 0
          ? widget.labelOf(widget.values[index - 1])
          : null,
      onIncrease: live && index < widget.values.length - 1
          ? () => _step(1)
          : null,
      onDecrease: live && index > 0 ? () => _step(-1) : null,
      child: ExcludeSemantics(
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: _keys,
          child: FocusableActionDetector(
            autofocus: widget.autofocus,
            enabled: live,
            focusNode: focus,
            mouseCursor: live
                ? SystemMouseCursors.grab
                : SystemMouseCursors.basic,
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            onShowHoverHighlight: (value) => setState(() => _hovered = value),
            child: LimitedBox(
              maxWidth: 200,
              child: Opacity(
                opacity: live ? 1 : .5,
                child: ComicHighlight(
                  states: {
                    if (_focused) WidgetState.focused,
                    if (_hovered) WidgetState.hovered,
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
                        child: wheel,
                      ),
                    ),
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

/// A one-time code, one inked box a digit, with the platform's one-time-code autofill. A paste fills it, a long press or
/// a secondary click offers Paste, and a screen reader hears one field.
///
/// ```dart
/// ComicInputOtp(label: 'Verification code', length: 6, onCompleted: verify)
/// ```
class ComicInputOtp extends StatefulWidget {
  /// Creates a code input of [length] boxes.
  const ComicInputOtp({
    super.key,
    this.style,
    required this.label,
    this.length = 6,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.error,
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
  final String label;

  /// How many digits.
  final int length;

  /// Holds the digits, when the caller does.
  final TextEditingController? controller;

  /// Told each edit.
  final ValueChanged<String>? onChanged;

  /// Told the keyboard's done.
  final ValueChanged<String>? onSubmitted;

  /// What is wrong, under the boxes.
  final String? error;

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

  /// Per-state appearance above the component theme.
  final ComicStyle? style;

  @override
  State<ComicInputOtp> createState() => _ComicInputOtpState();
}

class _ComicInputOtpState extends State<ComicInputOtp> {
  late DesignOtpController _code = _make();

  DesignOtpController _make() =>
      DesignOtpController(length: widget.length, text: widget.controller);

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

  Widget _box(BuildContext context, DesignOtpSlot slot) {
    final t = ComicTheme.of(context), c = t.colors;
    final live = slot.active && slot.focused;
    final look = ComicStyleOf(
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
    return Opacity(
      opacity: slot.enabled ? 1 : .55,
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
    final field = DesignOtpField(
      controller: _code,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      isError: widget.error != null,
      semanticLabel: widget.label,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      contextMenuBuilder: (context, anchors, items) =>
          ComicTextContextMenu(anchors: anchors, buttonItems: items),
      layoutBuilder: (context, slots) => Row(
        children: [
          for (final (i, slot) in slots.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: slot),
          ],
        ],
      ),
      slotBuilder: _box,
    );
    return _fieldColumn(
      t,
      label: widget.label,
      error: widget.error,
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
