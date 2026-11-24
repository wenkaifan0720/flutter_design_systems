// The mouse cursor over each draggable value part: a thumb grabs, and
// grabbing while dragged; a track that a press moves a thumb along clicks;
// a divider resizes; a disabled part is the basic arrow.
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

MouseCursor? _cursor() =>
    RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);

Future<TestGesture> _mouseAt(WidgetTester tester, Offset at) async {
  final mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    pointer: 1,
  );
  await mouse.addPointer(location: at);
  addTearDown(mouse.removePointer);
  await tester.pump();
  return mouse;
}

Widget _thumb(String key) => SizedBox(
  key: ValueKey(key),
  width: 20,
  height: 20,
  child: const ColoredBox(color: Color(0xFF333333)),
);

class _Range extends StatefulWidget {
  const _Range({this.enabled = true});

  final bool enabled;

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  RawRangeValues values = const RawRangeValues(20, 80);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 400,
      child: RawRangeSlider(
        values: values,
        max: 100,
        onChanged: widget.enabled
            ? (next) => setState(() => values = next)
            : null,
        trackBuilder: (context, track) => const SizedBox(
          height: 4,
          child: ColoredBox(color: Color(0xFFCCCCCC)),
        ),
        thumbBuilder: (context, index, states) => _thumb('thumb $index'),
      ),
    ),
  );
}

void main() {
  group('a value handle', () {
    Widget handle({bool enabled = true, bool dragging = false}) => harness(
      Center(
        child: RawValueHandle(
          value: 0.5,
          dragging: dragging,
          semanticLabel: 'Volume',
          onChanged: enabled ? (_) {} : null,
          builder: (context, states) => _thumb('handle'),
        ),
      ),
    );

    testWidgets('grabs, grabbing while dragged, basic when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(handle());
      await _mouseAt(
        tester,
        tester.getCenter(find.byKey(const ValueKey('handle'))),
      );
      expect(_cursor(), SystemMouseCursors.grab);
      await tester.pumpWidget(handle(dragging: true));
      expect(_cursor(), SystemMouseCursors.grabbing);
      await tester.pumpWidget(handle(enabled: false));
      expect(_cursor(), SystemMouseCursors.basic);
    });

    testWidgets('a cursor given wins', (tester) async {
      await tester.pumpWidget(
        harness(
          Center(
            child: RawValueHandle(
              value: 0.5,
              mouseCursor: SystemMouseCursors.precise,
              onChanged: (_) {},
              builder: (context, states) => _thumb('handle'),
            ),
          ),
        ),
      );
      await _mouseAt(
        tester,
        tester.getCenter(find.byKey(const ValueKey('handle'))),
      );
      expect(_cursor(), SystemMouseCursors.precise);
    });
  });

  group('a range slider', () {
    testWidgets(
      'its thumbs grab, its track clicks, and a drag is grabbing over the '
      'whole slider',
      (tester) async {
        await tester.pumpWidget(harness(const _Range()));
        final thumb = tester.getCenter(find.byKey(const ValueKey('thumb 0')));
        final mouse = await _mouseAt(tester, thumb);
        expect(_cursor(), SystemMouseCursors.grab);
        // The track midway between the thumbs.
        final track = Offset(200, thumb.dy);
        await mouse.moveTo(track);
        await tester.pump();
        expect(_cursor(), SystemMouseCursors.click);
        await mouse.moveTo(thumb);
        await mouse.down(thumb);
        await mouse.moveBy(const Offset(30, 0));
        await tester.pump();
        expect(_cursor(), SystemMouseCursors.grabbing);
        // Past the other thumb, where the dragged one stops: over the
        // other thumb and then the track, still grabbing.
        await mouse.moveTo(
          tester.getCenter(find.byKey(const ValueKey('thumb 1'))),
        );
        await tester.pump();
        expect(_cursor(), SystemMouseCursors.grabbing);
        await mouse.moveTo(Offset(390, thumb.dy));
        await tester.pump();
        expect(_cursor(), SystemMouseCursors.grabbing);
        await mouse.up();
        await tester.pump();
        expect(_cursor(), SystemMouseCursors.click);
      },
    );

    testWidgets('disabled, it is the basic arrow', (tester) async {
      await tester.pumpWidget(harness(const _Range(enabled: false)));
      final thumb = tester.getCenter(find.byKey(const ValueKey('thumb 0')));
      final mouse = await _mouseAt(tester, thumb);
      expect(_cursor(), SystemMouseCursors.basic);
      await mouse.moveTo(Offset(200, thumb.dy));
      await tester.pump();
      expect(_cursor(), SystemMouseCursors.basic);
    });
  });

  testWidgets("a colour slider's thumb grabs and its track clicks; the area is "
      'precise', (tester) async {
    final c = RawColorController(const Color(0xFFFF0000));
    addTearDown(c.dispose);
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: RawColorPicker(
              controller: c,
              areaHeight: 100,
              areaBuilder: (context, area) => const ColoredBox(
                key: ValueKey('area'),
                color: Color(0xFFFF0000),
              ),
              areaThumbBuilder: (context, area) =>
                  const SizedBox(width: 12, height: 12),
              trackBuilder: (context, channel, color) => SizedBox(
                height: 8,
                child: ColoredBox(
                  key: ValueKey('track ${channel.name}'),
                  color: const Color(0xFFCCCCCC),
                ),
              ),
              thumbBuilder: (context, states) => _thumb('hue thumb'),
            ),
          ),
        ),
      ),
    );
    final mouse = await _mouseAt(
      tester,
      tester.getCenter(find.byKey(const ValueKey('area'))),
    );
    expect(_cursor(), SystemMouseCursors.precise);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('hue thumb'))),
    );
    await tester.pump();
    expect(_cursor(), SystemMouseCursors.grab);
    final track = tester.getRect(find.byKey(const ValueKey('track hue')));
    await mouse.moveTo(track.centerRight - const Offset(20, 0));
    await tester.pump();
    expect(_cursor(), SystemMouseCursors.click);
  });

  testWidgets("a split view's divider resizes along its axis", (tester) async {
    Widget split(Axis axis) => harness(
      SizedBox(
        width: 400,
        height: 400,
        child: RawSplitView(
          axis: axis,
          first: const SizedBox.expand(),
          second: const SizedBox.expand(),
          dividerBuilder: (context, states, axis) => const ColoredBox(
            key: ValueKey('divider'),
            color: Color(0xFF000000),
          ),
        ),
      ),
    );
    await tester.pumpWidget(split(Axis.horizontal));
    final mouse = await _mouseAt(
      tester,
      tester.getCenter(find.byKey(const ValueKey('divider'))),
    );
    expect(_cursor(), SystemMouseCursors.resizeLeftRight);
    await tester.pumpWidget(split(Axis.vertical));
    await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('divider'))));
    await tester.pump();
    expect(_cursor(), SystemMouseCursors.resizeUpDown);
  });

  group('a wheel', () {
    Widget wheel({bool enabled = true}) => harness(
      Center(
        child: SizedBox(
          width: 200,
          child: RawPicker(
            semanticLabel: 'Hour',
            selection: const [5],
            itemExtent: 40,
            columns: (s) => [
              RawPickerColumn(
                itemCount: 24,
                itemLabel: (i) => '$i',
                semanticLabel: 'Hour',
              ),
            ],
            onChanged: enabled ? (_) {} : null,
            itemBuilder: (context, details) =>
                Center(child: Text(details.label)),
          ),
        ),
      ),
    );

    testWidgets('grabs, grabbing while the mouse turns it', (tester) async {
      await tester.pumpWidget(wheel());
      final at = tester.getCenter(find.byType(RawPicker));
      final mouse = await _mouseAt(tester, at);
      expect(_cursor(), SystemMouseCursors.grab);
      await mouse.down(at);
      await mouse.moveBy(const Offset(0, -30));
      await tester.pump();
      expect(_cursor(), SystemMouseCursors.grabbing);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(_cursor(), SystemMouseCursors.grab);
    });

    testWidgets('disabled, it is the basic arrow', (tester) async {
      await tester.pumpWidget(wheel(enabled: false));
      await _mouseAt(tester, tester.getCenter(find.byType(RawPicker)));
      expect(_cursor(), SystemMouseCursors.basic);
    });
  });
}
