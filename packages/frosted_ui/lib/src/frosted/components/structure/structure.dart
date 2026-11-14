/// Frosted's structure: the frosted glass tile every surface stands on
/// ([FrostedCard] in its faces, headed by a [FrostedCardHeader]), a section's
/// head on the canvas ([FrostedSectionHeader]), the list row and what it holds
/// ([FrostedListTile], [FrostedRowEnd], [FrostedTransactionRow], [FrostedNote]), the day
/// heads and month dividers that group rows ([FrostedRowGroup], [FrostedDayHead],
/// [FrostedMonthDivider]), a record's facts ([FrostedDescriptionList], [FrostedKeyValue]),
/// a record's head ([FrostedRecordHero] in its three faces) and its chart
/// ([FrostedRecordChart]), Spending's
/// [FrostedInsight], a sheet's [FrostedSuggestion], what is new ([FrostedNoteHero]),
/// the warm [FrostedNudge] and the cold [FrostedBanner], a category's
/// [FrostedBrowseCard], Home's [FrostedAccountCard] and a bill's [FrostedTicket],
/// each at the look's own values.
library;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, EnumProperty;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/chart_parts.dart';
import '../../internal/css_gradient.dart';
import '../../internal/css_shadow.dart';
import '../../internal/ellipse.dart';
import '../../internal/face.dart';
import '../../internal/flush_end.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';
import '../../localizations.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';

// --- metrics the stylesheet sets that chrome_metrics.dart has no name for --

// metric: .timeline .row + .row::before { left: 19.5px; top: -6px; height:
// 12px; width: 1px; background: rgba(21,21,45,.18) } the spine between two
// date blocks, down the blocks' centre line.
const double _timelineStart = 19.5;
const double _timelineTop = -6;
const double _timelineHeight = 12;
const double _timelineInk = 0.18;

// metric: .visits i { width: 10px; height: 10px } one visit's dot.
const double _visitsDot = 10;

// metric: .link { gap: 2px } between a link's words and its glyph.
const double _linkGap = 2;

// metric: the stylesheet's fills that are alphas of white or of the ink, not
// roles: .rows--mark .row.this (white .7), .goal-card--ghost (white .45 over
// ink .08), .suggest (white .7), .browse-c (white .5), .ticket (white .58 in
// a white .85 ring; its chip white .7), .banner (white .86), .nudge (warn .13
// in warn .26; --ok in moneyIn .2) and .rec-hero's tint when no hue is given
// (ink .04).
const double _markFill = 0.7;
const double _ghostFill = 0.45;
const double _ghostRing = 0.08;
const double _suggestFill = 0.7;
const double _browseFill = 0.5;
const double _ticketFill = 0.58;
const double _ticketRing = 0.85;
const double _ticketChipFill = 0.7;
const double _bannerFill = 0.86;
const double _nudgeFill = 0.13;
const double _nudgeRing = 0.26;
const double _nudgeOkRing = 0.2;
const double _recordTint = 0.04;

// --- the faces -------------------------------------------------------------

/// How a card is drawn (kept back from the barrel: [FrostedCard] names its
/// faces by constructor, and the parts that hold a face of their own draw it
/// with [FrostedFacedCard]): [plain] the glass with its light along the
/// top (`.tile`); [rim] the spectrum rim 1px along the top instead
/// (`.glass-tile`); [record] the rim over a wash of the hue from the top
/// start corner (`.rec-hero`, `.cat-hero`, `.note-new`); [hero] the rim over
/// a wash from the top centre, its content centred (`.txn-hero`,
/// `.rv-hero`); [account] the glass washed from the top end corner
/// (`.acct`); [insight] the hue's wash down the glass in its own edge
/// (`.insight`); [ghost] the faint white of something not yet real
/// (`.goal-card--ghost`); [list] the glass with the rows' room top and
/// bottom (`.list-tile`).
enum FrostedCardFace {
  /// The glass with its light along the top.
  plain,

  /// The spectrum rim, 1 along the top, in place of the light.
  rim,

  /// The rim over the hue's wash from the top start corner.
  record,

  /// The rim over the hue's wash from the top centre, the content centred.
  hero,

  /// The glass washed with the hue from the top end corner.
  account,

  /// The hue's wash down the glass, in the hue's own edge.
  insight,

  /// The faint white of something not yet real.
  ghost,

  /// The glass with room for rows at its top and foot.
  list,
}

/// The frosted glass tile every Frosted surface stands on: the translucent
/// glass over the canvas (no blur, as decision 14 keeps the frost for the
/// chrome), its corners at the page's tile radius, its [padding] the page's
/// inset, its light along the top, the hairline edge round it and the lift
/// under it. Its faces are its constructors: the plain tile, [FrostedCard.rim]
/// (the spectrum rim along the top), [FrostedCard.record] and
/// [FrostedCard.hero] (the rim over a wash of [hue]) and [FrostedCard.ghost]
/// (the faint outline of something not yet real). With [onPressed] the whole tile is one link,
/// [label] its spoken name (without a tap, [label] names the group).
///
/// ```dart
/// FrostedCard(child: Text('On pace'))
/// ```
///
/// ```dart
/// FrostedCard.record(hue: t.hues.cyan, child: body)
/// ```
class FrostedCard extends StatelessWidget {
  /// The glass with its light along the top (`.tile`).
  const FrostedCard({
    required this.child,
    this.padding,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : hue = null,
       _face = FrostedCardFace.plain;

  /// The spectrum rim, 1 along the top, in place of the light
  /// (`.glass-tile`).
  const FrostedCard.rim({
    required this.child,
    this.padding,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : hue = null,
       _face = FrostedCardFace.rim;

  /// The rim over a wash of [hue] from the top start corner (`.rec-hero`,
  /// `.cat-hero`, `.note-new`): a record's or a category's head tile.
  const FrostedCard.record({
    required this.child,
    this.hue,
    this.padding,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _face = FrostedCardFace.record;

  /// The rim over a wash of [hue] from the top centre, the content centred
  /// (`.txn-hero`, `.rv-hero`).
  const FrostedCard.hero({
    required this.child,
    this.hue,
    this.padding,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _face = FrostedCardFace.hero;

  /// The faint white of something not yet real (`.goal-card--ghost`).
  const FrostedCard.ghost({
    required this.child,
    this.padding,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : hue = null,
       _face = FrostedCardFace.ghost;

  final FrostedCardFace _face;

  /// What stands on the tile.
  final Widget child;

  /// The hue the record and hero faces are washed in.
  final FrostedHue? hue;

  /// The room inside the face; null for the face's own.
  final EdgeInsetsGeometry? padding;

  /// Opens what the tile stands for; null for a tile that is not a link.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The spoken name of the tile.
  final String? label;

  /// This card's own style, over `FrostedThemeData.components.card`: its
  /// fill, the words' colour and style, the edge's colour or a whole side
  /// (drawn inside the face in place of the hairline ring outside it), an
  /// overlay, its shape ([FrostedCorners.medium] by default), its
  /// padding (under [padding]) and its least size, each per state (hovered,
  /// focused and pressed when it is a link).
  ///
  /// ```dart
  /// FrostedCard(
  ///   style: const FrostedStyle(
  ///     padding: WidgetStatePropertyAll(EdgeInsets.all(24)),
  ///   ),
  ///   child: Text('On pace'),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) => FrostedFacedCard(
    focusNode: focusNode,
    autofocus: autofocus,
    face: _face,
    hue: hue,
    padding: padding,
    onPressed: onPressed,
    label: label,
    style: style,
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<FrostedCardFace>('face', _face));
  }
}

/// A card in any of [FrostedCardFace]'s faces: [FrostedCard]'s drawing,
/// kept back from the barrel for the parts that hold a face of their own (a
/// list section's rows, an account, a goal, an insight). Plumbing of the
/// components; pages use [FrostedCard].
class FrostedFacedCard extends StatelessWidget {
  /// A tile of glass holding [child], drawn as [face].
  const FrostedFacedCard({
    required this.child,
    required this.face,
    this.hue,
    this.padding,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What stands on the tile.
  final Widget child;

  /// Which face the tile wears.
  final FrostedCardFace face;

  /// The hue the record, hero, account and insight faces are washed in.
  final FrostedHue? hue;

  /// The room inside the face; null for the face's own.
  final EdgeInsetsGeometry? padding;

  /// Opens what the tile stands for; null for a tile that is not a link.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The spoken name of the tile.
  final String? label;

  /// The card's own style, over `FrostedThemeData.components.card`.
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final hue = this.hue;
    final pad = FrostedBreakpoints.pad(context);
    final layers = FrostedStyleLayers(style, t.components.card);
    // FrostedCorners.medium is a card's corner on a phone; the
    // desktop rounds it 2 further, as the look does (18 and 20 in opal).
    final knob = FrostedCorners.medium;
    OutlinedBorder? cutOf(FrostedStyleLayers s) =>
        s.shape ??
        (face == FrostedCardFace.ghost || knob is RoundedRectangleBorder
            ? null
            : knob);
    double radiusOf(OutlinedBorder? cut) => cut != null
        ? FrostedStyleLayers.radiusOf(cut, 0, FrostedCorners.r18)
        : face == FrostedCardFace.ghost
        ? FrostedChromeMetrics.ghostRadius
        : FrostedCorners.r18 +
              (wide ? FrostedCorners.r20 - FrostedCorners.r18 : 0);
    final lookInset = switch (face) {
      FrostedCardFace.ghost => const EdgeInsets.all(
        FrostedChromeMetrics.ghostInset,
      ),
      // .list-tile { padding-top: 8px; padding-bottom: 8px }
      FrostedCardFace.list => EdgeInsets.symmetric(
        horizontal: pad,
        vertical: FrostedChromeMetrics.listInset,
      ),
      // .txn-hero { padding-top: 28px; padding-bottom: 24px }
      FrostedCardFace.hero => EdgeInsets.fromLTRB(
        pad,
        FrostedChromeMetrics.transactionTop,
        pad,
        FrostedChromeMetrics.transactionBottom,
      ),
      // .acct { padding: 14px } and 18px 20px on the desktop.
      FrostedCardFace.account =>
        wide
            ? FrostedChromeMetrics.accountInsetWide
            : const EdgeInsets.all(FrostedChromeMetrics.accountInset),
      _ => wide ? FrostedInsets.tileWide : FrostedInsets.tile,
    };
    Widget draw(Set<WidgetState> states) {
      final s = layers.at(states);
      final cut = cutOf(s);
      final radius = BorderRadius.circular(radiusOf(cut));
      final side = s.side;
      // --edge: 0 0 0 1px, a ring just outside the glass.
      final edge = frostedShadow(
        color: s.edge ?? t.glass.edge,
        spread: FrostedStrokes.regular,
      );
      final tint =
          hue?.tintSolid ??
          t.colorScheme.textPrimary.withValues(alpha: _recordTint);
      final (
        Color fill,
        List<Gradient> gradients,
        Color? sheen,
        Color? ring,
        List<BoxShadow> shadows,
        bool rim,
      ) = switch (face) {
        // .tile { background: var(--glass); box-shadow: var(--rim), var(--edge),
        // var(--lift) }
        FrostedCardFace.plain || FrostedCardFace.list => (
          t.glass.fill,
          const <Gradient>[],
          t.glass.rim,
          null,
          <BoxShadow>[edge, ...t.shadows.tile],
          false,
        ),
        // .glass-tile { background: <spectrum> top / 100% 1px, var(--glass);
        // box-shadow: var(--edge), var(--lift) }
        FrostedCardFace.rim => (
          t.glass.fill,
          const <Gradient>[],
          null,
          null,
          <BoxShadow>[edge, ...t.shadows.tile],
          true,
        ),
        // .rec-hero { background: <rim>, radial-gradient(90% 60% at 0% 0%,
        // var(--t2) 0%, transparent 70%), var(--glass) }
        FrostedCardFace.record => (
          t.glass.fill,
          <Gradient>[_radial(tint, rx: 0.9, ry: 0.6, cx: 0, cy: 0, to: 0.7)],
          null,
          null,
          <BoxShadow>[edge, ...t.shadows.tile],
          true,
        ),
        // .txn-hero { background: <rim>, radial-gradient(70% 55% at 50% 0%,
        // var(--t2) 0%, transparent 100%), var(--glass) }
        FrostedCardFace.hero => (
          t.glass.fill,
          <Gradient>[_radial(tint, rx: 0.7, ry: 0.55, cx: 0.5, cy: 0, to: 1)],
          null,
          null,
          <BoxShadow>[edge, ...t.shadows.tile],
          true,
        ),
        // .acct { background: radial-gradient(100% 80% at 100% 0%, var(--t) 0%,
        // transparent 70%), var(--glass) }
        FrostedCardFace.account => (
          t.glass.fill,
          <Gradient>[
            if (hue != null)
              _radial(hue.tint, rx: 1, ry: 0.8, cx: 1, cy: 0, to: 0.7),
          ],
          t.glass.rim,
          null,
          <BoxShadow>[edge, ...t.shadows.tile],
          false,
        ),
        // .insight { background: linear-gradient(160deg, var(--t2) 0%, var(--t)
        // 45%, transparent 100%), var(--glass); box-shadow: inset 0 0 0 1px
        // var(--e), var(--lift) }
        FrostedCardFace.insight => (
          t.glass.fill,
          <Gradient>[_insightWash(hue ?? t.hues.iris)],
          null,
          (hue ?? t.hues.iris).edge,
          t.shadows.tile,
          false,
        ),
        // .goal-card--ghost { background: rgba(255,255,255,.45); box-shadow:
        // inset 0 0 0 1px rgba(21,21,45,.08) }
        FrostedCardFace.ghost => (
          t.glass.plane.withValues(alpha: _ghostFill),
          const <Gradient>[],
          null,
          t.colorScheme.textPrimary.withValues(alpha: _ghostRing),
          const <BoxShadow>[],
          false,
        ),
      };
      // The card's content shares its keylines (design6 P): the shared check
      // reads this region against the card's face.
      Widget inside = Padding(
        padding: padding ?? s.padding ?? lookInset,
        child: face == FrostedCardFace.hero
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DefaultTextStyle.merge(
                    textAlign: TextAlign.center,
                    child: child,
                  ),
                ],
              )
            : child,
      );
      inside = DesignKeylineRegion(label: this.label ?? 'card', child: inside);
      if (rim) {
        // The rim lies over the content, which keeps the tile's width: a
        // loose Stack would let a centred hero shrink to its words and stand
        // them at the start (`.txn-hero`'s content is centred on the tile).
        inside = Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: FrostedChromeMetrics.heroRim,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: t.glass.spectrumRim),
              ),
            ),
            inside,
          ],
        );
      }
      if (s.foreground != null || s.textStyle != null) {
        inside = DefaultTextStyle.merge(
          style: s.words(const TextStyle()),
          child: inside,
        );
      }
      return s.least(
        // A card is the thinnest glass: the backdrop shows through it. The
        // ghost is the one card of paint, an outline waiting to be filled.
        FrostedFace(
          material: face == FrostedCardFace.ghost
              ? FrostedMaterial.paint
              : FrostedMaterial.sheer,
          radius: radius,
          shape: cut,
          color: s.fill ?? (face == FrostedCardFace.ghost ? fill : null),
          gradients: gradients,
          wash: s.overlay,
          edge: side?.color,
          edges: side == null
              ? const EdgeInsets.all(FrostedChromeMetrics.outline)
              : EdgeInsets.all(side.width),
          sheen: sheen,
          ring: ring,
          shadows: side == null
              ? shadows
              : [
                  for (final shadow in shadows)
                    if (!identical(shadow, edge)) shadow,
                ],
          clipChild: rim,
          child: inside,
        ),
      );
    }

    final onPressed = this.onPressed;
    final label = this.label;
    if (onPressed != null) {
      final cut = cutOf(layers);
      // One link saying the tile's words, or [label] alone when given.
      return MergeSemantics(
        child: FrostedPressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: onPressed,
          role: FrostedPressRole.link,
          label: label,
          radius: radiusOf(cut),
          shape: cut,
          builder: (context, states, _) => draw(states),
        ),
      );
    }
    Widget tile = draw(const <WidgetState>{});
    if (label != null) {
      tile = Semantics(container: true, label: label, child: tile);
    }
    return tile;
  }
}

/// CSS's radial gradient (`radial-gradient(<rx> <ry> at <cx> <cy>, …)`),
/// the colour fading out to [to] of an ellipse [rx] of the box's
/// width across and [ry] of its height down, round the point [cx], [cy].
RadialGradient _radial(
  Color color, {
  required double rx,
  required double ry,
  required double cx,
  required double cy,
  required double to,
}) {
  final ellipse = FrostedEllipse(rx: rx, ry: ry, cx: cx, cy: cy);
  return RadialGradient(
    center: ellipse.center,
    radius: 1,
    colors: [color, color.withValues(alpha: 0)],
    stops: [0, to],
    transform: ellipse,
  );
}

/// `.insight`'s wash: `linear-gradient(160deg, var(--t2) 0%, var(--t) 45%,
/// rgba(255,255,255,0) 100%)`, mixed as CSS mixes it.
LinearGradient _insightWash(FrostedHue hue) {
  final mixed = frostedCssStops(
    [hue.tintSolid, hue.tint, hue.tint.withValues(alpha: 0)],
    stops: const [0, 0.45, 1],
  );
  return LinearGradient(
    colors: mixed.colors,
    stops: mixed.stops,
    transform: const FrostedCssAngle(160),
  );
}

/// [child] under a hairline, as `.note-r + .note-r` and the desktop grid's
/// `.kv-r:nth-child(n + 4)` rule a border-top between rows that grow by it
/// (a line with a min-height takes the hairline inside it: [_Ruled]).
class _Lined extends StatelessWidget {
  const _Lined({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: context.frostedTheme.colorScheme.border),
      ),
    ),
    // The line takes its own row of pixels, as CSS's border does.
    child: Padding(
      padding: const EdgeInsets.only(top: FrostedChromeMetrics.outline),
      child: child,
    ),
  );
}

/// A tile's head: its title in the display face with an [trailing] at the far
/// end (a caption, a small button, a segmented control), 12 under it.
///
/// ```dart
/// FrostedCardHeader('Transactions', trailing: Text('32 in October', style: t.caption))
/// ```
class FrostedCardHeader extends StatelessWidget {
  /// A tile's head titled [title], with [trailing] at the far end.
  const FrostedCardHeader(this.title, {this.trailing, super.key});

  /// The head's words.
  final String title;

  /// What stands at the head's end.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final trailing = this.trailing;
    // .tile-h { align-items: center; justify-content: space-between; gap:
    // 12px; margin-bottom: 12px; min-height: 24px }
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: FrostedChromeMetrics.tileHeadGap,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.tileHead,
        ),
        child: Row(
          spacing: FrostedChromeMetrics.tileHeadRowGap,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: t.textTheme.titleLarge),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A section's head on the canvas: its title in the display face with an
/// [aside] (a count, a sum) or an [trailing] at the far end on the same
/// baseline; the desktop draws none, its tiles carrying their own heads
/// (`.sec-h { display: none }` from 1024).
///
/// ```dart
/// FrostedSectionHeader('Accounts', aside: '5 accounts')
/// ```
class FrostedSectionHeader extends StatelessWidget {
  /// A section's head titled [title], with an [aside] or an [trailing].
  const FrostedSectionHeader(
    this.title, {
    this.aside,
    this.trailing,
    super.key,
  });

  /// The head's words.
  final String title;

  /// The words at the head's end.
  final String? aside;

  /// What stands at the head's end after the aside.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (FrostedBreakpoints.isWide(context)) return const SizedBox.shrink();
    final t = context.frostedTheme;
    final aside = this.aside;
    final trailing = this.trailing;
    // .sec-h { align-items: baseline; justify-content: space-between;
    // padding: 10px 2px 0 }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FrostedChromeMetrics.sectionHeadInset,
        FrostedChromeMetrics.sectionHeadTop,
        FrostedChromeMetrics.sectionHeadInset,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: FrostedSpacing.s12,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: t.textTheme.titleLarge),
            ),
          ),
          if (aside != null) Text(aside, style: t.textTheme.bodyMedium),
          ?trailing,
        ],
      ),
    );
  }
}

// --- rows ------------------------------------------------------------------

/// One row of a list: its [leading] (a mark, a date block), its [title] over
/// its [meta] taking the room, a [mid] column the desktop adds, and its
/// [trailing] (an amount, a chevron, a [FrostedRowEnd]); 52 tall at least. With
/// [onPressed] the row is one link that says its title, its meta line and
/// its trailing words. [current] marks the row the page is about among its neighbours.
///
/// ```dart
/// FrostedListTile(leading: FrostedMonogram('Blue Fern Café', hue: t.hues.coral), title: 'Blue Fern Café', meta: 'Dining out · 8:12 AM', trailing: const FrostedAmount(-6.75), onPressed: open)
/// ```
class FrostedListTile extends StatelessWidget {
  /// A row titled [title].
  const FrostedListTile({
    required this.title,
    this.leading,
    this.meta,
    this.trailing,
    this.mid,
    this.onPressed,
    this.enabled = true,
    this.selected = false,
    this.titleLines = 2,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What stands before the words (a mark, an avatar).
  final Widget? leading;

  /// The row's words.
  final String title;

  /// A quiet line under the title.
  final String? meta;

  /// What stands at the row's end (a value, a chevron).
  final Widget? trailing;

  /// A column between the words and the end (the desktop's account).
  final Widget? mid;

  /// What a press does; null leaves the row still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Whether the row answers: false paints it disabled, at the same size.
  final bool enabled;

  /// Whether this is the row the page stands on (`.rows--mark .row.this`).
  final bool selected;

  /// How many lines the title may take before it ellipsizes.
  final int titleLines;

  /// This row's own style, over `FrostedThemeData.components.listTile`: the
  /// chosen row's mark (fill and its ring, edge; its shape), the title's
  /// colour and style, and the row's padding, each per state (selected
  /// while [selected]).
  ///
  /// ```dart
  /// FrostedListTile(
  ///   title: 'Notifications',
  ///   style: const FrostedStyle(
  ///     padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10)),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final leading = this.leading;
    final meta = this.meta;
    final mid = this.mid;
    final trailing = this.trailing;
    final onPressed = this.onPressed;
    final s = FrostedStyleLayers(style, t.components.listTile, {
      if (selected) WidgetState.selected,
      if (!enabled) WidgetState.disabled,
    });
    // .row { align-items: center; gap: 12px; min-height: 52px; padding: 6px 0 }
    Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FrostedChromeMetrics.row),
      child: Padding(
        padding:
            s.padding ??
            const EdgeInsets.symmetric(vertical: FrostedChromeMetrics.rowInset),
        child: FrostedRowContent(
          child: Row(
            spacing: FrostedChromeMetrics.rowGap,
            children: [
              ?leading,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostedChromeMetrics.rowLineGap,
                  children: [
                    // .row-t { font: 500 16px/1.25 }
                    frostedCapCentred(
                      Text(
                        title,
                        style: s.words(t.textTheme.titleMedium),
                        maxLines: titleLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // .row-s { font: 400 14px/1.3; color: var(--ink-2);
                    // white-space: nowrap; text-overflow: ellipsis }
                    if (meta != null)
                      Text(
                        meta,
                        style: t.textTheme.bodyMedium.line(18.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              ?mid,
              ?trailing,
            ],
          ),
        ),
      ),
    );
    if (selected) {
      // .rows--mark .row.this { margin: 0 -10px; padding: 0 10px;
      // border-radius: 12px; background: rgba(255,255,255,.7); box-shadow:
      // inset 0 0 0 1px var(--line) }
      row = Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            start: -FrostedChromeMetrics.rowMarkBleed,
            end: -FrostedChromeMetrics.rowMarkBleed,
            top: 0,
            bottom: 0,
            child: FrostedFace(
              material: FrostedMaterial.paint,
              radius: BorderRadius.circular(
                FrostedStyleLayers.radiusOf(
                  s.shape,
                  0,
                  FrostedChromeMetrics.rowMarkRadius,
                ),
              ),
              shape: s.shape,
              color: s.fill ?? t.glass.plane.withValues(alpha: _markFill),
              wash: s.overlay,
              ring: s.edge ?? frostedLitEdge(t, t.colorScheme.border),
            ),
          ),
          row,
        ],
      );
    }
    row = FrostedDim(off: !enabled, child: row);
    return MergeSemantics(
      child: onPressed == null && enabled
          ? row
          : FrostedPressable(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: enabled ? onPressed : null,
              role: FrostedPressRole.link,
              // The ring traces the chosen row's plate, which bleeds past
              // the row on both sides, chosen or not.
              radius: FrostedStyleLayers.radiusOf(
                s.shape,
                0,
                FrostedChromeMetrics.rowMarkRadius,
              ),
              shape: s.shape,
              ringInsets: const EdgeInsets.symmetric(
                horizontal: -FrostedChromeMetrics.rowMarkBleed,
              ),
              child: row,
            ),
    );
  }
}

/// A row's end: the [amount] over a 12 point [note] (Pending with its
/// clock, a due date), the note in [noteTone]'s ink when it has one.
///
/// ```dart
/// FrostedRowEnd(amount: const FrostedAmount(-6.75), note: 'Pending', noteIcon: FrostedGlyphs.clock)
/// ```
class FrostedRowEnd extends StatelessWidget {
  /// A row's end showing [amount], with a [note] under it.
  const FrostedRowEnd({
    required this.amount,
    this.note,
    this.noteIcon,
    this.noteTone,
    super.key,
  });

  /// The figure.
  final Widget amount;

  /// A quiet line under the figure.
  final String? note;

  /// A glyph before the note.
  final IconData? noteIcon;

  /// The note's tone; null for the quiet ink.
  final FrostedTone? noteTone;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final note = this.note;
    final noteIcon = this.noteIcon;
    final tone = noteTone;
    final ink = tone == null ? t.colorScheme.textTertiary : t.toneInk(tone);
    // .row-end { flex-direction: column; align-items: flex-end; gap: 3px }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: FrostedChromeMetrics.rowEndGap,
      children: [
        amount,
        // .row-pend { gap: 3px; font: 500 12px/1; color: var(--ink-3) }
        if (note != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedChromeMetrics.rowPendingGap,
            children: [
              if (noteIcon != null)
                Icon(
                  noteIcon,
                  size: FrostedChromeMetrics.rowPendingGlyph,
                  color: ink,
                ),
              Text(note, style: t.textTheme.labelSmall.c(ink), maxLines: 1),
            ],
          ),
      ],
    );
  }
}

/// A transaction's row: its [mark] (what the money did), its [title] over
/// its [subtitle] (the category and the time), its [amount] signed, Pending
/// under it while it is, and on the desktop the [account] it moved on in
/// its own column before the amount.
///
/// ```dart
/// FrostedTransactionRow(mark: FrostedTransactionMark.purchase('Blue Fern Café', hue: t.hues.coral), title: 'Blue Fern Café', subtitle: 'Dining out · 8:12 AM', amount: -6.75, pending: true, account: 'Harbor Card', accountIcon: FrostedGlyphs.creditCard, onPressed: open)
/// ```
class FrostedTransactionRow extends StatelessWidget {
  /// A row for one entry: its [mark], [title] over [subtitle], and its [amount].
  const FrostedTransactionRow({
    required this.mark,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.pending = false,
    this.account,
    this.accountIcon,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The round mark at the row's start.
  final Widget mark;

  /// The entry's name.
  final String title;

  /// The quiet line under the name.
  final String subtitle;

  /// The entry's sum; below zero is money out.
  final num amount;

  /// Whether the entry is not yet settled (its sum in the quiet ink).
  final bool pending;

  /// The account's name, drawn on the desktop only (`.row-acct`).
  final String? account;

  /// A glyph for the account it rode, after the sub line.
  final IconData? accountIcon;

  /// What a press does; null leaves the row still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final screenWide = FrostedBreakpoints.isWide(context);
    // The account column stands only where the row itself has room for it
    // beside the mark, a title and the amount: a list in a narrow pane (a
    // 1024 screen's, beside its detail) leaves it out, as a phone does.
    return LayoutBuilder(
      builder: (context, box) => _build(
        context,
        screenWide,
        screenWide && box.maxWidth >= _accountRoom,
      ),
    );
  }

  /// The least width a row shows its account column at: the 40 mark, the
  /// 148 column, the 96 amount, three 12 gaps and 120 of title.
  static const double _accountRoom = 440;

  Widget _build(BuildContext context, bool wide, bool withAccount) {
    final t = context.frostedTheme;
    final account = this.account;
    final accountIcon = this.accountIcon;
    // `.row-pend`: the source's Pending is the word alone, no glyph (the
    // zap is Autopay's, on a page's own FrostedRowEnd).
    Widget end = FrostedRowEnd(
      amount: FrostedAmount(amount),
      note: pending ? 'Pending' : null,
    );
    if (wide) {
      // .row .amt, .row .row-end { min-width: 96px } on the desktop.
      end = ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: FrostedChromeMetrics.rowAmountWide,
        ),
        child: end,
      );
    }
    return FrostedListTile(
      focusNode: focusNode,
      autofocus: autofocus,
      leading: mark,
      title: title,
      meta: subtitle,
      onPressed: onPressed,
      // .row-acct { width: 148px; gap: 8px; font: 400 14px/1.3; color:
      // var(--ink-2) } .row-acct .i { 16px; color: var(--ink-3) }
      mid: withAccount && account != null
          ? SizedBox(
              width: FrostedChromeMetrics.rowAccountWide,
              child: Row(
                spacing: FrostedChromeMetrics.rowAccountGap,
                children: [
                  if (accountIcon != null)
                    Icon(
                      accountIcon,
                      size: FrostedChromeMetrics.rowAccountGlyph,
                      color: t.colorScheme.textTertiary,
                    ),
                  Expanded(
                    child: Text(
                      account,
                      style: t.textTheme.bodyMedium.line(18.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : null,
      trailing: end,
    );
  }
}

/// A day's head in a list of transactions: its [label] (Today, Fri, Oct
/// 23) in the quiet caption with the day's [net] at the end, money in lit
/// green; 14 of room above it, 2 when it is the list's [first].
///
/// ```dart
/// FrostedDayHead('Today', net: -9.65, first: true)
/// ```
class FrostedDayHead extends StatelessWidget {
  /// A day's head over its rows, named [label].
  const FrostedDayHead(this.label, {this.net, this.first = false, super.key});

  /// The day's name (Today, Mon 3 Nov).
  final String label;

  /// The day's net sum, at the far end.
  final num? net;

  /// Whether it heads the list (no room above it).
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final net = this.net;
    // .day { justify-content: space-between; gap: 12px; font: 500 12px/1;
    // color: var(--ink-3); padding: 14px 0 4px } .day:first-child { 2px }
    return Padding(
      padding: EdgeInsets.only(
        top: first
            ? FrostedChromeMetrics.dayTopFirst
            : FrostedChromeMetrics.dayTop,
        bottom: FrostedChromeMetrics.dayBottom,
      ),
      child: Row(
        spacing: FrostedChromeMetrics.rowGap,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: t.textTheme.labelSmall.c(t.colorScheme.textTertiary),
              ),
            ),
          ),
          if (net != null)
            FrostedAmount(net, size: FrostedAmountSize.extraSmall),
        ],
      ),
    );
  }
}

/// A column of rows: [FrostedListTile]s under their [FrostedDayHead]s and
/// [FrostedMonthDivider]s. [timeline] draws the spine between two rows'
/// date blocks (the bills); [hairlines] rules a line between each pair
/// (the earlier notes).
///
/// ```dart
/// FrostedRowGroup(children: [FrostedDayHead('Today', first: true), row, row])
/// ```
class FrostedRowGroup extends StatelessWidget {
  /// Rows standing as one group.
  const FrostedRowGroup({
    required this.children,
    this.timeline = false,
    this.hairlines = false,
    super.key,
  });

  /// The rows, in order.
  final List<Widget> children;

  /// Whether a line runs down the rows' marks.
  final bool timeline;

  /// Whether a hairline stands between two rows.
  final bool hairlines;

  static bool _isRow(Widget w) =>
      w is FrostedListTile || w is FrostedTransactionRow;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      if (hairlines && i > 0) child = _Lined(child: child);
      if (timeline && i > 0 && _isRow(children[i - 1]) && _isRow(child)) {
        child = Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            PositionedDirectional(
              start: _timelineStart,
              top: _timelineTop,
              child: SizedBox(
                width: FrostedChromeMetrics.outline,
                height: _timelineHeight,
                child: ColoredBox(
                  color: t.colorScheme.textPrimary.withValues(
                    alpha: _timelineInk,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      rows.add(child);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// A month's divider in a long list: its name small and bold under a
/// hairline, 10 of room above.
///
/// ```dart
/// FrostedMonthDivider('September 2026')
/// ```
class FrostedMonthDivider extends StatelessWidget {
  /// A divider naming the month [label].
  const FrostedMonthDivider(this.label, {super.key});

  /// The month's name.
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .month-div { font: 600 12px/1; color: var(--ink-2); margin-top: 10px;
    // padding: 16px 0 0; border-top: 1px solid var(--line) }
    return Padding(
      padding: const EdgeInsets.only(top: FrostedChromeMetrics.monthDividerTop),
      child: _Lined(
        child: Padding(
          padding: const EdgeInsets.only(
            top: FrostedChromeMetrics.monthDividerBottom,
          ),
          child: Semantics(
            header: true,
            child: Text(
              label,
              style: t.textTheme.labelSmall.semibold.c(
                t.colorScheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- facts -----------------------------------------------------------------

/// One fact of a [FrostedDescriptionList]: its [label] in the quiet ink at the
/// start, its [value] (or a [valueWidget], an amount or a hue dot with its
/// name) at the end with a [subtitle] under it, an [trailing] (a small act) after,
/// and a chevron when the fact [onPressed] opens something, the whole row then
/// one link.
///
/// ```dart
/// FrostedKeyValue(label: 'Held in', value: 'Savings ·· 9015', onPressed: openSavings)
/// ```
class FrostedKeyValue extends StatelessWidget {
  /// One fact: its [label] and [value].
  const FrostedKeyValue({
    required this.label,
    this.value,
    this.valueWidget,
    this.subtitle,
    this.onPressed,
    this.trailing,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(value != null || valueWidget != null, 'a value or a valueWidget');

  /// What the fact is.
  final String label;

  /// The fact itself.
  final String? value;

  /// Draws the value in place of [value]'s words.
  final Widget? valueWidget;

  /// A quiet line under the value.
  final String? subtitle;

  /// What a press does; null leaves the fact still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// What stands after the value.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) =>
      _KeyValueLine(row: this, grid: false, ruled: _Ruled.of(context));
}

/// Marks the [FrostedKeyValue] under it as one after another: drawn under
/// the hairline `.kv-r + .kv-r` sets, inside its 52 (the source's boxes
/// are border-box, so the line takes none of the row's height).
class _Ruled extends InheritedWidget {
  const _Ruled({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Ruled>() != null;

  @override
  bool updateShouldNotify(_Ruled oldWidget) => false;
}

/// A [FrostedKeyValue] drawn as a line (label | value) or as a cell of the
/// desktop's grid (label over value); [ruled] draws the line's hairline.
class _KeyValueLine extends StatelessWidget {
  const _KeyValueLine({
    required this.row,
    required this.grid,
    this.ruled = false,
  });

  final FrostedKeyValue row;
  final bool grid;
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final sub = row.subtitle;
    final end = row.trailing;
    final onTap = row.onPressed;
    final valueWidget = row.valueWidget;
    // .kv-v { font: 500 16px/1.3; text-align: right; white-space: nowrap }
    // .kv--grid .kv-v { text-align: left; white-space: normal }
    final value =
        valueWidget ??
        Text(
          row.value!,
          style: t.textTheme.titleMedium.line(20.8),
          textAlign: grid ? TextAlign.start : TextAlign.end,
          maxLines: grid ? null : 1,
          overflow: grid ? null : TextOverflow.ellipsis,
        );
    // .kv-v--2 { flex-direction: column; gap: 2px } .kv-sub { font: 400
    // 12px/1.3; color: var(--ink-3) }
    final parts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: grid
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      spacing: FrostedChromeMetrics.keyValueLineGap,
      children: [
        value,
        if (sub != null)
          Text(
            sub,
            style: t.textTheme.bodySmall
                .c(t.colorScheme.textTertiary)
                .line(15.6),
            textAlign: grid ? TextAlign.start : TextAlign.end,
          ),
      ],
    );
    final chevron = Icon(
      FrostedGlyphs.forward,
      size: FrostedChromeMetrics.keyValueGlyph,
      color: t.colorScheme.textTertiary,
    );
    Widget body;
    if (grid) {
      // .kv--grid .kv-r { flex-direction: column; align-items: flex-start;
      // gap: 4px; min-height: 0; padding: 12px 0 } .kv--grid .kv-k { font:
      // 500 12px; color: var(--ink-3) } a.kv-r .i-chevron-right { position:
      // absolute; right: 0; top: 35px }
      body = Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: FrostedChromeMetrics.keyValueGridInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedChromeMetrics.keyValueGridLineGap,
              children: [
                Text(row.label, style: t.textTheme.labelMedium),
                Row(
                  spacing: FrostedChromeMetrics.keyValuePartsGap,
                  children: [
                    Flexible(child: parts),
                    ?end,
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null)
            PositionedDirectional(
              end: 0,
              top: FrostedChromeMetrics.keyValueGridChevronTop,
              child: chevron,
            ),
        ],
      );
    } else {
      // .kv-r { align-items: center; gap: 12px; min-height: 52px; padding:
      // 8px 0 } .kv-k { flex: none; font: 400 14px/1.3; color: var(--ink-2) }
      // .kv-v { flex: 1; justify-content: flex-end; gap: 8px } .kv-r + .kv-r
      // { border-top: 1px solid var(--line) }: border-box, so the hairline
      // lies inside the 52 and a ruled line stands as tall as the first.
      body = ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.keyValue,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: FrostedChromeMetrics.keyValueInset,
          ),
          decoration: ruled
              ? BoxDecoration(
                  border: Border(top: BorderSide(color: t.colorScheme.border)),
                )
              : null,
          child: Row(
            spacing: FrostedChromeMetrics.keyValueGap,
            children: [
              Text(row.label, style: t.textTheme.bodyMedium.line(18.2)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: FrostedChromeMetrics.keyValuePartsGap,
                  children: [
                    Flexible(child: parts),
                    ?end,
                  ],
                ),
              ),
              // a.kv-r: the chevron is the line's own part, 12 after the
              // value (`.kv-r { gap: 12px }`), not one of the value's 8.
              if (onTap != null) chevron,
            ],
          ),
        ),
      );
    }
    return MergeSemantics(
      child: onTap == null
          ? body
          : FrostedPressable(
              focusNode: row.focusNode,
              autofocus: row.autofocus,
              onPressed: onTap,
              role: FrostedPressRole.link,
              child: body,
            ),
    );
  }
}

/// A record's facts, one [FrostedKeyValue] a line with a hairline between
/// each pair; [grid] lays them three across on the desktop, each label over
/// its value, the rows after the first ruled (a goal's, the profile's).
///
/// ```dart
/// FrostedDescriptionList(children: [FrostedKeyValue(label: 'Status', value: 'Pending'), FrostedKeyValue(label: 'Card', value: 'Harbor Card ·· 7730')])
/// ```
class FrostedDescriptionList extends StatelessWidget {
  /// A list of facts.
  const FrostedDescriptionList({
    required this.children,
    this.grid = false,
    super.key,
  });

  /// The facts, in order.
  final List<FrostedKeyValue> children;

  /// Whether the desktop lays the facts out three across (`.kv--grid`).
  final bool grid;

  @override
  Widget build(BuildContext context) {
    if (!(grid && FrostedBreakpoints.isWide(context))) {
      // .kv-r + .kv-r { border-top: 1px solid var(--line) }: each line after
      // the first draws the hairline inside its own 52.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++)
            i == 0 ? children[i] : _Ruled(child: children[i]),
        ],
      );
    }
    // .kv--grid { grid-template-columns: repeat(3, minmax(0, 1fr));
    // column-gap: 16px } .kv--grid .kv-r:nth-child(n + 4) { border-top }:
    // every fact as tall as its row (the grid's `align-items: stretch`), so
    // a linked one's press reaches the row's floor beside a two-line fact.
    const n = FrostedChromeMetrics.keyValueGridColumns;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += n) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostedChromeMetrics.keyValueGridGap,
            children: [
              for (var j = i; j < i + n; j++)
                Expanded(
                  child: j >= children.length
                      ? const SizedBox.shrink()
                      : i == 0
                      ? _KeyValueLine(row: children[j], grid: true)
                      : _Lined(
                          child: _KeyValueLine(row: children[j], grid: true),
                        ),
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// --- a record's head -------------------------------------------------------

enum _HeroFace { record, centred, review }

/// A record's head in its tile: its [mark] beside its [title] over its
/// [subtitle] (an [trailing] act after them), its [amount] in the display face over
/// what it is [of], its [chips] (and a full-width [note]) under, then the
/// page's own [child] (a chart, a meter); the tile washed in [hue] from
/// its top start corner (`.rec-hero`, `.cat-hero`). [FrostedRecordHero.centred]
/// is a transaction's: the large mark, the title and sub, the figure and
/// its chips all centred under the wash (`.txn-hero`); [FrostedRecordHero.review]
/// a move's: its [route] (from one token to another) over the figure and a
/// line saying where (`.rv-hero`).
///
/// ```dart
/// FrostedRecordHero(mark: FrostedIconMark(FrostedGlyphs.wallet, hue: everyday), title: 'Everyday', subtitle: 'Checking ·· 4821', amount: 6248.30, of: 'Available now', hue: everyday)
/// ```
///
/// ```dart
/// FrostedRecordHero.centred(mark: FrostedTransactionMark.purchase('Mesa Taqueria', hue: dining, size: FrostedMarkSize.large), title: 'Mesa Taqueria', subtitle: 'Dining out · Harbor Card', amount: -38.40, chips: [const FrostedTag('Posted', icon: FrostedGlyphs.check)], hue: dining)
/// ```
class FrostedRecordHero extends StatelessWidget {
  /// A record's head showing [amount].
  const FrostedRecordHero({
    required Widget this.mark,
    required String this.title,
    required this.amount,
    this.subtitle,
    this.of,
    this.ofEnd,
    this.flow = FrostedMoneyFlow.balance,
    this.sign = false,
    this.cents = true,
    this.hue,
    this.chips = const <Widget>[],
    this.note,
    this.trailing,
    this.child,
    this.label,
    super.key,
  }) : route = null,
       _face = _HeroFace.record;

  /// A transaction's head, everything centred under the wash.
  const FrostedRecordHero.centred({
    required Widget this.mark,
    required String this.title,
    required this.amount,
    this.subtitle,
    this.flow = FrostedMoneyFlow.balance,
    this.sign = false,
    this.cents = true,
    this.hue,
    this.chips = const <Widget>[],
    this.child,
    this.label,
    super.key,
  }) : of = null,
       ofEnd = null,
       note = null,
       trailing = null,
       route = null,
       _face = _HeroFace.centred;

  /// A move's head: its [route] over the figure and where it goes.
  const FrostedRecordHero.review({
    required Widget this.route,
    required this.amount,
    this.subtitle,
    this.flow = FrostedMoneyFlow.balance,
    this.cents = true,
    this.hue,
    this.child,
    this.label,
    super.key,
  }) : mark = null,
       title = null,
       of = null,
       ofEnd = null,
       sign = false,
       chips = const <Widget>[],
       note = null,
       trailing = null,
       _face = _HeroFace.review;

  /// The mark beside the title.
  final Widget? mark;

  /// The record's name.
  final String? title;

  /// The quiet line under the name.
  final String? subtitle;

  /// The record's figure.
  final num amount;

  /// The line under the figure: what the figure is of (`.of`); a
  /// `**strong**` run in it is set semibold in the ink (`.strong`), as the
  /// source sets the percent of a budget or a target.
  final String? of;

  /// What stands at the of-line's end on its line (`.cat-of`: a category's
  /// chip, over by or left).
  final Widget? ofEnd;

  /// Which way the figure moves money (in, out, neither).
  final FrostedMoneyFlow flow;

  /// Whether the figure shows its sign.
  final bool sign;

  /// Whether the figure shows its cents.
  final bool cents;

  /// The hue the head is washed with.
  final FrostedHue? hue;

  /// The chips (and subs) under the figure (`.rec-chips`, `.txn-meta`).
  final List<Widget> chips;

  /// A caption taking a whole line after the chips (`.rec-note`).
  final String? note;

  /// An act at the head's end (a category's Edit budget).
  final Widget? trailing;

  /// The page's own content under the head (a chart, a meter).
  final Widget? child;

  /// The review's route (a FrostedRoute: the two tokens and the beams),
  /// carrying `.route`'s own 8 under it.
  final Widget? route;

  /// The spoken name of the whole.
  final String? label;
  final _HeroFace _face;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final subtitle = this.subtitle;
    final of = this.of;
    final note = this.note;
    final trailing = this.trailing;
    final ofEnd = this.ofEnd;
    final child = this.child;
    final money = FrostedMoney(amount, flow: flow, sign: sign, cents: cents);
    final ofStyle = t.textTheme.bodyMedium.line(16.8);
    final ofStrong = ofStyle.semibold.c(t.colorScheme.textPrimary);
    switch (_face) {
      case _HeroFace.record:
        return FrostedCard.record(
          hue: hue,
          label: label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // .rec-top { align-items: center; gap: 12px } .rec-top
              // .row-main { gap: 2px }
              Row(
                spacing: FrostedChromeMetrics.recordMarkGap,
                children: [
                  mark!,
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: FrostedSpacing.s2,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title!, style: t.textTheme.titleLarge),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: t.textTheme.bodyMedium.line(18.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: FrostedChromeMetrics.recordGap),
              // .rec-fig { gap: 10px } .of { font: 400 14px/1.2; color:
              // var(--ink-2) }
              money,
              if (of != null) ...[
                const SizedBox(height: FrostedChromeMetrics.recordFigureGap),
                // .cat-of { align-items: center; justify-content:
                // space-between; gap: 8px } .strong { 600; color: var(--ink) }
                if (ofEnd == null)
                  _Runs(of, style: ofStyle, strong: ofStrong)
                else
                  Row(
                    spacing: FrostedSpacing.s8,
                    children: [
                      Expanded(
                        child: _Runs(of, style: ofStyle, strong: ofStrong),
                      ),
                      ofEnd,
                    ],
                  ),
              ],
              // .rec-chips { gap: 8px; flex-wrap: wrap; margin-top: -6px }
              // .rec-note { flex-basis: 100% }
              if (chips.isNotEmpty || note != null) ...[
                const SizedBox(
                  height:
                      FrostedChromeMetrics.recordGap -
                      FrostedChromeMetrics.recordChipsPull,
                ),
                Wrap(
                  spacing: FrostedChromeMetrics.recordChipsGap,
                  runSpacing: FrostedChromeMetrics.recordChipsGap,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...chips,
                    if (note != null)
                      SizedBox(
                        width: double.infinity,
                        child: Text(note, style: t.textTheme.labelMedium),
                      ),
                  ],
                ),
              ],
              if (child != null) ...[
                const SizedBox(height: FrostedChromeMetrics.recordGap),
                child,
              ],
            ],
          ),
        );
      case _HeroFace.centred:
        // .txn-hero { gap: 6px } .txn-hero .mono--lg { margin-bottom: 8px }
        // .txn-hero .money { margin: 14px 0 12px } .txn-meta { gap: 8px }
        return FrostedCard.hero(
          hue: hue,
          label: label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              mark!,
              const SizedBox(
                height:
                    FrostedChromeMetrics.transactionGap +
                    FrostedChromeMetrics.transactionMarkGap,
              ),
              Semantics(
                header: true,
                child: Text(
                  title!,
                  style: t.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: FrostedChromeMetrics.transactionGap),
                Text(
                  subtitle,
                  style: t.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(
                height:
                    FrostedChromeMetrics.transactionGap +
                    FrostedChromeMetrics.transactionFigureTop,
              ),
              money,
              if (chips.isNotEmpty) ...[
                const SizedBox(
                  height:
                      FrostedChromeMetrics.transactionFigureBottom +
                      FrostedChromeMetrics.transactionGap,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: FrostedChromeMetrics.transactionMetaGap,
                  runSpacing: FrostedChromeMetrics.transactionMetaGap,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: chips,
                ),
              ],
              if (child != null) ...[
                const SizedBox(height: FrostedChromeMetrics.transactionGap),
                child,
              ],
            ],
          ),
        );
      case _HeroFace.review:
        // .rv-hero { gap: 8px; padding-top: 24px; padding-bottom: 24px }
        // .route { margin-bottom: 8px } .rv-hero .money { margin: 8px 0 4px }
        final pad = FrostedBreakpoints.pad(context);
        return FrostedCard.hero(
          hue: hue,
          label: label,
          padding: EdgeInsets.fromLTRB(
            pad,
            FrostedChromeMetrics.reviewTop,
            pad,
            FrostedChromeMetrics.reviewBottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              route!,
              // The route carries `.route { margin-bottom: 8px }` itself.
              const SizedBox(
                height:
                    FrostedChromeMetrics.reviewGap +
                    FrostedChromeMetrics.reviewFigureTop,
              ),
              money,
              if (subtitle != null) ...[
                const SizedBox(
                  height:
                      FrostedChromeMetrics.reviewFigureBottom +
                      FrostedChromeMetrics.reviewGap,
                ),
                Text(
                  subtitle,
                  style: t.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              if (child != null) ...[
                const SizedBox(height: FrostedChromeMetrics.reviewGap),
                child,
              ],
            ],
          ),
        );
    }
  }
}

/// A record's chart (`.rec-chart`, `.cat-chart`): its [head] (a caption,
/// or a caption with the chart's keys or a sum at the far end) over the
/// [chart], 10 apart, the chart's axis words 10 further under the plot
/// than a lone chart's, as the source's column lays its axis out as an
/// item of its own (`.rec-chart { gap: 10px }`, `.rec-chart .chart {
/// margin-top: 0 }`). The [child] of a [FrostedRecordHero], or a tile's own.
///
/// ```dart
/// FrostedRecordChart(head: Text('Balance through October', style: t.caption), chart: FrostedTrailChart.steps(values: balance, start: opening, daysInMonth: 31, marks: axis, label: 'Everyday balance through October'))
/// ```
class FrostedRecordChart extends StatelessWidget {
  /// A record's [chart] under its [head].
  const FrostedRecordChart({required this.chart, this.head, super.key});

  /// The caption over the chart.
  final Widget? head;

  /// The chart.
  final Widget chart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostedSpacing.s10,
    children: [
      ?head,
      FrostedChartAxisRoom(extra: FrostedSpacing.s10, child: chart),
    ],
  );
}

// --- cards and alerts ------------------------------------------------------

/// Spending's insight: a [kind] line (its glyph and name in the hue's ink),
/// a [title] in the display face, a [body] whose `**bold**` runs stand out
/// in the hue's ink, the [visits] as a row of hued dots (said as
/// [visitsLabel]) and the page's own [child] (a meter) under them, the
/// tile washed in [hue] down from its top start corner; the whole a link
/// when it [onPressed] opens something.
///
/// ```dart
/// FrostedInsight(icon: FrostedGlyphs.utensils, kind: 'Insight · Dining out', title: r'$36.40 over budget', body: r'13 visits to Blue Fern Café came to **$84.25**.', hue: t.hues.coral, visits: 13, onPressed: open)
/// ```
class FrostedInsight extends StatelessWidget {
  /// An insight titled [title] under its [kind] line.
  const FrostedInsight({
    required this.icon,
    required this.kind,
    required this.title,
    required this.body,
    required this.hue,
    this.visits,
    this.visitsLabel,
    this.child,
    this.onPressed,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The glyph before the kind.
  final IconData icon;

  /// What sort of insight it is (Trend, Heads up).
  final String kind;

  /// The insight's words.
  final String title;

  /// The body; `**` round a run sets it bold in the hue's ink.
  final String body;

  /// The insight's hue.
  final FrostedHue hue;

  /// How many visits the dots count; null for no dots.
  final int? visits;

  /// What the dots say; null for "N visits".
  final String? visitsLabel;

  /// What stands under the words (a chart, a row).
  final Widget? child;

  /// What a press does; null leaves the tile still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// What a screen reader calls the tile.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final visits = this.visits;
    final child = this.child;
    // .insight { color: var(--k); gap: 12px } .insight-k { gap: 6px; font:
    // 500 12px/1 } .insight-t { font: 500 28px/1.05; letter-spacing: -.025em }
    // .insight-b { font: 400 16px/1.4; color: var(--ink-2) } .insight-b b {
    // font-family: var(--font-d); font-weight: 600; color: var(--k) }
    final bodyStyle = t.textTheme.bodyLarge
        .c(t.colorScheme.textSecondary)
        .line(22.4);
    return FrostedFacedCard(
      focusNode: focusNode,
      autofocus: autofocus,
      face: FrostedCardFace.insight,
      hue: hue,
      onPressed: onPressed,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FrostedChromeMetrics.insightGap,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedChromeMetrics.insightKindGap,
            children: [
              Icon(
                icon,
                size: FrostedChromeMetrics.insightKindGlyph,
                color: hue.ink,
              ),
              Flexible(
                child: Text(kind, style: t.textTheme.labelSmall.c(hue.ink)),
              ),
            ],
          ),
          Semantics(
            header: true,
            child: Text(
              title,
              style: t.textTheme.headlineMedium.c(hue.ink).line(29.4),
            ),
          ),
          _Runs(
            body,
            style: bodyStyle,
            strong: bodyStyle.display.semibold.c(hue.ink),
          ),
          if (visits != null)
            _Visits(count: visits, hue: hue, label: visitsLabel),
          ?child,
        ],
      ),
    );
  }
}

/// Words with `**bold**` runs in [strong].
class _Runs extends StatelessWidget {
  const _Runs(this.text, {required this.style, required this.strong});

  final String text;
  final TextStyle style;
  final TextStyle strong;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (var i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              TextSpan(text: parts[i], style: i.isOdd ? strong : null),
        ],
      ),
    );
  }
}

/// The visits as dots of the hue, said once as their count.
class _Visits extends StatelessWidget {
  const _Visits({required this.count, required this.hue, this.label});

  /// How many dots.
  final int count;

  /// The dots' hue.
  final FrostedHue hue;

  /// What a screen reader hears; null says the count.
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label ?? '$count visits',
    child: ExcludeSemantics(
      // .visits { flex-wrap: wrap; gap: 6px } .visits i { 10px round;
      // background: linear-gradient(135deg, var(--a), var(--b)) }
      child: Wrap(
        spacing: FrostedChromeMetrics.visitsGap,
        runSpacing: FrostedChromeMetrics.visitsGap,
        children: [
          for (var i = 0; i < count; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hue.dot,
              ),
              child: const SizedBox(width: _visitsDot, height: _visitsDot),
            ),
        ],
      ),
    ),
  );
}

/// A sheet's suggestion: a white mark with the [icon] in the hue's ink,
/// the [title] bold in that ink over its [subtitle], on a card washed in [hue]
/// from its top start corner; an [trailing] act after them (Use), or the whole
/// a button when it [onPressed] takes the suggestion.
///
/// ```dart
/// FrostedSuggestion(icon: FrostedGlyphs.sparkles, title: r'Suggested $275', subtitle: 'Your September and October average', hue: t.hues.coral)
/// ```
class FrostedSuggestion extends StatelessWidget {
  /// A suggestion titled [title] over [subtitle].
  const FrostedSuggestion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hue,
    this.trailing,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The glyph in the hue's round mark.
  final IconData icon;

  /// The suggestion's words.
  final String title;

  /// The quiet line under them.
  final String subtitle;

  /// The mark's hue.
  final FrostedHue hue;

  /// What stands at the end (an act).
  final Widget? trailing;

  /// What a press does; null leaves the row still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final trailing = this.trailing;
    final onPressed = this.onPressed;
    // .suggest { gap: 12px; padding: 12px; border-radius: 14px; background:
    // radial-gradient(100% 120% at 0% 0%, var(--t2) 0%, transparent 80%),
    // rgba(255,255,255,.7); box-shadow: inset 0 0 0 1px var(--e) }
    // .suggest-i { 36px; border-radius: 11px; background: #fff; color:
    // var(--k); box-shadow: inset 0 0 0 1px var(--e) } .suggest-i .i { 18px }
    // .suggest .row-t { color: var(--k); font-weight: 600 }
    final face = FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(FrostedChromeMetrics.suggestRadius),
      color: t.glass.plane.withValues(alpha: _suggestFill),
      gradients: [
        _radial(hue.tintSolid, rx: 1, ry: 1.2, cx: 0, cy: 0, to: 0.8),
      ],
      ring: hue.edge,
      child: Padding(
        padding: const EdgeInsets.all(FrostedChromeMetrics.suggestInset),
        child: Row(
          spacing: FrostedChromeMetrics.suggestGap,
          children: [
            FrostedFace(
              material: FrostedMaterial.paint,
              radius: BorderRadius.circular(
                FrostedChromeMetrics.suggestMarkRadius,
              ),
              color: t.glass.plane,
              ring: hue.edge,
              child: SizedBox(
                width: FrostedChromeMetrics.suggestMark,
                height: FrostedChromeMetrics.suggestMark,
                child: Icon(
                  icon,
                  size: FrostedChromeMetrics.suggestMarkGlyph,
                  color: hue.ink,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostedChromeMetrics.rowLineGap,
                children: [
                  Text(
                    title,
                    style: t.textTheme.titleMedium.semibold.c(hue.ink),
                  ),
                  Text(subtitle, style: t.textTheme.bodyMedium.line(18.2)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
    if (onPressed == null) return face;
    return MergeSemantics(
      child: FrostedPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        radius: FrostedChromeMetrics.suggestRadius,
        child: face,
      ),
    );
  }
}

/// The 8 point unread dot (`.unread-dot`), the coral alone on the row's glass.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      label: FrostedLocalizations.of(context).unread,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.colorScheme.unreadDot,
        ),
        child: const SizedBox(
          width: FrostedChromeMetrics.unreadDot,
          height: FrostedChromeMetrics.unreadDot,
        ),
      ),
    );
  }
}

/// A notification in the list: its [lead] at the top start, its [title]
/// over its [body] (which wraps) and the caption saying [when], the unread
/// dot and the chevron centred at its end; 12 of room above and below, a
/// hairline between two in a [FrostedRowGroup] with `hairlines`. The whole
/// is one link when it [onPressed] opens what it is about.
///
/// ```dart
/// FrostedNote(lead: FrostedTransactionMark.income('Northwind Studio'), title: 'Paycheck landed', body: r'+$3,412.50 from Northwind Studio.', when: 'Fri, Oct 23 · 6:31 AM', onPressed: open)
/// ```
class FrostedNote extends StatelessWidget {
  /// A note: its [lead], [title] over [body], and [when].
  const FrostedNote({
    required this.lead,
    required this.title,
    required this.body,
    this.when,
    this.unread = false,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The mark at the note's start.
  final Widget lead;

  /// The note's head.
  final String title;

  /// The note's words.
  final String body;

  /// When it came, at the far end.
  final String? when;

  /// Whether it is new (a dot, its title heavier).
  final bool unread;

  /// What a press does; null leaves the note still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final when = this.when;
    final onPressed = this.onPressed;
    // .note-r { align-items: flex-start; padding: 12px 0; gap: 12px }
    // .note-r .note-b { white-space: normal } .note-r .cap { margin-top: 4px }
    // .note-r > .i { 16px; color: var(--ink-3); align-self: center }
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: FrostedChromeMetrics.noteInset,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostedChromeMetrics.noteGap,
          children: [
            Align(
              alignment: AlignmentDirectional.topCenter,
              widthFactor: 1,
              child: lead,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostedChromeMetrics.rowLineGap,
                children: [
                  Text(title, style: t.textTheme.titleMedium),
                  Text(body, style: t.textTheme.bodyMedium.line(18.2)),
                  // .note-r .cap { margin-top: 4px } on top of the
                  // words' own 1 (`.row-main { gap: 1px }`), on .cap's
                  // 15.6 line (12px/1.3).
                  if (when != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: FrostedChromeMetrics.noteWhenGap,
                      ),
                      child: Text(
                        when,
                        style: t.textTheme.labelMedium.line(15.6),
                      ),
                    ),
                ],
              ),
            ),
            if (unread) const Center(widthFactor: 1, child: _UnreadDot()),
            if (onPressed != null)
              Center(
                widthFactor: 1,
                child: Icon(
                  FrostedGlyphs.forward,
                  size: FrostedChromeMetrics.noteGlyph,
                  color: t.colorScheme.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
    return MergeSemantics(
      child: onPressed == null
          ? row
          : FrostedPressable(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: onPressed,
              role: FrostedPressRole.link,
              child: row,
            ),
    );
  }
}

/// What is new, in its own tile: the unread dot and the caption saying
/// [when] (New · Today · 9:00 AM), the large [mark] beside the [title] in
/// the display face over the [body], and the [action] as a link line at
/// the foot; the tile rimmed and washed in [hue] from its top start
/// corner, the whole a link when it [onPressed] opens what it is about.
///
/// ```dart
/// FrostedNoteHero(mark: const FrostedIconMark(FrostedGlyphs.receipt, size: FrostedMarkSize.large), when: 'New · Today · 9:00 AM', title: 'Rent is due in 4 days', body: r'$1,150.00 to Linden Court Apartments on Nov 1.', action: 'See your bills', onPressed: openBills)
/// ```
class FrostedNoteHero extends StatelessWidget {
  /// A note opened in full: its [mark], [title], [body] and [when].
  const FrostedNoteHero({
    required this.mark,
    required this.when,
    required this.title,
    required this.body,
    this.action,
    this.onPressed,
    this.hue,
    this.unread = true,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The mark over the title.
  final Widget mark;

  /// When it came.
  final String when;

  /// The note's head.
  final String title;

  /// The note's words.
  final String body;

  /// The link line at the foot.
  final String? action;

  /// What a press does; null leaves it still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The hue it is washed with.
  final FrostedHue? hue;

  /// Whether it is new.
  final bool unread;

  /// What a screen reader calls it.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final action = this.action;
    // .note-new { gap: 14px } .note-new-h { gap: 8px } .note-new-m {
    // align-items: flex-start; gap: 14px } .note-new-m .row-main { gap: 6px }
    // .note-new-t { font: 500 28px/1.1; letter-spacing: -.025em } .link {
    // gap: 2px; font: 500 14px/1; color: var(--ink-2) } .link .i { 16px }
    return FrostedCard.record(
      focusNode: focusNode,
      autofocus: autofocus,
      hue: hue,
      onPressed: onPressed,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FrostedChromeMetrics.noteNewGap,
        children: [
          Row(
            spacing: FrostedChromeMetrics.noteNewHeadGap,
            children: [
              if (unread) const _UnreadDot(),
              Expanded(child: Text(when, style: t.textTheme.labelMedium)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostedChromeMetrics.noteNewGap,
            children: [
              mark,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostedChromeMetrics.noteNewLineGap,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: t.textTheme.headlineMedium),
                    ),
                    Text(body, style: t.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (action != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _linkGap,
              children: [
                Flexible(child: Text(action, style: t.textTheme.link)),
                Icon(
                  FrostedGlyphs.forward,
                  size: FrostedIconSize.i16,
                  color: t.colorScheme.textTertiary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A line that nudges: a white round mark with the [icon] in the warm ink
/// before the [text], the line washed warm in its own ring; [ok] says all
/// is well in the green of money in instead. An [action] (a small button)
/// stands at the end.
///
/// ```dart
/// FrostedNudge(r'Add $110 to stay on track.', action: FrostedButton(r'Add $110', size: FrostedButtonSize.small, onPressed: add))
/// ```
///
/// ```dart
/// FrostedNudge(r'On track for next October at $100 a month.', ok: true)
/// ```
class FrostedNudge extends StatelessWidget {
  /// A nudge saying [text].
  const FrostedNudge(
    this.text, {
    this.icon,
    this.ok = false,
    this.action,
    super.key,
  });

  /// The nudge's words.
  final String text;

  /// The mark's glyph; null for the clock the source sets on its warning,
  /// or the check when [ok].
  final IconData? icon;

  /// Whether it is good news (the calm ink, not the warm one).
  final bool ok;

  /// An act at its end.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final action = this.action;
    final ink = ok ? t.colorScheme.moneyIn : t.colorScheme.warning;
    // .nudge { gap: 12px; padding: 10px 10px 10px 12px; border-radius: 14px;
    // background: rgba(236,170,80,.13); box-shadow: inset 0 0 0 1px
    // rgba(236,170,80,.26) } .nudge--ok { background: var(--in-t); box-shadow:
    // inset 0 0 0 1px rgba(64,168,116,.2) } .nudge-i { 28px round; #fff;
    // color: var(--warn) } .nudge-i .i { 16px } .nudge .sub { color: var(--ink) }
    const inset = FrostedChromeMetrics.nudgeInset;
    return FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(FrostedChromeMetrics.nudgeRadius),
      color: ok
          ? t.colorScheme.moneyInTint
          : t.colorScheme.warning.withValues(alpha: _nudgeFill),
      ring: ok
          ? t.colorScheme.moneyIn.withValues(alpha: _nudgeOkRing)
          : t.colorScheme.warning.withValues(alpha: _nudgeRing),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset.left,
          inset.top,
          inset.right,
          inset.bottom,
        ),
        child: Row(
          spacing: FrostedChromeMetrics.nudgeGap,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.glass.plane,
              ),
              child: SizedBox(
                width: FrostedChromeMetrics.nudgeMark,
                height: FrostedChromeMetrics.nudgeMark,
                child: Icon(
                  icon ?? (ok ? FrostedGlyphs.check : FrostedGlyphs.clock),
                  size: FrostedChromeMetrics.nudgeMarkGlyph,
                  color: ink,
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: t.textTheme.bodyMedium.c(t.colorScheme.textPrimary),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// A standing notice in the cold ink: a white round mark with the [icon]
/// before the [title] bold and the [body] wrapping under it, the whole
/// washed in the cold tint on white in the cold edge with the tile's lift
/// (a frozen card's).
///
/// ```dart
/// FrostedBanner(icon: FrostedGlyphs.snowflake, title: 'Your card is frozen', body: 'New purchases and cash withdrawals are declined.')
/// ```
class FrostedBanner extends StatelessWidget {
  /// A banner titled [title] over [body].
  const FrostedBanner({
    required this.icon,
    required this.title,
    required this.body,
    this.padding,
    super.key,
  });

  /// The glyph at its start.
  final IconData icon;

  /// The banner's head.
  final String title;

  /// The banner's words.
  final String body;

  /// The inset round the mark and the words; 14 16 when null. A page that
  /// sets its own (the Cards page's desktop banner, `.pg-cards .a-bn
  /// { padding: 14px 20px }`) hands it here.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .banner { align-items: flex-start; gap: 12px; padding: 14px 16px;
    // border-radius: var(--r-tile); background: linear-gradient(var(--cold-t),
    // var(--cold-t)), rgba(255,255,255,.86); box-shadow: inset 0 0 0 1px
    // var(--cold-e), var(--lift) } .banner-i { 36px round; #fff; color:
    // var(--cold) } .banner-i .i { 18px } .banner .row-t { font-weight: 600;
    // color: var(--cold) } .banner-s { white-space: normal; color: var(--ink) }
    return FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(FrostedBreakpoints.tileRadius(context)),
      color: t.glass.plane.withValues(alpha: _bannerFill),
      gradients: [
        LinearGradient(
          colors: [t.colorScheme.coldTint, t.colorScheme.coldTint],
        ),
      ],
      ring: t.colorScheme.coldEdge,
      shadows: t.shadows.tile,
      padding:
          padding?.resolve(Directionality.of(context)) ??
          FrostedChromeMetrics.bannerInset,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FrostedChromeMetrics.bannerGap,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.glass.plane,
            ),
            child: SizedBox(
              width: FrostedChromeMetrics.bannerMark,
              height: FrostedChromeMetrics.bannerMark,
              child: Icon(
                icon,
                size: FrostedChromeMetrics.bannerMarkGlyph,
                color: t.colorScheme.cold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedChromeMetrics.rowLineGap,
              children: [
                Text(
                  title,
                  style: t.textTheme.titleMedium.semibold.c(t.colorScheme.cold),
                ),
                Text(
                  body,
                  style: t.textTheme.bodyMedium
                      .c(t.colorScheme.textPrimary)
                      .line(18.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A category to browse: its token in [hue] beside its [title] over a
/// [subtitle] (its month's figure, in the display face's tabular figures), on a small card washed in the hue from its
/// top start corner; two stand across a line, 8 apart. The whole is a link
/// when it [onPressed] opens the category.
///
/// ```dart
/// FrostedBrowseCard(icon: FrostedGlyphs.house, hue: t.hues.periwinkle, title: 'Rent & home', subtitle: r'$1,150.00', onPressed: open)
/// ```
class FrostedBrowseCard extends StatelessWidget {
  /// A card to browse to, titled [title].
  const FrostedBrowseCard({
    required this.icon,
    required this.hue,
    required this.title,
    this.subtitle,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The glyph in its token.
  final IconData icon;

  /// The token's hue.
  final FrostedHue hue;

  /// The card's words.
  final String title;

  /// The quiet line under them.
  final String? subtitle;

  /// What a press does.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final subtitle = this.subtitle;
    final onPressed = this.onPressed;
    // .browse-c { gap: 10px; padding: 10px; border-radius: 12px; background:
    // radial-gradient(120% 100% at 0% 0%, var(--t) 0%, transparent 80%),
    // rgba(255,255,255,.5); box-shadow: inset 0 0 0 1px var(--e) } .browse-c
    // .tok { 32px; border-radius: 10px } .browse-c .row-t { font-size: 14px;
    // white-space: nowrap; text-overflow: ellipsis } .browse-c .row-s { 12px }
    final face = FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(FrostedChromeMetrics.browseRadius),
      color: t.glass.plane.withValues(alpha: _browseFill),
      gradients: [_radial(hue.tint, rx: 1.2, ry: 1, cx: 0, cy: 0, to: 0.8)],
      ring: hue.edge,
      child: Padding(
        padding: const EdgeInsets.all(FrostedChromeMetrics.browseInset),
        child: Row(
          spacing: FrostedChromeMetrics.browseGap,
          children: [
            FrostedIconMark(icon, hue: hue, size: FrostedMarkSize.small),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostedChromeMetrics.rowLineGap,
                children: [
                  // 14 on .row-t's 1.25: a 17.5 line, not the 20 of 16.
                  Text(
                    title,
                    style: t.textTheme.titleMedium.at(14).line(17.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // search.py browse_tile(): `.row-s` holds `num(usd())`,
                  // the figure in the display face, 500, tabular, -.005em
                  // (in the text face it stood 4-7 narrower).
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: t.textTheme.bodyMedium
                          .at(12)
                          .line(15.6)
                          .display
                          .medium
                          .tabular
                          .tracked(-0.005),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return MergeSemantics(
      child: onPressed == null
          ? face
          : FrostedPressable(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: onPressed,
              role: FrostedPressRole.link,
              radius: FrostedChromeMetrics.browseRadius,
              child: face,
            ),
    );
  }
}

/// One of Home's accounts: its token in [hue] with its [mask] at the end,
/// its [name] over its [kind], its [balance] in the small display face and
/// a [note] under (what moved this month), on a tile washed in the hue
/// from its top end corner; two stand across a line on a phone, four on
/// the desktop. The whole is a link when it [onPressed] opens the account.
///
/// ```dart
/// FrostedAccountCard(icon: FrostedGlyphs.wallet, hue: t.hues.cyan, name: 'Everyday', kind: 'Checking', mask: '•• 4821', balance: 6248.30, onPressed: open)
/// ```
class FrostedAccountCard extends StatelessWidget {
  /// A card for one account showing its [balance].
  const FrostedAccountCard({
    required this.icon,
    required this.hue,
    required this.name,
    required this.kind,
    required this.balance,
    this.mask,
    this.note,
    this.noteTone,
    this.flow = FrostedMoneyFlow.balance,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The glyph in its mark.
  final IconData icon;

  /// The card's hue.
  final FrostedHue hue;

  /// The account's name.
  final String name;

  /// What kind of account it is (Checking, Goal pot).
  final String kind;

  /// The account's balance.
  final num balance;

  /// The account's last digits, in the caption's figures.
  final String? mask;

  /// A line under the figure (interest this month).
  final String? note;

  /// The note's tone, set in the tone's ink (`.acct-note.in`: money in);
  /// null for the secondary ink.
  final FrostedTone? noteTone;

  /// Which way the balance's figure reads (in, out, neither).
  final FrostedMoneyFlow flow;

  /// What a press does; null leaves the card still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final mask = this.mask;
    final note = this.note;
    final noteTone = this.noteTone;
    // .acct { gap: 10px } .acct-h { justify-content: space-between } .acct-h
    // .cap { color: var(--ink-2) } .acct-n { font: 500 14px/1.2 } .acct .sub {
    // font-size: 12px; color: var(--ink-2) } .acct-note { font: 500 12px/1.3;
    // color: var(--ink-2); margin-top: 6px }
    return FrostedFacedCard(
      focusNode: focusNode,
      autofocus: autofocus,
      face: FrostedCardFace.account,
      hue: hue,
      onPressed: onPressed,
      label: onPressed == null ? null : '$name, $kind',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FrostedChromeMetrics.accountGap,
        children: [
          Row(
            spacing: FrostedSpacing.s8,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FrostedIconMark(icon, hue: hue),
                ),
              ),
              if (mask != null)
                FrostedNumberText(
                  mask,
                  style: t.textTheme.labelMedium.c(t.colorScheme.textSecondary),
                ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: t.textTheme.bodyMedium.medium
                    .c(t.colorScheme.textPrimary)
                    .line(16.8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                kind,
                // `.sub` 14/1.35 at 12 is a 16.2 line (`at` keeps the 19).
                style: t.textTheme.bodyMedium.at(12).line(16.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // `<div>{money}<p class="acct-note">`: the note is one item with
          // the figure, 6 under it, not a further 10 of the card's gap.
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FrostedMoney(balance, flow: flow, size: FrostedMoneySize.small),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: FrostedChromeMetrics.accountNoteGap,
                  ),
                  child: Text(
                    note,
                    style: t.textTheme.labelMedium.c(
                      noteTone == null
                          ? t.colorScheme.textSecondary
                          : t.toneInk(noteTone),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A bill's ticket: the payee's small monogram in [hue], its [title] over
/// its [subtitle] on one line each, and a [chip] in the hue's ink at the end
/// (Autopay with its check), on a white card in its own light ring with a
/// small shadow; a link when it [onPressed] opens the bill.
///
/// ```dart
/// FrostedTicket(name: 'Linden Court Apartments', title: 'Linden Court Apartments', subtitle: 'One payment from Everyday', hue: t.hues.periwinkle, chip: 'Autopay', chipIcon: FrostedGlyphs.check)
/// ```
class FrostedTicket extends StatelessWidget {
  /// A ticket titled [title] over [subtitle].
  const FrostedTicket({
    required this.name,
    required this.title,
    required this.subtitle,
    this.hue,
    this.chip,
    this.chipIcon,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Whose initials the monogram shows.
  final String name;

  /// The ticket's head.
  final String title;

  /// The quiet line under it.
  final String subtitle;

  /// The ticket's hue.
  final FrostedHue? hue;

  /// The chip's words at the end.
  final String? chip;

  /// The glyph in its chip.
  final IconData? chipIcon;

  /// What a press does; null leaves it still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final chip = this.chip;
    final onPressed = this.onPressed;
    // .ticket { gap: 10px; padding: 8px 12px 8px 8px; border-radius: 10px;
    // background: rgba(255,255,255,.58); box-shadow: inset 0 0 0 1px
    // rgba(255,255,255,.85), 0 6px 16px -12px rgba(52,41,114,.45) } .ticket
    // .mono { 32px; border-radius: 10px; font-size: 12px } .ticket-m { gap:
    // 2px } .ticket-t { font: 500 14px/1.25; ellipsis } .ticket-s { font: 400
    // 12px/1.25; color: var(--ink-2); nowrap }
    final face = FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(FrostedChromeMetrics.ticketRadius),
      color: t.glass.plane.withValues(alpha: _ticketFill),
      ring: t.glass.plane.withValues(alpha: _ticketRing),
      shadows: t.shadows.ticket,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          FrostedChromeMetrics.ticketInset,
          FrostedChromeMetrics.ticketInset,
          FrostedChromeMetrics.ticketInsetEnd,
          FrostedChromeMetrics.ticketInset,
        ),
        child: Row(
          spacing: FrostedChromeMetrics.ticketGap,
          children: [
            FrostedMonogram(name, hue: hue, size: FrostedMarkSize.small),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostedChromeMetrics.ticketLineGap,
                children: [
                  Text(
                    title,
                    style: t.textTheme.bodyMedium.medium
                        .c(t.colorScheme.textPrimary)
                        .line(17.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: t.textTheme.bodySmall
                        .c(t.colorScheme.textSecondary)
                        .line(15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (chip != null) _TicketChip(chip, icon: chipIcon, hue: hue),
          ],
        ),
      ),
    );
    return MergeSemantics(
      child: onPressed == null
          ? face
          : FrostedPressable(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: onPressed,
              role: FrostedPressRole.link,
              radius: FrostedChromeMetrics.ticketRadius,
              child: face,
            ),
    );
  }
}

/// The ticket's chip: the chip's pill on white .7 in the hue's ink and edge.
class _TicketChip extends StatelessWidget {
  const _TicketChip(this.label, {required this.icon, required this.hue});

  /// The chip's words.
  final String label;

  /// The chip's glyph.
  final IconData? icon;

  /// The chip's hue.
  final FrostedHue? hue;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final icon = this.icon;
    final ink = hue?.ink ?? t.colorScheme.textSecondary;
    // .chip { gap: 4px; height: 24px; padding: 0 10px; border-radius: 999px;
    // font: 500 12px/1; white-space: nowrap } .chip .i { 14px } .ticket .chip
    // { background: rgba(255,255,255,.7); color: var(--k); box-shadow: inset
    // 0 0 0 1px var(--e) }
    return FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(FrostedCorners.rFull),
      color: t.glass.plane.withValues(alpha: _ticketChipFill),
      ring: hue?.edge,
      child: SizedBox(
        height: FrostedChromeMetrics.chipHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedChromeMetrics.chipInset,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedChromeMetrics.chipGap,
            children: [
              if (icon != null)
                Icon(icon, size: FrostedChromeMetrics.chipGlyph, color: ink),
              Text(
                label,
                style: t.textTheme.labelSmall.c(ink),
                maxLines: 1,
                textScaler: TextScaler.noScaling,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
