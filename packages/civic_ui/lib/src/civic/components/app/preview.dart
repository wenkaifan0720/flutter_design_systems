import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../../theme.dart';
import 'frame.dart';
import 'host.dart';
import 'routes.dart';

/// How a previewed page stands in its app: as one of its places, pushed
/// over one, or raised over the whole app.
enum CivicPresentation {
  /// One of the app's places, in its frame.
  root,

  /// A page pushed over a place: its top bar goes back.
  pushed,

  /// A task raised over the app: its top bar closes it.
  sheet,
}

/// One page as the app stands it, without its router: the same host, frame
/// and route the app gives it live, so a preview's pixels are the app's. A
/// place stands in the [tabs]' frame with [activeIndex] current; a pushed
/// page beside the places from 600 wide, as the app stands it; a raised
/// task over a blank stage, so its way out draws as it does live.
///
/// It stands in a [PreviewFrame] of [platform] and [brightness], so the
/// page behaves as on that platform.
///
/// ```dart
/// CivicPreview(
///   presentation: CivicPresentation.pushed,
///   child: const PermitPage(),
/// )
/// ```
class CivicPreview extends StatelessWidget {
  /// A preview of [child].
  const CivicPreview({
    super.key,
    required this.child,
    this.light,
    this.dark,
    this.brightness = Brightness.light,
    this.presentation = CivicPresentation.root,
    this.tabs = const <CivicNavItem>[],
    this.activeIndex = 0,
    this.action,
    this.brand,
    this.platform = PreviewPlatform.android,
    this.device = false,
  });

  /// The page.
  final Widget child;

  /// The theme by day; null is Civic's own.
  final CivicThemeData? light;

  /// The theme by night; null is Civic's own.
  final CivicThemeData? dark;

  /// The appearance it stands in.
  final Brightness brightness;

  /// How the page stands in its app.
  final CivicPresentation presentation;

  /// The app's places; empty draws no frame.
  final List<CivicNavItem> tabs;

  /// The current place.
  final int activeIndex;

  /// The app's one act.
  final ShellAction? action;

  /// The service's name, above the places from 600 wide.
  final String? brand;

  /// The platform the page behaves as on.
  final PreviewPlatform platform;

  /// Whether it draws on the platform's own device box.
  final bool device;

  @override
  Widget build(BuildContext context) {
    // A preview's page is looked at, not navigated: its places stay put.
    Widget framed(Widget page, {required bool places}) => CivicShellFrame(
      places: tabs,
      selectedIndex: activeIndex,
      onSelected: (_) {},
      action: action,
      brand: brand,
      showPlaces: places,
      child: page,
    );
    const stageKey = ValueKey<String>('civic-preview');
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      device: device,
      // The preview's app stands in a semantics container of its own: the
      // modal barrier under its routes hides only what it paints, never the
      // page round the preview.
      child: Semantics(
        container: true,
        child: MaterialApp(
          // A new presentation is a new stack: raise it afresh.
          key: ValueKey<CivicPresentation>(presentation),
          title: brand ?? '',
          debugShowCheckedModeBanner: false,
          builder: (context, app) => CivicHost(
            light: light,
            dark: dark,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            CivicPresentation.root => framed(child, places: true),
            // The places stand beside a pushed page from 600 wide, as the
            // app's frame stands them; a phone's bar yields to it.
            CivicPresentation.pushed => PreviewStage(
              route: (context, page) => CivicPage<void>(
                key: stageKey,
                child: page,
              ).createRoute(context),
              child: framed(child, places: false),
            ),
            CivicPresentation.sheet => PreviewStage(
              route: (context, page) => CivicSheetPage<void>(
                key: stageKey,
                child: page,
              ).createRoute(context),
              child: child,
            ),
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<CivicPresentation>('presentation', presentation))
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(IntProperty('activeIndex', activeIndex));
  }
}
