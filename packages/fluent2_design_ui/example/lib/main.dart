// The Fluent 2 gallery: every page, in every preset, light and dark, and the
// theme's settings. The band at the top picks the page, the preset and the
// appearance; Customize opens the settings (your own brand colour and the
// density), which every page takes as you set them. The page under the band is the gallery's own screen.
//
// A link opens a page in a given theme, direction and text size, the scheme every look's gallery reads:
// /#/<page>?theme=dark&dir=rtl&text=200 (and preset=<id>).
import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import 'gallery_pages.dart';
import 'kit_gallery/kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame: on the web the words never flash in a
  // fallback face and the glyphs never draw as empty boxes.
  await fluent2LoadFonts();
  runApp(GalleryApp(link: GalleryLink.of(Uri.base)));
}

/// What a link asks the gallery to open: `/#/<page>?theme=dark&dir=rtl&text=200`, and `preset=<id>`. Each part is
/// optional; one the gallery does not know is ignored.
class GalleryLink {
  /// A link that asks for nothing.
  const GalleryLink({
    this.page,
    this.theme,
    this.direction,
    this.textScale,
    this.preset,
  });

  /// Reads [uri]'s fragment.
  factory GalleryLink.of(Uri uri) {
    final fragment = uri.fragment;
    if (fragment.isEmpty) return const GalleryLink();
    final at = Uri.tryParse(fragment.startsWith('/') ? fragment : '/$fragment');
    if (at == null) return const GalleryLink();
    final q = at.queryParameters;
    final id = at.pathSegments.isEmpty ? null : at.pathSegments.first;
    final text = double.tryParse(q['text'] ?? '');
    return GalleryLink(
      page: galleryPages.any((p) => p.id == id) ? id : null,
      theme: switch (q['theme']) {
        'dark' => Brightness.dark,
        'light' => Brightness.light,
        _ => null,
      },
      direction: switch (q['dir']) {
        'rtl' => TextDirection.rtl,
        'ltr' => TextDirection.ltr,
        _ => null,
      },
      textScale: text == null || text <= 0 ? null : text / 100,
      preset: Fluent2ThemeData.presets.contains(q['preset'])
          ? q['preset']
          : null,
    );
  }

  /// The page's id.
  final String? page;

  /// Light or dark.
  final Brightness? theme;

  /// The reading direction.
  final TextDirection? direction;

  /// The text scale (`text=200` is 2.0).
  final double? textScale;

  /// The preset's id.
  final String? preset;
}

/// A brand colour the panel offers, for [Fluent2ThemeData.from].
typedef GalleryBrand = ({String name, Color colour});

/// The brand colours the panel offers beside the preset's.
const List<GalleryBrand> galleryBrands = [
  (name: 'Violet', colour: Color(0xFF8A3FFC)),
  (name: 'Teal', colour: Color(0xFF00B294)),
  (name: 'Amber', colour: Color(0xFFFFB900)),
  (name: 'Red', colour: Color(0xFFE81123)),
];

/// What the Customize panel holds. Its defaults are the look's own, so an
/// untouched panel draws the preset as designed.
@immutable
class GalleryCustom {
  /// The panel's settings.
  const GalleryCustom({this.density = Fluent2Density.standard, this.brand});

  /// How compact the controls stand.
  final Fluent2Density density;

  /// Your own brand colour in place of the preset's; null keeps the preset.
  final GalleryBrand? brand;

  /// [preset] in [brightness], or your own brand colour, at [density].
  Fluent2ThemeData theme(String preset, Brightness brightness) {
    final own = brand;
    final base = own == null
        ? Fluent2ThemeData.preset(preset, brightness)
        : Fluent2ThemeData.from(brand: own.colour, brightness: brightness);
    return base.copyWith(density: density);
  }

  /// This with the named settings changed; [brand] is set as given.
  GalleryCustom copyWith({
    Fluent2Density? density,
    GalleryBrand? Function()? brand,
  }) => GalleryCustom(
    density: density ?? this.density,
    brand: brand == null ? this.brand : brand(),
  );
}

/// The gallery with its picker.
class GalleryApp extends StatefulWidget {
  /// The gallery, opening on what [link] asks for, else its first page in the
  /// default preset, light, left to right.
  const GalleryApp({this.link = const GalleryLink(), super.key});

  /// The page, theme, direction and text size to open on.
  final GalleryLink link;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  late var _page = widget.link.page ?? galleryPages.first.id;
  late var _preset = widget.link.preset ?? kitShownPreset;
  late var _brightness = widget.link.theme ?? Brightness.light;
  late var _direction = widget.link.direction ?? TextDirection.ltr;
  late final _textScale = widget.link.textScale;
  var _custom = const GalleryCustom();
  var _customizing = false;

  @override
  Widget build(BuildContext context) {
    kitShownPreset = _preset;
    kitShownDirection = _direction;
    kitShownTextScale = _textScale;
    final custom = _custom;
    kitShownTheme = (brightness) => custom.theme(_preset, brightness);
    final page = galleryPages.firstWhere((p) => p.id == _page);
    final textScale = _textScale;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fluent 2',
      // The link was read before the first frame; the app opens at its root.
      initialRoute: Navigator.defaultRouteName,
      // The snack bars queue in the toaster round the app, inside the theme.
      // The whole gallery reads in the chosen direction, the band included.
      builder: (context, child) => MediaQuery(
        data: textScale == null
            ? MediaQuery.of(context)
            : MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: _direction,
          child: AnimatedFluent2Theme(
            data: custom.theme(_preset, _brightness),
            child: Fluent2Toaster(child: child!),
          ),
        ),
      ),
      home: Builder(
        builder: (context) => ColoredBox(
          color: context.fluent2Theme.background,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: 260,
                        child: Fluent2Select<String>(
                          label: 'Page',
                          value: _page,
                          options: [
                            for (final p in galleryPages)
                              Fluent2Option(p.id, p.title),
                          ],
                          onChanged: (v) => setState(() => _page = v),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: Fluent2Select<String>(
                          label: 'Preset',
                          value: _preset,
                          options: [
                            for (final id in Fluent2ThemeData.presets)
                              Fluent2Option(id, id),
                          ],
                          onChanged: (v) => setState(() => _preset = v),
                        ),
                      ),
                      Fluent2SegmentedButton<Brightness>(
                        label: 'Appearance',
                        value: _brightness,
                        segments: const [
                          Fluent2ButtonSegment(Brightness.light, 'Light'),
                          Fluent2ButtonSegment(Brightness.dark, 'Dark'),
                        ],
                        onChanged: (v) => setState(() => _brightness = v),
                      ),
                      Fluent2SegmentedButton<TextDirection>(
                        label: 'Direction',
                        value: _direction,
                        segments: const [
                          Fluent2ButtonSegment(
                            TextDirection.ltr,
                            'Left to right',
                          ),
                          Fluent2ButtonSegment(
                            TextDirection.rtl,
                            'Right to left',
                          ),
                        ],
                        onChanged: (v) => setState(() => _direction = v),
                      ),
                      Fluent2ToggleButton(
                        'Customize',
                        icon: Fluent2Icons.settings,
                        value: _customizing,
                        onChanged: (v) => setState(() => _customizing = v),
                      ),
                    ],
                  ),
                ),
                if (_customizing)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                    child: CustomizePanel(
                      custom: custom,
                      onChanged: (v) => setState(() => _custom = v),
                    ),
                  ),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(
                      '$_page/$_preset/${_brightness.name}/${_direction.name}/'
                      '${custom.density.vertical}/${custom.brand?.name}',
                    ),
                    child: page.build(_brightness),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The theme's knobs, each a control of the look's own at its natural
/// width.
class CustomizePanel extends StatelessWidget {
  /// A panel over [custom], reporting each change.
  const CustomizePanel({
    super.key,
    required this.custom,
    required this.onChanged,
  });

  /// What it shows.
  final GalleryCustom custom;

  /// Called with the panel's next settings.
  final ValueChanged<GalleryCustom> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = custom;
    final t = context.fluent2Theme;
    Widget strip<T>(
      String label,
      T value,
      List<Fluent2ButtonSegment<T>> segments,
      ValueChanged<T> set,
    ) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Fluent2Spacing.xs,
      children: [
        ExcludeSemantics(
          child: Text(label, style: t.caption1Strong.c(t.textSecondary)),
        ),
        Fluent2SegmentedButton<T>(
          label: label,
          value: value,
          segments: segments,
          onChanged: set,
        ),
      ],
    );
    return Fluent2Card(
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 220,
              child: Fluent2Select<String>(
                label: 'Your own brand colour',
                value: c.brand?.name ?? '',
                options: [
                  const Fluent2Option('', "The preset's"),
                  for (final b in galleryBrands) Fluent2Option(b.name, b.name),
                ],
                onChanged: (v) => onChanged(
                  c.copyWith(
                    brand: () =>
                        galleryBrands.where((b) => b.name == v).firstOrNull,
                  ),
                ),
              ),
            ),
            strip('Density', c.density, const [
              Fluent2ButtonSegment(Fluent2Density.standard, 'Standard'),
              Fluent2ButtonSegment(Fluent2Density.comfortable, 'Comfortable'),
              Fluent2ButtonSegment(Fluent2Density.compact, 'Compact'),
            ], (v) => onChanged(c.copyWith(density: v))),
          ],
        ),
      ],
    );
  }
}
