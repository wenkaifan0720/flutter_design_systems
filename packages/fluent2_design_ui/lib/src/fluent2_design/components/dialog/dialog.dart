import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../host.dart';

import 'package:ui_core/ui_core.dart';

/// Fluent 2's Dialog, its surface drawn in place: the surface centred over
/// the overlay, at most 600 wide, its corners 8, 24 round its parts, in
/// `shadow64`; the [title] in subtitle1, the [body] 8 under it in body1,
/// the [actions] 24 under that at the end, 8 apart, the primary last (on a
/// narrow phone they stack, the primary on top). An alert dialog: no
/// dismiss in its head, closed by its own acts. Raise one with [show] or
/// [confirm].
///
/// ```dart
/// Fluent2Dialog(title: 'Delete Q3 plan.docx?', content: const Text('It moves to the recycle bin for 30 days.'), actions: [Fluent2Button('Cancel', onPressed: cancel), Fluent2Button('Delete', appearance: Fluent2ButtonAppearance.primary, onPressed: delete)])
/// ```
class Fluent2Dialog extends StatelessWidget {
  /// A dialog titled [title].
  const Fluent2Dialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  /// The dialog's title.
  final String title;

  /// Its words, in body1 under the title; [content] follows them.
  final String? message;

  /// Whatever the words alone cannot say.
  final Widget? content;

  /// The acts, the primary last.
  final List<Widget> actions;

  /// Raises [dialog] over the whole app; completes with the value it pops
  /// with (null when the overlay is tapped).
  static Future<T?> show<T>(
    BuildContext context,
    Widget Function(BuildContext context) dialog,
  ) {
    final t = context.fluent2Theme;
    final navigator = Fluent2Host.navigatorOf(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push(
      RawDialogRoute<T>(
        barrierDismissible: true,
        barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: t.overlay,
        transitionDuration: Fluent2Motion.on(context)
            ? Fluent2Motion.gentle
            : Duration.zero,
        transitionBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Fluent2Motion.decelerateMid,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Fluent2Motion.decelerateMid,
              ),
            ),
            child: child,
          ),
        ),
        pageBuilder: (dialogContext, _, _) =>
            themes.wrap(Builder(builder: dialog)),
      ),
    );
  }

  /// Asks [title] (with [message]) and completes true on [confirmLabel],
  /// false on [cancelLabel], null when dismissed. Fluent 2 has no danger
  /// button: a loss is the primary act whose words say it ('Delete'). The
  /// labels default to "OK" and "Cancel" in the app's language.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
  }) => show<bool>(
    context,
    (dialogContext) => Fluent2Dialog(
      title: title,
      content: message == null ? null : Text(message),
      actions: [
        Fluent2Button(
          cancelLabel ??
              DesignLocalizations.of(dialogContext).cancelButtonLabel,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        Fluent2Button(
          confirmLabel ?? DesignLocalizations.of(dialogContext).okButtonLabel,
          appearance: Fluent2ButtonAppearance.primary,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final look = Fluent2StyleOf([t.dialogTheme], const {});
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Fluent2Spacing.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Fluent2ChromeMetrics.dialogWidth,
          ),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: Material(
              type: MaterialType.transparency,
              child: Fluent2Plate(
                fill: look.fill ?? t.colors.neutralBackground1,
                side:
                    look.side ??
                    (look.edge != null || t.isDark
                        ? BorderSide(
                            color: look.edge ?? t.colors.neutralStroke2,
                            width: Fluent2Stroke.thin,
                          )
                        : BorderSide.none),
                radius: BorderRadius.circular(Fluent2Radius.xLarge),
                shape: look.shape,
                shadows: t.shadows.shadow64,
                padding:
                    look.padding(Directionality.of(context)) ??
                    const EdgeInsets.all(Fluent2ChromeMetrics.dialogPadding),
                child: DefaultTextStyle(
                  style: t.body1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: t.subtitle1),
                      ),
                      if (message != null || content != null) ...[
                        const SizedBox(height: Fluent2ChromeMetrics.dialogGap),
                        Flexible(
                          child: SingleChildScrollView(
                            child: message == null
                                ? content
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    spacing: Fluent2ChromeMetrics.dialogGap,
                                    children: [Text(message!), ?content],
                                  ),
                          ),
                        ),
                      ],
                      if (actions.isNotEmpty) ...[
                        const SizedBox(
                          height: Fluent2ChromeMetrics.dialogActionsGap,
                        ),
                        if (narrow)
                          Fluent2ActsFill(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: Fluent2Spacing.s,
                              children: actions.reversed.toList(),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: Fluent2Spacing.s,
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
    );
  }
}
