import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/panel.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../forms/forms.dart';

/// A colour chosen by eye or by its hex (shadcn's color picker): a field of
/// the hue's saturation and brightness to drag a ring across, a rainbow
/// slider for the hue (and a fading one for the opacity with [showAlpha]),
/// the swatch and its hex in a field. Each part is a Tab stop; the arrows
/// move the ring and the knobs, and a screen reader hears each as a slider
/// with its value. ui_core's [DesignColorPicker] is the behaviour.
///
/// ```dart
/// FrostedColorPicker(value: tint, onChanged: (c) => setState(() => tint = c))
/// ```
class FrostedColorPicker extends StatefulWidget {
  /// A picker standing on [value].
  const FrostedColorPicker({
    required this.value,
    required this.onChanged,
    this.showAlpha = false,
    this.showHex = true,
    super.key,
  });

  /// The colour.
  final Color value;

  /// Called with the colour as it changes.
  final ValueChanged<Color> onChanged;

  /// Whether it has an opacity slider.
  final bool showAlpha;

  /// Whether it has the hex field.
  final bool showHex;

  @override
  State<FrostedColorPicker> createState() => _FrostedColorPickerState();
}

class _FrostedColorPickerState extends State<FrostedColorPicker> {
  late final DesignColorController _colour = DesignColorController(widget.value)
    ..addListener(_changed);
  late final TextEditingController _hex = TextEditingController(
    text: _colour.hex,
  );
  final FocusNode _hexFocus = FocusNode();

  void _changed() {
    final colour = _colour.color;
    if (!_hexFocus.hasFocus) _hex.text = _colour.hex;
    if (colour != widget.value) widget.onChanged(colour);
  }

  @override
  void didUpdateWidget(FrostedColorPicker old) {
    super.didUpdateWidget(old);
    if (widget.value != _colour.color) {
      _colour.value = HSVColor.fromColor(widget.value);
    }
  }

  @override
  void dispose() {
    _colour.dispose();
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final corner = BorderRadius.circular(FrostedCorners.r12);
    Widget knob(Set<WidgetState> states, {Color? fill}) {
      final face = SizedBox.square(
        dimension: 22,
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(11),
          // The slider's pearl: a dark knob by night (made for a switch's
          // light ink) takes the light ink, as FrostedSlider's does; dark,
          // the thumbs read as holes in the tracks (self-review round 3).
          color:
              fill ??
              (t.colorScheme.toggleKnob.computeLuminance() > .5
                  ? t.colorScheme.toggleKnob
                  : t.colorScheme.textPrimary),
          edge: t.glass.plane,
          edges: const EdgeInsets.all(3),
          shadows: t.shadows.toggleKnob,
        ),
      );
      return Center(child: frostedRingFor(states, face, radius: 11));
    }

    return DesignColorPicker(
      controller: _colour,
      showAlpha: widget.showAlpha,
      areaHeight: 180,
      areaBuilder: (context, area) => ClipRRect(
        borderRadius: corner,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: HSVColor.fromAHSV(1, area.color.hue, 1, 1).toColor(),
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xFF000000)],
                ),
              ),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
      areaThumbBuilder: (context, area) =>
          knob(area.states, fill: area.color.withAlpha(1).toColor()),
      trackBuilder: (context, channel, colour) {
        // The tracks run from the line's start as their thumbs do: drawn
        // left to right under a right-to-left thumb, each thumb stood on
        // another colour (self-review round 2).
        final gradient = switch (channel) {
          DesignColorChannel.hue => LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [
              for (var h = 0; h <= 360; h += 60)
                HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
            ],
          ),
          _ => LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [
              colour.withAlpha(0).toColor(),
              colour.withAlpha(1).toColor(),
            ],
          ),
        };
        return Center(
          child: SizedBox(
            height: 12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (channel == DesignColorChannel.alpha)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const CustomPaint(painter: _Checker()),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: t.glass.edge),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      thumbBuilder: (context, states) => knob(states),
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedSpacing.s12,
        children: [
          ...parts,
          if (widget.showHex)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: FrostedSpacing.s12,
              children: [
                SizedBox.square(
                  dimension: FrostedChromeMetrics.field,
                  child: ListenableBuilder(
                    listenable: _colour,
                    builder: (context, _) => FrostedFace(
                      material: FrostedMaterial.paint,
                      radius: corner,
                      color: _colour.color,
                      ring: t.glass.edge,
                    ),
                  ),
                ),
                Expanded(
                  child: FrostedTextField(
                    label: words.hex,
                    controller: _hex,
                    focusNode: _hexFocus,
                    textDirection: TextDirection.ltr,
                    onSubmitted: (text) {
                      if (!_colour.setHex(text)) _hex.text = _colour.hex;
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The checks an opacity track fades over.
class _Checker extends CustomPainter {
  const _Checker();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 6.0;
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFDADAE3);
    canvas.drawRect(Offset.zero & size, light);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        if (((x / cell).floor() + (y / cell).floor()).isOdd) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), dark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Checker oldDelegate) => false;
}
