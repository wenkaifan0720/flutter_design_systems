import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

/// A box to search with: a [CivicTextField] under its label with the search
/// button joined at its end, square, in the action colour, a magnifier on
/// it. The button and the keyboard's search key both search: [onSubmitted]
/// is called with the words.
///
/// The label says what is searched ("Search permits"); null says "Search"
/// in the reader's language.
///
/// Its box reads [CivicStyle] as [CivicTextField] does: [style], then
/// [CivicThemeData.textFieldStyle]. Its button reads fill and foreground
/// by state (pressed, disabled): [buttonStyle], then
/// [CivicThemeData.searchButtonStyle]; its size and the focus plate are
/// the look's.
///
/// ```dart
/// CivicSearchField(
///   labelText: 'Search applications',
///   helperText: 'A reference, a registration or a street',
///   onSubmitted: (words) => setState(() => query = words),
/// )
/// ```
class CivicSearchField extends StatefulWidget {
  /// A search box.
  const CivicSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.helperText,
    this.hintText,
    this.buttonLabel,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.buttonStyle,
  });

  /// The words; the field's own when null, and never disposed when given.
  final TextEditingController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// What is searched, above the box; null says "Search".
  final String? labelText;

  /// What a search can find.
  final String? helperText;

  /// Shown in the box while it is empty.
  final String? hintText;

  /// What a screen reader says for the button; null says "Search".
  final String? buttonLabel;

  /// Whether it takes input.
  final bool enabled;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Called as the words change.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the button or the keyboard's search key
  /// searches; null leaves the button off.
  final ValueChanged<String>? onSubmitted;

  /// Overrides for the box's look.
  final CivicStyle? style;

  /// Overrides for the button's look.
  final CivicStyle? buttonStyle;

  @override
  State<CivicSearchField> createState() => _CivicSearchFieldState();

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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('buttonLabel', buttonLabel, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>(
          'buttonStyle',
          buttonStyle,
          defaultValue: null,
        ),
      );
  }
}

class _CivicSearchFieldState extends State<CivicSearchField> {
  TextEditingController? _own;
  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _search() => widget.onSubmitted?.call(_controller.text);

  @override
  Widget build(BuildContext context) {
    final words = DesignLocalizations.of(context).searchFieldLabel;
    final submit = widget.onSubmitted;
    return CivicTextField(
      controller: _controller,
      focusNode: widget.focusNode,
      labelText: widget.labelText ?? words,
      helperText: widget.helperText,
      hintText: widget.hintText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: submit,
      style: widget.style,
      suffixIcon: _SearchButton(
        label: widget.buttonLabel ?? words,
        onPressed: widget.enabled && submit != null ? _search : null,
        style: widget.buttonStyle,
      ),
    );
  }
}

/// The search button: the action colour's square with a magnifier; a
/// pointer over it deepens it halfway to the action's edge colour, a press
/// sinks it the whole way, a keyboard focus floods it yellow with an ink
/// glyph over the ink bar.
class _SearchButton extends StatelessWidget {
  const _SearchButton({
    required this.label,
    required this.onPressed,
    required this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DesignPressable(
      onPressed: onPressed,
      semanticLabel: label,
      mouseCursor: onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      builder: (context, states, _) {
        final disabled = states.contains(WidgetState.disabled);
        final so = DesignStyleOf([style, t.searchButtonStyle], states);
        return CivicSpringValue(
          value: states.contains(WidgetState.pressed)
              ? 1
              : states.contains(WidgetState.hovered)
              ? 0.5
              : 0,
          spring: CivicMotion.press,
          effects: true,
          builder: (context, press, _) => CivicSpringValue(
            value: states.contains(WidgetState.focused) ? 1 : 0,
            spring: CivicMotion.focus,
            effects: true,
            builder: (context, focus, _) => CustomPaint(
              painter: CivicFacePainter(
                fill:
                    so.fill ??
                    (disabled
                        ? t.disabledFill
                        : Color.lerp(t.action, t.actionEdge, press)!),
                edgeColor: t.onFocus,
                edgeHeight: 0,
                press: 0,
                focus: focus,
                focusColor: t.focus,
                barColor: t.focusBar,
              ),
              child: Center(
                child: Icon(
                  LucideIcons.search,
                  size: _glyph,
                  color: Color.lerp(
                    so.foreground ?? (disabled ? t.textDisabled : t.onAction),
                    t.onFocus,
                    disabled ? 0 : focus,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The magnifier's size.
  static const double _glyph = 24;
}
