// The names the doc examples assume (an app's pages, its callbacks, its data and its controllers), so each example
// compiles as written and runs where it is a widget. A controller is made fresh where an example reads it and
// disposed when the test ends.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Takes what an example made where it is not a widget to show (a route, a call's result).
void show(Object? made) {}

/// An app's callback: fits a press, a tap and a change alike.
void open([Object? _]) {}

/// An app's callback.
void select([Object? _]) {}

/// An app's callback.
void add([Object? _]) {}

/// An app's callback.
void undo([Object? _]) {}

/// An app's callback.
void clear([Object? _]) {}

/// An app's callback.
void reload([Object? _]) {}

/// An app's callback.
void export([Object? _]) {}

/// An app's callback.
void delete([Object? _]) {}

/// An app's callback.
void pay([Object? _]) {}

/// An app's callback.
void send([Object? _]) {}

/// An app's callback.
void toggle([Object? _]) {}

/// An app's callback.
void pick([Object? _]) {}

/// An app's callback.
void setDue([Object? _]) {}

/// An app's callback.
void openFilters([Object? _]) {}

/// An app's fetch.
Future<void> fetch() async {}

/// A State's setState, outside a State.
void setState(VoidCallback change) => change();

/// The theme an example reads.
LedgerThemeData get t => LedgerThemeData.light();

/// A part's style and its states.
const LedgerStyle style = LedgerStyle();

/// The states a style resolves for.
const Set<WidgetState> states = {};

/// Whether the app is by lamplight.
const bool night = false;

/// A route to push.
Route<void> get route =>
    PageRouteBuilder<void>(pageBuilder: (_, _, _) => const SizedBox());

/// A font's bytes.
Future<ByteData> get bytes async => ByteData(0);

/// An app's widgets where an example takes one.
const Widget page = SizedBox();

/// An app's widget.
const Widget child = SizedBox();

/// An app's widget.
const Widget app = SizedBox();

/// An app's widget.
const Widget goals = SizedBox();

/// An app's widget.
const Widget save = SizedBox();

/// An app's widget.
const Widget form = SizedBox();

/// An app's widget.
const Widget amount = SizedBox();

/// An app's widget.
const Widget from = SizedBox();

/// An app's widget.
const Widget row = SizedBox(height: 44);

/// An app's widget.
const Widget memo = SizedBox();

/// An app's widget.
const Widget options = SizedBox();

/// An app's widget.
const Widget filters = SizedBox();

/// An app's widget.
const Widget range = SizedBox();

/// An app's pages.
const List<Widget> pages = [SizedBox(), SizedBox()];

/// An app's rows.
const List<Widget> rows = [SizedBox(height: 44)];

/// A form's fields.
const List<Widget> fields = [SizedBox(height: 44)];

/// A cheque's lines.
const List<Widget> lines = [SizedBox(height: 44)];

/// The tab shown.
int tab = 0;

/// The app's destinations.
const List<LedgerNavItem> tabs = [
  LedgerNavItem(LucideIcons.house, 'Home', ValueKey('home')),
  LedgerNavItem(LucideIcons.chartPie, 'Spending', ValueKey('spending')),
];

/// The signed-in account.
const LedgerAccount account = LedgerAccount(name: 'Maren Holt', initials: 'MH');

/// A list to reorder.
final List<String> names = ['Rent', 'Groceries', 'Dining out'];

/// A choice's value.
const String plan = 'monthly';

/// A choice's value.
const String when = 'Today';

/// A filter chosen.
const String filter = 'Groceries';

/// A slider's value.
double budget = 250;

/// A check's value.
bool done = false;

/// A due date.
final DateTime due = DateTime(2026, 11, 1);

/// A streak's days.
const int streak = 12;

/// A chart's values.
const List<double> spent = [40, 120, 300, 520];

/// A chart's values.
const List<double> daily = [40, 80, 220, 20];

/// A chart's values.
const List<double> balance = [2479.82, 3100, 6248.3];

/// A chart's values.
const List<double> interest = [
  48.1,
  51.3,
  52.0,
  54.6,
  55.2,
  57.9,
  58.4,
  61.0,
  63.8,
  66.1,
  70.1,
  73.42,
];

/// A chart's points.
const List<(int, double)> saved = [(0, 400), (6, 1600), (12, 2840)];

/// A chart's rules.
const List<LedgerGridLine> grid = [LedgerGridLine(1000, '1k')];

/// A category, as an app holds one.
class Category {
  const Category(this.name, this.icon, this.spent, this.count);

  final String name;
  final IconData icon;
  final double spent;
  final int count;
}

/// The app's categories.
const List<Category> categories = [
  Category('Dining out', LucideIcons.utensils, 286.4, 12),
];

/// The categories chosen.
const Set<Category> picked = {};

/// An account, as an app holds one.
class Account {
  const Account(this.name, this.balance);

  final String name;
  final double balance;
}

/// The app's accounts.
const List<Account> accounts = [Account('Everyday', 6248.3)];

/// A day of entries, as an app holds one.
class Day {
  const Day(this.label, this.net, this.rows);

  final String label;
  final double net;
  final List<LedgerTransactionRow> rows;
}

/// The app's days.
const List<Day> days = [Day('Today', -9.65, [])];

/// The ranges a chart shows.
const List<({String short, int months})> ranges = [
  (short: '1M', months: 1),
  (short: '1Y', months: 12),
];

/// Which money a list shows.
const List<({String words, bool? incoming})> directions = [
  (words: 'All', incoming: null),
  (words: 'Money in', incoming: true),
  (words: 'Money out', incoming: false),
];

/// An app's page.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// An app's page.
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// An app's page.
class NewGoalPage extends StatelessWidget {
  const NewGoalPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// An app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

T _held<T extends ChangeNotifier>(T notifier) {
  addTearDown(notifier.dispose);
  return notifier;
}

/// A field's words.
TextEditingController get name => _held(TextEditingController());

/// A field's words.
TextEditingController get password => _held(TextEditingController());

/// A field's words.
TextEditingController get note => _held(TextEditingController());

/// A field's words.
TextEditingController get reply => _held(TextEditingController());

/// A scroll view's position.
ScrollController get scroll => _held(ScrollController());

/// A table's rows and columns.
RawDataTableController<({String title, String amount})> get table => _held(
  RawDataTableController<({String title, String amount})>(
    rows: const [(title: 'Rent', amount: r'$1,150.00')],
    columns: const [
      RawDataColumn(id: 'title', label: 'Payee'),
      RawDataColumn(id: 'amount', label: 'Amount'),
    ],
  ),
);
