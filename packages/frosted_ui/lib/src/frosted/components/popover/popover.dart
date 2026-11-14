import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/panel.dart';
import '../../theme.dart';

/// A panel of the look's glass that a control opens beside itself
/// (`showPopover`, shadcn's Popover): [builder] paints the control and
/// calls the [MenuController]'s `open`, `close` or `toggle`; [content] is
/// what the panel holds (a short form, a filter, details). The panel takes
/// the side with room ([placement], below by default), grows in on a
/// spring, holds Tab inside it, and closes on Escape or a tap outside,
/// focus going back to the control. ui_core's [DesignAnchoredOverlay] is
/// the behaviour; this paints it.
///
/// ```dart
/// FrostedPopover(label: 'Filter', builder: (context, controller, _) => FrostedButton.glass('Filter', onPressed: () => controller.isOpen ? controller.close() : controller.open()), content: Column(mainAxisSize: MainAxisSize.min, children: [FrostedSwitchRow(label: 'Only unread', value: unread, onChanged: setUnread)]))
/// ```
class FrostedPopover extends StatelessWidget {
  /// A popover opened by [builder]'s control, holding [content].
  const FrostedPopover({
    required this.builder,
    required this.content,
    this.child,
    this.width = 288,
    // A panel of its own width, whatever the control it opens from.
    this.placement = const DesignOverlayPlacement(
      gap: 8,
      matchAnchorWidth: false,
    ),
    this.label,
    this.controller,
    this.onOpenChanged,
    super.key,
  });

  /// Paints the control that opens the popover.
  final Widget Function(
    BuildContext context,
    MenuController controller,
    Widget? child,
  )
  builder;

  /// Handed to [builder] as it is, so it is not rebuilt with the control.
  final Widget? child;

  /// What the panel holds.
  final Widget content;

  /// The panel's width.
  final double width;

  /// Which side of the control the panel prefers, and how far off.
  final DesignOverlayPlacement placement;

  /// What a screen reader calls the panel.
  final String? label;

  /// Opens and closes it from outside; null makes its own.
  final MenuController? controller;

  /// Called as the panel opens (true) and closes (false).
  final ValueChanged<bool>? onOpenChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return DesignAnchoredOverlay(
      controller: controller,
      placement: placement,
      semanticLabel: label,
      onOpenChanged: onOpenChanged,
      anchorBuilder: (context, anchor) =>
          builder(context, anchor.controller, child),
      overlayBuilder: (context, info) => FrostedPanel(
        width: width,
        presence: info.animation,
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: t.textTheme.titleMedium.c(t.colorScheme.textPrimary),
          child: content,
        ),
      ),
    );
  }
}

/// A card of details that stands beside [child] while a pointer rests on
/// it (shadcn's HoverCard): a person's name, a link's page. It opens after
/// the pointer has rested 0.7 s and closes 0.3 s after it leaves both the
/// child and the card, so a pointer can travel onto the card; a keyboard
/// reaches it the same way. Pointers only: on a phone it stays shut, so
/// what it says must also be reachable by a tap. ui_core's
/// [DesignAnchoredOverlay] (`trigger: hover`) is the behaviour.
///
/// ```dart
/// FrostedHoverCard(content: Text('Maya Chen · Design lead'), child: FrostedLink('@maya', link: '@maya', onPressed: openProfile))
/// ```
class FrostedHoverCard extends StatelessWidget {
  /// A hover card over [child], holding [content].
  const FrostedHoverCard({
    required this.child,
    required this.content,
    this.width = 300,
    // A panel of its own width, whatever the control it opens from.
    this.placement = const DesignOverlayPlacement(
      gap: 8,
      matchAnchorWidth: false,
    ),
    this.label,
    super.key,
  });

  /// What the pointer rests on.
  final Widget child;

  /// What the card holds.
  final Widget content;

  /// The card's width.
  final double width;

  /// Which side of [child] the card prefers, and how far off.
  final DesignOverlayPlacement placement;

  /// What a screen reader calls the card.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return DesignAnchoredOverlay(
      trigger: DesignOverlayTrigger.hover,
      focusOnOpen: false,
      placement: placement,
      semanticLabel: label,
      anchorBuilder: (context, anchor) => child,
      overlayBuilder: (context, info) => FrostedPanel(
        width: width,
        presence: info.animation,
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: t.textTheme.titleMedium.c(t.colorScheme.textPrimary),
          child: content,
        ),
      ),
    );
  }
}
