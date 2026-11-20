import 'package:fluent2_design_ui/fluent2_design_ui.dart' show Fluent2DataGrid;
import 'package:fluent2_design_ui_example/main.dart';
import 'package:flutter/widgets.dart'
    show Directionality, Scrollable, Size, TextDirection;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the four file rows announce their names and checked state', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const GalleryApp(link: GalleryLink(page: 'collections')),
    );
    await t.pumpAndSettle();
    final grid = find.byWidgetPredicate((widget) => widget is Fluent2DataGrid);
    for (final (name, owner, pages) in const [
      ('Budget', 'Ana Ruiz', 12),
      ('Roadmap', 'Kai Ito', 8),
      ('Handbook', 'Sam Lee', 40),
      ('Launch plan', 'Ana Ruiz', 21),
    ]) {
      final row = find.descendant(of: grid, matching: find.text(name));
      // Centre the row so the gallery's pinned bar can't take the tap.
      await Scrollable.ensureVisible(t.element(row), alignment: .5);
      await t.pumpAndSettle();
      final node = t.getSemantics(row);
      // The row merges its cells, so read the label a screen reader hears.
      final label = node.getSemanticsData().label;
      expect(label, contains(name));
      expect(label, contains(owner));
      expect(label, contains(pages.toString()));
      expect(
        node,
        isSemantics(hasCheckedState: true, isChecked: false, isButton: false),
      );
      await t.tap(row);
      await t.pumpAndSettle();
      expect(
        t.getSemantics(row),
        isSemantics(isChecked: true, isButton: false),
      );
    }
  });

  testWidgets('a confirmation covers the gallery controls until dismissed', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const GalleryApp(link: GalleryLink(page: 'dialog', textScale: 2)),
    );
    await t.pumpAndSettle();
    final settings = find.text('Customize');
    final trigger = find.text('Delete file');
    await Scrollable.ensureVisible(t.element(trigger), alignment: .5);
    await t.pumpAndSettle();
    await t.tap(trigger.hitTestable());
    await t.pumpAndSettle();
    expect(settings.hitTestable(), findsNothing);
    await t.tap(find.text('Cancel').hitTestable().first);
    await t.pumpAndSettle();
    expect(settings.hitTestable(), findsOneWidget);
  });

  testWidgets('the website field keeps its address in order in Arabic', (
    t,
  ) async {
    await t.pumpWidget(
      const GalleryApp(
        link: GalleryLink(
          page: 'entries',
          direction: TextDirection.rtl,
          textScale: 2,
        ),
      ),
    );
    await t.pumpAndSettle();
    final scheme = find.text('https://');
    final host = find.text('northwind');
    final suffix = find.text('.com');
    expect(Directionality.of(t.element(scheme)), TextDirection.ltr);
    expect(t.getCenter(scheme).dx, lessThan(t.getCenter(host).dx));
    expect(t.getCenter(host).dx, lessThan(t.getCenter(suffix).dx));
  });

  testWidgets(
    'Arabic progress captions use localized file counts and storage units',
    (t) async {
      await t.pumpWidget(
        const GalleryApp(
          link: GalleryLink(
            page: 'progress',
            direction: TextDirection.rtl,
            textScale: 2,
          ),
        ),
      );
      await t.pump();
      expect(find.text('٣ من ٥ ملفات'), findsOneWidget);
      expect(
        find.text('المستخدم ٩٫٤ غيغابايت من أصل ١٠ غيغابايت'),
        findsOneWidget,
      );
    },
  );
}
