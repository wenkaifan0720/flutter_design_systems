// The frame: a desktop of windows. On a phone they stack; from 1024 wide they tile on 12 columns and every column ends on one
// line. The desktop holds which window is active, so a page can't draw two heroes: a window has no `active` of its own.
import 'package:flutter/foundation.dart';

import 'internal/marks.dart';
import 'internal/modal.dart';

import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'press.dart';
import 'component_themes.dart';
import 'internal/caps.dart';
import 'internal/face.dart';

import 'glyphs.dart';

import 'layout.dart';
import 'pixels.dart';
import 'theme.dart';
import 'shapes.dart';
import 'tokens.dart';

/// What a window's content may ask: is this the active window, and should a star draw small.
///
/// ```dart
/// RetroDesktopWindowScope(active: true, compact: false, child: const Text('Active pane'))
/// ```
class RetroDesktopWindowScope extends InheritedWidget {
  /// Creates a [RetroDesktopWindowScope].
  const RetroDesktopWindowScope({
    super.key,
    required this.active,
    required this.compact,
    required super.child,
  });

  /// Whether the part is currently active.
  final bool active;

  /// The compact presentation, with less visual spacing.
  final bool compact;

  /// Returns the nearest matching scope, or null when none is installed.
  static RetroDesktopWindowScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RetroDesktopWindowScope>();
  @override
  bool updateShouldNotify(RetroDesktopWindowScope old) =>
      old.active != active || old.compact != compact;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('active', active))
      ..add(DiagnosticsProperty<bool>('compact', compact));
  }
}

/// True outside a desktop and in its active window, and not under an alert, a dialog or a sheet. A part that asks
/// builds under a [RetroDesktopModalWatch].
bool retroDesktopActiveHere(BuildContext context) =>
    (RetroDesktopWindowScope.maybeOf(context)?.active ?? true) &&
    !retroDesktopUnderModal(context);

/// A window's title bar alone, for a raised window the look draws on a surface of its own (a bottom sheet): [title],
/// a heading for a screen reader, the close box live when [onClose] is given (named [closeLabel] for a screen reader),
/// striped while the window is the front one. A modal sheet is neither zoomed nor shaded, so it carries no zoom or
/// shade box, on a desk either.
Widget retroDesktopTitleBar({
  required String title,
  VoidCallback? onClose,
  String? closeLabel,
}) => RetroDesktopModalWatch(
  builder: (context) => _TitleBar(
    title: title,
    active: retroDesktopActiveHere(context),
    onClose: onClose,
    closeLabel: closeLabel,
    header: true,
    modal: true,
  ),
);

/// The room between a window's frame and its title bar and body, in [t]'s appearance.
EdgeInsets retroDesktopWindowFrame(RetroDesktopThemeData t) => t.chisel
    ? const EdgeInsets.all(RetroDesktopSpacing.s2 + RetroDesktopSpacing.px)
    : const EdgeInsets.fromLTRB(
        RetroDesktopSpacing.s4 + RetroDesktopSpacing.px,
        RetroDesktopSpacing.px,
        RetroDesktopSpacing.s4 + RetroDesktopSpacing.px,
        RetroDesktopSpacing.s4 + RetroDesktopSpacing.px,
      );

/// Whether a star draws its small form: always in an inactive window, so a page has one hero whatever it writes, and in the
/// active window on a phone unless the desktop said `whole`. A desktop's active window keeps the whole object.
bool retroDesktopCompactHere(BuildContext context) {
  final s = RetroDesktopWindowScope.maybeOf(context);
  if (s == null) return false;
  if (!s.active) return true;
  return s.compact && !RetroDesktopTheme.of(context).desk;
}

// Window chrome outside the modal content.
class _Chrome extends SingleChildRenderObjectWidget {
  const _Chrome({required Widget super.child});
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderChrome();
}

class _RenderChrome extends RenderProxyBox {}

class _BoxPainter extends RetroDesktopPixelPainter {
  const _BoxPainter(this.c, this.kind, this.shape, {this.pressed = false});
  final RetroDesktopColors c;
  final int kind;
  final OutlinedBorder shape;

  /// Held: the box turns in, its face a step darker and its inner line in the frame's ink on the top and the start (the
  /// light stands at the top start: the top right right to left).
  final bool pressed;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    px.lit(r, () => _paint(px, r));
  }

  void _paint(RetroDesktopPixelGrid px, Rect r) {
    final canvas = px.canvas;
    final line = c.brightness == Brightness.dark ? c.control : c.outline;
    final h = px.hair, w = px.hairX;
    final outline = shape.copyWith(
      side: BorderSide(color: line, width: w),
    );
    canvas.drawPath(
      outline.getOuterPath(r),
      // Flat, its bevel doing the modelling (no part fades).
      Paint()
        ..color = pressed
            ? c.titleBoxDark
            : Color.lerp(c.titleBoxDark, c.titleBoxLight, .5)!,
    );
    outline.paint(canvas, r);
    RetroDesktopShapes.inset(outline, w)
        .copyWith(
          side: BorderSide(color: c.bevelDark, width: w),
        )
        .paint(canvas, r.deflate(w));
    if (pressed) {
      // The shade falls inside the top and the start, as a pressed plate's does (the light law).
      final inner = r.deflate(w);
      px.fillExact(inner.left, inner.top, inner.right, inner.top + h, line);
      px.fillExact(inner.left, inner.top, inner.left + w, inner.bottom, line);
    }
    // Each glyph stands on the box's middle, across and down. The zoom box's smaller box is 7 lp in the 13 lp box, so
    // it keeps 3 lp of face on every side at any whole device-pixel ratio (and within half a device pixel at any
    // other); the shade box's two bars and the gap between them are three of its lines, the gap on the middle.
    if (kind == 1) {
      px.frame(Rect.fromCenter(center: r.center, width: 7, height: 7), line);
    } else if (kind == 2) {
      final a = px.y(r.center.dy - 1.5 * h);
      final start = r.left + 2 * w, end = r.right - 2 * w;
      px.fillExact(start, a, end, a + h, line);
      px.fillExact(start, a + 2 * h, end, a + 3 * h, line);
    }
  }

  @override
  bool shouldRepaint(_BoxPainter o) =>
      o.c != c || o.kind != kind || o.shape != shape || o.pressed != pressed;
}

class _Stripes extends RetroDesktopPixelPainter {
  const _Stripes(this.c);
  final RetroDesktopColors c;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    retroDesktopPinstripes(px, Offset.zero & s, c.bevelDark, c.bevelLight);
  }

  @override
  bool shouldRepaint(_Stripes o) => o.c != c;
}

/// How far below the middle of [style]'s line box its capitals' middle is drawn. The engine puts a line's baseline on a
/// whole logical pixel from the line's top. Jersey 15's capitals are 750 of its 1350 units; another face's are taken as
/// 0.7 of its size. A title bar centres its words by their capitals and puts its glyph's middle on theirs.
double _capsBelowMiddle(TextStyle style, TextScaler scaler) {
  final words = TextPainter(
    text: TextSpan(text: 'H', style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final baseline = words
      .computeDistanceToActualBaseline(TextBaseline.alphabetic)
      .roundToDouble();
  final size = scaler.scale(style.fontSize ?? 14);
  final jersey = (style.fontFamily ?? '').endsWith('Jersey15');
  final below =
      baseline - size * (jersey ? 750 / 1350 : .7) / 2 - words.height / 2;
  words.dispose();
  return below;
}

double _captionTop(double height, double box, double pixel) =>
    ((height - box) / (2 * pixel)).roundToDouble() * pixel;

class _BarLayout extends MultiChildLayoutDelegate {
  _BarLayout(
    this.rtl, {
    this.caps = 0,
    this.line = 0,
    this.pixel = 1,
    this.striped = true,
    this.boxes = true,
    this.reach = 0,
  });
  final bool rtl;

  /// How far the close box's press reaches across the stripes: the finger's floor in effect.
  final double reach;

  /// Whether the zoom and shade boxes stand at the bar's end; without them the end keeps the close box's room, so the
  /// title stays on the window's middle and the stripes run alike on both sides.
  final bool boxes;

  /// Whether the title keeps to one line beside its stripes; false: it wraps between stripes of at least 12.
  final bool striped;

  /// How far the title's capitals stand below its line's middle, the height of one line, and one device pixel.
  final double caps, line, pixel;
  @override
  void performLayout(Size size) {
    const side = 2.0, box = 13.0, boxGap = 3.0, min = 6.0, margin = 6.0;
    double place(double x, double w) => rtl ? size.width - x - w : x;
    final y = _captionTop(size.height, box, pixel);
    final tiny = BoxConstraints.tight(const Size(box, box));
    layoutChild('close', tiny);
    positionChild('close', Offset(place(side, box), y));
    if (hasChild('reach')) {
      // The close box's press: the bar's height, from its start edge across a finger's reach of stripes.
      final wide = reach;
      layoutChild('reach', BoxConstraints.tight(Size(wide, size.height)));
      positionChild('reach', Offset(place(0, wide), 0));
    }
    layoutChild('shade', tiny);
    positionChild('shade', Offset(place(size.width - side - box, box), y));
    layoutChild('zoom', tiny);
    positionChild(
      'zoom',
      Offset(place(size.width - side - 2 * box - boxGap, box), y),
    );
    final start = side + box;
    final end = boxes
        ? size.width - side - 2 * box - boxGap - boxGap
        : size.width - side - box;
    // With no boxes at the end, the end's stripes run on through the close box's room to the bar's edge, as the
    // start's run from the close box: an empty slot there read as a missing box. The title keeps the window's middle.
    final endRun = boxes ? 0.0 : box;
    final room = end - start;
    final bars = 2 * (min + 2 * margin);
    // A title that wraps (twice the text size on a phone) keeps whole stripes of at least 12 beside its lines: as 6 px
    // stubs they read as nothing, and with none at all the front window read as an inactive one.
    final t = layoutChild(
      'title',
      BoxConstraints(
        maxWidth: math.max(0, room - math.max(bars, 2 * (12 + 2 * margin))),
      ),
    );
    // One line: its capitals' middle on the boxes' middle line, its top on a
    // whole device pixel as the boxes' are (a top on a fraction of one moves
    // the drawn capitals off where they were laid out). More lines centre as
    // a block on the same line.
    final oneLine = line > 0 && t.height < line * 1.5;
    final middle = y + box / 2;
    double snap(double v) => (v / pixel).roundToDouble() * pixel;
    // CSS flex: 1 1 0 on both sides, so the title is centred between the boxes, not the window. The stripes stand
    // where each run is at least 12 px long; shorter, they read as stubs, and the title stands alone between the boxes.
    final spare = (room - t.width) / 2 - 2 * margin;
    final stripes = spare >= 12;
    final bar = stripes ? spare : math.max(0.0, (room - t.width) / 2 - margin);
    final tx = stripes ? start + margin + bar + margin : start + margin + bar;
    final ty = snap(middle - t.height / 2 - (oneLine ? caps : 0));
    positionChild('title', Offset(place(tx, t.width).roundToDouble(), ty));
    final stripe = stripes ? bar : 0.0;
    final st = BoxConstraints.tightFor(width: stripe, height: 12);
    final sy = (1 + (size.height - 1 - 12) / 2).roundToDouble();
    layoutChild('left', st);
    positionChild(
      'left',
      Offset(place(start + margin, stripe).roundToDouble(), sy),
    );
    final endStripe = stripes ? stripe + endRun : 0.0;
    layoutChild('right', BoxConstraints.tightFor(width: endStripe, height: 12));
    positionChild(
      'right',
      Offset(place(tx + t.width + margin, endStripe).roundToDouble(), sy),
    );
  }

  @override
  bool shouldRelayout(_BarLayout o) =>
      o.rtl != rtl ||
      o.boxes != boxes ||
      o.caps != caps ||
      o.line != line ||
      o.pixel != pixel ||
      o.striped != striped ||
      o.reach != reach;
}

/// A title bar. Active: pinstripes, boxes and full ink. Inactive: flat, no boxes, quieter words, in the same place.
class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.title,
    required this.active,
    this.icon,
    this.strong = false,
    this.folded = false,
    this.onClose,
    this.closeLabel,
    this.style,
    this.header = false,
    this.modal = false,
  });
  final RetroDesktopStyle? style;
  final String title;

  /// Whether the bar is a modal sheet's, which is neither zoomed nor shaded: no zoom or shade box at its end.
  final bool modal;
  final IconData? icon;

  /// The close box's name for a screen reader, in place of the shared "Close".
  final String? closeLabel;

  /// [folded]: a window rolled up to its bar, which keeps its fold box even inactive (without it the bar alone read as
  /// a wide push button).
  final bool active, strong, folded;

  /// Whether the title is a heading of its own for a screen reader, as a sheet's is: a window names itself with its
  /// title, but a sheet's title merged into the node of whatever its body taps.
  final bool header;
  final VoidCallback? onClose;

  Widget _heading(Widget words) => header && title.isNotEmpty
      ? Semantics(container: true, header: true, child: words)
      : ExcludeSemantics(child: words);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PaintingBinding.instance.systemFonts,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final states = <WidgetState>{if (active) WidgetState.selected};
    final ink =
        RetroDesktopStyle.first(
          [style, t.windowTheme],
          (s) => s.foreground,
          states,
        ) ??
        (t.chisel && active
            ? c.onHighlight
            : active || strong
            ? c.text
            : c.textTertiary);
    final wordsStyle = t.textTheme.chrome
        .merge(
          RetroDesktopStyle.first(
            [style, t.windowTheme],
            (s) => s.textStyle,
            states,
          ),
        )
        .copyWith(color: ink);
    if (t.chisel) {
      return _chiselBar(context, t, ink, wordsStyle);
    }
    // Off the desk (a phone, a tablet) a window fills its screen and is neither shaded nor zoomed: its zoom and shade
    // boxes, drawn there, read as controls that did nothing; it keeps its close box, the way back.
    Widget box(int kind) => Visibility(
      visible:
          (active && (kind == 0 || (t.desk && !modal))) ||
          (kind == 0 && onClose != null) ||
          (kind == 2 && folded),
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: RetroDesktopPixelPaint(
        painter: _BoxPainter(c, kind, t.shapes.small),
      ),
    );
    final scaler = MediaQuery.textScalerOf(context);
    final pixel = 1 / MediaQuery.devicePixelRatioOf(context);
    final caps = _capsBelowMiddle(wordsStyle, scaler);
    final line = scaler.scale(
      (wordsStyle.fontSize ?? 14) * (wordsStyle.height ?? 1.2),
    );
    // A bar too narrow for the glyph beside a word or two keeps only the words (at 120 wide the glyph and its gap
    // stood 3 px past the room the boxes leave).
    final name = LayoutBuilder(
      builder: (context, room) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: RetroDesktopSpacing.s2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && room.maxWidth >= 4 + 20 + 24) ...[
              // The glyph's middle on the capitals' middle.
              Transform.translate(
                offset: Offset(0, caps),
                child: Icon(icon, size: 14, color: ink),
              ),
              const SizedBox(width: RetroDesktopSpacing.s6),
            ],
            Flexible(child: _heading(Text(title, style: wordsStyle))),
          ],
        ),
      ),
    );
    // The drawing stays 13 pixels; its action has the platform's padded target. Only a finger's reach grows the bar:
    // on a desk the press spans the bar as it stands, so a window that closes stands its title, stripes and boxes
    // level with one that does not, and the bar holds still as a closable window opens beside it.
    final reach = onClose != null;
    final grows = reach && RetroDesktopReach.padsAcross(context);
    // The title's height at a width, and whether it keeps to one line beside its stripes (101 is the boxes, 12 px
    // stripes and their margins).
    (double, bool) titleFit(double width) {
      final words = TextPainter(
        text: TextSpan(text: title, style: wordsStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      );
      final glyph = icon == null ? 0 : 20;
      // Wherever it would leave its stripes shorter than 12, the title wraps instead (one line with 6 to 12 px runs
      // showed no stripes, and the front window read as an inactive one).
      words.layout(maxWidth: math.max(1, width - 101 - glyph));
      final striped = words.computeLineMetrics().length <= 1;
      final height = words.height;
      words.dispose();
      return (
        math.max(grows ? RetroDesktopReach.least(context) : 24, height + 8),
        striped,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final (height, striped) = titleFit(constraints.maxWidth);
        return _Chrome(
          child: SizedBox(
            height: height,
            child: CustomMultiChildLayout(
              delegate: _BarLayout(
                Directionality.of(context) == TextDirection.rtl,
                caps: caps,
                line: line,
                pixel: pixel,
                striped: striped,
                boxes: (t.desk && !modal) || folded,
                reach: RawTapTargets.of(context).touch.width,
              ),
              children: [
                LayoutId(
                  id: 'close',
                  child: onClose == null || reach
                      ? box(0)
                      : RetroDesktopPressable(
                          onPressed: onClose,
                          child: box(0),
                        ),
                ),
                LayoutId(id: 'zoom', child: box(1)),
                LayoutId(id: 'shade', child: box(2)),
                LayoutId(
                  id: 'left',
                  child: active
                      ? RetroDesktopPixelPaint(painter: _Stripes(c))
                      : const SizedBox.shrink(),
                ),
                LayoutId(
                  id: 'right',
                  child: active
                      ? RetroDesktopPixelPaint(painter: _Stripes(c))
                      : const SizedBox.shrink(),
                ),
                LayoutId(id: 'title', child: name),
                if (reach)
                  LayoutId(
                    id: 'reach',
                    child: RetroDesktopPressable(
                      label:
                          closeLabel ??
                          RawWidgetsLocalizations.of(context).closeButtonLabel,
                      onPressed: onClose,
                      // Focus rings the 13 pixels drawn, not the padded target; held, the box drawn there turns in.
                      builder: (context, states) => LayoutBuilder(
                        builder: (context, room) => Stack(
                          children: [
                            const SizedBox.expand(),
                            PositionedDirectional(
                              start: 2,
                              top: _captionTop(room.maxHeight, 13, pixel),
                              width: 13,
                              height: 13,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (states.contains(WidgetState.pressed))
                                    RetroDesktopPixelPaint(
                                      painter: _BoxPainter(
                                        c,
                                        0,
                                        t.shapes.small,
                                        pressed: true,
                                      ),
                                    ),
                                  _CloseRing(states: states),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The close box's focus ring, claimed from its padded press and drawn round
/// the box itself, so it neither crosses the stripes nor runs off the bar.
class _CloseRing extends StatelessWidget {
  const _CloseRing({required this.states});
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    RetroDesktopHighlightClaim.maybeOf(context)?.claim(context, states);
    return RetroDesktopHighlight(
      shape: RetroDesktopTheme.of(context).shapes.small,
      focused: states.contains(WidgetState.focused),
      child: const SizedBox.expand(),
    );
  }
}

extension _ChiselTitleBar on _TitleBar {
  // Chisel's bar: one solid band, the accent while the window is active and a
  // quiet grey while not, the title at its start and three square bevelled
  // buttons at its end: shade, zoom, then close a step apart.
  Widget _chiselBar(
    BuildContext context,
    RetroDesktopThemeData t,
    Color ink,
    TextStyle wordsStyle,
  ) {
    final c = t.colors;
    final reach = onClose != null;
    // Only a finger's reach grows the bar; on a desk the press spans the bar as it stands (as the classic bar's).
    final grows = reach && RetroDesktopReach.padsAcross(context);
    final fill =
        RetroDesktopStyle.first(
          [style, t.windowTheme],
          (s) => s.fill,
          {if (active) WidgetState.selected},
        ) ??
        (active ? c.highlight : c.platinumDark);
    Widget box(int kind) => retroDesktopOwnSize(
      width: 16,
      height: 14,
      alignment: Alignment.center,
      child: RetroDesktopPixelPaint(painter: _CaptionPainter(c, kind)),
    );
    final words = TextPainter(
      text: TextSpan(text: title, style: wordsStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final height = math.max(
      grows ? RetroDesktopReach.least(context) : 22.0,
      words.height + 6,
    );
    words.dispose();
    final pixel = 1 / MediaQuery.devicePixelRatioOf(context);
    final lift =
        (_capsBelowMiddle(wordsStyle, MediaQuery.textScalerOf(context)) / pixel)
            .roundToDouble() *
        pixel;
    // A narrow window keeps its close button and some of its title: the shade
    // and zoom buttons give way first, then the icon. Off the desk (a phone, a
    // tablet) a window fills its screen and is neither shaded nor zoomed: it
    // keeps its close button alone, the way back, as a modal sheet does
    // anywhere. A folded window keeps them anywhere, as Platinum's keeps its
    // fold box: the bar alone read as a wide push button.
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth - 10;
        final withIcon = icon != null && room - 18 >= 16 + 24;
        final all =
            ((t.desk && !modal) || folded) &&
            room - (withIcon ? 18 : 0) >= 3 * 16 + 2 + 24;
        return _Chrome(
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: fill)),
                // The bar's whole height, so a bar grown to a finger's reach
                // keeps its title and buttons on its middle line.
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      RetroDesktopSpacing.s4,
                      0,
                      RetroDesktopSpacing.s2,
                      0,
                    ),
                    child: Row(
                      children: [
                        if (withIcon) ...[
                          Icon(icon, size: 14, color: ink),
                          const SizedBox(width: RetroDesktopSpacing.s4),
                        ],
                        Expanded(
                          // The capitals' middle, not the line's, on the
                          // bar's middle line with the glyph and buttons.
                          child: Transform.translate(
                            offset: Offset(0, -lift),
                            child: _heading(
                              Text(
                                title,
                                style: wordsStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: RetroDesktopSpacing.s4),
                        if (all) ...[
                          box(2),
                          box(1),
                          const SizedBox(width: RetroDesktopSpacing.s2),
                        ],
                        onClose == null || reach
                            ? box(0)
                            : RetroDesktopPressable(
                                onPressed: onClose,
                                child: box(0),
                              ),
                      ],
                    ),
                  ),
                ),
                if (reach)
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    width: RawTapTargets.of(context).touch.width,
                    child: RetroDesktopPressable(
                      label:
                          closeLabel ??
                          RawWidgetsLocalizations.of(context).closeButtonLabel,
                      onPressed: onClose,
                      // Focus marks the button drawn, not the padded target.
                      builder: (context, states) => Stack(
                        children: [
                          const SizedBox.expand(),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: RetroDesktopSpacing.s2,
                              ),
                              child: SizedBox(
                                width: 16,
                                height: 14,
                                child: _CloseRing(states: states),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A Chisel caption button: a raised square with a minimise bar (2), a
/// maximise frame (1) or a close cross (0) in ink.
class _CaptionPainter extends RetroDesktopPixelPainter {
  const _CaptionPainter(this.c, this.kind);
  final RetroDesktopColors c;
  final int kind;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    px.fill(r, c.platinum);
    retroDesktopPaintChiselRect(
      px.canvas,
      r,
      retroDesktopChiselEdge(c),
      litFromRight: px.litFromRight,
    );
    final ink = c.text;
    final cx = px.x(r.center.dx);
    final cy = px.y(r.center.dy);
    switch (kind) {
      case 0:
        for (var i = 0; i < 6; i++) {
          px.fillExact(cx - 4 + i, cy - 3 + i, cx - 2 + i, cy - 2 + i, ink);
          px.fillExact(cx + 2 - i, cy - 3 + i, cx + 4 - i, cy - 2 + i, ink);
        }
      case 1:
        final f = px.snap(
          Rect.fromCenter(center: r.center, width: 9, height: 8),
        );
        px.fillExact(f.left, f.top, f.right, f.top + 2, ink);
        px.fillExact(f.left, f.top, f.left + 1, f.bottom, ink);
        px.fillExact(f.right - 1, f.top, f.right, f.bottom, ink);
        px.fillExact(f.left, f.bottom - 1, f.right, f.bottom, ink);
      default:
        px.fillExact(cx - 3, cy + 2, cx + 3, cy + 4, ink);
    }
  }

  @override
  bool shouldRepaint(_CaptionPainter o) => o.c != c || o.kind != kind;
}

/// A window's shadow: its own outline, hard, offset down and toward the end
/// (away from the light at the top start), as the period's windows cast it. The front window's is darker; no window casts a
/// soft one (a blurred slab read as a second, smaller window under it). Chisel
/// draws none: its windows stand on their bevel.
List<BoxShadow> _shadows(RetroDesktopColors c, bool active) => [
  BoxShadow(
    color: c.shade.withValues(
      alpha: c.brightness == Brightness.dark
          ? (active ? .95 : .85)
          : (active ? .8 : .55),
    ),
    offset: const Offset(2, 2),
  ),
];

class _GrowBox extends RetroDesktopPixelPainter {
  const _GrowBox(this.c);
  final RetroDesktopColors c;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final canvas = px.canvas;
    Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);
    px.fill(const Rect.fromLTWH(4, 11, 8, 1), c.bevelLight);
    px.fill(const Rect.fromLTWH(4, 10, 8, 1), c.bevelDark);
    canvas.drawPath(
      poly(const [Offset(12, 2), Offset(12, 4), Offset(4, 12), Offset(2, 12)]),
      Paint()..color = c.bevelDark,
    );
    canvas.drawPath(
      poly(const [Offset(12, 4), Offset(12, 5), Offset(5, 12), Offset(4, 12)]),
      Paint()..color = c.bevelLight,
    );
    canvas.drawPath(
      poly(const [Offset(12, 6), Offset(12, 8), Offset(8, 12), Offset(6, 12)]),
      Paint()..color = c.bevelDark,
    );
    canvas.drawPath(
      poly(const [Offset(12, 8), Offset(12, 9), Offset(9, 12), Offset(8, 12)]),
      Paint()..color = c.bevelLight,
    );
  }

  @override
  bool shouldRepaint(_GrowBox o) => o.c != c;
}

/// `*words*` in a string go to full ink and bold, as a status line sets its figures.
List<InlineSpan> _starred(String text, TextStyle strong) {
  final out = <InlineSpan>[];
  final parts = text.split('*');
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    out.add(TextSpan(text: parts[i], style: i.isOdd ? strong : null));
  }
  return out;
}

/// A window: every section of a page is one. Give it a title; give it `info` for the small strip under the title bar, and
/// `status` for the foot. Whether it is active is the desktop's to say, not the window's, so its title bar, frame and shadow
/// follow. Its child stands 12 in from the frame unless it is a part that draws its own inset, like `RetroDesktopWell`.
///
/// ```dart
/// RetroDesktopWindow(title: 'Recent', icon: RetroDesktopGlyphs.fileText, info: '6 of 40', status: const ['Synced'], child: RetroDesktopWell(child: list))
/// ```
class RetroDesktopWindow extends StatelessWidget {
  /// Creates a [RetroDesktopWindow].
  const RetroDesktopWindow({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.info,
    this.infoEnd,
    this.infoFlag,
    this.toolbar,
    this.status = const [],
    this.statusAction,
    this.padding,
    this.onClose,
    this.style,
    this.fills = false,
  });

  /// Whether [child] scrolls itself: it takes the height the window is given
  /// and has none of its own.
  final bool fills;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String title;

  /// The glyph shown with the content.
  final IconData? icon;

  /// The widget displayed inside this part.
  final Widget child;

  /// The strip under the title bar: a count at its start, [infoEnd] at its end, [infoFlag] an inverted chip before it.
  final String? info, infoEnd, infoFlag;

  /// A `RetroDesktopToolbar`.
  final Widget? toolbar;

  /// The foot's facts, split by a rule; `*words*` go to full ink. On a desktop a grow box stands at its end.
  final List<String> status;

  /// A small `RetroDesktopButton` in the foot.
  final Widget? statusAction;

  /// In place of the 12 a window gives a child that isn't flush.
  final EdgeInsetsGeometry? padding;

  /// Draws the close box live. On a phone such a window's title bar stands a finger's reach tall, so the box reaches a finger.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => RetroDesktopModalWatch(builder: _build);

  Widget _build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    // A window inside a window is drawn inactive: a page can't get a second hero by nesting one. So is one under an
    // alert, a dialog or a sheet: the window in front is the active one (the stacking law).
    final active =
        (RetroDesktopWindowScope.maybeOf(context)?.active ?? false) &&
        context.getInheritedWidgetOfExactType<_InsideWindow>() == null &&
        !retroDesktopUnderModal(context);
    final states = <WidgetState>{if (active) WidgetState.selected};
    final flush = child is RetroDesktopFlush;
    final inset = t.density.apply(
      padding ??
          const EdgeInsets.fromLTRB(
            RetroDesktopSpacing.s12,
            RetroDesktopSpacing.s12,
            RetroDesktopSpacing.s12,
            RetroDesktopSpacing.s8,
          ),
      Directionality.of(context),
    );
    final body = flush && padding == null
        ? child
        : Padding(padding: inset, child: child);
    // Where the content is a well from edge to edge there is no keyline to
    // share: the strip and the foot keep their own 8.
    final words = flush && padding == null
        ? t.density.apply(
            const EdgeInsets.symmetric(horizontal: RetroDesktopSpacing.s8),
            Directionality.of(context),
          )
        : inset;
    final route = ModalRoute.of(context);
    final titleNamedByRoute =
        route is RawSideSheetRoute &&
        route.semanticLabel == title &&
        context.getInheritedWidgetOfExactType<_InsideWindow>() == null;
    return Semantics(
      container: true,
      label: titleNamedByRoute ? null : title,
      child: retroDesktopFace(
        shadows: _shadows(c, active),
        states: states,
        style: style,
        scale: RetroDesktopFaceScale.window,
        component: t.windowTheme.over(
          RetroDesktopStyle(
            fill: WidgetStatePropertyAll(c.platinum),
            // Activation highlights the title; the body stays on grey.
            foreground: WidgetStatePropertyAll(c.text),
          ),
        ),
        padding: EdgeInsets.zero,
        child: Padding(
          padding: retroDesktopWindowFrame(t),
          child: RetroDesktopColumn(
            children: [
              _TitleBar(
                title: title,
                style: style,
                icon: icon,
                active: active,
                onClose: onClose,
              ),
              // The strip's and the foot's words stand on the content's
              // keylines.
              if (info != null || infoEnd != null || infoFlag != null)
                _InfoStrip(
                  info: info,
                  end: infoEnd,
                  flag: infoFlag,
                  inset: words,
                ),
              ?toolbar,
              RetroDesktopGrow(
                fills: fills,
                // A window's content shares its keylines (the check in ui_core's alignment.dart).
                child: _InsideWindow(
                  child: RawKeylineRegion(label: title, child: body),
                ),
              ),
              if (status.isNotEmpty || statusAction != null)
                _Status(status: status, action: statusAction, inset: words),
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
      ..add(FlagProperty('fills', value: fills, ifTrue: 'fills'))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('title', title))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(StringProperty('info', info, defaultValue: null))
      ..add(StringProperty('infoEnd', infoEnd, defaultValue: null))
      ..add(StringProperty('infoFlag', infoFlag, defaultValue: null))
      ..add(IterableProperty<String>('status', status, defaultValue: const []))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: null,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onClose', onClose));
  }
}

class _InsideWindow extends InheritedWidget {
  const _InsideWindow({required super.child});
  @override
  bool updateShouldNotify(_InsideWindow old) => false;
}

class _RulePainter extends RetroDesktopPixelPainter {
  const _RulePainter(this.dark, this.light);
  final Color dark, light;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final top = px.y(0);
    px.fillExact(px.x(0), top, px.x(s.width), top + px.hair, dark);
    px.fillExact(
      px.x(0),
      top + px.hair,
      px.x(s.width),
      top + 2 * px.hair,
      light,
    );
  }

  @override
  bool shouldRepaint(_RulePainter o) => o.dark != dark || o.light != light;
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({this.info, this.end, this.flag, required this.inset});
  final String? info, end, flag;

  /// The window content's insets: its words start and end on them.
  final EdgeInsets inset;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: RetroDesktopSpacing.s4),
      child: RetroDesktopPixelPaint(
        painter: _RulePainter(c.bevelDark, c.bevelLight),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 22),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              inset.left,
              RetroDesktopSpacing.px,
              inset.right,
              0,
            ),
            // The count at the start and the fact at the end on one line while both fit; past that (large text
            // on a phone) the end fact steps under the count, each whole, rather than the count being cut to a
            // third of the strip ("6 docu…").
            child: LayoutBuilder(
              builder: (context, box) => Wrap(
                alignment: WrapAlignment.spaceBetween,
                // One line stands on the strip's middle, as it did in a row; two fill it.
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: RetroDesktopSpacing.s8,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth),
                    child: Text(
                      info ?? '',
                      style: t.textTheme.caption,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (end != null || flag != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: box.maxWidth),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (flag != null) ...[
                            Flexible(
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  color: c.text,
                                  shape: t.shapes.full,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    RetroDesktopSpacing.s4,
                                    RetroDesktopSpacing.px,
                                    RetroDesktopSpacing.s4,
                                    0,
                                  ),
                                  child: Text(
                                    flag!,
                                    style: t.textTheme.pixel(
                                      15,
                                      14,
                                      color: c.paper,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: RetroDesktopSpacing.s4),
                          ],
                          if (end != null)
                            Flexible(
                              child: Text(
                                end!,
                                style: t.textTheme.caption,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status, this.action, required this.inset});
  final List<String> status;
  final Widget? action;

  /// The window content's insets: the foot's first word or button starts on
  /// the leading one; the grow box keeps the corner.
  final EdgeInsets inset;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final strong = t.textTheme.caption.copyWith(
      color: c.text,
      fontWeight: FontWeight.w700,
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          rtl ? inset.right : inset.left,
          4,
          4,
          0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              // The action never pushes past the bar: at large text its words
              // give way inside it.
              if (action != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.max(
                      0,
                      constraints.maxWidth - (t.desk ? 13 : 0),
                    ),
                  ),
                  child: action,
                ),
              // The words take the room left: the grow box stands in the window's corner however few they are.
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < status.length; i++) ...[
                      if (i > 0 || action != null) ...[
                        const SizedBox(width: RetroDesktopSpacing.s10),
                        _StatusRule(
                          c.brightness == Brightness.dark
                              ? c.bevelLight
                              : c.bevelDark,
                        ),
                        const SizedBox(width: RetroDesktopSpacing.s10),
                      ],
                      // Each as wide as its words while they fit. Past that they give way in proportion to their words,
                      // not equally, and wrap at a space (large text): a status cut to "kept as you …" said nothing.
                      Flexible(
                        flex: 1000 + status[i].length * 40,
                        child: Text.rich(
                          TextSpan(
                            style: t.textTheme.caption,
                            children: _starred(status[i], strong),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (t.desk)
                _Chrome(
                  child: retroDesktopOwnSize(
                    width: 13,
                    height: 13,
                    // Its ridges face the corner it drags: in right to left
                    // it stands at the bottom left, mirrored.
                    child: Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: RetroDesktopPixelPaint(painter: _GrowBox(c)),
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

class _StatusRule extends StatelessWidget {
  const _StatusRule(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => retroDesktopOwnSize(
    width: 1,
    height: 12,
    child: RetroDesktopPixelPaint(painter: _DownRule(color)),
  );
}

class _DownRule extends RetroDesktopPixelPainter {
  const _DownRule(this.color);
  final Color color;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) =>
      px.ruleDown(0, s.height, 0, color);
  @override
  bool shouldRepaint(_DownRule o) => o.color != color;
}

/// The inset white well: your content. Lists, fields, the paper of a document, a chart's plot. A well takes the height a
/// stretched window gives it, so an empty end reads as an empty list, not a hole.
///
/// ```dart
/// RetroDesktopWell(child: RetroDesktopList(children: rows))
/// ```
class RetroDesktopWell extends StatelessWidget implements RetroDesktopFlush {
  /// Creates a [RetroDesktopWell].
  const RetroDesktopWell({
    super.key,
    required this.child,
    this.padding,
    this.style,
  });

  /// The widget displayed inside this part.
  final Widget child;

  /// Insets around the content.
  final EdgeInsetsGeometry? padding;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    // To ui_core's keyline check the well is one item at its frame, whatever
    // it holds (a table's heads and rows have the well's own keylines).
    return RawKeylineFace(
      child: retroDesktopFace(
        states: const {},
        component: t.wellTheme.over(
          RetroDesktopStyle(fill: WidgetStatePropertyAll(t.colors.paper)),
        ),
        scale: RetroDesktopFaceScale.surface,
        sunken: true,
        style: style,
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

/// A bar of controls under the title bar: wrap each in nothing, and put `Expanded` round the one that takes the room, or a
/// `Spacer` where it parts. With no `Expanded`, the controls before the `Spacer` wrap rather than overflow.
///
/// ```dart
/// RetroDesktopToolbar(children: [Expanded(child: RetroDesktopTextField(hintText: 'Search')), RetroDesktopButton('New', isDefaultAction: true, icon: RetroDesktopGlyphs.plus, onPressed: () {})])
/// ```
class RetroDesktopToolbar extends StatelessWidget {
  /// Creates a [RetroDesktopToolbar].
  const RetroDesktopToolbar({
    super.key,
    required this.children,
    this.gap = 8,
    this.style,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      RetroDesktopSpacing.s12,
      RetroDesktopSpacing.s10,
      RetroDesktopSpacing.s8,
      RetroDesktopSpacing.s6,
    ),
  });

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  /// The child widgets in reading order.
  final List<Widget> children;

  /// Space between adjacent items in logical pixels.
  final double gap;

  /// Insets around the content.
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final spacing = gap * t.density.horizontal;
    Widget row(List<Widget> kids) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kids.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          kids[i],
        ],
      ],
    );
    final Widget body;
    if (children.any((c) => c is Flexible)) {
      body = row(children);
    } else {
      final at = children.indexWhere((c) => c is Spacer);
      final start = at < 0 ? children : children.sublist(0, at);
      final end = at < 0 ? const <Widget>[] : children.sublist(at + 1);
      body = Row(
        children: [
          // Chip groups: a tool's reach takes the room between the faces, so
          // the tools stand [gap] apart as drawn, on a phone too.
          Expanded(
            child: RawChipGroup(
              spacing: spacing,
              runSpacing: spacing,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: start,
            ),
          ),
          if (end.isNotEmpty) ...[
            SizedBox(width: spacing),
            RawChipGroup(
              spacing: spacing,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: end,
            ),
          ],
        ],
      );
    }
    return retroDesktopFace(
      states: const {},
      component: t.toolbarTheme.over(
        const RetroDesktopStyle(
          fill: WidgetStatePropertyAll(Color(0x00000000)),
          side: WidgetStatePropertyAll(BorderSide.none),
        ),
      ),
      style: style,
      bevel: false,
      padding: padding,
      child: body,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('gap', gap, defaultValue: 8))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: const EdgeInsetsDirectional.fromSTEB(
            RetroDesktopSpacing.s12,
            RetroDesktopSpacing.s10,
            RetroDesktopSpacing.s8,
            RetroDesktopSpacing.s6,
          ),
        ),
      );
  }
}

class _ToolRulePainter extends RetroDesktopPixelPainter {
  const _ToolRulePainter(this.c);
  final RetroDesktopColors c;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) =>
      px.grooveDown(0, s.height, 0, c.bevelDark, c.bevelLight);

  @override
  bool shouldRepaint(_ToolRulePainter o) => o.c != c;
}

/// An etched rule between groups of tools in a `RetroDesktopToolbar`.
///
/// ```dart
/// RetroDesktopToolRule()
/// ```
class RetroDesktopToolRule extends StatelessWidget {
  /// Creates a [RetroDesktopToolRule].
  const RetroDesktopToolRule({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: RetroDesktopSpacing.s4),
    child: retroDesktopOwnSize(
      width: 2,
      height: 20,
      child: RetroDesktopPixelPaint(
        painter: _ToolRulePainter(RetroDesktopTheme.of(context).colors),
      ),
    ),
  );
}

/// A small fact among the tools, from 1024 wide: a phone hasn't the room. Its icon is set in quiet ink.
///
/// ```dart
/// RetroDesktopToolNote('Synced', icon: RetroDesktopGlyphs.cloudCheck)
/// ```
class RetroDesktopToolNote extends StatelessWidget {
  /// Creates a [RetroDesktopToolNote].
  const RetroDesktopToolNote(this.text, {super.key, this.icon});

  /// The text displayed by this part.
  final String text;

  /// The glyph shown with the content.
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    if (!t.desk) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RetroDesktopSpacing.s4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: t.colors.textSecondary),
            const SizedBox(width: RetroDesktopSpacing.s6),
          ],
          Text(text, style: t.textTheme.caption, maxLines: 1, softWrap: false),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null));
  }
}

/// An icon on the desk, for a place of the app's own (a disk, a document, the bin): its drawing over its name on a plate.
/// A press selects it and its name takes the highlight; a second press soon after, or Return while it has focus, opens it.
/// On a phone, where nothing is pressed twice, one press opens it. With neither callback it is only a mark.
///
/// ```dart
/// RetroDesktopDeskIcon('Documents', art: const RetroDesktopSystemMark(size: 40), selected: true, onPressed: select, onOpen: open)
/// ```
class RetroDesktopDeskIcon extends StatefulWidget {
  /// Creates a [RetroDesktopDeskIcon].
  const RetroDesktopDeskIcon(
    this.name, {
    super.key,
    required this.art,
    this.selected = false,
    this.onPressed,
    this.onOpen,
    this.focusNode,
    this.autofocus = false,
  });

  /// Its name, on the plate under the drawing.
  final String name;

  /// The drawing, about 48 square.
  final Widget art;

  /// Whether it is the selected icon: its name takes the highlight.
  final bool selected;

  /// Selects it: one press.
  final VoidCallback? onPressed;

  /// Opens it: a second press soon after the first, Return, or on a phone one press.
  final VoidCallback? onOpen;

  /// {@macro retro_desktop.ownFocusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  /// The width an icon takes at [context]'s text size, for a rail of icons: 84 at 100%, its name's plate growing
  /// with the text so a name reads whole (168 at 200%).
  static double widthOf(BuildContext context) =>
      (84 * math.max(1.0, MediaQuery.textScalerOf(context).scale(12) / 12))
          .roundToDouble();

  @override
  State<RetroDesktopDeskIcon> createState() => _RetroDesktopDeskIconState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(ObjectFlagProperty<VoidCallback>.has('onOpen', onOpen))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _RetroDesktopDeskIconState extends State<RetroDesktopDeskIcon> {
  Duration? _down, _last;

  // The time is the pointer's own; a press with none (the keyboard, a screen reader) selects.
  void _press() {
    final open = widget.onOpen;
    final at = _down;
    _down = null;
    if (!RetroDesktopTheme.of(context).desk && open != null) {
      open();
      return;
    }
    final last = _last;
    final twice = at != null && last != null && at - last <= kDoubleTapTimeout;
    _last = twice ? null : at;
    if (twice && open != null) {
      open();
    } else {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final lit = widget.selected;
    final width = RetroDesktopDeskIcon.widthOf(context);
    final face = SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.art,
          const SizedBox(height: RetroDesktopSpacing.s4),
          // The plate takes the family's control shape, as a file's name does.
          DecoratedBox(
            decoration: ShapeDecoration(
              color: lit ? c.highlight : c.markLabel,
              shape: t.shapes.small.copyWith(side: BorderSide.none),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RetroDesktopSpacing.s4,
              ),
              child: _IconName(
                widget.name,
                t.textTheme
                    .text(12, 15, weight: FontWeight.w600)
                    .copyWith(color: lit ? c.onHighlight : null),
                // The plate's room: the icon's width, less the plate's 4 a side.
                width - 2 * RetroDesktopSpacing.s4,
              ),
            ),
          ),
        ],
      ),
    );
    if (widget.onPressed == null && widget.onOpen == null) {
      return Semantics(
        label: widget.name,
        child: ExcludeSemantics(child: face),
      );
    }
    return CallbackShortcuts(
      bindings: {
        if (widget.onOpen != null) ...{
          const SingleActivator(LogicalKeyboardKey.enter): widget.onOpen!,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): widget.onOpen!,
        },
      },
      child: Listener(
        onPointerDown: (e) => _down = e.timeStamp,
        child: RetroDesktopPressable(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          label: widget.name,
          selected: lit,
          onPressed: _press,
          child: face,
        ),
      ),
    );
  }
}

// A desk icon's name, whole, on at most two lines broken only between words ("Docu" over "ments" broke inside one). A
// name that can't be (a word too long for its line, or three lines of words) stands on one line cut in its middle, as
// the Finder cut a long name ("Quarterly…report"): never an ellipsis inside a two-line name. Measured again when a
// font arrives (on the web a script's font loads after the first frame).
class _IconName extends StatelessWidget {
  const _IconName(this.name, this.style, this.room);

  final String name;
  final TextStyle style;
  final double room;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PaintingBinding.instance.systemFonts,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    bool fits(String words) {
      final p = TextPainter(
        text: TextSpan(text: words, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = p.width;
      p.dispose();
      return w <= room;
    }

    final whole = name.trim();
    final lines = <String>[];
    for (final word in whole.split(RegExp(r'\s+'))) {
      if (lines.isNotEmpty && fits('${lines.last} $word')) {
        lines.last = '${lines.last} $word';
      } else {
        lines.add(word);
      }
    }
    Widget line(String words) => Text(
      words,
      style: style,
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
    );
    if (lines.length <= 2 && lines.every(fits)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final words in lines) line(words)],
      );
    }
    // The most of its start and end that fit either side of the ellipsis, the start the longer by one.
    final chars = whole.characters.toList();
    String cut(int keep) =>
        '${chars.take((keep + 1) ~/ 2).join().trimRight()}…'
        '${chars.skip(chars.length - keep ~/ 2).join().trimLeft()}';
    var lo = 0, hi = chars.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (fits(cut(mid))) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return line(cut(lo));
  }
}

/// A collapsed window: its title bar alone, seated in a column, the route to what it holds. A phone hides it, so its route
/// must also be a tab.
///
/// ```dart
/// RetroDesktopWindowShade(title: 'Inbox · 18 open', icon: RetroDesktopGlyphs.inbox, onPressed: open)
/// ```
class RetroDesktopWindowShade extends StatelessWidget {
  /// Creates a [RetroDesktopWindowShade].
  const RetroDesktopWindowShade({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String title;

  /// The glyph shown with the content.
  final IconData? icon;

  /// {@macro retro_desktop.onPressed}
  final VoidCallback? onPressed;

  /// {@macro retro_desktop.ownFocusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final bar = retroDesktopFace(
      shadows: _shadows(c, false),
      states: const {},
      style: style,
      scale: RetroDesktopFaceScale.window,
      padding: EdgeInsets.zero,
      component: t.windowTheme.over(
        RetroDesktopStyle(fill: WidgetStatePropertyAll(c.platinum)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RetroDesktopSpacing.s4 + RetroDesktopSpacing.px,
          RetroDesktopSpacing.px,
          RetroDesktopSpacing.s4 + RetroDesktopSpacing.px,
          RetroDesktopSpacing.px,
        ),
        child: _TitleBar(
          title: title,
          style: style,
          icon: icon,
          active: false,
          strong: true,
          folded: true,
        ),
      ),
    );
    return onPressed == null
        ? bar
        : RetroDesktopPressable(
            focusNode: focusNode,
            autofocus: autofocus,
            button: true,
            label: title,
            onPressed: onPressed,
            child: RetroDesktopReach(child: bar),
          );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('title', title))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// An alert box: a double frame, an icon, a head, a line and its buttons, the last usually a `RetroDesktopButton`. Put it first
/// in a tile and on a desktop it lays itself over its neighbour for depth, but only over empty paper: if words stand there
/// it stays in its own column, so it never hides anything, on any data. On a phone it is a card in the stack.
///
/// ```dart
/// RetroDesktopAlert(icon: RetroDesktopGlyphs.alarmClock, title: 'Due at 14:00', body: 'The next step wants a warm room.', meta: 'in 4 h', actions: [RetroDesktopButton('Snooze', onPressed: () {}), RetroDesktopButton('Open', isDefaultAction: true, onPressed: () {})])
/// ```
class RetroDesktopAlert extends StatelessWidget {
  /// Creates a [RetroDesktopAlert].
  const RetroDesktopAlert({
    super.key,
    required this.title,
    this.body,
    this.icon = RetroDesktopGlyphs.triangleAlert,
    this.meta,
    this.actions = const [],
    this.liveRegion = true,
    this.mark,
    this.style,
    this.floating = true,
  });

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  /// Whether changes are announced as a live region.
  final bool liveRegion;

  /// Whether it stands as a window of its own, casting a window's hard shadow. False for a notice that sits in a
  /// window's content (a banner, an error state): only windows cast shadows (the light law).
  final bool floating;

  /// An identifying glyph or caller-supplied widget.
  final Widget? mark;

  /// The heading displayed above the content.
  final String title;

  /// The main content shown beneath the heading.
  final String? body;

  /// Secondary information displayed with the main content.
  final String? meta;

  /// The glyph shown with the content.
  final IconData icon;

  /// The actions displayed after the content.
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final ink = RetroDesktopStyle.first(
      [style, t.noticeTheme],
      (s) => s.foreground,
      const {},
    );
    final words = RetroDesktopStyle.first(
      [style, t.noticeTheme],
      (s) => s.textStyle,
      const {},
    );
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: retroDesktopFace(
        shadows: floating ? _shadows(c, true) : null,
        states: const {},
        style: style,
        scale: RetroDesktopFaceScale.window,
        component: t.noticeTheme.over(
          RetroDesktopStyle(fill: WidgetStatePropertyAll(c.platinum)),
        ),
        padding: const EdgeInsets.fromLTRB(
          RetroDesktopSpacing.s16,
          RetroDesktopSpacing.s16,
          RetroDesktopSpacing.s16,
          RetroDesktopSpacing.s12,
        ),
        child: Padding(
          padding: EdgeInsets.zero,
          child: RetroDesktopColumn(
            gap: 14,
            children: [
              LayoutBuilder(
                builder: (context, room) {
                  final titleStyle = t.textTheme.sub
                      .merge(words)
                      .copyWith(color: ink);
                  // The picture opens the box beside the title's top; once the title's first line grows taller than the
                  // picture (at a larger text size), the picture comes down to stand on its capitals' middle (left at the
                  // top, it stood above the words).
                  final down = math.max(
                    0.0,
                    retroDesktopCapsLine(context, titleStyle).middle - 20,
                  );
                  final markView = Container(
                    width: 40,
                    height: 40 + down,
                    padding: EdgeInsets.only(top: down),
                    child: ExcludeSemantics(
                      child: Center(
                        // An alert glyph opens the box with the period's picture
                        // for it (the note, the caution triangle, the stop
                        // sign); any other glyph is drawn in the box's ink.
                        child:
                            mark ??
                            switch (retroDesktopToneOfGlyph(icon)) {
                              final tone? => retroDesktopAlertArt(
                                t,
                                tone,
                                size:
                                    RetroDesktopStyle.first(
                                      [style, t.noticeTheme],
                                      (s) => s.iconSize,
                                      const {},
                                    ) ??
                                    32,
                              ),
                              null => Icon(
                                icon,
                                size:
                                    RetroDesktopStyle.first(
                                      [style, t.noticeTheme],
                                      (s) => s.iconSize,
                                      const {},
                                    ) ??
                                    36,
                                color: ink ?? c.text,
                              ),
                            },
                      ),
                    ),
                  );
                  final textView = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: titleStyle),
                      if (body != null) ...[
                        const SizedBox(height: RetroDesktopSpacing.s4),
                        Text(
                          body!,
                          style: t.textTheme.note
                              .merge(words)
                              .copyWith(color: ink),
                        ),
                      ],
                    ],
                  );
                  return room.maxWidth < 120
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            markView,
                            const SizedBox(height: RetroDesktopSpacing.s8),
                            textView,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            markView,
                            const SizedBox(width: RetroDesktopSpacing.s14),
                            Expanded(child: textView),
                          ],
                        );
                },
              ),
              if (actions.isNotEmpty || meta != null)
                RetroDesktopSplit(
                  gap: 8,
                  runGap: 8,
                  start: meta == null
                      ? const SizedBox.shrink()
                      : Text(
                          meta!,
                          style: t.textTheme.caption.copyWith(
                            color: c.textTertiary,
                          ),
                          maxLines: 1,
                        ),
                  end: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: RetroDesktopSpacing.s8,
                    runSpacing: RetroDesktopSpacing.s8,
                    children: actions,
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
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'liveRegion',
          value: liveRegion,
          ifFalse: 'liveRegion: false',
        ),
      )
      ..add(
        FlagProperty('floating', value: floating, ifFalse: 'floating: false'),
      )
      ..add(StringProperty('title', title))
      ..add(StringProperty('body', body, defaultValue: null))
      ..add(StringProperty('meta', meta, defaultValue: null))
      ..add(
        DiagnosticsProperty<IconData>(
          'icon',
          icon,
          defaultValue: RetroDesktopGlyphs.triangleAlert,
        ),
      );
  }
}

/// A group of windows standing in one column of the desktop. [span] is its share of the 12 columns. [under] is a row of
/// tiles standing below its windows and sharing its width. The last window of a column takes up the slack, so all columns end
/// on one line.
class RetroDesktopWindowColumn {
  /// Creates a [RetroDesktopWindowColumn].
  const RetroDesktopWindowColumn({
    required this.span,
    required this.windows,
    this.under = const [],
  });

  /// The number of grid columns occupied by this item.
  final int span;

  /// The windows arranged on the desktop.
  final List<Widget> windows;

  /// The content placed below the main pane.
  final List<RetroDesktopWindowColumn> under;
}

String? _titleOf(Widget w) => switch (w) {
  final RetroDesktopWindow x => x.title,
  final RetroDesktopAlert x => x.title,
  final RetroDesktopWindowShade x => x.title,
  _ => null,
};

/// The page's frame. Say which window is [active] by its title: that one is the hero, with pinstripes, boxes, a darker frame
/// and a deeper shadow, and no other can be: a window has no way to say so. A title that matches nothing, or none at all,
/// makes the first window active. On a phone the windows stack with the active one first and a star inside it draws compact,
/// unless the page says [whole], which only the look's home does. From 1024 wide they tile on 12 columns, every column ending
/// on one line.
///
/// ```dart
/// RetroDesktopDesktop(active: 'Today', tiles: [RetroDesktopWindowColumn(span: 8, windows: [RetroDesktopWindow(title: 'Today', child: list)]), RetroDesktopWindowColumn(span: 4, windows: [RetroDesktopWindow(title: 'Recent', child: other)])])
/// ```
class RetroDesktopDesktop extends StatelessWidget {
  /// Creates a [RetroDesktopDesktop].
  const RetroDesktopDesktop({
    super.key,
    required this.tiles,
    this.active,
    this.whole = false,
    this.marks,
    this.strip,
    this.phoneOrder = const [],
  });

  /// The tile groups arranged on the desktop.
  final List<RetroDesktopWindowColumn> tiles;

  /// The title of the one active window.
  final String? active;

  /// A star in the active window keeps its whole form on a phone. For the look's home alone.
  final bool whole;

  /// Caller-supplied desktop marks: in the rail at a desktop's right; on a phone only with [whole], as the page's sign-off.
  final Widget? marks;

  /// A `RetroDesktopDeskStrip`, flush to the screen's edge under the windows. Desktop only.
  final Widget? strip;

  /// Titles in the order a phone stacks them; the rest follow. Left out: the active window, then the tiles after it.
  final List<String> phoneOrder;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final entries = <Widget>[];
    final specs = <_Spec>[];
    _Spec walk(RetroDesktopWindowColumn tile) {
      final items = <int>[];
      for (final w in tile.windows) {
        items.add(entries.length);
        entries.add(w);
      }
      final under = [for (final u in tile.under) walk(u)];
      return _Spec(tile.span, items, under);
    }

    for (final tile in tiles) {
      specs.add(walk(tile));
    }
    var chosen = -1;
    for (var i = 0; i < entries.length; i++) {
      final w = entries[i];
      if (w is RetroDesktopWindow && w.title == active) {
        chosen = i;
        break;
      }
    }
    if (chosen < 0) chosen = entries.indexWhere((w) => w is RetroDesktopWindow);
    if (chosen < 0) {
      chosen = entries.indexWhere(
        (w) => w is! RetroDesktopAlert && w is! RetroDesktopWindowShade,
      );
    }
    Widget slot(int i) => RetroDesktopWindowScope(
      active: i == chosen,
      compact: !whole,
      child: entries[i],
    );
    if (!t.desk) {
      final order = _phoneOrder(entries, specs, chosen);
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          RetroDesktopSpacing.s12,
          RetroDesktopSpacing.s12,
          RetroDesktopSpacing.s12,
          RetroDesktopSpacing.s20,
        ),
        child: RetroDesktopColumn(
          gap: 12,
          children: [
            for (final i in order) slot(i),
            if (whole && marks != null) marks!,
          ],
        ),
      );
    }
    return _Tiles(
      specs: specs,
      alerts: {
        for (var i = 0; i < entries.length; i++)
          if (entries[i] is RetroDesktopAlert) i,
      },
      fixed: {
        for (var i = 0; i < entries.length; i++)
          if (entries[i] is RetroDesktopAlert ||
              entries[i] is RetroDesktopWindowShade)
            i,
      },
      active: chosen,
      hasMarks: marks != null,
      hasStrip: strip != null,
      direction: Directionality.of(context),
      children: [
        for (var i = 0; i < entries.length; i++) slot(i),
        ?marks,
        ?strip,
      ],
    );
  }

  List<int> _phoneOrder(List<Widget> entries, List<_Spec> specs, int chosen) {
    final out = <int>[];
    void add(int i) {
      if (out.contains(i) || entries[i] is RetroDesktopWindowShade) return;
      out.add(i);
    }

    for (final title in phoneOrder) {
      for (var i = 0; i < entries.length; i++) {
        if (_titleOf(entries[i]) == title) {
          add(i);
          break;
        }
      }
    }
    if (chosen >= 0) add(chosen);
    // The tile the active window stands in, then the tiles after it, then round to the first.
    bool holds(_Spec s) =>
        s.items.contains(chosen) || s.under.any((u) => holds(u));
    final from = math.max(0, specs.indexWhere(holds));
    void walk(_Spec s) {
      s.items.forEach(add);
      s.under.forEach(walk);
    }

    for (var k = 0; k < specs.length; k++) {
      walk(specs[(from + k) % specs.length]);
    }
    return out;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RetroDesktopWindowColumn>('tiles', tiles))
      ..add(StringProperty('active', active, defaultValue: null))
      ..add(FlagProperty('whole', value: whole, ifTrue: 'whole'))
      ..add(
        IterableProperty<String>(
          'phoneOrder',
          phoneOrder,
          defaultValue: const [],
        ),
      );
  }
}

class _Spec {
  const _Spec(this.span, this.items, this.under);
  final int span;
  final List<int> items;
  final List<_Spec> under;
}

class _Tiles extends MultiChildRenderObjectWidget {
  const _Tiles({
    required this.specs,
    required this.alerts,
    required this.fixed,
    required this.active,
    required this.hasMarks,
    required this.hasStrip,
    required this.direction,
    required super.children,
  });
  final List<_Spec> specs;
  final Set<int> alerts, fixed;
  final int active;
  final bool hasMarks, hasStrip;
  final TextDirection direction;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRetroDesktopTiles(this);
  @override
  void updateRenderObject(BuildContext context, _RenderRetroDesktopTiles o) {
    o
      .._w = this
      ..markNeedsLayout();
  }
}

class _TileData extends ContainerBoxParentData<RenderBox> {}

/// How an alert hangs over its neighbour: beside it ([_overSide]) or above it ([_overAbove]).
class _Hang {
  const _Hang(this.top, this.start, this.end);

  /// Down from the column's top, or up over what stands above, if negative.
  final double top;

  /// Out over the neighbour at the column's start; in from the column's end.
  final double start, end;
}

const _overSide = _Hang(72, 104, 28);
const _overAbove = _Hang(-44, 20, 12);

/// The tiled desktop. A render object, not a Row of Columns, because the columns share a height, the last window of each
/// takes the slack, and an overlay's place depends on what the finished layout put beneath it.
class _RenderRetroDesktopTiles extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TileData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TileData> {
  _RenderRetroDesktopTiles(this._w);
  _Tiles _w;
  static const double _gut = 24, _startPad = 24, _topPad = 24, _rail = 96;
  static const double _most = 1680, _reach = 140;
  final Set<int> _withdrawn = {};
  final Map<int, _Hang> _hanging = {};
  double _laidWidth = 0;
  late List<RenderBox> _kids;

  /// Every list of tiles counted from the same grid, in whole columns.
  List<(double, double)> _spans(List<_Spec> specs, double x, double w) {
    final sum = specs.fold<int>(0, (a, s) => a + s.span);
    final columns = math.max(sum, specs.length == 1 && sum < 12 ? 12 : sum);
    final unit = (w + _gut) / (columns == 0 ? 1 : columns);
    final out = <(double, double)>[];
    var at = 0.0;
    for (final s in specs) {
      final a = (x + at).roundToDouble();
      final b = (x + at + s.span * unit - _gut).roundToDouble();
      out.add((a, b - a));
      at += s.span * unit;
    }
    return out;
  }

  _Hang? _hangOf(_Spec s, int index, bool above, bool besides) {
    final i = s.items[index];
    if (index != 0 || !_w.alerts.contains(i) || _withdrawn.contains(i)) {
      return null;
    }
    if (above) return _overAbove;
    return besides ? _overSide : null;
  }

  /// Lays a tile's windows out at their own heights and returns the tile's height.
  double _natural(_Spec s, double w, bool above, bool besides) {
    var y = 0.0;
    for (var n = 0; n < s.items.length; n++) {
      final i = s.items[n];
      final hang = _hangOf(s, n, above, besides);
      final cw = hang == null ? w : w + hang.start - hang.end;
      _kids[i].layout(BoxConstraints.tightFor(width: cw), parentUsesSize: true);
      if (hang != null) {
        _hanging[i] = hang;
        y += hang.top;
      } else {
        _hanging.remove(i);
      }
      y += _kids[i].size.height;
      if (n < s.items.length - 1 || s.under.isNotEmpty) y += _gut;
    }
    if (s.under.isNotEmpty) {
      y += _underHeight(s, w);
    }
    return y;
  }

  double _underHeight(_Spec s, double w) {
    final spans = _spans(s.under, 0, w);
    var h = 0.0;
    for (var k = 0; k < s.under.length; k++) {
      h = math.max(h, _natural(s.under[k], spans[k].$2, true, k > 0));
    }
    return h;
  }

  void _place(_Spec s, double x, double y, double w, double height) {
    final natural = _measured(s, w);
    final slack = math.max(0.0, height - natural);
    final grower = s.under.isNotEmpty ? -1 : _growerOf(s);
    var at = y;
    for (var n = 0; n < s.items.length; n++) {
      final i = s.items[n];
      final k = _kids[i];
      final hang = _hanging[i];
      if (hang != null) at += hang.top;
      if (i == grower && slack > 0) {
        k.layout(
          BoxConstraints.tightFor(
            width: k.size.width,
            height: k.size.height + slack,
          ),
          parentUsesSize: true,
        );
      }
      final dx = hang == null ? x : x - hang.start;
      _set(k, dx, at);
      at += k.size.height;
      if (n < s.items.length - 1 || s.under.isNotEmpty) at += _gut;
    }
    if (s.under.isNotEmpty) {
      final rowH = y + height - at;
      final spans = _spans(s.under, x, w);
      for (var k = 0; k < s.under.length; k++) {
        _place(s.under[k], spans[k].$1, at, spans[k].$2, rowH);
      }
    }
  }

  /// The tile's height from the sizes its children already hold.
  double _measured(_Spec s, double w) {
    var y = 0.0;
    for (var n = 0; n < s.items.length; n++) {
      final i = s.items[n];
      final hang = _hanging[i];
      if (hang != null) y += hang.top;
      y += _kids[i].size.height;
      if (n < s.items.length - 1 || s.under.isNotEmpty) y += _gut;
    }
    if (s.under.isNotEmpty) {
      final spans = _spans(s.under, 0, w);
      var h = 0.0;
      for (var k = 0; k < s.under.length; k++) {
        h = math.max(h, _measured(s.under[k], spans[k].$2));
      }
      y += h;
    }
    return y;
  }

  int _growerOf(_Spec s) {
    for (final i in s.items.reversed) {
      if (!_w.fixed.contains(i)) return i;
    }
    return -1;
  }

  void _set(RenderBox k, double x, double y) {
    final rtl = _w.direction == TextDirection.rtl;
    (k.parentData as _TileData).offset = Offset(
      rtl ? _laidWidth - x - k.size.width : x,
      y,
    );
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TileData) child.parentData = _TileData();
  }

  double _width() => constraints.hasBoundedWidth ? constraints.maxWidth : 1440;

  @override
  void performLayout() {
    _kids = getChildrenAsList();
    final count = _kids.length;
    final marks = _w.hasMarks ? _kids[count - (_w.hasStrip ? 2 : 1)] : null;
    final strip = _w.hasStrip ? _kids[count - 1] : null;
    final total = _width();
    _laidWidth = total;
    final railRoom = marks == null ? _gut : _rail + _gut;
    final grid = math.min(total - _startPad - railRoom, _most);
    _withdrawn.clear();
    var height = 0.0;
    // Under the windows: the page's foot, or the strip standing 16 lp below them and 8 above the foot.
    strip?.layout(BoxConstraints(maxWidth: total), parentUsesSize: true);
    final foot = strip == null ? 8.0 : _gut - 8 + strip.size.height + 8;
    // An overlay that would hide words withdraws to its own column; the second pass lays out what that moved.
    for (var pass = 0; pass < 6; pass++) {
      final spans = _spans(_w.specs, _startPad, grid);
      height = 0;
      for (var k = 0; k < _w.specs.length; k++) {
        height = math.max(
          height,
          _natural(_w.specs[k], spans[k].$2, false, k > 0),
        );
      }
      height = height.ceilToDouble();
      // A little short of the screen and the windows reach the strip. Far short and they stand on the desk as they are.
      final screen = constraints.minHeight - _topPad - foot;
      if (screen > height && screen - height <= _reach) height = screen;
      for (var k = 0; k < _w.specs.length; k++) {
        _place(_w.specs[k], spans[k].$1, _topPad, spans[k].$2, height);
      }
      // Reads the sizes of what lies far under it, which a layout callback may.
      var blocked = const <int>{};
      invokeLayoutCallback<BoxConstraints>((_) => blocked = _blocked());
      if (blocked.isEmpty) break;
      _withdrawn.addAll(blocked);
    }
    // The rail and the strip keep to the screen's foot however short the windows.
    var floor = math.max(height, constraints.minHeight - _topPad - foot);
    if (marks != null) {
      // Marks taller than the windows beside them make the page taller: they are never cut.
      marks.layout(
        const BoxConstraints.tightFor(width: _rail),
        parentUsesSize: true,
      );
      floor = math.max(floor, marks.size.height);
    }
    var bottom = _topPad + floor + 8;
    if (marks != null) {
      marks.layout(
        BoxConstraints.tightFor(width: _rail, height: floor),
        parentUsesSize: true,
      );
      _set(marks, total - _rail, _topPad);
    }
    if (strip != null) {
      _set(strip, 0, _topPad + floor + _gut - 8);
      bottom = _topPad + floor + _gut - 8 + strip.size.height + 8;
    }
    size = constraints.constrain(Size(total, bottom));
  }

  Set<int> _blocked() {
    final out = <int>{};
    for (final MapEntry(key: i, value: _) in _hanging.entries) {
      final a = _kids[i];
      final rect = (a.parentData as _TileData).offset & a.size;
      for (var n = 0; n < _kids.length; n++) {
        if (n == i) continue;
        final other = _kids[n];
        if (!other.hasSize) continue;
        final at = (other.parentData as _TileData).offset & other.size;
        if (!at.overlaps(rect)) continue;
        if (_holdsContent(other, rect)) {
          out.add(i);
          break;
        }
      }
    }
    return out;
  }

  bool _holdsContent(RenderObject node, Rect rect) {
    if (node is _RenderChrome) return false;
    if (node is RenderBox && node.hasSize) {
      Rect local(Rect r) =>
          MatrixUtils.transformRect(node.getTransformTo(this), r);
      if (node is RenderParagraph) {
        final length = node.text.toPlainText().length;
        for (final box in node.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: length),
        )) {
          if (local(box.toRect()).overlaps(rect)) return true;
        }
        return false;
      }
      if (node is RenderEditable ||
          node is RenderImage ||
          (node is RenderRetroDesktopPixelPaint && node.child == null) ||
          (node is RenderCustomPaint &&
              node.child == null &&
              (node.painter != null || node.foregroundPainter != null))) {
        return local(Offset.zero & node.size).overlaps(rect);
      }
    }
    var found = false;
    node.visitChildren((c) {
      if (!found) found = _holdsContent(c, rect);
    });
    return found;
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;
  @override
  double computeMaxIntrinsicWidth(double height) => 0;
  @override
  double computeMinIntrinsicHeight(double width) => 0;
  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.smallest;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final kids = getChildrenAsList();
    final order = _paintOrder(kids);
    for (final k in order.reversed) {
      final d = k.parentData as _TileData;
      final hit = result.addWithPaintOffset(
        offset: d.offset,
        position: position,
        hitTest: (r, p) => k.hitTest(r, position: p),
      );
      if (hit) return true;
    }
    return false;
  }

  List<RenderBox> _paintOrder(List<RenderBox> kids) {
    final first = <RenderBox>[], last = <RenderBox>[];
    for (var i = 0; i < kids.length; i++) {
      if (i == _w.active || _w.alerts.contains(i)) continue;
      first.add(kids[i]);
    }
    if (_w.active >= 0 && _w.active < kids.length) last.add(kids[_w.active]);
    for (final i in _w.alerts) {
      if (i < kids.length) last.add(kids[i]);
    }
    return [...first, ...last];
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final k in _paintOrder(getChildrenAsList())) {
      context.paintChild(k, offset + (k.parentData as _TileData).offset);
    }
  }
}
