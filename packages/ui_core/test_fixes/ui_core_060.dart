// Each name ui_core 0.6.0 renamed (Raw* for all), used once; dart fix renames it (ui_core_060.dart.expect).
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

DesignAdaptiveShell? w0;
DesignBandScale? w1;
DesignBarrierBuilder? w2;
DesignBranchBackBehavior? w3;
DesignCapCenter? w4;
DesignChart? w5;
DesignChartBuilder? w6;
DesignChartDetails? w7;
DesignChartFormat? w8;
DesignChartPoint? w9;
DesignChartPointRef? w10;
DesignChartSeries? w11;
DesignChartTable? w12;
DesignChartTableCellBuilder? w13;
DesignChartTableCellDetails? w14;
DesignChartValueBuilder? w15;
DesignChartValueFormat? w16;
DesignChartXAxis? w17;
DesignComboboxField? w18;
DesignComboboxFieldBuilder? w19;
DesignControlBox? w20;
DesignDensity? w21;
DesignDestinationBuilder? w22;
DesignDestinationDetails? w23;
DesignDialogBuilder? w24;
DesignDialogDetails? w25;
DesignDialogRoute<Object?>? w26;
DesignForm? w27;
DesignFormField<Object?>? w28;
DesignFormState? w29;
DesignHandleBuilder? w30;
DesignHaptics? w31;
DesignHapticsScope? w32;
DesignInput? w33;
DesignInputGroup? w34;
DesignInputGroupBuilder? w35;
DesignKeylineFace? w36;
DesignKeylineRegion? w37;
DesignLinearScale? w38;
DesignListDetail<Object>? w39;
DesignMotionPolicy? w40;
DesignNavigationBuilder? w41;
DesignNavigationDestination? w42;
DesignNavigationDetails? w43;
DesignNavigationMode? w44;
DesignOptionSearch<Object?>? w45;
DesignOverlayAnchor? w46;
DesignOverlayAnchorBuilder? w47;
DesignPieChart? w48;
DesignPieChartBuilder? w49;
DesignPieChartDetails? w50;
DesignPieSlice? w51;
DesignPieSliceDetails? w52;
DesignScale? w53;
DesignScaleTick? w54;
DesignScrollbarVisibility? w55;
DesignSpacing? w56;
DesignSpacingScope? w57;
DesignStyle? w58;
DesignStyleOf? w59;
DesignTapTargets? w60;
DesignTapTargetScope? w61;
DesignTextEntryBox? w62;
DesignTimeScale? w63;
DesignTree<Object>? w64;
DesignTreeController<Object>? w65;
DesignTreeItem<Object>? w66;
DesignTreeRow<Object>? w67;
DesignValueHandle? w68;
DesignWindowSizeClass? w69;
RenderDesignCapCenter? w70;
RenderDesignSemanticsProxy? w71;

void uses(
  BuildContext context,
  AnimationController controller,
  SpringDescription spring,
  MenuSerializableShortcut shortcut,
) {
  designReduceMotionOf(context);
  designSpring(dampingRatio: 1, stiffness: 400);
  designSpringSimulation(spring, from: 0, to: 1);
  designMatchScore('Save', 'sa');
  designShortcutKeys(context, shortcut);
  designShortcutLabel(context, shortcut);
  designSwipeBack(const {});
  showDesignCommandPalette(
    context: context,
    palette: (run) => throw UnimplementedError(),
  );
  DesignSpringDrive(controller).springTo(1, spring);
}

const Tolerance tolerance = designSpringTolerance;
