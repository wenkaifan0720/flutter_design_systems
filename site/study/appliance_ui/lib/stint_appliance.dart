import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/week_summary.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';

/// Loads the bundled look typography before a host app mounts its study.
Future<Widget> openStintAppliance(StintLaunch launch) async {
  await applianceLoadFonts();
  return StintAppliance(launch: launch);
}

/// Stint in Appliance. A host app can load this library deferred and mount this widget.
class StintAppliance extends StatefulWidget {
  const StintAppliance({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;

  @override
  State<StintAppliance> createState() => _AppState();
}

class _AppState extends State<StintAppliance> {
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
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: appliancePageTransitions,
          ),
        ),
        onGenerateInitialRoutes: (_) => [_rootPage((_) => home())],
        onGenerateRoute: (_) => _rootPage((_) => home()),
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
            child: ApplianceTheme(
              data:
                  ApplianceThemeData.preset(
                    prefs.presetOf(_paletteIds),
                    brightness,
                  ).copyWith(
                    density: prefs.compact
                        ? ApplianceDensity.compact
                        : ApplianceDensity.standard,
                  ),
              child: ApplianceToaster(child: shell),
            ),
          );
        },
      );
    },
  );
}

// A shell and its destination root keep their element trees while a page or
// dialog moves above them. The pushed editor still takes Appliance's motion.
Route<void> _rootPage(WidgetBuilder builder) => PageRouteBuilder<void>(
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  pageBuilder: (context, _, _) => builder(context),
);

class _Workspace extends StatefulWidget {
  const _Workspace({super.key, required this.model});
  final StintController model;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

/// Appliance's six finishes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final palette in ApplianceThemeData.palettes)
    StintPalette(
      palette.id,
      ApplianceThemeData.preset(palette.id, Brightness.light).colors.signal,
      label: palette.label,
    ),
];

/// The palettes' ids, the theme's preset for each.
final _paletteIds = [for (final palette in _palettes) palette.id];
