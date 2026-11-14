import 'package:flutter/widgets.dart';

import '../../format.dart';
import '../../internal/narrow.dart';
import '../../theme.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';
import '../structure/structure.dart';

/// Which of the desktop's columns a [LedgerRegister] keeps: all of them,
/// no account's (one account holds every row), no category's (a
/// category's own register), or neither.
enum LedgerRegisterColumns {
  /// Every column.
  full,

  /// No account column: one account holds every row.
  oneAccount,

  /// No category column: a category's own register.
  noCategory,

  /// Neither the account nor the category column.
  noCategoryOneAccount,
}

typedef _Widths = ({
  double when,
  double lead,
  double? category,
  double? account,
  double amount,
});

/// [w] in a [room] narrower than its columns: `.tx`'s fixed columns need
/// 760 with the day and time, which the source's 1024 to 1180 board lacks
/// (its grid spills to the right). Here the category and account columns
/// give way first, then the time's, never below [_cellMin], so the
/// merchant keeps [_nameMin] and the amount stands whole; a room wide
/// enough keeps [w] as it is.
_Widths _fit(_Widths w, double room) {
  final cells = [w.category, w.account].whereType<double>();
  final gaps = _cellGap * (3 + cells.length);
  final need =
      w.when + w.lead + cells.fold(0.0, (a, b) => a + b) + w.amount + gaps;
  var short = need + _nameMin - room;
  if (!room.isFinite || short <= 0) return w;
  double give(double? cell) {
    if (cell == null || short <= 0) return cell ?? 0;
    final take = (cell - _cellMin).clamp(0.0, short);
    short -= take;
    return cell - take;
  }

  final category = w.category == null ? null : give(w.category);
  final account = w.account == null ? null : give(w.account);
  final when = give(w.when);
  return (
    when: when,
    lead: w.lead,
    category: category,
    account: account,
    amount: w.amount,
  );
}

const double _cellGap = 16;
const double _cellMin = 72;
const double _nameMin = 120;

class _RegisterScope extends InheritedWidget {
  const _RegisterScope({
    required this.columns,
    required this.search,
    required this.dayAndTime,
    required this.dense,
    required super.child,
  });

  final LedgerRegisterColumns columns;
  final bool search;
  final bool dayAndTime;
  final bool dense;

  static _RegisterScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RegisterScope>();

  /// The desktop's columns, as `.tx` and its variants grid them.
  _Widths get widths {
    final cat =
        columns == LedgerRegisterColumns.full ||
        columns == LedgerRegisterColumns.oneAccount;
    final acct =
        columns == LedgerRegisterColumns.full ||
        columns == LedgerRegisterColumns.noCategory;
    final lead = dense ? 36.0 : 40.0;
    if (search) {
      return acct
          ? (when: 96, lead: lead, category: 112, account: 96, amount: 104)
          : (when: 96, lead: lead, category: 128, account: null, amount: 104);
    }
    return (
      when: dayAndTime ? 176 : 132,
      lead: lead,
      category: cat ? 200 : null,
      // A category's own register stands the account in the 200 column.
      account: acct ? (cat ? 132 : 200) : null,
      amount: 132,
    );
  }

  @override
  bool updateShouldNotify(_RegisterScope old) =>
      old.columns != columns ||
      old.search != search ||
      old.dayAndTime != dayAndTime ||
      old.dense != dense;
}

/// The register (`.register`): the transactions as a statement, its day
/// groups 20 apart (28 on the desktop), a month rule where it runs back
/// into an earlier month. On the desktop its rows stand in columns (time,
/// mark, merchant, category, account, amount, as [columns] keeps them)
/// under the column [heads] (their words, the mark's column left blank);
/// [searchResults] narrows the columns to the search's main column; [showDay]
/// widens the first for rows that carry their day (Home's recent
/// activity, with no day groups).
///
/// ```dart
/// LedgerRegister(heads: const ['Time', 'Merchant', 'Category', 'Account', 'Amount'], children: [for (final d in days) LedgerDayGroup(d.label, net: d.net, rows: d.rows)])
/// ```
class LedgerRegister extends StatelessWidget {
  /// A register of [children].
  const LedgerRegister({
    required this.children,
    this.columns = LedgerRegisterColumns.full,
    this.heads,
    this.searchResults = false,
    this.showDay = false,
    super.key,
  });

  /// Its day groups and month rules, or its rows ([showDay]).
  final List<Widget> children;

  /// Which of the desktop's columns stand.
  final LedgerRegisterColumns columns;

  /// The desktop's column heads, in order.
  final List<String>? heads;

  /// Whether it lists search results: the columns narrow to the search's main
  /// column.
  final bool searchResults;

  /// Whether each row carries its day, the first column widened (no day
  /// groups).
  final bool showDay;

  /// The least room its desktop columns stand in with the payee whole (a
  /// name and its tag, 200): under it, in a column beside another (Home's
  /// recent activity, a 1024 window's page), the register takes its phone
  /// form, as a receipt does, rather than cut every payee short.
  static const double _deskFrom = 720;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) =>
        LedgerLayout.isWide(context) && box.maxWidth < _deskFrom
        ? LedgerNarrowScope(child: Builder(builder: _build))
        : _build(context),
  );

  Widget _build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final scope = _RegisterScope(
      columns: columns,
      search: searchResults,
      dayAndTime: showDay,
      dense: false,
      child: const SizedBox.shrink(),
    );
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final c = children[i];
      if (i > 0) {
        if (c is LedgerDayGroup && children[i - 1] is LedgerDayGroup) {
          items.add(SizedBox(height: wide ? _groupGapWide : _groupGap));
        } else if (c is LedgerDayGroup && children[i - 1] is LedgerMonthRule) {
          items.add(const SizedBox(height: _monthAfter));
        } else if (c is LedgerMonthRule) {
          items.add(const SizedBox(height: _monthGap));
        } else if (showDay) {
          items.add(
            ColoredBox(color: t.hairline, child: const SizedBox(height: 1)),
          );
        }
      }
      items.add(c);
    }
    return _RegisterScope(
      columns: columns,
      search: searchResults,
      dayAndTime: showDay,
      dense: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide && heads != null) _ColumnHeads(heads!, scope.widths),
          ...items,
        ],
      ),
    );
  }

  // `.daygroup + .daygroup` 20 (28); `.month-rule` 28 over it,
  // `.month-rule + .daygroup` 4 under it.
  static const double _groupGap = 20;
  static const double _groupGapWide = 28;
  static const double _monthGap = 28;
  static const double _monthAfter = 4;
}

class _ColumnHeads extends StatelessWidget {
  const _ColumnHeads(this.words, this.widths);

  final List<String> words;
  final _Widths widths;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, room) => _heads(context, _fit(widths, room.maxWidth)),
  );

  Widget _heads(BuildContext context, _Widths widths) {
    final t = context.ledgerTheme;
    Text head(String w, {bool end = false}) => Text(
      w.toUpperCase(),
      maxLines: 1,
      softWrap: false,
      textAlign: end ? TextAlign.right : null,
      style: t.meta,
    );
    var i = 0;
    String next() => i < words.length ? words[i++] : '';
    final when = next(), name = next();
    final cat = widths.category == null ? null : next();
    final acct = widths.account == null ? null : next();
    final amount = next();
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        spacing: _gap,
        children: [
          SizedBox(width: widths.when, child: head(when)),
          // The heads' mark column is 36 wide in every register.
          const SizedBox(width: 36),
          Expanded(child: head(name)),
          if (cat != null) SizedBox(width: widths.category, child: head(cat)),
          if (acct != null) SizedBox(width: widths.account, child: head(acct)),
          SizedBox(width: widths.amount, child: head(amount, end: true)),
        ],
      ),
    );
  }

  static const double _gap = 16;
}

/// A day of the register (`.daygroup`): its head (the day in the capitals,
/// its date [note] for Today and Yesterday, its [net] at the end: what was
/// spent and received, moves between the owner's accounts left out) over
/// its [rows], denser than a page's rows (36 marks, 10 above and below).
///
/// ```dart
/// LedgerDayGroup('Today', note: 'Wed, Oct 28', net: -9.65, rows: [LedgerTransactionRow(title: 'Blue Fern Café', category: 'Dining out', when: '8:12 AM', account: 'Checking', amount: -9.65)])
/// ```
class LedgerDayGroup extends StatelessWidget {
  /// A day worded [label], its [net] over its [rows].
  const LedgerDayGroup(
    this.label, {
    required this.net,
    required this.rows,
    this.note,
    super.key,
  });

  /// The day, in the capitals (Today).
  final String label;

  /// The day's date, for Today and Yesterday.
  final String? note;

  /// What the day spent and received, moves left out.
  final num net;

  /// The day's transactions.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final outer = _RegisterScope.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    // `.dayhead-net .amt`: 12.5 (13) on the amount's own 20 px line
    // (`.amt`'s 14px/20px keeps its px).
    final base = t.amount.sized(wide ? _netWide : _net).line(_netLine);
    // `.dayhead-net` is a span in the body's 15/1.45 line: that strut, deeper
    // than the amount's, sets the head's height (21.75 of words, 41.75 in all
    // on a phone).
    final strut = StrutStyle.fromTextStyle(t.body);
    final parts = LedgerFormat.moneyParts(net, showSign: true);
    final moneyIn = net > 0;
    final netInk = moneyIn ? t.moneyIn : t.textSecondary;
    final netText = net == 0
        ? Text.rich(
            TextSpan(
              text: '\$0',
              children: [
                TextSpan(
                  text: '.00',
                  style: TextStyle(color: t.moveCents),
                ),
              ],
            ),
            strutStyle: strut,
            textDirection: TextDirection.ltr,
            style: base.copyWith(fontWeight: FontWeight.w400, color: t.move),
          )
        : Text.rich(
            TextSpan(
              text: '${parts.sign}\$${parts.whole}',
              children: [
                TextSpan(
                  text: '.${parts.cents}',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: moneyIn ? t.moneyInCents : t.textTertiary,
                  ),
                ),
              ],
            ),
            strutStyle: strut,
            textDirection: TextDirection.ltr,
            style: base.colored(netInk),
          );
    final head = Container(
      padding: EdgeInsets.only(
        top: wide ? _headTopWide : _headTop,
        bottom: wide ? _headFootWide : _headFoot,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: _headGap,
        children: [
          Semantics(
            header: true,
            child: Text(label.toUpperCase(), style: t.label),
          ),
          // The note gives way to the net on a narrow head; at a large text
          // size it wraps, whole.
          if (note case final words?)
            Expanded(
              child: Text(
                words.toUpperCase(),
                maxLines: larger ? null : 1,
                softWrap: larger,
                overflow: larger ? null : TextOverflow.ellipsis,
                style: t.meta,
              ),
            )
          else
            const Spacer(),
          Semantics(
            label: 'Net ${LedgerFormat.money(net, showSign: true)}',
            excludeSemantics: true,
            // The amounts hang at their column's right in either direction;
            // in a right-to-left register's columns the day's net stands
            // over them there, not at the row's far end.
            child: wide && outer != null && rtl
                ? SizedBox(
                    width: outer.widths.amount,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: netText,
                    ),
                  )
                : netText,
          ),
        ],
      ),
    );
    return _RegisterScope(
      columns: outer?.columns ?? LedgerRegisterColumns.full,
      search: outer?.search ?? false,
      dayAndTime: false,
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          LedgerRows(children: rows),
        ],
      ),
    );
  }

  // `.dayhead`: 10 0 9 (12 0 10), its parts 10 apart; the net 12.5 (13).
  static const double _headTop = 10;
  static const double _headFoot = 9;
  static const double _headTopWide = 12;
  static const double _headFootWide = 10;
  static const double _headGap = 10;
  static const double _net = 12.5;
  static const double _netWide = 13;
  static const double _netLine = 20;
}

/// One transaction in the register (`.tx`): its mark (the merchant's
/// monogram, green on its wash for money in, a dashed [glyph] for a move
/// between the owner's accounts), its [title] (a [pending] one tagged),
/// under it its [category] and [when], its signed amount at the end; on
/// the desktop in the register's columns, its [account] among them. One
/// link to its record; read as one line.
///
/// ```dart
/// LedgerTransactionRow(title: 'Blue Fern Café', category: 'Dining out', when: '8:12 AM', account: 'Keel Card', amount: -6.75, pending: true, onTap: () {})
/// ```
class LedgerTransactionRow extends StatelessWidget {
  /// A transaction: [title], [category], [when], [account] and [amount].
  const LedgerTransactionRow({
    required this.title,
    required this.category,
    required this.when,
    required this.account,
    required this.amount,
    this.initials,
    this.glyph,
    this.pending = false,
    this.pendingLabel = 'Pending',
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The merchant or the payer.
  final String title;

  /// The transaction's category.
  final String category;

  /// When it happened.
  final String when;

  /// The account it was on, in its column on the desktop.
  final String account;

  /// The amount, signed.
  final num amount;

  /// The monogram's letters, when not the title's own.
  final String? initials;

  /// A move's glyph (a transfer's arrows, a card's payment): drawn dashed,
  /// its amount quiet.
  final IconData? glyph;

  /// Whether it has not settled yet, tagged.
  final bool pending;

  /// The pending tag's words.
  final String pendingLabel;

  /// Opens the transaction's record.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final scope = _RegisterScope.of(context);
    final dense = scope?.dense ?? false;
    final moved = glyph != null;
    final lead = moved
        ? LedgerGlyph(
            glyph!,
            tone: LedgerGlyphTone.move,
            size: dense ? LedgerGlyphSize.dense : LedgerGlyphSize.row,
          )
        : LedgerMonogram(
            title,
            initials: initials,
            tone: amount > 0
                ? LedgerMonogramTone.moneyIn
                : LedgerMonogramTone.plain,
            size: dense ? LedgerMonogramSize.dense : LedgerMonogramSize.row,
          );
    // One line, as the source sets it; at a large text size the name wraps,
    // whole.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final name = ledgerTitle(
      context,
      title,
      tag: pending ? LedgerTag(pendingLabel) : null,
      maxLines: larger ? null : 1,
    );
    final figure = LedgerAmount.entry(
      amount,
      moved: moved,
      textAlign: TextAlign.right,
    );
    final side = t.bodySmall;
    final timeStyle = t.meta.sized(wide ? 12 : 11).line(18).tracked(0);
    final Widget row;
    if (wide) {
      final widths = (scope ?? _phoneScope).widths;
      final cells = side.sized(14).colored(t.textSecondary);
      row = Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 8 : 12),
        child: LayoutBuilder(
          builder: (context, room) {
            final w = _fit(widths, room.maxWidth);
            return Row(
              spacing: 16,
              children: [
                SizedBox(
                  width: w.when,
                  child: Text(
                    when,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: timeStyle,
                  ),
                ),
                SizedBox(
                  width: w.lead,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: lead,
                  ),
                ),
                Expanded(child: name),
                if (w.category != null)
                  SizedBox(
                    width: w.category,
                    child: Text(
                      category,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: cells,
                    ),
                  ),
                if (w.account != null)
                  SizedBox(
                    width: w.account,
                    child: Text(
                      account,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: cells,
                    ),
                  ),
                SizedBox(width: w.amount, child: figure),
              ],
            );
          },
        ),
      );
    } else {
      row = Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 10 : 14),
        child: Row(
          spacing: 14,
          children: [
            lead,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  name,
                  // `.tx-cat` and `.tx-when` are grid cells of one 18 row,
                  // top to top: on a shared baseline the mono's would stand
                  // 0.6 lower and the row 0.6 longer. `.tx-when` 14 after
                  // the category, pulled back 6; where the two do not fit
                  // one line (a large text size), the time turns under,
                  // whole.
                  Wrap(
                    spacing: 8,
                    children: [
                      Text(
                        category,
                        maxLines: larger ? null : 1,
                        overflow: larger ? null : TextOverflow.ellipsis,
                        style: side,
                      ),
                      Text(when, style: timeStyle),
                    ],
                  ),
                ],
              ),
            ),
            figure,
          ],
        ),
      );
    }
    final words = [
      title,
      if (pending) pendingLabel,
      category,
      when,
      if (wide) account,
      LedgerFormat.money(amount, showSign: true),
    ].join(', ');
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      role: LedgerPressRole.link,
      label: words,
      child: row,
    );
  }

  static const _phoneScope = _RegisterScope(
    columns: LedgerRegisterColumns.full,
    search: false,
    dayAndTime: false,
    dense: false,
    child: SizedBox.shrink(),
  );
}

/// The bills' list (`.ledger.bills`): its rows with the hairline between,
/// on the desktop under the column [heads] (due, payee, account, status,
/// amount).
///
/// ```dart
/// LedgerBillList(heads: const ['Due', 'Payee', 'Account', 'Status', 'Amount'], children: [LedgerBillRow(due: DateTime(2026, 11, 1), name: 'Rent', account: 'Checking', status: 'In 4 days', amount: 1850)])
/// ```
class LedgerBillList extends StatelessWidget {
  /// The bills' [children], under [heads] on the desktop.
  const LedgerBillList({required this.children, this.heads, super.key});

  /// The bills, usually [LedgerBillRow]s.
  final List<Widget> children;

  /// The desktop's column heads, in order.
  final List<String>? heads;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    Text head(String w, {bool end = false}) => Text(
      w.toUpperCase(),
      maxLines: 1,
      softWrap: false,
      textAlign: end ? TextAlign.right : null,
      style: t.meta,
    );
    final words = heads;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide && words != null && words.length == 5)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              spacing: LedgerBillRow._gapWide,
              children: [
                SizedBox(width: LedgerBillRow._whenWide, child: head(words[0])),
                Expanded(child: head(words[1])),
                SizedBox(
                  width: LedgerBillRow._accountWide,
                  child: head(words[2]),
                ),
                SizedBox(width: LedgerBillRow._dueWide, child: head(words[3])),
                SizedBox(
                  width: LedgerBillRow._amountWide,
                  child: head(words[4], end: true),
                ),
              ],
            ),
          ),
        LedgerRows(children: children),
      ],
    );
  }
}

/// A bill (`.billrow`): its due date as a date tab, the payee on the dot
/// leader to the amount, the account under the payee and its [status]
/// under the amount (green on autopay); on the desktop a statement line
/// with the account and the status in their columns. One link, read as
/// the payee, the amount and the date.
///
/// ```dart
/// LedgerBillRow(due: DateTime(2026, 11, 1), name: 'Rent', account: 'Everyday ··4821', status: 'In 4 days', amount: 1150, onTap: () {})
/// ```
class LedgerBillRow extends StatelessWidget {
  /// A bill to [name], [amount] due on [due].
  const LedgerBillRow({
    required this.due,
    required this.name,
    required this.account,
    required this.status,
    required this.amount,
    this.autopay = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The day it is due, shown as a date tab.
  final DateTime due;

  /// The payee.
  final String name;

  /// The account it is paid from.
  final String account;

  /// Its standing (In 4 days, Paid).
  final String status;

  /// The amount due.
  final num amount;

  /// Whether it is paid automatically; the status is green.
  final bool autopay;

  /// Opens the bill.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    // One line, as the source sets it; at a large text size the payee and
    // the account wrap, whole.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final title = Text(
      name,
      maxLines: larger ? null : 1,
      softWrap: larger,
      overflow: larger ? null : TextOverflow.ellipsis,
      style: t.rowTitle,
    );
    final figure = LedgerAmount(amount, textAlign: TextAlign.right);
    final side = t.bodySmall;
    final Widget row;
    if (wide) {
      final cells = side.sized(14).colored(t.textSecondary);
      row = Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          spacing: _gapWide,
          children: [
            SizedBox(
              width: _whenWide,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LedgerDateTab(due),
              ),
            ),
            Expanded(child: title),
            SizedBox(
              width: _accountWide,
              child: Text(account, maxLines: 1, softWrap: false, style: cells),
            ),
            SizedBox(
              width: _dueWide,
              child: Text(
                status,
                maxLines: 1,
                softWrap: false,
                style: cells.colored(autopay ? t.moneyIn : t.textSecondary),
              ),
            ),
            SizedBox(width: _amountWide, child: figure),
          ],
        ),
      );
    } else {
      row = Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          spacing: 14,
          children: [
            LedgerDateTab(due),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LedgerLeaderLine(
                    start: title,
                    end: figure,
                    minLength: _leaderMin,
                  ),
                  const SizedBox(height: 2),
                  if (larger)
                    Wrap(
                      spacing: 14,
                      children: [
                        Text(account, style: side),
                        Text(
                          status,
                          style: side.colored(
                            autopay ? t.moneyIn : t.textTertiary,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            account,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: side,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          status,
                          maxLines: 1,
                          softWrap: false,
                          style: side.colored(
                            autopay ? t.moneyIn : t.textTertiary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      role: LedgerPressRole.link,
      label: '$name, ${LedgerFormat.money(amount)}, ${LedgerFormat.date(due)}',
      child: row,
    );
  }

  // `.billrow`'s leader is at least 12 between its gaps, pulled 6 into
  // each (24 of dots at the least); the desktop's columns 44, the payee,
  // 220, 180 and 140, 16 apart.
  static const double _leaderMin = 24;
  static const double _gapWide = 16;
  static const double _whenWide = 44;
  static const double _accountWide = 220;
  static const double _dueWide = 180;
  static const double _amountWide = 140;
}
