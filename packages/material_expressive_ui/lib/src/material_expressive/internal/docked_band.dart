/// The band an `ExpressiveScaffold`'s docked chrome (its sticky footer and
/// its bottom bar) holds above the screen's bottom edge, kept per route, so
/// a toast raised anywhere on that route stands above it, as Compose's
/// `Scaffold` places its snackbar host over `bottomBar`. Without it a toast
/// on a pushed page covered the page's footer (a mini player, a primary
/// action). Internal: the barrel never exports it.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final Expando<double> _bands = Expando<double>('expressiveDockedBand');

/// The docked band of the screen on [context]'s route, measured from the
/// screen's bottom edge (it spans the bottom system inset the chrome pads);
/// 0 when the route's screen docks nothing or there is no route.
double expressiveDockedBandOf(BuildContext context) {
  final route = ModalRoute.of(context);
  return route == null ? 0 : _bands[route] ?? 0;
}

/// Forgets [route]'s band (its screen docks nothing now).
void expressiveClearDockedBand(ModalRoute<Object?>? route) {
  if (route != null) _bands[route] = null;
}

/// Records its child's laid-out height as [route]'s docked band.
class ExpressiveDockedBand extends SingleChildRenderObjectWidget {
  /// A band recording its child's height for [route].
  const ExpressiveDockedBand({
    required this.route,
    required super.child,
    super.key,
  });

  /// The route whose docked band the child's height is recorded for.
  final ModalRoute<Object?>? route;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDockedBand(route);

  @override
  void updateRenderObject(BuildContext context, RenderProxyBox renderObject) {
    (renderObject as _RenderDockedBand).route = route;
  }
}

/// The render object of a [ExpressiveDockedBand].
class _RenderDockedBand extends RenderProxyBox {
  /// A render object recording its height for [route].
  _RenderDockedBand(this.route);

  /// The route whose docked band this records.
  ModalRoute<Object?>? route;

  @override
  void performLayout() {
    super.performLayout();
    final route = this.route;
    if (route != null) _bands[route] = size.height;
  }

  @override
  void dispose() {
    final route = this.route;
    if (route != null && hasSize && _bands[route] == size.height) {
      _bands[route] = null;
    }
    super.dispose();
  }
}
