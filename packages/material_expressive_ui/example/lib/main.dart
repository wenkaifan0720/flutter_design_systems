// The Material Expressive example: every component, live, in an app built
// on the look itself, and the trip planner, a small app built from it.
// Destinations stand in the wide navigation rail on a wide window and in
// the modal drawer on a phone; the look's app bar names the destination,
// and its secondary tabs pick the page within it. The trip planner opens
// over the whole window with its own navigation, as a study does.
// Customize re-themes every page, the example's own chrome included.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'gallery_pages.dart';
import 'kit_gallery/demos/buttons.dart';
import 'kit_gallery/demos/loading.dart';
import 'kit_gallery/demos/split_button.dart';
import 'kit_gallery/demos/toolbar.dart';
import 'kit_gallery/everyday.dart';
import 'kit_gallery/kit.dart';
import 'kit_gallery/trip.dart';

/// Every page of the example: the ordinary screens, then the component
/// references.
const List<GalleryPage> galleryExamplePages = [
  ...everydayGalleryPages,
  ...galleryPages,
];

/// One destination of the example's navigation: its [title] (the rail's
/// label and the app bar's title), [about] (what its pages show, its
/// overview card's second line), its [icon], and the [pages] its tabs pick
/// from, by id; the first opens.
typedef GalleryDestination = ({
  String title,
  String about,
  IconData icon,
  List<String> pages,
});

/// The overview's id: the one page that is the example's own.
const String galleryOverview = 'overview';

/// Pages kept as plain routes, out of the navigation: they exist for the
/// package's own checks (the inventory of components every look shares,
/// the host and the preview frame), not for a reader.
const List<String> galleryPlainRoutes = ['inventory', 'host', 'preview'];

/// The example's destinations in their order: the overview, the trip
/// planner, then the component families. Every page of
/// [galleryExamplePages] but [galleryPlainRoutes] stands in exactly one.
const List<GalleryDestination> galleryDestinations = [
  (
    title: 'Overview',
    about: 'What the package adds to Material, and the trip planner.',
    icon: ExpressiveSymbols.home,
    pages: [galleryOverview],
  ),
  (
    title: 'Trip planner',
    about:
        'A small app built from the look: a home, a form, a list beside '
        'its detail, a checkout and preferences, at every size.',
    icon: ExpressiveSymbols.hiking,
    pages: TripScreens.all,
  ),
  (
    title: 'Buttons',
    about: 'Filled to text buttons in five sizes, toggle groups, split buttons, the FAB and toolbars.',
    icon: ExpressiveSymbols.radioButtonChecked,
    pages: ['buttons', 'icon-buttons', 'split-button', 'fab', 'toolbar'],
  ),
  (
    title: 'Text fields',
    about: 'Filled and outlined fields, passwords, input groups, labelled form fields and the select.',
    icon: ExpressiveSymbols.keyboard,
    pages: ['text-fields', 'select'],
  ),
  (
    title: 'Selection',
    about: 'Checkboxes, radios and switches, choice tiles, chips and sliders.',
    icon: ExpressiveSymbols.checkBox,
    pages: ['selection', 'choice', 'chips', 'sliders'],
  ),
  (
    title: 'Pickers',
    about: 'Date, range and time pickers, the calendar, scroll wheels and the colour picker.',
    icon: ExpressiveSymbols.calendarMonth,
    pages: ['pickers'],
  ),
  (
    title: 'Navigation',
    about: 'The navigation bar, rail and drawer, app bars, tabs, the shell, screens and pages.',
    icon: ExpressiveSymbols.explore,
    pages: ['nav', 'app-bar', 'everyday-tabs', 'shell', 'screen', 'page'],
  ),
  (
    title: 'Lists and tables',
    about: 'List items that reorder and swipe, tables, the data table, scroll areas, resizable panes and the side sheet.',
    icon: ExpressiveSymbols.list,
    pages: ['lists', 'table', 'panes'],
  ),
  (
    title: 'Cards and media',
    about: 'Cards, the carousel, images, text and numbers, the hero moment and badges.',
    icon: ExpressiveSymbols.gridView,
    pages: [
      'cards',
      'everyday-cards',
      'carousel',
      'media',
      'content',
      'hero',
      'badge',
    ],
  ),
  (
    title: 'Dialogs and sheets',
    about: 'A dialog, the overlays, the bottom sheet, menus and the menu bar.',
    icon: ExpressiveSymbols.article,
    pages: ['everyday-dialog', 'overlays', 'sheet', 'menus'],
  ),
  (
    title: 'Feedback',
    about: 'Snackbars, progress and loading indicators, status views and the splash.',
    icon: ExpressiveSymbols.notifications,
    pages: ['feedback', 'toast', 'progress', 'loading', 'splash'],
  ),
  (
    title: 'Charts',
    about: 'Line, area, bar and pie charts, and sparklines.',
    icon: ExpressiveSymbols.barChart,
    pages: ['chart'],
  ),
  (
    title: 'Type and colour',
    about: 'The colour roles, type scale, shapes, icons, motion, spacing, elevation and states.',
    icon: ExpressiveSymbols.palette,
    pages: [
      'color',
      'type',
      'shape',
      'icons',
      'motion',
      'spacing',
      'elevation',
      'states',
      'foundations',
    ],
  ),
];

/// A tab's label: the page's own title, plainer where a destination already
/// says what kind of page it is.
String galleryTabLabel(String id) => switch (id) {
  'everyday-tabs' => 'Tabs',
  'everyday-cards' => 'Card grid',
  'everyday-dialog' => 'Dialog',
  'fab' => 'FAB',
  'states' => 'States',
  _ => galleryExamplePages.firstWhere((p) => p.id == id).title,
};

/// The window width from which the example stands its destinations in the
/// wide rail rather than the drawer (Material's expanded window class).
const double galleryRailWidth = 840;

/// The same page builder the live example and its performance check use.
Widget galleryBuildPage(GalleryPage page, Brightness brightness) =>
    _GalleryAssetsScope(child: KitLiveViewport(child: page.build(brightness)));

// This example intentionally shows the components' pending-media placeholders.
// Consult the actual asset manifest before asking the web host for optional
// demo photos, while preserving any bundled pictures and caller asset bundle.
class _GalleryAssetsScope extends StatelessWidget {
  const _GalleryAssetsScope({required this.child});

  final Widget child;
  static final _bundles = Expando<_GalleryAssets>();

  @override
  Widget build(BuildContext context) {
    final parent = DefaultAssetBundle.of(context);
    return DefaultAssetBundle(
      bundle: _bundles[parent] ??= _GalleryAssets(parent),
      child: child,
    );
  }
}

class _GalleryAssets extends CachingAssetBundle {
  _GalleryAssets(this.parent);

  final AssetBundle parent;
  late final Future<Set<String>?> _keys = () async {
    try {
      return (await AssetManifest.loadFromAssetBundle(parent))
          .listAssets()
          .toSet();
    } catch (_) {
      // A caller's custom bundle need not provide an asset manifest.
      return null;
    }
  }();

  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/media/')) {
      final keys = await _keys;
      if (keys != null && !keys.contains(key)) {
        throw FlutterError('The example does not bundle demo media: $key');
      }
    }
    return parent.load(key);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await expressiveLoadFonts();
  runApp(const GalleryApp());
}

/// The example panel's settings, shared with its accessibility and pixel tests.
class GalleryCustom {
  /// Unset choices keep the preset as drawn.
  const GalleryCustom({
    this.density = 'auto',
    this.motion = 'preset',
    this.seed = 'preset',
    this.direction = 'ltr',
    this.textSize = '100',
  });

  /// The platform's density (`auto`: compact with a pointer, standard on
  /// touch) or a fixed one; touch targets keep their size.
  final String density;

  /// The preset's own motion scheme, or Expressive or Standard springs.
  final String motion;

  /// Preset, teal, plum or grey seed colours.
  final String seed;

  /// The reading direction: `ltr` or `rtl`. Every page mirrors, its
  /// previews and overlays included.
  final String direction;

  /// The text size in percent of the platform's: `100`, `150` or `200`.
  final String textSize;

  /// [direction] as a [TextDirection].
  TextDirection get textDirection =>
      direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr;

  /// [textSize] as a [TextScaler] over the platform's [base].
  TextScaler textScaler(TextScaler base) => switch (textSize) {
    '150' => TextScaler.linear(1.5),
    '200' => TextScaler.linear(2),
    _ => base,
  };

  /// Applies the choices to an existing preset and brightness.
  ExpressiveThemeData apply(ExpressiveThemeData base) {
    final color = switch (seed) {
      'teal' => const Color(0xff00695c),
      'plum' => const Color(0xff7a1f5c),
      'grey' => const Color(0xff888888),
      _ => null,
    };
    final theme = color == null
        ? base
        : ExpressiveThemeData.from(seed: color, brightness: base.brightness);
    final scheme = switch (motion) {
      'expressive' => ExpressiveMotionScheme.expressive,
      'standard' => ExpressiveMotionScheme.standard,
      _ => base.motion.scheme,
    };
    return theme.copyWith(
      motion: theme.motion.copyWith(scheme: scheme),
      density: switch (density) {
        'standard' => ExpressiveDensity.standard,
        'comfortable' => ExpressiveDensity.comfortable,
        'compact' => ExpressiveDensity.compact,
        _ => null,
      },
    );
  }
}

/// The example app.
class GalleryApp extends StatefulWidget {
  /// The example, opening on [initialPage] (the overview by default) in the
  /// default preset, light.
  const GalleryApp({
    this.initialPage = galleryOverview,
    this.initialBrightness = Brightness.light,
    this.initialCustom = const GalleryCustom(),
    super.key,
  });

  /// The page opened when the example starts: [galleryOverview] or a
  /// [galleryExamplePages] id.
  final String initialPage;

  /// The brightness the example starts in.
  final Brightness initialBrightness;

  /// The Customize choices the example starts with.
  final GalleryCustom initialCustom;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  late var _page = _firstPage();
  var _preset = kitShownPreset;
  late var _brightness = _query['theme'] == 'dark'
      ? Brightness.dark
      : widget.initialBrightness;
  var _customize = false;
  late var _custom = GalleryCustom(
    density: widget.initialCustom.density,
    motion: widget.initialCustom.motion,
    seed: widget.initialCustom.seed,
    direction: _query['dir'] ?? widget.initialCustom.direction,
    textSize: _query['text'] ?? widget.initialCustom.textSize,
  );

  /// The opening link's query: `theme=dark`, `dir=rtl`, `text=150` or
  /// `200` open the page that way (`/#/chips?theme=dark&dir=rtl`).
  Map<String, String> get _query =>
      Uri.tryParse(_link)?.queryParameters ?? const <String, String>{};

  /// The route the example was opened on: the platform's, else on the web
  /// the address's fragment (`/#/chips?theme=dark` → `/chips?theme=dark`),
  /// which the platform's route does not always carry.
  String get _link {
    final route = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (route != '/' || !kIsWeb) return route;
    final fragment = Uri.base.fragment;
    return fragment.startsWith('/') ? fragment : route;
  }

  ExpressiveThemeData _shownTheme(ExpressiveThemeData base) =>
      _custom.apply(base);

  int get _destination => math.max(
    0,
    galleryDestinations.indexWhere((d) => d.pages.contains(_page)),
  );

  void _open(int destination) =>
      _show(galleryDestinations[destination].pages.first);

  /// The page a link opened ("/everyday-list"), else [GalleryApp.initialPage].
  String _firstPage() {
    if (widget.initialPage != galleryOverview) return widget.initialPage;
    final route = _link;
    final path = Uri.tryParse(route)?.path ?? route;
    final id = path.startsWith('/') ? path.substring(1) : path;
    return galleryExamplePages.any((p) => p.id == id) ? id : galleryOverview;
  }

  /// Shows [page] and, on the web, puts it in the address bar, so every
  /// page and every trip screen can be linked.
  void _show(String page) {
    setState(() => _page = page);
    if (kIsWeb) {
      SystemNavigator.routeInformationUpdated(uri: Uri(path: '/$page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    kitShownPreset = _preset;
    kitShownTheme = _shownTheme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material Expressive',
      localizationsDelegates: const [
        DefaultDesignLocalizations.delegate,
        ExpressiveLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      // Day to night, a preset or a Customize choice springs from one theme
      // to the next.
      // Direction and text size wrap the navigator, so every page, preview
      // and overlay reads them.
      builder: (context, child) => Directionality(
        textDirection: _custom.textDirection,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: _custom.textScaler(MediaQuery.textScalerOf(context)),
          ),
          child: AnimatedExpressiveTheme(
            data: _shownTheme(ExpressiveThemeData.preset(_preset, _brightness)),
            child: child!,
          ),
        ),
      ),
      // A link's route names a page, not a pushed route: the shell stands
      // alone and opens that page itself.
      onGenerateRoute: (_) => _shellRoute(),
      onGenerateInitialRoutes: (_) => [_shellRoute()],
    );
  }

  Route<void> _shellRoute() =>
      MaterialPageRoute<void>(builder: (context) => Builder(builder: _shell));

  /// The trip planner over the whole window, Customize above it when open.
  Widget _trip(BuildContext context) {
    final dark = _brightness == Brightness.dark;
    return ColoredBox(
      color: context.expressiveTheme.colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_customize)
            SafeArea(
              bottom: false,
              child: _CustomizePanel(
                preset: _preset,
                custom: _custom,
                onPreset: (v) => setState(() => _preset = v),
                onCustom: (v) => setState(() => _custom = v),
                onClose: () => setState(() => _customize = false),
              ),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: _customize,
              child: TripApp(
                key: const ValueKey('trip'),
                screen: _page,
                onScreenChanged: _show,
                gallery: (
                  exit: () => _show(galleryOverview),
                  toggleBrightness: () => setState(
                    () =>
                        _brightness = dark ? Brightness.light : Brightness.dark,
                  ),
                  customize: () => setState(() => _customize = !_customize),
                  dark: dark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ExpressiveNavItem> get _items => [
    for (final d in galleryDestinations) ExpressiveNavItem(d.icon, d.title),
  ];

  Widget _shell(BuildContext context) {
    if (TripScreens.all.contains(_page)) return _trip(context);
    final t = context.expressiveTheme;
    final wide = MediaQuery.sizeOf(context).width >= galleryRailWidth;
    final destination = galleryDestinations[_destination];
    final dark = _brightness == Brightness.dark;
    final bar = ExpressiveAppBar(
      title: destination.title,
      leading: wide
          ? null
          : ExpressiveIconButton(
              ExpressiveSymbols.menu,
              semanticLabel: 'Open navigation',
              onPressed: () async {
                final chosen = await showExpressiveNavigationDrawer(
                  context,
                  destinations: _items,
                  selectedIndex: _destination,
                );
                if (chosen != null) _open(chosen);
              },
            ),
      actions: [
        ExpressiveAppBarAction(
          dark ? ExpressiveSymbols.lightMode : ExpressiveSymbols.darkMode,
          label: dark ? 'Light theme' : 'Dark theme',
          onPressed: () => setState(
            () => _brightness = dark ? Brightness.light : Brightness.dark,
          ),
        ),
        ExpressiveAppBarAction(
          ExpressiveSymbols.tune,
          label: 'Customize',
          onPressed: () => setState(() => _customize = !_customize),
        ),
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        if (_customize)
          _CustomizePanel(
            preset: _preset,
            custom: _custom,
            onPreset: (v) => setState(() => _preset = v),
            onCustom: (v) => setState(() => _custom = v),
          ),
        if (destination.pages.length > 1)
          ExpressiveTabBar(
            key: ValueKey('tabs/${destination.title}'),
            variant: ExpressiveTabBarVariant.secondary,
            scrollable: true,
            // The first tab starts on the column's edge, under the title,
            // beside the page's content (not Compose's 52dp scroll hint).
            edgePadding: ExpressiveChromeMetrics.margin,
            selectedIndex: destination.pages.indexOf(_page),
            onChanged: (i) => _show(destination.pages[i]),
            tabs: [
              for (final id in destination.pages)
                ExpressiveTab(label: galleryTabLabel(id)),
            ],
          ),
        // Keyed, so the page keeps its element as the bars above it come
        // and go: a reference page keeps its preview host (and its
        // navigator) across pages, only the page inside it changing.
        Expanded(
          key: const ValueKey('page'),
          child: _page == galleryOverview
              ? _Overview(onOpen: _open, onTrip: () => _show(TripScreens.home))
              : galleryBuildPage(
                  galleryExamplePages.firstWhere((p) => p.id == _page),
                  _brightness,
                ),
        ),
      ],
    );
    return ColoredBox(
      color: t.colors.surface,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpressiveNavigationRail(
                  expanded: true,
                  destinations: _items,
                  selectedIndex: _destination,
                  onDestinationSelected: _open,
                ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeLeft: true,
                    child: content,
                  ),
                ),
              ],
            )
          : content,
    );
  }
}

/// Customize: the preset and the look's knobs, each control at its own
/// width, flowing from the start edge. Every page follows them, the
/// example's own chrome included.
class _CustomizePanel extends StatelessWidget {
  const _CustomizePanel({
    required this.preset,
    required this.custom,
    required this.onPreset,
    required this.onCustom,
    this.onClose,
  });

  final String preset;
  final GalleryCustom custom;
  final ValueChanged<String> onPreset;
  final ValueChanged<GalleryCustom> onCustom;

  /// Closes the panel, where no bar of the gallery's stands over it (the
  /// trip planner).
  final VoidCallback? onClose;

  Widget _knob(
    BuildContext context,
    String label,
    String value,
    List<(String, String)> options,
    GalleryCustom Function(String) change,
  ) {
    final t = context.expressiveTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: ExpressiveSpacing.s8,
      children: [
        Text(
          label,
          style: t.type.labelLarge.copyWith(color: t.colors.onSurfaceVariant),
        ),
        ExpressiveSegmentedButton<String>(
          expand: false,
          segments: [
            for (final (id, title) in options)
              ExpressiveButtonSegment(id, title),
          ],
          value: value,
          onChanged: (v) => onCustom(change(v)),
        ),
      ],
    );
  }

  GalleryCustom _with({
    String? density,
    String? motion,
    String? seed,
    String? direction,
    String? textSize,
  }) => GalleryCustom(
    density: density ?? custom.density,
    motion: motion ?? custom.motion,
    seed: seed ?? custom.seed,
    direction: direction ?? custom.direction,
    textSize: textSize ?? custom.textSize,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final height = MediaQuery.sizeOf(context).height;
    return Semantics(
      container: true,
      label: 'Customize',
      child: ColoredBox(
        color: t.colors.surfaceContainerLow,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * 0.45),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              ExpressiveChromeMetrics.margin,
              ExpressiveSpacing.s16,
              ExpressiveChromeMetrics.margin,
              ExpressiveSpacing.s24,
            ),
            child: Wrap(
              spacing: ExpressiveSpacing.s24,
              runSpacing: ExpressiveSpacing.s16,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 200,
                  child: ExpressiveSelect<String>(
                    label: 'Preset',
                    value: preset,
                    options: [
                      for (final id in ExpressiveThemeData.presets)
                        ExpressiveSelectOption(id, id),
                    ],
                    onChanged: onPreset,
                  ),
                ),
                _knob(context, 'Colours', custom.seed, const [
                  ('preset', 'Preset'),
                  ('teal', 'Teal'),
                  ('plum', 'Plum'),
                  ('grey', 'Grey'),
                ], (v) => _with(seed: v)),
                _knob(context, 'Density', custom.density, const [
                  ('auto', 'Automatic'),
                  ('standard', 'Standard'),
                  ('comfortable', 'Comfortable'),
                  ('compact', 'Compact'),
                ], (v) => _with(density: v)),
                _knob(context, 'Motion', custom.motion, const [
                  ('preset', 'Preset'),
                  ('expressive', 'Expressive'),
                  ('standard', 'Standard'),
                ], (v) => _with(motion: v)),
                _knob(context, 'Direction', custom.direction, const [
                  ('ltr', 'Left to right'),
                  ('rtl', 'Right to left'),
                ], (v) => _with(direction: v)),
                _knob(context, 'Text size', custom.textSize, const [
                  ('100', '100%'),
                  ('150', '150%'),
                  ('200', '200%'),
                ], (v) => _with(textSize: v)),
                if (onClose != null)
                  ExpressiveIconButton(
                    ExpressiveSymbols.close,
                    semanticLabel: 'Close Customize',
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The overview, the package's pitch: what it is in one sentence, the
/// trip planner live (on a wide window) or one tap away, what it adds to
/// Flutter's Material, each live, and then the index.
class _Overview extends StatelessWidget {
  const _Overview({required this.onOpen, required this.onTrip});

  final ValueChanged<int> onOpen;
  final VoidCallback onTrip;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    const margin = ExpressiveChromeMetrics.margin;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 1100;
        // On a wide window the parts stand under the pitch, beside the
        // trip planner's frame: the column beside the frame holds them, not
        // an empty band the frame's height.
        final column = wide
            ? width - 2 * margin - _tripGap - _LiveTrip.phone.width
            : width - 2 * margin;
        // The title in the emphasized display type, the look's name in the
        // primary colour: Expressive's way of saying what leads.
        final words = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Material 3 '),
                  TextSpan(
                    text: 'Expressive',
                    style: TextStyle(color: c.primary),
                  ),
                ],
              ),
              style:
                  (column >= 600
                          ? t.type.displayMediumEmphasized
                          : t.type.displaySmallEmphasized)
                      .copyWith(color: c.onSurface),
            ),
            const SizedBox(height: ExpressiveSpacing.s16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                "Material's newest look for Flutter: the components you know, "
                'with springs, shapes and emphasis, and the parts Material '
                'added for it. Light and dark, phone to desktop, built for '
                'screen readers and the keyboard.',
                style: t.type.bodyLarge.copyWith(color: c.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: ExpressiveSpacing.s24),
            ExpressiveFilledButton(
              'Open the trip planner',
              key: const ValueKey('overview/trip'),
              icon: ExpressiveSymbols.hiking,
              size: ExpressiveButtonSize.medium,
              expand: width < 600,
              onPressed: onTrip,
            ),
          ],
        );
        // The mark beside the words where there is room, above them on a
        // phone.
        final pitch = column >= 640
            ? Row(
                spacing: ExpressiveSpacing.s24,
                children: [
                  Expanded(child: words),
                  const _ShapeMark(size: 184),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ShapeMark(size: 120),
                  const SizedBox(height: ExpressiveSpacing.s16),
                  words,
                ],
              );
        final live = <(String, String, Widget)>[
          (
            'Button groups',
            'Press one: it widens and its neighbours make room.',
            kitSpecimenButtonGroupReply(),
          ),
          (
            'Split button',
            'One act and its options, in one button.',
            kitSpecimenSplitButtonSend(),
          ),
          (
            'Loading indicator',
            'Shapes that morph while you wait, open or contained.',
            kitSpecimenLoadingIndicatorPair(),
          ),
          (
            'Floating toolbar',
            "A screen's tools in a pill over its content.",
            kitSpecimenFloatingToolbarEditor(),
          ),
          (
            'Wavy progress',
            'For the one moment a screen celebrates.',
            ExpressiveHeroMoment(
              child: ExpressiveLinearProgressIndicator(
                value: .66,
                wavy: true,
                expand: true,
                // The track's secondaryContainer all but vanishes on the
                // tile's container, and the page's surface was a groove at
                // night: the tile's content colour, faint.
                trackColor: context.expressiveTheme.colors.onSurface.withValues(
                  alpha: .2,
                ),
                semanticLabel: 'Two thirds done',
              ),
            ),
          ),
          (
            'Toggle groups',
            'A choice of a few, the chosen one rounder.',
            kitSpecimenToggleGroupAlign(),
          ),
        ];
        const gap = ExpressiveSpacing.s16;
        final columns = wide ? (column >= 860 ? 3 : 2) : (width >= 600 ? 2 : 1);
        final tile = (column - (columns - 1) * gap) / columns;
        final parts = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "What Flutter's Material doesn't have",
              style: t.type.titleLarge.copyWith(color: c.onSurface),
            ),
            const SizedBox(height: ExpressiveSpacing.s16),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (title, about, demo) in live)
                  SizedBox(
                    width: tile,
                    // Tonal, on the extra-large corner: each part on a
                    // surface of its own, not a hairline box.
                    child: ExpressiveCard.filled(
                      key: ValueKey('overview/live/$title'),
                      style: ExpressiveComponentThemeData(
                        shape: WidgetStatePropertyAll(t.shapes.extraLarge),
                      ),
                      padding: const EdgeInsets.all(ExpressiveSpacing.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 112, child: Center(child: demo)),
                          const SizedBox(height: ExpressiveSpacing.s16),
                          Text(
                            title,
                            style: t.type.titleMedium.copyWith(
                              color: c.onSurface,
                            ),
                          ),
                          const SizedBox(height: ExpressiveSpacing.s4),
                          Text(
                            about,
                            style: t.type.bodyMedium.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(margin, 24, margin, 48),
          children: [
            if (wide)
              Row(
                // The words start on the preview's top line.
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _tripGap,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [pitch, const SizedBox(height: 48), parts],
                    ),
                  ),
                  _LiveTrip(onOpen: onTrip),
                ],
              )
            else ...[
              pitch,
              const SizedBox(height: 48),
              parts,
            ],
            const SizedBox(height: 48),
            Text(
              'Every component',
              style: t.type.titleLarge.copyWith(color: c.onSurface),
            ),
            const SizedBox(height: ExpressiveSpacing.s8),
            _Index(onOpen: onOpen, columns: width >= 900 ? 2 : 1),
          ],
        );
      },
    );
  }
}

/// The gap between the overview's column and the trip planner's frame.
const double _tripGap = 48;

/// The overview's mark: three of Material's library shapes, in the primary
/// container, the tertiary and the secondary container, that turn on a
/// spatial spring and change shape (Material's polygon morph) each time a
/// pointer comes over them or presses them. Decoration: a screen reader
/// skips it and it takes no focus.
class _ShapeMark extends StatefulWidget {
  const _ShapeMark({required this.size});

  /// The square the three shapes share.
  final double size;

  @override
  State<_ShapeMark> createState() => _ShapeMarkState();
}

class _ShapeMarkState extends State<_ShapeMark> {
  /// Each shape's turn through the library, one step a visit.
  static const List<List<ExpressiveMaterialShape>> _turns = [
    [
      ExpressiveMaterialShape.cookie9Sided,
      ExpressiveMaterialShape.sunny,
      ExpressiveMaterialShape.flower,
      ExpressiveMaterialShape.cookie12Sided,
    ],
    [
      ExpressiveMaterialShape.clover4Leaf,
      ExpressiveMaterialShape.softBurst,
      ExpressiveMaterialShape.puffy,
      ExpressiveMaterialShape.clover8Leaf,
    ],
    [
      ExpressiveMaterialShape.pill,
      ExpressiveMaterialShape.gem,
      ExpressiveMaterialShape.heart,
      ExpressiveMaterialShape.arch,
    ],
  ];

  int _step = 0;

  void _next() => setState(() => _step++);

  Widget _piece(int i, double size, Color color, double turn) {
    final shapes = _turns[i];
    return ExpressiveSpringValue(
      value: _step * turn,
      motion: ExpressiveMotionKey.slowSpatial,
      builder: (context, angle, child) =>
          Transform.rotate(angle: angle, child: child),
      child: ExpressiveSpringShape(
        value: ExpressiveMaterialShapeBorder(shapes[_step % shapes.length]),
        motion: ExpressiveMotionKey.defaultEffects,
        builder: (context, shape, _) => SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: ShapeDecoration(color: color, shape: shape),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    final s = widget.size;
    return ExcludeSemantics(
      child: MouseRegion(
        onEnter: (_) => _next(),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _next(),
          child: SizedBox.square(
            dimension: s,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: _piece(0, s * .66, c.primaryContainer, math.pi / 4),
                ),
                Positioned(
                  right: 0,
                  top: s * .30,
                  child: _piece(1, s * .48, c.tertiary, -math.pi / 3),
                ),
                Positioned(
                  left: s * .20,
                  bottom: 0,
                  child: _piece(2, s * .36, c.secondaryContainer, math.pi / 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The trip planner live beside the pitch on a wide window: the app at a
/// phone's size, working, in a frame of the large corner.
class _LiveTrip extends StatelessWidget {
  const _LiveTrip({required this.onOpen});

  final VoidCallback onOpen;

  /// The frame's size: a phone's.
  static const Size phone = Size(390, 720);

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final media = MediaQuery.of(context);
    return Semantics(
      container: true,
      label: 'The trip planner, live',
      child: ExpressiveSurface(
        key: const ValueKey('overview/live-trip'),
        shape: t.shapes.extraLarge,
        color: t.colors.surface,
        // The phone's edge, drawn over the app it holds (whose own surface
        // would cover an edge drawn under it): a screen, not page content.
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(
            shape: t.shapes.extraLarge.copyWith(
              side: BorderSide(color: t.colors.outline),
            ),
          ),
          child: SizedBox.fromSize(
            size: phone,
            child: MediaQuery(
              data: media.copyWith(
                size: phone,
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
              ),
              // The frame is a screen of its own: its own route, so its dialogs
              // stay in it and its FAB menu is not beside the page's toolbar.
              child: Navigator(
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  transitionDuration: Duration.zero,
                  pageBuilder: (_, _, _) => const TripApp(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The index: every destination but the overview, a row each, in one or
/// two columns.
class _Index extends StatelessWidget {
  const _Index({required this.onOpen, required this.columns});

  final ValueChanged<int> onOpen;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final entries = galleryDestinations.indexed.skip(1).toList();
    final per = (entries.length / columns).ceil();
    Widget section(Iterable<(int, GalleryDestination)> part) =>
        ExpressiveListSection(
          children: [
            for (final (i, d) in part)
              ExpressiveListTile(
                key: ValueKey('overview/${d.title}'),
                leading: Icon(d.icon),
                title: Text(d.title),
                subtitle: Text(d.about),
                trailing: const Icon(ExpressiveSymbols.chevronRight),
                onTap: () => onOpen(i),
              ),
          ],
        );
    if (columns == 1) return section(entries);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ExpressiveSpacing.s16,
      children: [
        for (var k = 0; k < columns; k++)
          Expanded(child: section(entries.skip(k * per).take(per))),
      ],
    );
  }
}
