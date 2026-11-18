import 'package:fluent2_design_ui_example/main.dart';
import 'package:flutter/widgets.dart'
    show Directionality, Scrollable, Size, TextDirection;
import 'package:flutter_test/flutter_test.dart';

void main() {
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
