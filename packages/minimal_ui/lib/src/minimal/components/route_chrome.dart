import 'package:material_ui/material_ui.dart';

import '../internal/centred_sheet_route.dart';

/// Which chrome a route position earns, read off the route itself: a nav
/// root, a page pushed off one, or a page raised as a sheet. [MinimalAppBar]
/// and [MinimalScaffold] derive their register from it, which is why a page
/// never authors its own back or close control.
enum MinimalRouteChrome {
  /// A route nothing sits beneath: the title leads, large, with its meta.
  root,

  /// A route pushed over another: the bordered back button and the
  /// breadcrumb.
  pushed,

  /// A route raised as a sheet: the card's compact header with its close.
  sheet;

  /// The register the route around [context] earns, asked of the route
  /// itself the way Material's AppBar asks it: a sheet is Minimal's own
  /// bottom-sheet route (or its centred form in a wide window), and a page
  /// is pushed when a route stands below it
  /// — not merely when its navigator can pop, which a sheet raised over a
  /// root would make true of the root too.
  static MinimalRouteChrome of(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is ModalBottomSheetRoute || route is MinimalCentredSheetRoute) {
      return sheet;
    }
    return route?.impliesAppBarDismissal ?? false ? pushed : root;
  }
}
