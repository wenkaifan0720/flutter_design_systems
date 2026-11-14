// The reading rows the shared inventory adds: a divider, a timeline, a description list, a status view
// over the look's own loading, empty, error and success states, and an action sheet on the bottom sheet's face.
import 'package:ui_core/ui_core.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

import '../chrome.dart';
import '../controls.dart';
import '../localizations.dart';
import '../press.dart';
import '../raised.dart';
import '../signatures/empty.dart';
import '../tell.dart';
import '../theme.dart';

/// An inked rule between parts of a page: across ([Axis.horizontal]) or down a row. With [label] the words stand in
/// the middle of the rule, in the lettering ("or", a date).
///
/// ```dart
/// ComicDivider(label: 'or')
/// ```
class ComicDivider extends StatelessWidget {
  /// Creates a [ComicDivider].
  const ComicDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.label,
    this.space = 16,
  });

  /// Across the page, or down a row.
  final Axis axis;

  /// Words in the middle of a horizontal rule.
  final String? label;

  /// The room on either side of the rule.
  final double space;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    // A loose rule on the page: the night issue's cream at night, where the contour's black would sink into the ground.
    final rule = ColoredBox(
      color: c.nightLine,
      child: axis == Axis.horizontal
          ? const SizedBox(height: 2, width: double.infinity)
          : const SizedBox(width: 2, height: double.infinity),
    );
    if (axis == Axis.vertical) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: space / 2),
        child: rule,
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: space / 2),
      child: label == null
          ? Semantics(container: true, child: rule)
          : Row(
              children: [
                Expanded(child: rule),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    label!.toUpperCase(),
                    style: t.type.letter(
                      13,
                      lineHeight: 1.1,
                      color: c.textSecondary,
                      tracking: .08,
                    ),
                  ),
                ),
                Expanded(child: rule),
              ],
            ),
    );
  }
}

/// Where a [ComicTimelineEntry] stands.
enum ComicTimelineStatus {
  /// Done: an inked disc.
  done,

  /// Now: the caption disc, a size larger.
  current,

  /// Still to come: an open ring.
  upcoming,
}

/// One entry on a [ComicTimeline].
@immutable
class ComicTimelineEntry {
  /// Creates a [ComicTimelineEntry].
  const ComicTimelineEntry(
    this.title, {
    this.time,
    this.body,
    this.step = ComicTimelineStatus.done,
  });

  /// What happened.
  final String title;

  /// When, in the caller's words.
  final String? time;

  /// More about it.
  final String? body;

  /// Done, now, or to come.
  final ComicTimelineStatus step;
}

/// Events down an inked rail, oldest first: each a disc on the rail (inked when done, the caption's when now, open
/// when to come) with its title, time and words beside it. The rail is solid up to now and broken after.
///
/// ```dart
/// ComicTimeline(entries: const [ComicTimelineEntry('Pencilled', time: 'Mon'), ComicTimelineEntry('Inked', time: 'Today', step: ComicTimelineStatus.current)])
/// ```
class ComicTimeline extends StatelessWidget {
  /// Creates a [ComicTimeline].
  const ComicTimeline({super.key, required this.entries});

  /// The events, oldest first.
  final List<ComicTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final words = ComicLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, entry) in entries.indexed)
          MergeSemantics(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _RailInk.width,
                    child: CustomPaint(
                      painter: _RailInk(
                        step: entry.step,
                        first: i == 0,
                        last: i == entries.length - 1,
                        broken: entry.step == ComicTimelineStatus.upcoming,
                        ink: c.nightLine,
                        caption: c.caption,
                        ground: c.dark ? c.card : c.paper,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i == entries.length - 1 ? 0 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            value: switch (entry.step) {
                              ComicTimelineStatus.done => words.stepDone,
                              ComicTimelineStatus.current => words.stepNow,
                              ComicTimelineStatus.upcoming =>
                                words.stepUpcoming,
                            },
                            child: Text(
                              entry.title,
                              style: t.type.title.copyWith(
                                color:
                                    entry.step == ComicTimelineStatus.upcoming
                                    ? c.textSecondary
                                    : c.text,
                              ),
                            ),
                          ),
                          if (entry.time != null)
                            Text(entry.time!, style: t.type.small),
                          if (entry.body != null) ...[
                            const SizedBox(height: 4),
                            Text(entry.body!, style: t.type.body),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RailInk extends CustomPainter {
  _RailInk({
    required this.step,
    required this.first,
    required this.last,
    required this.broken,
    required this.ink,
    required this.caption,
    required this.ground,
  });

  final ComicTimelineStatus step;
  final bool first, last, broken;
  final Color ink, caption, ground;

  static const double _top = 11;

  /// The rail is as wide as the current step's ring, rim and all, so its ring starts on the column's edge.
  static const double width = 2 * (9 + 2.5 / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final line = Paint()
      ..color = ink
      ..strokeWidth = 2.5;
    if (!first) canvas.drawLine(Offset(x, 0), Offset(x, _top), line);
    if (!last) {
      if (broken) {
        for (var y = _top; y < size.height; y += 10) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, (y + 5).clamp(0, size.height)),
            line,
          );
        }
      } else {
        canvas.drawLine(Offset(x, _top), Offset(x, size.height), line);
      }
    }
    final r = step == ComicTimelineStatus.current ? 9.0 : 7.0;
    final centre = Offset(x, _top);
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..color = switch (step) {
          ComicTimelineStatus.done => ink,
          ComicTimelineStatus.current => caption,
          ComicTimelineStatus.upcoming => ground,
        },
    );
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(_RailInk old) =>
      old.step != step ||
      old.first != first ||
      old.last != last ||
      old.broken != broken ||
      old.ink != ink ||
      old.caption != caption ||
      old.ground != ground;
}

/// One term and what it means, in a [ComicDescriptionList].
@immutable
class ComicDescriptionItem {
  /// Creates a [ComicDescriptionItem].
  const ComicDescriptionItem(this.term, this.detail);

  /// [term]: what is described. [detail]: its description.
  final String term, detail;
}

/// Terms and their details between rules: the term in the lettering over its detail on a phone, beside it on a wider
/// page. A screen reader hears each pair as one.
///
/// ```dart
/// ComicDescriptionList(entries: const [ComicDescriptionItem('Writer', 'Ana Ruiz'), ComicDescriptionItem('Pages', '24')])
/// ```
class ComicDescriptionList extends StatelessWidget {
  /// Creates a [ComicDescriptionList].
  const ComicDescriptionList({
    super.key,
    required this.entries,
    this.besideFrom = 480,
  });

  /// The pairs, in reading order.
  final List<ComicDescriptionItem> entries;

  /// The width from which the term stands beside its detail.
  final double besideFrom;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final term = t.type.letter(
      13,
      lineHeight: 1.2,
      color: c.textSecondary,
      tracking: .06,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final beside = box.maxWidth >= besideFrom;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, entry) in entries.indexed) ...[
              if (i > 0)
                ColoredBox(color: c.divider, child: const SizedBox(height: 1)),
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: beside
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: box.maxWidth * .34,
                              child: Text(
                                entry.term.toUpperCase(),
                                style: term,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(entry.detail, style: t.type.body),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.term.toUpperCase(), style: term),
                            const SizedBox(height: 4),
                            Text(entry.detail, style: t.type.body),
                          ],
                        ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A screen's whole state in one place: loading, empty, failed or done, each the look's own (the thought balloon's
/// dots, the empty panel, the error panel with its retry, the success caption).
///
/// ```dart
/// ComicStatusView.error(title: 'The issue did not load', onRetry: reload)
/// ```
class ComicStatusView extends StatelessWidget {
  /// While the screen's content loads.
  const ComicStatusView.loading({super.key, this.label})
    : _kind = _Status.loading,
      title = null,
      message = null,
      action = null,
      onRetry = null;

  /// When there is nothing to show yet.
  const ComicStatusView.empty({
    super.key,
    required String this.title,
    this.message,
    this.action,
  }) : _kind = _Status.empty,
       label = null,
       onRetry = null;

  /// When it failed; [onRetry] offers another try.
  const ComicStatusView.error({
    super.key,
    required String this.title,
    this.message,
    this.onRetry,
    this.action,
  }) : _kind = _Status.error,
       label = null;

  /// When it is done.
  const ComicStatusView.success({
    super.key,
    required String this.title,
    required String this.message,
    this.action,
  }) : _kind = _Status.success,
       label = null,
       onRetry = null;

  final _Status _kind;

  /// What is loading, for a screen reader.
  final String? label;

  /// [title]: the state's heading. [message]: its words.
  final String? title, message;

  /// An action under the words.
  final Widget? action;

  /// Tries again after a failure.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => switch (_kind) {
    _Status.loading => ComicLoadingState(label: label),
    _Status.empty => ComicEmptyState(
      title: title!,
      body: message,
      action: action,
    ),
    _Status.error => ComicErrorState(
      title: title!,
      message: message,
      onRetry: onRetry,
      action: action,
    ),
    _Status.success => ComicSuccessState(
      title: title!,
      message: message!,
      action: action,
    ),
  };
}

enum _Status { loading, empty, error, success }

/// One choice on a [ComicActionSheet].
@immutable
class ComicSheetAction<T> {
  /// Creates a [ComicSheetAction].
  const ComicSheetAction(
    this.label, {
    required this.value,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  /// Its words.
  final String label;

  /// What [showComicActionSheet] returns for it.
  final T value;

  /// An optional glyph before the words.
  final IconData? icon;

  /// Destroys something: the danger tone.
  final bool destructive;

  /// Whether it can be taken.
  final bool enabled;
}

/// A short list of choices raised from the page's foot on the bottom sheet's face, each a full-width row, with a cancel
/// under them. [showComicActionSheet] raises it and returns the chosen value.
///
/// ```dart
/// ComicActionSheet<String>(title: 'Issue 12', actions: const [ComicSheetAction('Share', value: 'share')], onSelected: (v) {})
/// ```
class ComicActionSheet<T> extends StatelessWidget {
  /// Creates a [ComicActionSheet].
  const ComicActionSheet({
    super.key,
    required this.actions,
    required this.onSelected,
    this.title,
    this.message,
    this.cancelLabel,
    this.onCancel,
  });

  /// The choices, in order.
  final List<ComicSheetAction<T>> actions;

  /// Takes a choice.
  final ValueChanged<T> onSelected;

  /// [title]: the sheet's heading. [message]: a line under it.
  final String? title, message;

  /// Overrides the localized cancel.
  final String? cancelLabel;

  /// Cancels; closes the route when null.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    return ComicBottomSheet(
      title: title,
      showClose: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null) ...[
            Text(message!, style: t.type.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: 12),
          ],
          for (final action in actions)
            _SheetRowReach(
              child: ComicPressable(
                label: action.label,
                onPressed: action.enabled
                    ? () => onSelected(action.value)
                    : null,
                // The rows stand free on the sheet, over its cancel: the control step, the cancel's own corner.
                outline: WidgetStatePropertyAll(t.shapes.small),
                wash: false,
                ring: false,
                sink: false,
                builder: (context, states) => ComicMenuRowFace(
                  states: states,
                  label: action.label,
                  icon: action.icon,
                  danger: action.destructive,
                  shape: t.shapes.small,
                ),
              ),
            ),
          const SizedBox(height: 12),
          ComicButton(
            cancelLabel ?? DesignLocalizations.of(context).cancelButtonLabel,
            onPressed: onCancel ?? () => Navigator.maybePop(context),
          ),
        ],
      ),
    );
  }
}

/// An action sheet's row reaching into the sheet's margin by its words' inset ([ComicMenuRowFace]'s 12) on either
/// side, so its words start on the title's and the cancel's edge while its lit face keeps that room round them.
class _SheetRowReach extends StatelessWidget {
  const _SheetRowReach({required this.child});
  final Widget child;
  static const double _reach = 12;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => OverflowBox(
      fit: OverflowBoxFit.deferToChild,
      minWidth: box.maxWidth + 2 * _reach,
      maxWidth: box.maxWidth + 2 * _reach,
      child: child,
    ),
  );
}

/// Raises a [ComicActionSheet] and returns the chosen value, or null on cancel or dismissal.
///
/// ```dart
/// final choice = await showComicActionSheet<String>(context, title: 'Issue 12', actions: const [ComicSheetAction('Delete', value: 'delete', destructive: true)]);
/// ```
Future<T?> showComicActionSheet<T>(
  BuildContext context, {
  required List<ComicSheetAction<T>> actions,
  String? title,
  String? message,
  String? cancelLabel,
}) => showComicBottomSheet<T>(
  context,
  builder: (context) => ComicActionSheet<T>(
    actions: actions,
    title: title,
    message: message,
    cancelLabel: cancelLabel,
    onSelected: (value) => Navigator.pop(context, value),
  ),
);
