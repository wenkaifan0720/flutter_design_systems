// Entry rows whose behaviour is ui_core's and whose every pixel is the look's: the password field, the input group,
// the combobox, the multi-select, the form row, the range slider and the colour picker.
import 'package:flutter/foundation.dart';

import 'dart:math' as math;

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

import 'actions.dart' show NeumorphicButtonGroup, NeumorphicToggleGroup;
import 'chrome_metrics.dart';
import 'controls.dart';
import 'component_themes.dart';
import 'editing.dart';
import 'entries.dart' show NeumorphicRadioGroup, NeumorphicSegmentedButton;
import 'frames.dart';
import 'glyphs.dart';
import 'internal/cap_label.dart';
import 'internal/cell_bank.dart' show neumorphicWideRoom;
import 'internal/error_line.dart';
import 'internal/field_hooks.dart';
import 'internal/geometry.dart' show cssLinear;
import 'internal/field_list.dart' show NeumorphicFieldListOwner;
import 'internal/panel.dart';
import 'internal/reach.dart';
import 'internal/text_entry.dart';
import 'knobs.dart';
import 'localizations.dart';
import 'shapes.dart';
import 'tell.dart' show NeumorphicCircularProgressIndicator;
import 'theme.dart';
import 'internal/out_of_use.dart';
import 'internal/moulded.dart';

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
/// The help or the error under a field whose node says them (ui_core's decorator put them there): drawn out of the
/// tree, but for the error where the platform takes no announcements, which stays a live region, as the decorator's
/// own line does.
class _Under extends StatelessWidget {
  const _Under({this.error, this.helper});
  final String? error, helper;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final error = this.error;
    final helper = this.helper;
    if (error == null && helper == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: error == null
          ? ExcludeSemantics(child: Text(helper!, style: t.textTheme.caption))
          : MediaQuery.supportsAnnounceOf(context)
          ? ExcludeSemantics(
              child: NeumorphicErrorLine(live: false, child: Text(error)),
            )
          : NeumorphicErrorLine(child: Text(error)),
    );
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
    this.onEditingComplete,
    this.semanticLabel,
    this.style,
    this.node = true,
    this.expanded,
  });

  /// Whether its seat is the field's semantics node; false where the node is a reach round the whole box.
  final bool node;

  /// Whether the list the field opens is showing; null for a field that opens none.
  final bool? expanded;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Enter in a field that keeps the focus after it (never with [onSubmitted]).
  final VoidCallback? onEditingComplete;
  final String? semanticLabel;
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final look = neumorphicStyleOf(
      [style, t.textFieldTheme],
      {if (!enabled) WidgetState.disabled},
    );
    final text = neumorphicEntryStyle(
      t.textTheme.body.merge(look.textStyle).copyWith(color: look.foreground),
    );
    // The frame around it is the group's or the tag field's; the seat is a target tall, its line centred.
    return NeumorphicEntrySeat(
      height: NeumorphicChromeMetrics.targetOf(context).height,
      focusNode: focusNode,
      enabled: enabled,
      label: semanticLabel,
      node: node,
      expanded: expanded,
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
            onEditingComplete: onEditingComplete,
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
/// NeumorphicPasswordField(labelText: 'Password', onChanged: setPassword)
/// ```
class NeumorphicPasswordField extends StatelessWidget {
  /// Creates a [NeumorphicPasswordField].
  const NeumorphicPasswordField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
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
  final String? labelText;

  /// Placeholder words.
  final String? hintText;

  /// Supporting words under the field.
  final String? helperText;

  /// Validation words; non-null marks the field invalid.
  final String? errorText;

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
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
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
        EnumProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
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
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
      )
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true))
      ..add(
        DiagnosticsProperty<bool>(
          'newPassword',
          newPassword,
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

/// A text field with add-ons joined to it in one groove: words before or after the value ("https://", ".com", "€"),
/// each behind an engraved line, and small parts at its ends. A press anywhere on the groove puts the caret in it, and
/// the whole groove rings while the field has focus.
///
/// ```dart
/// NeumorphicInputGroup(labelText: 'Website', prefix: 'https://', suffix: '.com', controller: site)
/// ```
class NeumorphicInputGroup extends StatefulWidget {
  /// Creates a [NeumorphicInputGroup].
  const NeumorphicInputGroup({
    super.key,
    this.labelText,
    this.controller,
    this.hintText,
    this.prefix,
    this.suffix,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.keyboardType,
    this.focusNode,
    this.style,
  });

  /// The words above the groove, and the field's spoken name.
  final String? labelText;

  /// An optional caller-owned controller.
  final TextEditingController? controller;

  /// Placeholder words.
  final String? hintText;

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
  final String? errorText;

  /// Supporting words under the groove.
  final String? helperText;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('prefix', prefix, defaultValue: null))
      ..add(StringProperty('suffix', suffix, defaultValue: null))
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
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
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
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
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
        if (widget.labelText != null)
          ListenableBuilder(
            listenable: _focus,
            builder: (context, _) =>
                _Label(widget.labelText!, lit: _focus.hasFocus),
          ),
        // The face keeps the density's height and the reach round it the platform's target, as a text field's: the
        // reach is the field's one node, and a press in it off the face reaches the line (in a 40-tall face the seat
        // alone would be a 40-tall target).
        // The help and the error join the group's node, from ui_core's decorator; the lines are drawn under the field.
        RawInputDecorator(
          helperText: widget.helperText,
          errorText: widget.errorText,
          enabled: widget.enabled,
          focusNode: _focus,
          builder: (context, parts) => parts.control,
          child: Semantics(
            container: true,
            label: [
              widget.labelText,
              widget.prefix,
              widget.suffix,
            ].whereType<String>().join(', '),
            child: NeumorphicReach(
              height: NeumorphicChromeMetrics.targetOf(context).height,
              child: RawInputGroup(
                focusNode: _focus,
                enabled: widget.enabled,
                isError: widget.errorText != null,
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
                      final floor = NeumorphicChromeMetrics.targetOf(context)
                          .width;
                      if (want <= other) return math.max(floor, whole);
                      return math.max(floor, room - whole);
                    }

                    // A text field's height: the density's control, or a line and its floor when the words are larger. Its
                    // own editor's intrinsic height would stand the group 54 tall among 40-tall fields.
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Center(
                                child: _BareEditor(
                                  controller: _text,
                                  focusNode: _focus,
                                  hint: widget.hintText,
                                  enabled: widget.enabled,
                                  keyboardType: widget.keyboardType,
                                  onChanged: widget.onChanged,
                                  onSubmitted: widget.onSubmitted,
                                  style: widget.style,
                                  node: false,
                                  semanticLabel: [
                                    widget.labelText,
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
        ),
        _Under(error: widget.errorText, helper: widget.helperText),
      ],
    );
  }
}

/// A text field that suggests as one types and keeps one of [options]: the look's menu rises under it with the matches,
/// the arrows and the pointer move one lifted row (one place, as in a native menu), Enter takes it. With [requireSelection] words that match nothing go back to the last
/// choice when focus leaves.
///
/// ```dart
/// NeumorphicCombobox<String>(labelText: 'Town', options: towns, onSelected: setTown)
/// ```
class NeumorphicCombobox<T extends Object> extends StatelessWidget {
  /// Creates a [NeumorphicCombobox].
  const NeumorphicCombobox({
    super.key,
    required this.options,
    this.search,
    this.debounceDuration,
    this.labelText,
    this.hintText,
    this.value,
    this.onSelected,
    this.displayStringForOption,
    this.isOptionEnabled,
    this.requireSelection = false,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.style,
  });

  /// Everything it may suggest.
  final List<T> options;

  /// Finds the options for what is typed, in place of filtering [options]: a search over the network or a database.
  /// While it runs the list says it is loading; when it fails, the list says so and offers Try again (Down moves the
  /// keys there, Enter runs it), and the focus stays in the field.
  final RawOptionSearch<T>? search;

  /// How long typing rests before [search] runs; null runs it at every change.
  final Duration? debounceDuration;

  /// The words above the field, and its spoken name.
  final String? labelText;

  /// Placeholder words.
  final String? hintText;

  /// The current choice.
  final T? value;

  /// Receives a choice.
  final ValueChanged<T>? onSelected;

  /// An option's words; `toString` by default.
  final String Function(T option)? displayStringForOption;

  /// Whether an option can be taken; one that cannot is shown out of use, and the keys pass over it. All by default.
  final bool Function(T option)? isOptionEnabled;

  /// Whether the field must hold one of [options] when focus leaves it.
  final bool requireSelection;

  /// Validation words; non-null marks the field invalid.
  final String? errorText;

  /// Supporting words under the field.
  final String? helperText;

  /// Whether the field takes input.
  final bool enabled;

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final words = displayStringForOption ?? (T option) => option.toString();
    final t = NeumorphicTheme.of(context);
    // Its open list starts its options' words where the field starts its value.
    final list = neumorphicFieldPanelInsets(context);
    // The list hangs from the groove, so the label and the words under it stand outside what it is anchored to. It
    // stands clear of the groove, and while it is up the groove rests.
    return NeumorphicFieldListOwner(
      builder: (context, open, surface) => neumorphicWideRoom(
        AlignmentDirectional.centerStart,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (labelText != null) _Label(labelText!),
            RawCombobox<T>(
              options: options,
              search: search,
              debounceDuration: debounceDuration,
              loadingBuilder: _searching,
              errorBuilder: (context, failure) =>
                  _SearchFailed(failure: failure, list: list),
              value: value,
              onSelected: onSelected,
              displayStringForOption: words,
              isOptionEnabled: isOptionEnabled,
              // The pointer's row and the keys' place both stand up off the panel, so they are one place, as in a
              // native menu: the pointer moves the keys' place, and two rows never read as two current options.
              highlightFollowsPointer: true,
              requireSelection: requireSelection,
              semanticLabel: labelText,
              // The input says the label, the help and the error; the label stands above and the lines under the
              // whole, so the list opens at the groove.
              fieldBuilder: (context, field) => NeumorphicFieldHooks(
                nameOnly: true,
                lines: false,
                expanded: field.isOpen,
                child: NeumorphicTextField(
                  labelText: labelText,
                  hintText: hintText,
                  helperText: helperText,
                  errorText: errorText,
                  enabled: enabled,
                  style: style,
                  controller: field.controller,
                  focusNode: field.focusNode,
                  // Enter keeps the focus here, so it comes in onEditingComplete with no onSubmitted: a submit that keeps the
                  // focus restarts the text input, and in a browser the restarted input takes no typing.
                  onEditingComplete: field.submit,
                  trailing: ExcludeSemantics(
                    child: Icon(
                      NeumorphicGlyphs.chevronsUpDown,
                      size: 18,
                      color: t.colors.inkTertiary,
                    ),
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
              surfaceBuilder: (context, rows) => surface(
                NeumorphicPanel(
                  padding: EdgeInsets.all(list.panel),
                  child: rows,
                ),
              ),
              emptyBuilder: (context) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  NeumorphicLocalizations.of(context).noResults,
                  style: t.textTheme.caption,
                ),
              ),
            ),
            _Under(error: errorText, helper: helperText),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(ObjectFlagProperty<RawOptionSearch<T>>.has('search', search))
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(
        ObjectFlagProperty<String Function(T option)>.has(
          'displayStringForOption',
          displayStringForOption,
        ),
      )
      ..add(
        ObjectFlagProperty<bool Function(T option)>.has(
          'isOptionEnabled',
          isOptionEnabled,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'requireSelection',
          requireSelection,
          defaultValue: false,
        ),
      )
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

/// Several choices in one groove, each a chip with its own ✕: type to find more among [options] (or, with [onCreate], to
/// add new ones), Backspace on an empty field takes the last chip, the arrows walk the chips. With no [onChanged] it is
/// out of use: its chips show without a ✕ and its field takes no typing.
///
/// ```dart
/// NeumorphicMultiSelect<String>(labelText: 'Guests', values: guests, onChanged: setGuests, options: people)
/// ```
class NeumorphicMultiSelect<T extends Object> extends StatefulWidget {
  /// Creates a [NeumorphicMultiSelect].
  const NeumorphicMultiSelect({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.labelText,
    this.hintText,
    this.displayStringForOption,
    this.isOptionEnabled,
    this.onCreate,
    this.maxTags,
    this.errorText,
    this.helperText,
    this.style,
  }) : assert((maxTags ?? 1) > 0);

  /// The chosen values, in order.
  final List<T> values;

  /// Receives the new list; null puts the field out of use.
  final ValueChanged<List<T>>? onChanged;

  /// What it may suggest.
  final List<T> options;

  /// Finds the options for what is typed, in place of filtering [options]: a search over the network or a database.
  /// While it runs the list says it is loading; when it fails, the list says so and offers Try again (Down moves the
  /// keys there, Enter runs it), and the focus stays in the field.
  final RawOptionSearch<T>? search;

  /// How long typing rests before [search] runs; null runs it at every change.
  final Duration? debounceDuration;

  /// The words above the groove, and its spoken name.
  final String? labelText;

  /// Placeholder words.
  final String? hintText;

  /// A value's words; `toString` by default.
  final String Function(T value)? displayStringForOption;

  /// Whether an option can be taken; one that cannot is shown out of use, and the keys pass over it. All by default.
  final bool Function(T option)? isOptionEnabled;

  /// Makes a value from typed words (Enter or a comma); null allows only [options].
  final T? Function(String text)? onCreate;

  /// The most it holds.
  final int? maxTags;

  /// Validation words; non-null marks the field invalid.
  final String? errorText;

  /// Supporting words under the groove.
  final String? helperText;

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  @override
  State<NeumorphicMultiSelect<T>> createState() =>
      _NeumorphicMultiSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<List<T>>>.has('onChanged', onChanged),
      )
      ..add(
        IterableProperty<T>('options', options, defaultValue: const <Never>[]),
      )
      ..add(ObjectFlagProperty<RawOptionSearch<T>>.has('search', search))
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(
        ObjectFlagProperty<String Function(T value)>.has(
          'displayStringForOption',
          displayStringForOption,
        ),
      )
      ..add(
        ObjectFlagProperty<bool Function(T option)>.has(
          'isOptionEnabled',
          isOptionEnabled,
        ),
      )
      ..add(
        ObjectFlagProperty<T? Function(String text)>.has('onCreate', onCreate),
      )
      ..add(IntProperty('maxTags', maxTags, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

class _NeumorphicMultiSelectState<T extends Object>
    extends State<NeumorphicMultiSelect<T>> {
  // The field's well deepens while its editor has the keys and its list is shut; a chip with the keys lifts itself, so
  // one thing at a time shows focus.
  bool _editing = false;

  // Out of use, the list never changes: the editor takes no focus, so no key reaches a tag.
  void _unchanged(List<T> _) {}

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // Its open list starts its options' words where the field starts its value.
    final list = neumorphicFieldPanelInsets(context);
    final local = NeumorphicLocalizations.of(context);
    final words =
        widget.displayStringForOption ?? (T value) => value.toString();
    final shape = t.shapes.corner(NeumorphicRadii.well);
    final off = widget.onChanged == null;
    Widget chip(T value, VoidCallback? onDeleted) => NeumorphicChip(
      words(value),
      dense: true,
      isEnabled: !off,
      onDeleted: onDeleted,
      deleteLabel: local.remove(words(value)),
    );
    // Its list stands clear of the well, and while it is up the well rests.
    return NeumorphicFieldListOwner(
      builder: (context, open, surface) => neumorphicWideRoom(
        AlignmentDirectional.centerStart,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.labelText != null) _Label(widget.labelText!),
            // The entry says the help and the error, from ui_core's decorator; the lines are drawn under the field.
            RawInputDecorator(
              helperText: widget.helperText,
              errorText: widget.errorText,
              enabled: !off,
              builder: (context, parts) => parts.control,
              child: RawTagInput<T>(
                values: widget.values,
                onChanged: widget.onChanged ?? _unchanged,
                options: widget.options,
                search: widget.search,
                debounceDuration: widget.debounceDuration,
                loadingBuilder: _searching,
                errorBuilder: (context, failure) =>
                    _SearchFailed(failure: failure, list: list),
                displayStringForOption: words,
                isOptionEnabled: widget.isOptionEnabled,
                // One place for the pointer and the keys, as the combobox's.
                highlightFollowsPointer: true,
                onCreate: widget.onCreate,
                maxTags: widget.maxTags,
                semanticLabel: widget.labelText,
                deleteLabel: local.remove('').trim(),
                fieldBuilder: (context, field) => Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  includeSemantics: false,
                  onFocusChange: (on) => setState(() => _editing = on),
                  child: _BareEditor(
                    controller: field.controller,
                    focusNode: field.focusNode,
                    enabled: !off,
                    // The hint stays under the chips: without it the words line read as an empty well under them.
                    hint: widget.hintText,
                    // Enter keeps the focus here, so it comes in onEditingComplete with no onSubmitted: a submit that keeps the
                    // focus restarts the text input, and in a browser the restarted input takes no typing.
                    onEditingComplete: field.submit,
                    style: widget.style,
                    semanticLabel: widget.labelText ?? widget.hintText,
                    expanded: field.isOpen,
                  ),
                ),
                layoutBuilder: (context, tags, field) => NeumorphicOutOfUse(
                  off: off,
                  child: NeumorphicFieldBox(
                    style: widget.style,
                    multiline: true,
                    shape: shape,
                    states: {
                      if (_editing && !open) WidgetState.focused,
                      if (widget.errorText != null) WidgetState.error,
                      if (off) WidgetState.disabled,
                    },
                    // The chips start where the words of any field start, and the words line goes on after the last chip,
                    // on its line while there is room, as one flow. With chips the flow stands further in above and
                    // below, 9 less the air its line leaves above a chip's face, so the first chip's face stands as far
                    // in from the well's top as from its side, square in its corner.
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: tags.isEmpty
                          ? 0
                          : math.max(0, 9 - _chipAir(context)),
                    ),
                    // Out of use, each chip is shown alone: no ✕, and no remove action for a screen reader.
                    child: _TagFlow(
                      line: NeumorphicChromeMetrics.lineOf(context),
                      children: [
                        if (off) ...[
                          for (final value in widget.values)
                            KeyedSubtree(
                              key: ValueKey<Object>(value),
                              child: chip(value, null),
                            ),
                        ] else
                          ...tags,
                        field,
                      ],
                    ),
                  ),
                ),
                tagBuilder: (context, value, tag) {
                  final face = chip(value, tag.onDeleted);
                  if (!tag.focused) return face;
                  return CustomPaint(
                    foregroundPainter: neumorphicFocusLift(t, t.shapes.capsule),
                    child: face,
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
                surfaceBuilder: (context, rows) => surface(
                  NeumorphicPanel(
                    padding: EdgeInsets.all(list.panel),
                    child: rows,
                  ),
                ),
              ),
            ),
            _Under(error: widget.errorText, helper: widget.helperText),
          ],
        ),
      ),
    );
  }
}

// A search on its way, in the list's panel: the look's turning ring and its word. ui_core announces it as it
// appears.
Widget _searching(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  child: Row(
    children: [
      const ExcludeSemantics(
        child: NeumorphicCircularProgressIndicator(size: 18),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          NeumorphicLocalizations.of(context).loading,
          style: NeumorphicTheme.of(context).textTheme.caption,
        ),
      ),
    ],
  ),
);

// A search that failed, in the list's panel: what happened, and Try again as the list's one row. The keys light it from
// the field (ui_core's [RawSearchError.focused]) and it never takes the focus itself, as an option row does not; the
// pointer raises it and a press runs the search again.
class _SearchFailed extends StatefulWidget {
  const _SearchFailed({required this.failure, required this.list});

  final RawSearchError failure;
  final ({double panel, double row}) list;

  @override
  State<_SearchFailed> createState() => _SearchFailedState();
}

class _SearchFailedState extends State<_SearchFailed> {
  final _unfocusable = FocusNode(
    debugLabel: 'Try again',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _unfocusable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final label = NeumorphicLocalizations.of(context).tryAgain;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            RawWidgetsLocalizations.of(context).searchFailedMessage,
            style: t.textTheme.caption,
          ),
        ),
        RawButton(
          onPressed: widget.failure.retry,
          focusNode: _unfocusable,
          semanticLabel: label,
          builder: (context, states, _) => NeumorphicPanelRow(
            label: label,
            states: {
              ...states,
              if (widget.failure.focused) WidgetState.focused,
            },
            inset: widget.list.row,
            panelInset: widget.list.panel,
          ),
        ),
      ],
    );
  }
}

/// A form row around any control: its label (with a required mark), the control, and its help or failure under it. A
/// single control speaks the label, help and failure itself; a group of controls ([group]: a segmented button, radios,
/// choices, chips in a wrap) is named by them, each control keeping its own node, so every one takes a tap from a screen
/// reader or a browser with semantics on. The drawn words are silent. In a `RawForm`, a `RawFormField` validates it
/// and the form focuses the first wrong field on submit.
///
/// ```dart
/// NeumorphicFormField(labelText: 'Email', helperText: 'The receipt goes here', required: true, child: NeumorphicTextField(controller: email))
/// ```
class NeumorphicFormField extends StatelessWidget {
  /// Creates a [NeumorphicFormField].
  const NeumorphicFormField({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.group,
  });

  /// The control.
  final Widget child;

  /// The words above it.
  final String? labelText;

  /// Supporting words under it.
  final String? helperText;

  /// Validation words; they replace the help.
  final String? errorText;

  /// Whether it must be filled: a mark after the label, "required" spoken.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// Whether [child] is a group of controls, which the label names as a group while each control keeps its own node;
  /// false, one control, which takes the label as its own name. Null decides by [child]: the look's segmented button,
  /// radio group, choices, toggle, button and latch groups, and several parts in a row, column or wrap (chips, say), are
  /// a group, seen through an [Align], [Padding], [SizedBox] or [ConstrainedBox]. A group that names itself in the
  /// label's words (a segmented button labelled as its field) is heard once: the field adds no name of its own.
  final bool? group;

  // Merged into one node, a group's controls would give a tap on any of them to the first, so the controls after it
  // could not be reached by a tap.
  static bool _isGroup(Widget w) => switch (w) {
    NeumorphicSegmentedButton() ||
    NeumorphicRadioGroup() ||
    NeumorphicChoices() ||
    NeumorphicToggleGroup() ||
    NeumorphicButtonGroup() ||
    NeumorphicLatchGroup() ||
    Flex() ||
    Wrap() => true,
    Align(:final child?) ||
    Padding(:final child?) ||
    SizedBox(:final child?) ||
    ConstrainedBox(:final child?) => _isGroup(child),
    _ => false,
  };

  // The name a group gives its own node, seen through the same wrappers.
  static String? _ownName(Widget w) => switch (w) {
    NeumorphicSegmentedButton(:final label) ||
    NeumorphicRadioGroup(:final label) ||
    NeumorphicToggleGroup(:final label) ||
    NeumorphicButtonGroup(:final label) => label,
    Align(:final child?) ||
    Padding(:final child?) ||
    SizedBox(:final child?) ||
    ConstrainedBox(:final child?) => _ownName(child),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final isGroup = group ?? _isGroup(child);
    // A group that already says the label's words on its own node: the field draws the label but does not say it, so
    // it is read once, not "Priority, Priority" (ui_core's rule, which applies when a field decides for itself).
    final own = isGroup ? _ownName(child)?.trim().toLowerCase() : null;
    final heard = own != null && own == labelText?.trim().toLowerCase();
    return RawInputDecorator(
      mergeSemantics: !isGroup,
      labelText: heard ? null : labelText,
      helperText: helperText,
      errorText: errorText,
      required: required,
      enabled: enabled,
      requiredHint: NeumorphicLocalizations.of(context).requiredField,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((parts.labelText ?? (heard ? labelText : null)) case final shown?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DefaultTextStyle.merge(
                style: t.textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: parts.enabled ? c.ink : c.inkTertiary,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child:
                          parts.label ?? ExcludeSemantics(child: Text(shown)),
                    ),
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
          if (parts.invalid && parts.errorText != null)
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<bool>('required', required, defaultValue: false),
      )
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true))
      ..add(DiagnosticsProperty<bool>('group', group, defaultValue: null));
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
/// NeumorphicRangeSlider(label: 'Price', values: const RawRangeValues(60, 140), max: 300, onChanged: setPrice)
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
  }) : assert((divisions ?? 1) > 0),
       assert(minGap >= 0);

  /// The span's two ends.
  final RawRangeValues values;

  /// Receives the new span; null puts it out of use.
  final ValueChanged<RawRangeValues>? onChanged;

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
          RawRangeSlider(
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawRangeValues>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<RawRangeValues>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DoubleProperty('min', min, defaultValue: 0))
      ..add(DoubleProperty('max', max, defaultValue: 1))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(DoubleProperty('minGap', minGap, defaultValue: 0))
      ..add(
        ObjectFlagProperty<String Function(double value)>.has(
          'valueLabel',
          valueLabel,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
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
    // over the groove, it would stand fuller than the groove beside it.
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
/// A [controller] is the caller's, made once and disposed with its owner. Without one the picker keeps its colour on a
/// controller of its own, starting on [initialColor], and tells [onChanged].
///
/// ```dart
/// NeumorphicColorPicker(controller: colour)
/// ```
///
/// ```dart
/// NeumorphicColorPicker(initialColor: NeumorphicTheme.of(context).colors.accent, onChanged: (colour) {})
/// ```
class NeumorphicColorPicker extends StatefulWidget {
  /// Creates a [NeumorphicColorPicker].
  const NeumorphicColorPicker({
    super.key,
    this.controller,
    this.initialColor = const Color(0xFF000000),
    this.onChanged,
    this.showAlpha = false,
    this.label,
  });

  /// The colour, with its hex. The caller keeps it and disposes it; when null, the picker makes its own, starting on
  /// [initialColor], and disposes it with itself.
  final RawColorController? controller;

  /// The colour the picker's own controller starts on, without a [controller]; later changes are not read.
  final Color initialColor;

  /// Called with the colour each time it changes.
  final ValueChanged<Color>? onChanged;

  /// Whether an opacity strip shows.
  final bool showAlpha;

  /// The picker's heading.
  final String? label;

  @override
  State<NeumorphicColorPicker> createState() => _NeumorphicColorPickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawColorController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ColorProperty(
          'initialColor',
          initialColor,
          defaultValue: const Color(0xFF000000),
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<Color>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<bool>('showAlpha', showAlpha, defaultValue: false),
      )
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

class _NeumorphicColorPickerState extends State<NeumorphicColorPicker> {
  // The picker's own controller, while the caller hands in none.
  RawColorController? _own;

  RawColorController get _controller =>
      widget.controller ?? (_own ??= RawColorController(widget.initialColor));

  // The colour last told to onChanged, so a change of hue alone on a grey tells no one.
  late Color _told;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _told = _controller.color;
  }

  @override
  void didUpdateWidget(NeumorphicColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == oldWidget.controller) return;
    (oldWidget.controller ?? _own)?.removeListener(_changed);
    // A controller handed in takes over from the picker's own, which goes; one taken away leaves a new own one,
    // starting on the colour the picker showed.
    if (widget.controller != null) {
      _own?.dispose();
      _own = null;
    } else {
      _own = RawColorController(oldWidget.controller!.color);
    }
    _controller.addListener(_changed);
    _told = _controller.color;
  }

  void _changed() {
    final colour = _controller.color;
    if (colour == _told) return;
    _told = colour;
    widget.onChanged?.call(colour);
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final showAlpha = widget.showAlpha;
    final label = widget.label;
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final area = t.shapes.corner(NeumorphicRadii.well);
    final strip = t.shapes.capsule;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) _Label(label),
        RawColorPicker(
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
                          final colours = channel == RawColorChannel.alpha
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

/// A tag field's chips in lines, [spacing] apart along a line and [runSpacing] between lines, each line's parts on its
/// middle, and its words line (the last child) after the last chip, taking the rest of that line, or a line of its own
/// when less than [fieldMin] is left. Laid out from the reader's start.
class _TagFlow extends MultiChildRenderObjectWidget {
  const _TagFlow({required this.line, required super.children});

  /// The least height of a line of the flow: the field's own line, so a line of chips stands as tall as the words line
  /// and a chip's reach is centred in it.
  final double line;

  static const spacing = 6.0, runSpacing = 0.0, fieldMin = 96.0;

  @override
  _RenderTagFlow createRenderObject(BuildContext context) =>
      _RenderTagFlow(Directionality.of(context), line);

  @override
  void updateRenderObject(BuildContext context, _RenderTagFlow renderObject) {
    renderObject
      ..direction = Directionality.of(context)
      ..line = line;
  }
}

class _TagFlowData extends ContainerBoxParentData<RenderBox> {}

class _RenderTagFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TagFlowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TagFlowData> {
  _RenderTagFlow(this._direction, this._line);

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  double _line;
  set line(double value) {
    if (value == _line) return;
    _line = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TagFlowData) child.parentData = _TagFlowData();
  }

  // Lines the children into [width] and returns the flow's size; [place] is told each child's offset.
  Size _flow(
    double width,
    Size Function(RenderBox child, BoxConstraints constraints) measure, [
    void Function(RenderBox child, Offset offset)? place,
  ]) {
    final lines = <List<(RenderBox, Size)>>[];
    var line = <(RenderBox, Size)>[];
    var x = 0.0;
    final field = lastChild;
    for (
      var child = firstChild;
      child != null && child != field;
      child = childAfter(child)
    ) {
      final size = measure(child, BoxConstraints(maxWidth: width));
      if (line.isNotEmpty && x + _TagFlow.spacing + size.width > width) {
        lines.add(line);
        line = [];
        x = 0;
      }
      x += (line.isEmpty ? 0 : _TagFlow.spacing) + size.width;
      line.add((child, size));
    }
    if (field != null) {
      var left = width - x - (line.isEmpty ? 0 : _TagFlow.spacing);
      if (line.isNotEmpty && left < math.min(_TagFlow.fieldMin, width)) {
        lines.add(line);
        line = [];
        left = width;
      }
      line.add((
        field,
        measure(field, BoxConstraints.tightFor(width: math.max(0, left))),
      ));
    }
    if (line.isNotEmpty) lines.add(line);
    var y = 0.0;
    for (final (i, parts) in lines.indexed) {
      if (i > 0) y += _TagFlow.runSpacing;
      // A line that holds a chip stands at least at the field's line; the words line alone keeps its own height.
      final height = parts.fold(
        parts.any((p) => p.$1 != field) ? _line : 0.0,
        (h, p) => math.max(h, p.$2.height),
      );
      var at = 0.0;
      for (final (child, size) in parts) {
        final dx = _direction == TextDirection.ltr
            ? at
            : width - at - size.width;
        place?.call(child, Offset(dx, y + (height - size.height) / 2));
        at += size.width + _TagFlow.spacing;
      }
      y += height;
    }
    return Size(width, y);
  }

  double _width(BoxConstraints constraints) => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : _TagFlow.fieldMin * 3;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    _flow(_width(constraints), (child, c) => child.getDryLayout(c)),
  );

  @override
  void performLayout() {
    size = constraints.constrain(
      _flow(
        _width(constraints),
        (child, c) {
          child.layout(c, parentUsesSize: true);
          return child.size;
        },
        (child, offset) => (child.parentData! as _TagFlowData).offset = offset,
      ),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => _TagFlow.fieldMin;

  @override
  double computeMaxIntrinsicWidth(double height) {
    var width = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      width +=
          child.getMaxIntrinsicWidth(height) +
          (child == firstChild ? 0 : _TagFlow.spacing);
    }
    return math.max(width, _TagFlow.fieldMin);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _flow(width, (child, c) => child.getDryLayout(c)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// The air a line of a field's flow leaves above and below a chip's face: the medium line
/// ([NeumorphicChromeMetrics.lineOf]) less the chip's face (its 36 at the density), halved; none where the face is the
/// taller.
double _chipAir(BuildContext context) {
  final face = NeumorphicTheme.of(context).density.height(36);
  return math.max(0.0, NeumorphicChromeMetrics.lineOf(context) - face) / 2;
}
