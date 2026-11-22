/// A field's list or calendar is the field's own: the docked calendar keeps
/// its container's width under its field on a desk, a list from a field
/// takes the exposed dropdown's own corners (`MenuDefaults.shape`), a
/// select shows its focus while its menu is open, as a docked date field
/// does while its calendar is, and never shows its value
/// selected as text, a combobox's toggle keeps one name while its expanded
/// state changes, and a tooltip is on its control's own node.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/keys.g.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

Widget host(Widget child) => MaterialApp(
  builder: (context, app) =>
      ExpressiveHost(light: bloom, brightness: Brightness.light, child: app!),
  home: Padding(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: 320, child: child),
    ),
  ),
);

const List<ExpressiveSelectOption<String>> projects = [
  ExpressiveSelectOption('studio', 'Open studio'),
  ExpressiveSelectOption('series', 'Workshop series'),
  ExpressiveSelectOption('launch', 'Spring launch'),
];

Widget select({String label = 'Project'}) => ExpressiveSelect<String>(
  label: label,
  options: projects,
  value: 'studio',
  onChanged: (_) {},
);

void main() {
  testWidgets('the docked calendar keeps its width under its field on a desk', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      host(
        ExpressiveDockedDatePicker(
          label: 'Due date',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.byType(ExpressiveDatePicker), findsOneWidget);
    expect(
      tester.getSize(find.byType(ExpressiveDatePicker)).width,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets("a list from a field takes the exposed dropdown's corners", (
    tester,
  ) async {
    await tester.pumpWidget(host(select()));
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    final surface = tester.widget<ExpressiveSurface>(
      find
          .descendant(
            of: find.byType(ExpressiveMenuSurface),
            matching: find.byType(ExpressiveSurface),
          )
          .first,
    );
    expect(surface.shape, bloom.shapes.of(ExpressiveShapeKey.cornerExtraSmall));
  });

  testWidgets('a select shows its focus while its menu is open', (
    tester,
  ) async {
    await tester.pumpWidget(host(select(label: 'Theme')));
    Color? labelColour() =>
        tester.widget<Text>(find.text('Theme')).style?.color;
    final resting = labelColour();
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.byType(ExpressiveMenuSurface), findsOneWidget);
    expect(labelColour(), bloom.colors.primary);
    expect(resting, isNot(bloom.colors.primary));
  });

  testWidgets('a docked date field shows its focus while its calendar is '
      'open, its own icon or a tap on its words having opened it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      host(
        ExpressiveDockedDatePicker(
          label: 'Due date',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
      ),
    );
    Color? labelColour() =>
        tester.widget<Text>(find.text('Due date')).style?.color;
    final resting = labelColour();
    expect(resting, isNot(bloom.colors.primary));
    for (final opener in [
      find.byType(EditableText),
      find.bySemanticsLabel('Select date'),
    ]) {
      await tester.tap(opener);
      await tester.pumpAndSettle();
      expect(find.byType(ExpressiveDatePicker), findsOneWidget);
      expect(labelColour(), bloom.colors.primary, reason: '$opener');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ExpressiveDatePicker), findsNothing);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(labelColour(), resting);
    }
  });

  testWidgets('a select never shows its value selected as text', (
    tester,
  ) async {
    await tester.pumpWidget(host(select()));
    // Focus that arrives without a tap (Tab here; a web page's pointer,
    // which the browser's input selects on) leaves the value unselected.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final field = tester.state<EditableTextState>(find.byType(EditableText));
    expect(field.widget.focusNode.hasFocus, isTrue);
    final selection = field.textEditingValue.selection;
    expect(selection.isCollapsed, isTrue, reason: '$selection');
  }, variant: TargetPlatformVariant.desktop());

  testWidgets("a combobox's toggle keeps one name, open or closed", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        ExpressiveCombobox<String>(
          label: 'Assignee',
          options: const [
            ExpressiveSelectOption('maya', 'Maya Reed'),
            ExpressiveSelectOption('sam', 'Sam Okafor'),
          ],
          onSelected: (_) {},
        ),
      ),
    );
    final toggle = find.bySemanticsLabel('Show suggestions');
    expect(
      tester.getSemantics(toggle),
      isSemantics(
        label: 'Show suggestions',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Show suggestions')),
      isSemantics(
        label: 'Show suggestions',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets("a plain tooltip is on its control's own node", (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Center(
          child: ExpressiveTooltip.plain(
            message: 'Share with your team',
            child: ExpressiveIconButton(
              ExpressiveSymbols.share,
              semanticLabel: 'Share',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Share')),
      isSemantics(
        label: 'Share',
        tooltip: 'Share with your team',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}
