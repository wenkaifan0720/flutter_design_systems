import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/field_frame.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../material.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

// A colour picker's caller builds its controller and reads the colour.
export 'package:ui_core/ui_core.dart' show RawColorController;

/// A named colour a [CivicColorPicker] offers.
@immutable
class CivicColorSwatch {
  /// [color], called [name].
  const CivicColorSwatch(this.color, this.name);

  /// The colour.
  final Color color;

  /// Its name: shown and said, since a colour alone says nothing to many.
  final String name;
}

/// A colour picked: named [swatches] first, each a square of its colour
/// with its name beside it (the one picked ticked and on the chosen rule),
/// then, with [showCustom], any colour: a saturation and brightness area
/// over a hue track, and the colour's hex code typed in a well. Every part
/// works by keyboard; the area and the track step with the arrow keys.
///
/// The [controller] holds the colour; the caller makes, keeps and disposes
/// it, and listens to it for changes.
///
/// Reads [CivicStyle]'s fill and edge (a swatch's square) by state: its
/// `style:`, then [CivicThemeData.colorPickerStyle].
///
/// ```dart
/// CivicColorPicker(
///   labelText: 'Badge colour',
///   controller: badge,
///   swatches: const [
///     CivicColorSwatch(Color(0xFF0F4C81), 'Harbour blue'),
///     CivicColorSwatch(Color(0xFF0B6136), 'Park green'),
///   ],
/// )
/// ```
class CivicColorPicker extends StatelessWidget {
  /// A colour picker.
  const CivicColorPicker({
    super.key,
    required this.controller,
    this.swatches = const [],
    this.showCustom = true,
    this.showAlpha = false,
    this.labelText,
    this.helperText,
    this.errorText,
    this.hexLabel = 'Hex code',
    this.style,
  }) : assert(swatches.length > 0 || showCustom);

  /// The colour.
  final RawColorController controller;

  /// The named colours offered first.
  final List<CivicColorSwatch> swatches;

  /// Whether any colour can be picked, beyond the swatches.
  final bool showCustom;

  /// Whether the custom picker has an alpha track.
  final bool showAlpha;

  /// What the colour is for.
  final String? labelText;

  /// How to choose.
  final String? helperText;

  /// What to fix; null while the colour is fine.
  final String? errorText;

  /// The hex field's label.
  final String hexLabel;

  /// Overrides for the swatches' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final body = ValueListenableBuilder<HSVColor>(
      valueListenable: controller,
      builder: (context, hsv, _) {
        final current = hsv.toColor();
        final picked = swatches.indexWhere(
          (s) => s.color.toARGB32() == current.toARGB32(),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: CivicSpacing.s16,
          children: [
            if (swatches.isNotEmpty)
              Semantics(
                container: true,
                explicitChildNodes: true,
                // The swatches are one radio group, Flutter's: one Tab stop,
                // and the arrow keys pick as they move.
                child: RadioGroup<int>(
                  groupValue: picked < 0 ? null : picked,
                  onChanged: (i) => controller.color = swatches[i!].color,
                  child: RadioGroupKeyboardFix<int>(
                    child: Wrap(
                      spacing: CivicSpacing.s16,
                      runSpacing: CivicSpacing.s8,
                      children: [
                        for (final (i, swatch) in swatches.indexed)
                          _Swatch(
                            key: ObjectKey(i),
                            index: i,
                            swatch: swatch,
                            chosen:
                                swatch.color.toARGB32() == current.toARGB32(),
                            styles: [style, t.colorPickerStyle],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (showCustom) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: RawColorPicker(
                  controller: controller,
                  showAlpha: showAlpha,
                  areaHeight: 180,
                  layoutBuilder: (context, parts) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    spacing: CivicSpacing.s12,
                    children: parts,
                  ),
                  areaBuilder: (context, area) => DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: t.border,
                        width: CivicMetrics.edge,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _Area(area.color.hue),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  areaThumbBuilder: (context, area) =>
                      _Thumb(states: area.states, color: area.color.toColor()),
                  trackBuilder: (context, channel, color) => DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: t.border,
                        width: CivicMetrics.edge,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _Track(channel, color),
                      child: const SizedBox(height: 24),
                    ),
                  ),
                  thumbBuilder: (context, states) => _Thumb(states: states),
                ),
              ),
              _Hex(
                key: ValueKey(current.toARGB32()),
                color: current,
                label: hexLabel,
                onChanged: (c) => controller.color = c,
              ),
            ],
          ],
        );
      },
    );
    if (labelText == null && helperText == null && errorText == null) {
      return body;
    }
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      builder: (context, parts) =>
          CivicFieldFrame(parts: parts, isLegend: true),
      child: body,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawColorController>('controller', controller))
      ..add(IterableProperty<CivicColorSwatch>('swatches', swatches))
      ..add(
        FlagProperty('showCustom', value: showCustom, ifFalse: 'swatches only'),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// A named swatch: its colour's square in a well, its name beside it, the
/// whole row the target; picked, ticked and standing on the chosen rule.
class _Swatch extends StatefulWidget {
  const _Swatch({
    super.key,
    required this.index,
    required this.swatch,
    required this.chosen,
    required this.styles,
  });

  final int index;
  final CivicColorSwatch swatch;
  final bool chosen;
  final List<DesignStyle?> styles;

  @override
  State<_Swatch> createState() => _SwatchState();
}

class _SwatchState extends State<_Swatch> {
  final FocusNode _focusNode = FocusNode();

  // The pointer over the swatch, held or not, as a mouse region hears it:
  // the plate stays while a press is down (RawRadio's hover is a focus
  // highlight's and leaves under a press).
  bool _hovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final swatch = widget.swatch;
    final chosen = widget.chosen;
    return TapTargetPadding(
      // One node for the swatch: RawRadio's (checked, one of a group, its
      // focus and its tap), with its name.
      child: MergeSemantics(
        child: RawRadio<int>(
          value: widget.index,
          mouseCursor: WidgetStateMouseCursor.clickable,
          toggleable: false,
          focusNode: _focusNode,
          autofocus: false,
          groupRegistry: RadioGroup.maybeOf<int>(context),
          enabled: true,
          builder: (context, radio) => Semantics(
            label: swatch.name,
            child: ExcludeSemantics(
              // All of it takes a press, its gaps too, as RawRadio's
              // detector finds only what the face paints.
              child: Listener(
                behavior: HitTestBehavior.opaque,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hovered = true),
                  onExit: (_) => setState(() => _hovered = false),
                  child: _face(context, t, text, swatch, chosen, {
                    for (final state in radio.states)
                      if (state != WidgetState.hovered) state,
                    if (_hovered) WidgetState.hovered,
                    if (radio.downPosition != null) WidgetState.pressed,
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _face(
    BuildContext context,
    CivicThemeData t,
    CivicTextTheme text,
    CivicColorSwatch swatch,
    bool chosen,
    Set<WidgetState> states,
  ) {
    final styles = widget.styles;
    final so = DesignStyleOf(styles, states);
    final focused = states.contains(WidgetState.focused);
    final hovered = states.contains(WidgetState.hovered);
    return CivicSpringValue(
      value: focused ? 1 : 0,
      spring: CivicMotion.focus,
      effects: true,
      builder: (context, focus, _) => CustomPaint(
        painter: CivicFacePainter(
          fill: hovered && !focused ? t.surface : const Color(0x00000000),
          edgeColor: t.onFocus,
          edgeHeight: 0,
          press: 0,
          focus: focus,
          focusColor: t.focus,
          barColor: t.focusBar,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4 + CivicMetrics.bar),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: CivicSpacing.s8,
            children: [
              CivicWell(
                fill: so.fill ?? swatch.color,
                edgeColor: so.edge ?? t.border,
                child: SizedBox.square(
                  dimension: 40,
                  child: chosen
                      ? Icon(
                          LucideIcons.check,
                          size: 24,
                          color: swatch.color.computeLuminance() > 0.4
                              ? const Color(0xFF0C1116)
                              : const Color(0xFFFFFFFF),
                        )
                      : null,
                ),
              ),
              // Under large text the name wraps beside its well.
              Flexible(
                child: Text(
                  swatch.name,
                  style: (chosen ? text.label : text.body).copyWith(
                    color: Color.lerp(t.textPrimary, t.onFocus, focus),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The custom picker's thumb: a square of [color] (none on a track) in a
/// white and an ink ring, so it shows on every colour; the keyboard's
/// focus rings it in yellow.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.states, this.color});

  final Set<WidgetState> states;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final focused = states.contains(WidgetState.focused);
    final pressed = states.contains(WidgetState.pressed);
    return Center(
      child: CivicSpringValue(
        value: focused ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, f, _) => CivicSpringValue(
          value: pressed ? 1 : 0,
          spring: CivicMotion.press,
          builder: (context, p, _) => Container(
            width: 24 + 4 * p,
            height: 24 + 4 * p,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
              boxShadow: [
                const BoxShadow(color: Color(0xFF0C1116), spreadRadius: 2),
                if (f > 0)
                  BoxShadow(
                    color: t.focus.withValues(alpha: f),
                    spreadRadius: 2 + 4 * f,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Area extends CustomPainter {
  _Area(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFFFFFF),
              HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
            ],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xFF000000)],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(_Area old) => old.hue != hue;
}

class _Track extends CustomPainter {
  _Track(this.channel, this.color);

  final RawColorChannel channel;
  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = switch (channel) {
      RawColorChannel.hue => [
        for (var h = 0; h <= 360; h += 60)
          HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
      ],
      RawColorChannel.saturation => [
        color.withSaturation(0).toColor(),
        color.withSaturation(1).toColor(),
      ],
      RawColorChannel.brightness => [
        color.withValue(0).toColor(),
        color.withValue(1).toColor(),
      ],
      RawColorChannel.alpha => [
        color.withAlpha(0).toColor(),
        color.withAlpha(1).toColor(),
      ],
    };
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Track old) =>
      old.channel != channel || old.color != color;
}

/// The colour's hex code, typed: taken when it is six figures whole.
class _Hex extends StatefulWidget {
  const _Hex({
    super.key,
    required this.color,
    required this.label,
    required this.onChanged,
  });

  final Color color;
  final String label;
  final ValueChanged<Color> onChanged;

  @override
  State<_Hex> createState() => _HexState();
}

class _HexState extends State<_Hex> {
  late final TextEditingController _text = TextEditingController(
    text: (widget.color.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase(),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _take() {
    final v = int.tryParse(_text.text, radix: 16);
    if (_text.text.length == 6 && v != null) {
      widget.onChanged(Color(0xFF000000 | v));
    }
  }

  @override
  Widget build(BuildContext context) => CivicTextField(
    controller: _text,
    labelText: widget.label,
    prefix: const Text('#'),
    widthInCharacters: 7,
    textCapitalization: TextCapitalization.characters,
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
      LengthLimitingTextInputFormatter(6),
    ],
    onEditingComplete: _take,
    onChanged: (_) => _take(),
  );
}
