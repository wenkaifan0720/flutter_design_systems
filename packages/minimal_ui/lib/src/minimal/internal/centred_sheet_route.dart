import 'package:flutter/widgets.dart';

/// The route a sheet page rides centred in a wide window
/// (`MinimalBottomSheet.centredRoute`): a dialog's route, which the page's
/// bar still reads as a sheet (`MinimalRouteChrome.sheet`), so the card
/// keeps its compact header and close.
class MinimalCentredSheetRoute<T> extends RawDialogRoute<T> {
  /// The centred sheet's route over [pageBuilder].
  MinimalCentredSheetRoute({
    required super.pageBuilder,
    required super.transitionBuilder,
    required super.transitionDuration,
    super.barrierColor,
    super.barrierLabel,
    super.settings,
  }) : super(barrierDismissible: true);
}
