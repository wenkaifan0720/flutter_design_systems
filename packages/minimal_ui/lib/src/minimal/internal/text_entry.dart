import 'package:cupertino_ui/cupertino_ui.dart'
    show
        cupertinoDesktopTextSelectionHandleControls,
        cupertinoTextSelectionHandleControls;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import '../theme.dart';
import 'field.dart';

/// The one way Minimal uses Flutter's `TextField`: the look draws the box
/// (its rim, fill, ring, side air and a minimum height from a control's
/// height), and the editable inside it is bare, exactly one line of text
/// tall, placed by alignment. A line then stands where the look put it under
/// any configuration: the platform's density, Material 2 or 3, larger text,
/// or an app's own `InputDecorationTheme` between the look and the field.
///
/// Its decoration is collapsed, with every field that could size or draw it
/// set, so no theme default reaches it: no padding, no borders, no fill,
/// standard density (a collapsed decorator nets the density's offset to zero
/// only when it is negative) and no constraints (an unset one takes the
/// theme's). Icons, buttons, add-ons, counters, help and error are the
/// look's own widgets beside or under the box, never the decoration's. The
/// caret is the theme's primary, [MinimalFieldMetrics.cursor] wide, and the
/// handles are [minimalSelectionControls]. The rest is `TextField`'s.
class MinimalBareTextField extends StatelessWidget {
  /// A bare field showing [hint] in [hintStyle] while empty.
  const MinimalBareTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.style,
    this.hint,
    this.hintStyle,
    this.hintMaxLines,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.autofillHints = const <String>[],
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
  });

  /// The text, as `TextField.controller`.
  final TextEditingController? controller;

  /// The focus, as `TextField.focusNode`.
  final FocusNode? focusNode;

  /// The typed text's style.
  final TextStyle? style;

  /// The words shown while the field is empty.
  final String? hint;

  /// The [hint]'s style.
  final TextStyle? hintStyle;

  /// Caps the hint's lines. A one-line box gives 1: Flutter keeps the box at
  /// the hint's height once text is typed, so a hint that wraps would hold
  /// the box at two lines and leave the typed line at its top.
  final int? hintMaxLines;

  /// As `TextField.enabled`.
  final bool enabled;

  /// As `TextField.readOnly`.
  final bool readOnly;

  /// As `TextField.autofocus`.
  final bool autofocus;

  /// As `TextField.keyboardType`.
  final TextInputType? keyboardType;

  /// As `TextField.textInputAction`.
  final TextInputAction? textInputAction;

  /// As `TextField.textCapitalization`.
  final TextCapitalization textCapitalization;

  /// As `TextField.autocorrect`.
  final bool autocorrect;

  /// As `TextField.enableSuggestions`.
  final bool enableSuggestions;

  /// As `TextField.obscureText`.
  final bool obscureText;

  /// As `TextField.maxLines`.
  final int? maxLines;

  /// As `TextField.minLines`.
  final int? minLines;

  /// As `TextField.inputFormatters`.
  final List<TextInputFormatter>? inputFormatters;

  /// As `TextField.autofillHints`.
  final Iterable<String>? autofillHints;

  /// As `TextField.onChanged`.
  final ValueChanged<String>? onChanged;

  /// As `TextField.onSubmitted`.
  final ValueChanged<String>? onSubmitted;

  /// As `TextField.onEditingComplete`.
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    selectionControls: minimalSelectionControls(context),
    focusNode: focusNode,
    enabled: enabled,
    readOnly: readOnly,
    autofocus: autofocus,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    textCapitalization: textCapitalization,
    autocorrect: autocorrect,
    enableSuggestions: enableSuggestions,
    obscureText: obscureText,
    maxLines: maxLines,
    minLines: minLines,
    inputFormatters: inputFormatters,
    autofillHints: autofillHints,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    onEditingComplete: onEditingComplete,
    cursorColor: context.minimalTheme.primary,
    cursorWidth: MinimalFieldMetrics.cursor,
    style: style,
    decoration: InputDecoration(
      isCollapsed: true,
      isDense: false,
      contentPadding: EdgeInsets.zero,
      hintText: hint,
      hintStyle: hintStyle,
      hintMaxLines: hintMaxLines,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(),
    ),
  );
}

/// The height one line of [style] takes at the text scale in [context]: the
/// look's styles set a line height and even leading, so a line's box is its
/// scaled size times its height.
double minimalLineHeight(BuildContext context, TextStyle style) =>
    MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
    (style.height ?? 1);

/// The air above and below a field's text inside its rims so that a first
/// line of [line] stands where a single line does in a box [height] tall
/// with [rim]s: half of what the line leaves, never under [least]. One line
/// in such a box is centred by alignment; this places the first of several.
double minimalLineAir({
  required double height,
  required double rim,
  required double line,
  double least = 0,
}) {
  final air = (height - line) / 2 - rim;
  return air < least ? least : air;
}

/// The platform's selection handles, as `TextField` picks them for
/// `selectionControls: null` (Material's on Android, Cupertino's on iOS, the
/// desktops' own, which draw none), with one change: a handle the field
/// hides takes no tap. Flutter keeps a focused field's handles in the
/// overlay while hidden, faded to nothing, and the drop under its caret
/// still took a tap, so a tap on the top of the field below a focused one
/// (a form's next line) went to a handle no one could see.
TextSelectionControls minimalSelectionControls(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.iOS => _iosHandles,
      TargetPlatform.macOS => _macHandles,
      TargetPlatform.android || TargetPlatform.fuchsia => _materialHandles,
      TargetPlatform.linux || TargetPlatform.windows => _desktopHandles,
    };

final TextSelectionControls _iosHandles = _ShownHandles(
  cupertinoTextSelectionHandleControls,
);
final TextSelectionControls _macHandles = _ShownHandles(
  cupertinoDesktopTextSelectionHandleControls,
);
final TextSelectionControls _materialHandles = _ShownHandles(
  materialTextSelectionHandleControls,
);
final TextSelectionControls _desktopHandles = _ShownHandles(
  desktopTextSelectionHandleControls,
);

/// [platform]'s handles, each taking taps only while it shows.
class _ShownHandles extends TextSelectionControls
    with TextSelectionHandleControls {
  _ShownHandles(this.platform);

  final TextSelectionControls platform;

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => _WhileShown(
    child: platform.buildHandle(context, type, textLineHeight, onTap),
  );

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      platform.getHandleAnchor(type, textLineHeight);

  @override
  Size getHandleSize(double textLineHeight) =>
      platform.getHandleSize(textLineHeight);
}

/// [child], ignoring the pointer while the fade Flutter shows and hides a
/// handle with stands at nothing.
class _WhileShown extends StatelessWidget {
  const _WhileShown({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = context.findAncestorWidgetOfExactType<FadeTransition>();
    if (fade == null) return child;
    return ValueListenableBuilder<double>(
      valueListenable: fade.opacity,
      builder: (context, opacity, child) =>
          IgnorePointer(ignoring: opacity == 0, child: child),
      child: child,
    );
  }
}
