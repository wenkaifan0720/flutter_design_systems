// The Comic gallery: every part the package exports, live, on pages with plain names. The look's own navigation moves
// between them: a side nav at a desktop's width, a drawer from the app bar's menu button on a phone. The app bar's
// moon or sun turns the page to night or day; Customize opens the theme's knobs (the preset, the strokes, the density,
// the faces, your own colours, the reading direction and the text scaling) and every page takes them as you set them.
// Comic's corners stay square and its type at the look's sizes: the platform's text scaling serves readers.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'gallery_pages.dart' show GalleryPage;
import 'kit_gallery/kit.dart';
import 'kit_gallery/live_pages.dart';

/// The live pages as the deck holds them.
final List<GalleryPage> examplePages = [
  for (final page in livePages)
    (id: page.id, title: page.title, build: (_) => livePageBody(page)),
];

/// A gallery viewport that retains visited pages and pauses hidden animations.
///
/// Each appearance has its own page state. Customization updates the active
/// page in place and reaches other visited pages when they are shown again.
class GalleryPageDeck extends StatefulWidget {
  /// Creates the viewport for [pageId] in [brightness].
  const GalleryPageDeck({
    super.key,
    required this.pages,
    required this.pageId,
    required this.preset,
    required this.brightness,
    this.revision,
  });

  /// The pages the gallery can show.
  final List<GalleryPage> pages;

  /// The selected page's identifier.
  final String pageId;

  /// The selected printing preset.
  final String preset;

  /// The selected appearance.
  final Brightness brightness;

  /// Changes when customization changes, without replacing the active state.
  final Object? revision;

  @override
  GalleryPageDeckState createState() => GalleryPageDeckState();
}

/// Retained pages and the currently visible subtree.
class GalleryPageDeckState extends State<GalleryPageDeck> {
  final _visited = <(String, Brightness), _VisitedPage>{};
  final _navigator = GlobalKey<NavigatorState>();

  /// The visited page/appearance pairs currently retained by the viewport.
  int get retainedPageCount => _visited.length;

  /// The active subtree, for scrolling or inspecting the page on screen.
  BuildContext? get activeContext =>
      _visited[(widget.pageId, widget.brightness)]?.key.currentContext;

  @override
  void didUpdateWidget(GalleryPageDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset) _visited.clear();
    if (oldWidget.pageId != widget.pageId ||
        oldWidget.brightness != widget.brightness ||
        oldWidget.preset != widget.preset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final navigator =
              Navigator.maybeOf(context, rootNavigator: true) ??
              _navigator.currentState;
          navigator?.popUntil((route) => route.isFirst);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = (widget.pageId, widget.brightness);
    final page = widget.pages.firstWhere((page) => page.id == widget.pageId);
    final active = _visited.putIfAbsent(
      id,
      () => _VisitedPage(widget.revision, page.build(widget.brightness)),
    );
    if (active.revision != widget.revision) {
      active
        ..revision = widget.revision
        ..child = page.build(widget.brightness);
    }
    final entries = _visited.entries.toList();
    final content = KitGalleryScope(
      child: IndexedStack(
        alignment: Alignment.topLeft,
        index: entries.indexWhere((entry) => entry.key == id),
        sizing: StackFit.expand,
        children: [
          for (final entry in entries)
            TickerMode(
              enabled: entry.key == id,
              child: ExcludeFocus(
                excluding: entry.key != id,
                child: KeyedSubtree(
                  key: entry.value.key,
                  child: KeyedSubtree(
                    key: ValueKey(
                      '${entry.key.$1}/${widget.preset}/${entry.key.$2.name}',
                    ),
                    child: entry.value.child,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (Navigator.maybeOf(context) != null) return content;
    return MaterialApp(
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      title: 'Comic',
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: comicPageTransitions,
        ),
      ),
      home: content,
    );
  }
}

class _VisitedPage {
  _VisitedPage(this.revision, this.child);
  final key = GlobalKey();
  Object? revision;
  Widget child;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame: on the web the words never flash in a fallback face.
  await comicLoadFonts();
  runApp(const GalleryApp());
}

/// Three printing inks for `ComicThemeData.from`: act, caption and shade.
typedef GalleryColours = ({String name, Color act, Color caption, Color shade});

/// The colour pairs the panel offers in place of a preset.
const List<GalleryColours> galleryColours = [
  (
    name: 'Plum press',
    act: Color(0xff802651),
    caption: Color(0xffeed36a),
    shade: Color(0xff276c99),
  ),
  (
    name: 'Teal issue',
    act: Color(0xff087c72),
    caption: Color(0xfff6bc54),
    shade: Color(0xff6852a0),
  ),
  (
    name: 'Night ink',
    act: Color(0xff273d72),
    caption: Color(0xffe9cb86),
    shade: Color(0xff825066),
  ),
  (
    name: 'Rose paper',
    act: Color(0xffb0305a),
    caption: Color(0xffedcf64),
    shade: Color(0xff3b6e8f),
  ),
];

/// What the Customize panel holds. Its defaults are the look's own, so an untouched panel draws the preset as designed.
@immutable
class GalleryCustom {
  /// The panel's settings.
  const GalleryCustom({
    this.bold = false,
    this.density = ComicDensity.standard,
    this.oneFace = false,
    this.colours,
    this.direction = TextDirection.ltr,
    this.textScale = 1,
  });

  /// Rims at 4 and the focus ring at 5.
  final bool bold;

  /// How compact the controls stand.
  final ComicDensity density;

  /// Shantell Sans for the heads too, in place of Bangers.
  final bool oneFace;

  /// Your own colours in place of the preset's; null keeps the preset.
  final GalleryColours? colours;

  /// The gallery's reading direction: right to left mirrors every page.
  final TextDirection direction;

  /// The system's text scaling the pages see, as a reader's accessibility setting would set it.
  final double textScale;

  /// [preset] in [brightness], or your own colours, with every knob set.
  ComicThemeData theme(String preset, Brightness brightness) {
    final pair = colours;
    final base = pair == null
        ? ComicThemeData.preset(preset, brightness)
        : ComicThemeData.from(
            primary: pair.act,
            caption: pair.caption,
            shade: pair.shade,
            brightness: brightness,
          );
    return base.copyWith(
      strokes: bold ? ComicStrokes.bold : ComicStrokes.standard,
      density: density,
      typeface: ComicTypeface.look.copyWith(
        display: oneFace ? 'ShantellSans' : null,
      ),
    );
  }

  /// This with the named settings changed; [colours] is set as given.
  GalleryCustom copyWith({
    bool? bold,
    ComicDensity? density,
    bool? oneFace,
    GalleryColours? Function()? colours,
    TextDirection? direction,
    double? textScale,
  }) => GalleryCustom(
    bold: bold ?? this.bold,
    density: density ?? this.density,
    oneFace: oneFace ?? this.oneFace,
    colours: colours == null ? this.colours : colours(),
    direction: direction ?? this.direction,
    textScale: textScale ?? this.textScale,
  );
}

/// The gallery: the look's app bar, its navigation and the live pages, with the Customize panel under the bar.
///
/// A link opens any page in a given theme, direction and text size, the scheme every look's gallery shares:
/// `/#/<page>?theme=dark&dir=rtl&text=200` (the page's id, as `buttons` or `dialogs`; `theme` light or dark; `dir`
/// ltr or rtl; `text` the text scaling in percent). Right to left reads in Arabic: the everyday screens, the pages'
/// names and the sections' labels, so the direction is checked on real script, not English reordered.
class GalleryApp extends StatefulWidget {
  /// The gallery, opening on the page, theme, direction and text size its link names, else the overview by day.
  /// [page], [brightness] and [direction], when given, open it there whatever the link says.
  const GalleryApp({super.key, this.page, this.brightness, this.direction});

  /// The page it opens on, by its id (as `buttons` or `form`).
  final String? page;

  /// Whether it opens by day or by night.
  final Brightness? brightness;

  /// The direction it opens in; right to left reads in Arabic.
  final TextDirection? direction;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> with WidgetsBindingObserver {
  var _page = livePages.first.id;
  var _preset = kitShownPreset;
  var _brightness = Brightness.light;
  var _custom = const GalleryCustom();
  var _customizing = false;

  void _go(String id) => setState(() => _page = id);

  @override
  void initState() {
    super.initState();
    // Watching before the app's own navigator does, so a link the browser pushes later comes here first.
    WidgetsBinding.instance.addObserver(this);
    final link = Uri.tryParse(Uri.base.fragment);
    if (link != null) _follow(link);
    if (livePages.any((page) => page.id == widget.page)) _page = widget.page!;
    _brightness = widget.brightness ?? _brightness;
    _custom = _custom.copyWith(direction: widget.direction);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Opens what [link] names: its page, and its theme, direction and text size where it gives them.
  void _follow(Uri link) {
    final id = link.pathSegments.where((part) => part.isNotEmpty).firstOrNull;
    if (livePages.any((page) => page.id == id)) _page = id!;
    final query = link.queryParameters;
    _brightness = switch (query['theme']) {
      'dark' => Brightness.dark,
      'light' => Brightness.light,
      _ => _brightness,
    };
    final text = int.tryParse(query['text'] ?? '');
    _custom = _custom.copyWith(
      direction: switch (query['dir']) {
        'rtl' => TextDirection.rtl,
        'ltr' => TextDirection.ltr,
        _ => null,
      },
      textScale: text != null && text >= 50 && text <= 400 ? text / 100 : null,
    );
  }

  // A link the browser pushes after the start (an address the reader edits, or Back to the opening link) is followed
  // in place. The app's navigator knows no named routes: given the link, it would find no page for it and throw.
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    setState(() => _follow(routeInformation.uri));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    kitShownPreset = _preset;
    // Every page builds its theme through this: the panel's knobs reach each page as they change.
    final custom = _custom, preset = _preset;
    kitShownTheme = (brightness) => custom.theme(preset, brightness);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comic',
      // Comic's page change, a cut, for the pages the gallery pushes, as an app gives it to its own routes.
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: comicPageTransitions,
        ),
      ),
      // ui_core's 30 languages, as an ordinary app gives them: a device in one of them hears the parts' shared words
      // (Cancel, Close, Today) in it, and right to left the gallery reads Arabic, Comic's own words with it.
      // flutter_localizations gives Flutter's Material and Cupertino words; Comic's theme gives its own library's.
      locale: custom.direction == TextDirection.rtl ? const Locale('ar') : null,
      supportedLocales: DesignLocalizations.supportedLocales,
      localizationsDelegates: [
        DesignLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        KitComicWords(arabic: custom.direction == TextDirection.rtl),
      ],
      builder: (context, child) => KitWords(
        arabic: custom.direction == TextDirection.rtl,
        child: Directionality(
          textDirection: custom.direction,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(custom.textScale)),
            child: ComicHost(
              light: custom.theme(preset, Brightness.light),
              dark: custom.theme(preset, Brightness.dark),
              brightness: _brightness,
              child: child!,
            ),
          ),
        ),
      ),
      home: LiveNavigation(
        go: _go,
        child: Builder(builder: _shell),
      ),
    );
  }

  Widget _shell(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final at = livePages.indexWhere((page) => page.id == _page);
    final items = [
      for (final page in livePages)
        ComicNavItem(
          label: kitSay(context, page.title),
          short: kitSay(context, page.title),
          icon: page.icon,
          key: ValueKey('nav/${page.id}'),
        ),
    ];
    ComicNavigationDrawer drawer(ValueChanged<int> select) =>
        ComicNavigationDrawer(
          label: 'Pages',
          header: const Padding(
            padding: EdgeInsetsDirectional.only(start: 4, top: 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ComicLogo('Comic'),
            ),
          ),
          destinations: items,
          selectedIndex: at,
          onDestinationSelected: select,
        );
    final night = _brightness == Brightness.dark;
    final bar = ComicAppBar(
      title: kitSay(context, livePages[at].title),
      leading: wide
          ? null
          : ComicIconButton(
              LucideIcons.menu,
              key: const ValueKey('nav/open'),
              label: 'Pages',
              onPressed: () async {
                final chosen = await showComicNavigationDrawer<int>(
                  context,
                  builder: (context) =>
                      drawer((i) => Navigator.of(context).pop(i)),
                );
                if (chosen != null) _go(livePages[chosen].id);
              },
            ),
      actions: [
        ComicIconButton(
          night ? LucideIcons.sun : LucideIcons.moon,
          key: const ValueKey('appearance'),
          label: night ? 'Day' : 'Night',
          onPressed: () => setState(
            () => _brightness = night ? Brightness.light : Brightness.dark,
          ),
        ),
        ComicIconButton(
          LucideIcons.slidersHorizontal,
          key: const ValueKey('customize'),
          label: 'Customize',
          selected: _customizing,
          onPressed: () => setState(() => _customizing = !_customizing),
        ),
      ],
    );
    final t = ComicTheme.of(context);
    // At a desk the sidebar runs the window's height with the brand at its top, and the bar stands over the content:
    // the page's title and its panels share one leading edge on every page.
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        if (_customizing)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .5,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.colors.card,
                border: Border(
                  bottom: BorderSide(
                    color: t.colors.nightLine,
                    width: t.rim(3),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: t.desk ? 32 : 12,
                  vertical: 16,
                ),
                child: CustomizePanel(
                  custom: _custom,
                  onChanged: (custom) => setState(() => _custom = custom),
                  preset: _preset,
                  onPreset: (preset) => setState(() => _preset = preset),
                ),
              ),
            ),
          ),
        Expanded(
          child: GalleryPageDeck(
            pages: examplePages,
            pageId: _page,
            preset: _preset,
            brightness: _brightness,
            revision: _custom,
          ),
        ),
      ],
    );
    if (!wide) return content;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 264, child: drawer((i) => _go(livePages[i].id))),
        Expanded(child: content),
      ],
    );
  }
}

/// The theme's knobs, each a control of the look's own at its natural width, on a grid from the start edge.
class CustomizePanel extends StatelessWidget {
  /// A panel over [custom], reporting each change to [onChanged]; with [onPreset], the preset too.
  const CustomizePanel({
    super.key,
    required this.custom,
    required this.onChanged,
    this.preset,
    this.onPreset,
  });

  /// What it shows.
  final GalleryCustom custom;

  /// Called with the panel's next settings.
  final ValueChanged<GalleryCustom> onChanged;

  /// The preset shown, offered as a select when [onPreset] is set.
  final String? preset;

  /// Called with the preset chosen.
  final ValueChanged<String>? onPreset;

  @override
  Widget build(BuildContext context) {
    final c = custom;
    final chosen = preset;
    final choose = onPreset;
    return Wrap(
      spacing: 32,
      runSpacing: 20,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        if (chosen != null && choose != null)
          SizedBox(
            width: 220,
            child: ComicSelect<String>(
              label: 'Preset',
              value: chosen,
              options: [
                for (final id in ComicThemeData.presets)
                  ComicSelectOption(id, id),
              ],
              onChanged: choose,
            ),
          ),
        _Labelled(
          'Strokes',
          ComicSegmentedButton<bool>(
            label: 'Strokes',
            value: c.bold,
            segments: const [
              ComicButtonSegment(false, 'As drawn'),
              ComicButtonSegment(true, 'Bold'),
            ],
            onChanged: (v) => onChanged(c.copyWith(bold: v)),
          ),
        ),
        _Labelled(
          'Density',
          ComicSegmentedButton<ComicDensity>(
            label: 'Density',
            value: c.density,
            segments: const [
              ComicButtonSegment(ComicDensity.standard, 'Standard'),
              ComicButtonSegment(ComicDensity.comfortable, 'Comfortable'),
              ComicButtonSegment(ComicDensity.compact, 'Compact'),
            ],
            onChanged: (v) => onChanged(c.copyWith(density: v)),
          ),
        ),
        _Labelled(
          'Families',
          ComicSegmentedButton<bool>(
            label: 'Families',
            value: c.oneFace,
            segments: const [
              ComicButtonSegment(false, 'Bangers and Shantell'),
              ComicButtonSegment(true, 'Shantell alone'),
            ],
            onChanged: (v) => onChanged(c.copyWith(oneFace: v)),
          ),
        ),
        _Labelled(
          'Direction',
          ComicSegmentedButton<TextDirection>(
            label: 'Direction',
            value: c.direction,
            segments: const [
              ComicButtonSegment(TextDirection.ltr, 'Left to right'),
              ComicButtonSegment(TextDirection.rtl, 'Right to left'),
            ],
            onChanged: (v) => onChanged(c.copyWith(direction: v)),
          ),
        ),
        _Labelled(
          'Text scaling',
          ComicSegmentedButton<double>(
            label: 'Text scaling',
            value: c.textScale,
            segments: const [
              ComicButtonSegment(1.0, '100%'),
              ComicButtonSegment(1.5, '150%'),
              ComicButtonSegment(2.0, '200%'),
            ],
            onChanged: (v) => onChanged(c.copyWith(textScale: v)),
          ),
        ),
        SizedBox(
          width: 220,
          child: ComicSelect<String>(
            label: 'Your own colours',
            value: c.colours?.name ?? '',
            options: [
              const ComicSelectOption('', "The preset's"),
              for (final pair in galleryColours)
                ComicSelectOption(pair.name, pair.name),
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
    );
  }
}

/// A knob's name drawn above its strip: a segmented button names itself only to a screen reader.
class _Labelled extends StatelessWidget {
  const _Labelled(this.text, this.child);

  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(child: ComicLabel(text)),
      const SizedBox(height: 4),
      child,
    ],
  );
}
