/// Read-only records drawn in the type and tokens of the rest: a timeline
/// of what happened ([ExpressiveTimeline]) and a list of terms and their
/// values ([ExpressiveDescriptionList]).
///
/// Material has neither as a component; each is drawn from the parts it
/// does have: the timeline a list whose leading slot is a marker on a
/// hairline, the description list a list section's rows in `labelLarge`
/// over `bodyLarge`. Neither takes a press, so neither has a state layer.
library;

import 'package:flutter/widgets.dart';

import '../shape.dart';
import '../spacing.dart';
import '../theme.dart';
import 'lists.dart';

/// One thing that happened, on an [ExpressiveTimeline].
class ExpressiveTimelineEntry {
  /// [title] at [time], with [description] under it.
  const ExpressiveTimelineEntry({
    required this.title,
    this.time,
    this.description,
    this.icon,
  });

  /// What happened, in `titleSmall`.
  final String title;

  /// When, in `labelMedium` `onSurfaceVariant` beside the title.
  final String? time;

  /// More about it, in `bodyMedium` `onSurfaceVariant`.
  final String? description;

  /// A glyph in the marker (one of `ExpressiveSymbols`); a dot when null.
  final IconData? icon;
}

/// What happened, in order: each entry a marker on a hairline that joins it
/// to the next, its title and time, and what more there is to say.
///
/// A dot (8dp, `outlineVariant`) or a glyph (24dp, on a
/// `secondaryContainer` circle) marks each entry; the [currentStep]'s marker
/// is drawn in `primary`. The hairline is `outlineVariant`. Entries are read
/// in order, each as one node.
///
/// ```dart
/// ExpressiveTimeline(currentStep: 1, entries: const [ExpressiveTimelineEntry(title: 'Order placed', time: '09:12'), ExpressiveTimelineEntry(title: 'Shipped', time: '14:40')])
/// ```
class ExpressiveTimeline extends StatelessWidget {
  /// A timeline of [entries], oldest first.
  const ExpressiveTimeline({
    required this.entries,
    this.currentStep,
    super.key,
  });

  /// What happened, in the order it is read.
  final List<ExpressiveTimelineEntry> entries;

  /// The index of the entry where things stand now, if any.
  final int? currentStep;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    const line = 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < entries.length; i++)
          MergeSemantics(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: ExpressiveSpacing.s24,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: ExpressiveSpacing.s24,
                          child: Center(
                            child: _marker(
                              context,
                              entries[i],
                              current: i == currentStep,
                            ),
                          ),
                        ),
                        if (i < entries.length - 1)
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                width: line,
                                child: ColoredBox(color: c.outlineVariant),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ExpressiveSpacing.s16),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < entries.length - 1
                            ? ExpressiveSpacing.s20
                            : 0,
                      ),
                      child: _text(context, entries[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _marker(
    BuildContext context,
    ExpressiveTimelineEntry entry, {
    required bool current,
  }) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final glyph = entry.icon;
    if (glyph == null) {
      return SizedBox.square(
        dimension: ExpressiveSpacing.s8,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: current ? c.primary : c.outlineVariant,
            shape: t.shapes.corner(ExpressiveCorner.full),
          ),
        ),
      );
    }
    return SizedBox.square(
      dimension: ExpressiveSpacing.s24,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: current ? c.primary : c.secondaryContainer,
          shape: t.shapes.corner(ExpressiveCorner.full),
        ),
        child: Center(
          child: ExcludeSemantics(
            child: Icon(
              glyph,
              size: ExpressiveSpacing.s16,
              color: current ? c.onPrimary : c.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(BuildContext context, ExpressiveTimelineEntry entry) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final time = entry.time;
    final description = entry.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: ExpressiveSpacing.s24,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.type.titleSmall.copyWith(color: c.onSurface),
                ),
              ),
              if (time != null) ...<Widget>[
                const SizedBox(width: ExpressiveSpacing.s8),
                Text(
                  time,
                  style: t.type.labelMedium.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        if (description != null)
          Text(
            description,
            style: t.type.bodyMedium.copyWith(color: c.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// One term and its value, in an [ExpressiveDescriptionList].
class ExpressiveDescriptionItem {
  /// [term] is [value].
  const ExpressiveDescriptionItem(this.term, this.value);

  /// What is described, in `labelLarge` `onSurfaceVariant`.
  final String term;

  /// What it is, in `bodyLarge` `onSurface`.
  final String value;
}

/// Terms and their values, a row each between hairline dividers: an
/// order's details, a file's properties.
///
/// From 600dp wide the term stands in a column of its own (a third of the
/// width) beside the value; narrower, the term stands over it. Each row is
/// read as one node, "term, value".
///
/// ```dart
/// ExpressiveDescriptionList(items: const [ExpressiveDescriptionItem('Order', '#4821'), ExpressiveDescriptionItem('Placed', '14 March')])
/// ```
class ExpressiveDescriptionList extends StatelessWidget {
  /// A list of [items].
  const ExpressiveDescriptionList({
    required this.items,
    this.dividers = true,
    super.key,
  });

  /// The terms and values, in order.
  final List<ExpressiveDescriptionItem> items;

  /// Whether hairlines stand between the rows.
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final termStyle = t.type.labelLarge.copyWith(color: c.onSurfaceVariant);
    final valueStyle = t.type.bodyLarge.copyWith(color: c.onSurface);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        Widget row(ExpressiveDescriptionItem item) => MergeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ExpressiveSpacing.s12,
            ),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: Text(item.term, style: termStyle)),
                      const SizedBox(width: ExpressiveSpacing.s16),
                      Expanded(
                        flex: 2,
                        child: Text(item.value, style: valueStyle),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item.term, style: termStyle),
                      const SizedBox(height: ExpressiveSpacing.s2),
                      Text(item.value, style: valueStyle),
                    ],
                  ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0 && dividers) const ExpressiveDivider(),
              row(items[i]),
            ],
          ],
        );
      },
    );
  }
}
