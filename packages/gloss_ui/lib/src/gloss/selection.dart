/// More of Gloss's ways to choose: the range slider (two pearl beads in
/// one groove, gel between them), the rating (gel stars), and the file
/// drop (a deep tray to put files in).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'feedback.dart';
import 'lists.dart';
import 'internal/glaze_state.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

/// A range's two ends.
@immutable
class GlossRangeValues {
  /// From [start] to [end].
  const GlossRangeValues(this.start, this.end);

  /// The lower end.
  final double start;

  /// The upper end.
  final double end;

  @override
  bool operator ==(Object other) =>
      other is GlossRangeValues && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'GlossRangeValues($start, $end)';
}

/// A range slider: two pearl beads in one groove, jade gel lit between
/// them. A drag moves the nearer bead; the keys move the focused one.
///
/// ```dart
/// GlossRangeSlider(values: const GlossRangeValues(15, 45), max: 90, onChanged: (values) {})
/// ```
class GlossRangeSlider extends StatelessWidget {
  // A bead's target, and the groove's depth: the groove runs from one bead's
  // centre to the other's, its round ends under them.
  static const double _target = 44;
  static const double _groove = 10;

  /// A range slider at [values].
  const GlossRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.startLabel,
    this.endLabel,
    this.semanticFormatterCallback,
    this.style,
  });

  /// The range.
  final GlossRangeValues values;

  /// A new range; null disables it.
  final ValueChanged<GlossRangeValues>? onChanged;

  /// The lowest.
  final double min;

  /// The highest.
  final double max;

  /// How many steps; null: any value.
  final int? divisions;

  /// What a screen reader calls the lower bead.
  final String? startLabel;

  /// What a screen reader calls the upper bead.
  final String? endLabel;

  /// A value as words, for a screen reader.
  final String Function(double value)? semanticFormatterCallback;

  /// Its own style, over [GlossThemeData.sliderStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final fill = DesignStyleOf([style, theme.sliderStyle], const {}).fill;
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RawRangeSlider(
      values: RawRangeValues(values.start, values.end),
      onChanged: onChanged == null
          ? null
          : (v) => onChanged!(GlossRangeValues(v.start, v.end)),
      min: min,
      max: max,
      divisions: divisions,
      startLabel: startLabel,
      endLabel: endLabel,
      semanticFormatterCallback: semanticFormatterCallback,
      thumbSize: const Size.square(_target),
      trackBuilder: (context, track) => SizedBox(
        height: _groove,
        child: CustomPaint(
          size: Size.infinite,
          painter: _RangeGroove(
            c: c,
            start: track.start,
            end: track.end,
            enabled: enabled,
            fill: fill,
            rtl: rtl,
            highContrast: high,
          ),
        ),
      ),
      thumbBuilder: (context, index, states) => Center(
        child: SizedBox.square(
          dimension: 28,
          child: AnimatedGlossSurface(
            face: GlossFace.pearl(c).copyWith(
              travel: states.contains(WidgetState.pressed) ? 0.6 : 0,
              lens: enabled ? null : 0.3,
              lift: enabled ? null : 0.4,
              focus: glossGlazeOf(c, states),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<GlossRangeValues>('values', values))
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max));
  }
}

class _RangeGroove extends CustomPainter {
  _RangeGroove({
    required this.c,
    required this.start,
    required this.end,
    required this.enabled,
    required this.fill,
    required this.rtl,
    required this.highContrast,
  });

  final GlossColors c;
  final double start;
  final double end;
  final bool enabled;
  final Color? fill;
  final bool rtl;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // The core track spans from the first thumb's center to the last one's.
    final radius = size.height / 2;
    paintGlossFace(
      canvas,
      Rect.fromLTRB(-radius, 0, size.width + radius, size.height),
      GlossFace.well(c).copyWith(
        lift: enabled ? -1 : -0.5,
        edge: highContrast ? c.ink : const Color(0x00000000),
      ),
      highContrast: highContrast,
    );
    final a = start * size.width;
    final b = end * size.width;
    final lit = rtl
        ? Rect.fromLTRB(size.width - b, 0, size.width - a, size.height)
        : Rect.fromLTRB(a, 0, b, size.height);
    if (lit.width <= 0) return;
    var face = GlossFace.well(c).copyWith(
      top: c.jadeBottom,
      middle: c.jade,
      bottom: c.jadeTop,
      shade: const Color(0x80002814),
    );
    if (fill != null) face = face.glazed(fill!);
    if (!enabled) {
      face = face.copyWith(
        top: c.inkDisabled,
        middle: c.inkDisabled,
        bottom: c.inkDisabled,
      );
    }
    paintGlossFace(canvas, lit, face, highContrast: highContrast);
  }

  @override
  bool shouldRepaint(_RangeGroove old) =>
      old.start != start ||
      old.end != end ||
      old.enabled != enabled ||
      old.fill != fill ||
      old.c != c ||
      old.rtl != rtl;
}

/// A rating: [max] stars, the ones given cast in jade gel, the rest
/// engraved in the page. ui_core's rating runs it: a press gives that many
/// (a press on the last star given takes it back), a drag sweeps across;
/// one tab stop, Right and Left change it by one (as drawn), Home clears
/// it, End gives all, a digit gives that many; a screen reader hears a
/// slider.
///
/// ```dart
/// GlossRating(value: 4, onChanged: (stars) {})
/// ```
class GlossRating extends StatelessWidget {
  /// A rating of [value] out of [max].
  const GlossRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.size = 28,
    this.semanticLabel,
  });

  /// How many stars are given.
  final int value;

  /// A new rating; null: it only shows.
  final ValueChanged<int>? onChanged;

  /// How many stars there are.
  final int max;

  /// Each star's size.
  final double size;

  /// What a screen reader calls it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final change = onChanged;
    final enabled = change != null;
    return RawRating(
      value: value.toDouble(),
      itemCount: max,
      readOnly: !enabled,
      onChanged: enabled ? (v) => change(v.round()) : null,
      semanticLabel: semanticLabel,
      itemBuilder: (context, star) {
        final n = star.index + 1;
        // Keyboard focus follows the last assigned star.
        final lead = n == math.max(1, value);
        final painted = SizedBox.square(
          dimension: enabled ? math.max(size + 8, 36) : size + 4,
          child: GlazePointerBuilder(
            enabled: enabled,
            builder: (hovered, pressed) => animatedGlazePaint(
              context,
              glossGlazeOf(c, {
                if (lead && star.states.contains(WidgetState.focused))
                  WidgetState.focused,
                if (hovered) WidgetState.hovered,
                if (pressed) WidgetState.pressed,
              }),
              (light) => _StarPainter(
                c,
                // The value, not a hovering pointer's preview: the stars
                // light only when given.
                on: n <= value,
                pressed: pressed,
                light: light,
                size: size,
              ),
            ),
          ),
        );
        if (!enabled) return painted;
        // Gloss's own: a press on the last star given takes it back (the
        // pointer's way to none), which ui_core's rating leaves alone.
        return TapTargetPadding(
          child: n == value
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: () => change(n - 1),
                  child: painted,
                )
              : painted,
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('value', value))
      ..add(IntProperty('max', max));
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(
    this.c, {
    required this.on,
    required this.pressed,
    required this.light,
    required this.size,
  });

  final GlossColors c;
  final bool on;
  final bool pressed;
  final Color light;
  final double size;

  Path _star(Offset centre, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.48;
      final p = centre + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size box) {
    final centre = box.center(Offset(0, pressed ? 1 : 0));
    final r = size / 2;
    final star = _star(centre, r);
    final bounds = star.getBounds();
    final day = c.brightness == Brightness.light;
    // A given star is on, so jade gel (law 1); one not given is engraved.
    final gel = GlossFace.gel(c);
    if (on) {
      canvas
        ..drawPath(
          star.shift(const Offset(0, 1.5)),
          Paint()
            ..color = const Color(0x33000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        )
        ..drawPath(
          star,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gel.top, gel.middle, gel.bottom],
            ).createShader(bounds),
        )
        ..drawPath(
          star,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..strokeJoin = StrokeJoin.round
            ..color = gel.edge,
        );
      // The lens: a sheen across the star's upper half.
      canvas
        ..save()
        ..clipPath(star)
        ..drawOval(
          Rect.fromLTRB(
            bounds.left + bounds.width * 0.18,
            bounds.top - bounds.height * 0.1,
            bounds.right - bounds.width * 0.18,
            bounds.top + bounds.height * 0.5,
          ),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
            ).createShader(bounds),
        )
        ..restore();
    } else {
      // Engraved: a dark cut with the light on its lower edge.
      canvas
        ..drawPath(
          star.shift(const Offset(0, 1)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeJoin = StrokeJoin.round
            ..color = c.lip,
        )
        ..drawPath(star, Paint()..color = c.well)
        ..drawPath(
          star,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeJoin = StrokeJoin.round
            // By night the cut's shade sinks into the dark page; its rim
            // catches a little light instead, so the star still reads.
            ..color = day ? c.wellShade : c.inkSecondary.withValues(alpha: 0.5),
        );
    }
    if (light.a > 0) {
      canvas
        ..save()
        ..clipPath(star);
      paintGlossHalo(
        canvas,
        RRect.fromRectAndRadius(bounds, Radius.zero),
        light,
        brightness: c.brightness,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.on != on ||
      old.pressed != pressed ||
      old.light != light ||
      old.c != c ||
      old.size != size;
}

/// A file chosen for a [GlossFileDrop].
@immutable
class GlossFile {
  /// A file named [name] of [bytes].
  const GlossFile({required this.name, required this.bytes, this.progress});

  /// Its name.
  final String name;

  /// Its size.
  final int bytes;

  /// How far it has uploaded, 0 to 1; null: done (or not uploading).
  final double? progress;
}

String _size(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// A file drop: a deep tray pressed into the page, a glyph and a key to
/// choose files in it, and the chosen files listed under it, each with its
/// progress and a bead to take it out. The app does the choosing
/// ([onChoose]).
///
/// ```dart
/// GlossFileDrop(label: 'Photos', onChoose: () {}, files: const [GlossFile(name: 'risotto.jpg', bytes: 240000)])
/// ```
class GlossFileDrop extends StatelessWidget {
  /// A file drop.
  const GlossFileDrop({
    super.key,
    required this.onChoose,
    this.files = const [],
    this.onRemove,
    this.label,
    this.hint,
    this.chooseLabel = 'Choose files',
  });

  /// Opens the app's chooser; null disables it.
  final VoidCallback? onChoose;

  /// The files chosen.
  final List<GlossFile> files;

  /// Takes a file out; null: files stay.
  final ValueChanged<GlossFile>? onRemove;

  /// The words above the tray.
  final String? label;

  /// What the tray says.
  final String? hint;

  /// The key's words.
  final String chooseLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final enabled = onChoose != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) GlossFieldLabel(label!, enabled: enabled),
        GlossSurface(
          face: GlossFace.well(c, radius: GlossMetrics.wellRadius),
          child: Padding(
            padding: const EdgeInsets.all(GlossSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.upload,
                  size: 28,
                  color: enabled ? c.inkSecondary : c.inkDisabled,
                  shadows: [
                    Shadow(
                      color: c.letterpress,
                      offset: Offset(0, c.letterpressBelow ? 1 : -1),
                    ),
                  ],
                ),
                if (hint != null) ...[
                  const SizedBox(height: GlossSpacing.small),
                  Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: glossLetterpress(theme.textTheme.secondary, c),
                  ),
                ],
                const SizedBox(height: GlossSpacing.regular),
                GlossButton(
                  chooseLabel,
                  onPressed: onChoose,
                  icon: const Icon(LucideIcons.paperclip),
                ),
              ],
            ),
          ),
        ),
        // The files are rows in one well (a group sits below the page),
        // each named in the row's weight, its size under it in second ink.
        if (files.isNotEmpty) ...[
          const SizedBox(height: GlossSpacing.small),
          GlossWell(
            dividerIndent: GlossSpacing.medium + 18 + GlossSpacing.medium,
            children: [
              for (final file in files)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    GlossSpacing.medium,
                    GlossSpacing.small,
                    GlossSpacing.tight,
                    GlossSpacing.small,
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.file, size: 18, color: c.inkSecondary),
                      const SizedBox(width: GlossSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.body.copyWith(
                                color: c.ink,
                                fontWeight: FontWeight.w500,
                                fontVariations: glossWeightAxis(
                                  FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              _size(file.bytes),
                              style: theme.textTheme.secondary,
                            ),
                            if (file.progress != null) ...[
                              const SizedBox(height: GlossSpacing.tight),
                              GlossProgressBar(
                                value: file.progress,
                                height: 8,
                                semanticLabel: file.name,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onRemove != null)
                        GlossIconButton.plain(
                          onPressed: () => onRemove!(file),
                          tooltip: '${words.deleteButtonTooltip} ${file.name}',
                          icon: const Icon(LucideIcons.x),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('files', files.length));
  }
}
