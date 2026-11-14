// Generated from the sample data (Keel, a fictional bank) and the reference
// pages' own arithmetic: every figure, label and chart bound here is
// computed as those pages compute it. Do not edit by hand.
// ignore_for_file: public_member_api_docs
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A transaction as the register sets it.
class KitTx {
  const KitTx({
    required this.id,
    required this.title,
    required this.lead,
    required this.subtitle,
    required this.time,
    required this.day,
    required this.account,
    required this.amount,
    required this.at,
    this.icon,
    this.income = false,
    this.moved = false,
    this.pending = false,
  });

  final String id;
  final String title;

  /// The monogram's initials, or null when the lead is a glyph ([icon]).
  final String? lead;
  final IconData? icon;
  final String subtitle;
  final String time;
  final String day;
  final String account;
  final double amount;
  final DateTime at;
  final bool income;
  final bool moved;
  final bool pending;
}

/// A day of the register: its label, its date note, its net and rows.
class KitDay {
  const KitDay(this.label, this.note, this.net, this.rows);

  final String label;
  final String? note;
  final double net;
  final List<KitTx> rows;
}

/// A ledger row: its glyph, name, amount and the two sub lines.
class KitRow {
  const KitRow({
    required this.icon,
    required this.name,
    required this.amount,
    this.subStart = '',
    this.subEnd = '',
    this.subEndGreen = false,
    this.subStartMono = false,
  });

  final IconData icon;
  final String name;
  final double amount;
  final String subStart;
  final String subEnd;
  final bool subEndGreen;
  final bool subStartMono;
}

/// A bill: when it falls due, its name, account, amount and status.
class KitBill {
  const KitBill(
    this.due,
    this.name,
    this.account,
    this.amount,
    this.status, {
    this.autopay = false,
  });

  final DateTime due;
  final String name;
  final String account;
  final double amount;

  /// Autopay on, or in how many days.
  final String status;
  final bool autopay;
}

/// A goal as its line and card show it.
class KitGoal {
  const KitGoal({
    required this.id,
    required this.name,
    required this.icon,
    required this.saved,
    required this.target,
    required this.percent,
    required this.by,
    required this.status,
    required this.behind,
    required this.note,
  });

  final String id;
  final String name;
  final IconData icon;
  final double saved;
  final double target;
  final int percent;
  final String by;
  final String status;
  final bool behind;
  final String note;
}

/// A category's month against its budget.
class KitCategory {
  const KitCategory({
    required this.name,
    required this.icon,
    required this.spent,
    required this.budget,
    required this.subStart,
    required this.subEnd,
  });

  final String name;
  final IconData icon;
  final double spent;
  final double budget;
  final String subStart;
  final String subEnd;
  bool get over => spent > budget;
}

/// A notification.
class KitNote {
  const KitNote(this.icon, this.title, this.body, this.when, this.unread);

  final IconData icon;
  final String title;
  final String body;
  final String when;
  final bool unread;
}

/// A switch row: its glyph, words, sub line and state.
class KitToggle {
  const KitToggle(this.icon, this.label, this.sub, this.on);

  final IconData icon;
  final String label;
  final String sub;
  final bool on;
}

/// A fact: its label, value parts and note.
class KitFact {
  const KitFact(
    this.label,
    this.value,
    this.note, {
    this.cents,
    this.amount,
    this.sign = false,
    this.green = false,
    this.over = false,
  });

  final String label;

  /// The sum, when the fact is money (its dollars and cents).
  final double? amount;
  final bool sign;
  final String value;
  final String? cents;
  final String note;
  final bool green;
  final bool over;
}

/// Home: the net worth by month end (in thousands), its bounds and grid.
const double kitNetWorth = 78182.56;
const double kitNetWorthChange = 2904.18;
const String kitNetWorthChangePct = '+3.86%';
const List<double> kitNetWorthK = [
  61.4,
  62.9,
  64.1,
  63.2,
  65.6,
  67,
  68.3,
  69.9,
  71.6,
  73.4,
  75.2784,
  78.1826,
];
const double kitNetWorthLo = 56;
const double kitNetWorthHi = 82;
const List<(double, String)> kitNetWorthGrid = [
  (80, '80k'),
  (70, '70k'),
  (60, '60k'),
];
const String kitNetWorthLast = 'Oct 78.18k';
const List<String> kitRanges = ['1M', '3M', '1Y', 'All'];
const String kitRange = '1Y';
const List<String> kitNetWorthMonths = [
  'N',
  'D',
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
];
const String kitNetWorthNote =
    'Sum of five accounts. The Keel Card balance of −\u2060\$\u20601\u2060,\u20603\u20602\u20606\u2060.\u20604\u20604 is netted out.';

/// Home's accounts, as their rows read.
const List<KitRow> kitAccounts = [
  KitRow(
    icon: LucideIcons.wallet,
    name: 'Everyday',
    amount: 6248.3,
    subStart: 'Checking ··4821',
    subEnd: '',
    subEndGreen: false,
    subStartMono: true,
  ),
  KitRow(
    icon: LucideIcons.landmark,
    name: 'Savings',
    amount: 21500,
    subStart: '4.10% APY ··9015',
    subEnd: '+\$73.42 in Oct',
    subEndGreen: true,
    subStartMono: true,
  ),
  KitRow(
    icon: LucideIcons.plane,
    name: 'Lisbon fund',
    amount: 2840,
    subStart: 'Goal pot',
    subEnd: '71% of \$4,000',
    subEndGreen: false,
    subStartMono: true,
  ),
  KitRow(
    icon: LucideIcons.creditCard,
    name: 'Keel Card',
    amount: -1326.44,
    subStart: 'Credit ··7730',
    subEnd: 'Due Nov 12 · autopay',
    subEndGreen: false,
    subStartMono: true,
  ),
  KitRow(
    icon: LucideIcons.trendingUp,
    name: 'Investing',
    amount: 48920.7,
    subStart: 'Brokerage',
    subEnd: '+\$391.37 today (+0.81%)',
    subEndGreen: true,
    subStartMono: true,
  ),
];

/// Home's upcoming bills (the next 15 days).
final List<KitBill> kitUpcoming = [
  KitBill(
    DateTime(2026, 11, 1),
    'Rent',
    'Everyday ··4821',
    1150,
    'In 4 days',
    autopay: false,
  ),
  KitBill(
    DateTime(2026, 11, 3),
    'Kite Mobile',
    'Keel Card ··7730',
    35,
    'In 6 days',
    autopay: false,
  ),
  KitBill(
    DateTime(2026, 11, 12),
    'Keel Card payment',
    'Everyday ··4821',
    1326.44,
    'Autopay on',
    autopay: true,
  ),
];

/// Home's quick acts: Move money's four ways.
const List<(IconData, String)> kitActs = [
  (LucideIcons.arrowRightLeft, 'Transfer'),
  (LucideIcons.receipt, 'Pay a bill'),
  (LucideIcons.piggyBank, 'Add to goal'),
  (LucideIcons.split, 'Split'),
];

/// October so far, as Home's section and Spending's hero hold it.
const double kitSpent = 2486.12;
const double kitBudget = 2700;
const int kitDay = 28;
const int kitDaysInMonth = 31;
const double kitLeft = 213.88;
const int kitDaysLeft = 3;
const String kitPaceWords = 'slightly ahead of pace';
const int kitSpentPercent = 92;
const String kitOverName = 'Dining out';
const String kitLeftLabel = '\$213.88 left';
const String kitDaysToGo = '3 days to go';
const String kitBudgetWhole = '\$2,700';
const String kitPaceLabel = 'Pace · day 28';
const String kitMonthName = 'October';
const double kitOverBy = 36.4;

/// The three goals.
const List<KitGoal> kitGoals = [
  KitGoal(
    id: 'lisbon',
    name: 'Lisbon in May',
    icon: LucideIcons.plane,
    saved: 2840,
    target: 4000,
    percent: 71,
    by: 'by May 2027',
    status: 'Behind',
    behind: true,
    note: 'At \$150 a month you reach \$3,890 by May 1. Add \$110 to stay on\u00A0track.',
  ),
  KitGoal(
    id: 'emergency',
    name: 'Emergency fund',
    icon: LucideIcons.shield,
    saved: 20860,
    target: 24000,
    percent: 87,
    by: 'reaches May 2027',
    status: 'On track',
    behind: false,
    note: 'Six months of essentials. At \$400 a month plus Savings interest you get there in May\u00A02027.',
  ),
  KitGoal(
    id: 'bike',
    name: 'New bike',
    icon: LucideIcons.bike,
    saved: 640,
    target: 1800,
    percent: 36,
    by: 'by Oct 2027',
    status: 'On track',
    behind: false,
    note: 'On track for next October at \$100 a\u00A0month.',
  ),
];

/// Home's recent activity (Today, Yesterday, Mon, Oct 26).
final List<KitTx> kitRecent = [
  KitTx(
    id: 't280812blue',
    title: 'Blue Fern Café',
    lead: 'BF',
    icon: null,
    subtitle: 'Dining out',
    time: '8:12 AM',
    day: 'Today',
    account: 'Keel Card',
    amount: -6.75,
    at: DateTime(2026, 10, 28, 8, 12),
    income: false,
    moved: false,
    pending: true,
  ),
  KitTx(
    id: 't280748harb',
    title: 'Harbor Transit',
    lead: 'HT',
    icon: null,
    subtitle: 'Transport',
    time: '7:48 AM',
    day: 'Today',
    account: 'Everyday',
    amount: -2.9,
    at: DateTime(2026, 10, 28, 7, 48),
    income: false,
    moved: false,
    pending: true,
  ),
  KitTx(
    id: 't271822gbm',
    title: 'Green Basket Market',
    lead: 'GB',
    icon: null,
    subtitle: 'Groceries',
    time: '6:22 PM',
    day: 'Yesterday',
    account: 'Keel Card',
    amount: -64.18,
    at: DateTime(2026, 10, 27, 18, 22),
    income: false,
    moved: false,
    pending: false,
  ),
  KitTx(
    id: 't270600stre',
    title: 'Streamline Music',
    lead: 'SM',
    icon: null,
    subtitle: 'Subscriptions',
    time: '6:00 AM',
    day: 'Yesterday',
    account: 'Keel Card',
    amount: -10.99,
    at: DateTime(2026, 10, 27, 6, 0),
    income: false,
    moved: false,
    pending: false,
  ),
  KitTx(
    id: 't261910cine',
    title: 'Cinema Lumen',
    lead: 'CL',
    icon: null,
    subtitle: 'Fun',
    time: '7:10 PM',
    day: 'Mon, Oct 26',
    account: 'Keel Card',
    amount: -28,
    at: DateTime(2026, 10, 26, 19, 10),
    income: false,
    moved: false,
    pending: false,
  ),
  KitTx(
    id: 't261235alde',
    title: 'Alder Pharmacy',
    lead: 'AP',
    icon: null,
    subtitle: 'Health',
    time: '12:35 PM',
    day: 'Mon, Oct 26',
    account: 'Keel Card',
    amount: -18.4,
    at: DateTime(2026, 10, 26, 12, 35),
    income: false,
    moved: false,
    pending: false,
  ),
];

/// Spending's cumulative month against the budget.
const List<double> kitCumulative = [
  1172.4,
  1210.55,
  1274.75,
  1371.55,
  1390.15,
  1402.55,
  1447.65,
  1470.4,
  1541.7,
  1596.6,
  1717.05,
  1732.25,
  1742.05,
  1800.65,
  1833.9,
  1852.8,
  1945.2,
  2021.35,
  2035.65,
  2063.25,
  2105.1,
  2124.8,
  2188.2,
  2209.35,
  2354.9,
  2401.3,
  2476.47,
  2486.12,
];
const double kitCumulativeHi = 3000;
const List<(double, String)> kitCumulativeGrid = [
  (2000, '\$2k'),
  (1000, '\$1k'),
];
const String kitBudgetLabel = 'Budget \$2,700';
const String kitRentWord = 'Rent';
const String kitRentNote = ' \$1,150.00 · Oct 1';
const double kitRentLift = 62;
const double kitRentLiftPhone = 74;
const String kitVsPill = '−6% vs September';

/// Spending's month at a glance.
const List<KitFact> kitMonthFacts = [
  KitFact(
    'Left',
    '\$213',
    '3 days to go',
    cents: '.88',
    amount: 213.88,
    sign: false,
    green: false,
    over: false,
  ),
  KitFact(
    'Vs September',
    '−6%',
    '\$2,644.90 last month',
    green: true,
    over: false,
  ),
  KitFact(
    'Money in',
    '+\$6,825',
    'Two paychecks',
    cents: '.00',
    amount: 6825,
    sign: true,
    green: true,
    over: false,
  ),
  KitFact('Pace', '90%', 'Day 28 of 31; 92% spent', green: false, over: false),
];
const String kitInsightCategory = 'Dining out';
const double kitInsightOver = 36.4;
const String kitInsightMerchant = 'Blue Fern Café';
const int kitInsightVisits = 13;
const double kitInsightAmount = 84.25;

/// The eight categories, as Spending lists them.
const List<KitCategory> kitCategories = [
  KitCategory(
    name: 'Rent & home',
    icon: LucideIcons.keyRound,
    spent: 1150,
    budget: 1150,
    subStart: '100% of \$1,150',
    subEnd: 'Paid Oct 1',
  ),
  KitCategory(
    name: 'Groceries',
    icon: LucideIcons.shoppingBasket,
    spent: 412.36,
    budget: 450,
    subStart: '92% of \$450',
    subEnd: '8% less than Sept',
  ),
  KitCategory(
    name: 'Dining out',
    icon: LucideIcons.utensils,
    spent: 286.4,
    budget: 250,
    subStart: 'Budget \$250',
    subEnd: 'Over by \$36.40',
  ),
  KitCategory(
    name: 'Shopping',
    icon: LucideIcons.shoppingBag,
    spent: 214.75,
    budget: 300,
    subStart: '72% of \$300',
    subEnd: '',
  ),
  KitCategory(
    name: 'Fun',
    icon: LucideIcons.ticket,
    spent: 143.45,
    budget: 200,
    subStart: '72% of \$200',
    subEnd: '',
  ),
  KitCategory(
    name: 'Transport',
    icon: LucideIcons.bus,
    spent: 118.2,
    budget: 160,
    subStart: '74% of \$160',
    subEnd: '',
  ),
  KitCategory(
    name: 'Health',
    icon: LucideIcons.heartPulse,
    spent: 96,
    budget: 120,
    subStart: '80% of \$120',
    subEnd: '',
  ),
  KitCategory(
    name: 'Subscriptions',
    icon: LucideIcons.repeat,
    spent: 64.96,
    budget: 70,
    subStart: '93% of \$70',
    subEnd: '',
  ),
];

/// Spending's top merchants: initials, name, total, visits.
const List<(String, String, double, String)> kitTopMerchants = [
  ('GB', 'Green Basket Market', 268.4, '6 visits'),
  ('BF', 'Blue Fern Café', 84.25, '13 visits'),
  ('HT', 'Harbor Transit', 76.3, '26 trips'),
  ('CL', 'Cinema Lumen', 56, '2 visits'),
];

/// Spent by month, newest first (the month menu).
const List<(String, double)> kitSpentByMonth = [
  ('October 2026', 2486.12),
  ('September 2026', 2644.9),
  ('August 2026', 2512.4),
  ('July 2026', 2733.15),
  ('June 2026', 2598.7),
  ('May 2026', 2689.05),
];

/// Activity's month of days: spent per day, the cap that breaks rent day, the
/// paydays.
const List<double> kitDaily = [
  1172.4,
  38.15,
  64.2,
  96.8,
  18.6,
  12.4,
  45.1,
  22.75,
  71.3,
  54.9,
  120.45,
  15.2,
  9.8,
  58.6,
  33.25,
  18.9,
  92.4,
  76.15,
  14.3,
  27.6,
  41.85,
  19.7,
  63.4,
  21.15,
  145.55,
  46.4,
  75.17,
  9.65,
];
const double kitDailyCap = 190;
const List<(double, String)> kitDailyGrid = [
  (150, '\$150'),
  (100, '\$100'),
  (50, '\$50'),
];
const List<(int, String)> kitPaydays = [
  (23, 'Pay +\$3,412.50'),
  (9, 'Pay +\$3,412.50'),
];
const Map<int, (String, String)> kitCapLabels = {
  1: ('\$1,172.40', ' Oct 1, rent day'),
};
const List<KitFact> kitActivityFacts = [
  KitFact(
    'Money in',
    '+\$6,825',
    'Two paychecks',
    cents: '.00',
    amount: 6825,
    sign: true,
    green: true,
    over: false,
  ),
  KitFact(
    'Spent',
    '\$2,486',
    '87 purchases',
    cents: '.12',
    amount: 2486.12,
    sign: false,
    green: false,
    over: false,
  ),
  KitFact(
    'Moved',
    '\$1,830',
    'Own accounts',
    cents: '.22',
    amount: 1830.22,
    sign: false,
    green: false,
    over: false,
  ),
];
const int kitActivityCount = 92;

/// Activity's first days of the register.
final List<KitDay> kitDays = [
  KitDay('Today', 'Wed, Oct 28', -9.65, [
    KitTx(
      id: 't280812blue',
      title: 'Blue Fern Café',
      lead: 'BF',
      icon: null,
      subtitle: 'Dining out',
      time: '8:12 AM',
      day: 'Today',
      account: 'Keel Card',
      amount: -6.75,
      at: DateTime(2026, 10, 28, 8, 12),
      income: false,
      moved: false,
      pending: true,
    ),
    KitTx(
      id: 't280748harb',
      title: 'Harbor Transit',
      lead: 'HT',
      icon: null,
      subtitle: 'Transport',
      time: '7:48 AM',
      day: 'Today',
      account: 'Everyday',
      amount: -2.9,
      at: DateTime(2026, 10, 28, 7, 48),
      income: false,
      moved: false,
      pending: true,
    ),
  ]),
  KitDay('Yesterday', 'Tue, Oct 27', -75.17, [
    KitTx(
      id: 't271822gbm',
      title: 'Green Basket Market',
      lead: 'GB',
      icon: null,
      subtitle: 'Groceries',
      time: '6:22 PM',
      day: 'Yesterday',
      account: 'Keel Card',
      amount: -64.18,
      at: DateTime(2026, 10, 27, 18, 22),
      income: false,
      moved: false,
      pending: false,
    ),
    KitTx(
      id: 't270600stre',
      title: 'Streamline Music',
      lead: 'SM',
      icon: null,
      subtitle: 'Subscriptions',
      time: '6:00 AM',
      day: 'Yesterday',
      account: 'Keel Card',
      amount: -10.99,
      at: DateTime(2026, 10, 27, 6, 0),
      income: false,
      moved: false,
      pending: false,
    ),
  ]),
  KitDay('Mon, Oct 26', null, -46.4, [
    KitTx(
      id: 't261910cine',
      title: 'Cinema Lumen',
      lead: 'CL',
      icon: null,
      subtitle: 'Fun',
      time: '7:10 PM',
      day: 'Mon, Oct 26',
      account: 'Keel Card',
      amount: -28,
      at: DateTime(2026, 10, 26, 19, 10),
      income: false,
      moved: false,
      pending: false,
    ),
    KitTx(
      id: 't261235alde',
      title: 'Alder Pharmacy',
      lead: 'AP',
      icon: null,
      subtitle: 'Health',
      time: '12:35 PM',
      day: 'Mon, Oct 26',
      account: 'Keel Card',
      amount: -18.4,
      at: DateTime(2026, 10, 26, 12, 35),
      income: false,
      moved: false,
      pending: false,
    ),
  ]),
  KitDay('Sun, Oct 25', null, -145.55, [
    KitTx(
      id: 't251420fiel',
      title: 'Field & Thread',
      lead: 'FT',
      icon: null,
      subtitle: 'Shopping',
      time: '2:20 PM',
      day: 'Sun, Oct 25',
      account: 'Keel Card',
      amount: -128,
      at: DateTime(2026, 10, 25, 14, 20),
      income: false,
      moved: false,
      pending: false,
    ),
    KitTx(
      id: 't251105lard',
      title: 'Corner Larder',
      lead: 'CL',
      icon: null,
      subtitle: 'Groceries',
      time: '11:05 AM',
      day: 'Sun, Oct 25',
      account: 'Keel Card',
      amount: -17.55,
      at: DateTime(2026, 10, 25, 11, 5),
      income: false,
      moved: false,
      pending: false,
    ),
  ]),
];

/// Blue Fern Café's October: each visit's day and amount.
const List<(int, double)> kitVisits = [
  (28, 6.75),
  (23, 6.5),
  (22, 5.75),
  (21, 7.5),
  (20, 7.5),
  (16, 5.5),
  (14, 7.25),
  (9, 7),
  (8, 6.25),
  (7, 4.75),
  (5, 5.25),
  (2, 8.25),
  (1, 6),
];
const int kitVisitDay = 28;
const int kitMonthDays = 31;
const int kitToday = 28;
const int kitVisitCount = 13;
const double kitVisitTotal = 84.25;
final KitTx kitBlueFern = KitTx(
  id: 't280812blue',
  title: 'Blue Fern Café',
  lead: 'BF',
  icon: null,
  subtitle: 'Dining out',
  time: '8:12 AM',
  day: 'Today',
  account: 'Keel Card',
  amount: -6.75,
  at: DateTime(2026, 10, 28, 8, 12),
  income: false,
  moved: false,
  pending: true,
);
const String kitBlueFernLong = 'Wednesday, October 28, 2026';
const String kitBlueFernCategory = 'Dining out';
const String kitBlueFernAccount = 'Keel Card ··7730';
final KitTx kitPaycheck = KitTx(
  id: 'x230630ever',
  title: 'Northwind Studio',
  lead: 'NS',
  icon: null,
  subtitle: 'Paycheck',
  time: '6:30 AM',
  day: 'Fri, Oct 23',
  account: 'Everyday',
  amount: 3412.5,
  at: DateTime(2026, 10, 23, 6, 30),
  income: true,
  moved: false,
  pending: false,
);
const String kitPaycheckAccount = 'Everyday ··4821';
const String kitPaycheckLong = 'Friday, October 23, 2026';

/// Dining out, October: spent per day, its grid and top.
const List<double> kitDiningDays = [
  15.7,
  32.35,
  29.2,
  38.5,
  5.25,
  0,
  4.75,
  6.25,
  20.05,
  0,
  13.45,
  9.4,
  0,
  23.95,
  0,
  16,
  0,
  0,
  8.41,
  7.5,
  26.35,
  5.75,
  6.5,
  10.29,
  0,
  0,
  0,
  6.75,
];
const List<(double, String)> kitDiningGrid = [(40, '\$40'), (20, '\$20')];
const double kitDiningHi = 43.2;
const double kitDiningSpent = 286.4;
const double kitDiningBudget = 250;
const double kitDiningSuggested = 275;
const String kitDiningSub = 'October · 25 purchases at 5 merchants';

/// Everyday's October, end of day, from the 1st's opening.
const List<double> kitEveryday = [
  673.12,
  667.32,
  667.32,
  667.32,
  661.52,
  655.72,
  649.92,
  644.12,
  4050.82,
  4050.82,
  4050.82,
  2864.8,
  2861.9,
  2859,
  2856.1,
  2853.2,
  2853.2,
  2853.2,
  2850.3,
  2847.4,
  2844.5,
  2841.6,
  6251.2,
  6251.2,
  6251.2,
  6251.2,
  6251.2,
  6248.3,
];
const double kitEverydayStart = 2479.82;
const double kitEverydayLo = 0;
const double kitEverydayHi = 7400;
const List<(double, String)> kitEverydayGrid = [
  (6000, '\$6k'),
  (4000, '\$4k'),
  (2000, '\$2k'),
];
const List<(int, String, bool)> kitEverydayMarks = [
  (23, 'Pay +\$3,412.50', true),
  (9, 'Pay +\$3,412.50', true),
  (12, 'Card −\$1,180.22', false),
];
const double kitEverydayBalance = 6248.3;
const double kitEverydayChange = 3768.48;
const String kitEverydaySince = 'since Oct 1';
const String kitEverydaySub = 'Checking ··4821';
const List<KitFact> kitEverydayFacts = [
  KitFact(
    'Money in',
    '+\$6,825',
    'Two paychecks',
    cents: '.00',
    amount: 6825,
    sign: true,
    green: true,
    over: false,
  ),
  KitFact(
    'Spent',
    '\$1,226',
    '27 purchases',
    cents: '.30',
    amount: 1226.3,
    sign: false,
    green: false,
    over: false,
  ),
  KitFact(
    'Moved',
    '\$1,830',
    'Own accounts',
    cents: '.22',
    amount: 1830.22,
    sign: false,
    green: false,
    over: false,
  ),
];
const List<(String, String)> kitEverydayDetails = [
  ('Account', '··4821'),
  ('Routing', '··0119'),
  ('Debit card', '··3907'),
  ('Opened', 'Mar 14, 2023'),
];
final List<KitDay> kitEverydayDays = [
  KitDay('Today', 'Wed, Oct 28', -2.9, [
    KitTx(
      id: 't280748harb',
      title: 'Harbor Transit',
      lead: 'HT',
      icon: null,
      subtitle: 'Transport',
      time: '7:48 AM',
      day: 'Today',
      account: 'Everyday',
      amount: -2.9,
      at: DateTime(2026, 10, 28, 7, 48),
      income: false,
      moved: false,
      pending: true,
    ),
  ]),
  KitDay('Fri, Oct 23', null, 3409.6, [
    KitTx(
      id: 't230745harb',
      title: 'Harbor Transit',
      lead: 'HT',
      icon: null,
      subtitle: 'Transport',
      time: '7:45 AM',
      day: 'Fri, Oct 23',
      account: 'Everyday',
      amount: -2.9,
      at: DateTime(2026, 10, 23, 7, 45),
      income: false,
      moved: false,
      pending: false,
    ),
    KitTx(
      id: 'x230630ever',
      title: 'Northwind Studio',
      lead: 'NS',
      icon: null,
      subtitle: 'Paycheck',
      time: '6:30 AM',
      day: 'Fri, Oct 23',
      account: 'Everyday',
      amount: 3412.5,
      at: DateTime(2026, 10, 23, 6, 30),
      income: true,
      moved: false,
      pending: false,
    ),
  ]),
];

/// Savings' interest by month, the year to date bracketed.
const List<double> kitInterest = [
  58.12,
  60.4,
  61.95,
  57.3,
  64.18,
  64.9,
  67.42,
  66.85,
  69.77,
  71.04,
  70.92,
  73.42,
];
const int kitInterestFirst = 2;
const String kitInterestYear = '2026 to date ';
const String kitInterestYtd = '\$667.75';
const String kitInterestLast = '+\$73.42';
const List<String> kitInterestMonths = [
  'N',
  'D',
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
];

/// Investing's October by day, its bounds and the end label.
const List<double> kitInvesting = [
  50612.4,
  50388.15,
  50388.15,
  50388.15,
  50701.92,
  50455.3,
  50120.84,
  49876.25,
  50034.61,
  50034.61,
  50034.61,
  49702.18,
  49388.47,
  49165.02,
  49420.66,
  49610.35,
  49610.35,
  49610.35,
  49283.9,
  48902.14,
  48655.37,
  48874.05,
  48712.68,
  48712.68,
  48712.68,
  48601.2,
  48529.33,
  48920.7,
];
const double kitInvestingStart = 50428.82;
const double kitInvestingLo = 47400;
const double kitInvestingHi = 51300;
const List<(double, String)> kitInvestingGrid = [
  (51000, '\$51k'),
  (50000, '\$50k'),
  (49000, '\$49k'),
  (48000, '\$48k'),
];
const String kitInvestingEnd = 'Today 48.92k';

/// The allocation: each kind, its value, its hatch and share.
const List<(String, double, String, String)> kitAllocation = [
  ('Stocks', 39432.6, 'ink', '80.6%'),
  ('Bonds', 7336.1, 'green', '15.0%'),
  ('Cash', 2152, 'pale', '4.4%'),
];

/// November's bills summed as they fall due; the two large ones named.
const List<(int, double)> kitBillSteps = [
  (1, 1150),
  (3, 35),
  (12, 1326.44),
  (15, 15.98),
  (19, 2.99),
  (27, 10.99),
];
const int kitBillDays = 30;
const double kitBillsHi = 3000;
const List<(double, String)> kitBillsGrid = [(2000, '\$2k'), (1000, '\$1k')];
const double kitBillsTotal = 2541.4;
const String kitBillsMonth = 'Nov';

/// The named steps: index, name, the rest, the phone's lift and the desktop's.
const List<(int, String, String, double, double)> kitBillNotes = [
  (0, 'Rent', '\$1,150.00 · Nov 1', 40, 46),
  (2, 'Keel Card payment', '\$1,326.44 · Nov 12', 74, 76),
];
final List<KitBill> kitBills = [
  KitBill(
    DateTime(2026, 11, 1),
    'Rent',
    'Everyday ··4821',
    1150,
    'In 4 days',
    autopay: false,
  ),
  KitBill(
    DateTime(2026, 11, 3),
    'Kite Mobile',
    'Keel Card ··7730',
    35,
    'In 6 days',
    autopay: false,
  ),
  KitBill(
    DateTime(2026, 11, 12),
    'Keel Card payment',
    'Everyday ··4821',
    1326.44,
    'Autopay on',
    autopay: true,
  ),
  KitBill(
    DateTime(2026, 11, 15),
    'Newsline',
    'Keel Card ··7730',
    15.98,
    'In 18 days',
    autopay: false,
  ),
  KitBill(
    DateTime(2026, 11, 19),
    'Cloudbox',
    'Keel Card ··7730',
    2.99,
    'In 22 days',
    autopay: false,
  ),
  KitBill(
    DateTime(2026, 11, 27),
    'Streamline Music',
    'Keel Card ··7730',
    10.99,
    'In 30 days',
    autopay: false,
  ),
];

/// Goals: the saved total at each month end against the summed target.
const List<double> kitSavedByMonth = [
  16521.85,
  17132.25,
  17744.2,
  18351.5,
  18965.68,
  19580.58,
  20338,
  21054.85,
  21774.62,
  22895.66,
  23616.58,
  24340,
];
const double kitGoalsTarget = 29800;
const double kitGoalsSaved = 24340;
const double kitGoalsLo = 15000;
const double kitGoalsHi = 31886;
const List<(double, String)> kitGoalsGrid = [
  (25000, '\$25k'),
  (20000, '\$20k'),
];
const String kitGoalsTargetLabel = 'Target \$29,800';
const String kitGoalsGap = '\$5,460';
const List<String> kitGoalsMonths = [
  'N',
  'D',
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
];

/// The Lisbon fund: saved so far, the projection to its date, the target.
const List<(int, double)> kitLisbonHist = [
  (0, 790),
  (1, 940),
  (2, 1090),
  (3, 1240),
  (4, 1390),
  (5, 1540),
  (6, 1690),
  (7, 1840),
  (8, 1990),
  (9, 2540),
  (10, 2690),
  (11, 2840),
];
const List<(int, double)> kitLisbonProj = [
  (12, 2990),
  (13, 3140),
  (14, 3290),
  (15, 3440),
  (16, 3590),
  (17, 3740),
  (18, 3890),
];
const int kitLisbonMonths = 19;
const double kitLisbonTarget = 4000;
const double kitLisbonLo = 0;
const double kitLisbonHi = 4400;
const List<(double, String)> kitLisbonGrid = [
  (3000, '\$3,000'),
  (2000, '\$2,000'),
  (1000, '\$1,000'),
];
const String kitLisbonTargetLabel = 'Target \$4,000';
const String kitLisbonEnd = '\$3,890\nby May 2027';
const List<String> kitLisbonKeys = [
  'N',
  'D',
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
  'N',
  'D',
  'J',
  'F',
  'M',
  'A',
  'M',
];
const int kitLisbonNow = 11;

/// The two cards.
const List<String> kitCardNumber = ['4242', '4242', '4242', '7730'];
const String kitCardHolder = 'MAREN HOLT';
const String kitCardKind = 'Credit';
const String kitCardAccount = 'Keel Card';
const String kitCardName = 'Keel Card';
const List<String> kitDebitNumber = ['4242', '4242', '4242', '3907'];
const String kitDebitHolder = 'MAREN HOLT';
const String kitDebitKind = 'Debit';
const String kitDebitAccount = 'Everyday';
const String kitFrozenOn = 'Oct 28';

/// The notifications, newest first.
const List<KitNote> kitNotes = [
  KitNote(
    LucideIcons.receipt,
    'Rent is due in 4 days',
    '\$1,150.00 to Linden Court Apartments on Nov 1.',
    '9:00 AM',
    true,
  ),
  KitNote(
    LucideIcons.arrowDownLeft,
    'Paycheck landed',
    '+\$3,412.50 from Northwind Studio.',
    'Oct 23',
    false,
  ),
  KitNote(
    LucideIcons.target,
    'Lisbon in May is 71% saved',
    '\$1,160 to go by May 1.',
    'Oct 22',
    false,
  ),
  KitNote(
    LucideIcons.chartPie,
    'Dining out is over budget',
    'You have spent \$257.11 of \$250.',
    'Oct 21',
    false,
  ),
  KitNote(
    LucideIcons.creditCard,
    'Keel Card autopay sent',
    '\$1,180.22 from Everyday.',
    'Oct 12',
    false,
  ),
  KitNote(
    LucideIcons.receipt,
    'Kite Mobile paid',
    '\$35.00 on your Keel Card.',
    'Oct 3',
    false,
  ),
];

/// The alert switches (Notifications and Profile).
const List<KitToggle> kitAlerts = [
  KitToggle(
    LucideIcons.receipt,
    'Bills',
    'A reminder before each bill is due',
    true,
  ),
  KitToggle(LucideIcons.chartPie, 'Budgets', 'When a category goes over', true),
  KitToggle(LucideIcons.badgeDollarSign, 'Large purchases', 'Over \$200', true),
  KitToggle(
    LucideIcons.calendarDays,
    'Weekly summary',
    'Mondays, the week in one note',
    false,
  ),
];

/// The Keel Card's controls.
const List<KitToggle> kitCardControls = [
  KitToggle(
    LucideIcons.globe,
    'Online payments',
    'Shops on the web and in apps',
    true,
  ),
  KitToggle(LucideIcons.nfc, 'Contactless', 'Tap to pay at a till', true),
];
const String kitMonthlyLimit = '\$2,000';

/// The transfer: from, to, the amount in figures and in words, the note.
const (IconData, String, String, double) kitFrom = (
  LucideIcons.wallet,
  'Everyday',
  '··4821',
  6248.3,
);
const (IconData, String, String, double) kitTo = (
  LucideIcons.landmark,
  'Savings',
  '··9015',
  21500,
);
const double kitTransferAmount = 500;
const String kitTransferWords = 'Five hundred and 00/100';
const String kitTransferNote = 'November top-up';
const String kitTransferWhen = 'Today · Wed, Oct 28';
const String kitTransferDate = 'Wed, Oct 28, 2026';
const String kitMicr = '··0119 ··4821 ··9015';
const double kitAddAmount = 110;
const List<double> kitAddQuick = [110, 150, 300];
