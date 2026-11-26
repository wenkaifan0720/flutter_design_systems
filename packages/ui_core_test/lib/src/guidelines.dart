/// The behaviour checks as Flutter's accessibility guidelines, beside
/// `androidTapTargetGuideline` and `labeledTapTargetGuideline`: a test pumps
/// a screen and expects it to meet one.
///
/// ```dart
/// await expectLater(tester, meetsGuideline(checkableRoleGuideline));
/// ```
///
/// Each runs its check over every view's whole screen and fails with the
/// check's own lines. The check classes stay, for a test that checks one
/// part of a screen or names its look in the messages. The radio group check
/// is not one of them: it drives the keys over one group from the focusable
/// before it, and a guideline reads a screen without changing it. Nor is the
/// field nodes check, which compares a field before and after it is typed
/// in.
library;

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'alignment.dart';

/// One of the checks as an [AccessibilityGuideline]: [run] checks a view's
/// screen, and the guideline fails with every problem it finds on any view.
class DesignCheckGuideline extends AccessibilityGuideline {
  /// A guideline that runs [run] on each view's screen.
  const DesignCheckGuideline({required this.description, required this.run});

  @override
  final String description;

  /// Checks `screen`, the topmost widget of one view, under `tester`.
  final FutureOr<DesignAlignmentReport> Function(
    WidgetTester tester,
    BuildContext screen,
  )
  run;

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    final problems = <String>[];
    for (final screen in _screens(tester)) {
      problems.addAll((await run(tester, screen)).problems);
    }
    return problems.isEmpty
        ? const Evaluation.pass()
        : Evaluation.fail(problems.join('\n'));
  }
}

// The topmost widget of each view: the one whose box the view holds.
List<BuildContext> _screens(WidgetTester tester) {
  final found = <BuildContext>[];
  final roots = <RenderObject>{};
  for (final element in collectAllElementsFrom(
    tester.binding.rootElement!,
    skipOffstage: false,
  )) {
    final box = element.renderObject;
    if (box is RenderBox && box.parent is RenderView && roots.add(box)) {
      found.add(element);
    }
  }
  return found;
}

/// Each checkbox, radio and switch says what it is, as Flutter's do
/// (`DesignCheckableCheck`).
const AccessibilityGuideline checkableRoleGuideline = DesignCheckGuideline(
  description:
      'Each checkbox, radio and switch says what it is: no button beside a '
      'checked or toggled state, and a radio says whether it is checked.',
  run: _checkable,
);

/// Each control inside a field takes a tap through the semantics tree, and
/// the field's label is read once (`DesignFieldSemanticsCheck`).
const AccessibilityGuideline fieldSemanticsGuideline = DesignCheckGuideline(
  description:
      "Each control inside a field has a node of its own that takes a tap, "
      "and the field's label is read once.",
  run: _fieldSemantics,
);

/// Each text field says a name on its own node (`DesignTextFieldNameCheck`).
const AccessibilityGuideline textFieldNameGuideline = DesignCheckGuideline(
  description:
      'Each text field says a name (a label, a hint or a tooltip) on its own '
      'node.',
  run: _textFieldName,
);

/// Each tap target takes a tap over the floor for its input, where a screen
/// reader outlines it (`DesignTapTargetCheck`): what Flutter's tap-target
/// guidelines read from the semantics box alone, read from hit testing.
const AccessibilityGuideline tapTargetReachGuideline = DesignCheckGuideline(
  description:
      'Each tap target takes a tap over the floor for its input, and a '
      'screen reader outlines no more than a tap reaches.',
  run: _tapTarget,
);

/// Each control shows a pointer that says it acts, and nothing else does
/// (`DesignCursorCheck`).
const AccessibilityGuideline cursorGuideline = DesignCheckGuideline(
  description:
      'Each control shows the click cursor where it takes a click, and a '
      'text field the text cursor.',
  run: _cursor,
);

/// No words or icon read under the least any Material or Cupertino words
/// or icon read in their own palettes (`DesignContrastCheck`'s faults:
/// words 2.6:1, icons 1.9:1, a hint 1.7:1). Its findings under Material's
/// bar (4.5:1 and 3:1) don't fail it; Flutter's `textContrastGuideline`
/// holds every text to that bar, which Cupertino's own colours don't meet.
/// It reads the drawn pixels.
const AccessibilityGuideline contrastFloorGuideline = DesignCheckGuideline(
  description:
      'No words or icon read under the least Material or Cupertino draws in '
      'its own palettes.',
  run: _contrast,
);

/// Each control's words and icon sit on the middle of its face, as drawn
/// (`DesignLabelCheck`). It reads the drawn pixels.
const AccessibilityGuideline labelPlacementGuideline = DesignCheckGuideline(
  description:
      "Each control's words and icon sit on the middle of its face, as they "
      'are drawn.',
  run: _label,
);

/// Each tooltip is on the node of the control it tips
/// (`DesignTooltipNodeCheck`).
const AccessibilityGuideline tooltipNodeGuideline = DesignCheckGuideline(
  description:
      "Each tooltip is on its control's own node, so a screen reader reads "
      'them as one.',
  run: _tooltipNode,
);

/// Each open list opens below its field while below holds it
/// (`DesignListSideCheck`). It reads layout boxes.
const AccessibilityGuideline listSideGuideline = DesignCheckGuideline(
  description:
      'Each open list that asks for below opens below its field while the '
      'room below holds it.',
  run: _listSide,
);

/// Each open overlay shows whole: on the screen, nothing in it cut
/// (`DesignOverlayCheck`). It reads layout boxes.
const AccessibilityGuideline overlayGuideline = DesignCheckGuideline(
  description:
      'Each open popover, menu, list, sheet and dialog stands on the screen, '
      'nothing in it cut.',
  run: _overlay,
);

/// Nothing overflows its row or column (`DesignOverflowCheck`); run it at
/// text scale 2 too. It reads layout boxes.
const AccessibilityGuideline overflowGuideline = DesignCheckGuideline(
  description: 'No row or column holds more than it has room for.',
  run: _overflow,
);

/// Each control keeps a node of its own, a row's trailing control beside
/// the row's own (`DesignControlNodesCheck`).
const AccessibilityGuideline controlNodesGuideline = DesignCheckGuideline(
  description:
      'Each control keeps a node of its own that a tap through the semantics '
      'tree reaches.',
  run: _controlNodes,
);

DesignAlignmentReport _controlNodes(WidgetTester tester, BuildContext screen) =>
    const DesignControlNodesCheck(look: 'Screen').check(screen);

DesignAlignmentReport _overlay(WidgetTester tester, BuildContext screen) =>
    const DesignOverlayCheck(look: 'Screen').check(screen);

DesignAlignmentReport _overflow(WidgetTester tester, BuildContext screen) =>
    const DesignOverflowCheck(look: 'Screen').check(screen);

DesignAlignmentReport _tooltipNode(WidgetTester tester, BuildContext screen) =>
    const DesignTooltipNodeCheck(look: 'Screen').check(screen);

DesignAlignmentReport _listSide(WidgetTester tester, BuildContext screen) =>
    const DesignListSideCheck(look: 'Screen').check(screen);

DesignAlignmentReport _checkable(WidgetTester tester, BuildContext screen) =>
    const DesignCheckableCheck(look: 'Screen').check(screen);

DesignAlignmentReport _fieldSemantics(
  WidgetTester tester,
  BuildContext screen,
) => const DesignFieldSemanticsCheck(look: 'Screen').check(screen);

DesignAlignmentReport _textFieldName(
  WidgetTester tester,
  BuildContext screen,
) => const DesignTextFieldNameCheck(look: 'Screen').check(screen);

DesignAlignmentReport _tapTarget(WidgetTester tester, BuildContext screen) =>
    const DesignTapTargetCheck(look: 'Screen').check(screen);

DesignAlignmentReport _cursor(WidgetTester tester, BuildContext screen) =>
    const DesignCursorCheck(look: 'Screen').check(screen);

Future<DesignAlignmentReport> _contrast(
  WidgetTester tester,
  BuildContext screen,
) =>
    const DesignContrastCheck(look: 'Screen')
        .check(screen, runAsync: tester.runAsync);

Future<DesignAlignmentReport> _label(
  WidgetTester tester,
  BuildContext screen,
) =>
    const DesignLabelCheck(look: 'Screen')
        .check(screen, runAsync: tester.runAsync);
