/// A short list of things to do with one object, raised from the bottom.
library;

import 'package:material_ui/material_ui.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';
import 'sheet.dart';

/// One action of a [MinimalActionSheet].
@immutable
class MinimalActionSheetAction {
  /// An action in a [MinimalActionSheet].
  const MinimalActionSheetAction(
    this.label, {
    this.icon,
    this.onPressed,
    this.destructive = false,
  });

  /// What the action says.
  final String label;

  /// A glyph before the label.
  final IconData? icon;

  /// Null greys the action.
  final VoidCallback? onPressed;

  /// The action deletes or discards: its words take the destructive ink.
  final bool destructive;
}

/// A short list of things to do with one object — a photo's Share, Save
/// and Delete; a message's Reply and Copy — raised from the bottom on a
/// phone: ONE card in the sheet's material holding an optional [title] and
/// [message], a row for each action (a glyph and the words, the destructive
/// one in the destructive ink) and, last, under a hairline like every row,
/// Cancel, centred in the muted ink: the quiet way out, not a second card.
///
/// Each row is a cell of the card: its press wash and focus ring take the
/// card's corners where it meets them and are square between rows. Raise it
/// with [showMinimalActionSheet], which closes the sheet before an action
/// runs. On a wide window an anchored `MinimalMenu` is the better answer.
///
/// ```dart
/// showMinimalActionSheet(context, title: 'Photo', actions: [MinimalActionSheetAction('Share', onPressed: share), MinimalActionSheetAction('Delete', destructive: true, onPressed: delete)])
/// ```
class MinimalActionSheet extends StatelessWidget {
  /// A sheet of [actions].
  const MinimalActionSheet({
    super.key,
    required this.actions,
    this.title,
    this.message,
    this.onCancel,
  });

  /// The actions, top to bottom.
  final List<MinimalActionSheetAction> actions;

  /// What the actions act on.
  final String? title;

  /// A line under the title.
  final String? message;

  /// The Cancel row's action; null shows no Cancel.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shape = MinimalBottomSheet.shapeOf(t, floating: true);
    // The rows stand inside the card's rim, so a row's corners are the
    // card's moved in by it: concentric.
    final rim = t.rim;
    final title = this.title;
    final message = this.message;
    final header = title != null || message != null;
    final cancel = onCancel;
    final count = actions.length + (header ? 1 : 0) + (cancel != null ? 1 : 0);
    final rows = <Widget>[
      if (header)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MinimalSpacing.s16,
            vertical: MinimalSpacing.s12,
          ),
          decoration: BoxDecoration(border: Border(bottom: t.rule)),
          child: Column(
            children: [
              if (title != null)
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: t.bodySmall.medium.c(t.foreground),
                ),
              if (message != null)
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: t.bodySmall.c(t.mutedForeground),
                ),
            ],
          ),
        ),
      for (var i = 0; i < actions.length; i++)
        _Row(
          action: actions[i],
          shape: minimalCell(
            shape,
            index: i + (header ? 1 : 0),
            count: count,
            inset: rim,
            axis: Axis.vertical,
          ),
          last: i == actions.length - 1 && cancel == null,
        ),
      if (cancel != null)
        _Row(
          action: MinimalActionSheetAction(
            MinimalLocalizations.of(context).cancel,
            onPressed: cancel,
          ),
          shape: minimalCell(
            shape,
            index: count - 1,
            count: count,
            inset: rim,
            axis: Axis.vertical,
          ),
          last: true,
          quiet: true,
        ),
    ];
    return MinimalBottomSheet.frame(
      t,
      floating: true,
      child: Padding(
        padding: EdgeInsets.all(rim),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.action,
    required this.shape,
    required this.last,
    this.quiet = false,
  });

  final MinimalActionSheetAction action;
  final OutlinedBorder shape;
  final bool last;

  /// Cancel's register: centred in the muted ink.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final ink = action.destructive
        ? t.destructiveInk
        : (quiet ? t.mutedForeground : t.foreground);
    final icon = action.icon;
    return MinimalPressable(
      onPressed: action.onPressed,
      enabled: action.onPressed != null,
      shape: shape,
      focusInside: true,
      child: Container(
        constraints: BoxConstraints(minHeight: t.density.height(48)),
        padding: const EdgeInsets.symmetric(horizontal: MinimalSpacing.s16),
        // Painted over the row's foot: the action is centred on the whole
        // row, the rule's pixel with it.
        foregroundDecoration: last
            ? null
            : BoxDecoration(border: Border(bottom: t.rule)),
        child: Row(
          mainAxisAlignment: icon == null
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (icon != null) ...[
              MinimalIcon(icon, size: MinimalIconSize.i18, color: ink),
              const MinimalGap(MinimalChromeMetrics.rowIconGap + 2),
            ],
            Flexible(
              child: minimalCapLabel(Text(action.label, style: t.body.c(ink))),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raises a [MinimalActionSheet] over the app from the bottom, on a dimmed
/// page, with a Cancel row. An action's press closes the sheet first, then
/// runs; a tap on the scrim, a drag down or Cancel closes it with nothing
/// done.
Future<void> showMinimalActionSheet(
  BuildContext context, {
  required List<MinimalActionSheetAction> actions,
  String? title,
  String? message,
}) {
  final t = context.minimalTheme;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0x00000000),
    elevation: 0,
    barrierColor: t.overlay,
    isScrollControlled: true,
    useRootNavigator: true,
    sheetAnimationStyle: MinimalBottomSheet.motionOf(context),
    constraints: const BoxConstraints(),
    builder: (sheet) {
      void close() => Navigator.of(sheet).pop();
      return Padding(
        padding: EdgeInsets.fromLTRB(
          MinimalChromeMetrics.sheetInset,
          0,
          MinimalChromeMetrics.sheetInset,
          MinimalBottomSheet.bottomGap(sheet),
        ),
        child: MinimalActionSheet(
          title: title,
          message: message,
          onCancel: close,
          actions: [
            for (final a in actions)
              MinimalActionSheetAction(
                a.label,
                icon: a.icon,
                destructive: a.destructive,
                onPressed: a.onPressed == null
                    ? null
                    : () {
                        close();
                        a.onPressed!();
                      },
              ),
          ],
        ),
      );
    },
  );
}
