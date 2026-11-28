import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_host.dart' show MinimalChromeMetrics;
import 'package:minimal_ui/minimal_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/week_summary.dart';
part 'src/localizations.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';

/// Loads the bundled look typography before a host app mounts its study.
Future<Widget> openStintMinimal(StintLaunch launch) async {
  await minimalLoadFonts();
  return StintMinimal(launch: launch);
}

/// Stint in Minimal. A host app can load this library deferred and mount this widget.
class StintMinimal extends StatefulWidget {
  const StintMinimal({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;

  @override
  State<StintMinimal> createState() => _AppState();
}

class _AppState extends State<StintMinimal> {
  late final model = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
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
      final prefs = model.settings;
      Widget home() => _Workspace(key: workspace, model: model);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stint',
        locale: prefs.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: [
          ..._stintControls,
          MinimalLocalizations.delegate,
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: minimalPageTransitions,
          ),
        ),
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: (_) => home()),
        ],
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => home()),
        builder: (context, child) {
          final brightness = switch (prefs.appearance) {
            Appearance.day => Brightness.light,
            Appearance.night => Brightness.dark,
            Appearance.system => MediaQuery.platformBrightnessOf(context),
          };
          final shell = CallbackShortcuts(
            bindings: {
              for (final meta in [false, true]) ...{
                SingleActivator(
                  LogicalKeyboardKey.keyK,
                  meta: meta,
                  control: !meta,
                ): () =>
                    workspace.currentState?.palette(),
                SingleActivator(
                  LogicalKeyboardKey.keyS,
                  meta: meta,
                  control: !meta,
                ): () =>
                    workspace.currentState?.saveShortcut(),
              },
            },
            child: child!,
          );
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: prefs.scale == null
                  ? media.textScaler
                  : TextScaler.linear(prefs.scale!),
            ),
            child: MinimalTheme(
              data:
                  MinimalThemeData.preset(
                    prefs.presetOf(_paletteIds),
                    brightness,
                  ).copyWith(
                    density: prefs.compact
                        ? MinimalDensity.compact
                        : MinimalDensity.standard,
                  ),
              child: MinimalToaster(child: shell),
            ),
          );
        },
      );
    },
  );
}

class _Workspace extends StatefulWidget {
  const _Workspace({super.key, required this.model});
  final StintController model;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

/// Minimal's six palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final palette in MinimalThemeData.palettes)
    StintPalette(
      palette.id,
      MinimalThemeData.preset(palette.id, Brightness.light).primary,
      label: palette.label,
    ),
];

/// The palettes' ids, the theme's preset for each.
final _paletteIds = [for (final palette in _palettes) palette.id];
