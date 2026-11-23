import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/centred_host.dart';

void main() {
  group('the focus ring', () {
    /// The colours along the row through the middle of [key]'s boundary,
    /// one per logical pixel.
    Future<List<Color>> row(WidgetTester tester, Key key) async {
      final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final shot = await tester.runAsync(() async {
        final image = await box.toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final width = image.width;
        final y = image.height ~/ 2;
        image.dispose();
        return [
          for (var x = 0; x < width; x++)
            Color.fromARGB(
              data.getUint8((y * width + x) * 4 + 3),
              data.getUint8((y * width + x) * 4),
              data.getUint8((y * width + x) * 4 + 1),
              data.getUint8((y * width + x) * 4 + 2),
            ),
        ];
      });
      return shot!;
    }

    bool near(Color a, Color b) =>
        (a.r - b.r).abs() < 0.02 &&
        (a.g - b.g).abs() < 0.02 &&
        (a.b - b.b).abs() < 0.02;

    for (final (name, brightness, inCard) in [
      ('a primary button on the page, light', Brightness.light, false),
      ('a danger button in a card, dark', Brightness.dark, true),
    ]) {
      testWidgets('stands off a filled face by 2 px of the ground it stands '
          'on, so it reads on a face in its own ink: $name', (tester) async {
        final t = MinimalThemeData.preset('standard', brightness);
        const shot = Key('shot');
        final button = Padding(
          padding: const EdgeInsets.all(8),
          child: MinimalButton(
            'Save',
            variant: inCard
                ? MinimalButtonVariant.destructive
                : MinimalButtonVariant.primary,
            onPressed: () {},
          ),
        );
        await tester.pumpWidget(
          centredHost(
            RepaintBoundary(
              key: shot,
              child: inCard
                  ? MinimalCard(padding: EdgeInsets.zero, child: button)
                  : ColoredBox(color: t.background, child: button),
            ),
            brightness: brightness,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final ground = inCard ? t.card : t.background;
        final line = await row(tester, shot);
        // From the start: the ground, then the ring, the gap, the face.
        final ring = line.indexWhere((c) => near(c, t.ring));
        expect(ring, greaterThan(0));
        expect(near(line[ring + 1], t.ring), isTrue);
        expect(near(line[ring + 2], ground), isTrue);
        expect(near(line[ring + 3], ground), isTrue);
        final face = line[ring + 4];
        expect(near(face, ground), isFalse);
        if (inCard) {
          // By night the danger fill is its tone over the ground: a red.
          expect(face.r, greaterThan(face.g));
          expect(face.r, greaterThan(face.b));
        } else {
          expect(near(face, t.primary), isTrue);
        }
      }, tags: 'goldens');
    }

    // A flush form row's words line up with the form's labels, so
    // its wash and ring reach past them instead of starting on their first
    // pixel, as a list row's text stands inside its own fill.
    final rows = <String, Widget>{
      'MinimalSelect': MinimalSelect<String>(
        labelText: 'Plan',
        value: 'pro',
        options: const [
          MinimalSelectOption('free', 'Free'),
          MinimalSelectOption('pro', 'Pro'),
        ],
        onChanged: (_) {},
      ),
      'MinimalFormRow': MinimalFormRow(label: 'Plan', onPressed: () {}),
      'MinimalChoiceRow': MinimalChoiceRow(
        title: 'Plan',
        selected: false,
        onPressed: () {},
      ),
      'MinimalProperty': MinimalProperty(
        icon: LucideIcons.circleDot,
        label: 'Plan',
        value: 'Pro',
        onPressed: () {},
      ),
      'MinimalActivity': MinimalActivity(
        at: DateTime(2026, 8, 27, 7, 40),
        text: 'Plan',
        onPressed: () {},
      ),
    };
    for (final MapEntry(key: name, value: part) in rows.entries) {
      testWidgets('$name: the wash and the ring reach 12 px past the row, '
          'its words where they stand at rest', (tester) async {
        await tester.pumpWidget(centredHost(SizedBox(width: 280, child: part)));
        final pressable = find.byType(MinimalPressable).first;
        final box = tester.getRect(pressable);
        final reach = tester.getRect(
          find.descendant(
            of: pressable,
            matching: find.byWidgetPredicate(
              (w) => w is AnimatedContainer && w.child == null,
            ),
          ),
        );
        expect(
          reach,
          Rect.fromLTRB(box.left - 12, box.top, box.right + 12, box.bottom),
        );
        final words = tester.getRect(find.text('Plan'));
        // A form row's label stands at the row's edge, in line with the
        // form's other labels (a property's and an activity's after their
        // glyph and time columns).
        if (!{'MinimalProperty', 'MinimalActivity'}.contains(name)) {
          expect(words.left, box.left);
        }
        expect(words.left - reach.left, greaterThanOrEqualTo(12));
      });
    }

    for (final brightness in Brightness.values) {
      testWidgets('a select row\'s ring and press stand clear of its label, '
          '${brightness.name}', (tester) async {
        final t = MinimalThemeData.preset('standard', brightness);
        const shot = Key('shot');
        await tester.pumpWidget(
          centredHost(
            RepaintBoundary(
              key: shot,
              child: ColoredBox(
                color: t.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(width: 240, child: rows['MinimalSelect']),
                ),
              ),
            ),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        final origin = tester.getTopLeft(find.byKey(shot));
        final label = (tester.getTopLeft(find.text('Plan')) - origin).dx;
        final idle = await row(tester, shot);

        final finger = await tester.startGesture(
          tester.getCenter(find.text('Plan')),
        );
        // Past the tap's press timeout, then past the wash's fade.
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 400));
        final pressed = await row(tester, shot);
        await finger.cancel();
        await tester.pumpAndSettle();
        // The wash covers the air before the label, 6 px out.
        final before = label.round() - 6;
        expect(near(idle[before], t.background), isTrue);
        expect(near(pressed[before], t.background), isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final focused = await row(tester, shot);
        final ring = focused.indexWhere((c) => near(c, t.ring));
        expect(ring, greaterThanOrEqualTo(0));
        expect(label - ring, greaterThanOrEqualTo(12));
      }, tags: 'goldens');
    }
  });
}
