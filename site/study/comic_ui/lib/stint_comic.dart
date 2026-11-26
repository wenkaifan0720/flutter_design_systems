import 'dart:math' as math;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/localizations.dart';
part 'src/time_settings.dart';

Future<Widget> openStintComic(StintLaunch launch) async {
  await comicLoadFonts();
  return StintComic(launch: launch);
}

class StintComic extends StatefulWidget {
  const StintComic({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintComic> createState() => _AppState();
}

class _AppState extends State<StintComic> {
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
          ComicLocalizations.delegate,
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: comicPageTransitions,
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
            child: ComicTheme(
              data:
                  ComicThemeData.preset(
                    prefs.presetOf(ComicThemeData.presets),
                    brightness,
                  ).copyWith(
                    density: prefs.compact
                        ? ComicDensity.compact
                        : ComicDensity.standard,
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
                child: child!,
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

/// Comic's six print runs, the look's own first, for a host's palette menu.
final _palettes = [
  for (final id in ComicThemeData.presets)
    StintPalette(id, ComicThemeData.preset(id, Brightness.light).colors.primary),
];
