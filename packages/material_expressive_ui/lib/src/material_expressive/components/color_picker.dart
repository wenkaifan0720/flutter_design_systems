/// The colour picker, painted on ui_core's `DesignColorPicker`.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/state_face.dart';
import '../spacing.dart';
import '../strings.dart';
import '../theme.dart';
import 'text_fields.dart';

/// A colour chosen on a saturation and brightness area, a hue slider and,
/// with [showAlpha], an opacity slider, its hex code typed beside a swatch
/// (shadcn's colour picker; Material has none). The area stands on the
/// medium corner; the sliders are 12dp pill tracks (the hue's spectrum, the
/// opacity's fade over a checker); every thumb is a 20dp circle of the
/// colour under a 2dp `surface` ring and an `outline` hairline, which grows
/// its state layer's halo under a pointer and wears the focus ring under
/// the keyboard. The keys are ui_core's: the arrows step a thumb, Page Up
/// and Down by ten; each part reads as an adjustable value.
///
/// ```dart
/// ExpressiveColorPicker(value: brand, onChanged: setBrand)
/// ```
class ExpressiveColorPicker extends StatefulWidget {
  /// A picker showing [value].
  const ExpressiveColorPicker({
    required this.value,
    required this.onChanged,
    this.showAlpha = false,
    this.showHex = true,
    this.areaHeight = 180,
    super.key,
  });

  /// The colour.
  final Color value;

  /// Told each new colour; out of use when null.
  final ValueChanged<Color>? onChanged;

  /// Whether an opacity slider stands under the hue.
  final bool showAlpha;

  /// Whether the hex field stands under the sliders.
  final bool showHex;

  /// The area's height.
  final double areaHeight;

  @override
  State<ExpressiveColorPicker> createState() => _ExpressiveColorPickerState();
}

class _ExpressiveColorPickerState extends State<ExpressiveColorPicker> {
  late final DesignColorController _color = DesignColorController(widget.value)
    ..addListener(_changed);
  late final TextEditingController _hex = TextEditingController(
    text: _color.hex,
  );

  /// Whether the controller is taking a new [ExpressiveColorPicker.value]
  /// from the parent, which is not a change to report back.
  bool _syncing = false;

  void _changed() {
    if (!_syncing) widget.onChanged?.call(_color.color);
    final hex = _color.hex;
    if (_hex.text.toUpperCase() != hex.toUpperCase()) _hex.text = hex;
  }

  @override
  void didUpdateWidget(ExpressiveColorPicker old) {
    super.didUpdateWidget(old);
    // The controller holds HSV, so a colour read back may differ from the
    // value by a rounding; only a new value from the parent moves it.
    if (widget.value != old.value && widget.value != _color.color) {
      _syncing = true;
      _color.color = widget.value;
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _color.dispose();
    _hex.dispose();
    super.dispose();
  }

  Widget _thumb(BuildContext context, Set<WidgetState> states, Color fill) {
    final t = context.expressiveTheme;
    return Center(
      child: SizedBox.square(
        dimension: ExpressiveSpacing.s20,
        child: ExpressiveStateFace(
          states: states,
          shape: t.shapes.full,
          color: fill,
          contentColor: t.colors.onSurface,
          layers: false,
          side: BorderSide(color: t.colors.surface, width: 2),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: t.shapes.full.copyWith(
                side: BorderSide(color: t.colors.outline, width: 1),
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  /// The halo a pointer or a press draws round a thumb: the state layer of
  /// `onSurface` on a 40dp circle behind it.
  Widget _halo(BuildContext context, Set<WidgetState> states, Widget thumb) {
    final t = context.expressiveTheme;
    final layer = states.contains(WidgetState.disabled)
        ? null
        : t.states.layerOf(
            t.colors.onSurface,
            states.difference(<WidgetState>{WidgetState.focused}),
          );
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (layer != null)
          SizedBox.square(
            dimension: ExpressiveSpacing.s40,
            child: DecoratedBox(
              decoration: ShapeDecoration(color: layer, shape: t.shapes.full),
            ),
          ),
        thumb,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    return IgnorePointer(
      ignoring: widget.onChanged == null,
      child: DesignColorPicker(
        controller: _color,
        showAlpha: widget.showAlpha,
        areaHeight: widget.areaHeight,
        areaBuilder: (context, area) => ClipPath(
          clipper: ShapeBorderClipper(shape: t.shapes.medium),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      const Color(0xFFFFFFFF),
                      HSVColor.fromAHSV(1, area.color.hue, 1, 1).toColor(),
                    ],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x00000000), Color(0xFF000000)],
                  ),
                ),
              ),
            ],
          ),
        ),
        areaThumbBuilder: (context, area) => _halo(
          context,
          area.states,
          _thumb(context, area.states, area.color.withAlpha(1).toColor()),
        ),
        trackBuilder: (context, channel, color) => Center(
          child: SizedBox(
            height: ExpressiveSpacing.s12,
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: t.shapes.full),
              child: channel == DesignColorChannel.alpha
                  ? CustomPaint(
                      painter: _Checker(c.surfaceContainerHighest, c.surface),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              color.withAlpha(0).toColor(),
                              color.withAlpha(1).toColor(),
                            ],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            for (var hue = 0; hue <= 360; hue += 60)
                              HSVColor.fromAHSV(
                                1,
                                hue.toDouble(),
                                1,
                                1,
                              ).toColor(),
                          ],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
          ),
        ),
        thumbBuilder: (context, states) => ValueListenableBuilder<HSVColor>(
          valueListenable: _color,
          builder: (context, color, _) => _halo(
            context,
            states,
            _thumb(context, states, color.withAlpha(1).toColor()),
          ),
        ),
        layoutBuilder: (context, parts) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            parts.first,
            const SizedBox(height: ExpressiveSpacing.s16),
            Row(
              children: <Widget>[
                ValueListenableBuilder<HSVColor>(
                  valueListenable: _color,
                  builder: (context, color, _) => SizedBox.square(
                    dimension: ExpressiveSpacing.s40,
                    child: CustomPaint(
                      painter: _Checker(
                        c.surfaceContainerHighest,
                        c.surface,
                        shape: t.shapes.full,
                      ),
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: color.toColor(),
                          shape: t.shapes.full.copyWith(
                            side: BorderSide(color: c.outlineVariant, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ExpressiveSpacing.s16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[...parts.skip(1)],
                  ),
                ),
              ],
            ),
            if (widget.showHex) ...<Widget>[
              const SizedBox(height: ExpressiveSpacing.s16),
              ExpressiveTextField(
                controller: _hex,
                kind: ExpressiveTextFieldKind.outlined,
                label: ExpressiveLocalizations.of(context).colorHex,
                enabled: widget.onChanged != null,
                onSubmitted: (text) {
                  if (!_color.setHex(text)) _hex.text = _color.hex;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The checker an opacity shows through.
class _Checker extends CustomPainter {
  const _Checker(this.dark, this.light, {this.shape});

  final Color dark;
  final Color light;
  final ShapeBorder? shape;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    final outline = shape;
    if (outline != null) canvas.clipPath(outline.getOuterPath(rect));
    canvas.drawRect(rect, Paint()..color = light);
    const cell = 6.0;
    final paint = Paint()..color = dark;
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        if (((x + y) / cell).round().isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Checker old) =>
      old.dark != dark || old.light != light || old.shape != shape;
}
