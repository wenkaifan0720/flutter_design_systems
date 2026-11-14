/// Wayfinding between pages of one place: breadcrumbs (where a page sits in
/// a hierarchy) and pagination (which page of a long list is showing).
///
/// Material 3 has neither; both are built only from Expressive's own
/// buttons, the type scale, the spacing scale and the scheme's roles, so
/// their presses, focus rings and corners are the buttons' own.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../icons.dart';
import '../internal/tokens/behavior.g.dart' show ButtonBehavior;
import '../spacing.dart';
import '../strings.dart';
import '../theme.dart';
import 'buttons.dart';
import 'icon_buttons.dart';
import 'menus.dart';

/// One step of a breadcrumb trail: its [label], what a tap does
/// ([onPressed]; the current page's step takes none) and an optional
/// leading [icon].
@immutable
class ExpressiveBreadcrumbItem {
  /// A step labelled [label].
  const ExpressiveBreadcrumbItem(this.label, {this.onPressed, this.icon});

  /// The step's name: `Orders`.
  final String label;

  /// Goes to the step's page.
  final VoidCallback? onPressed;

  /// A glyph before the label (a home glyph on the root), or none.
  final IconData? icon;
}

/// The direction-aware chevron between steps (the glyph mirrors itself
/// right to left).
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Icon(
      ExpressiveSymbols.chevronRight,
      size: ExpressiveSpacing.s20,
      color: context.expressiveTheme.colors.onSurfaceVariant,
    ),
  );
}

/// Breadcrumbs: the path from the root to the current page, each ancestor
/// an extra-small text button (`labelLarge`, `primary`, its press, focus
/// ring and corners the button's own) and the current page plain
/// `labelLarge` in `onSurface`, announced as the current page. A
/// `chevron_right` in `onSurfaceVariant` stands between steps, mirrored
/// right to left. Past [maxShown] steps the middle folds into a
/// `more_horiz` icon button that opens a menu of the folded steps; where
/// the trail is wider than its room it folds further, down to the root,
/// the fold and the current page, and only then scrolls, the current page
/// kept in view. Material 3
/// has no breadcrumbs (web-first); this is drawn from its buttons.
///
/// ```dart
/// ExpressiveBreadcrumb(items: [ExpressiveBreadcrumbItem('Home', onPressed: goHome), ExpressiveBreadcrumbItem('Orders', onPressed: goOrders), ExpressiveBreadcrumbItem('#1042')])
/// ```
class ExpressiveBreadcrumb extends StatelessWidget {
  /// A trail of [items], root first, the current page last.
  const ExpressiveBreadcrumb({
    required this.items,
    this.maxShown = 4,
    this.semanticLabel,
    super.key,
  }) : assert(maxShown >= 3);

  /// The steps, root first; the last is the current page.
  final List<ExpressiveBreadcrumbItem> items;

  /// How many steps show before the middle folds into a menu (at least 3:
  /// the root, the fold and the current page).
  final int maxShown;

  /// What a screen reader calls the trail; `Breadcrumbs` when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final t = context.expressiveTheme;
    final strings = ExpressiveLocalizations.of(context);
    final last = items.length - 1;
    final scaler = MediaQuery.textScalerOf(context);
    double textWidth(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: t.type.labelLarge),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    // A step's width: its words, a glyph and its gap, and the extra-small
    // button's sides (an ancestor never under a button's least width).
    double stepWidth(ExpressiveBreadcrumbItem item, {required bool current}) {
      final content =
          textWidth(item.label) +
          (item.icon == null
              ? 0
              : ExpressiveSpacing.s20 + ExpressiveSpacing.s8) +
          ExpressiveSpacing.s24;
      return current ? content : math.max(ButtonBehavior.minWidth, content);
    }

    // Shown with [shown] steps: the root, the fold (when any step folds)
    // and the last shown − 2 steps.
    ({
      List<ExpressiveBreadcrumbItem> folded,
      List<ExpressiveBreadcrumbItem> tail,
    })
    fold(int shown) {
      if (items.length <= shown) {
        return (
          folded: const <ExpressiveBreadcrumbItem>[],
          tail: items.skip(1).toList(),
        );
      }
      return (
        folded: items.sublist(1, items.length - (shown - 2)),
        tail: items.sublist(items.length - (shown - 2)),
      );
    }

    double widthOf(int shown) {
      final f = fold(shown);
      var width = stepWidth(items.first, current: last == 0);
      if (f.folded.isNotEmpty) {
        width += ExpressiveSpacing.s20 + ExpressiveSpacing.s48;
      }
      for (final item in f.tail) {
        width +=
            ExpressiveSpacing.s20 +
            stepWidth(item, current: identical(item, items[last]));
      }
      return width;
    }

    Widget step(ExpressiveBreadcrumbItem item, {required bool current}) {
      if (!current) {
        return ExpressiveTextButton(
          item.label,
          icon: item.icon,
          size: ExpressiveButtonSize.extraSmall,
          onPressed: item.onPressed,
        );
      }
      final color = t.colors.onSurface;
      return Semantics(
        label: item.label,
        selected: true,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ExpressiveSpacing.s48),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: ExpressiveSpacing.s12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: ExpressiveSpacing.s8,
              children: <Widget>[
                if (item.icon case final icon?)
                  Icon(icon, size: ExpressiveSpacing.s20, color: color),
                Text(
                  item.label,
                  maxLines: 1,
                  style: t.type.labelLarge.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget more(List<ExpressiveBreadcrumbItem> folded) => Builder(
      builder: (context) => ExpressiveIconButton(
        ExpressiveSymbols.moreHoriz,
        size: ExpressiveIconButtonSize.extraSmall,
        semanticLabel: strings.moreBreadcrumbs,
        onPressed: () {
          final box = context.findRenderObject()! as RenderBox;
          showExpressiveMenu(
            context,
            anchor: box.localToGlobal(Offset.zero) & box.size,
            entries: <ExpressiveMenuEntry>[
              for (final item in folded)
                ExpressiveMenuItem(
                  item.label,
                  icon: item.icon,
                  onPressed: item.onPressed,
                ),
            ],
          );
        },
      ),
    );

    Widget trail(int shown) {
      final f = fold(shown);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          step(items.first, current: last == 0),
          if (f.folded.isNotEmpty) ...<Widget>[
            const _Chevron(),
            more(f.folded),
          ],
          for (final item in f.tail) ...<Widget>[
            const _Chevron(),
            step(item, current: identical(item, items[last])),
          ],
        ],
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel ?? strings.breadcrumbs,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The most steps that fit, no more than maxShown, no fewer than 3.
          var shown = math.min(maxShown, items.length);
          while (shown > 3 && widthOf(shown) > constraints.maxWidth) {
            shown--;
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: trail(shown),
          );
        },
      ),
    );
  }
}

/// Pagination: previous and next standard icon buttons (`chevron_left`,
/// `chevron_right`, mirrored right to left, disabled at either end) around
/// the pages — the current one an extra-small tonal button announced as
/// "Page 3 of 12", the others extra-small text buttons, the first and last
/// always shown and each run between folded into an ellipsis. Where that
/// row doesn't fit, "Page 3 of 12" in `bodyMedium` stands between the
/// arrows instead. Material 3 has no pagination (it scrolls); this is
/// drawn from its buttons, so every press, focus ring and corner is theirs.
///
/// ```dart
/// ExpressivePagination(page: page, count: 12, onChanged: (p) => setState(() => page = p))
/// ```
class ExpressivePagination extends StatelessWidget {
  /// Page [page] (1-based) of [count], [onChanged] with the page asked for.
  const ExpressivePagination({
    required this.page,
    required this.count,
    required this.onChanged,
    this.siblings = 1,
    this.semanticLabel,
    super.key,
  }) : assert(count >= 1),
       assert(page >= 1 && page <= count),
       assert(siblings >= 0);

  /// The current page, 1-based.
  final int page;

  /// How many pages there are.
  final int count;

  /// Called with the page to go to; the control shows [page] until it
  /// rebuilds with a new one.
  final ValueChanged<int> onChanged;

  /// How many pages show on each side of the current one.
  final int siblings;

  /// What a screen reader calls the control; `Pagination` when null.
  final String? semanticLabel;

  /// The pages shown, in order; null where a run is folded.
  List<int?> get pages {
    final shown = <int>{
      1,
      count,
      for (var p = page - siblings; p <= page + siblings; p++)
        if (p >= 1 && p <= count) p,
    };
    // A fold that would hide a single page shows that page instead.
    final sorted = shown.toList()..sort();
    final out = <int?>[];
    for (final p in sorted) {
      if (out.isNotEmpty && out.last != null) {
        final gap = p - out.last!;
        if (gap == 2) {
          out.add(p - 1);
        } else if (gap > 2) {
          out.add(null);
        }
      }
      out.add(p);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final strings = ExpressiveLocalizations.of(context);
    // The pages' 32dp height, so the row shows one height on hover and
    // press (its target stays 48dp). The chevrons mirror themselves right to
    // left.
    Widget arrow(IconData icon, String label, int to) => ExpressiveIconButton(
      icon,
      size: ExpressiveIconButtonSize.extraSmall,
      semanticLabel: label,
      onPressed: to < 1 || to > count ? null : () => onChanged(to),
    );
    final previous = arrow(
      ExpressiveSymbols.chevronLeft,
      strings.previousPage,
      page - 1,
    );
    final next = arrow(
      ExpressiveSymbols.chevronRight,
      strings.nextPage,
      page + 1,
    );
    final shown = pages;
    final ellipsis = ExcludeSemantics(
      child: SizedBox(
        width: ExpressiveSpacing.s24,
        child: Text(
          '…',
          textAlign: TextAlign.center,
          style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
        ),
      ),
    );

    Widget number(int p) {
      final label = '$p';
      final current = p == page;
      // The current page says so in its name ("Page 5 of 12"); the others
      // name the page they go to.
      return current
          ? ExpressiveFilledButton.tonal(
              label,
              size: ExpressiveButtonSize.extraSmall,
              semanticLabel: strings.pageOf(p, count),
              onPressed: () {},
            )
          : ExpressiveTextButton(
              label,
              size: ExpressiveButtonSize.extraSmall,
              semanticLabel: strings.goToPage(p),
              onPressed: () => onChanged(p),
            );
    }

    // 8dp between the parts (a button group's space at medium size): flush,
    // a focused page's ring (2dp out, 3dp thick) ran under the next page,
    // and the current page's tonal pill covered its edge.
    const gap = ExpressiveSpacing.s8;
    final full = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: <Widget>[
        previous,
        for (final p in shown) p == null ? ellipsis : number(p),
        next,
      ],
    );
    final compact = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        previous,
        Flexible(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: ExpressiveSpacing.s8,
            ),
            child: Text(
              strings.pageOf(page, count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.type.bodyMedium.copyWith(color: t.colors.onSurface),
            ),
          ),
        ),
        next,
      ],
    );
    // The row of pages when it fits (each page button its label plus the
    // extra-small button's sides, never under a button's 58dp least width;
    // each arrow 48dp, each ellipsis 24dp, the gaps, a margin for the
    // type's rounding); the page count otherwise.
    final labelStyle = t.type.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    double labelWidth(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final needed =
        ExpressiveSpacing.s48 * 2 +
        ExpressiveSpacing.s24 +
        gap * (shown.length + 1) +
        <double>[
          for (final p in shown)
            p == null
                ? ExpressiveSpacing.s24
                : math.max(
                    ButtonBehavior.minWidth,
                    labelWidth('$p') +
                        ButtonBehavior.extraSmallContentPaddingStart +
                        ButtonBehavior.extraSmallContentPaddingEnd,
                  ),
        ].fold(0.0, (a, b) => a + b);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel ?? strings.pagination,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            needed <= constraints.maxWidth ? full : compact,
      ),
    );
  }
}
