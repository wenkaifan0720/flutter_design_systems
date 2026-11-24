// The names ui_core renamed that it still carries, each with what to use: 0.4.0's DesignLocalizations, and the
// Design* names 0.6.0 gave Raw* names (the inventory's are in inventory.dart). `dart fix` makes each rename
// (lib/fix_data.yaml), the renames of the names ui_core 0.6.0 removed among them.
import 'package:flutter/physics.dart' show SpringSimulation, Tolerance;
import 'package:flutter/widgets.dart';

import 'adaptive_shell.dart';
import 'anchored_overlay.dart';
import 'barrier.dart';
import 'cap_center.dart';
import 'chart.dart';
import 'chart_scale.dart';
import 'combobox.dart';
import 'command_palette.dart';
import 'control_box.dart';
import 'dialog.dart';
import 'form_field.dart';
import 'haptics.dart';
import 'input_group.dart';
import 'keyline_region.dart';
import 'list_detail.dart';
import 'localizations.dart';
import 'motion.dart';
import 'page_transitions.dart';
import 'scroll_area.dart';
import 'semantics_proxy.dart';
import 'shortcut_label.dart';
import 'spacing.dart';
import 'style.dart';
import 'tap_target.dart';
import 'tree.dart';
import 'value_handle.dart';

/// Renamed [RawWidgetsLocalizations] in ui_core 0.4.0.
@Deprecated(
  'Use RawWidgetsLocalizations. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignLocalizations = RawWidgetsLocalizations;

/// Renamed [RawAdaptiveShell] in ui_core 0.6.0.
@Deprecated(
  'Use RawAdaptiveShell. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignAdaptiveShell = RawAdaptiveShell;

/// Renamed [RawBandScale] in ui_core 0.6.0.
@Deprecated(
  'Use RawBandScale. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignBandScale = RawBandScale;

/// Renamed [RawBarrierBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawBarrierBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignBarrierBuilder = RawBarrierBuilder;

/// Renamed [RawBranchBackBehavior] in ui_core 0.6.0.
@Deprecated(
  'Use RawBranchBackBehavior. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignBranchBackBehavior = RawBranchBackBehavior;

/// Renamed [RawCapCenter] in ui_core 0.6.0.
@Deprecated(
  'Use RawCapCenter. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignCapCenter = RawCapCenter;

/// Renamed [RawChart] in ui_core 0.6.0.
@Deprecated('Use RawChart. This feature was deprecated after ui_core 0.6.0.')
typedef DesignChart = RawChart;

/// Renamed [RawChartBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartBuilder = RawChartBuilder;

/// Renamed [RawChartDetails] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartDetails. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartDetails = RawChartDetails;

/// Renamed [RawChartFormat] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartFormat. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartFormat = RawChartFormat;

/// Renamed [RawChartPoint] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartPoint. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartPoint = RawChartPoint;

/// Renamed [RawChartPointRef] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartPointRef. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartPointRef = RawChartPointRef;

/// Renamed [RawChartSeries] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartSeries. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartSeries = RawChartSeries;

/// Renamed [RawChartTable] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartTable. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartTable = RawChartTable;

/// Renamed [RawChartTableCellBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartTableCellBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartTableCellBuilder = RawChartTableCellBuilder;

/// Renamed [RawChartTableCellDetails] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartTableCellDetails. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartTableCellDetails = RawChartTableCellDetails;

/// Renamed [RawChartValueBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartValueBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartValueBuilder = RawChartValueBuilder;

/// Renamed [RawChartValueFormat] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartValueFormat. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartValueFormat = RawChartValueFormat;

/// Renamed [RawChartXAxis] in ui_core 0.6.0.
@Deprecated(
  'Use RawChartXAxis. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignChartXAxis = RawChartXAxis;

/// Renamed [RawComboboxField] in ui_core 0.6.0.
@Deprecated(
  'Use RawComboboxField. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignComboboxField = RawComboboxField;

/// Renamed [RawComboboxFieldBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawComboboxFieldBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignComboboxFieldBuilder = RawComboboxFieldBuilder;

/// Renamed [RawControlBox] in ui_core 0.6.0.
@Deprecated(
  'Use RawControlBox. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignControlBox = RawControlBox;

/// Renamed [RawDensity] in ui_core 0.6.0.
@Deprecated('Use RawDensity. This feature was deprecated after ui_core 0.6.0.')
typedef DesignDensity = RawDensity;

/// Renamed [RawDestinationBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawDestinationBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignDestinationBuilder = RawDestinationBuilder;

/// Renamed [RawDestinationDetails] in ui_core 0.6.0.
@Deprecated(
  'Use RawDestinationDetails. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignDestinationDetails = RawDestinationDetails;

/// Renamed [RawDialogBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawDialogBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignDialogBuilder = RawDialogBuilder;

/// Renamed [RawDialogDetails] in ui_core 0.6.0.
@Deprecated(
  'Use RawDialogDetails. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignDialogDetails = RawDialogDetails;

/// Renamed [RawModalDialogRoute] in ui_core 0.6.0.
@Deprecated(
  'Use RawModalDialogRoute. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignDialogRoute<T> = RawModalDialogRoute<T>;

/// Renamed [RawForm] in ui_core 0.6.0.
@Deprecated('Use RawForm. This feature was deprecated after ui_core 0.6.0.')
typedef DesignForm = RawForm;

/// Renamed [RawFormField] in ui_core 0.6.0.
@Deprecated(
  'Use RawFormField. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignFormField<T> = RawFormField<T>;

/// Renamed [RawFormState] in ui_core 0.6.0.
@Deprecated(
  'Use RawFormState. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignFormState = RawFormState;

/// Renamed [RawHandleBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawHandleBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignHandleBuilder = RawHandleBuilder;

/// Renamed [RawHaptics] in ui_core 0.6.0.
@Deprecated('Use RawHaptics. This feature was deprecated after ui_core 0.6.0.')
typedef DesignHaptics = RawHaptics;

/// Renamed [RawHapticsScope] in ui_core 0.6.0.
@Deprecated(
  'Use RawHapticsScope. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignHapticsScope = RawHapticsScope;

/// Renamed [RawInput] in ui_core 0.6.0.
@Deprecated('Use RawInput. This feature was deprecated after ui_core 0.6.0.')
typedef DesignInput = RawInput;

/// Renamed [RawInputGroup] in ui_core 0.6.0.
@Deprecated(
  'Use RawInputGroup. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignInputGroup = RawInputGroup;

/// Renamed [RawInputGroupBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawInputGroupBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignInputGroupBuilder = RawInputGroupBuilder;

/// Renamed [RawKeylineFace] in ui_core 0.6.0.
@Deprecated(
  'Use RawKeylineFace. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignKeylineFace = RawKeylineFace;

/// Renamed [RawKeylineRegion] in ui_core 0.6.0.
@Deprecated(
  'Use RawKeylineRegion. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignKeylineRegion = RawKeylineRegion;

/// Renamed [RawLinearScale] in ui_core 0.6.0.
@Deprecated(
  'Use RawLinearScale. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignLinearScale = RawLinearScale;

/// Renamed [RawListDetail] in ui_core 0.6.0.
@Deprecated(
  'Use RawListDetail. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignListDetail<T extends Object> = RawListDetail<T>;

/// Renamed [rawMatchScore] in ui_core 0.6.0.
@Deprecated(
  'Use rawMatchScore. This feature was deprecated after ui_core 0.6.0.',
)
int? designMatchScore(String text, String query) => rawMatchScore(text, query);

/// Renamed [RawMotionPolicy] in ui_core 0.6.0.
@Deprecated(
  'Use RawMotionPolicy. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignMotionPolicy = RawMotionPolicy;

/// Renamed [RawNavigationBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawNavigationBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignNavigationBuilder = RawNavigationBuilder;

/// Renamed [RawNavigationDestination] in ui_core 0.6.0.
@Deprecated(
  'Use RawNavigationDestination. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignNavigationDestination = RawNavigationDestination;

/// Renamed [RawNavigationDetails] in ui_core 0.6.0.
@Deprecated(
  'Use RawNavigationDetails. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignNavigationDetails = RawNavigationDetails;

/// Renamed [RawNavigationMode] in ui_core 0.6.0.
@Deprecated(
  'Use RawNavigationMode. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignNavigationMode = RawNavigationMode;

/// Renamed [RawOptionSearch] in ui_core 0.6.0.
@Deprecated(
  'Use RawOptionSearch. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignOptionSearch<T> = RawOptionSearch<T>;

/// Renamed [RawOverlayAnchor] in ui_core 0.6.0.
@Deprecated(
  'Use RawOverlayAnchor. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignOverlayAnchor = RawOverlayAnchor;

/// Renamed [RawOverlayAnchorBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawOverlayAnchorBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignOverlayAnchorBuilder = RawOverlayAnchorBuilder;

/// Renamed [RawPieChart] in ui_core 0.6.0.
@Deprecated('Use RawPieChart. This feature was deprecated after ui_core 0.6.0.')
typedef DesignPieChart = RawPieChart;

/// Renamed [RawPieChartBuilder] in ui_core 0.6.0.
@Deprecated(
  'Use RawPieChartBuilder. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignPieChartBuilder = RawPieChartBuilder;

/// Renamed [RawPieChartDetails] in ui_core 0.6.0.
@Deprecated(
  'Use RawPieChartDetails. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignPieChartDetails = RawPieChartDetails;

/// Renamed [RawPieSlice] in ui_core 0.6.0.
@Deprecated('Use RawPieSlice. This feature was deprecated after ui_core 0.6.0.')
typedef DesignPieSlice = RawPieSlice;

/// Renamed [RawPieSliceDetails] in ui_core 0.6.0.
@Deprecated(
  'Use RawPieSliceDetails. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignPieSliceDetails = RawPieSliceDetails;

/// Renamed [rawReduceMotionOf] in ui_core 0.6.0.
@Deprecated(
  'Use rawReduceMotionOf. This feature was deprecated after ui_core 0.6.0.',
)
bool designReduceMotionOf(BuildContext context) => rawReduceMotionOf(context);

/// Renamed [RawScale] in ui_core 0.6.0.
@Deprecated('Use RawScale. This feature was deprecated after ui_core 0.6.0.')
typedef DesignScale = RawScale;

/// Renamed [RawScaleTick] in ui_core 0.6.0.
@Deprecated(
  'Use RawScaleTick. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignScaleTick = RawScaleTick;

/// Renamed [RawScrollbarVisibility] in ui_core 0.6.0.
@Deprecated(
  'Use RawScrollbarVisibility. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignScrollbarVisibility = RawScrollbarVisibility;

/// Renamed [rawShortcutKeys] in ui_core 0.6.0.
@Deprecated(
  'Use rawShortcutKeys. This feature was deprecated after ui_core 0.6.0.',
)
List<String> designShortcutKeys(
  BuildContext context,
  MenuSerializableShortcut shortcut, {
  TargetPlatform? platform,
  bool appleSymbols = true,
}) => rawShortcutKeys(
  context,
  shortcut,
  platform: platform,
  appleSymbols: appleSymbols,
);

/// Renamed [rawShortcutLabel] in ui_core 0.6.0.
@Deprecated(
  'Use rawShortcutLabel. This feature was deprecated after ui_core 0.6.0.',
)
String designShortcutLabel(
  BuildContext context,
  MenuSerializableShortcut shortcut, {
  TargetPlatform? platform,
  bool appleSymbols = true,
}) => rawShortcutLabel(
  context,
  shortcut,
  platform: platform,
  appleSymbols: appleSymbols,
);

/// Renamed [RawSpacing] in ui_core 0.6.0.
@Deprecated('Use RawSpacing. This feature was deprecated after ui_core 0.6.0.')
typedef DesignSpacing = RawSpacing;

/// Renamed [RawSpacingScope] in ui_core 0.6.0.
@Deprecated(
  'Use RawSpacingScope. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignSpacingScope = RawSpacingScope;

/// Renamed [rawSpring] in ui_core 0.6.0.
@Deprecated('Use rawSpring. This feature was deprecated after ui_core 0.6.0.')
SpringDescription designSpring({
  required double dampingRatio,
  required double stiffness,
}) => rawSpring(dampingRatio: dampingRatio, stiffness: stiffness);

/// Renamed [RawSpringDrive] in ui_core 0.6.0. An extension has no alias, so
/// this one forwards to it; it is on a nullable controller, so [RawSpringDrive]
/// is the one a call picks wherever both are in scope.
@Deprecated(
  'Use RawSpringDrive. This feature was deprecated after ui_core 0.6.0.',
)
extension DesignSpringDrive on AnimationController? {
  /// [RawSpringDrive.springTo].
  TickerFuture springTo(
    double target,
    SpringDescription spring, {
    double? velocity,
    Tolerance tolerance = rawSpringTolerance,
  }) =>
      RawSpringDrive(this!)
          .springTo(target, spring, velocity: velocity, tolerance: tolerance);
}

/// Renamed [rawSpringSimulation] in ui_core 0.6.0.
@Deprecated(
  'Use rawSpringSimulation. This feature was deprecated after ui_core 0.6.0.',
)
SpringSimulation designSpringSimulation(
  SpringDescription spring, {
  required double from,
  required double to,
  double velocity = 0,
  Tolerance tolerance = rawSpringTolerance,
}) => rawSpringSimulation(
  spring,
  from: from,
  to: to,
  velocity: velocity,
  tolerance: tolerance,
);

/// Renamed [rawSpringTolerance] in ui_core 0.6.0.
@Deprecated(
  'Use rawSpringTolerance. This feature was deprecated after ui_core 0.6.0.',
)
const Tolerance designSpringTolerance = rawSpringTolerance;

/// Renamed [RawStyle] in ui_core 0.6.0.
@Deprecated('Use RawStyle. This feature was deprecated after ui_core 0.6.0.')
typedef DesignStyle = RawStyle;

/// Renamed [RawStyleOf] in ui_core 0.6.0.
@Deprecated('Use RawStyleOf. This feature was deprecated after ui_core 0.6.0.')
typedef DesignStyleOf = RawStyleOf;

/// Renamed [rawSwipeBack] in ui_core 0.6.0.
@Deprecated(
  'Use rawSwipeBack. This feature was deprecated after ui_core 0.6.0.',
)
Map<TargetPlatform, PageTransitionsBuilder> designSwipeBack(
  Map<TargetPlatform, PageTransitionsBuilder> builders, {
  Set<TargetPlatform> platforms = const {TargetPlatform.iOS},
}) => rawSwipeBack(builders, platforms: platforms);

/// Renamed [RawTapTargets] in ui_core 0.6.0.
@Deprecated(
  'Use RawTapTargets. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignTapTargets = RawTapTargets;

/// Renamed [RawTapTargetScope] in ui_core 0.6.0.
@Deprecated(
  'Use RawTapTargetScope. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignTapTargetScope = RawTapTargetScope;

/// Renamed [RawTextEntryBox] in ui_core 0.6.0.
@Deprecated(
  'Use RawTextEntryBox. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignTextEntryBox = RawTextEntryBox;

/// Renamed [RawTimeScale] in ui_core 0.6.0.
@Deprecated(
  'Use RawTimeScale. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignTimeScale = RawTimeScale;

/// Renamed [RawTree] in ui_core 0.6.0.
@Deprecated('Use RawTree. This feature was deprecated after ui_core 0.6.0.')
typedef DesignTree<T extends Object> = RawTree<T>;

/// Renamed [RawTreeController] in ui_core 0.6.0.
@Deprecated(
  'Use RawTreeController. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignTreeController<T extends Object> = RawTreeController<T>;

/// Renamed [RawTreeItem] in ui_core 0.6.0.
@Deprecated('Use RawTreeItem. This feature was deprecated after ui_core 0.6.0.')
typedef DesignTreeItem<T extends Object> = RawTreeItem<T>;

/// Renamed [RawTreeRow] in ui_core 0.6.0.
@Deprecated('Use RawTreeRow. This feature was deprecated after ui_core 0.6.0.')
typedef DesignTreeRow<T extends Object> = RawTreeRow<T>;

/// Renamed [RawValueHandle] in ui_core 0.6.0.
@Deprecated(
  'Use RawValueHandle. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignValueHandle = RawValueHandle;

/// Renamed [RawWindowSizeClass] in ui_core 0.6.0.
@Deprecated(
  'Use RawWindowSizeClass. This feature was deprecated after ui_core 0.6.0.',
)
typedef DesignWindowSizeClass = RawWindowSizeClass;

/// Renamed [RenderCapCenter] in ui_core 0.6.0.
@Deprecated(
  'Use RenderCapCenter. This feature was deprecated after ui_core 0.6.0.',
)
typedef RenderDesignCapCenter = RenderCapCenter;

/// Renamed [RenderSemanticsProxy] in ui_core 0.6.0.
@Deprecated(
  'Use RenderSemanticsProxy. This feature was deprecated after ui_core 0.6.0.',
)
typedef RenderDesignSemanticsProxy = RenderSemanticsProxy;

/// Renamed [showRawCommandPalette] in ui_core 0.6.0.
@Deprecated(
  'Use showRawCommandPalette. This feature was deprecated after ui_core 0.6.0.',
)
Future<void> showDesignCommandPalette({
  required BuildContext context,
  required RawCommandPalette Function(ValueChanged<RawCommand> run) palette,
  Widget Function(BuildContext context, Widget palette)? surfaceBuilder,
  Color barrierColor = const Color(0x66000000),
  RawBarrierBuilder? barrierBuilder,
  String? barrierLabel,
  AlignmentGeometry alignment = const Alignment(0, -0.6),
}) => showRawCommandPalette(
  context: context,
  palette: palette,
  surfaceBuilder: surfaceBuilder,
  barrierColor: barrierColor,
  barrierBuilder: barrierBuilder,
  barrierLabel: barrierLabel,
  alignment: alignment,
);
