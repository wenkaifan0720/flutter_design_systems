/// The preview: one page's isolated preview — the host and the ground a
/// page gets live, without a router — in the Android or the iOS register
/// (CONTRACT §4.2 `ExpressivePreview(…, platform:)`; §5; SPEC
/// `GenChrome.preview`). Chrome, no vocabulary role. Owner: w2-preview.
///
/// - The device: the design kit's [PreviewFrame] publishes the register,
///   its brightness and the screen; with `device` the page is laid out at
///   the register's [PreviewDevice] (Android 411.43 × 914.29 dp at 2.625,
///   iOS 390 × 844 pt at 3) and scaled to fit.
/// - The system bars: drawn for the register in Material's look — on
///   Android the edge-to-edge status bar and the gesture (or three-button)
///   navigation bar, on iOS the status bar and the home indicator — and
///   published as the screen's safe-area insets, so the page reserves them
///   exactly as it does live. Their glyphs follow the top-most
///   [SystemUiOverlayStyle] the page annotates under each band, as the
///   real bars do (a cover over a dark photo asks for light glyphs), and
///   otherwise the theme's content colour.
/// - The presentation: a page previewed alone stands in the register its
///   live route would — a root, a page pushed over another (the kit's
///   [PreviewStage] raises it on an [ExpressivePage] route) or a sheet
///   ([ExpressiveSheetPage]) — and a preview refuses its own pop.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/host.dart';

import '../icons.dart';
import '../spacing.dart';
import '../theme.dart';
import 'host.dart';
import 'page.dart';
import 'sheet_page.dart';

export 'package:ui_core/host.dart' show PreviewPlatform, RoutePresentation;
export 'package:ui_core/host.dart' show PreviewDevice, PreviewPlatformDevice;

/// How the Android register's navigation bar is drawn: Android's two
/// system navigation modes.
enum ExpressiveNavigationMode {
  /// Gesture navigation: the thin bar with the home handle.
  gesture,

  /// Three-button navigation: back, home and recents.
  threeButton,
}

/// One page previewed alone, in the [platform]'s register (Android, the
/// lab's default, or iOS) and the [brightness] asked for.
///
/// Everything it builds, its own app included, stands in the design kit's
/// preview frame, so the page behaves in the frame's register and reads its
/// brightness. The register's system bars are drawn over the page and
/// published as its safe-area insets (turn them off with [systemBars]).
/// The page stands in [presentation]'s register: a root, a page pushed over
/// [under] or a sheet raised over it, whose own exit (the derived back, a
/// barrier tap, the system back) leaves it standing.
///
/// Rebuilt with a new [child] (a hot reload, a new render of the page), it
/// keeps the page's state and focus.
///
/// ```dart
/// ExpressivePreview(platform: PreviewPlatform.ios, presentation: RoutePresentation.pushed, child: const TripPage())
/// ```
class ExpressivePreview extends StatefulWidget {
  /// A preview of [child] in the given [platform] and [brightness].
  const ExpressivePreview({
    required this.child,
    this.platform = PreviewPlatform.android,
    this.brightness = Brightness.light,
    this.light,
    this.dark,
    this.presentation = RoutePresentation.root,
    this.drawer = false,
    this.under,
    this.device = false,
    this.systemBars = true,
    this.navigationMode = ExpressiveNavigationMode.gesture,
    this.clock,
    super.key,
  });

  /// The previewed page.
  final Widget child;

  /// The platform register: its behaviour, device and system bars apply
  /// inside the preview.
  final PreviewPlatform platform;

  /// The brightness the page is previewed in.
  final Brightness brightness;

  /// The light theme; null wears the default preset's.
  final ExpressiveThemeData? light;

  /// The dark theme; null wears the default preset's.
  final ExpressiveThemeData? dark;

  /// The register the page stands in: [RoutePresentation.root] (the default),
  /// [RoutePresentation.pushed] (raised on an [ExpressivePage] route) or
  /// [RoutePresentation.sheet] (raised on an [ExpressiveSheetPage] route).
  final RoutePresentation presentation;

  /// With [RoutePresentation.sheet], whether the sheet is the full-screen
  /// cover rather than the modal bottom sheet.
  final bool drawer;

  /// What a pushed or sheet page is raised over — the page beneath it in
  /// the app; null raises it over the bare ground.
  final Widget? under;

  /// Whether the page is laid out at the register's [PreviewDevice] and
  /// scaled to fit the preview's box, rather than filling the box.
  final bool device;

  /// Whether the register's system bars are drawn and reserved.
  final bool systemBars;

  /// How the Android register's navigation bar is drawn; iOS always draws
  /// the home indicator.
  final ExpressiveNavigationMode navigationMode;

  /// The time the status bar shows, on a twelve-hour face without AM or PM
  /// as both platforms' bars show it; 12:30 when null. A page previewed on
  /// an injected clock passes that clock, so the bar and the page agree.
  final DateTime? clock;

  /// The safe-area insets the [platform]'s system bars take, the Android
  /// navigation bar drawn in [mode]: what a previewed page reads as
  /// `MediaQuery.padding`.
  static EdgeInsets systemInsetsOf(
    PreviewPlatform platform, {
    ExpressiveNavigationMode mode = ExpressiveNavigationMode.gesture,
  }) => switch (platform) {
    PreviewPlatform.android => EdgeInsets.only(
      top: _SystemBarMetrics.androidStatusBar,
      bottom: mode == ExpressiveNavigationMode.gesture
          ? _SystemBarMetrics.androidGestureBar
          : _SystemBarMetrics.androidThreeButtonBar,
    ),
    PreviewPlatform.ios => const EdgeInsets.only(
      top: _SystemBarMetrics.iosStatusBar,
      bottom: _SystemBarMetrics.iosHomeIndicatorInset,
    ),
  };

  @override
  State<ExpressivePreview> createState() => _ExpressivePreviewState();
}

class _ExpressivePreviewState extends State<ExpressivePreview> {
  /// The root page as last handed in: the app's home route lives in its
  /// own overlay entry, outside this build, so a new child reaches it
  /// through here rather than through the app's `home`.
  late final ValueNotifier<Widget> _page = ValueNotifier<Widget>(widget.child);

  @override
  void didUpdateWidget(ExpressivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.child, widget.child)) _page.value = widget.child;
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Route<void> _route(BuildContext context, Widget page) {
    const key = ValueKey<String>('expressive-preview');
    return switch (widget.presentation) {
      RoutePresentation.sheet => ExpressiveSheetPage<void>(
        key: key,
        drawer: widget.drawer,
        child: page,
      ).createRoute(context),
      _ => ExpressivePage<void>(key: key, child: page).createRoute(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.presentation == RoutePresentation.root
        ? ValueListenableBuilder<Widget>(
            valueListenable: _page,
            builder: (context, page, _) => page,
          )
        : PreviewStage(route: _route, under: widget.under, child: widget.child);
    final insets = widget.systemBars
        ? ExpressivePreview.systemInsetsOf(
            widget.platform,
            mode: widget.navigationMode,
          )
        : null;
    // The preview reads in the direction of the page it stands in: its own
    // app's English localizations would otherwise turn it left to right.
    final direction = Directionality.maybeOf(context);
    final app = MaterialApp(
      // A new presentation is a new stack: raise it afresh.
      key: ValueKey<Object>((widget.presentation, widget.drawer)),
      debugShowCheckedModeBanner: false,
      builder: (context, app) {
        final host = ExpressiveHost(
          light: widget.light,
          dark: widget.dark,
          brightness: widget.brightness,
          child: insets == null
              ? app ?? const SizedBox.shrink()
              : _AnnotatedBars(
                  platform: widget.platform,
                  mode: widget.navigationMode,
                  insets: insets,
                  clock: widget.clock,
                  child: app ?? const SizedBox.shrink(),
                ),
        );
        return direction == null
            ? host
            : Directionality(textDirection: direction, child: host);
      },
      home: home,
    );
    // The preview is a screen of its own to assistive technology: a modal
    // raised in it (a sheet's barrier) blocks the page under it in the
    // preview, never the page the preview stands in.
    return Semantics(
      container: true,
      child: PreviewFrame(
        platform: widget.platform,
        brightness: widget.brightness,
        device: widget.device,
        child: insets == null
            ? app
            : Builder(
                // The frame's screen, with the drawn bars as its safe area:
                // the page reserves them as it reserves the real ones.
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(padding: insets, viewPadding: insets),
                  child: app,
                ),
              ),
      ),
    );
  }
}

/// The system bars' geometry, per register. The bars are the platform's,
/// not Material components, so no Compose token names them: each value is
/// the platform's own, spelled in spacing steps (the literal lint's rule
/// for a length; T's README "The literal lint").
abstract final class _SystemBarMetrics {
  /// Android's status bar: AOSP `status_bar_height`, 24dp.
  static const double androidStatusBar = ExpressiveSpacing.s24;

  /// Android's gesture navigation bar: the gestural navigation overlay's
  /// `navigation_bar_height`, 24dp.
  static const double androidGestureBar = ExpressiveSpacing.s24;

  /// Android's three-button navigation bar: AOSP `navigation_bar_height`,
  /// 48dp.
  static const double androidThreeButtonBar = ExpressiveSpacing.s48;

  /// The gesture bar's home handle: SystemUI `navigation_home_handle_width`,
  /// 108dp.
  static const double androidHandleWidth =
      ExpressiveSpacing.s72 + ExpressiveSpacing.s36;

  /// The home handle's thickness: twice SystemUI's
  /// `navigation_handle_radius` (2dp), 4dp.
  static const double androidHandleHeight = ExpressiveSpacing.s4;

  /// A status-bar glyph (Android's 16dp status icons).
  static const double statusIcon = ExpressiveSpacing.s16;

  /// The gap between two status-bar glyphs.
  static const double statusGap = ExpressiveSpacing.s4;

  /// A three-button navigation glyph (Android's 20dp key glyphs).
  static const double navigationKey = ExpressiveSpacing.s20;

  /// The Android status bar's content inset from the screen's edges.
  static const double androidStatusInset = ExpressiveSpacing.s16;

  /// The iPhone reference phone's (390 × 844 pt) top safe area: 47pt.
  static const double iosStatusBar =
      ExpressiveSpacing.s40 + ExpressiveSpacing.s6 + 1;

  /// Its bottom safe area, the home indicator's: 34pt.
  static const double iosHomeIndicatorInset =
      ExpressiveSpacing.s32 + ExpressiveSpacing.s2;

  /// The home indicator's width: 134pt.
  static const double iosIndicatorWidth =
      ExpressiveSpacing.s72 + ExpressiveSpacing.s56 + ExpressiveSpacing.s6;

  /// The home indicator's thickness: 5pt.
  static const double iosIndicatorHeight = ExpressiveSpacing.s4 + 1;

  /// The home indicator's gap to the screen's bottom edge: 8pt.
  static const double iosIndicatorBottom = ExpressiveSpacing.s8;

  /// The iOS status bar's content inset from the screen's edges, clear of
  /// the display's corners.
  static const double iosStatusInset = ExpressiveSpacing.s32;

  /// The Dynamic Island's width between the status bar's two ears: 126pt.
  static const double iosIslandWidth =
      ExpressiveSpacing.s72 + ExpressiveSpacing.s48 + ExpressiveSpacing.s6;

  /// The cellular glyph: four bars in 17 × 11pt.
  static const Size iosSignalSize = Size(
    ExpressiveSpacing.s16 + 1,
    ExpressiveSpacing.s10 + 1,
  );

  /// The battery glyph, its terminal included: 27 × 12pt.
  static const Size iosBatterySize = Size(
    ExpressiveSpacing.s24 + ExpressiveSpacing.s2 + 1,
    ExpressiveSpacing.s12,
  );

  /// The battery body's corner: 4pt.
  static const double iosBatteryCorner = ExpressiveSpacing.s4;

  /// The gap between the battery's outline and its charge: 2pt.
  static const double iosBatteryInset = ExpressiveSpacing.s2;

  /// The battery terminal's height: 4pt.
  static const double iosBatteryTerminal = ExpressiveSpacing.s4;

  /// A cellular bar's width, and the gap between two: 3pt and 1pt.
  static const double iosSignalBar = ExpressiveSpacing.s2 + 1;
}

/// iOS's cellular glyph: four rising bars, full strength.
class _IosSignal extends CustomPainter {
  const _IosSignal(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const bars = 4;
    final step = (size.width + 1) / bars;
    for (var i = 0; i < bars; i++) {
      final height = size.height * (i + 1) / bars;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * step,
            size.height - height,
            _SystemBarMetrics.iosSignalBar,
            height,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_IosSignal old) => old.color != color;
}

/// iOS's battery glyph: a faint rounded outline, a full charge inside it,
/// and the terminal on its end.
class _IosBattery extends CustomPainter {
  const _IosBattery(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTWH(0, 0, size.width - 1 - 1, size.height);
    const corner = Radius.circular(_SystemBarMetrics.iosBatteryCorner);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(body.deflate(0.5), corner),
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          body.deflate(_SystemBarMetrics.iosBatteryInset),
          const Radius.circular(_SystemBarMetrics.iosBatteryInset),
        ),
        Paint()..color = color,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width - 1,
            (size.height - _SystemBarMetrics.iosBatteryTerminal) / 2,
            1,
            _SystemBarMetrics.iosBatteryTerminal,
          ),
          const Radius.circular(0.5),
        ),
        Paint()..color = color.withValues(alpha: 0.4),
      );
  }

  @override
  bool shouldRepaint(_IosBattery old) => old.color != color;
}

/// The overlay styles the page annotates under the two bands: the
/// top-most [SystemUiOverlayStyle] at each band's centre, as [RenderView]
/// finds them for the real bars; null where the page annotates none.
typedef _BandStyles = ({
  SystemUiOverlayStyle? status,
  SystemUiOverlayStyle? navigation,
  Color? statusInk,
  Color? navigationInk,
});

/// The page with the register's bars drawn over it, their glyphs resolved
/// from the page's own overlay-style annotations.
///
/// The page stands in a repaint boundary whose layer is searched at the
/// end of every frame the app draws, as [RenderView] searches its own for
/// the real bars: two point probes down the layer tree, never a frame of
/// their own (an idle preview does nothing) and a rebuild of the bars only
/// when what stands under a band changed.
class _AnnotatedBars extends StatefulWidget {
  const _AnnotatedBars({
    required this.platform,
    required this.mode,
    required this.insets,
    required this.clock,
    required this.child,
  });

  final PreviewPlatform platform;
  final ExpressiveNavigationMode mode;
  final EdgeInsets insets;
  final DateTime? clock;
  final Widget child;

  @override
  State<_AnnotatedBars> createState() => _AnnotatedBarsState();
}

class _AnnotatedBarsState extends State<_AnnotatedBars> {
  final GlobalKey _probe = GlobalKey();
  final ValueNotifier<_BandStyles> _styles = ValueNotifier<_BandStyles>((
    status: null,
    navigation: null,
    statusInk: null,
    navigationInk: null,
  ));

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(_resolve);
  }

  @override
  void dispose() {
    _styles.dispose();
    super.dispose();
  }

  /// After a drawn frame: the bands' styles, then again after the next
  /// frame drawn (registering schedules none).
  void _resolve(Duration _) {
    if (!mounted) return;
    final probe = _probe.currentContext?.findRenderObject();
    if (probe is _RenderOverlayProbe) {
      final next = probe.resolve(widget.insets);
      if (next != _styles.value) _styles.value = next;
    }
    SchedulerBinding.instance.addPostFrameCallback(
      _resolve,
      debugLabel: 'ExpressivePreview.systemBars',
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      _OverlayProbe(key: _probe, child: widget.child),
      ValueListenableBuilder<_BandStyles>(
        valueListenable: _styles,
        builder: (context, styles, _) => _SystemBars(
          platform: widget.platform,
          mode: widget.mode,
          insets: widget.insets,
          clock: widget.clock,
          styles: styles,
        ),
      ),
    ],
  );
}

/// The page's repaint boundary: its layer holds everything the page
/// annotates, searched for the bands' overlay styles.
class _OverlayProbe extends SingleChildRenderObjectWidget {
  const _OverlayProbe({required super.child, super.key});

  @override
  _RenderOverlayProbe createRenderObject(BuildContext context) =>
      _RenderOverlayProbe();
}

class _RenderOverlayProbe extends RenderProxyBox {
  @override
  bool get isRepaintBoundary => true;

  /// The top-most overlay style at the centre of each band, as
  /// [RenderView] probes the status and navigation bars' centres.
  _BandStyles resolve(EdgeInsets insets) {
    final layer = this.layer;
    if (!attached || !hasSize || layer is! OffsetLayer) {
      return (
        status: null,
        navigation: null,
        statusInk: null,
        navigationInk: null,
      );
    }
    // The boundary's layer holds its offset in its parent: probe in its
    // own coordinates.
    final origin = layer.offset;
    final x = size.width / 2;
    final top = origin + Offset(x, insets.top / 2);
    final bottom = origin + Offset(x, size.height - 1 - insets.bottom / 2);
    return (
      status: layer.find<SystemUiOverlayStyle>(top),
      navigation: layer.find<SystemUiOverlayStyle>(bottom),
      statusInk: layer.find<ExpressiveSystemBarColor>(top)?.color,
      navigationInk: layer.find<ExpressiveSystemBarColor>(bottom)?.color,
    );
  }
}

/// The register's system bars over the page: transparent (edge to edge),
/// never hit and never announced. Their glyphs are light or dark as the
/// page's overlay style under each band asks — on Android its
/// `statusBarIconBrightness` and `systemNavigationBarIconBrightness`
/// (light icons for [Brightness.light]); on iOS its `statusBarBrightness`
/// (light glyphs over [Brightness.dark] content), which the home indicator,
/// adapting to what is under it, also follows — and one style under only
/// one band speaks for both, as [RenderView] applies it. Where the page
/// annotates nothing they wear the theme's content colour.
class _SystemBars extends StatelessWidget {
  const _SystemBars({
    required this.platform,
    required this.mode,
    required this.insets,
    required this.clock,
    required this.styles,
  });

  final PreviewPlatform platform;
  final ExpressiveNavigationMode mode;
  final EdgeInsets insets;
  final DateTime? clock;
  final _BandStyles styles;

  /// [clock] as the bar shows it: `7:31`, `12:04`.
  String get _time {
    final at = clock;
    if (at == null) return '12:30';
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '$hour:${at.minute.toString().padLeft(2, '0')}';
  }

  /// Whether the glyphs [style] asks for are light; null when it does not
  /// say.
  static bool? _lightGlyphs(
    SystemUiOverlayStyle? style,
    PreviewPlatform platform, {
    required bool navigation,
  }) {
    if (style == null) return null;
    return switch (platform) {
      PreviewPlatform.ios => switch (style.statusBarBrightness) {
        null => null,
        final b => b == Brightness.dark,
      },
      PreviewPlatform.android => switch (navigation
          ? style.systemNavigationBarIconBrightness
          : style.statusBarIconBrightness) {
        null => null,
        final b => b == Brightness.light,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    // Light and dark glyphs from the theme's own grounds and inks, as the
    // real bars draw near-white or near-black: the lightest and the
    // darkest of them.
    final candidates = <Color>[
      c.onSurface,
      c.inverseOnSurface,
      c.surface,
      c.surfaceContainerLowest,
    ]..sort((a, b) => a.computeLuminance().compareTo(b.computeLuminance()));
    final lightInk = candidates.last;
    final darkInk = candidates.first;
    // Where the page asks for nothing, the ink of the theme scope under
    // the band (a page in a show's scheme), else the preview theme's.
    Color inkFor(bool? light, Color? scope) => switch (light) {
      null => scope ?? c.onSurface,
      true => lightInk,
      false => darkInk,
    };
    // iOS reads the status band alone for its status bar (RenderView).
    final statusStyle = platform == PreviewPlatform.ios
        ? styles.status
        : styles.status ?? styles.navigation;
    final navigationStyle = styles.navigation ?? styles.status;
    final ink = inkFor(
      _lightGlyphs(statusStyle, platform, navigation: false),
      styles.statusInk,
    );
    final navigationInk = inkFor(
      _lightGlyphs(navigationStyle, platform, navigation: true),
      // The home indicator follows the status band on iOS, as its glyphs
      // do.
      platform == PreviewPlatform.ios
          ? styles.navigationInk ?? styles.statusInk
          : styles.navigationInk,
    );
    final ios = platform == PreviewPlatform.ios;
    final statusInset = ios
        ? _SystemBarMetrics.iosStatusInset
        : _SystemBarMetrics.androidStatusInset;
    // The status bar's words do not follow the page's text scale: a real
    // one stays within its band.
    final Widget status;
    if (ios) {
      // iOS: the time centred in the left ear, beside the Dynamic Island,
      // and the cellular, Wi-Fi and battery glyphs centred in the right.
      status = MediaQuery.withNoTextScaling(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: statusInset),
          child: IconTheme(
            data: IconThemeData(color: ink, size: _SystemBarMetrics.statusIcon),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: Text(
                      _time,
                      style: t.type.titleMedium.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: _SystemBarMetrics.iosIslandWidth),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        CustomPaint(
                          size: _SystemBarMetrics.iosSignalSize,
                          painter: _IosSignal(ink),
                        ),
                        const SizedBox(width: _SystemBarMetrics.statusGap),
                        const ExpressiveIcon(
                          ExpressiveSymbols.wifi,
                          selected: true,
                        ),
                        const SizedBox(width: _SystemBarMetrics.statusGap),
                        CustomPaint(
                          size: _SystemBarMetrics.iosBatterySize,
                          painter: _IosBattery(ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      status = MediaQuery.withNoTextScaling(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: statusInset),
          child: IconTheme(
            data: IconThemeData(color: ink, size: _SystemBarMetrics.statusIcon),
            child: Row(
              children: <Widget>[
                Text(
                  _time,
                  style: t.type.labelLarge.copyWith(color: ink),
                  maxLines: 1,
                ),
                const Spacer(),
                const ExpressiveIcon(ExpressiveSymbols.wifi, selected: true),
                const SizedBox(width: _SystemBarMetrics.statusGap),
                const ExpressiveIcon(
                  ExpressiveSymbols.batteryFull,
                  selected: true,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final Widget navigation;
    if (ios) {
      navigation = Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: _SystemBarMetrics.iosIndicatorBottom,
          ),
          child: _Pill(
            key: const ValueKey<String>('expressive-preview:home-indicator'),
            width: _SystemBarMetrics.iosIndicatorWidth,
            height: _SystemBarMetrics.iosIndicatorHeight,
            color: navigationInk,
          ),
        ),
      );
    } else if (mode == ExpressiveNavigationMode.gesture) {
      navigation = Center(
        child: _Pill(
          key: const ValueKey<String>('expressive-preview:gesture-handle'),
          width: _SystemBarMetrics.androidHandleWidth,
          height: _SystemBarMetrics.androidHandleHeight,
          color: navigationInk,
        ),
      );
    } else {
      navigation = IconTheme(
        key: const ValueKey<String>('expressive-preview:three-button'),
        data: IconThemeData(
          color: navigationInk,
          size: _SystemBarMetrics.navigationKey,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // Back: the triangle, pointing to the start.
            RotatedBox(
              quarterTurns: 3,
              child: ExpressiveIcon(ExpressiveSymbols.changeHistory),
            ),
            ExpressiveIcon(ExpressiveSymbols.circle),
            ExpressiveIcon(ExpressiveSymbols.square),
          ],
        ),
      );
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Column(
          children: <Widget>[
            SizedBox(
              key: const ValueKey<String>('expressive-preview:status-bar'),
              height: insets.top,
              child: status,
            ),
            const Spacer(),
            SizedBox(
              key: const ValueKey<String>('expressive-preview:navigation-bar'),
              height: insets.bottom,
              child: navigation,
            ),
          ],
        ),
      ),
    );
  }
}

/// A fully rounded bar: the home handle and the home indicator.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.width,
    required this.height,
    required this.color,
    super.key,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
    ),
  );
}
