import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';

/// The documentation site's and the standalone app's entry point, including
/// Brutal's Space Grotesk face.
Future<Widget> openStintBrutal(StintLaunch launch) async {
  await brutalLoadFonts();
  return StintBrutal(launch: launch);
}

class StintBrutal extends StatefulWidget {
  const StintBrutal({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintBrutal> createState() => _AppState();
}

class _AppState extends State<StintBrutal> {
  late final c = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
  final studio = GlobalKey<_StudioState>();
  bool comfortable = false;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c.settings,
    builder: (context, _) {
      final p = c.settings;
      final density = p.compact
          ? BrutalDensity.compact
          : comfortable
          ? BrutalDensity.comfortable
          : BrutalDensity.standard;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stint',
        locale: p.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          _ControlDelegate(),
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: brutalPageTransitions,
          ),
        ),
        home: _Studio(
          key: studio,
          controller: c,
          density: density,
          onDensity: (d) => p.update(() {
            p.compact = d == BrutalDensity.compact;
            comfortable = d == BrutalDensity.comfortable;
          }),
        ),
        builder: (ctx, child) {
          final media = MediaQuery.of(ctx);
          return MediaQuery(
            data: media.copyWith(
              textScaler: p.scale == null
                  ? media.textScaler
                  : TextScaler.linear(p.scale!),
            ),
            child: BrutalHost(
              brightness: switch (p.appearance) {
                Appearance.system => null,
                Appearance.day => Brightness.light,
                Appearance.night => Brightness.dark,
              },
              theme: BrutalThemeData.preset(
                p.presetOf(BrutalThemeData.presets),
                Brightness.light,
                density: density,
              ),
              darkTheme: BrutalThemeData.preset(
                p.presetOf(BrutalThemeData.presets),
                Brightness.dark,
                density: density,
              ),
              child: CallbackShortcuts(
                bindings: {
                  for (final meta in [false, true]) ...{
                    SingleActivator(
                      LogicalKeyboardKey.keyK,
                      meta: meta,
                      control: !meta,
                    ): () =>
                        studio.currentState?.palette(),
                    SingleActivator(
                      LogicalKeyboardKey.keyS,
                      meta: meta,
                      control: !meta,
                    ): () =>
                        studio.currentState?.save(),
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

class _ControlDelegate extends LocalizationsDelegate<BrutalLocalizations> {
  const _ControlDelegate();
  @override
  bool isSupported(Locale l) =>
      StintLanguage.locales.any((s) => s.languageCode == l.languageCode);
  @override
  Future<BrutalLocalizations> load(Locale l) => SynchronousFuture(
    l.languageCode == 'en'
        ? const BrutalLocalizations()
        : _StintControls(StintWords(StintLanguage.forCode(l.languageCode))),
  );
  @override
  bool shouldReload(_ControlDelegate old) => false;
}

class _StintControls extends BrutalLocalizations {
  const _StintControls(this.words);
  final StintWords words;
  @override
  String rowCount(int count) => words.rowCount(count);
}

/// Brutal's six palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final id in BrutalThemeData.presets)
    StintPalette(
      id,
      BrutalThemeData.preset(id, Brightness.light).colors.signal,
    ),
];
