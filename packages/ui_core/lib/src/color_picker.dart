/// A colour picker, headless: a controller over hue, saturation, brightness
/// and alpha (with hex in and out), a saturation-brightness area, channel
/// sliders on [RawValueHandle], and [RawColorPicker] composing them.
/// Every part takes the keyboard (arrows a step, Shift ten) and tells a
/// screen reader its value; the hex text is the look's own field on
/// [RawColorController.hex] and [RawColorController.setHex].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/focus_visible.dart';
import 'localizations.dart';
import 'value_handle.dart';

/// A colour being picked, as hue, saturation, brightness and alpha.
///
/// The caller makes it (a State's field, say), keeps it across rebuilds
/// and disposes it; a widget it is given to only listens to it.
///
/// ```dart
/// RawColorController(const Color(0xFF3366FF))
/// ```
class RawColorController extends ValueNotifier<HSVColor> {
  /// A picker starting at [initial].
  RawColorController([Color initial = const Color(0xFF000000)])
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

/// A channel a [RawColorSlider] sets.
enum RawColorChannel {
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

void _setChannel(RawColorController c, RawColorChannel ch, double v) {
  switch (ch) {
    case RawColorChannel.hue:
      c.hue = v;
    case RawColorChannel.saturation:
      c.saturation = v;
    case RawColorChannel.brightness:
      c.brightness = v;
    case RawColorChannel.alpha:
      c.alpha = v;
  }
}

/// What the look paints the area from.
@immutable
class RawColorAreaDetails {
  /// The state; the area makes it.
  const RawColorAreaDetails({required this.color, required this.states});

  /// The colour: its hue fills the area, its saturation is the thumb's x
  /// (0 left to 1 right) and its brightness the thumb's height (1 at top).
  final HSVColor color;

  /// The thumb's states (focused while the keyboard is on it, hovered,
  /// dragged and pressed while dragged).
  final Set<WidgetState> states;
}

/// A saturation (across) and brightness (up) area for [controller]'s hue.
///
/// ```dart
/// RawColorArea(controller: controller, builder: (context, area) => const SizedBox.expand(), thumbBuilder: (context, area) => const SizedBox(width: 16, height: 16))
/// ```
class RawColorArea extends StatefulWidget {
  /// An area over [controller].
  const RawColorArea({
    super.key,
    required this.controller,
    required this.builder,
    required this.thumbBuilder,
    this.step = 0.01,
    this.semanticLabel,
    this.thumbSize = const Size(40, 40),
    this.focusNode,
    this.autofocus = false,
  }) : assert(step > 0);

  /// The colour. The caller makes it, keeps it across rebuilds
  /// and disposes it.
  final RawColorController controller;

  /// Paints the area (the hue's gradients).
  final Widget Function(BuildContext context, RawColorAreaDetails area) builder;

  /// Paints the thumb, centred in its [thumbSize] target.
  final Widget Function(BuildContext context, RawColorAreaDetails area)
  thumbBuilder;

  /// An arrow's change (Shift: ten times).
  final double step;

  /// What a screen reader calls it; null:
  /// [RawWidgetsLocalizations.colorAreaLabel].
  final String? semanticLabel;

  /// The thumb's target.
  final Size thumbSize;

  /// Its focus.
  ///
  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  State<RawColorArea> createState() => _DesignColorAreaState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawColorController>('controller', controller))
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, RawColorAreaDetails area)
        >.has('builder', builder),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, RawColorAreaDetails area)
        >.has('thumbBuilder', thumbBuilder),
      )
      ..add(DoubleProperty('step', step, defaultValue: 0.01))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<Size>(
          'thumbSize',
          thumbSize,
          defaultValue: const Size(40, 40),
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

class _DesignColorAreaState extends State<RawColorArea> {
  bool _focused = false;
  // Shown as a browser's :focus-visible shows it (internal/focus_visible.dart).
  late final RawFocusShown _focus;
  bool _hovered = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _focus = RawFocusShown((on) => setState(() => _focused = on));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  RawColorController get _c => widget.controller;

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
    final words = RawWidgetsLocalizations.of(context);
    // The reader's direction, for what a screen reader says of the area.
    final reading = Directionality.maybeOf(context);
    // A colour area is not mirrored right to left: saturation grows rightward.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<HSVColor>(
        valueListenable: _c,
        builder: (context, hsv, _) {
          final area = RawColorAreaDetails(
            color: hsv,
            states: {
              if (_focused) WidgetState.focused,
              if (_hovered) WidgetState.hovered,
              if (_dragging) ...{WidgetState.pressed, WidgetState.dragged},
            },
          );
          // "Saturation 40%, Brightness 60%", in the reader's words, digits
          // and percent sign.
          String said(double brightness) => [
            '${words.colorChannelLabel(RawColorChannel.saturation)} '
                '${words.formatPercent(hsv.saturation)}',
            '${words.colorChannelLabel(RawColorChannel.brightness)} '
                '${words.formatPercent(brightness)}',
          ].join(words.listSeparator);
          final page = widget.step * 10;
          return Semantics(
            container: true,
            slider: true,
            textDirection: reading,
            label: widget.semanticLabel ?? words.colorAreaLabel,
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
                onShowFocusHighlight: _focus.focused,
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
/// RawColorSlider(controller: controller, channel: RawColorChannel.hue, trackBuilder: (context, channel, color) => const SizedBox(height: 8), thumbBuilder: (context, states) => const SizedBox(width: 16, height: 16))
/// ```
class RawColorSlider extends StatefulWidget {
  /// A slider of [channel].
  const RawColorSlider({
    super.key,
    required this.controller,
    required this.channel,
    required this.trackBuilder,
    required this.thumbBuilder,
    this.semanticLabel,
    this.thumbSize = const Size(40, 40),
    this.focusNode,
    this.autofocus = false,
  });

  /// The colour. The caller makes it, keeps it across rebuilds
  /// and disposes it.
  final RawColorController controller;

  /// The channel it sets.
  final RawColorChannel channel;

  /// Paints the track (the hue spectrum, or the colour fading out).
  final Widget Function(
    BuildContext context,
    RawColorChannel channel,
    HSVColor color,
  )
  trackBuilder;

  /// Paints the thumb.
  final RawHandleBuilder thumbBuilder;

  /// What a screen reader calls it; null:
  /// [RawWidgetsLocalizations.colorChannelLabel].
  final String? semanticLabel;

  /// The thumb's target.
  final Size thumbSize;

  /// Its focus.
  ///
  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  State<RawColorSlider> createState() => _DesignColorSliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawColorController>('controller', controller))
      ..add(EnumProperty<RawColorChannel>('channel', channel))
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            RawColorChannel channel,
            HSVColor color,
          )
        >.has('trackBuilder', trackBuilder),
      )
      ..add(
        ObjectFlagProperty<RawHandleBuilder>.has('thumbBuilder', thumbBuilder),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<Size>(
          'thumbSize',
          thumbSize,
          defaultValue: const Size(40, 40),
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

class _DesignColorSliderState extends State<RawColorSlider> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final ch = widget.channel;
    final c = widget.controller;
    final words = RawWidgetsLocalizations.of(context);
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
          // A press on the track moves the thumb there (the click cursor);
          // the thumb grabs, and a drag holds (grabbing) over the slider.
          return MouseRegion(
            cursor: _dragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.click,
            child: GestureDetector(
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
                      child: RawValueHandle(
                        value: ch.of(hsv),
                        max: ch.max,
                        step: ch == RawColorChannel.hue ? 1 : 0.01,
                        pageStep: ch == RawColorChannel.hue ? 10 : 0.1,
                        dragging: _dragging,
                        minimumSize: t,
                        focusNode: widget.focusNode,
                        autofocus: widget.autofocus,
                        semanticLabel:
                            widget.semanticLabel ?? words.colorChannelLabel(ch),
                        // In the reader's digits: the hue in degrees ("270°"),
                        // the others as a percentage.
                        semanticFormatterCallback: ch == RawColorChannel.hue
                            ? (v) => '${words.formatDecimal(v.round())}°'
                            : words.formatPercent,
                        onChanged: (v) => _setChannel(c, ch, v),
                        builder: widget.thumbBuilder,
                      ),
                    ),
                  ],
                ),
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
/// RawColorPicker(controller: controller, areaBuilder: (context, area) => const SizedBox.expand(), areaThumbBuilder: (context, area) => const SizedBox(width: 16, height: 16), trackBuilder: (context, channel, color) => const SizedBox(height: 8), thumbBuilder: (context, states) => const SizedBox(width: 16, height: 16))
/// ```
class RawColorPicker extends StatelessWidget {
  /// A picker over [controller].
  const RawColorPicker({
    super.key,
    required this.controller,
    required this.areaBuilder,
    required this.areaThumbBuilder,
    required this.trackBuilder,
    required this.thumbBuilder,
    this.showAlpha = false,
    this.areaHeight = 180,
    this.layoutBuilder,
  }) : assert(areaHeight > 0);

  /// The colour. The caller makes it, keeps it across rebuilds
  /// and disposes it.
  final RawColorController controller;

  /// Paints the area.
  final Widget Function(BuildContext context, RawColorAreaDetails area)
  areaBuilder;

  /// Paints the area's thumb.
  final Widget Function(BuildContext context, RawColorAreaDetails area)
  areaThumbBuilder;

  /// Paints a slider's track.
  final Widget Function(
    BuildContext context,
    RawColorChannel channel,
    HSVColor color,
  )
  trackBuilder;

  /// Paints a slider's thumb.
  final RawHandleBuilder thumbBuilder;

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
        child: RawColorArea(
          controller: controller,
          builder: areaBuilder,
          thumbBuilder: areaThumbBuilder,
        ),
      ),
      RawColorSlider(
        controller: controller,
        channel: RawColorChannel.hue,
        trackBuilder: trackBuilder,
        thumbBuilder: thumbBuilder,
      ),
      if (showAlpha)
        RawColorSlider(
          controller: controller,
          channel: RawColorChannel.alpha,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawColorController>('controller', controller))
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, RawColorAreaDetails area)
        >.has('areaBuilder', areaBuilder),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, RawColorAreaDetails area)
        >.has('areaThumbBuilder', areaThumbBuilder),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            RawColorChannel channel,
            HSVColor color,
          )
        >.has('trackBuilder', trackBuilder),
      )
      ..add(
        ObjectFlagProperty<RawHandleBuilder>.has('thumbBuilder', thumbBuilder),
      )
      ..add(
        FlagProperty(
          'showAlpha',
          value: showAlpha,
          ifTrue: 'showAlpha',
          defaultValue: false,
        ),
      )
      ..add(DoubleProperty('areaHeight', areaHeight, defaultValue: 180))
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, List<Widget> parts)
        >.has('layoutBuilder', layoutBuilder),
      );
  }
}
