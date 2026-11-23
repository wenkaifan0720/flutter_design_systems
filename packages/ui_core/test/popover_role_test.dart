import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _anchorKey = ValueKey('anchor');

// A popover named 'Sort', of [role] (none: no role given), whose surface
// holds two buttons.
Widget _popover({SemanticsRole? role}) => Align(
  alignment: Alignment.topCenter,
  child: RawPopover(
    role: role,
    semanticLabel: 'Sort',
    anchorBuilder: (context, anchor) => RawButton(
      onPressed: anchor.toggle,
      builder: (context, states, _) => plainFace('Open', key: _anchorKey),
    ),
    overlayBuilder: (context, info) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final words in ['Newest', 'Oldest'])
          RawButton(
            onPressed: info.close,
            builder: (context, states, _) => plainFace(words),
          ),
      ],
    ),
  ),
);

void main() {
  for (final role in [
    SemanticsRole.menu,
    SemanticsRole.dialog,
    SemanticsRole.alertDialog,
  ]) {
    testWidgets("${role.name}: the surface's node carries the role beside its "
        'label', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(harness(_popover(role: role)));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      final data = tester
          .getSemantics(find.bySemanticsLabel('Sort'))
          .getSemanticsData();
      expect(data.role, role);
      expect(data.label, 'Sort');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Newest')),
        isSemantics(label: 'Newest', isButton: true),
        reason: 'its children keep their own nodes',
      );
      semantics.dispose();
    });
  }

  testWidgets('with no role given, its node has none, as before', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(_popover()));
    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle();
    final data = tester
        .getSemantics(find.bySemanticsLabel('Sort'))
        .getSemanticsData();
    expect(data.role, SemanticsRole.none);
    expect(data.label, 'Sort');
    semantics.dispose();
  });
}
