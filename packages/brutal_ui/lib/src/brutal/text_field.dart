/// Brutal's text entry: [BrutalTextField], a square box in the rule with its
/// label above and its help or error below, and [BrutalFieldLabel] and
/// [BrutalFieldMessage], the two lines every field and select shares.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import 'surface.dart';
import 'theme.dart';

/// A field's label: 14 px, semibold, 8 px above its box.
///
/// Reads [style]'s `foreground`, `padding` and `textStyle`, then
/// [BrutalThemeData.fieldLabelStyle]'s.
///
/// ```dart
/// const BrutalFieldLabel('Email')
/// ```
class BrutalFieldLabel extends StatelessWidget {
  /// The label [text].
  const BrutalFieldLabel(
    this.text, {
    super.key,
    this.enabled = true,
    this.style,
  });

  /// The words.
  final String text;

  /// Whether the field it names is on; off, it is grey.
  final bool enabled;

  /// Its style, over [BrutalThemeData.fieldLabelStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final layered = DesignStyleOf(
      [style, theme.fieldLabelStyle],
      {if (!enabled) WidgetState.disabled},
    );
    return Padding(
      padding:
          layered.padding(Directionality.of(context)) ??
          const EdgeInsets.only(bottom: BrutalSpacing.small),
      child: Text(
        text,
        style: layered.text(
          theme.textTheme.label.copyWith(
            fontSize: 14,
            height: 20 / 14,
            color:
                layered.foreground ??
                (enabled ? theme.colors.ink : theme.colors.disabled),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// The line under a field: its help in the muted ink, or its error in the
/// danger colour after a square mark. The error is announced as it appears.
///
/// Reads [style]'s `foreground` (in the error state for an error),
/// `padding` and `textStyle`, then [BrutalThemeData.fieldMessageStyle]'s.
///
/// ```dart
/// const BrutalFieldMessage(error: 'Enter the card number')
/// ```
class BrutalFieldMessage extends StatelessWidget {
  /// Help or an error; the error wins.
  const BrutalFieldMessage({
    super.key,
    this.helper,
    this.error,
    this.failureLine,
    this.style,
  });

  /// The help.
  final String? helper;

  /// The error.
  final String? error;

  /// Wraps the error line in place of its live region (a form library that
  /// announces the error itself).
  final Widget Function(Widget line)? failureLine;

  /// Its style, over [BrutalThemeData.fieldMessageStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf(
      [this.style, theme.fieldMessageStyle],
      {if (error != null) WidgetState.error},
    );
    final style = layered.text(theme.textTheme.secondary);
    final padding =
        layered.padding(Directionality.of(context)) ??
        const EdgeInsets.only(top: BrutalSpacing.small);
    if (error != null) {
      // An empty error marks the box alone; its words stand elsewhere.
      if (error!.isEmpty) return const SizedBox.shrink();
      final danger = layered.foreground ?? c.danger;
      final line = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // The mark centred on the first line.
            padding: EdgeInsets.only(
              top:
                  ((style.fontSize ?? 14) * (style.height ?? 1) -
                      BrutalSpacing.small) /
                  2,
            ),
            child: SizedBox.square(
              dimension: BrutalSpacing.small,
              child: ColoredBox(color: danger),
            ),
          ),
          const SizedBox(width: BrutalSpacing.small),
          Expanded(
            child: Text(error!, style: style.copyWith(color: danger)),
          ),
        ],
      );
      return Padding(
        padding: padding,
        child:
            failureLine?.call(line) ?? Semantics(liveRegion: true, child: line),
      );
    }
    if (helper != null) {
      return Padding(
        padding: padding,
        child: Text(helper!, style: style.copyWith(color: layered.foreground)),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
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

/// A one-line (or, with [maxLines], several-line) text field: a square box
/// in the look's rule, its [label] above, its [helper] or [error] below. A
/// focused field gets the look's focus rule, a second square line 2 px
/// outside its box; an error turns the rule red.
///
/// The box is drawn by the look and the editable inside is bare (no
/// decoration), so a line stands at the box's middle whatever the platform's
/// density or the app's `InputDecorationTheme`.
///
/// Reads [style]'s `fill`, `edge`, `foreground` (the words), `minimumSize`
/// (the box's least height) and `textStyle`, in its states (focused,
/// error, disabled), then [BrutalThemeData.textFieldStyle]'s. Its label and
/// message read [BrutalThemeData.fieldLabelStyle] and
/// [BrutalThemeData.fieldMessageStyle].
///
/// ```dart
/// BrutalTextField(label: 'Email', hint: 'you@example.com', keyboardType: TextInputType.emailAddress, onChanged: (value) => email = value)
/// ```
class BrutalTextField extends StatefulWidget {
  /// A text field.
  const BrutalTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textDirection,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.semanticLabel,
    this.onEditingComplete,
    this.decorate,
    this.failureLine,
    this.style,
  });

  /// The text being edited. Yours to dispose; given none, the field makes
  /// its own and disposes it.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The words over the box.
  final String? label;

  /// Grey words in the empty box: a format or an example, never the label.
  final String? hint;

  /// Help under the box.
  final String? helper;

  /// What is wrong with the text, under the box in red; null when nothing.
  /// An empty string turns the rule red and says nothing under it, for a
  /// field whose error stands elsewhere.
  final String? error;

  /// A glyph at the box's start.
  final Widget? prefixIcon;

  /// A widget at the box's end: a unit, a reveal button.
  final Widget? suffix;

  /// Whether the text is hidden (a password).
  final bool obscureText;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// The direction its words and hint run in, as `TextField.textDirection`;
  /// null follows the app's. A card number, a code or a phone number runs
  /// left to right in a right-to-left app, so its groups keep their order.
  final TextDirection? textDirection;

  /// How the keyboard capitalises.
  final TextCapitalization textCapitalization;

  /// What autofill may offer.
  final Iterable<String>? autofillHints;

  /// Formatters run on every edit.
  final List<TextInputFormatter>? inputFormatters;

  /// Called on every edit with the new text.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key is pressed; the field then lets
  /// go of the focus. A field that keeps it takes the key in
  /// [onEditingComplete] instead: never both.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes input; off, its rule and words go grey.
  final bool enabled;

  /// Whether the text can be selected but not changed.
  final bool readOnly;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// The most lines it shows; 1 for one line, null for no limit.
  final int? maxLines;

  /// The fewest lines it shows.
  final int? minLines;

  /// What a screen reader calls it when [label] is not the right name.
  final String? semanticLabel;

  /// Wraps the editable in your own semantics in place of the field's name
  /// and hint (a form library that names, hints and announces its fields):
  /// the field then names nothing itself, so give the wrapper the name.
  final Widget Function(Widget input)? decorate;

  /// Wraps the drawn error line in place of its live region (a form library
  /// that announces the error itself).
  final Widget Function(Widget line)? failureLine;

  /// Called when the keyboard's action key finishes the edit, in place of
  /// the platform's (which lets go of the focus): move to the next field, or
  /// add what was typed and stay for the next. Give such a field no
  /// [onSubmitted]: with both, Flutter restarts the text input of a field
  /// that keeps the focus, and in a browser the typing then goes nowhere.
  final VoidCallback? onEditingComplete;

  /// This field's style, over [BrutalThemeData.textFieldStyle].
  final BrutalStyle? style;

  @override
  State<BrutalTextField> createState() => _BrutalTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'))
      ..add(
        EnumProperty<TextDirection>(
          'textDirection',
          textDirection,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1));
  }
}

class _BrutalTextFieldState extends State<BrutalTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(BrutalTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_changed);
      if (widget.focusNode != null) {
        _ownFocus?.dispose();
        _ownFocus = null;
      }
      _focus.addListener(_changed);
    }
    if (old.controller != widget.controller && widget.controller != null) {
      _ownController?.dispose();
      _ownController = null;
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _ownFocus?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (_focus.hasFocus) WidgetState.focused,
      if (widget.error != null) WidgetState.error,
    };
    final layered = DesignStyleOf([widget.style, theme.textFieldStyle], states);
    final words = theme.textTheme.body
        .merge(layered.textStyle)
        .copyWith(
          color: layered.foreground ?? (widget.enabled ? c.ink : c.disabled),
        );
    final oneLine = widget.maxLines == 1;
    final face = BrutalFace(
      fill: layered.fill ?? c.surface,
      border:
          layered.side?.color ??
          layered.edge ??
          (!widget.enabled
              ? c.disabled
              : widget.error != null
              ? c.danger
              : c.ink),
      foreground: words.color!,
      focus: _focus.hasFocus
          ? (widget.error != null ? c.danger : c.ink)
          : c.ink.withValues(alpha: 0),
    );
    final rule = theme.borderWidth;
    // The field's name stands round the whole entry box, the control's full
    // height (its rule is drawn behind it, not round it), so the field a
    // screen reader outlines, and a finger finds, is the box.
    final Widget entryBox = DesignTextEntryBox(
      minHeight: layered.minimumSize?.height ?? theme.controlHeight,
      controller: _controller,
      maxLines: widget.maxLines,
      hint: widget.hint == null
          ? null
          : Text(
              widget.hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: words.copyWith(color: c.inkMuted),
            ),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: null,
          style: words,
          cursorColor: c.ink,
          cursorWidth: 2,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
        ),
      ),
    );
    final entry = _named(
      widget.textDirection == null
          ? entryBox
          : Directionality(
              textDirection: widget.textDirection!,
              child: entryBox,
            ),
    );
    // A tap anywhere in the box focuses the words; the words' own node, the
    // box's whole height, says what the field is and takes a reader's tap.
    final box = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBrutalSurface(
                face: face,
                stiffness: BrutalMotion.colorStiffness,
                child: const SizedBox.expand(),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: rule),
              child: IconTheme.merge(
                data: IconThemeData(color: face.foreground),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: face.foreground),
                  child: Row(
                    crossAxisAlignment: oneLine
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      if (widget.prefixIcon != null)
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: BrutalSpacing.medium,
                            top: oneLine ? 0 : BrutalSpacing.medium + rule,
                          ),
                          child: IconTheme.merge(
                            data: IconThemeData(
                              size: 20,
                              color: widget.enabled ? c.ink : c.disabled,
                            ),
                            child: widget.prefixIcon!,
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BrutalSpacing.medium,
                          ),
                          child: oneLine
                              ? DesignCapCenter(
                                  capHeightFactor: BrutalTheme.of(context)
                                      .capHeightFactor,
                                  child: entry,
                                )
                              : entry,
                        ),
                      ),
                      if (widget.suffix != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: BrutalSpacing.medium,
                          ),
                          child: DefaultTextStyle(
                            style: theme.textTheme.secondary,
                            child: widget.suffix!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: BrutalFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        box,
        BrutalFieldMessage(
          helper: widget.helper,
          error: widget.error,
          failureLine: widget.failureLine,
        ),
      ],
    );
  }

  /// The entry box named by [BrutalTextField.decorate], else by the field,
  /// as a node of its own: the words' render object is no semantics
  /// boundary, so without one the field's name and flags land on whatever
  /// node holds it (a page's column, with its results under it).
  Widget _named(Widget editable) => Semantics(
    container: true,
    child:
        widget.decorate?.call(editable) ??
        Semantics(
          label: widget.semanticLabel ?? widget.label,
          hint: widget.hint,
          child: editable,
        ),
  );
}
