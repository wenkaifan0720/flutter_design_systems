import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:ui_core/ui_core.dart';

import 'face.dart';
import 'lists.dart';
import 'theme.dart';

/// A one-line text field with a label above, a hint inside, and help or an
/// error below: Flutter's [TextField] for the typing (IME, selection,
/// autofill, a screen reader's text field), its decoration null, inside the
/// look's own box; ui_core's [RawInputDecorator] for the label, help and
/// error a screen reader hears.
///
/// ```dart
/// LookTextField(label: 'Name', hint: 'Ada Lovelace', controller: controller)
/// ```
class LookTextField extends StatefulWidget {
  /// A field labelled [label].
  const LookTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.enabled = true,
  });

  /// What the field is for, above it.
  final String label;

  /// An example of what to type, shown while it is empty.
  final String? hint;

  /// Help below the field.
  final String? helperText;

  /// What is wrong with the value, below the field in place of the help.
  final String? errorText;

  /// The text. The caller's, who disposes it; null: the field keeps its own.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Whether it takes input.
  final bool enabled;

  @override
  State<LookTextField> createState() => _LookTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _LookTextFieldState extends State<LookTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void didUpdateWidget(LookTextField old) {
    super.didUpdateWidget(old);
    // A controller or node handed in later replaces the one the field made.
    if (widget.controller != null && _ownController != null) {
      _ownController!.dispose();
      _ownController = null;
    }
    if (widget.focusNode != null && _ownFocusNode != null) {
      _ownFocusNode!.dispose();
      _ownFocusNode = null;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    final c = theme.colors;
    final entryStyle = theme.body.copyWith(height: 1.2);
    Widget entry = TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      decoration: null,
      style: entryStyle,
      cursorColor: c.accent,
    );
    // A look that stands on no Material: TextField asks for one above it.
    if (Material.maybeOf(context) == null) {
      entry = Material(type: MaterialType.transparency, child: entry);
    }
    return RawInputDecorator(
      labelText: widget.label,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      focusNode: _focusNode,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A tap on the label focuses the entry, so the label shows the
          // pointer the entry shows.
          if (parts.label != null)
            MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.text
                  : SystemMouseCursors.basic,
              child: DefaultTextStyle(
                style: theme.label.copyWith(color: c.ink),
                child: parts.label!,
              ),
            ),
          const SizedBox(height: 6),
          // The field's own rule changes with focus and error: no ring is
          // added round it. A press anywhere on the face, the side padding
          // too, focuses the entry: the face is the field's seat.
          MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.enabled ? _focusNode.requestFocus : null,
              child: AnimatedLookSurface(
                // The face a select and a combobox stand on too.
                face: lookFieldFace(
                  theme,
                  focused: parts.focused,
                  error: parts.errorText != null,
                  enabled: widget.enabled,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme.radius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: parts.control,
                ),
              ),
            ),
          ),
          if (parts.error != null || parts.helper != null) ...[
            const SizedBox(height: 6),
            DefaultTextStyle(
              style: theme.body.copyWith(
                fontSize: 13,
                color: parts.error != null ? c.danger : c.mutedInk,
              ),
              child: parts.error ?? parts.helper!,
            ),
          ],
        ],
      ),
      child: Semantics(
        hint: widget.hint,
        child: DesignCapCenter(
          capHeightFactor: theme.capHeightFactor,
          child: DesignTextEntryBox(
            // A press anywhere in the box reaches the entry, so the box
            // itself is the tap target: at least the floor for the input
            // the platform reaches it with, whatever the density.
            minHeight: math.max(
              theme.density.height(theme.controlHeight),
              DesignTapTargets.of(context).floorOn().height,
            ),
            controller: _controller,
            hint: widget.hint == null
                ? null
                : Text(
                    widget.hint!,
                    style: entryStyle.copyWith(color: c.mutedInk),
                  ),
            child: entry,
          ),
        ),
      ),
    );
  }
}
