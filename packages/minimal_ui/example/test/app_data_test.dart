import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui_example/kit_gallery/apps/habits_app.dart';
import 'package:minimal_ui_example/kit_gallery/demos/screen_orders.dart';
import 'package:minimal_ui_example/kit_gallery/habits.dart';
import 'package:minimal_ui_example/kit_gallery/kit_words.dart';

Future<void> _screen(
  WidgetTester t,
  Widget home, {
  double width = 390,
  double scale = 1,
  bool arabic = false,
}) async {
  kitArabic = arabic;
  addTearDown(() => kitArabic = false);
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 844);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) => MinimalTheme(
        data: MinimalThemeData.preset('standard', Brightness.light),
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        ),
      ),
      home: home,
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _tap(WidgetTester t, Finder target) async {
  await t.ensureVisible(target);
  await t.tap(target);
  await t.pumpAndSettle();
}

void main() {
  test('CSV includes a header and escaped current habit values', () {
    final store = KitHabits();
    addTearDown(store.dispose);
    store.clear();
    final header = store.toCsv();
    expect(header.split('\r\n'), hasLength(2));
    expect(header, contains('"Favourite","Kept today"'));
    final habit = store.add(
      name: 'Walk, "slowly"',
      group: 'Morning',
      note: 'سطر\nline 2',
    );
    store.toggleFavourite(habit);
    store.toggle(habit);
    store.setPaused(habit, true);
    final csv = store.toCsv();
    expect(csv, startsWith(header));
    expect(csv, contains('"Walk, ""slowly""","Morning","سطر\nline 2"'));
    expect(csv, endsWith('"true","true","true","1"\r\n'));
    final undo = store.remove(habit);
    expect(store.toCsv(), header);
    undo();
    expect(store.toCsv(), csv);
  });

  testWidgets('a favourite belongs to its habit after leaving the detail', (
    t,
  ) async {
    await _screen(t, const KitHabitsApp(gallery: null, screen: 'habits'));
    Finder star() => find.byWidgetPredicate(
      (w) => w is MinimalIconButton && w.semanticLabel == 'Favourite',
    );
    Future<void> open(String name) => _tap(t, find.text(name).first);
    Future<void> back() => _tap(
      t,
      find.byWidgetPredicate(
        (w) => w is MinimalIconButton && w.semanticLabel == 'Back',
      ),
    );
    await open('Morning run');
    await _tap(t, star());
    expect(t.widget<MinimalIconButton>(star()).selected, isTrue);
    await back();
    await open('Meditate');
    expect(t.widget<MinimalIconButton>(star()).selected, isFalse);
    await back();
    await open('Morning run');
    expect(t.widget<MinimalIconButton>(star()).selected, isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('native export puts the same habits on the clipboard', (t) async {
    String? copied;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _screen(t, const KitHabitsApp(gallery: null, screen: 'settings'));
    await _tap(t, find.text('Copy as CSV'));
    expect(copied, contains('"HAB-4","Morning run"'));
    expect(find.text('Habits copied as CSV'), findsOneWidget);
  });

  testWidgets('an empty Today offers to create a new habit', (t) async {
    await _screen(t, const KitHabitsApp(gallery: null, screen: 'settings'));
    await _tap(t, find.text('Erase every habit'));
    await _tap(t, find.text('Erase'));
    await _tap(t, find.text('Today').last);
    expect(find.text('No habits yet'), findsOneWidget);
    expect(find.byType(MinimalSegmentBar), findsNothing);
    expect(find.text('Show all'), findsNothing);
    await _tap(t, find.text('New habit'));
    final name = find.byType(EditableText).first;
    await t.enterText(name, 'Read outside');
    await t.pumpAndSettle();
    await _tap(t, find.text('Create habit'));
    expect(find.text('Read outside'), findsOneWidget);
    expect(find.text('No habits yet'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('Bakery ranges share orders and calculate their own totals', (
    t,
  ) async {
    await _screen(t, const KitOrdersPage(), width: 1440);
    Future<void> range(String from, String to) async {
      await _tap(t, find.text(from).first);
      await _tap(t, find.text(to).last);
    }

    int openCount() => t
        .widget<MinimalFilter>(
          find.byWidgetPredicate(
            (w) => w is MinimalFilter && w.label == 'Open',
          ),
        )
        .count!;
    String revenue() => t
        .widget<MinimalStat>(
          find.byWidgetPredicate(
            (w) => w is MinimalStat && w.label == 'Revenue',
          ),
        )
        .value;
    final today = revenue();
    expect(openCount(), 6);
    expect(find.text('1047'), findsOneWidget);
    await range('Today', 'Yesterday');
    final yesterday = revenue();
    expect(yesterday, isNot(today));
    expect(openCount(), 1);
    expect(find.text('1014'), findsOneWidget);
    expect(find.text('1047'), findsNothing);
    expect(
      find.textContaining('vs last Thu', findRichText: true),
      findsOneWidget,
    );
    await range('Yesterday', 'This week');
    expect([today, yesterday], isNot(contains(revenue())));
    expect(openCount(), 7);
    expect(
      find.textContaining('vs last week', findRichText: true),
      findsOneWidget,
    );
    await _tap(t, find.text('1014'));
    await _tap(t, find.text('Mark ready'));
    expect(openCount(), 6);
    await range('This week', 'Yesterday');
    expect(openCount(), 0);
    await _tap(t, find.text('Ready').first);
    expect(find.text('1014'), findsOneWidget);
    expect(revenue(), yesterday);
    expect(t.takeException(), isNull);
  });

  for (final arabic in [false, true]) {
    testWidgets(
      'a phone detail shows the full customer name at 2x, Arabic $arabic',
      (t) async {
        await _screen(t, const KitOrdersPage(), scale: 2, arabic: arabic);
        final name = ar('Hanna Berg', 'هند البرغوثي');
        await _tap(t, find.text(name));
        final title = find.text(name);
        expect(title, findsOneWidget);
        final paragraph = t.renderObject<RenderParagraph>(title);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.size.width, lessThanOrEqualTo(390));
        expect(find.bySemanticsLabel(name), findsWidgets);
        expect(t.takeException(), isNull);
      },
    );
  }
}
