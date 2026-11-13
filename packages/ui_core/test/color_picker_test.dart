import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

Set<WidgetState> _area = {};

// The bare reference painter: the colour as a fill, square thumbs, a grey
// track.
Widget _picker(
  DesignColorController c, {
  TextDirection direction = TextDirection.ltr,
}) => harness(_view(c), textDirection: direction);

Widget _view(DesignColorController c) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: 244,
    child: DesignColorPicker(
      controller: c,
      showAlpha: true,
      areaHeight: 100,
      areaBuilder: (context, area) => ColoredBox(
        color: area.color.withSaturation(1).withValue(1).toColor(),
      ),
      areaThumbBuilder: (context, area) {
        _area = area.states;
        return const SizedBox(width: 12, height: 12);
      },
      trackBuilder: (context, channel, color) => SizedBox(
        height: 8,
        child: ColoredBox(
          key: ValueKey('track ${channel.name}'),
          color: const Color(0xFFCCCCCC),
        ),
      ),
      thumbBuilder: (context, states) => const SizedBox(width: 12, height: 12),
    ),
  ),
);

late DesignColorController _cc;

void main() {
  behaviourContract(
    'DesignColorPicker',
    build: (c) => Owned<DesignColorController>(
      create: () => _cc = DesignColorController(const Color(0xFFFF0000)),
      builder: (context, c) => _view(c),
    ),
    node: () => find.bySemanticsLabel('Saturation and brightness'),
    semantics: isSemantics(
      label: 'Saturation and brightness',
      value: 'saturation 100%, brightness 100%',
      isSlider: true,
      isFocusable: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    noDisabledState:
        'a colour that may not change is a swatch; the look shows one',
    keyboard: (p) async {
      final t = p.tester;
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(p.data.value, 'saturation 99%, brightness 100%');
      await p.tabInto(find.bySemanticsLabel('Hue'));
      expect(
        semanticsOf(t, find.bySemanticsLabel('Hue')),
        isSemantics(isSlider: true, isFocused: true, value: '0 degrees'),
      );
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_cc.value.hue, closeTo(1, 0.5));
    },
    rtl: (p) async {
      await p.tabInto(find.bySemanticsLabel('Hue'));
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(
        _cc.value.hue,
        closeTo(1, 0.5),
        reason: 'Left is on, right to left',
      );
    },
    motion: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
    },
  );

  test('hex in and out; greys keep the hue; nonsense changes nothing', () {
    final c = DesignColorController(const Color(0xFF3366CC));
    expect(c.hex, '#3366CC');
    expect(c.setHex('#f80'), isTrue);
    expect(c.hex, '#FF8800');
    final hue = c.value.hue;
    expect(c.setHex('808080'), isTrue);
    expect(c.value.hue, hue, reason: 'a grey keeps the hue');
    expect(c.setHex('#12345'), isFalse);
    expect(c.setHex('zzzzzz'), isFalse);
    expect(c.hex, '#808080');
    expect(c.setHex('#11223380'), isTrue);
    expect(c.hex, '#11223380');
    expect(c.color.a, closeTo(0x80 / 255, 0.001));
  });

  testWidgets('the area: a press sets saturation across and brightness up; '
      'arrows step, Shift steps ten', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final c = DesignColorController(const Color(0xFFFF0000));
    addTearDown(c.dispose);
    await tester.pumpWidget(_picker(c));
    await tester.tapAt(const Offset(61, 25));
    await tester.pump();
    expect(c.value.saturation, closeTo(0.25, 0.001));
    expect(c.value.value, closeTo(0.75, 0.001));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_area, contains(WidgetState.focused));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(c.value.saturation, closeTo(0.26, 0.001));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(c.value.value, closeTo(0.65, 0.001));
  });

  testWidgets('the hue slider: a press, then keys; right to left mirrors '
      'it; a screen reader hears degrees', (tester) async {
    final semantics = tester.ensureSemantics();
    final c = DesignColorController(const Color(0xFFFF0000));
    addTearDown(c.dispose);
    await tester.pumpWidget(_picker(c, direction: TextDirection.rtl));
    final track = tester.getRect(find.byKey(const ValueKey('track hue')));
    expect(track.width, 200);
    await tester.tapAt(Offset(track.left + 50, track.center.dy));
    await tester.pump();
    expect(c.value.hue, closeTo(270, 0.5), reason: 'a quarter from the right');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Hue')),
      isSemantics(isSlider: true, value: '270 degrees'),
    );
    final owner = semanticsOwner();
    owner.performAction(
      tester.getSemantics(find.bySemanticsLabel('Hue')).id,
      SemanticsAction.increase,
    );
    expect(c.value.hue, closeTo(271, 0.5));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Alpha')),
      isSemantics(isSlider: true, value: '100%'),
    );
    semantics.dispose();
  });
}
