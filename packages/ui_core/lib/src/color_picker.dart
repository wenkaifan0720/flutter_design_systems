/// A colour picker, headless: a controller over hue, saturation, brightness
/// and alpha (with hex in and out), a saturation-brightness area, channel
/// sliders on [DesignValueHandle], and [DesignColorPicker] composing them.
/// Every part takes the keyboard (arrows a step, Shift ten) and tells a
/// screen reader its value; the hex text is the look's own field on
/// [DesignColorController.hex] and [DesignColorController.setHex].
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'value_handle.dart';

/// A colour being picked, as hue, saturation, brightness and alpha.
///
/// The caller makes it (a State's field, say), keeps it across rebuilds
/// and disposes it; a widget it is given to only listens to it.
///
/// ```dart
/// DesignColorController(const Color(0xFF3366FF))
/// ```
class DesignColorController extends ValueNotifier<HSVColor> {
  /// A picker starting at [initial].
  DesignColorController([Color initial = const Color(0xFF000000)])
    : super(HSVColor.fromColor(initial));

  /// The colour.
  Color get color => value.toColor();

  /// Picks [color], keeping the hue when [color] is a grey.
  set color(Color color) {
    final next = HSVColor.fromColor(color);
    final grey = next.saturation == 0 || next.value == 0;
    value = grey ? next.withHue(value.hue) : next;
  }

  /// Sets the hue, 0 to 360.
  set hue(double hue) => value = value.withHue(hue.clamp(0.0, 360.0));

  /// Sets the saturation, 0 to 1.
  set saturation(double s) => value = value.withSaturation(s.clamp(0.0, 1.0));

  /// Sets the brightness, 0 to 1.
  set brightness(double v) => value = value.withValue(v.clamp(0.0, 1.0));

  /// Sets the alpha, 0 to 1.
  set alpha(double a) => value = value.withAlpha(a.clamp(0.0, 1.0));

  /// The colour as `#RRGGBB`, or `#RRGGBBAA` when it is not opaque.
  String get hex {
    final c = color;
    String two(double x) =>
        (x * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    final rgb = '#${two(c.r)}${two(c.g)}${two(c.b)}';
    return c.a >= 1 ? rgb : '$rgb${two(c.a)}';
  }

  /// Picks the colour [text] names (`#RGB`, `#RRGGBB` or `#RRGGBBAA`, the
  /// `#` optional); false, and nothing changes, when it names none.
  bool setHex(String text) {
    var t = text.trim();
    if (t.startsWith('#')) t = t.substring(1);
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(t)) return false;
    if (t.length == 3) t = [for (final ch in t.split('')) '$ch$ch'].join();
    if (t.length == 6) t = '${t}FF';
    if (t.length != 8) return false;
    final n = int.parse(t, radix: 16);
    color = Color(((n & 0xFF) << 24) | (n >> 8));
    return true;
  }
}

/// A channel a [DesignColorSlider] sets.
enum DesignColorChannel {
  /// Hue, 0 to 360.
  hue,

  /// Saturation, 0 to 1.
  saturation,

  /// Brightness, 0 to 1.
  brightness,

  /// Alpha, 0 to 1.
  alpha;

  /// The channel's greatest value.
  double get max => this == hue ? 360 : 1;

  /// The channel's value in [color].
  double of(HSVColor color) => switch (this) {
    hue => color.hue,
    saturation => color.saturation,
    brightness => color.value,
    alpha => color.alpha,
  };
}

void _setChannel(DesignColorController c, DesignColorChannel ch, double v) {
  switch (ch) {
    case DesignColorChannel.hue:
      c.hue = v;
    case DesignColorChannel.saturation:
      c.saturation = v;
    case DesignColorChannel.brightness:
      c.brightness = v;
    case DesignColorChannel.alpha:
      c.alpha = v;
  }
}

String _percent(double v) => '${(v * 100).round()}%';

/// What the look paints the area from.
@immutable
class DesignColorAreaDetails {
  /// The state; the area makes it.
  const DesignColorAreaDetails({required this.color, required this.states});

  /// The colour: its hue fills the area, its saturation is the thumb's x
  /// (0 left to 1 right) and its brightness the thumb's height (1 at top).
  final HSVColor color;

  /// The thumb's states (focused while the keyboard is on it, hovered,
  /// pressed while dragged).
  final Set<WidgetState> states;
}

/// A saturation (across) and brightness (up) area for [controller]'s hue.
///
/// ```dart
/// DesignColorArea(controller: controller, builder: (context, area) => const SizedBox.expand(), thumbBuilder: (context, area) => const SizedBox(width: 16, height: 16))
/// ```
class DesignColorArea extends StatefulWidget {
  /// An area over [controller].
  const DesignColorArea({
    super.key,
    required this.controller,
    required this.builder,
    required this.thumbBuilder,
    this.step = 0.01,
    this.semanticLabel,
    this.thumbSize = const Size(44, 44),
    this.focusNode,
    this.autofocus = false,
  });

  /// The colour. The caller makes it, keeps it across rebuilds
  /// and disposes it.
  final DesignColorController controller;

  /// Paints the area (the hue's gradients).
  final Widget Function(BuildContext context, DesignColorAreaDetails area)
  builder;

  /// Paints the thumb, centred in its [thumbSize] target.
  final Widget Function(BuildContext context, DesignColorAreaDetails area)
  thumbBuilder;

  /// An arrow's change (Shift: ten times).
  final double step;

  /// What a screen reader calls it; null:
  /// [DesignLocalizations.colorAreaLabel].
  final String? semanticLabel;

  /// The thumb's target.
  final Size thumbSize;

  /// Its focus. The caller's, who disposes it; null: its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  State<DesignColorArea> createState() => _DesignColorAreaState();
}

class _DesignColorAreaState extends State<DesignColorArea> {
  bool _focused = false;
  bool _hovered = false;
  bool _dragging = false;

  DesignColorController get _c => widget.controller;

  void _at(Offset p, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _c.value = _c.value
        .withSaturation((p.dx / size.width).clamp(0.0, 1.0))
        .withValue((1 - p.dy / size.height).clamp(0.0, 1.0));
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step =
        widget.step * (HardwareKeyboard.instance.isShiftPressed ? 10 : 1);
    final v = _c.value;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      _c.saturation = v.saturation + step;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _c.saturation = v.saturation - step;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _c.brightness = v.value + step;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _c.brightness = v.value - step;
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    // A colour area is not mirrored right to left: saturation grows rightward.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<HSVColor>(
        valueListenable: _c,
        builder: (context, hsv, _) {
          final area = DesignColorAreaDetails(
            color: hsv,
            states: {
              if (_focused) WidgetState.focused,
              if (_hovered) WidgetState.hovered,
              if (_dragging) WidgetState.pressed,
            },
          );
          String said(double brightness) =>
              'saturation ${_percent(hsv.saturation)}, '
              'brightness ${_percent(brightness)}';
          final page = widget.step * 10;
          return Semantics(
            container: true,
            slider: true,
            label:
                widget.semanticLabel ??
                DesignLocalizations.of(context).colorAreaLabel,
            value: said(hsv.value),
            increasedValue: said((hsv.value + page).clamp(0.0, 1.0)),
            decreasedValue: said((hsv.value - page).clamp(0.0, 1.0)),
            onIncrease: () => _c.brightness = hsv.value + widget.step * 10,
            onDecrease: () => _c.brightness = hsv.value - widget.step * 10,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              includeSemantics: false,
              onKeyEvent: _key,
              child: FocusableActionDetector(
                focusNode: widget.focusNode,
                autofocus: widget.autofocus,
                mouseCursor: SystemMouseCursors.precise,
                onShowFocusHighlight: (on) => setState(() => _focused = on),
                onShowHoverHighlight: (on) => setState(() => _hovered = on),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = Size(box.maxWidth, box.maxHeight);
                    final t = widget.thumbSize;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) => _at(d.localPosition, size),
                      onPanStart: (_) => setState(() => _dragging = true),
                      onPanUpdate: (d) => _at(d.localPosition, size),
                      onPanEnd: (_) => setState(() => _dragging = false),
                      onPanCancel: () => setState(() => _dragging = false),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(child: widget.builder(context, area)),
                          Positioned(
                            left: hsv.saturation * size.width - t.width / 2,
                            top: (1 - hsv.value) * size.height - t.height / 2,
                            width: t.width,
                            height: t.height,
                            child: Center(
                              child: widget.thumbBuilder(context, area),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A slider for one [channel] of [controller]'s colour.
///
/// ```dart
/// DesignColorSlider(controller: controller, channel: DesignColorChannel.hue, trackBuilder: (context, channel, color) => const SizedBox(height: 8), thumbBuilder: (context, states) => const SizedBox(width: 16, height: 16))
/// ```
class DesignColorSlider extends StatefulWidget {
  /// A slider of [channel].
  const DesignColorSlider({
    super.key,
    required this.controller,
    required this.channel,
    required this.trackBuilder,
    required this.thumbBuilder,
    this.semanticLabel,
    this.thumbSize = const Size(44, 44),
    this.focusNode,
    this.autofocus = false,
  });

  /// The colour. The caller makes it, keeps it across rebuilds
  /// and disposes it.
  final DesignColorController controller;

  /// The channel it sets.
  final DesignColorChannel channel;

  /// Paints the track (the hue spectrum, or the colour fading out).
  final Widget Function(
    BuildContext context,
    DesignColorChannel channel,
    HSVColor color,
  )
  trackBuilder;

  /// Paints the thumb.
  final DesignHandleBuilder thumbBuilder;

  /// What a screen reader calls it; null:
  /// [DesignLocalizations.colorChannelLabel].
  final String? semanticLabel;

  /// The thumb's target.
  final Size thumbSize;

  /// Its focus. The caller's, who disposes it; null: its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  State<DesignColorSlider> createState() => _DesignColorSliderState();
}

class _DesignColorSliderState extends State<DesignColorSlider> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final ch = widget.channel;
    final c = widget.controller;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final t = widget.thumbSize;
    return ValueListenableBuilder<HSVColor>(
      valueListenable: c,
      builder: (context, hsv, _) => LayoutBuilder(
        builder: (context, box) {
          final usable = box.maxWidth - t.width;
          void at(double dx) {
            if (usable <= 0) return;
            var f = ((dx - t.width / 2) / usable).clamp(0.0, 1.0);
            if (rtl) f = 1 - f;
            _setChannel(c, ch, f * ch.max);
          }

          final f = ch.of(hsv) / ch.max;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragDown: (d) => at(d.localPosition.dx),
            onHorizontalDragStart: (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (d) => at(d.localPosition.dx),
            onHorizontalDragEnd: (_) => setState(() => _dragging = false),
            onHorizontalDragCancel: () => setState(() => _dragging = false),
            child: SizedBox(
              height: t.height,
              width: box.maxWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: t.width / 2,
                    right: t.width / 2,
                    top: 0,
                    bottom: 0,
                    // The track spans the row; its own height, centred.
                    child: Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ExcludeSemantics(
                          child: widget.trackBuilder(context, ch, hsv),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (rtl ? 1 - f : f) * usable,
                    top: 0,
                    width: t.width,
                    height: t.height,
                    child: DesignValueHandle(
                      value: ch.of(hsv),
                      max: ch.max,
                      step: ch == DesignColorChannel.hue ? 1 : 0.01,
                      pageStep: ch == DesignColorChannel.hue ? 10 : 0.1,
                      dragging: _dragging,
                      minimumSize: t,
                      focusNode: widget.focusNode,
                      autofocus: widget.autofocus,
                      semanticLabel:
                          widget.semanticLabel ??
                          DesignLocalizations.of(context).colorChannelLabel(ch),
                      semanticFormatterCallback: ch == DesignColorChannel.hue
                          ? (v) => '${v.round()} degrees'
                          : _percent,
                      onChanged: (v) => _setChannel(c, ch, v),
                      builder: widget.thumbBuilder,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// An area over a hue slider (and an alpha slider), on one controller.
///
/// ```dart
/// DesignColorPicker(controller: controller, areaBuilder: (context, area) => const SizedBox.expand(), areaThumbBuilder: (context, area) => const SizedBox(width: 16, height: 16), trackBuilder: (context, channel, color) => const SizedBox(height: 8), thumbBuilder: (context, states) => const SizedBox(width: 16, height: 16))
/// ```
class DesignColorPicker extends StatelessWidget {
  /// A picker over [controller].
  const DesignColorPicker({
    super.key,
    required this.controller,
    required this.areaBuilder,
    required this.areaThumbBuilder,
    required this.trackBuilder,
    required this.thumbBuilder,
    this.showAlpha = false,
    this.areaHeight = 180,
    this.layoutBuilder,
  });

  /// The colour. The caller makes it, keeps it across rebuilds
  /// and disposes it.
  final DesignColorController controller;

  /// Paints the area.
  final Widget Function(BuildContext context, DesignColorAreaDetails area)
  areaBuilder;

  /// Paints the area's thumb.
  final Widget Function(BuildContext context, DesignColorAreaDetails area)
  areaThumbBuilder;

  /// Paints a slider's track.
  final Widget Function(
    BuildContext context,
    DesignColorChannel channel,
    HSVColor color,
  )
  trackBuilder;

  /// Paints a slider's thumb.
  final DesignHandleBuilder thumbBuilder;

  /// Whether it has an alpha slider.
  final bool showAlpha;

  /// The area's height.
  final double areaHeight;

  /// Lays out the area and sliders (with the look's hex field, swatches);
  /// null: a column.
  final Widget Function(BuildContext context, List<Widget> parts)?
  layoutBuilder;

  @override
  Widget build(BuildContext context) {
    final parts = [
      SizedBox(
        height: areaHeight,
        child: DesignColorArea(
          controller: controller,
          builder: areaBuilder,
          thumbBuilder: areaThumbBuilder,
        ),
      ),
      DesignColorSlider(
        controller: controller,
        channel: DesignColorChannel.hue,
        trackBuilder: trackBuilder,
        thumbBuilder: thumbBuilder,
      ),
      if (showAlpha)
        DesignColorSlider(
          controller: controller,
          channel: DesignColorChannel.alpha,
          trackBuilder: trackBuilder,
          thumbBuilder: thumbBuilder,
        ),
    ];
    return layoutBuilder?.call(context, parts) ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: parts,
        );
  }
}
