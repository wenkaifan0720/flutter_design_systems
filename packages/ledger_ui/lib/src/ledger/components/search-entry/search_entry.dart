import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../internal/cap_center.dart';
import '../../theme.dart';
import '../inputs/inputs.dart';
import '../pressable/pressable.dart';

/// The way into a search: the search field drawn as a link, its glyph and
/// [hint] in a round of the raised paper that opens the search page when
/// pressed ([onTap]), and with [onFilterPressed] a square beside it that opens
/// the filters, carrying the green count of those in force ([filterCount]). It
/// takes no words itself; the page it opens does. One a page, over its first
/// section. Says its [semanticLabel] (the placeholder by default) as a link,
/// and the filter by [filterLabel] and how many are in force.
///
/// ```dart
/// LedgerSearchEntry(hint: 'Search entries', onTap: () => open('/search'), onFilterPressed: openFilters, filterCount: 2)
/// ```
class LedgerSearchEntry extends StatelessWidget {
  /// The way into a search, worded [hint].
  const LedgerSearchEntry({
    required this.onTap,
    this.hint,
    this.semanticLabel,
    this.onFilterPressed,
    this.filterLabel = 'Filters',
    this.filterCount = 0,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Opens the search.
  final VoidCallback onTap;

  /// The words on the link (Search transactions); null is the shared words'
  /// Search, as on a [LedgerSearchField].
  final String? hint;

  /// What a screen reader says the link is; null says the [hint].
  final String? semanticLabel;

  /// Opens the filters; the square is left out without it.
  final VoidCallback? onFilterPressed;

  /// What a screen reader says the filter is.
  final String filterLabel;

  /// How many filters are in force; a green mark shows when above zero.
  final int filterCount;

  /// The entry's focus; null keeps one of its own. The caller disposes the
  /// node it gives.
  final FocusNode? focusNode;

  /// Whether the entry takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Row(
      spacing: _gap,
      children: [
        Expanded(
          child: LedgerSearchField(
            hint: hint,
            semanticLabel: semanticLabel,
            onTap: onTap,
            focusNode: focusNode,
            autofocus: autofocus,
          ),
        ),
        if (onFilterPressed != null)
          LedgerPressable(
            onTap: onFilterPressed,
            label: filterLabel,
            value: filterCount > 0 ? '$filterCount in force' : null,
            radius: t.controlRadius,
            child: SizedBox.square(
              dimension: LedgerChromeMetrics.searchHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(t.controlRadius),
                  border: Border.all(color: t.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      LucideIcons.slidersHorizontal,
                      size: LedgerChromeMetrics.searchGlyph,
                      color: t.textPrimary,
                    ),
                    if (filterCount > 0)
                      PositionedDirectional(
                        top: _markInset - _knock,
                        end: _markInset - _knock,
                        // Knocked out of the glyph by a ring of the paper:
                        // ink never lies over ink.
                        child: Container(
                          padding: const EdgeInsets.all(_knock),
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: BorderRadius.circular(_mark),
                          ),
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: _mark,
                              minHeight: _mark,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: t.accent,
                              borderRadius: BorderRadius.circular(_mark),
                            ),
                            child: ledgerCapCenter(
                              t.tag,
                              Text(
                                '$filterCount',
                                textScaler: TextScaler.noScaling,
                                style: t.tag.line(_mark).colored(t.onAccent),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // DERIVED: the filter square is the field's 46, 8 from it; its mark 16.
  static const double _gap = 8;
  static const double _mark = 16;
  static const double _markInset = 5;
  static const double _knock = 2;
}
