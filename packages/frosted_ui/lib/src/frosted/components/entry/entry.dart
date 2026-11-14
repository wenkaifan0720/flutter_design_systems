import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../editing.dart';
import '../../glyphs.dart';
import '../../internal/bare_field.dart';
import '../../internal/face.dart';
import '../../internal/field_owner.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../forms/forms.dart';
import '../icon-button/round_button.dart';
import '../../internal/dim.dart';

// ---------------------------------------------------------------------------
// Password field
// ---------------------------------------------------------------------------

/// A password in a [FrostedTextField]'s well, its eye at the end showing or
/// hiding it (shadcn's password input): the text hidden at first, the eye
/// saying what it will do ("Show password"), the caret and focus kept as it
/// flips. Autofill fills it as a password ([newPassword] for a new one).
/// ui_core's [DesignPasswordReveal] is the behaviour.
///
/// ```dart
/// FrostedPasswordField(label: 'Password', value: password, onChanged: (v) => setState(() => password = v))
/// ```
class FrostedPasswordField extends StatelessWidget {
  /// A password field named [label].
  const FrostedPasswordField({
    required this.label,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.autofocus = false,
    this.newPassword = false,
    super.key,
  });

  /// The field's name, over its well.
  final String label;

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
  final String? hint;

  /// The help line under the well.
  final String? helper;

  /// What is wrong, in place of the help line.
  final String? error;

  /// Whether it takes input.
  final bool enabled;

  /// Whether it takes focus on its first frame.
  final bool autofocus;

  /// Whether it is a new password (autofill offers to make one).
  final bool newPassword;

  @override
  Widget build(BuildContext context) {
    return DesignPasswordReveal(
      focusNode: focusNode,
      showLabel: DesignLocalizations.of(context).showPasswordLabel,
      hideLabel: DesignLocalizations.of(context).hidePasswordLabel,
      builder: (context, password) => FrostedTextField(
        label: label,
        value: value,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        focusNode: focusNode,
        hint: hint,
        helper: helper,
        error: error,
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
/// [DesignInputGroup] is the behaviour.
///
/// ```dart
/// FrostedInputGroup(label: 'Website', prefix: Text('https://'), suffix: Text('.com'), value: site, onChanged: (v) => setState(() => site = v))
/// ```
class FrostedInputGroup extends StatefulWidget {
  /// A field named [label] between [prefix] and [suffix].
  const FrostedInputGroup({
    required this.label,
    this.prefix,
    this.suffix,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.autofocus = false,
    super.key,
  });

  /// The field's name, over its well.
  final String label;

  /// The add-on at the well's start.
  final Widget? prefix;

  /// The add-on at the well's end.
  final Widget? suffix;

  /// The text, when the page owns it.
  final String? value;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Called on Return.
  final ValueChanged<String>? onSubmitted;

  /// The text's controller, when the caller holds it.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// The placeholder.
  final String? hint;

  /// The help line under the well.
  final String? helper;

  /// What is wrong, in place of the help line.
  final String? error;

  /// Whether it takes input.
  final bool enabled;

  /// The keyboard to raise.
  final TextInputType? keyboardType;

  /// Rules the text is held to.
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<FrostedInputGroup> createState() => _FrostedInputGroupState();
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
    final error = widget.error;
    final helper = widget.helper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.fieldLabelGap,
      children: [
        FrostedFieldLabel(widget.label),
        DesignInputGroup(
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
            // read "com. | example | //:https" (self-review round 3).
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: IntrinsicHeight(
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
                            label: widget.label,
                            hint: widget.hint,
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
        if (error != null)
          FrostedFieldHint(error, error: true)
        else if (helper != null)
          FrostedFieldHint(helper),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// One-time code
// ---------------------------------------------------------------------------

/// A one-time code in a row of boxes (shadcn's InputOTP): [length] wells
/// 48 wide and 56 tall, 8 apart, each holding one figure; the box the next
/// figure goes in rings in the accent while the field has focus, every box
/// takes the over ink when [error] says what is wrong. One real input
/// stands under the boxes, so a paste, the code from a message and
/// Backspace all just work. [onCompleted] hears the code once every box
/// is full. ui_core's [DesignOtpField] is the behaviour.
///
/// ```dart
/// FrostedInputOtp(label: 'Code from your text', onCompleted: verify)
/// ```
class FrostedInputOtp extends StatelessWidget {
  /// A code of [length] figures.
  const FrostedInputOtp({
    this.length = 6,
    this.label,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.error,
    this.helper,
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType = TextInputType.number,
    this.inputFormatters = const [],
    this.autofillHints = const [AutofillHints.oneTimeCode],
    super.key,
  });

  /// How many figures the code has.
  final int length;

  /// The label over the boxes; a screen reader hears it as the field's
  /// name (the look's "One-time code" when null).
  final String? label;

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
  final DesignOtpController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// What is wrong, under the boxes.
  final String? error;

  /// The help line under the boxes.
  final String? helper;

  /// Whether each figure shows as a dot.
  final bool obscure;

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
    final error = this.error;
    final helper = this.helper;
    final label = this.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.fieldLabelGap,
      children: [
        if (label != null) FrostedFieldLabel(label),
        DesignOtpField(
          length: length,
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onCompleted: onCompleted,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          enabled: enabled,
          isError: error != null,
          obscureText: obscure,
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
              // glass a step darker than what holds it, its fill by day the
              // field's own while it is next or wrong. As opaque paint it
              // stood whiter than its card, not cut into it (round 10).
              child: FrostedFace(
                material: FrostedMaterial.well,
                radius: BorderRadius.circular(FrostedCorners.r12),
                color: t.isDark
                    ? null
                    : slot.isError
                    ? t.colorScheme.overTint
                    : lit
                    ? t.glass.plane.withValues(alpha: .6)
                    : null,
                // The next box's edge in the accent at the heavy stroke
                // (the over ink when wrong); the rest keep the well's ring.
                ring: lit || slot.isError
                    ? null
                    : frostedLitEdge(t, t.controlEdge),
                edge: slot.isError
                    ? (t.isDark ? t.colorScheme.over : _warmLight(t))
                    : lit
                    ? (t.isDark
                          ? t.colorScheme.accent
                          : const Color(0xFFFFFFFF))
                    : null,
                shadows: lit && !t.isDark
                    ? const [
                        BoxShadow(color: Color(0xF2FFFFFF), blurRadius: 10),
                      ]
                    : const <BoxShadow>[],
                edges: EdgeInsets.all(FrostedStrokes.heavy),
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
}

// ---------------------------------------------------------------------------
// Form field
// ---------------------------------------------------------------------------

/// A control with its label over it and its help or error under it, wired
/// as one (shadcn's Field, Material's FormField frame): a screen reader
/// hears the control named by [label], "required" when [required], then
/// the help or the error, and the error is announced as it appears. Use
/// it round a control that has no label of its own (a slider, a switch, a
/// set of chips or a switch row's group, the last two with
/// [mergeSemantics] false); [FrostedTextField] and its kin carry theirs.
/// ui_core's [DesignField] is the behaviour.
///
/// ```dart
/// FrostedFormField(label: 'Notify me', helper: 'Pick at least one', mergeSemantics: false, child: Row(children: [chipA, chipB]))
/// ```
class FrostedFormField extends StatelessWidget {
  /// [child] labelled [label].
  const FrostedFormField({
    required this.child,
    this.label,
    this.helper,
    this.error,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.mergeSemantics = true,
    super.key,
  });

  /// The control.
  final Widget child;

  /// Whether [child] is one control whose node takes the field's name and
  /// hint (a slider, a switch); false for a group of controls (a set of
  /// chips, a switch row's group), each keeping its own node, the field's
  /// name and hint on the group round them.
  final bool mergeSemantics;

  /// The control's name, over it.
  final String? label;

  /// The help line under it.
  final String? helper;

  /// What is wrong, in place of the help line.
  final String? error;

  /// Whether the control must be filled: a mark after the label.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus, so the label can follow it.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return DesignField(
      labelText: label,
      helperText: helper,
      errorText: error,
      required: required,
      enabled: enabled,
      focusNode: focusNode,
      mergeSemantics: mergeSemantics,
      requiredHint: DesignLocalizations.of(context).requiredHint,
      builder: (context, parts) {
        final head = parts.label;
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
}

// A wrong box's rim by day: the over hue warmed into the light, not a dark
// line.
Color _warmLight(FrostedThemeData t) =>
    Color.lerp(const Color(0xFFFFFFFF), t.colorScheme.over, .55)!;
