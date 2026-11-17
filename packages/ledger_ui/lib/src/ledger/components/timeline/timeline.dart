/// What happened to a record, in order, as a ledger's margin keeps it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// Where a [LedgerTimelineEntry] stands: done, the one under way, or to
/// come.
enum LedgerTimelineState {
  /// It happened.
  done,

  /// It is under way.
  current,

  /// It is still to come.
  upcoming,
}

/// One entry of a [LedgerTimeline]: its [when] in the mono, its [title] and
/// its [note].
@immutable
class LedgerTimelineEntry {
  /// An entry titled [title].
  const LedgerTimelineEntry({
    required this.when,
    required this.title,
    this.note,
    this.state = LedgerTimelineState.done,
  });

  /// When, as printed (Oct 28 · 9:41).
  final String when;

  /// What happened.
  final String title;

  /// The line under it.
  final String? note;

  /// Done, under way or to come.
  final LedgerTimelineState state;
}

/// What happened to a record, in order (a transfer sent, cleared, posted):
/// a rule down the reading start with a mark at each entry, a disc of the
/// ink for one done, a ring of the ink for the one under way and a ring of
/// the light rule for one to come, the rule inked down to the one under way;
/// beside each mark its time in the mono capitals, its title in the medium
/// and its note in the second ink. A screen reader hears each entry whole,
/// with where it stands.
///
/// ```dart
/// LedgerTimeline(entries: const [LedgerTimelineEntry(when: 'Oct 26', title: 'Sent'), LedgerTimelineEntry(when: 'Oct 28', title: 'Cleared', state: LedgerTimelineState.current)])
/// ```
class LedgerTimeline extends StatelessWidget {
  /// [entries], oldest first.
  const LedgerTimeline({required this.entries, super.key});

  /// The entries, oldest first.
  final List<LedgerTimelineEntry> entries;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<LedgerTimelineEntry>('entries', entries));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in entries.indexed)
          Semantics(
            container: true,
            label: [
              e.title,
              e.when,
              ?e.note,
              switch (e.state) {
                LedgerTimelineState.done => 'done',
                LedgerTimelineState.current => 'under way',
                LedgerTimelineState.upcoming => 'to come',
              },
            ].join(', '),
            excludeSemantics: true,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: LedgerSpacing.s12,
                children: [
                  SizedBox(
                    width: _mark,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // The rule to the next mark, inked when this one is
                        // done.
                        if (i < entries.length - 1)
                          Positioned(
                            top: _markTop + _mark,
                            bottom: 0,
                            child: SizedBox(
                              width: e.state == LedgerTimelineState.done
                                  ? 2
                                  : 1,
                              child: ColoredBox(
                                color: e.state == LedgerTimelineState.done
                                    ? t.textPrimary
                                    : t.border,
                              ),
                            ),
                          ),
                        Positioned(
                          top: _markTop,
                          child: Container(
                            width: _mark,
                            height: _mark,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.state == LedgerTimelineState.done
                                  ? t.textPrimary
                                  : t.surface,
                              border: Border.all(
                                color: e.state == LedgerTimelineState.upcoming
                                    ? t.border
                                    : t.textPrimary,
                                width: e.state == LedgerTimelineState.current
                                    ? 2
                                    : 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < entries.length - 1 ? LedgerSpacing.s20 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: LedgerSpacing.s2,
                        children: [
                          Text(
                            e.when.toUpperCase(),
                            style: t.meta.colored(t.textTertiary),
                          ),
                          Text(
                            e.title,
                            style: t.rowTitle.colored(
                              e.state == LedgerTimelineState.upcoming
                                  ? t.textSecondary
                                  : t.textPrimary,
                            ),
                          ),
                          if (e.note case final n?)
                            Text(
                              n,
                              style: t.bodySmall.colored(t.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static const double _mark = 12;
  static const double _markTop = 3;
}
