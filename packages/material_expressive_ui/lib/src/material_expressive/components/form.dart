/// Fields ui_core's form behaviours hold, painted in the outlined text
/// field's hand: [ExpressiveInputGroup] (a field and its add-ons as one
/// control, on `DesignInputGroup`) and [ExpressiveFormField] (any control
/// with its label, help and error, on `DesignField`).
library;

import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/state_face.dart';
import '../spacing.dart';
import '../theme.dart';
import 'lists.dart' show ExpressiveDivider;

/// A field and its add-ons as one control (shadcn's `InputGroup`): a
/// scheme's `https://` before the input, a unit or a copy button after it,
/// all inside the outlined text field's container, a hairline between each
/// add-on and the input. The container's outline is the text field's: 1dp
/// `outline`, `onSurface` under a pointer, 2dp `primary` while anything
/// inside has focus, `error` with [isError]. A press anywhere on the frame
/// focuses the input (ui_core's `DesignInputGroup`).
///
/// [leading] and [trailing] hold the add-ons: words with
/// [ExpressiveInputGroup.text], or a small icon button.
///
/// ```dart
/// ExpressiveInputGroup(hintText: 'example.com', leading: [ExpressiveInputGroup.text('https://')])
/// ```
class ExpressiveInputGroup extends StatefulWidget {
  /// An input with [leading] and [trailing] add-ons.
  const ExpressiveInputGroup({
    this.controller,
    this.focusNode,
    this.hintText,
    this.semanticLabel,
    this.leading = const <Widget>[],
    this.trailing = const <Widget>[],
    this.enabled = true,
    this.isError = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  /// Words as an add-on, in `bodyLarge` `onSurfaceVariant`: a scheme, a
  /// unit, a currency.
  static Widget text(String text) => _AddonText(text);

  /// The text; one is made when null.
  final TextEditingController? controller;

  /// The input's focus; one is made when null.
  final FocusNode? focusNode;

  /// Shown while the input is empty.
  final String? hintText;

  /// What a screen reader calls the input.
  final String? semanticLabel;

  /// Add-ons before the input.
  final List<Widget> leading;

  /// Add-ons after the input.
  final List<Widget> trailing;

  /// Whether it takes input.
  final bool enabled;

  /// Whether the value is wrong: the error outline.
  final bool isError;

  /// The keyboard.
  final TextInputType? keyboardType;

  /// The keyboard's action.
  final TextInputAction? textInputAction;

  /// Each edit.
  final ValueChanged<String>? onChanged;

  /// Enter.
  final ValueChanged<String>? onSubmitted;

  @override
  State<ExpressiveInputGroup> createState() => _ExpressiveInputGroupState();
}

class _ExpressiveInputGroupState extends State<ExpressiveInputGroup> {
  TextEditingController? _ownController;
  FocusNode? _ownNode;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _node =>
      widget.focusNode ??
      (_ownNode ??= FocusNode(debugLabel: 'ExpressiveInputGroup'));

  @override
  void dispose() {
    _ownController?.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = SizedBox(
      height: ExpressiveSpacing.s24,
      child: const ExpressiveDivider(vertical: true),
    );
    return DesignInputGroup(
      focusNode: _node,
      enabled: widget.enabled,
      isError: widget.isError,
      builder: (context, states, child) =>
          ExpressiveFieldFrame(states: states, child: child),
      child: Row(
        children: <Widget>[
          for (final addon in widget.leading) ...<Widget>[addon, divider],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ExpressiveSpacing.s12,
              ),
              child: ExpressiveBareField(
                controller: _controller,
                focusNode: _node,
                hintText: widget.hintText,
                semanticLabel: widget.semanticLabel,
                enabled: widget.enabled,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ),
          for (final addon in widget.trailing) ...<Widget>[divider, addon],
        ],
      ),
    );
  }
}

class _AddonText extends StatelessWidget {
  const _AddonText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ExpressiveSpacing.s12),
      child: Text(
        text,
        style: t.type.bodyLarge.copyWith(color: t.colors.onSurfaceVariant),
      ),
    );
  }
}

/// A control with its label above it and its help or error under it
/// (shadcn's `FormField`; ui_core's `DesignField`): the label in
/// `labelLarge` `onSurface` (`primary` while the control has focus, `error`
/// with [error]), a required field's asterisk after it, the help in
/// `bodySmall` `onSurfaceVariant` and the error in its place in `error`, as
/// a text field's supporting text. A screen reader hears the label as the
/// control's name and the error and help as its hint, once. Wrap the
/// fields in ui_core's `DesignForm` to validate them together.
///
/// ```dart
/// ExpressiveFormField(label: 'Notify me', help: 'At most once a day', child: ExpressiveSwitch(value: on, onChanged: setOn))
/// ```
class ExpressiveFormField extends StatelessWidget {
  /// [child] labelled [label].
  const ExpressiveFormField({
    required this.child,
    this.label,
    this.help,
    this.error,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.group = false,
    super.key,
  });

  /// The control.
  final Widget child;

  /// What the control is.
  final String? label;

  /// A line of help under it.
  final String? help;

  /// What is wrong; null while the value is fine.
  final String? error;

  /// Whether it must be filled: an asterisk after the label.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus, for the label's focused colour.
  final FocusNode? focusNode;

  /// Whether [child] is a group of controls (radios): the label names the
  /// group rather than one control.
  final bool group;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    return DesignField(
      labelText: label,
      helperText: help,
      errorText: error,
      required: required,
      enabled: enabled,
      focusNode: focusNode,
      mergeSemantics: !group,
      builder: (context, parts) {
        final labelColor = !parts.enabled
            ? c.onSurface.withValues(alpha: 0.38)
            : parts.hasError
            ? c.error
            : parts.focused
            ? c.primary
            : c.onSurface;
        final labelText = parts.label;
        final below = parts.error ?? parts.helper;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (labelText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: ExpressiveSpacing.s8),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: DefaultTextStyle(
                        style: t.type.labelLarge.copyWith(color: labelColor),
                        child: labelText,
                      ),
                    ),
                    if (parts.required)
                      ExcludeSemantics(
                        child: Text(
                          ' *',
                          style: t.type.labelLarge.copyWith(
                            color: parts.enabled
                                ? c.error
                                : c.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            parts.control,
            if (below != null)
              Padding(
                padding: const EdgeInsets.only(top: ExpressiveSpacing.s4),
                child: DefaultTextStyle(
                  style: t.type.bodySmall.copyWith(
                    color: parts.hasError ? c.error : c.onSurfaceVariant,
                  ),
                  child: below,
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}
