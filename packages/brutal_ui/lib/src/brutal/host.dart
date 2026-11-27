// Brutal's part of the host library: a page previewed alone, as the app stands it, with no router.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'app.dart';
import 'navigation.dart';
import 'overlays.dart';
import 'theme.dart';

/// How a page stands in a [BrutalPreview].
enum BrutalPresentation {
  /// A root, over the app's places.
  root,

  /// Pushed over a root.
  pushed,

  /// Raised as a sheet.
  sheet,
}

/// One page alone, as the app stands it: the same host, the same places
/// and act on a root, the same route on a pushed page or a sheet, with no
/// router.
///
/// ```dart
/// BrutalPreview(presentation: BrutalPresentation.pushed, child: BrutalScreen(body: const Text('Doors at eight.')))
/// ```
class BrutalPreview extends StatelessWidget {
  /// A preview of [child].
  const BrutalPreview({
    super.key,
    required this.child,
    this.theme,
    this.darkTheme,
    this.brightness = Brightness.light,
    this.presentation = BrutalPresentation.root,
    this.tabs = const [],
    this.selectedIndex = 0,
    this.action,
    this.brand,
    this.drawer = false,
    this.platform = PreviewPlatform.android,
  });

  /// The page.
  final Widget child;

  /// The theme by day.
  final BrutalThemeData? theme;

  /// The theme by night.
  final BrutalThemeData? darkTheme;

  /// The brightness to draw in.
  final Brightness brightness;

  /// How the page stands.
  final BrutalPresentation presentation;

  /// The app's places, on a root.
  final List<BrutalTab> tabs;

  /// The place the page is.
  final int selectedIndex;

  /// The app's one act, on a root.
  final ShellAction? action;

  /// The app's name, at the head of its places on a tablet or a desktop.
  final String? brand;

  /// Whether a sheet stands as tall as its content.
  final bool drawer;

  /// The platform previewed.
  final PreviewPlatform platform;

  @override
  Widget build(BuildContext context) {
    Widget rooted(Widget page) => tabs.isEmpty && action == null
        ? page
        : BrutalAppShell(
            tabs: tabs,
            selectedIndex: selectedIndex,
            onDestinationSelected: (_) {},
            action: switch (action) {
              final a? => BrutalShellAction(
                icon: a.icon,
                onPressed: a.onPressed,
                tooltip: a.label,
                accent: a.accent,
                key: a.key,
              ),
              null => null,
            },
            brand: brand,
            child: page,
          );
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      // The app inside, a semantics container of its own: its routes'
      // barriers would hide from a screen reader what the page around it
      // paints before it.
      child: Semantics(
        container: true,
        child: MaterialApp(
          key: ValueKey<Object>((presentation, drawer)),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            RawWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          builder: (context, app) => BrutalHost(
            theme: theme,
            darkTheme: darkTheme,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            BrutalPresentation.root => rooted(child),
            BrutalPresentation.pushed => PreviewStage(
              route: (context, page) => BrutalPage<void>(
                key: const ValueKey<String>('brutal-preview'),
                child: page,
              ).createRoute(context),
              child: child,
            ),
            BrutalPresentation.sheet => PreviewStage(
              route: (context, page) => BrutalSheetPage<void>(
                key: const ValueKey<String>('brutal-preview'),
                drawer: drawer,
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
      ..add(
        DiagnosticsProperty<BrutalThemeData>(
          'theme',
          theme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalThemeData>(
          'darkTheme',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<Brightness>('brightness', brightness))
      ..add(
        DiagnosticsProperty<BrutalPresentation>('presentation', presentation),
      )
      ..add(IterableProperty<BrutalTab>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(FlagProperty('drawer', value: drawer, ifTrue: 'drawer'))
      ..add(DiagnosticsProperty<PreviewPlatform>('platform', platform));
  }
}
