/// The text field: label, hint, error, leading icon, secure, multiline and
/// bare registers.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/field.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
import '../internal/text_entry.dart';
import '../localizations.dart';
import '../theme.dart';
import '../internal/message_reveal.dart';
import 'pressable.dart';

/// Minimal's text field: a 32 px box (the control height a md button
/// shares) on a 1 px rule at the control radius, a 12 px label above it, a
/// helper or an error under it. Focus draws a single 2 px accent edge over
/// the rule; a field in error keeps the danger tone, focused or not, so a
/// failed save that moves focus to the field still shows what is wrong.
/// [required] puts a quiet asterisk after the label and says "required". `mono: true` sets the value in Geist Mono
/// with tabular figures, for a number, an id, a time; a [suffix] prints its
/// unit at the end. Read-only and disabled fields sink onto the quiet
/// [MinimalThemeData.sunken] fill; a disabled one dims to the kit's 0.45.
///
/// The clear glyph keeps the tap floor's target where the label and the message
/// leave air around the box; a box with neither keeps its own 32.
///
/// The whole box is the field's tap target — a tap on its padding focuses
/// the field — and its value is one screen-reader node that stands for the
/// band taps land in (the tap floor), however small the box paints. A [trailing]
/// control (a show/hide toggle) stands at the box's end as a node and a
/// focus stop of its own, after the value.
///
/// [fieldStyle] dresses one box, `components.textField` every one, resolved
/// with [WidgetState.focused], [WidgetState.error] and
/// [WidgetState.disabled]: fill, edge or side, shape (else `shapes.small`),
/// padding and minimumSize. `density` moves its height and side inset;
/// `t.rim` is its rule; focused, the accent covers it and half a pixel
/// more, with no ring outside the box.
///
/// A caller that prints and announces the field's name and failure itself
/// (a form kit with its own announcement rules) passes no [labelText] and no
/// [errorText]: [invalid] then paints the error register, the danger rule and
/// ring, with no message of the field's own, and [fieldBuilder] wraps the
/// input in what it says, inside the field's own node.
///
/// Above `maxLines: 1` it is a notes box that grows to that height; with
/// `bare: true` it is the boxless page-as-field a create form's title or an
/// editor wants, in [style] (bodyLarge unless stated).
///
/// ```dart
/// MinimalTextField(labelText: 'Name', hintText: 'Stretch before bed', controller: name)
/// ```
class MinimalTextField extends StatefulWidget {
  /// A boxed text field.
  const MinimalTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
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
    this.helperText,
    this.clearable = false,
    this.onFocusChange,
    this.mono = false,
    this.suffix,
    this.inputFormatters,
    this.onEditingComplete,
    this.trailing,
    this.invalid = false,
    this.required = false,
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
             (labelText == null &&
                 errorText == null &&
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
  final String? labelText;

  /// Whether it must be filled: a quiet asterisk after [labelText], and
  /// "required" said with its name, as [MinimalFormField.required].
  final bool required;

  /// What an empty field says.
  final String? hintText;

  /// The message under the field; also turns its rule to the destructive ink.
  final String? errorText;

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

  /// {@macro minimal.readOnly}
  final bool readOnly;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// {@macro minimal.textInputAction}
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

  /// A quiet line under the field; the [errorText] replaces it.
  final String? helperText;

  /// Show a clear glyph at the end while the field holds text.
  final bool clearable;

  /// Reports when it gains or loses focus.
  final ValueChanged<bool>? onFocusChange;

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
  /// where here. A field that keeps the focus after Enter (one that adds
  /// another) takes Enter here and leaves [onSubmitted] unset: Flutter
  /// restarts the text input of a field told of a submit that still holds
  /// the focus, and in a browser it then takes no typing.
  final VoidCallback? onEditingComplete;

  /// A control at the box's end, after the value (and the clear glyph): a
  /// show/hide toggle, typically a small ghost [MinimalIconButton]. Its own
  /// screen-reader node and focus stop, reached after the value.
  final Widget? trailing;

  /// Paint the error register — the danger rule and ring — without a
  /// message of the field's own, for a caller that prints the failure
  /// itself. An [errorText] implies it, and so does a [MinimalFormField]'s
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscureText'),
      )
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1))
      ..add(IntProperty('minLines', minLines, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(FlagProperty('bare', value: bare, ifTrue: 'bare'))
      ..add(DiagnosticsProperty<TextStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<TextCapitalization>(
          'textCapitalization',
          textCapitalization,
          defaultValue: TextCapitalization.none,
        ),
      )
      ..add(
        FlagProperty(
          'autocorrect',
          value: autocorrect,
          ifFalse: 'autocorrect: false',
        ),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'enableSuggestions',
          enableSuggestions,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(FlagProperty('clearable', value: clearable, ifTrue: 'clearable'))
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onFocusChange',
          onFocusChange,
        ),
      )
      ..add(FlagProperty('mono', value: mono, ifTrue: 'mono'))
      ..add(StringProperty('suffix', suffix, defaultValue: null))
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(FlagProperty('invalid', value: invalid, ifTrue: 'invalid'))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(
        ObjectFlagProperty<Widget Function(Widget field)>.has(
          'fieldBuilder',
          fieldBuilder,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalStyle>(
          'fieldStyle',
          fieldStyle,
          defaultValue: null,
        ),
      );
  }
}

class _MinimalTextFieldState extends State<MinimalTextField>
    with MinimalFieldOwner<MinimalTextField> {
  @override
  TextEditingController? get externalController => widget.controller;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void focusChanged(bool focused) => widget.onFocusChange?.call(focused);

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
    final label = widget.labelText;
    // Words that name the field: its label or its hint.
    final named =
        (label?.isNotEmpty ?? false) || (widget.hintText?.isNotEmpty ?? false);
    final error = widget.errorText;
    final helper = widget.helperText;
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

    Widget field = MinimalBareTextField(
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
      style: valueStyle.c(ink),
      hint: widget.hintText,
      hintStyle: valueStyle.c(t.mutedForeground),
    );
    // A one-line field's line by its capitals, as every label beside it:
    // caret, hint and taps move with it. A text area keeps its lines.
    if (widget.maxLines == 1) field = minimalCapLabel(field);
    // In a combobox, the input says whether the field's list is showing.
    final open = MinimalFieldOpenScope.maybeOf(context);
    if (open != null) field = Semantics(expanded: open, child: field);
    final fieldBuilder = widget.fieldBuilder;
    if (fieldBuilder != null) field = fieldBuilder(field);
    if (Material.maybeOf(context) == null) {
      field = Material(type: MaterialType.transparency, child: field);
    }
    // At a finger the bare line stands in a band as tall as the floor, so a
    // title and the note under it each keep a finger's height.
    if (bare) return MinimalTapBand(child: field);

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
          so.paddingIn(context) ??
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
      foregroundDecoration: minimalFocusEdge(
        t,
        shown: focused,
        invalid: inError,
        shape: shape,
      ),
      builder: (context, _) => Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: multiline ? MinimalSpacing.s2 : 0),
              child: MinimalIcon(
                icon,
                size: MinimalIconSize.i16,
                // Beside a label or a hint the glyph only decorates; alone,
                // it is what names the field, so it reads at 3:1.
                color: named ? t.textTertiary : t.mutedForeground,
              ),
            ),
            const MinimalGap(MinimalSpacing.s8),
          ],
          // The decorator gives the input its node, beside a clear glyph or
          // an eye too, so the field's words are read with the input.
          Expanded(child: MinimalFieldTarget(node: false, child: field)),
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
            // The glyph keeps a finger's width laid out, inside the box,
            // and the box's height inside its rim (a grown box's too); the
            // band round the box gives it the rest.
            minimalInlineTargets(
              context,
              height: height - 2 * t.rim,
              MinimalPressable(
                onPressed: _clear,
                tapAlignment: AlignmentDirectional.centerEnd,
                semanticLabel: MinimalLocalizations.of(context)
                    .clear(label ?? widget.hintText),
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
                    // The clear button's only mark: 3:1 at least.
                    color: t.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
          if (trailing != null) ...[
            const MinimalGap(MinimalSpacing.s4),
            minimalInlineTargets(
              context,
              height: height - 2 * t.rim,
              MinimalTapAlignment(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing,
              ),
            ),
          ],
        ],
      ),
    );

    // ui_core's decorator names the value by the label and gives it the
    // error and the help as its hint, marked invalid while in error, as
    // Material's TextField reads; Minimal draws the words.
    final column = RawInputDecorator(
      labelText: label,
      helperText: helper,
      errorText: error,
      invalid: widget.invalid,
      required: widget.required,
      requiredHint: MinimalLocalizations.of(context).required,
      enabled: widget.enabled,
      focusNode: focusNode,
      // A tap anywhere on the box focuses the field (the field's own tap,
      // placing the caret, and the clear glyph's win the arena where they
      // land).
      // At a finger the box stands in a band as tall as the floor, laid
      // out: a tap in it lands on the box's nearest edge.
      child: MinimalTapBand(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // A pointer's convenience: the field's own node is the screen
          // reader's.
          excludeFromSemantics: true,
          onTap: widget.enabled ? focusNode.requestFocus : null,
          child: box,
        ),
      ),
      builder: (context, parts) {
        final name = parts.label;
        final message = parts.error ?? parts.helper;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (name != null) ...[
              DefaultTextStyle.merge(
                style: t.caption.medium.c(t.foreground),
                child: parts.required
                    ? Row(
                        children: [
                          Flexible(child: name),
                          ExcludeSemantics(
                            child: Text(
                              ' *',
                              style: t.caption.medium.c(t.textTertiary),
                            ),
                          ),
                        ],
                      )
                    : name,
              ),
              const MinimalGap(MinimalChromeMetrics.iconGap),
            ],
            parts.control,
            // The line grows open and fades in (and out), never jumps.
            MinimalMessageReveal(
              id: parts.errorText,
              child: !(message != null)
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(
                        top: MinimalChromeMetrics.iconGap,
                      ),
                      child: DefaultTextStyle.merge(
                        style: t.caption.c(
                          parts.errorText != null
                              ? t.destructiveInk
                              : t.mutedForeground,
                        ),
                        child: message,
                      ),
                    ),
            ),
          ],
        );
      },
    );
    return widget.enabled ? column : Opacity(opacity: 0.45, child: column);
  }
}
