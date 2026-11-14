// One executable fixture per exported widget, shared by the tests that sweep the whole library: shapes under every
// corner family, and text styled under a bare app.
import 'package:material_ui/material_ui.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';
import 'package:neumorphism_ui/src/neumorphism/chart.dart' show NeumorphicChart;
import 'package:neumorphism_ui/src/neumorphism/controls.dart'
    show NeumorphicTapFace;
import 'package:neumorphism_ui/src/neumorphism/internal/error_line.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/panel.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/text_entry.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../example/lib/demo_art.dart';

/// A callback that does nothing, so a fixture is enabled.
void hit() {}

/// The entry seat's focus, one for every fixture that builds it.
final _seatFocus = FocusNode();

/// A part that answers a registry row is built as the registry builds it: its specimen, at the height the gallery
/// gives one that fills what it is given. A fixture written out below takes its place.
Map<String, Widget Function(BuildContext)> _registryFixtures() => {
  for (final entry in neumorphicInventory.entries)
    if (entry.builder case final build?)
      'Neumorphic${entry.row}': (context) {
        final height = neumorphicInventoryHeights[entry.row];
        final specimen = build(context);
        return height == null
            ? specimen
            : SizedBox(height: height, child: specimen);
      },
};

/// One real, executable use of every exported widget, built in the theme it reads.
final neumorphicFixtures = <String, Widget Function(BuildContext)>{
  ..._registryFixtures(),
  'NeumorphicInventoryGallery': (context) =>
      const SizedBox(height: 600, child: NeumorphicInventoryGallery()),
  'NeumorphicToaster': (context) => const SizedBox(
    height: 200,
    child: NeumorphicToaster(child: Text('Content')),
  ),
  'NeumorphicPanel': (context) => const NeumorphicPanel(child: Text('Content')),
  'NeumorphicPanelRow': (context) =>
      const NeumorphicPanelRow(label: 'Bedroom', states: {}),
  'NeumorphicErrorLine': (context) =>
      const NeumorphicErrorLine(child: Text('Enter an email address.')),
  'NeumorphicEntrySeat': (context) => NeumorphicEntrySeat(
    height: 48,
    focusNode: _seatFocus,
    label: 'Email',
    child: const Text('Content'),
  ),
  'NeumorphicTapFace': (context) =>
      const NeumorphicTapFace(states: {}, child: Text('Content')),
  'AnimatedNeumorphicShape': (context) => AnimatedNeumorphicShape(
    shape: NeumorphicTheme.of(context).shapes.corner(12),
    builder: (_, shape) => DecoratedBox(
      decoration: ShapeDecoration(shape: shape!),
      child: const Text('Content'),
    ),
  ),
  'AnimatedNeumorphicTheme': (context) => AnimatedNeumorphicTheme(
    data: NeumorphicTheme.of(context),
    child: const Text('Content'),
  ),
  'NeumorphicButton.filled': (context) =>
      NeumorphicButton.filled('Save', onPressed: hit),
  'NeumorphicAppBar': (context) => const NeumorphicAppBar(title: 'Title'),
  'NeumorphicAutoRow': (context) =>
      const NeumorphicAutoRow(children: [Text('First'), Text('Second')]),
  'NeumorphicAvatar': (context) => const NeumorphicAvatar('NWA'),
  'NeumorphicBackButton': (context) => NeumorphicBackButton(onPressed: hit),
  'NeumorphicBadge': (context) => const NeumorphicBadge(123),
  'NeumorphicBalancedText': (context) => const NeumorphicBalancedText(
    'A balanced title',
    style: TextStyle(fontSize: 24),
  ),
  'NeumorphicBeside': (context) => NeumorphicBeside(
    object: const SizedBox.square(dimension: 48),
    child: const Text('Content'),
  ),
  'NeumorphicBottomSheet': (context) => SizedBox(
    height: 300,
    child: NeumorphicBottomSheet(
      title: 'Options',
      onClose: hit,
      child: const Text('Choose'),
    ),
  ),
  'NeumorphicBrandMark': (context) => const NeumorphicBrandMark(),
  'NeumorphicBrandRow': (context) => const NeumorphicBrandRow('Workspace'),
  'NeumorphicButton': (context) => NeumorphicButton('Save', onPressed: hit),
  'NeumorphicCard': (context) =>
      const NeumorphicCard(title: 'Details', children: [Text('Content')]),
  'NeumorphicPieChart': (context) => const NeumorphicPieChart(
    label: 'Time',
    slices: [
      NeumorphicPieSlice('Work', 6),
      NeumorphicPieSlice('Rest', 2),
      NeumorphicPieSlice('Travel', 1),
      NeumorphicPieSlice('Other', 1),
    ],
    caption: 'hours',
  ),
  'NeumorphicSparkline': (context) =>
      const NeumorphicSparkline(label: 'Steps', values: [4, 6, 5, 7]),
  'NeumorphicPagination': (context) =>
      NeumorphicPagination(count: 12, page: 5, onChanged: (_) {}),
  'NeumorphicBreadcrumb': (context) => NeumorphicBreadcrumb(
    crumbs: [
      NeumorphicCrumb('Home', onPressed: hit),
      NeumorphicCrumb('Rooms', onPressed: hit),
      const NeumorphicCrumb('Kitchen'),
    ],
  ),
  'NeumorphicCarouselView': (context) => const NeumorphicCarouselView(
    label: 'Rooms',
    height: 120,
    children: [
      NeumorphicCard(title: 'Kitchen', children: [Text('Lights on')]),
      NeumorphicCard(title: 'Hall', children: [Text('Quiet')]),
    ],
  ),
  'NeumorphicRating': (context) =>
      NeumorphicRating(label: 'Rating', value: 3, onChanged: (_) {}),
  'NeumorphicFileUpload': (context) => NeumorphicFileUpload(
    hint: 'PDF or image',
    onPressed: hit,
    files: const ['plan.pdf'],
    onRemove: (_) {},
  ),
  'NeumorphicChart': (context) => const NeumorphicChart(
    label: 'Hours',
    series: [
      NeumorphicChartSeries('Work', [2, 4, 3]),
    ],
    labels: ['Mon', 'Tue', 'Wed'],
  ),
  'NeumorphicLegend': (context) =>
      const NeumorphicLegend([NeumorphicLegendItem('Used')]),
  'NeumorphicRoundCheckbox': (context) =>
      NeumorphicRoundCheckbox(onChanged: (_) => hit()),
  'NeumorphicCheckRow': (context) =>
      NeumorphicCheckRow(value: false, label: 'Agree', onChanged: (_) => hit()),
  'NeumorphicCheckbox': (context) =>
      NeumorphicCheckbox(value: false, label: 'Agree', onChanged: (_) => hit()),
  'NeumorphicChip': (context) => NeumorphicChip('All', onPressed: hit),
  'NeumorphicChoiceBox': (context) =>
      NeumorphicChoiceBox(onPressed: hit, child: const Text('One')),
  'NeumorphicChoices': (context) => NeumorphicChoices(
    options: const [NeumorphicChoice('One')],
    onChanged: (_) => hit(),
  ),
  'NeumorphicChromeScope': (context) => const NeumorphicChromeScope(
    brand: NeumorphicBrand(name: 'Workspace'),
    nav: [],
    active: 0,
    child: Text('Page'),
  ),
  'NeumorphicCircularProgressIndicator': (context) =>
      const NeumorphicCircularProgressIndicator(value: .5),
  'NeumorphicInputOtp': (context) =>
      NeumorphicInputOtp(label: 'Code', onChanged: (_) => hit()),
  'NeumorphicColumn': (context) =>
      const NeumorphicColumn(children: [Text('First'), Text('Second')]),
  'NeumorphicColumnBars': (context) => const NeumorphicColumnBars(
    values: [2, 4, 1],
    labels: ['Mon', 'Tue', 'Wed'],
    now: 2,
    forecast: 3,
  ),
  'NeumorphicButton (destructive)': (context) =>
      NeumorphicButton('Delete', isDestructiveAction: true, onPressed: hit),
  'NeumorphicDatePicker': (context) => NeumorphicDatePicker(
    value: DateTime(2026, 11, 6),
    first: DateTime(2026, 11, 6),
    last: DateTime(2026, 11, 6),
    onChanged: (_) => hit(),
  ),
  'NeumorphicDayTray': (context) => const NeumorphicDayTray(
    from: 8,
    to: 10,
    events: [
      NeumorphicTrayEvent(
        start: '08:00',
        end: '09:00',
        title: 'Reading',
        subtitle: 'At home',
      ),
    ],
    free: [NeumorphicTrayFree('09:00', '10:00', 'Free')],
  ),
  'NeumorphicDial': (context) => NeumorphicDial(
    value: 40,
    figure: '40',
    compact: true,
    onDecrease: hit,
    onIncrease: hit,
  ),
  'NeumorphicDisclosure': (context) => NeumorphicDisclosure(
    title: 'Details',
    expanded: false,
    onExpansionChanged: (_) => hit(),
    child: const Text('More'),
  ),
  'NeumorphicDivider': (context) => const NeumorphicDivider(),
  'NeumorphicEmptyState': (context) =>
      const NeumorphicEmptyState(title: 'Content', body: 'Note'),
  'NeumorphicEqualRow': (context) => const NeumorphicEqualRow(
    flex: [1, 1],
    children: [Text('First'), Text('Second')],
  ),
  'NeumorphicErrorState': (context) =>
      NeumorphicErrorState(title: 'Failed', onRetry: hit),
  'NeumorphicEyebrow': (context) => const NeumorphicEyebrow('Details'),
  'NeumorphicAvatarGroup': (context) => const NeumorphicAvatarGroup([
    NeumorphicFace('NW'),
    NeumorphicFace('AK'),
  ], total: 3),
  'NeumorphicFieldBox': (context) =>
      const NeumorphicFieldBox(child: Text('Value')),
  'NeumorphicFigure': (context) => const NeumorphicFigure('12', unit: 'items'),
  'NeumorphicFitRow': (context) => const NeumorphicFitRow(
    fill: 0,
    children: [Text('First'), Text('Second')],
  ),
  'NeumorphicFlatScope': (context) =>
      const NeumorphicFlatScope(child: NeumorphicSlab(child: Text('Content'))),
  'NeumorphicFormGroup': (context) =>
      const NeumorphicFormGroup(label: 'Personal', child: Text('Content')),
  'NeumorphicGableArt': (context) => const NeumorphicGableArt(),
  'NeumorphicGauge': (context) =>
      NeumorphicGauge(value: 40, figure: '40', name: 'Level', onPressed: hit),
  'NeumorphicGridOf': (context) => const NeumorphicGridOf(
    columns: 2,
    children: [Text('First'), Text('Second')],
  ),
  'NeumorphicListSection': (context) =>
      const NeumorphicListSection(label: 'Group', children: [Text('Content')]),
  'NeumorphicGrow': (context) => const NeumorphicColumn(
    children: [NeumorphicGrow(child: Text('Flexible'))],
  ),
  'NeumorphicHeroBand': (context) => const NeumorphicHeroBand(
    object: NeumorphicKnob(value: .5),
    title: 'Volume',
  ),
  'NeumorphicHost': (context) => NeumorphicHost(
    light: NeumorphicTheme.of(context),
    darkData: NeumorphicTheme.of(context),
    child: const Text('Content'),
  ),
  'NeumorphicIconButton': (context) =>
      NeumorphicIconButton(NeumorphicGlyphs.plus, label: 'Add', onPressed: hit),
  'NeumorphicIconWell': (context) =>
      const NeumorphicIconWell(NeumorphicGlyphs.plus),
  'NeumorphicInput': (context) => NeumorphicInput(onChanged: (_) => hit()),
  'NeumorphicKnob': (context) => const NeumorphicKnob(value: .5),
  'NeumorphicKnobRow': (context) =>
      const NeumorphicKnobRow(value: .5, label: 'Volume', figure: '50'),
  'NeumorphicKvRow': (context) => const NeumorphicKvRow('Name', 'Alex'),
  'NeumorphicLabel': (context) => const NeumorphicLabel('Label'),
  'NeumorphicLatchGroup': (context) => NeumorphicLatchGroup(
    options: const [NeumorphicLatch('Day'), NeumorphicLatch('Week')],
    onChanged: (_) => hit(),
  ),
  'NeumorphicLed': (context) => const NeumorphicLed(),
  'NeumorphicLevelRow': (context) => NeumorphicLevelRow(
    icon: Icons.light,
    title: 'Lamp',
    state: 'Off',
    onChanged: (_) => hit(),
  ),
  'NeumorphicLoadingState': (context) => const NeumorphicLoadingState(),
  'NeumorphicDialog': (context) => NeumorphicDialog(
    title: 'Save changes?',
    message: 'Choose an action',
    actions: [
      NeumorphicButton.text('Cancel', onPressed: hit),
      NeumorphicButton.filled('Save', onPressed: hit),
    ],
  ),
  'NeumorphicLinearProgressIndicator': (context) =>
      const NeumorphicLinearProgressIndicator(value: .5, label: 'Loading'),
  'NeumorphicList': (context) =>
      const NeumorphicList(children: [Text('First'), Text('Second')]),
  'NeumorphicListTile': (context) =>
      NeumorphicListTile(title: 'Open', onPressed: hit),
  'NeumorphicLiveText': (context) => const NeumorphicLiveText('Live'),
  'NeumorphicMenu': (context) => NeumorphicMenu<String>(
    autofocus: false,
    items: const [NeumorphicMenuItem('copy', 'Copy')],
    onSelected: (_) => hit(),
  ),
  'NeumorphicMiniDial': (context) =>
      const NeumorphicMiniDial(value: 21, figure: '21°'),
  'NeumorphicMonogram': (context) => const NeumorphicMonogram('NWA'),
  'NeumorphicMonth': (context) =>
      NeumorphicMonth(year: 2026, month: 11, onDay: (_) => hit()),
  'NeumorphicNavigationBar': (context) => NeumorphicNavigationBar(
    items: const [NeumorphicNavItem(label: 'Home', icon: Icons.home)],
    onDestinationSelected: (_) => hit(),
  ),
  'NeumorphicNavigationDrawer': (context) => NeumorphicNavigationDrawer(
    items: const [
      NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
    ],
    onDestinationSelected: (_) => hit(),
  ),
  'NeumorphicNote': (context) =>
      const NeumorphicNote(title: 'Content', subtitle: 'Note'),
  'NeumorphicBanner': (context) => NeumorphicBanner('Saved', onDismiss: hit),
  'NeumorphicNudge': (context) =>
      const NeumorphicNudge(title: 'Content', note: 'Note'),
  'NeumorphicPageDots': (context) => NeumorphicPageDots(
    count: 1,
    selectedIndex: 0,
    label: 'Introduction',
    onChanged: (_) => hit(),
  ),
  'NeumorphicPageHead': (context) => const NeumorphicPageHead(title: 'Details'),
  'NeumorphicMedia': (context) =>
      const NeumorphicMedia(label: 'A room', glyph: NeumorphicGlyphs.house),
  'NeumorphicPictureCard': (context) =>
      NeumorphicPictureCard(glyph: Icons.photo, title: 'Photo', onPressed: hit),
  'NeumorphicPreview': (context) => NeumorphicPreview(
    light: NeumorphicTheme.of(context),
    darkData: NeumorphicTheme.of(context),
    child: const Text('Content'),
  ),
  'NeumorphicProgress': (context) => const NeumorphicProgress(value: .5),
  'NeumorphicPushGroup': (context) => NeumorphicPushGroup(
    items: [
      NeumorphicPush(
        icon: NeumorphicGlyphs.sun,
        label: 'Day',
        note: 'Until six',
        onPressed: () {},
      ),
      NeumorphicPush(
        icon: NeumorphicGlyphs.moon,
        label: 'Night',
        selected: true,
        onPressed: () {},
      ),
    ],
  ),
  'NeumorphicButton.text': (context) =>
      NeumorphicButton.text('Later', onPressed: hit),
  'NeumorphicRadioGroup': (context) => NeumorphicRadioGroup<String>(
    label: 'Space',
    options: const [NeumorphicRadio('room', 'Room')],
    onChanged: (_) => hit(),
  ),
  'NeumorphicRailLink': (context) =>
      NeumorphicRailLink(label: 'Home', onPressed: hit),
  'NeumorphicRailSet': (context) =>
      const NeumorphicRailSet(label: 'Settings', children: [Text('Entry')]),
  'NeumorphicRelief': (context) =>
      NeumorphicRelief(title: 'House', compact: true, onPressed: hit),
  'NeumorphicRoundButton': (context) => NeumorphicRoundButton(
    NeumorphicGlyphs.plus,
    label: 'Add',
    onPressed: hit,
  ),
  'NeumorphicRow': (context) => const NeumorphicRow(
    spans: [6, 6],
    children: [Text('First'), Text('Second')],
  ),
  'NeumorphicRuled': (context) => const NeumorphicRuled(child: Text('Content')),
  'NeumorphicScaffold': (context) => const NeumorphicScaffold(
    topBar: NeumorphicAppBar(title: 'Page'),
    body: Text('Content'),
  ),
  'NeumorphicSearchField': (context) =>
      NeumorphicSearchField(hint: 'Search', onChanged: (_) => hit()),
  'NeumorphicSectionHeader': (context) =>
      const NeumorphicSectionHeader(title: 'Details'),
  'NeumorphicSections': (context) =>
      const NeumorphicSections(children: [Text('First'), Text('Second')]),
  'NeumorphicSegmentedButton': (context) => NeumorphicSegmentedButton<String>(
    label: 'Period',
    segments: const [NeumorphicButtonSegment('day', 'Day')],
    onChanged: (_) => hit(),
  ),
  'NeumorphicSelect': (context) => NeumorphicSelect<String>(
    label: 'Space',
    options: const [NeumorphicMenuItem('room', 'Room')],
    onChanged: (_) => hit(),
  ),
  'NeumorphicSelectField': (context) =>
      NeumorphicSelectField(value: 'Town', onPressed: hit),
  'NeumorphicSendButton': (context) => NeumorphicSendButton(onPressed: hit),
  'NeumorphicShapeMark': (context) =>
      const NeumorphicShapeMark(NeumorphicMarkShape.solid),
  'NeumorphicShareBars': (context) =>
      const NeumorphicShareBars(rows: [NeumorphicShare('Work', '6', .5)]),
  'NeumorphicSkeleton': (context) => const NeumorphicSkeleton.row(),
  'NeumorphicSlab': (context) => const NeumorphicSlab(child: Text('Content')),
  'NeumorphicSlider': (context) =>
      NeumorphicSlider(label: 'Level', value: .5, onChanged: (_) => hit()),
  'NeumorphicSnackBar': (context) => const NeumorphicSnackBar('Saved'),
  'NeumorphicSpanDial': (context) => const NeumorphicSpanDial(
    start: '09:00',
    end: '10:00',
    elapsed: 20,
    total: 60,
    figure: '40',
    unit: 'min',
    tag: 'Left',
  ),
  'NeumorphicSplit': (context) =>
      NeumorphicSplit(start: const Text('First'), end: const Text('Second')),
  'NeumorphicStatus': (context) => const NeumorphicStatus('Live', live: true),
  'NeumorphicStatesScope': (context) =>
      const NeumorphicStatesScope(states: {}, child: Text('Content')),
  'NeumorphicStats': (context) => const NeumorphicStats([
    NeumorphicStat('Hours', '8', 'h'),
    NeumorphicStat('Tasks', '4'),
  ]),
  'NeumorphicStepLine': (context) => const NeumorphicStepLine(
    readings: [(0, 2), (12, 4), (24, 3)],
    steps: [(0, 2), (12, 3), (24, 3)],
    now: 12,
    xMax: 24,
    yMin: 0,
    yMax: 5,
    yTicks: [1, 3, 5],
    yLabel: 'kW',
    xLabels: [(0, '00'), (12, '12'), (24, '24')],
    keys: [NeumorphicLegendItem('Used')],
    note: 'Today',
  ),
  'NeumorphicStepProgress': (context) =>
      const NeumorphicStepProgress(count: 3, currentStep: 1, name: 'Setup'),
  'NeumorphicStepRow': (context) =>
      const NeumorphicStepRow(time: '09:00', title: 'Work'),
  'NeumorphicNumberField': (context) =>
      NeumorphicNumberField(value: '2', onDecrease: hit, onIncrease: hit),
  'NeumorphicSubHead': (context) => const NeumorphicSubHead('Details'),
  'NeumorphicSuccessState': (context) =>
      const NeumorphicSuccessState(title: 'Saved', message: 'Ready'),
  'NeumorphicSurface': (context) => const NeumorphicSurface(
    cast: NeumorphicSurfaceLevel.part,
    child: Text('Content'),
  ),
  'NeumorphicSwitch': (context) =>
      NeumorphicSwitch(value: false, onChanged: (_) => hit()),
  'NeumorphicSwitchRow': (context) =>
      NeumorphicSwitchRow(label: 'Setting', value: true, onChanged: (_) {}),
  'NeumorphicTabBar': (context) =>
      NeumorphicTabBar(tabs: const ['Overview'], onChanged: (_) => hit()),
  'NeumorphicTable': (context) => const NeumorphicTable(
    columns: [NeumorphicTableColumn('Key')],
    rows: [
      NeumorphicTableRow(['Content'], selected: true),
    ],
  ),
  'NeumorphicTag': (context) => const NeumorphicTag('Content'),
  'NeumorphicTap': (context) =>
      NeumorphicTap(onPressed: hit, child: const Text('Action')),
  'NeumorphicText': (context) =>
      const NeumorphicText('Content', style: TextStyle(fontSize: 16)),
  'NeumorphicTextArea': (context) =>
      NeumorphicTextArea(label: 'Notes', onChanged: (_) => hit()),
  'NeumorphicTextContextMenu': (context) => NeumorphicTextContextMenu(
    anchors: const TextSelectionToolbarAnchors(primaryAnchor: Offset(100, 150)),
    buttonItems: [ContextMenuButtonItem(label: 'Copy', onPressed: () {})],
  ),
  'NeumorphicTextField': (context) =>
      NeumorphicTextField(onChanged: (_) => hit()),
  'NeumorphicLink': (context) => NeumorphicLink('Open', onPressed: hit),
  'NeumorphicTheme': (context) => NeumorphicTheme(
    data: NeumorphicTheme.of(context),
    child: const Text('Content'),
  ),
  'NeumorphicTimePicker': (context) => NeumorphicTimePicker(
    value: const NeumorphicTime(0, 0),
    twentyFour: true,
    minuteStep: 30,
    onChanged: (_) => hit(),
  ),
  'NeumorphicTodoRow': (context) =>
      NeumorphicTodoRow(title: 'Task', onChanged: (_) => hit()),
  'NeumorphicTooltip': (context) =>
      const NeumorphicTooltip(message: 'More information', child: Text('Hint')),
  'NeumorphicTooltipFace': (context) =>
      const NeumorphicTooltipFace(message: 'More information'),
  'NeumorphicTotalRow': (context) => const NeumorphicTotalRow('Total', '12'),
  'NeumorphicTwoWayBars': (context) => const NeumorphicTwoWayBars(
    above: [2, 4, 1],
    below: {1: 1},
    slots: 3,
    peak: '4',
    now: 1.5,
    nowLabel: 'Now',
    labels: {0: 'Start', 2: 'End'},
    keys: [NeumorphicLegendItem('Used')],
  ),
  'NeumorphicWallSet': (context) =>
      const NeumorphicWallSet(title: 'Details', child: Text('Content')),
  'NeumorphicWell': (context) => const NeumorphicWell(child: Text('Content')),
  'NeumorphicWhoRow': (context) =>
      const NeumorphicWhoRow(initials: 'AM', name: 'Alex'),
};

/// Fixtures that need a bounded height: they fill the page they stand on.
const boundedFixtures = {
  'NeumorphicScaffold',
  'NeumorphicHost',
  'NeumorphicPreview',
  'NeumorphicNavigationDrawer',
  'NeumorphicDialog',
  'NeumorphicBottomSheet',
  'NeumorphicTextContextMenu',
};
