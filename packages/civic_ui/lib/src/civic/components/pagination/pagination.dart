import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/link_target.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../link/link.dart';

/// The way through a long list a page at a time: "Previous page" and "Next
/// page" as links at either end, and the pages' numbers between them, each
/// a square link; the page shown is a square in the action colour, the
/// colour that marks where you are across the look, its number on it. Far pages fold into an ellipsis: the first and the last
/// always show, with the page shown and its neighbours, so the next number
/// is always there to press.
/// The previous link is left out on the first page, the next on the last.
///
/// It wraps rather than shrinks, so at twice the text the numbers move to
/// a line of their own. A screen reader hears each number as its place
/// ("3 of 12"), the page shown as selected.
///
/// Reads [CivicStyle]'s fill (the page shown's square), foreground (a
/// number, by state: selected, focused, disabled) and textStyle (the
/// numbers): its `style:`, then [CivicThemeData.paginationStyle]. The
/// previous and next links are [CivicLink]s and read
/// [CivicThemeData.linkStyle]; the focus plate is the look's.
///
/// ```dart
/// CivicPagination(
///   pageCount: 12,
///   selectedIndex: page,
///   onPageChanged: (index) => setState(() => page = index),
///   urlOf: (index) => Uri.parse('/streets?page=${index + 1}'),
/// )
/// ```
class CivicPagination extends StatelessWidget {
  /// Pages of a list.
  const CivicPagination({
    super.key,
    required this.pageCount,
    required this.selectedIndex,
    required this.onPageChanged,
    this.urlOf,
    this.previousLabel,
    this.nextLabel,
    this.style,
  }) : assert(pageCount > 0),
       assert(selectedIndex >= 0 && selectedIndex < pageCount);

  /// How many pages there are.
  final int pageCount;

  /// The page shown, from 0.
  final int selectedIndex;

  /// Called with a page's index, from 0, as it is chosen; null disables
  /// the pages.
  final ValueChanged<int>? onPageChanged;

  /// A page's address, by its index from 0 (`(i) =>
  /// Uri.parse('/streets?page=${i + 1}')`): with it, Previous, Next and
  /// the numbers are read as links to their pages ([CivicLink.url]);
  /// without it, as buttons that change the page in place.
  final Uri Function(int index)? urlOf;

  /// The previous link's words; null says "Previous page" in the reader's
  /// language.
  final String? previousLabel;

  /// The next link's words; null says "Next page" in the reader's
  /// language.
  final String? nextLabel;

  /// Overrides for the numbers' look.
  final CivicStyle? style;

  /// The pages to show, from 0, with null for a fold: the first, the last,
  /// [selected] and [around] pages either side of it.
  static List<int?> _pagesFor(int count, int selected, {int around = 1}) {
    final shown = <int>{
      0,
      count - 1,
      for (var i = selected - around; i <= selected + around; i++)
        if (i >= 0 && i < count) i,
    }.toList()..sort();
    final out = <int?>[];
    for (final (n, page) in shown.indexed) {
      if (n > 0) {
        final gap = page - shown[n - 1];
        // A fold over one page would hide what fits in its place.
        if (gap == 2) out.add(page - 1);
        if (gap > 2) out.add(null);
      }
      out.add(page);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final words = DesignLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final go = onPageChanged;
    Widget arrow(IconData icon) => Transform.flip(
      flipX: rtl,
      child: Icon(icon, size: _arrow, applyTextScaling: true),
    );
    final previous = selectedIndex > 0
        ? CivicLink.quiet(
            onPressed: go == null ? null : () => go(selectedIndex - 1),
            url: go == null ? null : urlOf?.call(selectedIndex - 1),
            textStyle: context.civicText.label.copyWith(color: t.action),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CivicSpacing.s4,
              children: [
                arrow(LucideIcons.chevronLeft),
                Text(previousLabel ?? words.previousPageTooltip),
              ],
            ),
          )
        : null;
    final next = selectedIndex < pageCount - 1
        ? CivicLink.quiet(
            onPressed: go == null ? null : () => go(selectedIndex + 1),
            url: go == null ? null : urlOf?.call(selectedIndex + 1),
            textStyle: context.civicText.label.copyWith(color: t.action),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CivicSpacing.s4,
              children: [
                Text(nextLabel ?? words.nextPageTooltip),
                arrow(LucideIcons.chevronRight),
              ],
            ),
          )
        : null;
    // A link keeps the focus bar's room under its words; as much over them
    // stands its words level with the numbers'.
    Widget level(Widget link) => Padding(
      padding: const EdgeInsets.only(top: CivicMetrics.bar),
      child: link,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: CivicSpacing.s8,
        runSpacing: CivicSpacing.s8,
        children: [
          if (previous != null) level(previous),
          for (final page in _pagesFor(pageCount, selectedIndex, around: 1))
            if (page == null)
              ExcludeSemantics(
                child: SizedBox(
                  width: CivicSpacing.s24,
                  child: Text(
                    '…',
                    textAlign: TextAlign.center,
                    style: context.civicText.label,
                  ),
                ),
              )
            else
              _PageNumber(
                number: page + 1,
                semanticLabel: words.positionLabel(page + 1, pageCount),
                selected: page == selectedIndex,
                onPressed: go == null ? null : () => go(page),
                url: urlOf?.call(page),
                style: style,
              ),
          if (next != null) level(next),
        ],
      ),
    );
  }

  static const double _arrow = 20;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pageCount', pageCount))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onPageChanged',
          onPageChanged,
        ),
      )
      ..add(StringProperty('previousLabel', previousLabel, defaultValue: null))
      ..add(StringProperty('nextLabel', nextLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// One page's number: a square link in the action colour, underlined; the
/// page shown is the ink square, its number in the page's colour, and no
/// link.
class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.number,
    required this.semanticLabel,
    required this.selected,
    required this.onPressed,
    required this.url,
    required this.style,
  });

  final int number;
  final String semanticLabel;
  final bool selected;
  final VoidCallback? onPressed;
  final Uri? url;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final styles = [style, t.paginationStyle];
    final text = context.civicText.copyWith(
      label: context.civicText.label.merge(
        DesignStyleOf(styles, const {}).textStyle,
      ),
    );
    Widget square({required Color fill, required Widget child}) => ColoredBox(
      color: fill,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: CivicMetrics.controlHeight,
          minHeight: CivicMetrics.controlHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CivicSpacing.s8),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
    if (selected) {
      // The page shown is where the reader is, not a way to go.
      final so = DesignStyleOf(styles, const {WidgetState.selected});
      return Semantics(
        label: semanticLabel,
        selected: true,
        excludeSemantics: true,
        child: square(
          fill: so.fill ?? t.action,
          child: Text(
            '$number',
            style: text.label.copyWith(color: so.foreground ?? t.onAction),
          ),
        ),
      );
    }
    final address = url;
    final pressed = onPressed;
    Widget face(VoidCallback? onPressed, {required bool link}) =>
        DesignTapTarget(
          child: DesignPressable(
            onPressed: onPressed,
            // A link to its page when it has an address; else a button.
            button: !link && onPressed != null,
            link: link,
            semanticLabel: semanticLabel,
            excludeSemantics: true,
            mouseCursor: onPressed == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            builder: (context, states, _) {
              final disabled = states.contains(WidgetState.disabled);
              return CivicSpringValue(
                value: states.contains(WidgetState.pressed) ? 1 : 0,
                spring: CivicMotion.press,
                builder: (context, press, _) => CivicSpringValue(
                  value: states.contains(WidgetState.focused) ? 1 : 0,
                  spring: CivicMotion.focus,
                  effects: true,
                  builder: (context, focus, _) {
                    final so = DesignStyleOf(styles, states);
                    final ink = disabled
                        ? so.foreground ?? t.textDisabled
                        : Color.lerp(
                            so.foreground ?? t.action,
                            t.onFocus,
                            focus,
                          )!;
                    return CustomPaint(
                      painter: CivicFacePainter(
                        fill: t.focus.withValues(alpha: 0),
                        edgeColor: t.onFocus,
                        edgeHeight: 0,
                        press: 0,
                        focus: focus,
                        focusColor: t.focus,
                        barColor: t.focusBar,
                      ),
                      child: square(
                        fill: t.focus.withValues(alpha: 0),
                        child: Text(
                          '$number',
                          style: text.label.copyWith(
                            color: ink,
                            decoration: disabled
                                ? TextDecoration.none
                                : TextDecoration.underline,
                            // Under the focus the ink bar is the one line:
                            // the underline fades as the plate comes, as a
                            // link's does.
                            decorationColor: disabled
                                ? ink
                                : Color.lerp(
                                    so.foreground ?? t.action,
                                    t.onFocus.withValues(alpha: 0),
                                    focus,
                                  ),
                            decorationThickness: 1.2 + 1.8 * press,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
    if (address == null || pressed == null) {
      return face(pressed, link: false);
    }
    return CivicLinkTarget(
      url: address,
      onPressed: pressed,
      builder: (context, press) => face(press, link: true),
    );
  }
}
