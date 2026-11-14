import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../format.dart';
import '../../internal/css_gradient.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// The width a chart draws at when nothing bounds it: the pilot's phone
/// tile interior.
const double _unboundedWidth = 326;

/// Where one flow of a [FrostedFan] goes: its [amount], the [hue] of where
/// it lands, its [title] and what it is with its day ([subtitle]), and
/// where its row leads ([onPressed]); [key] names the row (a walk's door).
///
/// ```dart
/// FrostedFanEnd(amount: 400, hue: theme.hues.azure, title: 'Emergency fund', subtitle: 'Auto-save · Sun, Nov 1', onPressed: openGoal)
/// ```
@immutable
class FrostedFanEnd {
  /// Creates a [FrostedFanEnd].
  const FrostedFanEnd({
    required this.amount,
    required this.hue,
    required this.title,
    this.subtitle,
    this.onPressed,
    this.key,
  });

  /// The sum this end takes.
  final num amount;

  /// The end's hue.
  final FrostedHue hue;

  /// The end's name.
  final String title;

  /// A quiet line under the name.
  final String? subtitle;

  /// What a press on the end does; null leaves it still.
  final VoidCallback? onPressed;

  /// The row's key, for a test or a walk to find it by.
  final Key? key;
}

/// One account's money fanning out to where it goes: a source bar at the
/// start holding every flow stacked in the [source]'s light, a ribbon per
/// flow keeping its thickness and turning from that light into its own
/// hue, a bar of that hue where it lands, and its row beside it (the name,
/// what it is and its amount, a link when it leads somewhere). The flows
/// are spaced so each row has room; the plot stands [height] tall (the
/// source's phone and desktop heights by default). Sized by its width.
///
/// ```dart
/// FrostedFan(flows: scheduled, source: theme.hues.cyan, label: 'What leaves Everyday on its own in November')
/// ```
class FrostedFan extends StatelessWidget {
  /// Creates a [FrostedFan].
  const FrostedFan({
    required this.flows,
    required this.source,
    required this.label,
    this.height,
    super.key,
  });

  /// The flows in order from the top, largest first.
  final List<FrostedFanEnd> flows;

  /// The hue of the account they leave.
  final FrostedHue source;

  /// What a screen reader calls the drawing.
  final String label;

  /// The drawing's height; null takes the look's.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    // fan(): phone 228 tall, the destinations at 96, the bars 8 and 6
    // wide; desktop 280 tall, at 236, the bars 10 and 8. The rows start 12
    // (16) past the destination bars.
    final h = height ?? (wide ? 280.0 : 228.0);
    final dstX = wide ? 236.0 : 96.0;
    final srcW = wide ? 10.0 : 8.0;
    final dstW = wide ? 8.0 : 6.0;
    // metric: a fan's row stands 12 (16 from 1024) past its bar.
    final rowStart =
        dstX + dstW + (wide ? FrostedSpacing.s16 : FrostedSpacing.s12);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : _unboundedWidth;
        final g = _fan(w, h, dstX, srcW, dstW);
        return SizedBox(
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Semantics(
                  label: label,
                  child: ExcludeSemantics(
                    // The ribbons run from the start, as the rows beside
                    // their bars do: drawn left to right under right-to-left
                    // rows, a bar stood ~900 from its words (self-review
                    // round 6).
                    child: Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: CustomPaint(painter: _FanPainter(g, source)),
                    ),
                  ),
                ),
              ),
              for (final (i, flow) in flows.indexed)
                // .fan-l { position: absolute; right: 0; transform:
                // translateY(-50%) }
                PositionedDirectional(
                  start: rowStart,
                  end: 0,
                  top: g.centres[i],
                  child: FractionalTranslation(
                    translation: const Offset(0, -0.5),
                    child: _FanRow(flow, t, width: w - rowStart),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  _Fan _fan(double w, double h, double dstX, double srcW, double dstW) {
    const slotMin = 44.0;
    const pad = 10.0;
    final total = flows.fold<double>(0, (sum, f) => sum + f.amount);
    final n = flows.length;
    if (n == 0) {
      return const _Fan(ribbons: [], ends: [], source: null, centres: []);
    }
    // The thickness per dollar k: the slots (each at least slotMin, else
    // its band plus padding) fill the height exactly.
    var lo = 0.0;
    var hi = total > 0 ? h / total : 0.0;
    for (var i = 0; i < 60 && total > 0; i++) {
      final k = (lo + hi) / 2;
      var need = 0.0;
      for (final f in flows) {
        need += math.max(slotMin, f.amount * k + 2 * pad);
      }
      if (need <= h) {
        lo = k;
      } else {
        hi = k;
      }
    }
    final k = lo;
    final slots = [
      for (final f in flows) math.max(slotMin, f.amount * k + 2 * pad),
    ];
    final spare = (h - slots.fold<double>(0, (a, b) => a + b)) / n;
    final stack = total * k;
    final sy = (h - stack) / 2;
    final mx = (srcW + dstX) / 2;
    final ribbons = <_Ribbon>[];
    final ends = <_End>[];
    final centres = <double>[];
    var acc = sy;
    var top = 0.0;
    for (final (i, f) in flows.indexed) {
      final slot = slots[i] + spare;
      final thick = f.amount * k;
      final c = top + slot / 2;
      centres.add(c);
      final s0 = acc;
      final s1 = acc + thick;
      final d0 = c - thick / 2;
      final d1 = c + thick / 2;
      ribbons.add(
        _Ribbon(
          Path()
            ..moveTo(srcW, s0)
            ..cubicTo(mx, s0, mx, d0, dstX, d0)
            ..lineTo(dstX, d1)
            ..cubicTo(mx, d1, mx, s1, srcW, s1)
            ..close(),
          f.hue,
          srcW,
          dstX,
        ),
      );
      ends.add(
        _End(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(dstX, d0, dstW, math.max(thick, 2)),
            Radius.circular(dstW / 2),
          ),
          f.hue,
        ),
      );
      acc = s1;
      top += slot;
    }
    return _Fan(
      ribbons: ribbons,
      ends: ends,
      source: stack > 0
          ? RRect.fromRectAndRadius(
              Rect.fromLTWH(0, sy, srcW, stack),
              Radius.circular(srcW / 2),
            )
          : null,
      centres: centres,
    );
  }
}

class _FanRow extends StatelessWidget {
  const _FanRow(this.flow, this.t, {required this.width});

  final FrostedFanEnd flow;
  final FrostedThemeData t;

  /// The row's width, from its start past the bar to the chart's end.
  final double width;

  @override
  Widget build(BuildContext context) {
    final subtitle = flow.subtitle;
    final money = FrostedFormat.moneyParts(flow.amount);
    // .fan-l { display: flex; align-items: center; gap: 10px }
    final row = Row(
      spacing: FrostedSpacing.s10,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // .fan-l .row-main { gap: 2px }
            spacing: FrostedSpacing.s2,
            children: [
              // .fan-l .row-t { font-size: 14px } of .row-t 500 16/1.25
              Text(
                flow.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.titleMedium.at(14).line(17.5),
              ),
              // .fan-l .row-s { font-size: 12px } of .row-s 400 14/1.3 ink-2
              if (subtitle != null)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.bodyMedium
                      .at(12)
                      .line(15.6)
                      .c(t.colorScheme.textSecondary),
                ),
            ],
          ),
        ),
        // .fan-l .amt { font-size: 14px }: tabular, the cents quiet. It
        // keeps its size while it fits in three fifths of the row; a larger
        // text scale shrinks it before it crowds the words out.
        // metric: a fan row's amount takes at most three fifths of the row.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width * 0.6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text.rich(
              TextSpan(
                text: '\$${money.whole}',
                children: [
                  TextSpan(
                    text: '.${money.cents}',
                    style: TextStyle(color: t.colorScheme.textTertiary),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
              style: t.textTheme.amountSmall.line(16.8),
            ),
          ),
        ),
      ],
    );
    final onTap = flow.onPressed;
    if (onTap == null) {
      return flow.key == null ? row : KeyedSubtree(key: flow.key, child: row);
    }
    return FrostedPressable(
      key: flow.key,
      onPressed: onTap,
      role: FrostedPressRole.link,
      label: [
        flow.title,
        ?subtitle,
        FrostedFormat.money(flow.amount),
      ].join(', '),
      child: row,
    );
  }
}

class _Ribbon {
  const _Ribbon(this.path, this.hue, this.from, this.to);

  final Path path;
  final FrostedHue hue;
  final double from;
  final double to;
}

class _End {
  const _End(this.box, this.hue);

  final RRect box;
  final FrostedHue hue;
}

class _Fan {
  const _Fan({
    required this.ribbons,
    required this.ends,
    required this.source,
    required this.centres,
  });

  final List<_Ribbon> ribbons;
  final List<_End> ends;
  final RRect? source;
  final List<double> centres;
}

class _FanPainter extends CustomPainter {
  const _FanPainter(this.g, this.source);

  final _Fan g;
  final FrostedHue source;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (i, ribbon) in g.ribbons.indexed) {
      // A ribbon: the source's second stop at .22, its own first stop at
      // .4 past the middle, its second at .64 where it lands.
      final mixed = frostedCssStops(
        [
          source.b.withValues(alpha: 0.22),
          ribbon.hue.a.withValues(alpha: 0.4),
          ribbon.hue.b.withValues(alpha: 0.64),
        ],
        stops: const [0, 0.55, 1],
      );
      canvas.drawPath(
        ribbon.path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(ribbon.from, 0),
            Offset(ribbon.to, 0),
            mixed.colors,
            mixed.stops,
          ),
      );
      final end = g.ends[i];
      canvas.drawRRect(
        end.box,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, end.box.top),
            Offset(0, end.box.bottom),
            [end.hue.a, end.hue.b],
          ),
      );
    }
    final src = g.source;
    if (src != null) {
      canvas.drawRRect(
        src,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, src.top),
            Offset(0, src.bottom),
            [source.a, source.b],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_FanPainter old) => true;
}
