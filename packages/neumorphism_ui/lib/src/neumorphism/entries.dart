// Typed choices and text entry, using the look's moulded parts and inset shadows.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'chrome_metrics.dart';
import 'controls.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'shapes.dart';
import 'internal/reach.dart';
import 'internal/cell_bank.dart';
import 'internal/error_line.dart';
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

/// A search groove with its own clear action, keeping focus when cleared.
///
/// ```dart
/// NeumorphicSearchField(hint: 'Search the shelf', onChanged: filter)
/// ```
class NeumorphicSearchField extends StatefulWidget {
  /// Creates a [NeumorphicSearchField].
  const NeumorphicSearchField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.clearLabel,
    this.onEditingComplete,
    this.decorate,
    this.error,
    this.failureLine,
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

  /// A form's editable semantics; excludes the placeholder from naming.
  final Widget Function(Widget editable)? decorate;

  /// Placeholder text shown when the input is empty.
  final String hint;

  /// An error message displayed beneath the input.
  final String? error;

  /// Optionally wraps the error line before it is displayed.
  final Widget Function(Widget line)? failureLine;

  /// Formatters applied to user edits in order.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill purposes supplied to the platform text input.
  final Iterable<String>? autofillHints;

  /// The keyboard layout requested from the platform.
  final TextInputType? keyboardType;

  /// The text identifying this item or control.
  final String? label;

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
  Widget build(BuildContext context) => NeumorphicTextField(
    style: widget.style,
    controller: _text,
    focusNode: _node,
    autofocus: widget.autofocus,
    enabled: widget.enabled,
    hint: widget.hint,
    label: widget.label,
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    onEditingComplete: widget.onEditingComplete,
    decorate: widget.decorate,
    error: widget.error,
    failureLine: widget.failureLine,
    inputFormatters: widget.inputFormatters,
    autofillHints: widget.autofillHints,
    keyboardType: widget.keyboardType,
    nameOnly: true,
    textInputAction: TextInputAction.search,
    leading: const Icon(NeumorphicGlyphs.search, size: 20),
    trailing: _text.text.isEmpty
        ? null
        // The key's 48 target overhangs its 32 face without growing the field past the control height.
        : SizedBox(
            width: 48,
            height: 32,
            child: OverflowBox(
              maxWidth: 48,
              maxHeight: 48,
              child: NeumorphicRoundButton(
                NeumorphicGlyphs.close,
                size: 32,
                label:
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
          ),
  );
}

/// A multiline field with a steady label and the same selection menu as a field.
///
/// ```dart
/// NeumorphicTextArea(label: 'Notes', onChanged: saveDraft)
/// ```
class NeumorphicTextArea extends StatelessWidget {
  /// Creates a [NeumorphicTextArea].
  const NeumorphicTextArea({
    super.key,
    this.autofocus = false,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.lines = 4,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.maxLength,
    this.style,
  });

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  /// An optional externally owned text controller.
  final TextEditingController? controller;

  /// The initial text when no controller is supplied.
  final String? initialValue;

  /// The text identifying this item or control.
  final String? label;

  /// Placeholder text shown when the input is empty.
  final String? hint;

  /// Supporting text beneath the input.
  final String? helper;

  /// An error message displayed beneath the input.
  final String? error;

  /// The initial number of visible text lines.
  final int lines;

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
    label: label,
    hint: hint,
    helper: helper,
    error: error,
    lines: lines,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    focusNode: focusNode,
    enabled: enabled,
    maxLength: maxLength,
    keyboardType: TextInputType.multiline,
  );
}

/// One text input behind a row of code cells, supporting paste and one-time-code autofill.
///
/// ```dart
/// NeumorphicInputOtp(label: 'Verification code', length: 6, onCompleted: verify)
/// ```
class NeumorphicInputOtp extends StatefulWidget {
  /// Creates a [NeumorphicInputOtp].
  const NeumorphicInputOtp({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.label,
    this.helper,
    this.error,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.onEditingComplete,
    this.textInputAction = TextInputAction.done,
    this.keyboardType = TextInputType.number,
    this.inputFormatters = const [],
    this.autofillHints = const [AutofillHints.oneTimeCode],
    this.decorate,
    this.failureLine,
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
  final String? label;

  /// Supporting text beneath the input.
  final String? helper;

  /// An error message displayed beneath the input.
  final String? error;

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

  /// Wraps only the editable when a form owns its spoken name and hints.
  final Widget Function(Widget editable)? decorate;

  /// Wraps the drawn failure when a form owns its announcement.
  final Widget Function(Widget failure)? failureLine;

  /// Whether the characters are hidden (a PIN): a filled cell shows a dot.
  final bool obscure;

  @override
  State<NeumorphicInputOtp> createState() => _NeumorphicCodeFieldState();
}

class _NeumorphicCodeFieldState extends State<NeumorphicInputOtp> {
  // The code lives in the caller's controller when there is one: ui_core's
  // field reads and writes it, filters it, and leaves it the caller's.
  late DesignOtpController _code = _make();

  DesignOtpController _make() =>
      DesignOtpController(length: widget.length, text: widget.controller);

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
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (widget.error != null) WidgetState.error,
    };
    final baseStyle = NeumorphicStyleOf([
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
        // A cell is its widest figure and 8 each side: taken as a whole em, at twice the text six cells wanted 56 each
        // and the code broke into two rows of three, read as two codes.
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
          math.max(48.0, baseStyle.minimumSize?.height ?? 0),
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
    Widget cell(BuildContext context, DesignOtpSlot slot) {
      // The next cell to fill deepens while the code has focus, and the caret's place is that cell; a filled cell of a
      // hidden code shows a dot.
      final lit = slot.active && slot.focused;
      final cellStates = {...states, if (lit) WidgetState.focused};
      final look = NeumorphicStyleOf([
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

    final field = DesignOtpField(
      controller: _code,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      isError: widget.error != null,
      obscureText: widget.obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      // A form that owns the spoken name (decorate) names it; else the label.
      semanticLabel: widget.decorate == null
          ? widget.label ?? NeumorphicLocalizations.of(context).verificationCode
          : null,
      contextMenuBuilder: (context, anchors, items) =>
          NeumorphicTextContextMenu(anchors: anchors, buttonItems: items),
      layoutBuilder: cells,
      slotBuilder: cell,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          ExcludeSemantics(
            child: Text(
              widget.label!,
              style: t.textTheme.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
        ],
        NeumorphicOutOfUse(
          off: !widget.enabled,
          // The decorator's name and failure land on the code's one node, not on the page around it.
          child: widget.decorate == null
              ? field
              : MergeSemantics(child: widget.decorate!(field)),
        ),
        if (widget.error != null || widget.helper != null) ...[
          const SizedBox(height: 8),
          if (widget.error != null)
            (widget.failureLine ?? (child) => child)(
              NeumorphicErrorLine(
                live: widget.failureLine == null,
                child: Text(widget.error!),
              ),
            )
          else
            ExcludeSemantics(
              excluding: widget.decorate != null,
              child: Text(widget.helper!, style: t.textTheme.caption),
            ),
        ],
      ],
    );
  }
}

/// A typed choice with the look's menu and keyboard navigation.
///
/// ```dart
/// NeumorphicSelect<String>(label: 'Space', options: const [NeumorphicMenuItem('quiet', 'Quiet room')], value: space, onChanged: choose)
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
    this.label,
    this.prompt,
    this.helper,
    this.error,
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
  final String? label;

  /// Text shown before an option has been selected.
  final String? prompt;

  /// Supporting text beneath the input.
  final String? helper;

  /// An error message displayed beneath the input.
  final String? error;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  State<NeumorphicSelect<T>> createState() => _NeumorphicSelectState<T>();
}

class _NeumorphicSelectState<T> extends State<NeumorphicSelect<T>> {
  bool _open = false;
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
      label: widget.label,
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
        widget.prompt ??
        NeumorphicLocalizations.of(context).choose;
    final face = _face(t, value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      // Start, not stretch: in a row of a toolbar (no width to stretch to) the face takes its own width.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          ExcludeSemantics(
            child: Text(
              widget.label!,
              style: t.textTheme.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // From a medium window up the face is as wide as its widest option, at most a control's most; the open list
        // matches it, so it hugs the options too.
        LayoutBuilder(
          builder: (context, box) {
            final look = NeumorphicStyleOf([
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
              widget.prompt ?? NeumorphicLocalizations.of(context).choose,
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
            final width = box.hasBoundedWidth
                ? neumorphicControlWidth(
                    context,
                    box.maxWidth,
                    math.min(own, neumorphicWideControlMax),
                  )
                : math.min(own, neumorphicWideControlMax);
            if (!box.hasBoundedWidth) {
              return SizedBox(width: width, child: face);
            }
            return Align(
              alignment: AlignmentDirectional.centerStart,
              heightFactor: 1,
              child: SizedBox(width: width, child: face),
            );
          },
        ),
        if (widget.error != null || widget.helper != null) ...[
          const SizedBox(height: 8),
          if (widget.error != null)
            NeumorphicErrorLine(child: Text(widget.error!))
          else
            Text(widget.helper!, style: t.textTheme.caption),
        ],
      ],
    );
  }

  Widget _face(NeumorphicThemeData t, String value) => NeumorphicTap(
    focusNode: widget.focusNode,
    autofocus: widget.autofocus,
    key: _faceKey,
    style: widget.style,
    themeStyle: t.textFieldTheme,
    expanded: _open,
    label: [if (widget.label != null) widget.label!, value].join(', '),
    onPressed: widget.onChanged == null ? null : _show,
    child: Builder(
      builder: (context) {
        final states = {
          ...NeumorphicStatesScope.of(context),
          if (widget.error != null) WidgetState.error,
        };
        final look = NeumorphicStyleOf([
          widget.style,
          t.textFieldTheme,
        ], states);
        return NeumorphicOutOfUse(
          // Disabled reads as the other fields do.
          off: widget.onChanged == null,
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
        );
      },
    ),
  );
}

/// A rounded-square inset checkbox; null is mixed. Tristate adds mixed to the press cycle.
///
/// ```dart
/// NeumorphicCheckbox(value: agreed, label: 'Agree', onChanged: change)
/// ```
class NeumorphicCheckbox extends StatelessWidget {
  /// Creates a [NeumorphicCheckbox].
  const NeumorphicCheckbox({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.value,
    required this.label,
    this.onChanged,
    this.tristate = false,
    this.error = false,
    this.style,
  });

  /// Mark face, ink and outline before the checkbox theme.
  final NeumorphicStyle? style;

  /// The checked state; null is mixed when tristate is enabled.
  final bool? value;

  /// The text identifying this item or control.
  final String label;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool?>? onChanged;

  /// Whether activation cycles through the mixed state.
  final bool tristate;

  /// Whether to display the validation-error treatment.
  final bool error;
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
    // The mark's edge is the box's: its target's margins reach past it, hit-tested, never laid out. The root keeps the
    // checkbox's one spoken node, the whole 48 target, and the mark at its start when a column hands it its width.
    return NeumorphicEdgeTarget(
      slop: 10,
      child: NeumorphicFaceEdge(
        slop: 10,
        child: NeumorphicTap(
          focusNode: focusNode,
          autofocus: autofocus,
          style: style,
          themeStyle: t.checkboxTheme,
          shape: mark.fit(const Size.square(28)),
          checked: value == true,
          mixed: value == null,

          label: label,
          button: false,
          round: false,
          focusInset: 10,
          onPressed: onChanged == null ? null : () => onChanged!(_next),
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: _CheckMark(
                value: value,
                enabled: onChanged != null,
                error: error,
                style: style,
              ),
            ),
          ),
        ),
      ),
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
    final look = NeumorphicStyleOf([style, t.checkboxTheme], states);
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
    final inked = error && look.edge == null && look.side == null;
    final filled = pigmented
        ? NeumorphicStyle(fill: WidgetStatePropertyAll(t.colors.pigment))
        : inked
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
          // The empty light well has no mark to protect. Let its existing
          // inset shadow extend inward instead of clipping it to a thin edge.
          padding: value == false && !t.colors.dark
              ? const EdgeInsets.all(3)
              : EdgeInsets.zero,
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
    this.note,
    required this.value,
    this.onChanged,
    this.tristate = false,
    this.focusNode,
    this.error = false,
    this.style,
  });

  /// Checkbox mark and row words before the checkbox theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// The checked state; null is mixed when tristate is enabled.
  final bool? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool?>? onChanged;

  /// Whether activation cycles through the mixed state.
  final bool tristate;

  /// Marks an invalid value independently of its checked state.
  final bool error;

  /// The row's keyboard focus.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicTap(
      autofocus: autofocus,
      style: style,
      themeStyle: t.checkboxTheme,
      checked: value == true,
      mixed: value == null,
      focusNode: focusNode,
      // A row that holds a control passes its press to the control: the row stays flat and the control moves.
      pressRelief: false,

      button: false,
      label: [label, ?note].join(', '),
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
          final look = NeumorphicStyleOf(
            [style, t.checkboxTheme],
            {
              ...NeumorphicStatesScope.of(context),
              if (value != false) WidgetState.selected,
              if (onChanged == null) WidgetState.disabled,
              if (error) WidgetState.error,
            },
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                _CheckMark(
                  value: value,
                  enabled: onChanged != null,
                  error: error,
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
                        if (note != null)
                          Text(
                            note!,
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
}

/// One radio choice; the group holds the selected value. [trailingText] is a figure at the end of the label's line: a
/// delivery's or a plan's price.
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

  /// Whether the control accepts user interaction.
  final bool enabled;
  @override
  bool operator ==(Object other) =>
      other is NeumorphicRadio<T> &&
      other.value == value &&
      other.label == label &&
      other.note == note &&
      other.trailingText == trailingText &&
      other.enabled == enabled;
  @override
  int get hashCode => Object.hash(value, label, note, trailingText, enabled);
}

/// A single radio choice with roving arrow-key focus and one Tab stop.
///
/// ```dart
/// NeumorphicRadioGroup<String>(label: 'Time', options: const [NeumorphicRadio('day', 'Day'), NeumorphicRadio('night', 'Night')], value: time, onChanged: choose)
/// ```
class NeumorphicRadioGroup<T> extends StatelessWidget {
  /// Creates a [NeumorphicRadioGroup].
  const NeumorphicRadioGroup({
    super.key,
    required this.label,
    required this.options,
    this.value,
    this.onChanged,
    this.style,
  });

  /// Mark face and group words before the radio theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// The mutually exclusive options, in display order.
  final List<NeumorphicRadio<T>> options;

  /// The selected option value, or null for no selection.
  final T? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: _ChoiceSet(
        selectedIndex: options.indexWhere((o) => o.value == value),
        enabled: [for (final o in options) o.enabled && onChanged != null],
        onChanged: (i) => onChanged?.call(options[i].value),
        layout: (children) =>
            Column(mainAxisSize: MainAxisSize.min, children: children),
        item: (i, node, key) {
          final o = options[i];
          final selected = o.value == value;
          return NeumorphicTap(
            style: style,
            themeStyle: t.radioTheme,
            checked: selected,
            inMutuallyExclusiveGroup: true,
            // A row that holds a control passes its press to the control: the row stays flat and the control moves.
            pressRelief: false,

            button: false,
            focusNode: node,
            onKeyEvent: (_, e) => key(e),
            label: [
              o.label,
              if (o.trailingText != null) o.trailingText!,
              if (o.note != null) o.note!,
            ].join(', '),
            onPressed: !o.enabled || onChanged == null
                ? null
                : () => onChanged!(o.value),
            child: Builder(
              builder: (context) {
                final states = {
                  ...NeumorphicStatesScope.of(context),
                  if (selected) WidgetState.selected,
                  if (!o.enabled || onChanged == null) WidgetState.disabled,
                };
                final look = NeumorphicStyleOf([style, t.radioTheme], states);
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
                  off: !(o.enabled && onChanged != null),
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
                                duration: NeumorphicMotion.of(context).state,
                                width: selected ? 10 : 0,
                                height: selected ? 10 : 0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: look.foreground ?? t.colors.pigment,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      child: Text(o.label, style: words),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(o.trailingText!, style: words.tabular),
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
                      ],
                    ),
                  ),
                );
              },
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
/// stands under 3:1 (design_review_test, custom grey dark).
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
/// NeumorphicSegmentedButton<String>(label: 'Period', segments: const [NeumorphicButtonSegment('day', 'Day'), NeumorphicButtonSegment('week', 'Week')], value: period, onChanged: choose)
/// ```
class NeumorphicSegmentedButton<T> extends StatelessWidget {
  /// Creates a [NeumorphicSegmentedButton].
  const NeumorphicSegmentedButton({
    super.key,
    required this.label,
    required this.segments,
    this.value,
    this.onChanged,
    this.style,
  });

  /// Segment faces and words before the segmented-button theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

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
    final bankLook = NeumorphicStyleOf([
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
    var least = 48.0;
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
        label: label,
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
                  label: o.semanticLabel ?? o.label,
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
                        final look = NeumorphicStyleOf([
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
                                      // wash, as the label's accent would: the raw pigment fell to 4.33:1.
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

/// A score out of [count] stars. With [onChanged], each star is a target that sets the score to its place and the
/// stars up to the score fill in ink; without it, the rating only shows, and a fraction fills part of a star. The
/// empty stars are engraved outlines. [enabled] false keeps a rating's targets where they are, faded and still.
///
/// ```dart
/// NeumorphicRating(label: 'Your rating', value: 4, onChanged: (stars) => setState(() => rating = stars))
/// ```
class NeumorphicRating extends StatelessWidget {
  /// Creates a [NeumorphicRating].
  const NeumorphicRating({
    super.key,
    required this.label,
    required this.value,
    this.count = 5,
    this.onChanged,
    this.enabled = true,
    this.size = 24,
  }) : assert(count > 0),
       assert(value >= 0 && value <= count),
       assert(size >= 12);

  /// The accessible name of the score.
  final String label;

  /// The score, from 0 to [count]; a fraction fills part of a star when it only shows.
  final double value;

  /// How many stars make the scale.
  final int count;

  /// Reports the stars chosen, from 1 to [count]. Null shows the score only.
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
    if (onChanged == null) {
      return Semantics(
        container: true,
        label: label,
        value: words.ratingOf(value, count),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) SizedBox(width: size / 6),
                star((value - i).clamp(0.0, 1.0)),
              ],
            ],
          ),
        ),
      );
    }
    final chosen = value.round();
    final target = math.max(size + 16, NeumorphicChromeMetrics.targetSize);
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: NeumorphicOutOfUse(
        off: !enabled,
        // The first star's edge is the row's, the last's its end: the targets' outer margins are hit-tested only.
        child: NeumorphicFaceEdge(
          slop: (target - size) / 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++)
                NeumorphicTap(
                  round: true,
                  shape: t.shapes.circle(),
                  label: '$label, ${words.ratingOf(i + 1, count)}',
                  selected: i + 1 == chosen,
                  inMutuallyExclusiveGroup: true,
                  focusSize: Size.square(size + 12),
                  onPressed: enabled ? () => onChanged!(i + 1) : null,
                  child: SizedBox.square(
                    dimension: target,
                    child: Center(child: star(i < chosen ? 1 : 0)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
    // Moulded, not cut: each point and each inner corner is rounded off (no sharp corner in the plaster), the curve
    // starting a fifth of the way along each arm.
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
    // own colour by day its shadow alone showed it, and five stars read as four.
    final floor = colors.quiet;
    if (fill < 1) {
      neumorphicPaintPressed(
        canvas,
        star,
        colors,
        light: (Offset(-1, -1) * d, 2 * d),
        dark: (Offset(1.2, 1.2) * d, 2.4 * d),
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
        light: (Offset(-1.2, -1.2) * d, 2.4 * d),
        dark: (Offset(1.4, 1.4) * d, 3 * d),
        lightColor: Color.lerp(colors.highlight, colors.pigmentHi, .35),
        face: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
}
