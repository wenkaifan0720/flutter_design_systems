import 'dart:math' as math;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_expressive_ui/material_expressive_parts.dart'
    show ExpressiveSnackBarHost;
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/workspace.dart';
part 'src/today.dart';
part 'src/tasks.dart';
part 'src/detail.dart';
part 'src/time_settings.dart';

Future<Widget> openStintMaterialExpressive(StintLaunch launch) async {
  await expressiveLoadFonts();
  return StintMaterialExpressive(launch: launch);
}

class StintMaterialExpressive extends StatefulWidget {
  const StintMaterialExpressive({
    super.key,
    this.launch = const StintLaunch(),
    this.repository,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintMaterialExpressive> createState() => _AppState();
}

class _AppState extends State<StintMaterialExpressive> {
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
          ExpressiveLocalizations.delegate,
          RawWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: expressivePageTransitions,
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
          ExpressiveThemeData theme(Brightness brightness) =>
              ExpressiveThemeData.preset(
                prefs.presetOf(_presets),
                brightness,
              ).copyWith(
                density: prefs.compact
                    ? ExpressiveDensity.compact
                    : ExpressiveDensity.standard,
              );
          return MediaQuery(
            data: media.copyWith(
              textScaler: prefs.scale == null
                  ? media.textScaler
                  : TextScaler.linear(prefs.scale!),
            ),
            // The host wears the theme and shows the snackbars, above the
            // navigator.
            child: ExpressiveHost(
              theme: theme(Brightness.light),
              darkTheme: theme(Brightness.dark),
              brightness: brightness,
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

class _StintControls extends LocalizationsDelegate<ExpressiveLocalizations> {
  const _StintControls();
  @override
  bool isSupported(Locale locale) =>
      ['ar', 'ja', 'de'].contains(locale.languageCode);
  @override
  Future<ExpressiveLocalizations> load(Locale locale) =>
      SynchronousFuture(switch (locale.languageCode) {
        'ja' => _japanese,
        'de' => _german,
        _ => _arabic,
      });
  @override
  bool shouldReload(_StintControls old) => false;
}

final _arabic = ExpressiveLocalizations(
  cancelSearch: 'إلغاء البحث',
  showSuggestions: 'عرض الاقتراحات',
  sheetDragHandle: 'مقبض السحب',
  tryAgain: 'أعد المحاولة',
  toastDismiss: 'إغلاق',
  chartEmpty: 'لا توجد بيانات بعد',
  selectDate: 'اختر التاريخ',
  selectedDate: 'التاريخ المحدد',
  date: 'التاريخ',
  quantity: 'الكمية',
  selectTime: 'اختر الوقت',
  enterTime: 'أدخل الوقت',
  hour: 'الساعة',
  minute: 'الدقيقة',
  selectHour: 'اختر الساعة',
  selectMinute: 'اختر الدقائق',
  am: 'ص',
  pm: 'م',
  period: 'صباحًا أو مساءً',
  toKeyboard: 'اكتب الوقت',
  toDial: 'اختر من الساعة',
  toScroll: 'مرّر لاختيار الوقت',
  badHour: 'أدخل ساعة صحيحة',
  badMinute: 'أدخل دقيقة صحيحة',
  increase: (s) => 'زيادة $s',
  decrease: (s) => 'تقليل $s',
  hours: (n) => '${const StintWords(StintLanguage.ar).number(n)} ساعة',
  minutes: (n) => '${const StintWords(StintLanguage.ar).number(n)} دقيقة',
  oClock: (n) => 'الساعة ${const StintWords(StintLanguage.ar).number(n)}',
);

final _japanese = ExpressiveLocalizations(
  cancelSearch: '検索をキャンセル',
  showSuggestions: '候補を表示',
  sheetDragHandle: 'ドラッグハンドル',
  tryAgain: '再試行',
  toastDismiss: '閉じる',
  chartEmpty: 'データはまだありません',
  selectDate: '日付を選択',
  selectedDate: '選択した日付',
  date: '日付',
  quantity: '数量',
  selectTime: '時刻を選択',
  enterTime: '時刻を入力',
  hour: '時',
  minute: '分',
  selectHour: '時を選択',
  selectMinute: '分を選択',
  am: '午前',
  pm: '午後',
  period: '午前または午後',
  toKeyboard: '時刻を入力',
  toDial: '文字盤から選択',
  toScroll: 'スクロールして時刻を選択',
  badHour: '正しい時を入力してください',
  badMinute: '正しい分を入力してください',
  increase: (s) => '$sを増やす',
  decrease: (s) => '$sを減らす',
  hours: (n) => '$n時間',
  minutes: (n) => '$n分',
  oClock: (n) => '$n時',
);

final _german = ExpressiveLocalizations(
  cancelSearch: 'Suche abbrechen',
  showSuggestions: 'Vorschläge anzeigen',
  sheetDragHandle: 'Ziehpunkt',
  tryAgain: 'Erneut versuchen',
  toastDismiss: 'Schließen',
  chartEmpty: 'Noch keine Daten',
  selectDate: 'Datum auswählen',
  selectedDate: 'Ausgewähltes Datum',
  date: 'Datum',
  quantity: 'Menge',
  selectTime: 'Uhrzeit auswählen',
  enterTime: 'Uhrzeit eingeben',
  hour: 'Stunde',
  minute: 'Minute',
  selectHour: 'Stunde auswählen',
  selectMinute: 'Minuten auswählen',
  am: 'AM',
  pm: 'PM',
  period: 'Vormittag oder Nachmittag',
  toKeyboard: 'Uhrzeit eintippen',
  toDial: 'Auf dem Zifferblatt wählen',
  toScroll: 'Zum Auswählen scrollen',
  badHour: 'Gib eine gültige Stunde ein',
  badMinute: 'Gib eine gültige Minute ein',
  increase: (s) => '$s erhöhen',
  decrease: (s) => '$s verringern',
  hours: (n) => n == 1 ? '1 Stunde' : '$n Stunden',
  minutes: (n) => n == 1 ? '1 Minute' : '$n Minuten',
  oClock: (n) => '$n Uhr',
);

class _Workspace extends StatefulWidget {
  const _Workspace({super.key, required this.model});
  final StintController model;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

/// Material Expressive's six presets, its default first.
final _presets = [
  ExpressiveThemeData.defaultPreset,
  ...ExpressiveThemeData.presets.where(
    (id) => id != ExpressiveThemeData.defaultPreset,
  ),
];

/// [_presets] for a host's palette menu.
final _palettes = [
  for (final id in _presets)
    StintPalette(id, ExpressiveThemeData.preset(id, Brightness.light).colors.primary),
];
