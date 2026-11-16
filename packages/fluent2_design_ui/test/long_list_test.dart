// A long list opened from a field shows its chosen option though it stands near the end, and the keys keep the option
// they light wholly in view as they move (round the ends, to the first and the last, by a typed letter): a select's
// popover on a large window, its sheet on a phone, and a combobox's list (ui_core's, in the look's faces).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

// Thirty rooms, none's words the start of another's.
final _rooms = [
  for (var i = 1; i <= 30; i++)
    Fluent2Option('r$i', 'Room ${i.toString().padLeft(2, '0')}'),
];

Future<void> _app(WidgetTester t, Size size, Widget field) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) =>
          Fluent2Host(brightness: Brightness.light, child: navigator!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: SizedBox(width: 320, child: field),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// The listed option reading [words]: the words in the list's scrolling
/// window, not the field's own.
Finder _row(String words) => find
    .descendant(of: find.byType(Scrollable), matching: find.text(words))
    .first;

/// Whether [row] stands wholly inside the list's scrolling window.
void _inView(WidgetTester t, Finder row, String why) {
  final viewport = t.getRect(
    find.ancestor(of: row, matching: find.byType(Scrollable)).first,
  );
  final r = t.getRect(row);
  expect(
    r.top >= viewport.top - 0.5 && r.bottom <= viewport.bottom + 0.5,
    isTrue,
    reason: '$why: the row $r stands inside the list $viewport',
  );
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

void main() {
  testWidgets("a select's popover opens on its chosen option near the end, "
      'and the keys keep the lit option in view', (t) async {
    await _app(
      t,
      const Size(1440, 900),
      Fluent2Select<String>(
        label: 'Room',
        value: 'r28',
        options: _rooms,
        onChanged: (_) {},
      ),
    );
    await t.tap(find.byType(Fluent2Select<String>));
    await t.pumpAndSettle();
    _inView(t, _row('Room 28'), 'opened on the chosen option');
    await _key(t, LogicalKeyboardKey.end);
    _inView(t, _row('Room 30'), 'End');
    await _key(t, LogicalKeyboardKey.arrowDown);
    _inView(t, _row('Room 01'), 'Down round the end');
    await _key(t, LogicalKeyboardKey.arrowUp);
    _inView(t, _row('Room 30'), 'Up round the start');
    await _key(t, LogicalKeyboardKey.home);
    _inView(t, _row('Room 01'), 'Home');
    for (var i = 0; i < 14; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await t.pumpAndSettle();
    _inView(t, _row('Room 15'), 'Down, a row at a time');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a select's phone sheet opens on its chosen option near the "
      'end', (t) async {
    await _app(
      t,
      const Size(390, 844),
      Fluent2Select<String>(
        label: 'Room',
        value: 'r28',
        options: _rooms,
        onChanged: (_) {},
      ),
    );
    await t.tap(find.byType(Fluent2Select<String>));
    await t.pumpAndSettle();
    _inView(t, _row('Room 28'), 'opened on the chosen option');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets("a combobox's list opens on its chosen option near the end, "
      'and the keys keep the lit option in view', (t) async {
    await _app(
      t,
      const Size(1440, 900),
      Fluent2Combobox<String>(
        label: 'Room',
        value: 'r28',
        options: _rooms,
        onChanged: (_) {},
      ),
    );
    await t.tap(find.byType(EditableText));
    await t.pumpAndSettle();
    // A press opens the list, or else Down does.
    if (find
        .descendant(of: find.byType(Scrollable), matching: find.text('Room 28'))
        .evaluate()
        .isEmpty) {
      await _key(t, LogicalKeyboardKey.arrowDown);
    }
    _inView(t, _row('Room 28'), 'opened on the chosen option');
    await _key(t, LogicalKeyboardKey.arrowDown);
    await _key(t, LogicalKeyboardKey.arrowDown);
    _inView(t, _row('Room 30'), 'Down to the last');
    await _key(t, LogicalKeyboardKey.arrowDown);
    _inView(t, _row('Room 01'), 'Down round the end');
    await _key(t, LogicalKeyboardKey.arrowUp);
    _inView(t, _row('Room 30'), 'Up round the start');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
