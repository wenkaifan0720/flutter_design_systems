import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

Future<void> _page(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 620);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => MinimalTheme(
        data: MinimalThemeData.preset('standard', Brightness.light),
        child: Directionality(
          textDirection: direction,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: navigator!,
          ),
        ),
      ),
      home: Align(alignment: AlignmentDirectional.topStart, child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Escape clears a query, then closes the palette and returns focus',
    (tester) async {
      final opener = FocusNode();
      addTearDown(opener.dispose);
      await _page(
        tester,
        Builder(
          builder: (context) => MinimalButton(
            'Commands',
            focusNode: opener,
            autofocus: true,
            onPressed: () => MinimalCommand.show(
              context,
              actions: [MinimalCommandItem('Pin', onSelected: () {})],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Pi');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
      expect(opener.hasPrimaryFocus, isTrue);
    },
  );

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets(
      '${key.keyLabel} activates the initially focused sheet action',
      (tester) async {
        final opener = FocusNode();
        addTearDown(opener.dispose);
        var activated = 0;
        await _page(
          tester,
          Builder(
            builder: (context) => MinimalButton(
              'File actions',
              focusNode: opener,
              autofocus: true,
              onPressed: () => showMinimalActionSheet(
                context,
                actions: [
                  const MinimalActionSheetAction('Unavailable'),
                  MinimalActionSheetAction('Pin', onPressed: () => activated++),
                ],
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Pin'), findsOneWidget);
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(activated, 1);
        expect(find.text('Pin'), findsNothing);
        expect(opener.hasPrimaryFocus, isTrue);
      },
    );
  }

  for (final (direction, label, value) in [
    (TextDirection.ltr, 'Time of day', 'Every evening'),
    (TextDirection.rtl, 'Time of day', 'Every evening'),
    // A phone's project picker in Arabic: the docs' Stint walk saw the value
    // cut to an ellipsis at 200%.
    (TextDirection.rtl, 'المشروع', 'الاستوديو المفتوح'),
  ]) {
    testWidgets('picker labels and values fit at 200% in $direction: $value', (
      tester,
    ) async {
      await _page(
        tester,
        SizedBox(
          width: 310,
          child: MinimalSelect<String>(
            label: label,
            value: 'evening',
            options: [MinimalSelectOption('evening', value)],
            onChanged: (_) {},
          ),
        ),
        direction: direction,
        scale: 2,
      );
      for (final label in [label, value]) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }
      expect(tester.takeException(), isNull);
    });
    testWidgets('rail labels fit at 200% in $direction', (tester) async {
      await _page(
        tester,
        SizedBox(
          height: 400,
          child: MinimalNavigationRail(
            destinations: const [
              MinimalNavItem(Icons.home, 'Home'),
              MinimalNavItem(Icons.search, 'Search'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
        direction: direction,
        scale: 2,
      );
      for (final label in ['Home', 'Search']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
        expect(
          paragraph.size.width,
          greaterThanOrEqualTo(
            paragraph.getMaxIntrinsicWidth(double.infinity) - .5,
          ),
          reason: label,
        );
      }
    });
    testWidgets('chart callouts fit at 200% in $direction', (tester) async {
      await _page(
        tester,
        const SizedBox(
          width: 310,
          child: MinimalLineChart(
            series: [
              MinimalChartSeries('Balance', [100, 102, 104, 106]),
            ],
            labels: ['First', 'Second', 'Third', 'Fourth'],
            semanticLabel: 'Balance over time',
          ),
        ),
        direction: direction,
        scale: 2,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      for (final label in ['Balance', '106']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
