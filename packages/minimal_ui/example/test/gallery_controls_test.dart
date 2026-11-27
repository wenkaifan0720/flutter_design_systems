import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui_example/kit_gallery/demos/toggle_check.dart';
import 'package:minimal_ui_example/kit_gallery/kit.dart' show kitEmbedded;
import 'package:minimal_ui_example/gallery.dart' show CustomizePanel, Knobs;

Future<void> _show(WidgetTester t, Widget child) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(390, 844);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      home: MinimalTheme(
        data: MinimalThemeData.preset('standard', Brightness.light),
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: SingleChildScrollView(
              child: Center(child: SizedBox(width: 310, child: child)),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'all text-size choices fit at 200% and the user can change back',
    (t) async {
      var knobs = const Knobs(textScale: 2);
      await _show(
        t,
        CustomizePanel(knobs: () => knobs, onChanged: (value) => knobs = value),
      );
      for (final label in ['100%', '130%', '160%', '200%']) {
        final target = find.text(label);
        await t.ensureVisible(target);
        final paragraph = t.renderObject<RenderParagraph>(target);
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }
      await t.ensureVisible(find.text('100%'));
      await t.tap(find.text('100%'));
      await t.pumpAndSettle();
      expect(knobs.textScale, 1);
    },
  );

  testWidgets(
    'gallery state switches and checkboxes toggle, with readable disabled captions',
    (t) async {
      kitEmbedded = true;
      addTearDown(() => kitEmbedded = false);
      await _show(t, kitToggleCheckDemo(Brightness.light));
      final setting = t.renderObject<RenderParagraph>(
        find.text('Sync over cellular'),
      );
      expect(setting.didExceedMaxLines, isFalse);
      final toggle = find.byWidgetPredicate(
        (w) => w is MinimalSwitch && w.label == 'Off',
      );
      final box = find.byWidgetPredicate(
        (w) => w is MinimalCheckbox && w.semanticLabel == 'Off',
      );
      final element = t.element(toggle);
      await t.ensureVisible(toggle);
      await t.tap(toggle);
      await t.pumpAndSettle();
      expect((element.widget as MinimalSwitch).value, isTrue);
      final check = t.element(box);
      await t.ensureVisible(box);
      await t.tap(box);
      await t.pumpAndSettle();
      expect((check.widget as MinimalCheckbox).value, isTrue);
      final control = find
          .descendant(
            of: find.byWidget(check.widget),
            matching: find.byType(GestureDetector),
          )
          .first;
      Focus.of(t.element(control)).requestFocus();
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect((check.widget as MinimalCheckbox).value, isFalse);
      for (final caption in find.text('Disabled off').evaluate()) {
        final p = caption.renderObject! as RenderParagraph;
        final boxes = p.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: 'Disabled'.length),
        );
        expect(boxes.map((box) => box.top).toSet(), hasLength(1));
      }
      expect(t.takeException(), isNull);
    },
  );
}
