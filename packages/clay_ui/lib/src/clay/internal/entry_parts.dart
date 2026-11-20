/// What Clay's typed-in fields share: the well a line of words is typed in,
/// and the input itself, with no decoration of its own.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import '../fonts.dart';
import '../surface.dart';
import '../theme.dart';

/// The well a field is typed in, for its [states] (focused, disabled,
/// error): the text field's own, coloured by [fill] and rimmed by [edge]
/// when a style gives them.
ClayFace clayEntryFace(
  ClayThemeData theme,
  Set<WidgetState> states, {
  Color? fill,
  Color? edge,
  double? radius,
}) {
  final c = theme.colors;
  final error = states.contains(WidgetState.error);
  final enabled = !states.contains(WidgetState.disabled);
  final focused = states.contains(WidgetState.focused);
  final face = ClayFace.well(
    c,
    color: fill,
    radius: radius ?? ClayRadius.control,
  );
  return face.copyWith(
    // Off, the well fills nearly level with the ground.
    shadeOpacity: enabled ? null : face.shadeOpacity * 0.4,
    focusColor: error ? c.danger : (edge ?? c.focus),
    focus: focused || error ? 1 : 0,
  );
}

/// Keeps [builder] rebuilt as [focusNode] gains and loses the focus.
class ClayOnFocus extends StatelessWidget {
  /// Rebuilds [builder] with [focusNode]'s focus.
  const ClayOnFocus({
    super.key,
    required this.focusNode,
    required this.builder,
  });

  /// The focus it follows.
  final FocusNode focusNode;

  /// Builds with whether [focusNode] has the focus.
  final Widget Function(BuildContext context, bool focused) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: focusNode,
    builder: (context, _) => builder(context, focusNode.hasFocus),
  );
}

/// A line of words typed into a Clay well: Clay's body face, the coral
/// caret, the hint in second ink, centred on the line's capitals.
class ClayEntryText extends StatelessWidget {
  /// An input over [controller] and [focusNode].
  const ClayEntryText({
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
    this.textAlign = TextAlign.start,
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

  /// Over Clay's body face.
  final TextStyle? textStyle;

  /// Where the words stand on the line.
  final TextAlign textAlign;

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
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final words = theme.textTheme.body
        .merge(textStyle)
        .copyWith(color: enabled ? c.ink : c.inkDisabled);
    return DesignCapCenter(
      capHeightFactor: clayCapHeightFactor,
      child: DesignTextEntryBox(
        minHeight: minHeight ?? theme.controlHeight,
        controller: controller,
        hint: hint == null
            ? null
            : Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                style: words.copyWith(
                  color: enabled ? c.inkSecondary : c.inkDisabled,
                ),
              ),
        // One node, the field's own size, as the text field's: its name
        // and its text together, never spread onto what holds it (a list's
        // header below).
        child: MergeSemantics(
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
                textAlign: textAlign,
                cursorColor: c.accentInk,
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
      ),
    );
  }
}

/// A one-line well: [leading], the words, [trailing], at a control's
/// height, the text cursor over it and a tap anywhere on it putting the
/// caret in.
class ClayEntryWell extends StatelessWidget {
  /// A well around [child].
  const ClayEntryWell({
    super.key,
    required this.face,
    required this.child,
    this.focusNode,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.height,
  });

  /// How the well is painted ([clayEntryFace]).
  final ClayFace face;

  /// The words ([ClayEntryText]).
  final Widget child;

  /// The focus a tap on the well asks for.
  final FocusNode? focusNode;

  /// Whether it takes input.
  final bool enabled;

  /// Before the words: a glyph.
  final Widget? leading;

  /// After the words: a key, a unit.
  final Widget? trailing;

  /// Its height; null: a control's.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: enabled ? focusNode?.requestFocus : null,
        child: SizedBox(
          height: height ?? theme.controlHeight,
          child: AnimatedClaySurface(
            face: face,
            child: Row(
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: ClaySpacing.regular,
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
                          ? ClaySpacing.regular
                          : ClaySpacing.medium,
                      end: trailing == null
                          ? ClaySpacing.regular
                          : ClaySpacing.tight,
                    ),
                    child: child,
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: ClaySpacing.tight,
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

/// A groove across a well: the line where an add-on meets the words.
class ClayWellSeam extends StatelessWidget {
  /// A seam [height] tall.
  const ClayWellSeam({super.key, this.height = 24});

  /// How tall it runs.
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    return SizedBox(
      width: 2,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(c.well, c.track, 0.7),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
