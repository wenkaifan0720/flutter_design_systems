/// The preview frame every system's preview stands in: the device a
/// [PreviewPlatform] previews on, the platform override scoped
/// inside the frame, the brightness asked for, and the stage a pushed or
/// sheet page is raised over when previewed alone.
///
/// A system's `GenChrome.preview` wraps everything it builds in a
/// [PreviewFrame]; its host reads [PreviewFrame.targetPlatformOf] for the
/// platform whose behaviour applies (a Material host passes it to
/// `ThemeData.platform`, whose scroll behaviour and gestures follow it). The
/// override is scoped: nothing outside the frame changes, unlike the global
/// `debugDefaultTargetPlatformOverride`.
library;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';

import 'chrome_data.dart';

/// The device a platform previews on: its logical size and pixel density.
/// The oracle captures and the gallery's renders use the same numbers.
@immutable
class PreviewDevice {
  /// Creates a [PreviewDevice].
  const PreviewDevice({required this.size, required this.devicePixelRatio});

  /// The Android reference phone: 1080 × 2400 px at 420 dpi (DPR 2.625),
  /// i.e. 411.43 × 914.29 dp — the oracle's `material_oracle` AVD.
  static const PreviewDevice android = PreviewDevice(
    size: Size(1080 / 2.625, 2400 / 2.625),
    devicePixelRatio: 2.625,
  );

  /// The iPhone reference phone: 390 × 844 pt at @3x.
  static const PreviewDevice ios = PreviewDevice(
    size: Size(390, 844),
    devicePixelRatio: 3,
  );

  /// The device [platform] previews on.
  static PreviewDevice of(PreviewPlatform platform) => switch (platform) {
    PreviewPlatform.android => android,
    PreviewPlatform.ios => ios,
  };

  /// The logical size, in dp / pt.
  final Size size;

  /// Physical pixels per logical pixel.
  final double devicePixelRatio;

  /// The size in physical pixels.
  Size get physicalSize => size * devicePixelRatio;
}

/// What a [PreviewFrame] publishes to everything inside it.
@immutable
class PreviewFrameData {
  /// Creates a [PreviewFrameData].
  const PreviewFrameData({required this.platform, required this.brightness});

  /// The platform the frame is drawn for.
  final PreviewPlatform platform;

  /// The brightness the frame was asked for.
  final Brightness brightness;

  @override
  bool operator ==(Object other) =>
      other is PreviewFrameData &&
      other.platform == platform &&
      other.brightness == brightness;

  @override
  int get hashCode => Object.hash(platform, brightness);
}

/// The frame a preview stands in: publishes its [platform] and
/// [brightness] to everything inside it, scopes the platform override
/// there, and publishes its box as the screen.
///
/// - The platform: [targetPlatformOf] reads it inside the frame, and the
///   frame's scroll behaviour follows it. (An app built inside the frame
///   installs its own scroll behaviour; a Material one follows
///   `ThemeData.platform`, which the host sets from [targetPlatformOf].)
/// - The brightness: `MediaQuery.platformBrightness` reads it, so a host or
///   an app that follows the platform's brightness follows the frame.
/// - The box: with [device] false the frame's box is the phone — its size
///   is published as `MediaQuery.size`, and a box smaller than the view (a
///   phone framed on a page) stands without the view's safe-area insets.
///   With [device] true the child is laid out at the platform's
///   [PreviewDevice] size, without insets, and scaled to fit the box.
///
/// Placed outside any app the preview builds, so the app reads the frame's
/// media query.
///
/// ```dart
/// PreviewFrame(platform: PreviewPlatform.ios, brightness: Brightness.dark, child: const Text('App'))
/// ```
class PreviewFrame extends StatelessWidget {
  /// Creates a [PreviewFrame].
  const PreviewFrame({
    required this.child,
    this.platform = PreviewPlatform.android,
    this.brightness = Brightness.light,
    this.device = false,
    super.key,
  });

  /// What stands in the frame: usually the preview's own app.
  final Widget child;

  /// The platform the frame is drawn for.
  final PreviewPlatform platform;

  /// The brightness published as the platform's.
  final Brightness brightness;

  /// Whether the child is laid out at the platform's device size and scaled
  /// to fit, rather than filling the frame's box.
  final bool device;

  /// The nearest frame's data, or null outside any preview frame.
  static PreviewFrameData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PreviewScope>()?.data;

  /// The platform whose behaviour applies at [context]: the preview
  /// frame's platform inside one, else the device's own platform. A host
  /// reads this instead of pinning a platform.
  static TargetPlatform targetPlatformOf(BuildContext context) =>
      maybeOf(context)?.platform.targetPlatform ?? defaultTargetPlatform;

  @override
  Widget build(BuildContext context) {
    final scoped = _PreviewScope(
      data: PreviewFrameData(platform: platform, brightness: brightness),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(platform: platform.targetPlatform),
        child: child,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final mq =
            MediaQuery.maybeOf(context) ??
            MediaQueryData.fromView(View.of(context));
        if (device) {
          final size = PreviewDevice.of(platform).size;
          return FittedBox(
            child: SizedBox.fromSize(
              size: size,
              child: MediaQuery(
                data: mq.copyWith(
                  size: size,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                  platformBrightness: brightness,
                ),
                child: scoped,
              ),
            ),
          );
        }
        final box = constraints.biggest;
        final whole =
            box.width >= mq.size.width && box.height >= mq.size.height;
        return MediaQuery(
          data: mq.copyWith(
            size: box.isFinite ? box : mq.size,
            padding: whole ? mq.padding : EdgeInsets.zero,
            viewPadding: whole ? mq.viewPadding : EdgeInsets.zero,
            platformBrightness: brightness,
          ),
          child: scoped,
        );
      },
    );
  }
}

class _PreviewScope extends InheritedWidget {
  const _PreviewScope({required this.data, required super.child});

  final PreviewFrameData data;

  @override
  bool updateShouldNotify(_PreviewScope oldWidget) => data != oldWidget.data;
}

/// A stage that raises a previewed page on a route over itself once it is
/// on screen, and keeps it raised: how a pushed or sheet page is previewed
/// alone, so its exit renders as it does live and the chrome it derives is
/// the real one ([RoutePresentation.pushed] or the sheet's).
///
/// A preview is looked at, not walked out of. The raised page refuses every
/// pop that asks — its exit, a barrier tap, the system back — so they
/// leave it standing; a pop that takes it anyway (a drag past a sheet's
/// last detent, a direct `Navigator.pop`) raises it again rather than
/// leaving the stage bare. Routes raised over the page (a dialog, a menu)
/// still close. The raised page shows the stage's CURRENT [child]: when the
/// stage is rebuilt with a new one (a hot reload of the preview), the page
/// already standing takes it on the next frame.
///
/// Mount it as the home of the preview's navigator.
///
/// ```dart
/// PreviewStage(route: (context, page) => PageRouteBuilder<void>(pageBuilder: (context, animation, secondary) => page), child: const Text('Details'))
/// ```
class PreviewStage extends StatefulWidget {
  /// Creates a [PreviewStage].
  const PreviewStage({
    required this.route,
    required this.child,
    this.under,
    super.key,
  });

  /// Builds the route [child] is raised on — the system's push or sheet
  /// route around `page`.
  final Route<void> Function(BuildContext context, Widget page) route;

  /// The previewed page.
  final Widget child;

  /// What the page is raised over — the page beneath it in the app, e.g.
  /// the root a sheet rises from; null stands it over a blank stage.
  final Widget? under;

  @override
  State<PreviewStage> createState() => _PreviewStageState();
}

class _PreviewStageState extends State<PreviewStage> {
  late final ValueNotifier<Widget> _page = ValueNotifier<Widget>(widget.child);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _raise());
  }

  @override
  void didUpdateWidget(PreviewStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The raised page lives in another route, outside this build: hand it
    // the new child once this frame is done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _page.value = widget.child;
    });
  }

  void _raise() {
    if (!mounted) return;
    final page = PopScope<void>(
      canPop: false,
      child: ValueListenableBuilder<Widget>(
        valueListenable: _page,
        builder: (context, page, _) => page,
      ),
    );
    Navigator.of(context).push(widget.route(context, page)).then((_) {
      _raise();
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.under ?? const SizedBox.expand();
}

/// The platform's device, as data on the enum.
extension PreviewPlatformDevice on PreviewPlatform {
  /// The device this platform previews on.
  PreviewDevice get device => PreviewDevice.of(this);
}
