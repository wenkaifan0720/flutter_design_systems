/// The Register: every entry by day under a search and a filter, the ones
/// saved in Quill with them; each opens its receipt. Words that match
/// nothing leave the empty state; a register that cannot load leaves the
/// error state and its Try again.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';
import 'quill.dart';
import 'words.dart';

/// An entry's receipt, as the register's record prints it, in Quill's
/// language.
Widget quillReceipt(BuildContext context, KitTx english) {
  final tx = context.sayTx(english);
  return LedgerReceipt(
    kind: context.say(tx.income ? 'Quill · Money in' : 'Quill · Entry'),
    number: '${context.say('No.')} ${tx.id.toUpperCase()}',
    leading: tx.icon != null
        ? LedgerGlyph(tx.icon!, size: LedgerGlyphSize.record)
        : LedgerMonogram(tx.title, size: LedgerMonogramSize.record),
    name: tx.title,
    subtitle: '${tx.subtitle} · ${tx.account}',
    figure: LedgerFigure(tx.amount, showSign: tx.income),
    seal: LedgerSeal(
      kicker: tx.account,
      value: context.say(
        tx.pending ? 'Pending' : (tx.income ? 'Received' : 'Posted'),
      ),
      foot: context.sayDate(tx.at),
      tone: tx.pending ? LedgerSealTone.plain : LedgerSealTone.success,
    ),
    details: [
      LedgerKeyValue(
        context.say('Status'),
        context.say(tx.pending ? 'Pending' : 'Posted'),
      ),
      LedgerKeyValue(context.say('Day'), '${tx.day}, ${tx.time}'),
      LedgerKeyValue(context.say('Account'), tx.account),
      LedgerKeyValue(context.say('Category'), tx.subtitle),
    ],
  );
}

const List<String> _filters = ['All', 'Money in', 'Money out', 'Pending'];

bool _shows(String filter, KitTx tx) => switch (filter) {
  'Money in' => tx.income,
  'Money out' => !tx.income && !tx.moved,
  'Pending' => tx.pending,
  _ => true,
};

/// Whether [tx] (in the words shown) holds every word of [query].
bool _matches(String query, KitTx tx) {
  final words = query.toLowerCase().split(RegExp(r'\s+'));
  final hay = '${tx.title} ${tx.subtitle} ${tx.account}'.toLowerCase();
  return words.every((w) => w.isEmpty || hay.contains(w));
}

class QuillRegister extends StatefulWidget {
  const QuillRegister({this.offline = false, this.initialQuery, super.key});

  /// Whether it opens unable to load, as a register out of reach does.
  final bool offline;

  /// The words it opens searching for, in English (said in the app's
  /// language); null: not searching.
  final String? initialQuery;

  @override
  State<QuillRegister> createState() => _QuillRegisterState();
}

class _QuillRegisterState extends State<QuillRegister> {
  String _filter = _filters.first;
  final _search = TextEditingController();
  late bool _offline = widget.offline;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    if (widget.initialQuery case final q?) _search.text = context.say(q);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(KitTx tx) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => QuillReceiptPage(tx: tx)));

  @override
  Widget build(BuildContext context) {
    if (!quillSignedIn(context)) {
      return QuillSignedOutPage(title: context.say('Register'));
    }
    final query = _search.text.trim();
    final held = quillDays(context);
    // What the register holds, counted from its days: the meta never names
    // more entries than a scroll reaches.
    final total = held.fold<int>(0, (n, d) => n + d.rows.length);
    final found = [
      for (final english in held)
        if (context.sayDay(english) case final d)
          if (d.rows
                  .where((tx) => _shows(_filter, tx) && _matches(query, tx))
                  .toList()
              case final rows when rows.isNotEmpty)
            (english, d, rows),
    ];
    final shown = found.fold<int>(0, (n, f) => n + f.$3.length);
    final days = [
      for (final (english, d, rows) in found)
        LedgerDayGroup(
          d.label,
          note: d.note,
          // A day's sum over the entries shown: a search's or a filter's.
          net: rows.length == d.rows.length
              ? d.net
              : rows.fold<double>(0, (sum, tx) => sum + tx.amount),
          rows: [
            for (final tx in rows)
              LedgerTransactionRow(
                title: tx.title,
                category: tx.subtitle,
                when: tx.time,
                account: tx.account,
                amount: tx.amount,
                initials: tx.lead,
                glyph: tx.icon,
                pending: tx.pending,
                pendingLabel: context.say('Pending'),
                onTap: () =>
                    _open(english.rows.firstWhere((e) => e.id == tx.id)),
              ),
          ],
        ),
    ];
    final Widget list;
    if (_offline) {
      list = LedgerErrorState(
        title: context.say('The register could not load'),
        message: context.say(
          'Quill could not reach your accounts. Your entries are safe.',
        ),
        onRetryPressed: () => setState(() => _offline = false),
      );
    } else if (days.isEmpty) {
      list = query.isNotEmpty
          ? LedgerEmptyState(
              title: context.say('Nothing found'),
              body: context.say(
                'No entry has these words. Try a payee or a category.',
              ),
            )
          : LedgerEmptyState(
              title: context.say('Nothing here'),
              body: context.say('No entry matches this filter.'),
            );
    } else {
      list = LedgerRegister(
        heads: [
          for (final h in const [
            'Time',
            'Payee',
            'Category',
            'Account',
            'Amount',
          ])
            context.say(h),
        ],
        children: days,
      );
    }
    final narrowed = query.isNotEmpty || _filter != _filters.first;
    final screen = LedgerScreen(
      topBar: LedgerTopBar(
        title: context.say('Register'),
        // Nothing counted when nothing loaded; a search or a filter counts
        // what it shows of what the register holds, from its first day.
        meta: _offline
            ? context.say('Not loaded')
            : narrowed
            ? (context.quillHebrew
                  ? '$shown מתוך $total'
                  : '$shown of $total entries')
            : '$total ${context.say('entries since')} '
                  '${context.sayDate(held.last.rows.last.at)}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nothing to search or filter in a register that did not load.
          if (!_offline) ...[
            LedgerSearchField(
              hint: context.say('Search entries'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              onCleared: () => setState(_search.clear),
            ),
            const LedgerGap(LedgerSpacing.s16),
            LedgerFilters(
              label: context.say('Show'),
              options: [for (final f in _filters) context.say(f)],
              value: context.say(_filter),
              onChanged: (f) => setState(
                () => _filter = _filters.firstWhere(
                  (e) => context.say(e) == f,
                  orElse: () => _filters.first,
                ),
              ),
            ),
            const LedgerGap(LedgerSpacing.s24),
          ],
          list,
        ],
      ),
    );
    // The Register's own search stands under its head, so the desk's
    // masthead carries no second one.
    final owner = LedgerAccountScope.maybeOf(context);
    if (owner == null) return screen;
    return LedgerAccountScope(
      account: LedgerAccount(
        name: owner.name,
        initials: owner.initials,
        meta: owner.meta,
        unread: owner.unread,
        onProfilePressed: owner.onProfilePressed,
        onNotificationsPressed: owner.onNotificationsPressed,
        profileLocation: owner.profileLocation,
        notificationsLocation: owner.notificationsLocation,
      ),
      child: screen,
    );
  }
}

/// One entry's record: its receipt at the slip's measure.
class QuillReceiptPage extends StatelessWidget {
  const QuillReceiptPage({required this.tx, super.key});

  final KitTx tx;

  @override
  Widget build(BuildContext context) => !quillSignedIn(context)
      ? QuillSignedOutPage(title: context.say('Register'))
      : LedgerScreen(
          topBar: LedgerTopBar(
            title: context.say(tx.title),
            meta: context.say(tx.day),
          ),
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _measure),
              child: quillReceipt(context, tx),
            ),
          ),
        );

  static const double _measure = 480;
}
