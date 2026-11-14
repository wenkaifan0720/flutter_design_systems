// The Minimal gallery: every part the package exports, live, on pages with plain names, by day and by night, and
// made yours. The sidebar (a drawer on a phone) moves between the pages; the bar on top opens the Customize panel and
// switches the appearance, and every page takes the theme the panel sets. Each page stacks the gallery's own demos.
import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'gallery_pages.dart';
import 'kit_gallery/apps/app_frame.dart';
import 'kit_gallery/apps/habits_app.dart';
import 'kit_gallery/apps/issues_app.dart';
import 'kit_gallery/apps/orders_app.dart';
import 'kit_gallery/kit.dart';
import 'kit_gallery/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The bundled faces before the first frame, so the web build never shows
  // a fallback face.
  await minimalLoadFonts();
  runApp(GalleryApp.at(Uri.base));
}

/// One page of the example: its plain name, its glyph in the navigation, a
/// line on what it holds, and the demos it stacks.
typedef ExamplePage = ({
  String name,
  IconData icon,
  String about,
  List<Widget Function(Brightness)> shows,
});

/// The gallery's demo for the manifest group [id].
Widget Function(Brightness) _group(String id) =>
    galleryPages.firstWhere((p) => p.id == id).build;

/// Every page, in order: the pitch, then the parts by family. The apps are
/// not pages: each opens as itself, filling the window ([exampleApps]).
final List<ExamplePage> examplePages = [
  (
    name: 'Overview',
    icon: LucideIcons.layoutDashboard,
    about: 'The look at its best, and what the package holds',
    shows: [],
  ),
  (
    name: 'Buttons',
    icon: LucideIcons.mousePointerClick,
    about: 'Buttons, icon buttons, button groups, toggle groups, split buttons, links',
    shows: [_group('button'), _group('button-group'), _group('toggle-split')],
  ),
  (
    name: 'Text fields',
    icon: LucideIcons.textCursorInput,
    about:
        'Fields, add-ons, codes, comboboxes, text areas, search, the composer',
    shows: [
      _group('input'),
      _group('input-group'),
      _group('combobox'),
      _group('text-area'),
      _group('search'),
      _group('composer'),
      _group('sign-in'),
    ],
  ),
  (
    name: 'Selection',
    icon: LucideIcons.squareCheck,
    about: 'Checkbox, radio, switch, segmented, chips, sliders, colour, rating',
    shows: [
      _group('toggle-check'),
      _group('radio-rating'),
      _group('segmented-tabs'),
      _group('chips'),
      _group('slider-stepper'),
      _group('range-color'),
      _group('selection'),
      _group('filters'),
    ],
  ),
  (
    name: 'Pickers',
    icon: LucideIcons.calendar,
    about: 'Select, date, range, time and wheel pickers, calendars, menus',
    shows: [_group('pickers'), _group('time-wheel'), _group('calendar')],
  ),
  (
    name: 'Navigation',
    icon: LucideIcons.compass,
    about: 'App bar, tab bar, rail, sidebar, menu bar, breadcrumbs, pagination',
    shows: [
      _group('top-bar'),
      _group('navigation'),
      _group('menu-bar'),
      _group('shell'),
      _group('action-bar'),
      _group('properties'),
    ],
  ),
  (
    name: 'Lists and tables',
    icon: LucideIcons.list,
    about: 'Rows, tables, data tables, panes, reorder, refresh, trees, swipe',
    shows: [
      _group('list-rows'),
      _group('table'),
      _group('data-table'),
      _group('swipe'),
      _group('status'),
      _group('activity'),
      _group('disclosure'),
      _group('panes'),
      _group('list-behaviours'),
    ],
  ),
  (
    name: 'Cards and media',
    icon: LucideIcons.image,
    about: 'Cards, sections, pictures, carousels, avatars, face piles, tags',
    shows: [
      _group('cards'),
      _group('media'),
      _group('carousel'),
      _group('identity'),
    ],
  ),
  (
    name: 'Dialogs and sheets',
    icon: LucideIcons.panelTop,
    about:
        'Dialog, sheets, popover, hover card, tooltip, banner, command palette',
    shows: [
      _group('dialog'),
      _group('sheet'),
      _group('overlays'),
      _group('notices'),
      _group('command'),
    ],
  ),
  (
    name: 'Feedback',
    icon: LucideIcons.bell,
    about: 'Toast, loading, error, empty, success, spinner, skeleton, badge',
    shows: [_group('states'), _group('feedback')],
  ),
  (
    name: 'Charts',
    icon: LucideIcons.chartColumn,
    about: 'Line, bar, area, donut, sparkline, KPIs, progress',
    shows: [_group('series-charts'), _group('stats'), _group('kpi')],
  ),
  (
    name: 'Type and colour',
    icon: LucideIcons.palette,
    about: 'The type scale, colour roles, spacing and corners',
    shows: [_group('foundations')],
  ),
];

/// The inventory of every part against the kit's list: for the package's
/// own tests and reviews, linked as `?page=inventory`, out of the
/// navigation.
final ExamplePage inventoryPage = (
  name: 'Inventory',
  icon: LucideIcons.listChecks,
  about: 'Every part the kit names, and Minimal\'s',
  shows: [_group('inventory')],
);

/// MinimalPreview's three presentations and a nested MinimalHost: for a
/// tool that previews one page of an app, linked as `?page=host-and-preview`,
/// out of the navigation (the apps show the shell itself).
final ExamplePage previewPage = (
  name: 'Host and preview',
  icon: LucideIcons.appWindow,
  about: 'One page previewed as a root, pushed or raised; a nested host',
  shows: [_group('preview')],
);

/// One app of the example: its link (`?app=habits`), its name and glyph, a
/// line on what it is, and the app itself, given its way out.
typedef ExampleApp = ({
  String slug,
  String name,
  IconData icon,
  String about,
  Widget Function(KitGalleryLink gallery) build,
});

/// The three apps the look is shown in, each filling the window.
final List<ExampleApp> exampleApps = [
  (
    slug: 'habits',
    name: 'Ritual',
    icon: LucideIcons.calendarCheck,
    about: 'A habit tracker: the day\'s list, a habit\'s record, a new habit',
    build: (gallery) => KitHabitsApp(gallery: gallery),
  ),
  (
    slug: 'issues',
    name: 'Tracker',
    icon: LucideIcons.circleUser,
    about: 'An issue tracker: my issues by status, each beside its page',
    build: (gallery) => KitIssuesApp(gallery: gallery),
  ),
  (
    slug: 'orders',
    name: 'Lund Bakery',
    icon: LucideIcons.croissant,
    about: 'A bakery\'s back office: the morning\'s figures, orders, products',
    build: (gallery) => KitOrdersApp(gallery: gallery),
  ),
];

/// At this width and wider the pages are listed in a sidebar; under it, in a
/// drawer the bar's menu button opens.
const double _sidebarWidth = 840;

/// The gallery: the page it shows, the appearance and the knobs.
class GalleryApp extends StatefulWidget {
  /// The gallery, opening on [initialPage] (its overview by default) in
  /// [initialBrightness] with [initialKnobs].
  const GalleryApp({
    super.key,
    this.initialPage = 0,
    this.initialApp,
    this.initialBrightness = Brightness.light,
    this.initialKnobs = const Knobs(),
  });

  /// The gallery a link opens: `?page=buttons&appearance=dark&radius=12`
  /// starts on that page (its name in lower case, words joined by hyphens), by
  /// night, with those corners, so a page can be linked to directly;
  /// `?app=habits` opens that app, filling the window; `&dir=rtl` reads it
  /// right to left and `&text=1.3` shows it at the largest text size
  /// Minimal lays out (MinimalChromeMetrics.maxTextScale).
  factory GalleryApp.at(Uri address) {
    final q = address.queryParameters;
    final page = galleryPagesAll.indexWhere(
      (p) => pageSlug(p.name) == q['page'],
    );
    final app = exampleApps.indexWhere((a) => a.slug == q['app']);
    return GalleryApp(
      initialPage: page < 0 ? 0 : page,
      initialApp: app < 0 ? null : app,
      initialBrightness: q['appearance'] == 'dark'
          ? Brightness.dark
          : Brightness.light,
      initialKnobs: Knobs(
        radius: double.tryParse(q['radius'] ?? '') ?? 8,
        density: Density.values.firstWhere(
          (d) => d.name == q['density'],
          orElse: () => Density.platform,
        ),
        direction: q['dir'] == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
        textScale: double.tryParse(q['text'] ?? '') ?? 1,
      ),
    );
  }

  /// A page's name as a link spells it: "Lists and tables" is
  /// `lists-and-tables`.
  static String pageSlug(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');

  /// An index into [galleryPagesAll].
  final int initialPage;

  /// An index into [exampleApps]; null opens the gallery.
  final int? initialApp;
  final Brightness initialBrightness;
  final Knobs initialKnobs;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

/// Every page a link can open: the navigation's, then the inventory and the
/// preview.
final List<ExamplePage> galleryPagesAll = [
  ...examplePages,
  inventoryPage,
  previewPage,
];

class _GalleryAppState extends State<GalleryApp> {
  late var _page = widget.initialPage;
  late int? _app = widget.initialApp;
  late var _brightness = widget.initialBrightness;
  late var _knobs = widget.initialKnobs;

  void _setKnobs(Knobs knobs) => setState(() => _knobs = knobs);
  void _open(int page) => setState(() => _page = page);
  void _openApp(int app) => setState(() => _app = app);

  void _customize(BuildContext context) => showMinimalBottomSheet<void>(
    context,
    title: 'Customize',
    builder: (_) => CustomizePanel(knobs: () => _knobs, onChanged: _setKnobs),
  );

  /// An app's way out: back here, the appearance, Customize.
  KitGalleryLink get _link => KitGalleryLink(
    onBack: () => setState(() => _app = null),
    dark: _brightness == Brightness.dark,
    onAppearance: () => setState(
      () => _brightness = _brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ),
    onCustomize: _customize,
  );

  @override
  Widget build(BuildContext context) {
    // Every demo builds its theme through the kit, so the knobs reach each
    // page live; a demo hands its sections to the page rather than mounting
    // an app of its own.
    kitEmbedded = true;
    kitShownTheme = _knobs.themed ? _knobs.theme : null;
    return MaterialApp(
      title: 'Minimal',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final host = Directionality(
          textDirection: _knobs.direction,
          child: MinimalHost(
            light: kitTheme(Brightness.light),
            dark: kitTheme(Brightness.dark),
            brightness: _brightness,
            child: child!,
          ),
        );
        if (_knobs.textScale == 1) return host;
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(_knobs.textScale)),
          child: host,
        );
      },
      home: _app != null
          // An app is the whole window: no gallery around it.
          ? KeyedSubtree(
              key: ValueKey('app ${_app!}'),
              child: exampleApps[_app!].build(_link),
            )
          : Builder(
              builder: (context) => LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth >= _sidebarWidth;
                  final page = ExamplePageView(
                    key: ValueKey(_page),
                    page: galleryPagesAll[_page],
                    brightness: _brightness,
                    onOpen: _open,
                    onOpenApp: _openApp,
                    gallery: _link,
                    bar: _bar(context, wide: wide),
                  );
                  if (!wide) return page;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExampleNavigation(
                        selected: _page,
                        onSelected: _open,
                        onApp: _openApp,
                      ),
                      Expanded(child: page),
                    ],
                  );
                },
              ),
            ),
    );
  }

  /// The bar on every page: the drawer's button on a phone, the page's
  /// name, Customize and the appearance. On a phone the appearance is one
  /// icon button (the sun or the moon it turns to, as in the apps), so the
  /// page's name keeps its words.
  Widget _bar(BuildContext context, {required bool wide}) {
    final dark = _brightness == Brightness.dark;
    return MinimalAppBar(
      title: galleryPagesAll[_page].name,
      leading: wide
          ? null
          : MinimalIconButton(
              LucideIcons.menu,
              label: 'Pages',
              onPressed: () => _openDrawer(context),
            ),
      actions: [
        MinimalIconButton(
          LucideIcons.slidersHorizontal,
          label: 'Customize',
          onPressed: () => _customize(context),
        ),
        if (wide) ...[
          const MinimalGap(MinimalSpacing.s8),
          SizedBox(
            width: 132,
            child: MinimalSegmentedButton<Brightness>(
              segments: const [
                MinimalButtonSegment(Brightness.light, 'Light'),
                MinimalButtonSegment(Brightness.dark, 'Dark'),
              ],
              value: _brightness,
              label: 'Appearance',
              onChanged: (b) => setState(() => _brightness = b),
            ),
          ),
        ] else
          MinimalIconButton(
            dark ? LucideIcons.sun : LucideIcons.moon,
            label: dark ? 'Light appearance' : 'Dark appearance',
            onPressed: () => setState(
              () => _brightness = dark ? Brightness.light : Brightness.dark,
            ),
          ),
      ],
    );
  }

  /// The pages in a drawer from the start edge, on a phone.
  void _openDrawer(BuildContext context) {
    final t = context.minimalTheme;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close the pages',
      barrierColor: t.overlay,
      transitionDuration: context.minimalStill
          ? Duration.zero
          : MinimalMotion.base,
      pageBuilder: (drawer, _, _) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: ExampleNavigation(
          selected: _page,
          onSelected: (i) {
            Navigator.of(drawer).pop();
            _open(i);
          },
          onApp: (i) {
            Navigator.of(drawer).pop();
            _openApp(i);
          },
        ),
      ),
      transitionBuilder: (_, motion, _, child) => SlideTransition(
        position: Tween(
          begin: Offset(
            Directionality.of(context) == TextDirection.rtl ? 1 : -1,
            0,
          ),
          end: Offset.zero,
        ).chain(CurveTween(curve: MinimalMotion.out)).animate(motion),
        child: child,
      ),
    );
  }
}

/// The list of pages, then the apps, in the look's own sidebar.
class ExampleNavigation extends StatelessWidget {
  /// The pages, [selected] current.
  const ExampleNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onApp,
  });

  /// The current page's index in [galleryPagesAll].
  final int selected;

  /// Opens the page at an index.
  final ValueChanged<int> onSelected;

  /// Opens the app at an index in [exampleApps].
  final ValueChanged<int> onApp;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    MinimalNavItem item(ExamplePage p) => MinimalNavItem(p.icon, p.name);
    final pages = examplePages.length;
    return ColoredBox(
      color: t.background,
      child: SafeArea(
        right: false,
        child: MinimalNavigationDrawer(
          // The inventory and the preview, out of the list, mark no row.
          selectedIndex: selected < pages ? selected : -1,
          onDestinationSelected: (i) =>
              i < pages ? onSelected(i) : onApp(i - pages),
          header: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinimalSpacing.s8,
              vertical: MinimalSpacing.s12,
            ),
            child: Text('Minimal', style: t.h3),
          ),
          sections: [
            MinimalNavigationSection(
              title: 'Components',
              destinations: [for (final p in examplePages) item(p)],
            ),
            MinimalNavigationSection(
              title: 'Apps',
              destinations: [
                for (final a in exampleApps) MinimalNavItem(a.icon, a.name),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One page: the bar, then its demos stacked on the page's measure.
class ExamplePageView extends StatelessWidget {
  /// [page] in [brightness] under [bar].
  const ExamplePageView({
    super.key,
    required this.page,
    required this.brightness,
    required this.onOpen,
    required this.bar,
    this.onOpenApp,
    this.gallery,
  });

  /// The page shown.
  final ExamplePage page;

  /// The appearance the demos are built for.
  final Brightness brightness;

  /// Opens another page (the overview's index).
  final ValueChanged<int> onOpen;

  /// Opens an app (the overview's).
  final ValueChanged<int>? onOpenApp;

  /// The apps' way out, for the overview's live app.
  final KitGalleryLink? gallery;

  /// The bar on top.
  final Widget bar;

  /// The page's measure: the demos never stretch past it.
  static const double measure = 720;

  /// The overview's: the pitch and the live app beside it.
  static const double overviewMeasure = 1040;

  @override
  Widget build(BuildContext context) {
    final overview = identical(page, examplePages.first);
    // The inventory is a page-long list that scrolls itself: it stands as
    // the page, on the page's measure, rather than in a phone's window.
    if (identical(page, inventoryPage)) {
      return MinimalScaffold(
        topBar: bar,
        scroll: false,
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: measure + 2 * MinimalChromeMetrics.gutter,
            ),
            child: const MinimalInventoryGallery(
              padding: EdgeInsets.fromLTRB(
                MinimalChromeMetrics.gutter,
                0,
                MinimalChromeMetrics.gutter,
                MinimalSpacing.s48,
              ),
            ),
          ),
        ),
      );
    }
    return MinimalScaffold(
      topBar: bar,
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: overview ? overviewMeasure : measure,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (overview)
                _Overview(onOpen: onOpen, onOpenApp: onOpenApp ?? (_) {}),
              for (final (i, show) in page.shows.indexed) ...[
                if (i > 0) const MinimalGap(MinimalSpacing.s48),
                _windowed(show(brightness)),
              ],
              const MinimalGap(MinimalSpacing.s48),
            ],
          ),
        ),
      ),
    );
  }
}

/// A whole app screen (its own host and routes) in a phone-height window;
/// a demo's sections, a demo already windowed, or a phone as tall as its
/// rows ([KitPhone]), as it is.
Widget _windowed(Widget demo) =>
    demo is KitWindow || demo is KitEmbeddedScreen || demo is KitPhone
    ? demo
    : KitWindow(child: demo);

/// What the package holds, in four lines a visitor reads in passing.
const List<(String, String)> _holds = [
  (
    'Every part an app needs',
    'Buttons to data tables, sheets to charts, each styled through its theme.',
  ),
  (
    'Every size',
    'A bar on a phone, a rail on a tablet, a sidebar and side sheets on a '
        'laptop.',
  ),
  ('Light and dark', 'Both designed, the accent chosen again for each.'),
  (
    'Accessible',
    '44 px targets, screen readers, the keyboard, larger text, Reduce Motion '
        'and Increase Contrast.',
  ),
];

/// The pitch: the look at its best (Ritual, live, beside the words on a
/// wide window), one sentence on what the look is, the three apps, what the
/// package holds, and only then the parts.
class _Overview extends StatelessWidget {
  const _Overview({required this.onOpen, required this.onOpenApp});

  final ValueChanged<int> onOpen;
  final ValueChanged<int> onOpenApp;

  /// From this wide the live app stands beside the pitch.
  static const double _liveFrom = 840;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final pitch = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text('Minimal', style: t.h1)),
        const MinimalGap(MinimalSpacing.s8),
        Text(
          'A precise, quiet look for Flutter apps: hairline edges, one accent '
          'and dense controls, on a phone, a tablet and a laptop.',
          style: t.body.c(t.mutedForeground),
        ),
        const MinimalGap(MinimalSpacing.s20),
        Wrap(
          spacing: MinimalSpacing.s8,
          runSpacing: MinimalSpacing.s8,
          children: [
            MinimalButton('Open Ritual', onPressed: () => onOpenApp(0)),
            MinimalButton(
              'Browse the parts',
              variant: MinimalButtonVariant.secondary,
              onPressed: () => onOpen(1),
            ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s32),
        _heading(context, 'Apps'),
        // The bare register: the page is padded already, so the rows keep
        // the column's edges, as the headings, words and buttons do.
        MinimalListSection(
          gutter: false,
          children: [
            for (final (i, a) in exampleApps.indexed)
              MinimalListTile(
                icon: a.icon,
                title: a.name,
                below: _about(a.about),
                chevron: true,
                onTap: () => onOpenApp(i),
              ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s40),
        _heading(context, 'In the package'),
        // Two to a line where the column has the room for two.
        LayoutBuilder(
          builder: (context, column) {
            final two = column.maxWidth >= _twoHoldsFrom;
            return Wrap(
              spacing: MinimalSpacing.s24,
              runSpacing: MinimalSpacing.s16,
              children: [
                for (final (title, line) in _holds)
                  SizedBox(
                    width: two
                        ? (column.maxWidth - MinimalSpacing.s24) / 2
                        : column.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: t.body.semibold.c(t.foreground)),
                        const MinimalGap(MinimalSpacing.s2),
                        Text(line, style: t.bodySmall.c(t.mutedForeground)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
    final parts = [
      const MinimalGap(MinimalSpacing.s40),
      _heading(context, 'Parts'),
      Text(
        'The bar\'s Customize panel sets the corner radius, density and '
        'colour of every page and app.',
        style: t.bodySmall.c(t.mutedForeground),
      ),
      const MinimalGap(MinimalSpacing.s8),
      MinimalListSection(
        gutter: false,
        children: [
          for (final (i, p) in examplePages.indexed.skip(1))
            MinimalListTile(
              icon: p.icon,
              title: p.name,
              below: _about(p.about),
              chevron: true,
              onTap: () => onOpen(i),
            ),
        ],
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        // The pitch, the apps, what the package holds and the parts flow
        // down one column beside the live app: no row waits for the
        // phone's foot, so the column has no holes.
        if (box.maxWidth >= _liveFrom) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [pitch, ...parts],
                ),
              ),
              const MinimalGap(MinimalSpacing.s48),
              // Ritual itself, at a phone's size: mark a habit, open one.
              SizedBox(
                width: 390,
                child: KitWindow(
                  height: _liveHeight,
                  child: KitHabitsApp(gallery: null),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [pitch, ...parts],
        );
      },
    );
  }

  /// From this wide the package's four lines stand two to a line.
  static const double _twoHoldsFrom = 560;

  /// The live app's height: Ritual's Today, every habit and the tab bar,
  /// with nothing scrolled out of sight.
  static const double _liveHeight = 632;

  /// A row's line on what it opens: content, so it wraps rather than
  /// ending in an ellipsis on a phone.
  static Widget _about(String text) => Text(text, maxLines: 4);

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: MinimalSpacing.s8),
    child: Semantics(
      header: true,
      child: Text(text, style: context.minimalTheme.h3),
    ),
  );
}

/// What the panel's density control offers: the platform's own (standard on
/// a phone, compact on a desktop) or one chosen.
enum Density {
  platform(null),
  compact(MinimalDensity.compact),
  standard(MinimalDensity.standard);

  const Density(this.visual);

  /// The theme's density; null is the platform's.
  final MinimalDensity? visual;
}

/// Every knob the panel sets, at the look's own by default.
@immutable
class Knobs {
  /// The look as designed.
  const Knobs({
    this.radius = 8,
    this.density = Density.platform,
    this.accent,
    this.direction = TextDirection.ltr,
    this.textScale = 1,
  });

  /// The one radius the corner scale derives from.
  final double radius;
  final Density density;

  /// An app's own accent, through `MinimalThemeData.from`; null keeps the
  /// preset's.
  final Color? accent;

  /// Which way the gallery reads: right to left mirrors every page.
  final TextDirection direction;

  /// The text scale every page is shown at; 1 keeps the platform's own.
  final double textScale;

  /// Whether the theme itself differs from the look as designed.
  bool get themed =>
      radius != 8 || density != Density.platform || accent != null;

  Knobs copyWith({
    double? radius,
    Density? density,
    Color? accent,
    bool clearAccent = false,
    TextDirection? direction,
    double? textScale,
  }) => Knobs(
    radius: radius ?? this.radius,
    density: density ?? this.density,
    accent: clearAccent ? null : accent ?? this.accent,
    direction: direction ?? this.direction,
    textScale: textScale ?? this.textScale,
  );

  /// The theme these knobs make in [brightness].
  MinimalThemeData theme(Brightness brightness) {
    final base = accent == null
        ? MinimalThemeData.preset(kitPreset, brightness)
        : MinimalThemeData.from(primary: accent!, brightness: brightness);
    return base.copyWith(
      shapes: MinimalShapes(radius: radius),
      density: density.visual,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Knobs &&
      other.radius == radius &&
      other.density == density &&
      other.accent == accent &&
      other.direction == direction &&
      other.textScale == textScale;

  @override
  int get hashCode =>
      Object.hash(radius, density, accent, direction, textScale);
}

/// The Customize panel: every knob the theme has, live on the page under
/// it.
class CustomizePanel extends StatefulWidget {
  const CustomizePanel({
    super.key,
    required this.knobs,
    required this.onChanged,
  });

  /// The knobs in force (read on each build: the app owns them).
  final Knobs Function() knobs;
  final ValueChanged<Knobs> onChanged;

  @override
  State<CustomizePanel> createState() => _CustomizePanelState();
}

class _CustomizePanelState extends State<CustomizePanel> {
  void _set(Knobs next) {
    widget.onChanged(next);
    setState(() {});
  }

  static const _accents = <(String, Color?)>[
    ('Preset', null),
    ('Plum', Color(0xFF7A1F5C)),
    ('Teal', Color(0xFF0E9F9A)),
    ('Orange', Color(0xFFFF8A00)),
    ('Grey', Color(0xFF808080)),
  ];

  @override
  Widget build(BuildContext context) {
    final k = widget.knobs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _natural(
          3,
          MinimalSlider(
            label: 'Corner radius',
            value: k.radius,
            min: 0,
            max: 16,
            divisions: 16,
            unit: 'px',
            onChanged: (r) => _set(k.copyWith(radius: r)),
          ),
        ),
        MinimalSection(
          title: 'Density',
          child: _natural(
            3,
            MinimalSegmentedButton<Density>(
              segments: const [
                MinimalButtonSegment(Density.platform, 'Platform'),
                MinimalButtonSegment(Density.compact, 'Compact'),
                MinimalButtonSegment(Density.standard, 'Standard'),
              ],
              value: k.density,
              label: 'Density',
              onChanged: (d) => _set(k.copyWith(density: d)),
            ),
          ),
        ),
        MinimalSection(
          title: 'Your colour',
          child: MinimalChipRow(
            children: [
              for (final (name, colour) in _accents)
                MinimalChip(
                  name,
                  selected: k.accent == colour,
                  onPressed: () => _set(
                    colour == null
                        ? k.copyWith(clearAccent: true)
                        : k.copyWith(accent: colour),
                  ),
                ),
            ],
          ),
        ),
        MinimalSection(
          title: 'Direction',
          child: _natural(
            2,
            MinimalSegmentedButton<TextDirection>(
              segments: const [
                MinimalButtonSegment(TextDirection.ltr, 'Left to right'),
                MinimalButtonSegment(TextDirection.rtl, 'Right to left'),
              ],
              value: k.direction,
              label: 'Direction',
              onChanged: (d) => _set(k.copyWith(direction: d)),
            ),
          ),
        ),
        MinimalSection(
          title: 'Text size',
          child: _natural(
            3,
            MinimalSegmentedButton<double>(
              segments: const [
                // MinimalHost lays text out at most at maxTextScale (130%).
                MinimalButtonSegment(1.0, '100%'),
                MinimalButtonSegment(1.15, '115%'),
                MinimalButtonSegment(1.3, '130%'),
              ],
              value: k.textScale,
              label: 'Text size',
              onChanged: (s) => _set(k.copyWith(textScale: s)),
            ),
          ),
        ),
        const MinimalGap(MinimalSpacing.s8),
        MinimalButton(
          'Reset',
          variant: MinimalButtonVariant.secondary,
          onPressed: k == const Knobs() ? null : () => _set(const Knobs()),
        ),
      ],
    );
  }
}

/// [child] at a natural width on the panel's start edge: about 112 px for
/// each of [segments], never the sheet's whole width.
Widget _natural(int segments, Widget child) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 112.0 * segments),
    child: child,
  ),
);
