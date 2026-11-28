import 'package:flutter/services.dart';
import 'package:gloss_ui/gloss_host.dart' show ShellInsets;
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';

/// Opens the standalone app and the documentation site's embed with the same
/// bundled face.
Future<Widget> openStintGloss(StintLaunch launch) async {
  await glossLoadFonts();
  return StintGloss(launch: launch);
}

class StintGloss extends StatefulWidget {
  const StintGloss({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });

  final StintLaunch launch;
  final StintRepository? repository;

  @override
  State<StintGloss> createState() => _StintGlossState();
}

class _StintGlossState extends State<StintGloss> {
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
      final settings = model.settings;
      Widget page(BuildContext _) => _Workspace(key: workspace, model: model);
      return MaterialApp(
        title: 'Stint',
        debugShowCheckedModeBanner: false,
        locale: settings.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: glossPageTransitions,
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
          return MediaQuery(
            data: media.copyWith(
              textScaler: settings.scale == null
                  ? media.textScaler
                  : TextScaler.linear(settings.scale!),
            ),
            child: GlossTheme(
              data: GlossThemeData.preset(
                settings.presetOf(_paletteIds),
                brightness,
                density: settings.compact
                    ? GlossDensity.compact
                    : GlossDensity.standard,
              ),
              child: GlossToaster(
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
  const _Workspace({super.key, required this.model});
  final StintController model;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

/// Gloss's six gels, the look's own first, for a host's palette menu.
final _palettes = [
  for (final palette in GlossThemeData.palettes)
    StintPalette(
      palette.id,
      GlossThemeData.preset(palette.id, Brightness.light).colors.jade,
      label: palette.label,
    ),
];

/// The palettes' ids, the theme's preset for each.
final _paletteIds = [for (final palette in _palettes) palette.id];
