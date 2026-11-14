// The heroes: the cover, which is the look's whole home, and the splash, which any page's first panel can be. Each has a compact
// form through `ComicPanel(compact: true)`: a band about 130 tall on a phone. On a desktop the cover stays whole, and a compact splash
// stands about 380 tall with the work beside it.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../balloons.dart';
import '../frames.dart';
import '../layout.dart';
import '../people.dart';
import '../print.dart';
import '../rows.dart';
import '../theme.dart';
import '../press.dart';

/// One corner box of a cover: a big line in the lettering, a small one under it.
class ComicCoverBox {
  /// Creates a [ComicCoverBox].
  const ComicCoverBox(this.big, this.small, {this.onPressed});

  /// [big]: uses the emphasized, larger presentation. [small]: uses the smaller visual treatment.
  final String big, small;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;
}

class _Corner extends StatelessWidget {
  const _Corner(this.box, {this.you = false, this.end = false});
  final ComicCoverBox box;
  final bool you, end;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final line = BorderSide(color: c.outline, width: t.rim(3));
    final letters = you ? c.onPrimary : c.onPaper;
    final content = DecoratedBox(
      decoration: ShapeDecoration(
        color: you ? c.primary : c.paper,
        shape: t.shapes.small.copyWith(side: line),
      ),
      child: Padding(
        // A flutter border doesn't take room as a CSS one does, so the padding holds its 3 on the side the line is.
        padding: EdgeInsetsDirectional.fromSTEB(
          (t.desk ? 16 : 10) + (end ? 3 : 0),
          t.desk ? 9 : 6,
          (t.desk ? 16 : 10) + (end ? 0 : 3),
          t.desk ? 13 : 10,
        ),
        child: Column(
          crossAxisAlignment: you
              ? CrossAxisAlignment.center
              : end
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              box.big.toUpperCase(),
              maxLines: 1,
              style: t.type.letter(
                t.desk ? 34 : 24,
                lineHeight: .9,
                color: letters,
                tracking: .04,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              box.small.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.type.text(
                t.desk ? 12 : 11,
                1.2,
                weight: FontWeight.w800,
                color: letters,
                tracking: .06,
              ),
            ),
          ],
        ),
      ),
    );
    if (box.onPressed == null) return content;
    return ComicPressable(onPressed: box.onPressed, child: content);
  }
}

/// The cover: the look's whole home, once. Action lines and two fading halftones on a process-colour ground; an issue box, a price
/// box and a date box in its corners; a big outlined [masthead]; a [subtitle] with its [emphasis] lit; one burst; someone in a
/// balloon whose tail finds them in the lineup; a cast shoulder to shoulder at its foot. The boxes say any neutral thing: "No. 27,
/// plans this year". On a phone in a compact panel it's a band of 130 lp: masthead, the issue box, a small burst.
///
/// ```dart
/// ComicCover(masthead: 'Huzzah!', subtitle: 'The first', emphasis: 'issue!', issue: const ComicCoverBox('No. 27', 'plans so far'), cast: const [ComicCast('Sam'), ComicCast('You', isCurrentUser: true)])
/// ```
class ComicCover extends StatelessWidget {
  /// Creates a [ComicCover].
  const ComicCover({
    super.key,
    required this.masthead,
    this.subtitle,
    this.emphasis,
    this.issue,
    this.price,
    this.date,
    this.burst,
    this.say,
    this.sayer,
    this.cast = const [],
    this.onPressed,
    this.compact = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// The publication or application name at the top of the cover.
  final String masthead;

  /// [subtitle]: the supporting line under the title. [emphasis]: words given the composition's strongest lettering. [say]: the words attributed to this person.
  final String? subtitle, emphasis, say;

  /// The boxes in its corners. Each is optional.
  final ComicCoverBox? issue, price, date;

  /// The screen's one `ComicBurst`. Its size is set here.
  final ComicCoverBurst? burst;

  /// Which of [cast] the balloon points at.
  final int? sayer;

  /// The people shown in the lineup, in order.
  final List<ComicCast> cast;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// Its short form on a phone, for a page that isn't the look's home.
  final bool compact;

  Widget _top(ComicThemeData t, {bool fillDate = false}) {
    final spacer = const SizedBox.shrink();
    final kids = <Widget>[
      if (issue != null) _Corner(issue!),
      if (price != null) _Corner(price!, you: true),
      if (date != null && fillDate)
        _Corner(date!, end: true)
      else ...[
        spacer,
        if (date != null) _Corner(date!, end: true),
      ],
    ];
    final fill = fillDate && date != null
        ? kids.length - 1
        : kids.indexOf(spacer);
    return ComicFitRow(
      fill: fill < 0 ? 0 : fill,
      fillShare: fillDate ? .4 : 0,
      gap: 0,
      align: ComicFitAlign.bottom,
      children: kids,
    );
  }

  Widget _subtitle(ComicThemeData t, double size) => ComicLettering(
    '${subtitle ?? ''}${emphasis == null ? '' : ' $emphasis'}',
    size: size,
    fill: t.colors.paper,
    style: ComicLetteringStyle.subtitle,
    spans: [
      if (subtitle != null) ('$subtitle ', t.colors.paper),
      if (emphasis != null) (emphasis!, t.colors.caption),
    ],
  );

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final short =
        !t.desk &&
        (compact ||
            (context
                    .dependOnInheritedWidgetOfExactType<ComicCompactScope>()
                    ?.on ??
                false));
    return ComicPanel(
      focusNode: focusNode,
      autofocus: autofocus,
      bleed: true,
      onPressed: onPressed,
      label: masthead,
      child: short ? _short(t) : _whole(context, t, c),
    );
  }

  Widget _short(ComicThemeData t) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 124),
    child: ComicCoverPrint(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ComicColumn(
              children: [
                if (issue != null)
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    widthFactor: 1,
                    heightFactor: 1,
                    child: _Corner(issue!),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 110, 0),
                  child: ComicLettering(
                    masthead,
                    size: 56,
                    lineHeight: .92,
                    tracking: .03,
                    fit: true,
                    fill: t.colors.caption,
                    style: const ComicLetteringStyle(
                      outline: 2.8,
                      layers: [(3.5, 3.5, 0, 'drama'), (5.5, 5.5, 0, 'line')],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (burst != null)
            PositionedDirectional(
              end: 6,
              top: 12,
              child: ComicBurst(
                number: burst!.number,
                over: burst!.over,
                under: burst!.under,
                width: 104,
                height: 96,
                wordSize: 11,
                numberSize: 26,
                seed: 11,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _whole(BuildContext context, ComicThemeData t, ComicColors c) {
    final desk = t.desk;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: desk ? 594 : 0),
      child: ComicCoverPrint(
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.hasBoundedWidth ? box.maxWidth : t.width;
            final cell = cast.isEmpty ? w : w / cast.length;
            double tailFor(double left, double width) {
              if (sayer == null || cast.isEmpty) return .6;
              return ((cell * (sayer! + .5) - left) / width).clamp(.08, .9);
            }

            final type = ComicColumn(
              children: [
                _top(t, fillDate: !desk),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    desk ? 24 : 10,
                    desk ? 6 : 8,
                    desk ? (burst == null ? 24 : 250) : 10,
                    0,
                  ),
                  child: ComicLettering(
                    masthead,
                    size: desk ? 176 : 104,
                    lineHeight: .92,
                    tracking: .03,
                    fit: true,
                    fill: c.caption,
                    style: ComicLetteringStyle.masthead,
                  ),
                ),
                if (subtitle != null || emphasis != null)
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      desk ? 30 : 14,
                      desk ? 6 : 4,
                      desk ? (burst == null ? 24 : 250) : 14,
                      0,
                    ),
                    child: _subtitle(t, desk ? 56 : 34),
                  ),
                if (!desk && (burst != null || say != null))
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 10, 8),
                    child: Row(
                      children: [
                        if (burst != null) ...[
                          ComicBurst(
                            number: burst!.number,
                            over: burst!.over,
                            under: burst!.under,
                            width: 186,
                            height: 160,
                            wordSize: 16,
                            numberSize: 36,
                            seed: 11,
                          ),
                          const SizedBox(width: 2),
                        ],
                        if (say != null)
                          Expanded(
                            child: ComicBalloon(
                              say,
                              small: true,
                              fill: true,
                              room: false,
                              tailAt: tailFor(188, math.max(1, w - 200)),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (desk) SizedBox(height: say == null ? 24 : 112),
                ComicGrow(child: const SizedBox.shrink()),
                ComicLineup(cast),
              ],
            );
            if (!desk) return type;
            const sayLeft = .575, sayWidth = 250.0;
            // The balloon keeps inside the cover: on a narrow cover it moves toward the start before the contour can
            // slice its end, and narrows only when the cover is narrower than the balloon.
            final sayW = math.min(sayWidth, w - 32);
            final sayStart = math.max(
              16.0,
              math.min(w * sayLeft, w - sayW - 16),
            );
            return Stack(
              fit: StackFit.passthrough,
              children: [
                type,
                if (burst != null)
                  PositionedDirectional(
                    end: 14,
                    top: 74,
                    child: ComicBurst(
                      number: burst!.number,
                      over: burst!.over,
                      under: burst!.under,
                      width: 232,
                      height: 200,
                      wordSize: 22,
                      numberSize: 50,
                      seed: 11,
                    ),
                  ),
                if (say != null)
                  PositionedDirectional(
                    start: sayStart,
                    top: 344,
                    width: sayW,
                    child: ComicBalloon(
                      say,
                      fill: true,
                      room: false,
                      tailAt: tailFor(sayStart, sayW),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The words of a cover's burst.
class ComicCoverBurst {
  /// Creates a [ComicCoverBurst].
  const ComicCoverBurst(this.number, {this.over, this.under});

  /// The number printed in the figure.
  final String number;

  /// [over]: the words above the main figure. [under]: the words below the main figure.
  final String? over, under;
}

/// Where a splash's title stands: low over a full scene, or high beside a thing drawn on action lines.
enum ComicSplashLayout {
  /// Places the title below the leading figure.
  titleLow,

  /// Places the title above the leading figure.
  titleHigh,
}

/// A page's opening panel: a scene or a picture running to the contour, a narration caption, a big outlined title, one burst, and a
/// bar of facts along its foot. [art] fills it: a `ComicDrawing`, a `ComicMedia`, or a `ComicArtBand`. `titleHigh` sets the title up on
/// action lines with [figure] at its side and a [balloon] from the author. In a compact panel on a phone it becomes a band of about
/// 130 lp with the title and a small burst, and drops the facts and the rest: the page's job then shows on the first screen. On a
/// desktop [compact] keeps all of it at about 380 lp, not 540, so the panels beside it don't end on blank paper.
///
/// ```dart
/// ComicSplash(title: 'The long weekend', caption: 'Meanwhile, by the lake', art: ComicArtBand(ground: 2, leading: Icon(ComicGlyphs.house)), burst: const ComicCoverBurst('23', over: 'In', under: 'days!'), facts: const [('162 km', 'by road'), ('Sleeps 6', 'three rooms')])
/// ```
class ComicSplash extends StatelessWidget {
  static const double _compactDesk = 380;

  /// Creates a [ComicSplash].
  const ComicSplash({
    super.key,
    required this.title,
    this.art,
    this.caption,
    this.captionIcon,
    this.note,
    this.burst,
    this.facts = const [],
    this.factsCentred = false,
    this.layout = ComicSplashLayout.titleLow,
    this.figure,
    this.sfx,
    this.balloon,
    this.compact = false,
    this.heroSize,
  });

  /// The primary heading.
  final String title;

  /// [art]: a caller-supplied illustration or image widget. [figure]: the primary printed figure. [balloon]: draws the words inside a speech balloon.
  final Widget? art, figure, balloon;

  /// [caption]: the optional narration caption. [note]: secondary explanatory text. [sfx]: the optional printed sound effect.
  final String? caption, note, sfx;

  /// An optional glyph beside the narration caption.
  final IconData? captionIcon;

  /// The optional burst displayed beside the main content.
  final ComicCoverBurst? burst;

  /// Supporting facts displayed beside the main content.
  final List<(String, String)> facts;

  /// Centers the supporting facts in their available width.
  final bool factsCentred;

  /// The arrangement used by the composition.
  final ComicSplashLayout layout;

  /// Its short form, for a page where the job comes first: a band on a phone, a lower panel on a desktop.
  final bool compact;

  /// A title's size on a desktop, if the words want less than the hero's.
  final double? heroSize;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final short =
        !t.desk &&
        (compact ||
            (context
                    .dependOnInheritedWidgetOfExactType<ComicCompactScope>()
                    ?.on ??
                false));
    return ComicPanel(
      bleed: true,
      label: title,
      child: short
          ? _short(context, t)
          : ComicColumn(
              children: [
                ComicGrow(
                  child: layout == ComicSplashLayout.titleLow
                      ? _low(context, t)
                      : _high(context, t),
                ),
                if (facts.isNotEmpty) ComicFacts(facts, centred: factsCentred),
              ],
            ),
    );
  }

  Widget _title(ComicThemeData t, double size) => ComicLettering(
    title,
    size: size,
    fill: t.colors.paper,
    style: ComicLetteringStyle.title,
  );

  Widget _short(BuildContext context, ComicThemeData t) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 124),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child:
              art ??
              ComicActionLines(
                color: t.colors.ray,
                ground: t.dark ? t.colors.card : t.colors.caption,
              ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: burst == null ? 0 : 100,
            bottom: 12,
          ),
          child: ComicColumn(
            children: [
              if (caption != null)
                ComicCaption(caption!, icon: captionIcon, tight: true),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: ComicLettering(
                  title,
                  size: 36,
                  fill: t.colors.paper,
                  style: const ComicLetteringStyle(
                    outline: 2.2,
                    layers: [(3, 3.5, 0, 'line')],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (burst != null)
          PositionedDirectional(
            end: 4,
            top: 12,
            child: ComicBurst(
              number: burst!.number,
              over: burst!.over,
              under: burst!.under,
              width: 96,
              height: 92,
              wordSize: 11,
              numberSize: 34,
              seed: 8,
            ),
          ),
      ],
    ),
  );

  Widget _low(BuildContext context, ComicThemeData t) {
    final desk = t.desk;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: desk ? (compact ? _compactDesk : 480) : 470,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: art ?? ColoredBox(color: t.colors.sky)),
          ComicColumn(
            children: [
              if (caption != null) ComicCaption(caption!, icon: captionIcon),
              if (note != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: desk ? 18 : 12,
                    top: desk ? 10 : 8,
                    end: burst != null ? (desk ? 300 : 12) : 12,
                  ),
                  child: ComicCaption(note!, free: true),
                ),
              ComicGrow(child: SizedBox(height: desk && compact ? 60 : 180)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  desk ? 30 : 14,
                  0,
                  desk ? 30 : 14,
                  desk ? 26 : 14,
                ),
                child: _title(t, t.type.hero.fontSize!),
              ),
            ],
          ),
          if (burst != null)
            PositionedDirectional(
              end: desk ? 36 : 4,
              top: desk ? 26 : 70,
              child: ComicBurst(
                number: burst!.number,
                over: burst!.over,
                under: burst!.under,
                large: true,
                seed: 8,
              ),
            ),
        ],
      ),
    );
  }

  Widget _high(BuildContext context, ComicThemeData t) {
    final desk = t.desk;
    final c = t.colors;
    final words = ComicColumn(
      children: [
        if (caption != null) ComicCaption(caption!, icon: captionIcon),
        Padding(
          padding: desk
              ? const EdgeInsets.fromLTRB(30, 24, 30, 30)
              : const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: ComicColumn(
            children: [
              _title(t, heroSize ?? (desk ? 88 : t.type.hero.fontSize!)),
              if (balloon != null)
                Padding(
                  padding: EdgeInsets.only(top: desk ? 22 : 14),
                  // The drawing keeps the page's right side: a long line from the author wraps, it doesn't cover it.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: desk ? 350 : double.infinity,
                    ),
                    child: balloon!,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final scene = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        ?figure,
        if (sfx != null)
          PositionedDirectional(
            start: desk ? null : 14,
            end: desk ? 300 : null,
            top: desk ? 34 : 28,
            child: ComicSfx(
              sfx!,
              size: desk ? 64 : 46,
              fill: c.paper,
              tilt: -12,
              big: true,
            ),
          ),
        if (burst != null)
          PositionedDirectional(
            end: desk ? 26 : 8,
            top: desk ? 26 : -6,
            child: ComicBurst(
              number: burst!.number,
              over: burst!.over,
              under: burst!.under,
              seed: 21,
            ),
          ),
      ],
    );
    return ComicActionLines(
      color: c.ray,
      ground: c.dark ? c.card : c.caption,
      child: desk
          ? ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: compact ? _compactDesk : 540,
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(child: scene),
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    heightFactor: 1,
                    child: SizedBox(width: 470, child: words),
                  ),
                ],
              ),
            )
          : ComicColumn(
              children: [
                words,
                SizedBox(height: 300, child: scene),
              ],
            ),
    );
  }
}
