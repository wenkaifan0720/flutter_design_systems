// Frosted's finger floor as a guideline: ui_core's (RawTapTargets.fallback's touch, 40 by 40, WCAG 2.2's target size
// minimum). Flutter's Android 48 and iOS 44 guidelines ask more than the family's floor.
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

/// Every target reaches Frosted's finger floor, 40 by 40.
final AccessibilityGuideline touchFloorGuideline = MinimumTapTargetGuideline(
  size: FrostedBreakpoints.targets.touch,
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
);
