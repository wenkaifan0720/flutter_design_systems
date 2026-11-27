// Typed choices and text entry, using the look's moulded parts and inset shadows.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'chrome_metrics.dart';
import 'controls.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'shapes.dart';
import 'internal/cell_bank.dart';
import 'internal/eased_lines.dart';
import 'internal/reach.dart' show NeumorphicFacePlace, NeumorphicOwnRoot;
import 'internal/error_line.dart';
import 'internal/field_hooks.dart';
import 'internal/panel.dart' show neumorphicFieldWords;
import 'editing.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'localizations.dart';
import 'layout.dart';
import 'ornaments.dart';
import 'raised.dart';
import 'theme.dart';
import 'internal/cap_label.dart';
import 'knobs.dart' show NeumorphicElevation;
import 'internal/out_of_use.dart';
import 'internal/moulded.dart';
import 'internal/group_rows.dart' show NeumorphicGroupRowScope;

/// A search groove with its own clear action, keeping focus when cleared.
///
/// ```dart
/// NeumorphicSearchField(hintText: 'Search the shelf', onChanged: filter)
/// ```
class NeumorphicSearchField extends StatefulWidget {
  /// Creates a [NeumorphicSearchField].
  const NeumorphicSearchField({
    super.key,
    required this.hintText,
    this.labelText,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.clearLabel,
    this.onEditingComplete,
    this.errorText,
    this.inputFormatters,
    this.autofillHints,
    this.keyboardType,
    this.style,
  });

  /// Form-owned completion, including traversal past the clear action.
  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  /// Called when the user finishes editing.
  final VoidCallback? onEditingComplete;

  /// Placeholder text shown when the input is empty.
  final String hintText;

  /// An error message displayed beneath the input.
  final String? errorText;

  /// Formatters applied to user edits in order.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill purposes supplied to the platform text input.
  final Iterable<String>? autofillHints;

  /// The keyboard layout requested from the platform.
  final TextInputType? keyboardType;

  /// The text identifying this item or control.
  final String? labelText;

  /// The accessible label of the clear action; null uses localizations.
  final String? clearLabel;

  /// An optional externally owned text controller.
  final TextEditingController? controller;

  /// An optional externally owned focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first attached.
  final bool autofocus;

  /// Whether the control accepts user interaction.
  final bool enabled;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the current text.
  final ValueChanged<String>? onSubmitted;
  @override
  State<NeumorphicSearchField> createState() => _NeumorphicSearchFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(StringProperty('hintText', hintText))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
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
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('clearLabel', clearLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
      )
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      );
  }
}

class _NeumorphicSearchFieldState extends State<NeumorphicSearchField> {
  TextEditingController? _own;
  FocusNode? _ownNode;
  TextEditingController get _text =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  void _changed() => setState(() {});
  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
  }

  @override
  void didUpdateWidget(NeumorphicSearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_changed);
      _text.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _text.removeListener(_changed);
    _own?.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The search glyph and the hint say what the field is: its label names the input and is not drawn.
    final hooks = NeumorphicFieldHooks.maybeOf(context);
    return NeumorphicFieldHooks(
      decorate: hooks?.decorate,
      failureLine: hooks?.failureLine,
      nameOnly: true,
      child: NeumorphicTextField(
        style: widget.style,
        controller: _text,
        focusNode: _node,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        hintText: widget.hintText,
        labelText: widget.labelText,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        errorText: widget.errorText,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        keyboardType: widget.keyboardType,
        textInputAction: TextInputAction.search,
        leading: const Icon(NeumorphicGlyphs.search, size: 20),
        // The key stands at its target in the field's key slot, which lets a target overhang the groove without
        // growing the field: a 32-tall box round it here stopped taps 8 short of the target above and below.
        trailing: _text.text.isEmpty
            ? null
            : NeumorphicRoundButton(
                NeumorphicGlyphs.close,
                size: 32,
                semanticLabel:
                    widget.clearLabel ??
                    NeumorphicLocalizations.of(context).clearSearch,
                onPressed: !widget.enabled
                    ? null
                    : () {
                        _text.clear();
                        widget.onChanged?.call('');
                        _node.requestFocus();
                      },
              ),
      ),
    );
  }
}

/// A multiline field with a steady label and the same selection menu as a field.
///
/// ```dart
/// NeumorphicTextArea(labelText: 'Notes', onChanged: saveDraft)
/// ```
class NeumorphicTextArea extends StatelessWidget {
  /// Creates a [NeumorphicTextArea].
  const NeumorphicTextArea({
    super.key,
    this.autofocus = false,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.maxLines = 4,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.maxLength,
    this.style,
  }) : assert(maxLines >= 1),
       assert((maxLength ?? 1) > 0);

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  /// An optional externally owned text controller.
  final TextEditingController? controller;

  /// The initial text when no controller is supplied.
  final String? initialValue;

  /// The text identifying this item or control.
  final String? labelText;

  /// Placeholder text shown when the input is empty.
  final String? hintText;

  /// Supporting text beneath the input.
  final String? helperText;

  /// An error message displayed beneath the input.
  final String? errorText;

  /// The initial number of visible text lines.
  final int maxLines;

  /// The maximum number of input characters, when specified.
  final int? maxLength;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the current text.
  final ValueChanged<String>? onSubmitted;

  /// An optional externally owned focus node.
  final FocusNode? focusNode;

  /// Whether the control accepts user interaction.
  final bool enabled;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => NeumorphicTextField(
    autofocus: autofocus,
    style: style,
    controller: controller,
    initialValue: initialValue,
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    maxLines: maxLines,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    focusNode: focusNode,
    enabled: enabled,
    maxLength: maxLength,
    keyboardType: TextInputType.multiline,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('initialValue', initialValue, defaultValue: null))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 4))
      ..add(IntProperty('maxLength', maxLength, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true))
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
      );
  }
}

/// One text input behind a row of code cells, supporting paste and one-time-code autofill.
///
/// ```dart
/// NeumorphicInputOtp(labelText: 'Verification code', length: 6, onCompleted: verify)
/// ```
class NeumorphicInputOtp extends StatefulWidget {
  /// Creates a [NeumorphicInputOtp].
  const NeumorphicInputOtp({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.labelText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.onEditingComplete,
    this.textInputAction = TextInputAction.done,
    this.keyboardType = TextInputType.number,
    this.inputFormatters = const [],
    this.autofillHints = const [AutofillHints.oneTimeCode],
    this.enabled = true,
    this.autofocus = false,
    this.obscure = false,
    this.style,
  }) : assert(length > 0 && length <= 12);

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  /// The number of code characters and displayed cells.
  final int length;

  /// An optional externally owned text controller.
  final TextEditingController? controller;

  /// An optional externally owned focus node.
  final FocusNode? focusNode;

  /// The text identifying this item or control.
  final String? labelText;

  /// Supporting text beneath the input.
  final String? helperText;

  /// An error message displayed beneath the input.
  final String? errorText;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<String>? onChanged;

  /// Called when the entered code reaches the requested length.
  final ValueChanged<String>? onCompleted;

  /// Invoked by the keyboard's completion action, including a partial code.
  final ValueChanged<String>? onSubmitted;

  /// Whether the control accepts user interaction.
  final bool enabled;

  /// Whether to request focus when first attached.
  final bool autofocus;

  /// The keyboard's completion action.
  final TextInputAction textInputAction;

  /// The keyboard shown for the numeric code.
  final TextInputType keyboardType;

  /// Additional formatters, applied before the digit and length limits.
  final List<TextInputFormatter> inputFormatters;

  /// Hints supplied to the platform's autofill service.
  final Iterable<String> autofillHints;

  /// Form-owned completion and focus traversal.
  final VoidCallback? onEditingComplete;

  /// Whether the characters are hidden (a PIN): a filled cell shows a dot.
  final bool obscure;

  @override
  State<NeumorphicInputOtp> createState() => _NeumorphicCodeFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('length', length, defaultValue: 6))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onCompleted',
          onCompleted,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true))
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
      )
      ..add(
        EnumProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: TextInputAction.done,
        ),
      )
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: TextInputType.number,
        ),
      )
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: const <TextInputFormatter>[],
        ),
      )
      ..add(
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: const [AutofillHints.oneTimeCode],
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(DiagnosticsProperty<bool>('obscure', obscure, defaultValue: false));
  }
}

class _NeumorphicCodeFieldState extends State<NeumorphicInputOtp> {
  // The code lives in the caller's controller when there is one: ui_core's
  // field reads and writes it, filters it, and leaves it the caller's.
  late RawOtpController _code = _make();

  RawOtpController _make() =>
      RawOtpController(length: widget.length, text: widget.controller);

  @override
  void didUpdateWidget(NeumorphicInputOtp old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller || old.length != widget.length) {
      final was = _code;
      _code = _make();
      WidgetsBinding.instance.addPostFrameCallback((_) => was.dispose());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // A form that says the field's words itself (a kit adapter) wraps the code in them; else ui_core's decorator reads
    // the label, the help and the error on the code's one node.
    final hooks = NeumorphicFieldHooks.maybeOf(context);
    final decorate = hooks?.decorate;
    final failureLine = hooks?.failureLine;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (widget.errorText != null) WidgetState.error,
    };
    final baseStyle = neumorphicStyleOf([
      widget.style,
      t.textFieldTheme,
    ], states);
    final shape = baseStyle.shape;
    final safe =
        shape?.dimensions.resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final digitStyle = t.textTheme.title.merge(baseStyle.textStyle);
    final scaler = MediaQuery.textScalerOf(context);
    Widget cells(BuildContext context, List<Widget> slots) => LayoutBuilder(
      builder: (context, box) {
        final max = box.hasBoundedWidth ? box.maxWidth : 56.0 * slots.length;
        const gap = 8.0;
        // A cell is its widest figure and 8 each side: taken as a whole em, at twice the text six cells would want 56
        // each and the code would break into two rows of three, read as two codes.
        final figure = TextPainter(
          text: TextSpan(text: '0', style: digitStyle.tabular),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final digitWidth = figure.width + 16 + safe.horizontal;
        figure.dispose();
        final mostColumns = math.max(
          1,
          ((max + gap) / (digitWidth + gap)).floor(),
        );
        final rows = (slots.length / mostColumns).ceil();
        final columns = (slots.length / rows).ceil();
        final side = math.max(
          1.0,
          math.min(
            math.max(56.0, digitWidth),
            (max - gap * (columns - 1)) / columns,
          ),
        );
        final height = math.max(
          math.max(
            NeumorphicChromeMetrics.targetOf(context).height,
            baseStyle.minimumSize?.height ?? 0,
          ),
          scaler.scale(28) + 16 + safe.vertical,
        );
        // The rows planned, each as long as the first: a wrap packed as many as fit and left a short last row (4 and 2).
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (
                    var i = r * columns;
                    i < math.min(slots.length, (r + 1) * columns);
                    i++
                  ) ...[
                    if (i > r * columns) const SizedBox(width: gap),
                    neumorphicOwnSize(
                      width: side,
                      height: height,
                      child: slots[i],
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
    Widget cell(BuildContext context, RawOtpSlot slot) {
      // The next cell to fill deepens while the code has focus, and the caret's place is that cell; a filled cell of a
      // hidden code shows a dot.
      final lit = slot.active && slot.focused;
      final cellStates = {...states, if (lit) WidgetState.focused};
      final look = neumorphicStyleOf([
        widget.style,
        t.textFieldTheme,
      ], cellStates);
      return NeumorphicFieldBox(
        style: widget.style,
        states: cellStates,
        shape: shape,
        padding: EdgeInsets.zero,
        child: Center(
          child: Text(
            slot.obscured && slot.filled ? '•' : slot.character,
            style: t.textTheme.title
                .merge(look.textStyle)
                .copyWith(color: look.foreground),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      );
    }

    final field = RawOtpField(
      controller: _code,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      isError: widget.errorText != null,
      obscureText: widget.obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      contextMenuBuilder: (context, anchors, items) =>
          NeumorphicTextContextMenu(anchors: anchors, buttonItems: items),
      layoutBuilder: cells,
      slotBuilder: cell,
    );
    final label = widget.labelText;
    final helper = widget.helperText;
    final error = widget.errorText;
    if (decorate != null) {
      // Under a form's hooks the form names the code and says its failure, on the code's one node.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            ExcludeSemantics(
              child: Text(
                label,
                style: t.textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          NeumorphicOutOfUse(
            off: !widget.enabled,
            child: MergeSemantics(child: decorate(field)),
          ),
          // The help or the failure eases in under the boxes.
          NeumorphicHintSlot(
            child: error != null
                ? KeyedSubtree(
                    key: const ValueKey<bool>(true),
                    child: (failureLine ?? (child) => child)(
                      NeumorphicErrorLine(
                        live: failureLine == null,
                        child: Text(error),
                      ),
                    ),
                  )
                : helper != null
                ? ExcludeSemantics(
                    key: const ValueKey<bool>(false),
                    child: Text(helper, style: t.textTheme.caption),
                  )
                : null,
          ),
        ],
      );
    }
    return RawInputDecorator(
      labelText: label ?? NeumorphicLocalizations.of(context).verificationCode,
      helperText: helper,
      errorText: error,
      invalid: error != null,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      child: NeumorphicOutOfUse(off: !widget.enabled, child: field),
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            DefaultTextStyle.merge(
              style: t.textTheme.caption.copyWith(fontWeight: FontWeight.w700),
              child: parts.label ?? ExcludeSemantics(child: Text(label)),
            ),
            const SizedBox(height: 8),
          ],
          parts.control,
          // The help or the failure eases in under the boxes.
          NeumorphicHintSlot(
            child: error != null
                ? NeumorphicErrorLine(
                    live: false,
                    child: parts.error ?? Text(error),
                  )
                : helper != null
                ? DefaultTextStyle.merge(
                    style: t.textTheme.caption,
                    child:
                        parts.helper ?? ExcludeSemantics(child: Text(helper)),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// A typed choice with the look's menu and keyboard navigation.
///
/// ```dart
/// NeumorphicSelect<String>(labelText: 'Space', options: const [NeumorphicMenuItem('quiet', 'Quiet room')], value: space, onChanged: choose)
/// ```
class NeumorphicSelect<T> extends StatefulWidget {
  /// Creates a [NeumorphicSelect].
  const NeumorphicSelect({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.options,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.style,
  });

  /// Field face and words before the text-field component theme.
  final NeumorphicStyle? style;

  /// The menu entries from which a value can be selected.
  final List<NeumorphicMenuItem<T>> options;

  /// The selected option value, or null for no selection.
  final T? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<T>? onChanged;

  /// The text identifying this item or control.
  final String? labelText;

  /// Text shown before an option has been selected.
  final String? hintText;

  /// Supporting text beneath the input.
  final String? helperText;

  /// An error message displayed beneath the input.
  final String? errorText;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  State<NeumorphicSelect<T>> createState() => _NeumorphicSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(IterableProperty<NeumorphicMenuItem<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
      );
  }
}

class _NeumorphicSelectState<T> extends State<NeumorphicSelect<T>> {
  bool _open = false;
  // Whether the face has the keys' focus: its label is lit in the pigment's ink, as a text field's is.
  bool _focused = false;
  // The face, which the open list hangs from and matches in width.
  final _faceKey = GlobalKey();
  Future<void> _show() async {
    if (_open ||
        widget.onChanged == null ||
        !widget.options.any((o) => !o.divider && o.enabled)) {
      return;
    }
    final box =
        (_faceKey.currentContext ?? context).findRenderObject()! as RenderBox;
    setState(() => _open = true);
    final result = await showNeumorphicMenu<T>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      label: widget.labelText,
      matchWidth: true,
      fieldWords: neumorphicFieldWords(NeumorphicTheme.of(context)),
      items: [
        for (final item in widget.options)
          if (item.divider)
            NeumorphicMenuItem<T>.divider()
          else
            NeumorphicMenuItem<T>(
              item.value as T,
              item.label!,
              icon: item.icon,
              note: item.note,
              enabled: item.enabled,
              danger: item.danger,
              selected: item.value == widget.value,
            ),
      ],
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (result != null) widget.onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final selected = widget.options
        .where((o) => !o.divider && o.value == widget.value)
        .firstOrNull;
    final value =
        selected?.label ??
        widget.hintText ??
        NeumorphicLocalizations.of(context).choose;
    final face = _face(t, value);
    final label = widget.labelText;
    final helper = widget.helperText;
    final error = widget.errorText;
    // The face names itself by its label and value (a button's name is its own); the help and the error are its
    // hint, from ui_core's decorator.
    return RawInputDecorator(
      helperText: helper,
      errorText: error,
      enabled: widget.onChanged != null,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        // Start, not stretch: in a row of a toolbar (no width to stretch to) the face takes its own width.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            // A focused select names itself in the pigment's ink, as a focused text field does.
            NeumorphicLabelInk(
              lit: _focused,
              style: t.textTheme.caption.copyWith(fontWeight: FontWeight.w700),
              child: ExcludeSemantics(child: Text(label)),
            ),
            const SizedBox(height: 8),
          ],
          parts.control,
          // The help or the failure eases in under the face.
          NeumorphicHintSlot(
            child: error != null
                ? NeumorphicErrorLine(live: false, child: parts.error!)
                : helper != null
                ? DefaultTextStyle.merge(
                    style: t.textTheme.caption,
                    child: parts.helper!,
                  )
                : null,
          ),
        ],
      ),
      // The face takes its column; the open list matches it.
      child: LayoutBuilder(
        builder: (context, box) {
          final look = neumorphicStyleOf([
            widget.style,
            t.textFieldTheme,
          ], const {});
          final words = t.textTheme.body.merge(look.textStyle);
          final scaler = MediaQuery.textScalerOf(context);
          var widest = 0.0;
          for (final o in [
            for (final o in widget.options)
              if (!o.divider) o.label!,
            // The prompt too, so choosing never moves the face's end.
            widget.hintText ?? NeumorphicLocalizations.of(context).choose,
          ]) {
            final painter = TextPainter(
              text: TextSpan(text: o, style: words),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            widest = math.max(widest, painter.width);
            painter.dispose();
          }
          final own =
              (widest +
                      t.density
                          .padding(const EdgeInsets.symmetric(horizontal: 14))
                          .horizontal +
                      12 +
                      (look.iconSize ?? 18))
                  .ceilToDouble() +
              1;
          // In a column it takes the column, as every field does (Material's dropdown field too); alone in a row with no
          // bound (a filter in a toolbar), its widest option's width.
          if (box.hasBoundedWidth) return face;
          return SizedBox(
            width: math.min(own, neumorphicWideControlMax),
            child: face,
          );
        },
      ),
    );
  }

  Widget _face(NeumorphicThemeData t, String value) => NeumorphicTap(
    focusNode: widget.focusNode,
    autofocus: widget.autofocus,
    key: _faceKey,
    style: widget.style,
    themeStyle: t.textFieldTheme,
    expanded: _open,
    // A select is a field: its focus deepens its well (below) and lights its label, as a text field's does, and never
    // raises the face.
    showFocus: false,
    onStatesChanged: (states) {
      final focused = states.contains(WidgetState.focused);
      if (focused != _focused) setState(() => _focused = focused);
    },
    semanticLabel: [
      if (widget.labelText != null) widget.labelText!,
      value,
    ].join(', '),
    onPressed: widget.onChanged == null ? null : _show,
    // The arrows open it too, as Enter and Space do: its list opens on the chosen option, or the first, and the
    // arrows go on moving there.
    onKeyEvent: widget.onChanged == null
        ? null
        : (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                    event.logicalKey == LogicalKeyboardKey.arrowUp)) {
              _show();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
    child: Builder(
      builder: (context) {
        // While its list is open the well rests: the list shows where the keys are.
        final states = {
          ...NeumorphicStatesScope.of(context),
          if (widget.errorText != null) WidgetState.error,
        }..removeWhere((s) => _open && s == WidgetState.focused);
        final look = neumorphicStyleOf([
          widget.style,
          t.textFieldTheme,
        ], states);
        return NeumorphicOutOfUse(
          // Disabled reads as the other fields do.
          off: widget.onChanged == null,
          child: NeumorphicStatesScope(
            states: states,
            child: NeumorphicFieldBox(
              style: widget.style,
              states: states,
              // The density's air, so the face keeps the control height (a button's beside it) at every density.
              child: Padding(
                padding: t.density.padding(
                  const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: neumorphicLabel(
                        Text(
                          value,
                          style: t.textTheme.body
                              .merge(look.textStyle)
                              .copyWith(color: look.foreground),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _open
                          ? NeumorphicGlyphs.chevronUp
                          : NeumorphicGlyphs.chevronDown,
                      size: look.iconSize ?? 18,
                      color: look.foreground,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// A rounded-square inset checkbox; null is mixed. Tristate adds mixed to the press cycle.
///
/// ```dart
/// NeumorphicCheckbox(value: agreed, semanticLabel: 'Agree', onChanged: change)
/// ```
class NeumorphicCheckbox extends StatelessWidget {
  /// Creates a [NeumorphicCheckbox].
  const NeumorphicCheckbox({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.value,
    required this.semanticLabel,
    this.onChanged,
    this.tristate = false,
    this.isError = false,
    this.style,
  });

  /// Mark face, ink and outline before the checkbox theme.
  final NeumorphicStyle? style;

  /// The checked state; null is mixed when tristate is enabled.
  final bool? value;

  /// The text identifying this item or control.
  final String semanticLabel;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool?>? onChanged;

  /// Whether activation cycles through the mixed state.
  final bool tristate;

  /// Whether to display the validation-error treatment.
  final bool isError;
  bool? get _next => !tristate
      ? !(value ?? false)
      : value == false
      ? true
      : value == true
      ? null
      : false;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final mark = t.shapes.corner(6);
    // Laid out at its target (TapTargetPadding), the mark on the start keyline unless its slot says otherwise: the
    // press, the one spoken node and the box are one, so the words or key beside it never take a press a screen reader
    // says is the mark's. Handed a column's whole width, it stands at the start.
    final place = NeumorphicFacePlace.of(context);
    return NeumorphicOwnRoot(
      child: TapTargetPadding(
        minSize: NeumorphicChromeMetrics.targetOf(context),
        alignment: place,
        child: NeumorphicTap(
          focusNode: focusNode,
          autofocus: autofocus,
          style: style,
          themeStyle: t.checkboxTheme,
          shape: mark.fit(const Size.square(28)),
          checked: value == true,
          mixed: value == null,

          semanticLabel: semanticLabel,
          button: false,
          round: false,
          focusInset:
              (NeumorphicChromeMetrics.targetOf(context).width - 28) / 2,
          // The box is a socket: keyboard focus deepens it, as it does a field's well, and nothing rises round it.
          showFocus: false,
          faceAlignment: place,
          onPressed: onChanged == null ? null : () => onChanged!(_next),
          child: SizedBox.fromSize(
            size: NeumorphicChromeMetrics.targetOf(context),
            child: Align(
              alignment: place,
              child: _CheckMark(
                value: value,
                enabled: onChanged != null,
                error: isError,
                style: style,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<bool>('value', value, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ObjectFlagProperty<ValueChanged<bool?>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<bool>('tristate', tristate, defaultValue: false),
      )
      ..add(DiagnosticsProperty<bool>('isError', isError, defaultValue: false))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
      );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({
    required this.value,
    required this.enabled,
    this.error = false,
    this.style,
  });
  final bool? value;
  final bool enabled, error;
  final NeumorphicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final states = {
      ...NeumorphicStatesScope.of(context),
      if (value != false) WidgetState.selected,
      if (!enabled) WidgetState.disabled,
      if (error) WidgetState.error,
    };
    final look = neumorphicStyleOf([style, t.checkboxTheme], states);
    final diameter = math.max(
      28.0,
      math.max(look.minimumSize?.width ?? 0, look.minimumSize?.height ?? 0),
    );
    var shape = look.shape ?? t.shapes.corner(6);
    if (shape is NeumorphicBorder) shape = shape.fit(Size.square(diameter));
    // Selection shows by fill, as the switch's does: a checked well takes the pigment and its tick the pigment's ink,
    // unless the widget's style or the checkbox theme sets a fill of its own (those win, in that order). A box in error
    // still shows its value: its well stays bare and its edge and tick take the ink; the message goes under it.
    final pigmented = value != false && !error && look.fill == null;
    final needsEdge = look.edge == null && look.side == null;
    // An empty box prints no rim: it reads by its moulding alone, as every part does (high contrast prints its edge).
    final filled = pigmented
        ? NeumorphicStyle(fill: WidgetStatePropertyAll(t.colors.pigment))
        : error && needsEdge
        ? NeumorphicStyle(edge: WidgetStatePropertyAll(t.colors.ink))
        : null;
    return NeumorphicOutOfUse(
      off: !enabled,
      child: SizedBox.square(
        dimension: diameter,
        child: NeumorphicSurface(
          style: style?.merge(filled) ?? filled,
          themeStyle: t.checkboxTheme,
          shape: shape,
          states: states,
          cast: NeumorphicSurfaceLevel.groove,
          round: false,
          outlined: true,
          boundary: true,
          padding: EdgeInsets.zero,
          child: Center(
            child: AnimatedSwitcher(
              duration: NeumorphicMotion.of(context).state,
              child: value == false
                  ? null
                  : Icon(
                      value == null
                          ? NeumorphicGlyphs.minus
                          : NeumorphicGlyphs.check,
                      key: ValueKey((value, error)),
                      size: look.iconSize ?? 16,
                      color:
                          look.foreground ??
                          (pigmented ? t.colors.onPigment : t.colors.ink),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A check and its words as one target and one spoken control.
///
/// ```dart
/// NeumorphicCheckRow(label: 'Remember this', value: remember, onChanged: change)
/// ```
class NeumorphicCheckRow extends StatelessWidget {
  /// Creates a [NeumorphicCheckRow].
  const NeumorphicCheckRow({
    super.key,
    this.autofocus = false,
    required this.label,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.tristate = false,
    this.focusNode,
    this.isError = false,
    this.style,
  });

  /// Checkbox mark and row words before the checkbox theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// Supporting text displayed with the primary content.
  final String? subtitle;

  /// The checked state; null is mixed when tristate is enabled.
  final bool? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool?>? onChanged;

  /// Whether activation cycles through the mixed state.
  final bool tristate;

  /// Marks an invalid value independently of its checked state.
  final bool isError;

  /// The row's keyboard focus.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // In a grouped list the row is a band of its card, a breath inside its rim, as a list tile is: its focus lift goes
    // round that band and not round its words and its control. Elsewhere the row has no face to rise: its box's socket
    // deepens, as a lone checkbox's does.
    final cell = NeumorphicGroupRowScope.cellOf(context);
    return NeumorphicTap(
      autofocus: autofocus,
      style: style,
      themeStyle: t.checkboxTheme,
      checked: value == true,
      mixed: value == null,
      focusNode: focusNode,
      // A row that holds a control passes its press to the control: the row stays flat and the control moves.
      pressRelief: false,
      shape: cell?.border,
      faceOutset: cell?.outset ?? EdgeInsets.zero,
      focusReach: cell == null ? 1 : .5,
      showFocus: cell != null,

      button: false,
      semanticLabel: [label, ?subtitle].join(', '),
      onPressed: onChanged == null
          ? null
          : () => onChanged!(
              !tristate
                  ? !(value ?? false)
                  : value == false
                  ? true
                  : value == true
                  ? null
                  : false,
            ),
      child: Builder(
        builder: (context) {
          final look = neumorphicStyleOf(
            [style, t.checkboxTheme],
            {
              ...NeumorphicStatesScope.of(context),
              if (value != false) WidgetState.selected,
              if (onChanged == null) WidgetState.disabled,
              if (isError) WidgetState.error,
            },
          );
          // 10 of air above and below at the standard density, 2 less a step denser, so the row stands at the medium
          // line (NeumorphicChromeMetrics.lineOf) beside the buttons and fields of its density.
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: math.max(0, 10 + t.density.heightDelta / 2),
            ),
            child: Row(
              children: [
                _CheckMark(
                  value: value,
                  enabled: onChanged != null,
                  error: isError,
                  style: style,
                ),
                const SizedBox(width: 12),
                Expanded(
                  // A disabled row's words fade with its mark.
                  child: NeumorphicOutOfUse(
                    off: onChanged == null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: t.textTheme.body
                              .merge(look.textStyle)
                              .copyWith(color: look.foreground),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: t.textTheme.caption
                                .merge(look.textStyle)
                                .copyWith(color: look.foreground),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('label', label))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<bool?>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<bool>('tristate', tristate, defaultValue: false),
      )
      ..add(DiagnosticsProperty<bool>('isError', isError, defaultValue: false))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
      );
  }
}

/// One radio choice; the group holds the selected value. [trailingText] is a figure at the end of the label's line: a
/// delivery's or a plan's price. [suffix] follows the words right beside them: a palette's swatches.
///
/// ```dart
/// NeumorphicRadio('next', 'Next day', note: 'Tomorrow by 18:00', trailingText: '£6.00')
/// ```
@immutable
class NeumorphicRadio<T> {
  /// Creates a [NeumorphicRadio].
  const NeumorphicRadio(
    this.value,
    this.label, {
    this.note,
    this.trailingText,
    this.suffix,
    this.enabled = true,
  });

  /// The stable value represented by this option.
  final T value;

  /// The text identifying this item or control.
  final String label;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// A figure at the end of the label's line, on its baseline: a price. A long label wraps before it moves the figure.
  final String? trailingText;

  /// What follows the words, right beside them at any width, as an input's suffix follows its text: a palette's
  /// swatches, so they read as that palette's colours. It is drawn, not read: the [label] names the choice.
  final Widget? suffix;

  /// Whether the control accepts user interaction.
  final bool enabled;
  @override
  bool operator ==(Object other) =>
      other is NeumorphicRadio<T> &&
      other.value == value &&
      other.label == label &&
      other.note == note &&
      other.trailingText == trailingText &&
      other.suffix == suffix &&
      other.enabled == enabled;
  @override
  int get hashCode =>
      Object.hash(value, label, note, trailingText, suffix, enabled);
}

/// A single radio choice with roving arrow-key focus and one Tab stop.
///
/// ```dart
/// NeumorphicRadioGroup<String>(semanticLabel: 'Time', options: const [NeumorphicRadio('day', 'Day'), NeumorphicRadio('night', 'Night')], value: time, onChanged: choose)
/// ```
class NeumorphicRadioGroup<T> extends StatelessWidget {
  /// Creates a [NeumorphicRadioGroup].
  const NeumorphicRadioGroup({
    super.key,
    required this.semanticLabel,
    required this.options,
    this.value,
    this.onChanged,
    this.style,
  });

  /// Mark face and group words before the radio theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String semanticLabel;

  /// The mutually exclusive options, in display order.
  final List<NeumorphicRadio<T>> options;

  /// The selected option value, or null for no selection.
  final T? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) {
    assert(
      options.map((o) => o.value).toSet().length == options.length,
      'Radio values must be distinct.',
    );
    final takesChoice = onChanged != null;
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      // Flutter's radio group: one Tab stop, on the chosen option or else the first one that can be chosen, and arrows
      // that choose as they move, wrapping and passing over options out of use. ui_core's keyboard fix inside it keeps
      // the Tab stop when the chosen option is out of use, and swaps Left and Right in right-to-left text.
      child: RadioGroup<T>(
        groupValue: value,
        // RadioGroup takes no null: a group that takes no choice is given a change that does nothing, and each option
        // is turned off.
        onChanged: (next) {
          if (next != null && next != value) onChanged?.call(next);
        },
        child: RadioGroupKeyboardFix<T>(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                _NeumorphicRadioOption<T>(
                  key: ObjectKey(option.value),
                  option: option,
                  chosen: option.value == value,
                  enabled: option.enabled && takesChoice,
                  style: style,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IterableProperty<NeumorphicRadio<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged));
  }
}

/// One option of a [NeumorphicRadioGroup]: Flutter's [RawRadio] on the group's registry, which takes the focus, the tap
/// and the keys and says the option is checked and one of a group, drawing the look's row: a socket whose dot carries
/// the choice, the words beside it.
class _NeumorphicRadioOption<T> extends StatefulWidget {
  const _NeumorphicRadioOption({
    super.key,
    required this.option,
    required this.chosen,
    required this.enabled,
    this.style,
  });

  final NeumorphicRadio<T> option;

  /// Whether the group's value is this option's.
  final bool chosen;

  /// Whether the option can be chosen: its own [NeumorphicRadio.enabled], in a group that takes a choice.
  final bool enabled;

  final NeumorphicStyle? style;

  @override
  State<_NeumorphicRadioOption<T>> createState() =>
      _NeumorphicRadioOptionState<T>();
}

class _NeumorphicRadioOptionState<T> extends State<_NeumorphicRadioOption<T>> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final o = widget.option;
    final style = widget.style;
    // One node for the option: RawRadio's (checked, one of a group, its focus and its tap), with its words.
    return MergeSemantics(
      child: RawRadio<T>(
        value: o.value,
        mouseCursor: WidgetStateMouseCursor.clickable,
        toggleable: false,
        focusNode: _focusNode,
        autofocus: false,
        groupRegistry: RadioGroup.maybeOf<T>(context),
        enabled: widget.enabled,
        builder: (context, radio) {
          final selected = radio.value ?? widget.chosen;
          return Semantics(
            label: [
              o.label,
              if (o.trailingText != null) o.trailingText!,
              if (o.note != null) o.note!,
            ].join(', '),
            child: ExcludeSemantics(
              // All of it takes a press, its gaps too, as RawRadio's
              // detector finds only what the face paints.
              child: Listener(
                behavior: HitTestBehavior.opaque,
                child: NeumorphicTapFace(
                  // RawRadio's hover, focus and out of use, and pressed while a press is down on it. The row draws the
                  // choice itself, in the socket's dot.
                  states: {
                    for (final state in radio.states)
                      if (state != WidgetState.selected) state,
                    if (radio.downPosition != null) WidgetState.pressed,
                  },
                  style: style,
                  themeStyle: t.radioTheme,
                  // A row that holds a control passes its press to the control: the row stays flat and the control
                  // moves.
                  pressRelief: false,
                  // The row has no face to rise: keyboard focus deepens the option's socket, as it does a field's well.
                  showFocus: false,
                  child: Builder(
                    builder: (context) {
                      final states = {
                        ...NeumorphicStatesScope.of(context),
                        if (selected) WidgetState.selected,
                        if (!widget.enabled) WidgetState.disabled,
                      };
                      final look = neumorphicStyleOf([
                        style,
                        t.radioTheme,
                      ], states);
                      final diameter = math.max(
                        24.0,
                        math.max(
                          look.minimumSize?.width ?? 0,
                          look.minimumSize?.height ?? 0,
                        ),
                      );
                      var shape = look.shape ?? t.shapes.circle();
                      if (shape is NeumorphicBorder) {
                        shape = shape.fit(Size.square(diameter));
                      }
                      final words = t.textTheme.body
                          .merge(look.textStyle)
                          .copyWith(color: look.foreground);
                      return NeumorphicOutOfUse(
                        off: !widget.enabled,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              SizedBox.square(
                                dimension: diameter,
                                child: NeumorphicSurface(
                                  style: style,
                                  themeStyle: t.radioTheme,
                                  shape: shape,
                                  states: states,
                                  // Always a socket, as the checkbox is always a well: the dot carries the choice. A
                                  // raised disc cast its light past its own edge (3:1 a pixel left of the column in dark,
                                  // ~3 px of glow), so the column read as the shadow's, not the disc's.
                                  cast: NeumorphicSurfaceLevel.groove,
                                  round: true,
                                  outlined: true,
                                  boundary: true,
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: NeumorphicMotion.of(context)
                                          .state,
                                      width: selected ? 10 : 0,
                                      height: selected ? 10 : 0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            look.foreground ?? t.colors.pigment,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Words keep to their own width before a suffix, so it stands right beside them.
                              if (o.suffix == null)
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (o.trailingText == null)
                                        Text(o.label, style: words)
                                      else
                                        // The figure on the label's baseline; the label wraps before it moves the figure.
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                o.label,
                                                style: words,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              o.trailingText!,
                                              style: words.tabular,
                                            ),
                                          ],
                                        ),
                                      if (o.note != null)
                                        Text(
                                          o.note!,
                                          style: t.textTheme.caption
                                              .merge(look.textStyle)
                                              .copyWith(color: look.foreground),
                                        ),
                                    ],
                                  ),
                                )
                              else ...[
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (o.trailingText == null)
                                        Text(o.label, style: words)
                                      else
                                        // The figure on the label's baseline; the label wraps before it moves the figure.
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                o.label,
                                                style: words,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              o.trailingText!,
                                              style: words.tabular,
                                            ),
                                          ],
                                        ),
                                      if (o.note != null)
                                        Text(
                                          o.note!,
                                          style: t.textTheme.caption
                                              .merge(look.textStyle)
                                              .copyWith(color: look.foreground),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                o.suffix!,
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One segment's value and label.
@immutable
class NeumorphicButtonSegment<T> {
  /// Creates a [NeumorphicButtonSegment].
  const NeumorphicButtonSegment(
    this.value,
    this.label, {
    this.icon,
    this.semanticLabel,
    this.enabled = true,
  });

  /// The stable value represented by this segment.
  final T value;

  /// The text identifying this item or control.
  final String label;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// Spoken words when the visible abbreviation needs expansion.
  final String? semanticLabel;

  /// Whether the control accepts user interaction.
  final bool enabled;
  @override
  bool operator ==(Object other) =>
      other is NeumorphicButtonSegment<T> &&
      other.value == value &&
      other.label == label &&
      other.icon == icon &&
      other.semanticLabel == semanticLabel &&
      other.enabled == enabled;
  @override
  int get hashCode => Object.hash(value, label, icon, semanticLabel, enabled);
}

/// Whether two inks differ enough to tell a state by colour alone: more than a tenth of the range, summed over the
/// channels.
bool _toldApart(Color a, Color b) =>
    (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs() > .1;

/// The contrast ratio of [a] against [b].
double _ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

/// Whether a chosen segment's tint can't tell it from the wall: the pigment is a grey (no hue between its channels), or
/// its lit ink is the ink's own colour. The choice would rest on the well's depth alone, which by night on a grey wall
/// stands under 3:1.
bool _greyChoice(NeumorphicColors c) {
  final p = c.pigment;
  final hue =
      math.max(p.r, math.max(p.g, p.b)) - math.min(p.r, math.min(p.g, p.b));
  return hue < .04 || !_toldApart(c.pigmentInkLit, c.ink);
}

/// A bank of segments choosing one value, with a roving keyboard path. The bank is one raised part split by
/// full-height engraved seams into equal cells; the chosen segment is its whole cell pressed in, flush to the bank's
/// rim and the seams, under one even tint of the pigment. Its outer corners are the bank's own, concentric, and its
/// inner corners are square. The bank is as tall as a field; when its cells can't share a row, up to four stand one
/// to a row, and more wrap into even rows.
///
/// ```dart
/// NeumorphicSegmentedButton<String>(semanticLabel: 'Period', segments: const [NeumorphicButtonSegment('day', 'Day'), NeumorphicButtonSegment('week', 'Week')], value: period, onChanged: choose)
/// ```
class NeumorphicSegmentedButton<T> extends StatelessWidget {
  /// Creates a [NeumorphicSegmentedButton].
  const NeumorphicSegmentedButton({
    super.key,
    required this.semanticLabel,
    required this.segments,
    this.value,
    this.onChanged,
    this.style,
  });

  /// Segment faces and words before the segmented-button theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String semanticLabel;

  /// The mutually exclusive segments, in display order.
  final List<NeumorphicButtonSegment<T>> segments;

  /// The selected segment value, or null for no selection.
  final T? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final dir = Directionality.of(context);
    final bankLook = neumorphicStyleOf([
      style,
      t.segmentedButtonTheme,
    ], const {});
    final pad =
        bankLook.padding(dir) ??
        t.density.padding(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        );
    // One weight in both states: a chosen label never reflows or moves.
    TextStyle words(bool selected) => t.textTheme.body
        .copyWith(fontWeight: FontWeight.w600)
        .merge(bankLook.textStyle);
    final scaler = MediaQuery.textScalerOf(context);
    // A cell is no narrower than the medium line ([NeumorphicChromeMetrics.lineOf]): square at its least.
    var least = NeumorphicChromeMetrics.lineOf(context);
    for (final o in segments) {
      least = math.max(
        least,
        neumorphicWidestWord(o.label, words(true), textScaler: scaler) +
            pad.horizontal +
            (o.icon == null ? 0 : (bankLook.iconSize ?? 18) + 8),
      );
    }
    final selectedIndex = segments.indexWhere((o) => o.value == value);
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: Semantics(
        container: true,
        label: semanticLabel,
        explicitChildNodes: true,
        child: _ChoiceSet(
          selectedIndex: selectedIndex,
          enabled: [for (final o in segments) o.enabled && onChanged != null],
          onChanged: (i) => onChanged?.call(segments[i].value),
          layout: (children) => NeumorphicCellBank(
            selected: selectedIndex,
            minCellWidth: least,
            side: bankLook.side,
            edge: bankLook.edge,
            // In a row with no bound the bank takes the kit's 104 a choice, its total whatever the labels; cells
            // whose widest word won't fit that wrap to a second row rather than squeeze it.
            naturalWidth: segments.length * 104.0,
            contentHeight: (cellWidth) {
              var tallest = 0.0;
              for (final o in segments) {
                final painter =
                    TextPainter(
                      text: TextSpan(text: o.label, style: words(true)),
                      textDirection: dir,
                      textScaler: scaler,
                    )..layout(
                      maxWidth: math.max(
                        0,
                        cellWidth -
                            pad.horizontal -
                            (o.icon == null
                                ? 0
                                : (bankLook.iconSize ?? 18) + 8),
                      ),
                    );
                tallest = math.max(tallest, painter.height);
                painter.dispose();
              }
              return tallest + pad.vertical;
            },
            children: children,
          ),
          item: (i, node, key) {
            final o = segments[i];
            final selected = o.value == value;
            final enabled = o.enabled && onChanged != null;
            return Builder(
              builder: (context) {
                final cell = NeumorphicCellScope.of(context);
                return NeumorphicTap(
                  style: style,
                  themeStyle: t.segmentedButtonTheme,
                  shape: cell.border,
                  focusReach: .5,
                  // The chosen cell is already in; a press on another shows it going in.
                  pressRelief: !selected,
                  focusNode: node,
                  onKeyEvent: (_, e) => key(e),
                  semanticLabel: o.semanticLabel ?? o.label,
                  selected: selected,
                  onPressed: enabled ? () => onChanged!(o.value) : null,
                  child: NeumorphicCellFace(
                    child: Builder(
                      builder: (context) {
                        final states = {
                          ...NeumorphicStatesScope.of(context),
                          if (selected) WidgetState.selected,
                          if (!enabled) WidgetState.disabled,
                        };
                        final look = neumorphicStyleOf([
                          style,
                          t.segmentedButtonTheme,
                        ], states);
                        final fill = look.fill;
                        Widget face = NeumorphicOutOfUse(
                          off: !enabled,
                          child: Padding(
                            padding: pad,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (o.icon != null) ...[
                                    Icon(
                                      o.icon,
                                      size: look.iconSize ?? 18,
                                      // On the selected wash a glyph takes the pigment's ink for words over a
                                      // wash, as the label's accent would: the raw pigment would fall to 4.33:1.
                                      color:
                                          look.foreground ??
                                          (selected
                                              ? t.colors.pigmentInkLit
                                              : t.colors.ink),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: neumorphicLabel(
                                      Text(
                                        o.label,
                                        textAlign: TextAlign.center,
                                        style: words(selected)
                                            .merge(look.textStyle)
                                            .copyWith(
                                              color: look.foreground,
                                              // A grey pigment (a grey on a grey) underlines the chosen words in
                                              // whichever of the two inks stands at 3:1 on the wall, so the
                                              // choice never rests on the well alone.
                                              decoration:
                                                  selected &&
                                                      _greyChoice(t.colors)
                                                  ? TextDecoration.underline
                                                  : null,
                                              decorationColor:
                                                  _ratio(
                                                        t.colors.pigmentInkLit,
                                                        t.colors.ground,
                                                      ) >=
                                                      3
                                                  ? t.colors.pigmentInkLit
                                                  : t.colors.ink,
                                              decorationThickness: 2,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        if (fill != null) {
                          // A style's own fill for the state, in the cell's exact outline.
                          face = DecoratedBox(
                            decoration: ShapeDecoration(
                              color: fill,
                              shape: cell.border,
                            ),
                            child: face,
                          );
                        }
                        return face;
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IterableProperty<NeumorphicButtonSegment<T>>('segments', segments))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged));
  }
}

typedef _ChoiceItem = Widget Function(
  int index,
  FocusNode node,
  KeyEventResult Function(KeyEvent) key,
);

class _ChoiceSet extends StatefulWidget {
  const _ChoiceSet({
    required this.selectedIndex,
    required this.enabled,
    required this.onChanged,
    required this.item,
    required this.layout,
  });
  final int selectedIndex;
  final List<bool> enabled;
  final ValueChanged<int> onChanged;
  final _ChoiceItem item;
  final Widget Function(List<Widget>) layout;
  @override
  State<_ChoiceSet> createState() => _ChoiceSetState();
}

class _ChoiceSetState extends State<_ChoiceSet> {
  final _nodes = <FocusNode>[];
  void _resize() {
    while (_nodes.length > widget.enabled.length) {
      _nodes.removeLast().dispose();
    }
    while (_nodes.length < widget.enabled.length) {
      _nodes.add(FocusNode());
    }
  }

  @override
  void initState() {
    super.initState();
    _resize();
  }

  @override
  void didUpdateWidget(_ChoiceSet old) {
    super.didUpdateWidget(old);
    _resize();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final enabled = [
      for (var i = 0; i < widget.enabled.length; i++)
        if (widget.enabled[i]) i,
    ];
    if (enabled.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward =
        key == LogicalKeyboardKey.arrowDown ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight);
    final back =
        key == LogicalKeyboardKey.arrowUp ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft);
    int? target;
    if (forward || back) {
      target =
          enabled[(enabled.indexOf(index) +
                  (forward ? 1 : -1) +
                  enabled.length) %
              enabled.length];
    }
    if (key == LogicalKeyboardKey.home) target = enabled.first;
    if (key == LogicalKeyboardKey.end) target = enabled.last;
    if (target == null) return KeyEventResult.ignored;
    _nodes[target].requestFocus();
    widget.onChanged(target);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        widget.selectedIndex >= 0 && widget.enabled[widget.selectedIndex]
        ? widget.selectedIndex
        : widget.enabled.indexWhere((e) => e);
    return widget.layout([
      for (var i = 0; i < widget.enabled.length; i++)
        Builder(
          builder: (context) {
            _nodes[i].skipTraversal = i != selected;
            return widget.item(i, _nodes[i], (event) => _key(i, event));
          },
        ),
    ]);
  }
}

/// A score out of [count] stars, on ui_core's [RawRating]. With [onChanged] it is one control, one tab stop: a tap
/// or a drag across the stars sets the score, hovering shows the score a tap would give, Right and Left (mirrored right
/// to left) step it, Home clears it, End and a digit set it, and a screen reader hears a slider. The stars up to the
/// score stand raised in the pigment; the rest are engraved outlines, and the star at the score wears the focus.
/// Without [onChanged] the rating only shows, and a fraction fills part of a star. [enabled] false keeps a rating
/// where it is, faded and still.
///
/// ```dart
/// NeumorphicRating(semanticLabel: 'Your rating', value: 4, onChanged: (stars) => setState(() => rating = stars))
/// ```
class NeumorphicRating extends StatelessWidget {
  /// Creates a [NeumorphicRating].
  const NeumorphicRating({
    super.key,
    required this.semanticLabel,
    required this.value,
    this.count = 5,
    this.onChanged,
    this.enabled = true,
    this.size = 24,
  }) : assert(count > 0),
       assert(value >= 0 && value <= count),
       assert(size >= 12);

  /// The accessible name of the score.
  final String semanticLabel;

  /// The score, from 0 to [count]; a fraction fills part of a star when it only shows.
  final double value;

  /// How many stars make the scale.
  final int count;

  /// Reports the stars chosen, from 0 (Home clears the score) to [count]. Null shows the score only.
  final ValueChanged<int>? onChanged;

  /// Whether a rating with [onChanged] takes a choice now. False keeps its size and lays it flat: a form that is
  /// sending, say. A rating that only shows has no disabled state.
  final bool enabled;

  /// Each star's size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    Widget star(double fill) => SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _StarPainter(
          fill,
          t.colors,
          neumorphicRuleWidth,
          t.elevation,
          NeumorphicFlatScope.of(context),
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
    String say(double score) => words.ratingOf(score, count);
    // As wide as its stars wherever it stands: ui_core's rating takes a tap or a hover anywhere in its box (past the
    // last star, all of them), and a stretching column would make its box the column's width.
    Widget own(Widget rating) => Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: rating,
    );
    if (onChanged == null) {
      return own(
        RawRating(
          value: value,
          onChanged: null,
          readOnly: true,
          itemCount: count,
          semanticLabel: semanticLabel,
          semanticFormatterCallback: say,
          layoutBuilder: (context, items) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) SizedBox(width: size / 6),
                item,
              ],
            ],
          ),
          itemBuilder: (context, item) => star(item.fill),
        ),
      );
    }
    final chosen = value.round();
    final target = math.max(
      size + 16,
      NeumorphicChromeMetrics.targetOf(context).width,
    );
    final place = NeumorphicFacePlace.of(context);
    // The star at the score (the first while there is none) wears a drag's press, as a slider's thumb would. The
    // rating's focus raises the whole row of stars ([_RatingRise]): the rating is one stop, and the stars filled say
    // the score the keys move.
    final wearer = math.max(chosen - 1, 0);
    return own(
      NeumorphicOutOfUse(
        off: !enabled,
        // Each star stands at its target, the targets edge to edge, so a press anywhere on the row is one star's; its
        // face stands at the target's start (NeumorphicFacePlace), so the first star's face is on the row's edge.
        child: _RatingRise(
          count: count,
          target: target,
          size: size,
          place: place,
          builder: (lit) => RawRating(
            value: chosen.toDouble(),
            onChanged: enabled ? (score) => onChanged!(score.round()) : null,
            itemCount: count,
            semanticLabel: semanticLabel,
            semanticFormatterCallback: say,
            itemBuilder: (context, item) => _StarTarget(
              item: item,
              wearer: wearer,
              lit: lit,
              builder: (context, states) => NeumorphicTapFace(
                states: states,
                shape: t.shapes.circle(),
                round: true,
                // A press sinks a disc 6 round the star wherever the star stands in its target.
                focusInset: (target - size) / 2,
                faceOutset: const EdgeInsets.all(6),
                faceAlignment: place,
                child: SizedBox.square(
                  dimension: target,
                  child: Align(
                    alignment: place,
                    child: star(item.fill >= 1 ? 1 : 0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(DoubleProperty('value', value))
      ..add(IntProperty('count', count, defaultValue: 5))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true))
      ..add(DoubleProperty('size', size, defaultValue: 24));
  }
}

/// One star's target in a [NeumorphicRating]: the face's states for it. The star at the score ([wearer]) wears the
/// rating's focus and a drag's press; a finger or a button held down on a star sinks that star, as each star's own
/// press did before the rating moved onto [RawRating] (which reports a press only once it drags).
class _StarTarget extends StatefulWidget {
  const _StarTarget({
    required this.item,
    required this.wearer,
    required this.lit,
    required this.builder,
  });

  final RawRatingItemDetails item;
  final int wearer;

  /// Whether the rating shows its focus, for [_RatingRise] to raise the row.
  final ValueNotifier<bool> lit;
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  @override
  State<_StarTarget> createState() => _StarTargetState();
}

class _StarTargetState extends State<_StarTarget> {
  bool _down = false;

  void _press(bool down) {
    if (down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final rating = widget.item.states;
    final disabled = rating.contains(WidgetState.disabled);
    final wears = widget.item.index == widget.wearer;
    final dragged = rating.contains(WidgetState.pressed);
    // Every star hears the rating's states; the row rises while it shows its focus.
    widget.lit.value = rating.contains(WidgetState.focused);
    return Listener(
      // The whole target, not only the star's paint: a press anywhere on it is this star's.
      behavior: HitTestBehavior.opaque,
      onPointerDown: disabled ? null : (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: widget.builder(context, {
        if (dragged ? wears : _down && !disabled) WidgetState.pressed,
        if (disabled) WidgetState.disabled,
      }),
    );
  }
}

/// A rating's keyboard focus: its row of stars rises off the wall as one part ([neumorphicPaintFocusLift] round a
/// capsule 6 past the stars' faces), as a raised part rises. The stars stay as they are.
class _RatingRise extends StatefulWidget {
  const _RatingRise({
    required this.count,
    required this.target,
    required this.size,
    required this.place,
    required this.builder,
  });

  final int count;
  final double target, size;
  final AlignmentGeometry place;
  final Widget Function(ValueNotifier<bool> lit) builder;

  @override
  State<_RatingRise> createState() => _RatingRiseState();
}

class _RatingRiseState extends State<_RatingRise> {
  final _lit = ValueNotifier(false);

  @override
  void dispose() {
    _lit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return CustomPaint(
      foregroundPainter: _RatingRisePainter(
        _lit,
        t.colors,
        t.elevation,
        t.shapes.capsule,
        widget.count,
        widget.target,
        widget.size,
        widget.place.resolve(Directionality.of(context)),
      ),
      child: widget.builder(_lit),
    );
  }
}

class _RatingRisePainter extends CustomPainter {
  _RatingRisePainter(
    this.lit,
    this.c,
    this.elevation,
    this.border,
    this.count,
    this.target,
    this.size,
    this.place,
  ) : super(repaint: lit);
  final ValueNotifier<bool> lit;
  final NeumorphicColors c;
  final NeumorphicElevation elevation;

  /// The row's outline, the look's capsule.
  final OutlinedBorder border;
  final int count;
  final double target, size;
  final Alignment place;

  @override
  void paint(Canvas canvas, Size box) {
    if (!lit.value || count < 1) return;
    final first = Rect.fromLTWH(
      (target - size) * (place.x + 1) / 2,
      (box.height - size) * (place.y + 1) / 2,
      size,
      size,
    );
    final row = first
        .expandToInclude(first.shift(Offset(target * (count - 1), 0)))
        .inflate(6);
    neumorphicPaintFocusLift(
      canvas,
      border.getOuterPath(row),
      c,
      elevation: elevation,
    );
  }

  @override
  bool shouldRepaint(_RatingRisePainter o) =>
      o.lit != lit ||
      o.c != c ||
      o.elevation != elevation ||
      o.border != border ||
      o.count != count ||
      o.target != target ||
      o.size != size ||
      o.place != place;
}

/// A star in relief: given, it stands raised and lit in the pigment; not given, it is pressed into the wall. Flat (a
/// washed-out screen, a rating out of use) the given star keeps the pigment and the rest keep a quiet outline.
class _StarPainter extends CustomPainter {
  const _StarPainter(
    this.fill,
    this.colors,
    this.rule,
    this.elevation,
    this.flat, {
    this.rtl = false,
  });

  /// Whether the stars run right to left: a part-given star fills from its start, the right.
  final bool rtl;
  final double fill, rule;
  final NeumorphicColors colors;
  final NeumorphicElevation elevation;
  final bool flat;
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2, centre = size.center(Offset.zero);
    // Plump points: a pressed or raised star reads at 24 px only if its arms have some width.
    final points = [
      for (var i = 0; i < 10; i++)
        centre +
            Offset(
                  math.cos(-math.pi / 2 + i * math.pi / 5),
                  math.sin(-math.pi / 2 + i * math.pi / 5),
                ) *
                (i.isEven ? r : r * .5),
    ];
    // Moulded, not cut: each point and each inner corner is rounded off (no sharp corner in a moulded surface), the
    // curve starting a fifth of the way along each arm.
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final before = points[(i + 9) % 10], at = points[i];
      final after = points[(i + 1) % 10];
      final into = Offset.lerp(at, before, .2)!;
      final out = Offset.lerp(at, after, .2)!;
      i == 0 ? star.moveTo(into.dx, into.dy) : star.lineTo(into.dx, into.dy);
      star.quadraticBezierTo(at.dx, at.dy, out.dx, out.dy);
    }
    star.close();
    final box = Offset.zero & size;
    final d = (size.shortestSide / 24).clamp(.5, 1.5);
    // An empty star's floor is the quiet ink, the look's 3:1 mark with no words, by day and by night: in the well's
    // own colour by day its shadow alone would show it, and five stars read as four.
    final floor = colors.quiet;
    if (fill < 1) {
      neumorphicPaintPressed(
        canvas,
        star,
        colors,
        light: (const Offset(-1, -1) * d, 2 * d),
        dark: (const Offset(1.2, 1.2) * d, 2.4 * d),
        face: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [floor, floor],
        ).createShader(box),
        flat: flat,
        elevation: elevation,
      );
      if (flat) {
        canvas.drawPath(
          star,
          Paint()
            ..color = colors.quiet
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.5, rule)
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    if (fill > 0) {
      canvas.save();
      if (fill < 1) {
        // A part-given star: only its given part stands up.
        canvas.clipRect(
          Rect.fromLTWH(
            rtl ? size.width * (1 - fill) : 0,
            -8,
            size.width * fill,
            size.height + 16,
          ),
        );
      }
      neumorphicPaintRaised(
        canvas,
        star,
        colors,
        light: (const Offset(-1.2, -1.2) * d, 2.4 * d),
        dark: (const Offset(1.4, 1.4) * d, 3 * d),
        lightColor: Color.lerp(colors.highlight, colors.pigmentHi, .35),
        face: LinearGradient(
          begin: colors.light,
          end: -colors.light,
          colors: [colors.pigmentHi, colors.pigment, colors.pigmentDk],
          stops: const [0, .55, 1],
        ).createShader(box),
        flat: flat,
        elevation: elevation,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.fill != fill ||
      old.colors != colors ||
      old.rule != rule ||
      old.elevation != elevation ||
      old.flat != flat ||
      old.rtl != rtl;
}

/// Where files are dropped or chosen: a pressed well with an upload mark, a title and a hint, and a button that
/// opens the chooser. The host listens for drags (a drop package on the web and desktop) and sets [active] while
/// files are held over it; the well then lifts its rim and says to let go. Chosen files list under it as chips
/// that [onRemove] takes away.
///
/// ```dart
/// NeumorphicFileUpload(hint: 'PDF or image, up to 10 MB', onPressed: pick, files: names, onRemove: remove)
/// ```
class NeumorphicFileUpload extends StatelessWidget {
  /// Creates a [NeumorphicFileUpload].
  const NeumorphicFileUpload({
    super.key,
    this.title,
    this.hint,
    this.buttonLabel,
    this.onPressed,
    this.active = false,
    this.files = const [],
    this.onRemove,
  });

  /// The well's title; null says 'Drop files here'.
  final String? title;

  /// What the well takes: kinds and sizes.
  final String? hint;

  /// The chooser button's words; null says 'Choose files'.
  final String? buttonLabel;

  /// Opens the file chooser. Null disables the button.
  final VoidCallback? onPressed;

  /// Whether files are being held over the well.
  final bool active;

  /// The names of the files chosen so far.
  final List<String> files;

  /// Removes the file at an index from [files].
  final ValueChanged<int>? onRemove;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    final heading = active ? words.releaseToAdd : (title ?? words.dropFiles);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: heading,
          hint: hint,
          explicitChildNodes: true,
          child: NeumorphicSurface(
            cast: active
                ? NeumorphicSurfaceLevel.part
                : NeumorphicSurfaceLevel.groove,
            radius: NeumorphicRadii.well,
            outlined: active,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: NeumorphicIconWell(
                    NeumorphicGlyphs.upload,
                    live: active,
                  ),
                ),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: Text(
                    heading,
                    style: t.textTheme.title,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  ExcludeSemantics(
                    child: Text(
                      hint!,
                      style: t.textTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                NeumorphicButton(
                  buttonLabel ?? words.chooseFiles,
                  icon: NeumorphicGlyphs.upload,
                  alignment: Alignment.center,
                  onPressed: onPressed,
                ),
              ],
            ),
          ),
        ),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, name) in files.indexed)
                NeumorphicChip(
                  name,
                  onDeleted: onRemove == null ? null : () => onRemove!(i),
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('buttonLabel', buttonLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(DiagnosticsProperty<bool>('active', active, defaultValue: false))
      ..add(
        IterableProperty<String>(
          'files',
          files,
          defaultValue: const <String>[],
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onRemove', onRemove));
  }
}
