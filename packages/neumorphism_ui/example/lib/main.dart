// The Neumorphism gallery: every part the package exports, working, on pages with plain names, in every preset, by day
// and by night, and made yours. The look's own navigation moves between the pages: the pilaster rail from 1024 wide, a
// drawer behind the menu key below that. Customize opens what a product team really turns (the preset or your own
// colours, the density, the depth, high contrast) above every page, and every page takes them as you set them.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'kit_gallery/hearth.dart';
import 'kit_gallery/live.dart';
import 'kit_gallery/kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame: on the web the words never flash in a fallback face.
  await neumorphicLoadFonts();
  // A page opens by link, in the looks' shared form /#/<page>?theme=dark&dir=rtl&text=200 or the gallery's own
  // ?design=<page>&dark=1&rtl=1&text=2 (and ?contrast=1, ?density=compact, ?slow=8).
  final link = Uri.parse(Uri.base.fragment.isEmpty ? '/' : Uri.base.fragment);
  final query = {...Uri.base.queryParameters, ...link.queryParameters};
  final linkedPage = link.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
  final text = double.tryParse(query['text'] ?? '') ?? 1;
  // A reviewer's slow motion: ?slow=8 plays every move eight times slower, so a frame between two states can be looked
  // at with a real pointer.
  timeDilation = (double.tryParse(query['slow'] ?? '') ?? 1).clamp(1, 20);
  runApp(
    GalleryApp(
      initialPage: linkedPage ?? query['design'] ?? 'overview',
      initialBrightness: query['theme'] == 'dark' || query['dark'] == '1'
          ? Brightness.dark
          : Brightness.light,
      initialCustom: GalleryCustom(
        highContrast: query['contrast'] == '1',
        rightToLeft: query['dir'] == 'rtl' || query['rtl'] == '1',
        // text=200 is a percentage, text=2 a scale.
        textScale: (text > 4 ? text / 100 : text).clamp(1, 2),
        density: GalleryDensity.values.firstWhere(
          (d) => d.name == query['density'],
          orElse: () => GalleryDensity.automatic,
        ),
      ),
    ),
  );
}

/// The densities the panel offers. Automatic is the look's own: compact where a pointer drives the app, standard on
/// touch.
enum GalleryDensity {
  /// The platform's: compact on a desktop, standard on a phone.
  automatic(null, 'Automatic'),

  /// Touch-sized everywhere.
  standard(NeumorphicDensity.standard, 'Standard'),

  /// Two steps in, everywhere.
  compact(NeumorphicDensity.compact, 'Compact');

  const GalleryDensity(this.density, this.label);

  /// What the theme takes; null leaves it to the platform.
  final NeumorphicDensity? density;

  /// The panel's name for it.
  final String label;
}

/// A pair of colours for `NeumorphicThemeData.from`: the pigment and the ground.
typedef GalleryColours = ({String name, Color pigment, Color ground});

/// The colour pairs the panel offers in place of a preset.
const List<GalleryColours> galleryColours = [
  (
    name: 'Clay and blue',
    pigment: Color(0xFF2459AD),
    ground: Color(0xFFE3D8CD),
  ),
  (
    name: 'Sage and berry',
    pigment: Color(0xFF8D315B),
    ground: Color(0xFFD9E0D7),
  ),
  (
    name: 'Slate and amber',
    pigment: Color(0xFFC27B16),
    ground: Color(0xFF252C38),
  ),
  (name: 'One grey', pigment: Color(0xFF888888), ground: Color(0xFF888888)),
];

/// What the Customize panel holds. Its defaults are the look's own, so an untouched panel draws the preset as designed.
@immutable
class GalleryCustom {
  /// The panel's settings.
  const GalleryCustom({
    this.highContrast = false,
    this.density = GalleryDensity.automatic,
    this.depth = 1,
    this.colours,
    this.rightToLeft = false,
    this.textScale = 1,
  });

  /// Lays every page out right to left, as Arabic and Hebrew read.
  final bool rightToLeft;

  /// The reader's text size, from 1 to 2.
  final double textScale;

  /// The fine outline on every part. Off leaves it to the platform's own setting.
  final bool highContrast;

  /// How compact the controls stand.
  final GalleryDensity density;

  /// Relief depth: as drawn, or lower.
  final double depth;

  /// Your own colours in place of the preset's; null keeps the preset.
  final GalleryColours? colours;

  /// [preset] in [brightness], or your own colours, with every setting applied.
  NeumorphicThemeData theme(String preset, Brightness brightness) {
    final pair = colours;
    final base = pair == null
        ? NeumorphicThemeData.preset(preset, brightness)
        : NeumorphicThemeData.from(
            pigment: pair.pigment,
            ground: pair.ground,
            brightness: brightness,
          );
    return base.copyWith(
      highContrast: highContrast ? true : null,
      density: density.density,
      elevation: depth == 1 ? null : NeumorphicElevation(depth: depth),
    );
  }

  /// This with the named settings changed; [colours] is set as given.
  GalleryCustom copyWith({
    bool? highContrast,
    GalleryDensity? density,
    double? depth,
    GalleryColours? Function()? colours,
    bool? rightToLeft,
    double? textScale,
  }) => GalleryCustom(
    highContrast: highContrast ?? this.highContrast,
    density: density ?? this.density,
    depth: depth ?? this.depth,
    colours: colours == null ? this.colours : colours(),
    rightToLeft: rightToLeft ?? this.rightToLeft,
    textScale: textScale ?? this.textScale,
  );
}

/// The gallery: its pages behind the look's navigation, with the Customize panel.
class GalleryApp extends StatefulWidget {
  /// The gallery, opening on [initialPage] in the default preset.
  const GalleryApp({
    super.key,
    this.initialPage = 'overview',
    this.initialBrightness = Brightness.light,
    this.initialCustom = const GalleryCustom(),
    this.initialCustomizing = false,
  });

  /// The page it opens on, an id from [liveGalleryPages] or one of the app's [hearthScreens]; an unknown id opens the
  /// Overview.
  final String initialPage;

  /// The appearance it opens in.
  final Brightness initialBrightness;

  /// The knobs it opens with.
  final GalleryCustom initialCustom;

  /// Whether it opens with the Customize panel showing.
  final bool initialCustomizing;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  late var _page =
      liveGalleryPages.any((p) => p.id == widget.initialPage) ||
          isHearthScreen(widget.initialPage)
      ? widget.initialPage
      : liveGalleryPages.first.id;
  var _preset = kitShownPreset;
  late var _brightness = widget.initialBrightness;
  late var _custom = widget.initialCustom;
  late var _customizing = widget.initialCustomizing;

  /// Opens [page], and on the web puts it in the address, so a page or an app screen can be linked.
  void _open(String page) {
    setState(() => _page = page);
    if (kIsWeb) {
      // The shared link form, keeping the address's own settings: /#/<page>?theme=dark&dir=rtl&text=200.
      final link = Uri.parse(
        Uri.base.fragment.isEmpty ? '/' : Uri.base.fragment,
      );
      SystemNavigator.routeInformationUpdated(
        uri: Uri(
          path: '/$page',
          queryParameters: link.queryParameters.isEmpty
              ? null
              : link.queryParameters,
        ),
        replace: true,
      );
    }
  }

  void _toggleCustomize() => setState(() => _customizing = !_customizing);

  void _toggleBrightness() => setState(
    () => _brightness = _brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
  );

  /// The phone's page list: the look's drawer, sliding in from the start edge over the scrim its sheets use.
  void _openDrawer(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // Every timing zero under Reduce Motion.
    final motion = NeumorphicMotion.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final active = liveGalleryPages.indexWhere((p) => p.id == _page);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: NeumorphicLocalizations.of(context).close,
      barrierColor: const Color(0x66000000),
      transitionDuration: motion.raise,
      transitionBuilder: (context, animation, _, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: motion.enter,
          reverseCurve: motion.exit,
        );
        return SlideTransition(
          position: Tween(
            begin: Offset(rtl ? 1 : -1, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        );
      },
      pageBuilder: (drawerContext, _, _) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: DefaultTextStyle(
          style: t.textTheme.body,
          child: IconTheme(
            data: IconThemeData(color: t.colors.ink, size: 22),
            child: NeumorphicNavigationDrawer(
              key: const Key('gallery-drawer'),
              width: math.min(320, MediaQuery.sizeOf(drawerContext).width - 56),
              label: 'Pages',
              header: const NeumorphicBrandRow('Neumorphism'),
              selectedIndex: active,
              items: [
                for (final page in liveGalleryPages)
                  NeumorphicNavItem(
                    label: page.title,
                    icon: page.icon,
                    key: Key('drawer-${page.id}'),
                  ),
              ],
              onDestinationSelected: (i) {
                Navigator.pop(drawerContext);
                _open(liveGalleryPages[i].id);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _customizePanel() => CustomizePanel(
    custom: _custom,
    onChanged: (custom) => setState(() => _custom = custom),
    preset: _preset,
    onPreset: (preset) => setState(() => _preset = preset),
    onClose: _toggleCustomize,
  );

  Widget _home(BuildContext context) {
    // The app is its own world, with its own navigation and one quiet way back.
    if (isHearthScreen(_page)) {
      return HearthApp(
        key: const ValueKey('hearth'),
        route: _page,
        onRoute: _open,
        onGallery: () => _open('overview'),
        brightness: _brightness,
        onBrightness: (b) => setState(() => _brightness = b),
        customizing: _customizing,
        onCustomize: _toggleCustomize,
        panel: _customizing ? _customizePanel() : null,
      );
    }
    final dark = _brightness == Brightness.dark;
    final active = liveGalleryPages.indexWhere((p) => p.id == _page);
    return NeumorphicChromeScope(
      brand: const NeumorphicBrand(name: 'Neumorphism'),
      nav: [
        for (final page in liveGalleryPages)
          NeumorphicNavItem(
            label: page.title,
            icon: page.icon,
            key: Key('nav-${page.id}'),
            onPressed: () => _open(page.id),
          ),
      ],
      active: active,
      child: NeumorphicScaffold(
        scroll: false,
        fullBleed: true,
        railAct: NeumorphicButton(
          _customizing ? 'Close Customize' : 'Customize',
          key: const Key('gallery-customize'),
          icon: NeumorphicGlyphs.slidersHorizontal,
          wide: true,
          onPressed: _toggleCustomize,
        ),
        railFoot: [
          _Labelled(
            'Appearance',
            NeumorphicSegmentedButton<Brightness>(
              key: const Key('gallery-appearance'),
              label: 'Appearance',
              value: _brightness,
              segments: const [
                NeumorphicButtonSegment(Brightness.light, 'Day'),
                NeumorphicButtonSegment(Brightness.dark, 'Night'),
              ],
              onChanged: (v) => setState(() => _brightness = v),
            ),
          ),
        ],
        lead: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) => NeumorphicRoundButton(
                NeumorphicGlyphs.menu,
                key: const Key('gallery-menu'),
                label: 'Pages',
                onPressed: () => _openDrawer(context),
              ),
            ),
            const SizedBox(width: 14),
            const Flexible(child: NeumorphicBrandRow('Neumorphism')),
          ],
        ),
        actions: [
          NeumorphicRoundButton(
            dark ? NeumorphicGlyphs.sun : NeumorphicGlyphs.moon,
            key: const Key('gallery-brightness'),
            label: dark ? 'Day' : 'Night',
            onPressed: _toggleBrightness,
          ),
          NeumorphicRoundButton(
            NeumorphicGlyphs.slidersHorizontal,
            key: const Key('gallery-customize-key'),
            label: _customizing ? 'Close Customize' : 'Customize',
            selected: _customizing,
            onPressed: _toggleCustomize,
          ),
        ],
        // Keyed by the page, not by the knobs: a corner that changes eases to its new shape in place.
        body: KeyedSubtree(
          key: ValueKey(_page),
          child: LiveExample(
            page: _page,
            onOpen: _open,
            header: _customizing ? _customizePanel() : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    kitShownPreset = _preset;
    // Every gallery page builds its theme through this: the panel's knobs reach each page as they change.
    final custom = _custom;
    kitShownTheme = (brightness) => custom.theme(_preset, brightness);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neumorphism',
      // The app's root, as an app's own is: the host sets the theme, the ground, the type and the icons; the animated
      // theme inside it eases each knob's change across the page.
      builder: (context, child) => Directionality(
        // The panel's reading direction and text size reach every page, as a device's would.
        textDirection: custom.rightToLeft
            ? TextDirection.rtl
            : Directionality.of(context),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: custom.textScale == 1
                ? MediaQuery.textScalerOf(context)
                : TextScaler.linear(custom.textScale),
          ),
          child: NeumorphicHost(
            light: custom.theme(_preset, Brightness.light),
            darkData: custom.theme(_preset, Brightness.dark),
            brightness: _brightness,
            child: AnimatedNeumorphicTheme(
              data: custom.theme(_preset, _brightness),
              child: child!,
            ),
          ),
        ),
      ),
      // The address names a page (/#/buttons): the gallery opens that page itself, so the navigator holds one route
      // whatever the address says.
      onGenerateInitialRoutes: (_) => [MaterialPageRoute<void>(builder: _home)],
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: _home),
    );
  }
}

/// The theme's knobs, each a control of the look's own at its natural width, on a grid that starts at the left.
class CustomizePanel extends StatelessWidget {
  /// A panel over [custom], reporting each change to [onChanged].
  const CustomizePanel({
    super.key,
    required this.custom,
    required this.onChanged,
    this.preset,
    this.onPreset,
    this.onClose,
  });

  /// What it shows.
  final GalleryCustom custom;

  /// Called with the panel's next settings.
  final ValueChanged<GalleryCustom> onChanged;

  /// The preset in force, when the panel offers the presets.
  final String? preset;

  /// Called with the chosen preset.
  final ValueChanged<String>? onPreset;

  /// Closes the panel.
  final VoidCallback? onClose;

  static String _name(String id) => id[0].toUpperCase() + id.substring(1);

  @override
  Widget build(BuildContext context) {
    final c = custom;
    return NeumorphicSlab(
      child: NeumorphicColumn(
        gap: 20,
        children: [
          NeumorphicSectionHeader(
            title: 'Customize',
            subtitle: 'Every page takes these as you set them.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicButton.text(
                  'Reset',
                  onPressed: () => onChanged(const GalleryCustom()),
                ),
                if (onClose != null) ...[
                  const SizedBox(width: 8),
                  NeumorphicButton.text('Done', onPressed: onClose),
                ],
              ],
            ),
          ),
          Wrap(
            key: const Key('customize-knobs'),
            spacing: 24,
            runSpacing: 22,
            children: [
              if (preset != null)
                _Knob(
                  null,
                  260,
                  NeumorphicSelect<String>(
                    label: 'Preset',
                    value: preset,
                    options: [
                      for (final id in NeumorphicThemeData.presets)
                        NeumorphicMenuItem(id, _name(id)),
                    ],
                    onChanged: c.colours == null ? onPreset : null,
                    helper: c.colours == null
                        ? null
                        : 'Your own colours stand in for it.',
                  ),
                ),
              _Knob(
                null,
                260,
                NeumorphicSelect<String>(
                  label: 'Your own colours',
                  value: c.colours?.name ?? '',
                  options: [
                    const NeumorphicMenuItem('', "The preset's"),
                    for (final pair in galleryColours)
                      NeumorphicMenuItem(pair.name, pair.name),
                  ],
                  onChanged: (v) => onChanged(
                    c.copyWith(
                      colours: () =>
                          galleryColours.where((p) => p.name == v).firstOrNull,
                    ),
                  ),
                ),
              ),
              _Knob(
                'Density',
                380,
                NeumorphicSegmentedButton<GalleryDensity>(
                  label: 'Density',
                  value: c.density,
                  segments: [
                    for (final d in GalleryDensity.values)
                      NeumorphicButtonSegment(d, d.label),
                  ],
                  onChanged: (v) => onChanged(c.copyWith(density: v)),
                ),
                note: c.density == GalleryDensity.automatic
                    ? 'Compact with a pointer, standard on touch.'
                    : null,
              ),
              _Knob(
                'Relief',
                240,
                NeumorphicSegmentedButton<double>(
                  label: 'Relief',
                  value: c.depth,
                  segments: const [
                    NeumorphicButtonSegment(.5, 'Low'),
                    NeumorphicButtonSegment(1.0, 'As drawn'),
                  ],
                  onChanged: (v) => onChanged(c.copyWith(depth: v)),
                ),
              ),
              _Knob(
                null,
                340,
                NeumorphicSwitchRow(
                  label: 'High contrast',
                  note: 'A fine outline on every part. Off follows the device.',
                  value: c.highContrast,
                  onChanged: (v) => onChanged(c.copyWith(highContrast: v)),
                ),
              ),
              _Knob(
                null,
                340,
                NeumorphicSwitchRow(
                  label: 'Right to left',
                  note: 'Every page laid out as Arabic and Hebrew read.',
                  value: c.rightToLeft,
                  onChanged: (v) => onChanged(c.copyWith(rightToLeft: v)),
                ),
              ),
              _Knob(
                'Text size',
                240,
                NeumorphicSegmentedButton<double>(
                  label: 'Text size',
                  value: c.textScale,
                  segments: const [
                    NeumorphicButtonSegment(1.0, 'As set'),
                    NeumorphicButtonSegment(1.5, 'Large'),
                    NeumorphicButtonSegment(2.0, 'Largest'),
                  ],
                  onChanged: (v) => onChanged(c.copyWith(textScale: v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One knob of the panel at its own width (never wider than the panel), its name above it.
class _Knob extends StatelessWidget {
  const _Knob(this.label, this.width, this.child, {this.note});

  /// The name drawn above it, when the control draws none of its own.
  final String? label;
  final double width;
  final Widget child;
  final String? note;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SizedBox(
      width: math.min(width, box.maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            ExcludeSemantics(child: _KnobName(label!)),
            const SizedBox(height: 8),
          ],
          child,
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(note!, style: NeumorphicTheme.of(context).textTheme.caption),
          ],
        ],
      ),
    ),
  );
}

/// A control's name drawn above it: a segmented button names itself only to a screen reader.
class _Labelled extends StatelessWidget {
  const _Labelled(this.text, this.child);

  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExcludeSemantics(child: _KnobName(text)),
      const SizedBox(height: 8),
      child,
    ],
  );
}

/// A knob's name in the words a field's label takes (a select's, a text field's), so every name on the panel matches.
class _KnobName extends StatelessWidget {
  const _KnobName(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: NeumorphicTheme.of(context).textTheme.caption
        .copyWith(fontWeight: FontWeight.w700),
  );
}
