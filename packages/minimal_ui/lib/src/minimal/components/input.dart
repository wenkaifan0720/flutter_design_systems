/// The text field: label, hint, error, leading icon, secure, multiline and
/// bare registers.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/field.dart';
import '../internal/text_entry.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';

/// Minimal's text field: a 32 px box (the control height a md button
/// shares) on a 1 px rule at the control radius, a 12 px label above it, a
/// helper or an error under it. Focus turns the rule to the accent (the
/// danger's when the field is in error); keyboard focus also draws the kit's
/// solid 2 px ring outside it. `mono: true` sets the value in Geist Mono
/// with tabular figures, for a number, an id, a time; a [suffix] prints its
/// unit at the end. Read-only and disabled fields sink onto the quiet
/// [MinimalThemeData.sunken] fill; a disabled one dims to the kit's 0.45.
///
/// The clear glyph keeps a 44 px target where the label and the message
/// leave air around the box; a box with neither keeps its own 32.
///
/// The whole box is the field's tap target — a tap on its padding focuses
/// the field — and its value is one screen-reader node that stands for the
/// 44 px band taps land in, however small the box paints. A [trailing]
/// control (a show/hide toggle) stands at the box's end as a node and a
/// focus stop of its own, after the value.
///
/// [fieldStyle] dresses one box, `components.textField` every one, resolved
/// with [WidgetState.focused], [WidgetState.error] and
/// [WidgetState.disabled]: fill, edge or side, shape (else `shapes.small`),
/// padding and minimumSize. `density` moves its height and side inset;
/// `t.rim` is its rule and `t.focusWidth` its ring.
///
/// A caller that prints and announces the field's name and failure itself
/// (a form kit with its own announcement rules) passes no [label] and no
/// [error]: [invalid] then paints the error register, the danger rule and
/// ring, with no message of the field's own, and [fieldBuilder] wraps the
/// input in what it says, inside the field's own node.
///
/// Above `maxLines: 1` it is a notes box that grows to that height; with
/// `bare: true` it is the boxless page-as-field a create form's title or an
/// editor wants, in [style] (bodyLarge unless stated).
///
/// ```dart
/// MinimalTextField(label: 'Name', hint: 'Stretch before bed', controller: name)
/// ```
class MinimalTextField extends StatefulWidget {
  /// A boxed text field.
  const MinimalTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.bare = false,
    this.style,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions,
    this.helper,
    this.clearable = false,
    this.onFocusChanged,
    this.mono = false,
    this.suffix,
    this.inputFormatters,
    this.onEditingComplete,
    this.trailing,
    this.invalid = false,
    this.fieldBuilder,
    this.fieldStyle,
  }) : assert(maxLines >= 1, 'maxLines starts at 1'),
       assert(minLines == null || minLines >= 1, 'minLines starts at 1'),
       assert(
         minLines == null || minLines <= maxLines,
         'a field cannot rest taller than it grows',
       ),
       assert(
         !obscureText || maxLines == 1,
         'an obscured field is single-line',
       ),
       assert(
         !bare ||
             (label == null &&
                 error == null &&
                 icon == null &&
                 trailing == null &&
                 !invalid),
         'a bare field is the page: no label, no error, no icon, no control',
       ),
       assert(
         style == null || bare,
         'only the bare register takes a style step; a boxed field wears the '
         'control register',
       );

  /// What it holds, over the box.
  final String? label;

  /// What an empty field says.
  final String? hint;

  /// The message under the field; also turns its rule to the destructive ink.
  final String? error;

  /// A glyph at the field's start, in the tertiary ink.
  final IconData? icon;

  /// The text; null keeps its own.
  final TextEditingController? controller;

  /// Whether it hides what is typed.
  final bool obscureText;

  /// Above 1 the field becomes a notes box that grows to this many lines
  /// and scrolls past them.
  final int maxLines;

  /// Where the field rests; unstated it is [maxLines], so a notes box
  /// stands at its full height.
  final int? minLines;

  /// Reports each edit.
  final ValueChanged<String>? onChanged;

  /// The page-as-field register: no box, no rule, no label.
  final bool bare;

  /// The bare register's type step; [MinimalThemeData.bodyLarge] unstated.
  final TextStyle? style;

  /// Its focus; null keeps its own.
  final FocusNode? focusNode;

  /// Whether it takes input.
  final bool enabled;

  /// Whether its text is shown but not edited.
  final bool readOnly;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Reports the text when the keyboard's action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// What the platform may fill it with: an email, a password.
  final Iterable<String>? autofillHints;

  /// Which letters the keyboard capitalises.
  final TextCapitalization textCapitalization;

  /// Whether the keyboard corrects spelling.
  final bool autocorrect;

  /// Whether the keyboard offers and learns suggestions; unstated, off for
  /// an [obscureText] field and on otherwise. A password field whose show/hide
  /// toggle reveals it passes `false`, so revealing the password never
  /// hands it to the keyboard.
  final bool? enableSuggestions;

  /// A quiet line under the field; the [error] replaces it.
  final String? helper;

  /// Show a clear glyph at the end while the field holds text.
  final bool clearable;

  /// Reports when it gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// Set the value (and hint) in Geist Mono with tabular figures.
  final bool mono;

  /// A unit printed at the field's end (`pages`, `min`, `€`): a word, so in
  /// the body face, quiet, beside a mono value.
  final String? suffix;

  /// What the field lets through as it is typed: digits only for a code,
  /// a length cap.
  final List<TextInputFormatter>? inputFormatters;

  /// Runs when the keyboard's action finishes editing, before
  /// [onSubmitted]; unstated, the field's own default (Next moves focus on,
  /// Done unfocuses). A form that moves Next past its own controls says
  /// where here.
  final VoidCallback? onEditingComplete;

  /// A control at the box's end, after the value (and the clear glyph): a
  /// show/hide toggle, typically a small ghost [MinimalIconButton]. Its own
  /// screen-reader node and focus stop, reached after the value.
  final Widget? trailing;

  /// Paint the error register — the danger rule and ring — without a
  /// message of the field's own, for a caller that prints the failure
  /// itself. An [error] implies it, and so does a [MinimalFormField]'s
  /// error round the field.
  final bool invalid;

  /// Wraps the text input inside the field's one screen-reader node: for a
  /// caller that names and describes the field itself (a `Semantics` with
  /// its label and hint, an announcer), so what it says lands on the
  /// field's own node rather than on a node around the whole box.
  final Widget Function(Widget field)? fieldBuilder;

  /// The box's style, over `components.textField`. The bare register has
  /// no box and reads none.
  final MinimalStyle? fieldStyle;

  @override
  State<MinimalTextField> createState() => _MinimalTextFieldState();
}

class _MinimalTextFieldState extends State<MinimalTextField>
    with MinimalFieldOwner<MinimalTextField> {
  @override
  TextEditingController? get externalController => widget.controller;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void focusChanged(bool focused) => widget.onFocusChanged?.call(focused);

  @override
  void didUpdateWidget(MinimalTextField old) {
    super.didUpdateWidget(old);
    syncField(oldController: old.controller, oldFocusNode: old.focusNode);
  }

  void _clear() {
    controller.clear();
    widget.onChanged?.call('');
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final label = widget.label;
    final error = widget.error;
    final helper = widget.helper;
    final icon = widget.icon;
    final suffix = widget.suffix;
    final bare = widget.bare;
    final multiline = widget.maxLines > 1;
    final focused = focusNode.hasFocus;
    final muted = !widget.enabled || widget.readOnly;

    final valueStyle = bare
        ? (widget.style ?? t.bodyLarge)
        : widget.mono
        ? t.monoValue
        : t.body;
    final ink = widget.enabled ? t.foreground : t.mutedForeground;

    Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect && !widget.obscureText,
      enableSuggestions: widget.enableSuggestions ?? !widget.obscureText,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      minLines: widget.minLines ?? widget.maxLines,
      cursorColor: t.primary,
      cursorWidth: MinimalFieldMetrics.cursor,
      style: valueStyle.c(ink),
      decoration: minimalBareDecoration(
        hint: widget.hint,
        hintStyle: valueStyle.c(t.textTertiary),
      ),
    );
    // A one-line field's line by its capitals, as every label beside it:
    // caret, hint and taps move with it. A text area keeps its lines.
    if (widget.maxLines == 1) field = minimalCapLabel(field);
    // The label is the field's name for a screen reader, not a node of its
    // own.
    if (label != null) field = Semantics(label: label, child: field);
    final fieldBuilder = widget.fieldBuilder;
    if (fieldBuilder != null) field = fieldBuilder(field);
    if (Material.maybeOf(context) == null) {
      field = Material(type: MaterialType.transparency, child: field);
    }
    if (bare) return field;

    final showClear =
        widget.clearable &&
        controller.text.isNotEmpty &&
        widget.enabled &&
        !widget.readOnly;
    final trailing = widget.trailing;
    final inError =
        error != null || widget.invalid || MinimalFieldErrorScope.of(context);
    final ruleColor = inError
        ? t.destructive
        : focused
        ? t.ring
        : t.border;

    final so = MinimalStyleOf(
      [widget.fieldStyle, t.components.textField],
      minimalStates(enabled: widget.enabled, focused: focused, error: inError),
    );
    final shape = so.shape ?? t.shapes.small;
    final least = so.minimumSize;
    final height =
        least?.height ??
        minimalGrownHeight(
          context,
          t.density.height(MinimalChromeMetrics.control),
        );
    // Several lines start where one line stands, centred in [height].
    final air = multiline
        ? minimalLineAir(
            height: height,
            rim: t.rim,
            line: minimalLineHeight(context, valueStyle),
          )
        : 0.0;
    final inset = t.density.padding(
      EdgeInsets.only(
        left: MinimalFieldMetrics.inset,
        right: showClear || trailing != null
            ? MinimalSpacing.s2
            : MinimalFieldMetrics.inset,
      ),
    );
    // The rim and the focus ring lerp to each state: focus, error, rest.
    final box = MinimalFace(
      constraints: BoxConstraints(
        minWidth: least?.width ?? 0,
        minHeight: height,
      ),
      padding:
          so.padding ??
          EdgeInsetsDirectional.only(
            start: inset.left,
            end: inset.right,
            top: air,
            bottom: air,
          ),
      decoration: minimalFrame(
        shape,
        fill: so.fill ?? (muted ? t.sunken : t.card),
        side: so.rim(ruleColor, t.rim),
      ),
      foregroundDecoration: minimalFieldRing(
        t,
        shown: keyboardFocused,
        error: inError,
        shape: shape,
      ),
      builder: (context, _) => Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: multiline ? 2 : 0),
              child: MinimalIcon(
                icon,
                size: MinimalIconSize.i16,
                color: t.textTertiary,
              ),
            ),
            const MinimalGap(MinimalSpacing.s8),
          ],
          Expanded(child: MinimalFieldTarget(child: field)),
          if (suffix != null) ...[
            const MinimalGap(MinimalSpacing.s8),
            Text(
              suffix,
              style: t.body.copyWith(
                fontSize: t.monoValue.fontSize,
                color: t.mutedForeground,
              ),
            ),
          ],
          if (showClear) ...[
            const MinimalGap(MinimalSpacing.s4),
            MinimalPressable(
              onPressed: _clear,
              semanticLabel: MinimalLocalizations.of(context)
                  .clear(label ?? widget.hint),
              shape: t.shapes.mark,
              // As tall as the box inside its rim at most: a compact
              // field (28) keeps its height with the glyph in it.
              child: SizedBox.square(
                dimension: math.min(
                  MinimalChromeMetrics.controlSm,
                  height - 2 * t.rim,
                ),
                child: MinimalIcon(
                  LucideIcons.circleX,
                  size: MinimalIconSize.i16,
                  color: t.textTertiary,
                ),
              ),
            ),
          ],
          if (trailing != null) ...[
            const MinimalGap(MinimalSpacing.s4),
            trailing,
          ],
        ],
      ),
    );

    final message = error ?? helper;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          ExcludeSemantics(
            child: Text(label, style: t.caption.medium.c(t.foreground)),
          ),
          const MinimalGap(MinimalChromeMetrics.iconGap),
        ],
        // Taps in the air the label and the message leave around the box
        // still reach it: the clear glyph keeps its 44 px target, and a tap
        // anywhere else on the box focuses the field (the field's own tap,
        // placing the caret, wins the arena where it lands).
        MinimalHitTarget(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A pointer's convenience: the field's own node is the screen
            // reader's.
            excludeFromSemantics: true,
            onTap: widget.enabled ? focusNode.requestFocus : null,
            child: box,
          ),
        ),
        if (message != null) ...[
          const MinimalGap(MinimalChromeMetrics.iconGap),
          Semantics(
            liveRegion: error != null,
            child: Text(
              message,
              style: t.caption.c(
                error != null ? t.destructiveInk : t.mutedForeground,
              ),
            ),
          ),
        ],
      ],
    );
    return widget.enabled ? column : Opacity(opacity: 0.45, child: column);
  }
}
