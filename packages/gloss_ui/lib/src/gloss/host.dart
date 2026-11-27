// Gloss's part of the app host: what a host app's router shell takes for its
// places and its act (a router adapter's GlossShell), and the preview frame that stands
// one page alone. The package exports it from gloss_host.dart, beside the
// main library, not in it: an app built on the package frames its places
// with GlossAppShell and GlossActKey.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'app.dart';
import 'navigation.dart';
import 'overlays.dart';
import 'theme.dart';

/// One of an app shell's places as an app declares it: its glyph, its name
/// and the key on its cell.
///
/// ```dart
/// GlossTab(LucideIcons.house, 'Today', ValueKey('open-today'))
/// ```
@immutable
class GlossTab {
  /// A place called [label], shown by [icon].
  const GlossTab(this.icon, this.label, [this.key]);

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// The key on its cell.
  final Key? key;

  /// This place as a [GlossAppShell]'s destination, its [key] on its cell.
  RawNavigationDestination get destination =>
      RawNavigationDestination(label: label, icon: icon, data: key);
}

/// A host's act ([action], a [GlossShellAction] or ui_core's [ShellAction])
/// as the shell's [GlossActKey], keyed with its key; pressed, it calls the
/// act with the context it stands in.
Widget glossShellActKey(ShellAction action) => Builder(
  builder: (context) => KeyedSubtree(
    key: action.key,
    child: GlossActKey(
      icon: action.icon,
      label: action.label ?? 'New',
      accent: action.accent,
      onPressed: () => action.onPressed(context),
    ),
  ),
);

/// The app's one act beside its places (add, plan, capture): a jade gel
/// bead in the chrome when [accent], a pearl one when not.
///
/// ```dart
/// GlossShellAction(icon: LucideIcons.plus, accent: true, onPressed: (context) => openNewRecipe(context))
/// ```
class GlossShellAction extends ShellAction {
  /// An act wearing [icon].
  const GlossShellAction({
    required super.icon,
    required super.onPressed,
    super.label,
    super.accent = true,
    super.key,
  });
}

/// How a page stands in a [GlossPreview].
enum GlossPresentation {
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
/// GlossPreview(presentation: GlossPresentation.pushed, child: GlossScreen(body: const Text('Serves two.')))
/// ```
class GlossPreview extends StatelessWidget {
  /// A preview of [child].
  const GlossPreview({
    super.key,
    required this.child,
    this.theme,
    this.darkTheme,
    this.brightness = Brightness.light,
    this.presentation = GlossPresentation.root,
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
  final GlossThemeData? theme;

  /// The theme by night.
  final GlossThemeData? darkTheme;

  /// The brightness to draw in.
  final Brightness brightness;

  /// How the page stands.
  final GlossPresentation presentation;

  /// The app's places, on a root.
  final List<GlossTab> tabs;

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
    final act = action;
    final name = brand;
    Widget rooted(Widget page) => tabs.isEmpty && act == null
        ? page
        : GlossAppShell.router(
            destinations: [for (final tab in tabs) tab.destination],
            selectedIndex: selectedIndex,
            onDestinationSelected: (_) {},
            header: name == null || name.isEmpty ? null : GlossBrand(name),
            action: act == null ? null : glossShellActKey(act),
            body: page,
          );
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      // A semantics node of its own: the app's routes block only what is
      // under them in it, never the page the preview stands on.
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
          builder: (context, app) => GlossHost(
            theme: theme,
            darkTheme: darkTheme,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            GlossPresentation.root => rooted(child),
            GlossPresentation.pushed => PreviewStage(
              route: (context, page) => GlossPage<void>(
                key: const ValueKey<String>('gloss-preview'),
                child: page,
              ).createRoute(context),
              child: child,
            ),
            GlossPresentation.sheet => PreviewStage(
              route: (context, page) => GlossSheetPage<void>(
                key: const ValueKey<String>('gloss-preview'),
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
        DiagnosticsProperty<GlossThemeData>('theme', theme, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<GlossThemeData>(
          'darkTheme',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<Brightness>('brightness', brightness))
      ..add(
        DiagnosticsProperty<GlossPresentation>('presentation', presentation),
      )
      ..add(IterableProperty<GlossTab>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(FlagProperty('drawer', value: drawer, ifTrue: 'drawer'))
      ..add(DiagnosticsProperty<PreviewPlatform>('platform', platform));
  }
}
