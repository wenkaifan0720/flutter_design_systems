// Every shipped shape set must contain the painted content it surrounds.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';
import 'shape_fit_support.dart';

final _parts = <String, Widget Function()>{
  'act': () => ComicButton.filled('Save', onPressed: () {}),
  'small act': () =>
      ComicButton.filled('Save', size: ComicButtonSize.small, onPressed: () {}),
  'wide act': () => ComicButton.filled(
    'Save issue',
    wide: true,
    icon: ComicGlyphs.plus,
    onPressed: () {},
  ),
  'line': () => ComicButton('Share', onPressed: () {}),
  'danger': () => ComicButton(
    'Delete',
    isDestructiveAction: true,
    icon: ComicGlyphs.trash2,
    onPressed: () {},
  ),
  'icon': () =>
      ComicIconButton(ComicGlyphs.search, label: 'Search', onPressed: () {}),
  'checkbox': () =>
      ComicCheckbox(label: 'Keep', value: true, onChanged: (_) {}),
  'check row': () =>
      ComicCheckRow(label: 'Keep', value: true, onChanged: (_) {}),
  'radio': () => ComicRadioGroup(
    label: 'Edition',
    value: 1,
    options: const [ComicRadio(1, 'Print')],
    onChanged: (_) {},
  ),
  'switch': () => ComicSwitch(value: true, onChanged: (_) {}),
  'field': () => const ComicTextField(hint: 'Your name'),
  'filled field': () => const ComicTextField(initialValue: 'Thursday'),
  'reply': () => const ComicTextField(hint: 'A reply', onPaper: true),
  'search': () => ComicSearchField(hint: 'Find issue', onChanged: (_) {}),
  'area': () => const ComicTextArea(hint: 'A few words'),
  'code': () => const ComicInputOtp(label: 'Code'),
  'select': () => ComicSelect<String>(
    value: 'p',
    options: const [ComicSelectOption('p', 'Print')],
    onChanged: (_) {},
  ),
  'value': () => ComicSelectField(value: 'Thursday', onPressed: () {}),
  'chip': () => ComicChip('Print', icon: ComicGlyphs.search, onPressed: () {}),
  'remove chip': () => ComicChip('Print', onDeleted: () {}),
  'option': () =>
      ComicChoiceBox(onPressed: () {}, child: const Text('Your content')),
  'segments': () => ComicSegmentedButton(
    label: 'View',
    value: 1,
    segments: const [
      ComicButtonSegment(1, 'Day'),
      ComicButtonSegment(2, 'Week'),
    ],
    onChanged: (_) {},
  ),
  'stepper': () => ComicNumberField(value: 3, onChanged: (_) {}),
  'slider': () => ComicSlider(label: 'Level', value: .5, onChanged: (_) {}),
  'caption': () => const ComicCaption('Narration', free: true),
  'badge': () => const ComicBadge(12),
  'avatar': () => const ComicColumn(
    children: [
      ComicAvatar('AB'),
      ComicAvatarGroup([ComicFace('NW'), ComicFace('AK')]),
    ],
  ),
  'grouped key values': () => const ComicListSection(
    children: [
      ComicKvRow('Pages', '24', isFirst: true),
      ComicKvRow('Print run', '500'),
    ],
  ),
  'grouped list rows': () => const ComicListSection(
    children: [
      ComicListTile(title: 'First', subtitle: 'Issue', isFirst: true),
      ComicListTile(title: 'Second', trailing: Text('24')),
    ],
  ),
  'table cells': () => const ComicTable(
    columns: ['Issue', 'Pages'],
    rows: [
      ['Twelve', '24'],
      ['Thirteen', '32'],
    ],
  ),
  'panel': () => const ComicPanel(child: Text('A short issue.')),
  'well': () => const ComicWell(child: Text('A short issue.')),
  'card': () =>
      const ComicCard(title: 'Issue', children: [Text('A short issue.')]),
  'dialog': () =>
      const ComicDialog(title: 'Issue', message: 'Keep this issue?'),
  'sheet': () => const ComicBottomSheet(
    title: 'Issue',
    showClose: false,
    child: Text('A short issue.'),
  ),
  'menu': () => ComicMenu<String>(
    items: const [ComicMenuItem('save', 'Save')],
    onSelected: (_) {},
  ),
  'snack': () => const ComicSnackBar('Issue saved'),
  'tooltip': () => const ComicTooltipFace(message: 'Save this issue'),
  'date': () => ComicDatePicker(
    value: DateTime(2026, 11, 6),
    currentDate: DateTime(2026, 11, 6),
    onChanged: (_) {},
  ),
  'time': () =>
      ComicTimePicker(value: const ComicTime(12, 0), onChanged: (_) {}),
};

void main() {
  setUpAll(loadComicFonts);
  final sets = {
    'square': const ComicShapes(),
    'small': ComicShapes.rounded(4),
    'medium': ComicShapes.rounded(8),
    'large': ComicShapes.rounded(12),
  };
  for (final MapEntry(key: set, value: shapes) in sets.entries) {
    for (final width in [120.0, 240.0, 390.0]) {
      for (final density in [
        ComicDensity.standard,
        ComicDensity.comfortable,
        ComicDensity.compact,
      ]) {
        for (final scale in [1.0, 1.3]) {
          for (final MapEntry(key: name, value: build) in _parts.entries) {
            testWidgets(
              '$name / $set / $width / ${density.vertical} / $scale',
              (tester) async {
                final theme = ComicThemeData.offset().copyWith(
                  shapes: shapes,
                  density: density,
                );
                await tester.pumpWidget(
                  MaterialApp(
                    home: ComicTheme(
                      data: theme,
                      child: MediaQuery(
                        data: MediaQueryData(
                          textScaler: TextScaler.linear(scale),
                          disableAnimations: true,
                        ),
                        child: SingleChildScrollView(
                          child: Center(
                            child: SizedBox(width: width, child: build()),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                expectComicContentClearance(tester);
                if (name == 'avatar') {
                  for (final paragraph
                      in tester.renderObjectList<RenderParagraph>(
                        find.byType(RichText),
                      )) {
                    final text = paragraph.text.toPlainText();
                    for (final box in paragraph.getBoxesForSelection(
                      TextSelection(baseOffset: 0, extentOffset: text.length),
                    )) {
                      final painted = MatrixUtils.transformRect(
                        paragraph.getTransformTo(null),
                        box.toRect(),
                      );
                      expect(
                        painted.height,
                        greaterThanOrEqualTo(10),
                        reason:
                            'Initials must remain readable inside custom marks',
                      );
                    }
                  }
                }
              },
            );
          }
        }
      }
    }
  }
}
