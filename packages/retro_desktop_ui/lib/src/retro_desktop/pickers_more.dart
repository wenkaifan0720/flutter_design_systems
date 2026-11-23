// More pickers: a range slider, a colour picker, an inline calendar and a date range picker. They stand on
// ui_core's behaviour (two handles that never cross, the colour's channels, the month's keys and ranges); this file
// draws them in Retro Desktop's hand.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'controls.dart';
import 'glyphs.dart';
import 'internal/caps.dart';
import 'internal/face.dart';
import 'internal/parts.dart';
import 'layout.dart' show RetroDesktopReach;
import 'localizations.dart';
import 'press.dart';
import 'theme.dart';
import 'tokens.dart';

/// A slider's grip, in the appearance's hand: Platinum's grey block with its
/// ridges, Chisel's bevelled block. Held, it shows its press (Platinum's
/// darker grey, Chisel's sunken face).
// A slider's grip at its own size (16 by 24), the focus ring round it.
Widget _gripWithRing(RetroDesktopThemeData t, Set<WidgetState> states) =>
    SizedBox(
      width: 16,
      height: 24,
      child: RetroDesktopHighlight(
        shape: t.shapes.small,
        focused: states.contains(WidgetState.focused),
        child: CustomPaint(painter: _Grip(t, states)),
      ),
    );

class _Grip extends CustomPainter {
  const _Grip(this.t, this.states);
  final RetroDesktopThemeData t;
  final Set<WidgetState> states;

  @override
  void paint(Canvas canvas, Size size) {
    final c = t.colors;
    final held = states.contains(WidgetState.pressed);
    final box = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 16,
      height: 24,
    );
    if (t.chisel) {
      canvas.drawRect(
        box,
        Paint()..color = held ? retroDesktopChiselHeldBox(c) : c.platinum,
      );
      retroDesktopPaintChiselRect(
        canvas,
        box,
        retroDesktopChiselEdge(c, pressed: held),
      );
      return;
    }
    final shape = t.shapes.small.copyWith(
      side: BorderSide(color: c.control, width: t.strokes.regular),
    );
    canvas.drawPath(
      shape.getOuterPath(box),
      Paint()
        ..color = held
            ? (c.brightness == Brightness.dark ? c.platinum : c.platinumDark)
            : c.platinumLight,
    );
    shape.paint(canvas, box);
    for (var dx = -3.0; dx <= 3; dx += 3) {
      canvas.drawLine(
        Offset(box.center.dx + dx, box.top + 6),
        Offset(box.center.dx + dx, box.bottom - 6),
        Paint()..color = c.bevelDark,
      );
    }
  }

  @override
  bool shouldRepaint(_Grip old) => old.t != t || !setEquals(old.states, states);
}

/// The groove a slider runs in, the chosen stretch lit in the highlight.
class _Groove extends CustomPainter {
  const _Groove(this.t, this.start, this.end, {required this.rtl});
  final RetroDesktopThemeData t;
  final double start, end;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final c = t.colors;
    final groove = Rect.fromLTWH(0, (size.height - 6) / 2, size.width, 6);
    canvas.drawRect(groove, Paint()..color = c.paper);
    double x(double f) => groove.left + groove.width * (rtl ? 1 - f : f);
    final a = x(start), b = x(end);
    canvas.drawRect(
      Rect.fromLTRB(
        math.min(a, b),
        groove.top + 1,
        math.max(a, b),
        groove.bottom - 1,
      ),
      Paint()..color = c.highlight,
    );
    if (t.chisel) {
      retroDesktopPaintChiselRect(
        canvas,
        groove,
        retroDesktopChiselEdge(c, sunken: true),
      );
    } else {
      canvas.drawRect(
        groove.deflate(.5),
        Paint()
          ..color = c.control
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_Groove old) =>
      old.t != t || old.start != start || old.end != end || old.rtl != rtl;
}

/// A slider with two grips for a stretch of values: a price from and to, a
/// time window. The grips never cross; the arrows move the focused one.
/// ui_core's range slider carries both handles, their keys and semantics.
///
/// ```dart
/// RetroDesktopRangeSlider(label: 'Price', values: const RawRangeValues(20, 80), max: 100, onChanged: (_) {})
/// ```
class RetroDesktopRangeSlider extends StatelessWidget {
  /// Creates a [RetroDesktopRangeSlider].
  const RetroDesktopRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.semanticFormatterCallback,
    this.startLabel,
    this.endLabel,
  }) : assert(divisions == null || divisions > 0);

  /// The stretch chosen.
  final RawRangeValues values;

  /// Reports a new stretch; null disables the slider.
  final ValueChanged<RawRangeValues>? onChanged;

  /// The ends of the scale.
  final double min, max;

  /// How many steps the scale has; null is continuous.
  final int? divisions;

  /// The words above the slider.
  final String? label;

  /// A value's words for a screen reader.
  final String Function(double value)? semanticFormatterCallback;

  /// The two grips' names for a screen reader.
  final String? startLabel, endLabel;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final reach = math.max(44.0, RetroDesktopReach.least(context));
    final slider = Opacity(
      opacity: onChanged == null ? .5 : 1,
      child: RawRangeSlider(
        values: values,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        thumbSize: Size(reach, reach),
        semanticFormatterCallback: semanticFormatterCallback,
        startLabel:
            startLabel ??
            RawWidgetsLocalizations.of(context).rangeSliderStartLabel,
        endLabel:
            endLabel ?? RawWidgetsLocalizations.of(context).rangeSliderEndLabel,
        trackBuilder: (context, track) => SizedBox(
          height: 32,
          child: CustomPaint(
            painter: _Groove(t, track.start, track.end, rtl: rtl),
          ),
        ),
        // The handle centres its thumb loosely: the grip takes its own size,
        // so the ring has an outline to follow (just outside it: a grip is too
        // small to hold Chisel's dots).
        thumbBuilder: (context, index, states) => _gripWithRing(t, states),
      ),
    );
    // Each grip reaches 44 across, so the range's track starts half a reach
    // in from its sides; the slider's starts half its 20 px grip in. The range
    // stands the difference wider than its room each way, so the two tracks
    // start and end on one x down a column.
    final outset = reach / 2 - 10;
    final ranged = LayoutBuilder(
      builder: (context, room) => !room.hasBoundedWidth || outset <= 0
          ? slider
          : SizedBox(
              width: room.maxWidth,
              height: reach,
              child: OverflowBox(
                minWidth: room.maxWidth + 2 * outset,
                maxWidth: room.maxWidth + 2 * outset,
                child: slider,
              ),
            ),
    );
    if (label == null) return ranged;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(label!, style: t.textTheme.body)),
        const SizedBox(height: RetroDesktopSpacing.s4),
        ranged,
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawRangeValues>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<RawRangeValues>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(DoubleProperty('min', min, defaultValue: 0))
      ..add(DoubleProperty('max', max, defaultValue: 1))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        ObjectFlagProperty<String Function(double value)>.has(
          'semanticFormatterCallback',
          semanticFormatterCallback,
        ),
      )
      ..add(StringProperty('startLabel', startLabel, defaultValue: null))
      ..add(StringProperty('endLabel', endLabel, defaultValue: null));
  }
}

/// A colour chooser: a field of shade and brightness for the hue, a hue strip
/// (and an opacity strip with [showAlpha]), the swatch and its hex. ui_core's
/// colour picker carries the channels, their keys and semantics.
///
/// Give it a [value] and an [onChanged], or hand in a [controller] to set and
/// read the colour from outside.
///
/// ```dart
/// RetroDesktopColorPicker(value: RetroDesktopTheme.of(context).colors.highlight, onChanged: (color) {})
/// ```
class RetroDesktopColorPicker extends StatelessWidget {
  /// Creates a [RetroDesktopColorPicker].
  const RetroDesktopColorPicker({
    super.key,
    this.controller,
    this.value,
    this.onChanged,
    this.showAlpha = false,
    this.areaHeight = 160,
  }) : assert(
         controller == null || value == null,
         'A controller holds the colour: give the colour to the controller.',
       );

  /// The colour being chosen, for a caller that sets or reads it from
  /// outside. The caller makes it and disposes it; the picker only listens.
  /// Null: the picker keeps a controller of its own, starting at [value], and
  /// disposes it.
  final RawColorController? controller;

  /// The colour shown when no [controller] is handed in; a new value moves the
  /// picker to it. Null starts at black.
  final Color? value;

  /// Called with the colour each time it changes: the user's picks, and with a
  /// [controller], any change made to it. Moving to a new [value] is not
  /// reported.
  final ValueChanged<Color>? onChanged;

  /// Whether an opacity strip shows.
  final bool showAlpha;

  /// The shade field's height.
  final double areaHeight;

  @override
  Widget build(BuildContext context) => _ColorPickerHost(this);

  // The picker over [controller], the handed-in one or its own.
  Widget _draw(BuildContext context, RawColorController controller) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    Widget well(Widget child) => DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(
        shape: t.shapes.small.copyWith(
          side: BorderSide(color: c.control, width: t.strokes.regular),
        ),
      ),
      child: child,
    );
    // On a phone a strip reaches a finger, 48 high with its 14 drawn in the
    // middle, as the range slider's grips do; on a desk 44.
    final reach = math.max(44.0, RetroDesktopReach.least(context));
    final picker = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: areaHeight,
          child: RawColorArea(
            controller: controller,
            builder: (context, area) => well(
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFFFFF),
                      HSVColor.fromAHSV(1, area.color.hue, 1, 1).toColor(),
                    ],
                  ),
                ),
                child: const DecoratedBox(
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
            thumbBuilder: (context, area) => RetroDesktopHighlight(
              shape: const RoundedRectangleBorder(),
              focused: area.states.contains(WidgetState.focused),
              // The mark stays whole inside the field: at an edge it steps in
              // by its half (at full brightness, centred on the field's top,
              // half of it hung over the frame).
              child: Transform.translate(
                offset: Offset(
                  (1 - 2 * area.color.saturation) * 7,
                  (2 * area.color.value - 1) * 7,
                ),
                child: Center(
                  child: SizedBox.square(
                    dimension: 12,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: area.color.toColor(),
                        shape: t.shapes.small.copyWith(
                          side: const BorderSide(
                            color: Color(0xFFFFFFFF),
                            width: 2,
                          ),
                        ),
                        shadows: const [
                          BoxShadow(color: Color(0xFF000000), spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final strip in [
          RawColorChannel.hue,
          if (showAlpha) RawColorChannel.alpha,
        ])
          RawColorSlider(
            controller: controller,
            channel: strip,
            thumbSize: Size.square(reach),
            trackBuilder: (context, channel, color) => SizedBox(
              height: 14,
              child: well(
                DecoratedBox(
                  decoration: BoxDecoration(
                    // From the start edge, as the thumb runs: right to left, the rainbow mirrors with it.
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: channel == RawColorChannel.alpha
                          ? [
                              color.toColor().withAlpha(0),
                              color.toColor().withAlpha(255),
                            ]
                          : [
                              for (var h = 0; h <= 360; h += 60)
                                HSVColor.fromAHSV(
                                  1,
                                  h.toDouble(),
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
            thumbBuilder: (context, states) => _gripWithRing(t, states),
          ),
        const SizedBox(height: RetroDesktopSpacing.s8),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Row(
            children: [
              SizedBox.square(
                dimension: 24,
                child: well(ColoredBox(color: controller.color)),
              ),
              const SizedBox(width: RetroDesktopSpacing.s8),
              Text(
                controller.hex,
                style: t.textTheme.mono(13, 16).copyWith(color: c.text),
              ),
            ],
          ),
        ),
      ],
    );
    // From 600 up the shade field keeps a month's width at its column's
    // start, as the calendar beside it does.
    if (MediaQuery.sizeOf(context).width < 600) return picker;
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: picker,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawColorController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(ColorProperty('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<Color>>.has('onChanged', onChanged))
      ..add(FlagProperty('showAlpha', value: showAlpha, ifTrue: 'showAlpha'))
      ..add(DoubleProperty('areaHeight', areaHeight, defaultValue: 160));
  }
}

// A colour picker's controller: the handed-in one, or one of its own made from
// the picker's value and disposed with it. Reports each change to onChanged.
class _ColorPickerHost extends StatefulWidget {
  const _ColorPickerHost(this.picker);

  final RetroDesktopColorPicker picker;

  @override
  State<_ColorPickerHost> createState() => _ColorPickerHostState();
}

class _ColorPickerHostState extends State<_ColorPickerHost> {
  RawColorController? _own;
  // Set while the picker moves to a new value, which is not reported.
  bool _following = false;

  RawColorController get _controller => widget.picker.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.picker.controller == null) {
      _own = RawColorController(widget.picker.value ?? const Color(0xFF000000));
    }
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(_ColorPickerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final handed = widget.picker.controller;
    if (handed != oldWidget.picker.controller) {
      final old = oldWidget.picker.controller ?? _own!;
      old.removeListener(_changed);
      if (handed == null) {
        // Its own starts where the handed-in one was, unless a value is given.
        _own = RawColorController(widget.picker.value ?? old.color);
      } else {
        _own?.dispose();
        _own = null;
      }
      _controller.addListener(_changed);
    }
    final own = _own;
    final value = widget.picker.value;
    if (own != null &&
        value != null &&
        value != oldWidget.picker.value &&
        value != own.color) {
      _following = true;
      own.color = value;
      _following = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() {
    if (!_following) widget.picker.onChanged?.call(_controller.color);
  }

  @override
  Widget build(BuildContext context) =>
      widget.picker._draw(context, _controller);
}

/// A month's day in the calendar's grid: the chosen day (and a range's ends)
/// lit in the highlight, the days between tinted, today outlined, the days of
/// other months and the days off-limits quieter. While a range waits for its
/// end, the day under the pointer or the keyboard (ui_core's
/// [RawCalendarDayDetails.isPreviewEnd]) is lit as the end it would be, so the
/// preview's band ends where the range would.
Widget _day(
  BuildContext context,
  RawCalendarDayDetails day,
  Set<WidgetState> states,
) {
  final t = RetroDesktopTheme.of(context);
  final c = t.colors;
  final words = RetroDesktopLocalizations.of(context);
  final lit =
      day.selected || day.isRangeStart || day.isRangeEnd || day.isPreviewEnd;
  final tint = !lit && (day.inRange || day.inPreview);
  final ink = lit
      ? c.onHighlight
      : (!day.enabled || !day.inMonth)
      ? c.textTertiary
      : c.text;
  Widget cell = DecoratedBox(
    decoration: day.isToday && !lit
        ? ShapeDecoration(
            color: tint ? c.highlightContainer : null,
            shape: t.shapes.small.copyWith(
              side: BorderSide(color: c.text, width: t.strokes.regular),
            ),
          )
        : BoxDecoration(
            color: lit
                ? c.highlight
                : tint
                ? c.highlightContainer
                : null,
          ),
    // The month's numbers shrink together to their cells, the widest with a
    // gap either side, rather than running into each other (twice the text
    // size on a phone read "21222324", and 4 px apart "1920" still read as
    // one number), as Flutter's own calendar caps its day numbers.
    child: LayoutBuilder(
      builder: (context, box) {
        Widget number = Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RetroDesktopCaps(
              style: t.textTheme.body,
              Text(
                words.formatInteger(day.date.day),
                style: t.textTheme.body.copyWith(color: ink),
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        );
        if (!box.hasBoundedWidth) return number;
        final widest = _widestDay(context, t.textTheme.body);
        final room = box.maxWidth - 2 * _dayGap;
        final size = t.textTheme.body.fontSize ?? 14;
        final scale = MediaQuery.textScalerOf(context).scale(size) / size;
        if (widest > 0 && widest * scale > room) {
          number = MediaQuery.withClampedTextScaling(
            maxScaleFactor: math.max(.5, room / widest),
            child: number,
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RetroDesktopSpacing.s2,
          ),
          child: number,
        );
      },
    ),
  );
  if (states.contains(WidgetState.pressed) && !lit) {
    cell = retroDesktopHeldGround(t, held: true, child: cell);
  }
  return RetroDesktopHighlight(
    shape: const RoundedRectangleBorder(),
    focused: states.contains(WidgetState.focused),
    inside: true,
    insideColor: lit ? ink : null,
    child: SizedBox(
      height: math.max(32, RetroDesktopReach.least(context)),
      child: cell,
    ),
  );
}

Widget _monthHead(
  BuildContext context,
  RawCalendarHeaderDetails h, {
  bool back = true,
  bool on = true,
}) {
  final t = RetroDesktopTheme.of(context);
  // Months side by side step from their outer ends: the first month's head
  // has the step back, the last's the step on. An inner step keeps its room,
  // unseen, so every month's name stands on its grid's middle.
  Widget step(bool shown, Widget button) => shown
      ? button
      : ExcludeSemantics(
          child: Visibility.maintain(visible: false, child: button),
        );
  return Padding(
    padding: const EdgeInsets.only(bottom: RetroDesktopSpacing.s4),
    // The month between its two steps, one group in the middle.
    child: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          step(
            back,
            RetroDesktopIconButton(
              // The arrows point the way the months run: the other way right to left.
              Directionality.of(context) == TextDirection.rtl
                  ? RetroDesktopGlyphs.chevronRight
                  : RetroDesktopGlyphs.chevronLeft,
              label: RawWidgetsLocalizations.of(context).previousMonthTooltip,
              onPressed: h.previous,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RetroDesktopSpacing.s12,
              ),
              child: Text(
                h.label,
                textAlign: TextAlign.center,
                style: t.textTheme.chrome.copyWith(color: t.colors.text),
              ),
            ),
          ),
          step(
            on,
            RetroDesktopIconButton(
              Directionality.of(context) == TextDirection.rtl
                  ? RetroDesktopGlyphs.chevronLeft
                  : RetroDesktopGlyphs.chevronRight,
              label: RawWidgetsLocalizations.of(context).nextMonthTooltip,
              onPressed: h.next,
            ),
          ),
        ],
      ),
    ),
  );
}

// The room either side of a day's number, so two numbers side by side never
// read as one.
const double _dayGap = 4;

// The widest of a month's day numbers in [style] at the plain text size, by
// locale and style: measured once, not in each of the month's 42 cells.
final Map<(String, TextStyle), double> _dayWidths = {};

double _widestDay(BuildContext context, TextStyle style) {
  final words = RetroDesktopLocalizations.of(context);
  final key = (Localizations.localeOf(context).toString(), style);
  return _dayWidths[key] ??= () {
    var most = 0.0;
    for (var d = 1; d <= 31; d++) {
      final tp = TextPainter(
        text: TextSpan(text: words.formatInteger(d), style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      most = math.max(most, tp.width);
      tp.dispose();
    }
    return most;
  }();
}

Widget _weekday(BuildContext context, int weekday, String label) {
  final t = RetroDesktopTheme.of(context);
  final style = t.textTheme.small.copyWith(color: t.colors.textSecondary);
  // The week's names show their first letters, all seven, once any of them
  // is wider than its column, as the date picker's do (twice the text size
  // on a phone broke "Su" into "S" over "u"; chosen name by name, the head
  // read "Su M Tu W").
  final names = RawWidgetsLocalizations.of(context);
  return LayoutBuilder(
    builder: (context, box) {
      var fits = true;
      if (box.hasBoundedWidth) {
        for (final name in {
          label,
          for (var d = 1; d <= 7; d++) names.formatShortWeekday(d),
        }) {
          final tp = TextPainter(
            text: TextSpan(text: name, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          if (tp.width > box.maxWidth - 4) fits = false;
          tp.dispose();
          if (!fits) break;
        }
      }
      return Center(
        child: Text(
          fits ? label : label.characters.first,
          style: style,
          maxLines: 1,
          softWrap: false,
        ),
      );
    },
  );
}

/// A month or two on paper, in a well: a day, a set of days or a range,
/// chosen with the pointer or the arrows. ui_core's calendar carries the
/// keys, the selection and the announcements.
///
/// For one day, give it [firstDate], [lastDate], a [value] and an
/// [onChanged]. For a range or a set of days, or to turn the month from
/// outside, hand in a [controller].
///
/// ```dart
/// RetroDesktopCalendar(firstDate: DateTime(2026), lastDate: DateTime(2027), value: DateTime(2026, 11, 6), onChanged: (day) {})
/// ```
class RetroDesktopCalendar extends StatelessWidget {
  /// Creates a [RetroDesktopCalendar].
  const RetroDesktopCalendar({
    super.key,
    this.controller,
    this.firstDate,
    this.lastDate,
    this.value,
    this.months = 1,
    this.onChanged,
    this.firstWeekday,
    this.minDayWidth = 36,
  }) : assert(minDayWidth > 0),
       assert(
         controller != null || (firstDate != null && lastDate != null),
         'Without a controller, a calendar takes a firstDate and a lastDate.',
       ),
       assert(
         controller == null ||
             (firstDate == null && lastDate == null && value == null),
         'A controller holds the limits and the choice: give them to it.',
       );

  /// What is chosen, the month shown and the limits, for a caller that sets or
  /// reads them from outside (a range, a set of days). The caller makes it and
  /// disposes it; the calendar only listens. Null: the calendar keeps a
  /// controller of its own for one day between [firstDate] and [lastDate], and
  /// disposes it.
  final RawCalendarController? controller;

  /// The first and last days that can be chosen, when no [controller] is
  /// handed in.
  final DateTime? firstDate, lastDate;

  /// The chosen day when no [controller] is handed in; a new value chooses it
  /// and turns to its month.
  final DateTime? value;

  /// How many months stand side by side.
  final int months;

  /// Called with the day the user chooses. With a [controller], read the
  /// whole choice (a range, the days) from it.
  final ValueChanged<DateTime>? onChanged;

  /// The week's first day (`DateTime.monday`..`sunday`); null starts it where
  /// the locale does (`RawWidgetsLocalizations.firstDayOfWeek`: Sunday in English).
  final int? firstWeekday;

  /// The narrowest a day may be, so it keeps its target in a narrow month.
  final double minDayWidth;

  /// The room between two months side by side.
  static const double _monthGap = 16;

  @override
  Widget build(BuildContext context) => _CalendarHost(this);

  // The calendar over [controller], the handed-in one or its own.
  Widget _draw(BuildContext context, RawCalendarController controller) {
    final t = RetroDesktopTheme.of(context);
    // Seven days reach a finger's width on a phone only with a narrow margin.
    final pad = RetroDesktopReach.least(context) >= 44 ? 4.0 : 8.0;
    // Under a finger a day is at least the touch floor wide, and no wider than its seventh where seven of them fit
    // (a day overhanging its seventh would be outlined past where a tap reaches it, over the next day's edge).
    final day = math.max(
      minDayWidth,
      RetroDesktopReach.padsAcross(context)
          ? DesignTapTargets.of(context).floorOn().width
          : RetroDesktopReach.least(context),
    );
    final box = retroDesktopSunkenBox(
      context,
      states: const {},
      padding: EdgeInsets.all(pad),
      child: RawCalendarDatePicker(
        controller: controller,
        months: months,
        onChanged: onChanged,
        firstWeekday: firstWeekday,
        minDayWidth: day,
        dayBuilder: _day,
        headerBuilder: (context, h) {
          final shown = controller.month;
          final index =
              (h.month.year - shown.year) * 12 + h.month.month - shown.month;
          return _monthHead(
            context,
            h,
            back: index == 0,
            on: index == months - 1,
          );
        },
        weekdayBuilder: _weekday,
        monthsBuilder: (context, grids) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, grid) in grids.indexed) ...[
              if (i > 0) const SizedBox(width: _monthGap),
              Expanded(child: grid),
            ],
          ],
        ),
      ),
    );
    // From 600 up a month keeps its own width (seven days), at its column's
    // start, rather than its column's.
    if (MediaQuery.sizeOf(context).width < 600) return box;
    final rim = retroDesktopFaceRim(t);
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              months * 7 * day +
              (months - 1) * _monthGap +
              2 * (pad * t.density.horizontal + rim),
        ),
        child: box,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawCalendarController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>(
          'firstDate',
          firstDate,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>('lastDate', lastDate, defaultValue: null),
      )
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(IntProperty('months', months, defaultValue: 1))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
      )
      ..add(IntProperty('firstWeekday', firstWeekday, defaultValue: null))
      ..add(DoubleProperty('minDayWidth', minDayWidth, defaultValue: 36));
  }
}

// A calendar's controller: the handed-in one, or one of its own for a single
// day between the calendar's first and last dates, disposed with it.
class _CalendarHost extends StatefulWidget {
  const _CalendarHost(this.calendar);

  final RetroDesktopCalendar calendar;

  @override
  State<_CalendarHost> createState() => _CalendarHostState();
}

class _CalendarHostState extends State<_CalendarHost> {
  RawCalendarController? _own;

  RawCalendarController get _controller => widget.calendar.controller ?? _own!;

  RawCalendarController _make(DateTime? chosen, {DateTime? month}) =>
      RawCalendarController(
        firstDate: widget.calendar.firstDate!,
        lastDate: widget.calendar.lastDate!,
        selectedDate: chosen,
        initialMonth: month,
      );

  @override
  void initState() {
    super.initState();
    if (widget.calendar.controller == null) {
      _own = _make(widget.calendar.value);
    }
  }

  @override
  void didUpdateWidget(_CalendarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final now = widget.calendar, was = oldWidget.calendar;
    final own = _own;
    if (now.controller != null) {
      own?.dispose();
      _own = null;
      return;
    }
    if (own == null ||
        now.firstDate != was.firstDate ||
        now.lastDate != was.lastDate) {
      // A new one of its own for the new limits, keeping the choice and the
      // shown month; a new value is chosen and shown instead.
      final from = was.controller ?? own!;
      final moved = !DateUtils.isSameDay(now.value, was.value);
      _own = _make(
        moved ? now.value : from.selectedDate,
        month: moved ? now.value ?? from.month : from.month,
      );
      own?.dispose();
      return;
    }
    final value = now.value;
    if (!DateUtils.isSameDay(value, was.value) &&
        !DateUtils.isSameDay(value, own.selectedDate)) {
      if (value == null) {
        own.clear();
      } else {
        own.focus(value, months: now.months);
        own.select(value);
      }
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.calendar._draw(context, _controller);
}

/// A stretch of days: the range read out above two months (one on a phone),
/// its ends lit and the days between tinted, the hover's range previewed.
///
/// ```dart
/// RetroDesktopDateRangePicker(labelText: 'Stay', firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (_) {})
/// ```
class RetroDesktopDateRangePicker extends StatefulWidget {
  /// Creates a [RetroDesktopDateRangePicker].
  const RetroDesktopDateRangePicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.onChanged,
    this.labelText,
    this.initialMonth,
  });

  /// The first and last days that can be chosen.
  final DateTime firstDate, lastDate;

  /// The range chosen first.
  final RawDateRange? value;

  /// Reports each change of the range; null shows it still.
  final ValueChanged<RawDateRange?>? onChanged;

  /// The words above the readout.
  final String? labelText;

  /// The month shown first.
  final DateTime? initialMonth;

  @override
  State<RetroDesktopDateRangePicker> createState() => _RangePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('firstDate', firstDate))
      ..add(DiagnosticsProperty<DateTime>('lastDate', lastDate))
      ..add(
        DiagnosticsProperty<RawDateRange>('value', value, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<RawDateRange?>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<DateTime>(
          'initialMonth',
          initialMonth,
          defaultValue: null,
        ),
      );
  }
}

class _RangePickerState extends State<RetroDesktopDateRangePicker> {
  late final RawCalendarController _calendar = RawCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: RawCalendarMode.range,
    selectedRange: widget.value,
    initialMonth: widget.initialMonth ?? widget.value?.start,
  );

  @override
  void dispose() {
    _calendar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final words = RetroDesktopLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) => ListenableBuilder(
        listenable: _calendar,
        builder: (context, _) {
          final range = _calendar.selectedRange;
          final readout = range == null
              ? '—'
              : range.end == null
              ? words.formatDate(range.start)
              : '${words.formatDate(range.start)} – ${words.formatDate(range.end!)}';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.labelText != null)
                ExcludeSemantics(
                  child: Text(widget.labelText!, style: t.textTheme.body),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: RetroDesktopSpacing.s6,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    readout,
                    style: t.textTheme.chrome.copyWith(color: t.colors.text),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: widget.onChanged == null,
                child: RetroDesktopCalendar(
                  controller: _calendar,
                  months: box.maxWidth >= 560 ? 2 : 1,
                  onChanged: (_) =>
                      widget.onChanged?.call(_calendar.selectedRange),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
