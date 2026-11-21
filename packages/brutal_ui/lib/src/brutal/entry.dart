/// Brutal's other text entries, each the field's square ruled box:
/// [BrutalSearchField], [BrutalPasswordField], [BrutalInputGroup] (a field
/// with add-on cells on shared rules), [BrutalCodeField] (a one-time code as
/// a strip of cells), [BrutalCombobox] (a field that suggests),
/// [BrutalTagInput] (values as tags in the box), [BrutalFormField] (a label,
/// help and error round any control) and [BrutalFieldButton] (a glyph button
/// inside a field).
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'feedback.dart';
import 'lists.dart';
import 'menu.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

// The controller BrutalCodeField takes, from the design kit, so an app (or a
// kit) reaches it through Brutal.
export 'package:ui_core/ui_core.dart' show RawOtpController;

/// A glyph button that stands inside a field's box: 32 px square, ink with
/// paper glyph under a press, the inset focus rule on the keyboard's.
///
/// Reads [style]'s `foreground` (the glyph at rest) and `iconSize`, then
/// [BrutalThemeData.textFieldStyle]'s, as the box it stands in does. A
/// press stays ink.
///
/// ```dart
/// BrutalFieldButton(icon: LucideIcons.x, semanticLabel: 'Clear', onPressed: controller.clear)
/// ```
class BrutalFieldButton extends StatelessWidget {
  /// A button of [icon] named [semanticLabel].
  const BrutalFieldButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.style,
  });

  /// The glyph.
  final IconData icon;

  /// What a screen reader calls it.
  final String semanticLabel;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// Its style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    return TapTargetPadding(
      child: RawButton(
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        builder: (context, states, _) {
          final pressed = states.contains(WidgetState.pressed);
          final layered = DesignStyleOf([style, theme.textFieldStyle], states);
          final glyph = states.contains(WidgetState.disabled)
              ? c.disabled
              : pressed
              ? c.paper
              : layered.foreground ?? c.ink;
          return SizedBox.square(
            dimension: 32,
            child: CustomPaint(
              foregroundPainter: states.contains(WidgetState.focused)
                  ? BrutalInsetFocusPainter(pressed ? c.paper : c.ink)
                  : null,
              child: ColoredBox(
                color: pressed ? c.ink : c.ink.withValues(alpha: 0),
                child: Center(
                  child: Icon(icon, size: layered.iconSize ?? 20, color: glyph),
                ),
              ),
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
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A search box: the field with a magnifier at its start and, once it holds
/// words, a button that clears them. A screen reader hears a search field.
///
/// Reads [style] as [BrutalTextField] does, then
/// [BrutalThemeData.textFieldStyle].
///
/// ```dart
/// BrutalSearchField(hint: 'Events, venues, who is on', onChanged: (q) => setState(() => query = q))
/// ```
class BrutalSearchField extends StatefulWidget {
  /// A search field.
  const BrutalSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.semanticLabel,
    this.clearLabel = 'Clear search',
    this.onEditingComplete,
    this.decorate,
    this.style,
  });

  /// The words searched for. Yours to dispose; given none, it makes its own.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words over the box.
  final String? label;

  /// The grey words in the empty box.
  final String hint;

  /// Called on every edit, and with '' when cleared.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's search key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Whether it takes input.
  final bool enabled;

  /// What a screen reader calls it when [label] is not the name; the hint
  /// otherwise.
  final String? semanticLabel;

  /// The clear button's name (pass it in the app's language).
  final String clearLabel;

  /// Called when the search key finishes the edit, in place of the
  /// platform's.
  final VoidCallback? onEditingComplete;

  /// Wraps the editable in your own semantics in place of the field's name
  /// ([BrutalTextField.decorate]).
  final Widget Function(Widget input)? decorate;

  /// The box's style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  @override
  State<BrutalSearchField> createState() => _BrutalSearchFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(StringProperty('clearLabel', clearLabel))
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        ObjectFlagProperty<Widget Function(Widget input)>.has(
          'decorate',
          decorate,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _BrutalSearchFieldState extends State<BrutalSearchField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(BrutalSearchField old) {
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

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) => BrutalTextField(
    controller: _controller,
    focusNode: widget.focusNode,
    label: widget.label,
    hint: widget.hint,
    semanticLabel: widget.semanticLabel ?? widget.label ?? widget.hint,
    prefixIcon: const Icon(LucideIcons.search),
    textInputAction: TextInputAction.search,
    autofocus: widget.autofocus,
    enabled: widget.enabled,
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    onEditingComplete: widget.onEditingComplete,
    decorate: widget.decorate,
    style: widget.style,
    suffix: _controller.text.isEmpty
        ? null
        : BrutalFieldButton(
            icon: LucideIcons.x,
            semanticLabel: widget.clearLabel,
            onPressed: widget.enabled ? _clear : null,
            style: widget.style,
          ),
  );
}

/// A password: the field with its words hidden and an eye button at its end
/// that shows them.
///
/// Reads [style] as [BrutalTextField] does, then
/// [BrutalThemeData.textFieldStyle].
///
/// ```dart
/// const BrutalPasswordField(label: 'Password', helper: 'At least 12 characters')
/// ```
class BrutalPasswordField extends StatelessWidget {
  /// A password field.
  const BrutalPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.revealLabels,
    this.onEditingComplete,
    this.decorate,
    this.failureLine,
    this.style,
  });

  /// The password. Yours to dispose; given none, the field makes its own.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words over the box.
  final String? label;

  /// The grey words in the empty box.
  final String? hint;

  /// Help under the box.
  final String? helper;

  /// What is wrong, under the box in red.
  final String? error;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// What autofill may offer: a saved password, or a new one.
  final Iterable<String>? autofillHints;

  /// Formatters run on every edit.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether it takes input.
  final bool enabled;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// The eye button's names while the words are hidden and shown, in that
  /// order (pass them in the app's language); null takes the design kit's.
  final (String show, String hide)? revealLabels;

  /// Wraps the editable in your own semantics in place of the field's name
  /// and hint (a form library that names, hints and announces its fields):
  /// the field then names nothing itself, so give the wrapper the name.
  final Widget Function(Widget input)? decorate;

  /// Wraps the drawn error line in place of its live region (a form library
  /// that announces the error itself).
  final Widget Function(Widget line)? failureLine;

  /// Called when the keyboard's action key finishes the edit, in place of
  /// the platform's (which lets go of the focus): move to the next field.
  final VoidCallback? onEditingComplete;

  /// The box's style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) => RawPasswordReveal(
    focusNode: focusNode,
    showLabel: revealLabels?.$1,
    hideLabel: revealLabels?.$2,
    builder: (context, password) => BrutalTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      helper: helper,
      error: error,
      obscureText: password.obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      decorate: decorate,
      failureLine: failureLine,
      enabled: enabled,
      autofocus: autofocus,
      style: style,
      suffix: BrutalFieldButton(
        icon: password.obscured ? LucideIcons.eye : LucideIcons.eyeOff,
        semanticLabel: password.toggleLabel,
        onPressed: enabled ? password.toggle : null,
        style: style,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
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
        DiagnosticsProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
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
        ObjectFlagProperty<List<TextInputFormatter>>.has(
          'inputFormatters',
          inputFormatters,
        ),
      )
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        ObjectFlagProperty<Widget Function(Widget input)>.has(
          'decorate',
          decorate,
        ),
      )
      ..add(
        ObjectFlagProperty<Widget Function(Widget line)>.has(
          'failureLine',
          failureLine,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A bare one-line entry for a box the look draws round it.
class _Entry extends StatelessWidget {
  const _Entry({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    this.hint,
    this.semanticLabel,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.layers = const [],
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final List<BrutalStyle?> layers;
  final String? hint;
  final String? semanticLabel;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Given, Enter keeps the keyboard in the entry (Flutter's TextField lets
  /// go of it otherwise).
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf(layers, {if (!enabled) WidgetState.disabled});
    final words = layered
        .text(theme.textTheme.body)
        .copyWith(color: enabled ? layered.foreground ?? c.ink : c.disabled);
    return DesignCapCenter(
      capHeightFactor: theme.capHeightFactor,
      child: DesignTextEntryBox(
        minHeight:
            (layered.minimumSize?.height ?? theme.controlHeight) -
            2 * theme.borderWidth,
        controller: controller,
        hint: hint == null
            ? null
            : Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: words.copyWith(color: c.inkMuted),
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
              cursorColor: c.ink,
              cursorWidth: 2,
              enabled: enabled,
              keyboardType: keyboardType,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onEditingComplete: onEditingComplete,
            ),
          ),
        ),
      ),
    );
  }
}

/// A field (or a select) and what stands round it, as one box's rules
/// shared: [before] and [after] are words in cells of their own (`https://`,
/// `.admit.events`, `kg`), apart from the entry on rules. A press anywhere
/// in the box puts the caret in it.
///
/// Reads [style]'s `fill` (the entry's ground), `edge`, `foreground` (the
/// words), `padding` (the entry's), `minimumSize` and `textStyle` in its
/// states, then [BrutalThemeData.textFieldStyle]'s. The add-on cells stay
/// paper with muted words.
///
/// ```dart
/// const BrutalInputGroup(label: 'Your page', before: 'https://', after: '.admit.events', hint: 'your-night')
/// ```
class BrutalInputGroup extends StatefulWidget {
  /// A field with add-on cells.
  const BrutalInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.before,
    this.after,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.style,
  });

  /// The words entered. Yours to dispose; given none, it makes its own.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words over the box.
  final String? label;

  /// The box's style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  /// The grey words in the empty entry.
  final String? hint;

  /// Help under the box.
  final String? helper;

  /// What is wrong, under the box in red.
  final String? error;

  /// The cell before the entry.
  final String? before;

  /// The cell after the entry.
  final String? after;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes input.
  final bool enabled;

  @override
  State<BrutalInputGroup> createState() => _BrutalInputGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      )
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(StringProperty('before', before, defaultValue: null))
      ..add(StringProperty('after', after, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'));
  }
}

class _BrutalInputGroupState extends State<BrutalInputGroup> {
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

  Widget _cell(BrutalThemeData theme, String words) => ExcludeSemantics(
    child: ColoredBox(
      color: theme.colors.paper,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BrutalSpacing.medium),
        child: Center(
          widthFactor: 1,
          child: DesignCapCenter(
            capHeightFactor: theme.capHeightFactor,
            child: Text(
              words,
              maxLines: 1,
              style: theme.textTheme.body.copyWith(
                color: widget.enabled
                    ? theme.colors.inkMuted
                    : theme.colors.disabled,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [widget.style, theme.textFieldStyle];
    final rest = DesignStyleOf(layers, {
      if (!widget.enabled) WidgetState.disabled,
      if (widget.error != null) WidgetState.error,
    });
    final rule =
        rest.side?.color ??
        rest.edge ??
        (!widget.enabled
            ? c.disabled
            : widget.error != null
            ? c.danger
            : c.ink);
    Widget split() => SizedBox(
      width: theme.borderWidth,
      child: ColoredBox(color: rule),
    );
    final semantic = [
      widget.label,
      widget.before,
      widget.after,
    ].whereType<String>().join(', ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: BrutalFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        DesignInputGroup(
          focusNode: _focus,
          enabled: widget.enabled,
          isError: widget.error != null,
          builder: (context, states, child) => AnimatedBrutalSurface(
            stiffness: BrutalMotion.colorStiffness,
            face: BrutalFace(
              fill: DesignStyleOf(layers, states).fill ?? c.surface,
              border: rule,
              foreground: c.ink,
              focus: states.contains(WidgetState.focused)
                  ? rule
                  : rule.withValues(alpha: 0),
            ),
            child: child,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.before != null) ...[
                  _cell(theme, widget.before!),
                  split(),
                ],
                Expanded(
                  child: Padding(
                    padding:
                        rest.padding(Directionality.of(context)) ??
                        const EdgeInsets.symmetric(
                          horizontal: BrutalSpacing.medium,
                        ),
                    child: _Entry(
                      controller: _controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      layers: layers,
                      hint: widget.hint,
                      semanticLabel: semantic.isEmpty ? null : semantic,
                      keyboardType: widget.keyboardType,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ),
                if (widget.after != null) ...[
                  split(),
                  _cell(theme, widget.after!),
                ],
              ],
            ),
          ),
        ),
        BrutalFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

/// A one-time code as a strip of square cells on shared rules, one a
/// character, over one real input: paste, a code from a text message and
/// Backspace work as in any field. The caret's cell carries a heavy bar at
/// its foot; [obscureText] shows a square for each character.
///
/// Reads [style]'s `fill`, `edge` (the box and the rules between cells),
/// `foreground` (the characters) and `textStyle` in its states, then
/// [BrutalThemeData.textFieldStyle]'s.
///
/// ```dart
/// BrutalCodeField(label: 'Code from your bank', onCompleted: (code) => verify(code))
/// ```
class BrutalCodeField extends StatefulWidget {
  /// A code of [length] characters.
  const BrutalCodeField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.label,
    this.helper,
    this.error,
    this.onChanged,
    this.onCompleted,
    this.autofocus = false,
    this.enabled = true,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.onEditingComplete,
    this.decorate,
    this.failureLine,
    this.style,
  });

  /// How many characters.
  final int length;

  /// The code. Yours to dispose; given none, it makes its own.
  final RawOtpController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words over the cells, and the field's name.
  final String? label;

  /// Help under the cells.
  final String? helper;

  /// What is wrong, under the cells in red.
  final String? error;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called once every cell holds a character.
  final ValueChanged<String>? onCompleted;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Whether it takes input.
  final bool enabled;

  /// Whether the characters are hidden.
  final bool obscureText;

  /// The keyboard's action key; null takes the platform's (done).
  final TextInputAction? textInputAction;

  /// Called with the code when the action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Called when the action key finishes the edit, in place of the
  /// platform's.
  final VoidCallback? onEditingComplete;

  /// Wraps the input in your own semantics in place of the field's name
  /// ([BrutalTextField.decorate]).
  final Widget Function(Widget input)? decorate;

  /// Wraps the drawn error line in place of its live region.
  final Widget Function(Widget line)? failureLine;

  /// The cells' style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  @override
  State<BrutalCodeField> createState() => _BrutalCodeFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(
        DiagnosticsProperty<RawOtpController>(
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
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onCompleted',
          onCompleted,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscureText'),
      )
      ..add(
        DiagnosticsProperty<TextInputAction>(
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
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        ObjectFlagProperty<Widget Function(Widget input)>.has(
          'decorate',
          decorate,
        ),
      )
      ..add(
        ObjectFlagProperty<Widget Function(Widget line)>.has(
          'failureLine',
          failureLine,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _BrutalCodeFieldState extends State<BrutalCodeField> {
  FocusNode? _ownFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(BrutalCodeField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_changed);
      if (widget.focusNode != null) {
        _ownFocus?.dispose();
        _ownFocus = null;
      }
      _focus.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf(
      [widget.style, theme.textFieldStyle],
      {
        if (!widget.enabled) WidgetState.disabled,
        if (widget.error != null) WidgetState.error,
        if (_focus.hasFocus) WidgetState.focused,
      },
    );
    final rule =
        layered.side?.color ??
        layered.edge ??
        (!widget.enabled
            ? c.disabled
            : widget.error != null
            ? c.danger
            : c.ink);
    final height = theme.controlHeight + BrutalSpacing.small;
    final decorate = widget.decorate;
    final otp = RawOtpField(
      length: widget.length,
      controller: widget.controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      isError: widget.error != null,
      obscureText: widget.obscureText,
      semanticLabel: decorate == null ? widget.label : null,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      layoutBuilder: (context, slots) => AnimatedBrutalSurface(
        stiffness: BrutalMotion.colorStiffness,
        face: BrutalFace(
          fill: layered.fill ?? c.surface,
          border: rule,
          foreground: c.ink,
          focus: _focus.hasFocus ? rule : rule.withValues(alpha: 0),
        ),
        child: SizedBox(
          height: height - 2 * theme.borderWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, slot) in slots.indexed) ...[
                if (i > 0)
                  SizedBox(
                    width: theme.borderWidth,
                    child: ColoredBox(color: rule),
                  ),
                slot,
              ],
            ],
          ),
        ),
      ),
      slotBuilder: (context, slot) {
        final ink = slot.enabled ? layered.foreground ?? c.ink : c.disabled;
        return SizedBox(
          width: 44,
          child: Stack(
            children: [
              Center(
                child: slot.character.isEmpty
                    ? null
                    : slot.obscured
                    ? SizedBox.square(
                        dimension: 12,
                        child: ColoredBox(color: ink),
                      )
                    : Text(
                        slot.character,
                        style: layered
                            .text(theme.textTheme.title)
                            .copyWith(color: ink),
                      ),
              ),
              if (slot.active && slot.focused)
                PositionedDirectional(
                  start: BrutalSpacing.small,
                  end: BrutalSpacing.small,
                  bottom: BrutalSpacing.small,
                  height: BrutalSpacing.tight,
                  child: ColoredBox(color: slot.isError ? c.danger : c.ink),
                ),
            ],
          ),
        );
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: BrutalFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        decorate?.call(otp) ?? otp,
        BrutalFieldMessage(
          helper: widget.helper,
          error: widget.error,
          failureLine: widget.failureLine,
        ),
      ],
    );
  }
}

/// The raised panel a field's suggestions stand on: a menu, so it reads
/// [BrutalThemeData.menuStyle]'s `fill` and `edge`.
Widget _suggestions(BuildContext context, Widget list) {
  final theme = BrutalTheme.of(context);
  final c = theme.colors;
  final panel = DesignStyleOf([theme.menuStyle], const {});
  final rule = panel.side?.color ?? panel.edge ?? c.ink;
  // As the select's list: the rule is drawn over the panel, so the panel is
  // the field's width from the field's edge as drawn too; its rows stand
  // inside the rule.
  return BrutalSurface(
    face: BrutalFace(
      fill: panel.fill ?? c.surface,
      border: rule,
      foreground: c.ink,
      shadow: c.ink,
      borderWidth: 0,
    ),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: rule, width: theme.borderWidth),
      ),
      child: Padding(padding: EdgeInsets.all(theme.borderWidth), child: list),
    ),
  );
}

/// What the suggestions say when nothing matches.
Widget _nothing(BuildContext context, String words) {
  final theme = BrutalTheme.of(context);
  // The field's width, as the list it stands in for (the suggestions' room is
  // the field's).
  return SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.all(BrutalSpacing.medium),
      child: Text(words, style: theme.textTheme.secondary),
    ),
  );
}

// A search's line where the rows would stand: [lead], then [words].
Widget _searchLine(BuildContext context, Widget lead, String words) {
  final theme = BrutalTheme.of(context);
  return SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.all(BrutalSpacing.medium),
      child: Row(
        children: [
          lead,
          const SizedBox(width: BrutalSpacing.medium),
          Expanded(child: Text(words, style: theme.textTheme.secondary)),
        ],
      ),
    ),
  );
}

/// What the suggestions say while a search runs: a small spinner and
/// "Loading".
Widget _searching(BuildContext context) => _searchLine(
  context,
  const BrutalSpinner(size: 16),
  RawWidgetsLocalizations.of(context).loadingLabel,
);

/// What the suggestions say when a search failed: the failure, then "Try
/// again" as a row, lit while the keys are on it (ui_core moves them there on
/// Down), run by Enter or a press.
Widget _failed(BuildContext context, RawSearchError failed) {
  final theme = BrutalTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _searchLine(
        context,
        Icon(LucideIcons.circleAlert, size: 16, color: theme.colors.danger),
        words.searchFailedMessage,
      ),
      SizedBox(
        height: theme.borderWidth,
        child: ColoredBox(color: theme.colors.ink),
      ),
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: failed.retry,
          child: BrutalMenuRow(
            label: words.retryButtonLabel,
            icon: LucideIcons.rotateCw,
            states: {if (failed.focused) WidgetState.focused},
          ),
        ),
      ),
    ],
  );
}

/// A field that suggests: typing narrows a list of [options] dropped under
/// it; the arrows move through it and Enter takes one. With
/// [requireSelection] the words go back to the chosen option when the field
/// is left.
///
/// With [search] the options come from a search that may take time and
/// fail (a server's): it runs once typing rests for [debounceDuration], the
/// list says "Loading" by a small spinner while it runs, and a failed one
/// says so over a "Try again" row that Down reaches and Enter or a press
/// runs, the keyboard staying in the field; only the latest words' result
/// shows. The behaviour is ui_core's ([RawCombobox]).
///
/// The box reads [style] as [BrutalTextField] does, then
/// [BrutalThemeData.textFieldStyle]; the list reads
/// [BrutalThemeData.menuStyle], as every menu does.
///
/// ```dart
/// BrutalCombobox<String>(label: 'Venue', options: venues, labelOf: (v) => v, value: venue, onSelected: (v) => setState(() => venue = v))
/// ```
class BrutalCombobox<T extends Object> extends StatelessWidget {
  /// A combobox over [options].
  const BrutalCombobox({
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

  /// Finds the options for the words typed, in place of filtering
  /// [options]: a future for a search that takes time, which may fail.
  final DesignOptionSearch<T>? search;

  /// How long typing rests before [search] runs; null runs it at every
  /// letter.
  final Duration? debounceDuration;

  /// Each option's words.
  final String Function(T option) labelOf;

  /// Whether an option may be taken; a disabled option stands grey in the
  /// list, the keys pass it by and neither a press nor Enter takes it.
  final bool Function(T option)? isOptionEnabled;

  /// The option chosen.
  final T? value;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// The words over the box.
  final String? label;

  /// The grey words in the empty box.
  final String? hint;

  /// Help under the box.
  final String? helper;

  /// What is wrong, under the box in red.
  final String? error;

  /// What the list says when nothing matches.
  final String emptyText;

  /// Whether only an option may stand in the box.
  final bool requireSelection;

  /// Whether it takes input.
  final bool enabled;

  /// The box's style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (label != null)
        ExcludeSemantics(child: BrutalFieldLabel(label!, enabled: enabled)),
      RawCombobox<T>(
        options: options,
        search: search,
        debounceDuration: debounceDuration,
        displayStringForOption: labelOf,
        value: value,
        onSelected: onSelected,
        requireSelection: requireSelection,
        isOptionEnabled: isOptionEnabled,
        // The pointer's row is the keys' row: Brutal draws both the same
        // way, so two would read as two current options.
        highlightFollowsPointer: true,
        semanticLabel: label,
        fieldBuilder: (context, field) => BrutalTextField(
          controller: field.controller,
          focusNode: field.focusNode,
          hint: hint,
          error: error == null ? null : '',
          semanticLabel: label,
          enabled: enabled,
          style: style,
          // Enter in onEditingComplete alone: the field keeps the keyboard, and
          // with no onSubmitted Flutter does not restart its text input (a
          // browser's restarted input takes no typing).
          onEditingComplete: field.submit,
          suffix: ExcludeSemantics(
            child: Icon(
              LucideIcons.chevronsUpDown,
              size: 20,
              color: enabled
                  ? BrutalTheme.of(context).colors.ink
                  : BrutalTheme.of(context).colors.disabled,
            ),
          ),
        ),
        optionBuilder: (context, option, states) => BrutalMenuRow(
          label: labelOf(option),
          states: states,
          checked: states.contains(WidgetState.selected),
        ),
        surfaceBuilder: _suggestions,
        emptyBuilder: (context) => _nothing(context, emptyText),
        loadingBuilder: _searching,
        errorBuilder: _failed,
      ),
      BrutalFieldMessage(helper: helper, error: error),
    ],
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<DesignOptionSearch<T>>.has('search', search))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// Values as tags in one box, with a field after them that suggests from
/// [options] (and, given [onCreate], makes a new value of its words on
/// Enter or a comma). Each tag is a ruled cell with a cross that removes
/// it; Backspace in the empty field takes the last.
///
/// With [search] the suggestions come from a search that may take time and
/// fail, as [BrutalCombobox]'s: "Loading" while it runs, a failure with
/// "Try again" when it fails.
///
/// The box reads [style]'s `fill`, `edge`, `foreground` (the field's words)
/// and `textStyle` in its states, then [BrutalThemeData.textFieldStyle]'s;
/// the suggestions read [BrutalThemeData.menuStyle]. The tags stay paper
/// cells, ink while focused.
///
/// ```dart
/// BrutalTagInput<String>(label: 'Kinds of night', values: kinds, options: allKinds, labelOf: (k) => k, onChanged: (next) => setState(() => kinds = next))
/// ```
class BrutalTagInput<T extends Object> extends StatefulWidget {
  /// Tags over [values].
  const BrutalTagInput({
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
    this.style,
  });

  /// Whether an option may be taken; a disabled option stands grey among the
  /// suggestions, the keys pass it by and neither a press nor Enter takes it.
  final bool Function(T option)? isOptionEnabled;

  /// The values chosen, as tags.
  final List<T> values;

  /// Called with the new list.
  final ValueChanged<List<T>> onChanged;

  /// What the field suggests, when there is no [search].
  final Iterable<T> options;

  /// Finds the suggestions for the words typed, in place of filtering
  /// [options]: a future for a search that takes time, which may fail.
  final DesignOptionSearch<T>? search;

  /// How long typing rests before [search] runs; null runs it at every
  /// letter.
  final Duration? debounceDuration;

  /// Each value's words.
  final String Function(T value) labelOf;

  /// Makes a value of words that match no option; null: only options.
  final T? Function(String text)? onCreate;

  /// The words over the box.
  final String? label;

  /// The grey words in the empty field.
  final String? hint;

  /// Help under the box.
  final String? helper;

  /// What is wrong, under the box in red.
  final String? error;

  /// The most tags it holds.
  final int? maxTags;

  /// Whether it takes input.
  final bool enabled;

  /// The box's style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  @override
  State<BrutalTagInput<T>> createState() => _BrutalTagInputState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<List<T>>>.has('onChanged', onChanged),
      )
      ..add(IterableProperty<T>('options', options))
      ..add(ObjectFlagProperty<DesignOptionSearch<T>>.has('search', search))
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<String Function(T value)>.has('labelOf', labelOf),
      )
      ..add(
        ObjectFlagProperty<T? Function(String text)>.has('onCreate', onCreate),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(IntProperty('maxTags', maxTags, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _BrutalTagInputState<T extends Object> extends State<BrutalTagInput<T>> {
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
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [widget.style, theme.textFieldStyle];
    final layered = DesignStyleOf(layers, {
      if (!widget.enabled) WidgetState.disabled,
      if (widget.error != null) WidgetState.error,
      if (_focus.hasFocus) WidgetState.focused,
    });
    final rule =
        layered.side?.color ??
        layered.edge ??
        (!widget.enabled
            ? c.disabled
            : widget.error != null
            ? c.danger
            : c.ink);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: BrutalFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        RawTagInput<T>(
          values: widget.values,
          onChanged: widget.onChanged,
          options: widget.options,
          search: widget.search,
          debounceDuration: widget.debounceDuration,
          displayStringForOption: widget.labelOf,
          onCreate: widget.onCreate,
          maxTags: widget.maxTags,
          isOptionEnabled: widget.isOptionEnabled,
          // As the combobox's: the pointer's row is the keys' row.
          highlightFollowsPointer: true,
          focusNode: _focus,
          semanticLabel: widget.label,
          layoutBuilder: (context, tags, field) => MouseRegion(
            cursor: SystemMouseCursors.text,
            // A press anywhere in the box focuses the entry: the pointer's
            // convenience, no button to a screen reader, which focuses the
            // entry itself.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.enabled ? _focus.requestFocus : null,
              child: AnimatedBrutalSurface(
                stiffness: BrutalMotion.colorStiffness,
                face: BrutalFace(
                  fill: layered.fill ?? c.surface,
                  border: rule,
                  foreground: c.ink,
                  focus: _focus.hasFocus ? rule : rule.withValues(alpha: 0),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: BrutalSpacing.small,
                    end: BrutalSpacing.small,
                  ),
                  child: Wrap(
                    spacing: BrutalSpacing.small,
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
          fieldBuilder: (context, field) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BrutalSpacing.tight,
            ),
            child: _Entry(
              controller: field.controller,
              focusNode: field.focusNode,
              enabled: widget.enabled,
              layers: layers,
              hint: widget.values.isEmpty ? widget.hint : null,
              semanticLabel: widget.label,
              // Enter takes a tag and leaves the keyboard here for the next,
              // in onEditingComplete alone: with onSubmitted too, Flutter
              // restarts the text input, and a browser's restarted input
              // takes no typing.
              onEditingComplete: field.submit,
            ),
          ),
          tagBuilder: (context, value, tag) => _Tag(
            label: widget.labelOf(value),
            focused: tag.focused,
            enabled: widget.enabled,
            onDeleted: tag.onDeleted,
          ),
          optionBuilder: (context, option, states) => BrutalMenuRow(
            label: widget.labelOf(option),
            states: states,
            checked: states.contains(WidgetState.selected),
          ),
          surfaceBuilder: _suggestions,
          loadingBuilder: _searching,
          errorBuilder: _failed,
        ),
        BrutalFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.focused,
    required this.enabled,
    required this.onDeleted,
  });

  final String label;
  final bool focused;
  final bool enabled;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final words = !enabled
        ? c.disabled
        : focused
        ? c.paper
        : c.ink;
    final rule = enabled ? c.ink : c.disabled;
    // The face is 28 tall in the field's 44; the cross's target is the
    // whole 44 square at the chip's end, over its cell and the label's end.
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          AnimatedBrutalSurface(
            stiffness: BrutalMotion.colorStiffness,
            face: BrutalFace(
              fill: focused ? c.ink : c.paper,
              border: rule,
              foreground: words,
            ),
            child: SizedBox(
              height: 28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: BrutalSpacing.small,
                      end: BrutalSpacing.medium,
                    ),
                    child: DesignCapCenter(
                      capHeightFactor: theme.capHeightFactor,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.label.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          color: words,
                        ),
                      ),
                    ),
                  ),
                  BrutalRule(vertical: true, color: rule),
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: Icon(LucideIcons.x, size: 16, color: words),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: 44,
            child: RawButton(
              onPressed: enabled ? onDeleted : null,
              semanticLabel: 'Remove $label',
              builder: (context, states, _) => const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label, help and an error round any [child] that is not a field of the
/// look's own (a segmented choice, a group of radios, a slider): the label
/// 8 px over it, the help or the error 8 px under it. A screen reader hears
/// the label as the control's name and the help or the error with it. A
/// child of one control (a slider, a switch) is one node named by the label;
/// a child of several (a stepper's buttons and number, segments, chips,
/// radios) keeps each control's own node, so a tap through the semantics
/// tree reaches the one under it, and the label names them as a group.
///
/// A layout with no face of its own: its label reads
/// [BrutalThemeData.fieldLabelStyle] and its message
/// [BrutalThemeData.fieldMessageStyle].
///
/// ```dart
/// BrutalFormField(labelText: 'Seats', helperText: 'Standing has no seat number', child: BrutalSegmentedButton<String>(segments: const [BrutalSegment(value: 'stalls', label: 'Stalls'), BrutalSegment(value: 'standing', label: 'Standing')], value: area, onChanged: (value) => setState(() => area = value)))
/// ```
class BrutalFormField extends StatelessWidget {
  /// [child] with its label, help and error.
  const BrutalFormField({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.mergeSemantics,
  });

  /// The control.
  final Widget child;

  /// The label over it.
  final String? labelText;

  /// Help under it.
  final String? helperText;

  /// What is wrong, under it in red; null when nothing.
  final String? errorText;

  /// Whether it must be answered: the label says so.
  final bool required;

  /// Whether the control is on; off, the label is grey.
  final bool enabled;

  /// Whether the label, help and error join the control's own node: true
  /// always (one node for the whole child), false never (the label names
  /// the child as a group), null (the default) as the child's controls say:
  /// one control joins, several keep their own nodes.
  final bool? mergeSemantics;

  @override
  Widget build(BuildContext context) => RawInputDecorator(
    labelText: labelText,
    helperText: helperText,
    errorText: errorText,
    required: required,
    enabled: enabled,
    mergeSemantics: mergeSemantics,
    builder: (context, parts) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labelText != null)
          ExcludeSemantics(
            child: BrutalFieldLabel(
              required ? '$labelText (required)' : labelText!,
              enabled: enabled,
            ),
          ),
        parts.control,
        ExcludeSemantics(
          child: BrutalFieldMessage(helper: helperText, error: errorText),
        ),
      ],
    ),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(
        DiagnosticsProperty<bool>(
          'mergeSemantics',
          mergeSemantics,
          defaultValue: null,
        ),
      );
  }
}
