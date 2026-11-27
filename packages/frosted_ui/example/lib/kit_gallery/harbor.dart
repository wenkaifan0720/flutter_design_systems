/// Harbor, the bank the look's pages are written for, as a small app: its
/// Activity and its Settings, live, on Frosted's own navigation (the
/// navigation bar on a phone, the sidebar from 1024), and one quiet way back
/// to the gallery. Every bar, card, field, menu and sheet in it is glass over
/// the theme's backdrop. It takes no router, so the package's example
/// carries it too.
library;

import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'arabic.dart';

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

/// Where Harbor opens.
enum HarborOpening {
  /// Activity, its list of transactions.
  activity,

  /// Activity with its first transaction open: in a sheet on a phone, in
  /// the detail pane from 1024.
  transaction,

  /// Settings.
  settings,
}

/// Harbor's app: its shell and its two screens.
class HarborApp extends StatefulWidget {
  /// Harbor, reaching the app around it through [host], open at [opening].
  const HarborApp({
    required this.host,
    this.opening = HarborOpening.activity,
    super.key,
  });

  /// The app around Harbor.
  final HarborHost host;

  /// Where Harbor opens.
  final HarborOpening opening;

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
    // A nested navigator: its own semantics container, as the gallery's
    // nested apps are (kit.dart's _kitApp).
    child: Semantics(
      container: true,
      child: Navigator(
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (_, _, _) => _HarborShell(widget.opening),
        ),
      ),
    ),
  );
}

/// Harbor's navigation and its two screens.
class _HarborShell extends StatefulWidget {
  const _HarborShell(this.opening);

  final HarborOpening opening;

  @override
  State<_HarborShell> createState() => _HarborShellState();
}

class _HarborShellState extends State<_HarborShell> {
  // In the shown language, so built each time.
  static List<FrostedNavItem> get _tabs => [
    FrostedNavItem(LucideIcons.receipt, kitSay('Activity')),
    FrostedNavItem(LucideIcons.settings, kitSay('Settings')),
  ];

  late int _tab = widget.opening == HarborOpening.settings ? 1 : 0;

  // Settings is built when first shown, not with Activity: opening Harbor
  // mounts only the screen it shows.
  late bool _settingsBuilt = _tab == 1;

  void _select(int i) => setState(() {
    _tab = i;
    if (i == 1) _settingsBuilt = true;
  });

  @override
  Widget build(BuildContext context) {
    // Each screen keeps its scroll and its state while the other shows.
    final screens = IndexedStack(
      index: _tab,
      children: [
        HarborActivity(opensFirst: widget.opening == HarborOpening.transaction),
        if (_settingsBuilt) const HarborSettings() else const SizedBox.shrink(),
      ],
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
              brand: kitSay('Harbor'),
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
      semanticLabel: t.isDark
          ? kitSay('Light appearance')
          : kitSay('Dark appearance'),
      onPressed: () =>
          host.onBrightness(t.isDark ? Brightness.light : Brightness.dark),
    ),
    FrostedIconButton(
      FrostedGlyphs.close,
      semanticLabel: kitSay('Back to the gallery'),
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
/// transaction in a sheet; from a tablet's width
/// ([FrostedBreakpoints.medium]) the chosen one stands in a detail pane
/// beside the list.
class HarborActivity extends StatefulWidget {
  /// Creates a [HarborActivity]; [opensFirst] opens its first transaction's
  /// sheet on a phone once it shows.
  const HarborActivity({this.opensFirst = false, super.key});

  /// Whether a phone opens the first transaction's sheet as it shows.
  final bool opensFirst;

  @override
  State<HarborActivity> createState() => _HarborActivityState();
}

class _HarborActivityState extends State<HarborActivity> {
  var _show = _Show.all;
  String _query = '';
  final _splits = ValueNotifier(<HarborTransaction, int>{});

  @override
  void dispose() {
    _splits.dispose();
    super.dispose();
  }

  HarborTransaction? _chosen = harborDays.first.rows.first;

  @override
  void initState() {
    super.initState();
    if (!widget.opensFirst) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !FrostedBreakpoints.isCompact(context)) return;
      _openSheet(context, harborDays.first.rows.first);
    });
  }

  bool _keeps(HarborTransaction tx) {
    final inFilter = switch (_show) {
      _Show.all => true,
      _Show.spending => !tx.isIncome,
      _Show.income => tx.isIncome,
      _Show.pending => tx.pending,
    };
    final query = _query.trim().toLowerCase();
    return inFilter &&
        (query.isEmpty ||
            [
              kitSay(tx.title),
              kitSay(tx.category),
              kitSay(tx.account),
              kitSay(tx.pending ? 'Pending' : 'Settled'),
              FrostedFormat.money(tx.amount),
            ].any((word) => word.toLowerCase().contains(query)));
  }

  String _splitSummary(HarborTransaction tx, int people) {
    final cents = (tx.amount.abs() * 100).round();
    final each = cents ~/ people, remainder = cents % people;
    final lower = FrostedFormat.money(each / 100);
    if (remainder == 0) return '$people × $lower';
    final upper = FrostedFormat.money((each + 1) / 100);
    return '$remainder × $upper + ${people - remainder} × $lower';
  }

  Future<void> _editSplit(BuildContext context, HarborTransaction tx) async {
    var people = _splits.value[tx] ?? 2;
    final save = await FrostedDialog.show(
      context,
      title: kitSay('Split transaction'),
      confirmLabel: kitSay('Save split'),
      cancelLabel: kitSay('Cancel'),
      content: StatefulBuilder(
        builder: (context, change) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              '${kitSay(tx.title)} · ${FrostedFormat.money(tx.amount.abs())}',
            ),
            FrostedNumberField(
              labelText: kitSay('People'),
              value: people,
              min: 2,
              max: 20,
              step: 1,
              unit: (_) => kitSay('people'),
              onChanged: (v) => change(() => people = v),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                _splitSummary(tx, people),
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted && save == true) _splits.value = {..._splits.value, tx: people};
  }

  Widget _detail(HarborTransaction tx) => ValueListenableBuilder(
    valueListenable: _splits,
    builder: (context, splits, child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        child!,
        if (splits[tx] case final int people)
          FrostedKeyValue(
            label: kitSay('Split'),
            value: _splitSummary(tx, people),
          ),
      ],
    ),
    child: HarborTransactionDetail(tx),
  );

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

  Widget _row(BuildContext context, HarborTransaction tx, bool panes) {
    final t = context.frostedTheme;
    return FrostedTransactionRow(
      mark: tx.isIncome
          ? FrostedTransactionMark.income(kitSay(tx.title))
          : FrostedTransactionMark.purchase(
              kitSay(tx.title),
              hue: _hue(t, tx.hue),
            ),
      title: kitSay(tx.title),
      subtitle: '${kitSay(tx.category)} · ${kitSay(tx.time)}',
      amount: tx.amount,
      pending: tx.pending,
      account: kitSay(tx.account),
      accountIcon: tx.account == 'Harbor Card'
          ? LucideIcons.creditCard
          : LucideIcons.wallet,
      onPressed: () =>
          panes ? setState(() => _chosen = tx) : _openSheet(context, tx),
    );
  }

  void _openSheet(BuildContext context, HarborTransaction tx) {
    FrostedSheet.show<void>(
      context,
      title: kitSay(tx.title),
      builder: (context) => [_detail(tx)],
      foot: (context) => [
        FrostedButton.glass(
          kitSay('Split'),
          icon: FrostedGlyphs.split,
          onPressed: () => _editSplit(context, tx),
        ),
        FrostedButton(
          kitSay('Done'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // From a tablet's width the list and the chosen transaction stand side
    // by side; on a phone a row opens its sheet.
    final panes = !FrostedBreakpoints.isCompact(context);
    final wide = FrostedBreakpoints.isWide(context);
    final days = [
      for (final day in harborDays)
        (label: day.label, rows: day.rows.where(_keeps).toList()),
    ].where((day) => day.rows.isNotEmpty).toList();
    final list = <Widget>[
      FrostedSearchField(
        hintText: kitSay('Search activity'),
        value: _query,
        onChanged: (value) => setState(() => _query = value),
      ),
      const SizedBox(height: 12),
      FrostedFilterChipGroup<_Show>(
        semanticLabel: kitSay('Show'),
        value: _show,
        onChanged: (v) => setState(() => _show = v),
        options: [
          FrostedFilterOption(_Show.all, kitSay('All')),
          FrostedFilterOption(_Show.spending, kitSay('Spending')),
          FrostedFilterOption(_Show.income, kitSay('Income')),
          FrostedFilterOption(_Show.pending, kitSay('Pending')),
        ],
      ),
      if (days.isEmpty)
        FrostedEmptyState(
          title: kitSay('No matching transactions'),
          body: kitSay('Try another merchant, category or account.'),
        ),
      for (final day in days) ...[
        const SizedBox(height: 20),
        FrostedListSection(
          title: kitSay(day.label),
          aside: kitTransactions(day.rows.length),
          rows: [for (final tx in day.rows) _row(context, tx, panes)],
        ),
      ],
    ];
    final bar = FrostedAppBar(
      title: kitSay('Activity'),
      caption: kitSay('October 2026'),
      actions: _barActs(context),
    );
    if (!panes) {
      return FrostedScaffold(
        topBar: bar,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: list,
        ),
      );
    }
    final chosen = _chosen != null && _keeps(_chosen!)
        ? _chosen
        : days.firstOrNull?.rows.first;
    return FrostedScaffold(
      topBar: bar,
      scroll: false,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          // The list scrolls within its column, but the chips' glow, the
          // search field's focus glow and the cards' shadows reach past the
          // column's sides and top: its viewport stands a strip's reach out
          // into the gutter, the gap and the room under the bar, so it clips
          // only what scrolls away.
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => OverflowBox(
                alignment: Alignment.bottomCenter,
                minWidth: box.maxWidth + 2 * FrostedChromeMetrics.stripReach,
                maxWidth: box.maxWidth + 2 * FrostedChromeMetrics.stripReach,
                minHeight: box.maxHeight + FrostedChromeMetrics.stripReach,
                maxHeight: box.maxHeight + FrostedChromeMetrics.stripReach,
                child: ListView(
                  // Under a tablet's tab bar, the band it stands in too.
                  padding: EdgeInsets.fromLTRB(
                    FrostedChromeMetrics.stripReach,
                    FrostedChromeMetrics.stripReach,
                    FrostedChromeMetrics.stripReach,
                    40 + ShellInsets.of(context),
                  ),
                  children: list,
                ),
              ),
            ),
          ),
          SizedBox(
            width: wide ? 380 : 300,
            child: chosen == null
                ? const SizedBox.shrink()
                : FrostedCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        FrostedCardHeader(kitSay(chosen.title)),
                        _detail(chosen),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: FrostedButton.glass(
                                kitSay('Split'),
                                icon: FrostedGlyphs.split,
                                expand: true,
                                onPressed: () => _editSplit(context, chosen),
                              ),
                            ),
                            Expanded(
                              child: FrostedButton.glass(
                                kitSay('Get help'),
                                expand: true,
                                onPressed: () => FrostedDialog.show(
                                  context,
                                  title: kitSay('Transaction help'),
                                  message: kitSay(
                                    'Check the merchant, date and amount in this transaction before contacting your bank.',
                                  ),
                                  confirmLabel: kitSay('Done'),
                                ),
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

/// The day [tx] is listed under, as its header reads ("Today", "Fri, Oct
/// 23"): the detail's When says its day, not only its month.
String _dayOf(HarborTransaction tx) => harborDays
    .firstWhere((day) => day.rows.contains(tx), orElse: () => harborDays.first)
    .label;

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
          caption: tx.isIncome ? kitSay('Received') : kitSay('Spent'),
          flow: tx.isIncome
              ? FrostedMoneyFlow.inflow
              : FrostedMoneyFlow.balance,
        ),
        FrostedKeyValue(label: kitSay('Category'), value: kitSay(tx.category)),
        FrostedKeyValue(label: kitSay('Account'), value: kitSay(tx.account)),
        FrostedKeyValue(
          label: kitSay('When'),
          value: '${kitSay(_dayOf(tx))} · ${kitSay(tx.time)}',
        ),
        FrostedKeyValue(
          label: kitSay('Status'),
          value: tx.pending ? kitSay('Pending') : kitSay('Settled'),
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
  int _monthlyLimit = 2500;

  Future<void> _editLimit() async {
    var draft = _monthlyLimit;
    final save = await FrostedDialog.show(
      context,
      title: kitSay('Monthly spending limit'),
      confirmLabel: kitSay('Save limit'),
      cancelLabel: kitSay('Cancel'),
      content: StatefulBuilder(
        builder: (context, change) => FrostedNumberField(
          labelText: kitSay('Limit in dollars'),
          value: draft,
          min: 0,
          step: 100,
          money: true,
          onChanged: (value) => change(() => draft = value),
        ),
      ),
    );
    if (mounted && save == true) setState(() => _monthlyLimit = draft);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final host = _HarborScope.of(context);
    return FrostedScaffold(
      topBar: FrostedAppBar(
        title: kitSay('Settings'),
        actions: _barActs(context),
      ),
      // The form stands on the title's keyline at its own most width: one
      // leading edge down the page.
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              FrostedSettingsGroup(
                title: kitSay('Notifications'),
                children: [
                  FrostedSwitchRow(
                    label: kitSay('Money in and out'),
                    note: kitSay('The moment it moves'),
                    value: _moves,
                    onChanged: (v) => setState(() => _moves = v),
                  ),
                  FrostedSwitchRow(
                    label: kitSay('Bills before they are due'),
                    note: kitSay('Three days ahead'),
                    value: _bills,
                    onChanged: (v) => setState(() => _bills = v),
                  ),
                  FrostedSwitchRow(
                    label: kitSay('Weekly summary'),
                    note: kitSay('Sunday evenings'),
                    value: _weekly,
                    onChanged: (v) => setState(() => _weekly = v),
                  ),
                ],
              ),
              FrostedSettingsGroup(
                title: kitSay('Security'),
                children: [
                  FrostedSwitchRow(
                    label: kitSay('Unlock with Face ID'),
                    value: _faceId,
                    onChanged: (v) => setState(() => _faceId = v),
                  ),
                  FrostedValueRow(
                    title: kitSay('Passcode'),
                    subtitle: kitSay('Changed in August'),
                    onPressed: () {},
                  ),
                  FrostedValueRow(
                    title: kitSay('Signed-in devices'),
                    value: '2',
                    onPressed: () {},
                  ),
                ],
              ),
              FrostedSettingsGroup(
                title: kitSay('Appearance'),
                children: [
                  FrostedFormRow(
                    label: kitSay('Theme'),
                    trailing: FrostedSegmentedButton<Brightness>(
                      label: kitSay('Theme'),
                      value: t.brightness,
                      onChanged: host.onBrightness,
                      segments: [
                        FrostedButtonSegment(Brightness.light, kitSay('Light')),
                        FrostedButtonSegment(Brightness.dark, kitSay('Dark')),
                      ],
                    ),
                  ),
                  // What the glass shows: the same control as the theme's,
                  // so the row keeps the group's height and trailing edge.
                  FrostedFormRow(
                    label: kitSay('Backdrop'),
                    trailing: FrostedSegmentedButton<FrostedBackdropKind>(
                      label: kitSay('Backdrop'),
                      value: t.backdrop.kind,
                      onChanged: host.onBackdrop,
                      segments: [
                        FrostedButtonSegment(
                          FrostedBackdropKind.dawn,
                          kitSay('Dawn'),
                        ),
                        FrostedButtonSegment(
                          FrostedBackdropKind.night,
                          kitSay('Night sky'),
                        ),
                        FrostedButtonSegment(
                          FrostedBackdropKind.plain,
                          kitSay('Plain'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              FrostedSettingsGroup(
                title: kitSay('Limits'),
                children: [
                  FrostedValueRow(
                    title: kitSay('Monthly spending limit'),
                    value: FrostedFormat.money(_monthlyLimit, cents: false),
                    onPressed: _editLimit,
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FrostedButton.glass(
                  kitSay('Close account'),
                  style: FrostedStyle(
                    foreground: WidgetStatePropertyAll(t.colorScheme.danger),
                  ),
                  onPressed: () => FrostedDialog.show(
                    context,
                    title: kitSay('Close your account?'),
                    message: kitSay(
                      'Your balance moves to the account you choose, and your cards stop working today.',
                    ),
                    confirmLabel: kitSay('Close account'),
                    cancelLabel: kitSay('Keep it'),
                    isDestructiveAction: true,
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
