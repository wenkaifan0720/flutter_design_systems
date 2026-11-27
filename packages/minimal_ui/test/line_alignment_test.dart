// Minimal's controls that share a line, held to ui_core's alignment check
// (DesignAlignmentMatrix): per row, as
// Android, iOS and macOS, one height, one centre, every label's capitals on
// the row's centre line (no exception held), each label's and glyph's ink
// centred; no control moving between platforms. And
// every text entry: its line in the middle of its box, the hint on the typed
// text's baseline, nothing in the editable's decoration but the hint, at each
// density, at text scale 1.5 and under a host InputDecorationTheme whose
// padding is uneven and whose constraints set a minimum.
@Tags(['goldens'])
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The densities Minimal offers, chosen (a theme that follows the platform
/// would change size between the platforms on purpose).
const Map<String, MinimalDensity> _densities = {
  'standard': MinimalDensity.standard,
  'comfortable': MinimalDensity.comfortable,
  'compact': MinimalDensity.compact,
};

/// What an app's theme may say about decorations: uneven padding, a dense
/// decoration, a minimum height. A text entry that leaves one to the theme
/// moves under it.
const InputDecorationTheme _hostDecoration = InputDecorationTheme(
  contentPadding: EdgeInsets.fromLTRB(20, 24, 20, 8),
  isDense: true,
  constraints: BoxConstraints(minHeight: 56),
);

/// Minimal as an app's page has it, at [density], its text at [scale], and
/// with [host] an app's decoration theme over the page. Read for a finger on
/// every platform: the checks compare platforms, and a pointer's 24 px tap
/// floor lays out less room round the same faces by design.
DesignAlignmentTheme _page(
  MinimalDensity density, {
  double scale = 1,
  bool host = false,
}) =>
    (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => MinimalHost(
        light: MinimalThemeData.preset(
          'standard',
          Brightness.light,
        ).copyWith(density: density),
        dark: MinimalThemeData.preset(
          'standard',
          Brightness.dark,
        ).copyWith(density: density),
        brightness: Brightness.light,
        child: navigator!,
      ),
      home: Builder(
        builder: (context) {
          final page = RawTapTargetScope(
            targets: const RawTapTargets(input: RawInput.touch),
            child: Material(type: MaterialType.transparency, child: child),
          );
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: host
                ? Theme(
                    data: Theme.of(context)
                        .copyWith(inputDecorationTheme: _hostDecoration),
                    child: page,
                  )
                : page,
          );
        },
      ),
    );

final DesignAlignmentMatrix minimalAlignment = DesignAlignmentMatrix(
  look: 'Minimal',
  themes: {
    for (final MapEntry(:key, :value) in _densities.entries) key: _page(value),
  },
  rows: [
    DesignAlignmentRow(
      size: 'default',
      entries: [
        DesignAlignmentEntry(
          DesignInlineControl.button,
          (context, label) => MinimalButton(label, onPressed: () {}),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.iconButton,
          (context, label) => MinimalIconButton(
            LucideIcons.plus,
            semanticLabel: label,
            onPressed: () {},
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.textField,
          (context, label) => MinimalTextField(hintText: label),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.searchField,
          (context, label) => MinimalSearchField(hintText: label),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.segmentedButton,
          (context, label) => MinimalSegmentedButton<int>(
            segments: [
              MinimalButtonSegment(0, label),
              const MinimalButtonSegment(1, 'TWO'),
            ],
            value: 0,
            expand: false,
            onChanged: (_) {},
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.numberField,
          (context, label) =>
              MinimalNumberField(value: 5, min: 0, max: 9, onChanged: (_) {}),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.labeledSwitch,
          (context, label) => MinimalSwitch(
            value: true,
            label: label,
            showLabel: true,
            onChanged: (_) {},
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.listTile,
          (context, label) => MinimalListTile(title: label, onTap: () {}),
        ),
      ],
      heightExceptions: {
        DesignInlineControl.searchField:
            'the field is drawn at the row height and stands centred in a '
            'band at the tap floor, so its clear glyph keeps a whole touch '
            'target',
        DesignInlineControl.labeledSwitch:
            'a track and its label with no frame around them: it stands on '
            "the row's centre, its label on the row's baseline",
        DesignInlineControl.listTile:
            'a list row is a whole tap target at every density (44, never '
            'under the tap floor), taller than the controls; it stands on '
            'their centre, never their height',
      },
    ),
    DesignAlignmentRow(
      size: 'small',
      entries: [
        DesignAlignmentEntry(
          DesignInlineControl.button,
          (context, label) => MinimalButton(
            label,
            size: MinimalButtonSize.small,
            onPressed: () {},
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.iconButton,
          (context, label) => MinimalIconButton(
            LucideIcons.plus,
            semanticLabel: label,
            size: MinimalButtonSize.small,
            onPressed: () {},
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.segmentedButton,
          (context, label) => MinimalSegmentedButton<int>(
            segments: [
              MinimalButtonSegment(0, label),
              const MinimalButtonSegment(1, 'TWO'),
            ],
            value: 0,
            small: true,
            expand: false,
            onChanged: (_) {},
          ),
        ),
        // Minimal's select on a line is the menu button showing its value
        // (MinimalSelect is a 44 px form row, the list tile's kind); it is
        // drawn at the small button's height, as a filter is.
        DesignAlignmentEntry(
          DesignInlineControl.select,
          (context, label) => MinimalMenu.button(
            LucideIcons.calendarDays,
            text: label,
            semanticLabel: 'Range',
            small: true,
            items: [MinimalMenuItem(label, onPressed: () {})],
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.chip,
          (context, label) => MinimalChip(label, onPressed: () {}),
        ),
      ],
    ),
    DesignAlignmentRow(
      size: 'large',
      entries: [
        DesignAlignmentEntry(
          DesignInlineControl.button,
          (context, label) => MinimalButton(
            label,
            size: MinimalButtonSize.large,
            onPressed: () {},
          ),
        ),
      ],
    ),
  ],
  absent: {
    DesignInlineControl.labeledCheckbox:
        'Minimal prints no label beside a checkbox: a check with words is a '
        '44 px row (a MinimalListTile with the MinimalCheckbox leading, the '
        "list row's kind), and MinimalCheckbox alone announces its label "
        'without printing it',
  },
);

/// Lucide's faces, under the names its package registers them by: the check
/// measures each glyph's ink, which a test's stand-in face does not draw.
Future<void> _loadLucide() => Future.wait([
  for (final cut in ['', '100', '200', '300', '400', '500', '600'])
    (FontLoader('packages/lucide_icons_flutter/Lucide$cut')..addFont(
          rootBundle.load(
            cut.isEmpty
                ? 'packages/lucide_icons_flutter/assets/lucide.ttf'
                : 'packages/lucide_icons_flutter/assets/build_font/'
                      'LucideVariable-w$cut.ttf',
          ),
        ))
        .load(),
]);

void main() {
  setUpAll(() => Future.wait([minimalLoadFonts(), _loadLucide()]));

  testWidgets('the controls that share a line share it', (tester) async {
    final report = await minimalAlignment.check(
      pump: tester.pumpWidget,
      runAsync: tester.runAsync,
    );
    report.verify();
  }, tags: 'goldens');

  testWidgets('every text entry keeps its line in the middle of its box', (
    tester,
  ) async {
    (await DesignTextEntryCheck(
      look: 'Minimal',
      themes: {
        for (final MapEntry(:key, :value) in _densities.entries) ...{
          key: _page(value),
          '$key ×1.5': _page(value, scale: 1.5),
          '$key under a host decoration theme': _page(value, host: true),
        },
      },
      entries: {
        'Text field': (context, controller, hint) =>
            MinimalTextField(controller: controller, hintText: hint),
        'Search field': (context, controller, hint) =>
            MinimalSearchField(controller: controller, hintText: hint),
        'Composer': (context, controller, hint) =>
            MinimalComposer(controller: controller, hintText: hint),
        'Input group': (context, controller, hint) =>
            MinimalInputGroup(controller: controller, hintText: hint),
        'Combobox': (context, controller, hint) => MinimalCombobox<String>(
          controller: controller,
          hintText: hint,
          options: const ['Lisbon', 'London', 'Lyon'],
        ),
      },
    ).check(pump: tester.pumpWidget)).verify();
  }, tags: 'goldens');
}
