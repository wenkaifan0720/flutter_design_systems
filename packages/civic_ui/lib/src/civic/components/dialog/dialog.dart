import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../theme.dart';

/// Opens [builder]'s [CivicDialog] over the page, on a scrim of ink, and
/// returns what it closes with: ui_core's [DesignDialogRoute], Civic's
/// painting. The scrim comes up on a spring under a dialog that stands whole
/// from its first frame (under Reduce Motion, whichever platform asks for
/// it, the two fade in together, settled within 150 ms). The keyboard's
/// focus stays inside it until it closes, then goes back to what held it.
/// Escape, Android's back and a press on the scrim close it, unless
/// [barrierDismissible] is false: a dialog that must be answered, which only
/// its own buttons close and which a screen reader hears as an alert.
///
/// ```dart
/// final cancel = await showCivicDialog<bool>(
///   context: context,
///   builder: (context) => CivicDialog(
///     title: 'Cancel your application?',
///     content: const Text('You will lose the answers you have given.'),
///     actions: [
///       CivicButton(isDestructiveAction: true, onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancel application')),
///       CivicButton.secondary(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep it')),
///     ],
///   ),
/// );
/// ```
Future<T?> showCivicDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final t = CivicTheme.of(context);
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    DesignDialogRoute<T>(
      isAlert: !barrierDismissible,
      barrierDismissible: barrierDismissible,
      // By night the scrim is black and deeper, so the page behind falls
      // back as far as it does by day.
      barrierColor: t.isDark
          ? const Color(0xFF000000).withValues(alpha: 0.85)
          : const Color(0xFF0C1116).withValues(alpha: 0.6),
      // The scrim comes up on Civic's panel spring; the dialog itself does
      // not move.
      dampingRatio: CivicMotion.panel.dampingRatio,
      stiffness: CivicMotion.panel.stiffness,
      builder: (context, _) => CivicTheme(
        data: t,
        // One that must be answered: neither Escape nor back closes it.
        child: PopScope<T>(
          canPop: barrierDismissible,
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
}

/// A question the page stops for: a card on the page's white (by night the
/// raised surface), its corners rounded, floating on a hairline and a soft
/// shadow over the scrim, its [title] as a heading,
/// its [content] under it, its [actions] at the foot (the one that does
/// what the title asks first; full width below 600).
///
/// Reads [CivicStyle]'s fill, edge, foreground, padding and textStyle (the
/// question): its `style:`, then [CivicThemeData.dialogStyle]. The edge's
/// width is the look's.
///
/// [showCivicDialog] opens one; its example builds a dialog with its
/// actions.
class CivicDialog extends StatelessWidget {
  /// A dialog.
  const CivicDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
    this.style,
  });

  /// The question.
  final String title;

  /// What else to know.
  final Widget? content;

  /// Its buttons.
  final List<Widget> actions;

  /// Overrides for this dialog's look.
  final CivicStyle? style;

  /// The widest a dialog stands.
  static const double maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < CivicLayout.medium;
    final body = content;
    final so = DesignStyleOf([style, t.dialogStyle], const {});
    final words = text.body.copyWith(color: so.foreground);
    return SafeArea(
      child: Center(
        child: Padding(
          // On a phone the dialog's edges stand on the page's margin, so
          // they meet the page's column instead of nearly missing it.
          padding: EdgeInsets.all(
            narrow ? CivicLayout.marginFor(size.width) : CivicSpacing.s32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            // Its title names the route the dialog's route scopes.
            child: Semantics(
              namesRoute: true,
              explicitChildNodes: true,
              label: title,
              child: DecoratedBox(
                // A card over the scrim, its corners a card's; by night it
                // stands on the raised band, apart from the page under it.
                decoration: civicFloating(
                  face: so.fill ?? (t.isDark ? t.surface : t.background),
                  hairline: so.edge ?? t.rule,
                  dark: t.isDark,
                  radius: CivicMetrics.cardCorner,
                ),
                child: SingleChildScrollView(
                  // The room under the last button matches the room the
                  // title's line leaves over its words.
                  padding:
                      so.padding(Directionality.of(context)) ??
                      (narrow
                          ? const EdgeInsets.fromLTRB(
                              CivicSpacing.s20,
                              CivicSpacing.s20,
                              CivicSpacing.s20,
                              CivicSpacing.s24,
                            )
                          : const EdgeInsets.fromLTRB(
                              CivicSpacing.s32,
                              CivicSpacing.s32,
                              CivicSpacing.s32,
                              CivicSpacing.s40,
                            )),
                  child: DefaultTextStyle(
                    style: words,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: text.headingM
                                .copyWith(color: so.foreground)
                                .merge(so.textStyle),
                          ),
                        ),
                        if (body != null) ...[
                          const SizedBox(height: CivicSpacing.s16),
                          body,
                        ],
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: CivicSpacing.s32),
                          if (narrow)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: CivicSpacing.s12,
                              children: actions,
                            )
                          else
                            Wrap(
                              spacing: CivicSpacing.s16,
                              runSpacing: CivicSpacing.s12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: actions,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(IntProperty('actions', actions.length))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
