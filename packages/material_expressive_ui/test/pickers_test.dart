/// Pickers: Compose's `DatePicker`, `DateRangePicker`, the docked picker,
/// `DatePickerDialog`, `TimePicker`, `TimeInput`, `TimeScroll` and
/// `ScrollField` — geometry and colours from the tokens, selection and
/// validation, the dialogs' draft-and-confirm, and the Cody v2 calendar
/// tests ported (decision F14).
library;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'support/brand_shapes.dart';

import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/date_picker_modal_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/time_picker_tokens.g.dart';

import 'support/pressable.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

Widget host(WidgetBuilder builder, {double scale = 1}) => MaterialApp(
  builder: (context, app) =>
      ExpressiveHost(light: bloom, brightness: Brightness.light, child: app!),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: builder(context),
          ),
        ),
      ),
    ),
  ),
);

final DateTime today = DateTime(2026, 9, 1);

/// A picker holding its own selection, reporting each change.
class Held extends StatefulWidget {
  const Held({
    required this.initial,
    this.firstDate,
    this.lastDate,
    this.mode = ExpressiveDatePickerMode.picker,
    this.onChanged,
    super.key,
  });

  final DateTime? initial;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ExpressiveDatePickerMode mode;
  final ValueChanged<DateTime>? onChanged;

  @override
  State<Held> createState() => _HeldState();
}

class _HeldState extends State<Held> {
  late DateTime? _day = widget.initial;

  @override
  Widget build(BuildContext context) => ExpressiveDatePicker(
    selected: _day,
    currentDate: today,
    initialMonth: widget.initial ?? today,
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    initialMode: widget.mode,
    onChanged: (d) {
      setState(() => _day = d);
      widget.onChanged?.call(d);
    },
  );
}

/// The drawn day (inside its 48dp touch target).
Size sizeOfDay(WidgetTester tester, String day) => tester.getSize(
  find
      .ancestor(of: find.text(day), matching: find.byType(ExpressiveSurface))
      .first,
);

/// The touch target around the day.
Size targetOfDay(WidgetTester tester, String day) => tester.getSize(
  find
      .ancestor(of: find.text(day), matching: find.byType(ExpressivePressable))
      .first,
);

void main() {
  testWidgets('custom period shapes retain real 48dp buttons', (tester) async {
    final controller = ExpressiveTimePickerController(hour: 10, minute: 15);
    addTearDown(controller.dispose);
    for (final shapes in const [
      roundedTestShapes,
      cookieTestShapes,
      scallopedTestShapes,
    ]) {
      controller.setPeriod(pm: false);
      await tester.pumpWidget(
        host(
          (_) => ExpressiveTheme(
            data: bloom.copyWith(timePickerTheme: shapedStyle(shapes.wide)),
            child: ExpressiveTimeInput(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pm = find.byWidgetPredicate(
        (widget) =>
            widget is ExpressivePressable && widget.semanticLabel == 'PM',
      );
      final bounds = tester.getRect(pm);
      expect(bounds.width, greaterThanOrEqualTo(48));
      expect(bounds.height, greaterThanOrEqualTo(48));
      await tester.tapAt(bounds.center);
      expect(controller.isPm, isTrue);
    }
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'time dialog actions remain reachable after resizing $direction',
      (tester) async {
        var confirmed = 0;
        for (final width in [390.0, 120.0, 240.0, 390.0]) {
          await tester.pumpWidget(
            host(
              (_) => Directionality(
                textDirection: direction,
                child: SizedBox(
                  width: width,
                  child: ExpressiveTimePickerDialog(
                    modeToggle: ExpressiveTimePickerModeToggle(
                      mode: ExpressiveTimePickerMode.input,
                      onChanged: (_) {},
                    ),
                    dismiss: ExpressiveTextButton('Cancel', onPressed: () {}),
                    confirm: ExpressiveTextButton(
                      'OK',
                      key: const ValueKey('confirm-time'),
                      onPressed: () => confirmed++,
                    ),
                    child: const SizedBox(width: 256, height: 80),
                  ),
                ),
              ),
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          final dialog = tester.getRect(
            find.byType(ExpressiveTimePickerDialog),
          );
          final confirm = find.byKey(const ValueKey('confirm-time'));
          for (final action in [
            confirm,
            find.byType(ExpressiveTimePickerModeToggle),
          ]) {
            final rect = tester.getRect(action);
            expect(dialog.contains(rect.topLeft), isTrue);
            expect(
              dialog.contains(rect.bottomRight - const Offset(.001, .001)),
              isTrue,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.tap(confirm);
          await tester.pumpAndSettle();
        }
        expect(confirmed, 4);
      },
    );
  }

  testWidgets(
    'time input resolves focus and error style with per-state fallback',
    (tester) async {
      final time = ExpressiveTimePickerController(hour: 9, minute: 30);
      addTearDown(time.dispose);
      const focused = Color(0xff123456);
      const invalid = Color(0xff654321);
      await tester.pumpWidget(
        host(
          (_) => ExpressiveTheme(
            data: bloom.copyWith(
              timePickerTheme: const ExpressiveComponentThemeData(
                foregroundColor: WidgetStatePropertyAll(focused),
              ),
            ),
            child: ExpressiveTimeInput(
              controller: time,
              style: ExpressiveComponentThemeData(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) =>
                      states.contains(WidgetState.error) ? invalid : null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.color,
        focused,
      );
      await tester.enterText(find.byType(EditableText), '13');
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.color,
        invalid,
      );
      expect(time.hour, 9);
      await tester.enterText(find.byType(EditableText), '11');
      await tester.pumpAndSettle();
      expect(time.hour, 11);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.color,
        focused,
      );
    },
  );

  group('Cody v2 ports (F14)', () {
    testWidgets('calendar bounds prevent selecting unavailable days', (
      tester,
    ) async {
      DateTime? value = DateTime(2026, 9, 5);
      await tester.pumpWidget(
        host(
          (_) => Held(
            initial: value,
            firstDate: DateTime(2026, 9, 3),
            lastDate: DateTime(2026, 9, 10),
            onChanged: (d) => value = d,
          ),
        ),
      );
      await tester.tap(pressableOf(find.text('1')));
      await tester.pumpAndSettle();
      expect(value!.day, 5);
      await tester.tap(pressableOf(find.text('8')));
      await tester.pumpAndSettle();
      expect(value!.day, 8);
      expect(find.text('8 Sep 2026'), findsOneWidget);
    });

    testWidgets('date dialog cancellation preserves value and OK commits the '
        'draft', (tester) async {
      DateTime? result = DateTime(2026, 9, 5);
      late BuildContext launcher;
      await tester.pumpWidget(
        host((context) {
          launcher = context;
          return const SizedBox();
        }),
      );
      late Future<DateTime?> chosen;
      Future<void> open() async {
        chosen = showExpressiveDatePicker(
          context: launcher,
          initialDate: result,
          today: today,
        );
        await tester.pumpAndSettle();
        await tester.tap(pressableOf(find.text('12')));
        await tester.pumpAndSettle();
        expect(find.text('12 Sep 2026'), findsOneWidget);
      }

      await open();
      await tester.tap(pressableOf(find.text('Cancel')));
      await tester.pumpAndSettle();
      result = await chosen ?? result;
      expect(result, DateTime(2026, 9, 5));

      await open();
      await tester.tap(pressableOf(find.text('OK')));
      await tester.pumpAndSettle();
      result = await chosen ?? result;
      expect(result, DateTime(2026, 9, 12));
    });

    testWidgets('docked date commits immediately and Escape dismisses its '
        'popover', (tester) async {
      DateTime? value = DateTime(2026, 9, 5);
      await tester.pumpWidget(
        host(
          (_) => StatefulBuilder(
            builder: (context, update) => SizedBox(
              width: 300,
              child: ExpressiveDockedDatePicker(
                label: 'Starts',
                value: value,
                currentDate: today,
                onChanged: (d) => update(() => value = d),
              ),
            ),
          ),
        ),
      );
      // The field, not its floating label (which ignores pointers).
      await tester.tap(find.byType(ExpressiveDockedDatePicker));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('OK'), findsNothing);
      expect(find.text('Select date'), findsNothing);
      await tester.tap(pressableOf(find.text('12')));
      await tester.pumpAndSettle();
      expect(value, DateTime(2026, 9, 12));
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('09/12/2026'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsNothing);
    });

    testWidgets('docked date is a filled field like its neighbours, or '
        'outlined as Compose draws it', (tester) async {
      for (final kind in ExpressiveTextFieldKind.values) {
        await tester.pumpWidget(
          host(
            (_) => SizedBox(
              width: 300,
              child: ExpressiveDockedDatePicker(
                label: 'Leave',
                kind: kind,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        expect(
          tester
              .widget<ExpressiveTextField>(find.byType(ExpressiveTextField))
              .kind,
          kind,
        );
      }
      await tester.pumpWidget(
        host(
          (_) => SizedBox(
            width: 300,
            child: ExpressiveDockedDatePicker(
              label: 'Leave',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<ExpressiveTextField>(find.byType(ExpressiveTextField))
            .kind,
        ExpressiveTextFieldKind.filled,
      );
    });

    testWidgets('docked date prints the day as format says', (tester) async {
      DateTime? value = DateTime(2026, 10, 3);
      await tester.pumpWidget(
        host(
          (_) => StatefulBuilder(
            builder: (context, update) => SizedBox(
              width: 300,
              child: ExpressiveDockedDatePicker(
                label: 'Starts',
                value: value,
                currentDate: today,
                format: (d) =>
                    '${ExpressiveFormat.weekday(d)} ${ExpressiveFormat.date(d)}',
                onChanged: (d) => update(() => value = d),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Sat 3 Oct 2026'), findsOneWidget);
      expect(find.text('10/03/2026'), findsNothing);
      await tester.tap(find.byType(ExpressiveDockedDatePicker));
      await tester.pumpAndSettle();
      await tester.tap(pressableOf(find.text('12')));
      await tester.pumpAndSettle();
      expect(value, DateTime(2026, 10, 12));
      expect(find.text('Mon 12 Oct 2026'), findsOneWidget);
    });

    testWidgets('popovers keep the app theme when the app is not the root', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MaterialApp(
            builder: (context, app) => ExpressiveHost(
              light: bloom,
              brightness: Brightness.light,
              child: app!,
            ),
            home: Center(
              child: SizedBox(
                width: 300,
                child: ExpressiveDockedDatePicker(
                  label: 'Starts',
                  currentDate: today,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      // The field, not its floating label (which ignores pointers).
      await tester.tap(find.byType(ExpressiveDockedDatePicker));
      await tester.pumpAndSettle();
      final picker = find.byType(ExpressiveDatePicker);
      expect(picker, findsOneWidget);
      expect(tester.element(picker).expressiveTheme, bloom);
    });
  });

  group('date picker', () {
    testWidgets('at large text every day prints at one size', (tester) async {
      await tester.pumpWidget(
        host(
          (_) => SizedBox(
            width: DatePickerModalTokens.containerWidth,
            child: Held(initial: DateTime(2026, 9, 5)),
          ),
          scale: 2,
        ),
      );
      final one = tester.getRect(find.text('1').first);
      final thirty = tester.getRect(find.text('30').first);
      expect(one.height, moreOrLessEquals(thirty.height, epsilon: 0.5));
    });

    for (final direction in TextDirection.values) {
      testWidgets('the month arrows point with the reading direction '
          '(${direction.name})', (tester) async {
        await tester.pumpWidget(
          host(
            (_) => Directionality(
              textDirection: direction,
              child: SizedBox(
                width: DatePickerModalTokens.containerWidth,
                child: Held(initial: DateTime(2026, 9, 5)),
              ),
            ),
          ),
        );
        // The arrows are icon buttons named by their tooltips.
        Finder arrow(String tip) => find.byWidgetPredicate(
          (w) => w is ExpressiveIconButton && w.tooltip == tip,
        );
        IconData glyph(String tip) =>
            tester.widget<ExpressiveIconButton>(arrow(tip)).icon;
        final rtl = direction == TextDirection.rtl;
        // Back points against the reading direction, on toward it.
        expect(
          glyph('Previous month'),
          rtl
              ? ExpressiveSymbols.keyboardArrowRight
              : ExpressiveSymbols.keyboardArrowLeft,
        );
        expect(
          glyph('Next month'),
          rtl
              ? ExpressiveSymbols.keyboardArrowLeft
              : ExpressiveSymbols.keyboardArrowRight,
        );
        expect(
          tester.getCenter(arrow('Next month')).dx >
              tester.getCenter(arrow('Previous month')).dx,
          !rtl,
        );
      });
    }

    testWidgets('lays out Compose geometry from the tokens', (tester) async {
      await tester.pumpWidget(
        host(
          (_) => SizedBox(
            width: DatePickerModalTokens.containerWidth,
            child: Held(initial: DateTime(2026, 9, 5)),
          ),
        ),
      );
      final picker = tester.getSize(find.byType(ExpressiveDatePicker));
      expect(picker.width, DatePickerModalTokens.containerWidth);
      // Header 120 (its divider inside), navigation 56, weekdays 48, six rows of 48.
      expect(
        picker.height,
        DatePickerModalTokens.headerContainerHeight +
            DatePickerBehavior.monthYearHeight +
            DatePickerBehavior.cellSize * 7,
      );
      expect(
        sizeOfDay(tester, '17'),
        const Size(
          DatePickerModalTokens.dateContainerWidth,
          DatePickerModalTokens.dateContainerHeight,
        ),
      );
      expect(targetOfDay(tester, '17'), const Size.square(48));
      expect(find.text('Select date'), findsOneWidget);
      expect(find.text('5 Sep 2026'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      // Sunday first: S M T W T F S.
      expect(find.text('S'), findsNWidgets(2));
      expect(find.text('T'), findsNWidgets(2));
    });

    testWidgets('the week starts where the locale says, unless the picker '
        'is told', (tester) async {
      // The weekday heading's leftmost column.
      String first() {
        final columns = <String, double>{
          for (final day in const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ])
            day: tester
                .getRect(
                  find
                      .byWidgetPredicate(
                        (w) => w is Semantics && w.properties.label == day,
                      )
                      .first,
                )
                .left,
        };
        return (columns.entries.toList()
              ..sort((a, b) => a.value.compareTo(b.value)))
            .first
            .key;
      }

      Future<void> pump(int? locale, int? told) => tester.pumpWidget(
        host(
          (context) => Localizations.override(
            context: context,
            delegates: <LocalizationsDelegate<dynamic>>[
              _WeekFrom(locale ?? DateTime.sunday),
            ],
            child: ExpressiveDatePicker(
              selected: DateTime(2026, 9, 5),
              currentDate: today,
              firstDayOfWeek: told,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await pump(null, null);
      expect(first(), 'Sunday');
      await pump(DateTime.monday, null);
      expect(first(), 'Monday');
      await pump(DateTime.monday, DateTime.saturday);
      expect(first(), 'Saturday');
      // The days follow the heading: with Monday first, Sunday the 6th is in
      // the last column, right of Tuesday the 1st.
      await pump(DateTime.monday, null);
      expect(
        tester.getRect(find.text('6')).left,
        greaterThan(tester.getRect(find.text('1')).left),
      );
    });

    testWidgets('selected day is primary, today outlined', (tester) async {
      await tester.pumpWidget(host((_) => Held(initial: DateTime(2026, 9, 5))));
      await tester.pumpAndSettle();
      Color textColor(String day) => tester
          .renderObject<RenderParagraph>(find.text(day))
          .text
          .style!
          .color!;
      expect(textColor('5'), bloom.colors.onPrimary);
      expect(textColor('1'), bloom.colors.primary);
      expect(textColor('17'), bloom.colors.onSurface);
    });

    testWidgets('arrows page months and the year grid jumps years', (
      tester,
    ) async {
      await tester.pumpWidget(host((_) => Held(initial: DateTime(2026, 9, 5))));
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(pressableOf(find.text('September 2026')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Next month'), findsNothing);
      expect(
        tester.getSize(
          find
              .ancestor(
                of: find.text('2030'),
                matching: find.byType(ExpressivePressable),
              )
              .first,
        ),
        const Size(
          DatePickerModalTokens.selectionYearContainerWidth,
          DatePickerModalTokens.selectionYearContainerHeight,
        ),
      );
      await tester.tap(pressableOf(find.text('2030')));
      await tester.pumpAndSettle();
      expect(find.text('September 2030'), findsOneWidget);
    });

    testWidgets('month arrows and the mode toggle wear onSurfaceVariant; '
        'the year menu arrow the ambient colour', (tester) async {
      await tester.pumpWidget(host((_) => Held(initial: DateTime(2026, 9, 5))));
      await tester.pumpAndSettle();
      Color iconColor(IconData icon) => IconTheme.of(
        tester.element(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is ExpressiveIcon && w.icon == icon,
            ),
            matching: find.byType(Icon),
          ),
        ),
      ).color!;
      expect(
        iconColor(ExpressiveSymbols.keyboardArrowRight),
        bloom.colors.onSurfaceVariant,
      );
      expect(
        iconColor(ExpressiveSymbols.edit),
        bloom.colors.role(DatePickerModalTokens.headerHeadlineColor),
      );
      final drop = tester.widget<Icon>(
        find.byIcon(ExpressiveSymbols.arrowDropDown),
      );
      expect(drop.color, isNot(bloom.colors.onSurfaceVariant));
      final label = tester.renderObject<RenderParagraph>(
        find.text('September 2026'),
      );
      expect(label.text.style!.color, bloom.colors.onSurfaceVariant);
    });

    testWidgets('a swipe pages to the next month', (tester) async {
      await tester.pumpWidget(host((_) => Held(initial: DateTime(2026, 9, 5))));
      await tester.fling(
        pressableOf(find.text('16')),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('input mode validates as it is typed', (tester) async {
      DateTime? value;
      await tester.pumpWidget(
        host(
          (_) => Held(
            initial: null,
            mode: ExpressiveDatePickerMode.input,
            onChanged: (d) => value = d,
          ),
        ),
      );
      expect(find.text('Select date'), findsOneWidget);
      expect(find.text('Entered date'), findsOneWidget);
      final field = find.byType(EditableText);
      await tester.enterText(field, '13012031');
      await tester.pump();
      expect(find.text('Use the form MM/DD/YYYY'), findsOneWidget);
      await tester.enterText(field, '03122031');
      await tester.pump();
      expect(find.text('03/12/2031'), findsOneWidget);
      expect(value, DateTime(2031, 3, 12));
      expect(find.text('12 Mar 2031'), findsOneWidget);
      await tester.enterText(field, '03122201');
      await tester.pump();
      expect(find.text('Pick a year from 1900 to 2100'), findsOneWidget);
    });

    testWidgets('the toggle switches between the calendar and typing', (
      tester,
    ) async {
      await tester.pumpWidget(host((_) => Held(initial: DateTime(2026, 9, 5))));
      await tester.tap(find.bySemanticsLabel('Type a date'));
      await tester.pumpAndSettle();
      expect(find.text('09/05/2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Pick from the calendar'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
    });
  });

  group('date range picker', () {
    testWidgets('selection follows updateDateSelection', (tester) async {
      DateTime? start;
      DateTime? end;
      await tester.pumpWidget(
        host(
          (_) => StatefulBuilder(
            builder: (context, update) => SizedBox(
              height: 520,
              child: ExpressiveDateRangePicker(
                start: start,
                end: end,
                currentDate: today,
                initialMonth: DateTime(2026, 9),
                onChanged: (s, e) => update(() {
                  start = s;
                  end = e;
                }),
              ),
            ),
          ),
        ),
      );
      final sep = find.descendant(
        of: find.ancestor(
          of: find.text('September 2026'),
          matching: find.byType(Column),
        ),
        matching: find.text('10'),
      );
      await tester.tap(pressableOf(sep.first));
      await tester.pump();
      expect(start, DateTime(2026, 9, 10));
      expect(end, isNull);
      await tester.tap(
        pressableOf(
          find
              .descendant(
                of: find
                    .ancestor(
                      of: find.text('September 2026'),
                      matching: find.byType(Column),
                    )
                    .first,
                matching: find.text('14'),
              )
              .first,
        ),
      );
      await tester.pump();
      expect(end, DateTime(2026, 9, 14));
      expect(find.text('10 Sep 2026'), findsOneWidget);
      expect(find.text('14 Sep 2026'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_RangePainter',
        ),
        findsOneWidget,
      );
    });
  });

  group('Compose layout parity', () {
    testWidgets('the range headline wraps rather than ellipsizing', (
      tester,
    ) async {
      Future<void> pick(double width) => tester.pumpWidget(
        host(
          (_) => SizedBox(
            width: width,
            height: 520,
            child: ExpressiveDateRangePicker(
              start: DateTime(2031, 3, 10),
              end: DateTime(2031, 3, 17),
              currentDate: today,
              initialMonth: DateTime(2031, 3),
              onChanged: (_, _) {},
            ),
          ),
        ),
      );
      List<TextBox> lines(String text) => tester
          .renderObject<RenderParagraph>(find.text(text))
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          );

      // Room for one date a line: the end date moves whole under the start
      // (never "17 Mar / 2031"), and nothing is cut.
      await pick(420);
      final end = tester.renderObject<RenderParagraph>(
        find.text('17 Mar 2031'),
      );
      expect(end.didExceedMaxLines, isFalse);
      expect(lines('10 Mar 2031').map((b) => b.top).toSet(), hasLength(1));
      expect(lines('17 Mar 2031').map((b) => b.top).toSet(), hasLength(1));
      expect(
        tester.getTopLeft(find.text('17 Mar 2031')).dy,
        greaterThan(tester.getBottomLeft(find.text('10 Mar 2031')).dy - 1),
      );

      // A line narrower than one date (the test font's wide glyphs at
      // 360): it wraps inside, and nothing is cut.
      await pick(360);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('17 Mar 2031'))
            .didExceedMaxLines,
        isFalse,
      );
      expect(tester.getSize(find.text('10 Mar 2031')).width, greaterThan(0));
      expect(tester.getSize(find.text('17 Mar 2031')).width, greaterThan(0));
    });

    testWidgets('the date field keeps its height with and without an error', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          // Wide enough that the test font keeps the error on one line.
          (_) => SizedBox(
            width: 480,
            child: Held(initial: null, mode: ExpressiveDatePickerMode.input),
          ),
        ),
      );
      final picker = find.byType(ExpressiveDatePicker);
      final before = tester.getSize(picker).height;
      await tester.enterText(find.byType(EditableText), '13012031');
      await tester.pump();
      expect(find.text('Use the form MM/DD/YYYY'), findsOneWidget);
      expect(tester.getSize(picker).height, before);
    });

    testWidgets('the time input keeps two supporting lines', (tester) async {
      final time = ExpressiveTimePickerController(hour: 9, minute: 30);
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host((_) => ExpressiveTimeInput(controller: time)),
      );
      // 72dp field + 7dp gap + two 16dp bodySmall lines (`minLines = 2`).
      expect(tester.getSize(find.byType(ExpressiveTimeInput)).height, 111);
    });

    testWidgets('the 24-hour dial keeps the 96dp selectors', (tester) async {
      final time = ExpressiveTimePickerController(
        hour: 17,
        minute: 30,
        is24Hour: true,
      );
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host(
          (_) => ExpressiveTimePicker(
            controller: time,
            layout: ExpressiveTimePickerLayout.vertical,
          ),
        ),
      );
      // Compose's ClockDisplay never reads the 24h vertical width token.
      final selectors = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_TimeSelector',
      );
      expect(selectors, findsNWidgets(2));
      expect(
        tester.getSize(selectors.first).width,
        TimePickerTokens.timeSelectorContainerWidth,
      );
    });
  });

  group('time picker', () {
    testWidgets('dial and selectors from the tokens; a tap sets the hour '
        'and moves on to the minutes', (tester) async {
      final time = ExpressiveTimePickerController(hour: 9, minute: 30);
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host(
          (_) => ExpressiveTimePicker(
            controller: time,
            layout: ExpressiveTimePickerLayout.vertical,
          ),
        ),
      );
      expect(find.text('09'), findsOneWidget);
      expect(find.text('30'), findsWidgets);
      final hourBox = find
          .ancestor(of: find.text('09'), matching: find.byType(SizedBox))
          .first;
      expect(
        tester.getSize(hourBox),
        const Size(
          TimePickerTokens.timeSelectorContainerWidth,
          TimePickerTokens.timeSelectorContainerHeight,
        ),
      );
      final dial = find.byWidgetPredicate(
        (w) =>
            w is SizedBox &&
            w.width == TimePickerTokens.clockDialContainerSize &&
            w.height == TimePickerTokens.clockDialContainerSize,
      );
      expect(dial, findsOneWidget);
      // Three o'clock: right of centre on the outer ring.
      final centre = tester.getCenter(dial);
      await tester.tapAt(
        centre + const Offset(TimePickerBehavior.outerCircleRadius, 0),
      );
      await tester.pump();
      expect(time.hour, 3);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(time.selection, ExpressiveTimeSelection.minute);
      // Half past: straight down; a tap snaps to five minutes.
      await tester.tapAt(
        centre + const Offset(2, TimePickerBehavior.outerCircleRadius),
      );
      await tester.pumpAndSettle();
      expect(time.minute, 30);
      await tester.tap(pressableOf(find.text('PM')));
      await tester.pumpAndSettle();
      expect(time.hour, 15);
    });

    testWidgets('the unselected period is transparent in its 1dp outline', (
      tester,
    ) async {
      final time = ExpressiveTimePickerController(hour: 9);
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host(
          (_) => ExpressiveTimePicker(
            controller: time,
            layout: ExpressiveTimePickerLayout.vertical,
          ),
        ),
      );
      ExpressivePressable period(String label) => tester.widget(
        find.byWidgetPredicate(
          (w) => w is ExpressivePressable && w.semanticLabel == label,
        ),
      );
      final colors = tester.element(find.text('PM')).expressiveTheme.colors;
      final pm = period('PM');
      expect(pm.color.a, 0);
      expect(pm.side.color, colors.outline);
      expect(pm.side.width, TimePickerTokens.periodSelectorOutlineWidth);
      final am = period('AM');
      expect(am.color, colors.primaryContainer);
      expect(am.side, BorderSide.none);
    });

    testWidgets('the 24-hour dial picks the inner ring by distance', (
      tester,
    ) async {
      final time = ExpressiveTimePickerController(hour: 9, is24Hour: true);
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host(
          (_) => ExpressiveTimePicker(
            controller: time,
            autoSwitchToMinute: false,
            layout: ExpressiveTimePickerLayout.vertical,
          ),
        ),
      );
      expect(find.text('AM'), findsNothing);
      final dial = find.byWidgetPredicate(
        (w) =>
            w is SizedBox &&
            w.width == TimePickerTokens.clockDialContainerSize &&
            w.height == TimePickerTokens.clockDialContainerSize,
      );
      final centre = tester.getCenter(dial);
      await tester.tapAt(
        centre + const Offset(0, TimePickerBehavior.innerCircleRadius),
      );
      await tester.pumpAndSettle();
      expect(time.hour, 18);
      await tester.tapAt(
        centre + const Offset(0, TimePickerBehavior.outerCircleRadius),
      );
      await tester.pumpAndSettle();
      expect(time.hour, 6);
    });

    testWidgets('time input validates and moves on to the minutes', (
      tester,
    ) async {
      final time = ExpressiveTimePickerController(hour: 9, minute: 30);
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host((_) => ExpressiveTimeInput(controller: time)),
      );
      expect(find.text('Hour'), findsOneWidget);
      expect(find.text('Minute'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '13');
      await tester.pump();
      expect(find.text('Enter a valid hour'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '11');
      await tester.pumpAndSettle();
      expect(time.hour, 11);
      expect(time.selection, ExpressiveTimeSelection.minute);
      await tester.enterText(find.byType(EditableText), '45');
      await tester.pump();
      expect(time.minute, 45);
    });

    // Compose's `TimeInputTransformation` + `TimeInputErrorHandler`
    // (`HapticFeedbackType.Reject`): a third digit rejects the edit with the
    // platform's reject haptic; a digit typed into a full field replaces it.
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ]) {
      testWidgets('${platform.name}: the time input rejects a third digit '
          'with the reject haptic', (tester) async {
        final haptics = <Object?>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final time = ExpressiveTimePickerController(hour: 9, minute: 30);
        addTearDown(time.dispose);
        await tester.pumpWidget(
          host(
            (context) => Theme(
              data: Theme.of(context).copyWith(platform: platform),
              child: ExpressiveTimeInput(controller: time),
            ),
          ),
        );
        await tester.pump();
        final field = find.byType(EditableText);
        String text() => tester.widget<EditableText>(field).controller.text;
        expect(text(), '09');

        // A digit typed at the caret of the full field replaces its two.
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '709',
            selection: TextSelection.collapsed(offset: 1),
          ),
        );
        await tester.pump();
        expect(text(), '7');
        expect(time.hour, 7);
        expect(haptics, isEmpty);

        // More than two digits at once: the edit reverts, rejected.
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '123',
            selection: TextSelection.collapsed(offset: 3),
          ),
        );
        await tester.pump();
        expect(text(), '7');
        expect(time.hour, 7);
        expect(haptics, <Object?>['HapticFeedbackType.errorNotification']);

        // Anything but digits reverts without a haptic.
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '7a',
            selection: TextSelection.collapsed(offset: 2),
          ),
        );
        await tester.pump();
        expect(text(), '7');
        expect(haptics, hasLength(1));
      });
    }

    testWidgets('the time input focuses the selected field from the first '
        'frame and sets its colon in the field style', (tester) async {
      final time = ExpressiveTimePickerController(hour: 9, minute: 30);
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host((_) => ExpressiveTimeInput(controller: time)),
      );
      await tester.pump();
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isTrue);
      expect(field.controller.selection.baseOffset, 0);
      final colon = tester.widget<Text>(find.text(':'));
      expect(colon.style!.fontSize, bloom.type.displayMedium.fontSize);
    });

    testWidgets('a tap on the selected field\'s box off its digits focuses '
        'it again', (tester) async {
      final time = ExpressiveTimePickerController(hour: 9, minute: 30);
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host((_) => ExpressiveTimeInput(controller: time)),
      );
      await tester.pump();
      final field = tester.widget<EditableText>(find.byType(EditableText));
      field.focusNode.unfocus();
      await tester.pump();
      expect(field.focusNode.hasFocus, isFalse);
      final line = tester.getRect(find.byType(EditableText));
      // In the box, above the line the digits stand on.
      final point = Offset(line.center.dx, line.top - 4);
      expect(line.contains(point), isFalse);
      await tester.tapAt(point);
      await tester.pump();
      expect(field.focusNode.hasFocus, isTrue);
    });

    testWidgets('time scroll springs to a new minute', (tester) async {
      final time = ExpressiveTimePickerController(hour: 7, minute: 5);
      addTearDown(time.dispose);
      await tester.pumpWidget(
        host((_) => ExpressiveTimeScroll(controller: time)),
      );
      expect(
        tester.getSize(find.byType(ExpressiveScrollField).first),
        const Size(
          TimePickerBehavior.scrollFieldWidth,
          TimePickerBehavior.vibrantFieldHeight,
        ),
      );
      await tester.drag(
        find.byType(ExpressiveScrollField).last,
        const Offset(0, -ScrollFieldBehavior.height / 3 * 2),
      );
      await tester.pumpAndSettle();
      expect(time.minute, 7);
      expect(time.hour, 7);
    });

    testWidgets('the time dialog resolves to the confirmed time', (
      tester,
    ) async {
      late BuildContext launcher;
      await tester.pumpWidget(
        host((context) {
          launcher = context;
          return const SizedBox();
        }),
      );
      final result = showExpressiveTimePicker(
        context: launcher,
        initialHour: 9,
        initialMinute: 30,
        is24Hour: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('Select time'), findsOneWidget);
      await tester.tap(pressableOf(find.text('PM')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Type the time'));
      await tester.pumpAndSettle();
      expect(find.text('Enter time'), findsOneWidget);
      await tester.tap(pressableOf(find.text('OK')));
      await tester.pumpAndSettle();
      expect(await result, (hour: 21, minute: 30));
    });
  });

  testWidgets('pickers fit a phone at text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final time = ExpressiveTimePickerController(hour: 18, is24Hour: true);
    final time12 = ExpressiveTimePickerController(hour: 9);
    addTearDown(time.dispose);
    addTearDown(time12.dispose);
    await tester.pumpWidget(
      host(
        (_) => Column(
          children: <Widget>[
            Held(initial: DateTime(2026, 9, 5)),
            SizedBox(
              height: 400,
              child: ExpressiveDateRangePicker(
                currentDate: today,
                onChanged: (_, _) {},
              ),
            ),
            ExpressiveTimePicker(
              controller: time,
              vibrant: true,
              layout: ExpressiveTimePickerLayout.vertical,
            ),
            ExpressiveTimeInput(controller: time12),
            ExpressiveTimeScroll(controller: time12),
          ],
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('in a 358dp column (seven 48dp days do not fit) every day '
      'keeps a whole 48dp target: the outer days stand flush with the '
      'month, inside the pager\'s clip', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        (context) =>
            SizedBox(width: 358, child: Held(initial: DateTime(2026, 9, 14))),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    // September 2026 starts on a Tuesday: the 6th is a Sunday, the 12th a
    // Saturday, the grid's outer columns. The guideline reads each day's
    // node as the pager clips it.
    expect(targetOfDay(tester, '6').width, 48);
    expect(targetOfDay(tester, '12').width, 48);
    semantics.dispose();
  });
}

/// ui_core's shared words with the week starting on [day], as a locale
/// that starts its weeks there gives them.
class _WeekFrom extends LocalizationsDelegate<DesignLocalizations> {
  const _WeekFrom(this.day);

  final int day;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(_WeekWords(day));

  @override
  bool shouldReload(_WeekFrom old) => old.day != day;
}

class _WeekWords extends DefaultDesignLocalizations {
  const _WeekWords(this.day);

  final int day;

  @override
  int get firstDayOfWeek => day;
}
