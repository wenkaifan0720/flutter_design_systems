/// The overlays group's demo: the basic alert dialog, the dialog with its
/// hero icon, stacked actions and a live dialog on the spring; the plain
/// and rich tooltips as bubbles and on live anchors; the coach mark with
/// its caret, inline and live, its action as words or as a widget of its
/// own (Compose's `RichTooltip` action slot).
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The overlays group's demo, in [brightness].
Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Overlays',
  sections: const <Widget>[
    _Dialogs(),
    _LiveDialog(),
    _Tooltips(),
    _LiveTooltips(),
    _CoachMark(),
  ],
);

/// An overlay at its own size, not stretched across the page.
class _Inline extends StatelessWidget {
  const _Inline(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: AlignmentDirectional.centerStart, child: child);
}

/// A demo trigger: a pill on the tonal container. The buttons family is its
/// own item; this demo keeps to what the overlays family and the
/// foundations provide.
class _Trigger extends StatelessWidget {
  const _Trigger(this.label, {required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ExpressivePressable(
      shapes: ExpressivePressShapes.all(t.shapes.full),
      motion: ExpressiveMotionKey.fastSpatial,
      color: t.colors.secondaryContainer,
      contentColor: t.colors.onSecondaryContainer,
      // A live button even when only its tooltip answers it: hover, press
      // and keyboard focus show on it as on any button.
      onPressed: onPressed ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ExpressiveSpacing.s16,
          vertical: ExpressiveSpacing.s12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExpressiveIcon(icon),
            const SizedBox(width: ExpressiveSpacing.s8),
            Flexible(child: Text(label, style: t.type.labelLarge)),
          ],
        ),
      ),
    );
  }
}

class _Dialogs extends StatelessWidget {
  const _Dialogs();

  @override
  Widget build(BuildContext context) => kitSection(
    'Dialogs',
    children: const <Widget>[
      // Side by side where they fit, 24dp apart: a column of them 8dp
      // apart read as one lumpy pile (11-13).
      Wrap(
        spacing: ExpressiveSpacing.s24,
        runSpacing: ExpressiveSpacing.s24,
        children: <Widget>[
          ExpressiveDialog(
            title: 'Discard draft?',
            text: 'Your changes to this message will be lost.',
            actions: <ExpressiveDialogAction>[
              ExpressiveDialogAction('Cancel'),
              ExpressiveDialogAction('Discard'),
            ],
          ),
          ExpressiveDialog(
            icon: ExpressiveSymbols.notifications,
            title: 'Turn on notifications?',
            text: 'Hear about replies and reminders the moment they happen.',
            actions: <ExpressiveDialogAction>[
              ExpressiveDialogAction('Not now'),
              ExpressiveDialogAction('Turn on'),
            ],
          ),
          // A destructive confirm, filled.
          ExpressiveDialog(
            title: 'Empty trash?',
            text: '2 notes will be deleted forever.',
            actions: <ExpressiveDialogAction>[
              ExpressiveDialogAction('Cancel'),
              ExpressiveDialogAction('Empty', filled: true),
            ],
          ),
          ExpressiveDialog(
            title: 'Leave the group?',
            text: 'You can rejoin later if someone invites you back.',
            actions: <ExpressiveDialogAction>[
              ExpressiveDialogAction('Stay in the group'),
              ExpressiveDialogAction('Leave and delete messages'),
            ],
          ),
        ],
      ),
    ],
  );
}

class _LiveDialog extends StatefulWidget {
  const _LiveDialog();

  @override
  State<_LiveDialog> createState() => _LiveDialogState();
}

class _LiveDialogState extends State<_LiveDialog> {
  String _answer = 'No answer yet';

  Future<void> _ask() async {
    final answer = await showExpressiveDialog<String>(
      context: context,
      builder: (context) => const ExpressiveDialog(
        icon: ExpressiveSymbols.delete,
        title: 'Delete 3 photos?',
        text: 'They move to the bin and are removed for good in 30 days.',
        actions: <ExpressiveDialogAction>[
          ExpressiveDialogAction('Cancel', value: 'Kept them'),
          ExpressiveDialogAction('Delete', value: 'Deleted them'),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _answer = answer ?? 'Dismissed');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Live dialog',
      children: <Widget>[
        _Inline(
          _Trigger(
            'Show dialog',
            icon: ExpressiveSymbols.delete,
            onPressed: _ask,
          ),
        ),
        Text(_answer, style: TextStyle(color: t.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _Tooltips extends StatelessWidget {
  const _Tooltips();

  @override
  Widget build(BuildContext context) => kitSection(
    'Tooltips',
    children: const <Widget>[
      _Inline(ExpressivePlainTooltip('Add to favourites')),
      _Inline(
        ExpressiveRichTooltip(
          title: 'Offline mode',
          text: 'Saved pages stay readable when you lose your connection.',
          actionLabel: 'Learn more',
          // Live, so the sample shows the action as the spec draws it,
          // not greyed out as a disabled one.
          onAction: _learnMore,
        ),
      ),
    ],
  );
}

/// The sample rich tooltips' action: nothing to learn or dismiss here.
void _learnMore() {}

class _LiveTooltips extends StatelessWidget {
  const _LiveTooltips();

  @override
  Widget build(BuildContext context) => kitSection(
    'Live tooltips',
    children: <Widget>[
      Wrap(
        spacing: kitGap,
        runSpacing: kitGap,
        children: <Widget>[
          const ExpressiveTooltip.plain(
            message: 'Add to favourites',
            child: _Trigger('Hold me', icon: ExpressiveSymbols.favorite),
          ),
          ExpressiveTooltip.rich(
            title: 'Offline mode',
            text: 'Saved pages stay readable when you lose your connection.',
            actionLabel: 'Got it',
            onAction: () {},
            position: ExpressiveTooltipPosition.below,
            child: const _Trigger('Rich tooltip', icon: ExpressiveSymbols.info),
          ),
        ],
      ),
    ],
  );
}

class _CoachMark extends StatefulWidget {
  const _CoachMark();

  @override
  State<_CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends State<_CoachMark> {
  bool _visible = false;

  /// Whether the tour step (a coach mark whose action is a widget) is up.
  bool _step = false;

  void _endStep() => setState(() => _step = false);

  @override
  Widget build(BuildContext context) => kitSection(
    'Coach mark',
    children: <Widget>[
      const _Inline(
        ExpressiveRichTooltip(
          title: 'New: filters',
          text: 'Narrow the list to what matters today.',
          actionLabel: 'Got it',
          onAction: _learnMore,
          // From the start edge: it points at the trigger's start in RTL too.
          caret: ExpressiveTooltipCaret.start(
            below: false,
            start: ExpressiveSpacing.s24,
          ),
        ),
      ),
      _Inline(
        ExpressiveCoachMark(
          visible: _visible,
          title: 'New: filters',
          text: 'Narrow the list to what matters today.',
          actionLabel: 'Got it',
          onAction: () => setState(() => _visible = false),
          onDismissed: () => setState(() => _visible = false),
          child: _Trigger(
            _visible ? 'Showing the coach mark' : 'Show coach mark',
            icon: ExpressiveSymbols.filterList,
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
      ),
      // The action slot: a tour step's own actions, which words alone
      // cannot draw.
      _Inline(
        ExpressiveRichTooltip(
          title: 'Share the list',
          text: 'Anyone you send it to can add to it too.',
          action: _StepActions(onSkip: () {}, onNext: () {}),
          caret: const ExpressiveTooltipCaret.start(
            below: false,
            start: ExpressiveSpacing.s24,
          ),
        ),
      ),
      _Inline(
        ExpressiveCoachMark(
          visible: _step,
          title: 'Share the list',
          text: 'Anyone you send it to can add to it too.',
          action: _StepActions(onSkip: _endStep, onNext: _endStep),
          onDismissed: _endStep,
          child: _Trigger(
            _step ? 'Showing a tour step' : 'Show a tour step',
            icon: ExpressiveSymbols.share,
            onPressed: () => setState(() => _step = !_step),
          ),
        ),
      ),
    ],
  );
}

/// A tour step's actions in a coach mark's action slot: Skip as the
/// overlays' text action, Next as a small filled button.
class _StepActions extends StatelessWidget {
  const _StepActions({required this.onSkip, required this.onNext});

  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: ExpressiveSpacing.s8,
    children: <Widget>[
      ExpressiveTextButton('Skip', onPressed: onSkip),
      ExpressiveFilledButton('Next', onPressed: onNext),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A confirmation with its icon, title, text and two actions, in place.
Widget kitSpecimenAlertDialogDiscard() => const Center(
  child: ExpressiveDialog(
    icon: ExpressiveSymbols.delete,
    title: 'Discard this draft?',
    text: 'The note and its photo are removed from this phone.',
    actions: <ExpressiveDialogAction>[
      ExpressiveDialogAction('Cancel'),
      ExpressiveDialogAction('Discard'),
    ],
  ),
);

/// A coach mark up over the control it teaches: its caret, the feature's
/// name and what it does, and its action.
Widget kitSpecimenCoachMarkFilters() => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      ExpressiveCoachMark(
        visible: true,
        title: 'New: filters',
        text: 'Narrow the list to what matters today.',
        actionLabel: 'Got it',
        onAction: () {},
        child: _Trigger(
          'Filters',
          icon: ExpressiveSymbols.filterList,
          onPressed: () {},
        ),
      ),
      // Room for the bubble under the control, inside the band.
      const SizedBox(height: ExpressiveSpacing.s40 * 4),
    ],
  ),
);
