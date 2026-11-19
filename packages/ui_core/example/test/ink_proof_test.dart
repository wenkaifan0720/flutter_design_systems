import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The example app under test.
// ignore: avoid_relative_lib_imports
import '../lib/ink_proof.dart';
import 'support/behaviour_contract.dart';

void main() {
  // A contract for a control with a completely custom face. Only the
  // public constructor, label, value and available actions matter here.
  behaviourContract(
    'Ink coverage',
    build: (c) {
      var coverage = 40;
      return Center(
        child: StatefulBuilder(
          builder: (context, setState) => InkCoverage(
            label: 'Ink coverage',
            value: coverage,
            onChanged: c.enabled
                ? (next) => setState(() => coverage = next)
                : null,
          ),
        ),
      );
    },
    node: () => find.bySemanticsLabel('Ink coverage'),
    root: () => find.byType(InkCoverage),
    semantics: isSemantics(
      label: 'Ink coverage',
      value: '40%',
      increasedValue: '50%',
      decreasedValue: '30%',
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    disabled: isSemantics(
      label: 'Ink coverage',
      value: '40%',
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasIncreaseAction: false,
      hasDecreaseAction: false,
    ),
    keyboard: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(p.data.value, '50%');
    },
    motion: (p) async {
      await p.tabInto();
      await p.tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await p.tester.pump();
    },
  );

  testWidgets(
    'Tab and Enter operate the assembled proof and reset both settings',
    (tester) async {
      await tester.pumpWidget(const InkProofApp());
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Textured')),
        isSemantics(isChecked: true),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ink coverage')).value,
        '50%',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Smooth')),
        isSemantics(isChecked: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ink coverage')).value,
        '40%',
      );
    },
  );

  testWidgets(
    'an Arabic proof keeps both stock actions at double text size in the dark',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final platform = tester.platformDispatcher;
      platform.localesTestValue = const [Locale('ar')];
      platform.textScaleFactorTestValue = 2;
      platform.platformBrightnessTestValue = Brightness.dark;
      addTearDown(platform.clearLocalesTestValue);
      addTearDown(platform.clearTextScaleFactorTestValue);
      addTearDown(platform.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const InkProofApp());
      await tester.pumpAndSettle();
      final heading = find.text('تجربة الطباعة');
      final context = tester.element(heading);
      expect(Directionality.of(context), TextDirection.rtl);
      expect(MediaQuery.textScalerOf(context).scale(12), 24);
      final nightInk = DefaultTextStyle.of(context).style.color;
      final first = find.bySemanticsLabel('ناعم');
      final second = find.bySemanticsLabel('خشن');
      expect(
        tester.getCenter(first).dx,
        greaterThan(tester.getCenter(second).dx),
      );
      final smooth = tester.getSemantics(first);
      final textured = tester.getSemantics(second);
      expect(smooth.id, isNot(textured.id));
      expect(smooth, isSemantics(isChecked: true, hasTapAction: true));
      expect(textured, isSemantics(isChecked: false, hasTapAction: true));
      final owner = tester.binding.renderViews.single.owner!.semanticsOwner!;
      // Act on just the textured stock, through its own accessibility node.
      owner.performAction(textured.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(second), isSemantics(isChecked: true));
      final column = find.bySemanticsLabel('تغطية الحبر');
      expect(tester.getSemantics(column).value, '٤٠٪\u061c');
      owner.performAction(
        tester.getSemantics(column).id,
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(tester.getSemantics(column).value, '٥٠٪\u061c');
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      platform.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        DefaultTextStyle.of(tester.element(heading)).style.color,
        isNot(nightInk),
      );
      expect(tester.getSemantics(second), isSemantics(isChecked: true));
      expect(tester.getSemantics(column).value, '٥٠٪\u061c');
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(tester.takeException(), isNull);
    },
  );
}
