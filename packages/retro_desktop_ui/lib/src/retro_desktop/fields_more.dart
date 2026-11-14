// Round 4's fields: a text area, a password field, an input group, a combobox, a multi-select and a form field. The
// last five stand on ui_core's behaviour (reveal, focus-within, the option list, tags, the field's semantics); this
// file paints them in Retro Desktop's hand: white boxes sunk into the machine, the highlight for the keyboard's row.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'controls.dart';
import 'glyphs.dart';
import 'internal/face.dart';
import 'internal/parts.dart';
import 'layout.dart' show RetroDesktopReach;
import 'pixels.dart';
import 'press.dart';
import 'theme.dart';
import 'internal/caps.dart';

/// A box for a few lines of words: a note, a message, an address. The text
/// field's box, taller, its words from the top.
///
/// ```dart
/// RetroDesktopTextArea(label: 'Notes', hint: 'Anything the courier should know', lines: 4)
/// ```
class RetroDesktopTextArea extends StatelessWidget {
  /// Creates a [RetroDesktopTextArea].
  const RetroDesktopTextArea({
    super.key,
    this.controller,
    this.initial,
    this.hint,
    this.label,
    this.helper,
    this.error,
    this.lines = 4,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
  }) : assert(lines > 1);

  /// An optional externally owned controller; the caller disposes it.
  final TextEditingController? controller;

  /// The first words when no controller supplies them.
  final String? initial;

  /// The words shown while the box is empty.
  final String? hint;

  /// The words above the box, under it, and the error that replaces them.
  final String? label, helper, error;

  /// How many lines the box shows.
  final int lines;

  /// Whether the box takes input.
  final bool enabled;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// Reports each edit.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => RetroDesktopTextField(
    controller: controller,
    initial: initial,
    hint: hint,
    label: label,
    helper: helper,
    error: error,
    lines: lines,
    enabled: enabled,
    focusNode: focusNode,
    autofocus: autofocus,
    onChanged: onChanged,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
  );
}

/// A password box with an eye that shows and hides what was typed. ui_core's
/// reveal keeps the state and the eye's name; the box is the text field's.
///
/// ```dart
/// RetroDesktopPasswordField(label: 'Password', onChanged: (_) {})
/// ```
class RetroDesktopPasswordField extends StatelessWidget {
  /// Creates a [RetroDesktopPasswordField].
  const RetroDesktopPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.newPassword = false,
  });

  /// An optional externally owned controller; the caller disposes it.
  final TextEditingController? controller;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// The words above the box, in it while empty, and under it.
  final String? label, hint, helper;

  /// The error that replaces the helper.
  final String? error;

  /// Whether the box takes input.
  final bool enabled;

  /// Reports each edit, and the submit key.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// Whether the platform should offer a new password rather than a saved one.
  final bool newPassword;

  @override
  Widget build(BuildContext context) {
    return DesignPasswordReveal(
      focusNode: focusNode,
      showLabel: DesignLocalizations.of(context).showPasswordLabel,
      hideLabel: DesignLocalizations.of(context).hidePasswordLabel,
      builder: (context, s) => RetroDesktopTextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        label: label,
        hint: hint,
        helper: helper,
        error: error,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        obscureText: s.obscured,
        keyboardType: TextInputType.visiblePassword,
        autofillHints: [
          newPassword ? AutofillHints.newPassword : AutofillHints.password,
        ],
        trailing: retroDesktopFieldButton(
          context,
          icon: s.obscured ? RetroDesktopGlyphs.eye : RetroDesktopGlyphs.eyeOff,
          label: s.toggleLabel,
          onPressed: enabled ? s.toggle : null,
        ),
      ),
    );
  }
}

/// A box with words fixed at either end of what is typed: a site's address
/// round a name, a currency before an amount. The add-ons are the machine's
/// grey, ruled off from the white; a press anywhere on the box types in it.
/// ui_core's input group carries focus-within and the press.
///
/// ```dart
/// RetroDesktopInputGroup(label: 'Site', prefix: 'https://', suffix: '.example.com', hint: 'studio')
/// ```
class RetroDesktopInputGroup extends StatefulWidget {
  /// Creates a [RetroDesktopInputGroup].
  const RetroDesktopInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.prefix,
    this.suffix,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  /// An optional externally owned controller; the caller disposes it.
  final TextEditingController? controller;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// The words above the box, in it while empty, and under it.
  final String? label, hint, helper;

  /// The error that replaces the helper.
  final String? error;

  /// The fixed words before and after the typed ones.
  final String? prefix, suffix;

  /// A widget at the box's start, usually an `Icon`, which takes the box's
  /// icon size and ink.
  final Widget? leading;

  /// A small button at the box's end.
  final Widget? trailing;

  /// Whether the box takes input.
  final bool enabled;

  /// The platform keyboard requested.
  final TextInputType? keyboardType;

  /// Reports each edit, and the submit key.
  final ValueChanged<String>? onChanged, onSubmitted;

  @override
  State<RetroDesktopInputGroup> createState() => _InputGroupState();
}

class _InputGroupState extends State<RetroDesktopInputGroup> {
  TextEditingController? _ownText;
  FocusNode? _ownFocus;
  TextEditingController get _text =>
      widget.controller ?? (_ownText ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownText?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  Widget _addOn(
    RetroDesktopThemeData t,
    String words, {
    required bool start,
    required double most,
    double shrink = 1,
  }) {
    final c = t.colors;
    final rule = BorderSide(
      color: c.outline,
      width: t.strokes.regular == 0 ? 1 : t.strokes.regular,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.platinumLight,
        border: BorderDirectional(
          end: start ? rule : BorderSide.none,
          start: start ? BorderSide.none : rule,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: most),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            widthFactor: 1,
            child: Builder(
              builder: (context) {
                final text = Text(
                  words,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // The words typed between are the field's: the add-ons match
                  // them, in the secondary ink.
                  style: t.type.body.copyWith(color: c.textSecondary),
                );
                if (shrink >= 1) return text;
                final size = t.type.body.fontSize ?? 14;
                final now = MediaQuery.textScalerOf(context).scale(size) / size;
                return MediaQuery.withClampedTextScaling(
                  maxScaleFactor: now * shrink,
                  child: text,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final error = widget.error;
    final editor = retroDesktopBareEditor(
      context,
      controller: _text,
      focusNode: _focus,
      autofocus: widget.autofocus,
      hint: widget.hint,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      semanticLabel: widget.label,
    );
    // The words typed between keep two fifths of the row (up to 120), so they never get pushed out of a narrow
    // column. Add-ons too wide for the rest may take that room down to the hint's own width; then their words step
    // down a little (to four fifths); only then do they share the rest by their widths, each cut short (twice the
    // text size on a phone left "https://" and ".example.com" the whole row and the field a sliver; in a narrow card
    // at the plain size, "http…" and ".example.…" were cut beside an empty half of the field).
    final group = LayoutBuilder(
      builder: (context, room) {
        double natural(String? words) {
          if (words == null) return 0;
          final tp = TextPainter(
            text: TextSpan(text: words, style: t.type.body),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final width = tp.width + 16 + 2;
          tp.dispose();
          return width;
        }

        final pre = natural(widget.prefix), post = natural(widget.suffix);
        final keep = room.hasBoundedWidth
            ? math.min(room.maxWidth * .4, 120.0)
            : 0.0;
        var spare = room.hasBoundedWidth
            ? room.maxWidth - keep
            : double.infinity;
        var shrink = 1.0;
        if (pre + post > spare) {
          spare =
              room.maxWidth -
              math.min(keep, math.max(48.0, natural(widget.hint)));
          final pads =
              (widget.prefix != null ? 18 : 0) +
              (widget.suffix != null ? 18 : 0);
          final words = pre + post - pads;
          if (pre + post > spare && words > 0) {
            shrink = math.max(.8, (spare - pads) / words);
          }
        }
        final shrunk = (pre + post) * shrink;
        final cut = shrunk <= spare ? 1.0 : spare / shrunk;
        final mostPre = cut < 1 ? pre * shrink * cut : double.infinity;
        final mostPost = cut < 1 ? post * shrink * cut : double.infinity;
        return DesignInputGroup(
          focusNode: _focus,
          enabled: widget.enabled,
          isError: error != null,
          builder: (context, states, child) => RetroDesktopHighlight(
            shape: t.shapes.small,
            focused: states.contains(WidgetState.focused),
            child: Opacity(
              opacity: widget.enabled ? 1 : .5,
              child: retroDesktopSunkenBox(
                context,
                states: states,
                padding: EdgeInsets.zero,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.prefix != null)
                        _addOn(
                          t,
                          widget.prefix!,
                          start: true,
                          most: mostPre,
                          shrink: shrink,
                        ),
                      if (widget.leading != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: IconTheme.merge(
                            data: IconThemeData(size: 15, color: c.text),
                            child: widget.leading!,
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: child,
                        ),
                      ),
                      if (widget.trailing != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4),
                          child: Center(widthFactor: 1, child: widget.trailing),
                        ),
                      if (widget.suffix != null)
                        _addOn(
                          t,
                          widget.suffix!,
                          start: false,
                          most: mostPost,
                          shrink: shrink,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child: editor,
        );
      },
    );
    return _Labelled(
      label: widget.label,
      note: error ?? widget.helper,
      error: error != null,
      child: group,
    );
  }
}

/// A field's words above it and its note under it, the text field's way.
class _Labelled extends StatelessWidget {
  const _Labelled({
    required this.child,
    this.label,
    this.note,
    this.error = false,
    this.dropdown = false,
  });
  final Widget child;
  final String? label, note;
  final bool error;
  // A dropdown: from 600 up it doesn't stretch to its column, it stands at
  // its start at most 320 wide, as a select does.
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    // Under a pointer the box is drawn one line tall and its reach stands
    // around it, as a text field's does, so stacked fields keep one rhythm.
    final child = RetroDesktopReach.padsAcross(context)
        ? this.child
        : RetroDesktopReach(child: this.child);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ExcludeSemantics(child: Text(label!, style: t.type.body)),
          ),
        if (dropdown && MediaQuery.sizeOf(context).width >= 600)
          Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: child,
            ),
          )
        else
          child,
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: error
                ? Semantics(
                    liveRegion: true,
                    child: retroDesktopFieldNote(t, note!, error: true),
                  )
                : ExcludeSemantics(
                    child: retroDesktopFieldNote(t, note!, error: false),
                  ),
          ),
      ],
    );
  }
}

/// The arrows a Platinum field draws when it has a list behind it, the
/// popup's pair (Chisel's field has the select's drop button instead).
const Widget _listMark = Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    RetroDesktopTriangleMark(AxisDirection.up, size: 8),
    RetroDesktopTriangleMark(AxisDirection.down, size: 8),
  ],
);

/// An option in a field's list, as a select's list draws one: the row runs
/// rim to rim, the keyboard's row lit; its words start where the field's do
/// (8 px in at the density), on one x down the list; the chosen one's tick
/// stands at the end, in a column every row keeps.
Widget _optionRow(BuildContext context, String words, Set<WidgetState> states) {
  final t = RetroDesktopTheme.of(context);
  final chosen = states.contains(WidgetState.selected);
  return retroDesktopLitRow(
    context,
    lit: states.contains(WidgetState.focused),
    enabled: !states.contains(WidgetState.disabled),
    shape: const RoundedRectangleBorder(),
    padding: _optionPadding(t),
    child: Row(
      children: [
        Expanded(child: RetroDesktopCaps(Text(words))),
        SizedBox(
          width: 20,
          child: chosen
              ? const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Icon(RetroDesktopGlyphs.check, size: 14),
                )
              : null,
        ),
      ],
    ),
  );
}

/// An option's room in a field's list: its words on the field's.
EdgeInsetsGeometry _optionPadding(RetroDesktopThemeData t) =>
    EdgeInsetsDirectional.fromSTEB(8 * t.density.horizontal, 8, 8, 8);

/// A field's list: no room at its sides, so its rows reach the rims.
Widget _listPanel(BuildContext context, Widget list) => retroDesktopPanel(
  context,
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: list,
);

/// A box that suggests as you type: the options that match open under it, the
/// arrows move along them, Enter takes one. ui_core's combobox carries the
/// list, its keys and its announcements.
///
/// ```dart
/// RetroDesktopCombobox<String>(label: 'Country', options: const ['Austria', 'Belgium', 'Chile'], onSelected: (_) {})
/// ```
class RetroDesktopCombobox<T extends Object> extends StatelessWidget {
  /// Creates a [RetroDesktopCombobox].
  const RetroDesktopCombobox({
    super.key,
    required this.options,
    this.displayString,
    this.value,
    this.onSelected,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.requireSelection = false,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  /// The options in their order.
  final List<T> options;

  /// Each option's words; null uses its `toString`.
  final String Function(T option)? displayString;

  /// The chosen option.
  final T? value;

  /// Reports the option taken.
  final ValueChanged<T>? onSelected;

  /// The words above the box, in it while empty, and under it.
  final String? label, hint, helper;

  /// The error that replaces the helper.
  final String? error;

  /// Whether the box keeps only an option (it clears free words on leaving).
  final bool requireSelection;

  /// Whether the box takes input.
  final bool enabled;

  /// An optional externally owned controller; the caller disposes it.
  final TextEditingController? controller;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final words = displayString ?? (T option) => '$option';
    final box = DesignCombobox<T>(
      options: options,
      displayStringForOption: words,
      value: value,
      onSelected: onSelected,
      requireSelection: requireSelection,
      controller: controller,
      focusNode: focusNode,
      semanticLabel: label,
      fieldBuilder: (context, f) => _ListField(
        focusNode: f.focusNode,
        error: error != null,
        enabled: enabled,
        child: retroDesktopBareEditor(
          context,
          controller: f.controller,
          focusNode: f.focusNode,
          autofocus: autofocus,
          hint: hint,
          enabled: enabled,
          onSubmitted: (_) => f.submit(),
          semanticLabel: label,
        ),
      ),
      optionBuilder: (context, option, states) =>
          _optionRow(context, words(option), states),
      surfaceBuilder: _listPanel,
      emptyBuilder: _noMatchesRow,
    );
    return _Labelled(
      label: label,
      note: error ?? helper,
      error: error != null,
      dropdown: true,
      child: box,
    );
  }
}

/// Says in the list that no option fits, on the line an option's words take.
Widget _noMatchesRow(BuildContext context) {
  final t = RetroDesktopTheme.of(context);
  return Padding(
    padding: _optionPadding(t),
    child: Text(
      DesignLocalizations.of(context).noResultsLabel,
      style: t.type.body.copyWith(color: t.colors.textSecondary),
    ),
  );
}

/// The sunken box round a field with a list behind it, ringed while focused.
class _ListField extends StatelessWidget {
  const _ListField({
    required this.focusNode,
    required this.child,
    this.error = false,
    this.enabled = true,
  });
  final FocusNode focusNode;
  final Widget child;
  final bool error, enabled;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final states = <WidgetState>{
          if (focusNode.hasFocus) WidgetState.focused,
          if (error) WidgetState.error,
          if (!enabled) WidgetState.disabled,
        };
        return RetroDesktopHighlight(
          shape: t.shapes.small,
          focused: focusNode.hasFocus,
          child: Opacity(
            opacity: enabled ? 1 : .5,
            child: t.chisel
                // The PC's combo box: the select's bevelled drop button at
                // its end, two pixels in from the well.
                ? retroDesktopSunkenBox(
                    context,
                    states: states,
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 2, 0),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: Center(child: child)),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: SizedBox(
                              width: 18,
                              child: RetroDesktopPixelPaint(
                                painter: RetroDesktopArrowButtonPainter(
                                  t.colors,
                                  false,
                                  t.strokes.regular,
                                  t.strokes.hairline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : retroDesktopSunkenBox(
                    context,
                    states: states,
                    child: Row(
                      children: [
                        Expanded(child: child),
                        const SizedBox(width: 6),
                        _listMark,
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// A control with its words: the name above it, its help under it, and the
/// error that replaces the help, the way every Retro Desktop field reads.
/// ui_core's field gives the control its name, help and error for a screen
/// reader, and marks it required.
///
/// ```dart
/// RetroDesktopFormField(label: 'Email', help: 'We send the receipt here', required: true, child: RetroDesktopTextField(hint: 'name@example.com'))
/// ```
class RetroDesktopFormField extends StatelessWidget {
  /// Creates a [RetroDesktopFormField].
  const RetroDesktopFormField({
    super.key,
    required this.child,
    this.label,
    this.help,
    this.error,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.requiredHint,
  });

  /// The word a screen reader hears for a required field.
  final String? requiredHint;

  /// The control: a field, a select, a group of boxes.
  final Widget child;

  /// The name above the control, the help under it, and the error that
  /// replaces the help.
  final String? label, help, error;

  /// Whether the field must be filled.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus, so a press on the name reaches it.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return DesignField(
      labelText: label,
      helperText: help,
      errorText: error,
      required: required,
      enabled: enabled,
      focusNode: focusNode,
      requiredHint:
          requiredHint ?? DesignLocalizations.of(context).requiredHint,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DefaultTextStyle.merge(
                style: t.type.body.copyWith(
                  color: enabled ? c.text : c.textTertiary,
                ),
                child: Row(
                  children: [
                    Flexible(child: parts.label!),
                    if (parts.required)
                      ExcludeSemantics(child: Text(' *', style: t.type.body)),
                  ],
                ),
              ),
            ),
          parts.control,
          if (parts.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ExcludeSemantics(
                child: retroDesktopFieldNote(t, parts.errorText!, error: true),
              ),
            )
          else if (parts.helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ExcludeSemantics(
                child: retroDesktopFieldNote(
                  t,
                  parts.helperText!,
                  error: false,
                ),
              ),
            ),
        ],
      ),
      child: child,
    );
  }
}
