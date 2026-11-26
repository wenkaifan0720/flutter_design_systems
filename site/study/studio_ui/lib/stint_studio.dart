import 'package:flutter/services.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';

final _stationFonts = Future.wait([
  studioLoadFonts(),
  (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      ))
      .load(),
]);

/// Opens the standalone app and the documentation site's embed with the same
/// text and icon faces.
Future<Widget> openStintStudio(StintLaunch launch) async {
  await _stationFonts;
  return StintStudio(launch: launch);
}

/// A team planner arranged as windows on a Studio console.
class StintStudio extends StatefulWidget {
  /// Opens the workspace with the given launch options and optional repository.
  const StintStudio({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });

  /// The initial place, preferences and fixture scenario.
  final StintLaunch launch;

  /// An optional repository to inspect or retain the team’s edits.
  final StintRepository? repository;

  @override
  State<StintStudio> createState() => _StintStudioState();
}

class _StintStudioState extends State<StintStudio> {
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
            comfortable = value == StudioDensity.comfortable;
            settings.compact = value == StudioDensity.compact;
          });
        },
      );
      return MaterialApp(
        title: 'Stint',
        debugShowCheckedModeBanner: false,
        locale: settings.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          _StudioWordsDelegate(),
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: studioPageTransitions,
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
            child: StudioHost(
              brightness: brightness,
              theme:
                  StudioThemeData.preset(
                    settings.presetOf(StudioThemeData.presets),
                    Brightness.light,
                  ).copyWith(
                    density: settings.compact
                        ? StudioDensity.compact
                        : comfortable
                        ? StudioDensity.comfortable
                        : StudioDensity.standard,
                  ),
              darkTheme:
                  StudioThemeData.preset(
                    settings.presetOf(StudioThemeData.presets),
                    Brightness.dark,
                  ).copyWith(
                    density: settings.compact
                        ? StudioDensity.compact
                        : comfortable
                        ? StudioDensity.comfortable
                        : StudioDensity.standard,
                  ),
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
  final ValueChanged<StudioDensity> chooseDensity;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _StudioWordsDelegate extends LocalizationsDelegate<StudioLocalizations> {
  const _StudioWordsDelegate();
  @override
  bool isSupported(Locale locale) =>
      StintLanguage.locales.any((l) => l.languageCode == locale.languageCode);
  @override
  Future<StudioLocalizations> load(Locale locale) async =>
      locale.languageCode == 'en'
      ? const DefaultStudioLocalizations()
      : _StintStudioWords(
          StintWords(StintLanguage.forCode(locale.languageCode)),
        );
  @override
  bool shouldReload(_StudioWordsDelegate old) => false;
}

class _StintStudioWords extends DefaultStudioLocalizations {
  const _StintStudioWords(this.words);
  final StintWords words;
  @override
  String rowCount(int n) => words.totalTasks(n);
}

/// Studio's six presets, the look's own first, for a host's palette menu.
final _palettes = [
  for (final id in StudioThemeData.presets)
    StintPalette(
      id,
      StudioThemeData.preset(id, Brightness.light).colors.indicator,
    ),
];
