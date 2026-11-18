import 'package:ui_core/ui_core.dart';

/// The route a sheet page rides centred in a wide window
/// (`MinimalBottomSheet.centredRoute`): ui_core's dialog route, which the
/// page's bar still reads as a sheet (`MinimalRouteChrome.sheet`), so the
/// card keeps its compact header and close. It adds nothing but its name.
class MinimalCentredSheetRoute<T> extends DesignDialogRoute<T> {
  /// The centred sheet's route, its page [builder]'s.
  MinimalCentredSheetRoute({
    required super.builder,
    super.barrierColor,
    super.barrierLabel,
    super.settings,
  }) : super(
         dampingRatio: _damping,
         stiffness: _stiffness,
         barrierDismissible: true,
       );

  // A dialog's spring (MinimalChromeMetrics.routeDamping, dialogStiffness).
  static const double _damping = 1;
  static const double _stiffness = 2500;
}
