import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialLocalizations, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../internal/soft_routes.dart';
import '../../theme.dart';
import '../glass.dart';
import '../button/button.dart';
import '../host.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';
import '../../internal/act_row.dart';

/// A dialog: a short decision or an acknowledgement on the desktop sheet's
/// face (its white falling to the canvas, corners of 20, its edge and rim,
/// the dialog's shadow), centred over the scrim at most 320 wide, 24 in at
/// every side. Its [title] (the h1) and [message] stand centred; under them
/// [cancelLabel] (a glass act) and [confirmLabel] (the ink act, or the danger fill
/// when the act is [isDestructiveAction]: Delete, Remove) share the row as the
/// sheet's foot sets them; words too long for half the width, or text set
/// large, stack them as wide acts instead, the confirm on top. Without a
/// cancel there is one wide act and nothing to decide. [actions] (the
/// page's own buttons, the dismissive one first and the confirming one
/// last) take the acts' place the same way: side by side while they fit,
/// else stacked with the last on top, as ui_core's `RawActionBar` lays
/// them out. This is the card;
/// [FrostedDialog.show] raises it over the whole app and completes with
/// whether it was confirmed (null when dismissed). A phone shows the same
/// card over the scrim.
///
/// ```dart
/// FrostedDialog(title: 'Freeze this card?', message: 'Payments stop until you unfreeze it.', confirmLabel: 'Freeze', cancelLabel: 'Cancel', onConfirm: freeze, onCancel: close)
/// ```
class FrostedDialog extends StatelessWidget {
  /// Creates a [FrostedDialog].
  const FrostedDialog({
    required this.title,
    this.message,
    this.content,
    this.actions,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.isDestructiveAction = false,
    this.style,
    super.key,
  });

  /// The dialog's head.
  final String title;

  /// The words under the title.
  final String? message;

  /// A part of the page's own between the words and the acts.
  final Widget? content;

  /// The page's own acts, in place of [cancelLabel] and [confirmLabel].
  final List<Widget>? actions;

  /// The confirming act's word.
  final String? confirmLabel;

  /// The declining act's word; null leaves a single act.
  final String? cancelLabel;

  /// What the confirming act does.
  final VoidCallback? onConfirm;

  /// What the declining act does.
  final VoidCallback? onCancel;

  /// Whether confirming is a loss, set in the danger fill.
  final bool isDestructiveAction;

  /// This dialog's own style, over `FrostedThemeData.components.dialog`: its
  /// fill (a flat colour in place of the sheet's face), the edge's colour or
  /// a whole side, its shape ([FrostedCorners.large] by default) and
  /// its padding.
  ///
  /// ```dart
  /// FrostedDialog(
  ///   title: 'Leave the group?',
  ///   style: const FrostedStyle(
  ///     padding: WidgetStatePropertyAll(EdgeInsets.all(32)),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  /// Raises a dialog over the whole app (the app's root navigator,
  /// [FrostedHost.navigatorOf]). Completes with true when confirmed, false
  /// when declined, null when dismissed (the scrim, the system back).
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructiveAction = false,
  }) {
    final t = context.frostedTheme;
    final navigator = FrostedHost.navigatorOf(context);
    final words = MaterialLocalizations.of(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push(
      FrostedSoftDialogRoute<bool>(
        soften: frostedOpaqueAt(context) ? 0 : t.materials.soften,
        barrierDismissible: true,
        barrierLabel: words.scrimLabel,
        barrierColor: t.materials.scrim,
        semanticLabel: title,
        isAlert: true,
        builder: (dialogContext) => themes.wrap(
          RoutePresentationScope(
            presentation: RoutePresentation.sheet,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(FrostedChromeMetrics.dialogEdge),
                child: FrostedDialog(
                  title: title,
                  message: message,
                  content: content,
                  confirmLabel: confirmLabel,
                  cancelLabel: cancelLabel,
                  isDestructiveAction: isDestructiveAction,
                  onConfirm: () => Navigator.of(dialogContext).pop(true),
                  onCancel: () => Navigator.of(dialogContext).pop(false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _confirmAct(String label, {required bool expand}) =>
      isDestructiveAction
      ? _DangerAct(label, onTap: onConfirm, expand: expand)
      : FrostedButton(label, expand: expand, onPressed: onConfirm);

  @override
  Widget build(BuildContext context) {
    final confirmLabel =
        this.confirmLabel ?? RawWidgetsLocalizations.of(context).okButtonLabel;
    final t = context.frostedTheme;
    final decline = cancelLabel;
    final s = FrostedStyleLayers(
      style,
      t.components.dialog,
      const <WidgetState>{},
      t,
    );
    final (cut, corner) = s.surface(
      FrostedCorners.large,
      FrostedStyleLayers.stockLarge,
      t.corner(RawCorner.extraLarge, FrostedChromeMetrics.sheetWideRadius),
    );
    final fill = s.fill;
    // By day the lit hairline round the glass, never a dark line (law 2).
    final (edge, edges) = s.edgeOf(
      frostedLitEdge(t, t.glass.sheetEdge),
      FrostedStrokes.regular,
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: FrostedChromeMetrics.dialogWidth,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: FrostedFace(
            material: FrostedMaterial.slab,
            radius: BorderRadius.circular(corner),
            shape: cut,
            color: fill,
            edge: edge,
            edges: edges,
            ring: frostedSlabRing(t),
            // By night its rim is lit from above, not a stroke (law 2).
            litFromAbove: t.isDark,
            sheen: t.glass.rim,
            shadows: t.shadows.dialog,
            clipChild: true,
            padding:
                s.padding?.resolve(Directionality.of(context)) ??
                const EdgeInsets.all(FrostedChromeMetrics.dialogEdge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: frostedCapCentred(
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineSmall,
                    ),
                  ),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: FrostedChromeMetrics.dialogWordsGap,
                    ),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyLarge.c(
                        t.colorScheme.textSecondary,
                      ),
                    ),
                  ),
                if (content != null)
                  Padding(
                    padding: const EdgeInsets.only(top: FrostedSpacing.s16),
                    child: content,
                  ),
                const SizedBox(height: FrostedChromeMetrics.dialogActsGap),
                switch ((actions, decline)) {
                  (final acts?, _) => FrostedActBar(acts),
                  (null, null) => _confirmAct(confirmLabel, expand: true),
                  (null, final decline?) => FrostedActBar([
                    FrostedButton.glass(decline, onPressed: onCancel),
                    _confirmAct(confirmLabel, expand: false),
                  ]),
                },
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
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(IterableProperty<Widget>('actions', actions, defaultValue: null))
      ..add(StringProperty('confirmLabel', confirmLabel, defaultValue: null))
      ..add(StringProperty('cancelLabel', cancelLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onConfirm', onConfirm))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      )
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

/// The confirming act of a loss: the button's shape in the danger fill, its
/// word in the ink on it; [expand] sets it wide (48, the larger word).
class _DangerAct extends StatelessWidget implements FrostedSizedAct {
  const _DangerAct(this.label, {required this.onTap, required this.expand});

  @override
  FrostedActSize get actSize =>
      expand ? FrostedActSize.wide : FrostedActSize.regular;

  final String label;
  final VoidCallback? onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // As a button: the density's height, and its row's size beside another.
    final wide = FrostedActRow.shown(context, actSize) == FrostedActSize.wide;
    final style = wide
        ? t.textTheme.labelLarge.at(FrostedChromeMetrics.buttonWideWord)
        : t.textTheme.labelLarge;
    // Grown with large text as a button is (else at 200% Delete stands
    // shorter than Keep beside it).
    final height = frostedGrownHeight(
      context,
      t.density.height(
        wide
            ? FrostedChromeMetrics.buttonWideHeight
            : FrostedChromeMetrics.buttonHeight,
      ),
      style,
    );
    final face = SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(height / 2),
        color: t.colorScheme.danger,
        sheen: t.colorScheme.buttonSheen,
        shadows: onTap == null
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: t.colorScheme.danger.withValues(alpha: 0.35),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                  spreadRadius: -8,
                ),
              ],
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedChromeMetrics.buttonInset,
        ),
        child: Center(
          child: frostedCapCentred(
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.c(t.colorScheme.onDanger),
            ),
          ),
        ),
      ),
    );
    final act = FrostedPressable(
      onPressed: onTap,
      semanticLabel: label,
      radius: height / 2,
      child: FrostedDim(off: onTap == null, child: face),
    );
    // A compact act stands in the whole target round its face, as a button
    // does (its pressable lays it out there).
    return act;
  }
}
