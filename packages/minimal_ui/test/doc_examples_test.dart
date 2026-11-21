// Every doc example in Minimal's lib, compiled and run: each `/// Example:`
// line and each fenced dart block is written out below as the body of an
// entry, so an example that stops compiling fails analysis; the first test
// fails when lib has an example this file lacks; the rest build each widget
// example, and make each call (a sheet shown, a route pushed) after the
// first frame, in a bare app.
//
// The names an example takes as the caller's own (a callback, a value, its
// setter, a controller) are made here first, as the docs say the caller
// does.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'doc_examples.dart';

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

/// Makes [call] after the first frame (a sheet shown, a route pushed), as a
/// caller's tap would.
Object? _later(FutureOr<void> Function() call) {
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run(call)));
  return null;
}

Future<void> _run(FutureOr<void> Function() call) async => call();

/// A value an example makes and goes on to use.
void _use(Object? value) {}

/// A bare app, its pages under the standard theme.
Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      MinimalTheme(data: MinimalThemeData.standard(), child: page!),
  home: Material(type: MaterialType.transparency, child: child),
);

// --- the caller's own -------------------------------------------------------

// What a caller does when a part calls back: any of these takes the value
// it is given, or none.
void add([Object? _]) {}
void archive([Object? _]) {}
void billing([Object? _]) {}
void close([Object? _]) {}
void copy([Object? _]) {}
void create([Object? _]) {}
void day([Object? _]) {}
void delete([Object? _]) {}
void go([Object? _]) {}
void logAll([Object? _]) {}
void open([Object? _]) {}
void openProfile([Object? _]) {}
void openSearch([Object? _]) {}
void pick([Object? _]) {}
void pickGoal([Object? _]) {}
void pickRepeat([Object? _]) {}
void pickStatus([Object? _]) {}
void pickTime([Object? _]) {}
void refund([Object? _]) {}
void remove([Object? _]) {}
void rename([Object? _]) {}
void reset([Object? _]) {}
void restore([Object? _]) {}
void save([Object? _]) {}
void saveAs([Object? _]) {}
void search([Object? _]) {}
void send([Object? _]) {}
void setAnother([Object? _]) {}
void setChosen([Object? _]) {}
void setCity([Object? _]) {}
void setColour([Object? _]) {}
void setDay([Object? _]) {}
void setFilter([Object? _]) {}
void setFormats([Object? _]) {}
void setLabels([Object? _]) {}
void setOn([Object? _]) {}
void setPage([Object? _]) {}
void setPages([Object? _]) {}
void setPart([Object? _]) {}
void setPlan([Object? _]) {}
void setPrice([Object? _]) {}
void setRemindAt([Object? _]) {}
void setRepeat([Object? _]) {}
void setStay([Object? _]) {}
void setTab([Object? _]) {}
void setView([Object? _]) {}
void share([Object? _]) {}
void signIn([Object? _]) {}
void toHabits([Object? _]) {}
void toggle([Object? _]) {}
void verify([Object? _]) {}
void week([Object? _]) {}
void move(int from, int to) {}
Future<void> reload() async {}
void setState(VoidCallback change) => change();

// What a caller holds.
final MinimalThemeData t = MinimalThemeData.standard();
int page = 1;
const int tab = 0;
const int view = 0;
const int filter = 1;
const int streak = 12;
bool done = false;
bool remind = true;
int stars = 3;
const bool showNote = true;
const bool picked = true;
const bool another = false;
const bool on = true;
const bool dark = false;
DateTime remindAt = DateTime(2026, 11, 14, 21, 30);
final RawDateRange stay = RawDateRange(
  DateTime(2026, 11, 14),
  DateTime(2026, 11, 18),
);
const Color colour = Color(0xFF2563EB);
const String plan = 'free';
const String city = 'Lisbon';
const String sort = 'Name';
const List<MinimalMenuItem> sorts = [
  MinimalMenuItem('Name'),
  MinimalMenuItem('Streak'),
];
const double pages = 20;
const List<String> labels = ['Bug'];
const Set<String> formats = {'b'};
const String repeat = 'daily';
const List<MinimalSelectOption<String>> repeats = [
  MinimalSelectOption('daily', 'Every day'),
  MinimalSelectOption('weekly', 'Every week'),
];
const String part = 'crust';
const List<MinimalSelectOption<String>> parts = [
  MinimalSelectOption('crust', 'Crust'),
  MinimalSelectOption('crumb', 'Crumb'),
];
const List<double> weekly = [3, 5, 4, 6, 7, 5, 8];
const List<double> monthly = [12, 15, 14, 18, 21, 19];
const List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
final List<int> last84 = [for (var i = 0; i < 84; i++) i % 3];
const List<String> photos = ['hero-bakery'];
const List<MinimalUploadFile> uploads = [
  MinimalUploadFile(name: 'orders.csv', progress: 0.4),
];
const List<String> steps = ['Warm up', 'Run', 'Stretch'];
const Map<String, List<String>> folders = {
  'lib': ['lib/main.dart'],
  'test': [],
};
const List<MinimalNavItem> tabs = [
  MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
  MinimalNavItem(LucideIcons.listChecks, 'Habits'),
];
final List<({String name, double total})> orders = [
  (name: 'Hanna Berg', total: 24.5),
  (name: 'Ola Dahl', total: 12),
];
const ({String id, String name, int streak}) habit = (
  id: 'read',
  name: 'Read 20 pages',
  streak: 12,
);
const List<({String id, String name, int streak})> habits = [habit];
const Widget form = Text('Name');
const Widget summary = Text('3 of 5 kept');
const Widget heatmap = Text('Heatmap');
const Widget tile = Text('Read 20 pages');
const Widget list = Text('Issues');
const Widget detail = Text('HAB-4');
const Widget details = Text('2 loaves');
const Widget personCard = Text('Ana Lima');
const Widget moreGlyph = Icon(LucideIcons.ellipsis);
const Widget initials = Text('HB');
const Widget app = Text('App');
const Widget row = Text('Read 20 pages');
const List<Widget> rows = [Text('Reminder'), Text('Repeats')];
const List<Widget> fields = [Text('Name')];
const List<Widget> notes = [Text('Note')];
const List<Widget> messages = [Text('Hi')];
const List<Widget> pills = [Text('Daily')];
late final RouterConfig<Object> router;
late final Future<ByteData> bytes;

/// An app's page, as the docs name one.
class InboxPage extends StatelessWidget {
  /// The inbox.
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Inbox');
}

/// An app's page, as the docs name one.
class TodayPage extends StatelessWidget {
  /// Today.
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Today');
}

/// An app's page, as the docs name one.
class HabitPage extends StatelessWidget {
  /// A habit.
  const HabitPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Habit');
}

/// An app's page, as the docs name one.
class NewHabitPage extends StatelessWidget {
  /// A new habit.
  const NewHabitPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('New habit');
}

/// An app, as the docs name one.
class MyApp extends StatelessWidget {
  /// The app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const Text('App');
}

final Map<String, DocExample> _examples = {
  'MinimalButton': (context) => const MinimalButton(
    'Save',
    onPressed: save,
    style: MinimalStyle(
      shape: WidgetStatePropertyAll(StadiumBorder()),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
    ),
  ),
  'MinimalThemeData': (context) {
    final theme = MinimalThemeData.standard().copyWith(
      components: const MinimalComponentThemes(
        chip: MinimalStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
      ),
    );
    _use(theme);
    return null;
  },
  'MinimalActionBar': (context) => const MinimalActionBar(
    summary: '3 of 5 kept',
    detail: 'Two to go',
    label: 'Log all',
    onPressed: logAll,
  ),
  'showMinimalActionSheet': (context) => _later(
    () => showMinimalActionSheet(
      context,
      title: 'Photo',
      actions: [
        const MinimalActionSheetAction('Share', onPressed: share),
        const MinimalActionSheetAction(
          'Delete',
          destructive: true,
          onPressed: delete,
        ),
      ],
    ),
  ),
  'MinimalTimeline': (context) => MinimalTimeline(
    entries: [
      MinimalActivity(at: DateTime(2026, 8, 28, 7, 12), text: 'Marked done'),
    ],
  ),
  'MinimalActivity': (context) => MinimalActivity(
    at: DateTime(2026, 8, 27, 7, 40),
    text: 'Marked done',
    detail: 'note added',
  ),
  'MinimalAvatar': (context) => const MinimalAvatar('Hanna Berg', size: 24),
  'MinimalAvatarGroup': (context) => const MinimalAvatarGroup([
    'Hanna Berg',
    'Oskar Lind',
    'Ines Duarte',
  ], max: 3),
  'MinimalBadge': (context) =>
      const MinimalBadge(count: 3, child: MinimalIcon(LucideIcons.bell)),
  'MinimalBanner': (context) => const MinimalBanner(
    tone: MinimalTone.warning,
    title: 'Your trial ends Friday',
    message: 'Add a card to keep your projects.',
    actions: [
      MinimalButton(
        'Add card',
        size: MinimalButtonSize.small,
        onPressed: billing,
      ),
    ],
  ),
  'MinimalBreadcrumbItem': (context) =>
      const MinimalBreadcrumbItem('HAB-4', mono: true),
  'MinimalBreadcrumb': (context) => const MinimalBreadcrumb(
    crumbs: [
      MinimalBreadcrumbItem('Habits', onPressed: toHabits),
      MinimalBreadcrumbItem('HAB-4', mono: true),
    ],
  ),
  'MinimalButton 2': (context) =>
      const MinimalButton('Create habit', onPressed: create),
  'MinimalButtonGroup': (context) => const MinimalButtonGroup(
    items: [
      MinimalButtonGroupItem(label: 'Day', onPressed: day),
      MinimalButtonGroupItem(label: 'Week', onPressed: week),
    ],
  ),
  'MinimalCalendar': (context) {
    final day = DateTime(2026, 11, 14);
    return MinimalCalendar(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      value: day,
      onChanged: setDay,
    );
  },
  'MinimalDateRangePicker': (context) => MinimalDateRangePicker(
    label: 'Stay',
    firstDate: DateTime(2026),
    lastDate: DateTime(2027),
    value: stay,
    onChanged: setStay,
  ),
  'MinimalCard': (context) => const MinimalCard(child: summary),
  'MinimalCarouselView': (context) => MinimalCarouselView(
    height: 220,
    children: [for (final slot in photos) MinimalMedia.media(slot)],
  ),
  'MinimalBarChart': (context) =>
      const MinimalBarChart([4, 9, 6, 12], labels: ['M', 'T', 'W', 'T']),
  'MinimalSparkline': (context) =>
      MinimalSparkline(weekly, height: 26, color: t.success),
  'MinimalCheckbox': (context) => MinimalCheckbox(
    value: done,
    label: 'Meditate',
    onChanged: (v) => setState(() => done = v),
  ),
  'MinimalCheckMark': (context) => const MinimalCheckMark(value: picked),
  'MinimalChip': (context) => MinimalChip(
    'Open',
    count: 2,
    selected: filter == 1,
    onPressed: () => setFilter(1),
  ),
  'MinimalChipRow': (context) {
    final filters = [(name: 'Open', count: 2), (name: 'Done', count: 5)];
    final on = filters.first;
    return MinimalChipRow(
      children: [
        for (final f in filters)
          MinimalChip(
            f.name,
            count: f.count,
            selected: f == on,
            onPressed: () => pick(f),
          ),
      ],
    );
  },
  'MinimalCodeBlock': (context) => const MinimalCodeBlock(
    'curl -X POST https://api.example.com/v1/orders',
    label: 'bash',
  ),
  'MinimalKbd': (context) => MinimalKbd.chord('⌘ K'),
  'MinimalKbd 2': (context) => MinimalKbd.shortcut(
    const SingleActivator(LogicalKeyboardKey.keyK, meta: true),
  ),
  'MinimalColorPicker': (context) => const MinimalColorPicker(
    value: colour,
    onChanged: setColour,
    swatches: [Color(0xFF2563EB), Color(0xFF16A34A)],
  ),
  'MinimalCombobox': (context) => const MinimalCombobox<String>(
    label: 'City',
    options: ['Lisbon', 'London', 'Lyon'],
    value: city,
    onSelected: setCity,
  ),
  'MinimalMultiSelect': (context) => const MinimalMultiSelect<String>(
    label: 'Labels',
    values: labels,
    options: ['Bug', 'Design', 'Docs'],
    onChanged: setLabels,
  ),
  'MinimalCommandItem': (context) => const MinimalCommandItem(
    'New habit',
    icon: LucideIcons.plus,
    group: 'Habits',
    shortcut: 'N',
    onSelected: create,
  ),
  'MinimalCommand': (context) => _later(
    () => MinimalCommand.show(
      context,
      actions: [
        const MinimalCommandItem(
          'New habit',
          icon: LucideIcons.plus,
          shortcut: 'N',
          onSelected: create,
        ),
      ],
    ),
  ),
  'MinimalComposer': (context) {
    final draft = _own(TextEditingController());
    return MinimalComposer(controller: draft, onSend: send);
  },
  'MinimalComposerAction': (context) =>
      const MinimalComposerAction(onPressed: send),
  'MinimalComposerLayout': (context) => MinimalComposerLayout(
    composer: const MinimalComposer(onSend: send),
    bodyBuilder: (context, bottomInset) => ListView(
      padding: EdgeInsets.only(bottom: bottomInset),
      children: messages,
    ),
  ),
  'MinimalCounter': (context) =>
      MinimalCounter(streak, style: t.giant, format: (v) => '${v}d'),
  'MinimalDataColumn': (context) =>
      MinimalDataColumn<({String name, double total})>(
        'Total',
        value: (o) => '\$${o.total}',
        sortKey: (o) => o.total,
        numeric: true,
      ),
  'MinimalDataTable': (context) =>
      MinimalDataTable<({String name, double total})>(
        rows: orders,
        columns: [
          MinimalDataColumn('Customer', value: (o) => o.name, sortable: true),
          MinimalDataColumn(
            'Total',
            value: (o) => '\$${o.total}',
            sortKey: (o) => o.total,
            numeric: true,
          ),
        ],
        pageSize: 10,
        onSelectionChanged: setChosen,
      ),
  'MinimalDatePicker': (context) => MinimalDatePicker(
    label: 'Reminder',
    value: remindAt,
    mode: MinimalDatePickerMode.time,
    onChanged: setRemindAt,
  ),
  'showMinimalDialog': (context) => _later(() async {
    final sure = await showMinimalDialog<bool>(
      context,
      builder: (context) => const MinimalDialog(
        title: 'Delete habit?',
        message: 'Its history goes too.',
        confirmLabel: 'Delete',
        cancelLabel: 'Keep',
        destructive: true,
      ),
    );
    _use(sure);
  }),
  'showMinimalDialog 2': (context) => _later(() async {
    final sure =
        await showMinimalDialog<bool>(
          context,
          builder: (context) => const MinimalDialog(
            title: 'Archive habit?',
            confirmLabel: 'Archive',
            cancelLabel: 'Keep',
          ),
        ) ??
        false;
    _use(sure);
  }),
  'MinimalDisclosure': (context) => const MinimalDisclosure(
    title: 'Advanced',
    child: Text('Webhooks, API keys and audit logs.'),
  ),
  'MinimalDivider': (context) => const MinimalDivider(label: 'or'),
  'MinimalCircularProgressIndicator': (context) => const TickerMode(
    enabled: false,
    child: MinimalCircularProgressIndicator(label: 'Syncing'),
  ),
  'MinimalSkeleton': (context) =>
      const TickerMode(enabled: false, child: MinimalSkeleton.text(lines: 3)),
  'MinimalMeter': (context) => const MinimalMeter(
    label: 'Storage',
    value: 7.2,
    max: 10,
    valueLabel: '7.2 of 10 GB',
    warningAt: 0.8,
  ),
  'MinimalFileUpload': (context) => const MinimalFileUpload(
    title: 'Drop a CSV here, or browse',
    link: 'browse',
    hint: 'Up to 10 MB',
    onBrowse: pick,
    files: uploads,
    onRemove: remove,
  ),
  'MinimalFilter': (context) => MinimalFilter(
    'Open',
    count: 2,
    selected: view == 1,
    onPressed: () => setView(1),
  ),
  'MinimalFilterBar': (context) {
    final filters = [(label: 'Open', count: 2), (label: 'Done', count: 5)];
    return MinimalFilterBar(
      children: [
        for (final (i, f) in filters.indexed)
          MinimalFilter(
            f.label,
            count: f.count,
            selected: i == view,
            onPressed: () => setView(i),
          ),
      ],
    );
  },
  'MinimalFormSection': (context) => const MinimalFormSection(
    title: 'Schedule',
    footer: 'Reminders follow your device time zone.',
    children: rows,
  ),
  'MinimalFormRow': (context) => const MinimalFormRow(
    label: 'Remind me',
    icon: LucideIcons.bell,
    trailing: MinimalSwitch(value: on, onChanged: setOn),
  ),
  'MinimalInputRow': (context) {
    final name = _own(TextEditingController());
    return MinimalInputRow(
      label: 'Name',
      controller: name,
      hint: 'Stretch before bed',
    );
  },
  'MinimalFormField': (context) => const MinimalFormField(
    label: 'Plan',
    help: 'You can change it later',
    group: true,
    child: MinimalRadioGroup<String>(
      value: plan,
      onChanged: setPlan,
      options: [
        MinimalRadioOption(value: 'free', label: 'Free'),
        MinimalRadioOption(value: 'pro', label: 'Pro'),
      ],
    ),
  ),
  'MinimalForm': (context) => const MinimalForm(
    onSubmit: save,
    child: Column(children: fields),
  ),
  'MinimalSectionHeader': (context) =>
      const MinimalSectionHeader('Morning', count: '2/3'),
  'MinimalHeatmap': (context) => MinimalHeatmap(levels: last84, today: 81),
  'MaterialApp': (context) =>
      () => MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MinimalHost(
          light: MinimalThemeData.preset('standard', Brightness.light),
          dark: MinimalThemeData.preset('standard', Brightness.dark),
          child: child!,
        ),
      ),
  'MinimalAppBar': (context) => const MinimalAppBar(
    title: 'Today',
    actions: [
      MinimalIconButton(LucideIcons.search, label: 'Search', onPressed: search),
    ],
  ),
  'MinimalListTile': (context) => const MinimalListTile(
    title: 'Notifications',
    leading: MinimalIconTile(LucideIcons.bell),
  ),
  'MinimalPlaceholderImage': (context) =>
      const MinimalPlaceholderImage(MinimalMediaKind.product, 3),
  'MinimalMedia': (context) =>
      const MinimalMedia.media('hero-bakery', height: 180),
  'MinimalTextField': (context) {
    final name = _own(TextEditingController());
    return MinimalTextField(
      label: 'Name',
      hint: 'Stretch before bed',
      controller: name,
    );
  },
  'MinimalInputGroup': (context) {
    final site = _own(TextEditingController());
    return MinimalInputGroup(
      label: 'Website',
      prefixText: 'https://',
      suffixText: '.com',
      controller: site,
    );
  },
  'MinimalPasswordField': (context) {
    final password = _own(TextEditingController());
    return MinimalPasswordField(
      label: 'Password',
      controller: password,
      onSubmitted: (_) => signIn(),
    );
  },
  'MinimalInputOtp': (context) => const MinimalInputOtp(
    length: 6,
    label: 'Code from your email',
    onCompleted: verify,
  ),
  'MinimalLink': (context) =>
      const MinimalLink('Forgot password?', onPressed: reset),
  'MinimalReorderableListView': (context) => MinimalReorderableListView<String>(
    items: steps,
    labelOf: (s) => s,
    onReorder: move,
    itemBuilder: (context, s) => Text(s),
  ),
  'MinimalRefreshIndicator': (context) => MinimalRefreshIndicator(
    onRefresh: reload,
    child: ListView(children: rows),
  ),
  'MinimalTreeView': (context) => MinimalTreeView<String>(
    roots: const ['lib', 'test'],
    childrenOf: (path) => folders[path] ?? const <String>[],
    labelOf: (path) => path,
    onActivate: open,
  ),
  'MinimalListTile 2': (context) => const MinimalListTile(
    icon: LucideIcons.circleDashed,
    title: 'Drink water',
    meta: '10d',
    onTap: open,
  ),
  'MinimalListSection': (context) => MinimalListSection(
    children: [
      for (final h in habits)
        MinimalListTile(title: h.name, meta: '${h.streak}d'),
    ],
  ),
  'Image': (context) =>
      Image(image: MinimalMediaSource.image('hero-bakery'), fit: BoxFit.cover),
  'MinimalMediaSource': (context) =>
      MinimalMediaSource.reference = (context, value) =>
          value.startsWith('https:')
          ? (slot: null, image: NetworkImage(value))
          : null,
  'MinimalMediaImage': (context) =>
      const MinimalMediaImage(slotId: 'face-hanna', fallback: initials),
  'MinimalMenuItem': (context) => const MinimalMenuItem(
    'Rename',
    icon: LucideIcons.pencil,
    shortcut: SingleActivator(LogicalKeyboardKey.keyR),
    onPressed: rename,
  ),
  'MinimalMenu': (context) => const MinimalMenu(
    label: 'Habit actions',
    items: [MinimalMenuItem('Rename', onPressed: rename)],
    child: moreGlyph,
  ),
  'MinimalMenu 2': (context) => const MinimalMenu.button(
    LucideIcons.arrowDownUp,
    text: 'Sort: $sort',
    label: 'Sort habits',
    items: sorts,
  ),
  'MinimalMenuEntry': (context) => const MinimalMenuEntry(
    'File',
    children: [
      MinimalMenuEntry(
        'New',
        shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true),
        onPressed: create,
      ),
    ],
  ),
  'MinimalMenuBar': (context) => const MinimalMenuBar(
    menus: [
      MinimalMenuEntry(
        'File',
        children: [
          MinimalMenuEntry('New', onPressed: create),
          MinimalMenuEntry('Open…', onPressed: open),
        ],
      ),
    ],
  ),
  'MinimalMetaRow': (context) => const MinimalMetaRow(
    leading: Text('1047'),
    middle: Text('Hanna Berg · 3 loaves'),
    trailing: Text('09:30'),
  ),
  'MinimalNavItem': (context) =>
      const MinimalNavItem.media(LucideIcons.play, 'Watch'),
  'MinimalNavigationBar': (context) => const MinimalNavigationBar(
    items: [
      MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
      MinimalNavItem(LucideIcons.listChecks, 'Habits'),
    ],
    selectedIndex: tab,
    onDestinationSelected: go,
  ),
  'MinimalNavigationRail': (context) => const MinimalNavigationRail(
    destinations: [
      MinimalNavItem(LucideIcons.inbox, 'Inbox'),
      MinimalNavItem(LucideIcons.folder, 'Projects'),
    ],
    selectedIndex: tab,
    onDestinationSelected: setTab,
  ),
  'MinimalNavigationDrawer': (context) => MinimalNavigationDrawer(
    sections: const [
      MinimalNavigationSection(
        destinations: [
          MinimalNavItem(LucideIcons.inbox, 'Inbox'),
          MinimalNavItem(LucideIcons.listTodo, 'My issues'),
        ],
      ),
    ],
    selectedIndex: page,
    onDestinationSelected: setPage,
  ),
  'showMinimalSheet': (context) {
    const filters = Text('Filters');
    return _later(
      () => showMinimalSheet<void>(
        context,
        title: 'Filters',
        builder: (context) => filters,
      ),
    );
  },
  'showMinimalSheet 2': (context) => _later(() async {
    await showMinimalSheet<void>(
      context,
      title: 'Order #1042',
      builder: (context) => details,
      trailing: const MinimalSheetAction('Refund', onPressed: refund),
    );
  }),
  'MinimalPopover': (context) {
    const filters = Text('Filters');
    return MinimalPopover(
      anchor: (context, toggle, open) => MinimalButton(
        'Filters',
        variant: MinimalButtonVariant.secondary,
        onPressed: toggle,
      ),
      content: (context, close) => filters,
    );
  },
  'MinimalHoverCard': (context) => const MinimalHoverCard(
    card: personCard,
    child: MinimalLink('@ana', onPressed: openProfile),
  ),
  'MinimalPage': (context) =>
      const MinimalPage<void>(key: ValueKey('habit'), child: HabitPage()),
  'MinimalSheetPage': (context) => const MinimalSheetPage<void>(
    key: ValueKey('new-habit'),
    child: NewHabitPage(),
  ),
  'MinimalPagination': (context) => MinimalPagination(
    page: page,
    pageCount: 12,
    onPageChanged: (p) => setState(() => page = p),
  ),
  'MinimalPageDots': (context) {
    final controller = _own(PageController());
    return MinimalPageDots(
      count: 4,
      selectedIndex: page,
      onChanged: controller.jumpToPage,
    );
  },
  'MinimalStepProgress': (context) =>
      const MinimalStepProgress(steps: ['Account', 'Plan', 'Pay'], current: 1),
  'MinimalScrollArea': (context) =>
      const MinimalScrollArea(height: 240, child: Column(children: notes)),
  'MinimalResizable': (context) => const MinimalResizable(
    first: list,
    second: detail,
    initialFraction: 0.35,
    minFirst: 220,
    minSecond: 320,
  ),
  'MinimalSelectOption': (context) =>
      const MinimalSelectOption('evening', 'Evening', icon: LucideIcons.moon),
  'MinimalSelect': (context) => const MinimalSelect(
    label: 'Repeats',
    value: repeat,
    options: repeats,
    onChanged: setRepeat,
  ),
  'MinimalSelectionList': (context) => const MinimalSelectionList(
    value: part,
    options: parts,
    onChanged: setPart,
  ),
  'MinimalPressable': (context) =>
      MinimalPressable(onPressed: open, shape: t.shapes.medium, child: tile),
  'MinimalHitTarget': (context) =>
      const MinimalHitTarget(line: 28, child: Row(children: pills)),
  'MinimalPreview': (context) => MinimalPreview(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    tabs: tabs,
    child: const TodayPage(),
  ),
  'MinimalLinearProgressIndicator': (context) =>
      const MinimalLinearProgressIndicator(value: 0.62, label: 'Upload'),
  'MinimalDescriptionList': (context) => const MinimalDescriptionList(
    properties: [
      MinimalProperty(
        icon: LucideIcons.bell,
        label: 'Reminder',
        value: '07:00',
        mono: true,
      ),
    ],
  ),
  'MinimalProperty': (context) => const MinimalProperty(
    icon: LucideIcons.circleDot,
    label: 'Status',
    value: 'Active',
    tone: MinimalTone.success,
    onPressed: pickStatus,
  ),
  'MinimalPropertyPill': (context) => const MinimalPropertyPill(
    icon: LucideIcons.bell,
    label: '21:30',
    name: 'Reminder',
    mono: true,
    hasValue: true,
    onPressed: pickTime,
  ),
  'MinimalPropertyBar': (context) => const MinimalPropertyBar(
    pills: [
      MinimalPropertyPill(
        icon: LucideIcons.repeat,
        label: 'Every evening',
        hasValue: true,
        onPressed: pickRepeat,
      ),
      MinimalPropertyPill(
        icon: LucideIcons.target,
        label: 'Goal',
        onPressed: pickGoal,
      ),
    ],
  ),
  'MinimalRadio': (context) => MinimalRadio(
    selected: plan == 'pro',
    label: 'Pro',
    onPressed: () => setPlan('pro'),
  ),
  'MinimalRadioGroup': (context) => const MinimalRadioGroup<String>(
    value: plan,
    onChanged: setPlan,
    options: [
      MinimalRadioOption(value: 'free', label: 'Free'),
      MinimalRadioOption(value: 'pro', label: 'Pro'),
    ],
  ),
  'MinimalRangeSlider': (context) => MinimalRangeSlider(
    label: 'Price',
    values: const RawRangeValues(20, 80),
    min: 0,
    max: 200,
    format: (v) => '\$${v.round()}',
    onChanged: setPrice,
  ),
  'MinimalRating': (context) => MinimalRating(
    value: stars.toDouble(),
    onChanged: (v) => setState(() => stars = v),
    label: 'Your rating',
  ),
  'MinimalReveal': (context) => const MinimalReveal(
    visible: showNote,
    child: MinimalListTile(title: 'Note'),
  ),
  'Navigator': (context) => _later(
    () =>
        Navigator.of(context)
            .push(MinimalFadeRoute<void>(builder: (_) => const InboxPage())),
  ),
  'MinimalScaffold': (context) => const MinimalScaffold(
    topBar: MinimalAppBar(title: 'Today', subtitle: 'Fri 28 Aug'),
    padding: EdgeInsets.zero,
    body: Column(children: rows),
  ),
  'MinimalSearchField': (context) {
    void filter(String query) {}
    return MinimalSearchField(
      hint: 'Search habits',
      onChanged: filter,
      clearable: true,
    );
  },
  'MinimalSearchEntry': (context) => const MinimalSearchEntry(
    label: 'Search habits',
    shortcut: '/',
    onPressed: openSearch,
  ),
  'MinimalSection': (context) => const MinimalSection(
    title: 'Last 12 weeks',
    count: '71 / 84',
    child: heatmap,
  ),
  'MinimalSegmentBar': (context) => const MinimalSegmentBar(
    value: 3,
    total: 5,
    label: 'kept',
    showPercent: true,
  ),
  'MinimalWeekDots': (context) => const MinimalWeekDots(
    completedDays: [false, true, true, true, true, false, false],
    currentDay: 4,
  ),
  'MinimalSegmentedButton': (context) {
    const view = 'week';
    return const MinimalSegmentedButton<String>(
      segments: [
        MinimalButtonSegment('week', 'Week'),
        MinimalButtonSegment('month', 'Month'),
      ],
      value: view,
      onChanged: setView,
    );
  },
  'MinimalButtonSegment': (context) =>
      const MinimalButtonSegment('board', 'Board', icon: LucideIcons.kanban),
  'MinimalChoiceRow': (context) => MinimalChoiceRow(
    title: 'Every day',
    selected: repeat == 'daily',
    onPressed: () => setRepeat('daily'),
  ),
  'MinimalSelectionGroup': (context) => MinimalSelectionGroup(
    children: [
      MinimalChoiceRow(
        title: 'Morning',
        selected: part == 'am',
        onPressed: () => setPart('am'),
      ),
    ],
  ),
  'MinimalLineChart': (context) => const MinimalLineChart(
    series: [MinimalChartSeries('Signups', weekly)],
    labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  ),
  'MinimalAreaChart': (context) => MinimalAreaChart(
    series: const [MinimalChartSeries('Revenue', monthly)],
    labels: months,
    format: (v) => '\$${v.round()}',
  ),
  'MinimalPieChart': (context) => const MinimalPieChart(
    slices: [
      MinimalChartSlice('Design', 42),
      MinimalChartSlice('Build', 31),
      MinimalChartSlice('Ops', 12),
    ],
    centerLabel: 'Hours',
  ),
  'MinimalSheetAction': (context) => const MinimalSheetAction(
    'Create habit',
    onPressed: create,
    isDefaultAction: true,
  ),
  'MinimalScaffold 2': (context) => const MinimalScaffold(
    topBar: MinimalAppBar(title: 'New habit'),
    footer: MinimalSheetFooter(
      accessory: MinimalSwitch(
        value: another,
        onChanged: setAnother,
        label: 'Create another',
        showLabel: true,
      ),
      leading: MinimalSheetAction('Cancel'),
      trailing: MinimalSheetAction(
        'Create habit',
        onPressed: create,
        isDefaultAction: true,
      ),
    ),
    body: form,
  ),
  'MinimalBottomSheet': (context) => const MinimalBottomSheet(
    title: 'New habit',
    subtitle: 'Habits',
    floating: true,
    trailing: MinimalSheetAction('Create habit', isDefaultAction: true),
    child: form,
  ),
  'showMinimalBottomSheet': (context) => _later(() async {
    await showMinimalBottomSheet<void>(
      context,
      title: 'New habit',
      subtitle: 'Habits',
      trailing: const MinimalSheetAction(
        'Create habit',
        onPressed: create,
        isDefaultAction: true,
      ),
      builder: (context) => form,
    );
  }),
  'MinimalSignInButton': (context) =>
      const MinimalSignInButton('apple', onPressed: signIn),
  'MinimalSignInStack': (context) =>
      const MinimalSignInStack(['apple', 'google', 'email'], onPressed: signIn),
  'MinimalSlider': (context) => const MinimalSlider(
    label: 'Daily reading goal',
    value: pages,
    min: 10,
    max: 50,
    divisions: 8,
    unit: 'pages',
    onChanged: setPages,
  ),
  'MinimalSplitButton': (context) => const MinimalSplitButton(
    'Save',
    onPressed: save,
    actions: [
      MinimalMenuItem('Save as…', onPressed: saveAs),
      MinimalMenuItem('Save a copy', onPressed: copy),
    ],
  ),
  'MinimalStat': (context) => const MinimalStat(
    label: 'Kept',
    value: '23/28',
    delta: '4',
    deltaUp: true,
  ),
  'MinimalStatRow': (context) {
    const streak = Text('12d');
    const kept = Text('71%');
    return const MinimalStatRow(children: [streak, kept]);
  },
  'MinimalStatRow 2': (context) {
    const revenue = Text('€1,284');
    const orders = Text('42');
    const late = Text('3');
    return const MinimalStatRow.joined(children: [revenue, orders, late]);
  },
  'MinimalScaffold 3': (context) => const TickerMode(
    enabled: false,
    child: MinimalScaffold(
      body: MinimalLoadingState(message: 'Loading habits'),
    ),
  ),
  'MinimalErrorState': (context) => const MinimalErrorState(
    title: 'Could not sync',
    message: 'Check your connection and try again.',
    onRetry: reload,
  ),
  'MinimalEmptyState': (context) => const MinimalEmptyState(
    icon: LucideIcons.inbox,
    title: 'No habits yet',
    body: 'Habits you add show up here.',
    actionLabel: 'New habit',
    onAction: add,
  ),
  'MinimalStatusView': (context) => const MinimalStatusView.success(
    title: 'Invite sent',
    message: 'Ana will get an email in a minute.',
    actionLabel: 'Done',
    onAction: close,
  ),
  'MinimalStatusIcon': (context) =>
      MinimalStatusIcon(MinimalTaskStatus.done, onPressed: () => toggle(habit)),
  'MinimalPriorityIcon': (context) =>
      const MinimalPriorityIcon(MinimalPriority.high),
  'MinimalStatusBadge': (context) =>
      const MinimalStatusBadge('Late', tone: MinimalTone.warning),
  'MinimalNumberField': (context) {
    const pages = 20;
    return const MinimalNumberField(
      value: pages,
      min: 5,
      max: 50,
      step: 5,
      unit: 'pages',
      label: 'Pages',
      onChanged: setPages,
    );
  },
  'MinimalSwipeAction': (context) => const MinimalSwipeAction(
    'Archive',
    icon: LucideIcons.archive,
    onPressed: archive,
  ),
  'MinimalSwipeActions': (context) => const MinimalSwipeActions(
    trailing: [
      MinimalSwipeAction(
        'Delete',
        destructive: true,
        icon: LucideIcons.trash2,
        onPressed: delete,
      ),
    ],
    child: row,
  ),
  'MinimalDismissible': (context) => MinimalDismissible(
    key: ValueKey(habit.id),
    onDismissed: () => remove(habit),
    child: row,
  ),
  'MinimalColumn': (context) =>
      const MinimalColumn('Qty', width: 44, numeric: true, sortable: true),
  'MinimalCell': (context) =>
      const MinimalCell.badge('Ready', tone: MinimalTone.success),
  'MinimalTableRow': (context) => const MinimalTableRow([
    MinimalCell('1039'),
    MinimalCell('Jonas Weber'),
  ], faded: true),
  'MinimalTable': (context) {
    final orders = [(id: '1047', name: 'Hanna Berg', qty: 3)];
    return MinimalTable(
      columns: const [
        MinimalColumn('#', width: 40, mono: true),
        MinimalColumn('Customer'),
        MinimalColumn('Qty', width: 38, numeric: true),
      ],
      rows: [
        for (final o in orders)
          MinimalTableRow([
            MinimalCell(o.id),
            MinimalCell(o.name, strong: true),
            MinimalCell('${o.qty}'),
          ]),
      ],
      onRowPressed: open,
    );
  },
  'MinimalTabBar': (context) => const MinimalTabBar(
    tabs: ['Overview', 'Activity', 'Notes'],
    counts: [null, 12, 3],
    selectedIndex: tab,
    onChanged: go,
  ),
  'MinimalTag': (context) =>
      const MinimalTag('Overdue', tone: MinimalTone.destructive),
  'MinimalTag 2': (context) =>
      const MinimalTag('Bug', dot: MinimalTone.destructive),
  'MinimalTextArea': (context) {
    final notes = _own(TextEditingController());
    return MinimalTextArea(
      label: 'Notes',
      hint: 'Anything the team should know',
      controller: notes,
    );
  },
  'MinimalTimePicker': (context) => MinimalTimePicker(
    label: 'Remind me at',
    value: remindAt,
    onChanged: (v) => setState(() => remindAt = v),
  ),
  'showMinimalSnackBar': (context) => _later(() async {
    showMinimalSnackBar(
      context,
      'Habit archived',
      actionLabel: 'Undo',
      onAction: restore,
    );
  }),
  'MinimalToaster': (context) => const MinimalToaster(child: app),
  'MinimalSnackBar': (context) => const MinimalSnackBar(
    'Habit archived',
    icon: LucideIcons.archive,
    actionLabel: 'Undo',
    onAction: restore,
  ),
  'MinimalSwitch': (context) => MinimalSwitch(
    value: remind,
    label: 'Reminders',
    onChanged: (v) => setState(() => remind = v),
  ),
  'MinimalToggleItem': (context) => const MinimalToggleItem(
    'bold',
    icon: LucideIcons.bold,
    semanticLabel: 'Bold',
  ),
  'MinimalToggleGroup': (context) => const MinimalToggleGroup<String>(
    items: [
      MinimalToggleItem('b', icon: LucideIcons.bold, semanticLabel: 'Bold'),
      MinimalToggleItem('i', icon: LucideIcons.italic, semanticLabel: 'Italic'),
    ],
    selected: formats,
    multiple: true,
    onChanged: setFormats,
  ),
  'MinimalTooltip': (context) => const MinimalTooltip(
    message: 'Archive',
    child: MinimalIconButton(
      LucideIcons.archive,
      label: 'Archive',
      onPressed: archive,
    ),
  ),
  'MinimalAppBar 2': (context) => const MinimalAppBar(
    title: 'Today',
    subtitle: 'Fri 28 Aug',
    actions: [
      MinimalIconButton(LucideIcons.search, label: 'Search', onPressed: search),
      MinimalIconButton(
        LucideIcons.plus,
        label: 'New habit',
        variant: MinimalIconButtonVariant.primary,
        onPressed: add,
      ),
    ],
  ),
  'FontLoader': (context) => () async {
    final loader = FontLoader(minimalFontFamily('Geist'))..addFont(bytes);
    await loader.load();
    _use(loader);
  },
  'main': (context) {
    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await minimalLoadFonts();
      runApp(const MyApp());
    }

    return main;
  },
  'Text': (context) => Text(
    MinimalFormat.money(128400, symbol: '€', cents: false),
    style: t.giant,
  ),
  'MinimalThemeData 2': (context) {
    final theme = MinimalThemeData.standard().copyWith(
      density: MinimalDensity.compact,
    );
    _use(theme);
    return null;
  },
  'MinimalThemeData 3': (context) {
    final theme = MinimalThemeData.standard().copyWith(
      typeface: const MinimalTypeface.app(sans: 'Inter', mono: 'JetBrainsMono'),
    );
    _use(theme);
    return null;
  },
  'Text 2': (context) => Text(MinimalLocalizations.of(context).back),
  'MaterialApp 2': (context) =>
      () => MaterialApp(
        localizationsDelegates: [
          MinimalLocalizations.delegateOf(
            const MinimalLocalizationsEn(),
            isSupported: (l) => l.languageCode == 'en',
          ),
          RawWidgetsLocalizations.delegate,
        ],
      ),
  'MaterialApp 5': (context) =>
      () => const MaterialApp(
        localizationsDelegates: [
          MinimalLocalizations.delegate,
          RawWidgetsLocalizations.delegate,
        ],
      ),
  'MinimalThemeData 4': (context) {
    final softer = MinimalThemeData.standard().copyWith(
      shapes: const MinimalShapes(radius: 12),
    );
    _use(softer);
    return null;
  },
  'MinimalIcon': (context) =>
      MinimalIcon(LucideIcons.bell, color: t.foreground),
  'MinimalThemeData 5': (context) {
    final t = MinimalThemeData.standard();
    final quieter = t.copyWith(
      colors: t.colors.copyWith(border: const Color(0xFFF0F0F2)),
    );
    _use(t);
    _use(quieter);
    return null;
  },
  'MinimalThemeData 6': (context) {
    final t = MinimalThemeData.standard();
    final own = t.copyWith(
      typeface: const MinimalTypeface.app(sans: 'Inter', mono: 'JetBrainsMono'),
    );
    _use(t);
    _use(own);
    return null;
  },
  'MinimalThemeData 7': (context) {
    final night = MinimalThemeData.preset('ember', Brightness.dark);
    final mine = night.copyWith(
      shapes: const MinimalShapes(radius: 12),
      density: MinimalDensity.compact,
      components: const MinimalComponentThemes(
        chip: MinimalStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
      ),
    );
    _use(night);
    _use(mine);
    return null;
  },
  'MinimalThemeData 8': (context) {
    final brand = MinimalThemeData.from(
      primary: const Color(0xFF7A1F5C),
      neutral: const Color(0xFF8B7355),
      brightness: Brightness.dark,
    );
    _use(brand);
    return null;
  },
  'MaterialApp 3': (context) =>
      () => MaterialApp(
        builder: (context, child) => MinimalTheme(
          data: MinimalThemeData.preset(
            'standard',
            MediaQuery.platformBrightnessOf(context),
          ),
          child: child!,
        ),
        home: const InboxPage(),
      ),
  'MaterialApp 4': (context) =>
      () => MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: minimalPageTransitions,
          ),
        ),
        builder: (context, child) =>
            MinimalTheme(data: MinimalThemeData.standard(), child: child!),
        home: const InboxPage(),
      ),
  'AnimatedMinimalTheme': (context) {
    const page = Text('Page');
    return AnimatedMinimalTheme(
      data: MinimalThemeData.preset(
        'standard',
        dark ? Brightness.dark : Brightness.light,
      ),
      child: page,
    );
  },
};

void main() {
  tearDown(() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
  });

  testDocExamples(
    self: 'test/doc_examples_test.dart',
    examples: _examples,
    wrap: _wrap,
    // The inventory's example is ui_core's own gallery, which ui_core's
    // examples test runs; the package's tests reach the look's libraries.
    // The parts library's header is the exporter's import note (where a
    // copied part's imports come from), not an example.
    skip: const {'inventory.dart', 'minimal_parts.dart'},
  );
}
