// The pickers' notes of 11-25, each measured on 0.6.3 first:
// - A picker card's stock title ("Select a time", "Select a date") is Frosted's English: in another language the card
//   shows none and is named a dialog in the reader's words (ui_core speaks no such title yet), as Cupertino's time
//   picker has no title; an app's own title shows in any language.
// - On the 12-hour clock each wheel is as wide as its widest figure or word and the three stand together at the band's
//   centre: three equal thirds put the time off the centre and a wide gap before AM and PM.
// - The date picker's card holds the weeks of the month it shows (no empty sixth row's band under a five-week month)
//   and stands at the top of the room six weeks take, so a month turning moves only its foot.
// - Today's figure is set at the days' weight, its ring marking it (as Material's today): it read bolder than the
//   chosen day's beside it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:frosted_ui/src/frosted/internal/today_ring.dart';

Future<void> _pump(
  WidgetTester t,
  Widget home, {
  Locale? locale,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final page = Material(
    type: MaterialType.transparency,
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(padding: const EdgeInsets.all(16), child: home),
    ),
  );
  await t.pumpWidget(
    locale == null
        ? MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) =>
                FrostedHost(brightness: brightness, child: child!),
            home: page,
          )
        : WidgetsApp(
            color: const Color(0xFF000000),
            locale: locale,
            supportedLocales: RawWidgetsLocalizations.supportedLocales,
            localizationsDelegates: const [
              RawWidgetsLocalizations.delegate,
              FrostedLocalizations.delegate,
            ],
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            ),
            builder: (context, child) =>
                FrostedHost(brightness: brightness, child: child!),
            home: page,
          ),
  );
  await t.pumpAndSettle();
}

Future<void> _open(
  WidgetTester t,
  void Function(BuildContext context) open, {
  Locale? locale,
}) async {
  await t.pumpWidget(const SizedBox());
  await _pump(
    t,
    Builder(
      builder: (context) =>
          FrostedButton.glass('Open', onPressed: () => open(context)),
    ),
    locale: locale,
  );
  await t.tap(find.text('Open'));
  await t.pumpAndSettle();
}

final Finder _slab = find.byWidgetPredicate(
  (w) => w is FrostedFace && w.material == FrostedMaterial.slab,
);

TextStyle? _styleOf(WidgetTester t, String text) => t
    .widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == text,
      ),
    )
    .text
    .style;

void main() {
  group('a picker card names itself in the reader\'s language', () {
    for (final (name, open, stock)
        in <(String, void Function(BuildContext), String)>[
          (
            'time',
            (context) => showFrostedTimePicker(
              context,
              initialTime: const FrostedTime(hour: 9, minute: 30),
            ),
            'Select a time',
          ),
          (
            'date',
            (context) => showFrostedDatePicker(
              context,
              initialDate: DateTime(2026, 7, 15),
              first: DateTime(2026),
              last: DateTime(2027, 12, 31),
            ),
            'Select a date',
          ),
        ]) {
      testWidgets('the $name picker in German: no English title, named a '
          'dialog', (t) async {
        final semantics = t.ensureSemantics();
        await _open(t, open, locale: const Locale('de'));
        expect(find.text(stock), findsNothing);
        final dialog = RawWidgetsLocalizations.of(t.element(_slab)).dialogLabel;
        expect(
          find.bySemanticsLabel(dialog),
          findsOneWidget,
          reason: 'the card is named "$dialog"',
        );
        semantics.dispose();
      });

      testWidgets('the $name picker in English keeps its title', (t) async {
        await _open(t, open);
        expect(find.text(stock), findsOneWidget);
      });
    }

    testWidgets('an app\'s own title shows in German', (t) async {
      await _open(
        t,
        (context) => showFrostedTimePicker(
          context,
          initialTime: const FrostedTime(hour: 9, minute: 30),
          title: 'Weckzeit',
        ),
        locale: const Locale('de'),
      );
      expect(find.text('Weckzeit'), findsOneWidget);
    });
  });

  testWidgets('on the 12-hour clock the wheels stand together at the '
      'band\'s centre, no wide gap before PM', (t) async {
    await _pump(
      t,
      FrostedTimePicker(
        value: const FrostedTime(hour: 21, minute: 5),
        onChanged: (_) {},
      ),
    );
    final minute = t.getRect(find.text('05'));
    final half = t.getRect(find.text('PM'));
    final hour = t.getRect(find.text('9'));
    final band = t.getRect(find.byType(FrostedTimePicker));
    // Each word stands in its wheel's own room (12 a side, the widest
    // figure's width): the minute's and the half day's rooms meet.
    expect(half.left - minute.right, lessThanOrEqualTo(40));
    // The time stands at the band's middle: the hour's figure as far in from
    // its start as the half day's word from its end, to the difference of
    // their widths.
    expect(
      (hour.left + half.right) / 2,
      moreOrLessEquals(band.center.dx, epsilon: 12),
    );
  });

  testWidgets('on the 24-hour clock the colon stands at the band\'s '
      'centre', (t) async {
    await _pump(
      t,
      MediaQuery(
        data: const MediaQueryData(alwaysUse24HourFormat: true),
        child: FrostedTimePicker(
          value: const FrostedTime(hour: 21, minute: 5),
          onChanged: (_) {},
        ),
      ),
    );
    final band = t.getRect(find.byType(FrostedTimePicker));
    expect(
      t.getRect(find.text(':')).center.dx,
      moreOrLessEquals(band.center.dx, epsilon: 1),
    );
  });

  testWidgets('the date card holds a five-week month\'s weeks and keeps its '
      'head where a six-week month puts it', (t) async {
    await _open(
      t,
      (context) => showFrostedDatePicker(
        context,
        initialDate: DateTime(2026, 7, 15),
        first: DateTime(2026),
        last: DateTime(2027, 12, 31),
      ),
    );
    // July 2026 spans five weeks from a Sunday or a Monday; August six.
    final july = t.getRect(_slab);
    final julyHead = t.getRect(find.text('July 2026'));
    await t.tap(
      find.byWidgetPredicate(
        (w) => w is FrostedPressable && w.semanticLabel == 'Next month',
      ),
    );
    await t.pumpAndSettle();
    final august = t.getRect(_slab);
    expect(t.getRect(find.text('August 2026')).top, julyHead.top);
    expect(august.top, july.top);
    // A week's row (the source's 44, over the floor) and the 4 under it.
    expect(august.height - july.height, moreOrLessEquals(48));
  });

  for (final (name, view) in <(String, Widget)>[
    (
      'calendar',
      FrostedCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        value: DateTime(2026, 11, 20),
        currentDate: DateTime(2026, 11, 18),
        onChanged: (_) {},
      ),
    ),
    (
      'date picker',
      FrostedDatePicker(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        value: DateTime(2026, 11, 20),
        currentDate: DateTime(2026, 11, 18),
        onChanged: (_) {},
      ),
    ),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('in the $name today\'s figure is set as the days\' are, '
          'its ring marking it (${brightness.name})', (t) async {
        await _pump(t, view, brightness: brightness);
        final today = _styleOf(t, '18')!;
        final day = _styleOf(t, '19')!;
        expect(today.color, isSameColorAs(day.color!));
        expect(today.fontWeight, day.fontWeight);
        expect(find.byType(FrostedTodayRing), findsOneWidget);
      });
    }
  }
}
