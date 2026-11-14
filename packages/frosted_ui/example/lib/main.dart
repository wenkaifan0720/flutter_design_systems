// The Frosted gallery: every page of the look's gallery, in every preset, by
// day and by night, over each backdrop, and made yours. The glass bar at the
// top goes back to the list of pages and sets the appearance and what stands
// behind the glass (the light, the night sky, a plain ground; below the
// desktop both wait in the Customize panel, so the bar stays one row); Customize opens
// the preset and the theme's knobs (the density, your own accent) and every page takes them as you set them. The
// page under the bar is the gallery's own screen, as the catalog renders it.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

import 'gallery_pages.dart';
import 'kit_gallery/harbor.dart';
import 'kit_gallery/kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame: on the web the words never flash in a
  // fallback face.
  await frostedLoadFonts();
  runApp(const GalleryApp());
}

/// An accent for `FrostedThemeData.from`, by name.
typedef GalleryAccent = ({String name, Color accent});

/// The accents the panel offers in place of a preset.
const List<GalleryAccent> galleryAccents = [
  (name: 'Ocean', accent: Color(0xFF0A7CFF)),
  (name: 'Forest', accent: Color(0xFF2F7D5B)),
  (name: 'Ember', accent: Color(0xFFD9480F)),
  (name: 'Orchid', accent: Color(0xFFA23CC8)),
];

/// What the Customize panel holds. Its defaults are the look's own, so an
/// untouched panel draws the preset as designed.
@immutable
class GalleryCustom {
  /// The panel's settings.
  const GalleryCustom({
    this.density,
    this.accent,
    this.backdrop = FrostedBackdropKind.dawn,
    this.direction = TextDirection.ltr,
    this.textScale,
  });

  /// How compact the controls stand; null is the platform's (compact on a
  /// desktop, standard on touch).
  final FrostedDensity? density;

  /// Your own accent in place of the preset; null keeps the preset.
  final GalleryAccent? accent;

  /// What stands behind the glass.
  final FrostedBackdropKind backdrop;

  /// The reading direction every page lays out in: right to left mirrors
  /// them, as an Arabic or Hebrew reader sees them.
  final TextDirection direction;

  /// The text size; null is the device's.
  final double? textScale;

  /// The theme's backdrop for [backdrop].
  FrostedBackdrop get backdropOf => switch (backdrop) {
    FrostedBackdropKind.night => const FrostedBackdrop.night(),
    FrostedBackdropKind.plain => const FrostedBackdrop.plain(),
    _ => const FrostedBackdrop.dawn(),
  };

  /// [preset] in [brightness], or your own accent, with every knob set.
  FrostedThemeData theme(String preset, Brightness brightness) {
    final own = accent;
    final base = own == null
        ? FrostedThemeData.preset(preset, brightness)
        : FrostedThemeData.from(accent: own.accent, brightness: brightness);
    return base.copyWith(density: density, backdrop: backdropOf);
  }

  /// This with the named settings changed; [accent] is set as given.
  GalleryCustom copyWith({
    FrostedDensity? density,
    GalleryAccent? Function()? accent,
    FrostedBackdropKind? backdrop,
    TextDirection? direction,
    double? Function()? textScale,
  }) => GalleryCustom(
    density: density ?? this.density,
    accent: accent == null ? this.accent : accent(),
    backdrop: backdrop ?? this.backdrop,
    direction: direction ?? this.direction,
    textScale: textScale == null ? this.textScale : textScale(),
  );
}

/// The gallery: its list of pages, the page it shows, the preset, the
/// appearance and the Customize panel.
class GalleryApp extends StatefulWidget {
  /// The gallery, opening on its list of pages in opal by day.
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  /// The page shown, by its index in [galleryPages]; null shows the list.
  int? _page;
  var _preset = kitShownPreset;
  var _brightness = Brightness.light;
  var _custom = const GalleryCustom();
  var _customizing = false;

  /// The dialog or sheet a page has raised, if any: the bar dims and softens
  /// under it as the page does.
  final _raised = ValueNotifier<ModalRoute<Object?>?>(null);

  /// Whether a link asked for Harbor: it opens over the list once.
  var _harborLink = false;

  @override
  void initState() {
    super.initState();
    kitNavigatorObservers = () => [_RaisedWatch(_raised)];
    _follow(Uri.tryParse(Uri.base.fragment));
  }

  /// Opens what a link names, in the scheme every look's gallery shares:
  /// `/#/<page>?theme=dark&dir=rtl&text=200`, `<page>` a page's id (or
  /// `harbor`), `text` a percentage; `backdrop=night|plain` and
  /// `preset=<name>` besides.
  void _follow(Uri? link) {
    if (link == null) return;
    final id = link.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
    final at = galleryPages.indexWhere((p) => p.id == id);
    if (at >= 0) _page = at;
    _harborLink = id == 'harbor';
    final q = link.queryParameters;
    if (q['theme'] == 'dark') _brightness = Brightness.dark;
    final preset = q['preset'];
    if (FrostedThemeData.presets.contains(preset)) _preset = preset!;
    final text = double.tryParse(q['text'] ?? '');
    _custom = _custom.copyWith(
      direction: q['dir'] == 'rtl' ? TextDirection.rtl : null,
      textScale: text == null ? null : () => text == 100 ? null : text / 100,
      backdrop: switch (q['backdrop']) {
        'night' => FrostedBackdropKind.night,
        'plain' => FrostedBackdropKind.plain,
        _ => null,
      },
    );
  }

  @override
  void dispose() {
    kitNavigatorObservers = null;
    _raised.dispose();
    super.dispose();
  }

  /// Opens Harbor over the gallery: its Settings set the backdrop and the
  /// appearance the gallery carries, its close comes back here.
  void _openHarbor(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => HarborApp(
          host: HarborHost(
            onBackdrop: (kind) =>
                setState(() => _custom = _custom.copyWith(backdrop: kind)),
            onBrightness: (b) => setState(() => _brightness = b),
            onExit: navigator.pop,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    kitShownPreset = _preset;
    // Every gallery page builds its theme through this: the panel's knobs
    // reach each page as they change.
    final custom = _custom;
    kitShownTheme = (brightness) => custom.theme(_preset, brightness);
    // Each page is its own app, whose localizations would lay it out left
    // to right: the panel's direction reaches them through this.
    kitShownDirection = custom.direction;
    return MaterialApp(
      title: 'Frosted gallery',
      debugShowCheckedModeBanner: false,
      // A link's page and modes are read above; the navigator starts at home.
      initialRoute: Navigator.defaultRouteName,
      // The panel's direction and text size reach every page, Harbor's too.
      builder: (context, child) => Directionality(
        textDirection: custom.direction,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: switch (custom.textScale) {
              final scale? => TextScaler.linear(scale),
              null => MediaQuery.textScalerOf(context),
            },
          ),
          child: FrostedHost(
            light: custom.theme(_preset, Brightness.light),
            dark: custom.theme(_preset, Brightness.dark),
            brightness: _brightness,
            child: child!,
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final t = context.frostedTheme;
          if (_harborLink) {
            _harborLink = false;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _openHarbor(context),
            );
          }
          final page = _page == null ? null : galleryPages[_page!];
          // The gallery stands on the theme's backdrop, its bar a glass over
          // it, as every page under it does. The bar is always one row of
          // one height: below the desktop (1024) it holds back, the page's
          // name and Customize, the appearance and the backdrop waiting in
          // the panel Customize opens; on the desktop they stand in it too.
          final compact =
              MediaQuery.sizeOf(context).width < FrostedBreakpoints.wide;
          final appearance = FrostedSegmentedButton<Brightness>(
            segments: const [
              FrostedButtonSegment(Brightness.light, 'Light'),
              FrostedButtonSegment(Brightness.dark, 'Dark'),
            ],
            value: _brightness,
            label: 'Appearance',
            onChanged: (b) => setState(() => _brightness = b),
          );
          final backdrop = FrostedSegmentedButton<FrostedBackdropKind>(
            segments: const [
              FrostedButtonSegment(FrostedBackdropKind.dawn, 'Dawn'),
              FrostedButtonSegment(FrostedBackdropKind.night, 'Night sky'),
              FrostedButtonSegment(FrostedBackdropKind.plain, 'Plain'),
            ],
            value: _custom.backdrop,
            label: 'Backdrop',
            onChanged: (kind) =>
                setState(() => _custom = _custom.copyWith(backdrop: kind)),
          );
          void customize() => setState(() => _customizing = !_customizing);
          final back = page == null
              ? null
              : FrostedButton.glass(
                  'Pages',
                  icon: FrostedGlyphs.back,
                  size: FrostedButtonSize.small,
                  onPressed: () => setState(() => _page = null),
                );
          final title = Text(
            page?.title ?? 'Frosted',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.bodyLarge.copyWith(
              color: t.colorScheme.textPrimary,
            ),
          );
          final head = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostedSurface(
                material: FrostedMaterial.bar,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: compact
                        ? Row(
                            spacing: 12,
                            children: [
                              ?back,
                              Expanded(child: title),
                              FrostedIconButton(
                                FrostedGlyphs.sparkles,
                                label: 'Customize',
                                selected: _customizing,
                                size: FrostedIconButtonSize.small,
                                onPressed: customize,
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ?back,
                              title,
                              appearance,
                              backdrop,
                              FrostedButton.glass(
                                _customizing ? 'Done' : 'Customize',
                                icon: FrostedGlyphs.sparkles,
                                size: FrostedButtonSize.small,
                                onPressed: customize,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              if (_customizing)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .45,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        if (compact)
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [appearance, backdrop],
                          ),
                        CustomizePanel(
                          custom: _custom,
                          onChanged: (c) => setState(() => _custom = c),
                          preset: _preset,
                          onPreset: (v) => setState(() => _preset = v),
                        ),
                      ],
                    ),
                  ),
                ),
              // The bar's foot: the lit hairline by day, the night glass's rule
              // by night.
              Container(
                height: 1,
                color: t.isDark
                    ? t.colorScheme.border
                    : const Color(0xD9FFFFFF),
              ),
            ],
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              const FrostedBackdropView(),
              Column(
                children: [
                  // Under a demo's dialog or sheet the bar dims and softens
                  // with the page, so the whole window is covered.
                  Stack(
                    children: [
                      head,
                      Positioned.fill(child: _RaisedOver(_raised)),
                    ],
                  ),
                  Expanded(
                    child: page == null
                        ? FrostedScaffold(
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 16,
                              children: [
                                _Overview(onOpen: () => _openHarbor(context)),
                                _Sections(
                                  onOpen: (i) => setState(() => _page = i),
                                ),
                              ],
                            ),
                          )
                        // Keyed by what the page is, not by the knobs: a page
                        // keeps its scroll and its state as the knobs change.
                        : KeyedSubtree(
                            key: ValueKey((page.id, _preset, _brightness)),
                            child: page.build(_brightness),
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The home page's sections, each a tile of glass holding the pages it
/// names by id, as an app's settings hold their rows; a page no section
/// names stands in the last.
const List<(String, List<String>)> _sections = [
  ('Start here', ['foundations', 'preview', 'inventory']),
  (
    'Actions',
    ['controls', 'actions', 'toggle', 'action-bar', 'swipe', 'sign-in'],
  ),
  (
    'Inputs',
    [
      'inputs',
      'entry',
      'selection',
      'choices',
      'pickers',
      'combobox',
      'calendar',
      'slider',
      'color-picker',
      'composer',
      'forms',
    ],
  ),
  ('Navigation', ['shell', 'top-bar', 'tabs', 'move', 'command']),
  (
    'Surfaces',
    [
      'structure',
      'card',
      'list-section',
      'sheet',
      'dialog',
      'menu',
      'raise',
      'popover',
      'scroll',
    ],
  ),
  ('Feedback', ['states', 'progress']),
  (
    'Money and data',
    [
      'money',
      'meters',
      'charts',
      'data',
      'hold',
      'week',
      'marks',
      'image',
      'wordmark',
    ],
  ),
];

/// The gallery's pages on glass: [_sections] as tiles of rows, one column
/// on a phone, two from 720 wide and three from 1200.
class _Sections extends StatelessWidget {
  const _Sections({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final index = {for (final (i, p) in galleryPages.indexed) p.id: i};
    final named = {for (final (_, ids) in _sections) ...ids};
    final rest = [
      for (final p in galleryPages)
        if (!named.contains(p.id)) p.id,
    ];
    final tiles = [
      for (final (title, ids) in [..._sections, ('More', rest)])
        if (ids.any(index.containsKey))
          FrostedSettingsGroup(
            title: title,
            children: [
              for (final id in ids)
                if (index[id] case final i?)
                  FrostedValueRow(
                    title: galleryPages[i].title,
                    onPressed: () => onOpen(i),
                  ),
            ],
          ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 1200
            ? 3
            : box.maxWidth >= 720
            ? 2
            : 1;
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: tiles,
          );
        }
        // Each tile to the column holding the fewest rows so far, so the
        // columns end near one another.
        final stacks = [for (var c = 0; c < columns; c++) <Widget>[]];
        final rows = List<int>.filled(columns, 0);
        for (final tile in tiles) {
          var c = 0;
          for (var k = 1; k < columns; k++) {
            if (rows[k] < rows[c]) c = k;
          }
          stacks[c].add(tile);
          rows[c] += 1 + tile.children.length;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            for (final stack in stacks)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: stack,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Follows the dialogs and sheets a page raises over itself: the one on top
/// that dims what is below it.
class _RaisedWatch extends NavigatorObserver {
  _RaisedWatch(this.raised);

  final ValueNotifier<ModalRoute<Object?>?> raised;
  final _stack = <ModalRoute<Object?>>[];

  static bool _dims(Route<Object?> route) =>
      route is PopupRoute<Object?> && (route.barrierColor?.a ?? 0) > 0;

  void _show() => raised.value = _stack.isEmpty ? null : _stack.last;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    if (!_dims(route)) return;
    final modal = route as ModalRoute<Object?>;
    _stack.add(modal);
    // The bar clears as the route's own barrier does, as it begins to leave.
    modal.animation?.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _forget(modal);
    });
    _show();
  }

  void _forget(Route<Object?> route) {
    if (_stack.remove(route)) _show();
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) {
    // A route leaving with an animation clears the bar as it runs out.
    final rise = route is ModalRoute<Object?> ? route.animation : null;
    if (rise == null || rise.isDismissed) _forget(route);
  }

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      _forget(route);
}

/// The raised route's barrier, carried over the gallery's bar: the same
/// colour along the same curve, the same softening when the route softens
/// the page (a dialog's or a sheet's scrim), and a tap on it dismisses the
/// route as a tap on the page's barrier does.
class _RaisedOver extends StatelessWidget {
  const _RaisedOver(this.raised);

  final ValueNotifier<ModalRoute<Object?>?> raised;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return ValueListenableBuilder(
      valueListenable: raised,
      builder: (context, route, _) {
        final rise = route?.animation;
        final color = route?.barrierColor;
        if (route == null || rise == null || color == null) {
          return const SizedBox.shrink();
        }
        final soften = color == t.materials.scrim ? t.materials.soften : 0.0;
        final curve = route.barrierCurve;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: route.barrierDismissible
              ? () => route.navigator?.maybePop()
              : null,
          child: AnimatedBuilder(
            animation: rise,
            builder: (context, _) {
              final v = rise.value.clamp(0.0, 1.0);
              final blur = v * soften;
              final dim = ColoredBox(
                color: color.withValues(alpha: color.a * curve.transform(v)),
              );
              return blur <= .01
                  ? dim
                  : ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                        child: dim,
                      ),
                    );
            },
          ),
        );
      },
    );
  }
}

/// The pitch at the head of the gallery: what Frosted is, in a sentence,
/// and the app that shows it.
class _Overview extends StatelessWidget {
  const _Overview({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Frosted',
            style: t.textTheme.displayMedium.c(t.colorScheme.textPrimary),
          ),
          Text(
            'A look made of glass. Every bar, card, field and sheet is a '
            'material the page passes under: blurred, lit along its edge, '
            'thicker the higher it floats.',
            style: t.textTheme.titleMedium.c(t.colorScheme.textSecondary),
          ),
          FrostedButton('Open Harbor', onPressed: onOpen),
        ],
      ),
    );
  }
}

/// The theme's knobs, each a control of the look's own.
class CustomizePanel extends StatelessWidget {
  /// A panel over [custom], reporting each change to [onChanged].
  const CustomizePanel({
    super.key,
    required this.custom,
    required this.onChanged,
    this.preset,
    this.onPreset,
  });

  /// The preset shown; null leaves the preset out of the panel.
  final String? preset;

  /// Called with the preset chosen.
  final ValueChanged<String>? onPreset;

  /// What it shows.
  final GalleryCustom custom;

  /// Called with the panel's next settings.
  final ValueChanged<GalleryCustom> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = custom;
    return FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (preset case final preset?)
            FrostedSelect<String>(
              label: 'Preset',
              value: preset,
              options: [
                for (final id in FrostedThemeData.presets)
                  FrostedSelectOption(id, id),
              ],
              onChanged: (v) => onPreset?.call(v),
            ),
          FrostedSegmentedButton<FrostedDensity>(
            label: 'Density',
            labelled: true,
            fill: true,
            value: c.density ?? FrostedDensity.adaptivePlatformDensity,
            segments: const [
              FrostedButtonSegment(FrostedDensity.standard, 'Standard'),
              FrostedButtonSegment(FrostedDensity.comfortable, 'Comfortable'),
              FrostedButtonSegment(FrostedDensity.compact, 'Compact'),
            ],
            onChanged: (v) => onChanged(c.copyWith(density: v)),
          ),
          FrostedSegmentedButton<TextDirection>(
            label: 'Direction',
            labelled: true,
            fill: true,
            value: c.direction,
            segments: const [
              FrostedButtonSegment(TextDirection.ltr, 'Left to right'),
              FrostedButtonSegment(TextDirection.rtl, 'Right to left'),
            ],
            onChanged: (v) => onChanged(c.copyWith(direction: v)),
          ),
          FrostedSegmentedButton<double>(
            label: 'Text size',
            labelled: true,
            fill: true,
            value: c.textScale ?? 1,
            segments: const [
              FrostedButtonSegment(1, 'Device'),
              FrostedButtonSegment(1.5, '150%'),
              FrostedButtonSegment(2, '200%'),
            ],
            onChanged: (v) =>
                onChanged(c.copyWith(textScale: () => v == 1 ? null : v)),
          ),
          FrostedSelect<String>(
            label: 'Your own accent',
            value: c.accent?.name ?? '',
            options: [
              const FrostedSelectOption('', "The preset's"),
              for (final a in galleryAccents)
                FrostedSelectOption(a.name, a.name),
            ],
            onChanged: (v) => onChanged(
              c.copyWith(
                accent: () =>
                    galleryAccents.where((a) => a.name == v).firstOrNull,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
