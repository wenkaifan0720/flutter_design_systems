import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/measure.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../input/field_core.dart';
import '../pressable/pressable.dart';

/// What a field's validation says, Fluent's `validationState`: [error]
/// the red diamond and red words (and the control's red stroke),
/// [warning] the orange warning, [success] the green check, [none] the
/// words alone in the third ink.
enum Fluent2ValidationState {
  /// No validation message.
  none,

  /// An error: the message and its glyph in the danger colour.
  error,

  /// A warning: its glyph in the warning colour.
  warning,

  /// A success: its glyph in the success colour.
  success,
}

/// How a field lays out, Fluent's `orientation`: [vertical] the label
/// over the control, [horizontal] the label in the start third beside it
/// (vertical again once the field is under 400 wide).
enum Fluent2FieldOrientation {
  /// The label above the control.
  vertical,

  /// The label before the control.
  horizontal,
}

/// A label's weight, Fluent's Label `weight`.
enum Fluent2LabelWeight {
  /// A regular label.
  regular,

  /// A semibold label.
  semibold,
}

/// Fluent 2's Label: [text] in body1 (caption1 small, 16/22 semibold
/// large) in the first ink, and, when [required], the asterisk 4 after it
/// in `paletteRedForeground1` (Fluent's `paletteRedForeground3` misses
/// 4.5:1 on the light presets' ground); the disabled ink when not [enabled].
///
/// ```dart
/// Fluent2Label('Display name', required: true)
/// ```
class Fluent2Label extends StatelessWidget {
  /// A label reading [text].
  const Fluent2Label(
    this.text, {
    this.required = false,
    this.size = Fluent2InputSize.medium,
    this.weight = Fluent2LabelWeight.regular,
    this.enabled = true,
    super.key,
  });

  /// The label's words.
  final String text;

  /// Whether the field must be filled (a red asterisk follows).
  final bool required;

  /// Fluent's `size`: small, medium or large type.
  final Fluent2InputSize size;

  /// Fluent's `weight`: regular or semibold.
  final Fluent2LabelWeight weight;

  /// False draws it in the disabled ink.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    var style = switch (size) {
      Fluent2InputSize.small => t.caption1,
      Fluent2InputSize.medium => t.body1,
      Fluent2InputSize.large => t.subtitle2,
    };
    if (weight == Fluent2LabelWeight.semibold) style = style.strong;
    return Semantics(
      label: required ? '$text, required' : text,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: enabled
                      ? t.sharedColors.paletteRedForeground1
                      : t.colors.neutralForegroundDisabled,
                ),
              ),
          ],
        ),
        style: style.c(
          enabled
              ? t.colors.neutralForeground1
              : t.colors.neutralForegroundDisabled,
        ),
      ),
    );
  }
}

/// Fluent 2's InfoLabel: a [Fluent2Label] with the info button after it
/// (the 16 info glyph, 12 small and 20 large, in the second ink, its
/// filled design and the brand ink under the pointer, 4 round it) that
/// opens a popover (at most 264 wide, 12 round its words in caption1,
/// body1 large) saying [info]. Read as the label, then a button named
/// "Information about" the label.
///
/// ```dart
/// Fluent2InfoLabel('Retention', info: 'Files in the bin are deleted after 30 days.')
/// ```
class Fluent2InfoLabel extends StatefulWidget {
  /// A label reading [text], an info button after it.
  const Fluent2InfoLabel(
    this.text, {
    required this.info,
    this.required = false,
    this.size = Fluent2InputSize.medium,
    this.enabled = true,
    super.key,
  });

  /// The label's words.
  final String text;

  /// What the popover says.
  final String info;

  /// Whether the field must be filled (a red asterisk follows).
  final bool required;

  /// Fluent's `size`: small, medium or large type.
  final Fluent2InputSize size;

  /// False draws it in the disabled ink.
  final bool enabled;

  @override
  State<Fluent2InfoLabel> createState() => _Fluent2InfoLabelState();
}

class _Fluent2InfoLabelState extends State<Fluent2InfoLabel> {
  final _portal = OverlayPortalController();

  void _toggle() => setState(_portal.isShowing ? _portal.hide : _portal.show);

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final (glyph, filled, size) = switch (widget.size) {
      Fluent2InputSize.small => (
        Fluent2Icons.info16,
        Fluent2Icons.info16Filled,
        12.0,
      ),
      Fluent2InputSize.medium => (
        Fluent2Icons.info16,
        Fluent2Icons.info16Filled,
        16.0,
      ),
      Fluent2InputSize.large => (
        Fluent2Icons.info,
        Fluent2Icons.infoFilled,
        20.0,
      ),
    };
    final open = _portal.isShowing;
    final button = Fluent2FieldPopover(
      controller: _portal,
      width: 264,
      minWidth: 120,
      onDismiss: () => setState(_portal.hide),
      popover: (context) => Fluent2PopoverSurface(
        padding: const EdgeInsets.all(Fluent2Spacing.m),
        child: Semantics(
          liveRegion: true,
          child: Text(
            widget.info,
            style:
                (widget.size == Fluent2InputSize.large ? t.body1 : t.caption1)
                    .c(c.neutralForeground1),
          ),
        ),
      ),
      child: Fluent2Pressable(
        onPressed: widget.enabled ? _toggle : null,
        label: Fluent2Localizations.of(context).informationAbout(widget.text),
        selected: open,
        radius: Fluent2Radius.medium,
        builder: (context, states) {
          final press = states.press;
          final lit =
              open ||
              press == Fluent2Press.hover ||
              press == Fluent2Press.pressed;
          return Container(
            padding: EdgeInsets.all(
              widget.size == Fluent2InputSize.large
                  ? Fluent2Spacing.xxs
                  : Fluent2Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: open
                  ? c.transparentBackgroundSelected
                  : press.pick(
                      c.transparentBackground,
                      c.transparentBackgroundHover,
                      c.transparentBackgroundPressed,
                    ),
              borderRadius: BorderRadius.circular(Fluent2Radius.medium),
            ),
            child: Icon(
              lit ? filled : glyph,
              size: size,
              color: open
                  ? c.neutralForeground2BrandSelected
                  : press.pick(
                      c.neutralForeground2,
                      c.neutralForeground2BrandHover,
                      c.neutralForeground2BrandPressed,
                      c.neutralForegroundDisabled,
                    ),
            ),
          );
        },
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Fluent2Label(
            widget.text,
            required: widget.required,
            size: widget.size,
            enabled: widget.enabled,
          ),
        ),
        button,
      ],
    );
  }
}

/// The validation line under a control: the 12 state glyph 4 before its
/// words in caption1, the words red for an error and in the third ink
/// otherwise; an error is announced as it appears.
class _Validation extends StatelessWidget {
  const _Validation(this.state, this.message);

  final Fluent2ValidationState state;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final s = t.sharedColors;
    final (IconData? glyph, Color ink) = switch (state) {
      Fluent2ValidationState.error => (
        Fluent2Icons.diamondDismissFilled,
        s.paletteRedForeground1,
      ),
      Fluent2ValidationState.warning => (
        Fluent2Icons.warningFilled,
        s.paletteDarkOrangeForeground1,
      ),
      Fluent2ValidationState.success => (
        Fluent2Icons.checkmarkCircleFilled,
        s.paletteGreenForeground1,
      ),
      Fluent2ValidationState.none => (null, t.colors.neutralForeground3),
    };
    final words = state == Fluent2ValidationState.error
        ? s.paletteRedForeground1
        : t.colors.neutralForeground3;
    return Semantics(
      liveRegion: state == Fluent2ValidationState.error,
      child: Padding(
        padding: const EdgeInsets.only(top: Fluent2Spacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (glyph != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: Fluent2Spacing.xxs,
                  end: Fluent2Spacing.xs,
                ),
                child: Icon(glyph, size: 12, color: ink),
              ),
            Expanded(child: Text(message, style: t.caption1.c(words))),
          ],
        ),
      ),
    );
  }
}

/// Fluent 2's Field: its [label] (a [Fluent2Label], or a [Fluent2InfoLabel]
/// when [info] is given; the asterisk when [required]) 4 over the
/// [child] control, then the validation line ([validationMessage] with its
/// [validationState]'s glyph: an error by default) and the [hint] in
/// caption1 in the third ink, 2 apart. The control takes the field's label
/// as its spoken name and, for an error, its red stroke.
/// [Fluent2FieldOrientation.horizontal] stands the label in the start third.
///
/// ```dart
/// Fluent2FormField(label: 'Email', required: true, helper: 'We send the invite here.', child: Fluent2TextField(value: email, onChanged: (v) => setState(() => email = v)))
/// ```
class Fluent2FormField extends StatelessWidget {
  /// A form field: [label] over [child], with its hint and validation under.
  const Fluent2FormField({
    required this.child,
    this.label,
    this.required = false,
    this.helper,
    this.validationMessage,
    this.validationState,
    this.info,
    this.orientation = Fluent2FieldOrientation.vertical,
    this.size = Fluent2InputSize.medium,
    super.key,
  });

  /// The control the field labels.
  final Widget child;

  /// The label's words; null shows none.
  final String? label;

  /// Whether the field must be filled (a red asterisk follows its label).
  final bool required;

  /// A hint under the control; null shows none.
  final String? helper;

  /// The validation message under the control; null shows none.
  final String? validationMessage;

  /// Null is an error once there is a [validationMessage], else none.
  final Fluent2ValidationState? validationState;

  /// What the label's info button says; null draws a plain label.
  final String? info;

  /// The label above the control, or before it.
  final Fluent2FieldOrientation orientation;

  /// Fluent's `size`: the label's type.
  final Fluent2InputSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final state =
        validationState ??
        (validationMessage != null
            ? Fluent2ValidationState.error
            : Fluent2ValidationState.none);
    final words = label;
    final Widget? head = words == null
        ? null
        : info != null
        ? Fluent2InfoLabel(words, info: info!, required: required, size: size)
        : ExcludeSemantics(
            child: Fluent2Label(words, required: required, size: size),
          );
    final message = validationMessage;
    final error = state == Fluent2ValidationState.error;
    // The lines under the control are drawn for the eye; a screen reader
    // hears them as the control's hint (the design kit's DesignField).
    final under = [
      if (message != null) ExcludeSemantics(child: _Validation(state, message)),
      if (helper != null)
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: Fluent2Spacing.xxs),
            child: Text(
              helper!,
              style: t.caption1.c(t.colors.neutralForeground3),
            ),
          ),
        ),
    ];
    // A warning or a success is said as help; only an error marks the
    // control invalid.
    final help = [if (message != null && !error) message, ?helper];
    return DesignField(
      labelText: words,
      helperText: help.isEmpty ? null : help.join(' '),
      errorText: error ? message : null,
      required: required,
      requiredHint: DesignLocalizations.of(context).requiredHint,
      // The control's own name comes from the field, so the scope gives it
      // none: the field's node says the label once.
      child: Fluent2FieldScope(
        label: null,
        required: required,
        invalid: error,
        child: child,
      ),
      builder: (context, parts) =>
          _layout(context, head: head, control: parts.control, under: under),
    );
  }

  Widget _layout(
    BuildContext context, {
    required Widget? head,
    required Widget control,
    required List<Widget> under,
  }) {
    Widget vertical() => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (head != null)
          Padding(
            // Fluent: 2 over and under the label and 2 after it (large: 1
            // and 4).
            padding: size == Fluent2InputSize.large
                ? const EdgeInsets.only(top: 1, bottom: 1 + Fluent2Spacing.xs)
                : const EdgeInsets.only(
                    top: Fluent2Spacing.xxs,
                    bottom: Fluent2Spacing.xxs * 2,
                  ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: head,
            ),
          ),
        control,
        ...under,
      ],
    );
    if (orientation == Fluent2FieldOrientation.vertical) return vertical();
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 400) return vertical();
        // The label beside: a third of the width, 6 over it (4 small, 9
        // large) so its line sits on the control's, 12 after it.
        final top = switch (size) {
          Fluent2InputSize.small => Fluent2Spacing.xs,
          Fluent2InputSize.medium => Fluent2Spacing.sNudge,
          Fluent2InputSize.large => 9.0,
        };
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: box.maxWidth / 3,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: top,
                  end: Fluent2Spacing.m,
                ),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: head ?? const SizedBox.shrink(),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [control, ...under],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A titled group of fields, as Fluent's forms and settings pages set
/// them: the [title] in subtitle2 (a header to a screen reader) and its
/// [description] in body1 in the third ink 4 under it, then the
/// [children] (fields, a checkbox, a switch) 16 apart, 12 under the head,
/// and a [footnote] in caption1 under the last.
///
/// ```dart
/// Fluent2FormSection(title: 'Notifications', description: 'How Northwind reaches you.', children: [Fluent2FormField(label: 'Email', child: Fluent2TextField(value: email, onChanged: setEmail)), Fluent2Switch(value: push, label: 'Push notifications', onChanged: setPush)])
/// ```
class Fluent2FormSection extends StatelessWidget {
  /// A section of a form: [title] and [description] over [children].
  const Fluent2FormSection({
    required this.children,
    this.title,
    this.description,
    this.footnote,
    super.key,
  });

  /// The section's fields, in order.
  final List<Widget> children;

  /// The section's heading; null shows none.
  final String? title;

  /// A line under the heading; null shows none.
  final String? description;

  /// A quiet line under the fields; null shows none.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final head = title;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      // A reading measure: on a wide page the form stops at 560 from its
      // start. The head, the fields and the choices share the section's
      // keylines (the keyline check).
      child: Align(
        alignment: AlignmentDirectional.topStart,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: fluent2FormMeasure),
          child: DesignKeylineRegion(
            label: head ?? 'Form',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (head != null)
                  Semantics(
                    header: true,
                    child: Text(head, style: t.subtitle2),
                  ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Fluent2Spacing.xs),
                    child: Text(
                      description!,
                      style: t.body1.c(t.colors.neutralForeground3),
                    ),
                  ),
                if (head != null || description != null)
                  const SizedBox(height: Fluent2Spacing.m),
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: Fluent2Spacing.l),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: null,
                    child: children[i],
                  ),
                ],
                if (footnote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Fluent2Spacing.m),
                    child: Text(
                      footnote!,
                      style: t.caption1.c(t.colors.neutralForeground3),
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
