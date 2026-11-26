import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/route_motion.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../host.dart';

import 'package:ui_core/ui_core.dart';

/// Fluent 2's Dialog, its surface drawn in place: the surface centred over the
/// overlay, at most 600 wide, its corners 8, 24 round its parts, in `shadow64`;
/// the [title] in subtitle1, the [message] and [content] 8 under it in body1,
/// the [actions] 24 under that at the end, 8 apart, the primary last (on a
/// narrow phone they stack, the primary on top). An alert dialog: no dismiss in
/// its head, closed by its own acts. Raise one with [show] or [confirm]. An
/// act that loses something is a [Fluent2Button.danger]: the primary on
/// danger's solid when the loss is what the dialog asks for (Delete), a
/// secondary in danger's ink beside another primary (Discard by Save).
///
/// ```dart
/// Fluent2Dialog(title: 'Delete Q3 plan.docx?', content: const Text('It moves to the recycle bin for 30 days.'), actions: [Fluent2Button('Cancel', onPressed: cancel), Fluent2Button('Delete', appearance: Fluent2ButtonAppearance.primary, danger: true, onPressed: delete)])
/// ```
class Fluent2Dialog extends StatelessWidget {
  /// A dialog titled [title].
  const Fluent2Dialog({
    this.style,
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  /// This dialog's own look, slot by slot, over its component theme
  /// ([Fluent2ThemeData.dialogTheme]): the slots its doc names.
  final Fluent2Style? style;

  /// The dialog's title; an empty one draws no head, and a screen reader
  /// hears ui_core's word for a dialog in the app's language.
  final String title;

  /// Its words, in body1 under the title; [content] follows them.
  final String? message;

  /// Whatever the words alone cannot say.
  final Widget? content;

  /// The acts, the primary last.
  final List<Widget> actions;

  /// Raises [dialog] over the whole app; completes with the value it pops
  /// with (null when the overlay is tapped or Escape pressed).
  ///
  /// It is ui_core's dialog route (`RawModalDialogRoute`): it fades in from
  /// .95 of its size on a spring that settles in Fluent's `durationGentle`,
  /// and under Reduce Motion only fades. Focus moves into it, Tab stays
  /// inside it, and as it closes the focus goes back to what held it. A
  /// screen reader hears a dialog named by its title, or with [isAlert] an
  /// alert dialog (the overlay still closes it).
  static Future<T?> show<T>(
    BuildContext context,
    Widget Function(BuildContext context) dialog, {
    bool isAlert = false,
  }) {
    final t = context.fluent2Theme;
    final navigator = Fluent2Host.navigatorOf(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push(
      RawModalDialogRoute<T>(
        isAlert: isAlert,
        barrierDismissible: true,
        barrierLabel: RawWidgetsLocalizations.of(context)
            .modalBarrierDismissLabel,
        barrierColor: t.overlay,
        dampingRatio: Fluent2Motion.springDamping,
        stiffness: Fluent2Motion.springGentle,
        builder: (dialogContext, details) => themes.wrap(
          fluent2DialogRise(details.animation, Builder(builder: dialog)),
        ),
      ),
    );
  }

  /// Asks [title] (with [message]), an alert dialog to a screen reader, and
  /// completes true on [confirmLabel], false on [cancelLabel], null when
  /// dismissed. With [danger] the confirming act is a loss ('Delete'), on
  /// danger's solid. The labels default to "OK" and "Cancel" in the app's
  /// language.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    bool danger = false,
  }) => show<bool>(
    context,
    isAlert: true,
    (dialogContext) => Fluent2Dialog(
      title: title,
      content: message == null ? null : Text(message),
      actions: [
        Fluent2Button(
          cancelLabel ??
              RawWidgetsLocalizations.of(dialogContext).cancelButtonLabel,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        Fluent2Button(
          confirmLabel ??
              RawWidgetsLocalizations.of(dialogContext).okButtonLabel,
          appearance: Fluent2ButtonAppearance.primary,
          danger: danger,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final look = Fluent2StyleOf([style, t.dialogTheme], const {});
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Fluent2Spacing.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Fluent2ChromeMetrics.dialogWidth,
          ),
          // The route round it is the dialog a screen reader hears; its
          // title names it.
          child: Semantics(
            namesRoute: true,
            explicitChildNodes: true,
            label: title.isEmpty
                ? RawWidgetsLocalizations.of(context).dialogLabel
                : title,
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
                      if (title.isNotEmpty)
                        Semantics(
                          header: true,
                          child: Text(title, style: t.subtitle1),
                        ),
                      if (message != null || content != null) ...[
                        if (title.isNotEmpty)
                          const SizedBox(
                            height: Fluent2ChromeMetrics.dialogGap,
                          ),
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
                        // Under 480 Fluent stacks a dialog's acts, the
                        // primary on top; wider they stand at the end at
                        // their own widths while they fit, and stack once
                        // they don't (long words, large text).
                        if (narrow)
                          Fluent2ActsFill(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: Fluent2Spacing.s,
                              children: actions.reversed.toList(),
                            ),
                          )
                        else
                          Fluent2ActsFill(
                            child: RawActionBar(
                              spacing: Fluent2Spacing.s,
                              overflowSpacing: Fluent2Spacing.s,
                              children: actions,
                            ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
      )
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null));
  }
}
