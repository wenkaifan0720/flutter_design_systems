import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/service.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/task_form.dart';
part 'src/fields.dart';
part 'src/timesheet.dart';

/// Opens the Fieldwork Studio service in Civic's bundled typefaces.
Future<Widget> openStintCivic(StintLaunch launch) async {
  await civicLoadFonts();
  return StintCivic(launch: launch);
}

class StintCivic extends StatefulWidget {
  const StintCivic({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintCivic> createState() => _StintCivicState();
}

class _StintCivicState extends State<StintCivic> {
  late final service = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
  final home = GlobalKey<_ServiceState>();
  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: service.settings,
    builder: (_, _) {
      final p = service.settings;
      return MaterialApp(
        title: 'Stint',
        debugShowCheckedModeBanner: false,
        locale: p.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: civicPageTransitions,
          ),
        ),
        home: _Service(key: home, controller: service),
        builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            textScaler: p.scale == null
                ? MediaQuery.textScalerOf(ctx)
                : TextScaler.linear(p.scale!),
          ),
          child: CivicTheme(
            data: CivicThemeData.preset(
              p.presetOf(CivicThemeData.presets),
              switch (p.appearance) {
                Appearance.day => Brightness.light,
                Appearance.night => Brightness.dark,
                Appearance.system => MediaQuery.platformBrightnessOf(ctx),
              },
            ),
            child: CivicToaster(
              child: RawCommandShortcut(
                onOpen: () => home.currentState?.commands(),
                child: CallbackShortcuts(
                  bindings: {
                    for (final mac in [false, true])
                      SingleActivator(
                        LogicalKeyboardKey.keyS,
                        meta: mac,
                        control: !mac,
                      ): () =>
                          home.currentState?.save(),
                  },
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Civic's six palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final id in CivicThemeData.presets)
    StintPalette(id, CivicThemeData.preset(id, Brightness.light).action),
];
