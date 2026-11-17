import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/hatch.dart';
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
/// height struck in its [tone] and engraved with fine hatching, its [icon]
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
/// [DesignSwipeActions]; the squares are Ledger's.
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

  /// The width each act takes.
  static const double actionWidth = 76;

  static DesignSwipeAction _design(LedgerSwipeAction a) => DesignSwipeAction(
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
  Widget build(BuildContext context) => DesignSwipeActions(
    startActions: [for (final a in leading) _design(a)],
    endActions: [for (final a in trailing) _design(a)],
    actionExtent: actionWidth,
    // A ledger's row never runs an act on a long swipe: it resists past
    // its acts, and an act is taken by its press.
    fullSwipe: false,
    initiallyOpen: initiallyOpen,
    actionBuilder: (context, action, details) =>
        _Cell(action: action.data! as LedgerSwipeAction),
    child: _Paper(child: child),
  );
}

/// The paper the row stands on, so the acts under it never show through.
class _Paper extends StatelessWidget {
  const _Paper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.ledgerTheme.background, child: child);
}

/// One revealed square: its tone's ground engraved with hatching, the glyph
/// over the label in the small capitals.
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
    return SizedBox(
      width: LedgerSwipeActions.actionWidth,
      child: CustomPaint(
        painter: _Engraving(
          fill: fill,
          line: ink.withValues(alpha: _hatch),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: _gap,
            children: [
              if (action.icon != null)
                Icon(action.icon, size: LedgerIconSize.i18, color: ink),
              Text(
                action.label.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: t.tag.colored(ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DERIVED: the hatching a tenth of the ink, the glyph 4 over the label.
  static const double _hatch = .1;
  static const double _gap = 4;
}

/// A tone's ground with the fine 45 degree hatching of Ledger's engravings.
class _Engraving extends CustomPainter {
  const _Engraving({required this.fill, required this.line});

  final Color fill;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = fill)
      ..drawPath(
        ledgerHatch(
          (x, y) => true,
          0,
          0,
          size.width,
          math.max(size.height, 1),
          3.2,
          step: .5,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = line,
      );
  }

  @override
  bool shouldRepaint(_Engraving old) => old.fill != fill || old.line != line;
}
