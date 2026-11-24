import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../editing.dart';
import '../../glyphs.dart';
import '../../internal/bare_field.dart';
import '../../internal/face.dart';
import '../../internal/field_owner.dart';
import '../../internal/hit_slop.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../forms/forms.dart';
import '../icon-button/round_button.dart';
import '../actions/actions.dart' show FrostedButtonGroup;
import '../choices/choices.dart' show FrostedChoices, FrostedRadioGroup;
import '../color_picker/color_picker.dart' show FrostedColorPicker;
import '../controls/controls.dart'
    show FrostedFilterChipGroup, FrostedIconPicker, FrostedSegmentedButton;
import '../toggle/toggle.dart' show FrostedToggleGroup;
import '../../internal/dim.dart';

// ---------------------------------------------------------------------------
// Password field
// ---------------------------------------------------------------------------

/// A password in a [FrostedTextField]'s well, its eye at the end showing or
/// hiding it (shadcn's password input): the text hidden at first, the eye
/// saying what it will do ("Show password"), the caret and focus kept as it
/// flips. Autofill fills it as a password ([newPassword] for a new one).
/// ui_core's [RawPasswordReveal] is the behaviour.
///
/// ```dart
/// FrostedPasswordField(labelText: 'Password', value: password, onChanged: (v) => setState(() => password = v))
/// ```
class FrostedPasswordField extends StatelessWidget {
  /// A password field named [labelText].
  const FrostedPasswordField({
    required this.labelText,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.newPassword = false,
    super.key,
  });

  /// The field's name, over its well.
  final String labelText;

  /// The password, when the page owns it.
  final String? value;

  /// Called as the password changes.
  final ValueChanged<String>? onChanged;

  /// Called on Return.
  final ValueChanged<String>? onSubmitted;

  /// The text's controller, when the caller holds it.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// The placeholder.
  final String? hintText;

  /// {@macro frosted.helper}
  final String? helperText;

  /// {@macro frosted.error}
  final String? errorText;

  /// Whether it takes input.
  final bool enabled;

  /// Whether it takes focus on its first frame.
  final bool autofocus;

  /// Whether it is a new password (autofill offers to make one).
  final bool newPassword;

  @override
  Widget build(BuildContext context) {
    return RawPasswordReveal(
      focusNode: focusNode,
      showLabel: RawWidgetsLocalizations.of(context).showPasswordLabel,
      hideLabel: RawWidgetsLocalizations.of(context).hidePasswordLabel,
      builder: (context, password) => FrostedTextField(
        labelText: labelText,
        value: value,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        focusNode: focusNode,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        enabled: enabled,
        autofocus: autofocus,
        obscureText: password.obscured,
        keyboardType: TextInputType.visiblePassword,
        autofillHints: [
          newPassword ? AutofillHints.newPassword : AutofillHints.password,
        ],
        trailing: FrostedIconButton(
          password.obscured ? FrostedGlyphs.show : FrostedGlyphs.hide,
          label: password.toggleLabel,
          size: FrostedIconButtonSize.small,
          onPressed: enabled ? password.toggle : null,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(StringProperty('value', value, defaultValue: null))
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
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        FlagProperty('newPassword', value: newPassword, ifTrue: 'newPassword'),
      );
  }
}

// ---------------------------------------------------------------------------
// Input group
// ---------------------------------------------------------------------------

/// A field and its add-ons in one well (shadcn's InputGroup): [prefix] and
/// [suffix] (a unit, `https://`, a glyph, a small button) stand in the
/// well's ends, each on the wash past a hairline, the text between, read
/// left to right in any language (a value's parts, as an amount's). The
/// whole well lights as one while anything in it has focus, and a press on
/// it or on a plain add-on puts the caret in the text. ui_core's
/// [RawInputGroup] is the behaviour.
///
/// ```dart
/// FrostedInputGroup(labelText: 'Website', prefix: Text('https://'), suffix: Text('.com'), value: site, onChanged: (v) => setState(() => site = v))
/// ```
class FrostedInputGroup extends StatefulWidget {
  /// A field named [labelText] between [prefix] and [suffix].
  const FrostedInputGroup({
    required this.labelText,
    this.prefix,
    this.suffix,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.autofocus = false,
    super.key,
  });

  /// The field's name, over its well.
  final String labelText;

  /// The add-on at the well's start.
  final Widget? prefix;

  /// The add-on at the well's end.
  final Widget? suffix;

  /// The text, when the page owns it.
  final String? value;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// Called on Return.
  final ValueChanged<String>? onSubmitted;

  /// The text's controller, when the caller holds it.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// The placeholder.
  final String? hintText;

  /// {@macro frosted.helper}
  final String? helperText;

  /// {@macro frosted.error}
  final String? errorText;

  /// Whether it takes input.
  final bool enabled;

  /// The keyboard to raise.
  final TextInputType? keyboardType;

  /// Rules the text is held to.
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<FrostedInputGroup> createState() => _FrostedInputGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
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
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
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
      );
  }
}

class _FrostedInputGroupState extends State<FrostedInputGroup>
    with FrostedFieldOwner<FrostedInputGroup> {
  @override
  TextEditingController? controllerOf(FrostedInputGroup w) => w.controller;

  @override
  String? valueOf(FrostedInputGroup w) => w.value;

  @override
  FocusNode? focusNodeOf(FrostedInputGroup w) => w.focusNode;

  Widget _addOn(BuildContext context, Widget child, {required bool start}) {
    final t = context.frostedTheme;
    final hairline = BorderSide(color: t.colorScheme.border);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.glass.wash,
        border: BorderDirectional(
          end: start ? hairline : BorderSide.none,
          start: start ? BorderSide.none : hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedChromeMetrics.fieldInset,
        ),
        child: Center(
          widthFactor: 1,
          child: DefaultTextStyle.merge(
            style: t.textTheme.bodyLarge
                .line(19.2)
                .c(t.colorScheme.textSecondary),
            child: IconTheme.merge(
              data: IconThemeData(
                size: FrostedIconSize.i18,
                color: t.colorScheme.textTertiary,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;
    return RawInputDecorator(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: error,
      enabled: widget.enabled,
      focusNode: fieldFocus,
      builder: frostedFieldColumn,
      child: RawInputGroup(
        focusNode: fieldFocus,
        enabled: widget.enabled,
        isError: error != null,
        // At least the field's height, growing with larger text; the
        // add-ons stand as tall as the well, the line on its centre.
        builder: (context, states, child) => ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FrostedChromeMetrics.field,
          ),
          child: FrostedWell(
            focused: states.contains(WidgetState.focused),
            error: states.contains(WidgetState.error),
            enabled: widget.enabled,
            child: child,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FrostedCorners.r12),
          // The well reads left to right in any language, as the amount
          // well does: its add-ons are a value's parts (https:// and .com,
          // a currency, a unit). Under a right-to-left page the website
          // would read "com. | example | //:https".
          child: Directionality(
            textDirection: TextDirection.ltr,
            // The line answers taps from the well's top to its bottom.
            child: IntrinsicHeight(
              child: FrostedFieldRoom(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.prefix case final prefix?)
                      _addOn(context, prefix, start: true),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FrostedChromeMetrics.fieldInset,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FrostedBareField(
                            autofocus: widget.autofocus,
                            controller: fieldController,
                            focusNode: fieldFocus,
                            labelText: widget.labelText,
                            ownNode: false,
                            hintText: widget.hintText,
                            enabled: widget.enabled,
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                            keyboardType: widget.keyboardType,
                            inputFormatters: widget.inputFormatters,
                          ),
                        ),
                      ),
                    ),
                    if (widget.suffix case final suffix?)
                      _addOn(context, suffix, start: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One-time code
// ---------------------------------------------------------------------------

/// A one-time code in a row of boxes (shadcn's InputOTP): [length] wells
/// 48 wide and 56 tall, 8 apart, each holding one figure; the box the next
/// figure goes in rings in the accent while the field has focus, every box
/// takes the over ink when [errorText] says what is wrong. One real input
/// stands under the boxes, so a paste, the code from a message and
/// Backspace all just work. [onCompleted] hears the code once every box
/// is full. ui_core's [RawOtpField] is the behaviour.
///
/// ```dart
/// FrostedInputOtp(labelText: 'Code from your text', onCompleted: verify)
/// ```
class FrostedInputOtp extends StatelessWidget {
  /// A code of [length] figures.
  const FrostedInputOtp({
    this.length = 6,
    this.labelText,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType = TextInputType.number,
    this.inputFormatters = const [],
    this.autofillHints = const [AutofillHints.oneTimeCode],
    super.key,
  }) : assert(length > 0, 'A code has at least one digit.');

  /// How many figures the code has.
  final int length;

  /// The label over the boxes; a screen reader hears it as the field's
  /// name (the look's "One-time code" when null).
  final String? labelText;

  /// Called as the code changes.
  final ValueChanged<String>? onChanged;

  /// Called with the code once every box is full.
  final ValueChanged<String>? onCompleted;

  /// Called with the code when the keyboard's action key sends it.
  final ValueChanged<String>? onSubmitted;

  /// Run over what is typed or pasted, before the code keeps its figures.
  final List<TextInputFormatter> inputFormatters;

  /// What the platform may fill the boxes with (the code from a message).
  final Iterable<String> autofillHints;

  /// The code's controller, when the caller holds it.
  final RawOtpController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// What is wrong, under the boxes.
  final String? errorText;

  /// The help line under the boxes.
  final String? helperText;

  /// Whether each figure shows as a dot.
  final bool obscureText;

  /// Whether it takes focus on its first frame.
  final bool autofocus;

  /// Whether it takes input.
  final bool enabled;

  /// The keyboard to raise: figures, or [TextInputType.text] for letters too.
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final error = errorText;
    final helper = helperText;
    final label = labelText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.fieldLabelGap,
      children: [
        if (label != null) FrostedFieldLabel(label),
        RawOtpField(
          length: length,
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onCompleted: onCompleted,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          enabled: enabled,
          isError: error != null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          textDirection: Directionality.of(context),
          semanticLabel: label ?? words.oneTimeCode,
          contextMenuBuilder: (context, anchors, items) =>
              FrostedTextContextMenu(anchors: anchors, buttonItems: items),
          // The boxes keep their size while they fit; a column narrower
          // than the code shrinks the row whole.
          layoutBuilder: (context, slots) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedSpacing.s8,
              children: slots,
            ),
          ),
          slotBuilder: (context, slot) {
            final lit = slot.active && slot.focused;
            // 48 wide, at least 56 tall (larger text grows it), the figure
            // on its centre by alignment.
            final box = ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 48,
                maxWidth: 48,
                minHeight: 56,
              ),
              // Each box is a well, as every field is (FrostedWell): recessed
              // glass a step darker than what holds it, its rim the well's
              // light one. The next box clears as a focused field does; a
              // wrong one says so in the message under the boxes.
              child: FrostedCleared(
                level: lit ? 1 : 0,
                outline: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(FrostedCorners.r12),
                  ),
                ),
                child: FrostedFace(
                  material: FrostedMaterial.well,
                  radius: BorderRadius.circular(FrostedCorners.r12),
                  ring: frostedLitEdge(t, t.controlEdge),
                  edges: const EdgeInsets.all(FrostedStrokes.heavy),
                  child: Center(
                    child: slot.character.isEmpty
                        ? (lit
                              ? Container(
                                  width: FrostedStrokes.heavy,
                                  height: 24,
                                  color: t.colorScheme.accent,
                                )
                              : null)
                        : Text(
                            slot.obscured ? '•' : slot.character,
                            style: t.textTheme.amount.c(
                              t.colorScheme.textPrimary,
                            ),
                          ),
                  ),
                ),
              ),
            );
            return FrostedDim(off: !slot.enabled, child: box);
          },
        ),
        if (error != null)
          FrostedFieldHint(error, error: true)
        else if (helper != null)
          FrostedFieldHint(helper),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length, defaultValue: 6))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onCompleted',
          onCompleted,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
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
        DiagnosticsProperty<RawOtpController>(
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
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscure'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: TextInputType.number,
        ),
      );
  }
}

// ---------------------------------------------------------------------------
// Form field
// ---------------------------------------------------------------------------

/// A control with its label over it and its help or error under it, wired
/// as one (shadcn's Field, Material's FormField frame): a screen reader
/// hears the control named by [labelText], "required" when [required], then
/// the help or the error, and the error is announced as it appears. Use
/// it round a control that has no label of its own (a slider, a switch, a
/// set of chips, a segmented button, a switch row's group);
/// [FrostedTextField] and its kin carry theirs. A single control takes the
/// field's name as its own; a group keeps each control's node under the
/// field's name, so a tap reaches the control it lands on.
/// ui_core's [RawInputDecorator] is the behaviour.
///
/// ```dart
/// FrostedFormField(labelText: 'Notify me', helperText: 'Pick at least one', child: Row(children: [chipA, chipB]))
/// ```
class FrostedFormField extends StatelessWidget {
  /// [child] labelled [labelText].
  const FrostedFormField({
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.mergeSemantics,
    super.key,
  });

  /// The control.
  final Widget child;

  /// Whether [child] is one control whose node takes the field's name and
  /// hint (a slider, a switch), or a group of controls (a set of chips, a
  /// segmented button, radios, a stepper, a switch row's group), each keeping
  /// its own node with the field's name and hint on the group round them.
  /// Null decides by [child]: one of the look's groups, or a row, column or
  /// wrap of controls (through an [Align], [Padding], [SizedBox] or
  /// [ConstrainedBox]), is a group. Merged into one node, a group's controls
  /// gave every tap through semantics (a screen reader's, a browser's with
  /// semantics on) to the first of them. A group that names itself in the
  /// label's words (a segmented button labelled as its field) is heard once:
  /// the field adds no name of its own.
  final bool? mergeSemantics;

  static bool _isGroup(Widget w) => switch (w) {
    FrostedSegmentedButton() ||
    FrostedRadioGroup() ||
    FrostedChoices() ||
    FrostedToggleGroup() ||
    FrostedButtonGroup() ||
    FrostedFilterChipGroup() ||
    FrostedNumberField() ||
    FrostedColorPicker() ||
    FrostedIconPicker() ||
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
    FrostedSegmentedButton(:final label) => label,
    FrostedRadioGroup(labelText: final label) => label,
    FrostedNumberField(labelText: final label) => label,
    FrostedChoices(:final label) => label,
    FrostedToggleGroup(:final label) => label,
    FrostedButtonGroup(:final label) => label,
    FrostedFilterChipGroup(:final label) => label,
    FrostedIconPicker(:final label) => label,
    Align(:final child?) ||
    Padding(:final child?) ||
    SizedBox(:final child?) ||
    ConstrainedBox(:final child?) => _ownName(child),
    _ => null,
  };

  /// The control's name, over it.
  final String? labelText;

  /// The help line under it.
  final String? helperText;

  /// {@macro frosted.error}
  final String? errorText;

  /// Whether the control must be filled: a mark after the label.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus, so the label can follow it.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final merge = mergeSemantics ?? !_isGroup(child);
    // A group that already says the label's words on its own node: the
    // field draws the label but does not say it, so it is read once, not
    // "Priority, Priority" (ui_core 0.3.2's rule, which applies when a field
    // decides for itself).
    final own = merge ? null : _ownName(child)?.trim().toLowerCase();
    final heard = own != null && own == labelText?.trim().toLowerCase();
    return RawInputDecorator(
      labelText: heard ? null : labelText,
      helperText: helperText,
      errorText: errorText,
      required: required,
      enabled: enabled,
      focusNode: focusNode,
      mergeSemantics: merge,
      requiredHint: RawWidgetsLocalizations.of(context).requiredHint,
      builder: (context, parts) {
        final head =
            parts.label ??
            (heard ? ExcludeSemantics(child: Text(labelText!)) : null);
        final hint = parts.error ?? parts.helper;
        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedChromeMetrics.fieldLabelGap,
          children: [
            if (head != null)
              DefaultTextStyle.merge(
                style: t.textTheme.labelSmall.line(15.6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: head),
                    if (parts.required)
                      ExcludeSemantics(
                        child: Text(
                          ' *',
                          style: TextStyle(color: t.colorScheme.over),
                        ),
                      ),
                  ],
                ),
              ),
            parts.control,
            if (hint != null)
              DefaultTextStyle.merge(
                style: parts.error != null
                    ? t.textTheme.bodySmall.line(15.6).c(t.colorScheme.over)
                    : t.textTheme.bodySmall.line(15.6),
                child: hint,
              ),
          ],
        );
        return FrostedDim(off: !parts.enabled, child: column);
      },
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty(
          'mergeSemantics',
          value: mergeSemantics,
          ifTrue: 'mergeSemantics: true',
          ifFalse: 'mergeSemantics: false',
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      );
  }
}
