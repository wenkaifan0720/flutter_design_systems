/// The Overview: what Ledger is, in one sentence and one live record; the
/// app's screens; what the package holds; how to add it; then the index of
/// its parts.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';
import 'quill.dart';
import 'register.dart';
import 'words.dart';

class QuillOverview extends StatelessWidget {
  const QuillOverview({
    required this.onOpen,
    required this.onNewEntry,
    this.parts = const [],
    super.key,
  });

  final ValueChanged<QuillPage> onOpen;
  final VoidCallback onNewEntry;
  final List<QuillPart> parts;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final pitch = Text(
      context.say(
        'Ruled lines instead of boxes, the serif for money, small capitals '
        'for every label, and paper slips for the records that matter: '
        'an app set the way a ledger is.',
      ),
      style: wide ? t.title.sized(34).line(42) : t.title.sized(24).line(31),
    );
    final record = quillReceipt(context, kitBlueFern);
    final screens = LedgerSection(
      head: LedgerHead(
        context.say('Screens'),
        note: context.say('Quill, built on it'),
      ),
      child: LedgerRows(
        children: [
          LedgerSettingRow(
            title: context.say('Home'),
            subtitle: context.say(
              'The figure, the accounts, the last of the register',
            ),
            onTap: () => onOpen(QuillPage.home),
          ),
          LedgerSettingRow(
            title: context.say('Register'),
            subtitle: context.say(
              'Every entry by day, filtered; each opens its receipt',
            ),
            onTap: () => onOpen(QuillPage.register),
          ),
          LedgerSettingRow(
            title: context.say('New entry'),
            subtitle: context.say(
              'A form on the rule, checked as it is filled',
            ),
            onTap: onNewEntry,
          ),
          LedgerSettingRow(
            title: context.say('Settings'),
            subtitle: context.say(
              'Profile, alerts, preferences and the appearance',
            ),
            onTap: () => onOpen(QuillPage.settings),
          ),
        ],
      ),
    );
    final holds = LedgerSection(
      head: LedgerHead(context.say('In the package')),
      child: LedgerFacts(
        columns: LedgerFactColumns.pair,
        facts: [
          for (final (label, value, note) in const [
            (
              'Parts',
              'Fields to slips',
              'Forms, rows, the register, receipts, charts, navigation',
            ),
            (
              'Widths',
              '320 to 1440',
              'A tab bar, then a rail, then the side bar',
            ),
            ('Light and dark', 'Both', 'Or your own paper, ink and accent'),
            (
              'Access',
              '40 targets',
              'Spoken names, a double-ruled focus, text to 200%',
            ),
          ])
            LedgerFact(
              context.say(label),
              context.say(value),
              note: context.say(note),
            ),
        ],
      ),
    );
    final install = LedgerSection(
      head: LedgerHead(context.say('Add it')),
      // Printed on the slip's side room, as a receipt's words are.
      child: LedgerSlip(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerSpacing.s20,
          vertical: LedgerSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: LedgerSpacing.s8,
          children: [
            _code(t, 'flutter pub add ledger_ui'),
            _code(
              t,
              'builder: (context, child) =>\n'
              '    LedgerTheme(\n'
              '      data: LedgerThemeData.light(),\n'
              '      child: child!,\n'
              '    ),',
            ),
            Text(
              context.say(
                "In your app's builder, under a MaterialApp, a CupertinoApp or "
                'a WidgetsApp; then any part.',
              ),
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
    final own = LedgerSection(
      head: LedgerHead(context.say('Corners of its own')),
      child: LedgerSlip(
        style: _ticketSlip,
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerSpacing.s20,
          vertical: LedgerSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: LedgerSpacing.s16,
          children: [
            Text(
              context.say(
                'A part takes its own step at each corner from its style: '
                "this slip and its button cut two diagonal corners square, as "
                "a ticket's stub is. A corner takes square to extra large, or "
                'round.',
              ),
              style: t.body,
            ),
            LedgerButton(
              context.say('Print the receipt'),
              style: _ticketButton,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    final index = parts.isEmpty
        ? null
        : LedgerSection(
            head: LedgerHead(
              context.say('Every part'),
              note: '${parts.length} ${context.say('pages')}',
            ),
            child: LedgerRows(
              children: [
                for (final part in parts)
                  LedgerSettingRow(
                    title: part.title,
                    onTap: () => _openPart(context, part),
                  ),
              ],
            ),
          );
    const gap = LedgerGap(LedgerSpacing.s40);
    final Widget body;
    if (wide) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [pitch, gap, screens],
                ),
              ),
              const SizedBox(width: LedgerSpacing.s56),
              SizedBox(width: _recordWidth, child: record),
            ],
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: holds),
              const SizedBox(width: LedgerSpacing.s56),
              SizedBox(width: _recordWidth, child: install),
            ],
          ),
          gap,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(width: _recordWidth, child: own),
          ),
          if (index != null) ...[gap, index],
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pitch,
          const LedgerGap(LedgerSpacing.s28),
          record,
          gap,
          screens,
          gap,
          holds,
          gap,
          install,
          gap,
          own,
          if (index != null) ...[gap, index],
        ],
      );
    }
    return LedgerScreen(
      topBar: LedgerTopBar(
        title: context.say('Ledger'),
        meta: 'ledger_ui · Flutter',
      ),
      body: body,
    );
  }

  static const double _recordWidth = 400;

  // A ticket's stub: two diagonal corners square, the others an app's own.
  static const _ticketSlip = LedgerStyle(
    corners: WidgetStatePropertyAll(
      RawCorners(
        topStart: RawCorner.extraLarge,
        topEnd: RawCorner.none,
        bottomStart: RawCorner.none,
        bottomEnd: RawCorner.extraLarge,
      ),
    ),
  );

  // The button keeps its round ends where the slip keeps its corners.
  static const _ticketButton = LedgerStyle(
    corners: WidgetStatePropertyAll(
      RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none),
    ),
  );

  // Code reads left to right in any page and keeps its lines: too wide for
  // the slip (a large text), it sets smaller rather than break inside a
  // name or run past the slip's edge.
  static Widget _code(LedgerThemeData t, String code) => Directionality(
    textDirection: TextDirection.ltr,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        code,
        softWrap: false,
        style: t.meta.sized(13).colored(t.textPrimary),
      ),
    ),
  );

  void _openPart(BuildContext context, QuillPart part) {
    final brightness = context.ledgerTheme.brightness;
    // The part's page draws its own bar, with the way back, on this app's
    // host: what it raises covers the whole window.
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => part.build(brightness)));
  }
}
