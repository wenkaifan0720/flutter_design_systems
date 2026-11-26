import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/localizations.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';

/// Opens the standalone app and the documentation site's embed with the same
/// text and icon faces.
Future<Widget> openStintRetroDesktop(StintLaunch launch) async {
  await retroDesktopLoadFonts();
  return StintRetroDesktop(launch: launch);
}

/// A team planner arranged as windows on a Retro Desktop workspace.
class StintRetroDesktop extends StatefulWidget {
  /// Opens the workspace with the given launch options and optional repository.
  const StintRetroDesktop({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });

  /// The initial place, preferences and fixture scenario.
  final StintLaunch launch;

  /// An optional repository to inspect or retain the team’s edits.
  final StintRepository? repository;

  @override
  State<StintRetroDesktop> createState() => _StintRetroDesktopState();
}

class _StintRetroDesktopState extends State<StintRetroDesktop> {
  late final model = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
  bool comfortable = false;
  final workspace = GlobalKey<_WorkspaceState>();

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model.settings,
    builder: (context, _) {
      final settings = model.settings;
      Widget page(BuildContext _) => _Workspace(
        key: workspace,
        model: model,
        chooseDensity: (value) {
          settings.update(() {
            comfortable = value == RetroDesktopDensity.comfortable;
            settings.compact = value == RetroDesktopDensity.compact;
          });
        },
      );
      return MaterialApp(
        title: 'Stint',
        debugShowCheckedModeBanner: false,
        locale: settings.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          _DesktopWordsDelegate(),
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: retroDesktopPageTransitions,
          ),
        ),
        onGenerateInitialRoutes: (_) => [_root(page)],
        onGenerateRoute: (_) => _root(page),
        builder: (ctx, child) {
          final media = MediaQuery.of(ctx);
          final brightness = switch (settings.appearance) {
            Appearance.system => media.platformBrightness,
            Appearance.day => Brightness.light,
            Appearance.night => Brightness.dark,
          };
          final density = settings.compact
              ? RetroDesktopDensity.compact
              : comfortable
              ? RetroDesktopDensity.comfortable
              : RetroDesktopDensity.standard;
          RetroDesktopThemeData desk(Brightness brightness) =>
              RetroDesktopThemeData.preset(
                settings.presetOf(RetroDesktopThemeData.presets),
                brightness,
              ).copyWith(density: density);
          return MediaQuery(
            data: media.copyWith(
              textScaler: settings.scale == null
                  ? media.textScaler
                  : TextScaler.linear(settings.scale!),
            ),
            // The host installs the look's toaster above the navigator, so a
            // notice stands above the phone's Save strip (a marked footer).
            child: RetroDesktopHost(
              light: desk(Brightness.light),
              dark: desk(Brightness.dark),
              brightness: brightness,
              child: RawCommandShortcut(
                onOpen: () => workspace.currentState?.palette(),
                child: CallbackShortcuts(
                  bindings: {
                    for (final meta in [false, true])
                      SingleActivator(
                        LogicalKeyboardKey.keyS,
                        meta: meta,
                        control: !meta,
                      ): () =>
                          workspace.currentState?.save(),
                  },
                  child: child!,
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Route<void> _root(WidgetBuilder builder) => PageRouteBuilder<void>(
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  pageBuilder: (ctx, _, _) => builder(ctx),
);

class _Workspace extends StatefulWidget {
  const _Workspace({
    super.key,
    required this.model,
    required this.chooseDensity,
  });
  final StintController model;
  final ValueChanged<RetroDesktopDensity> chooseDensity;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

/// Retro Desktop's six palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final id in RetroDesktopThemeData.presets)
    StintPalette(
      id,
      RetroDesktopThemeData.preset(id, Brightness.light).colors.highlight,
    ),
];
