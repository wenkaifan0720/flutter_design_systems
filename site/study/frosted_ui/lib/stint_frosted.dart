import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';
part 'src/localizations.dart';

final _faces = Future.wait([
  frostedLoadFonts(),
  (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      ))
      .load(),
]);

/// Loads the faces before either the standalone study or the documentation
/// site's embed opens.
Future<Widget> openStintFrosted(StintLaunch launch) async {
  await _faces;
  return StintFrosted(launch: launch);
}

/// Fieldwork Studio’s task list and timesheet in Frosted.
class StintFrosted extends StatefulWidget {
  /// Opens the study at [launch], optionally using an existing [repository].
  const StintFrosted({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });

  /// Initial place, locale and appearance.
  final StintLaunch launch;

  /// Storage shared with a test or the embedding application.
  final StintRepository? repository;
  @override
  State<StintFrosted> createState() => _StintFrostedState();
}

class _StintFrostedState extends State<StintFrosted> {
  late final c = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
  final workspace = GlobalKey<_WorkspaceState>();
  bool comfortable = false;
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c.settings,
    builder: (_, _) {
      final s = c.settings;
      final density = s.compact
          ? FrostedDensity.compact
          : comfortable
          ? FrostedDensity.comfortable
          : FrostedDensity.standard;
      return MaterialApp(
        title: 'Stint',
        debugShowCheckedModeBanner: false,
        locale: s.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          _WordsDelegate(),
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: frostedPageTransitions,
          ),
        ),
        builder: (ctx, child) {
          final media = MediaQuery.of(ctx);
          return MediaQuery(
            data: media.copyWith(
              textScaler: s.scale == null
                  ? media.textScaler
                  : TextScaler.linear(s.scale!),
            ),
            child: FrostedHost(
              theme: FrostedThemeData.preset(
                s.presetOf(_paletteIds),
                Brightness.light,
              ).copyWith(density: density),
              darkTheme: FrostedThemeData.preset(
                s.presetOf(_paletteIds),
                Brightness.dark,
              ).copyWith(density: density),
              brightness: s.appearance == Appearance.system
                  ? null
                  : s.appearance == Appearance.night
                  ? Brightness.dark
                  : Brightness.light,
              child: RawCommandShortcut(
                onOpen: () => workspace.currentState?.commands(),
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
        home: _Workspace(
          key: workspace,
          c: c,
          density: density,
          chooseDensity: (v) => s.update(() {
            comfortable = v == FrostedDensity.comfortable;
            s.compact = v == FrostedDensity.compact;
          }),
        ),
      );
    },
  );
}

class _Workspace extends StatefulWidget {
  const _Workspace({
    super.key,
    required this.c,
    required this.density,
    required this.chooseDensity,
  });
  final StintController c;
  final FrostedDensity density;
  final ValueChanged<FrostedDensity> chooseDensity;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

/// Frosted's six palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final palette in FrostedThemeData.palettes)
    StintPalette(
      palette.id,
      FrostedThemeData.preset(palette.id, Brightness.light).colorScheme.accent,
      label: palette.label,
    ),
];

/// The palettes' ids, the theme's preset for each.
final _paletteIds = [for (final palette in _palettes) palette.id];
