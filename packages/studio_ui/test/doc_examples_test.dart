// lib/ui/my_card.dart, copied from package:studio_ui/src/studio/... and renamed.
import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_parts.dart';

import 'package:material_ui/material_ui.dart'
    show MaterialApp, PageTransitionsTheme, ThemeData;
import 'package:flutter/services.dart' show FontLoader, LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'doc_examples.dart';

// StudioMenuList's example passes print as its callback; nothing is chosen.
// ignore_for_file: avoid_print

// Every doc example in lib, compiled and run (ui_core's template). Each
// example (a fenced dart block in the package) is written out below as the
// body of an entry, so an example that stops compiling fails analysis; the
// first test fails when lib has an example this file lacks; the rest build
// each widget example (and run each call) in a bare app, held still so a
// spinner or a skeleton settles. The three imports at the top are
// studio_parts.dart's own example.
//
// What an example names from its page (a callback, a value it shows, the
// setState that changes it) is made in its entry first, as the page has it.

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

/// A page's setState, for the examples that change their value: here the
/// change is made and nothing rebuilds.
void setState(VoidCallback change) => change();

/// Runs [call] after the frame: a call that opens a route or a toast does it
/// from an event, never while the tree builds.
Object? _afterFrame(void Function() call) {
  WidgetsBinding.instance.addPostFrameCallback((_) => call());
  return null;
}

/// The episode title [StudioTextField]'s example keeps.
String title = '';

/// The password [StudioPasswordField]'s example keeps.
String password = '';

/// The feed address [StudioInputGroup]'s example keeps.
String feed = '';

/// The search [StudioSearchField]'s example keeps.
String query = '';

/// The lengths [StudioRangeFader]'s example keeps.
StudioRangeValues lengths = const StudioRangeValues(10, 40);

/// The start [StudioTimePicker]'s example keeps.
StudioTime start = const StudioTime(hour: 19, minute: 30);

/// The app `studioLoadFonts`' example runs.
class MyApp extends StatelessWidget {
  /// An app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// The home page the app examples open on.
class Home extends StatelessWidget {
  /// A page.
  const Home({super.key});

  @override
  Widget build(BuildContext context) => const Text('Home');
}

/// The page [StudioAppShell]'s example shows.
class HomePage extends StatelessWidget {
  /// A page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Home');
}

/// The page [StudioPage]'s example pushes.
class EpisodePage extends StatelessWidget {
  /// A page.
  const EpisodePage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Episode');
}

/// The page [StudioSheetPage]'s example raises.
class ExportPage extends StatelessWidget {
  /// A page.
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Export');
}

const _places = [
  StudioDestination(icon: Icon(LucideIcons.house), label: 'Home'),
  StudioDestination(icon: Icon(LucideIcons.libraryBig), label: 'Library'),
];

final Map<String, DocExample> _examples = {
  // fonts.dart
  'FontLoader': (context) {
    final loader = FontLoader(studioRegisteredFamily(studioFontFamily));
    return loader;
  },
  'studioLoadFonts': (context) {
    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await studioLoadFonts();
      runApp(const MyApp());
    }

    return main;
  },
  // text_field.dart
  'StudioFieldLabel': (context) => const StudioFieldLabel('Episode title'),
  'StudioFieldMessage': (context) =>
      const StudioFieldMessage(error: 'Give the episode a title.'),
  'StudioTextField': (context) => StudioTextField(
    labelText: 'Episode title',
    hintText: 'Season 2, episode 4',
    onChanged: (v) => title = v,
  ),
  // words.dart
  'StudioLocalizations': (context) {
    const rows = ['Pilot'];
    return Text(StudioLocalizations.of(context).rowCount(rows.length));
  },
  // transitions.dart
  'studioPageTransitions': (context) => ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: studioPageTransitions,
    ),
  ),
  'studioPageTransitions in an app': (context) => MaterialApp(
    theme: ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: studioPageTransitions,
      ),
    ),
    home: const Home(),
  ),
  // actions.dart
  'StudioFloatingKey': (context) {
    void record() {}
    return StudioFloatingKey(
      icon: const Icon(LucideIcons.mic),
      tooltip: 'New recording',
      onPressed: record,
    );
  },
  'StudioKeyRow': (context) {
    void cut() {}
    void split() {}
    return StudioKeyRow(
      semanticLabel: 'Clip',
      items: [
        StudioKeyRowItem(
          label: 'Cut',
          icon: const Icon(LucideIcons.scissors),
          onPressed: cut,
        ),
        StudioKeyRowItem(label: 'Split', onPressed: split),
      ],
    );
  },
  'StudioToggleBank': (context) {
    var on = <String>{'Solo'};
    return StudioToggleBank<String>(
      options: const ['Mute', 'Solo'],
      selected: on,
      labelOf: (s) => s,
      onSelectionChanged: (next) => setState(() => on = next),
    );
  },
  'StudioSplitKey': (context) {
    void exportMp3() {}
    void exportWav() {}
    return StudioSplitKey(
      label: 'Export',
      onPressed: exportMp3,
      actions: [StudioMenuItem(label: 'Export WAV', onPressed: exportWav)],
    );
  },
  'StudioLink': (context) {
    const notes = 'Recorded in one take.';
    void open(String what) {}
    return StudioLink('Show notes', onPressed: () => open(notes));
  },
  'StudioKbd': (context) =>
      const StudioKbd(['Ctrl', 'K'], semanticLabel: 'Control K'),
  'StudioKbd.shortcut': (context) => const StudioKbd.shortcut(
    SingleActivator(LogicalKeyboardKey.keyK, control: true),
  ),
  // feedback.dart
  'StudioProgressBar': (context) =>
      const StudioProgressBar(value: 0.4, semanticLabel: 'Uploading'),
  'StudioLampRing': (context) =>
      const StudioLampRing(lit: 0.6, size: 32, semanticLabel: 'Exported'),
  'StudioSpinner': (context) =>
      const StudioSpinner(size: 24, semanticLabel: 'Loading'),
  'StudioSkeleton': (context) => const StudioSkeleton(width: 200, height: 16),
  'StudioStatusView.error': (context) {
    void retry() {}
    return StudioStatusView.error(
      title: 'Upload failed',
      message: 'The connection dropped at 64%.',
      actionLabel: 'Try again',
      onAction: retry,
    );
  },
  'StudioBanner': (context) {
    void listen() {}
    void dismiss() {}
    return StudioBanner(
      message: 'A new version of the mix is ready.',
      actionLabel: 'Listen',
      onAction: listen,
      onClose: dismiss,
    );
  },
  // select.dart
  'StudioSelect': (context) {
    String? q = 'hi';
    return StudioSelect<String>(
      labelText: 'Quality',
      value: q,
      items: const [StudioSelectItem(value: 'hi', label: 'High')],
      onChanged: (v) => setState(() => q = v),
    );
  },
  'StudioMenuList': (context) => const StudioMenuList<int>(
    items: [StudioMenuEntry(value: 1, label: 'One')],
    value: 1,
    onChosen: print,
  ),
  'StudioListBezel': (context) {
    const rows = [Text('Pilot'), Text('The long table')];
    return const StudioListBezel(child: Column(children: rows));
  },
  'StudioMenuRow': (context) {
    const states = <WidgetState>{};
    return const StudioMenuRow(
      label: 'High',
      states: states,
      chosen: true,
      showLamp: true,
    );
  },
  // lists.dart
  'StudioSectionHeader': (context) =>
      const StudioSectionHeader('Audio quality'),
  'StudioListGroup': (context) {
    const on = true;
    void set(bool value) {}
    return StudioListGroup(
      header: 'Notifications',
      children: [
        StudioListTile.toggle(title: 'New episodes', value: on, onChanged: set),
      ],
    );
  },
  'StudioListTile': (context) {
    void pick() {}
    return StudioListTile(
      title: 'Audio quality',
      trailingText: 'High',
      onTap: () => pick(),
    );
  },
  // charts.dart
  'StudioSeries': (context) => const StudioSeries('Plays', [120, 180, 150]),
  'StudioLineChart': (context) => const StudioLineChart(
    semanticLabel: 'Plays by day',
    labels: ['Mon', 'Tue', 'Wed'],
    series: [
      StudioSeries('Plays', [120, 180, 150]),
    ],
  ),
  'StudioAreaChart': (context) {
    const days = ['Mon', 'Tue', 'Wed'];
    const listeners = <double>[40, 64, 52];
    return const StudioAreaChart(
      semanticLabel: 'Listeners',
      labels: days,
      series: [StudioSeries('Listeners', listeners)],
    );
  },
  'StudioBarChart': (context) => const StudioBarChart(
    semanticLabel: 'Downloads by episode',
    labels: ['1', '2', '3'],
    series: [
      StudioSeries('Downloads', [340, 410, 290]),
    ],
  ),
  'StudioPieChart': (context) => const StudioPieChart(
    semanticLabel: 'Listening by device',
    slices: [
      StudioSlice('Phone', 62),
      StudioSlice('Desktop', 28),
      StudioSlice('Speaker', 10),
    ],
  ),
  'StudioSparkline': (context) => const StudioSparkline(
    values: [3, 5, 4, 8, 7, 11],
    semanticLabel: 'Plays this week, rising',
  ),
  // choices.dart
  'StudioCheckbox': (context) {
    var explicit = false;
    return StudioCheckbox(
      value: explicit,
      onChanged: (v) => setState(() => explicit = v),
      semanticLabel: 'Explicit',
    );
  },
  'StudioCheckRow': (context) {
    var done = false;
    return StudioCheckRow(
      label: 'Done',
      value: done,
      onChanged: (v) => setState(() => done = v),
    );
  },
  'StudioRadio': (context) {
    String? format = 'mp3';
    return StudioRadio<String>(
      value: 'mp3',
      groupValue: format,
      onChanged: (v) => setState(() => format = v),
      semanticLabel: 'MP3',
    );
  },
  'StudioRadioGroup': (context) {
    String? format = 'mp3';
    return StudioRadioGroup<String>(
      options: const ['mp3', 'aac', 'wav'],
      value: format,
      labelOf: (f) => f.toUpperCase(),
      onChanged: (f) => setState(() => format = f),
    );
  },
  'StudioSwitch': (context) {
    var notify = true;
    return StudioSwitch(
      value: notify,
      onChanged: (v) => setState(() => notify = v),
      semanticLabel: 'New episodes',
    );
  },
  'StudioSegmentedButton': (context) {
    var speed = 1.0;
    return StudioSegmentedButton<double>(
      segments: const [
        StudioSegment(value: 1, label: '1×'),
        StudioSegment(value: 1.5, label: '1.5×'),
      ],
      value: speed,
      onChanged: (v) => setState(() => speed = v),
    );
  },
  // menu.dart
  'StudioMenuItem': (context) {
    void rename() {}
    return StudioMenuItem(
      label: 'Rename',
      icon: const Icon(LucideIcons.pencil),
      onPressed: rename,
    );
  },
  'StudioMenu': (context) {
    void rename() {}
    return StudioMenu(
      items: [StudioMenuItem(label: 'Rename', onPressed: rename)],
      builder: (context, toggle, open) => StudioIconButton(
        icon: const Icon(LucideIcons.ellipsis),
        tooltip: 'More',
        selected: open,
        onPressed: toggle,
      ),
    );
  },
  'StudioMenuBarMenu': (context) {
    void create() {}
    return StudioMenuBarMenu('Episode', [
      StudioMenuItem(label: 'New', shortcut: '⌘ N', onPressed: create),
    ]);
  },
  'StudioMenuBar': (context) {
    void create() {}
    return StudioMenuBar(
      menus: [
        StudioMenuBarMenu('Episode', [
          StudioMenuItem(label: 'New', onPressed: create),
        ]),
      ],
    );
  },
  'StudioCommand': (context) {
    void create() {}
    return StudioCommand(
      label: 'New episode',
      group: 'Episodes',
      shortcut: '⌘ N',
      onPressed: create,
    );
  },
  'StudioCommandPalette': (context) {
    final commands = [StudioCommand(label: 'New episode', onPressed: () {})];
    return StudioCommandPalette(
      commands: commands,
      onSelected: (c) => c.onPressed?.call(),
    );
  },
  'showStudioCommandPalette': (context) {
    final commands = [StudioCommand(label: 'New episode', onPressed: () {})];
    return _afterFrame(
      () => showStudioCommandPalette(context, commands: commands),
    );
  },
  // overlays.dart
  'showStudioDialog': (context) => _afterFrame(
    () => showStudioDialog<bool>(
      context: context,
      builder: (context) => StudioDialog(
        title: 'Discard this take?',
        actions: [
          StudioButton('Keep', onPressed: () => Navigator.pop(context, false)),
        ],
      ),
    ),
  ),
  'StudioDialog': (context) {
    void keep() {}
    void discard() {}
    return StudioDialog(
      title: 'Discard this take?',
      content: const Text('The 4 minutes you recorded will be gone.'),
      actions: [
        StudioButton('Keep', onPressed: keep),
        StudioButton.lit(
          'Discard',
          isDestructiveAction: true,
          onPressed: discard,
        ),
      ],
    );
  },
  'showStudioBottomSheet': (context) => _afterFrame(
    () => showStudioBottomSheet<void>(
      context: context,
      title: 'Export',
      builder: (context) => const Text('MP3, 128 kbps'),
    ),
  ),
  'StudioSheetPage': (context) {
    const state = (pageKey: ValueKey<String>('/export'));
    return StudioSheetPage<void>(
      key: state.pageKey,
      drawer: true,
      child: const ExportPage(),
    );
  },
  'StudioSheet': (context) =>
      const StudioSheet(title: 'Export', child: Text('MP3, 128 kbps')),
  'StudioToaster': (context) {
    const app = Text('Roomtone');
    return const StudioToaster(child: app);
  },
  'showStudioToast': (context) => _afterFrame(
    () => showStudioToast(
      context,
      'Marker added at 12:04',
      actionLabel: 'Undo',
      onAction: () {},
    ),
  ),
  // panel.dart
  'StudioPanel': (context) {
    void mark() {}
    return StudioPanel(
      child: Row(children: [StudioButton('Mark', onPressed: mark)]),
    );
  },
  'StudioDisplay': (context) {
    const episode = (notes: 'Recorded in one take.');
    return StudioDisplay(child: Text(episode.notes));
  },
  // button.dart
  'StudioButton.lit': (context) {
    void publish() {}
    return StudioButton.lit('Publish', onPressed: () => publish());
  },
  'StudioIconButton': (context) => StudioIconButton(
    icon: const Icon(LucideIcons.chevronLeft),
    tooltip: 'Back',
    onPressed: () => Navigator.pop(context),
  ),
  'StudioTransportKey': (context) {
    void play() {}
    return StudioTransportKey(
      icon: const Icon(LucideIcons.play),
      tooltip: 'Play',
      onPressed: play,
    );
  },
  // display.dart
  'StudioDisclosure': (context) {
    const notes = 'Recorded in one take.';
    return const StudioDisclosure(title: 'Show notes', child: Text(notes));
  },
  'StudioTable': (context) => const StudioTable(
    columns: [
      StudioTableColumn('Episode'),
      StudioTableColumn('Plays', numeric: true),
    ],
    rows: [
      ['Pilot', '1,204'],
    ],
  ),
  'StudioDescriptionList': (context) => const StudioDescriptionList(
    entries: [
      StudioDescription('Length', '42 min'),
      StudioDescription('Format', 'Stereo, 48 kHz'),
    ],
  ),
  'StudioTimeline': (context) => const StudioTimeline(
    entries: [
      StudioTimelineEntry(title: 'Recorded', time: 'Mon 14:00', done: true),
      StudioTimelineEntry(title: 'Published', time: 'Thu 09:00'),
    ],
  ),
  'StudioAvatar': (context) => const StudioAvatar(name: 'Noor Haddad'),
  'StudioAvatarGroup': (context) => const StudioAvatarGroup(
    names: ['Noor Haddad', 'Teo Park', 'Ama Boateng'],
  ),
  'StudioBadge': (context) =>
      const StudioBadge(count: 3, child: Icon(LucideIcons.bell)),
  'StudioTag': (context) => const StudioTag('On air', tone: StudioTagTone.lit),
  'StudioMedia': (context) => const StudioMedia(
    image: AssetImage('assets/cover.jpg'),
    semanticLabel: 'The cover: a microphone in a dark room',
  ),
  // controls.dart
  'StudioFader': (context) {
    const position = 12.0;
    const length = 42.0;
    void seek(double to) {}
    return StudioFader(
      value: position,
      max: length,
      onChanged: (v) => seek(v),
      semanticLabel: 'Position',
    );
  },
  'StudioKnob': (context) {
    var gain = 0.5;
    return StudioKnob(
      value: gain,
      onChanged: (v) => setState(() => gain = v),
      semanticLabel: 'Input gain',
    );
  },
  'StudioMeter': (context) {
    const left = 0.62;
    const leftPeak = 0.8;
    return const StudioMeter(
      level: left,
      peak: leftPeak,
      semanticLabel: 'Left channel',
    );
  },
  // wayfinding.dart
  'StudioCrumb': (context) {
    const library = '/library';
    void go(String place) {}
    return StudioCrumb('Library', onPressed: () => go(library));
  },
  'StudioBreadcrumb': (context) {
    void back() {}
    return StudioBreadcrumb(
      crumbs: [
        StudioCrumb('Library', onPressed: back),
        const StudioCrumb('Season 2'),
      ],
    );
  },
  'StudioPagination': (context) {
    var page = 1;
    return StudioPagination(
      page: page,
      pageCount: 12,
      onChanged: (p) => setState(() => page = p),
    );
  },
  'StudioStepProgress': (context) => const StudioStepProgress(
    steps: ['Record', 'Edit', 'Publish'],
    currentStep: 1,
  ),
  'StudioPageDots': (context) {
    const page = 0;
    void goTo(int index) {}
    return StudioPageDots(count: 4, index: page, onChanged: goTo);
  },
  // pickers.dart
  'StudioDateRange': (context) => StudioDateRange(
    start: DateTime(2026, 11, 14),
    end: DateTime(2026, 11, 16),
  ),
  'StudioTime': (context) => const StudioTime(hour: 19, minute: 30),
  'StudioCalendar': (context) {
    DateTime? day = DateTime(2026, 11, 16);
    return StudioCalendar(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      selectedDate: day,
      onDateChanged: (d) => setState(() => day = d),
    );
  },
  'StudioDatePicker': (context) {
    DateTime? day = DateTime(2026, 11, 16);
    return StudioDatePicker(
      labelText: 'Release date',
      value: day,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      onChanged: (d) => setState(() => day = d),
    );
  },
  'StudioDateRangePicker': (context) {
    StudioDateRange? span;
    return StudioDateRangePicker(
      labelText: 'Recording days',
      value: span,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      onChanged: (r) => setState(() => span = r),
    );
  },
  'StudioWheelPicker': (context) {
    var takes = 2;
    return StudioWheelPicker<int>(
      items: const [1, 2, 3, 4],
      value: takes,
      labelOf: (n) => '$n',
      semanticLabel: 'Takes',
      onChanged: (n) => setState(() => takes = n),
    );
  },
  'StudioTimePicker': (context) => StudioTimePicker(
    value: const StudioTime(hour: 19, minute: 30),
    onChanged: (t) => setState(() => start = t),
  ),
  'StudioColorPicker': (context) {
    var tint = const Color(0xFFE8A33D);
    return StudioColorPicker(
      value: tint,
      onChanged: (c) => setState(() => tint = c),
    );
  },
  'StudioRangeValues': (context) => const StudioRangeValues(10, 40),
  'StudioRangeFader': (context) => StudioRangeFader(
    values: const StudioRangeValues(10, 40),
    max: 60,
    startLabel: 'Shortest',
    endLabel: 'Longest',
    onChanged: (v) => setState(() => lengths = v),
  ),
  'StudioChip': (context) {
    var interviews = false;
    return StudioChip(
      label: 'Interviews',
      selected: interviews,
      onSelected: (on) => setState(() => interviews = on),
    );
  },
  'StudioRating': (context) {
    var stars = 4;
    return StudioRating(
      value: stars,
      semanticLabel: 'Your rating',
      onChanged: (v) => setState(() => stars = v),
    );
  },
  'StudioFile': (context) =>
      const StudioFile(name: 'take-3.wav', bytes: 48200000, progress: 0.4),
  'StudioFileDrop': (context) {
    final files = [const StudioFile(name: 'take-3.wav', bytes: 48200000)];
    void pick() {}
    return StudioFileDrop(
      labelText: 'Audio',
      hintText: 'WAV or MP3, up to 500 MB',
      files: files,
      onChoose: pick,
      onRemove: (f) => setState(() => files.remove(f)),
    );
  },
  // navigation.dart
  'StudioAppBar': (context) {
    void search() {}
    return StudioAppBar(
      title: 'Library',
      actions: [
        StudioIconButton(
          icon: const Icon(LucideIcons.search),
          tooltip: 'Search',
          onPressed: search,
        ),
      ],
    );
  },
  'StudioAppBar.autoLeading': (context) => StudioAppBar(
    title: 'Episode',
    leading: StudioAppBar.autoLeading(context),
  ),
  'StudioNavigationBar': (context) {
    const places = _places;
    const tab = 0;
    void go(int index) {}
    return StudioNavigationBar(
      destinations: places,
      selectedIndex: tab,
      onDestinationSelected: go,
    );
  },
  'StudioNavigationRail': (context) {
    const places = _places;
    const tab = 0;
    void go(int index) {}
    return StudioNavigationRail(
      destinations: places,
      selectedIndex: tab,
      onDestinationSelected: go,
    );
  },
  'StudioSideNavigation': (context) {
    const places = _places;
    const tab = 0;
    void go(int index) {}
    return StudioSideNavigation(
      header: const Text('Roomtone'),
      destinations: places,
      selectedIndex: tab,
      onDestinationSelected: go,
    );
  },
  'StudioTabBar': (context) {
    var tab = 0;
    return StudioTabBar(
      tabs: const ['Notes', 'Chapters'],
      selectedIndex: tab,
      onChanged: (i) => setState(() => tab = i),
    );
  },
  'StudioScaffold': (context) {
    const places = _places;
    const tab = 0;
    const page = Text('Three new episodes since Monday.');
    void go(int index) {}
    return StudioScaffold(
      destinations: places,
      selectedIndex: tab,
      onDestinationSelected: go,
      appBar: const StudioAppBar(title: 'Home'),
      body: page,
    );
  },
  // popovers.dart
  'StudioPopover': (context) {
    const speedControls = Text('1×, 1.5×, 2×');
    return StudioPopover(
      builder: (context, toggle, open) =>
          StudioButton('Speed', onPressed: toggle),
      content: (context, close) => speedControls,
    );
  },
  'StudioHoverCard': (context) {
    const hostDetails = Text('Host of Night Desk since 2024.');
    void openHost() {}
    return StudioHoverCard(
      content: (context) => hostDetails,
      child: StudioLink('Noor Haddad', onPressed: openHost),
    );
  },
  'StudioTooltip': (context) {
    const skipBackKey = Icon(LucideIcons.rotateCcw);
    return const StudioTooltip(
      message: 'Skip back 15 seconds',
      child: skipBackKey,
    );
  },
  'showStudioSideSheet': (context) {
    const filters = Text('Unplayed only');
    return _afterFrame(
      () => showStudioSideSheet<void>(
        context: context,
        title: 'Filters',
        builder: (context) => filters,
      ),
    );
  },
  'showStudioActionSheet': (context) => _afterFrame(
    () => showStudioActionSheet<String>(
      context: context,
      title: 'This take',
      actions: const [
        StudioSheetAction(label: 'Keep', value: 'keep'),
        StudioSheetAction(
          label: 'Discard',
          value: 'discard',
          isDestructiveAction: true,
        ),
      ],
    ),
  ),
  // app.dart
  'StudioHost': (context) =>
      // The app itself is not run here: it has no home, so its builder's
      // child is the navigator an app with routes would give it.
      () => MaterialApp(builder: (context, child) => StudioHost(child: child!)),
  'StudioScreen': (context) => const StudioScreen(
    topBar: StudioAppBar(title: 'Episode'),
    body: Text('Recorded in one take.'),
  ),
  'StudioPage': (context) {
    const state = (pageKey: ValueKey<String>('/episode'));
    return StudioPage<void>(key: state.pageKey, child: const EpisodePage());
  },
  'StudioPreview': (context) => const StudioPreview(
    presentation: StudioPresentation.pushed,
    child: StudioScreen(body: Text('Recorded in one take.')),
  ),
  'StudioAppShell': (context) => StudioAppShell(
    tabs: const [
      StudioTab(LucideIcons.house, 'Home'),
      StudioTab(LucideIcons.mic, 'Record'),
    ],
    selectedIndex: 0,
    onSelected: (i) {},
    child: const HomePage(),
  ),
  'StudioTab': (context) =>
      const StudioTab(LucideIcons.house, 'Home', ValueKey('open-home')),
  'StudioShellAction': (context) {
    void startRecording(BuildContext context) {}
    return StudioShellAction(
      icon: LucideIcons.mic,
      accent: true,
      onPressed: (context) => startRecording(context),
    );
  },
  'StudioLoadingState': (context) => const StudioLoadingState(),
  'StudioErrorState': (context) {
    void reload() {}
    return StudioErrorState(
      title: 'Could not load',
      message: 'Check your connection.',
      onRetry: reload,
    );
  },
  'StudioInput': (context) {
    void search(String words) {}
    return StudioInput(hintText: 'Search episodes', onSubmitted: search);
  },
  // surface.dart
  'StudioSurface': (context) {
    final colors = StudioTheme.of(context).colors;
    return StudioSurface(
      face: StudioFace(
        fill: colors.key,
        fillLow: colors.keyLow,
        depth: StudioDepth.raised,
      ),
      child: const Text('Key'),
    );
  },
  'AnimatedStudioSurface': (context) {
    final resting = StudioTheme.of(context).colors.keyFace;
    Widget key({required bool pressed}) => AnimatedStudioSurface(
      face: pressed ? resting.copyWith(travel: 1) : resting,
      child: const Text('Play'),
    );
    return key(pressed: true);
  },
  'StudioLamp': (context) {
    final colors = StudioTheme.of(context).colors;
    const recording = true;
    return StudioLamp(on: recording, color: colors.danger);
  },
  'StudioReadout': (context) => const StudioReadout('1:24:05'),
  'StudioGroove': (context) => const StudioGroove(),
  'StudioLegend': (context) => const StudioLegend('Audio quality'),
  // theme.dart
  'StudioStyle': (context) {
    const wide = StudioStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)),
    );
    return StudioButton('Export', style: wide, onPressed: () {});
  },
  'studioContrast': (context) {
    final colors = StudioTheme.of(context).colors;
    // The example of a deprecated function, kept while it is.
    // ignore: deprecated_member_use_from_same_package
    final readable = studioContrast(colors.onDisplay, colors.display) >= 4.5;
    return readable;
  },
  'StudioThemeData.from': (context) {
    final theme = StudioThemeData.from(indicator: const Color(0xFF4FD1C5));
    return theme;
  },
  'StudioThemeData.preset': (context) {
    final theme = StudioThemeData.preset('cobalt', Brightness.dark);
    return theme;
  },
  'StudioTheme': (context) => MaterialApp(
    builder: (context, child) =>
        StudioTheme(data: StudioThemeData.dark(), child: child!),
    home: const Home(),
  ),
  'AnimatedStudioTheme': (context) {
    const page = Text('Night Desk');
    Widget room({required bool night}) => AnimatedStudioTheme(
      data: night ? StudioThemeData.dark() : StudioThemeData.light(),
      child: page,
    );
    return room(night: true);
  },
  // entry.dart
  'StudioSearchField': (context) => StudioSearchField(
    hintText: 'Search episodes',
    onChanged: (q) => setState(() => query = q),
  ),
  'StudioPasswordField': (context) => StudioPasswordField(
    labelText: 'Password',
    onChanged: (v) => password = v,
  ),
  'StudioInputGroup': (context) => StudioInputGroup(
    labelText: 'Feed address',
    leading: const Text('https://'),
    hintText: 'roomtone.example/feed',
    onChanged: (v) => feed = v,
  ),
  'StudioCodeField': (context) {
    void verify(String code) {}
    return StudioCodeField(
      length: 6,
      semanticLabel: 'Sign-in code',
      onCompleted: verify,
    );
  },
  'StudioStepper': (context) {
    var copies = 1;
    return StudioStepper(
      value: copies,
      min: 1,
      max: 9,
      semanticLabel: 'Copies',
      onChanged: (v) => setState(() => copies = v),
    );
  },
  'StudioFormField': (context) {
    const time = StudioTime(hour: 7, minute: 0);
    void setTime(StudioTime to) {}
    return StudioFormField(
      labelText: 'Publish at',
      helperText: "Your listeners' time",
      child: StudioTimePicker(
        value: time,
        semanticLabel: 'Publish at',
        onChanged: setTime,
      ),
    );
  },
  'StudioCombobox': (context) {
    const shows = ['Night Desk', 'Field Notes'];
    String? show;
    return StudioCombobox<String>(
      labelText: 'Show',
      options: shows,
      labelOf: (s) => s,
      value: show,
      onSelected: (s) => setState(() => show = s),
    );
  },
  'StudioTagInput': (context) {
    const allTopics = ['Sound', 'Rooms', 'Craft'];
    var topics = ['Sound'];
    return StudioTagInput<String>(
      labelText: 'Topics',
      values: topics,
      options: allTopics,
      labelOf: (t) => t,
      onChanged: (next) => setState(() => topics = next),
    );
  },
  // collections.dart
  'StudioDataTable': (context) {
    final table = _own(
      StudioTableController<Map<String, String>>(
        rows: const [
          {'title': 'Pilot', 'plays': '1,204'},
        ],
        columns: [
          const StudioDataColumn(id: 'title', label: 'Episode'),
          const StudioDataColumn(id: 'plays', label: 'Plays'),
        ],
      ),
    );
    return StudioDataTable<Map<String, String>>(
      controller: table,
      cell: (row, id) => row[id] ?? '',
    );
  },
  'StudioScrollArea': (context) {
    final scroll = _own(ScrollController());
    const rows = [Text('Pilot'), Text('The long table')];
    return StudioScrollArea(
      controller: scroll,
      child: ListView(controller: scroll, children: rows),
    );
  },
  'StudioSplitView': (context) {
    const episodes = Text('Episodes');
    const notes = Text('Notes');
    return const StudioSplitView(
      first: episodes,
      second: notes,
      initialFraction: 0.4,
    );
  },
  'StudioCarousel': (context) {
    const covers = [Text('Night Desk'), Text('Field Notes')];
    return StudioCarousel(
      itemCount: covers.length,
      itemBuilder: (context, i) => covers[i],
      semanticLabel: 'Featured shows',
    );
  },
  'StudioReorderableList': (context) {
    final queue = ['Pilot', 'The long table'];
    return StudioReorderableList<String>(
      items: queue,
      labelOf: (s) => s,
      onReorder: (from, to) =>
          setState(() => queue.insert(to, queue.removeAt(from))),
      itemBuilder: (context, s) => Text(s),
    );
  },
  'StudioSwipeRow': (context) {
    const row = Text('Episode 11');
    void delete() {}
    return StudioSwipeRow(
      endActions: [
        StudioSwipeAction(
          label: 'Delete',
          icon: const Icon(LucideIcons.trash2),
          destructive: true,
          onPressed: delete,
        ),
      ],
      child: row,
    );
  },
  'StudioPullToRefresh': (context) {
    Future<void> reload() async {}
    const rows = [Text('Pilot'), Text('The long table')];
    return StudioPullToRefresh(
      onRefresh: reload,
      child: ListView(children: rows),
    );
  },
  'StudioTree': (context) {
    final folders = _own(
      StudioTreeController<String>(
        roots: const ['Shows'],
        childrenOf: (path) => path == 'Shows' ? const ['Shows/Night Desk'] : [],
      ),
    );
    return StudioTree<String>(
      controller: folders,
      labelOf: (path) => path.split('/').last,
    );
  },
};

/// The bare app each example runs in: the look's host above the navigator,
/// held still (a spinner, a skeleton and a waiting bar stand still, as they do
/// for someone who asked for less motion), so every example settles.
Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [
    StudioLocalizations.delegate,
    RawWidgetsLocalizations.delegate,
  ],
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: StudioHost(child: page!),
  ),
  home: child,
);

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
    wrap: _app,
  );
}
