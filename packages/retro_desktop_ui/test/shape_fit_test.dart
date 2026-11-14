// The package emitter moves these gallery demos into the example app.
// ignore_for_file: avoid_relative_lib_imports
// A shipped shape set must leave content inside its outline at each supported density.
// The specimens cover the same public components as the gallery, including raised faces.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/charts.dart';
import '../example/lib/kit_gallery/demos/chrome.dart';
import '../example/lib/kit_gallery/demos/complete.dart';
import '../example/lib/kit_gallery/demos/controls.dart';
import '../example/lib/kit_gallery/demos/coverage.dart';
import '../example/lib/kit_gallery/demos/entries.dart';
import '../example/lib/kit_gallery/demos/foundations.dart';
import '../example/lib/kit_gallery/demos/frames.dart';
import '../example/lib/kit_gallery/demos/lists.dart';
import '../example/lib/kit_gallery/demos/objects.dart';
import '../example/lib/kit_gallery/demos/raised.dart';
import '../example/lib/kit_gallery/demos/rows.dart';

import 'support.dart';

final shapeSpecimens = <String, Widget Function()>{
  'kitSpecimenThumbGauge': kitSpecimenThumbGauge,
  'kitSpecimenGaugeBlock': kitSpecimenGaugeBlock,
  'kitSpecimenMonthGrid': kitSpecimenMonthGrid,
  'kitSpecimenMonthHead': kitSpecimenMonthHead,
  'kitSpecimenLegend': kitSpecimenLegend,
  'kitSpecimenPixelSky': kitSpecimenPixelSky,
  'kitSpecimenHourStrip': kitSpecimenHourStrip,
  'kitSpecimenRangeShape': kitSpecimenRangeShape,
  'kitSpecimenHatchBars': kitSpecimenHatchBars,
  'kitSpecimenDayBars': kitSpecimenDayBars,
  'kitSpecimenScaleBar': kitSpecimenScaleBar,
  'kitSpecimenSpanBar': kitSpecimenSpanBar,
  'kitSpecimenTopBar': kitSpecimenTopBar,
  'kitSpecimenTabBar': kitSpecimenTabBar,
  'kitSpecimenDeskStrip': kitSpecimenDeskStrip,
  'kitSpecimenDeskMarks': kitSpecimenDeskMarks,
  'kitSpecimenMark': kitSpecimenMark,
  'kitSpecimenPhoto': kitSpecimenPhoto,
  'kitSpecimenPictureCard': kitSpecimenPictureCard,
  'kitSpecimenLoadingState': kitSpecimenLoadingState,
  'kitSpecimenErrorState': kitSpecimenErrorState,
  'kitSpecimenButton': kitSpecimenButton,
  'kitSpecimenInput': kitSpecimenInput,
  'kitSpecimenScreen': kitSpecimenScreen,
  'kitSpecimenQuietButton': kitSpecimenQuietButton,
  'kitSpecimenDangerButton': kitSpecimenDangerButton,
  'kitSpecimenLink': kitSpecimenLink,
  'kitSpecimenNavigationDrawer': kitSpecimenNavigationDrawer,
  'kitSpecimenNavigationRail': kitSpecimenNavigationRail,
  'kitSpecimenPageDots': kitSpecimenPageDots,
  'kitSpecimenStepProgress': kitSpecimenStepProgress,
  'kitSpecimenNotice': kitSpecimenNotice,
  'kitSpecimenBadge': kitSpecimenBadge,
  'kitSpecimenCircularProgressIndicator': kitSpecimenCircularProgressIndicator,
  'kitSpecimenSkeleton': kitSpecimenSkeleton,
  'kitSpecimenSuccessState': kitSpecimenSuccessState,
  'kitSpecimenEmptyState': kitSpecimenEmptyState,
  'kitSpecimenAvatar': kitSpecimenAvatar,
  'kitSpecimenFacePile': kitSpecimenFacePile,
  'kitSpecimenPicture': kitSpecimenPicture,
  'kitSpecimenSurface': kitSpecimenSurface,
  'kitSpecimenCard': kitSpecimenCard,
  'kitSpecimenGroupedList': kitSpecimenGroupedList,
  'kitSpecimenDivider': kitSpecimenDivider,
  'kitSpecimenAmount': kitSpecimenAmount,
  'kitSpecimenMeter': kitSpecimenMeter,
  'kitSpecimenChart': kitSpecimenChart,
  'kitSpecimenLineChart': kitSpecimenLineChart,
  'kitSpecimenAreaChart': kitSpecimenAreaChart,
  'kitSpecimenDonutChart': kitSpecimenDonutChart,
  'kitSpecimenSparkline': kitSpecimenSparkline,
  'kitSpecimenChartEmpty': kitSpecimenChartEmpty,
  'kitSpecimenChartLoading': kitSpecimenChartLoading,
  'kitSpecimenBreadcrumbs': kitSpecimenBreadcrumbs,
  'kitSpecimenPagination': kitSpecimenPagination,
  'kitSpecimenRating': kitSpecimenRating,
  'kitSpecimenFileDrop': kitSpecimenFileDrop,
  'kitSpecimenActButton': kitSpecimenActButton,
  'kitSpecimenLineButton': kitSpecimenLineButton,
  'kitSpecimenIconButton': kitSpecimenIconButton,
  'kitSpecimenPopup': kitSpecimenPopup,
  'kitSpecimenTextBox': kitSpecimenTextBox,
  'kitSpecimenKbd': kitSpecimenKbd,
  'kitSpecimenCheck': kitSpecimenCheck,
  'kitSpecimenCheckRow': kitSpecimenCheckRow,
  'kitSpecimenChip': kitSpecimenChip,
  'kitSpecimenFlag': kitSpecimenFlag,
  'kitSpecimenPriority': kitSpecimenPriority,
  'kitSpecimenProgress': kitSpecimenProgress,
  'kitSpecimenEtch': kitSpecimenEtch,
  'kitSpecimenDisclosure': kitSpecimenDisclosure,
  'kitSpecimenChoices': kitSpecimenChoices,
  'kitSpecimenStepper': kitSpecimenStepper,
  'kitSpecimenGroupBox': kitSpecimenGroupBox,
  'kitSpecimenFolderTabs': kitSpecimenFolderTabs,
  'kitSpecimenSearchField': kitSpecimenSearchField,
  'kitSpecimenCodeField': kitSpecimenCodeField,
  'kitSpecimenSelect': kitSpecimenSelect,
  'kitSpecimenSwitch': kitSpecimenSwitch,
  'kitSpecimenSwitchRow': kitSpecimenSwitchRow,
  'kitSpecimenRadioGroup': kitSpecimenRadioGroup,
  'kitSpecimenSegmentedButton': kitSpecimenSegmentedButton,
  'kitSpecimenSlider': kitSpecimenSlider,
  'kitSpecimenDatePicker': kitSpecimenDatePicker,
  'kitSpecimenTimePicker': kitSpecimenTimePicker,
  'kitSpecimenBeside': kitSpecimenBeside,
  'kitSpecimenDesktop': kitSpecimenDesktop,
  'kitSpecimenWindow': kitSpecimenWindow,
  'kitSpecimenWindowClosing': kitSpecimenWindowClosing,
  'kitSpecimenWell': kitSpecimenWell,
  'kitSpecimenToolbar': kitSpecimenToolbar,
  'kitSpecimenShade': kitSpecimenShade,
  'kitSpecimenAlert': kitSpecimenAlert,
  'kitSpecimenEyebrow': kitSpecimenEyebrow,
  'kitSpecimenHead': kitSpecimenHead,
  'kitSpecimenSubHead': kitSpecimenSubHead,
  'kitSpecimenPartHead': kitSpecimenPartHead,
  'kitSpecimenLabel': kitSpecimenLabel,
  'kitSpecimenLabelled': kitSpecimenLabelled,
  'kitSpecimenMonogram': kitSpecimenMonogram,
  'kitSpecimenListView': kitSpecimenListView,
  'kitSpecimenTable': kitSpecimenTable,
  'kitSpecimenFolderGrid': kitSpecimenFolderGrid,
  'kitSpecimenFileGrid': kitSpecimenFileGrid,
  'kitSpecimenTreeBars': kitSpecimenTreeBars,
  'kitSpecimenChecklist': kitSpecimenChecklist,
  'kitSpecimenDocument': kitSpecimenDocument,
  'kitSpecimenDayTile': kitSpecimenDayTile,
  'kitSpecimenBigFigure': kitSpecimenBigFigure,
  'kitSpecimenHero': kitSpecimenHero,
  'kitSpecimenFigureHero': kitSpecimenFigureHero,
  'kitSpecimenReadingHead': kitSpecimenReadingHead,
  'kitSpecimenEmpty': kitSpecimenEmpty,
  'kitSpecimenDialog': kitSpecimenDialog,
  'kitSpecimenButtonGroup': kitSpecimenButtonGroup,
  'kitSpecimenToggleGroup': kitSpecimenToggleGroup,
  'kitSpecimenSplitButton': kitSpecimenSplitButton,
  'kitSpecimenTextArea': kitSpecimenTextArea,
  'kitSpecimenPasswordField': kitSpecimenPasswordField,
  'kitSpecimenInputGroup': kitSpecimenInputGroup,
  'kitSpecimenFormField': kitSpecimenFormField,
  'kitSpecimenRangeSlider': kitSpecimenRangeSlider,
  'kitSpecimenCombobox': kitSpecimenCombobox,
  'kitSpecimenCalendar': kitSpecimenCalendar,
  'kitSpecimenDateRangePicker': kitSpecimenDateRangePicker,
  'kitSpecimenColorPicker': kitSpecimenColorPicker,
  'kitSpecimenMenuBar': kitSpecimenMenuBar,
  'kitSpecimenDataTable': kitSpecimenDataTable,
  'kitSpecimenTreeView': kitSpecimenTreeView,
  'kitSpecimenScrollArea': kitSpecimenScrollArea,
  'kitSpecimenResizable': kitSpecimenResizable,
  'kitSpecimenReorderable': kitSpecimenReorderable,
  'kitSpecimenTimeline': kitSpecimenTimeline,
  'kitSpecimenSheet': kitSpecimenSheet,
  'kitSpecimenActionSheet': kitSpecimenActionSheet,
  'kitSpecimenPopover': kitSpecimenPopover,
  'kitSpecimenTag': kitSpecimenTag,
  'kitSpecimenStatusView': kitSpecimenStatusView,
  'kitSpecimenBottomSheet': kitSpecimenBottomSheet,
  'kitSpecimenMenu': kitSpecimenMenu,
  'kitSpecimenTooltip': kitSpecimenTooltip,
  'tooltip face': kitTooltipFace,
  'kitSpecimenSnackBar': kitSpecimenSnackBar,
  'kitSpecimenMenuAnchor': kitSpecimenMenuAnchor,
  'raise launchers': kitRaiseLaunchers,
  'kitSpecimenList': kitSpecimenList,
  'kitSpecimenActionRow': kitSpecimenActionRow,
  'kitSpecimenTaskRow': kitSpecimenTaskRow,
  'kitSpecimenFacts': kitSpecimenFacts,
  'kitSpecimenStats': kitSpecimenStats,
  'kitSpecimenReadings': kitSpecimenReadings,
  'kitSpecimenMeasures': kitSpecimenMeasures,
};

void main() {
  setUpAll(loadRetroDesktopFonts);
  test('the shape matrix includes every gallery specimen', () {
    final directory = [
      Directory('lib/kit_gallery/demos'),
      Directory('example/lib/kit_gallery/demos'),
    ].firstWhere((candidate) => candidate.existsSync());
    final declared = <String>{
      for (final file in directory.listSync().whereType<File>())
        if (file.path.endsWith('.dart'))
          for (final match in RegExp(
            r'^Widget (kitSpecimen\w+)\(',
            multiLine: true,
          ).allMatches(file.readAsStringSync()))
            match[1]!,
    };
    final tested = shapeSpecimens.keys
        .where((name) => name.startsWith('kitSpecimen'))
        .toSet();
    expect(declared, isNotEmpty);
    expect(tested, declared);
  });
  // Each appearance as drawn: the corners follow it.
  const sets = <String, RetroDesktopAppearance>{
    'platinum': RetroDesktopAppearance.platinum,
    'chisel': RetroDesktopAppearance.chisel,
  };
  const densities = <String, RetroDesktopDensity>{
    'compact': RetroDesktopDensity.compact,
    'standard': RetroDesktopDensity.standard,
    'comfortable': RetroDesktopDensity.comfortable,
  };
  for (final set in sets.entries) {
    for (final density in densities.entries) {
      for (final width in [120.0, 240.0, 390.0]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets(
            '${set.key} ${density.key} at $width and $scale keeps content inside',
            (tester) async {
              tester.view.physicalSize = Size(width, 1600);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              final theme = RetroDesktopThemeData.classic().copyWith(
                appearance: set.value,
                density: density.value,
              );
              var faces = 0;
              final failures = <String>[];
              for (final specimen in shapeSpecimens.entries) {
                await tester.pumpWidget(
                  MaterialApp(
                    builder: (context, child) => RetroDesktopTheme(
                      data: theme,
                      child: MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(textScaler: TextScaler.linear(scale)),
                        child: child!,
                      ),
                    ),
                    home: KeyedSubtree(
                      key: ValueKey(specimen.key),
                      child: specimen.key == 'kitSpecimenScreen'
                          ? specimen.value()
                          : SingleChildScrollView(child: specimen.value()),
                    ),
                  ),
                );
                await tester.pump();
                final error = tester.takeException();
                if (error != null) {
                  failures.add('${specimen.key}: $error');
                  continue;
                }
                void checkFace(RenderBox frame, RenderBox? content, Path path) {
                  // What the outline must never cut is ink: the words and
                  // glyphs set inside it. Fills flush with the face (a
                  // header band, a selected row, a picture) are clipped to
                  // its inner corners on purpose, so the measure is each
                  // line of text's glyph boxes, not the content's box.
                  if (content == null ||
                      !content.hasSize ||
                      content.size.isEmpty) {
                    return;
                  }
                  final whole = Offset.zero & frame.size;
                  void visit(RenderObject node) {
                    if (node is RenderParagraph && node.hasSize) {
                      final text = node.text.toPlainText();
                      final boxes = node.getBoxesForSelection(
                        TextSelection(baseOffset: 0, extentOffset: text.length),
                      );
                      final transform = node.getTransformTo(frame);
                      for (final box in boxes) {
                        final line = MatrixUtils.transformRect(
                          transform,
                          box.toRect(),
                        );
                        // The letters' bodies: a line box less its leading,
                        // ascender room and descenders (a quarter above and
                        // below), the band a capsule's round ends must clear.
                        final ink = Rect.fromLTRB(
                          line.left + 1,
                          line.top + line.height / 4,
                          line.right - 1,
                          line.bottom - line.height / 4,
                        );
                        // Scrolled or overflowing lines past the frame's
                        // box are the viewport's to clip, not the outline's.
                        if (ink.isEmpty ||
                            !whole.contains(ink.topLeft) ||
                            !whole.contains(ink.bottomRight)) {
                          continue;
                        }
                        for (final point in [
                          ink.topLeft,
                          ink.topRight,
                          ink.bottomLeft,
                          ink.bottomRight,
                        ]) {
                          if (!path.contains(point)) {
                            failures.add(
                              '${specimen.key}: "$text" at $point outside '
                              '${frame.size}',
                            );
                          }
                        }
                      }
                      return;
                    }
                    node.visitChildren(visit);
                  }

                  visit(content);
                  faces++;
                }

                for (final element in find.byType(ClipPath).evaluate()) {
                  final widget = element.widget as ClipPath;
                  final clipper = widget.clipper;
                  if (clipper is! ShapeBorderClipper) continue;
                  final frame = element.renderObject! as RenderClipPath;
                  checkFace(frame, frame.child, clipper.getClip(frame.size));
                }
                // Marks such as monograms paint their outline without clipping.
                // Their child must respect the same inset as a clipped face.
                for (final element in find.byType(DecoratedBox).evaluate()) {
                  final decoration =
                      (element.widget as DecoratedBox).decoration;
                  if (decoration is! ShapeDecoration) continue;
                  final frame = element.renderObject! as RenderDecoratedBox;
                  checkFace(
                    frame,
                    frame.child,
                    decoration.shape.getOuterPath(
                      Offset.zero & frame.size,
                      textDirection: Directionality.of(element),
                    ),
                  );
                }
              }
              expect(failures, isEmpty, reason: failures.join('\n'));
              expect(
                faces,
                greaterThan(40),
                reason: 'The matrix must reach the component faces.',
              );
              debugPrint(
                'SHAPE FIT ${set.key}/${density.key}/$width/$scale: '
                '${shapeSpecimens.length} specimens, $faces outlined faces',
              );
            },
          );
        }
      }
    }
  }
}
