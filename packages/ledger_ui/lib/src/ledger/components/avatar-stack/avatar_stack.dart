import 'package:flutter/widgets.dart';

import '../../format.dart';
import '../../theme.dart';

/// Several people as one line of marks: ink discs bearing their initials in
/// the italic serif, side by side a little apart as signatures stand on a
/// form (one never laid over another), then the rest as a count in the mono
/// ("+3"). Up to [max] show; [total] says how many there are when [names]
/// lists only the first few. It is one node for a screen reader: the first
/// names and how many more.
///
/// ```dart
/// LedgerAvatarStack(names: const ['Maren Holt', 'Jonas Ahn', 'Priya Rao', 'Lee Wong'], total: 9)
/// ```
class LedgerAvatarStack extends StatelessWidget {
  /// The people in [names] as one mark.
  const LedgerAvatarStack({
    required this.names,
    this.max = 4,
    this.total,
    this.size = 32,
    this.label,
    super.key,
  }) : assert(max > 0, 'a stack shows at least one');

  /// The people, in the order they stand.
  final List<String> names;

  /// The most discs shown before the count.
  final int max;

  /// How many people there are in all; null counts [names].
  final int? total;

  /// Each disc's width.
  final double size;

  /// Its name for a screen reader; null lists the first names.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final all = total ?? names.length;
    final shown = names.take(max).toList();
    final more = all - shown.length;
    final gap = size * _gap;
    return Semantics(
      label: label ?? _spoken(shown, more),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: [
          for (final name in shown)
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.avatar,
              ),
              child: Text(
                LedgerFormat.initials(name),
                maxLines: 1,
                softWrap: false,
                textScaler: TextScaler.noScaling,
                style: t.initials.sized(size * _initials).colored(t.onAvatar),
              ),
            ),
          if (more > 0)
            Padding(
              padding: EdgeInsetsDirectional.only(start: gap),
              // A count reads left to right in either direction: "+5".
              child: Text(
                '+$more',
                maxLines: 1,
                softWrap: false,
                textDirection: TextDirection.ltr,
                style: t.pill.sized(size * _count).colored(t.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  static String _spoken(List<String> shown, int more) {
    if (shown.isEmpty) return '';
    final lead = shown.take(3).toList();
    final rest = shown.length - lead.length + more;
    final list = lead.length == 1
        ? lead.first
        : '${lead.sublist(0, lead.length - 1).join(', ')} and ${lead.last}';
    return rest > 0 && lead.length == shown.length && more == 0
        ? list
        : rest > 0
        ? '${lead.join(', ')} and $rest more'
        : list;
  }

  // DERIVED (the source's avatar stands alone): the discs an eighth of one
  // apart (4 at 32), the count twice that after the last; the initials at
  // 38% of the disc, the count at 40% in the mono.
  static const double _gap = .125;
  static const double _initials = .38;
  static const double _count = .4;
}
