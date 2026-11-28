import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ledger_ui/ledger_host.dart' show LedgerChromeMetrics;
import 'package:ledger_ui/ledger_parts.dart'
    show
        LedgerPressable,
        LedgerPressRole,
        LedgerShellFace,
        LedgerShellDestinations,
        LedgerSideInset,
        LedgerBarSlot,
        LedgerBarSlotScope;
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/book.dart';
part 'src/today.dart';
part 'src/register.dart';
part 'src/record.dart';
part 'src/time_preferences.dart';

/// Opens the studio register with Ledger's bundled typefaces.
Future<Widget> openStintLedger(StintLaunch launch) async {
  await ledgerLoadFonts();
  return StintLedger(launch: launch);
}

class StintLedger extends StatefulWidget {
  const StintLedger({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintLedger> createState() => _LedgerAppState();
}

class _LedgerAppState extends State<StintLedger> {
  late final c = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
  final book = GlobalKey<_BookState>();
  bool comfortable = false;
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c.settings,
    builder: (ctx, _) {
      final p = c.settings;
      final density = p.compact
          ? LedgerDensity.compact
          : comfortable
          ? LedgerDensity.comfortable
          : LedgerDensity.standard;
      return MaterialApp(
        title: 'Stint',
        debugShowCheckedModeBanner: false,
        locale: p.language.locale,
        supportedLocales: StintLanguage.locales,
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: _Book(
          key: book,
          controller: c,
          density: density,
          onDensity: (d) => p.update(() {
            p.compact = d == LedgerDensity.compact;
            comfortable = d == LedgerDensity.comfortable;
          }),
        ),
        builder: (ctx, child) {
          final mq = MediaQuery.of(ctx);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: p.scale == null
                  ? mq.textScaler
                  : TextScaler.linear(p.scale!),
            ),
            child: LedgerHost(
              theme: LedgerThemeData.preset(
                p.presetOf(_paletteIds),
                Brightness.light,
              ).copyWith(density: density),
              darkTheme: LedgerThemeData.preset(
                p.presetOf(_paletteIds),
                Brightness.dark,
              ).copyWith(density: density),
              brightness: switch (p.appearance) {
                Appearance.system => null,
                Appearance.day => Brightness.light,
                Appearance.night => Brightness.dark,
              },
              child: CallbackShortcuts(
                bindings: {
                  for (final meta in [false, true]) ...{
                    SingleActivator(
                      LogicalKeyboardKey.keyK,
                      meta: meta,
                      control: !meta,
                    ): () =>
                        book.currentState?.palette(),
                    SingleActivator(
                      LogicalKeyboardKey.keyS,
                      meta: meta,
                      control: !meta,
                    ): () =>
                        book.currentState?.save(),
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

/// Ledger's six palettes, the look's own first, for a host's palette menu.
final _palettes = [
  for (final palette in LedgerThemeData.palettes)
    StintPalette(
      palette.id,
      LedgerThemeData.preset(palette.id, Brightness.light).accent,
      label: palette.label,
    ),
];

/// The palettes' ids, the theme's preset for each.
final _paletteIds = [for (final palette in _palettes) palette.id];
