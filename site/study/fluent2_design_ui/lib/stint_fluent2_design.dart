import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/localizations.dart';
part 'src/time_settings.dart';

Future<Widget> openStintFluent2Design(StintLaunch launch) async {
  await loadStintFluent2Fonts();
  return StintFluent2Design(launch: launch);
}

/// Selawik covers the Latin script. Load the Arabic face for both the
/// standalone study and the documentation site's embed.
Future<void> loadStintFluent2Fonts() async {
  const face = 'assets/fonts/NotoSansArabic-Regular.ttf';
  const embedded = 'packages/stint_fluent2_design/$face';
  final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
  final arabic = FontLoader('packages/stint_fluent2_design/StintArabic')
    ..addFont(
      rootBundle.load(assets.listAssets().contains(embedded) ? embedded : face),
    );
  await Future.wait([fluent2LoadFonts(), arabic.load()]);
}

class StintFluent2Design extends StatefulWidget {
  const StintFluent2Design({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintFluent2Design> createState() => _AppState();
}

class _AppState extends State<StintFluent2Design> {
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
      Route<void> route() => MaterialPageRoute<void>(
        builder: (_) => _Workspace(key: workspace, model: model),
      );
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stint',
        locale: prefs.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          _StintControls(),
          Fluent2Localizations.delegate,
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: fluent2PageTransitions,
          ),
        ),
        onGenerateInitialRoutes: (_) => [route()],
        onGenerateRoute: (_) => route(),
        builder: (ctx, child) {
          final media = MediaQuery.of(ctx);
          final brightness = switch (prefs.appearance) {
            Appearance.system => media.platformBrightness,
            Appearance.day => Brightness.light,
            Appearance.night => Brightness.dark,
          };
          return MediaQuery(
            data: media.copyWith(
              textScaler: prefs.scale == null
                  ? media.textScaler
                  : TextScaler.linear(prefs.scale!),
            ),
            child: Fluent2Theme(
              data:
                  Fluent2ThemeData.preset(
                    prefs.presetOf(_paletteIds),
                    brightness,
                  ).copyWith(
                    solidAcrylic: true,
                    density: prefs.compact
                        ? Fluent2Density.compact
                        : Fluent2Density.standard,
                  ),
              child: CallbackShortcuts(
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
                        workspace.currentState?.save(),
                  },
                },
                child: Fluent2Toaster(child: child!),
              ),
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

/// Fluent 2's six brand palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final palette in Fluent2ThemeData.palettes)
    StintPalette(
      palette.id,
      Fluent2ThemeData.preset(palette.id, Brightness.light).accent,
      label: palette.label,
    ),
];

/// The palettes' ids, the theme's preset for each.
final _paletteIds = [for (final palette in _palettes) palette.id];
