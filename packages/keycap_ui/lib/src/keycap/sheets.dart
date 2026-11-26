/// Keycap's other sheets: [KeycapSideSheet] (a panel sliding in from the
/// side, for wide screens) and [KeycapActionSheet] (a short list of
/// actions sliding up, a key to cancel under them).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'cap.dart';
import 'overlays.dart';
import 'select.dart';
import 'theme.dart';

// The ui_core types these parts' APIs take, through the look's barrel.
export 'package:ui_core/ui_core.dart' show RawSheetEdge;

/// A panel of keycap plastic sliding in from the screen's side (the end,
/// by default): a [title] and a close key at its top, its [child]
/// scrolling, [footer] keys sharing its foot. For a wide screen's details
/// and filters; a phone uses [KeycapSheet].
///
/// ```dart
/// showKeycapSideSheet(context: context, title: 'Filters', builder: (context) => filters)
/// ```
class KeycapSideSheet extends StatelessWidget {
  /// A side sheet.
  const KeycapSideSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.footer = const [],
    this.side = AxisDirection.right,
    this.style,
  });

  /// What it holds.
  final Widget child;

  /// Its name.
  final String? title;

  /// Called by its close key; shows one when given.
  final VoidCallback? onClose;

  /// Keys at its foot, sharing the row.
  final List<Widget> footer;

  /// The side it stands on.
  final AxisDirection side;

  /// Overrides, over [KeycapThemeData.dialogStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = RawStyleOf([style, theme.dialogStyle], const {});
    final words = RawWidgetsLocalizations.of(context);
    final media = MediaQuery.of(context);
    const r = Radius.circular(KeycapMetrics.panelRadius);
    final radius = side == AxisDirection.left
        ? const BorderRadius.horizontal(right: r)
        : const BorderRadius.horizontal(left: r);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: KeycapPanel(
        color: layered.fill,
        radius: radius,
        child: Padding(
          padding: EdgeInsets.only(
            top: media.padding.top,
            bottom: media.padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                // The close key ends on the content's edge.
                padding: const EdgeInsetsDirectional.fromSTEB(
                  KeycapSpacing.large,
                  KeycapSpacing.regular,
                  KeycapSpacing.large,
                  0,
                ),
                // At least the close key's finger floor high; taller when
                // large text takes the title to two lines.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: RawTapTargets.of(context).touch.height,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: title == null
                            ? const SizedBox()
                            : Semantics(
                                header: true,
                                child: Text(
                                  title!,
                                  maxLines: 2,
                                  style: theme.textTheme.heading.copyWith(
                                    color: theme.colors.ink,
                                  ),
                                ),
                              ),
                      ),
                      if (onClose != null)
                        KeycapIconButton(
                          icon: const Icon(LucideIcons.x),
                          semanticLabel: words.closeButtonLabel,
                          onPressed: onClose,
                          style: const KeycapStyle(
                            minimumSize: WidgetStatePropertyAll(
                              Size.square(40),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(KeycapSpacing.large),
                  child: child,
                ),
              ),
              if (footer.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KeycapSpacing.large,
                    0,
                    KeycapSpacing.large,
                    KeycapSpacing.large,
                  ),
                  child: Row(
                    children: [
                      for (final (i, a) in footer.indexed) ...[
                        if (i > 0) const SizedBox(width: KeycapSpacing.small),
                        Expanded(child: a),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title, defaultValue: null));
  }
}

/// Slides a [KeycapSideSheet] in from [edge] (the end, by default), the
/// keyboard dimmed under it; a swipe toward its edge, Escape or a tap on
/// the dimmed keyboard closes it.
///
/// ```dart
/// showKeycapSideSheet(context: context, title: 'Filters', builder: (context) => filters)
/// ```
Future<T?> showKeycapSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  List<Widget> footer = const [],
  RawSheetEdge edge = RawSheetEdge.end,
  double width = 380,
}) {
  final theme = KeycapTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    RawSideSheetRoute<T>(
      edge: edge,
      width: width,
      barrierColor: theme.colors.scrim,
      semanticLabel: title,
      dampingRatio: KeycapMotion.sheet.dampingRatio,
      stiffness: KeycapMotion.sheet.stiffness,
      builder: (context, sheet) => KeycapTheme(
        data: theme,
        child: KeycapSideSheet(
          title: title,
          footer: footer,
          side: sheet.side,
          onClose: sheet.close,
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
}

/// One action of a [KeycapActionSheet].
@immutable
class KeycapSheetAction {
  /// An action reading [label].
  const KeycapSheetAction(
    this.label, {
    required this.onPressed,
    this.isDestructiveAction = false,
    this.icon,
  });

  /// Its words.
  final String label;

  /// What it does; the sheet closes first.
  final VoidCallback onPressed;

  /// Whether it destroys something (printed in the danger ink).
  final bool isDestructiveAction;

  /// A glyph before the words.
  final IconData? icon;
}

/// A short list of actions on a panel at the keyboard's front edge (a
/// note's "Share, Duplicate, Delete"), the one lit row on a plate, and a
/// key under them to cancel. Opened by [showKeycapActionSheet].
///
/// ```dart
/// KeycapActionSheet(actions: [KeycapSheetAction('Duplicate', onPressed: duplicate)], onCancel: () => Navigator.pop(context))
/// ```
class KeycapActionSheet extends StatelessWidget {
  /// An action sheet.
  const KeycapActionSheet({
    super.key,
    required this.actions,
    required this.onCancel,
    this.title,
    this.message,
    this.cancelLabel,
    this.style,
  });

  /// The actions.
  final List<KeycapSheetAction> actions;

  /// Closes it with nothing done.
  final VoidCallback onCancel;

  /// What the actions act on.
  final String? title;

  /// More words.
  final String? message;

  /// The cancel key's words; the kit's "Cancel" when null.
  final String? cancelLabel;

  /// Overrides, over [KeycapThemeData.dialogStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.dialogStyle], const {});
    final media = MediaQuery.of(context);
    final words = RawWidgetsLocalizations.of(context);
    const top = Radius.circular(KeycapMetrics.panelRadius);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: KeycapSheet.maxWidth),
      child: Semantics(
        explicitChildNodes: true,
        child: KeycapPanel(
          color: layered.fill,
          radius: const BorderRadius.only(topLeft: top, topRight: top),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              KeycapSpacing.regular,
              KeycapSpacing.regular,
              KeycapSpacing.regular,
              KeycapSpacing.regular + media.padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Semantics(
                    header: true,
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.label.copyWith(color: c.inkMuted),
                    ),
                  ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: KeycapSpacing.tight),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.secondary,
                    ),
                  ),
                if (title != null || message != null)
                  const SizedBox(height: KeycapSpacing.small),
                for (final a in actions)
                  RawButton(
                    onPressed: a.onPressed,
                    semanticLabel: a.label,
                    excludeSemantics: true,
                    builder: (context, states, _) => KeycapMenuRow(
                      label: a.label,
                      height: theme.controlHeight,
                      isDestructiveAction: a.isDestructiveAction,
                      leading: a.icon == null ? null : Icon(a.icon),
                      lit:
                          states.contains(WidgetState.focused) ||
                          states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.pressed),
                    ),
                  ),
                const SizedBox(height: KeycapSpacing.regular),
                KeycapButton(
                  onPressed: onCancel,
                  child: Text(cancelLabel ?? words.cancelButtonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('actions', actions.length));
  }
}

/// Slides a [KeycapActionSheet] up from the keyboard's front edge; an
/// action closes it before it runs.
///
/// ```dart
/// showKeycapActionSheet(context: context, title: 'Garden plan', actions: [KeycapSheetAction('Delete', isDestructiveAction: true, onPressed: delete)])
/// ```
Future<void> showKeycapActionSheet({
  required BuildContext context,
  required List<KeycapSheetAction> actions,
  String? title,
  String? message,
  String? cancelLabel,
}) => showKeycapSheet<void>(
  context: context,
  semanticLabel: title,
  builder: (sheetContext) => KeycapActionSheet(
    title: title,
    message: message,
    cancelLabel: cancelLabel,
    onCancel: () => Navigator.of(sheetContext).pop(),
    actions: [
      for (final a in actions)
        KeycapSheetAction(
          a.label,
          isDestructiveAction: a.isDestructiveAction,
          icon: a.icon,
          onPressed: () {
            Navigator.of(sheetContext).pop();
            a.onPressed();
          },
        ),
    ],
  ),
);
