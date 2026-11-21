/// Studio's other entries, all glass windows in the metal like
/// [StudioTextField]: [StudioSearchField], [StudioPasswordField],
/// [StudioInputGroup] (a window with engraved add-ons), [StudioCodeField] (a
/// one-time code in small readout windows), [StudioStepper] (a count in a
/// readout between two keys), [StudioFormField] (any control with its label,
/// help and error), [StudioCombobox] and [StudioTagInput].
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'feedback.dart' show StudioSpinner;
import 'internal/stepper_glyph.dart';
import 'select.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

// A window's face for [states]: the glass, its rim lit while focused and
// red with an error, dimmed when off. Focus lights its edge as it does a
// key's: however it came, it is where the typing goes.
StudioFace _window(StudioThemeData theme, Set<WidgetState> states) {
  final c = theme.colors;
  final error = states.contains(WidgetState.error);
  final focused = states.contains(WidgetState.focused);
  final disabled = states.contains(WidgetState.disabled);
  return c.displayFace.copyWith(
    radius: StudioRadii.key,
    rim: error
        ? c.danger
        : focused
        ? c.indicator.withValues(alpha: 0.9)
        : c.indicator.withValues(alpha: 0),
    focus: focused ? c.focusRing : c.focusRing.withValues(alpha: 0),
    fill: disabled ? Color.lerp(c.display, c.panelLow, 0.4) : null,
  );
}

// A bare entry on a window's glass: no window of its own.
class _Entry extends StatelessWidget {
  const _Entry({
    required this.controller,
    required this.focusNode,
    this.hint,
    this.enabled = true,
    this.semanticLabel,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.keyboardType,
    this.inputFormatters,
    this.textStyle,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final bool enabled;
  final String? semanticLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final words = theme.textTheme.body
        .copyWith(color: enabled ? c.onDisplay : c.onDisplayMuted)
        .merge(textStyle);
    return Semantics(
      label: semanticLabel,
      child: DesignTextEntryBox(
        minHeight: theme.controlHeight,
        controller: controller,
        hint: hint == null
            ? null
            : Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: words.copyWith(color: c.onDisplayMuted),
              ),
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: null,
            style: words,
            cursorColor: c.indicator,
            cursorWidth: 2,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onEditingComplete: onEditingComplete,
          ),
        ),
      ),
    );
  }
}

// A small capless key inside a window (clear, reveal): a 44 target round a
// 28 face whose recess shows under a press.
class _WindowKey extends StatelessWidget {
  const _WindowKey({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, states, _) => TapTargetPadding(
        child: SizedBox.square(
          dimension: 28,
          child: AnimatedStudioSurface(
            face: c.recessFace.copyWith(
              radius: StudioRadii.small,
              presence: states.contains(WidgetState.pressed) ? 1 : 0,
              focus: states.contains(WidgetState.focused)
                  ? c.focusRing
                  : c.focusRing.withValues(alpha: 0),
            ),
            child: Icon(
              icon,
              size: StudioIconSizes.medium,
              color: states.contains(WidgetState.disabled)
                  ? c.disabled
                  : c.onDisplayMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// A search field: a glass window with a lens at its start and, once it
/// has words, a key at its end that clears them. Submitting gives up the
/// keyboard, as a search does.
///
/// Reads [style] as [StudioTextField] does, then
/// [StudioThemeData.textFieldStyle].
///
/// ```dart
/// StudioSearchField(hint: 'Search episodes', onChanged: (q) => setState(() => query = q))
/// ```
class StudioSearchField extends StatefulWidget {
  /// A search field.
  const StudioSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.semanticLabel,
    this.clearLabel = 'Clear',
    this.style,
  });

  /// The words; yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// What it says while empty.
  final String hint;

  /// Called as the words change (cleared included).
  final ValueChanged<String>? onChanged;

  /// Called when the words are submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes words.
  final bool enabled;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// What a screen reader calls it; its [hint] when null.
  final String? semanticLabel;

  /// The clear key's name.
  final String clearLabel;

  /// Its style, over [StudioThemeData.textFieldStyle].
  final StudioStyle? style;

  @override
  State<StudioSearchField> createState() => _StudioSearchFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hint', hint))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _StudioSearchFieldState extends State<StudioSearchField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(StudioSearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_changed);
      if (widget.controller != null) {
        _own?.dispose();
        _own = null;
      }
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
  Widget build(BuildContext context) => StudioTextField(
    controller: _controller,
    focusNode: widget.focusNode,
    hint: widget.hint,
    semanticLabel: widget.semanticLabel ?? widget.hint,
    enabled: widget.enabled,
    autofocus: widget.autofocus,
    textInputAction: TextInputAction.search,
    textCapitalization: TextCapitalization.none,
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    style: widget.style,
    prefixIcon: const Icon(LucideIcons.search),
    suffix: _controller.text.isEmpty
        ? null
        : _WindowKey(
            icon: LucideIcons.x,
            label: widget.clearLabel,
            onPressed: widget.enabled
                ? () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  }
                : null,
          ),
  );
}

/// A password field: its words hidden as dots, with a key at its end that
/// shows them while it is pressed in, and hides them again when the field
/// loses the keyboard.
///
/// Built on ui_core's RawPasswordReveal; reads [style] as
/// [StudioTextField] does.
///
/// ```dart
/// StudioPasswordField(label: 'Password', onChanged: (v) => password = v)
/// ```
class StudioPasswordField extends StatelessWidget {
  /// A password field.
  const StudioPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.helper,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofillHints = const [AutofillHints.password],
    this.showLabel = 'Show password',
    this.hideLabel = 'Hide password',
    this.style,
  });

  /// The words; yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The label above it.
  final String? label;

  /// A note under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the words are submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes words.
  final bool enabled;

  /// What autofill may put in it.
  final Iterable<String>? autofillHints;

  /// The reveal key's name while the words are hidden.
  final String showLabel;

  /// The reveal key's name while they show.
  final String hideLabel;

  /// Its style, over [StudioThemeData.textFieldStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) => RawPasswordReveal(
    focusNode: focusNode,
    hideOnBlur: true,
    showLabel: showLabel,
    hideLabel: hideLabel,
    builder: (context, password) => StudioTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      helper: helper,
      error: error,
      enabled: enabled,
      obscureText: password.obscured,
      autofillHints: autofillHints,
      keyboardType: TextInputType.visiblePassword,
      textCapitalization: TextCapitalization.none,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: style,
      suffix: _WindowKey(
        icon: password.obscured ? LucideIcons.eye : LucideIcons.eyeOff,
        label: password.toggleLabel,
        onPressed: enabled ? password.toggle : null,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }
}

/// A field with add-ons in one window: [leading] and [trailing] stand as
/// engraved plates at its ends (a scheme, a unit), parted from the words by
/// a groove; the window's rim and edge light while the words have the
/// keyboard.
///
/// Built on ui_core's DesignInputGroup; reads [style]'s `fill` and `edge`,
/// then [StudioThemeData.textFieldStyle].
///
/// ```dart
/// StudioInputGroup(label: 'Feed address', leading: const Text('https://'), hint: 'roomtone.example/feed', onChanged: (v) => feed = v)
/// ```
class StudioInputGroup extends StatefulWidget {
  /// A field with add-ons.
  const StudioInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.leading,
    this.trailing,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.style,
  });

  /// The words; yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The add-on before the words.
  final Widget? leading;

  /// The add-on after the words.
  final Widget? trailing;

  /// The label above it.
  final String? label;

  /// What it says while empty.
  final String? hint;

  /// A note under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called when the words are submitted.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// What it lets through.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether it takes words.
  final bool enabled;

  /// Its style, over [StudioThemeData.textFieldStyle].
  final StudioStyle? style;

  @override
  State<StudioInputGroup> createState() => _StudioInputGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _StudioInputGroupState extends State<StudioInputGroup> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  Widget _plate(BuildContext context, Widget child) {
    final theme = StudioTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.medium),
      child: DefaultTextStyle(
        style: theme.textTheme.secondary.copyWith(
          color: widget.enabled
              ? theme.colors.onDisplayMuted
              : theme.colors.disabled,
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            size: StudioIconSizes.medium,
            color: theme.colors.onDisplayMuted,
          ),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
  }

  Widget _groove(StudioColors c) => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(vertical: StudioSpacing.small),
    color: c.displayLine,
  );

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: StudioFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        DesignInputGroup(
          focusNode: _focus,
          enabled: widget.enabled,
          isError: widget.error != null,
          builder: (context, states, child) {
            final layered = DesignStyleOf([
              widget.style,
              theme.textFieldStyle,
            ], states);
            return AnimatedStudioSurface(
              face: layered.on(_window(theme, states)),
              stiffness: StudioMotion.lampStiffness,
              child: child,
            );
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.leading != null) ...[
                  ExcludeSemantics(child: _plate(context, widget.leading!)),
                  _groove(c),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: StudioSpacing.medium + StudioSpacing.hair,
                    ),
                    child: _Entry(
                      controller: _controller,
                      focusNode: _focus,
                      hint: widget.hint,
                      enabled: widget.enabled,
                      semanticLabel: widget.label,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  _groove(c),
                  ExcludeSemantics(child: _plate(context, widget.trailing!)),
                ],
              ],
            ),
          ),
        ),
        StudioFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

/// A one-time code: one small readout window per figure, the figures lit
/// in the indicator; the window the next figure goes in has its rim lit.
/// Paste fills them all; Backspace walks back.
///
/// Built on ui_core's RawOtpField (one input under the windows, so a
/// screen reader and autofill meet one field).
///
/// ```dart
/// StudioCodeField(length: 6, semanticLabel: 'Sign-in code', onCompleted: verify)
/// ```
class StudioCodeField extends StatelessWidget {
  /// A code of [length] figures.
  const StudioCodeField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.label,
    this.semanticLabel,
    this.error,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
  });

  /// How many figures.
  final int length;

  /// The code; yours to dispose.
  final RawOtpController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Called as the code changes.
  final ValueChanged<String>? onChanged;

  /// Called once every window holds a figure.
  final ValueChanged<String>? onCompleted;

  /// The label above it.
  final String? label;

  /// What a screen reader calls it; [label] when null.
  final String? semanticLabel;

  /// What is wrong, under it.
  final String? error;

  /// Whether it takes figures.
  final bool enabled;

  /// Whether its figures are hidden.
  final bool obscureText;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          ExcludeSemantics(child: StudioFieldLabel(label!, enabled: enabled)),
        RawOtpField(
          length: length,
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onCompleted: onCompleted,
          enabled: enabled,
          isError: error != null,
          obscureText: obscureText,
          autofocus: autofocus,
          semanticLabel: semanticLabel ?? label,
          layoutBuilder: (context, slots) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, slot) in slots.indexed) ...[
                if (i > 0)
                  SizedBox(
                    width: length == 6 && i == 3
                        ? StudioSpacing.large
                        : StudioSpacing.small,
                  ),
                slot,
              ],
            ],
          ),
          slotBuilder: (context, slot) {
            final figure = slot.character;
            return SizedBox(
              width: 40,
              height: 52,
              child: AnimatedStudioSurface(
                stiffness: StudioMotion.lampStiffness,
                face: c.readoutFace.copyWith(
                  radius: StudioRadii.small,
                  rim: slot.isError
                      ? c.danger
                      : slot.active && slot.focused
                      ? c.readoutLit.withValues(alpha: 0.9)
                      : c.readoutLit.withValues(alpha: 0),
                ),
                child: Center(
                  child: Text(
                    figure.isEmpty
                        ? ''
                        : slot.obscured
                        ? '•'
                        : figure,
                    style: theme.textTheme.readout.copyWith(
                      fontSize: 24,
                      color: slot.enabled ? c.readoutLit : c.disabled,
                      shadows: slot.enabled
                          ? c.readoutGlow(c.readoutLit, alpha: 0.5)
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        StudioFieldMessage(error: error),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

/// A count you step: its figures in a readout window between a key that
/// takes one away and a key that adds one, the keys as tall as the window
/// (the control's height, or taller as the figures grow). The arrow keys
/// step it while it has the keyboard; a screen reader reads and steps it as
/// a value. A key at a bound goes dark.
///
/// A null [onChanged] disables it.
///
/// ```dart
/// StudioStepper(value: copies, min: 1, max: 9, semanticLabel: 'Copies', onChanged: (v) => setState(() => copies = v))
/// ```
class StudioStepper extends StatelessWidget {
  /// A stepper at [value].
  const StudioStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.semanticLabel,
    this.format,
    this.decreaseLabel = 'Fewer',
    this.increaseLabel = 'More',
  });

  /// The count.
  final int value;

  /// Called with the next count; null disables it.
  final ValueChanged<int>? onChanged;

  /// The least count.
  final int min;

  /// The most count.
  final int max;

  /// How much a key steps.
  final int step;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How the count reads (`'$value min'`); the figure in the reader's
  /// digits when null.
  final String Function(int value)? format;

  /// The take-away key's name.
  final String decreaseLabel;

  /// The add key's name.
  final String increaseLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final words = RawWidgetsLocalizations.of(context);
    String text(int v) => format?.call(v) ?? words.formatDecimal(v);
    final c = theme.colors;
    final change = onChanged;
    final canDown = change != null && value - step >= min;
    final canUp = change != null && value + step <= max;
    void down() => change?.call((value - step).clamp(min, max));
    void up() => change?.call((value + step).clamp(min, max));
    final figure = theme.textTheme.readout.copyWith(
      color: change == null ? c.disabled : c.readoutLit,
    );
    // The keys and the readout are one height: the control's, or taller as
    // the figures grow.
    final line = TextPainter(
      text: TextSpan(text: text(value), style: figure),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final height = math.max(theme.controlHeight, line.height);
    line.dispose();
    final keyStyle = StudioStyle(
      minimumSize: WidgetStatePropertyAll(Size.square(height)),
    );
    return Semantics(
      container: true,
      label: semanticLabel,
      value: text(value),
      increasedValue: canUp ? text(value + step) : null,
      decreasedValue: canDown ? text(value - step) : null,
      onIncrease: canUp ? up : null,
      onDecrease: canDown ? down : null,
      child: Focus(
        canRequestFocus: change != null,
        onKeyEvent: (node, event) {
          if (event is KeyUpEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowRight) {
            if (canUp) up();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.arrowLeft) {
            if (canDown) down();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: ExcludeFocus(
                    child: StudioIconButton(
                      icon: const Icon(LucideIcons.minus),
                      tooltip: decreaseLabel,
                      style: keyStyle,
                      onPressed: canDown ? down : null,
                    ),
                  ),
                ),
                const SizedBox(width: StudioSpacing.small),
                ExcludeSemantics(
                  child: AnimatedStudioSurface(
                    stiffness: StudioMotion.lampStiffness,
                    face: c.readoutFace.copyWith(
                      rim: focused
                          ? c.readoutLit.withValues(alpha: 0.9)
                          : c.readoutLit.withValues(alpha: 0),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 64,
                        minHeight: height,
                        maxHeight: height,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: StudioSpacing.medium,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(text(value), maxLines: 1, style: figure),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: StudioSpacing.small),
                ExcludeSemantics(
                  child: ExcludeFocus(
                    child: StudioIconButton(
                      icon: const Icon(LucideIcons.plus),
                      tooltip: increaseLabel,
                      style: keyStyle,
                      onPressed: canUp ? up : null,
                    ),
                  ),
                ),
              ],
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
      ..add(IntProperty('value', value))
      ..add(IntProperty('min', min))
      ..add(IntProperty('max', max))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// Any control with its label above it, its help under it and its error
/// beside a lit lamp in the help's place, read to a screen reader as one
/// field (its name, its hint, its validity). A group of controls (a row or
/// column of them, a segmented choice, a stepper, chips) keeps each
/// control's own node and tap, and the label names the group
/// ([mergeSemantics]).
///
/// Built on ui_core's RawInputDecorator; a [StudioTextField] carries its own label
/// and needs none.
///
/// ```dart
/// StudioFormField(label: 'Publish at', helper: "Your listeners' time", child: StudioTimePicker(value: time, semanticLabel: 'Publish at', onChanged: setTime))
/// ```
class StudioFormField extends StatelessWidget {
  /// [child] as a field.
  const StudioFormField({
    super.key,
    required this.child,
    this.label,
    this.helper,
    this.error,
    this.isRequired = false,
    this.enabled = true,
    this.mergeSemantics,
  });

  /// The control.
  final Widget child;

  /// Its label.
  final String? label;

  /// A note under it.
  final String? helper;

  /// What is wrong, in the help's place.
  final String? error;

  /// Whether it must be filled in (a screen reader says so).
  final bool isRequired;

  /// Whether the control is on.
  final bool enabled;

  /// Whether the control is one node that takes the label as its name
  /// (true) or a group the label names (false). Left null, ui_core's
  /// RawInputDecorator reads what the child brings to the semantics tree: one
  /// control is one node; several (a stepper's keys, a segmented choice,
  /// radios, chips) keep each its own node and tap, the label naming them;
  /// and a group that already names itself is not named again.
  final bool? mergeSemantics;

  @override
  Widget build(BuildContext context) => RawInputDecorator(
    labelText: label,
    helperText: helper,
    errorText: error,
    required: isRequired,
    enabled: enabled,
    mergeSemantics: mergeSemantics,
    builder: (context, parts) {
      final theme = StudioTheme.of(context);
      final c = theme.colors;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.labelText != null)
            ExcludeSemantics(
              child: StudioFieldLabel(parts.labelText!, enabled: enabled),
            ),
          parts.control,
          if (parts.error != null)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.small),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StudioLamp(on: true, color: c.danger, size: 6),
                  const SizedBox(width: StudioSpacing.small),
                  Expanded(
                    child: DefaultTextStyle(
                      style: theme.textTheme.caption.copyWith(
                        color: c.dangerLegend,
                      ),
                      child: parts.error!,
                    ),
                  ),
                ],
              ),
            )
          else if (parts.helper != null)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.small),
              child: DefaultTextStyle(
                style: theme.textTheme.caption.copyWith(color: c.legendMuted),
                child: parts.helper!,
              ),
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
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(FlagProperty('isRequired', value: isRequired, ifTrue: 'required'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        FlagProperty('mergeSemantics', value: mergeSemantics, ifFalse: 'group'),
      );
  }
}

Widget _nothing(BuildContext context, String words) {
  final theme = StudioTheme.of(context);
  return SizedBox(
    height: theme.controlHeight,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(
        start:
            StudioSpacing.medium +
            StudioSpacing.hair -
            StudioMetrics.recessInset,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          words,
          style: theme.textTheme.body.copyWith(
            color: theme.colors.onDisplayMuted,
          ),
        ),
      ),
    ),
  );
}

Widget _suggestions(BuildContext context, Widget list) =>
    StudioListBezel(child: list);

// A search on its way: a small ring of lamps and its word, where the
// options will stand.
Widget _searching(BuildContext context) {
  final theme = StudioTheme.of(context);
  return SizedBox(
    height: theme.controlHeight,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(
        start:
            StudioSpacing.medium +
            StudioSpacing.hair -
            StudioMetrics.recessInset,
      ),
      child: Row(
        children: [
          const ExcludeSemantics(child: StudioSpinner(size: 16)),
          const SizedBox(width: StudioSpacing.small),
          Flexible(
            child: Text(
              RawWidgetsLocalizations.of(context).loadingLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.body.copyWith(
                color: theme.colors.onDisplayMuted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// A search that failed: what happened, and Try again as an option row, lit
// while the keys are on it (the keyboard stays in the field).
Widget _failed(BuildContext context, RawSearchError error) {
  final words = RawWidgetsLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _nothing(context, words.searchFailedMessage),
      Semantics(
        button: true,
        label: words.retryButtonLabel,
        onTap: error.retry,
        excludeSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: error.retry,
            child: StudioMenuRow(
              label: words.retryButtonLabel,
              highlighted: error.focused,
            ),
          ),
        ),
      ),
    ],
  );
}

/// A field that suggests: type, and the options whose words match open in
/// a glass list under it; the arrows walk them, Enter takes the lit one and
/// the field keeps the keyboard. With [requireSelection] only an option may
/// stand in it. Given [search] in place of [options], it asks for the options
/// as the typing rests ([debounceDuration]): while it looks the list says so,
/// and when the search fails the list says that and offers Try again.
///
/// Built on ui_core's RawCombobox. Enter is taken in the entry's
/// editing-complete (never its submit), so on the web the keyboard keeps
/// typing after it.
///
/// ```dart
/// StudioCombobox<String>(label: 'Show', options: shows, labelOf: (s) => s, value: show, onSelected: (s) => setState(() => show = s))
/// ```
class StudioCombobox<T extends Object> extends StatelessWidget {
  /// A combobox over [options].
  const StudioCombobox({
    super.key,
    this.options = const [],
    this.search,
    this.debounceDuration,
    required this.labelOf,
    this.value,
    this.onSelected,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.emptyText = 'Nothing matches',
    this.requireSelection = true,
    this.enabled = true,
    this.isOptionEnabled,
    this.style,
  });

  /// What may be chosen, when there is no [search].
  final Iterable<T> options;

  /// Finds the options for the words typed, in place of filtering [options]
  /// (a lookup on a server).
  final DesignOptionSearch<T>? search;

  /// How long the typing rests before [search] runs; null runs it at once.
  final Duration? debounceDuration;

  /// Each option's words.
  final String Function(T option) labelOf;

  /// The option chosen.
  final T? value;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// The label above it.
  final String? label;

  /// What it says while empty.
  final String? hint;

  /// A note under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// What the list says when nothing matches.
  final String emptyText;

  /// Whether only an option may stand in it.
  final bool requireSelection;

  /// Whether it takes words.
  final bool enabled;

  /// Whether `option` may be taken.
  final bool Function(T option)? isOptionEnabled;

  /// The window's style, over [StudioThemeData.textFieldStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: StudioFieldLabel(label!, enabled: enabled)),
        RawCombobox<T>(
          options: options,
          search: search,
          debounceDuration: debounceDuration,
          loadingBuilder: _searching,
          errorBuilder: _failed,
          displayStringForOption: labelOf,
          value: value,
          onSelected: onSelected,
          requireSelection: requireSelection,
          isOptionEnabled: isOptionEnabled,
          // One lit slot: the pointer's row is the keys' row.
          highlightFollowsPointer: true,
          semanticLabel: label,
          fieldBuilder: (context, field) => StudioTextField(
            controller: field.controller,
            focusNode: field.focusNode,
            hint: hint,
            error: error == null ? null : '',
            semanticLabel: label,
            enabled: enabled,
            style: style,
            textCapitalization: TextCapitalization.none,
            // Enter takes the lit option and the field keeps the keyboard.
            onEditingComplete: field.submit,
            suffix: ExcludeSemantics(
              child: SizedBox.square(
                dimension: StudioIconSizes.medium,
                child: Center(
                  child: StudioStepperGlyph(
                    color: enabled ? c.onDisplayMuted : c.disabled,
                  ),
                ),
              ),
            ),
          ),
          optionBuilder: (context, option, states) => StudioMenuRow(
            label: labelOf(option),
            states: states,
            showLamp: true,
          ),
          surfaceBuilder: _suggestions,
          emptyBuilder: (context) => _nothing(context, emptyText),
        ),
        StudioFieldMessage(helper: helper, error: error),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// Values as small engraved plates in one glass window, with an entry after
/// them that suggests from [options] (and, given [onCreate], makes a new
/// value of its words on Enter or a comma). Each plate's cross removes it;
/// Backspace in the empty entry takes the last. Enter keeps the keyboard in
/// the entry for the next. Given [search] in place of [options], it asks for
/// suggestions as the typing rests ([debounceDuration]), the list saying
/// while it looks and offering Try again when the search fails.
///
/// Built on ui_core's RawTagInput; Enter is taken in the entry's
/// editing-complete (never its submit), so on the web typing carries on.
///
/// ```dart
/// StudioTagInput<String>(label: 'Topics', values: topics, options: allTopics, labelOf: (t) => t, onChanged: (next) => setState(() => topics = next))
/// ```
class StudioTagInput<T extends Object> extends StatefulWidget {
  /// Tags over [values].
  const StudioTagInput({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.debounceDuration,
    required this.labelOf,
    this.onCreate,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.maxTags,
    this.enabled = true,
    this.isOptionEnabled,
    this.removeLabel = 'Remove',
    this.style,
  });

  /// The values, in order.
  final List<T> values;

  /// Called with the next values.
  final ValueChanged<List<T>> onChanged;

  /// What may be suggested, when there is no [search].
  final Iterable<T> options;

  /// Finds suggestions for the words typed, in place of filtering
  /// [options] (a lookup on a server).
  final DesignOptionSearch<T>? search;

  /// How long the typing rests before [search] runs; null runs it at once.
  final Duration? debounceDuration;

  /// Each value's words.
  final String Function(T value) labelOf;

  /// Makes a value of typed words; null takes only [options].
  final T? Function(String words)? onCreate;

  /// The label above it.
  final String? label;

  /// What it says while it holds nothing.
  final String? hint;

  /// A note under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// The most values it takes.
  final int? maxTags;

  /// Whether it takes input.
  final bool enabled;

  /// Whether `option` may be taken.
  final bool Function(T option)? isOptionEnabled;

  /// A plate's cross's name ("Remove Interviews").
  final String removeLabel;

  /// The window's style, over [StudioThemeData.textFieldStyle].
  final StudioStyle? style;

  @override
  State<StudioTagInput<T>> createState() => _StudioTagInputState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _StudioTagInputState<T extends Object> extends State<StudioTagInput<T>> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (widget.error != null) WidgetState.error,
      if (_focus.hasFocus) WidgetState.focused,
    };
    final layered = DesignStyleOf([widget.style, theme.textFieldStyle], states);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: StudioFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        RawTagInput<T>(
          values: widget.values,
          onChanged: widget.onChanged,
          options: widget.options,
          search: widget.search,
          debounceDuration: widget.debounceDuration,
          loadingBuilder: _searching,
          errorBuilder: _failed,
          displayStringForOption: widget.labelOf,
          onCreate: widget.onCreate,
          maxTags: widget.maxTags,
          isOptionEnabled: widget.isOptionEnabled,
          highlightFollowsPointer: true,
          focusNode: _focus,
          semanticLabel: widget.label,
          deleteLabel: widget.removeLabel,
          layoutBuilder: (context, tags, field) => MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            // A press anywhere in the window gives the entry the keyboard:
            // the pointer's convenience; a screen reader focuses the entry.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.enabled ? _focus.requestFocus : null,
              child: AnimatedStudioSurface(
                stiffness: StudioMotion.lampStiffness,
                face: layered.on(
                  _window(theme, states).copyWith(
                    radius: StudioRadii.small + StudioMetrics.recessInset,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: theme.controlHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(StudioMetrics.recessInset),
                    child: Wrap(
                      spacing: StudioSpacing.tight,
                      runSpacing: StudioSpacing.tight,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...tags,
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 120,
                            maxWidth: 240,
                          ),
                          child: IntrinsicWidth(child: field),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          fieldBuilder: (context, field) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.small - StudioSpacing.hair,
            ),
            child: _Entry(
              controller: field.controller,
              focusNode: field.focusNode,
              enabled: widget.enabled,
              hint: widget.values.isEmpty ? widget.hint : null,
              semanticLabel: widget.label,
              textStyle: layered.textStyle,
              // Enter takes a tag and leaves the keyboard here for the next.
              onEditingComplete: field.submit,
            ),
          ),
          tagBuilder: (context, value, tag) => _Plate(
            label: widget.labelOf(value),
            focused: tag.focused,
            enabled: widget.enabled,
            removeLabel: '${widget.removeLabel} ${widget.labelOf(value)}',
            onDeleted: tag.onDeleted,
          ),
          optionBuilder: (context, option, states) =>
              StudioMenuRow(label: widget.labelOf(option), states: states),
          surfaceBuilder: _suggestions,
        ),
        StudioFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

// The tag face fills its touch target and grows with its label. The remove
// key uses the trailing end of the plate, including the space around the cross.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.label,
    required this.focused,
    required this.enabled,
    required this.removeLabel,
    required this.onDeleted,
  });

  final String label;
  final bool focused;
  final bool enabled;
  final String removeLabel;
  final VoidCallback onDeleted;

  static const double _face = 32;
  static const double _cross = 28;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final ink = enabled ? c.onKey : c.disabled;
    final floor = DesignTapTargets.of(context).floorOn();
    final style = theme.textTheme.secondary.copyWith(
      color: ink,
      fontWeight: FontWeight.w500,
    );
    final faceHeight = math.max(
      math.max(_face, floor.height),
      MediaQuery.textScalerOf(context).scale(style.fontSize!) *
              (style.height ?? 1.2) +
          2 * StudioSpacing.tight,
    );
    return SizedBox(
      height: faceHeight,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          AnimatedStudioSurface(
            stiffness: StudioMotion.lampStiffness,
            face: c.keyFace.copyWith(
              radius: StudioRadii.small,
              focus: focused ? c.focusRing : c.focusRing.withValues(alpha: 0),
              fill: enabled ? null : Color.lerp(c.key, c.panelLow, 0.5),
            ),
            child: SizedBox(
              height: faceHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: StudioSpacing.small + StudioSpacing.hair,
                    ),
                    child: Text(label, style: style),
                  ),
                  const SizedBox(width: _cross),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: math.max(_cross, floor.width),
            child: RawButton(
              onPressed: enabled ? onDeleted : null,
              semanticLabel: removeLabel,
              builder: (context, states, _) => Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(
                  width: _cross,
                  height: faceHeight,
                  child: Icon(
                    LucideIcons.x,
                    size: StudioIconSizes.small,
                    color: states.contains(WidgetState.pressed)
                        ? c.dangerLegend
                        : ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
