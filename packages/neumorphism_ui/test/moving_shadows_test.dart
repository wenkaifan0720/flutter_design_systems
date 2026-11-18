// The ten everyday screens in their moving states (ui_core's moving_states.dart): each screen's controls pressed
// halfway on a phone, and hovered and focused on a desk by day and by night, with no shadow, light or focus lift cut
// near the control at any moment (ui_core's DesignShadowClipCheck, given the control's rect). A sheet and a dialog
// are checked halfway up too.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart' show DesignShadowClipCheck;

// ignore: avoid_relative_lib_imports
import '../example/lib/everyday_screens.dart';
import 'moving_states.dart';
import 'support.dart' show loadNeumorphicFonts, sweepUnlessTurn;

final _heights = {390.0: 844.0, 1440.0: 900.0};

/// What each screen presses, hovers and focuses, by its words: the first of a target's words (`|`) the screen shows,
/// as a phone's key can read less than a desk's; a target marked `?` only where the screen shows it (a desk's detail
/// pane). A bank of choices is one stop for the Tab key, its chosen cell, so the chosen cell is the one named.
List<String> _targets(String id, Brightness brightness) => switch (id) {
  'home' => ['Ceiling light', 'Reading lamp'],
  'devices' => ['Reading lamp', 'Ceiling fan'],
  'devices-search' => ['Floor lamp'],
  'device' => ['Remove from home', 'Floor lamp'],
  'no-match' => ['garage', '?Remove from home'],
  'add-device' => ['Add device', 'Cancel'],
  'checkout' => ['Standard', 'Card', 'Pay £40.00|Pay'],
  'account-email-error' => ['Save details', 'United Kingdom'],
  'settings' => ['Leave this home', 'Weekly summary'],
  'look-and-feel' => [
    'Customize',
    if (brightness == Brightness.dark) 'Night' else 'Day',
  ],
  _ => throw ArgumentError.value(id, 'id', 'a screen with no targets'),
};

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The control a person means by [words]: the focusable part that holds them (a key, a field), or else the one beside
/// them on their line (a light's switch beside its name). Found from the words outward, so a page's own focusable
/// regions round a whole card are never taken for it.
Finder? _control(String words) {
  final text = find.text(words).hitTestable();
  if (text.evaluate().isEmpty) return null;
  final at = text.evaluate().first;
  final line = (at.renderObject! as RenderBox).paintBounds.shift(
    (at.renderObject! as RenderBox).localToGlobal(Offset.zero),
  );
  // A Focus that takes no focus itself (ExcludeFocus round a row's own switch, a field's hover watch) is no control.
  final nodes = FocusManager.instance.rootScope.descendants.toList();
  bool isControl(Element e) =>
      e.widget is Focus &&
      e.widget is! FocusScope &&
      nodes.any((n) => identical(n.context, e) && n.canRequestFocus);
  Element? found;
  at.visitAncestorElements((up) {
    if (isControl(up)) {
      found = up;
      return false;
    }
    final beside = <(double, Element)>[];
    void look(Element e) {
      if (isControl(e) && e.renderObject is RenderBox) {
        final box = e.renderObject! as RenderBox;
        if (box.hasSize) {
          final r = box.localToGlobal(Offset.zero) & box.size;
          if ((r.center.dy - line.center.dy).abs() < 24) {
            beside.add(((r.center.dx - line.center.dx).abs(), e));
          }
        }
      }
      e.visitChildElements(look);
    }

    up.visitChildElements(look);
    if (beside.isEmpty) return true;
    beside.sort((a, b) => a.$1.compareTo(b.$1));
    found = beside.first.$2;
    return false;
  });
  final control = found;
  return control == null
      ? null
      : find.byElementPredicate((e) => identical(e, control));
}

void main() {
  setUpAll(loadNeumorphicFonts);

  // Each screen in one of its three sizes and modes every time, in turn; the sweep runs the rest.
  for (final (turn, screen) in everydayScreens.indexed) {
    for (final (cell, (width, brightness)) in [
      (390.0, Brightness.light),
      (1440.0, Brightness.light),
      (1440.0, Brightness.dark),
    ].indexed) {
      final name = '${screen.id} ${width.toInt()} ${brightness.name}';
      testWidgets('$name: no shadow is cut as its controls move', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, _heights[width]!);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(screen.app(brightness, TextDirection.ltr));
        final cuts = <String>[];
        Future<void> check(String what, Rect near) async {
          final report = await const DesignShadowClipCheck(look: 'Neumorphism')
              .check(
                // The gallery's app, sheets and dialogs included: a WidgetsApp under any Material.
                tester.element(find.byType(WidgetsApp).first),
                runAsync: tester.runAsync,
                near: near,
              );
          for (final p in report.problems) {
            cuts.add('$what: $p');
          }
        }

        if (screen.id == 'look-and-feel' || screen.id == 'add-device') {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 150));
          await check('opening', Offset.zero & tester.view.physicalSize);
        }
        await _settle(tester);
        for (final target in _targets(screen.id, brightness)) {
          final optional = target.startsWith('?');
          final choices = target.replaceFirst('?', '').split('|');
          final words = choices.firstWhere(
            (w) => find.text(w).evaluate().isNotEmpty,
            orElse: () => choices.first,
          );
          if (_control(words) == null &&
              find.text(words).evaluate().isNotEmpty) {
            await tester.ensureVisible(find.text(words).first);
            await _settle(tester);
          }
          final control = _control(words);
          if (optional && control == null) continue;
          expect(control, isNotNull, reason: '$name shows "$words"');
          Future<void> look(String moment) async {
            final at = _control(words);
            if (at != null) await check('$words $moment', tester.getRect(at));
          }

          if (width < 600) {
            await atPressHalfway(tester, control!, look);
          } else {
            await atHover(tester, control!, look);
            await atFocus(tester, control, look);
          }
          expect(tester.takeException(), isNull);
        }
        expect(cuts, isEmpty, reason: '$name: shadows cut');
        await tester.pumpWidget(const SizedBox());
        await _settle(tester);
      }, tags: sweepUnlessTurn(turn, cell, 3));
    }
  }
}
