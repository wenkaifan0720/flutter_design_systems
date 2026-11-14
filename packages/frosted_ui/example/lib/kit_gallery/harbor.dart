/// Harbor, the bank the look's pages are written for, as a small app: its
/// Activity and its Settings, live, on Frosted's own navigation (the
/// navigation bar on a phone, the sidebar from 1024), and one quiet way back
/// to the gallery. Every bar, card, field, menu and sheet in it is glass over
/// the theme's backdrop. It takes no router, so the package's example
/// carries it too.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// What Harbor asks of the app around it: the backdrop and the appearance
/// to set, and the way back.
class HarborHost {
  /// Creates a [HarborHost].
  const HarborHost({
    required this.onBackdrop,
    required this.onBrightness,
    required this.onExit,
  });

  /// Sets the theme's backdrop.
  final ValueChanged<FrostedBackdropKind> onBackdrop;

  /// Sets light or dark.
  final ValueChanged<Brightness> onBrightness;

  /// Leaves Harbor for the gallery.
  final VoidCallback onExit;
}

/// Harbor's app: its shell and its two screens.
class HarborApp extends StatefulWidget {
  /// Harbor, reaching the app around it through [host].
  const HarborApp({required this.host, super.key});

  /// The app around Harbor.
  final HarborHost host;

  @override
  State<HarborApp> createState() => _HarborAppState();
}

class _HarborAppState extends State<HarborApp> {
  // A navigator of Harbor's own: its screens are first on it, so they keep
  // the bar's band clear (`ShellInsets` yields on a pushed page), and its
  // sheets and dialogs rise over its bar.
  @override
  Widget build(BuildContext context) => _HarborScope(
    host: widget.host,
    child: Navigator(
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (_, _, _) => const _HarborShell(),
      ),
    ),
  );
}

/// Harbor's navigation and its two screens.
class _HarborShell extends StatefulWidget {
  const _HarborShell();

  @override
  State<_HarborShell> createState() => _HarborShellState();
}

class _HarborShellState extends State<_HarborShell> {
  static const _tabs = [
    FrostedNavItem(LucideIcons.receipt, 'Activity'),
    FrostedNavItem(LucideIcons.settings, 'Settings'),
  ];

  int _tab = 0;

  void _select(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    // Each screen keeps its scroll and its state while the other shows.
    final screens = IndexedStack(
      index: _tab,
      children: const [HarborActivity(), HarborSettings()],
    );
    final Widget shell;
    if (FrostedBreakpoints.isWide(context)) {
      // The sidebar down the left edge, glass over the backdrop; the
      // screens stand right of it.
      shell = Stack(
        fit: StackFit.expand,
        children: [
          const FrostedBackdropView(),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: FrostedChromeMetrics.sideWidth,
            ),
            child: screens,
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: FrostedChromeMetrics.sideWidth,
            child: FrostedNavigationDrawer(
              items: _tabs,
              selectedIndex: _tab,
              onDestinationSelected: _select,
              brand: 'Harbor',
            ),
          ),
        ],
      );
    } else {
      // The bar at the foot, the screens running on under its glass with
      // the band it stands in reserved at their end.
      final band = FrostedNavigationBar.heightIn(
        MediaQuery.paddingOf(context).bottom,
      );
      shell = Stack(
        fit: StackFit.expand,
        children: [
          ShellInsets(bottomInset: band, child: screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FrostedNavigationBar(
              items: _tabs,
              selectedIndex: _tab,
              onDestinationSelected: _select,
            ),
          ),
        ],
      );
    }
    return shell;
  }
}

class _HarborScope extends InheritedWidget {
  const _HarborScope({required this.host, required super.child});

  final HarborHost host;

  static HarborHost of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_HarborScope>()!.host;

  @override
  bool updateShouldNotify(_HarborScope oldWidget) => false;
}

/// The two acts every Harbor bar carries: light or dark, and the way back
/// to the gallery.
List<Widget> _barActs(BuildContext context) {
  final t = context.frostedTheme;
  final host = _HarborScope.of(context);
  return [
    FrostedIconButton(
      t.isDark ? LucideIcons.sun : LucideIcons.moon,
      label: t.isDark ? 'Light appearance' : 'Dark appearance',
      onPressed: () =>
          host.onBrightness(t.isDark ? Brightness.light : Brightness.dark),
    ),
    FrostedIconButton(
      FrostedGlyphs.close,
      label: 'Back to the gallery',
      onPressed: host.onExit,
    ),
  ];
}

// --- Activity ----------------------------------------------------------------

/// One transaction of Harbor's.
@immutable
class HarborTransaction {
  /// Creates a [HarborTransaction].
  const HarborTransaction(
    this.title,
    this.category,
    this.time,
    this.amount, {
    this.hue = 'coral',
    this.pending = false,
    this.account = 'Harbor Card',
  });

  /// Who the money went to or came from.
  final String title;

  /// What it was for.
  final String category;

  /// When, on its day.
  final String time;

  /// How much; negative is money out.
  final double amount;

  /// The mark's hue, by name.
  final String hue;

  /// Whether it is still pending.
  final bool pending;

  /// The account it moved on.
  final String account;

  /// Whether it is money in.
  bool get isIncome => amount > 0;
}

/// A day of Harbor's activity.
typedef HarborDay = ({String label, List<HarborTransaction> rows});

/// Harbor's October, newest first.
const List<HarborDay> harborDays = [
  (
    label: 'Today',
    rows: [
      HarborTransaction(
        'Blue Fern Café',
        'Dining out',
        '8:12 AM',
        -6.75,
        pending: true,
      ),
      HarborTransaction(
        'Harbor Transit',
        'Transport',
        '7:48 AM',
        -2.90,
        hue: 'mint',
        pending: true,
        account: 'Everyday',
      ),
    ],
  ),
  (
    label: 'Fri, Oct 23',
    rows: [
      HarborTransaction(
        'Northwind Studio',
        'Paycheck',
        '6:31 AM',
        3412.50,
        account: 'Everyday',
      ),
      HarborTransaction(
        'Larder & Co.',
        'Groceries',
        '6:05 PM',
        -84.12,
        hue: 'apricot',
      ),
      HarborTransaction(
        'Cinema Lumen',
        'Going out',
        '9:40 PM',
        -24.00,
        hue: 'orchid',
      ),
    ],
  ),
  (
    label: 'Thu, Oct 22',
    rows: [
      HarborTransaction(
        'Pine Street Books',
        'Shopping',
        '1:15 PM',
        -32.40,
        hue: 'periwinkle',
      ),
      HarborTransaction(
        'Harbor Transit',
        'Transport',
        '8:02 AM',
        -2.90,
        hue: 'mint',
      ),
      HarborTransaction(
        'Maren Holt',
        'From a friend',
        '7:30 PM',
        45.00,
        account: 'Everyday',
      ),
    ],
  ),
  (
    label: 'Wed, Oct 21',
    rows: [
      HarborTransaction(
        'Gridline Energy',
        'Bills',
        '9:00 AM',
        -118.64,
        hue: 'lemon',
        account: 'Everyday',
      ),
      HarborTransaction('Blue Fern Café', 'Dining out', '8:20 AM', -5.25),
      HarborTransaction(
        'Tidewater Gym',
        'Health',
        '6:45 PM',
        -39.00,
        hue: 'teal',
      ),
    ],
  ),
  (
    label: 'Tue, Oct 20',
    rows: [
      HarborTransaction(
        'Larder & Co.',
        'Groceries',
        '5:52 PM',
        -61.37,
        hue: 'apricot',
      ),
      HarborTransaction(
        'Streamline',
        'Subscriptions',
        '12:00 AM',
        -11.99,
        hue: 'sky',
      ),
      HarborTransaction('Saltwater Ramen', 'Dining out', '8:10 PM', -28.60),
    ],
  ),
  (
    label: 'Mon, Oct 19',
    rows: [
      HarborTransaction(
        'Coastline Rail',
        'Travel',
        '7:15 AM',
        -46.00,
        hue: 'cyan',
      ),
      HarborTransaction(
        'Pine Street Books',
        'Shopping',
        '4:40 PM',
        -18.95,
        hue: 'periwinkle',
      ),
      HarborTransaction(
        'Interest',
        'Savings',
        '12:01 AM',
        4.12,
        account: 'Savings',
      ),
    ],
  ),
  (
    label: 'Sun, Oct 18',
    rows: [
      HarborTransaction(
        'Farmers Market',
        'Groceries',
        '10:30 AM',
        -22.50,
        hue: 'apricot',
      ),
      HarborTransaction(
        'Harbor Transit',
        'Transport',
        '9:12 AM',
        -2.90,
        hue: 'mint',
      ),
    ],
  ),
];

/// What the filter row offers.
enum _Show { all, spending, income, pending }

/// Harbor's Activity: the search, the filter row, and October's days, each
/// a section of glass holding its rows. On a phone a row opens its
/// transaction in a sheet; from 1024 the chosen one stands in a detail pane
/// beside the list.
class HarborActivity extends StatefulWidget {
  /// Creates a [HarborActivity].
  const HarborActivity({super.key});

  @override
  State<HarborActivity> createState() => _HarborActivityState();
}

class _HarborActivityState extends State<HarborActivity> {
  var _show = _Show.all;
  HarborTransaction? _chosen = harborDays.first.rows.first;

  bool _keeps(HarborTransaction tx) => switch (_show) {
    _Show.all => true,
    _Show.spending => !tx.isIncome,
    _Show.income => tx.isIncome,
    _Show.pending => tx.pending,
  };

  FrostedHue _hue(FrostedThemeData t, String name) => switch (name) {
    'mint' => t.hues.mint,
    'apricot' => t.hues.apricot,
    'orchid' => t.hues.orchid,
    'periwinkle' => t.hues.periwinkle,
    'lemon' => t.hues.lemon,
    'teal' => t.hues.teal,
    'sky' => t.hues.sky,
    'cyan' => t.hues.cyan,
    _ => t.hues.coral,
  };

  Widget _row(BuildContext context, HarborTransaction tx, bool wide) {
    final t = context.frostedTheme;
    return FrostedTransactionRow(
      mark: tx.isIncome
          ? FrostedTransactionMark.income(tx.title)
          : FrostedTransactionMark.purchase(tx.title, hue: _hue(t, tx.hue)),
      title: tx.title,
      subtitle: '${tx.category} · ${tx.time}',
      amount: tx.amount,
      pending: tx.pending,
      account: tx.account,
      accountIcon: tx.account == 'Harbor Card'
          ? LucideIcons.creditCard
          : LucideIcons.wallet,
      onPressed: () =>
          wide ? setState(() => _chosen = tx) : _openSheet(context, tx),
    );
  }

  void _openSheet(BuildContext context, HarborTransaction tx) {
    FrostedSheet.show<void>(
      context,
      title: tx.title,
      builder: (context) => [HarborTransactionDetail(tx)],
      foot: (context) => [
        FrostedButton.glass(
          'Split',
          icon: FrostedGlyphs.split,
          onPressed: () {},
        ),
        FrostedButton('Done', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = FrostedBreakpoints.isWide(context);
    final days = [
      for (final day in harborDays)
        (label: day.label, rows: day.rows.where(_keeps).toList()),
    ].where((day) => day.rows.isNotEmpty);
    final list = <Widget>[
      const FrostedSearchField(hint: 'Search activity'),
      const SizedBox(height: 12),
      FrostedFilterChipGroup<_Show>(
        label: 'Show',
        value: _show,
        onChanged: (v) => setState(() => _show = v),
        options: const [
          FrostedFilterOption(_Show.all, 'All'),
          FrostedFilterOption(_Show.spending, 'Spending'),
          FrostedFilterOption(_Show.income, 'Income'),
          FrostedFilterOption(_Show.pending, 'Pending'),
        ],
      ),
      for (final day in days) ...[
        const SizedBox(height: 20),
        FrostedListSection(
          title: day.label,
          aside:
              '${day.rows.length} '
              '${day.rows.length == 1 ? 'transaction' : 'transactions'}',
          rows: [for (final tx in day.rows) _row(context, tx, wide)],
        ),
      ],
    ];
    final bar = FrostedAppBar(
      title: 'Activity',
      caption: 'October 2026',
      actions: _barActs(context),
    );
    if (!wide) {
      return FrostedScaffold(
        topBar: bar,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: list,
        ),
      );
    }
    final chosen = _chosen;
    return FrostedScaffold(
      topBar: bar,
      scroll: false,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: list,
            ),
          ),
          SizedBox(
            width: 380,
            child: chosen == null
                ? const SizedBox.shrink()
                : FrostedCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        FrostedCardHeader(chosen.title),
                        HarborTransactionDetail(chosen),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: FrostedButton.glass(
                                'Split',
                                icon: FrostedGlyphs.split,
                                expand: true,
                                onPressed: () {},
                              ),
                            ),
                            Expanded(
                              child: FrostedButton.glass(
                                'Get help',
                                expand: true,
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One transaction at length: its figure, then what, where and when.
class HarborTransactionDetail extends StatelessWidget {
  /// The detail of [transaction].
  const HarborTransactionDetail(this.transaction, {super.key});

  /// What it shows.
  final HarborTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FrostedFigure(
          tx.amount.abs(),
          caption: tx.isIncome ? 'Received' : 'Spent',
          flow: tx.isIncome
              ? FrostedMoneyFlow.inflow
              : FrostedMoneyFlow.balance,
        ),
        FrostedKeyValue(label: 'Category', value: tx.category),
        FrostedKeyValue(label: 'Account', value: tx.account),
        FrostedKeyValue(label: 'When', value: 'October · ${tx.time}'),
        FrostedKeyValue(
          label: 'Status',
          value: tx.pending ? 'Pending' : 'Settled',
        ),
      ],
    );
  }
}

// --- Settings ----------------------------------------------------------------

/// Harbor's Settings: notifications, security, appearance (light or dark,
/// and the backdrop behind the glass), the monthly limit, and closing the
/// account, quiet at the end.
class HarborSettings extends StatefulWidget {
  /// Creates a [HarborSettings].
  const HarborSettings({super.key});

  @override
  State<HarborSettings> createState() => _HarborSettingsState();
}

class _HarborSettingsState extends State<HarborSettings> {
  var _moves = true;
  var _bills = true;
  var _weekly = false;
  var _faceId = true;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final host = _HarborScope.of(context);
    return FrostedScaffold(
      topBar: FrostedAppBar(title: 'Settings', actions: _barActs(context)),
      // The form stands on the title's keyline at its own most width: one
      // leading edge down the page (design6 P).
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              FrostedSettingsGroup(
                title: 'Notifications',
                children: [
                  FrostedSwitchRow(
                    label: 'Money in and out',
                    note: 'The moment it moves',
                    value: _moves,
                    onChanged: (v) => setState(() => _moves = v),
                  ),
                  FrostedSwitchRow(
                    label: 'Bills before they are due',
                    note: 'Three days ahead',
                    value: _bills,
                    onChanged: (v) => setState(() => _bills = v),
                  ),
                  FrostedSwitchRow(
                    label: 'Weekly summary',
                    note: 'Sunday evenings',
                    value: _weekly,
                    onChanged: (v) => setState(() => _weekly = v),
                  ),
                ],
              ),
              FrostedSettingsGroup(
                title: 'Security',
                children: [
                  FrostedSwitchRow(
                    label: 'Unlock with Face ID',
                    value: _faceId,
                    onChanged: (v) => setState(() => _faceId = v),
                  ),
                  FrostedValueRow(
                    title: 'Passcode',
                    subtitle: 'Changed in August',
                    onPressed: () {},
                  ),
                  FrostedValueRow(
                    title: 'Signed-in devices',
                    value: '2',
                    onPressed: () {},
                  ),
                ],
              ),
              FrostedSettingsGroup(
                title: 'Appearance',
                children: [
                  FrostedFormRow(
                    label: 'Theme',
                    trailing: FrostedSegmentedButton<Brightness>(
                      label: 'Theme',
                      value: t.brightness,
                      onChanged: host.onBrightness,
                      segments: const [
                        FrostedButtonSegment(Brightness.light, 'Light'),
                        FrostedButtonSegment(Brightness.dark, 'Dark'),
                      ],
                    ),
                  ),
                  // What the glass shows: the same control as the theme's,
                  // so the row keeps the group's height and trailing edge.
                  FrostedFormRow(
                    label: 'Backdrop',
                    trailing: FrostedSegmentedButton<FrostedBackdropKind>(
                      label: 'Backdrop',
                      value: t.backdrop.kind,
                      onChanged: host.onBackdrop,
                      segments: const [
                        FrostedButtonSegment(FrostedBackdropKind.dawn, 'Dawn'),
                        FrostedButtonSegment(
                          FrostedBackdropKind.night,
                          'Night sky',
                        ),
                        FrostedButtonSegment(
                          FrostedBackdropKind.plain,
                          'Plain',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              FrostedSettingsGroup(
                title: 'Limits',
                children: [
                  FrostedValueRow(
                    title: 'Monthly spending limit',
                    value: r'$2,500',
                    onPressed: () {},
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FrostedButton.glass(
                  'Close account',
                  style: FrostedStyle(
                    foreground: WidgetStatePropertyAll(t.colorScheme.danger),
                  ),
                  onPressed: () => FrostedDialog.show(
                    context,
                    title: 'Close your account?',
                    message:
                        'Your balance moves to the account you choose, and '
                        'your cards stop working today.',
                    confirmLabel: 'Close account',
                    cancelLabel: 'Keep it',
                    destructive: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
