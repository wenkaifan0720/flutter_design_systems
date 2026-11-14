import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'behavior.dart';
import 'component_themes.dart';
import 'controls.dart';
import 'editing.dart';
import 'glyphs.dart';
import 'internal/face.dart';
import 'localizations.dart';
import 'layout.dart';
import 'pixels.dart';
import 'press.dart';
import 'raised.dart';
import 'theme.dart';
import 'shapes.dart';
import 'internal/caps.dart';

Widget _labelled(
  BuildContext context,
  Widget child, {
  String? label,
  String? helper,
  String? error,
}) {
  if (label == null && helper == null && error == null) return child;
  final t = RetroDesktopTheme.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (label != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: t.type.body),
        ),
      child,
      if (error != null || helper != null)
        Semantics(
          liveRegion: error != null,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: retroDesktopFieldNote(
              t,
              error ?? helper!,
              error: error != null,
            ),
          ),
        ),
    ],
  );
}

/// A search editor whose clear action preserves the editor's focus.
///
/// ```dart
/// RetroDesktopSearchField(hint: 'Search documents', onChanged: (_) {})
/// ```
class RetroDesktopSearchField extends StatefulWidget {
  /// Creates a [RetroDesktopSearchField].
  const RetroDesktopSearchField({
    super.key,
    this.style,
    required this.hint,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.clearLabel,
    this.name,
    this.autofocus = false,
    this.decorate,
    this.onEditingComplete,
    this.error,
    this.helper,
    this.failureLine,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction = TextInputAction.search,
    this.enabled = true,
  });

  /// Placeholder text shown while the input has no value.
  final String hint;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// An optional externally owned controller; the caller disposes it.
  final TextEditingController? controller;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the entered text.
  final ValueChanged<String>? onSubmitted;

  /// Overrides the accessible label of the search clear action.
  final String? clearLabel;

  /// The name identifying this item.
  final String? name;

  /// The validation error, when the value needs attention.
  final String? error;

  /// Supporting text shown below the input.
  final String? helper;

  /// Wraps the validation message, for example to add a live region.
  final Widget Function(Widget error)? failureLine;

  /// Input transformations applied before a value is accepted.
  final List<TextInputFormatter>? inputFormatters;

  /// The platform keyboard requested for this input.
  final TextInputType? keyboardType;

  /// The action offered by the platform keyboard.
  final TextInputAction textInputAction;

  /// Whether this input requests focus when first mounted.
  final bool autofocus;

  /// Decorates only the editable, keeping trailing actions separate.
  final Widget Function(Widget editable)? decorate;

  /// Called when the platform completes the editing operation.
  final VoidCallback? onEditingComplete;

  /// Whether the part accepts user interaction.
  final bool enabled;
  @override
  State<RetroDesktopSearchField> createState() => _SearchState();
}

class _SearchState extends State<RetroDesktopSearchField> {
  TextEditingController? _own;
  FocusNode? _ownFocus;
  TextEditingController get _text =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  void _changed() => setState(() {});
  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
  }

  @override
  void didUpdateWidget(RetroDesktopSearchField old) {
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
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RetroDesktopTextField(
    style: widget.style,
    hint: widget.hint,
    nameOnly: true,
    autofocus: widget.autofocus,
    decorate:
        widget.decorate ??
        (editable) =>
            Semantics(label: widget.name ?? widget.hint, child: editable),
    onEditingComplete: widget.onEditingComplete,
    enabled: widget.enabled,
    controller: _text,
    focusNode: _focus,
    leading: const Icon(RetroDesktopGlyphs.search),
    textInputAction: widget.textInputAction,
    keyboardType: widget.keyboardType,
    inputFormatters: widget.inputFormatters,
    error: widget.error,
    helper: widget.helper,
    failureLine: widget.failureLine,
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    trailing: _text.text.isEmpty
        ? null
        : retroDesktopFieldButton(
            context,
            icon: RetroDesktopGlyphs.close,
            label:
                widget.clearLabel ??
                DesignLocalizations.of(context).clearButtonTooltip,
            onPressed: !widget.enabled
                ? null
                : () {
                    _text.clear();
                    widget.onChanged?.call('');
                    _focus.requestFocus();
                  },
          ),
  );
}

/// A one-time code in a row of sunken paper boxes, one character each: typing
/// fills them in turn, Backspace empties the last, a paste or the platform's
/// code autofill fills them all. One real input runs underneath (ui_core's
/// code field), so autofill and a screen reader treat it as one field; the box
/// the next character goes in carries the appearance's focus mark.
///
/// ```dart
/// RetroDesktopInputOtp(label: 'Verification code', length: 6, onCompleted: (_) {})
/// ```
class RetroDesktopInputOtp extends StatefulWidget {
  /// Creates a [RetroDesktopInputOtp].
  const RetroDesktopInputOtp({
    super.key,
    this.style,
    required this.label,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.helper,
    this.error,
    this.enabled = true,
    this.autofocus = false,
    this.obscure = false,
    this.textInputAction = TextInputAction.done,
    this.onCompleted,
    this.onEditingComplete,
    this.inputFormatters = const [],
    this.autofillHints = const [AutofillHints.oneTimeCode],
    this.decorate,
    this.failureLine,
  }) : assert(length > 0);

  /// The visible or accessible name of this part.
  final String label;

  /// Run before the code's own filter and length (upper-casing letters, say).
  final List<TextInputFormatter> inputFormatters;

  /// What autofill may offer; a one-time code by default.
  final Iterable<String> autofillHints;

  /// The number of code characters accepted.
  final int length;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// An optional externally owned controller, which holds the code; the
  /// caller disposes it.
  final TextEditingController? controller;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Reports the code as it changes, partial codes included.
  final ValueChanged<String>? onChanged;

  /// Called with the code when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Supporting text shown below the input.
  final String? helper;

  /// The validation error, when the value needs attention.
  final String? error;

  /// Whether the part accepts user interaction.
  final bool enabled;

  /// Whether this input requests focus when first mounted.
  final bool autofocus;

  /// Whether the characters show as dots (a PIN).
  final bool obscure;

  /// The action offered by the platform keyboard.
  final TextInputAction textInputAction;

  /// Called with the code each time it becomes whole.
  final ValueChanged<String>? onCompleted;

  /// Called when the keyboard's action key is pressed, in place of letting go
  /// of the focus.
  final VoidCallback? onEditingComplete;

  /// Wraps the boxes and their input, for integrations that attach editing
  /// behaviour and name the input themselves.
  final Widget Function(Widget editable)? decorate;

  /// Wraps the validation message, for example to add a live region.
  final Widget Function(Widget error)? failureLine;

  @override
  State<RetroDesktopInputOtp> createState() => _InputOtpState();
}

class _InputOtpState extends State<RetroDesktopInputOtp> {
  late DesignOtpController _otp = _make();

  // The code lives in the caller's controller when there is one.
  DesignOtpController _make() =>
      DesignOtpController(length: widget.length, text: widget.controller);

  @override
  void didUpdateWidget(RetroDesktopInputOtp old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller || old.length != widget.length) {
      final was = _otp;
      _otp = _make();
      WidgetsBinding.instance.addPostFrameCallback((_) => was.dispose());
    }
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final error = widget.error, helper = widget.helper;
    final enabled = widget.enabled;
    final digit = t.type.text(16, 20);
    final line = MediaQuery.textScalerOf(context).scale(16) * 1.25;
    // A box is a one-line field's height: drawn 30 tall and reaching the
    // pointer's least on a phone.
    final tall = math.max(line + 12, RetroDesktopReach.least(context));
    final gap = t.chisel ? 4.0 : 6.0;
    final component = t.textFieldTheme.merge(
      RetroDesktopStyle(fill: WidgetStatePropertyAll(c.paper)),
    );
    Widget field = DesignOtpField(
      length: widget.length,
      controller: _otp,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: enabled,
      isError: error != null,
      obscureText: widget.obscure,
      semanticLabel: widget.decorate != null ? null : widget.label,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      contextMenuBuilder: (menu, anchors, items) =>
          RetroDesktopTextContextMenu.forField(
            menu,
            context,
            anchors: anchors,
            buttonItems: items,
          ),
      layoutBuilder: (context, slots) => LayoutBuilder(
        builder: (context, box) {
          // Boxes 36 wide at most; in a column too narrow for that, as wide as
          // fits, so the row never runs past its edge.
          final n = slots.length;
          final room = box.hasBoundedWidth
              ? box.maxWidth
              : 36.0 * n + gap * (n - 1);
          final width = math.max(
            0.0,
            math.min(36.0, (room - gap * (n - 1)) / n),
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, slot) in slots.indexed) ...[
                if (i > 0) SizedBox(width: gap),
                SizedBox(width: width, height: tall, child: slot),
              ],
            ],
          );
        },
      ),
      slotBuilder: (context, s) {
        final here = s.focused && s.active;
        final box = retroDesktopFace(
          states: {
            if (!s.enabled) WidgetState.disabled,
            if (s.isError) WidgetState.error,
            if (here) WidgetState.focused,
          },
          component: component,
          style: widget.style,
          sunken: true,
          padding: EdgeInsets.zero,
          child: Center(
            child: s.filled
                ? Text(
                    s.obscured ? '•' : s.character,
                    style: digit.copyWith(
                      color: s.enabled ? c.text : c.textTertiary,
                    ),
                  )
                : here
                ? SizedBox(
                    width: 1,
                    height: line * .8,
                    child: ColoredBox(color: c.text),
                  )
                : null,
          ),
        );
        return RetroDesktopHighlight(
          shape: t.shapes.small,
          focused: here,
          child: box,
        );
      },
    );
    if (widget.decorate != null) field = widget.decorate!(field);
    Widget? message;
    if (error != null || helper != null) {
      final drawn = retroDesktopFieldNote(
        t,
        error ?? helper!,
        error: error != null,
      );
      message = error != null
          ? widget.failureLine?.call(drawn) ??
                Semantics(liveRegion: true, child: drawn)
          : ExcludeSemantics(child: drawn);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ExcludeSemantics(
            child: Text(widget.label, style: t.type.body),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MouseRegion(
            cursor: enabled ? SystemMouseCursors.text : MouseCursor.defer,
            child: Opacity(opacity: enabled ? 1 : .5, child: field),
          ),
        ),
        if (message != null)
          Padding(padding: const EdgeInsets.only(top: 6), child: message),
      ],
    );
  }
}

/// A value and its presentation in a select menu.
@immutable
class RetroDesktopOption<T> {
  /// Creates a [RetroDesktopOption].
  const RetroDesktopOption(
    this.value,
    this.label, {
    this.icon,
    this.enabled = true,
  });

  /// The current value to display or edit.
  final T value;

  /// The visible or accessible name of this part.
  final String label;

  /// The glyph shown with the content.
  final IconData? icon;

  /// Whether the part accepts user interaction.
  final bool enabled;
}

/// A controlled value picker with a real keyboard menu.
///
/// ```dart
/// RetroDesktopSelect(label: 'Sort by', value: 'name', options: const [RetroDesktopOption('name', 'Name'), RetroDesktopOption('date', 'Date')], onChanged: (_) {})
/// ```
class RetroDesktopSelect<T> extends StatefulWidget {
  /// Creates a [RetroDesktopSelect].
  const RetroDesktopSelect({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.prompt,
    this.helper,
    this.error,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The selectable options in reading order.
  final List<RetroDesktopOption<T>> options;

  /// The current value to display or edit.
  final T? value;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<T>? onChanged;

  /// The visible or accessible name of this part.
  final String? label;

  /// The text displayed before a value is selected.
  final String? prompt;

  /// Supporting text shown below the input.
  final String? helper;

  /// The validation error, when the value needs attention.
  final String? error;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The focus node this part uses; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  @override
  State<RetroDesktopSelect<T>> createState() => _SelectState<T>();
}

class _SelectState<T> extends State<RetroDesktopSelect<T>> {
  bool _opening = false;
  Future<void> _show(BuildContext anchorContext) async {
    if (_opening) return;
    final box = anchorContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    _opening = true;
    try {
      final picked = await showRetroDesktopMenu<T>(
        anchorContext,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        matchWidth: true,
        label: widget.label,
        items: [
          for (final o in widget.options)
            RetroDesktopMenuItem(
              o.value,
              o.label,
              icon: o.icon,
              enabled: o.enabled,
              selected: o.value == widget.value,
            ),
        ],
      );
      if (mounted && picked != null) widget.onChanged?.call(picked);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final selected = widget.options
        .where((o) => o.value == widget.value)
        .firstOrNull;
    final shown =
        selected?.label ??
        widget.prompt ??
        RetroDesktopLocalizations.of(context).choose;
    // From 600 up a select doesn't stretch to its column: it is as wide as
    // its widest option, at most 320, at the column's start.
    final hug = MediaQuery.sizeOf(context).width >= 600;
    Widget choice({EdgeInsetsGeometry padding = EdgeInsets.zero}) =>
        _SelectChoice(
          options: widget.options,
          selected: selected,
          shown: shown,
          hug: hug,
          padding: padding,
        );
    final press = Builder(
      builder: (context) => RetroDesktopPressable(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        label: widget.label ?? shown,
        value: selected?.label,
        error: widget.error != null,
        onPressed:
            widget.onChanged == null || !widget.options.any((o) => o.enabled)
            ? null
            : () => _show(context),
        builder: (context, states) => t.chisel
            // The PC's: a sunken field holding the choice, with a bevelled
            // arrow button at its end. To the shared checks it is its box, as
            // a Chisel button is: its shade row on top sits barely off the
            // window's grey by night, and read from the pixels the face
            // started a row late.
            ? DesignKeylineFace(
                child: retroDesktopFace(
                  states: states,
                  sunken: true,
                  component: t.optionTheme.merge(
                    RetroDesktopStyle(
                      fill: WidgetStatePropertyAll(t.colors.paper),
                    ),
                  ),
                  style: widget.style,
                  // Its words start where a field's do (8 in).
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 2, 2, 2),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: hug ? MainAxisSize.min : MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        choice(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 18,
                          child: RetroDesktopPixelPaint(
                            painter: RetroDesktopArrowButtonPainter(
                              t.colors,
                              states.contains(WidgetState.pressed),
                              t.strokes.regular,
                              t.strokes.hairline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // The Mac's: a popup button, its double arrow at its end.
            : retroDesktopFace(
                states: states,
                scale: RetroDesktopFaceScale.button,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: states.contains(WidgetState.pressed)
                      ? [t.colors.platinum, t.colors.platinumDark]
                      : [t.colors.platinumLight, t.colors.platinum],
                ),
                component: t.optionTheme,
                style: widget.style,
                // Its words start where a field's do (8 in): stacked in one
                // column, a field and a popup read as one.
                padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 12, 8),
                child: Row(
                  mainAxisSize: hug ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    choice(),
                    const SizedBox(width: 8),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RetroDesktopTriangleMark(AxisDirection.up, size: 8),
                        RetroDesktopTriangleMark(AxisDirection.down, size: 8),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
    return _labelled(
      context,
      hug
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: press,
              ),
            )
          : press,
      label: widget.label,
      helper: widget.helper,
      error: widget.error,
    );
  }
}

/// The choice on a select's face, its glyph and words. Hugging, it is as wide
/// as the widest option (the face's own type), so choosing another doesn't
/// resize the face; otherwise it takes the face's room.
class _SelectChoice<T> extends StatelessWidget {
  const _SelectChoice({
    required this.options,
    required this.selected,
    required this.shown,
    required this.hug,
    required this.padding,
  });
  final List<RetroDesktopOption<T>> options;
  final RetroDesktopOption<T>? selected;
  final String shown;
  final bool hug;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          if (selected?.icon != null) ...[
            Icon(selected!.icon),
            const SizedBox(width: 8),
          ],
          Expanded(child: RetroDesktopCaps(Text(shown))),
        ],
      ),
    );
    if (!hug) return Expanded(child: row);
    return Flexible(
      child: Builder(
        builder: (context) {
          final style = DefaultTextStyle.of(context).style;
          final scaler = MediaQuery.textScalerOf(context);
          final glyph = (IconTheme.of(context).size ?? 24) + 8;
          double width(String words) {
            final p = TextPainter(
              text: TextSpan(text: words, style: style),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            final w = p.width;
            p.dispose();
            return w;
          }

          var widest = width(shown) + (selected?.icon != null ? glyph : 0);
          for (final o in options) {
            widest = math.max(
              widest,
              width(o.label) + (o.icon != null ? glyph : 0),
            );
          }
          return SizedBox(width: widest.ceilToDouble(), child: row);
        },
      ),
    );
  }
}

/// A switch's face: a sunken track, lit when on, and a raised grey lever at the end it stands for.
class _SwitchFace extends StatelessWidget {
  const _SwitchFace({required this.value, required this.states, this.style});
  final bool value;
  final Set<WidgetState> states;
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final leverInk = RetroDesktopStyle.first<Color>(
      [style, t.switchTheme],
      (s) => s.foreground,
      states,
    );
    final trackShape =
        RetroDesktopStyle.first<OutlinedBorder>(
          [style, t.switchTheme],
          (s) => s.shape,
          states,
        ) ??
        t.shapes.full;
    final leverShape = RetroDesktopShapes.inset(
      trackShape,
      t.strokes.regular + t.strokes.hairline + 2,
    );
    // Its own size, at the start, even when a stretching column hands it a
    // tight width: a switch never grows into a bar.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: 48,
        height: 28,
        child: retroDesktopFace(
          states: states,
          scale: RetroDesktopFaceScale.mark,
          sunken: true,
          component: t.switchTheme.merge(
            RetroDesktopStyle(
              fill: WidgetStatePropertyAll(
                value ? t.colors.highlight : t.colors.platinumDark,
              ),
            ),
          ),
          style: style,
          padding: const EdgeInsets.all(2),
          child: AnimatedAlign(
            duration: RetroDesktopMotion.of(context).state,
            curve: RetroDesktopMotion.of(context).standard,
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            // The lever is a small raised button in the track, concentric
            // with it: Platinum's grey face, Chisel's grey bevelled block.
            // Held, it shows the press its appearance's buttons show: Platinum's
            // face darkens, Chisel's bevel turns over.
            child: SizedBox(
              width: 18,
              height: 20,
              child: retroDesktopFace(
                states: {
                  if (states.contains(WidgetState.pressed)) WidgetState.pressed,
                },
                scale: RetroDesktopFaceScale.mark,
                component: RetroDesktopStyle(
                  shape: WidgetStatePropertyAll(leverShape),
                  fill: leverInk == null
                      ? null
                      : WidgetStatePropertyAll(leverInk),
                ),
                // A grey button's face in both states: only the track lights for on, so an off switch is never
                // tinted as a chosen thing is.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [t.colors.platinumLight, t.colors.platinum],
                ),
                padding: EdgeInsets.zero,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A desktop switch whose sliding lever is inset from its themed track.
///
/// ```dart
/// RetroDesktopSwitch(value: true, label: 'Notifications', onChanged: (_) {})
/// ```
class RetroDesktopSwitch extends StatelessWidget {
  /// Creates a [RetroDesktopSwitch].
  const RetroDesktopSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Whether the switch is on.
  final bool value;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<bool>? onChanged;

  /// The visible or accessible name of this part.
  final String? label;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this input requests focus when first mounted.
  final bool autofocus;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => RetroDesktopPressable(
    focusShape: RetroDesktopTheme.of(context).shapes.full,
    label: label,
    button: false,
    toggled: value,
    focusNode: focusNode,
    autofocus: autofocus,
    onPressed: onChanged == null ? null : () => onChanged!(!value),
    builder: (context, states) =>
        _SwitchFace(value: value, states: states, style: style),
  );
}

/// The entire setting row toggles; the lever adds no second semantics node.
///
/// ```dart
/// RetroDesktopSwitchRow(label: 'Notifications', value: true, note: 'Show desktop alerts', onChanged: (_) {})
/// ```
class RetroDesktopSwitchRow extends StatelessWidget {
  /// Creates a [RetroDesktopSwitchRow].
  const RetroDesktopSwitchRow({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// The visible or accessible name of this part.
  final String label;

  /// Supporting text shown with the main content.
  final String? note;

  /// Whether the switch is on.
  final bool value;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<bool>? onChanged;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => RetroDesktopPressable(
    label: label,
    focusNode: focusNode,
    autofocus: autofocus,
    hint: note,
    button: false,
    toggled: value,
    onPressed: onChanged == null ? null : () => onChanged!(!value),
    // No surface of its own: alone, its words start on its column's edge and
    // its lever ends on the far one, as a check row's do; among a list's rows
    // (a grouped settings list) it keeps the rows' 12 inset from the group.
    builder: (context, states) => Padding(
      padding: EdgeInsets.symmetric(
        horizontal: RetroDesktopRowPlace.maybeOf(context) == null ? 0 : 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: RetroDesktopTheme.of(context).type.body),
                if (note != null)
                  Text(note!, style: RetroDesktopTheme.of(context).type.meta),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _SwitchFace(value: value, states: states, style: style),
        ],
      ),
    ),
  );
}

/// One mutually exclusive option; [enabled] can disable an individual choice.
@immutable
class RetroDesktopRadio<T> {
  /// Creates a [RetroDesktopRadio].
  const RetroDesktopRadio(
    this.value,
    this.label, {
    this.note,
    this.enabled = true,
  });

  /// The current value to display or edit.
  final T value;

  /// The visible or accessible name of this part.
  final String label;

  /// Supporting text shown with the main content.
  final String? note;

  /// Whether the part accepts user interaction.
  final bool enabled;
}

/// A value-labelled segment in a single-selection segmented button.
@immutable
class RetroDesktopButtonSegment<T> {
  /// Creates a [RetroDesktopButtonSegment].
  const RetroDesktopButtonSegment(
    this.value,
    this.label, {
    this.icon,
    this.name,
    this.enabled = true,
  });

  /// The current value to display or edit.
  final T value;

  /// The visible or accessible name of this part.
  final String label;

  /// The name identifying this item.
  final String? name;

  /// The glyph shown with the content.
  final IconData? icon;

  /// Whether the part accepts user interaction.
  final bool enabled;
}

/// One tab stop for the group; arrow keys choose the next enabled radio.
///
/// ```dart
/// RetroDesktopRadioGroup(label: 'Appearance', value: 'day', options: const [RetroDesktopRadio('day', 'Day'), RetroDesktopRadio('night', 'Night')], onChanged: (_) {})
/// ```
class RetroDesktopRadioGroup<T> extends StatelessWidget {
  /// Creates a [RetroDesktopRadioGroup].
  const RetroDesktopRadioGroup({
    super.key,
    required this.label,
    required this.options,
    this.value,
    this.onChanged,
    this.error,
    this.style,
    this.showLabel = true,
    this.rowSegmentWidth = 120,
  });

  /// Whether the label stands visibly with it; without, the label is its name for a screen reader alone.
  final bool showLabel;

  /// Width reserved for each segment in a horizontal arrangement.
  final double rowSegmentWidth;

  /// The visible or accessible name of this part.
  final String label;

  /// The selectable options in reading order.
  final List<RetroDesktopRadio<T>> options;

  /// The current value to display or edit.
  final T? value;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<T>? onChanged;

  /// The validation error, when the value needs attention.
  final String? error;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => _labelled(
    context,
    Semantics(
      label: showLabel ? null : label,
      container: true,
      explicitChildNodes: true,
      child: _ChoiceGroup<T>(
        rowSegmentWidth: rowSegmentWidth,
        options: [
          for (final o in options)
            _Choice(o.value, o.label, note: o.note, enabled: o.enabled),
        ],
        value: value,
        onChanged: onChanged,
        radio: true,
        error: error != null,
        style: style,
      ),
    ),
    label: showLabel ? label : null,
    error: error,
  );
}

/// A row of the appearance's buttons sharing edges, the chosen one pressed in, with roving focus and one selected value.
///
/// ```dart
/// RetroDesktopSegmentedButton(label: 'View', value: 'list', segments: const [RetroDesktopButtonSegment('list', 'List'), RetroDesktopButtonSegment('grid', 'Grid')], onChanged: (_) {})
/// ```
class RetroDesktopSegmentedButton<T> extends StatelessWidget {
  /// Creates a [RetroDesktopSegmentedButton].
  const RetroDesktopSegmentedButton({
    super.key,
    required this.label,
    required this.segments,
    this.value,
    this.onChanged,
    this.style,
    this.showLabel = true,
    this.rowSegmentWidth = 120,
  });

  /// Whether the label stands visibly with it; without, the label is its name for a screen reader alone.
  final bool showLabel;

  /// Width reserved for each segment in a horizontal arrangement.
  final double rowSegmentWidth;

  /// The visible or accessible name of this part.
  final String label;

  /// The selectable segments in reading order.
  final List<RetroDesktopButtonSegment<T>> segments;

  /// The current value to display or edit.
  final T? value;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<T>? onChanged;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => _labelled(
    context,
    Semantics(
      label: showLabel ? null : label,
      container: true,
      explicitChildNodes: true,
      child: _ChoiceGroup<T>(
        rowSegmentWidth: rowSegmentWidth,
        options: [
          for (final o in segments)
            _Choice(
              o.value,
              o.label,
              icon: o.icon,
              enabled: o.enabled,
              name: o.name,
            ),
        ],
        value: value,
        onChanged: onChanged,
        style: style,
      ),
    ),
    label: showLabel ? label : null,
  );
}

class _Choice<T> {
  const _Choice(
    this.value,
    this.label, {
    this.note,
    this.name,
    this.icon,
    required this.enabled,
  });
  final T value;
  final String label;
  final String? note, name;
  final IconData? icon;
  final bool enabled;
}

class _ChoiceGroup<T> extends StatefulWidget {
  const _ChoiceGroup({
    required this.options,
    this.value,
    this.onChanged,
    this.radio = false,
    this.rowSegmentWidth = 120,
    this.error = false,
    this.style,
  });
  final List<_Choice<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final bool radio, error;
  final double rowSegmentWidth;
  final RetroDesktopStyle? style;
  @override
  State<_ChoiceGroup<T>> createState() => _ChoiceState<T>();
}

class _ChoiceState<T> extends State<_ChoiceGroup<T>> {
  final List<FocusNode> _nodes = [];
  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  KeyEventResult _keys(int index, KeyEvent event) {
    if (widget.onChanged == null ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final options = widget.options;
    final enabled = [
      for (var i = 0; i < options.length; i++)
        if (options[i].enabled) i,
    ];
    if (enabled.isEmpty) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    int? target;
    final by = key == LogicalKeyboardKey.arrowDown
        ? 1
        : key == LogicalKeyboardKey.arrowUp
        ? -1
        : key == LogicalKeyboardKey.arrowRight
        ? (rtl ? -1 : 1)
        : key == LogicalKeyboardKey.arrowLeft
        ? (rtl ? 1 : -1)
        : 0;
    if (key == LogicalKeyboardKey.home) {
      target = enabled.first;
    } else if (key == LogicalKeyboardKey.end) {
      target = enabled.last;
    } else if (by != 0) {
      target = enabled[(enabled.indexOf(index) + by) % enabled.length];
    }
    if (target == null) return KeyEventResult.ignored;
    _nodes[target].requestFocus();
    if (options[target].value != widget.value) {
      widget.onChanged!(options[target].value);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    while (_nodes.length < widget.options.length) {
      _nodes.add(FocusNode());
    }
    // Keep removed nodes alive until the old element has detached from them.
    final selected = widget.options.indexWhere(
      (o) => o.enabled && o.value == widget.value,
    );
    final entry = selected < 0
        ? widget.options.indexWhere((o) => o.enabled)
        : selected;
    final t = RetroDesktopTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Cells: a row of the appearance's buttons sharing edges, the chosen one
    // pressed in. Platinum frames them in one outlined button split by
    // full-height dividers; Chisel sets bevelled buttons side by side.
    final frameShape =
        RetroDesktopStyle.first<OutlinedBorder>(
          [widget.style, t.segmentedButtonTheme],
          (s) => s.shape,
          const {},
        ) ??
        t.shapes.button;
    final rim = t.chisel ? 0.0 : t.strokes.regular;
    final inner = rim == 0
        ? frameShape
        : RetroDesktopShapes.inset(frameShape, rim);
    final count = widget.options.length;
    // A row of segments shows a button's face height, as every control that
    // stands in a row with buttons does (Platinum's frame round its cells,
    // Chisel's cells whole buttons), in a reach of its own: one top and one
    // bottom beside a push button, a popup or an icon button.
    final faceHeight = retroDesktopButtonFaceHeight(context);
    final cellHeight = faceHeight - 2 * rim;
    final reachHeight = math.max(RetroDesktopReach.least(context), faceHeight);
    // Where each cell's press puts its band (the frame's height, its cell
    // inside the rim): the middle, on a whole pixel, as a button's face.
    final frameTop = ((reachHeight - faceHeight) / 2).roundToDouble();
    final cellTop = frameTop + rim;
    final parts = <Widget>[];
    for (var i = 0; i < count; i++) {
      final option = widget.options[i];
      final live = widget.onChanged != null && option.enabled;
      final chosen = option.value == widget.value;
      _nodes[i].skipTraversal = i != entry;
      final cell = widget.radio
          ? null
          : _cellShape(inner, first: i == 0, last: i == count - 1, rtl: rtl);
      parts.add(
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: (_, event) => _keys(i, event),
          child: RetroDesktopPressable(
            focusShape: cell ?? t.shapes.small,
            label: option.name ?? option.label,
            hint: option.note,
            button: !widget.radio,
            checked: widget.radio ? chosen : null,
            selected: widget.radio ? null : chosen,
            inGroup: true,
            error: widget.error,
            focusNode: _nodes[i],
            onPressed: live
                ? () {
                    if (!chosen) widget.onChanged!(option.value);
                  }
                : null,
            builder: (context, states) => widget.radio
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      // The dot on the label's first line, however many lines
                      // the label or its note take.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RetroDesktopOnCaps(
                          style: t.type.body,
                          child: SizedBox.square(
                            dimension: 18,
                            // Chisel: a sunken white disc, greyed while the
                            // pointer holds it. Platinum: a raised, bevelled grey
                            // disc. A black dot in either.
                            child: retroDesktopFace(
                              states: states,
                              sunken: t.chisel,
                              component: t.radioTheme.merge(
                                RetroDesktopStyle(
                                  shape: WidgetStatePropertyAll(t.shapes.radio),
                                  fill: WidgetStatePropertyAll(
                                    !t.chisel
                                        ? t.colors.platinumLight
                                        : states.contains(WidgetState.pressed)
                                        ? retroDesktopChiselHeldBox(t.colors)
                                        : t.colors.controlFace,
                                  ),
                                  foreground: WidgetStatePropertyAll(
                                    t.colors.text,
                                  ),
                                ),
                              ),
                              style: widget.style,
                              padding: const EdgeInsets.all(3),
                              child: Builder(
                                builder: (context) => DecoratedBox(
                                  decoration: ShapeDecoration(
                                    shape: t.shapes.radio,
                                    color: chosen
                                        ? DefaultTextStyle.of(context)
                                              .style
                                              .color
                                        : const Color(0x00000000),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(option.label, style: t.type.body),
                              if (option.note != null)
                                Text(option.note!, style: t.type.meta),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                // Every cell's face is the button face's height inside the
                // frame (the press centres it in its reach): one top and one
                // bottom across the row, the chosen one's sunken face
                // included. To the shared checks a cell is its band, the
                // frame's rim above and below it included: what the eye
                // reads as its top and bottom beside a button, whether a
                // chosen cell's own top row is ink or shade.
                : DesignKeylineFace(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: rim),
                      child: SizedBox(
                        height: cellHeight,
                        child: retroDesktopFace(
                          // The chosen cell stays pressed in; its label never moves.
                          states: chosen
                              ? {...states, WidgetState.selected}
                              : states,
                          sunken: chosen,
                          // Flush in the row: an outside ring would cross its
                          // neighbours.
                          ringInside: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: states.contains(WidgetState.pressed)
                                ? [t.colors.platinum, t.colors.platinumDark]
                                : [t.colors.platinumLight, t.colors.platinum],
                          ),
                          component: t.segmentedButtonTheme.merge(
                            RetroDesktopStyle(
                              fill: chosen
                                  ? WidgetStatePropertyAll(t.colors.highlight)
                                  : null,
                            ),
                          ),
                          style: (widget.style ?? const RetroDesktopStyle())
                              .merge(
                                RetroDesktopStyle(
                                  shape: WidgetStatePropertyAll(cell!),
                                  side: rim == 0
                                      ? null
                                      : const WidgetStatePropertyAll(
                                          BorderSide.none,
                                        ),
                                ),
                              ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (option.icon != null) ...[
                                Icon(option.icon),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: RetroDesktopCaps(
                                  Text(
                                    option.label,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );
    }
    // From 600 up a choice group keeps to its widest choice (radios) or its
    // segments at the widest one's width, at its column's start.
    final hug = retroDesktopHugs(context);
    Widget hugged(Widget group) => hug
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: IntrinsicWidth(child: group),
          )
        : group;
    if (widget.radio) {
      return hugged(Column(mainAxisSize: MainAxisSize.min, children: parts));
    }
    // A divider spans the cells' height, not the reach's.
    final divider = Padding(
      padding: EdgeInsets.only(
        top: cellTop,
        bottom: reachHeight - cellTop - cellHeight,
      ),
      child: SizedBox(
        width: rim,
        child: ColoredBox(color: t.colors.control),
      ),
    );
    final row = SizedBox(
      height: reachHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0 && rim > 0) divider,
            Expanded(child: parts[i]),
          ],
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final cells = rim == 0
            ? row
            // Platinum's frame: one outline round the cells' band, a rim
            // outside them, its inner corners the end cells' outer corners.
            // The presses keep the whole reach above and below it.
            : Stack(
                children: [
                  Positioned(
                    top: frameTop,
                    height: faceHeight,
                    left: 0,
                    right: 0,
                    child: retroDesktopFace(
                      states: const {},
                      scale: RetroDesktopFaceScale.button,
                      bevel: false,
                      component: t.segmentedButtonTheme.merge(
                        RetroDesktopStyle(
                          fill: WidgetStatePropertyAll(t.colors.platinum),
                          shape: WidgetStatePropertyAll(frameShape),
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: rim),
                    child: row,
                  ),
                ],
              );
        // In a row the whole control stands
        // [RetroDesktopSegmentedButton.rowSegmentWidth] a segment.
        if (!constraints.hasBoundedWidth) {
          return SizedBox(width: widget.rowSegmentWidth * count, child: cells);
        }
        if (hug) return hugged(cells);
        // Words too wide for their equal shares (twice the text size on a phone cut "loading" to "lo…") come down
        // together to the size at which the widest fits: every choice readable, all at one size.
        final share =
            (constraints.maxWidth - (count + 1) * rim) / count - 2 * 12 - 2;
        final words = t.type.body.merge(
          RetroDesktopStyle.first<TextStyle>(
            [widget.style, t.segmentedButtonTheme],
            (s) => s.textStyle,
            const {},
          ),
        );
        final scaler = MediaQuery.textScalerOf(context);
        var most = double.infinity;
        var over = false;
        for (final o in widget.options) {
          final tp = TextPainter(
            text: TextSpan(text: o.label, style: words),
            textDirection: Directionality.of(context),
            textScaler: TextScaler.noScaling,
            maxLines: 1,
          )..layout();
          final plain = tp.width;
          tp.dispose();
          final room = share - (o.icon != null ? 22 : 0);
          if (plain <= 0) continue;
          if (scaler.scale(plain) > room) over = true;
          most = math.min(most, room / plain);
        }
        if (!over) return cells;
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: math.max(1.0, most),
          child: cells,
        );
      },
    );
  }
}

/// A cell's outline in a segmented row: [inner]'s corners on the ends it
/// meets (the start corners on the first, the end corners on the last),
/// square where it meets a neighbour.
OutlinedBorder _cellShape(
  OutlinedBorder inner, {
  required bool first,
  required bool last,
  required bool rtl,
}) {
  if (inner is! RoundedRectangleBorder) {
    return first && last ? inner : const RetroDesktopBorder.square();
  }
  final r = inner.borderRadius.resolve(TextDirection.ltr);
  final left = rtl ? last : first, right = rtl ? first : last;
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: left ? r.topLeft : Radius.zero,
      bottomLeft: left ? r.bottomLeft : Radius.zero,
      topRight: right ? r.topRight : Radius.zero,
      bottomRight: right ? r.bottomRight : Radius.zero,
    ),
  );
}

/// An adjustable range: a capsule track, a grip thumb in the family's control shape, pointer dragging and arrow keys.
///
/// ```dart
/// RetroDesktopSlider(label: 'Volume', value: .5, onChanged: (_) {})
/// ```
class RetroDesktopSlider extends StatefulWidget {
  /// Creates a [RetroDesktopSlider].
  const RetroDesktopSlider({
    super.key,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.valueLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
    this.showLabel = true,
    this.rowWidth = 240,
  }) : assert(max > min),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0);

  /// Whether the label stands visibly with it; without, the label is its name for a screen reader alone.
  final bool showLabel;

  /// Width reserved for a row of options before wrapping.
  final double rowWidth;

  /// The visible or accessible name of this part.
  final String label;

  /// The current value to display or edit.
  final double value;

  /// The lower bound of the supported range.
  final double min;

  /// The upper bound of the supported range.
  final double max;

  /// The number of discrete slider intervals, or null for continuous movement.
  final int? divisions;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<double>? onChanged;

  /// Reports the value when a slider interaction finishes.
  final ValueChanged<double>? onChangeEnd;

  /// Formats the displayed and accessible slider value.
  final String Function(double)? valueLabel;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  State<RetroDesktopSlider> createState() => _SliderState();
}

class _SliderState extends State<RetroDesktopSlider> {
  final WidgetStatesController _states = WidgetStatesController();
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  double? _moved;
  bool _dragging = false;
  double get _span => widget.max - widget.min;
  double get _step => _span / (widget.divisions ?? 20);
  bool get _enabled => widget.onChanged != null;
  double _snap(double raw) {
    final value = raw.clamp(widget.min, widget.max);
    final divisions = widget.divisions;
    return divisions == null
        ? value
        : widget.min +
              ((value - widget.min) / _span * divisions).round() /
                  divisions *
                  _span;
  }

  String _words(double value) =>
      widget.valueLabel?.call(value) ??
      RetroDesktopLocalizations.of(context)
          .formatPercent((value - widget.min) / _span);
  void _set(double raw) {
    final value = _snap(raw);
    if (value != (_moved ?? widget.value)) widget.onChanged?.call(value);
    _moved = value;
  }

  void _settle() {
    final value = _moved ?? widget.value;
    _moved = null;
    widget.onChangeEnd?.call(value);
  }

  void _stepBy(double step) {
    _set(widget.value + step);
    _settle();
  }

  void _pointer(Offset local, double width) {
    final ratio = ((local.dx - 10) / math.max(1, width - 20)).clamp(0.0, 1.0);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    _set(widget.min + (rtl ? 1 - ratio : ratio) * _span);
  }

  KeyEventResult _keys(FocusNode node, KeyEvent event) {
    if (!_enabled || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    _pointerPosition = null;
    if (key == LogicalKeyboardKey.home) {
      _set(widget.min);
      _settle();
    } else if (key == LogicalKeyboardKey.end) {
      _set(widget.max);
      _settle();
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _stepBy(_step);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _stepBy(-_step);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _stepBy(rtl ? _step : -_step);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _stepBy(rtl ? -_step : _step);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _ownFocus?.dispose();
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return LimitedBox(
      maxWidth: widget.rowWidth,
      child: Semantics(
        container: true,
        slider: true,
        label: widget.label,
        value: _words(widget.value),
        enabled: _enabled,
        increasedValue: _enabled ? _words(_snap(widget.value + _step)) : null,
        decreasedValue: _enabled ? _words(_snap(widget.value - _step)) : null,
        onIncrease: _enabled ? () => _stepBy(_step) : null,
        onDecrease: _enabled ? () => _stepBy(-_step) : null,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showLabel)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(widget.label, style: t.type.body),
                    Text(_words(widget.value), style: t.type.meta),
                  ],
                ),
              Focus(
                canRequestFocus: false,
                skipTraversal: true,
                includeSemantics: false,
                onKeyEvent: _keys,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final width = box.hasBoundedWidth
                        ? box.maxWidth
                        : widget.rowWidth;
                    // Taps and keyboard activation use DesignPressable. Only the drag recognizer lives here.
                    return GestureDetector(
                      excludeFromSemantics: true,
                      onHorizontalDragStart: !_enabled
                          ? null
                          : (details) {
                              _pointerPosition = null;
                              _focus.requestFocus();
                              setState(() => _dragging = true);
                              _states.update(WidgetState.pressed, true);
                              _pointer(details.localPosition, width);
                            },
                      onHorizontalDragUpdate: !_enabled
                          ? null
                          : (details) => _pointer(details.localPosition, width),
                      onHorizontalDragEnd: !_enabled
                          ? null
                          : (_) {
                              setState(() => _dragging = false);
                              _states.update(WidgetState.pressed, false);
                              _settle();
                            },
                      onHorizontalDragCancel: !_enabled
                          ? null
                          : () {
                              setState(() => _dragging = false);
                              _states.update(WidgetState.pressed, false);
                              _moved = null;
                            },
                      child: Listener(
                        onPointerDown: !_enabled
                            ? null
                            : (event) {
                                _pointerPosition = event.localPosition;
                              },
                        child: RetroDesktopPressable(
                          button: false,
                          focusNode: _focus,
                          autofocus: widget.autofocus,
                          statesController: _states,
                          cursor: _dragging
                              ? SystemMouseCursors.grabbing
                              : SystemMouseCursors.grab,
                          onPressed: !_enabled
                              ? null
                              : () {
                                  final at = _pointerPosition;
                                  _pointerPosition = null;
                                  if (at == null) {
                                    _stepBy(_step);
                                  } else {
                                    _pointer(at, width);
                                    _settle();
                                  }
                                },
                          // The thumb is the part you move: it, not the
                          // whole track, takes the focus ring.
                          builder: (context, states) => Builder(
                            builder: (context) {
                              RetroDesktopHighlightClaim.maybeOf(context)
                                  ?.claim(context, states);
                              return retroDesktopOwnSize(
                                width: width,
                                height: 32,
                                child: CustomPaint(
                                  painter: _SliderPainter(
                                    ring: states.contains(WidgetState.focused)
                                        ? t.focus
                                        : null,
                                    hover: null,
                                    chisel: t.chisel,
                                    hairline: t.strokes.hairline,
                                    ratio: (widget.value - widget.min) / _span,
                                    rtl:
                                        Directionality.of(context) ==
                                        TextDirection.rtl,
                                    colors: t.colors,
                                    shapeDefault: t.shapes.small,
                                    trackShape: t.shapes.full,
                                    stroke: t.strokes.regular,
                                    states: states,
                                    style: widget.style,
                                    theme: t.sliderTheme,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Offset? _pointerPosition;
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.ratio,
    required this.shapeDefault,
    required this.trackShape,
    required this.stroke,
    required this.rtl,
    required this.colors,
    required this.states,
    required this.theme,
    this.style,
    this.ring,
    this.hover,
    this.chisel = false,
    this.hairline = 1,
  });
  final bool chisel;
  final double hairline;
  final RetroDesktopFocusRing? ring;
  final Color? hover;
  final OutlinedBorder shapeDefault, trackShape;
  final double stroke;
  final double ratio;
  final bool rtl;
  final RetroDesktopColors colors;
  final Set<WidgetState> states;
  final RetroDesktopStyle theme;
  final RetroDesktopStyle? style;
  @override
  void paint(Canvas canvas, Size size) {
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, theme], get, states);
    final edge = slot((s) => s.edge) ?? colors.control;
    final track = Rect.fromLTWH(
      10,
      (size.height - 6) / 2,
      math.max(0, size.width - 20),
      6,
    );
    final position = rtl ? 1 - ratio : ratio;
    final x = track.left + track.width * position;
    if (chisel && slot((s) => s.shape) == null) {
      _paintChisel(
        canvas,
        size,
        track,
        x,
        slot((s) => s.fill) ?? colors.highlight,
        slot((s) => s.foreground) ??
            (states.contains(WidgetState.pressed)
                ? retroDesktopChiselHeldBox(colors)
                : colors.platinum),
      );
      return;
    }
    // A style's shape is the thumb's; the track keeps the theme's capsule.
    final trackOutline = trackShape.copyWith(
      side: slot((s) => s.side) ?? BorderSide(color: edge, width: stroke),
    );
    canvas.drawPath(
      trackOutline.getOuterPath(track),
      Paint()..color = colors.paper,
    );
    canvas.save();
    canvas.clipPath(trackOutline.getInnerPath(track));
    final fill = Rect.fromLTRB(
      rtl ? x : track.left + stroke,
      track.top + stroke,
      rtl ? track.right - stroke : x,
      track.bottom - stroke,
    );
    canvas.drawPath(
      RetroDesktopShapes.inset(trackOutline, stroke).getOuterPath(fill),
      Paint()..color = slot((s) => s.fill) ?? colors.highlight,
    );
    canvas.restore();
    trackOutline.paint(canvas, track);
    final thumb = Rect.fromCenter(
      center: Offset(x, size.height / 2),
      width: 18,
      height: 26,
    );
    final shape = (slot((s) => s.shape) ?? shapeDefault).copyWith(
      side: slot((s) => s.side) ?? BorderSide(color: edge, width: stroke),
    );
    // Held, Platinum's thumb darkens and loses its lit edge, as its buttons do.
    final held = states.contains(WidgetState.pressed);
    canvas.drawPath(
      shape.getOuterPath(thumb),
      Paint()
        ..color =
            slot((s) => s.foreground) ??
            (held
                ? (colors.dark ? colors.platinum : colors.platinumDark)
                : colors.platinumLight),
    );
    shape.paint(canvas, thumb);
    canvas.save();
    canvas.clipPath(shape.getInnerPath(thumb));
    if (!held) {
      canvas.drawLine(
        thumb.topLeft + const Offset(1, 1),
        thumb.topRight + const Offset(-1, 1),
        Paint()..color = colors.bevelLight,
      );
    }
    for (var delta = -3; delta <= 3; delta += 3) {
      canvas.drawLine(
        Offset(x + delta, thumb.top + 6),
        Offset(x + delta, thumb.bottom - 6),
        Paint()..color = colors.bevelDark,
      );
    }
    if (hover != null) {
      canvas.drawPath(shape.getInnerPath(thumb), Paint()..color = hover!);
    }
    canvas.restore();
    final ring = this.ring;
    if (ring != null && ring.width > 0) {
      RetroDesktopShapes.outset(shape, ring.gap)
          .copyWith(
            side: BorderSide(
              color: ring.color,
              width: ring.width,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          )
          .paint(canvas, thumb.inflate(ring.gap));
    }
  }

  // The PC's trackbar: a sunken groove, and a grip that points down at it,
  // lit along its top and left, dark along its right and its point. Focus is
  // a dotted rectangle round the whole control.
  void _paintChisel(
    Canvas canvas,
    Size size,
    Rect groove,
    double x,
    Color fill,
    Color face,
  ) {
    final g = Rect.fromLTWH(groove.left, groove.top - 1, groove.width, 8);
    canvas.drawRect(g, Paint()..color = colors.paper);
    canvas.drawRect(
      rtl
          ? Rect.fromLTRB(x, g.top + 2, g.right - 2, g.bottom - 2)
          : Rect.fromLTRB(g.left + 2, g.top + 2, x, g.bottom - 2),
      Paint()..color = fill,
    );
    retroDesktopPaintChiselRect(
      canvas,
      g,
      retroDesktopChiselEdge(colors, sunken: true),
      outer: stroke,
      inner: hairline,
    );
    final l = (x - 9).roundToDouble(), r = l + 18;
    final t = (size.height / 2 - 13).roundToDouble();
    final body = t + 18, point = t + 26;
    final cx = (l + r) / 2;
    final grip = Path()
      ..addPolygon([
        Offset(l, t),
        Offset(r, t),
        Offset(r, body),
        Offset(cx, point),
        Offset(l, body),
      ], true);
    canvas.drawPath(grip, Paint()..color = face);
    void line(List<Offset> pts, Color color) {
      canvas.drawPath(
        Path()..addPolygon(pts, false),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..isAntiAlias = false,
      );
    }

    // Held, the grip sinks: its bevel turns over, light below and right.
    final held = states.contains(WidgetState.pressed);
    final light = held ? colors.outline : colors.bevelLight;
    final light2 = held ? colors.bevelDark : colors.platinumLight;
    final dark = held ? colors.bevelLight : colors.outline;
    final dark2 = held ? colors.platinumLight : colors.bevelDark;
    line([
      Offset(l + .5, body),
      Offset(l + .5, t + .5),
      Offset(r - .5, t + .5),
    ], light);
    line([Offset(l + .5, body), Offset(cx, point - .5)], light);
    line([
      Offset(l + 1.5, body - 1),
      Offset(l + 1.5, t + 1.5),
      Offset(r - 1.5, t + 1.5),
    ], light2);
    line([
      Offset(r - .5, t + .5),
      Offset(r - .5, body),
      Offset(cx, point - .5),
    ], dark);
    line([
      Offset(r - 1.5, t + 1.5),
      Offset(r - 1.5, body - .5),
      Offset(cx, point - 1.5),
    ], dark2);
    final ring = this.ring;
    if (ring != null && ring.width > 0) {
      final box = (Offset.zero & size).deflate(ring.width / 2);
      final paint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.width
        ..isAntiAlias = false;
      final path = Path()..addRect(box);
      for (final contour in path.computeMetrics()) {
        for (var from = 0.0; from < contour.length; from += 2 * ring.width) {
          canvas.drawPath(
            contour.extractPath(
              from,
              math.min(from + ring.width, contour.length),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.chisel != chisel ||
      old.hairline != hairline ||
      old.ring != ring ||
      old.hover != hover ||
      old.shapeDefault != shapeDefault ||
      old.trackShape != trackShape ||
      old.stroke != stroke ||
      old.ratio != ratio ||
      old.rtl != rtl ||
      old.colors != colors ||
      !setEquals(old.states, states) ||
      old.style != style ||
      old.theme != theme;
}
