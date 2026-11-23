/// Appliance's other fields, all wells in the panel like
/// [ApplianceTextField]: [ApplianceSearchField] (a lens and a clear key),
/// [AppliancePasswordField] (a key that shows the words), [ApplianceInputGroup]
/// (a well with its units moulded at its ends), [ApplianceOtpField] (a code in
/// display-window cells) and [ApplianceField] (any control with its label,
/// help and error).
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/glyphs.dart';
import 'material.dart';
import 'text_field.dart';
import 'theme.dart';
import 'internal/field_frame.dart';

/// A small key standing inside a well's end: a search's clear key, a
/// password's eye. Its target reaches the floor round it.
class _WellKey extends StatelessWidget {
  const _WellKey({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.latched = false,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool latched;

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    return RawButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      // A latched key (the eye, revealing) is a button that is selected.
      semanticSelected: latched ? true : null,
      builder: (context, states, _) {
        final down = latched || states.contains(WidgetState.pressed);
        final disabled = states.contains(WidgetState.disabled);
        final face =
            (down
                    ? ApplianceFace.keyDown(
                        c,
                        radius: ApplianceMetrics.smallKeyRadius,
                      )
                    : ApplianceFace.key(
                        c,
                        radius: ApplianceMetrics.smallKeyRadius,
                      ))
                .copyWith(
                  lift: disabled ? 0.3 : null,
                  foreground: disabled ? c.printDisabled : c.printMuted,
                  focus: states.contains(WidgetState.focused)
                      ? c.focus
                      : c.focus.withValues(alpha: 0),
                );
        return TapTargetPadding(
          child: SizedBox.square(
            dimension: 28,
            child: AnimatedApplianceSurface(
              face: face,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(size: 16, color: face.foreground),
                  child: icon,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A search field: a well with a lens at its start and, once something is
/// typed, a small clear key at its end. The keyboard's action key reads
/// "Search".
///
/// [onSubmitted] runs the search (the keyboard's key, Enter); [onChanged]
/// as the words change, for a search as you type.
///
/// ```dart
/// ApplianceSearchField(hintText: 'Search the shop', onSubmitted: (words) {})
/// ```
class ApplianceSearchField extends StatefulWidget {
  /// A search field.
  const ApplianceSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.semanticLabel = 'Search',
    this.clearLabel = 'Clear',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.style,
  });

  /// The words' controller; one you give is yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// What the well says while it is empty.
  final String? hintText;

  /// The field's name for a screen reader.
  final String semanticLabel;

  /// The clear key's name for a screen reader.
  final String clearLabel;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Runs the search.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field takes words.
  final bool enabled;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// The well's style, over [ApplianceThemeData.textFieldStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceSearchField> createState() => _ApplianceSearchFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _ApplianceSearchFieldState extends State<ApplianceSearchField> {
  TextEditingController? _own;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'ApplianceSearchField'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(ApplianceSearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_changed);
      _controller.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ApplianceTextField(
    controller: _controller,
    focusNode: _focus,
    hintText: widget.hintText,
    semanticLabel: widget.semanticLabel,
    leading: const ApplianceGlyph(ApplianceLensPainter.new),
    trailing: _controller.text.isEmpty || !widget.enabled
        ? null
        : _WellKey(
            icon: const ApplianceGlyph(ApplianceCrossPainter.new),
            semanticLabel: widget.clearLabel,
            onPressed: _clear,
          ),
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    textInputAction: TextInputAction.search,
    enabled: widget.enabled,
    autofocus: widget.autofocus,
    style: widget.style,
  );
}

/// An eye, open or struck through.
class _EyePainter extends CustomPainter {
  _EyePainter(this.color, {required this.struck});

  final Color color;
  final bool struck;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final eye = Path()
      ..moveTo(s * 0.08, s * 0.5)
      ..quadraticBezierTo(s * 0.5, s * 0.08, s * 0.92, s * 0.5)
      ..quadraticBezierTo(s * 0.5, s * 0.92, s * 0.08, s * 0.5)
      ..close();
    canvas
      ..drawPath(eye, paint)
      ..drawCircle(Offset(s * 0.5, s * 0.5), s * 0.14, paint);
    if (struck) {
      canvas.drawLine(
        Offset(s * 0.18, s * 0.82),
        Offset(s * 0.82, s * 0.18),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EyePainter old) =>
      old.color != color || old.struck != struck;
}

/// A password field: the words hidden, and a small key at the well's end
/// that shows them while it is latched down (and hides them again).
///
/// [hideOnBlur] hides them again when the field loses the focus.
///
/// ```dart
/// AppliancePasswordField(labelText: 'Password', onChanged: (words) {})
/// ```
class AppliancePasswordField extends StatelessWidget {
  /// A password field.
  const AppliancePasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText = 'Password',
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.hideOnBlur = false,
    this.enabled = true,
    this.style,
  });

  /// The words' controller; one you give is yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words over the well.
  final String? labelText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key submits the words.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// What the platform's password manager may fill in.
  final Iterable<String> autofillHints;

  /// Whether the words hide again when the field loses the focus.
  final bool hideOnBlur;

  /// Whether the field takes words.
  final bool enabled;

  /// The well's style, over [ApplianceThemeData.textFieldStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => RawPasswordReveal(
    focusNode: focusNode,
    hideOnBlur: hideOnBlur,
    builder: (context, password) => ApplianceTextField(
      controller: controller,
      focusNode: focusNode,
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      obscureText: password.obscured,
      autofillHints: autofillHints,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      style: style,
      trailing: _WellKey(
        icon: ApplianceGlyph((c) => _EyePainter(c, struck: !password.obscured)),
        semanticLabel: password.toggleLabel,
        latched: !password.obscured,
        onPressed: enabled ? password.toggle : null,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

/// A well with what the words are counted in moulded at its ends: a
/// currency before them, a unit after ("£" … ".00", … "kg"). The add-ons are
/// the panel's plastic, standing flush at a parting line inside the well;
/// one bezel lights round the whole while the words have the focus.
///
/// ```dart
/// ApplianceInputGroup(labelText: 'Weight', suffix: 'kg', keyboardType: TextInputType.number)
/// ```
class ApplianceInputGroup extends StatefulWidget {
  /// A well with [prefix] and [suffix].
  const ApplianceInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.semanticLabel,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.style,
  });

  /// The words' controller; one you give is yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words over the well.
  final String? labelText;

  /// What the well says while it is empty.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// The field's name for a screen reader, when [labelText] is not shown.
  final String? semanticLabel;

  /// What stands before the words ("£", "https://").
  final String? prefix;

  /// What stands after them ("kg", ".00").
  final String? suffix;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key submits the words.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// Formatters run on every change.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field takes words.
  final bool enabled;

  /// The well's style, over [ApplianceThemeData.textFieldStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceInputGroup> createState() => _ApplianceInputGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('prefix', prefix, defaultValue: null))
      ..add(StringProperty('suffix', suffix, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _ApplianceInputGroupState extends State<ApplianceInputGroup> {
  TextEditingController? _own;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'ApplianceInputGroup'));

  @override
  void dispose() {
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final error = widget.errorText != null;
    Widget addOn(String words, {required bool start}) {
      final side = BorderSide(color: c.seamShade, width: 1);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: c.face,
          border: BorderDirectional(
            end: start ? side : BorderSide.none,
            start: start ? BorderSide.none : side,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ApplianceSpacing.medium,
          ),
          child: Center(
            widthFactor: 1,
            child: DesignCapCenter(
              capHeightFactor: theme.capHeightFactor,
              child: Text(
                words,
                style: theme.textTheme.body.copyWith(
                  color: widget.enabled ? c.printMuted : c.printDisabled,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return applianceFieldFrame(
      labelText: widget.labelText,
      semanticLabel: widget.semanticLabel,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      control: DesignInputGroup(
        focusNode: _focus,
        enabled: widget.enabled,
        isError: error,
        builder: (context, states, child) {
          final layered = DesignStyleOf([
            widget.style,
            theme.textFieldStyle,
          ], states);
          final face = layered.on(
            ApplianceFace.well(c).copyWith(
              lift: widget.enabled ? -1 : -0.5,
              edge: error ? c.danger : null,
              focus: states.contains(WidgetState.focused)
                  ? (error ? c.danger : c.focus)
                  : c.focus.withValues(alpha: 0),
            ),
          );
          return AnimatedApplianceSurface(
            face: face,
            child: ClipRRect(borderRadius: face.radius, child: child),
          );
        },
        child: SizedBox(
          height: theme.controlHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.prefix != null) addOn(widget.prefix!, start: true),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ApplianceSpacing.medium,
                  ),
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Semantics(
                      container: true,
                      label: widget.semanticLabel ?? widget.labelText,
                      child: DesignTextEntryBox(
                        minHeight: theme.controlHeight,
                        controller: _controller,
                        maxLines: 1,
                        hint: widget.hintText == null
                            ? null
                            : Text(
                                widget.hintText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.body.copyWith(
                                  color: c.printMuted,
                                ),
                              ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            decoration: null,
                            style: theme.textTheme.body.copyWith(
                              color: widget.enabled ? c.print : c.printDisabled,
                            ),
                            cursorColor: c.signal,
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
              if (widget.suffix != null) addOn(widget.suffix!, start: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// A code typed into a display window: each character in a cell of smoked
/// glass, lit in the display's figure; the cell the next character goes in
/// shows a lit bar. Six cells stand in two threes.
///
/// [onCompleted] runs when every cell is full. The whole is one text field to
/// a screen reader, and takes a pasted code.
///
/// ```dart
/// ApplianceOtpField(onCompleted: (code) {})
/// ```
class ApplianceOtpField extends StatelessWidget {
  /// A field for a code of [length] characters.
  const ApplianceOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.semanticLabel = 'One-time code',
    this.isError = false,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.style,
  });

  /// How many characters.
  final int length;

  /// The code's controller; one you give is yours to dispose.
  final RawOtpController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Called as the code changes.
  final ValueChanged<String>? onChanged;

  /// Called with the code once every cell is full.
  final ValueChanged<String>? onCompleted;

  /// The field's name for a screen reader.
  final String? semanticLabel;

  /// Whether the code is wrong: the cells' rims turn red.
  final bool isError;

  /// Whether the field takes a code.
  final bool enabled;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Whether the characters are hidden.
  final bool obscureText;

  /// The cells' style, over [ApplianceThemeData.displayStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final cell = theme.controlHeight;
    return RawOtpField(
      length: length,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onCompleted: onCompleted,
      semanticLabel: semanticLabel,
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
                    ? ApplianceSpacing.large
                    : ApplianceSpacing.small,
              ),
            slot,
          ],
        ],
      ),
      slotBuilder: (context, slot) {
        final states = <WidgetState>{
          if (!slot.enabled) WidgetState.disabled,
          if (slot.focused && slot.active) WidgetState.focused,
          if (slot.isError) WidgetState.error,
        };
        final layered = DesignStyleOf([style, theme.displayStyle], states);
        final face = layered.on(
          ApplianceFace.well(
            c,
            radius: ApplianceMetrics.smallKeyRadius,
            fill: c.display,
          ).copyWith(
            lift: slot.enabled ? -1 : -0.5,
            foreground: slot.enabled ? c.onDisplay : c.printDisabled,
            edge: slot.isError ? c.danger : null,
            focus: slot.focused && slot.active
                ? (slot.isError ? c.danger : c.focus)
                : c.focus.withValues(alpha: 0),
          ),
        );
        return SizedBox(
          width: cell * 0.75,
          height: cell,
          child: AnimatedApplianceSurface(
            face: face,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  slot.obscured && slot.filled ? '•' : slot.character,
                  style: layered.text(
                    theme.textTheme.figure.copyWith(color: face.foreground),
                  ),
                ),
                if (slot.focused && slot.active && !slot.filled)
                  Positioned(
                    bottom: ApplianceSpacing.small,
                    child: Container(
                      width: cell * 0.36,
                      height: 2,
                      color: c.signal,
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

/// Any control with its label over it and its help or error under it, as
/// [ApplianceTextField] stands: a switch, a select, a row of radios, a
/// slider. A single control's node takes the label as its name and the
/// error and help as its hint; a group of controls (a row or column of
/// them, a selector, a stepper, chips, a time picker's figures and keys)
/// keeps each control's own node and tap, and the label names the group
/// ([mergeSemantics]).
///
/// ```dart
/// ApplianceField(labelText: 'Delivery day', helperText: 'We deliver Monday to Saturday.', child: ApplianceSwitch(value: true, onChanged: (on) {}))
/// ```
class ApplianceField extends StatelessWidget {
  /// [child] with its label, help and error.
  const ApplianceField({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
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

  /// What is wrong, under it beside a red lamp.
  final String? errorText;

  /// Whether an answer is required: said to a screen reader, and marked.
  final bool required;

  /// Whether the control takes input: its label greys when not.
  final bool enabled;

  /// The control's focus node, so a tap on the label focuses it.
  final FocusNode? focusNode;

  /// Whether the control is one node that takes the label as its name
  /// (true) or a group the label names (false). Left null, ui_core's
  /// RawInputDecorator reads what the child brings to the semantics tree: one
  /// control is one node; several (a stepper's keys, a segmented choice,
  /// radios, chips) keep each its own node and tap, the label naming them;
  /// and a group that already names itself is not named again.
  final bool? mergeSemantics;

  @override
  Widget build(BuildContext context) => applianceFieldFrame(
    labelText: labelText,
    helperText: helperText,
    errorText: errorText,
    required: required,
    enabled: enabled,
    focusNode: focusNode,
    mergeSemantics: mergeSemantics,
    control: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'));
  }
}
