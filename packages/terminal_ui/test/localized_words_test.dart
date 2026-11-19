// The words Terminal's own parts say and write come from its
// localizations: in an Arabic or a German app, a pager, page dots, a path,
// steps, a tag, a table, a file field, a confirmation, a sheet, a refresh,
// a sparkline and the colour swatches speak that language with nothing
// English beside them, and nothing needs setting up for it. An app's own
// words still win.
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show RenderParagraph, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

const _locales = [Locale('en'), Locale('ar'), Locale('de')];

// An app in [locale] with ui_core's words and Flutter's, and none of
// Terminal's: Terminal finds its own for the locale.
Widget _host(
  Widget child, {
  required Locale locale,
  List<LocalizationsDelegate<Object>> extra = const [],
  double width = 600,
}) => MaterialApp(
  locale: locale,
  supportedLocales: _locales,
  localizationsDelegates: [
    ...extra,
    DesignLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: TermTheme.of(context).background,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

// Every label a screen reader hears, and every word painted.
List<String> _heard(WidgetTester tester) {
  final said = <String>[];
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) said.add(data.label);
    if (data.value.isNotEmpty) said.add(data.value);
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return said;
}

List<String> _painted(WidgetTester tester) => [
  for (final text in tester.widgetList<RichText>(find.byType(RichText)))
    text.text.toPlainText(),
];

// The words each language says, as a reader of it would write them.
const _words = <String, Map<String, String>>{
  'en': {
    'pages': 'pages',
    'previous': 'previous page',
    'next': 'next page',
    'page 3': 'page 3',
    'page 2 of 5': 'page 2 of 5',
    'page 2 of 4': 'page 2 of 4',
    'page 1': 'page 1',
    'path': 'path',
    'step': 'step 2 of 3, test, current',
    'remove': 'remove production',
    'select page': 'select page',
    'browse': 'browse',
    'proceed': 'proceed?',
    'proceed said': 'proceed? yes or no, no by default',
    'typed': 'type atlas-api to confirm',
    'keys': 'y yes · n no · esc',
    'cancel': 'esc cancel',
    'sparkline': 'from 3 to 9, least 3, most 9',
    'no values': 'no values',
    'red': 'red',
    'bright white': 'bright white',
    'pull': 'pull to refresh',
    'no': 'no',
    'cancel row': 'cancel',
    'no file': 'no file chosen',
    'loading': 'loading',
    'commands': 'commands',
    'command hint': 'type a command',
    'no command': 'no command matches',
    'no match': 'no match',
    'show': 'show',
    'code': 'one-time code',
    'palette keys': '↑↓ move · ⏎ run · esc close',
  },
  'ar': {
    'pages': 'الصفحات',
    'previous': 'الصفحة السابقة',
    'next': 'الصفحة التالية',
    'page 3': 'الصفحة ٣',
    'page 2 of 5': 'الصفحة ٢ من ٥',
    'page 2 of 4': 'الصفحة ٢ من ٤',
    'page 1': 'الصفحة ١',
    'path': 'المسار',
    'step': 'الخطوة ٢ من ٣، test، الحالية',
    'remove': 'إزالة production',
    'select page': 'تحديد الصفحة',
    'browse': 'استعراض',
    'proceed': 'متابعة؟',
    'proceed said': 'متابعة؟ نعم أو لا، لا افتراضيًا',
    'typed': 'اكتب atlas-api للتأكيد',
    'keys': 'y نعم · n لا · esc',
    'cancel': 'esc إلغاء',
    'sparkline': 'من 3 إلى 9، الأدنى 3، الأعلى 9',
    'no values': 'لا قيم',
    'red': 'أحمر',
    'bright white': 'أبيض فاتح',
    'pull': 'اسحب للتحديث',
    'no': 'لا',
    'cancel row': 'إلغاء',
    'no file': 'لم يُختر أي ملف',
    'loading': 'جارٍ التحميل',
    'commands': 'الأوامر',
    'command hint': 'اكتب أمرًا',
    'no command': 'لا يطابقها أي أمر',
    'no match': 'لا تطابق',
    'show': 'إظهار',
    'code': 'رمز لمرة واحدة',
    'palette keys': '↑↓ تنقّل · ⏎ تشغيل · esc إغلاق',
  },
  'de': {
    'pages': 'Seiten',
    'previous': 'vorherige Seite',
    'next': 'nächste Seite',
    'page 3': 'Seite 3',
    'page 2 of 5': 'Seite 2 von 5',
    'page 2 of 4': 'Seite 2 von 4',
    'page 1': 'Seite 1',
    'path': 'Pfad',
    'step': 'Schritt 2 von 3, test, aktuell',
    'remove': 'production entfernen',
    'select page': 'Seite auswählen',
    'browse': 'durchsuchen',
    'proceed': 'fortfahren?',
    'proceed said': 'fortfahren? ja oder nein, standardmäßig nein',
    'typed': 'atlas-api eingeben, um zu bestätigen',
    'keys': 'y ja · n nein · esc',
    'cancel': 'esc abbrechen',
    'sparkline': 'von 3 bis 9, Minimum 3, Maximum 9',
    'no values': 'keine Werte',
    'red': 'Rot',
    'bright white': 'helles Weiß',
    'pull': 'zum Aktualisieren ziehen',
    'no': 'nein',
    'cancel row': 'abbrechen',
    'no file': 'keine Datei ausgewählt',
    'loading': 'wird geladen',
    'commands': 'Befehle',
    'command hint': 'Befehl eingeben',
    'no command': 'kein passender Befehl',
    'no match': 'kein Treffer',
    'show': 'anzeigen',
    'code': 'Einmalcode',
    'palette keys': '↑↓ bewegen · ⏎ ausführen · esc schließen',
  },
};

// English words that only Terminal's defaults say: none may be heard or
// painted in another language.
const _english = [
  'page',
  'path',
  'step',
  'remove',
  'select',
  'browse',
  'proceed',
  'type ',
  'confirm',
  ' yes',
  'cancel',
  'least',
  'values',
  'bright',
  'refresh',
];

// The parts, each with what it should say: a word heard (`said`), painted
// (`shows`), or both.
typedef _Case = ({
  String name,
  Widget Function() build,
  List<String> said,
  List<String> shows,
  double width,
});

List<_Case> _cases() {
  _Case c(
    String name,
    Widget Function() build, {
    List<String> said = const [],
    List<String> shows = const [],
    double width = 600,
  }) => (name: name, build: build, said: said, shows: shows, width: width);
  return [
    c(
      'a pager',
      () => TermPagination(page: 2, pageCount: 5, onChanged: (_) {}),
      said: ['pages', 'previous', 'next', 'page 3'],
    ),
    c(
      'a pager too narrow for its numbers',
      () => TermPagination(page: 2, pageCount: 5, onChanged: (_) {}),
      said: ['page 2 of 5'],
      width: 120,
    ),
    c(
      'page dots',
      () => TermPageDots(count: 4, index: 1, onChanged: (_) {}),
      said: ['page 2 of 4', 'page 1'],
    ),
    c(
      'a path',
      () => TermBreadcrumb(
        crumbs: [
          (label: '~', onPressed: () {}),
          (label: 'atlas-api', onPressed: null),
        ],
      ),
      said: ['path'],
    ),
    c(
      'steps',
      () => const TermSteps(
        steps: [
          (label: 'source', state: TermStepState.done),
          (label: 'test', state: TermStepState.current),
          (label: 'deploy', state: TermStepState.upcoming),
        ],
      ),
      said: ['step'],
    ),
    c(
      'a tag that can go',
      () => TermTag(label: 'production', onDeleted: () {}),
      said: ['remove'],
    ),
    c('a table', () => const _Table(), said: ['select page']),
    c(
      'a file field',
      () => TermFileField(files: const [], onBrowse: () {}),
      shows: ['browse', 'no file'],
    ),
    c(
      'a confirmation',
      () => TermConfirmDialog(
        title: 'deploy',
        message: 'atlas-api goes to production.',
        confirmLabel: 'deploy',
        onConfirm: () {},
        onCancel: () {},
      ),
      said: ['proceed said', 'keys', 'no'],
      shows: ['proceed', 'keys', 'no'],
    ),
    c(
      'a typed confirmation',
      () => TermConfirmDialog(
        title: 'delete project',
        message: 'atlas-api and its runs go for good.',
        confirmLabel: 'delete',
        typedConfirmation: 'atlas-api',
        isDestructiveAction: true,
        onConfirm: () {},
        onCancel: () {},
      ),
      shows: ['typed', 'cancel'],
    ),
    c(
      'an action sheet',
      () => const TermActionSheet<int>(
        title: 'run #1482',
        actions: [TermSheetAction(label: 'rerun', value: 1)],
      ),
      shows: ['cancel', 'cancel row'],
    ),
    c(
      'a sparkline',
      () => const TermSparkline(values: [3, 5, 4, 8, 6, 9]),
      said: ['sparkline'],
    ),
    c(
      'an empty sparkline',
      () => const TermSparkline(values: []),
      said: ['no values'],
    ),
    c('a skeleton', () => const TermSkeleton(), said: ['loading']),
    c('a password field', () => const _Password(), shows: ['show']),
    c('a one-time code', () => const TermOtpField(), said: ['code']),
    c(
      'a command palette',
      () => TermCommandPalette(
        commands: [DesignCommand(label: 'rerun', onPressed: () {})],
      ),
      said: ['commands'],
      shows: ['commands', 'command hint', 'palette keys'],
    ),
    c(
      'the colour swatches',
      () => const _Colours(),
      said: ['red', 'bright white'],
    ),
  ];
}

class _Table extends StatefulWidget {
  const _Table();

  @override
  State<_Table> createState() => _TableState();
}

class _TableState extends State<_Table> {
  final _table = DesignTableController<Map<String, String>>(
    rows: const [
      {'id': '1482', 'took': '2m 14s'},
    ],
    columns: const [
      DesignTableColumn(id: 'id', label: 'run'),
      DesignTableColumn(id: 'took', label: 'took'),
    ],
  );

  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TermDataTable<Map<String, String>>(
    controller: _table,
    widths: const {'id': 6, 'took': 7},
    cellBuilder: (context, run, column) => Text(run[column.id] ?? ''),
  );
}

class _Password extends StatefulWidget {
  const _Password();

  @override
  State<_Password> createState() => _PasswordState();
}

class _PasswordState extends State<_Password> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TermPasswordField(controller: _text, labelText: 'token');
}

class _Colours extends StatefulWidget {
  const _Colours();

  @override
  State<_Colours> createState() => _ColoursState();
}

class _ColoursState extends State<_Colours> {
  final _colour = DesignColorController();

  @override
  void dispose() {
    _colour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TermColorPicker(controller: _colour);
}

void main() {
  for (final locale in _locales) {
    final words = _words[locale.languageCode]!;
    for (final part in _cases()) {
      testWidgets(
        '${locale.languageCode}: ${part.name} speaks the reader\'s words',
        (tester) async {
          final semantics = tester.ensureSemantics();
          tester.view.physicalSize = const Size(800, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _host(part.build(), locale: locale, width: part.width),
          );
          await tester.pumpAndSettle();
          final heard = _heard(tester);
          final painted = _painted(tester);
          for (final key in part.said) {
            expect(
              heard.any((s) => s.contains(words[key]!)),
              isTrue,
              reason: '"${words[key]}" heard, in $heard',
            );
          }
          for (final key in part.shows) {
            expect(
              painted.any((s) => s.contains(words[key]!)),
              isTrue,
              reason: '"${words[key]}" painted, in $painted',
            );
          }
          if (locale.languageCode != 'en') {
            for (final english in _english) {
              final stray = [
                ...heard,
                ...painted,
              ].where((s) => s.toLowerCase().contains(english));
              // The app's own words (its labels, its values) aside, and
              // ui_core's colour area value, which ui_core says in English
              // (ui_core 0.3.1 and 0.3.2).
              final ours = stray.where(
                (s) => !const [
                  'production',
                  'deploy',
                  'delete',
                  'atlas-api',
                  'rerun',
                  'saturation ',
                ].any(s.contains),
              );
              expect(ours, isEmpty, reason: '"$english" in $ours');
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
          semantics.dispose();
        },
        // A pointer's platform, where the keys a dialog takes show.
        variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      );
    }
  }

  testWidgets('a pull to refresh says what a pull does in the reader\'s '
      'words', (tester) async {
    for (final locale in _locales) {
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 400,
            child: TermPullToRefresh(
              onRefresh: () async {},
              child: ListView(
                children: [for (var i = 0; i < 30; i++) Text('run $i')],
              ),
            ),
          ),
          locale: locale,
        ),
      );
      final pull = await tester.startGesture(
        tester.getCenter(find.text('run 2')),
      );
      await pull.moveBy(const Offset(0, 24));
      await tester.pump();
      expect(
        find.text(_words[locale.languageCode]!['pull']!),
        findsOneWidget,
        reason: locale.languageCode,
      );
      await pull.cancel();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  for (final locale in _locales) {
    final words = _words[locale.languageCode]!;
    testWidgets('${locale.languageCode}: a search that matches nothing says '
        'so in the reader\'s words', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              TermCommandPalette(
                commands: [DesignCommand(label: 'rerun', onPressed: () {})],
              ),
              const TermCombobox<String>(options: ['staging', 'production']),
            ],
          ),
          locale: locale,
        ),
      );
      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), 'zzz');
      await tester.enterText(fields.at(1), 'zzz');
      await tester.pumpAndSettle();
      final painted = _painted(tester);
      expect(
        painted.any((s) => s.contains('${words['no command']}: "zzz"')),
        isTrue,
        reason: '$painted',
      );
      expect(
        painted.any((s) => s.contains(words['no match']!)),
        isTrue,
        reason: '$painted',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('an Arabic line of keys reads right to left: each key to the '
      'right of its word', (tester) async {
    await tester.pumpWidget(
      _host(
        TermConfirmDialog(
          title: 'deploy',
          message: 'atlas-api',
          confirmLabel: 'deploy',
          onConfirm: () {},
          onCancel: () {},
        ),
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    final keys = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('نعم ·'),
    );
    expect(keys, findsOneWidget);
    final line = tester.renderObject<RenderParagraph>(keys);
    final text = line.text.toPlainText();
    double leftOf(String part) => line
        .getBoxesForSelection(
          TextSelection(
            baseOffset: text.indexOf(part),
            extentOffset: text.indexOf(part) + part.length,
          ),
        )
        .first
        .left;
    expect(leftOf('y'), greaterThan(leftOf('نعم')));
    expect(leftOf('نعم'), greaterThan(leftOf('esc')));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  test('Terminal speaks English, Arabic and German, and English else', () {
    expect(TermLocalizations.supportedLocales, _locales);
    expect(
      TermLocalizations.forLocale(const Locale('fr')).breadcrumbLabel,
      'path',
    );
    expect(TermLocalizations.forLocale(null).breadcrumbLabel, 'path');
    expect(
      TermLocalizations.forLocale(const Locale('ar', 'EG')).breadcrumbLabel,
      'المسار',
    );
    expect(
      TermLocalizations.forLocale(const Locale('de', 'AT')).breadcrumbLabel,
      'Pfad',
    );
    expect(
      () => const DefaultTermLocalizations().paletteColorName(16),
      throwsRangeError,
    );
  });

  test('Arabic counts people in its six forms, German in its two', () {
    final ar = TermLocalizations.forLocale(const Locale('ar'));
    List<String> names(int n) => [for (var i = 0; i < n; i++) 'n$i'];
    String count(TermLocalizations l, int n) =>
        l.avatarGroupLabel(names(n)).split(':').first;
    expect(count(ar, 1), 'شخص واحد');
    expect(count(ar, 2), 'شخصان');
    expect(count(ar, 3), '٣ أشخاص');
    expect(count(ar, 10), '١٠ أشخاص');
    expect(count(ar, 11), '١١ شخصًا');
    expect(count(ar, 99), '٩٩ شخصًا');
    expect(count(ar, 100), '١٠٠ شخص');
    expect(count(ar, 103), '١٠٣ أشخاص');
    expect(ar.avatarGroupLabel(const ['Ada', 'Alan']), 'شخصان: Ada، Alan');
    final de = TermLocalizations.forLocale(const Locale('de'));
    expect(count(de, 1), '1 Person');
    expect(count(de, 2), '2 Personen');
  });

  testWidgets('the delegate loads the same words, and an app\'s own win', (
    tester,
  ) async {
    late TermLocalizations seen;
    Widget probe() => Builder(
      builder: (context) {
        seen = TermLocalizations.of(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      _host(
        probe(),
        locale: const Locale('de'),
        extra: const [TermLocalizations.delegate],
      ),
    );
    expect(seen.breadcrumbLabel, 'Pfad');
    await tester.pumpWidget(
      _host(
        probe(),
        locale: const Locale('de'),
        extra: const [_OwnWords.delegate],
      ),
    );
    expect(seen.breadcrumbLabel, 'Verzeichnis');
    expect(seen.browseLabel, 'browse');
  });

  testWidgets('a part keeps the words an app gives it', (tester) async {
    await tester.pumpWidget(
      _host(
        TermFileField(files: const [], onBrowse: () {}, hintText: 'nichts da'),
        locale: const Locale('de'),
      ),
    );
    expect(find.text('nichts da'), findsOneWidget);
    expect(find.text('keine Datei ausgewählt'), findsNothing);
  });
}

// An app's own words: a subclass of the English ones and a delegate for it.
class _OwnWords extends DefaultTermLocalizations {
  const _OwnWords();

  static const delegate = _OwnWordsDelegate();

  @override
  String get breadcrumbLabel => 'Verzeichnis';
}

class _OwnWordsDelegate extends LocalizationsDelegate<TermLocalizations> {
  const _OwnWordsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<TermLocalizations> load(Locale locale) =>
      SynchronousFuture<TermLocalizations>(const _OwnWords());

  @override
  bool shouldReload(_OwnWordsDelegate old) => false;
}
