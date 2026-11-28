import 'package:flutter/widgets.dart';

/// Where a list and its detail show their notices. Side by side, each pane
/// has a toaster of its own, so a notice stands in the pane it is about and
/// never across the seam between them; narrow, the list is the page and the
/// detail a page pushed over it, both under the app's toaster.
class PaneNotices {
  /// Notices in panes, each in the look's [toaster].
  PaneNotices(this.toaster);

  /// The look's toaster around a pane.
  final Widget Function(Widget pane) toaster;

  final GlobalKey _list = GlobalKey(debugLabel: 'list pane notices');
  final GlobalKey _detail = GlobalKey(debugLabel: 'detail pane notices');

  /// Whether a list-detail [width] wide sets its panes side by side: from
  /// 840, the expanded window class, as `RawListDetail` does by default.
  static bool sideBySideAt(double width) => width >= 840;

  /// [child], the list pane, in a toaster of its own when [sideBySide]. The
  /// list keeps its state as the window crosses the width.
  Widget list({required bool sideBySide, required Widget child}) {
    final keyed = KeyedSubtree(key: _list, child: child);
    return sideBySide ? toaster(keyed) : keyed;
  }

  /// [child], the detail pane, in a toaster of its own when [sideBySide].
  Widget detail({required bool sideBySide, required Widget child}) => sideBySide
      ? toaster(
          _DetailPane(
            child: KeyedSubtree(key: _detail, child: child),
          ),
        )
      : child;

  /// Where a notice about the list shows from: inside the list's toaster
  /// when it has one, else [fallback].
  BuildContext forList(BuildContext fallback) =>
      _list.currentContext ?? fallback;

  /// Where a notice about the open item shows from: inside the detail's
  /// toaster when it has one, else [fallback].
  BuildContext forDetail(BuildContext fallback) =>
      _detail.currentContext ?? fallback;
}

/// Marks a detail pane with a toaster of its own.
class _DetailPane extends InheritedWidget {
  const _DetailPane({required super.child});

  @override
  bool updateShouldNotify(_DetailPane oldWidget) => false;
}

/// Room at the end of a detail pane's scroll for the pane's notices: an
/// action scrolled to the end (Save) stands above a notice rather than under
/// it, as Material moves its floating button clear of a snack bar. It takes
/// room only in a detail pane of [PaneNotices]; narrow, the detail is a page
/// under the app's toaster, which keeps its foot clear.
class ToastClearance extends StatelessWidget {
  /// Room for the look's notice band, [band] tall at text scale 1 (a notice
  /// and its margin over the pane's foot), and 8 more above it, less the
  /// [after] the scroll already ends with under the action.
  const ToastClearance({super.key, required this.band, required this.after});

  /// The look's notice band at text scale 1.
  final double band;

  /// The room the scroll already ends with under the action.
  final double after;

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_DetailPane>() == null) {
      return const SizedBox.shrink();
    }
    final room = MediaQuery.textScalerOf(context).scale(band) + 8 - after;
    return SizedBox(height: room > 0 ? room : 0);
  }
}
