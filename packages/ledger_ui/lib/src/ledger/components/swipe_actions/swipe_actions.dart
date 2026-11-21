import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

/// What a [LedgerSwipeAction] stands for, and so what ground it is struck on.
enum LedgerSwipeTone {
  /// A quiet act: the ink ground, the paper's words (snooze, more).
  plain,

  /// The act that finishes the thing: the green (done, pay, keep).
  accent,

  /// The act that cannot be taken back: the vermilion (delete).
  destructive,
}

/// One act a [LedgerSwipeActions] row holds under it: a square the row's full
/// height filled with its [tone], its [icon]
/// over its [label] in the small capitals. The label is also what a screen
/// reader offers as the row's custom action.
///
/// ```dart
/// LedgerSwipeAction('Delete', icon: LucideIcons.trash2, tone: LedgerSwipeTone.destructive, onPressed: delete)
/// ```
class LedgerSwipeAction {
  /// An act worded [label] that calls [onPressed].
  const LedgerSwipeAction(
    this.label, {
    required this.onPressed,
    this.icon,
    this.tone = LedgerSwipeTone.plain,
  });

  /// The word on the square, and the name of its custom action.
  final String label;

  /// Called when the act is taken; the row closes as it acts.
  final VoidCallback onPressed;

  /// The act's glyph, over its label.
  final IconData? icon;

  /// The act's colour.
  final LedgerSwipeTone tone;
}

/// A list row that opens on its acts when dragged aside: [leading] acts wait
/// under its start edge and [trailing] acts under its end, squares the row's
/// full height, butted edge to edge in their tones with no gap. The row snaps
/// open past a share of its acts' width and shut below it, resists a drag
/// past them, and while open a tap on it closes it rather than opening the
/// record; an act closes the row as it acts. Every act is also offered to a
/// screen reader as a custom action on the row, so nothing here needs the
/// gesture. [initiallyOpen] starts it open on its trailing acts (its leading
/// ones when it has none): a preview, or a hint that the row swipes. Right to
/// left mirrors the edges. The drag, the snap and the actions are ui_core's
/// [RawSwipeActions]; the squares are Ledger's.
///
/// ```dart
/// LedgerSwipeActions(trailing: [LedgerSwipeAction('Delete', icon: LucideIcons.trash2, tone: LedgerSwipeTone.destructive, onPressed: delete)], child: row)
/// ```
class LedgerSwipeActions extends StatelessWidget {
  /// A row of [child] that opens on its [leading] and [trailing] acts.
  const LedgerSwipeActions({
    required this.child,
    this.leading = const [],
    this.trailing = const [],
    this.initiallyOpen = false,
    super.key,
  });

  /// The row, on the paper: it covers the acts until it is dragged.
  final Widget child;

  /// Acts revealed by dragging toward the end edge, the first nearest the
  /// start edge.
  final List<LedgerSwipeAction> leading;

  /// Acts revealed by dragging toward the start edge, the first nearest the
  /// end edge.
  final List<LedgerSwipeAction> trailing;

  /// Starts with the trailing acts shown (the leading ones with none).
  final bool initiallyOpen;

  /// The minimum width of an action when there is room.
  static const double actionWidth = 76;

  static RawSwipeAction _design(LedgerSwipeAction a) => RawSwipeAction(
    label: a.label,
    onPressed: a.onPressed,
    destructive: a.tone == LedgerSwipeTone.destructive,
    data: a,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<LedgerSwipeAction>('leading', leading))
      ..add(IterableProperty<LedgerSwipeAction>('trailing', trailing))
      ..add(
        FlagProperty(
          'initiallyOpen',
          value: initiallyOpen,
          ifTrue: 'initiallyOpen',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final style = context.ledgerTheme.tag;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    var width = actionWidth;
    for (final action in [...leading, ...trailing]) {
      painter.text = TextSpan(text: action.label.toUpperCase(), style: style);
      painter.layout();
      width = math.max(width, painter.width.ceilToDouble() + 12);
    }
    painter.dispose();
    final count = math.max(1, math.max(leading.length, trailing.length));
    return LayoutBuilder(
      builder: (context, box) => RawSwipeActions(
        startActions: [for (final a in leading) _design(a)],
        endActions: [for (final a in trailing) _design(a)],
        actionExtent: math.max(1.0, math.min(width, box.maxWidth / count)),
        // A ledger's row never runs an act on a long swipe: it resists past
        // its acts, and an act is taken by its press.
        fullSwipe: false,
        initiallyOpen: initiallyOpen,
        actionBuilder: (context, action, details) =>
            _Cell(action: action.data! as LedgerSwipeAction),
        child: _Paper(child: child),
      ),
    );
  }
}

/// The paper the row stands on, so the acts under it never show through.
class _Paper extends StatelessWidget {
  const _Paper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.ledgerTheme.background, child: child);
}

/// The action's icon and label on a solid background.
class _Cell extends StatelessWidget {
  const _Cell({required this.action});

  final LedgerSwipeAction action;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final (fill, ink) = switch (action.tone) {
      LedgerSwipeTone.plain => (t.surfaceInverse, t.textInverse),
      LedgerSwipeTone.accent => (t.accent, t.onAccent),
      LedgerSwipeTone.destructive => (t.danger, t.onDanger),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: fill),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: _gap,
          children: [
            if (action.icon != null)
              Icon(action.icon, size: LedgerIconSize.i18, color: ink),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                action.label.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: t.tag.colored(ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _gap = 4;
}
