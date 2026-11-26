import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/localizations.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';

final _studyFonts = Future.wait([
  neumorphicLoadFonts(),
  (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      ))
      .load(),
]);

/// Opens the standalone app and the documentation site's embed with the same
/// text and icon faces.
Future<Widget> openStintNeumorphism(StintLaunch launch) async {
  await _studyFonts;
  return StintNeumorphism(launch: launch);
}

class StintNeumorphism extends StatefulWidget {
  const StintNeumorphism({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });

  final StintLaunch launch;
  final StintRepository? repository;

  @override
  State<StintNeumorphism> createState() => _StintNeumorphismState();
}

class _StintNeumorphismState extends State<StintNeumorphism> {
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
          _PlasterWordsDelegate(),
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: neumorphicPageTransitions,
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
            child: NeumorphicTheme(
              data:
                  NeumorphicThemeData.preset(
                    settings.presetOf(NeumorphicThemeData.presets),
                    brightness,
                  ).copyWith(
                    density: settings.compact
                        ? NeumorphicDensity.compact
                        : NeumorphicDensity.standard,
                  ),
              child: NeumorphicToaster(
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

/// Neumorphism's six palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final id in NeumorphicThemeData.presets)
    StintPalette(
      id,
      NeumorphicThemeData.preset(id, Brightness.light).colors.accent,
    ),
];
