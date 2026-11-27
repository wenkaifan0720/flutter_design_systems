// showMinimalDialog(isAlert: true): a question that wants an answer is an
// alert to a screen reader (ui_core's RawModalDialogRoute, SemanticsRole.
// alertDialog), and a tap on the scrim leaves it standing; a plain dialog
// is a dialog and the scrim closes it; barrierDismissible overrides either.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Future<Future<bool?>> _raise(
  WidgetTester tester, {
  bool isAlert = false,
  bool? barrierDismissible,
}) async {
  late Future<bool?> answer;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MinimalHost(child: child!),
      home: Builder(
        builder: (context) => Center(
          child: MinimalButton(
            'Ask',
            onPressed: () => answer = showMinimalDialog<bool>(
              context,
              isAlert: isAlert,
              barrierDismissible: barrierDismissible,
              builder: (context) => const MinimalDialog(
                title: 'Delete "Stoner"?',
                confirmLabel: 'Delete',
                cancelLabel: 'Keep',
                destructive: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ask'));
  await tester.pumpAndSettle();
  return answer;
}

Set<SemanticsRole> _roles(WidgetTester tester) {
  final roles = <SemanticsRole>{};
  bool visit(SemanticsNode node) {
    roles.add(node.getSemanticsData().role);
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return roles;
}

void main() {
  testWidgets('an alert is heard as an alert; the scrim leaves it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final answer = await _raise(tester, isAlert: true);
    expect(_roles(tester), contains(SemanticsRole.alertDialog));
    expect(_roles(tester), isNot(contains(SemanticsRole.dialog)));
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Stoner"?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(await answer, isFalse);
    semantics.dispose();
  });

  testWidgets('a dialog is heard as a dialog; the scrim closes it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final answer = await _raise(tester);
    expect(_roles(tester), contains(SemanticsRole.dialog));
    expect(_roles(tester), isNot(contains(SemanticsRole.alertDialog)));
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Stoner"?'), findsNothing);
    expect(await answer, isNull);
    semantics.dispose();
  });

  testWidgets('barrierDismissible overrides the alert', (tester) async {
    final answer = await _raise(
      tester,
      isAlert: true,
      barrierDismissible: true,
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Stoner"?'), findsNothing);
    expect(await answer, isNull);
  });

  testWidgets('Escape still answers an alert', (tester) async {
    final answer = await _raise(tester, isAlert: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Delete "Stoner"?'), findsNothing);
    expect(await answer, isNull);
  });
}
