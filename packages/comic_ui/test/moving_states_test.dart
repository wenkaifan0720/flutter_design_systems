// Comic's moments between states, held still and checked (ui_core's moving_states.dart): a press held halfway, a
// hover and a keyboard focus on each everyday control, by day and by night, and a sheet halfway up. No shadow, glow
// or rim is cut flat by a clip round it in any of them; the check reads only the casts that reach the control
// (near:), so a long page costs nothing.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';

import 'moving_states.dart';

void main() {
  final controls = <String, Widget Function()>{
    'filled button': () => ComicButton.filled('Save', onPressed: () {}),
    'button': () => ComicButton('Cancel', onPressed: () {}),
    'text button': () => ComicButton.text('More', onPressed: () {}),
    'icon button': () =>
        ComicIconButton(ComicGlyphs.bell, label: 'Alerts', onPressed: () {}),
    'chip': () => ComicChip('Fish', onPressed: () {}),
    'checkbox': () =>
        ComicCheckbox(label: 'Keep issue', value: true, onChanged: (_) {}),
    'switch': () => ComicSwitch(value: true, onChanged: (_) {}),
    'field': () => const ComicTextField(hint: 'Your name'),
    'link': () => ComicLink('Read the issue', onPressed: () {}),
  };

  Widget app(Brightness brightness, Widget child) => MaterialApp(
    home: ComicHost(
      light: ComicThemeData.offset(),
      dark: ComicThemeData.offset(Brightness.dark),
      brightness: brightness,
      child: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );

  Future<List<String>> shadows(WidgetTester tester, Rect? near) async {
    final report = await const DesignShadowClipCheck(look: 'Comic').check(
      tester.element(find.byType(ComicHost)),
      runAsync: tester.runAsync,
      near: near,
    );
    return report.problems;
  }

  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: control) in controls.entries) {
      testWidgets('a $name pressed, hovered and focused casts no cut shadow '
          '(${brightness.name})', (tester) async {
        tester.view.physicalSize = const Size(390, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          app(
            brightness,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ComicButton('Before', onPressed: () {}),
                const SizedBox(height: 16),
                KeyedSubtree(key: const Key('control'), child: control()),
              ],
            ),
          ),
        );
        final target = find.byKey(const Key('control'));
        final problems = <String>[];
        Future<void> look(String moment) async => problems.addAll([
          for (final p in await shadows(tester, tester.getRect(target)))
            '$moment: $p',
        ]);
        await atPressHalfway(tester, target, look);
        await atHover(tester, target, look);
        await atFocus(tester, target, look);
        expect(tester.takeException(), isNull);
        expect(problems, isEmpty);
      });
    }

    testWidgets('a sheet halfway up casts no cut shadow (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late BuildContext context;
      await tester.pumpWidget(
        app(
          brightness,
          Builder(
            builder: (c) {
              context = c;
              return const Text('Issue 12');
            },
          ),
        ),
      );
      final problems = <String>[];
      await atSheetHalfway(
        tester,
        () => showComicSheet<void>(
          context,
          builder: (_) =>
              const ComicSheet(title: 'Filters', child: Text('Only unread')),
        ).ignore(),
        (moment) async => problems.addAll([
          for (final p in await shadows(tester, null)) '$moment: $p',
        ]),
      );
      expect(tester.takeException(), isNull);
      expect(problems, isEmpty);
    });
  }
}
