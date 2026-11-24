import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart' show RawWidgetsLocalizations;

import 'design/design.dart';
import 'garden.dart';
import 'screens/plants.dart';

/// Tend, the app: its garden over everything, Flutter's [MaterialApp] for
/// the routes, text editing and localizations, and its own design in the
/// app's builder, so every route, dialog and toast stands under it.
class TendApp extends StatefulWidget {
  /// The app, on [garden], or on a garden of examples when none is given.
  const TendApp({super.key, this.garden});

  /// The plants and settings; the app makes and owns one when null.
  final Garden? garden;

  @override
  State<TendApp> createState() => _TendAppState();
}

class _TendAppState extends State<TendApp> {
  Garden? _owned;

  Garden get _garden => widget.garden ?? (_owned ??= Garden.example());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GardenScope(
    garden: _garden,
    child: ListenableBuilder(
      listenable: _garden,
      builder: (context, _) => MaterialApp(
        title: 'Tend',
        debugShowCheckedModeBanner: false,
        // ui_core's built-in words (Close, Back, the scrim's name) in the
        // reader's language, beside Flutter's own.
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: RawWidgetsLocalizations.supportedLocales,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: tendPageTransitions,
          ),
        ),
        builder: (context, child) =>
            tendHost(context, child!, _brightness(context)),
        // The first screen stands on the design's route too: Material's
        // route under a RawPageRoute is never told to play its exit.
        onGenerateRoute: (settings) => TendPageRoute<void>(
          settings: settings,
          builder: (context) => const PlantsScreen(),
        ),
      ),
    ),
  );

  Brightness _brightness(BuildContext context) => switch (_garden.appearance) {
    Appearance.system => MediaQuery.platformBrightnessOf(context),
    Appearance.light => Brightness.light,
    Appearance.dark => Brightness.dark,
  };
}

/// The app's design round [child], as the app's builder puts it: the theme
/// for [brightness], the toasts over every route, and the ground.
Widget tendHost(BuildContext context, Widget child, Brightness brightness) {
  final data = TendThemeData.of(brightness);
  return TendTheme(
    data: data,
    // Toasts over every route, under the design's theme.
    child: TendToaster(
      child: ColoredBox(color: data.colors.ground, child: child),
    ),
  );
}
