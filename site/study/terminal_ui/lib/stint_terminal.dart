import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';
import 'package:terminal_ui/terminal_ui.dart';

part 'src/console.dart';
part 'src/today.dart';
part 'src/queue.dart';
part 'src/editor.dart';
part 'src/clock.dart';

/// Opens the studio console with Terminal's bundled monospace faces.
Future<Widget> openStintTerminal(StintLaunch launch) async {
  await termLoadFonts();
  return StintTerminal(launch: launch);
}

class StintTerminal extends StatefulWidget {
  const StintTerminal({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintTerminal> createState() => _StintTerminalState();
}

class _StintTerminalState extends State<StintTerminal> {
  late final state = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
  final console = GlobalKey<_ConsoleState>();
  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.settings,
    builder: (ctx, _) {
      final prefs = state.settings;
      return MaterialApp(
        title: 'Stint',
        debugShowCheckedModeBanner: false,
        locale: prefs.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: termPageTransitions,
          ),
        ),
        home: _Console(key: console, state: state),
        builder: (ctx, child) {
          final dark = switch (prefs.appearance) {
            Appearance.day => false,
            Appearance.night => true,
            Appearance.system =>
              MediaQuery.platformBrightnessOf(ctx) == Brightness.dark,
          };
          final grid = TermGrid(lineHeight: prefs.compact ? 20 : 24);
          return MediaQuery(
            data: MediaQuery.of(ctx).copyWith(
              textScaler: prefs.scale == null
                  ? MediaQuery.textScalerOf(ctx)
                  : TextScaler.linear(prefs.scale!),
            ),
            child: TermTheme(
              data: TermThemeData.preset(
                prefs.presetOf(_paletteIds),
                dark ? Brightness.dark : Brightness.light,
                grid: grid,
              ),
              child: TermToaster(
                child: RawCommandShortcut(
                  onOpen: () => console.currentState?.commands(),
                  child: CallbackShortcuts(
                    bindings: {
                      for (final meta in [false, true])
                        SingleActivator(
                          LogicalKeyboardKey.keyS,
                          meta: meta,
                          control: !meta,
                        ): () =>
                            console.currentState?.save(),
                      for (final place in Place.values)
                        _windowKeys[place.index]: () =>
                            console.currentState?.go(place),
                      _timerKey: () => console.currentState?.timerKey(),
                      _switchKey: () => console.currentState?.switchKey(),
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

const _windowKeys = [
  SingleActivator(LogicalKeyboardKey.digit1, alt: true),
  SingleActivator(LogicalKeyboardKey.digit2, alt: true),
  SingleActivator(LogicalKeyboardKey.digit3, alt: true),
  SingleActivator(LogicalKeyboardKey.digit4, alt: true),
];

/// A short form: a sheet at a phone's foot; from 600 px a dialog where it
/// stays, as Sign out is, not a phone sheet hanging over the status line.
Future<T?> _raise<T>({
  required BuildContext context,
  required String semanticLabel,
  required WidgetBuilder builder,
}) => MediaQuery.sizeOf(context).width < 600
    ? showTermSheet<T>(
        context: context,
        semanticLabel: semanticLabel,
        builder: builder,
      )
    : showTermDialog<T>(
        context: context,
        semanticLabel: semanticLabel,
        builder: builder,
      );

/// [_raise]'s face: a [TermSheet] on a phone, a [TermDialog] from 600 px.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.footer,
    required this.actions,
    required this.child,
  });
  final String title, footer;
  final List<Widget> actions;
  final Widget child;
  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width < 600
      ? TermSheet(title: title, footer: footer, actions: actions, child: child)
      : TermDialog(
          title: title,
          footer: footer,
          actions: actions,
          content: child,
        );
}

/// Terminal's six palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final palette in TermThemeData.palettes)
    StintPalette(
      palette.id,
      TermThemeData.preset(palette.id, Brightness.light).accent,
      label: palette.label,
    ),
];

/// The palettes' ids, the theme's preset for each.
final _paletteIds = [for (final palette in _palettes) palette.id];
