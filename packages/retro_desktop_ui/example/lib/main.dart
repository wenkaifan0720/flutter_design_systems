import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/chrome.dart';
import 'kit_gallery/demos/complete.dart';
import 'kit_gallery/demos/controls.dart';
import 'kit_gallery/demos/coverage.dart';
import 'kit_gallery/demos/entries.dart';
import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/frames.dart';
import 'kit_gallery/demos/lists.dart';
import 'kit_gallery/demos/objects.dart';
import 'kit_gallery/demos/ordinary.dart';
import 'kit_gallery/demos/papers.dart';
import 'kit_gallery/demos/raised.dart';
import 'kit_gallery/demos/rows.dart';
import 'kit_gallery/kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await retroDesktopLoadFonts();
  runApp(const GalleryApp());
}

/// One page of the example: its plain name, its glyph in the side nav, and
/// the screen it shows by day or by night.
typedef ExamplePage = ({
  String name,
  IconData icon,
  Widget Function(Brightness) build,
});

Widget Function(Brightness) _page(
  String title,
  List<(String, List<Widget> Function())> parts, {
  bool bare = false,
}) =>
    (brightness) => kitScreen(
      brightness: brightness,
      title: title,
      bare: bare,
      sections: [
        for (final (label, children) in parts)
          kitSection(label, children: children()),
      ],
    );

/// Every page, in the order a reader looks for things: the parts by kind,
/// then ordinary applications built from them, then the look's own pieces.
/// Every widget the package exports is live on at least one of them.
final List<ExamplePage> examplePages = [
  (
    name: 'Overview',
    icon: RetroDesktopGlyphs.devices,
    build: (b) => kitPapersScreen(KitPapersWindow.documents, b),
  ),
  (
    name: 'Buttons',
    icon: RetroDesktopGlyphs.check,
    build: _page('Buttons', [
      ('The default button', () => [kitSpecimenActButton()]),
      ('A line button', () => [kitSpecimenLineButton()]),
      ('An icon button', () => [kitSpecimenIconButton()]),
      (
        'Quiet and destructive actions',
        () => [
          kitSpecimenQuietButton(),
          kitSpecimenDangerButton(),
          kitSpecimenLink(),
        ],
      ),
      ('The plain button', () => [kitSpecimenButton()]),
      ('A popup', () => [kitSpecimenPopup()]),
      ('A key', () => [kitSpecimenKbd()]),
      ('Buttons side by side', () => [kitSpecimenButtonGroup()]),
      ('A toggle group', () => [kitSpecimenToggleGroup()]),
      ('A split button', () => [kitSpecimenSplitButton()]),
      ('Keyboard and pointer states', () => [kitStateSamples()]),
    ]),
  ),
  (
    name: 'Text fields',
    icon: RetroDesktopGlyphs.fileText,
    build: _page('Text fields', [
      ('A text box', () => [kitSpecimenTextBox()]),
      ('A labelled field', () => [kitSpecimenLabelled()]),
      ('The plain input', () => [kitSpecimenInput()]),
      ('Search', () => [kitSpecimenSearchField()]),
      ('A code field', () => [kitSpecimenCodeField()]),
      ('Several lines', () => [kitSpecimenTextArea()]),
      ('A password', () => [kitSpecimenPasswordField()]),
      ('Words either side', () => [kitSpecimenInputGroup()]),
      ('A form field', () => [kitSpecimenFormField()]),
    ]),
  ),
  (
    name: 'Selection',
    icon: RetroDesktopGlyphs.listChecks,
    build: _page('Selection', [
      ('A checkbox', () => [kitSpecimenCheck()]),
      ('A check row', () => [kitSpecimenCheckRow()]),
      ('A radio', () => [kitRadioSamples()]),
      ('A radio group', () => [kitSpecimenRadioGroup()]),
      ('Switches', () => [kitSpecimenSwitch(), kitSpecimenSwitchRow()]),
      ('Segments', () => [kitSpecimenSegmentedButton()]),
      ('Choices', () => [kitSpecimenChoices()]),
      ('Chips', () => [kitSpecimenChip()]),
      ('A slider', () => [kitSpecimenSlider()]),
      ('A range', () => [kitSpecimenRangeSlider()]),
      ('A stepper', () => [kitSpecimenStepper()]),
      ('A rating', () => [kitSpecimenRating()]),
    ]),
  ),
  (
    name: 'Pickers',
    icon: RetroDesktopGlyphs.calendar,
    build: _page('Pickers', [
      ('A select menu', () => [kitSpecimenSelect()]),
      ('A date', () => [kitSpecimenDatePicker()]),
      ('A time', () => [kitSpecimenTimePicker()]),
      ('A file drop', () => [kitSpecimenFileDrop()]),
      ('A combo box', () => [kitSpecimenCombobox()]),
      ('A calendar', () => [kitSpecimenCalendar()]),
      ('A range of dates', () => [kitSpecimenDateRangePicker()]),
      ('A colour', () => [kitSpecimenColorPicker()]),
    ]),
  ),
  (
    name: 'Navigation',
    // No arrow or chevron for a page: in the list of pages one read as a disclosure, open or closed.
    icon: RetroDesktopGlyphs.location,
    build: _page('Navigation', [
      ('The menu bar', () => [const _MenuBarSample()]),
      ('Menus in a bar', () => [kitSpecimenMenuBar()]),
      ('The top bar', () => [kitSpecimenTopBar()]),
      ('The strip of places', () => [kitSpecimenTabBar()]),
      (
        'Side navigation',
        () => [kitSpecimenNavigationDrawer(), kitSpecimenNavigationRail()],
      ),
      ('Folder tabs', () => [kitSpecimenFolderTabs()]),
      ('Breadcrumbs', () => [kitSpecimenBreadcrumbs()]),
      ('Pagination', () => [kitSpecimenPagination()]),
      (
        'Pages and steps',
        () => [kitSpecimenPageDots(), kitSpecimenStepProgress()],
      ),
      ('A disclosure', () => [kitSpecimenDisclosure()]),
      ('The way back and the way out', () => [const _BackSamples()]),
    ]),
  ),
  (
    name: 'Lists and tables',
    icon: RetroDesktopGlyphs.inbox,
    build: _page('Lists and tables', [
      ('A list of rows', () => [kitSpecimenList()]),
      ('An action row', () => [kitSpecimenActionRow()]),
      ('A task', () => [kitSpecimenTaskRow()]),
      ('A list view', () => [kitSpecimenListView()]),
      ('A grouped list', () => [kitSpecimenGroupedList()]),
      ('A table', () => [kitSpecimenTable()]),
      ('A table that sorts', () => [kitSpecimenDataTable()]),
      ('A tree', () => [kitSpecimenTreeView()]),
      ('A scroll area', () => [kitSpecimenScrollArea()]),
      ('Panes that resize', () => [kitSpecimenResizable()]),
      ('Rows in your order', () => [kitSpecimenReorderable()]),
      ('A timeline', () => [kitSpecimenTimeline()]),
      ('A checklist', () => [kitSpecimenChecklist()]),
      ('Folders', () => [kitSpecimenFolderGrid()]),
      ('Files', () => [kitSpecimenFileGrid()]),
      ('A divider', () => [kitSpecimenDivider()]),
    ]),
  ),
  (
    name: 'Cards and media',
    icon: RetroDesktopGlyphs.photos,
    build: _page('Cards and media', [
      ('A surface and a card', () => [kitSpecimenSurface(), kitSpecimenCard()]),
      ('A group box', () => [kitSpecimenGroupBox()]),
      ('A picture card', () => [kitSpecimenPictureCard()]),
      ('Pictures', () => [kitSpecimenPicture()]),
      // Named for what it is: unnamed, the fallback beside a picture read as one that failed to load.
      ('A picture, in its fallback', () => [kitSpecimenPhoto()]),
      (
        'Faces',
        () => [
          kitSpecimenAvatar(),
          kitSpecimenFacePile(),
          kitSpecimenMonogram(),
        ],
      ),
      ('A document', () => [kitSpecimenDocument()]),
      ('Cards on the grid', () => [const _GridRow()]),
      ('Columns as wide as their words', () => [const _AutoRow()]),
    ]),
  ),
  (
    name: 'Dialogs and sheets',
    icon: RetroDesktopGlyphs.external,
    build: _page('Dialogs and sheets', [
      ('A dialog window', () => [kitSpecimenDialog()]),
      ('An alert', () => [kitSpecimenAlert()]),
      ('A sheet at the foot', () => [kitSpecimenBottomSheet()]),
      ('A sheet at the side', () => [kitSpecimenSheet(), kitSheetLauncher()]),
      (
        'An action sheet',
        () => [kitSpecimenActionSheet(), kitActionSheetLauncher()],
      ),
      ('A popover', () => [kitSpecimenPopover()]),
      ('A menu', () => [kitSpecimenMenu()]),
      ('A tooltip', () => [kitSpecimenTooltip(), kitTooltipFace()]),
      ('A toast', () => [kitSpecimenSnackBar()]),
      ('Open each one', () => [kitRaiseLaunchers()]),
      ('Before closing', () => [kitOrdinaryContent('dialog')]),
    ]),
  ),
  (
    name: 'Feedback',
    icon: RetroDesktopGlyphs.bell,
    build: _page('Feedback', [
      ('A notice', () => [kitSpecimenNotice()]),
      ('A progress bar', () => [kitSpecimenProgress()]),
      ('A spinner', () => [kitSpecimenCircularProgressIndicator()]),
      ('A skeleton', () => [kitSpecimenSkeleton()]),
      ('Loading', () => [kitSpecimenLoadingState()]),
      ('An error', () => [kitSpecimenErrorState()]),
      ('Done', () => [kitSpecimenSuccessState()]),
      ('Empty', () => [kitSpecimenEmptyState(), kitSpecimenEmpty()]),
      (
        'Badges and tags',
        () => [
          kitSpecimenBadge(),
          kitSpecimenFlag(),
          kitSpecimenPriority(),
          kitSpecimenTag(),
        ],
      ),
      ('One view for each state', () => [kitSpecimenStatusView()]),
    ]),
  ),
  (
    name: 'Charts',
    icon: RetroDesktopGlyphs.sunrise,
    build: _page('Charts', [
      ('Bars', () => [kitSpecimenChart()]),
      ('Lines', () => [kitSpecimenLineChart()]),
      ('An area', () => [kitSpecimenAreaChart()]),
      ('A donut', () => [kitSpecimenDonutChart()]),
      ('A sparkline', () => [kitSpecimenSparkline()]),
      (
        'Empty and loading',
        () => [kitSpecimenChartEmpty(), kitSpecimenChartLoading()],
      ),
      ('Amounts', () => [kitSpecimenAmount(), kitSpecimenMeter()]),
      ('A legend', () => [kitSpecimenLegend()]),
    ]),
  ),
  (
    name: 'All components',
    // Every part on one page: the kit's hammer, not Selection's checklist.
    icon: RetroDesktopGlyphs.hammer,
    build: (brightness) => kitFilledScreen(
      brightness: brightness,
      title: 'All components',
      body: const RetroDesktopInventoryGallery(),
    ),
  ),
  (
    name: 'Type and colour',
    icon: RetroDesktopGlyphs.eye,
    build: _page('Type and colour', [
      ('Type', () => [kitTypeSamples()]),
      ('Colour', () => [kitColourSamples()]),
      (
        'Heads',
        () => [
          kitSpecimenEyebrow(),
          kitSpecimenHead(),
          kitSpecimenSubHead(),
          kitSpecimenPartHead(),
        ],
      ),
      ('A label', () => [kitSpecimenLabel()]),
      ('An etched line', () => [kitSpecimenEtch()]),
      ('A theme that changes', () => [const _ThemeChange()]),
    ]),
  ),
  (
    name: 'Form',
    icon: RetroDesktopGlyphs.person,
    build: (b) => kitPapersScreen(KitPapersWindow.details, b),
  ),
  (
    name: 'Settings',
    icon: RetroDesktopGlyphs.key,
    build: (b) => kitPapersScreen(KitPapersWindow.settings, b),
  ),
  (
    name: 'List',
    icon: RetroDesktopGlyphs.notebook,
    build: (b) => kitPapersScreen(KitPapersWindow.documents, b, alone: true),
  ),
  (
    name: 'Checkout',
    icon: RetroDesktopGlyphs.tag,
    build: (b) => kitPapersScreen(KitPapersWindow.prints, b),
  ),
  (
    name: 'Workspace',
    icon: RetroDesktopGlyphs.contacts,
    build: (b) => kitOrdinaryScreen('tabs', b),
  ),
  (
    name: 'Projects',
    icon: RetroDesktopGlyphs.folder,
    build: (b) => kitOrdinaryScreen('cards', b),
  ),
  (
    name: 'Desktop and windows',
    icon: RetroDesktopGlyphs.hourglass,
    build: _page('Desktop and windows', bare: true, [
      ('A desktop, one window active', () => [kitSpecimenDesktop()]),
      ('A window', () => [kitSpecimenWindow()]),
      ('A window that closes', () => [kitSpecimenWindowClosing()]),
      ('A folded window', () => [kitSpecimenShade()]),
      ('A well', () => [kitSpecimenWell()]),
      ('A toolbar', () => [kitSpecimenToolbar()]),
      ('A strip on the desk', () => [kitSpecimenDeskStrip()]),
      ('Marks on the desk', () => [kitSpecimenDeskMarks()]),
      ('The mark', () => [kitSpecimenMark()]),
      ('One page on its own', () => [const _PagePreview()]),
    ]),
  ),
  (
    name: 'Objects and figures',
    icon: RetroDesktopGlyphs.verified,
    build: _page('Objects and figures', [
      ('A day tile', () => [kitSpecimenDayTile()]),
      ('A big figure', () => [kitSpecimenBigFigure()]),
      ('A hero', () => [kitSpecimenHero()]),
      ('A figure hero', () => [kitSpecimenFigureHero()]),
      ('A reading head', () => [kitSpecimenReadingHead()]),
      ('Facts', () => [kitSpecimenFacts()]),
      ('Stats', () => [kitSpecimenStats()]),
      ('Readings', () => [kitSpecimenReadings()]),
      ('Measures', () => [kitSpecimenMeasures()]),
      ('An object beside its words', () => [kitSpecimenBeside()]),
    ]),
  ),
  (
    name: 'Gauges and calendars',
    icon: RetroDesktopGlyphs.calendarDays,
    build: _page('Gauges and calendars', [
      ('A thumb gauge', () => [kitSpecimenThumbGauge()]),
      ('A gauge with figures', () => [kitSpecimenGaugeBlock()]),
      ('A month', () => [kitSpecimenMonthGrid()]),
      ('A month head', () => [kitSpecimenMonthHead()]),
      ('A pixel sky', () => [kitSpecimenPixelSky()]),
      ('An hour strip', () => [kitSpecimenHourStrip()]),
      ('A range of days', () => [kitSpecimenRangeShape()]),
      ('Hatched bars', () => [kitSpecimenHatchBars()]),
      ('Day bars', () => [kitSpecimenDayBars()]),
      ('A scale', () => [kitSpecimenScaleBar()]),
      ('A span', () => [kitSpecimenSpanBar()]),
      ('A tree of shares', () => [kitSpecimenTreeBars()]),
    ]),
  ),
];

/// The pages that are the look's own application, Papers, rather than the
/// gallery's: they open on the whole screen under the app's menu bar, and
/// leave by its "Gallery".
const galleryAppPages = {'Overview', 'Form', 'Settings', 'List', 'Checkout'};

/// The look's menu bar over a small desktop: the brand at its start and
/// places that switch the page under it. The example's own pages leave it
/// out, so it is shown here, live.
class _MenuBarSample extends StatefulWidget {
  const _MenuBarSample();
  @override
  State<_MenuBarSample> createState() => _MenuBarSampleState();
}

class _MenuBarSampleState extends State<_MenuBarSample> {
  var _active = 0;
  @override
  Widget build(BuildContext context) => SizedBox(
    // As tall as its words need: a fixed 220 cut the page under the bar at twice the text size.
    height: MediaQuery.textScalerOf(context).scale(220),
    child: RetroDesktopChromeScope(
      brand: 'Retro Desktop',
      active: _active,
      nav: [
        for (final (i, item) in kitTabs.indexed)
          RetroDesktopNavItem(
            label: item.label,
            short: item.short,
            icon: item.icon,
            onPressed: () => setState(() => _active = i),
          ),
      ],
      child: RetroDesktopScaffold(
        topBar: RetroDesktopAppBar(title: kitTabs[_active].label),
        body: Text('The ${kitTabs[_active].label} page, under the menu bar.'),
      ),
    ),
  );
}

/// The way back from a pushed page and the way out of a sheet.
class _BackSamples extends StatelessWidget {
  const _BackSamples();
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      RetroDesktopBackButton(onPressed: () {}),
      RetroDesktopBackButton(close: true, onPressed: () {}),
    ],
  );
}

/// Two cards on the 12-column grid: side by side from 1024 wide, stacked
/// below that.
class _GridRow extends StatelessWidget {
  const _GridRow();
  @override
  Widget build(BuildContext context) => const RetroDesktopRow(
    spans: [7, 5],
    children: [
      RetroDesktopCard(
        title: 'This week',
        child: Text('Notes for the week ahead, kept beside the calendar.'),
      ),
      RetroDesktopCard(
        title: 'Due Friday',
        child: Text('Three tasks, one of them shared.'),
      ),
    ],
  );
}

/// Columns as wide as their words; a long one wraps when they don't fit.
class _AutoRow extends StatelessWidget {
  const _AutoRow();
  @override
  Widget build(BuildContext context) => const RetroDesktopAutoRow(
    children: [
      Text('Project notes'),
      Text('Meeting notes and next steps, shared with the design group'),
      Text('12 KB'),
    ],
  );
}

/// A part whose theme moves to new colours over a third of a second.
class _ThemeChange extends StatefulWidget {
  const _ThemeChange();
  @override
  State<_ThemeChange> createState() => _ThemeChangeState();
}

class _ThemeChangeState extends State<_ThemeChange> {
  bool _berry = false;
  @override
  Widget build(BuildContext context) {
    final base = RetroDesktopTheme.of(context);
    final berry = RetroDesktopThemeData.berry(
      base.colors.dark ? Brightness.dark : Brightness.light,
    ).colors;
    // At once (its default), as every state of the look changes: a colour that fades between two themes
    // half-animates.
    return AnimatedRetroDesktopTheme(
      data: _berry ? base.copyWith(colors: berry) : base,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          RetroDesktopButton(
            _berry ? 'Back to these colours' : 'Change to berry',
            isDefaultAction: true,
            onPressed: () => setState(() => _berry = !_berry),
          ),
          const Text('Changes at once'),
        ],
      ),
    );
  }
}

/// One page as an app hosts it, framed on its own: the host, the route and
/// the sheet it gets live, without the router.
class _PagePreview extends StatelessWidget {
  const _PagePreview();
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return SizedBox(
      height: 420,
      child: RetroDesktopPreview(
        light: kitTheme(Brightness.light),
        dark: kitTheme(Brightness.dark),
        brightness: t.colors.dark ? Brightness.dark : Brightness.light,
        child: const RetroDesktopScaffold(
          topBar: RetroDesktopAppBar(title: 'Notes'),
          body: Column(
            children: [
              RetroDesktopListTile(title: 'Project notes', subtitle: 'Today'),
              RetroDesktopListTile(title: 'Reading list', subtitle: 'Monday'),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom primary colour and optional desktop surface.
typedef GalleryColours = ({String name, Color primary, Color? surface});
const List<GalleryColours> galleryColours = [
  (name: 'Cobalt', primary: Color(0xff2455aa), surface: null),
  (name: 'Forest', primary: Color(0xff236047), surface: null),
  (name: 'Mulberry', primary: Color(0xff752c65), surface: null),
  (name: 'Warm paper', primary: Color(0xff803b1c), surface: Color(0xffe5dfcf)),
];

/// Immutable settings shared by the controls and the gallery pages.
@immutable
class GalleryCustom {
  const GalleryCustom({
    this.appearance = RetroDesktopAppearance.platinum,
    this.density,
    this.colours,
    this.direction = TextDirection.ltr,
  });
  final RetroDesktopAppearance appearance;

  /// The reading direction the pages are shown in.
  final TextDirection direction;

  /// Null: the platform's.
  final RetroDesktopDensity? density;
  final GalleryColours? colours;

  RetroDesktopThemeData theme(String preset, Brightness brightness) {
    final pair = colours;
    final base = pair == null
        ? RetroDesktopThemeData.preset(preset, brightness)
        : RetroDesktopThemeData.from(
            primary: pair.primary,
            surface: pair.surface,
            brightness: brightness,
          );
    return base.copyWith(appearance: appearance, density: density);
  }

  GalleryCustom copyWith({
    RetroDesktopAppearance? appearance,
    RetroDesktopDensity? density,
    GalleryColours? Function()? colours,
    TextDirection? direction,
  }) => GalleryCustom(
    appearance: appearance ?? this.appearance,
    density: density ?? this.density,
    colours: colours == null ? this.colours : colours(),
    direction: direction ?? this.direction,
  );
}

/// The width from which the side nav stands beside the page; below it the
/// pages open from a drawer.
const double gallerySideNavWidth = 900;

/// The example's own page navigation, apart from the side navigation a page
/// shows as a specimen.
const galleryNavKey = ValueKey('gallery-pages');

/// Every page, preset and theme setting in one application.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});
  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  var _page = 0;
  var _preset = kitShownPreset;
  var _brightness = Brightness.light;
  var _custom = const GalleryCustom();
  var _customizing = false;
  var _drawer = false;
  // Where "Gallery" goes back to: the last page that is the gallery's.
  var _galleryPage = 1;

  // A link may open a page, by day or by night, in either appearance, right to
  // left, at a text size in percent, and slow what moves N times to be seen
  // mid-move. The looks share one form, /#/text-fields?theme=dark&dir=rtl&text=200
  // (the page is its name in lower case, words joined by hyphens); the older
  // ?page=Text%20fields&night=1&appearance=chisel&slow=10 still opens.
  @override
  void initState() {
    super.initState();
    final query = {...Uri.base.queryParameters};
    var pageName = query['page'];
    final hash = Uri.base.fragment;
    if (hash.startsWith('/')) {
      final link = Uri.parse(hash);
      query.addAll(link.queryParameters);
      final slug = link.pathSegments.firstOrNull;
      if (slug != null && slug.isNotEmpty) pageName = slug;
    }
    final slow = double.tryParse(query['slow'] ?? '');
    if (slow != null && slow >= 1) timeDilation = slow;
    String slugOf(String name) =>
        name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
    final page = examplePages.indexWhere(
      (p) => p.name == pageName || slugOf(p.name) == pageName,
    );
    if (page >= 0) {
      _page = page;
      if (!galleryAppPages.contains(examplePages[page].name)) {
        _galleryPage = page;
      }
    }
    if (query['night'] == '1' || query['theme'] == 'dark') {
      _brightness = Brightness.dark;
    }
    final look = RetroDesktopAppearance.values
        .where((a) => a.name == query['appearance'])
        .firstOrNull;
    if (look != null) _custom = _custom.copyWith(appearance: look);
    if (query['dir'] == 'rtl') {
      _custom = _custom.copyWith(direction: TextDirection.rtl);
    }
    final text = double.tryParse(query['text'] ?? '');
    if (text != null && text > 0) _textScale = text / 100;
  }

  // The text size a link asked for; null follows the platform's.
  double? _textScale;

  void _open(int page) => setState(() {
    _page = page;
    _drawer = false;
    if (!galleryAppPages.contains(examplePages[page].name)) _galleryPage = page;
  });

  @override
  Widget build(BuildContext context) {
    kitShownPreset = _preset;
    kitShownTheme = (brightness) => _custom.theme(_preset, brightness);
    // The example's own app bar and side navigation are the chrome; a page
    // doesn't add the sample menu bar of places that lead nowhere.
    kitShownChrome = false;
    kitShownDirection = _custom.direction;
    final page = examplePages[_page];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retro Desktop',
      builder: (context, child) => MediaQuery(
        data: _textScale == null
            ? MediaQuery.of(context)
            : MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(_textScale!)),
        child: Directionality(
          textDirection: _custom.direction,
          child: RetroDesktopTheme(
            data: _custom.theme(_preset, _brightness),
            child: child!,
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final t = RetroDesktopTheme.of(context);
          if (galleryAppPages.contains(page.name)) {
            // The app is the whole screen: its menu bar is the chrome.
            return ColoredBox(
              color: t.colors.desktop,
              child: SafeArea(
                bottom: false,
                child: KitPapersHost(
                  onGallery: () => _open(_galleryPage),
                  night: _brightness == Brightness.dark,
                  onNight: (night) => setState(
                    () => _brightness = night
                        ? Brightness.dark
                        : Brightness.light,
                  ),
                  // Night keeps the app's windows where they are.
                  child: KeyedSubtree(
                    key: ValueKey('${page.name}/$_preset'),
                    child: page.build(_brightness),
                  ),
                ),
              ),
            );
          }
          final width = MediaQuery.sizeOf(context).width;
          final side = width >= gallerySideNavWidth;
          // Day and night sit in the app bar where there is room for them,
          // and in the Customize panel on a phone.
          final roomy = width >= 600;
          final nav = RetroDesktopNavigationDrawer(
            key: galleryNavKey,
            label: 'Pages',
            selectedIndex: _page,
            onDestinationSelected: _open,
            items: [
              for (final p in examplePages)
                RetroDesktopNavItem(label: p.name, short: p.name, icon: p.icon),
            ],
          );
          final dayNight = RetroDesktopSegmentedButton<Brightness>(
            showLabel: false,
            label: 'Day and night',
            value: _brightness,
            segments: const [
              RetroDesktopButtonSegment(Brightness.light, 'Day'),
              RetroDesktopButtonSegment(Brightness.dark, 'Night'),
            ],
            onChanged: (value) => setState(() => _brightness = value),
          );
          // Where large text leaves the bar too narrow for its buttons' words beside the title (a phone at twice the
          // size broke "Customize" mid-word and cut the title to a letter), the buttons show their glyphs alone.
          final tight =
              MediaQuery.textScalerOf(context).scale(100) / width > .4;
          void togglePages() => setState(() => _drawer = !_drawer);
          void customize() => setState(() => _customizing = !_customizing);
          final bar = RetroDesktopAppBar(
            title: 'Retro Desktop',
            leading: side
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: tight
                        ? RetroDesktopIconButton(
                            RetroDesktopGlyphs.menu,
                            label: 'Pages',
                            onPressed: togglePages,
                          )
                        : RetroDesktopButton(
                            'Pages',
                            icon: RetroDesktopGlyphs.menu,
                            onPressed: togglePages,
                          ),
                  ),
            actions: [
              if (roomy) ...[
                // Bounded, so the control keeps to its words (an unbounded
                // row gives every segment its full row width).
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: dayNight,
                ),
                const SizedBox(width: 8),
              ],
              if (tight)
                RetroDesktopIconButton(
                  _customizing
                      ? RetroDesktopGlyphs.check
                      : RetroDesktopGlyphs.key,
                  label: _customizing ? 'Done' : 'Customize',
                  onPressed: customize,
                )
              else
                RetroDesktopButton(
                  _customizing ? 'Done' : 'Customize',
                  onPressed: customize,
                ),
            ],
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_customizing)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .45,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: CustomizePanel(
                      custom: _custom,
                      onChanged: (value) => setState(() => _custom = value),
                      preset: _preset,
                      onPreset: (value) => setState(() => _preset = value),
                      dayNight: roomy ? null : dayNight,
                    ),
                  ),
                ),
              Expanded(
                child: KeyedSubtree(
                  // A new page, preset or day/night builds the page afresh; the
                  // Customize knobs update its existing elements.
                  key: ValueKey('${page.name}/$_preset/${_brightness.name}'),
                  child: page.build(_brightness),
                ),
              ),
            ],
          );
          // The list of pages, on the window's grey with a rule at its end.
          final pages = DecoratedBox(
            decoration: BoxDecoration(
              color: t.colors.platinum,
              border: BorderDirectional(
                end: BorderSide(
                  color: t.colors.control,
                  width: t.strokes.regular,
                ),
              ),
            ),
            child: Padding(padding: const EdgeInsets.all(8), child: nav),
          );
          return ColoredBox(
            color: t.colors.desktop,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  bar,
                  Expanded(
                    child: side
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              pages,
                              Expanded(child: content),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned.fill(child: content),
                              if (_drawer) ...[
                                Positioned.fill(
                                  child: RetroDesktopPressable(
                                    label: 'Close the pages',
                                    onPressed: () =>
                                        setState(() => _drawer = false),
                                    child: ColoredBox(
                                      color: t.colors.shade.withValues(
                                        alpha: .4,
                                      ),
                                    ),
                                  ),
                                ),
                                PositionedDirectional(
                                  start: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: pages,
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Labelled controls for each theme value exposed by the example. Each keeps
/// its natural width, on a grid read from the start edge.
class CustomizePanel extends StatelessWidget {
  const CustomizePanel({
    super.key,
    required this.custom,
    required this.onChanged,
    this.preset,
    this.onPreset,
    this.dayNight,
  });
  final GalleryCustom custom;
  final ValueChanged<GalleryCustom> onChanged;

  /// The preset shown, and where a new one goes; no preset control without.
  final String? preset;
  final ValueChanged<String>? onPreset;

  /// Day and night, when the app bar has no room for them.
  final Widget? dayNight;
  @override
  Widget build(BuildContext context) {
    final c = custom;
    return RetroDesktopSurface(
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          if (preset != null && onPreset != null)
            SizedBox(
              width: 200,
              child: RetroDesktopSelect<String>(
                label: 'Preset',
                value: preset,
                options: [
                  for (final id in RetroDesktopThemeData.presets)
                    RetroDesktopOption(id, id),
                ],
                onChanged: onPreset,
              ),
            ),
          if (dayNight case final dayNight?)
            _Labelled('Day and night', dayNight),
          _Labelled(
            'Appearance',
            RetroDesktopSegmentedButton<RetroDesktopAppearance>(
              showLabel: false,
              label: 'Appearance',
              value: c.appearance,
              segments: const [
                RetroDesktopButtonSegment(
                  RetroDesktopAppearance.chisel,
                  'Chisel (95-era PC)',
                ),
                RetroDesktopButtonSegment(
                  RetroDesktopAppearance.platinum,
                  'Platinum (classic Mac)',
                ),
              ],
              onChanged: (v) => onChanged(c.copyWith(appearance: v)),
            ),
          ),
          _Labelled(
            'Reading direction',
            RetroDesktopSegmentedButton<TextDirection>(
              showLabel: false,
              label: 'Reading direction',
              value: c.direction,
              segments: const [
                RetroDesktopButtonSegment(TextDirection.ltr, 'Left to right'),
                RetroDesktopButtonSegment(TextDirection.rtl, 'Right to left'),
              ],
              onChanged: (v) => onChanged(c.copyWith(direction: v)),
            ),
          ),
          _Labelled(
            'Density',
            RetroDesktopSegmentedButton<RetroDesktopDensity>(
              showLabel: false,
              label: 'Density',
              // Until one is chosen, the platform's.
              value: c.density ?? RetroDesktopDensity.adaptivePlatformDensity,
              segments: const [
                RetroDesktopButtonSegment(
                  RetroDesktopDensity.standard,
                  'Standard',
                ),
                RetroDesktopButtonSegment(
                  RetroDesktopDensity.comfortable,
                  'Comfortable',
                ),
                RetroDesktopButtonSegment(
                  RetroDesktopDensity.compact,
                  'Compact',
                ),
              ],
              onChanged: (v) => onChanged(c.copyWith(density: v)),
            ),
          ),
          SizedBox(
            width: 240,
            child: RetroDesktopSelect<String>(
              label: 'Your own colours',
              value: c.colours?.name ?? '',
              options: [
                const RetroDesktopOption('', 'The preset'),
                for (final pair in galleryColours)
                  RetroDesktopOption(pair.name, pair.name),
              ],
              onChanged: (v) => onChanged(
                c.copyWith(
                  colours: () =>
                      galleryColours.where((p) => p.name == v).firstOrNull,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A control under its label, bounded by the room and no more: from 600 up a
/// segmented control keeps to its segments at the widest label's width (a
/// fixed width cut "Comfortable" short), below it fills the room.
class _Labelled extends StatelessWidget {
  const _Labelled(this.text, this.child);
  final String text;
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, room) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A field's label: the body's type, 6 above the control, as Preset's
        // and Your own colours' are.
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(text, style: RetroDesktopTheme.of(context).type.body),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: room.maxWidth),
          child: child,
        ),
      ],
    ),
  );
}
