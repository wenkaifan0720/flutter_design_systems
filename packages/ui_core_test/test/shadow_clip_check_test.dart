@Tags(['goldens'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _shadow = [
  BoxShadow(color: Color(0x66000000), offset: Offset(4, 4), blurRadius: 8),
];

// A raised face with a soft shadow, [room] from the edge of the box round
// it, which clips or not.
Widget _raised({
  required double room,
  bool clip = true,
  BorderRadius radius = const BorderRadius.all(Radius.circular(16)),
  Decoration? decoration,
}) {
  Widget face = Padding(
    padding: EdgeInsets.all(room),
    child: DecoratedBox(
      decoration:
          decoration ??
          BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: radius,
            boxShadow: _shadow,
          ),
      child: const SizedBox(width: 120, height: 64),
    ),
  );
  if (clip) face = ClipRect(child: face);
  return face;
}

Future<DesignAlignmentReport> _check(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(key: const Key('page'), child: child),
    ),
  );
  return const DesignShadowClipCheck(look: 'Test').check(
    tester.element(find.byKey(const Key('page'))),
    runAsync: tester.runAsync,
  );
}

void main() {
  testWidgets('a shadow a tight clip cuts flat is named', (tester) async {
    final report = await _check(tester, _raised(room: 4));
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(
        contains('the shadow of a 120 × 64 face'),
        contains('cut flat at its'),
        contains('right'),
        contains('bottom'),
        contains('a clip (ClipRect)'),
      ),
    );
  });

  testWidgets('a custom clipper is read by its own clip, not the whole box '
      'its approximate rect reports', (tester) async {
    // Cuts at the start and end only; its approximate rect is the default,
    // the whole box.
    final report = await _check(
      tester,
      ClipRect(
        clipper: const _StartAndEnd(),
        child: _raised(room: 4, clip: false),
      ),
    );
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(contains('cut flat at its right'), isNot(contains('bottom'))),
    );
  });

  testWidgets('near a control, only the casts that reach it are read', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          key: const Key('page'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(key: const Key('first'), child: _raised(room: 4)),
              const SizedBox(height: 80),
              _raised(room: 4),
            ],
          ),
        ),
      ),
    );
    Future<DesignAlignmentReport> check({Rect? near}) =>
        const DesignShadowClipCheck(look: 'Test').check(
          tester.element(find.byKey(const Key('page'))),
          runAsync: tester.runAsync,
          near: near,
        );
    expect((await check()).problems, hasLength(2));
    final first = tester.getRect(find.byKey(const Key('first')));
    expect((await check(near: first)).problems, hasLength(1));
    expect((await check(near: first.translate(0, 400))).problems, isEmpty);
  });

  group('a scroll view\'s edge', () {
    // Eight raised rows 64 tall and 16 apart in a list 300 tall: at its
    // start the third row's foot is 4 pt above the list's, at its end the
    // last row's; each shadow reaches past it.
    Widget rows(ScrollController controller) => SizedBox(
      width: 200,
      height: 300,
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(40, 72, 40, 4),
        children: [
          for (var i = 0; i < 8; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == 7 ? 0 : 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _shadow,
                ),
                child: const SizedBox(height: 64),
              ),
            ),
        ],
      ),
    );

    testWidgets('along its scroll, with more past it, is scrolling', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final report = await _check(tester, rows(controller));
      expect(controller.position.pixels, 0);
      expect(controller.position.maxScrollExtent, greaterThan(0));
      expect(report.problems, isEmpty);
    });

    testWidgets('at the end of its content still cuts', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(key: const Key('page'), child: rows(controller)),
        ),
      );
      // The list's extent is an estimate until its last rows are built: the
      // jump can land past the true end, which the physics then settle.
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(controller.position.pixels, controller.position.maxScrollExtent);
      final report = await const DesignShadowClipCheck(look: 'Test').check(
        tester.element(find.byKey(const Key('page'))),
        runAsync: tester.runAsync,
      );
      expect(report.problems, hasLength(1));
      expect(
        report.problems.single,
        allOf(
          contains('cut flat at its bottom'),
          contains("a scroll view's edge"),
        ),
      );
    });

    testWidgets('across its scroll still cuts', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final report = await _check(
        tester,
        SizedBox(
          width: 160,
          height: 300,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(4, 120, 4, 0),
            children: [
              for (var i = 0; i < 8; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: 140),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFEEEEEE),
                      boxShadow: _shadow,
                    ),
                    child: SizedBox(height: 40),
                  ),
                ),
            ],
          ),
        ),
      );
      expect(report.problems, isNotEmpty);
      expect(
        report.problems.first,
        allOf(contains('cut flat at its right'), isNot(contains('bottom'))),
      );
    });

    testWidgets('a SingleChildScrollView part-way through its content is '
        'scrolling', (tester) async {
      final report = await _check(
        tester,
        SizedBox(
          width: 200,
          height: 300,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 16, 40, 0),
            child: Column(
              children: [
                for (var i = 0; i < 8; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _shadow,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: i == 3 ? 40 : 64,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      expect(report.problems, isEmpty);
    });
  });

  testWidgets('a shadow with room inside its clip passes', (tester) async {
    final report = await _check(tester, _raised(room: 32));
    expect(report.problems, isEmpty);
  });

  testWidgets('a shadow with no clip round it passes', (tester) async {
    final report = await _check(tester, _raised(room: 4, clip: false));
    expect(report.problems, isEmpty);
  });

  testWidgets('a clip on a round face\'s own edge shows its shadow square', (
    tester,
  ) async {
    // Neumorphism's dialog in its frame: the clip stands on the face's box,
    // so its shadow fills the corners its round face leaves.
    final report = await _check(tester, _raised(room: 0));
    expect(
      report.problems.single,
      allOf(
        contains('cut along its own edge at its'),
        contains('behind its round'),
        contains('bottom right'),
        contains('the shadow shows square'),
      ),
    );
  });

  testWidgets('a clip on a square face\'s own edge hides it, unseen', (
    tester,
  ) async {
    final report = await _check(
      tester,
      _raised(room: 0, radius: BorderRadius.zero),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a face clipped by its own round shape passes', (tester) async {
    final report = await _check(
      tester,
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _raised(room: 0, clip: false),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('the frame round a screen in a preview is its edge', (
    tester,
  ) async {
    // A phone in a gallery's preview: the bar's shadow ends at the phone's
    // screen, as on the phone.
    final report = await _check(
      tester,
      ClipRect(
        child: SizedBox(
          width: 200,
          height: 120,
          child: Overlay.wrap(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _raised(room: 2, clip: false),
            ),
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a full-width face ends its shadow at the screen\'s sides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        key: Key('page'),
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ClipRect(
            child: SizedBox(
              width: 400,
              height: 200,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: _shadow,
                  ),
                  child: SizedBox(width: 400, height: 120),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final report = await const DesignShadowClipCheck(look: 'Test').check(
      tester.element(find.byKey(const Key('page'))),
      runAsync: tester.runAsync,
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a phone shown small ends a sheet\'s shadow at its screen', (
    tester,
  ) async {
    // A preview's phone: its app clips to its own screen, inside the
    // overlay its routes stand in; a full-width sheet's shadow ends there.
    final report = await _check(
      tester,
      SizedBox(
        width: 200,
        height: 300,
        child: Overlay.wrap(
          child: const ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: _shadow,
                ),
                child: SizedBox(width: 200, height: 160),
              ),
            ),
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a small knob\'s shadow is not read for its corners', (
    tester,
  ) async {
    // A slider's 22-pt thumb, raised by a deep soft shadow and a lit one,
    // its rim inside it: under 32 pt the blur spans the whole corner, and
    // what it casts reads as round.
    final report = await _check(
      tester,
      const CustomPaint(
        painter: _Knob(),
        child: SizedBox(width: 22, height: 22),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a square shadow behind a round face is named', (tester) async {
    // The face is round; its shadow, cast by a square box behind it, is not.
    final report = await _check(
      tester,
      const Padding(
        padding: EdgeInsets.all(32),
        child: DecoratedBox(
          decoration: BoxDecoration(boxShadow: _shadow),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: ColoredBox(
              color: Color(0xFFEEEEEE),
              child: SizedBox(width: 120, height: 64),
            ),
          ),
        ),
      ),
    );
    expect(report.problems, isNotEmpty);
  });

  // A physical model's and a physical shape's shadows, as a decoration's
  // are.
  testWidgets("a physical model's and a physical shape's shadows a tight "
      'clip cuts are named', (tester) async {
    const fill = Color(0xFFEEEEEE);
    for (final face in <Widget>[
      const PhysicalModel(
        color: fill,
        elevation: 6,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        child: SizedBox(width: 120, height: 64),
      ),
      const PhysicalModel(
        color: fill,
        elevation: 6,
        shape: BoxShape.circle,
        child: SizedBox(width: 64, height: 64),
      ),
      const PhysicalShape(
        clipper: ShapeBorderClipper(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        color: fill,
        elevation: 6,
        child: SizedBox(width: 120, height: 64),
      ),
    ]) {
      final report = await _check(
        tester,
        ClipRect(
          child: Padding(padding: const EdgeInsets.all(4), child: face),
        ),
      );
      expect(
        report.problems,
        anyElement(contains('cut flat at its')),
        reason: '$face',
      );
    }
  });
}

// A raised round knob as a soft look paints one: a deep shadow and a lit
// one thrown either way, the face, and a rim inside its edge.
class _Knob extends CustomPainter {
  const _Knob();

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final shape = Path()..addOval(box);
    Paint soft(Color color) => Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas
      ..drawPath(shape.shift(const Offset(8, 8)), soft(const Color(0xFFA3B1C6)))
      ..drawPath(
        shape.shift(const Offset(-8, -8)),
        soft(const Color(0xFFFFFFFF)),
      )
      ..drawPath(shape, Paint()..color = const Color(0xFFE6E9EF))
      ..save()
      ..clipPath(shape);
    Path outside(Offset by) => Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(box.inflate(4))
      ..addPath(shape, by);
    canvas
      ..drawPath(
        outside(const Offset(1, 1)),
        Paint()..color = const Color(0x66FFFFFF),
      )
      ..drawPath(
        outside(const Offset(-1, -1)),
        Paint()..color = const Color(0x33000000),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_Knob oldDelegate) => false;
}

// A clip at a box's start and end only, open above and below; it leaves
// getApproximateClipRect at CustomClipper's default (the whole box).
class _StartAndEnd extends CustomClipper<Rect> {
  const _StartAndEnd();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -size.height, size.width, 2 * size.height);

  @override
  bool shouldReclip(_StartAndEnd oldClipper) => false;
}
