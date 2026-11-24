import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_center.dart';
import '../internal/even_acts.dart';
import '../internal/grabber.dart';
import '../internal/narrow.dart';
import '../internal/pixel_center.dart';
import '../internal/presence.dart';
import '../theme.dart';
import 'host.dart';
import 'icon-button/icon_button.dart';

/// A sheet's head (`.sheet-head`): its [title] in the serif, the ringed
/// [close] at its end hung 6 into the gutter, an ink rule under both; 14
/// over the title on a phone (under the grip), 26 on the desktop's dialog.
/// [leading] and [actions] stand before the title and before the close.
///
/// ```dart
/// LedgerSheetHead(title: 'Category', close: LedgerIconButton.outlined(LucideIcons.x, semanticLabel: 'Close', size: LedgerIconButtonSize.small, onPressed: () {}))
/// ```
class LedgerSheetHead extends StatelessWidget {
  /// A sheet's head titled [title].
  const LedgerSheetHead({
    required this.title,
    this.close,
    this.leading,
    this.actions = const [],
    super.key,
  });

  /// The sheet's title, in the serif.
  final String title;

  /// A mark before the title.
  final Widget? leading;

  /// The ringed close at the head's end.
  final Widget? close;

  /// Acts before the close.
  final List<Widget> actions;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    // The ink rule stands 12 under the title, outside that room (a
    // Container insets by the rule, as CSS's border does).
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.headRule)),
      ),
      padding: EdgeInsets.only(
        top: wide
            ? LedgerChromeMetrics.sheetHeadTopWide
            : LedgerChromeMetrics.sheetHeadTop,
        bottom: LedgerChromeMetrics.sheetHeadFoot,
      ),
      child: Row(
        spacing: LedgerChromeMetrics.sheetHeadGap,
        children: [
          ?leading,
          Expanded(
            child: Semantics(
              header: true,
              child: ledgerCapCenter(
                t.sheetTitle,
                Text(title, style: t.sheetTitle),
              ),
            ),
          ),
          ...actions,
          // On the column's end, as every part of the card: its whole target
          // inside the head, so a tap reaches all of it.
          ?close,
        ],
      ),
    );
  }
}

/// A modal sheet's card, drawn in place: on a phone it rises off the bottom
/// edge, its top corners at 6 (`--r-sheet`), the grip over its head; at
/// desktop width it stands centred, 480 wide, every corner at 6 and no
/// grip. Its face is the raised paper with the sheet's shadow. The head
/// ([LedgerSheetHead]: the [title] and the ringed close over the ink rule),
/// then the body's [children] 8 under it, then the [foot] 20 under that:
/// one button takes the whole width, two share it 12 apart. The card
/// scrolls once its parts outgrow 90% of the screen (84% at desktop
/// width). For a sheet composed in place; [LedgerSheet.show] presents this
/// same widget, so the two never drift apart.
///
/// ```dart
/// LedgerSheetShell(title: 'Add money', foot: [LedgerButton.filled('Confirm', onPressed: add)], children: [amount, from])
/// ```
class LedgerSheetShell extends StatelessWidget {
  /// A sheet's card titled [title], holding [children].
  const LedgerSheetShell({
    required this.title,
    required this.children,
    this.foot = const [],
    this.showClose = true,
    this.onClose,
    this.closeKey,
    this.useSafeArea = false,
    super.key,
  });

  /// The head's title.
  final String title;

  /// The body's parts, in order.
  final List<Widget> children;

  /// The acts at the card's foot: one takes the whole width, two share it.
  final List<Widget> foot;

  /// Whether the head carries the close (a dialog that closes by its own
  /// Cancel leaves it out).
  final bool showClose;

  /// What the close does; null dismisses the sheet's route.
  final VoidCallback? onClose;

  /// A key for the close button, where a tap lands.
  final Key? closeKey;

  /// Apply the bottom safe-area inset inside the card (a phone's sheet).
  final bool useSafeArea;

  /// Whether [context] stands on a sheet's card.
  static bool around(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_OnCard>() != null;

  /// The room inside a card: 10 above, 20 at the sides and 28 under on a
  /// phone; 24 above, 28 at the sides and under at desktop width.
  static EdgeInsets padding(BuildContext context) =>
      LedgerLayout.isWide(context)
      ? const EdgeInsets.fromLTRB(
          LedgerChromeMetrics.dialogPad,
          0,
          LedgerChromeMetrics.dialogPad,
          LedgerChromeMetrics.dialogPad,
        )
      : const EdgeInsets.fromLTRB(
          LedgerChromeMetrics.gutter,
          0,
          LedgerChromeMetrics.gutter,
          LedgerChromeMetrics.sheetFoot,
        );

  /// The foot's acts laid out as the source's: each takes an even share of
  /// the card's width, 12 apart (the card is their measure, so a desktop
  /// dialog's two acts share its 440 as a phone's share its width, and a
  /// phone's one act spans its sheet). From 600 wide each act keeps to 320
  /// at most (a control's measure there), the row on the card's trailing
  /// end with the confirm last: a dialog's lone act, and a wide card's acts
  /// (a tablet's bottom sheet), stand at its end, not across it.
  static Widget footOf(List<Widget> acts) => LedgerCardActsScope(
    child: Builder(
      builder: (context) {
        final row = LedgerEvenActs(
          gap: LedgerChromeMetrics.buttonRowGap,
          children: acts,
        );
        if (MediaQuery.sizeOf(context).width < LedgerLayout.measuredFrom) {
          return row;
        }
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  acts.length * LedgerLayout.fieldMeasure +
                  (acts.length - 1) * LedgerChromeMetrics.buttonRowGap,
            ),
            child: row,
          ),
        );
      },
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('showClose', value: showClose, ifTrue: 'showClose'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onClose', onClose))
      ..add(DiagnosticsProperty<Key>('closeKey', closeKey, defaultValue: null))
      ..add(
        FlagProperty('useSafeArea', value: useSafeArea, ifTrue: 'useSafeArea'),
      );
  }

  @override
  Widget build(BuildContext context) {
    final wide = LedgerLayout.isWide(context);
    final inset = useSafeArea && !wide
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final pad = padding(context);
    return LedgerSheetCard(
      child: SingleChildScrollView(
        padding: pad.copyWith(bottom: pad.bottom + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!wide) const LedgerGrabber(),
            LedgerSheetHead(
              title: title,
              close: showClose
                  ? LedgerIconButton.outlined(
                      LucideIcons.x,
                      key: closeKey,
                      semanticLabel: RawWidgetsLocalizations.of(context)
                          .closeButtonLabel,
                      size: LedgerIconButtonSize.small,
                      tapAlignment: AlignmentDirectional.centerEnd,
                      onPressed:
                          onClose ?? () => Navigator.of(context).maybePop(),
                    )
                  : null,
            ),
            const SizedBox(height: LedgerChromeMetrics.sheetBodyTop),
            ...children,
            if (foot.isNotEmpty) ...[
              const SizedBox(height: LedgerChromeMetrics.sheetFootTop),
              footOf(foot),
            ],
          ],
        ),
      ),
    );
  }
}

/// The card a sheet stands on, as the source draws it: the raised paper
/// (on a phone open at its foot, at desktop width a whole dialog with its
/// own deeper shadow), its content clipped to its corners and marked as on
/// a card ([LedgerSheetShell.around]). Plumbing of the sheets; a page never
/// places one.
class LedgerSheetCard extends StatelessWidget {
  /// The card a sheet's [child] stands on.
  const LedgerSheetCard({required this.child, super.key});

  /// The sheet's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final radius = wide
        ? BorderRadius.circular(t.sheetRadius)
        : BorderRadius.vertical(top: Radius.circular(t.sheetRadius));
    return Material(
      // Text defaults for a sheet composed above any Material; paints
      // nothing.
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: radius,
          boxShadow: wide ? t.dialogShadow : t.sheetShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: _OnCard(child: child),
        ),
      ),
    );
  }
}

/// Marks a sheet's card ([LedgerSheetShell.around]).
class _OnCard extends InheritedWidget {
  const _OnCard({required super.child});

  @override
  bool updateShouldNotify(_OnCard oldWidget) => false;
}

/// Present a sheet: [show] raises a transient one from a control (a
/// category, an amount, a confirm) over the whole app; [pageRoute] is the
/// route a declared sheet PAGE rides, created on the root navigator by the
/// route code ([LedgerSheetPage]): that page is a plain `LedgerScreen`,
/// whose bar becomes the sheet's head with its close.
///
/// On a phone both rise off the bottom edge over the scrim, on ui_core's
/// [RawBottomSheetRoute]: a drag moves the sheet with the finger and a
/// drag down or a fling lets it go. At desktop width both stand centred as
/// a dialog, on ui_core's [RawModalDialogRoute], fading in. Both move on
/// ui_core's springs (a short fade under Reduce Motion), keep the focus in
/// them and give it back as they close; a tap on the scrim, Escape, the
/// system back or the close dismisses them.
///
/// ```dart
/// final picked = await LedgerSheet.show<String>(context, title: 'Category', builder: (context) => [options]);
/// ```
abstract final class LedgerSheet {
  /// Ledger's timed rise and fall above [context] (none at all where the
  /// platform asks for reduced motion), for an app's own transition that
  /// should keep time with Ledger's. Ledger's sheets and dialogs move on
  /// ui_core's springs since 0.3.0 (their routes' `stiffness`).
  static AnimationStyle motionOf(BuildContext context) =>
      LedgerMotion.isReduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: LedgerMotion.slow,
          curve: Curves.easeOutCubic,
          reverseDuration: LedgerMotion.base,
          reverseCurve: Curves.easeInCubic,
        );

  /// The tallest a sheet stands on the screen [context] reads: 90% of it on a
  /// phone, 84% at desktop width.
  static double maxHeight(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).height;
    return screen *
        (LedgerLayout.isWide(context)
            ? LedgerChromeMetrics.dialogMaxShare
            : LedgerChromeMetrics.sheetMaxShare);
  }

  /// The dialog's width at desktop width: 480 for a task, 440 for a
  /// [confirm] (the source's `.modal-sheet.dialog`).
  static double dialogWidth({bool confirm = false}) => confirm
      ? LedgerChromeMetrics.dialogNarrow
      : LedgerChromeMetrics.dialogWidth;

  /// Raises a transient sheet over the whole app (the app's root navigator,
  /// [LedgerHost.navigatorOf]): an [LedgerSheetShell] headed by [title],
  /// holding [builder]'s parts and [foot]'s acts. [confirm] marks a question
  /// its foot's acts answer (Freeze your card?), which at desktop width
  /// stands narrower than a task's. Completes with the value the sheet pops
  /// with: null when it is dismissed (the close, a drag down, the scrim).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<Widget> Function(BuildContext context) builder,
    List<Widget> Function(BuildContext context)? foot,
    bool close = true,
    bool confirm = false,
  }) {
    final t = context.ledgerTheme;
    final navigator = LedgerHost.navigatorOf(context);
    // As showModalBottomSheet does: the caller's themes ride along.
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final most = maxHeight(context);
    Widget shell(BuildContext sheetContext) => RoutePresentationScope(
      presentation: RoutePresentation.sheet,
      child: LedgerSheetShell(
        title: title,
        showClose: close,
        useSafeArea: true,
        foot: foot?.call(sheetContext) ?? const [],
        children: builder(sheetContext),
      ),
    );
    if (LedgerLayout.isWide(context)) {
      return navigator.push(
        RawModalDialogRoute<T>(
          barrierDismissible: true,
          barrierColor: t.overlay,
          semanticLabel: title,
          builder: (sheetContext, details) => themes.wrap(
            FadeTransition(
              opacity: details.animation.drive(ledgerPresence),
              child: LedgerPixelCenter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: dialogWidth(confirm: confirm),
                    maxHeight: most,
                  ),
                  child: shell(sheetContext),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return navigator.push(
      RawBottomSheetRoute<T>(
        barrierColor: t.overlay,
        semanticLabel: title,
        // The keyboard rides outside the card (ui_core stands the sheet on
        // it): the card keeps its geometry and simply sits higher.
        builder: (sheetContext, details) =>
            themes.wrap(_SheetMeasure(most: most, child: shell(sheetContext))),
      ),
    );
  }

  /// The modal route a declared sheet page rides: the page stands on the
  /// sheet's card at the tallest a sheet stands, or with [drawer] as tall
  /// as its content (a short task that leaves the page it came from in
  /// view). At desktop width it is the centred dialog, narrower for a
  /// [confirm].
  static Route<T> pageRoute<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool drawer = false,
    bool confirm = false,
  }) {
    final t = context.ledgerTheme;
    // Measured on the presenting screen: the modal layer sits above the app's
    // own insets and would report none.
    final most = maxHeight(context);
    Widget card(BuildContext sheetContext) => RoutePresentationScope(
      presentation: RoutePresentation.sheet,
      child: _PageSheetCard(child: builder(sheetContext)),
    );
    if (LedgerLayout.isWide(context)) {
      return RawModalDialogRoute<T>(
        settings: settings,
        barrierDismissible: true,
        barrierColor: t.overlay,
        builder: (sheetContext, details) => FadeTransition(
          opacity: details.animation.drive(ledgerPresence),
          child: LedgerPixelCenter(
            child: SizedBox(
              width: dialogWidth(confirm: confirm),
              height: drawer ? null : most,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: most),
                child: card(sheetContext),
              ),
            ),
          ),
        ),
      );
    }
    return RawBottomSheetRoute<T>(
      settings: settings,
      barrierColor: t.overlay,
      builder: (sheetContext, details) => _SheetMeasure(
        most: most,
        // A page stands at the tallest a sheet stands, the keyboard taking
        // its foot; a drawer at its content's height.
        full: !drawer,
        child: card(sheetContext),
      ),
    );
  }
}

/// A phone's sheet on ui_core's route: at most [most] tall and, on a tablet,
/// the sheet's measure, centred; with [full], [most] tall less what the
/// on-screen keyboard takes (the route stands the sheet on the keyboard and
/// gives it the room above, so the card's top stays where it was).
class _SheetMeasure extends StatelessWidget {
  const _SheetMeasure({
    required this.most,
    required this.child,
    this.full = false,
  });

  final double most;
  final bool full;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, room) {
      // The keyboard as the navigator's screen tells it: the route takes it
      // off the sheet's own MediaQuery, and the sheet's room (which changes
      // with it, so this rebuilds) is the navigator's, not the window's (a
      // preview's stage).
      final navigator = Navigator.maybeOf(context);
      final keyboard = navigator == null
          ? 0.0
          : MediaQuery.viewInsetsOf(navigator.context).bottom;
      return Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: LedgerLayout.sheetMeasure,
            maxHeight: math.max(0.0, most - keyboard),
          ),
          child: full
              ? SizedBox(height: math.max(0.0, most - keyboard), child: child)
              : child,
        ),
      );
    },
  );
}

/// The card a sheet page stands on: the sheet's face, and the page told it
/// has no status bar above it.
class _PageSheetCard extends StatelessWidget {
  const _PageSheetCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return LedgerSheetCard(
      child: MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(top: 0),
          viewPadding: mq.viewPadding.copyWith(top: 0),
        ),
        child: child,
      ),
    );
  }
}
