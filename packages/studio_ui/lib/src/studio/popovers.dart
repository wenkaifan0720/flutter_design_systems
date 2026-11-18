/// Studio's anchored and edge overlays: [StudioPopover] (a panel that a key
/// opens), [StudioHoverCard] (a panel the pointer opens), [StudioTooltip]
/// (a small dark readout naming a thing), [showStudioSideSheet] (a panel
/// slid in from the side) and [showStudioActionSheet] (a bank of keys from
/// the bottom).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'overlays.dart';
import 'surface.dart';
import 'theme.dart';

// A raised panel with a shadow under it, for whatever an overlay holds.
Widget _panel(
  BuildContext context,
  double width,
  StudioStyle? style,
  Widget child,
) {
  final theme = StudioTheme.of(context);
  final c = theme.colors;
  final night = c.brightness == Brightness.dark;
  final layered = DesignStyleOf([style, theme.popoverStyle], const {});
  final face = layered.on(
    c.panelFace.copyWith(radius: StudioRadii.panel, brushed: true),
  );
  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: width),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StudioRadii.panel),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: night ? 0.55 : 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: StudioSurface(
        face: face,
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              const EdgeInsets.all(StudioSpacing.regular),
          child: DefaultTextStyle.merge(
            style: layered.text(theme.textTheme.body.copyWith(color: c.legend)),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// A panel that a key opens: [builder] draws the opener (given `toggle`
/// and whether it is `open`), and [content] stands in a raised panel under
/// it, with the keyboard inside it; Escape or a press outside closes it.
///
/// Built on ui_core's DesignAnchoredOverlay.
///
/// Reads [style]'s `fill` and `padding`, then
/// [StudioThemeData.popoverStyle].
///
/// ```dart
/// StudioPopover(builder: (context, toggle, open) => StudioButton('Speed', onPressed: toggle), content: (context, close) => speedControls)
/// ```
class StudioPopover extends StatelessWidget {
  /// A popover opened by [builder]'s key.
  const StudioPopover({
    super.key,
    required this.builder,
    required this.content,
    this.width = 320,
    this.semanticLabel,
    this.style,
  });

  /// The opener.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  builder;

  /// What the panel holds; `close` puts it away.
  final Widget Function(BuildContext context, VoidCallback close) content;

  /// Its widest.
  final double width;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its style, over [StudioThemeData.popoverStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    semanticLabel: semanticLabel,
    placement: const DesignOverlayPlacement(
      gap: StudioSpacing.small,
      margin: StudioSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: StudioMotion.dampingRatio,
    stiffness: StudioMotion.overlayStiffness,
    anchorBuilder: (context, anchor) =>
        builder(context, anchor.toggle, anchor.isOpen),
    overlayBuilder: (context, info) => FadeTransition(
      opacity: info.animation,
      child: _panel(context, width, style, content(context, info.close)),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('width', width));
  }
}

/// A panel the pointer opens: rest on [child] and [content] shows in a
/// raised panel beside it; move away and it goes. It adds to the pointer's
/// view only; what it shows must be reachable another way.
///
/// Built on ui_core's DesignAnchoredOverlay.
///
/// ```dart
/// StudioHoverCard(content: (context) => hostDetails, child: StudioLink('Noor Haddad', onPressed: openHost))
/// ```
class StudioHoverCard extends StatelessWidget {
  /// A hover card over [child].
  const StudioHoverCard({
    super.key,
    required this.child,
    required this.content,
    this.width = 300,
    this.style,
  });

  /// What the pointer rests on.
  final Widget child;

  /// What the panel holds.
  final WidgetBuilder content;

  /// Its widest.
  final double width;

  /// Its style, over [StudioThemeData.popoverStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    trigger: DesignOverlayTrigger.hover,
    focusOnOpen: false,
    placement: const DesignOverlayPlacement(
      gap: StudioSpacing.small,
      margin: StudioSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: StudioMotion.dampingRatio,
    stiffness: StudioMotion.overlayStiffness,
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) => FadeTransition(
      opacity: info.animation,
      child: ExcludeSemantics(
        child: _panel(context, width, style, Builder(builder: content)),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('width', width));
  }
}

/// A thing's name in a small dark readout over it, shown after the pointer
/// rests on it for half a second, at once while it has the keyboard, or
/// after a long press of a finger. The pointer may move onto the readout and
/// it stays; Escape hides it; one shows at a time, and along a row of keys
/// the next shows at once. A screen reader hears [message] as the thing's
/// tooltip.
///
/// Built on ui_core's DesignTooltip; Studio paints the readout.
///
/// Reads [style]'s `fill`, `foreground` and `textStyle`, then
/// [StudioThemeData.tooltipStyle].
///
/// ```dart
/// StudioTooltip(message: 'Skip back 15 seconds', child: skipBackKey)
/// ```
class StudioTooltip extends StatelessWidget {
  /// [child] named [message].
  const StudioTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
  });

  /// What it says.
  final String message;

  /// What it names.
  final Widget child;

  /// Its style, over [StudioThemeData.tooltipStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tooltipStyle], const {});
    return DesignTooltip(
      message: message,
      placement: const DesignOverlayPlacement(
        side: DesignOverlaySide.above,
        align: DesignOverlayAlign.center,
        gap: 6,
        margin: StudioSpacing.small,
        preferredExtent: 48,
        matchAnchorWidth: false,
      ),
      child: child,
      tooltipBuilder: (context, info) => FadeTransition(
        opacity: info.animation,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: layered.fill ?? c.readout,
              borderRadius: BorderRadius.circular(StudioRadii.small),
              boxShadow: [
                BoxShadow(
                  color: c.shadow.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding:
                  layered.padding(Directionality.of(context)) ??
                  const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.small,
                    vertical: 6,
                  ),
              child: Text(
                message,
                style: layered.text(
                  theme.textTheme.caption.copyWith(
                    color: layered.foreground ?? c.onReadout,
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
    properties.add(StringProperty('message', message));
  }
}

/// Slides a panel in from the end (or the start, with [fromStart]) over a
/// dimmed page: its [title] engraved at its top beside a close key, what
/// [builder] makes under it. A press on the dimmed page, Escape or a drag
/// back closes it.
///
/// Built on ui_core's DesignSideSheetRoute.
///
/// ```dart
/// showStudioSideSheet<void>(context: context, title: 'Filters', builder: (context) => filters)
/// ```
Future<T?> showStudioSideSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  double width = 380,
  bool fromStart = false,
  StudioStyle? style,
}) {
  final theme = StudioTheme.of(context);
  final words = DesignLocalizations.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    DesignSideSheetRoute<T>(
      edge: fromStart ? DesignSheetEdge.start : DesignSheetEdge.end,
      width: width,
      barrierColor: theme.colors.scrim,
      barrierLabel: words.modalBarrierDismissLabel,
      semanticLabel: title,
      dampingRatio: StudioMotion.dampingRatio,
      stiffness: StudioMotion.overlayStiffness * 0.8,
      builder: (context, sheet) => StudioTheme(
        data: theme,
        child: _SidePanel(
          title: title,
          sheet: sheet,
          builder: builder,
          style: style,
        ),
      ),
    ),
  );
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.title,
    required this.sheet,
    required this.builder,
    this.style,
  });

  final String title;
  final DesignSheetInfo sheet;
  final WidgetBuilder builder;
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final pad = MediaQuery.paddingOf(context);
    final words = DesignLocalizations.of(context);
    final layered = DesignStyleOf([style, theme.sideSheetStyle], const {});
    final night = c.brightness == Brightness.dark;
    final body =
        layered.padding(Directionality.of(context)) ??
        const EdgeInsets.all(StudioSpacing.large);
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: night ? 0.6 : 0.3),
            blurRadius: 24,
          ),
        ],
      ),
      child: StudioSurface(
        face: layered.on(c.panelFace.copyWith(radius: 0, brushed: true)),
        child: Padding(
          padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 64,
                child: Padding(
                  // The title and the close key stand on the body's
                  // keylines: the words where its content starts, the key's
                  // face where it ends.
                  padding: EdgeInsets.only(left: body.left, right: body.right),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: layered.text(
                              theme.textTheme.title.copyWith(color: c.legend),
                            ),
                          ),
                        ),
                      ),
                      StudioIconButton(
                        icon: const Icon(LucideIcons.x),
                        tooltip: words.closeButtonLabel,
                        onPressed: sheet.close,
                      ),
                    ],
                  ),
                ),
              ),
              const StudioGroove(),
              Expanded(
                child: SingleChildScrollView(
                  padding: body,
                  child: DesignKeylineRegion(
                    label: title,
                    child: DefaultTextStyle.merge(
                      style: theme.textTheme.body.copyWith(color: c.legend),
                      child: Builder(builder: builder),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One key of an action sheet.
@immutable
class StudioSheetAction<T> {
  /// An action [label]led, giving [value].
  const StudioSheetAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructiveAction = false,
  });

  /// Its legend.
  final String label;

  /// What choosing it gives.
  final T value;

  /// A glyph before its legend.
  final Widget? icon;

  /// Whether it destroys something: its legend in red.
  final bool isDestructiveAction;
}

/// Asks which of a few actions to take: a sheet up from the bottom with
/// [title] (and [message]), the [actions] as a column of full-width keys,
/// and a cancel key apart under them. Gives the chosen action's value, or
/// null.
///
/// ```dart
/// showStudioActionSheet<String>(context: context, title: 'This take', actions: const [StudioSheetAction(label: 'Keep', value: 'keep'), StudioSheetAction(label: 'Discard', value: 'discard', isDestructiveAction: true)])
/// ```
Future<T?> showStudioActionSheet<T>({
  required BuildContext context,
  required String title,
  required List<StudioSheetAction<T>> actions,
  String? message,
  String cancelLabel = 'Cancel',
}) => showStudioBottomSheet<T>(
  context: context,
  title: title,
  builder: (context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message != null) ...[
          Text(
            message,
            style: theme.textTheme.secondary.copyWith(color: c.legendMuted),
          ),
          const SizedBox(height: StudioSpacing.regular),
        ],
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(height: StudioSpacing.small),
          SizedBox(
            height: theme.controlHeight + 4,
            child: StudioButton(
              a.label,
              icon: a.icon,
              isDestructiveAction: a.isDestructiveAction,
              onPressed: () => Navigator.of(context).pop(a.value),
            ),
          ),
        ],
        const SizedBox(height: StudioSpacing.large),
        SizedBox(
          height: theme.controlHeight + 4,
          child: StudioButton.text(
            cancelLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  },
);
