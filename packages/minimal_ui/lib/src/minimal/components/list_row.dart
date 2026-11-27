import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
import '../internal/row_trailing.dart';
import '../internal/trailing_glyph.dart';
import '../theme.dart';
import 'card.dart';
import 'pressable.dart';

/// The workhorse row: an 18 px glyph (or a [leading] tile or avatar), the
/// 14/500 title with an optional caption under it, then a [trailing]
/// accessory, a mono [meta] figure and an optional chevron — 44 px tall
/// ([dense]: 36), padded by the screen gutter so it runs edge to edge.
///
/// Rows never draw their own rules: a [MinimalListSection] divides them, full
/// bleed on the page or inset in a card. `selected: true` tints the row
/// with [MinimalThemeData.selection] (the open record, the current match) and
/// announces it; `selected: false` announces an unselected option of a set
/// (null, the default, is a row that is not one of a set). [muted]
/// quiets the title to the secondary ink (a done habit, an archived
/// record); [destructive] inks it in the destructive colour ("Delete habit"). With
/// [onTap] the whole row is one control with the press wash, Enter/Space
/// and a 2 px focus ring drawn INSIDE its edge — a full-bleed row has no
/// outside to draw on, and a card or a reveal clips it; `enabled: false`
/// dims it and swallows taps.
///
/// A control in the [leading] or [trailing] slot (a [MinimalStatusIcon] with
/// `onPressed:`, a [MinimalSwitch]) keeps its whole tap target: the row's
/// content line spans the row's full height and its gutters, so the
/// control's margin is never cut off by the row's padding.
///
/// The glyph or [leading] stands centred in a slot of one width, so the
/// title keeps its keyline whatever leads it: an 18 px glyph's slot unless
/// [leadingWidth] widens it. A list whose rows lead with different kinds (a
/// glyph, a tile, an avatar) gives every row the widest one's width.
///
/// [below] is a second line as widgets rather than words — a mono id and
/// label tags under an issue's title — in the caption register. [metaWidth]
/// stands [meta] in a fixed, end-aligned column so an accessory before it
/// ([MinimalWeekDots], a sparkline) lines up down the list whatever the figure
/// (`4d`, `12d`). At large text (from [MinimalChromeMetrics.rowStackScale])
/// the [trailing] part and [meta] drop under the title, as iOS stacks a
/// row's detail at its accessibility sizes.
///
/// ```dart
/// MinimalListTile(icon: LucideIcons.circleDashed, title: 'Drink water', meta: '10d', onTap: open)
/// ```
class MinimalListTile extends StatelessWidget {
  /// A list row titled [title].
  const MinimalListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.below,
    this.icon,
    this.iconColor,
    this.leading,
    this.leadingWidth,
    this.trailing,
    this.meta,
    this.metaWidth,
    this.metaLabel,
    this.onTap,
    this.chevron = false,
    this.destructive = false,
    this.selected,
    this.muted = false,
    this.dense = false,
    this.enabled = true,
    this.padding,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         icon == null || leading == null,
         'a row leads with a glyph or a leading widget, not both',
       );

  /// What the row is.
  final String title;

  /// One caption line under the title.
  final String? subtitle;

  /// A line of widgets under the title (and under [subtitle], when both are
  /// given): a mono id beside label tags. Text in it takes the caption
  /// register and one line.
  final Widget? below;

  /// The row's 18 px glyph, in the quiet ink unless [iconColor] says
  /// otherwise.
  final IconData? icon;

  /// Its glyph's ink; null takes the quiet ink.
  final Color? iconColor;

  /// A leading widget in place of [icon]: a [MinimalIconTile], a
  /// [MinimalAvatar], a status glyph.
  final Widget? leading;

  /// The width of the slot [icon] or [leading] stands centred in; a wider
  /// one keeps its own width. Null takes an 18 px glyph's, so a 16 px
  /// status or priority glyph puts its title where an 18 px glyph's
  /// stands. Rows that lead with a glyph, a [MinimalIconTile] (28) or a
  /// [MinimalAvatar] in one list take the widest one's, so their titles
  /// share one keyline.
  final double? leadingWidth;

  /// An accessory before [meta]: a tag, a toggle, a small chart, the
  /// row's menu key (a [MinimalMenu.button], ghost here).
  final Widget? trailing;

  /// The trailing figure, printed in mono in the quiet ink: `12d`, `09:30`,
  /// `€1,284`.
  final String? meta;

  /// A fixed width for [meta]'s column, end-aligned (a longer figure scales
  /// down to fit it), so what stands before it lines up from row to row;
  /// null prints the figure at its own width.
  final double? metaWidth;

  /// What a screen reader says for [meta] when the figure alone is terse:
  /// `12-day streak` for `12d`.
  final String? metaLabel;

  /// Opens the row, as Flutter's `ListTile.onTap`; null leaves it still.
  final VoidCallback? onTap;

  /// Show a chevron affordance (the row pushes a page).
  final bool chevron;

  /// Destructive row: the title and glyph in the destructive colour.
  final bool destructive;

  /// Whether this row is the highlighted one of a set: true tints it and
  /// announces selected, false announces an unselected option, null is a
  /// row that is not one of a set.
  final bool? selected;

  /// The title in the secondary ink: a record that is done or archived.
  final bool muted;

  /// The 36 px register for a dense list; a row that presses keeps the tap
  /// floor (40 at a finger) whatever the density.
  final bool dense;

  /// False dims the row and swallows taps (a record the user cannot open
  /// right now); announced as disabled.
  final bool enabled;

  /// The row's side padding. Null takes the group's, or on its own the
  /// card's row inset ([MinimalCard.rowInsetOf]) in a card and the screen
  /// gutter on the page.
  final EdgeInsetsGeometry? padding;

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final sub = subtitle;
    final below = this.below;
    final glyph = icon;
    final lead = leading;
    final meta = this.meta;
    final metaWidth = this.metaWidth;
    final chosen = selected ?? false;
    // On the selection wash the caption keeps its 4.5:1.
    final caption = chosen
        ? t.caption.c(
            RawPalette.readableTone(
              t.caption.color ?? t.mutedForeground,
              on: [t.selection],
            ),
          )
        : t.caption;
    final side =
        (padding ??
                _MinimalRowScope.maybeOf(context) ??
                MinimalCard.rowInsetOf(context) ??
                MinimalInsets.gutter)
            .resolve(Directionality.of(context));
    // The line's first child stands at the START edge: in a right-to-left
    // row that is the right-hand padding.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final start = rtl ? side.right : side.left;
    final end = rtl ? side.left : side.right;
    final titleColor = destructive
        ? t.destructiveInk
        : muted
        ? t.mutedForeground
        : t.foreground;
    // At large text what follows the title (its trailing part and meta)
    // drops under it.
    final part = trailing;
    // A menu key in the slot stands ghost (MinimalRowTrailing).
    final trail = part == null ? null : MinimalRowTrailing(child: part);
    final stacked =
        (trail != null || meta != null) &&
        MediaQuery.textScalerOf(context).scale(10) / 10 >=
            MinimalChromeMetrics.rowStackScale;
    final twoLines = sub != null || below != null || stacked;

    // The leading mark centred in a slot of one width, so the title's
    // keyline does not move with the mark's size.
    Widget slot(Widget mark) => ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: leadingWidth ?? MinimalIconSize.i18,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: mark),
    );

    // A cell of its own on the row's middle, by its capitals.
    final Widget? metaText = meta == null
        ? null
        : minimalCapLabel(
            Text(
              meta,
              style: t.mono.c(t.mutedForeground),
              maxLines: 1,
              semanticsLabel: metaLabel,
            ),
          );

    // The title and what stands under it.
    final Widget words = Padding(
      padding: EdgeInsets.symmetric(
        vertical: twoLines ? MinimalSpacing.s8 : MinimalSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A one-line row's title stands on the row's middle by
          // its capitals; over a subtitle it keeps its line.
          if (sub == null && below == null)
            minimalCapLabel(
              Text(
                title,
                style: t.body.medium.c(titleColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              title,
              style: t.body.medium.c(titleColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (sub != null) ...[
            const MinimalGap(MinimalSpacing.s2),
            Text(
              sub,
              style: caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (below != null) ...[
            const MinimalGap(MinimalSpacing.s4),
            DefaultTextStyle.merge(
              style: caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: below,
            ),
          ],
          if (stacked) ...[
            const MinimalGap(MinimalSpacing.s4),
            Wrap(
              spacing: _gap,
              runSpacing: MinimalSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [?trail, ?metaText],
            ),
          ],
        ],
      ),
    );

    // The trailing part on the line, held to two thirds of it (a long tag
    // ellipsizes, the title keeps a third); last in the row, a control stands
    // on the end keyline.
    final Widget? endPart = trail == null || stacked
        ? null
        : metaText == null
        ? MinimalTapAlignment(
            alignment: AlignmentDirectional.centerEnd,
            child: trail,
          )
        : trail;

    // The content line spans the row's whole box — its height and its side
    // padding — so a leading or trailing control's target stands inside it
    // rather than being cut off at a padded inner edge. The side
    // padding is therefore laid out as the line's own first and last gaps,
    // and the vertical breath belongs to the words alone.
    // The selection wash fades in and out (Minimal's short fade).
    final row = MinimalFace(
      decoration: BoxDecoration(
        color: chosen ? t.selection : t.selection.withValues(alpha: 0),
      ),
      builder: (context, _) => Container(
        constraints: BoxConstraints(
          // A row that presses stands at least the tap floor: a finger's
          // 40 whatever the density; the dense 36 holds for a pointer.
          minHeight: math.max(
            dense ? t.rowHeightCompact : t.rowHeight,
            onTap == null ? 0 : minimalTapFloor(context),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: start),
            if (glyph != null) ...[
              slot(
                MinimalIcon(
                  glyph,
                  color: destructive ? t.destructiveInk : iconColor,
                ),
              ),
              const MinimalGap(_gap),
            ] else if (lead != null) ...[
              slot(MinimalRowLeading(title: title, child: lead)),
              const MinimalGap(_gap),
            ],
            Expanded(
              child: endPart == null
                  ? words
                  : MinimalRowLine(title: words, end: endPart, gap: _gap),
            ),
            if (metaText != null && !stacked) ...[
              const MinimalGap(_gap),
              if (metaWidth == null)
                metaText
              else
                SizedBox(
                  width: metaWidth,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(fit: BoxFit.scaleDown, child: metaText),
                  ),
                ),
            ],
            if (chevron) ...[
              const MinimalGap(MinimalSpacing.s4),
              MinimalTrailingChevron(color: t.textTertiary),
            ],
            SizedBox(width: end),
          ],
        ),
      ),
    );

    if (onTap == null && enabled) {
      return selected == null
          ? row
          : Semantics(container: true, selected: selected, child: row);
    }
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onTap,
      enabled: enabled,
      // The row stands the tap floor itself, so it takes no tap target: one
      // would merge a control in its slots (a row's menu key) into the row's
      // node, and a screen reader could not reach the control alone.
      tapTarget: false,
      // Full-bleed: the wash runs square to the edges (a card clips it to
      // its own corners), and the keyboard's ring stands inside the edge,
      // where neither the neighbouring rows nor a card can cover it.
      radius: 0,
      focusInside: true,
      selected: selected,
      child: row,
    );
  }

  /// Air between the row's glyph, text and accessories.
  static const double _gap = MinimalChromeMetrics.rowIconGap;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(ColorProperty('iconColor', iconColor, defaultValue: null))
      ..add(DoubleProperty('leadingWidth', leadingWidth, defaultValue: null))
      ..add(StringProperty('meta', meta, defaultValue: null))
      ..add(DoubleProperty('metaWidth', metaWidth, defaultValue: null))
      ..add(StringProperty('metaLabel', metaLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(FlagProperty('chevron', value: chevron, ifTrue: 'chevron'))
      ..add(
        FlagProperty('destructive', value: destructive, ifTrue: 'destructive'),
      )
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(FlagProperty('muted', value: muted, ifTrue: 'muted'))
      ..add(FlagProperty('dense', value: dense, ifTrue: 'dense'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: null,
        ),
      )
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

/// A vertical group of [MinimalListTile]s divided by hairlines — Minimal's
/// list: no card around it, rules between the rows.
///
/// On the page (a full-bleed `MinimalScaffold(padding: EdgeInsets.zero)`) the
/// rows run edge to edge at the screen gutter, a rule between each two; in a
/// column narrower than the window (a laptop's measure) the rules stop on
/// the rows' keylines instead of running into the page's gutter. The last
/// row is left bare: what follows the list (the space before the next
/// section, a card's edge) closes it, and a hairline divides only where
/// space can't. `inset: true` stands the group in its own [MinimalCard]
/// instead: rows at the card's [MinimalCard.inset], the card's edge closing
/// it. A group placed in a [MinimalCard] by hand reads the card and takes
/// the same register, its rows padded only by what the card's own padding
/// leaves of the inset. The rules are drawn from the rows' laid-out
/// heights, so a [MinimalReveal] child that has folded away draws none, and
/// the last row still showing is the one left bare. `gutter: false` removes the gutter: the rows take no side padding of their own, so a
/// group standing in a padded page lines up with everything beside it.
///
/// Rule ownership: a [MinimalListTile] draws no rule of its own — put list
/// rows in a MinimalListSection and it draws them. Form and choice rows
/// ([MinimalFormRow], [MinimalInputRow], [MinimalSelect], [MinimalChoiceRow],
/// a compact [MinimalDatePicker], [MinimalProperty], [MinimalActivity]) rule
/// themselves and belong in a [MinimalFormSection], a [MinimalSelectionGroup]
/// or a property list, never in a row group, which would draw a second
/// hairline.
///
/// ```dart
/// MinimalListSection(children: [for (final h in habits) MinimalListTile(title: h.name, meta: '${h.streak}d')])
/// ```
class MinimalListSection extends StatelessWidget {
  /// A group of rows.
  const MinimalListSection({
    super.key,
    required this.children,
    this.divided = true,
    this.gutter = true,
    this.inset = false,
    this.style,
  });

  /// Its rows.
  final List<Widget> children;

  /// The card's style when [inset], over `components.listSection` (and
  /// then `components.card`): fill, edge or side, shape (else
  /// `shapes.medium`). Full bleed, the group has no frame to dress.
  final MinimalStyle? style;

  /// Hairlines between the rows.
  final bool divided;

  /// Pad the rows to the group's register (the screen gutter, or the
  /// card's inset); false leaves them at the edge of what holds them.
  final bool gutter;

  /// Stand the group in its own card rather than full bleed on the page.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    if (inset) {
      return MinimalCard(
        padding: EdgeInsets.zero,
        style: minimalLayered([
          style,
          context.minimalTheme.components.listSection,
        ]),
        child: _rows(context, inCard: true),
      );
    }
    // In a card the card is the keyline region; full bleed, the group is.
    if (MinimalCard.contains(context)) return _rows(context, inCard: true);
    return RawKeylineRegion(
      label: 'MinimalListSection',
      child: _rows(context, inCard: false),
    );
  }

  Widget _rows(BuildContext context, {required bool inCard}) {
    final t = context.minimalTheme;
    return _MinimalRowScope(
      padding: !gutter
          ? EdgeInsets.zero
          : inCard
          ? MinimalCard.rowInsetOf(context) ??
                const EdgeInsets.symmetric(horizontal: MinimalCard.inset)
          : MinimalInsets.gutter,
      child: divided
          ? _RuledColumn(
              rule: t.rule,
              // Full bleed, the rules run edge to edge only where the group
              // spans the window (a phone's page); in a narrower column (a
              // laptop's measure) they stop on the rows' keylines, with
              // everything else in the column.
              inset: !inCard && gutter ? MinimalChromeMetrics.gutter : 0,
              window: MediaQuery.sizeOf(context).width,
              children: children,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      )
      ..add(FlagProperty('divided', value: divided, ifFalse: 'divided: false'))
      ..add(FlagProperty('gutter', value: gutter, ifFalse: 'gutter: false'))
      ..add(FlagProperty('inset', value: inset, ifTrue: 'inset'));
  }
}

/// A stretched column that draws a hairline over the bottom edge of every
/// child with height — so a collapsed [MinimalReveal] (zero tall) draws
/// nothing — but the last child with height, which it leaves bare: what
/// follows the group (space, a card's own edge) closes it. "Last" is
/// decided when the rules are painted, from the children's laid-out sizes.
class _RuledColumn extends Flex {
  const _RuledColumn({
    required this.rule,
    required this.inset,
    required this.window,
    required super.children,
  }) : super(
         direction: Axis.vertical,
         crossAxisAlignment: CrossAxisAlignment.stretch,
       );

  final BorderSide rule;
  final double inset;
  final double window;

  @override
  RenderFlex createRenderObject(BuildContext context) => _RenderRuledColumn(
    rule: rule,
    inset: inset,
    window: window,
    direction: direction,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: getEffectiveTextDirection(context),
    verticalDirection: verticalDirection,
  );

  @override
  void updateRenderObject(BuildContext context, RenderFlex renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderRuledColumn)
      ..rule = rule
      ..inset = inset
      ..window = window;
  }
}

class _RenderRuledColumn extends RenderFlex {
  _RenderRuledColumn({
    required this._rule,
    required this._inset,
    required this._window,
    super.direction,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
  });

  BorderSide _rule;
  set rule(BorderSide value) {
    if (value == _rule) return;
    _rule = value;
    markNeedsPaint();
  }

  double _inset;
  set inset(double value) {
    if (value == _inset) return;
    _inset = value;
    markNeedsPaint();
  }

  double _window;
  set window(double value) {
    if (value == _window) return;
    _window = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final width = _rule.width;
    if (_rule.style == BorderStyle.none || width <= 0) return;
    RenderBox? bare;
    for (var c = lastChild; c != null; c = childBefore(c)) {
      if (c.size.height > width) {
        bare = c;
        break;
      }
    }
    final paint = Paint()..color = _rule.color;
    final side = size.width < _window - 0.5 ? _inset : 0.0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      if (c.size.height <= width || identical(c, bare)) continue;
      final at = offset + (c.parentData! as FlexParentData).offset;
      context.canvas.drawRect(
        Rect.fromLTWH(
          at.dx + side,
          at.dy + c.size.height - width,
          c.size.width - 2 * side,
          width,
        ),
        paint,
      );
    }
  }
}

/// The side padding a [MinimalListSection] hands its rows.
class _MinimalRowScope extends InheritedWidget {
  const _MinimalRowScope({required this.padding, required super.child});

  final EdgeInsets padding;

  static EdgeInsets? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MinimalRowScope>()?.padding;

  @override
  bool updateShouldNotify(_MinimalRowScope oldWidget) =>
      padding != oldWidget.padding;
}
