// The names the doc examples assume (a page's state, its callbacks, its
// data, its other widgets), so each example compiles as written and runs.
// What an example makes and must dispose it gives to [own].
// ignore_for_file: public_member_api_docs
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/frosted_ui.dart';

final List<VoidCallback> _disposers = [];

/// [value], disposed by [disposeOwned] once the example's tree is gone.
T own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

/// Disposes what the examples made through [own].
void disposeOwned() {
  for (final dispose in _disposers) {
    dispose();
  }
  _disposers.clear();
}

// A page's state, as its State would hold it.
void setState(VoidCallback fn) => fn();
DateTime? due = DateTime(2026, 11, 12);
DesignDateRange? trip;
FrostedTime? alarm;
bool faceId = true;
bool veg = false;
bool kept = false;
bool receipt = true;
bool unread = false;
bool on = true;
bool focused = true;
bool shown = true;
bool dark = false;
double stars = 4;
Color tint = const Color(0xFF3A5BD9);
DesignRangeValues price = const DesignRangeValues(20, 80);
List<String> chosen = ['Travel'];
int budget = 2700;
String? amount = '580';
String range = '1m';
String scope = 'all';
String room = 'k';
String size = 'm';
String speed = 'standard';
String? plan = 'free';
String? country = 'Portugal';
String site = 'harbor';
String query = '';
String notes = '';
String password = '';
String name = 'Lisbon in May';
String target = '4000';
String date = 'May 2027';
int guests = 2;
int index = 0;
int tab = 0;
int page = 0;
String? icon = 'Home';
Set<String> styles = {'b'};
double volume = .6;
double alertAt = 80;
String? picked = 'jonah';
List<FrostedUploadFile> files = [const FrostedUploadFile('receipt.pdf')];

// Its callbacks: each takes what its control gives, or nothing.
void open([Object? _]) {}
void undo([Object? _]) {}
void redo([Object? _]) {}
void transfer([Object? _]) {}
void save([Object? _]) {}
void close([Object? _]) {}
void freeze([Object? _]) {}
void cancel([Object? _]) {}
void report([Object? _]) {}
void review([Object? _]) {}
void openCategory([Object? _]) {}
void openProfile([Object? _]) {}
void openCards([Object? _]) {}
void openBills([Object? _]) {}
void openGoal([Object? _]) {}
void openLimit([Object? _]) {}
void openMove([Object? _]) {}
void openPasscode([Object? _]) {}
void openSavings([Object? _]) {}
void openSettings([Object? _]) {}
void startGoal([Object? _]) {}
void add([Object? _]) {}
void bills([Object? _]) {}
void clear([Object? _]) {}
void copy([Object? _]) {}
void delete([Object? _]) {}
void goal([Object? _]) {}
void home([Object? _]) {}
void move([Object? _]) {}
void pay([Object? _]) {}
void pickCurrency([Object? _]) {}
void pickFrom([Object? _]) {}
void pop([Object? _]) {}
void projects([Object? _]) {}
void saveAll([Object? _]) {}
void saveAs([Object? _]) {}
void search([Object? _]) {}
void seeAll([Object? _]) {}
void share([Object? _]) {}
void signIn([Object? _]) {}
void signInWithApple([Object? _]) {}
void signInWithEmail([Object? _]) {}
void split([Object? _]) {}
void attach([Object? _]) {}
void back([Object? _]) {}
void create([Object? _]) {}
void verify([Object? _]) {}
void send([Object? _]) {}
void pick([Object? _]) {}
void remove([Object? _]) {}
void toggle([Object? _]) {}
void select([Object? _]) {}
void keep([Object? _]) {}
void setTab([Object? _]) {}
void setUnread([Object? _]) {}
void setDate([Object? _]) {}
void setFaceId([Object? _]) {}
void setName([Object? _]) {}
void setOn([Object? _]) {}
void setPlan([Object? _]) {}
void setRange([Object? _]) {}
void setTarget([Object? _]) {}
void setVolume([Object? _]) {}
void setAlertAt([Object? _]) {}
void saveAlertAt([Object? _]) {}
Future<void> reload([Object? _]) async {}
String money(int cents) => FrostedFormat.money(cents / 100);

// Its data.
final FrostedThemeData theme = FrostedThemeData.opal();
final FrostedThemeData t = theme;
final FrostedHue everyday = theme.hues.azure;
final FrostedHue hue = theme.hues.periwinkle;
final FrostedHue dining = theme.hues.coral;
final DateTime now = DateTime(2026, 10, 28, 19, 40);
const Duration d = Duration(milliseconds: 300);
const Curve c = Curves.easeOut;
const String email = 'maya@park.studio';
const String answer = 'Everything in Basic, with no foreign fees.';
const String cover = 'https://example.com/lisbon.jpg';
final Future<ByteData> bytes = Future.value(ByteData(0));
// An app's router (go_router's GoRouter, say).
late final RouterConfig<Object> router;
Route<void> get route =>
    PageRouteBuilder<void>(pageBuilder: (_, _, _) => const SizedBox());
const FrostedAccount account = FrostedAccount(
  name: 'Maren Holt',
  initials: 'MH',
);
const List<FrostedButtonSegment<String>> segments = [
  FrostedButtonSegment('1m', '1M'),
  FrostedButtonSegment('1y', '1Y'),
];
const List<FrostedNavItem> tabs = [
  FrostedNavItem(FrostedGlyphs.house, 'Home'),
  FrostedNavItem(FrostedGlyphs.wallet, 'Accounts'),
  FrostedNavItem(FrostedGlyphs.search, 'Search'),
];
const List<String> months = ['Aug', 'Sep', 'Oct'];
const List<String> shortMonths = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'];
const List<num> emergencyByMonth = [18200, 18900, 19500, 19900, 20400, 20860];
const List<num> lisbonByMonth = [1800, 2100, 2350, 2600, 2740, 2840];
const List<num> interestByMonth = [41, 43, 44, 46, 47, 49];
const List<num> netWorthByMonth = [44100, 45200, 45900, 46800, 47300, 48210];
const List<num> savedByMonth = [1800, 2100, 2350, 2600, 2740, 2840];
const List<num> ahead = [2840, 3140, 3440, 3740, 4040];
final List<num> valueByDay = [for (var i = 0; i < 28; i++) 12000 + i * 40];
final List<num> diningByDay = [for (var i = 0; i < 28; i++) (i * 7) % 30];
final List<num> closingByDay = [for (var i = 0; i < 28; i++) 2479.82 - i * 20];
final List<num> spentByDay = [for (var i = 0; i < 28; i++) i * 90];
final List<num> balance = [for (var i = 0; i < 28; i++) 6248.30 - i * 30];
const num opening = 6248.30;
const List<FrostedAxisMark> axis = [
  FrostedAxisMark.first('Oct 1'),
  FrostedAxisMark(14, 'Oct 15'),
];
const List<FrostedAxisMark> octoberAxis = axis;
const List<FrostedAxisMark> novemberAxis = [
  FrostedAxisMark.first('Nov 1'),
  FrostedAxisMark(14, 'Nov 15'),
];
const List<FrostedAxisMark> goalAxis = [
  FrostedAxisMark.first('Nov'),
  FrostedAxisMark(4, 'May'),
];
final List<FrostedFanEnd> scheduled = [
  FrostedFanEnd(amount: 1150, hue: theme.hues.periwinkle, title: 'Rent'),
  FrostedFanEnd(amount: 250, hue: theme.hues.sunset, title: 'Lisbon in May'),
];
List<String> tasks = ['Pay rent', 'Call the bank'];
const List<String> countries = ['Portugal', 'Spain', 'France'];
const List<String> tags = ['Travel', 'Food', 'Home'];
const Map<String, List<String>> folders = {
  'Bills': ['Rent'],
  'Trips': ['Lisbon'],
};
const List<String> photos = [];
const List<({String title, String year})> films = [
  (title: 'Harbor Lights', year: '2024'),
  (title: 'Salt Roads', year: '2023'),
];
const List<({String payee, int cents})> payments = [
  (payee: 'Blue Fern Café', cents: 675),
  (payee: 'Harbor Apartments', cents: 115000),
];

// Its other widgets.
Widget get row => const Text('Blue Fern Café');
Widget get body => const Text('On pace for May');
Widget get child => const Text('Everyday');
Widget get card => const Text('Everyday account');
Widget get chipA => const Text('Groceries');
Widget get chipB => const Text('Dining out');
Widget get chips => const Text('Amounts');
Widget get from => const Text('From Everyday');
Widget get icons => const Text('Icons');
Widget get inboxIcon => const Icon(FrostedGlyphs.bell);
Widget get copyButton => const Text('Copy');
Widget get face => const SizedBox(width: 48, height: 32);
Widget get list => const Text('Inbox');
Widget get detail => const Text('Message');
Widget get settings => const Text('Settings');
Widget get shareTargets => const Text('Share to');
Widget get title => const Text('October');
Widget get app => const SizedBox();
List<Widget> get rows => const [Text('Rent'), Text('Groceries')];
List<Widget> get options => const [Text('Groceries'), Text('Dining out')];
List<Widget> get tiles => const [Text('Lisbon in May'), Text('Emergency fund')];

/// An app's page.
class AccountPage extends StatelessWidget {
  /// An account's page.
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Everyday');
}

/// An app's page.
class NewGoalPage extends StatelessWidget {
  /// A new goal's page.
  const NewGoalPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('New goal');
}

/// An app.
class MyApp extends StatelessWidget {
  /// The app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
