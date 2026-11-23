// Fields stand in one form at one height: a text field, a select and a
// combobox share their window's height at the reader's text size, and a
// date field's window matches them while its date fits one line.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

void main() {
  setUpAll(studioLoadFonts);

  for (final scale in [1.0, 2.0]) {
    testWidgets('fields share one height at ${scale}x', (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(780, 2400);
      addTearDown(tester.view.reset);
      final keys = List.generate(4, (_) => GlobalKey());
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: StudioHost(brightness: Brightness.light, child: app!),
          ),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 358,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyedSubtree(
                    key: keys[0],
                    child: const StudioTextField(labelText: 'Title'),
                  ),
                  KeyedSubtree(
                    key: keys[1],
                    child: StudioSelect<int>(
                      labelText: 'Project',
                      value: 1,
                      items: const [
                        StudioSelectItem(value: 1, label: 'Open studio'),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                  KeyedSubtree(
                    key: keys[2],
                    child: StudioCombobox<String>(
                      labelText: 'Assignee',
                      options: const ['Maya Reed'],
                      labelOf: (s) => s,
                      onSelected: (_) {},
                    ),
                  ),
                  KeyedSubtree(
                    key: keys[3],
                    child: StudioDatePicker(
                      labelText: 'Due date',
                      value: DateTime(2026, 11, 20),
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2027),
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double window(GlobalKey key) => tester
          .getSize(
            find
                .descendant(
                  of: find.byKey(key),
                  matching: find.byType(AnimatedStudioSurface),
                )
                .first,
          )
          .height;
      final height = window(keys[0]);
      expect(height, greaterThanOrEqualTo(44));
      for (final key in keys.sublist(1, scale == 1 ? 4 : 3)) {
        expect(window(key), moreOrLessEquals(height, epsilon: 0.5));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
