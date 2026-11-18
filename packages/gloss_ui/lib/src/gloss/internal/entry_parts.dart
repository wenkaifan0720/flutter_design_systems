/// What Gloss's typed-in fields share: the well a line of words is typed
/// in, and the input itself, with no decoration of its own.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import '../fonts.dart';
import '../surface.dart';
import '../theme.dart';

/// The well a field is typed in, for its [states] (focused, disabled,
/// error), glazed by [fill] and rimmed by [edge] when a style gives them.
GlossFace glossEntryFace(
  GlossThemeData theme,
  Set<WidgetState> states, {
  Color? fill,
  Color? edge,
  double? radius,
}) {
  final c = theme.colors;
  final error = states.contains(WidgetState.error);
  final enabled = !states.contains(WidgetState.disabled);
  var face = GlossFace.well(c, radius: radius ?? GlossMetrics.fieldRadius);
  if (fill != null) face = face.glazed(fill);
  return face.copyWith(
    foreground: enabled ? c.ink : c.inkDisabled,
    edge: error ? c.danger : edge,
    lift: enabled ? -1 : -0.45,
    focus: states.contains(WidgetState.focused)
        ? (error ? c.danger : c.focus)
        : c.focus.withValues(alpha: 0),
  );
}

/// A line of words typed into a Gloss well: Gloss's body face, the jade
/// caret, the hint in second ink, centred on the line's capitals.
class GlossEntryText extends StatelessWidget {
  /// An input over [controller] and [focusNode].
  const GlossEntryText({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.semanticLabel,
    this.textStyle,
    this.minHeight,
  });

  /// The words.
  final TextEditingController controller;

  /// The focus.
  final FocusNode focusNode;

  /// What the empty field says.
  final String? hint;

  /// Each change of the words.
  final ValueChanged<String>? onChanged;

  /// Enter, for a field that gives up the focus after it.
  final ValueChanged<String>? onSubmitted;

  /// Enter, for a field that keeps the focus after it (a combobox, a tag
  /// input, the palette's search): never given with [onSubmitted].
  final VoidCallback? onEditingComplete;

  /// Whether the words are hidden (a password).
  final bool obscureText;

  /// Whether it takes input.
  final bool enabled;

  /// Whether its words can be read and copied but not changed.
  final bool readOnly;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// What the words may be.
  final List<TextInputFormatter>? inputFormatters;

  /// What autofill may offer.
  final Iterable<String>? autofillHints;

  /// What a screen reader calls the field.
  final String? semanticLabel;

  /// Over Gloss's body face.
  final TextStyle? textStyle;

  /// How tall the editable stands, its line centred in it; null: a
  /// control's height. The editable is what a tap reaches, so it spans the
  /// well it is typed in, not only its line.
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    assert(
      onSubmitted == null || onEditingComplete == null,
      'A field takes Enter in onSubmitted (it gives up the focus) or in '
      'onEditingComplete (it keeps it), never both.',
    );
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = theme.textTheme.body
        .merge(textStyle)
        .copyWith(color: enabled ? c.ink : c.inkDisabled);
    return DesignCapCenter(
      capHeightFactor: glossCapHeightFactor,
      child: DesignTextEntryBox(
        minHeight: minHeight ?? theme.controlHeight,
        controller: controller,
        hint: hint == null
            ? null
            : Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: words.copyWith(color: c.inkSecondary),
              ),
        child: Semantics(
          label: semanticLabel,
          hint: hint,
          child: Material(
            type: MaterialType.transparency,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: null,
              style: words,
              cursorColor: c.jadeInk,
              cursorWidth: 2,
              cursorRadius: const Radius.circular(1),
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              autofillHints: autofillHints,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onEditingComplete: onEditingComplete,
              enabled: enabled,
              readOnly: readOnly,
              autofocus: autofocus,
            ),
          ),
        ),
      ),
    );
  }
}

/// A one-line well: [leading], the words, [trailing], at a control's
/// height, the text cursor over it and a tap anywhere on it putting the
/// caret in.
class GlossEntryWell extends StatelessWidget {
  /// A well around [child].
  const GlossEntryWell({
    super.key,
    required this.face,
    required this.child,
    this.focusNode,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.height,
  });

  /// How the well is painted.
  final GlossFace face;

  /// The words ([GlossEntryText]).
  final Widget child;

  /// The focus a tap on the well asks for.
  final FocusNode? focusNode;

  /// Whether it takes input.
  final bool enabled;

  /// Before the words: a glyph.
  final Widget? leading;

  /// After the words: a bead, a unit.
  final Widget? trailing;

  /// Its height; null: a control's.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: enabled ? focusNode?.requestFocus : null,
        child: SizedBox(
          height: height ?? theme.controlHeight,
          child: AnimatedGlossSurface(
            face: face,
            child: Row(
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: GlossSpacing.medium,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(
                        size: 20,
                        color: enabled ? c.inkSecondary : c.inkDisabled,
                      ),
                      child: leading!,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: leading == null
                          ? GlossSpacing.regular
                          : GlossSpacing.small,
                      end: trailing == null
                          ? GlossSpacing.regular
                          : GlossSpacing.tight,
                    ),
                    child: child,
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: GlossSpacing.tight,
                    ),
                    child: trailing,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
