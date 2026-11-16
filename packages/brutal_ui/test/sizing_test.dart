// A button keeps its own height wherever it stands, as Flutter's do: under a
// Center on a whole screen (loose constraints, the screen's height bounded) it
// is a control's height, not the screen's.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  final buttons = <String, Widget>{
    'BrutalButton': BrutalButton('Save', onPressed: () {}),
    'BrutalButton.filled': BrutalButton.filled('Buy tickets', onPressed: () {}),
    'BrutalButton.text': BrutalButton.text('Not now', onPressed: () {}),
    'BrutalIconButton': BrutalIconButton(
      onPressed: () {},
      tooltip: 'More',
      icon: const Icon(LucideIcons.ellipsis),
    ),
  };
  for (final MapEntry(key: name, value: button) in buttons.entries) {
    testWidgets('$name under a Center keeps its own height', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: BrutalTheme(
            data: BrutalThemeData.light(),
            child: Center(child: button),
          ),
        ),
      );
      final theme = BrutalTheme.of(tester.element(find.byWidget(button)));
      final height = tester.getSize(find.byWidget(button)).height;
      // The control's height, its tap target's at most, never the screen's.
      expect(
        height,
        lessThanOrEqualTo(
          theme.controlHeight + theme.shadowOffset + theme.borderWidth + 8,
        ),
        reason: name,
      );
    });
  }
}
