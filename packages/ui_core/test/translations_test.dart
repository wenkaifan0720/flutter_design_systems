import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/localizations_data.dart';

// Each message's DesignLocalizations member, by its name in the tables, with
// the values a test fills its placeholders with.
final Map<String, String Function(DesignLocalizations l)> _words = {
  'cancelButtonLabel': (l) => l.cancelButtonLabel,
  'okButtonLabel': (l) => l.okButtonLabel,
  'closeButtonLabel': (l) => l.closeButtonLabel,
  'clearButtonTooltip': (l) => l.clearButtonTooltip,
  'backButtonTooltip': (l) => l.backButtonTooltip,
  'deleteButtonTooltip': (l) => l.deleteButtonTooltip,
  'moreButtonTooltip': (l) => l.moreButtonTooltip,
  'showMenuTooltip': (l) => l.showMenuTooltip,
  'searchFieldLabel': (l) => l.searchFieldLabel,
  'modalBarrierDismissLabel': (l) => l.modalBarrierDismissLabel,
  'currentDateLabel': (l) => l.currentDateLabel,
  'previousMonthTooltip': (l) => l.previousMonthTooltip,
  'nextMonthTooltip': (l) => l.nextMonthTooltip,
  'previousPageTooltip': (l) => l.previousPageTooltip,
  'nextPageTooltip': (l) => l.nextPageTooltip,
  'collapsedIconTapHint': (l) => l.collapsedIconTapHint,
  'expandedIconTapHint': (l) => l.expandedIconTapHint,
  'showMoreLabel': (l) => l.showMoreLabel,
  'showLessLabel': (l) => l.showLessLabel,
  'selectedLabel': (l) => l.selectedLabel,
  'loadingLabel': (l) => l.loadingLabel,
  'noResultsLabel': (l) => l.noResultsLabel,
  'retryButtonLabel': (l) => l.retryButtonLabel,
  'doneButtonLabel': (l) => l.doneButtonLabel,
  'confirmButtonLabel': (l) => l.confirmButtonLabel,
  'positionLabel': (l) => l.positionLabel(2, 5),
  'carouselLabel': (l) => l.carouselLabel,
  'carouselSlideLabel': (l) => l.carouselSlideLabel(1, 5),
  'colorAreaLabel': (l) => l.colorAreaLabel,
  'colorChannelHue': (l) => l.colorChannelLabel(DesignColorChannel.hue),
  'colorChannelSaturation': (l) =>
      l.colorChannelLabel(DesignColorChannel.saturation),
  'colorChannelBrightness': (l) =>
      l.colorChannelLabel(DesignColorChannel.brightness),
  'colorChannelAlpha': (l) => l.colorChannelLabel(DesignColorChannel.alpha),
  'commandPaletteLabel': (l) => l.commandPaletteLabel,
  'commandPaletteBarrierLabel': (l) => l.commandPaletteBarrierLabel,
  'sortedAscendingHint': (l) =>
      l.dataTableSortedHint(DesignSortDirection.ascending),
  'sortedDescendingHint': (l) =>
      l.dataTableSortedHint(DesignSortDirection.descending),
  'requiredHint': (l) => l.requiredHint,
  'showPasswordLabel': (l) => l.showPasswordLabel,
  'hidePasswordLabel': (l) => l.hidePasswordLabel,
  'menuBarLabel': (l) => l.menuBarLabel,
  'refreshLabel': (l) => l.refreshLabel,
  'refreshingMessage': (l) => l.refreshingMessage,
  'refreshedMessage': (l) => l.refreshedMessage,
  'rangeSliderStartLabel': (l) => l.rangeSliderStartLabel,
  'rangeSliderEndLabel': (l) => l.rangeSliderEndLabel,
  'reorderableListMovedMessage': (l) =>
      l.reorderableListMovedMessage('Milk', 2, 5),
  'sideSheetBarrierLabel': (l) => l.sideSheetBarrierLabel,
  'splitButtonMenuLabel': (l) => l.splitButtonMenuLabel,
  'splitViewHandleLabel': (l) => l.splitViewHandleLabel,
  'tagInputDeleteLabel': (l) => l.tagInputDeleteLabel,
  'toasterRegionLabel': (l) => l.toasterRegionLabel,
  'treeLevelHint': (l) => l.treeLevelHint(3, 2, 5),
  // 0.3.0 overlays: a shortcut's keys (designShortcutKeys).
  'keyboardKeyAlt': (l) => l.keyboardKeyAlt,
  'keyboardKeyControl': (l) => l.keyboardKeyControl,
  'keyboardKeyShift': (l) => l.keyboardKeyShift,
  'keyboardKeyMeta': (l) => l.keyboardKeyMeta,
  'keyboardKeyMetaWindows': (l) => l.keyboardKeyMetaWindows,
  'keyboardKeyMetaMacOs': (l) => l.keyboardKeyMetaMacOs,
  'keyboardKeyBackspace': (l) => l.keyboardKeyBackspace,
  'keyboardKeyDelete': (l) => l.keyboardKeyDelete,
  'keyboardKeyEnd': (l) => l.keyboardKeyEnd,
  'keyboardKeyEscape': (l) => l.keyboardKeyEscape,
  'keyboardKeyHome': (l) => l.keyboardKeyHome,
  'keyboardKeyInsert': (l) => l.keyboardKeyInsert,
  'keyboardKeyPageDown': (l) => l.keyboardKeyPageDown,
  'keyboardKeyPageUp': (l) => l.keyboardKeyPageUp,
  'keyboardKeySpace': (l) => l.keyboardKeySpace,
  'keyboardKeyOption': (l) => l.keyboardKeyOption,
  'keyboardKeyEnter': (l) => l.keyboardKeyEnter,
  'keyboardKeyTab': (l) => l.keyboardKeyTab,
  // 0.3.0 overlays: a search that failed (DesignCombobox.errorBuilder).
  'searchFailedMessage': (l) => l.searchFailedMessage,
  // 0.3.0 routes
  'alertDialogLabel': (l) => l.alertDialogLabel,
  'bottomSheetLabel': (l) => l.bottomSheetLabel,
  'dialogLabel': (l) => l.dialogLabel,
  'drawerLabel': (l) => l.drawerLabel,
  'dragHandleLabel': (l) => l.dragHandleLabel,
  'tabLabel': (l) => l.tabLabel(tabIndex: 2, tabCount: 5),
  // 0.3.0 routes end
  ..._valueWords,
};

// 0.3.0 values
final Map<String, String Function(DesignLocalizations l)> _valueWords = {
  'anteMeridiemAbbreviation': (l) => l.anteMeridiemAbbreviation,
  'postMeridiemAbbreviation': (l) => l.postMeridiemAbbreviation,
  'timePickerHourLabel': (l) => l.timePickerHourLabel,
  'timePickerMinuteLabel': (l) => l.timePickerMinuteLabel,
  'dateFieldYearLabel': (l) => l.dateFieldYearLabel,
  'dateFieldMonthLabel': (l) => l.dateFieldMonthLabel,
  'dateFieldDayLabel': (l) => l.dateFieldDayLabel,
  'timeFieldSecondLabel': (l) => l.timeFieldSecondLabel,
  'timeFieldDayPeriodLabel': (l) => l.timeFieldDayPeriodLabel,
  'dateFieldYearPlaceholder': (l) => l.dateFieldYearPlaceholder,
  'dateFieldMonthPlaceholder': (l) => l.dateFieldMonthPlaceholder,
  'dateFieldDayPlaceholder': (l) => l.dateFieldDayPlaceholder,
  'dateOutOfRangeLabel': (l) => l.dateOutOfRangeLabel,
  'emptyValueLabel': (l) => l.emptyValueLabel,
  'ratingLabel': (l) => l.ratingLabel,
  'ratingValueLabel': (l) => l.ratingValueLabel(3, 5),
  'chartRangeLabel': (l) => l.chartRangeLabel('1', '9'),
  'chartExtremesLabel': (l) => l.chartExtremesLabel('2', '8'),
  'chartPointLabel': (l) => l.chartPointLabel('3', 'Milk', '4'),
  'chartShowTableLabel': (l) => l.chartShowTableLabel,
  'listSeparator': (l) => l.listSeparator,
};

// Words a right-to-left locale writes in Latin letters, as Flutter's
// Material translations do (its AM and PM, its date hint's letters) or as
// the language punctuates.
const Map<String, Set<String>> _latinInRtl = {
  'ar': {
    'dateFieldYearPlaceholder',
    'dateFieldMonthPlaceholder',
    'dateFieldDayPlaceholder',
  },
  'he': {
    'anteMeridiemAbbreviation',
    'postMeridiemAbbreviation',
    'dateFieldYearPlaceholder',
    'dateFieldMonthPlaceholder',
    'dateFieldDayPlaceholder',
    'chartPointLabel',
    'listSeparator',
  },
  'ur': {
    'anteMeridiemAbbreviation',
    'postMeridiemAbbreviation',
    'dateFieldYearPlaceholder',
    'dateFieldMonthPlaceholder',
    'dateFieldDayPlaceholder',
  },
};
// 0.3.0 values end
const _filled = {
  'position': 2,
  'count': 5,
  'slide': 2,
  'label': 'Milk',
  'level': 3,
  // 0.3.0 routes
  'tabIndex': 2,
  'tabCount': 5,
  // 0.3.0 routes end
  // 0.3.0 values
  'value': 3,
  'from': '1',
  'to': '9',
  'lowest': '2',
  'highest': '8',
  'x': '3',
  'series': 'Milk',
  'y': '4',
};
final Map<String, String Function(DesignLocalizations l, int n)> _counted = {
  'selectedRowCountTitle': (l, n) => l.selectedRowCountTitle(n),
  'commandPaletteResultsMessage': (l, n) => l.commandPaletteResultsMessage(n),
  'formProblemsMessage': (l, n) => l.formProblemsMessage(n),
  // 0.3.0 values
  'chartSeriesCountLabel': (l, n) => l.chartSeriesCountLabel(n),
  'chartPointCountLabel': (l, n) => l.chartPointCountLabel(n),
  'chartSliceCountLabel': (l, n) => l.chartSliceCountLabel(n),
};

String _key(Locale l) => l.countryCode == null
    ? l.languageCode
    : '${l.languageCode}_${l.countryCode}';

// A table's template with its placeholders filled and its digits ASCII.
String _fill(String template, Map<String, Object> values) =>
    template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => '${values[m[1]]}');

String _ascii(String s, String? zero) => zero == null
    ? s
    : String.fromCharCodes(
        s.runes.map((c) {
          final d = c - zero.runes.single;
          return d >= 0 && d <= 9 ? 0x30 + d : c;
        }),
      );

// The code points of the scripts written right to left.
bool _rtl(int c) =>
    (c >= 0x0590 && c <= 0x08FF) || (c >= 0xFB1D && c <= 0xFEFC);

void main() {
  test('supportedLocales are the 30 the tables hold', () {
    expect(DesignLocalizations.supportedLocales, hasLength(30));
    expect(
      DesignLocalizations.supportedLocales.map(_key).toSet(),
      designLocaleData.keys.toSet(),
    );
  });

  test('every locale says every message from its table, filled, in its '
      'digits', () {
    for (final locale in DesignLocalizations.supportedLocales) {
      if (locale.languageCode == 'en') continue;
      final data = designLocaleData[_key(locale)]!;
      final l = DesignLocalizations.forLocale(locale);
      expect(
        l.runtimeType,
        isNot(DefaultDesignLocalizations),
        reason: '$locale',
      );
      expect(
        data.words.keys.toSet(),
        _words.keys.toSet(),
        reason: '$locale: a table word no member says, or the reverse',
      );
      for (final MapEntry(:key, :value) in _words.entries) {
        expect(
          _ascii(value(l), data.zeroDigit),
          _fill(data.words[key]!, _filled),
          reason: '$locale $key',
        );
      }
      expect(data.plurals.keys.toSet(), _counted.keys.toSet());
    }
  });

  test('English: the template ARB says what DefaultDesignLocalizations '
      'says', () {
    const en = DefaultDesignLocalizations();
    final data = designLocaleData['en']!;
    for (final MapEntry(:key, :value) in _words.entries) {
      expect(value(en), _fill(data.words[key]!, _filled), reason: key);
    }
    for (final MapEntry(:key, :value) in _counted.entries) {
      final forms = data.plurals[key]!;
      for (final n in [0, 1, 2, 7]) {
        final form = forms['=$n'] ?? forms[n == 1 ? 'one' : 'other']!;
        expect(value(en, n), _fill(form, {'count': n}), reason: '$key $n');
      }
    }
    expect(
      DesignLocalizations.forLocale(const Locale('en', 'GB')),
      isA<DefaultDesignLocalizations>(),
    );
  });

  test('counted messages take the form for the exact count, else the '
      'count\'s plural category', () {
    String results(String locale, int n) =>
        DesignLocalizations.forLocale(Locale(locale))
            .commandPaletteResultsMessage(n);
    String problems(String locale, int n) =>
        DesignLocalizations.forLocale(Locale(locale)).formProblemsMessage(n);

    expect([1, 2, 5, 11, 21, 22, 112].map((n) => results('ru', n)), [
      '1 результат',
      '2 результата',
      '5 результатов',
      '11 результатов',
      '21 результат',
      '22 результата',
      '112 результатов',
    ]);
    expect([1, 2, 5, 12, 22].map((n) => problems('pl', n)), [
      '1 pole wymaga uwagi',
      '2 pola wymagają uwagi',
      '5 pól wymaga uwagi',
      '12 pól wymaga uwagi',
      '22 pola wymagają uwagi',
    ]);
    expect([1, 3, 5].map((n) => problems('cs', n)), [
      '1 pole vyžaduje pozornost',
      '3 pole vyžadují pozornost',
      '5 polí vyžaduje pozornost',
    ]);
    // Arabic's six forms, in Arabic-Indic digits.
    expect([0, 1, 2, 3, 11, 100].map((n) => results('ar', n)), [
      'لا توجد نتائج',
      'نتيجة واحدة',
      'نتيجتان',
      '٣ نتائج',
      '١١ نتيجة',
      '١٠٠ نتيجة',
    ]);
    expect([1, 2, 3].map((n) => problems('he', n)), [
      'שדה אחד דורש תשומת לב',
      'שני שדות דורשים תשומת לב',
      '3 שדות דורשים תשומת לב',
    ]);
    // French counts 0 and 1 alike, after an exact 0.
    expect([0, 1, 2].map((n) => results('fr', n)), [
      'Aucun résultat',
      '1 résultat',
      '2 résultats',
    ]);
    expect([1, 2, 20].map((n) => problems('ro', n)), [
      'Un câmp necesită atenție',
      '2 câmpuri necesită atenție',
      '20 de câmpuri necesită atenție',
    ]);
    expect(results('ja', 3), '3 件の結果');
    // Flutter's Material words, with its Zero and One as exact counts.
    final de = DesignLocalizations.forLocale(const Locale('de'));
    expect([0, 1, 3].map(de.selectedRowCountTitle), [
      'Keine Objekte ausgewählt',
      // Flutter's German keeps a count on its noun's line.
      '1\u00A0Element ausgewählt',
      '3\u00A0Elemente ausgewählt',
    ]);
  });

  test('placeholders take their values, a slide counted from 1, numbers in '
      'the locale\'s digits', () {
    DesignLocalizations l(String language) =>
        DesignLocalizations.forLocale(Locale(language));
    expect(l('de').carouselSlideLabel(0, 3), 'Folie 1 von 3');
    expect(
      l('ja').reorderableListMovedMessage('牛乳', 2, 5),
      '牛乳 を 5 件中 2 番目に移動しました',
    );
    expect(l('fa').treeLevelHint(2, 1, 4), 'سطح ۲، ۱ از ۴');
    expect(l('bn').positionLabel(2, 5), '৫-এর মধ্যে ২');
    expect(l('ar').positionLabel(12, 30), '١٢ من ٣٠');
    expect(l('hi').positionLabel(2, 5), '5 में से 2');
  });

  test('dates: each locale\'s names, patterns, digits and first day', () {
    DesignLocalizations l(Locale locale) =>
        DesignLocalizations.forLocale(locale);
    final monday = DateTime(2025, 3, 3);
    final december = DateTime(2025, 12);
    expect(
      l(const Locale('de')).formatFullDate(monday),
      'Montag, 3. März 2025',
    );
    expect(l(const Locale('de')).formatMonthYear(december), 'Dezember 2025');
    expect(
      l(const Locale('es')).formatFullDate(monday),
      'lunes, 3 de marzo de 2025',
    );
    expect(l(const Locale('ja')).formatFullDate(monday), '2025年3月3日月曜日');
    expect(l(const Locale('ja')).formatMonthYear(december), '2025年12月');
    // Russian's month in a date takes the genitive, on its own the nominative;
    // CLDR keeps its year and its “г.” together (a narrow no-break space).
    expect(
      l(const Locale('ru')).formatFullDate(monday),
      'понедельник, 3 марта 2025\u202Fг.',
    );
    expect(
      l(const Locale('ru')).formatMonthYear(december),
      'декабрь 2025\u202Fг.',
    );
    expect(
      l(const Locale('ar')).formatFullDate(monday),
      'الاثنين، ٣ مارس ٢٠٢٥',
    );
    expect(l(const Locale('fa')).formatMonthYear(december), 'دسامبر ۲۰۲۵');

    expect(l(const Locale('de')).firstDayOfWeek, DateTime.monday);
    expect(l(const Locale('ar')).firstDayOfWeek, DateTime.saturday);
    expect(l(const Locale('he')).firstDayOfWeek, DateTime.sunday);
    expect(
      [
        for (var d = 1; d <= 7; d++)
          l(const Locale('de')).formatShortWeekday(d),
      ],
      ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
    );
    expect(
      [
        for (var d = 1; d <= 7; d++)
          l(const Locale('fr')).formatShortWeekday(d),
      ],
      ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'],
    );
    // Arabic's short names are whole words; a month's columns take one letter.
    expect(l(const Locale('ar')).formatShortWeekday(DateTime.saturday), 'س');
    // Every locale names all seven days, distinctly where its names allow.
    for (final locale in DesignLocalizations.supportedLocales) {
      final days = [
        for (var d = 1; d <= 7; d++) l(locale).formatShortWeekday(d),
      ];
      expect(days.every((d) => d.isNotEmpty), isTrue, reason: '$locale');
      expect(days.toSet().length, greaterThanOrEqualTo(5), reason: '$locale');
    }
  });

  test('a locale finds its language: Traditional Chinese by script or '
      'region, the older codes, English for the rest', () {
    String handle(Locale l) =>
        DesignLocalizations.forLocale(l).splitViewHandleLabel;
    expect(handle(const Locale('zh')), '调整大小');
    expect(handle(const Locale('zh', 'CN')), '调整大小');
    expect(handle(const Locale('zh', 'TW')), '調整大小');
    expect(handle(const Locale('zh', 'HK')), '調整大小');
    expect(
      handle(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
      '調整大小',
    );
    expect(handle(const Locale('iw')), handle(const Locale('he')));
    expect(handle(const Locale('in')), handle(const Locale('id')));
    expect(handle(const Locale('tl')), handle(const Locale('fil')));
    expect(handle(const Locale('pt', 'BR')), 'Redimensionar');
    expect(
      DesignLocalizations.forLocale(const Locale('sw')),
      isA<DefaultDesignLocalizations>(),
    );
    expect(handle(const Locale('sw')), 'Resize');
  });

  test('the delegate takes every locale, loads its words at once and never '
      'reloads', () async {
    const delegate = DesignLocalizations.delegate;
    expect(delegate.isSupported(const Locale('sw')), isTrue);
    expect(delegate.isSupported(const Locale('ko')), isTrue);
    expect((await delegate.load(const Locale('ko'))).cancelButtonLabel, '취소');
    expect(
      await delegate.load(const Locale('sw')),
      isA<DefaultDesignLocalizations>(),
    );
    expect(delegate.shouldReload(delegate), isFalse);
    expect(delegate.toString(), 'DesignLocalizations.delegate(30 locales)');
  });

  for (final language in ['ar', 'fa', 'ur', 'he']) {
    testWidgets('$language: written right to left, and a behaviour says it '
        'in a right-to-left app', (tester) async {
      final l = DesignLocalizations.forLocale(Locale(language));
      for (final MapEntry(:key, :value) in _words.entries) {
        if (_latinInRtl[language]?.contains(key) ?? false) continue;
        // Every message is in its script (Milk, a label, aside).
        // Key caps' names stay in Latin letters, as Material's own
        // translations keep them (Alt, Ctrl, Shift).
        if (key.startsWith('keyboardKey')) continue;
        final text = value(l).replaceAll('Milk', '');
        expect(text.runes.any(_rtl), isTrue, reason: '$language $key: $text');
      }
      final semantics = tester.ensureSemantics();
      late TextDirection direction;
      await tester.pumpWidget(
        Localizations(
          locale: Locale(language),
          delegates: const [
            DesignLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                direction = Directionality.of(context);
                return SizedBox(
                  width: 400,
                  height: 200,
                  child: DesignSplitView(
                    first: const SizedBox.expand(),
                    second: const SizedBox.expand(),
                    dividerBuilder: (context, states, axis) =>
                        const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(direction, TextDirection.rtl);
      expect(find.bySemanticsLabel(l.splitViewHandleLabel), findsOneWidget);
      expect(find.bySemanticsLabel('Resize'), findsNothing);
      semantics.dispose();
    });
  }
}
