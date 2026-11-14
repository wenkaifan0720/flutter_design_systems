// Entry rows whose behaviour is ui_core's and whose every pixel is the look's: the password field, the input group,
// the combobox, the multi-select, the form row, the range slider and the colour picker.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart'
    show
        HSVColor,
        InputBorder,
        InputDecoration,
        Material,
        MaterialType,
        TextField,
        VisualDensity;
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'chrome_metrics.dart';
import 'controls.dart';
import 'component_themes.dart';
import 'editing.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'internal/cap_label.dart';
import 'internal/cell_bank.dart' show neumorphicWideRoom;
import 'internal/error_line.dart';
import 'internal/geometry.dart' show cssLinear;
import 'internal/panel.dart';
import 'internal/reach.dart';
import 'internal/text_entry.dart';
import 'knobs.dart';
import 'localizations.dart';
import 'shapes.dart';
import 'styled.dart';
import 'theme.dart';
import 'internal/out_of_use.dart';

/// A field's label above it: the words a text field draws, silent because the input speaks them itself.
class _Label extends StatelessWidget {
  const _Label(this.words, {this.lit = false});
  final String words;

  /// Whether its field has focus: it names itself in the pigment's ink, as a text field's label does.
  final bool lit;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ExcludeSemantics(
      child: Text(
        words,
        style: NeumorphicTheme.of(context).textTheme.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: lit ? NeumorphicTheme.of(context).colors.pigmentInk : null,
        ),
      ),
    ),
  );
}

/// A field's failure, or else its help, under it: the lines a text field draws.
class _Under extends StatelessWidget {
  const _Under({this.error, this.helper});
  final String? error, helper;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    if (error == null && helper == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: error == null
          ? Text(helper!, style: t.textTheme.caption)
          : NeumorphicErrorLine(child: Text(error!)),
    );
  }
}

/// [child] laid out [bleed] wider than its room on each side, over its parent's inset: its box, and so whatever is
/// anchored to it, spans the face around it.
class _Bleed extends SingleChildRenderObjectWidget {
  const _Bleed(this.bleed, {required super.child});

  final EdgeInsets bleed;

  @override
  _RenderBleed createRenderObject(BuildContext context) => _RenderBleed(bleed);

  @override
  void updateRenderObject(BuildContext context, _RenderBleed renderObject) {
    renderObject.bleed = bleed;
  }
}

class _RenderBleed extends RenderShiftedBox {
  _RenderBleed(this._bleed) : super(null);

  EdgeInsets _bleed;
  set bleed(EdgeInsets value) {
    if (value == _bleed) return;
    _bleed = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(0, super.computeMinIntrinsicWidth(height) - _bleed.horizontal);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(0, super.computeMaxIntrinsicWidth(height) - _bleed.horizontal);

  @override
  void performLayout() {
    final c = constraints;
    final child = this.child;
    if (child == null) {
      size = c.smallest;
      return;
    }
    final room = c.hasBoundedWidth ? c.maxWidth : c.minWidth;
    final wide = room + _bleed.horizontal;
    child.layout(
      BoxConstraints(
        minWidth: wide,
        maxWidth: wide,
        minHeight: c.minHeight,
        maxHeight: c.maxHeight,
      ),
      parentUsesSize: true,
    );
    size = c.constrain(Size(room, child.size.height));
    (child.parentData! as BoxParentData).offset = Offset(-_bleed.left, 0);
  }
}

/// The text a field holds, with no frame of its own: the one line a group's or a tag field's frame stands around.
class _BareEditor extends StatelessWidget {
  const _BareEditor({
    required this.controller,
    required this.focusNode,
    this.hint,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
    this.style,
    this.node = true,
  });

  /// Whether its seat is the field's semantics node; false where the node is a reach round the whole box.
  final bool node;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final look = NeumorphicStyleOf(
      [style, t.textFieldTheme],
      {if (!enabled) WidgetState.disabled},
    );
    final text = neumorphicEntryStyle(
      t.textTheme.body.merge(look.textStyle).copyWith(color: look.foreground),
    );
    // The frame around it is the group's or the tag field's; the seat is a target tall, its line centred.
    return NeumorphicEntrySeat(
      height: NeumorphicChromeMetrics.targetSize,
      focusNode: focusNode,
      enabled: enabled,
      label: semanticLabel,
      node: node,
      // One line, on the seat's middle by its capitals, as the text field's.
      child: neumorphicLabel(
        Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            style: text,
            cursorColor: t.colors.ink,
            cursorWidth: 1.5,
            selectionControls: NeumorphicTextSelectionControls.of(
              defaultTargetPlatform,
            ),
            contextMenuBuilder: NeumorphicTextContextMenu.editable,
            decoration: _bareDecoration(
              hint: hint,
              hintStyle: text.copyWith(
                color: look.foreground ?? t.colors.inkTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A password's field: the text field with its eye, hidden until asked, and autofill told what it holds.
///
/// ```dart
/// NeumorphicPasswordField(label: 'Password', onChanged: setPassword)
/// ```
class NeumorphicPasswordField extends StatelessWidget {
  /// Creates a [NeumorphicPasswordField].
  const NeumorphicPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.newPassword = false,
    this.style,
  });

  /// An optional caller-owned controller.
  final TextEditingController? controller;

  /// The words above the field, and its spoken name.
  final String? label;

  /// Placeholder words.
  final String? hint;

  /// Supporting words under the field.
  final String? helper;

  /// Validation words; non-null marks the field invalid.
  final String? error;

  /// Receives each edit.
  final ValueChanged<String>? onChanged;

  /// Receives the text when the keyboard submits it.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// An optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Whether it asks for focus when first shown.
  final bool autofocus;

  /// Whether the field takes input.
  final bool enabled;

  /// Whether this is a new password (autofill offers to make one) rather than the current one.
  final bool newPassword;

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) => NeumorphicTextField(
    controller: controller,
    label: label,
    hint: hint,
    helper: helper,
    error: error,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    textInputAction: textInputAction,
    focusNode: focusNode,
    autofocus: autofocus,
    enabled: enabled,
    obscureText: true,
    keyboardType: TextInputType.visiblePassword,
    autofillHints: [
      newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    style: style,
  );
}

/// A text field with add-ons joined to it in one groove: words before or after the value ("https://", ".com", "€"),
/// each behind an engraved line, and small parts at its ends. A press anywhere on the groove puts the caret in it, and
/// the whole groove rings while the field has focus.
///
/// ```dart
/// NeumorphicInputGroup(label: 'Website', prefix: 'https://', suffix: '.com', controller: site)
/// ```
class NeumorphicInputGroup extends StatefulWidget {
  /// Creates a [NeumorphicInputGroup].
  const NeumorphicInputGroup({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.prefix,
    this.suffix,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.error,
    this.helper,
    this.enabled = true,
    this.keyboardType,
    this.focusNode,
    this.style,
  });

  /// The words above the groove, and the field's spoken name.
  final String? label;

  /// An optional caller-owned controller.
  final TextEditingController? controller;

  /// Placeholder words.
  final String? hint;

  /// Words before the value.
  final String? prefix;

  /// Words after the value.
  final String? suffix;

  /// A glyph or small part at the groove's start.
  final Widget? leading;

  /// An act at the groove's end.
  final Widget? trailing;

  /// Receives each edit.
  final ValueChanged<String>? onChanged;

  /// Receives the text when the keyboard submits it.
  final ValueChanged<String>? onSubmitted;

  /// Validation words; non-null marks the field invalid.
  final String? error;

  /// Supporting words under the groove.
  final String? helper;

  /// Whether the field takes input.
  final bool enabled;

  /// The keyboard the platform shows.
  final TextInputType? keyboardType;

  /// An optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  @override
  State<NeumorphicInputGroup> createState() => _NeumorphicInputGroupState();
}

class _NeumorphicInputGroupState extends State<NeumorphicInputGroup> {
  TextEditingController? _ownText;
  FocusNode? _ownFocus;

  TextEditingController get _text =>
      widget.controller ?? (_ownText ??= TextEditingController());
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'InputGroup'));

  @override
  void dispose() {
    _ownText?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final flat = NeumorphicFlatScope.of(context);
    final shape = t.shapes.corner(NeumorphicRadii.control);
    // An add-on gives up width before the editor does: its words are cut rather than run past the groove.
    Widget addOn(String words, double most) => ExcludeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: most),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            widthFactor: 1,
            child: Text(
              words,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              // The fixed words are part of the value, in the secondary ink: in the hint's own grey they read as a hint.
              style: t.textTheme.body.copyWith(color: c.inkSecondary),
            ),
          ),
        ),
      ),
    );
    final line = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 1,
            child: ColoredBox(color: flat ? c.quiet : c.crease),
          ),
          if (!flat) SizedBox(width: 1, child: ColoredBox(color: c.rim)),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ListenableBuilder(
            listenable: _focus,
            builder: (context, _) =>
                _Label(widget.label!, lit: _focus.hasFocus),
          ),
        // The face keeps the density's height and the reach round it the platform's target, as a text field's: the
        // reach is the field's one node, and a press in it off the face reaches the line (in a 40-tall face the seat
        // alone was a 40-tall target).
        Semantics(
          container: true,
          label: [
            widget.label,
            widget.prefix,
            widget.suffix,
          ].whereType<String>().join(', '),
          child: NeumorphicReach(
            height: NeumorphicChromeMetrics.targetSize,
            child: DesignInputGroup(
              focusNode: _focus,
              enabled: widget.enabled,
              isError: widget.error != null,
              builder: (context, states, child) => NeumorphicOutOfUse(
                off: !widget.enabled,
                child: NeumorphicFieldBox(
                  style: widget.style,
                  states: states,
                  shape: shape,
                  padding: EdgeInsets.zero,
                  child: child,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  // The add-ons keep their whole words while the editor keeps 80 px; narrower, the shorter keeps its whole
                  // words if they fit in half of what is left, and the longer takes the rest: shared in the measure of
                  // their words, twice the text cut both (http… and .c…).
                  double natural(String? words) {
                    if (words == null) return 0;
                    final painter = TextPainter(
                      text: TextSpan(text: words, style: t.textTheme.body),
                      textDirection: TextDirection.ltr,
                      textScaler: MediaQuery.textScalerOf(context),
                      maxLines: 1,
                    )..layout();
                    final w = painter.width + 24;
                    painter.dispose();
                    return w;
                  }

                  final wants = (
                    natural(widget.prefix),
                    natural(widget.suffix),
                  );
                  final room = box.maxWidth - 108;
                  double most(double want) {
                    if (!box.hasBoundedWidth || wants.$1 + wants.$2 <= room) {
                      return double.infinity;
                    }
                    final other = want == wants.$1 ? wants.$2 : wants.$1;
                    final whole = math.min(want, other) <= room / 2
                        ? math.min(want, other)
                        : room / 2;
                    // This one is the shorter (or the two are equal): its whole words, or half.
                    if (want <= other) return math.max(48.0, whole);
                    return math.max(48.0, room - whole);
                  }

                  // A text field's height: the density's control, or a line and its floor when the words are larger. Its
                  // own editor's intrinsic height stood the group 54 tall among 40-tall fields.
                  final control = math.max(
                    t.density.height(48),
                    neumorphicLineHeight(context, t.textTheme.body) + 16,
                  );
                  // A link, an address or a number is written left to right in any page, its add-ons with it: set in a
                  // right-to-left page's direction, https:// your-home .com read ".com your-home //:https".
                  final leftToRight = const [
                    TextInputType.number,
                    TextInputType.phone,
                    TextInputType.datetime,
                    TextInputType.emailAddress,
                    TextInputType.url,
                  ].any((kind) => kind.index == widget.keyboardType?.index);
                  final group = SizedBox(
                    height: control,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.prefix != null) ...[
                          addOn(widget.prefix!, most(wants.$1)),
                          line,
                        ],
                        if (widget.leading != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 12,
                            ),
                            child: Center(child: widget.leading),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: _BareEditor(
                                controller: _text,
                                focusNode: _focus,
                                hint: widget.hint,
                                enabled: widget.enabled,
                                keyboardType: widget.keyboardType,
                                onChanged: widget.onChanged,
                                onSubmitted: widget.onSubmitted,
                                style: widget.style,
                                node: false,
                                semanticLabel: [
                                  widget.label,
                                  widget.prefix,
                                  widget.suffix,
                                ].whereType<String>().join(', '),
                              ),
                            ),
                          ),
                        ),
                        if (widget.trailing != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: Center(child: widget.trailing),
                          ),
                        if (widget.suffix != null) ...[
                          line,
                          addOn(widget.suffix!, most(wants.$2)),
                        ],
                      ],
                    ),
                  );
                  return leftToRight
                      ? Directionality(
                          textDirection: TextDirection.ltr,
                          child: group,
                        )
                      : group;
                },
              ),
            ),
          ),
        ),
        _Under(error: widget.error, helper: widget.helper),
      ],
    );
  }
}

/// A text field that suggests as one types and keeps one of [options]: the look's menu rises under it with the matches,
/// arrows move the pressed-in row, Enter takes it. With [requireSelection] words that match nothing go back to the last
/// choice when focus leaves.
///
/// ```dart
/// NeumorphicCombobox<String>(label: 'Town', options: towns, onSelected: setTown)
/// ```
class NeumorphicCombobox<T extends Object> extends StatelessWidget {
  /// Creates a [NeumorphicCombobox].
  const NeumorphicCombobox({
    super.key,
    required this.options,
    this.label,
    this.hint,
    this.value,
    this.onSelected,
    this.displayString,
    this.requireSelection = false,
    this.error,
    this.helper,
    this.enabled = true,
    this.style,
  });

  /// Everything it may suggest.
  final List<T> options;

  /// The words above the field, and its spoken name.
  final String? label;

  /// Placeholder words.
  final String? hint;

  /// The current choice.
  final T? value;

  /// Receives a choice.
  final ValueChanged<T>? onSelected;

  /// An option's words; `toString` by default.
  final String Function(T option)? displayString;

  /// Whether the field must hold one of [options] when focus leaves it.
  final bool requireSelection;

  /// Validation words; non-null marks the field invalid.
  final String? error;

  /// Supporting words under the field.
  final String? helper;

  /// Whether the field takes input.
  final bool enabled;

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final words = displayString ?? (T option) => option.toString();
    final t = NeumorphicTheme.of(context);
    // Its open list starts its options' words where the field starts its value.
    final list = neumorphicFieldPanelInsets(context);
    // The list hangs from the groove, so the label and the words under it stand outside what it is anchored to.
    return neumorphicWideRoom(
      AlignmentDirectional.centerStart,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) _Label(label!),
          DesignCombobox<T>(
            options: options,
            value: value,
            onSelected: onSelected,
            displayStringForOption: words,
            requireSelection: requireSelection,
            semanticLabel: label,
            fieldBuilder: (context, field) => NeumorphicTextField(
              label: label,
              nameOnly: true,
              hint: hint,
              // The groove shows the failure; its line is drawn under the field, below.
              error: error,
              failureLine: (_) => const SizedBox.shrink(),
              enabled: enabled,
              style: style,
              controller: field.controller,
              focusNode: field.focusNode,
              onSubmitted: (_) => field.submit(),
              trailing: ExcludeSemantics(
                child: Icon(
                  NeumorphicGlyphs.chevronsUpDown,
                  size: 18,
                  color: t.colors.inkTertiary,
                ),
              ),
            ),
            optionBuilder: (context, option, states) => NeumorphicPanelRow(
              label: words(option),
              states: states,
              checked: states.contains(WidgetState.selected),
              inset: list.row,
              panelInset: list.panel,
              checkAtEnd: true,
            ),
            surfaceBuilder: (context, rows) => NeumorphicPanel(
              padding: EdgeInsets.all(list.panel),
              child: rows,
            ),
            emptyBuilder: (context) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                NeumorphicLocalizations.of(context).noResults,
                style: t.textTheme.caption,
              ),
            ),
          ),
          _Under(error: error, helper: helper),
        ],
      ),
    );
  }
}

/// Several choices in one groove, each a chip with its own ✕: type to find more among [options] (or, with [onCreate], to
/// add new ones), Backspace on an empty field takes the last chip, the arrows walk the chips.
///
/// ```dart
/// NeumorphicMultiSelect<String>(label: 'Guests', values: guests, onChanged: setGuests, options: people)
/// ```
class NeumorphicMultiSelect<T extends Object> extends StatefulWidget {
  /// Creates a [NeumorphicMultiSelect].
  const NeumorphicMultiSelect({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.label,
    this.hint,
    this.displayString,
    this.onCreate,
    this.maxTags,
    this.error,
    this.helper,
    this.style,
  });

  /// The chosen values, in order.
  final List<T> values;

  /// Receives the new list.
  final ValueChanged<List<T>> onChanged;

  /// What it may suggest.
  final List<T> options;

  /// The words above the groove, and its spoken name.
  final String? label;

  /// Placeholder words.
  final String? hint;

  /// A value's words; `toString` by default.
  final String Function(T value)? displayString;

  /// Makes a value from typed words (Enter or a comma); null allows only [options].
  final T? Function(String text)? onCreate;

  /// The most it holds.
  final int? maxTags;

  /// Validation words; non-null marks the field invalid.
  final String? error;

  /// Supporting words under the groove.
  final String? helper;

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  @override
  State<NeumorphicMultiSelect<T>> createState() =>
      _NeumorphicMultiSelectState<T>();
}

class _NeumorphicMultiSelectState<T extends Object>
    extends State<NeumorphicMultiSelect<T>> {
  // The field's well deepens while its editor has the keys; a chip with the keys lifts itself, so one thing at a time
  // shows focus.
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // Its open list starts its options' words where the field starts its value.
    final list = neumorphicFieldPanelInsets(context);
    final local = NeumorphicLocalizations.of(context);
    final words = widget.displayString ?? (T value) => value.toString();
    final shape = t.shapes.corner(NeumorphicRadii.well);
    // The groove's own inset (its shape's dimensions): the words line bleeds over it, so the list it opens starts on
    // the groove's leading edge and is the groove's width.
    final bleed = shape.dimensions.resolve(Directionality.of(context));
    return neumorphicWideRoom(
      AlignmentDirectional.centerStart,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label != null) _Label(widget.label!),
          DesignTagInput<T>(
            values: widget.values,
            onChanged: widget.onChanged,
            options: widget.options,
            displayStringForOption: words,
            onCreate: widget.onCreate,
            maxTags: widget.maxTags,
            semanticLabel: widget.label,
            deleteLabel: local.remove('').trim(),
            fieldBuilder: (context, field) => Focus(
              canRequestFocus: false,
              skipTraversal: true,
              includeSemantics: false,
              onFocusChange: (on) => setState(() => _editing = on),
              // The words line spans the groove (its list opens from the groove's leading edge, as wide as it); the
              // words keep the groove's inset inside it.
              child: Padding(
                padding: EdgeInsets.only(
                  left: 10 + bleed.left,
                  right: 10 + bleed.right,
                ),
                child: _BareEditor(
                  controller: field.controller,
                  focusNode: field.focusNode,
                  // The hint stays under the chips: without it the words line read as an empty well under them.
                  hint: widget.hint,
                  onSubmitted: (_) => field.submit(),
                  style: widget.style,
                  semanticLabel: widget.label ?? widget.hint,
                ),
              ),
            ),
            layoutBuilder: (context, tags, field) => NeumorphicFieldBox(
              style: widget.style,
              multiline: true,
              shape: shape,
              states: {
                if (_editing) WidgetState.focused,
                if (widget.error != null) WidgetState.error,
              },
              padding: const EdgeInsets.symmetric(vertical: 6),
              // The chips start where the words of any field start, on their own lines over the words line.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tags.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: tags,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  _Bleed(bleed, child: field),
                ],
              ),
            ),
            tagBuilder: (context, value, tag) {
              final chip = NeumorphicChip(
                words(value),
                dense: true,
                onDeleted: tag.onDeleted,
                deleteLabel: local.remove(words(value)),
              );
              if (!tag.focused) return chip;
              return CustomPaint(
                foregroundPainter: neumorphicFocusLift(t, t.shapes.capsule),
                child: chip,
              );
            },
            optionBuilder: (context, option, states) => NeumorphicPanelRow(
              label: words(option),
              states: states,
              checked: widget.values.contains(option),
              inset: list.row,
              panelInset: list.panel,
              checkAtEnd: true,
            ),
            surfaceBuilder: (context, rows) => NeumorphicPanel(
              padding: EdgeInsets.all(list.panel),
              child: rows,
            ),
          ),
          _Under(error: widget.error, helper: widget.helper),
        ],
      ),
    );
  }
}

/// A form row around any control: its label (with a required mark), the control, and its help or failure under it. The
/// control speaks the label, help and failure itself; the drawn words are silent. In a `DesignForm`, a `DesignFormField`
/// validates it and the form focuses the first wrong field on submit.
///
/// ```dart
/// NeumorphicFormField(label: 'Email', help: 'The receipt goes here', required: true, child: NeumorphicTextField(controller: email))
/// ```
class NeumorphicFormField extends StatelessWidget {
  /// Creates a [NeumorphicFormField].
  const NeumorphicFormField({
    super.key,
    required this.child,
    this.label,
    this.help,
    this.error,
    this.required = false,
    this.enabled = true,
  });

  /// The control.
  final Widget child;

  /// The words above it.
  final String? label;

  /// Supporting words under it.
  final String? help;

  /// Validation words; they replace the help.
  final String? error;

  /// Whether it must be filled: a mark after the label, "required" spoken.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    return DesignField(
      labelText: label,
      helperText: help,
      errorText: error,
      required: required,
      enabled: enabled,
      requiredHint: NeumorphicLocalizations.of(context).requiredField,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.labelText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DefaultTextStyle.merge(
                style: t.textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: parts.enabled ? c.ink : c.inkTertiary,
                ),
                child: Row(
                  children: [
                    Flexible(child: parts.label ?? Text(parts.labelText!)),
                    if (parts.required)
                      ExcludeSemantics(
                        child: Text(
                          ' *',
                          style: t.textTheme.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: c.pigmentInk,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          parts.control,
          if (parts.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: NeumorphicErrorLine(
                live: false,
                child: parts.error ?? Text(parts.errorText!),
              ),
            )
          else if (parts.helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DefaultTextStyle.merge(
                style: t.textTheme.caption,
                child: parts.helper ?? Text(parts.helperText!),
              ),
            ),
        ],
      ),
      child: child,
    );
  }
}

/// How far the kit sets a slider's track in from each side: half its thumb's 44 target, so a thumb's centre reaches
/// each end. A plain slider's groove runs to the column's edges with its thumb kept inside; a range's and a colour
/// strip's stopped this far short of the words above them.
const double _thumbReach = 22;

/// [track] run on by [_thumbReach] past each end of the room the kit gives it, to the column's edges.
Widget _reachingEdges(Widget track) => LayoutBuilder(
  builder: (context, box) => OverflowBox(
    fit: OverflowBoxFit.deferToChild,
    minWidth: box.maxWidth + 2 * _thumbReach,
    maxWidth: box.maxWidth + 2 * _thumbReach,
    child: track,
  ),
);

/// A raised round handle, as the slider's thumb is (a colour's carries its colour as a point); it presses in while held.
class _Handle extends StatelessWidget {
  const _Handle({required this.states, this.size = 26, this.point});
  final Set<WidgetState> states;
  final double size;

  /// The colour point on the handle (a colour picker's); null: a plain thumb.
  final Color? point;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final circle = t.shapes.circle(size);
    final off = states.contains(WidgetState.disabled);
    return Center(
      child: CustomPaint(
        foregroundPainter: states.contains(WidgetState.focused)
            ? neumorphicFocusLift(t, circle)
            : null,
        child: SizedBox.square(
          dimension: size,
          // Half a key's relief, as a slider's thumb has: a key's light cast reached over the fill beside it and
          // faded the pigment out short of the handle.
          child: NeumorphicTheme(
            data: t.copyWith(
              elevation: t.elevation.copyWith(depth: t.elevation.depth * .5),
            ),
            child: NeumorphicSurface(
              cast: NeumorphicSurfaceLevel.part,
              round: true,
              shape: circle,
              outlined: true,
              depression: states.contains(WidgetState.pressed) ? .6 : 0,
              // A plain thumb, as a slider's: the pigment point on a range's handles made two sliders of one kind
              // look apart. Only a colour's handle carries a point, the colour it stands on.
              child: point == null
                  ? const SizedBox.shrink()
                  : Center(
                      child: SizedBox.square(
                        dimension: size * .27,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: off ? c.inkTertiary : point,
                            shape: t.shapes.circle(size * .27),
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

/// Two handles in one groove, choosing a span (a price from and to, nights from and to): the span between them is filled
/// with the pigment, and each handle takes the arrows on its own.
///
/// ```dart
/// NeumorphicRangeSlider(label: 'Price', values: const DesignRangeValues(60, 140), max: 300, onChanged: setPrice)
/// ```
class NeumorphicRangeSlider extends StatelessWidget {
  /// Creates a [NeumorphicRangeSlider].
  const NeumorphicRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.label,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minGap = 0,
    this.valueLabel,
    this.style,
  });

  /// The span's two ends.
  final DesignRangeValues values;

  /// Receives the new span; null puts it out of use.
  final ValueChanged<DesignRangeValues>? onChanged;

  /// The words above it, with the span's ends beside them.
  final String? label;

  /// The scale's ends.
  final double min, max;

  /// The steps the handles stop on.
  final int? divisions;

  /// The least the two ends may part by.
  final double minGap;

  /// An end's words; the number by default.
  final String Function(double value)? valueLabel;

  /// Visual overrides before the slider theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final local = NeumorphicLocalizations.of(context);
    String say(double v) => valueLabel?.call(v) ?? local.formatNumber(v);
    final live = onChanged != null;
    return NeumorphicOutOfUse(
      off: !live,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            ExcludeSemantics(
              child: Row(
                children: [
                  Expanded(child: Text(label!, style: t.textTheme.body)),
                  Text(
                    '${say(values.start)} – ${say(values.end)}',
                    style: t.textTheme.caption.tabular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: t.colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          DesignRangeSlider(
            values: values,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: divisions,
            minGap: minGap,
            semanticFormatterCallback: say,
            startLabel: label == null
                ? local.minimum
                : '$label, ${local.minimum}',
            endLabel: label == null
                ? local.maximum
                : '$label, ${local.maximum}',
            trackBuilder: (context, track) => _reachingEdges(
              SizedBox(
                height: 8,
                child: CustomPaint(
                  painter: _RangeTrack(
                    colors: t.colors,
                    elevation: t.elevation,
                    border: t.shapes.capsule,
                    start: track.start,
                    end: track.end,
                    flat: NeumorphicFlatScope.of(context),
                    direction: Directionality.of(context),
                  ),
                ),
              ),
            ),
            thumbBuilder: (context, index, states) => _Handle(states: states),
          ),
        ],
      ),
    );
  }
}

class _RangeTrack extends CustomPainter {
  const _RangeTrack({
    required this.colors,
    required this.elevation,
    required this.border,
    required this.start,
    required this.end,
    required this.flat,
    required this.direction,
  });
  final NeumorphicColors colors;
  final NeumorphicElevation elevation;
  final OutlinedBorder border;
  final double start, end;
  final bool flat;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = border.getOuterPath(
      (Offset.zero & size).deflate(.75),
      textDirection: direction,
    );
    // By night the narrow groove's floor takes a shade of the quiet ink (the slider's does): its shadow alone vanished
    // on the dark wall.
    final floor = Color.lerp(colors.ground, colors.inkTertiary, .22)!;
    neumorphicPaintPressed(
      canvas,
      shape,
      colors,
      light: (const Offset(-1, -1), 2),
      dark: (const Offset(1, 1), 2),
      face: colors.dark
          ? cssLinear(Offset.zero & size, 90, [floor, floor])
          : null,
      flat: flat,
      elevation: elevation,
    );
    // The groove runs to the column's edges; its fill still ends at the handles' centres, a reach in from each end.
    final rtl = direction == TextDirection.rtl;
    final run = math.max(0.0, size.width - 2 * _thumbReach);
    final a = _thumbReach + run * (rtl ? 1 - end : start);
    final b = _thumbReach + run * (rtl ? 1 - start : end);
    if (b - a <= 0) return;
    // The span is the groove's floor between the handles, under the groove's own shade in the pigment's tones: laid
    // over the groove, it stood fuller than the groove beside it.
    final span = Rect.fromLTRB(a, 0, b, size.height);
    canvas.save();
    canvas.clipRect(span);
    neumorphicPaintPressed(
      canvas,
      shape,
      colors,
      light: (const Offset(-1, -1), 2),
      dark: (const Offset(1, 1), 2),
      tone: colors.pigment,
      face: cssLinear(span, 90, [colors.pigment, colors.pigment]),
      flat: flat,
      elevation: elevation,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RangeTrack o) =>
      o.colors != colors ||
      o.elevation != elevation ||
      o.border != border ||
      o.start != start ||
      o.end != end ||
      o.flat != flat ||
      o.direction != direction;
}

/// A colour chosen on a saturation and brightness field and a hue strip (and an opacity strip with [showAlpha]), with
/// its hex beside a swatch. Every handle takes the arrows.
///
/// ```dart
/// NeumorphicColorPicker(controller: colour)
/// ```
class NeumorphicColorPicker extends StatelessWidget {
  /// Creates a [NeumorphicColorPicker].
  const NeumorphicColorPicker({
    super.key,
    required this.controller,
    this.showAlpha = false,
    this.label,
  });

  /// The colour, with its hex.
  final DesignColorController controller;

  /// Whether an opacity strip shows.
  final bool showAlpha;

  /// The picker's heading.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final area = t.shapes.corner(NeumorphicRadii.well);
    final strip = t.shapes.capsule;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) _Label(label!),
        DesignColorPicker(
          controller: controller,
          showAlpha: showAlpha,
          areaHeight: 180,
          areaBuilder: (context, a) => NeumorphicSurface(
            cast: NeumorphicSurfaceLevel.well,
            shape: area,
            padding: const EdgeInsets.all(4),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: NeumorphicShapes.inset(area, 4),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFFFFF),
                      HSVColor.fromAHSV(1, a.color.hue, 1, 1).toColor(),
                    ],
                  ),
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xFF000000)],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
          areaThumbBuilder: (context, a) =>
              _Handle(states: a.states, size: 22, point: a.color.toColor()),
          // The strip's colours lie in its groove, not as the groove's content: a capsule keeps content clear of its
          // curve by its radius, which is more than a 12 px strip's height, and the colours vanished in every family
          // but square.
          // The groove runs to the column's edges, as a slider's does; its colours run from start to end as the
          // handle does (right to left, the handle's hue sat over the mirrored one), each stop under the handle's
          // centre at its value.
          trackBuilder: (context, channel, colour) => _reachingEdges(
            SizedBox(
              height: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NeumorphicSurface(
                    cast: NeumorphicSurfaceLevel.groove,
                    shape: strip,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: NeumorphicShapes.inset(strip, 2),
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final shown = box.maxWidth;
                          final run = shown + 4 - 2 * _thumbReach;
                          double at(double f) => shown <= 0 || run <= 0
                              ? f
                              : ((_thumbReach - 2 + f * run) / shown).clamp(
                                  0.0,
                                  1.0,
                                );
                          final colours = channel == DesignColorChannel.alpha
                              ? [
                                  colour.withAlpha(0).toColor(),
                                  colour.withAlpha(1).toColor(),
                                ]
                              : [
                                  for (var h = 0; h <= 360; h += 60)
                                    HSVColor.fromAHSV(
                                      1,
                                      h.toDouble(),
                                      1,
                                      1,
                                    ).toColor(),
                                ];
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: AlignmentDirectional.centerStart,
                                end: AlignmentDirectional.centerEnd,
                                colors: colours,
                                stops: [
                                  for (var i = 0; i < colours.length; i++)
                                    at(i / (colours.length - 1)),
                                ],
                              ),
                            ),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          thumbBuilder: (context, states) => _Handle(states: states, size: 24),
          layoutBuilder: (context, parts) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, part) in parts.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                part,
              ],
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Row(
                  children: [
                    SizedBox.square(
                      dimension: 32,
                      child: NeumorphicSurface(
                        cast: NeumorphicSurfaceLevel.groove,
                        shape: t.shapes.corner(NeumorphicRadii.cap),
                        padding: const EdgeInsets.all(3),
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: controller.color,
                            shape: t.shapes.corner(NeumorphicRadii.cap - 3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        // ui_core's hex carries its own '#'; a code is written left to right in any page (B5624C#).
                        controller.hex,
                        textDirection: TextDirection.ltr,
                        style: t.textTheme.body.tabular.copyWith(color: c.ink),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A collapsed decoration with every field that could size or draw it set here, so no theme default reaches it: no
/// padding, no borders, no fill, standard density and no constraints (an unset one takes the theme's). It carries
/// the hint only, [hint] or a [hintWidget]; icons, buttons, counters, help and error are the look's own widgets
/// beside or under the box.
InputDecoration _bareDecoration({
  String? hint,
  Widget? hintWidget,
  TextStyle? hintStyle,
}) => InputDecoration(
  isCollapsed: true,
  isDense: false,
  contentPadding: EdgeInsets.zero,
  hintText: hintWidget == null ? hint : null,
  hint: hintWidget,
  hintStyle: hintStyle,
  hintMaxLines: 1,
  filled: false,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  visualDensity: VisualDensity.standard,
  constraints: const BoxConstraints(),
);
