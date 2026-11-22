// A dialog that asks more than yes or no (Unsaved changes: Cancel, Discard,
// Save changes) takes a list of actions, as Material's AlertDialog does: in a
// row at the end when they fit, stacked with the main one on top when they
// don't, each answering the route itself, raised or in place.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

List<RawDialogAction> _actions(BuildContext context, {VoidCallback? save}) => [
  RawDialogAction(
    label: 'Cancel',
    onPressed: () => Navigator.of(context).pop('cancel'),
  ),
  RawDialogAction(
    label: 'Discard',
    isDestructiveAction: true,
    onPressed: () => Navigator.of(context).pop('discard'),
  ),
  RawDialogAction(
    label: 'Save changes',
    isDefaultAction: true,
    onPressed: save ?? () => Navigator.of(context).pop('save'),
  ),
];

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: MinimalHost(
      light: MinimalThemeData.preset('standard', Brightness.light),
      dark: MinimalThemeData.preset('standard', Brightness.dark),
      brightness: Brightness.light,
      child: navigator!,
    ),
  ),
  home: MinimalScaffold(padding: EdgeInsets.zero, body: home),
);

void _size(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(minimalLoadFonts);

  testWidgets('raised, three actions stand in a row and each answers', (
    tester,
  ) async {
    _size(tester, 1440);
    Object? answer = 'none';
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showMinimalDialog<String>(
                context,
                builder: (context) => MinimalDialog(
                  title: 'Unsaved changes',
                  message: 'Save your changes before leaving this task?',
                  actions: _actions(context),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final cancel = tester.getRect(find.text('Cancel'));
    final discard = tester.getRect(find.text('Discard'));
    final save = tester.getRect(find.text('Save changes'));
    // One row, in the order given, the main one at the end.
    expect(discard.center.dy, closeTo(cancel.center.dy, 0.5));
    expect(save.center.dy, closeTo(cancel.center.dy, 0.5));
    expect(cancel.right, lessThan(discard.left));
    expect(discard.right, lessThan(save.left));
    // With a destructive answer, the focus opens on the safe one.
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.descendant(
        of: find.byWidget(focused.widget),
        matching: find.text('Cancel'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(answer, 'save');
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets(
    'raised on a phone at large text, they stack, the main one on top',
    (tester) async {
      _size(tester, 390);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showMinimalDialog<String>(
                context,
                builder: (context) => MinimalDialog(
                  title: 'Unsaved changes',
                  actions: _actions(context),
                ),
              ),
              child: const Text('open'),
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final cancel = tester.getRect(find.text('Cancel'));
      final discard = tester.getRect(find.text('Discard'));
      final save = tester.getRect(find.text('Save changes'));
      expect(save.bottom, lessThanOrEqualTo(discard.top));
      expect(discard.bottom, lessThanOrEqualTo(cancel.top));
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsNothing);
    },
  );

  testWidgets('in place, each action wears its register and Enter saves', (
    tester,
  ) async {
    _size(tester, 1440);
    var saved = 0;
    await tester.pumpWidget(
      _app(
        Center(
          child: Builder(
            builder: (context) => MinimalDialog(
              title: 'Unsaved changes',
              autofocus: true,
              actions: _actions(context, save: () => saved++),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    MinimalButtonVariant variant(String label) => tester
        .widget<MinimalButton>(find.widgetWithText(MinimalButton, label))
        .variant;
    expect(variant('Cancel'), MinimalButtonVariant.secondary);
    expect(variant('Discard'), MinimalButtonVariant.destructive);
    expect(variant('Save changes'), MinimalButtonVariant.primary);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(saved, 1);
  });

  testWidgets(
    'in place, when they do not share a line, the main one is on top',
    (tester) async {
      _size(tester, 390);
      await tester.pumpWidget(
        _app(
          Center(
            child: Builder(
              builder: (context) => MinimalDialog(
                title: 'Unsaved changes',
                actions: _actions(context, save: () {}),
              ),
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      final cancel = tester.getRect(find.text('Cancel'));
      final save = tester.getRect(find.text('Save changes'));
      expect(save.bottom, lessThanOrEqualTo(cancel.top));
    },
  );
}
