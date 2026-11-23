import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  testWidgets('a closed select and its action sheet announce each name once', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    String? chosen;
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            BrutalTheme(data: BrutalThemeData.light(), child: child!),
        home: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrutalSelect<String>(
                labelText: 'Paper size',
                value: 'a4',
                items: const [BrutalSelectItem(value: 'a4', label: 'A4')],
                onChanged: (_) {},
              ),
              Builder(
                builder: (context) => BrutalButton(
                  'File actions',
                  onPressed: () async {
                    chosen = await showBrutalActionSheet<String>(
                      context: context,
                      title: 'File actions',
                      actions: const [
                        BrutalSheetAction(label: 'Pin', value: 'pin'),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final select = t.getSemantics(find.text('A4')).getSemanticsData();
    expect(select.label, 'Paper size');
    expect(select.value, 'A4');
    await t.tap(find.text('File actions'));
    await t.pumpAndSettle();
    expect(t.getSemantics(find.text('Pin')).getSemanticsData().label, 'Pin');
    await t.tap(find.text('Pin'));
    await t.pumpAndSettle();
    expect(chosen, 'pin');
    semantics.dispose();
  });
}
