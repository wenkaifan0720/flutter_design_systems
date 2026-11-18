/// Appliance's choices, each one mechanical object: [ApplianceCheckbox] (a
/// latching key that stays down with a tick), [ApplianceRadio] (a round
/// preset key, down with its lamp lit), [ApplianceSwitch] (a slide switch),
/// [ApplianceSegmentedButton] (a slide selector: a block sliding in a
/// trough) and [ApplianceStepper] (two keys round a display window).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/spring_value.dart';
import 'material.dart';
import 'theme.dart';

Color _none(Color c) => c.withValues(alpha: 0);

/// A checkbox: a small square key that latches. Checked, it stays down in
/// the panel with a tick printed on it; unchecked, it stands up, blank.
/// [tristate] adds a third, mixed state (a dash), for a box over a group.
///
/// A null [onChanged] disables it. [semanticLabel] names it for a screen
/// reader when no words stand beside it; a row that holds it
/// ([ApplianceListTile]) names it with its own title.
///
/// Reads [style]'s `fill` (the key), `foreground` (the tick) and `edge` in
/// its states, then [ApplianceThemeData.toggleStyle]'s.
///
/// ```dart
/// ApplianceCheckbox(value: gift, onChanged: (value) => setState(() => gift = value!), semanticLabel: 'Gift wrap')
/// ```
class ApplianceCheckbox extends StatelessWidget {
  /// A checkbox at [value].
  const ApplianceCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.semanticLabel,
    this.focusNode,
    this.style,
  }) : assert(tristate || value != null);

  /// Checked, unchecked, or (with [tristate]) null for mixed.
  final bool? value;

  /// Called with the next value; null disables it.
  final ValueChanged<bool?>? onChanged;

  /// Whether null (mixed) is a state of its own.
  final bool tristate;

  /// Its name for a screen reader.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Its style, over [ApplianceThemeData.toggleStyle].
  final ApplianceStyle? style;

  /// The key's side.
  static const double size = 24;

  bool? get _next => switch (value) {
    false => true,
    true => tristate ? null : false,
    null => false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(_next),
      focusNode: focusNode,
      checked: value ?? false,
      mixed: value == null,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.toggleStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final latched = value != false;
        final down = latched || states.contains(WidgetState.pressed);
        final radius = ApplianceMetrics.smallKeyRadius;
        var face = down
            ? ApplianceFace.keyDown(c, radius: radius)
            : ApplianceFace.key(c, radius: radius);
        if (disabled) face = face.copyWith(lift: face.lift * 0.4);
        face = layered.on(
          face.copyWith(
            foreground: disabled ? c.printDisabled : c.print,
            focus: states.contains(WidgetState.focused)
                ? c.focus
                : _none(c.focus),
          ),
        );
        return DesignTapTarget(
          child: SizedBox.square(
            dimension: size,
            child: AnimatedApplianceSurface(
              face: face,
              child: ApplianceSpringValue(
                value: latched ? 1 : 0,
                spring: ApplianceMotion.lamp,
                spatial: false,
                builder: (context, t, _) => CustomPaint(
                  painter: _TickPainter(
                    t.clamp(0.0, 1.0),
                    face.foreground,
                    mixed: value == null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.t, this.color, {required this.mixed});

  final double t;
  final Color color;
  final bool mixed;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    // Drawn a pixel low: the key sits down when it shows.
    if (mixed) {
      canvas.drawLine(
        Offset(w * 0.3, h * 0.5),
        Offset(w * 0.7, h * 0.5),
        paint,
      );
      return;
    }
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.27, h * 0.5)
        ..lineTo(w * 0.44, h * 0.66)
        ..lineTo(w * 0.74, h * 0.34),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) =>
      old.t != t || old.color != color || old.mixed != mixed;
}

/// A radio: a round preset key, one of a bank. The chosen one stays down
/// with its lamp lit; the rest stand up with their lamps out. Choosing one
/// lets the last one up.
///
/// A null [onChanged] disables it. Reads [style]'s `fill` and `edge` in its
/// states, then [ApplianceThemeData.toggleStyle]'s.
///
/// ```dart
/// ApplianceRadio<String>(value: 'standard', groupValue: delivery, onChanged: (value) => setState(() => delivery = value), semanticLabel: 'Standard delivery')
/// ```
class ApplianceRadio<T> extends StatelessWidget {
  /// The radio for [value] in a group at [groupValue].
  const ApplianceRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.style,
  });

  /// This radio's value.
  final T value;

  /// The group's chosen value.
  final T? groupValue;

  /// Called with [value] when chosen; null disables it.
  final ValueChanged<T>? onChanged;

  /// Its name for a screen reader.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Its style, over [ApplianceThemeData.toggleStyle].
  final ApplianceStyle? style;

  /// The key's diameter.
  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final chosen = value == groupValue;
    return DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(value),
      focusNode: focusNode,
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.toggleStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final down = chosen || states.contains(WidgetState.pressed);
        var face = down
            ? ApplianceFace.keyDown(c, circle: true)
            : ApplianceFace.key(c, circle: true);
        if (disabled) face = face.copyWith(lift: face.lift * 0.4);
        face = layered.on(
          face.copyWith(
            focus: states.contains(WidgetState.focused)
                ? c.focus
                : _none(c.focus),
          ),
        );
        return DesignTapTarget(
          child: SizedBox.square(
            dimension: size,
            child: AnimatedApplianceSurface(
              face: face,
              child: Center(
                child: ApplianceLamp(
                  lit: chosen,
                  size: 9,
                  color: disabled ? c.printDisabled : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(DiagnosticsProperty<T>('groupValue', groupValue))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// A switch: a slide switch. A key-like cap rides in a sunken slot; on, it
/// snaps to the slot's end side and the lamp in it lights, and the slot's
/// start side shows its moulded on mark (a bar); off, it rests at the start
/// side over the on mark and shows the off mark (a ring). So on and off
/// read from the cap's place, its lamp and the mark beside it, with no
/// colour needed, and a screen reader hears on or off.
///
/// A null [onChanged] disables it. Reads [style]'s `fill` (the slot) and
/// `edge` in its states, then [ApplianceThemeData.toggleStyle]'s.
///
/// ```dart
/// ApplianceSwitch(value: notify, onChanged: (value) => setState(() => notify = value), semanticLabel: 'Order updates')
/// ```
class ApplianceSwitch extends StatelessWidget {
  /// A switch at [value].
  const ApplianceSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.style,
  });

  /// On or off.
  final bool value;

  /// Called with the next value; null disables it.
  final ValueChanged<bool>? onChanged;

  /// Its name for a screen reader.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Its style, over [ApplianceThemeData.toggleStyle].
  final ApplianceStyle? style;

  /// The slot's size.
  static const Size size = Size(56, 30);

  /// The cap's size.
  static const Size capSize = Size(28, 24);

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      focusNode: focusNode,
      toggled: value,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.toggleStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final held = states.contains(WidgetState.pressed);
        final slot = layered.on(
          ApplianceFace(
            top: c.trough,
            bottom: c.trough,
            lift: -1,
            radius: BorderRadius.circular(ApplianceMetrics.smallKeyRadius),
            foreground: disabled ? c.printDisabled : c.print,
            focus: states.contains(WidgetState.focused)
                ? c.focus
                : _none(c.focus),
          ),
        );
        return DesignTapTarget(
          child: SizedBox.fromSize(
            size: size,
            child: AnimatedApplianceSurface(
              face: slot,
              child: ApplianceSpringValue(
                value: value ? 1 : 0,
                spring: ApplianceMotion.snap,
                builder: (context, t, _) => CustomPaint(
                  painter: _SwitchPainter(
                    marks: slot.foreground,
                    rtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                  child: Align(
                    alignment: Alignment.lerp(
                      AlignmentDirectional.centerStart.resolve(
                        Directionality.of(context),
                      ),
                      AlignmentDirectional.centerEnd.resolve(
                        Directionality.of(context),
                      ),
                      t,
                    )!,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ApplianceMetrics.capInset,
                      ),
                      child: SizedBox.fromSize(
                        size: capSize,
                        child: ApplianceSurface(
                          // Concentric with the slot: its corner less the
                          // room between them.
                          face: ApplianceFace.key(
                            c,
                            radius:
                                ApplianceMetrics.smallKeyRadius -
                                ApplianceMetrics.capInset,
                          ).copyWith(lift: disabled ? 0.4 : (held ? 0.6 : 1)),
                          // A gripped cap: two moulded ribs round its lamp.
                          child: CustomPaint(
                            painter: _GripPainter(
                              shade: c.shade,
                              light: c.highlight,
                            ),
                            child: Center(
                              child: ApplianceLamp(
                                lit: value && !disabled,
                                size: ApplianceMetrics.lampSize - 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off'))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

// The slot's moulded marks: a bar for on at the start side, a ring for off
// at the end side; the cap covers the one it rests on.
// Two short moulded ribs either side of a cap's middle: a shaded line with a
// lit one beside it, as light from the top falls on a ridge.
class _GripPainter extends CustomPainter {
  _GripPainter({required this.shade, required this.light});

  final Color shade;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const reach = 5.0;
    const apart = 8.0;
    for (final x in [c.dx - apart, c.dx + apart]) {
      canvas
        ..drawLine(
          Offset(x, c.dy - reach),
          Offset(x, c.dy + reach),
          Paint()
            ..strokeWidth = 1
            ..color = shade.withValues(alpha: 0.28),
        )
        ..drawLine(
          Offset(x + 1, c.dy - reach),
          Offset(x + 1, c.dy + reach),
          Paint()
            ..strokeWidth = 1
            ..color = light.withValues(alpha: 0.7),
        );
    }
  }

  @override
  bool shouldRepaint(_GripPainter old) =>
      old.shade != shade || old.light != light;
}

class _SwitchPainter extends CustomPainter {
  _SwitchPainter({required this.marks, required this.rtl});

  final Color marks;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final cap = ApplianceSwitch.capSize.width + 6;
    final startX = cap / 2;
    final endX = size.width - cap / 2;
    final (onX, offX) = rtl ? (endX, startX) : (startX, endX);
    final cy = size.height / 2;
    final paint = Paint()
      ..color = marks
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // The on mark sits where the cap rests when off; moulded large enough
    // that the exposed mark, I or O, says on or off without the lamp.
    canvas
      ..drawLine(Offset(onX, cy - 6.5), Offset(onX, cy + 6.5), paint)
      ..drawCircle(Offset(offX, cy), 5.5, paint);
  }

  @override
  bool shouldRepaint(_SwitchPainter old) =>
      old.marks != marks || old.rtl != rtl;
}

/// One position of an [ApplianceSegmentedButton] or an [ApplianceTabBar].
@immutable
class ApplianceSegment<T> {
  /// The position for [value], reading [label].
  const ApplianceSegment({
    required this.value,
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  /// What choosing it sets.
  final T value;

  /// What it says.
  final String label;

  /// A glyph before the words.
  final Widget? icon;

  /// What a screen reader says for it when its words do not name it alone;
  /// null says [label].
  final String? semanticLabel;
}

/// Two to five short choices as the positions of a slide selector: a
/// sunken trough, its positions printed along it, and a raised block that
/// slides to the chosen one and snaps into its detent. Every position is
/// the same width, and a label never moves; the chosen one reads in the
/// print's full weight, the rest muted. Below 600 px it spans its column;
/// wider, each position takes the widest label's width.
///
/// A null [onChanged] disables it. Left and Right move the choice, Home and
/// End to the ends.
///
/// Reads [style]'s `fill` (the trough) and `edge`, `foreground`,
/// `textStyle` and `iconSize` (the positions' words) and `minimumSize` (its
/// height) in its states, then [ApplianceThemeData.selectorStyle]'s.
///
/// ```dart
/// ApplianceSegmentedButton<String>(segments: const [ApplianceSegment(value: 'grid', label: 'Grid'), ApplianceSegment(value: 'list', label: 'List')], value: view, onChanged: (value) => setState(() => view = value))
/// ```
class ApplianceSegmentedButton<T> extends StatelessWidget {
  /// A selector over [segments].
  const ApplianceSegmentedButton({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expand,
    this.semanticLabel,
    this.style,
  }) : _tabs = false,
       assert(segments.length >= 2);

  const ApplianceSegmentedButton._tabs({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expand,
    this.semanticLabel,
    this.style,
  }) : _tabs = true;

  /// The positions, in order.
  final List<ApplianceSegment<T>> segments;

  /// The chosen value.
  final T value;

  /// Called with the value chosen; null disables it.
  final ValueChanged<T>? onChanged;

  /// Whether it spans its column; null: below 600 px wide it does.
  final bool? expand;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.selectorStyle].
  final ApplianceStyle? style;

  final bool _tabs;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.selectorStyle];
    final off = onChanged == null;
    final frame = DesignStyleOf(layers, {if (off) WidgetState.disabled});
    final words = frame.text(
      theme.textTheme.label.copyWith(fontSize: 15, height: 20 / 15),
    );
    final scale = MediaQuery.textScalerOf(context);
    double widest = 0;
    for (final s in segments) {
      final painter = TextPainter(
        text: TextSpan(
          text: s.label,
          style: words.copyWith(fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scale,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width + (s.icon == null ? 0 : 28));
      painter.dispose();
    }
    const inset = ApplianceMetrics.troughInset;
    final cell = widest + 2 * ApplianceSpacing.regular;
    final hugged = segments.length * cell + 2 * inset;
    final height = frame.minimumSize?.height ?? theme.controlHeight;
    final index = math.max(0, segments.indexWhere((s) => s.value == value));
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            (expand ?? MediaQuery.sizeOf(context).width < 600) ||
            hugged > constraints.maxWidth;
        final width = wide ? constraints.maxWidth : hugged;
        final each = (width - 2 * inset) / segments.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;

        void move(int by) {
          if (onChanged == null) return;
          final next = (index + by).clamp(0, segments.length - 1);
          if (next != index) onChanged!(segments[next].value);
        }

        final trough = _troughFace(
          frame,
          ApplianceFace(
            top: c.trough,
            bottom: c.trough,
            lift: -1,
            radius: BorderRadius.circular(ApplianceMetrics.troughRadius),
            foreground: c.print,
          ),
        );
        final block = ApplianceSurface(
          face: ApplianceFace.key(
            c,
            radius:
                ApplianceMetrics.troughRadius - ApplianceMetrics.troughInset,
          ).copyWith(lift: off ? 0.4 : 1),
          // The lamp says which position is chosen, as a latched key's does.
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: ApplianceSpacing.small,
                top: ApplianceSpacing.small,
              ),
              child: ApplianceLamp(
                lit: !off,
                size: ApplianceMetrics.lampSize - 2,
              ),
            ),
          ),
        );
        final control = Semantics(
          // Tabs are named by ui_core's tab bar.
          label: _tabs ? null : semanticLabel,
          container: true,
          explicitChildNodes: true,
          child: SizedBox(
            width: width,
            height: height,
            child: ApplianceSurface(
              face: trough,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: inset),
                child: _tabs
                    ? _TabStrip<T>(
                        segments: segments,
                        index: index,
                        onChanged: onChanged,
                        semanticLabel: semanticLabel,
                        block: Padding(
                          padding: const EdgeInsets.symmetric(vertical: inset),
                          child: block,
                        ),
                        legend: (context, s, states) => _legend(
                          context,
                          theme,
                          s,
                          states.contains(WidgetState.selected),
                          states,
                          words,
                          layers,
                        ),
                      )
                    : Stack(
                        children: [
                          // The block, sliding to the chosen position.
                          ApplianceSpringValue(
                            value: index.toDouble(),
                            spring: ApplianceMotion.snap,
                            builder: (context, at, _) => PositionedDirectional(
                              start: at * each,
                              top: inset,
                              bottom: inset,
                              width: each,
                              child: block,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, s) in segments.indexed)
                                SizedBox(
                                  width: each,
                                  child: _position(
                                    context,
                                    theme,
                                    s,
                                    i == index,
                                    words,
                                    layers,
                                    move,
                                    rtl,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
        return wide
            ? control
            : Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                heightFactor: 1,
                child: control,
              );
      },
    );
  }

  static ApplianceFace _troughFace(DesignStyleOf frame, ApplianceFace face) =>
      frame.fill == null && frame.edge == null && frame.side == null
      ? face
      : face.copyWith(
          top: frame.fill,
          bottom: frame.fill,
          edge: frame.side?.color ?? frame.edge,
        );

  Widget _position(
    BuildContext context,
    ApplianceThemeData theme,
    ApplianceSegment<T> s,
    bool chosen,
    TextStyle words,
    List<ApplianceStyle?> layers,
    void Function(int by) move,
    bool rtl,
  ) {
    return DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(s.value),
      selected: chosen,
      semanticSelected: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: s.semanticLabel ?? s.label,
      excludeSemantics: true,
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(
          rtl ? 1 : -1,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(
          rtl ? -1 : 1,
        ),
        const SingleActivator(LogicalKeyboardKey.home): _MoveIntent(
          -segments.length,
        ),
        const SingleActivator(LogicalKeyboardKey.end): _MoveIntent(
          segments.length,
        ),
      },
      actions: {
        _MoveIntent: CallbackAction<_MoveIntent>(
          onInvoke: (intent) {
            move(intent.by);
            return null;
          },
        ),
      },
      builder: (context, states, _) =>
          _legend(context, theme, s, chosen, states, words, layers),
    );
  }

  // A position's legend (and its glyph) in [states], on the trough.
  Widget _legend(
    BuildContext context,
    ApplianceThemeData theme,
    ApplianceSegment<T> s,
    bool chosen,
    Set<WidgetState> states,
    TextStyle words,
    List<ApplianceStyle?> layers,
  ) {
    final c = theme.colors;
    final layered = DesignStyleOf(layers, states);
    final disabled = states.contains(WidgetState.disabled);
    final ink =
        layered.foreground ??
        (disabled
            ? c.printDisabled
            : chosen
            ? c.print
            : c.printMuted);
    final radius = ApplianceMetrics.troughRadius - ApplianceMetrics.troughInset;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ApplianceMetrics.troughInset,
      ),
      child: ApplianceSurface(
        face: ApplianceFace(
          top: _none(c.face),
          bottom: _none(c.face),
          radius: BorderRadius.circular(radius),
          foreground: ink,
          travel: states.contains(WidgetState.pressed) ? 0.6 : 0,
          focus: states.contains(WidgetState.focused)
              ? c.focus
              : _none(c.focus),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ApplianceSpacing.small,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (s.icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(size: layered.iconSize ?? 18),
                  child: s.icon!,
                ),
                const SizedBox(width: ApplianceSpacing.small),
              ],
              Flexible(
                child: DesignCapCenter(
                  capHeightFactor: theme.capHeightFactor,
                  child: Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // The weight stays: a chosen label never shifts.
                    style: words.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('segments', segments.length))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// Tabs over a page's views, as a slide selector: the same object as
/// [ApplianceSegmentedButton], on ui_core's [DesignTabBar]. It is one tab
/// stop; the arrows move along it, choosing as they go (mirrored right to
/// left), Home and End to the ends; a screen reader hears a tab bar of
/// tabs, each with its place ("Tab 1 of 3"). The block slides on
/// [ApplianceMotion.snap].
///
/// ```dart
/// ApplianceTabBar<String>(tabs: const [ApplianceSegment(value: 'open', label: 'Open'), ApplianceSegment(value: 'past', label: 'Past')], value: tab, onChanged: (value) => setState(() => tab = value))
/// ```
class ApplianceTabBar<T> extends StatelessWidget {
  /// Tabs over [tabs].
  const ApplianceTabBar({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    this.expand,
    this.semanticLabel,
    this.style,
  }) : assert(tabs.length >= 2);

  /// The tabs, in order.
  final List<ApplianceSegment<T>> tabs;

  /// The current tab.
  final T value;

  /// Called with the tab chosen.
  final ValueChanged<T>? onChanged;

  /// Whether it spans its column; null: below 600 px wide it does.
  final bool? expand;

  /// What a screen reader calls the tabs.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.selectorStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => ApplianceSegmentedButton<T>._tabs(
    segments: tabs,
    value: value,
    onChanged: onChanged,
    expand: expand,
    semanticLabel: semanticLabel,
    style: style,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('tabs', tabs.length));
  }
}

// ApplianceTabBar's positions on ui_core's DesignTabBar, its controller
// following [index] and telling [onChanged] of a tab chosen.
class _TabStrip<T> extends StatefulWidget {
  const _TabStrip({
    required this.segments,
    required this.index,
    required this.onChanged,
    required this.semanticLabel,
    required this.block,
    required this.legend,
  });

  final List<ApplianceSegment<T>> segments;
  final int index;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;
  final Widget block;
  final Widget Function(
    BuildContext context,
    ApplianceSegment<T> segment,
    Set<WidgetState> states,
  )
  legend;

  @override
  State<_TabStrip<T>> createState() => _TabStripState<T>();
}

class _TabStripState<T> extends State<_TabStrip<T>>
    with TickerProviderStateMixin {
  late DesignTabController _controller = _make();

  DesignTabController _make() => DesignTabController(
    length: widget.segments.length,
    initialIndex: widget.index,
    vsync: this,
    dampingRatio: ApplianceMotion.snap.dampingRatio,
    stiffness: ApplianceMotion.snap.stiffness,
  )..addListener(_chosen);

  void _chosen() {
    final i = _controller.index;
    if (i != widget.index) widget.onChanged?.call(widget.segments[i].value);
  }

  @override
  void didUpdateWidget(_TabStrip<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.segments.length != _controller.length) {
      final old = _controller..removeListener(_chosen);
      _controller = _make();
      // The bar lets go of it as it rebuilds.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    } else if (widget.index != _controller.index) {
      _controller.animateTo(widget.index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DesignTabBar(
    controller: _controller,
    semanticLabel: widget.semanticLabel,
    tabs: [
      for (final s in widget.segments)
        DesignTab(
          label: s.semanticLabel ?? s.label,
          enabled: widget.onChanged != null,
        ),
    ],
    indicatorBuilder: (context, details) => widget.block,
    tabBuilder: (context, tab, details) =>
        widget.legend(context, widget.segments[details.index], details.states),
  );
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.by);

  final int by;
}

/// A whole number stepped down and up: two keys round a small sunken
/// display window, its figure lit. A key at its bound stands disabled. A
/// null [onChanged] disables it.
///
/// Reads [style]'s `fill` (the window), `foreground` (the keys' glyphs),
/// `textStyle` (the figure) and `minimumSize` (its height) in its states,
/// then [ApplianceThemeData.stepperStyle]'s.
///
/// ```dart
/// ApplianceStepper(value: quantity, min: 1, max: 9, onChanged: (value) => setState(() => quantity = value), semanticLabel: 'Quantity')
/// ```
class ApplianceStepper extends StatelessWidget {
  /// A stepper between [min] and [max].
  const ApplianceStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.semanticLabel,
    this.decreaseLabel = 'Decrease',
    this.increaseLabel = 'Increase',
    this.style,
  }) : assert(min <= value && value <= max);

  /// The number.
  final int value;

  /// Called with the next number; null disables it.
  final ValueChanged<int>? onChanged;

  /// The least.
  final int min;

  /// The most.
  final int max;

  /// What the number counts, for a screen reader.
  final String? semanticLabel;

  /// What a screen reader calls the minus key, before [semanticLabel].
  final String decreaseLabel;

  /// What a screen reader calls the plus key, before [semanticLabel].
  final String increaseLabel;

  /// Its style, over [ApplianceThemeData.stepperStyle].
  final ApplianceStyle? style;

  String _name(String verb) =>
      semanticLabel == null ? verb : '$verb $semanticLabel';

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final off = onChanged == null;
    final layers = [style, theme.stepperStyle];
    final frame = DesignStyleOf(layers, {if (off) WidgetState.disabled});
    final h = frame.minimumSize?.height ?? theme.controlHeight;
    Widget step(bool up, String label, int to) {
      final can = !off && to >= min && to <= max;
      return DesignPressable(
        onPressed: can ? () => onChanged!(to) : null,
        semanticLabel: label,
        excludeSemantics: true,
        builder: (context, states, _) {
          final layered = DesignStyleOf(layers, states);
          final disabled = states.contains(WidgetState.disabled);
          final pressed = states.contains(WidgetState.pressed);
          final face =
              (pressed ? ApplianceFace.keyDown(c) : ApplianceFace.key(c))
                  .copyWith(
                    lift: disabled ? 0.35 : null,
                    foreground:
                        layered.foreground ??
                        (disabled ? c.printDisabled : c.print),
                    focus: states.contains(WidgetState.focused)
                        ? c.focus
                        : _none(c.focus),
                  );
          return DesignTapTarget(
            child: SizedBox.square(
              dimension: h,
              child: AnimatedApplianceSurface(
                face: face,
                child: CustomPaint(
                  painter: _PlusMinusPainter(face.foreground, plus: up),
                ),
              ),
            ),
          );
        },
      );
    }

    final window = ApplianceFace.well(
      c,
      fill: frame.fill ?? c.display,
      radius: ApplianceMetrics.smallKeyRadius + 2,
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        height: h,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            step(false, _name(decreaseLabel), value - 1),
            const SizedBox(width: ApplianceSpacing.small),
            Semantics(
              label: semanticLabel,
              value: '$value',
              child: SizedBox(
                width: 52,
                height: h - ApplianceSpacing.small,
                child: ApplianceSurface(
                  face: window,
                  child: Center(
                    child: DesignCapCenter(
                      capHeightFactor: theme.capHeightFactor,
                      child: Text(
                        '$value',
                        style: frame.text(
                          theme.textTheme.figure.copyWith(
                            fontSize: 18,
                            color: off
                                ? c.onDisplay.withValues(alpha: 0.5)
                                : c.onDisplay,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: ApplianceSpacing.small),
            step(true, _name(increaseLabel), value + 1),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('value', value))
      ..add(IntProperty('min', min))
      ..add(IntProperty('max', max));
  }
}

class _PlusMinusPainter extends CustomPainter {
  _PlusMinusPainter(this.color, {required this.plus});

  final Color color;
  final bool plus;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-6, 0), c.translate(6, 0), paint);
    if (plus) canvas.drawLine(c.translate(0, -6), c.translate(0, 6), paint);
  }

  @override
  bool shouldRepaint(_PlusMinusPainter old) =>
      old.color != color || old.plus != plus;
}
