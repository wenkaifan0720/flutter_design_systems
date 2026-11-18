/// One line of words with no box of its own, for a part that draws its own
/// well round it (a combobox, a tag input).
library;

import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// A bare line of words in the look's print, its caret in the signal.
class ApplianceBareField extends StatelessWidget {
  /// Words in [controller], focused by [focusNode].
  const ApplianceBareField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.minHeight,
    this.hint,
    this.semanticLabel,
    this.enabled = true,
    this.onChanged,
    this.onEditingComplete,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
  });

  /// The words.
  final TextEditingController controller;

  /// Its focus.
  final FocusNode focusNode;

  /// The height the line is centred in.
  final double minHeight;

  /// What it says while empty.
  final String? hint;

  /// Its name for a screen reader (the part's label, shown above it).
  final String? semanticLabel;

  /// Whether it takes words.
  final bool enabled;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Takes Enter, keeping the focus (no `onSubmitted`: on the web a field
  /// that keeps the focus after a submit loses its typing).
  final VoidCallback? onEditingComplete;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Formatters run on every change.
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final words = theme.textTheme.body.copyWith(
      color: enabled ? c.print : c.printDisabled,
    );
    // A node of its own: the words' render object is no semantics boundary,
    // so without one the entry's flags and name land on whatever node holds
    // it (the well round a lens, a page's column).
    return Semantics(
      container: true,
      child: Semantics(
        label: semanticLabel,
        child: DesignTextEntryBox(
          minHeight: minHeight,
          controller: controller,
          maxLines: 1,
          hint: hint == null
              ? null
              : Text(
                  hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: words.copyWith(color: c.printMuted),
                ),
          child: Material(
            type: MaterialType.transparency,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: null,
              style: words,
              cursorColor: c.signal,
              cursorWidth: 2,
              enabled: enabled,
              onChanged: onChanged,
              onEditingComplete: onEditingComplete,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
            ),
          ),
        ),
      ),
    );
  }
}
