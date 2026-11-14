// Parts looked at between their states (design6 O): what a moving, dragged or previewing part shows mid-move. The
// state matrix shows each part at rest; these hold the frames between.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/src/fluent2_design/internal/well.dart'
    show fluent2BrandWell;

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (BuildContext context, Widget? page) =>
      Fluent2Host(brightness: Brightness.light, child: page!),
  home: Center(child: SizedBox(width: 360, child: child)),
);

final _t = Fluent2ThemeData.preset('lapis', Brightness.light);
final _c = _t.colors;

void main() {
  group('a date range, after the first press', () {
    DesignCalendarController range() => DesignCalendarController(
      firstDate: DateTime(2026, 3, 1),
      lastDate: DateTime(2026, 3, 31),
      currentDate: DateTime(2026, 3, 1),
      mode: DesignCalendarMode.range,
    );

    /// The band's pieces (the brand tint), each a rect on screen.
    List<Rect> band(WidgetTester t) => [
      for (final e
          in find
              .byWidgetPredicate(
                (w) => w is ColoredBox && w.color == fluent2BrandWell(_t),
              )
              .evaluate())
        t.getRect(find.byWidget(e.widget)),
    ];

    /// The fill of the disc behind day [n].
    Color? disc(WidgetTester t, String n) =>
        (t
                    .widget<Container>(
                      find
                          .ancestor(
                            of: find.text(n),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration)
            .color;

    Future<TestGesture> pointer(WidgetTester t) async {
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      return mouse;
    }

    testWidgets('a start alone has no band', (t) async {
      final c = range();
      await t.pumpWidget(_host(Fluent2DateRangePicker(controller: c)));
      await t.tap(find.text('10'));
      await t.pump();
      expect(band(t), isEmpty);
      expect(disc(t, '10'), isNot(isNull));
    });

    testWidgets('the band ends at the hovered day, which stands as an end', (
      t,
    ) async {
      final c = range();
      await t.pumpWidget(_host(Fluent2DateRangePicker(controller: c)));
      await t.tap(find.text('10'));
      await t.pump();
      final mouse = await pointer(t);
      await mouse.moveTo(t.getCenter(find.text('13')));
      await t.pump();
      final pieces = band(t);
      expect(pieces, isNotEmpty);
      final start = t.getCenter(find.text('10'));
      final end = t.getCenter(find.text('13'));
      expect(
        pieces.map((r) => r.left).reduce((a, b) => a < b ? a : b),
        closeTo(start.dx, 0.5),
      );
      expect(
        pieces.map((r) => r.right).reduce((a, b) => a > b ? a : b),
        closeTo(end.dx, 0.5),
        reason: 'the band stops at the hovered day, not past it',
      );
      expect(disc(t, '13'), anyOf(_c.brandBackground, _c.brandBackgroundHover));
    });

    testWidgets('in a later week the last row ends at the hovered day', (
      t,
    ) async {
      final c = range();
      await t.pumpWidget(_host(Fluent2DateRangePicker(controller: c)));
      await t.tap(find.text('10'));
      await t.pump();
      final mouse = await pointer(t);
      await mouse.moveTo(t.getCenter(find.text('20')));
      await t.pump();
      final end = t.getCenter(find.text('20'));
      final row = band(t).where((r) => (r.center.dy - end.dy).abs() < 1);
      expect(row, isNotEmpty);
      expect(
        row.map((r) => r.right).reduce((a, b) => a > b ? a : b),
        closeTo(end.dx, 0.5),
      );
    });

    testWidgets('before the start there is no band', (t) async {
      final c = range();
      await t.pumpWidget(_host(Fluent2DateRangePicker(controller: c)));
      await t.tap(find.text('10'));
      await t.pump();
      final mouse = await pointer(t);
      await mouse.moveTo(t.getCenter(find.text('7')));
      await t.pump();
      expect(band(t), isEmpty);
    });

    testWidgets('from the keyboard the band ends at the focused day', (
      t,
    ) async {
      final c = range();
      await t.pumpWidget(_host(Fluent2DateRangePicker(controller: c)));
      await t.tap(find.text('10'));
      await t.pump();
      for (var i = 0; i < 8; i++) {
        if (FocusManager.instance.primaryFocus?.debugLabel ==
            'DesignCalendar') {
          break;
        }
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'DesignCalendar');
      final from = c.focusedDay;
      for (var i = 0; i < 3; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await t.pump();
      }
      final day = '${from.add(const Duration(days: 3)).day}';
      final end = t.getCenter(find.text(day));
      expect(
        band(t).map((r) => r.right).reduce((a, b) => a > b ? a : b),
        closeTo(end.dx, 0.5),
      );
    });
  });

  group('a carousel, mid-swipe', () {
    final slides = [
      for (final colour in const [Color(0xFF0F6CBD), Color(0xFFC50F1F)])
        ColoredBox(color: colour),
    ];

    {
      testWidgets('the frame clips the moving slide to its corners', (t) async {
        await t.pumpWidget(
          _host(Fluent2CarouselView(label: 'Highlights', children: slides)),
        );
        final view = find.byType(PageView);
        final frame = t.getRect(view);
        final drag = await t.startGesture(frame.center);
        await drag.moveBy(Offset(-frame.width * .3, 0));
        await t.pump();
        // The clip round the viewport, not round each slide, holds the
        // corners while a slide is half in.
        final clip = find.ancestor(
          of: view,
          matching: find.byWidgetPredicate(
            (w) => w is ClipRRect || w is ClipPath,
          ),
        );
        expect(clip, findsWidgets);
        expect(t.getRect(clip.first), frame);
        final w = t.widget(clip.first);
        final corner = w is ClipRRect
            ? (w.borderRadius as BorderRadius).topLeft.x
            : (((w as ClipPath).clipper! as ShapeBorderClipper).shape
                      as RoundedRectangleBorder)
                  .borderRadius
                  .resolve(TextDirection.ltr)
                  .topLeft
                  .x;
        expect(corner, closeTo(Fluent2Radius.medium, 0.01));
        await drag.moveBy(Offset(-frame.width * .4, 0));
        await t.pump();
        expect(t.getRect(clip.first), frame);
        await drag.up();
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  });
}
