/// The top bar in each register and the screen deriving its chrome from the
/// route live: push a page and its way back appears, raise it as a sheet
/// page and its close does. On a phone a [LedgerScreen] pins the bar's
/// frosted strip over the page and opens the page with the masthead (a
/// tab's date over its title); on the desktop the masthead heads every
/// page; a [LedgerTopBar.heading] (Spending's month bar) stands in a
/// masthead's title place. Its [LedgerTopBar] never authors a back or a
/// close.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitTopBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Top bar & screen',
  sections: [
    kitSection(
      'Derived by the route',
      children: [
        Builder(
          builder: (context) => kitRow([
            LedgerButton(
              'Push a page',
              size: LedgerButtonSize.small,
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const _Detail())),
            ),
            LedgerButton(
              'As a sheet page',
              size: LedgerButtonSize.small,
              onPressed: () => Navigator.of(context).push(
                LedgerSheet.pageRoute<void>(
                  context: context,
                  drawer: true,
                  builder: (_) => const _Detail(),
                ),
              ),
            ),
          ]),
        ),
      ],
    ),
    kitSection("A tab's bar", children: [kitSpecimenTopBarRoot()]),
    kitSection(
      'As a pushed page draws it',
      children: [kitSpecimenTopBarPushed()],
    ),
    kitSection(
      'As a sheet page draws it',
      children: [_sheetHead(const LedgerTopBar(title: 'Category'))],
    ),
    kitSection(
      "Home's masthead",
      children: [_phone(brightness, 420, kitSpecimenScreenHome())],
    ),
    kitSection(
      "Spending's masthead: a heading in the title's place",
      children: [_phone(brightness, 200, kitSpecimenScreenHeading())],
    ),
  ],
);

/// A phone's screen as a phone shows it: 390 wide from the column's start,
/// [height] of it, in a preview of its own (a window of its own: this page's
/// side bar or rail never reaches over it).
Widget _phone(Brightness brightness, double height, Widget screen) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ClipRect(
    child: SizedBox(
      width: 390,
      height: height,
      child: LedgerPreview(
        light: kitTheme(Brightness.light),
        dark: kitTheme(Brightness.dark),
        brightness: brightness,
        child: LedgerAccountScope(account: kitMaren, child: screen),
      ),
    ),
  ),
);

/// The card's details, pushed or raised (the Cards page raises them as a
/// sheet): the number, its note, and the one act at the page's foot.
class _Detail extends StatelessWidget {
  const _Detail();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerScreen(
      topBar: const LedgerTopBar(title: 'Card details', backLabel: 'Cards'),
      footer: Builder(
        builder: (context) => LedgerButton.filled(
          'Copy card number',
          icon: LucideIcons.copy,
          expand: true,
          onPressed: () => LedgerToast.show(
            context,
            'Card number copied',
            icon: LucideIcons.copy,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CARD NUMBER', style: t.label),
          const LedgerGap(LedgerSpacing.s8),
          Text('4242 4242 4242 7730', style: t.figureSmall),
          const LedgerGap(LedgerSpacing.s20),
          Text(
            'Only you can see this. It hides again when you close it.',
            style: t.bodySmall.colored(t.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A sheet page's [bar] on its card, as the sheet stands it: on the card,
/// in the card's room (the grip is the sheet route's own).
Widget _sheetHead(LedgerTopBar bar) => Builder(
  builder: (context) {
    final card = kitInRegister(
      RoutePresentation.sheet,
      LedgerSheetCard(
        child: Builder(
          builder: (context) =>
              Padding(padding: LedgerSheetShell.padding(context), child: bar),
        ),
      ),
    );
    // At desktop width a sheet page is raised a dialog's width: drawn in
    // place, it stands that wide from the column's start, as raised.
    return LedgerLayout.isWide(context)
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(width: LedgerSheet.dialogWidth(), child: card),
          )
        : card;
  },
);

/// Maren's accounts and their balances (the sample data).
const _accounts = <(String, num)>[
  ('Everyday', 6248.30),
  ('Savings', 21500.00),
  ('Lisbon fund', 2840.00),
  ('Keel Card', -1326.44),
  ('Investing', 48920.70),
];

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// A tab's frosted strip: the wordmark (the app's title), the bell wearing
/// its unread dot, and the avatar. Held a root's: a gallery page is pushed
/// in Quill, where the bar would otherwise draw the way back.
Widget kitSpecimenTopBarRoot() =>
    kitInRegister(RoutePresentation.root, const LedgerTopBar());

/// A pushed page's strip: the ringed way back, what the page is in the
/// serif, centred.
Widget kitSpecimenTopBarPushed() => kitInRegister(
  RoutePresentation.pushed,
  const LedgerTopBar(title: 'Account', backLabel: 'Home'),
);

/// Home's first screen: the strip over the masthead (the moment over the
/// greeting), the net worth, the accounts it sums with their dot leaders
/// and the double-ruled total, with the tab bar over the page's foot as the
/// shell lays it.
Widget kitSpecimenScreenHome() => Stack(
  fit: StackFit.expand,
  children: [
    LedgerScreen(
      topBar: LedgerTopBar(
        title: 'Good evening,',
        titleItalic: 'Maren',
        meta: LedgerFormat.nowLabel(kitNow),
      ),
      body: Builder(
        builder: (context) {
          final t = context.ledgerTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('NET WORTH', style: t.label),
              const LedgerFigure(78182.56, size: LedgerFigureSize.hero),
              const LedgerGap(LedgerSpacing.s32),
              Text('ACCOUNTS', style: t.label),
              const LedgerGap(LedgerSpacing.s4),
              for (final (name, balance) in _accounts)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: LedgerSpacing.s12,
                  ),
                  child: LedgerLeaderLine(
                    start: Text(name, style: t.rowTitle),
                    end: LedgerAmount(balance),
                  ),
                ),
              const LedgerStatementTotal(title: 'Net worth', amount: 78182.56),
            ],
          );
        },
      ),
    ),
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: LedgerNavBar(
        items: keelTabs,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
  ],
);

/// The transfer's review: the balances it leaves, and the act that sends it
/// in the footer band at the page's foot.
Widget kitSpecimenScreenFooter() => kitInRegister(
  RoutePresentation.pushed,
  LedgerScreen(
    topBar: const LedgerTopBar(title: 'Review', backLabel: 'Transfer'),
    footer: LedgerButton.filled(
      'Transfer ${LedgerFormat.money(500)}',
      expand: true,
      onPressed: () {},
    ),
    body: Builder(
      builder: (context) {
        final t = context.ledgerTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('AMOUNT', style: t.label),
            const LedgerFigure(500, size: LedgerFigureSize.receipt),
            const LedgerGap(LedgerSpacing.s32),
            Text('BALANCES AFTER', style: t.label),
            const LedgerGap(LedgerSpacing.s4),
            // the sample data's transfer example: 500 from Everyday to
            // Savings.
            for (final (name, after) in const <(String, num)>[
              ('Everyday', 5748.30),
              ('Savings', 22000.00),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: LedgerSpacing.s12,
                ),
                child: LedgerLeaderLine(
                  start: Text(name, style: t.rowTitle),
                  end: LedgerAmount(after),
                ),
              ),
          ],
        );
      },
    ),
  ),
);

/// Spending's masthead: its month bar standing in the title's place
/// ([LedgerTopBar.heading]), the way to earlier months, the month in the
/// serif with its year in the italic, and the way to the next, not yet
/// there.
Widget kitSpecimenScreenHeading() => LedgerScreen(
  topBar: LedgerTopBar(
    title: 'Spending',
    heading: Builder(
      builder: (context) {
        final t = context.ledgerTheme;
        final (name, year) = switch (kitSpentByMonth.first.$1.split(' ')) {
          [final n, final y] => (n, y),
          _ => (kitSpentByMonth.first.$1, ''),
        };
        final style = t.title;
        // As tall as its two ways, never the serif's taller line: they stand
        // on the bar's line with the desk search beside them.
        return SizedBox(
          height: LedgerIconButton.sideOf(t, LedgerIconButtonSize.medium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LedgerIconButton.outlined(
                LucideIcons.chevronLeft,
                semanticLabel: 'Earlier months',
                // The bar's own size, as its bell and desk search beside it.
                size: LedgerIconButtonSize.medium,
                onPressed: () {},
              ),
              // The bar keeps its height: at a large text size the month
              // sets smaller between its ways rather than run under them.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$name '),
                        TextSpan(text: year, style: style.italic),
                      ],
                    ),
                    style: style,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              const LedgerIconButton.outlined(
                LucideIcons.chevronRight,
                semanticLabel: 'Next month, not yet',
                size: LedgerIconButtonSize.medium,
                onPressed: null,
              ),
            ],
          ),
        );
      },
    ),
  ),
  body: const SizedBox.shrink(),
);
