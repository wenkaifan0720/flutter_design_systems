// Every doc example in lib, compiled and run (ui_core's template,
// test/doc_examples.dart). Each fenced dart block is written out below as
// the body of an entry, so an example that stops compiling fails analysis;
// the first test fails when lib has an example this file lacks; the rest
// build each one in a bare app. Written by the pack's gen_doc_examples.py
// from the lib's docs; the names the examples take for granted are defined
// once above them. A call that opens something is put behind a button.
// The examples stay as the docs write them, without the consts the lints
// would add (testDocExamples compares them const aside).
// ignore_for_file: prefer_function_declarations_over_variables, unnecessary_lambdas, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'doc_examples.dart';

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

// The app's own state and handlers, as the examples name them.
void setState(VoidCallback fn) => fn();
void deploy([String? branch]) {}
void fresh() {}
void openRuns() {}
void verify(String code) {}
void retry() {}
void clear() {}
void openCommit() {}
void rerun() {}
void copy() {}
void pickFiles() {}
void goHome() {}
void openProject() {}
void open() {}
void menu() {}
Future<void> reload() async {}
var view = 'list';
var onlyFailed = false;
var replicas = 3;
var branch = 'main';
var regions = ['eu-west'];
var tab = 0;
var page = 5;
var share = 0.2;
var latency = const RawRangeValues(200, 800);
var stars = 3;
String? environment = 'staging';
var autoMerge = true;
var notify = false;
var valid = true;
var dark = true;
DateTime? freeze;
RawDateRange? window;
TermTime? at;
final picked = ['build.log'];
const branches = ['main', 'release/2.4'];
const allRegions = ['eu-west', 'us-east'];
const url = 'https://example.com/deploy-graph.png';
const steps = ['build', 'test', 'deploy'];
const commands = [RawCommand(label: 'deploy to staging')];
const Widget app = SizedBox();
const Widget child = Text('slipway');
const Widget files = Text('files');
const Widget preview = Text('preview');
const lines = [Text('one'), Text('two')];
const rows = [Text('#1482'), Text('#1481')];
const pages = [Text('home'), Text('runs')];
const destinations = [
  TermNavigationDestination(label: 'home'),
  TermNavigationDestination(label: 'runs'),
];
const states = <WidgetState>{};
final theme = TermThemeData.dark();
final style = TermStyle(
  foreground: const WidgetStatePropertyAll(Color(0xFFE3C46F)),
);
final bytes = Future.value(
  ByteData.view(
    File('assets/fonts/JetBrainsMonoNL-Regular.ttf').readAsBytesSync().buffer,
  ),
);

/// The app's screens, as the examples name them.
class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) => const Text('home');
}

class MyApp extends Home {
  const MyApp({super.key});
}

class RunPage extends Home {
  const RunPage({super.key});
}

class RunDetails extends Home {
  const RunDetails({super.key});
}

class FilterForm extends Home {
  const FilterForm({super.key});
}

final Map<String, DocExample> _examples = {
  "actions.dart:31": (context) => TermButtonGroup(
    semanticLabel: 'run actions',
    children: [
      TermButton(label: 'rerun', onPressed: () {}),
      TermButton(label: 'cancel', onPressed: () {}),
    ],
  ),
  "actions.dart:74": (context) => TermToggleGroup<String>(
    options: const ['list', 'tiles'],
    selected: {view},
    labelOf: (v) => v,
    onSelectionChanged: (s) => setState(() => view = s.first),
  ),
  "actions.dart:201": (context) => TermSplitButton(
    label: 'deploy',
    onPressed: deploy,
    actions: [RawSplitAction(label: 'deploy without cache', onPressed: fresh)],
  ),
  "actions.dart:302": (context) =>
      TermLink(label: 'the docs', onPressed: () {}),
  "button.dart:32": (context) => TermButton(
    label: 'Cancel',
    shortcut: const SingleActivator(LogicalKeyboardKey.escape),
    onPressed: () {},
  ),
  "button.dart:225": (context) =>
      TermIconButton(glyph: '?', semanticLabel: 'Help', onPressed: () {}),
  "charts.dart:52": (context) => TermSparkline(
    values: const [3, 5, 4, 8, 6, 9],
    semanticLabel: 'build time, last 6 runs',
  ),
  "charts.dart:159": (context) => TermBarChart(
    bars: const [('api', 42), ('web', 18), ('worker', 7)],
    unit: 'min',
  ),
  "charts.dart:296": (context) => TermLineChart(
    series: const [
      TermSeries(label: 'p95 ms', values: [120, 135, 128, 160, 142]),
    ],
    xLabels: ('mon', 'fri'),
  ),
  "charts.dart:482": (context) => TermAreaChart(
    series: const [
      TermSeries(label: 'requests', values: [4, 9, 7, 12, 10]),
    ],
  ),
  "chips.dart:20": (context) =>
      TermTag(label: 'production', tone: TermTone.warning),
  "chips.dart:146": (context) => TermChip(
    label: 'failed',
    selected: onlyFailed,
    onSelected: (v) => setState(() => onlyFailed = v),
  ),
  "chips.dart:245": (context) => Row(
    children: [
      Text('failed'),
      TermBadge(count: 3, semanticLabel: 'failed runs'),
    ],
  ),
  "command_palette.dart:31": (context) {
    termMatchRanges('deploy to staging', 'dts'); // [(0, 1), (7, 8), (10, 11)]
    return null;
  },
  "command_palette.dart:65": (context) => TermCommandPalette(
    commands: [
      RawCommand(
        label: 'deploy to staging',
        group: 'deploy',
        onPressed: deploy,
      ),
      RawCommand(
        label: 'open the runs',
        group: 'go',
        shortcut: 'M-2',
        onPressed: openRuns,
      ),
    ],
  ),
  "command_palette.dart:446": (context) => RawCommandShortcut(
    onOpen: () => showTermCommandPalette(context: context, commands: commands),
    child: app,
  ),
  "containers.dart:56": (context) =>
      TermDisclosure(title: 'environment', child: Text('NODE_ENV=production')),
  "containers.dart:218": (context) => TermTable(
    columns: const [
      TermColumn(label: 'run', cols: 6),
      TermColumn(label: 'branch'),
      TermColumn(label: 'took', cols: 7, numeric: true),
    ],
    rows: [
      [Text('#1482'), Text('main'), Text('2m 14s')],
    ],
  ),
  "containers.dart:342": (context) {
    final table = _own(
      RawDataTableController<Map<String, String>>(
        rows: const [
          {'id': '1482', 'took': '2m 14s'},
        ],
        columns: const [
          RawDataColumn(id: 'id', label: 'run'),
          RawDataColumn(id: 'took', label: 'took'),
        ],
      ),
    );
    return TermDataTable<Map<String, String>>(
      controller: table,
      widths: const {'id': 6, 'took': 7},
      cellBuilder: (context, run, column) => Text(run[column.id] ?? ''),
    );
  },
  "containers.dart:543": (context) => const TermDivider(label: 'older'),
  "containers.dart:609": (context) {
    final scroll = _own(ScrollController());
    return TermScrollArea(
      controller: scroll,
      child: ListView(controller: scroll, children: lines),
    );
  },
  "containers.dart:680": (context) =>
      TermWholeLines(child: ListView(children: lines)),
  "containers.dart:735": (context) =>
      TermSplitView(first: files, second: preview, initialFraction: 0.3),
  "containers.dart:832": (context) => TermReorderableList<String>(
    items: steps,
    labelOf: (s) => s,
    onReorder: (from, to) =>
        setState(() => steps.insert(to, steps.removeAt(from))),
  ),
  "containers.dart:932": (context) => TermPullToRefresh(
    onRefresh: reload,
    child: ListView(children: rows),
  ),
  "containers.dart:1013": (context) {
    final tree = _own(
      DesignTreeController<String>(
        roots: const ['lib'],
        childrenOf: (path) =>
            path == 'lib' ? const ['lib/main.dart'] : const [],
      ),
    );
    return TermTree<String>(
      controller: tree,
      labelOf: (path) => path.split('/').last,
    );
  },
  "containers.dart:1152": (context) => TermTimeline(
    entries: const [
      TermTimelineEntry(
        time: '14:02',
        title: 'build passed',
        tone: TermTone.success,
      ),
      TermTimelineEntry(time: '14:05', title: 'deploy started'),
    ],
  ),
  "containers.dart:1273": (context) => TermAvatar(name: 'Ada Lovelace'),
  "containers.dart:1331": (context) => TermAvatarGroup(
    names: const ['Ada Lovelace', 'Alan Turing', 'Grace Hopper'],
  ),
  "containers.dart:1383": (context) =>
      TermMedia(image: NetworkImage(url), alt: 'the deploy graph', lines: 10),
  "containers.dart:1516": (context) => TermDescriptionList(
    items: const [('branch', 'main'), ('commit', '4f2a91c')],
  ),
  "dialog.dart:31": (context) => TermDialog(
    title: 'discard changes',
    content: const Text('the form has edits that are not saved.'),
    actions: [
      TermButton(label: 'keep', onPressed: () {}),
      TermButton.filled(label: 'discard', onPressed: () {}),
    ],
  ),
  "dialog.dart:410": (context) {
    return TermButton(
      label: 'open',
      onPressed: () async {
        final sure = await showTermConfirmDialog(
          context: context,
          title: 'delete logs',
          message: "run #1482's logs go for good",
          confirmLabel: 'delete',
          isDestructiveAction: true,
        );
        sure?.toString();
      },
    );
  },
  "dialog.dart:417": (context) {
    return TermButton(
      label: 'open',
      onPressed: () {
        showTermSheet<void>(
          context: context,
          builder: (context) => TermSheet(
            title: 'share run #1482',
            actions: [TermButton.filled(label: 'copy link', onPressed: () {})],
            child: const Text('a link anyone on the team can open'),
          ),
        );
      },
    );
  },
  "feedback.dart:61": (context) => const TermSpinner(),
  "feedback.dart:120": (context) =>
      const TermProgressBar(value: 0.42, cols: 20),
  "feedback.dart:289": (context) => const TermCaret(),
  "feedback.dart:334": (context) {
    return TermButton(
      label: 'open',
      onPressed: () {
        TermToaster.show(
          context,
          message: 'deployed atlas-api to staging',
          tone: TermTone.success,
        );
      },
    );
  },
  "inputs.dart:32": (context) {
    final token = _own(TextEditingController());
    return TermPasswordField(labelText: 'token', controller: token);
  },
  "inputs.dart:125": (context) =>
      TermOtpField(onCompleted: (code) => verify(code)),
  "inputs.dart:292": (context) => TermNumberField(
    semanticLabel: 'replicas',
    value: replicas,
    min: 1,
    max: 9,
    onChanged: (v) => setState(() => replicas = v),
  ),
  "inputs.dart:407": (context) => TermCombobox<String>(
    labelText: 'branch',
    options: branches,
    onSelected: (b) => setState(() => branch = b),
  ),
  "inputs.dart:528": (context) => TermTagInput<String>(
    labelText: 'regions',
    values: regions,
    options: allRegions,
    onChanged: (v) => setState(() => regions = v),
  ),
  "key_hint.dart:17": (context) {
    termKeyLabel(
      const SingleActivator(LogicalKeyboardKey.keyK, control: true),
    ); // ^K
    return null;
  },
  "key_hint.dart:52": (context) {
    const TermKey('^K');
    return null;
  },
  "list_tile.dart:40": (context) => TermListTile(
    leading: const Text('✓'),
    title: const Text('atlas-api'),
    subtitle: const Text('main · 2m 14s'),
    trailing: const Text('4m'),
    selected: true,
    onTap: () {},
  ),
  "list_tile.dart:88": (context) => TermListTile(
    title: const Text('atlas-api'),
    selected: true,
    onTap: open,
    action: TermIconButton(
      glyph: '⋯',
      semanticLabel: 'actions',
      onPressed: menu,
    ),
  ),
  "list_tile.dart:385": (context) =>
      const TermSectionHeader(title: 'recent runs', trailing: '12'),
  "navigation.dart:110": (context) => TermTabBar(
    tabs: const ['steps', 'log', 'env'],
    selectedIndex: tab,
    onTap: (index) => setState(() => tab = index),
  ),
  "navigation.dart:253": (context) => TermTopBar(
    title: 'slipway',
    subtitle: 'atlas-api › runs',
    actions: [
      TermIconButton(glyph: '/', semanticLabel: 'Search', onPressed: () {}),
    ],
  ),
  "navigation.dart:467": (context) => TermNavigationBar(
    destinations: const [
      TermNavigationDestination(label: 'home'),
      TermNavigationDestination(label: 'runs'),
    ],
    selectedIndex: 0,
    onDestinationSelected: (index) {},
  ),
  "navigation.dart:649": (context) => TermSideBar(
    title: 'slipway',
    destinations: destinations,
    selectedIndex: 0,
    onDestinationSelected: (index) {},
  ),
  "navigation.dart:761": (context) => const TermStatusLine(
    mode: 'RUNS',
    segments: [
      TermStatusSegment('atlas-api'),
      TermStatusSegment('\u{E0A0} main'),
    ],
    keys: [(keys: '^K', label: 'palette')],
  ),
  "notice.dart:23": (context) => TermBanner(
    tone: TermTone.error,
    message: 'connection lost · showing the runs from 2 min ago',
    action: TermButton(label: 'retry', onPressed: retry),
  ),
  "notice.dart:130": (context) => TermEmptyState(
    title: 'no runs match "mobile-gatway"',
    message: 'try fewer letters, or another branch',
    action: TermButton(label: 'clear search', onPressed: clear),
  ),
  "overlays.dart:101": (context) {
    return TermButton(
      label: 'open',
      onPressed: () {
        showTermSideSheet<void>(
          context: context,
          builder: (context) =>
              const TermSideSheet(title: 'run #1482', child: RunDetails()),
        );
      },
    );
  },
  "overlays.dart:163": (context) {
    return TermButton(
      label: 'open',
      onPressed: () async {
        final what = await showTermActionSheet<String>(
          context: context,
          title: 'run #1482',
          actions: const [
            TermSheetAction(label: 'rerun', value: 'rerun'),
            TermSheetAction(
              label: 'delete logs',
              value: 'delete',
              isDestructiveAction: true,
            ),
          ],
        );
        what?.length;
      },
    );
  },
  "overlays.dart:303": (context) => TermPopover(
    anchorBuilder: (context, anchor) =>
        TermButton(label: 'filters', onPressed: anchor.toggle),
    builder: (context) => const FilterForm(),
  ),
  "overlays.dart:363": (context) => TermHoverCard(
    builder: (context) => const Text('4f2a91c fix the cache key'),
    child: TermLink(label: '4f2a91c', onPressed: openCommit),
  ),
  "overlays.dart:416": (context) => TermTooltip(
    message: 'rerun (r)',
    child: TermIconButton(glyph: 'r', semanticLabel: 'rerun', onPressed: rerun),
  ),
  "overlays.dart:525": (context) => TermMenu(
    anchorBuilder: (context, anchor) => TermIconButton(
      glyph: '⋯',
      semanticLabel: 'more',
      onPressed: anchor.toggle,
    ),
    items: [TermMenuItem(label: 'rerun', shortcut: 'r', onPressed: rerun)],
  ),
  "pane.dart:19": (context) => const TermPane(
    padding: TermInset(start: 2, end: 2),
    child: Text('ready'),
  ),
  "pane.dart:80": (context) => const TermPane(
    title: 'atlas-api',
    trailing: 'main',
    child: Text('last deploy 4m ago'),
  ),
  "pickers.dart:43": (context) {
    final calendar = _own(
      RawCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      ),
    );
    return TermCalendar(
      controller: calendar,
      onChanged: (day) => setState(() {}),
    );
  },
  "pickers.dart:224": (context) => TermDatePicker(
    labelText: 'freeze from',
    value: freeze,
    firstDate: DateTime(2026),
    lastDate: DateTime(2027),
    onChanged: (d) => setState(() => freeze = d),
  ),
  "pickers.dart:333": (context) => TermDateRangePicker(
    labelText: 'window',
    value: window,
    firstDate: DateTime(2026),
    lastDate: DateTime(2027),
    onChanged: (r) => setState(() => window = r),
  ),
  "pickers.dart:572": (context) => TermTimeField(
    labelText: 'deploy at',
    value: const TermTime(hour: 14, minute: 30),
    onChanged: (t) => setState(() => at = t),
  ),
  "pickers.dart:705": (context) {
    final colour = _own(RawColorController());
    return TermColorPicker(controller: colour);
  },
  "range.dart:31": (context) => TermSlider(
    semanticLabel: 'canary share',
    value: share,
    onChanged: (v) => setState(() => share = v),
  ),
  "range.dart:236": (context) => TermRangeSlider(
    values: const RawRangeValues(200, 800),
    max: 1000,
    onChanged: (v) => setState(() => latency = v),
  ),
  "range.dart:369": (context) =>
      TermMeter(value: 0.72, label: 'disk', reading: '7.2 of 10 GB'),
  "range.dart:465": (context) => TermRating(
    semanticLabel: 'how did the deploy go',
    value: stars,
    onChanged: (v) => setState(() => stars = v),
  ),
  "route.dart:30": (context) => MaterialApp(
    theme: ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: termPageTransitions,
      ),
    ),
    builder: (context, child) =>
        TermTheme(data: TermThemeData.dark(), child: child!),
    home: const Home(),
  ),
  "route.dart:78": (context) {
    return TermButton(
      label: 'open',
      onPressed: () {
        Navigator.of(context)
            .push(TermPageRoute<void>(builder: (context) => const RunPage()));
      },
    );
  },
  "select.dart:58": (context) => TermSelect<String>(
    labelText: 'environment',
    value: environment,
    items: const [
      TermSelectItem(value: 'staging', label: 'staging'),
      TermSelectItem(value: 'production', label: 'production'),
    ],
    onChanged: (value) => setState(() => environment = value),
  ),
  "selection.dart:112": (context) => TermCheckbox(
    value: autoMerge,
    label: 'merge when checks pass',
    onChanged: (value) => setState(() => autoMerge = value!),
  ),
  "selection.dart:295": (context) => RadioGroup<String>(
    groupValue: environment,
    onChanged: (value) => setState(() => environment = value),
    child: RadioGroupKeyboardFix<String>(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          TermRadio<String>(value: 'staging', label: 'staging'),
          TermRadio<String>(value: 'production', label: 'production'),
        ],
      ),
    ),
  ),
  "selection.dart:368": (context) => TermSwitch(
    value: notify,
    label: 'notify on failure',
    onChanged: (value) => setState(() => notify = value),
  ),
  "status.dart:21": (context) => const TermSkeleton(lines: 3),
  "status.dart:110": (context) => TermStatusView(
    status: TermStatus.error,
    title: "couldn't load runs",
    message: 'the server did not answer in 30s',
    action: TermButton(label: 'retry', onPressed: reload),
  ),
  "status.dart:209": (context) => TermFileField(
    labelText: 'attach logs',
    files: picked,
    onBrowse: pickFiles,
    onRemoved: (i) => setState(() => picked.removeAt(i)),
  ),
  "text_field.dart:38": (context) => TermTextField(
    labelText: 'branch',
    hintText: 'main',
    prompt: '\u{E0A0}',
    onSubmitted: (value) => deploy(value),
  ),
  "text_field.dart:87": (context) {
    final timeout = _own(TextEditingController());
    return TermTextField.inline(
      labelText: 'timeout',
      labelCols: 16,
      controller: timeout,
      errorText: valid ? null : 'a number and s, m or h',
    );
  },
  "wayfinding.dart:36": (context) => TermBreadcrumb(
    crumbs: [
      (label: '~', onPressed: goHome),
      (label: 'atlas-api', onPressed: openProject),
      (label: '#1482', onPressed: null),
    ],
  ),
  "wayfinding.dart:130": (context) => TermPagination(
    page: 5,
    pageCount: 21,
    onChanged: (p) => setState(() => page = p),
  ),
  "wayfinding.dart:280": (context) => TermPageDots(count: 5, index: 2),
  "wayfinding.dart:383": (context) => TermSteps(
    steps: const [
      (label: 'source', state: TermStepState.done),
      (label: 'test', state: TermStepState.current),
      (label: 'deploy', state: TermStepState.upcoming),
    ],
  ),
  "wayfinding.dart:502": (context) => TermMenuBar(
    menus: [
      RawMenuEntry(
        label: 'run',
        children: [
          RawMenuEntry(label: 'rerun', shortcut: 'R', onPressed: rerun),
        ],
      ),
    ],
  ),
  "wayfinding.dart:572": (context) => TermContextMenu(
    menuChildren: [
      RawMenuEntry(label: 'rerun', shortcut: 'r', onPressed: rerun),
      RawMenuEntry(label: 'copy link', onPressed: copy),
    ],
    child: const Text('run #1482'),
  ),
  "wayfinding.dart:613": (context) => TermNavigationRail(
    destinations: destinations,
    selectedIndex: 0,
    onDestinationSelected: (i) {},
  ),
  "wayfinding.dart:752": (context) => TermScaffold(
    topBar: const TermTopBar(title: 'slipway'),
    destinations: destinations,
    selectedIndex: tab,
    onDestinationSelected: (i) => setState(() => tab = i),
    body: pages[tab],
  ),
  "fonts.dart:34": (context) {
    const plex = TermFace(family: 'IBMPlexMono', advance: 0.6);
    final theme = TermThemeData.dark(face: plex);
    return theme;
  },
  "fonts.dart:103": (context) async {
    final loader = FontLoader(termRegisteredFamily(termFontFamily))
      ..addFont(bytes);
    await loader.load();
    return loader;
  },
  "fonts.dart:124": (context) async {
    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await termLoadFonts();
      runApp(const MyApp());
    }

    return main;
  },
  "grid.dart:23": (context) {
    final grid = context.termGrid;
    SizedBox(width: grid.cols(12), height: grid.lines(2));
    return grid;
  },
  "inventory.dart:48": (context) {
    termInventory.verify();
    return null;
  },
  "localizations.dart:19": (context) => Text(
    TermLocalizations.of(context)
        .avatarGroupLabel(const ['Ada Lovelace', 'Alan Turing']),
  ),
  "localizations.dart:37": (context) =>
      const DefaultTermLocalizations().avatarGroupLabel(const ['Ada Lovelace']),
  "palette.dart:17": (context) {
    final palette = TermPalette.night.copyWith(cyan: const Color(0xFF7DD3FC));
    return palette;
  },
  "style.dart:31": (context) {
    final style = TermStyle(
      foreground: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? const Color(0xFF626A76)
            : const Color(0xFFE3C46F),
      ),
    );
    return style;
  },
  "style.dart:41": (context) {
    final own = TermStyleOf([style, theme.buttonStyle], states);
    final ink = own.foreground ?? theme.foreground;
    return ink;
  },
  "theme.dart:124": (context) {
    final accent = termReadable(
      const Color(0xFF0A7D4F),
      on: TermPalette.night.background,
    );
    return accent;
  },
  "theme.dart:162": (context) {
    final theme =
        TermThemeData.from(
          TermPalette.night,
          accent: const Color(0xFF34C77B),
        ).copyWith(
          filledButtonStyle: TermStyle(
            textStyle: WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
    return theme;
  },
  "theme.dart:1524": (context) => MaterialApp(
    builder: (context, child) =>
        TermTheme(data: TermThemeData.dark(), child: child!),
    home: const Home(),
  ),
  "theme.dart:1681": (context) => AnimatedTermTheme(
    data: dark ? TermThemeData.dark() : TermThemeData.light(),
    child: child,
  ),
  "theme.dart:1752": (context) {
    const TermCells(cols: 20, lines: 1, child: Text('ready'));
    return null;
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
    // terminal_parts.dart's example is a file to copy, not code to run.
    skip: const {'terminal_parts.dart'},
    wrap: (child) => MaterialApp(
      home: Builder(
        // Loops stand still (a spinner, the caret), so each one settles.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: TermTheme(
            data: TermThemeData.dark(),
            child: TermToaster(child: child),
          ),
        ),
      ),
    ),
    size: const Size(720, 720),
  );
}
