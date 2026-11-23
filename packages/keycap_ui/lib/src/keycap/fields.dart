/// Keycap's other fields, each a well cut into the case as
/// [KeycapTextField] is: [KeycapSearchField], [KeycapPasswordField],
/// [KeycapInputGroup] (a field with its unit printed in the well),
/// [KeycapOtpField] (a code in a row of small wells), [KeycapStepper] (a
/// number between a minus key and a plus key) and [KeycapField] (any
/// control under its label, over its help or error).
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'internal/small_key.dart';
import 'text_field.dart';
import 'theme.dart';

// The ui_core types these parts' APIs take, through the look's barrel.
export 'package:ui_core/ui_core.dart' show RawPasswordController;
export 'package:ui_core/ui_core.dart' show RawOtpController;

/// A search field: a well with a magnifier at its start and, once there are
/// words in it, a small clear key at its end. A screen reader hears a
/// search field.
///
/// ```dart
/// KeycapSearchField(hintText: 'Search notes', onChanged: search)
/// ```
class KeycapSearchField extends StatefulWidget {
  /// A search field.
  const KeycapSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.semanticLabel,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.style,
  });

  /// The words; the field keeps its own when null.
  final TextEditingController? controller;

  /// The field's focus node.
  final FocusNode? focusNode;

  /// The words in the empty field.
  final String? hintText;

  /// The field's name for a screen reader; the kit's "Search" when null.
  final String? semanticLabel;

  /// Called as the words change (and with '' when cleared).
  final ValueChanged<String>? onChanged;

  /// Called when the reader submits.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field takes focus when it first appears.
  final bool autofocus;

  /// Whether the field is on.
  final bool enabled;

  /// Overrides, over [KeycapThemeData.textFieldStyle].
  final KeycapStyle? style;

  @override
  State<KeycapSearchField> createState() => _KeycapSearchFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _KeycapSearchFieldState extends State<KeycapSearchField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(KeycapSearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_changed);
      _controller.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final empty = _controller.text.isEmpty;
    return Semantics(
      textField: true,
      container: true,
      child: KeycapTextField(
        controller: _controller,
        focusNode: widget.focusNode,
        hintText: widget.hintText,
        semanticLabel: widget.semanticLabel ?? words.searchFieldLabel,
        leading: const Icon(LucideIcons.search),
        trailing: empty || !widget.enabled
            ? null
            : KeycapSmallKey(
                icon: LucideIcons.x,
                semanticLabel: words.clearButtonTooltip,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
              ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        style: widget.style,
      ),
    );
  }
}

/// A password field: its words hidden, and a small key at its end that
/// shows them while it is latched. Built on ui_core's `RawPasswordReveal`.
///
/// ```dart
/// KeycapPasswordField(labelText: 'Password', onChanged: setPassword)
/// ```
class KeycapPasswordField extends StatelessWidget {
  /// A password field.
  const KeycapPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.passwordController,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.password],
    this.enabled = true,
    this.style,
  });

  /// The words; the field keeps its own when null.
  final TextEditingController? controller;

  /// The field's focus node.
  final FocusNode? focusNode;

  /// Whether the words show; the field keeps its own when null.
  final RawPasswordController? passwordController;

  /// The words over the field.
  final String? labelText;

  /// The words in the empty field.
  final String? hintText;

  /// Help under the field.
  final String? helperText;

  /// What is wrong, under the field.
  final String? errorText;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the reader submits.
  final ValueChanged<String>? onSubmitted;

  /// What autofill may offer (a new password's hint for a sign-up).
  final Iterable<String> autofillHints;

  /// Whether the field is on.
  final bool enabled;

  /// Overrides, over [KeycapThemeData.textFieldStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) => RawPasswordReveal(
    controller: passwordController,
    focusNode: focusNode,
    builder: (context, password) => KeycapTextField(
      controller: controller,
      focusNode: focusNode,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      obscureText: password.obscured,
      autofillHints: autofillHints,
      keyboardType: TextInputType.visiblePassword,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      style: style,
      trailing: KeycapSmallKey(
        icon: password.obscured ? LucideIcons.eye : LucideIcons.eyeOff,
        semanticLabel: password.toggleLabel,
        toggled: !password.obscured,
        onPressed: enabled ? password.toggle : null,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null));
  }
}

/// A field with words printed in its well beside the entry: a unit after
/// it ("kg", "words"), a prefix before it ("https://"), set off from the
/// entry by a hairline. The whole well takes focus as one field. Built on
/// ui_core's `DesignInputGroup`.
///
/// ```dart
/// KeycapInputGroup(labelText: 'Goal', suffixText: 'words a day', keyboardType: TextInputType.number)
/// ```
class KeycapInputGroup extends StatefulWidget {
  /// A field with a [prefixText], a [suffixText] or both.
  const KeycapInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.semanticLabel,
    this.prefixText,
    this.suffixText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.style,
  });

  /// The words; the field keeps its own when null.
  final TextEditingController? controller;

  /// The entry's focus node.
  final FocusNode? focusNode;

  /// The words over the field.
  final String? labelText;

  /// The words in the empty entry.
  final String? hintText;

  /// Help under the field.
  final String? helperText;

  /// What is wrong, under the field.
  final String? errorText;

  /// The field's name for a screen reader, when there is no [labelText].
  final String? semanticLabel;

  /// Words printed before the entry.
  final String? prefixText;

  /// Words printed after it.
  final String? suffixText;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the reader submits.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// Rules for what may be entered.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field is on.
  final bool enabled;

  /// Overrides, over [KeycapThemeData.textFieldStyle].
  final KeycapStyle? style;

  @override
  State<KeycapInputGroup> createState() => _KeycapInputGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('prefixText', prefixText, defaultValue: null))
      ..add(StringProperty('suffixText', suffixText, defaultValue: null));
  }
}

class _KeycapInputGroupState extends State<KeycapInputGroup> {
  TextEditingController? _own;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'KeycapInputGroup'));

  @override
  void dispose() {
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final wrong = widget.errorText != null;
    final pad = KeycapSpacing.medium + theme.density.paddingDelta / 2;
    final ink = widget.enabled ? c.ink : c.inkDisabled;
    final printed = theme.textTheme.body.copyWith(
      color: widget.enabled ? c.inkMuted : c.inkDisabled,
    );
    // The add-ons keep their words whole: they take their own width and
    // the entry keeps at least a third of the well; where large text leaves
    // them too little, their words print smaller to fit, never cut.
    TextScaler addOnScaler(double width) {
      final scaler = MediaQuery.textScalerOf(context);
      final painter = TextPainter(
        textDirection: Directionality.of(context),
        textScaler: scaler,
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      );
      final drawn = DefaultTextStyle.of(context).style.merge(printed);
      var words = 0.0;
      for (final text in [?widget.prefixText, ?widget.suffixText]) {
        painter
          ..text = TextSpan(text: text, style: drawn)
          ..layout();
        words += painter.width;
      }
      painter.dispose();
      final ends =
          (widget.prefixText == null ? 0 : 2 * pad + 1) +
          (widget.suffixText == null ? 0 : 2 * pad + 1);
      final room = width * 2 / 3 - ends;
      if (words <= room || words <= 0 || room <= 1) return scaler;
      final size = drawn.fontSize ?? 14;
      // A pixel spare: text widths round, and a word a hair too wide cuts.
      return TextScaler.linear(scaler.scale(size) / size * (room - 1) / words);
    }

    Widget addOn(
      String words, {
      required bool start,
      required double most,
      required TextScaler scaler,
    }) => ConstrainedBox(
      constraints: BoxConstraints(maxWidth: most),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!start) _Hairline(color: c.hairline),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: DesignCapCenter(
                capHeightFactor: theme.capHeightFactor,
                child: Text(
                  words,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: scaler,
                  style: printed,
                ),
              ),
            ),
          ),
          if (start) _Hairline(color: c.hairline),
        ],
      ),
    );
    return KeycapField(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      focusNode: _focus,
      child: DesignInputGroup(
        focusNode: _focus,
        enabled: widget.enabled,
        isError: wrong,
        builder: (context, states, child) {
          final layered = DesignStyleOf([
            widget.style,
            theme.textFieldStyle,
          ], states);
          final focused = states.contains(WidgetState.focused);
          return KeycapWell(
            radius: BorderRadius.circular(KeycapMetrics.fieldRadius),
            floor:
                layered.fill ??
                (widget.enabled ? null : Color.lerp(c.well, c.ground, 0.6)),
            rim: focused
                ? (wrong ? c.dangerInk : c.focus)
                : wrong
                ? c.dangerInk.withValues(alpha: 0.55)
                : null,
            rimWidth: focused ? KeycapMetrics.focusWidth : 1,
            child: child,
          );
        },
        child: SizedBox(
          height: KeycapMetrics.grown(
            context,
            theme.controlHeight,
            theme.textTheme.body,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final scaler = addOnScaler(box.maxWidth);
              final most = box.maxWidth * 2 / 3;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.prefixText != null)
                    addOn(
                      widget.prefixText!,
                      start: true,
                      most: most,
                      scaler: scaler,
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: DesignCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: Semantics(
                          container: true,
                          label: widget.semanticLabel ?? widget.labelText,
                          child: DesignTextEntryBox(
                            minHeight: theme.controlHeight,
                            controller: _controller,
                            hint: widget.hintText == null
                                ? null
                                : Text(
                                    widget.hintText!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.body.copyWith(
                                      color: c.inkMuted,
                                    ),
                                  ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: TextField(
                                controller: _controller,
                                focusNode: _focus,
                                decoration: null,
                                style: theme.textTheme.body.copyWith(
                                  color: ink,
                                ),
                                cursorColor: c.accent.top,
                                cursorWidth: 2,
                                keyboardType: widget.keyboardType,
                                inputFormatters: widget.inputFormatters,
                                onChanged: widget.onChanged,
                                onSubmitted: widget.onSubmitted,
                                enabled: widget.enabled,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.suffixText != null)
                    addOn(
                      widget.suffixText!,
                      start: false,
                      most: most,
                      scaler: scaler,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KeycapSpacing.small),
    child: SizedBox(width: 1, child: ColoredBox(color: color)),
  );
}

/// A code typed into a row of small wells, one character to each; the well
/// the next character goes in is ringed in the focus band, with a caret
/// at its foot. Six wells stand in two threes. [onCompleted] runs when
/// every well is full. To a screen reader it is one text field, and it
/// takes a pasted code. Built on ui_core's `RawOtpField`.
///
/// ```dart
/// KeycapOtpField(onCompleted: verify)
/// ```
class KeycapOtpField extends StatelessWidget {
  /// A field for a code of [length] characters.
  const KeycapOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.semanticLabel,
    this.isError = false,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.style,
  });

  /// How many characters the code has.
  final int length;

  /// The code; the field keeps its own when null.
  final RawOtpController? controller;

  /// The field's focus node.
  final FocusNode? focusNode;

  /// Called as the code changes.
  final ValueChanged<String>? onChanged;

  /// Called with the whole code once every well is full.
  final ValueChanged<String>? onCompleted;

  /// The field's name for a screen reader.
  final String? semanticLabel;

  /// Whether the code was wrong: the wells' edges in the danger ink.
  final bool isError;

  /// Whether the field is on.
  final bool enabled;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Whether the characters are hidden.
  final bool obscureText;

  /// Overrides, over [KeycapThemeData.textFieldStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final h = KeycapMetrics.grown(
      context,
      theme.controlHeight,
      theme.textTheme.figure.copyWith(fontSize: 20),
    );
    // A slot widens by what one figure gains as text grows, not with its
    // height: six still sit in a phone's row at 200%.
    final grows = MediaQuery.textScalerOf(context).scale(20) - 20;
    final w = (theme.controlHeight * 0.8 + grows * 0.6).ceilToDouble();
    return RawOtpField(
      length: length,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onCompleted: onCompleted,
      semanticLabel: semanticLabel ?? 'One-time code',
      isError: isError,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: obscureText,
      layoutBuilder: (context, slots) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, slot) in slots.indexed) ...[
            if (i > 0)
              SizedBox(
                width: length == 6 && i == 3
                    ? KeycapSpacing.medium
                    : KeycapMetrics.keyGap,
              ),
            slot,
          ],
        ],
      ),
      slotBuilder: (context, slot) {
        final here = slot.focused && slot.active;
        final states = <WidgetState>{
          if (!slot.enabled) WidgetState.disabled,
          if (here) WidgetState.focused,
          if (slot.isError) WidgetState.error,
        };
        final layered = DesignStyleOf([style, theme.textFieldStyle], states);
        return SizedBox(
          width: w,
          height: h,
          child: KeycapWell(
            radius: BorderRadius.circular(KeycapMetrics.fieldRadius),
            floor:
                layered.fill ??
                (slot.enabled ? null : Color.lerp(c.well, c.ground, 0.6)),
            rim: here
                ? (slot.isError ? c.dangerInk : c.focus)
                : slot.isError
                ? c.dangerInk.withValues(alpha: 0.55)
                : null,
            rimWidth: here ? KeycapMetrics.focusWidth : 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  slot.obscured && slot.filled ? '•' : slot.character,
                  style: theme.textTheme.figure.copyWith(
                    fontSize: 20,
                    color: slot.enabled ? c.ink : c.inkDisabled,
                  ),
                ),
                if (here && !slot.filled)
                  Positioned(
                    bottom: KeycapSpacing.small + 2,
                    child: SizedBox(
                      width: w * 0.4,
                      height: 2,
                      child: ColoredBox(color: c.accent.top),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'error'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

/// A number between two keys: a minus key, a small well holding the
/// figure (typed into, or stepped), a plus key. Held, a key repeats; the
/// arrows step it too; at [min] or [max] its key goes off. Built on
/// ui_core's `RawNumberField`.
///
/// ```dart
/// KeycapStepper(value: copies, min: 1, max: 20, onChanged: (v) => setState(() => copies = v), semanticLabel: 'Copies')
/// ```
class KeycapStepper extends StatelessWidget {
  /// A number stepper.
  const KeycapStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.fractionDigits,
    this.semanticLabel,
    this.unit,
    this.focusNode,
    this.style,
  });

  /// The number; null when empty.
  final double? value;

  /// Called with the new number; null turns the stepper off.
  final ValueChanged<double?>? onChanged;

  /// The least it may be.
  final double? min;

  /// The most it may be.
  final double? max;

  /// How far a key steps it.
  final double step;

  /// How many decimals it shows; whole numbers when null and [step] is.
  final int? fractionDigits;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  /// A unit printed after the figure, inside the well ("min").
  final String? unit;

  /// The entry's focus node.
  final FocusNode? focusNode;

  /// Overrides for the well, over [KeycapThemeData.textFieldStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final h = theme.controlHeight;
    return RawNumberField(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      step: step,
      fractionDigits: fractionDigits,
      focusNode: focusNode,
      semanticLabel: semanticLabel,
      layoutBuilder: (context, field, decrement, increment) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          decrement,
          const SizedBox(width: KeycapMetrics.keyGap),
          field,
          const SizedBox(width: KeycapMetrics.keyGap),
          increment,
        ],
      ),
      fieldBuilder: (context, d) {
        final layered = DesignStyleOf([style, theme.textFieldStyle], d.states);
        final enabled = !d.states.contains(WidgetState.disabled);
        final focused = d.states.contains(WidgetState.focused);
        // The whole well takes a tap into the number, as a text field's
        // does: the words alone are a sliver of a finger's reach.
        return SizedBox(
          width: unit == null ? 72 : 104,
          height: h,
          child: MouseRegion(
            cursor: enabled ? SystemMouseCursors.text : MouseCursor.defer,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: enabled ? d.focusNode.requestFocus : null,
              child: KeycapWell(
                radius: BorderRadius.circular(KeycapMetrics.fieldRadius),
                floor:
                    layered.fill ??
                    (enabled ? null : Color.lerp(c.well, c.ground, 0.6)),
                rim: focused ? c.focus : null,
                rimWidth: KeycapMetrics.focusWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: KeycapSpacing.small,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DesignCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        // Material's field keeps a node of its own; the
                        // stepper's node takes the value from here
                        // (RawNumberField's contract).
                        child: ListenableBuilder(
                          listenable: d.controller,
                          builder: (context, child) =>
                              Semantics(value: d.controller.text, child: child),
                          child: Material(
                            type: MaterialType.transparency,
                            child: TextField(
                              controller: d.controller,
                              focusNode: d.focusNode,
                              keyboardType: d.keyboardType,
                              inputFormatters: d.inputFormatters,
                              onEditingComplete: d.onEditingComplete,
                              enabled: enabled,
                              decoration: null,
                              textAlign: TextAlign.center,
                              cursorColor: c.accent.top,
                              cursorWidth: 2,
                              style: theme.textTheme.figure.copyWith(
                                fontSize: 16,
                                color: enabled ? c.ink : c.inkDisabled,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (unit != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: KeycapSpacing.tight,
                        ),
                        child: Text(
                          unit!,
                          style: theme.textTheme.secondary.copyWith(
                            color: enabled ? c.inkMuted : c.inkDisabled,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      buttonBuilder: (context, d) {
        final face = keycapKeyFace(theme, KeycapKind.alpha, d.states);
        return TapTargetPadding(
          child: SizedBox.square(
            dimension: h,
            child: AnimatedKeycapCap(
              face: face,
              walls: KeycapMetrics.walls(h),
              child: Center(
                child: Icon(
                  d.isIncrement ? LucideIcons.plus : LucideIcons.minus,
                  size: 20,
                  color: face.legend,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min, defaultValue: null))
      ..add(DoubleProperty('max', max, defaultValue: null));
  }
}

/// Any control with its label over it and its help or error under it, as
/// [KeycapTextField] stands: a switch, a select, a row of radios, a
/// stepper. One control takes the label as its name and the error and help
/// as its hint; a group of controls keeps each its own node, the label
/// naming the group ([mergeSemantics]). Built on ui_core's `RawInputDecorator`.
///
/// ```dart
/// KeycapField(labelText: 'Copies', helperText: 'Up to 20.', child: KeycapStepper(value: 1, onChanged: setCopies))
/// ```
class KeycapField extends StatelessWidget {
  /// [child] with its label, help and error.
  const KeycapField({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.invalid = false,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.mergeSemantics,
  });

  /// The control.
  final Widget child;

  /// What the control is.
  final String? labelText;

  /// Help under it.
  final String? helperText;

  /// What is wrong, under it; an empty string marks it wrong without words,
  /// as [invalid] does.
  final String? errorText;

  /// Whether its value is wrong with no words to say why: a screen reader
  /// hears it invalid and the help gives way, as with [errorText].
  final bool invalid;

  /// Whether an answer is required: said to a screen reader, and marked.
  final bool required;

  /// Whether the control takes input: its label greys when not.
  final bool enabled;

  /// The control's focus node, so a tap on the label focuses it.
  final FocusNode? focusNode;

  /// Whether the control is one node that takes the label as its name
  /// (true) or a group the label names (false); read from the child when
  /// null.
  final bool? mergeSemantics;

  @override
  Widget build(BuildContext context) => RawInputDecorator(
    labelText: labelText,
    helperText: helperText,
    errorText: errorText == '' ? null : errorText,
    invalid: invalid || errorText == '',
    required: required,
    enabled: enabled,
    focusNode: focusNode,
    mergeSemantics: mergeSemantics,
    builder: (context, parts) {
      final theme = KeycapTheme.of(context);
      final c = theme.colors;
      final secondary = theme.textTheme.secondary;
      final line = (secondary.fontSize ?? 14) * (secondary.height ?? 1);
      final label = parts.labelText;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            ExcludeSemantics(
              child: KeycapFieldLabel(
                parts.required ? '$label *' : label,
                enabled: parts.enabled,
              ),
            ),
          parts.control,
          if (parts.error != null)
            Padding(
              padding: const EdgeInsets.only(top: KeycapSpacing.small),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: line,
                    child: Center(
                      child: Icon(
                        LucideIcons.circleAlert,
                        size: 16,
                        color: c.dangerInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: KeycapSpacing.small),
                  Expanded(
                    child: DefaultTextStyle(
                      style: secondary.copyWith(color: c.dangerInk),
                      child: parts.error!,
                    ),
                  ),
                ],
              ),
            )
          else if (parts.helper != null && !parts.invalid)
            Padding(
              padding: const EdgeInsets.only(top: KeycapSpacing.small),
              child: DefaultTextStyle(style: secondary, child: parts.helper!),
            ),
        ],
      );
    },
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('invalid', value: invalid, ifTrue: 'invalid'))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}
