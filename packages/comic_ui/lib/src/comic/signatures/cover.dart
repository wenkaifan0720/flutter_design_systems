// The heroes: the cover, which is the look's whole home, and the splash, which any page's first panel can be. Each has a compact
// form through `ComicPanel(compact: true)`: a band about 130 tall on a phone. On a desktop the cover stays whole, and a compact splash
// stands about 380 tall with the work beside it.
import 'package:flutter/foundation.dart';

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
import '../internal/lettering.dart' show comicLetteringScaler;
import '../knobs.dart' show ComicSpace;

/// The masthead keeps clear of the cover's figure, which stands at the end of the band: the figure's width and its gap.
const double _mastheadClear = 110;

/// One corner box of a cover: a big line in the lettering, a small one under it.
class ComicCoverBox {
  /// Creates a [ComicCoverBox].
  const ComicCoverBox(this.big, this.small, {this.onPressed});

  /// [big]: uses the emphasized, larger presentation. [small]: uses the smaller visual treatment.
  final String big, small;

  /// {@macro comic.onPressed}
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
              textScaler: comicLetteringScaler(
                context,
                t.type.letter(t.desk ? 34 : 24),
              ),
              style: t.type.letter(
                t.desk ? 34 : 24,
                lineHeight: .9,
                color: letters,
                tracking: .04,
              ),
            ),
            const SizedBox(height: ComicSpace.fine),
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

  /// {@macro comic.onPressed}
  final VoidCallback? onPressed;

  /// Its short form on a phone, for a page that isn't the look's home.
  final bool compact;

  Widget _top(ComicThemeData t, {bool fillDate = false, bool stack = false}) {
    // Under large text on a phone the three boxes can't share a line: the date takes one of its own, below, and the
    // last box above runs to the end. Left at their own widths, they framed a corner of bare art over the date's line,
    // which read as a panel gone missing (the fresh-eyes read, 11-15).
    if (stack && date != null && (issue != null || price != null)) {
      final above = [
        if (issue != null) _Corner(issue!),
        if (price != null) _Corner(price!, you: true),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ComicFitRow(
            fill: above.length - 1,
            gap: 0,
            align: ComicFitAlign.bottom,
            children: above,
          ),
          _Corner(date!, end: true),
        ],
      );
    }
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

  /// {@macro comic.focusNode}
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
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
            padding: const EdgeInsets.only(bottom: ComicSpace.close),
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
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    ComicSpace.close,
                    ComicSpace.close,
                    _mastheadClear,
                    0,
                  ),
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
                _top(
                  t,
                  fillDate: !desk,
                  stack:
                      !desk && MediaQuery.textScalerOf(context).scale(10) > 15,
                ),
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
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      ComicSpace.fine,
                      ComicSpace.fine,
                      ComicSpace.close,
                      ComicSpace.close,
                    ),
                    // Beside the burst while the balloon holds its widest word (large text widens it); under the
                    // burst, across the cover, once it would break a word.
                    child: Builder(
                      builder: (context) {
                        final word = say == null
                            ? 0.0
                            : comicWidestWord(
                                say!.toUpperCase(),
                                t.type.balloon.copyWith(fontSize: 13),
                                textScaler: MediaQuery.textScalerOf(context),
                              );
                        final beside = burst == null || word + 48 <= w - 200;
                        final pop = burst == null
                            ? null
                            : ComicBurst(
                                number: burst!.number,
                                over: burst!.over,
                                under: burst!.under,
                                width: 186,
                                height: 160,
                                wordSize: 16,
                                numberSize: 36,
                                seed: 11,
                              );
                        Widget balloon(double left, double width) =>
                            ComicBalloon(
                              say!,
                              small: true,
                              fill: true,
                              room: false,
                              tailAt: tailFor(left, width),
                            );
                        if (!beside) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              pop!,
                              const SizedBox(height: ComicSpace.fine),
                              if (say != null)
                                SizedBox(
                                  width: double.infinity,
                                  child: balloon(0, math.max(1, w - 12)),
                                ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            if (pop != null) ...[
                              pop,
                              const SizedBox(width: ComicSpace.fine),
                            ],
                            if (say != null)
                              Expanded(
                                child: balloon(188, math.max(1, w - 200)),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                if (desk) SizedBox(height: say == null ? 24 : 112),
                const ComicGrow(child: SizedBox.shrink()),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('masthead', masthead))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(StringProperty('emphasis', emphasis, defaultValue: null))
      ..add(StringProperty('say', say, defaultValue: null))
      ..add(
        DiagnosticsProperty<ComicCoverBox>('issue', issue, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<ComicCoverBox>('price', price, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<ComicCoverBox>('date', date, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<ComicCoverBurst>(
          'burst',
          burst,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('sayer', sayer, defaultValue: null))
      ..add(IterableProperty<ComicCast>('cast', cast, defaultValue: const []))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        FlagProperty(
          'compact',
          value: compact,
          ifTrue: 'compact',
          defaultValue: false,
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
              const SizedBox(height: ComicSpace.close),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: ComicSpace.near,
                  end: ComicSpace.close,
                ),
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
              // The note keeps clear of the burst at its end: under large text it wraps before the burst, never under it.
              if (note != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: desk ? 18 : 12,
                    top: desk ? 10 : 8,
                    end: burst != null ? (desk ? 300 : 150) : 12,
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
              ? const EdgeInsets.fromLTRB(
                  ComicSpace.tier,
                  ComicSpace.room,
                  ComicSpace.tier,
                  ComicSpace.tier,
                )
              : const EdgeInsets.fromLTRB(
                  ComicSpace.gap,
                  ComicSpace.gap,
                  ComicSpace.gap,
                  0,
                ),
          child: ComicColumn(
            children: [
              _title(t, heroSize ?? (desk ? 88 : t.type.hero.fontSize!)),
              if (balloon != null)
                Padding(
                  padding: EdgeInsets.only(
                    top: desk ? ComicSpace.room : ComicSpace.gap,
                  ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(DiagnosticsProperty<Widget>('art', art, defaultValue: null))
      ..add(DiagnosticsProperty<Widget>('figure', figure, defaultValue: null))
      ..add(DiagnosticsProperty<Widget>('balloon', balloon, defaultValue: null))
      ..add(StringProperty('caption', caption, defaultValue: null))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(StringProperty('sfx', sfx, defaultValue: null))
      ..add(
        DiagnosticsProperty<IconData>(
          'captionIcon',
          captionIcon,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<ComicCoverBurst>(
          'burst',
          burst,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<(String, String)>(
          'facts',
          facts,
          defaultValue: const [],
        ),
      )
      ..add(
        FlagProperty(
          'factsCentred',
          value: factsCentred,
          ifTrue: 'factsCentred',
          defaultValue: false,
        ),
      )
      ..add(
        EnumProperty<ComicSplashLayout>(
          'layout',
          layout,
          defaultValue: ComicSplashLayout.titleLow,
        ),
      )
      ..add(
        FlagProperty(
          'compact',
          value: compact,
          ifTrue: 'compact',
          defaultValue: false,
        ),
      )
      ..add(DoubleProperty('heroSize', heroSize, defaultValue: null));
  }
}
