/// A colour from an area, a hue slider, an alpha slider, a hex field and
/// swatches, painted on ui_core's colour picker.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'input.dart';
import 'pressable.dart';

const double _track = 12;
const double _thumb = 16;
const Size _target = Size(44, 44);

/// The one gap between the picker's parts: the area, each strip, the hex
/// row and the swatches.
const double _gap = MinimalSpacing.s16;

/// A strip's band: its track with half a gap above and below, so two
/// strips stand one gap apart and each takes the hits nearer its own track.
const double _band = _track + _gap;

/// A colour picked by eye or by number: a label's colour, a calendar's, a
/// brand accent. A saturation and brightness area for the hue (its outline
/// `shapes.small`, a hairline round it) over a hue slider and, with
/// [showAlpha], an opacity slider on a checker; beside the hex field, a
/// swatch of the colour; under them, [swatches] to pick at a press. One
/// 16 px gap stands between each part and the next.
///
/// The area and each slider take the keyboard (an arrow a step, Shift ten)
/// and tell a screen reader their values. Their gradients are the colour
/// space itself, not reading order, so they run left to right in every
/// language, as the area's saturation does: each thumb stands over its
/// colour, and the right arrow moves it right. The hex field takes `#RGB`,
/// `#RRGGBB` or `#RRGGBBAA` as typed. It spans a phone's column; from a
/// tablet up it stops at [MinimalLayout.controlMax], on its start, as every
/// control that fills its column does. The behaviour is ui_core's
/// ([DesignColorPicker]); Minimal paints it.
///
/// ```dart
/// MinimalColorPicker(value: colour, onChanged: setColour, swatches: const [Color(0xFF2563EB), Color(0xFF16A34A)])
/// ```
class MinimalColorPicker extends StatefulWidget {
  /// A picker at [value].
  const MinimalColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.showAlpha = false,
    this.swatches = const [],
    this.areaHeight = 160,
  });

  /// The colour.
  final Color value;

  /// Called with the colour as it changes.
  final ValueChanged<Color> onChanged;

  /// Whether it offers an opacity slider (and the hex keeps its alpha).
  final bool showAlpha;

  /// Colours to pick at a press, under the field.
  final List<Color> swatches;

  /// The area's height.
  final double areaHeight;

  @override
  State<MinimalColorPicker> createState() => _MinimalColorPickerState();
}

class _MinimalColorPickerState extends State<MinimalColorPicker> {
  late final DesignColorController _colour = DesignColorController(widget.value)
    ..addListener(_changed);
  late final TextEditingController _hex = TextEditingController(
    text: _colour.hex,
  );
  final FocusNode _hexFocus = FocusNode(debugLabel: 'MinimalColorPicker hex');

  bool _syncing = false;

  void _changed() {
    if (_syncing) {
      // The caller's new value, during its build: the field's text
      // follows after the frame, and this build already reads the colour.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hexFocus.hasFocus) _hex.text = _colour.hex;
      });
      return;
    }
    if (!_hexFocus.hasFocus) _hex.text = _colour.hex;
    final c = _colour.color;
    if (c != widget.value) widget.onChanged(c);
    setState(() {});
  }

  @override
  void didUpdateWidget(MinimalColorPicker old) {
    super.didUpdateWidget(old);
    if (widget.value != _colour.color) {
      _syncing = true;
      _colour.color = widget.value;
      _syncing = false;
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
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    final frame = t.shapes.small;

    Widget handle(Set<WidgetState> states, {Color? fill}) {
      final ring = t.focusWidth;
      return SizedBox.square(
        dimension: _thumb + 4 + 2 * ring,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (states.ring)
              Container(
                width: _thumb + 4 + 2 * ring,
                height: _thumb + 4 + 2 * ring,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.ring, width: ring),
                ),
              ),
            Container(
              width: _thumb,
              height: _thumb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill ?? const Color(0x00000000),
                // A ring of the ground inside an ink hairline: it reads on
                // any colour without a shadow (nothing on the page casts
                // one).
                border: Border.all(color: t.background, width: 2),
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: t.foreground,
                  width: t.hairline,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final picker = DesignColorPicker(
      controller: _colour,
      showAlpha: widget.showAlpha,
      areaHeight: widget.areaHeight,
      areaBuilder: (context, area) => Container(
        foregroundDecoration: minimalFrame(
          frame,
          side: BorderSide(color: t.border, width: t.hairline),
        ),
        child: minimalClip(
          frame,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: area.color.withSaturation(1).withValue(1).toColor(),
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
      ),
      areaThumbBuilder: (context, area) =>
          handle(area.states, fill: area.color.withAlpha(1).toColor()),
      trackBuilder: (context, channel, colour) => CustomPaint(
        size: const Size(double.infinity, _track),
        painter: _ChannelTrack(
          channel: channel,
          colour: colour,
          slot: t.shapes.pill,
          rim: t.border,
          checkerA: t.card,
          checkerB: t.muted,
          // The thumbs' travel stops half a thumb from the column's edges
          // (_bleed); the strip runs on to the edges, so at either end the
          // thumb covers the strip's rounded end.
          overhang: _thumb / 2,
        ),
      ),
      thumbBuilder: (context, states) => handle(states),
      // The area runs the column; each slider bleeds past it so its strip
      // does too, its ends in line with the area's and the hex field's. Half
      // a gap under the area and a strip's own half gap make one gap.
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, part) in parts.indexed)
            if (i == 0) ...[part, const MinimalGap(_gap / 2)] else _bleed(part),
        ],
      ),
    );

    // The swatch stands as tall as the hex field beside it, and its rim is
    // the stronger hairline, so a colour near the ground's keeps an edge.
    final side = t.density.height(MinimalChromeMetrics.control);
    final swatch = Container(
      width: side,
      height: side,
      decoration: minimalFrame(
        frame,
        fill: _colour.color,
        side: BorderSide(color: t.borderStrong, width: t.hairline),
      ),
    );

    // A control that fills its column: from a tablet up it stops at
    // MinimalLayout.controlMax, on its start.
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        picker,
        // The last strip's band ends half a gap under its track.
        const MinimalGap(_gap / 2),
        Row(
          children: [
            ExcludeSemantics(child: swatch),
            const MinimalGap(MinimalSpacing.s8),
            Expanded(
              child: MinimalTextField(
                controller: _hex,
                focusNode: _hexFocus,
                mono: true,
                hint: '#RRGGBB',
                fieldBuilder: (field) =>
                    Semantics(label: words.hexColour, child: field),
                onChanged: (text) {
                  if (text.replaceAll('#', '').length >= 6) {
                    _colour.setHex(text);
                  }
                },
                onSubmitted: (text) {
                  if (!_colour.setHex(text)) _hex.text = _colour.hex;
                },
                onFocusChanged: (focused) {
                  if (!focused) _hex.text = _colour.hex;
                },
              ),
            ),
          ],
        ),
        if (widget.swatches.isNotEmpty) ...[
          const MinimalGap(_gap),
          MinimalHitTarget(
            child: Wrap(
              spacing: MinimalSpacing.s8,
              runSpacing: MinimalSpacing.s8,
              children: [
                for (final c in widget.swatches)
                  MinimalPressable(
                    onPressed: () => _colour.color = c,
                    shape: t.shapes.mark,
                    selected: c == _colour.color,
                    semanticLabel: _hexOf(c),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: minimalFrame(
                        t.shapes.mark,
                        fill: c,
                        side: BorderSide(
                          color: c == _colour.color
                              ? t.foreground
                              : t.borderStrong,
                          width: c == _colour.color ? 2 : t.hairline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
    return MinimalLayout.capControl(context, column);
  }

  static String _hexOf(Color c) {
    String two(double x) =>
        (x * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${two(c.r)}${two(c.g)}${two(c.b)}';
  }
}

/// [slider], ui_core's, laid out at its thumb's 44 px target and stood in
/// a [_band] (its track and half a gap above and below), widened past the
/// column on both sides so the thumb's centre travels from half a thumb
/// inside one edge to half a thumb inside the other, as a `MinimalSlider`'s
/// does. What stands past the band paints but takes no hits, so two strips
/// one gap apart split the air between them. It runs left to right in
/// either reading direction, as ui_core's area does: right to left, ui_core
/// would mirror the thumb and its arrow keys, while the strip under it keeps
/// the colour's own order.
Widget _bleed(Widget slider) {
  final reach = _target.width / 2 - _thumb / 2;
  final over = (_target.height - _band) / 2;
  return SizedBox(
    height: _band,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -reach,
          right: -reach,
          top: -over,
          bottom: -over,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: slider,
          ),
        ),
      ],
    ),
  );
}

/// A channel's track: the hue spectrum, or the colour fading in over a
/// checker; it reaches [overhang] past the thumbs' travel at both ends,
/// the end colours held.
class _ChannelTrack extends CustomPainter {
  const _ChannelTrack({
    required this.channel,
    required this.colour,
    required this.slot,
    required this.rim,
    required this.checkerA,
    required this.checkerB,
    required this.overhang,
  });

  final DesignColorChannel channel;
  final HSVColor colour;
  final OutlinedBorder slot;
  final Color rim;
  final Color checkerA;
  final Color checkerB;
  final double overhang;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = Offset.zero & size;
    final whole = Rect.fromLTRB(
      -overhang,
      0,
      size.width + overhang,
      size.height,
    );
    final path = slot.getOuterPath(whole, textDirection: TextDirection.ltr);
    canvas.save();
    canvas.clipPath(path);
    if (channel == DesignColorChannel.alpha) {
      const cell = 4.0;
      canvas.drawRect(whole, Paint()..color = checkerA);
      final dark = Paint()..color = checkerB;
      for (var x = whole.left; x < whole.right; x += cell) {
        for (var y = 0.0; y < size.height; y += cell) {
          if (((x - whole.left) ~/ cell + y ~/ cell).isEven) {
            canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), dark);
          }
        }
      }
    }
    final colours = switch (channel) {
      DesignColorChannel.hue => [
        for (var h = 0; h <= 360; h += 60)
          HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
      ],
      DesignColorChannel.alpha => [
        colour.withAlpha(0).toColor(),
        colour.withAlpha(1).toColor(),
      ],
      DesignColorChannel.saturation => [
        colour.withSaturation(0).withAlpha(1).toColor(),
        colour.withSaturation(1).withAlpha(1).toColor(),
      ],
      DesignColorChannel.brightness => [
        colour.withValue(0).withAlpha(1).toColor(),
        colour.withValue(1).withAlpha(1).toColor(),
      ],
    };
    canvas.drawRect(
      whole,
      Paint()..shader = LinearGradient(colors: colours).createShader(inner),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rim,
    );
  }

  @override
  bool shouldRepaint(_ChannelTrack old) =>
      old.channel != channel ||
      old.colour != colour ||
      old.slot != slot ||
      old.rim != rim ||
      old.checkerA != checkerA ||
      old.checkerB != checkerB ||
      old.overhang != overhang;
}
