// ui_core's alignment contract (design6 step 1): the controls that share a line, at each size and each density the
// look offers, drawn in its real fonts as Android, iOS and macOS. In a row: one height, one centre, one label baseline;
// in a control: its label's and icon's ink in its middle; across platforms: no control changes size or place. And
// every text entry through ui_core's text entry check, at text scale 1.5 and under a host input theme with uneven
// padding and a minimum height.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

void _tap() {}
void _drop(Object? _) {}

/// The look as an app's page gets it: the app's MaterialApp, the look's host at [density], a page.
DesignAlignmentTheme _look(
  NeumorphicDensity density, {
  double scale = 1,
  InputDecorationTheme? host,
}) =>
    (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: host == null ? null : ThemeData(inputDecorationTheme: host),
      builder: (context, navigator) {
        final page = NeumorphicHost(
          light: NeumorphicThemeData.porcelain().copyWith(density: density),
          brightness: Brightness.light,
          child: navigator!,
        );
        return scale == 1
            ? page
            : MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: page,
              );
      },
      home: Scaffold(body: child),
    );

/// Each density the look offers by name. The adaptive default is one of these per platform (compact on a desktop), as
/// Material's is, so it is checked as the three it can be.
final _densities = <String, DesignAlignmentTheme>{
  'standard': _look(NeumorphicDensity.standard),
  'comfortable': _look(NeumorphicDensity.comfortable),
  'compact': _look(NeumorphicDensity.compact),
};

/// The look's matrix, for this test and the review page's Rows sheet.
final neumorphicAlignment = DesignAlignmentMatrix(
  look: 'Neumorphism',
  themes: _densities,
  rows: [
    DesignAlignmentRow(
      size: 'small',
      entries: [
        DesignAlignmentEntry(
          DesignInlineControl.button,
          (context, label) => NeumorphicButton(
            label,
            size: NeumorphicButtonSize.small,
            onPressed: _tap,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.iconButton,
          (context, label) => NeumorphicIconButton(
            NeumorphicGlyphs.plus,
            label: label,
            size: 36,
            onPressed: _tap,
          ),
        ),
        // The chip is a small control: a 36 face and a caption label, as the small button has. Beside the medium
        // controls' 16 px labels its 14 px label could not share their baseline.
        DesignAlignmentEntry(
          DesignInlineControl.chip,
          (context, label) => NeumorphicChip(label, onPressed: _tap),
        ),
      ],
    ),
    DesignAlignmentRow(
      size: 'medium',
      entries: [
        DesignAlignmentEntry(
          DesignInlineControl.button,
          (context, label) => NeumorphicButton(label, onPressed: _tap),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.iconButton,
          (context, label) => NeumorphicIconButton(
            NeumorphicGlyphs.plus,
            label: label,
            onPressed: _tap,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.textField,
          (context, label) => NeumorphicTextField(hint: label),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.select,
          (context, label) => NeumorphicSelect<String>(
            options: [NeumorphicMenuItem(label, label)],
            value: label,
            onChanged: _drop,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.searchField,
          (context, label) => NeumorphicSearchField(hint: label),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.segmentedButton,
          (context, label) => NeumorphicSegmentedButton<int>(
            label: 'Choice',
            value: 0,
            segments: [
              NeumorphicButtonSegment(0, label),
              NeumorphicButtonSegment(1, label),
            ],
            onChanged: _drop,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.numberField,
          (context, label) => NeumorphicNumberField(
            value: label,
            onDecrease: _tap,
            onIncrease: _tap,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.labeledCheckbox,
          (context, label) =>
              NeumorphicCheckRow(label: label, value: false, onChanged: _drop),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.labeledSwitch,
          (context, label) =>
              NeumorphicSwitchRow(label: label, value: false, onChanged: _drop),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.listTile,
          (context, label) => NeumorphicListTile(
            title: label,
            isFirst: true,
            leading: const Icon(NeumorphicGlyphs.lamp, size: 22),
            trailing: Text(label),
            onPressed: _tap,
          ),
        ),
      ],
    ),
    DesignAlignmentRow(
      size: 'large',
      entries: [
        DesignAlignmentEntry(
          DesignInlineControl.button,
          (context, label) => NeumorphicButton(
            label,
            size: NeumorphicButtonSize.large,
            onPressed: _tap,
          ),
        ),
      ],
    ),
  ],
);

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });

  testWidgets('the controls that share a line line up', (tester) async {
    tester.view.physicalSize = const Size(2400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final report = await neumorphicAlignment.check(
      pump: tester.pumpWidget,
      runAsync: tester.runAsync,
    );
    expect(report.problems, isEmpty, reason: report.problems.join('\n'));
  }, tags: ['goldens']);

  testWidgets('every text entry is one structure', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    (await DesignTextEntryCheck(
      look: 'Neumorphism',
      themes: {
        ..._densities,
        'standard ×1.5': _look(NeumorphicDensity.standard, scale: 1.5),
        'standard under a host input theme': _look(
          NeumorphicDensity.standard,
          host: const InputDecorationTheme(
            contentPadding: EdgeInsets.fromLTRB(20, 24, 20, 8),
            isDense: true,
            constraints: BoxConstraints(minHeight: 56),
          ),
        ),
      },
      entries: {
        'Field': (context, controller, hint) =>
            NeumorphicTextField(controller: controller, hint: hint),
        'Composer': (context, controller, hint) => NeumorphicTextField(
          controller: controller,
          hint: hint,
          trailing: NeumorphicSendButton(onPressed: _tap),
        ),
        'Search': (context, controller, hint) =>
            NeumorphicSearchField(controller: controller, hint: hint),
        'Password': (context, controller, hint) =>
            NeumorphicPasswordField(controller: controller, hint: hint),
        'Input group': (context, controller, hint) => NeumorphicInputGroup(
          controller: controller,
          hint: hint,
          prefix: 'https://',
          suffix: '.com',
        ),
      },
    ).check(pump: tester.pumpWidget)).verify();
  });
}
