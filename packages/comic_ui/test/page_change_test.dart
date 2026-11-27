// Comic's page change: a panel wipe from the reading start, the page whole at full ink inside it; a cut under Reduce
// Motion.
import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;

const _page = ValueKey('pushed');

Future<NavigatorState> _app(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  bool still = false,
}) async {
  final navigator = GlobalKey<NavigatorState>();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: Directionality(
          textDirection: direction,
          child: ComicHost(child: child!),
        ),
      ),
      home: const SizedBox.expand(),
    ),
  );
  return navigator.currentState!;
}

// The wipe's clip under the pushed page, or null when it stands whole.
Rect? _wipe(WidgetTester tester) {
  final clips = find.ancestor(
    of: find.byKey(_page),
    matching: find.byType(ClipRect),
  );
  for (final element in clips.evaluate()) {
    final clip = (element.widget as ClipRect).clipper;
    if (clip == null) continue;
    return clip.getClip((element.renderObject! as RenderBox).size);
  }
  return null;
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'a pushed page is revealed from the reading start (${direction.name}) and stands whole after',
      (tester) async {
        final navigator = await _app(tester, direction: direction);
        navigator.push(
          MaterialPageRoute<void>(
            builder: (context) => const SizedBox.expand(key: _page),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final mid = _wipe(tester)!;
        expect(mid.width, greaterThan(0));
        expect(mid.width, lessThan(400));
        if (direction == TextDirection.ltr) {
          expect(mid.left, 0);
        } else {
          expect(mid.right, 400);
        }
        await tester.pump(const Duration(milliseconds: 200));
        expect(_wipe(tester), isNull);
        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        final going = _wipe(tester)!;
        expect(going.width, inExclusiveRange(0, 400));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byKey(_page), findsNothing);
      },
    );
  }

  testWidgets(
    'under Reduce Motion a pushed page stands whole in its first frame',
    (tester) async {
      final navigator = await _app(tester, still: true);
      navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => const SizedBox.expand(key: _page),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(_page), findsOneWidget);
      expect(_wipe(tester), isNull);
    },
  );
}
