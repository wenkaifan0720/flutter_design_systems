/// Appliance's anchored surfaces: [AppliancePopover] and [ApplianceHoverCard]
/// (a small plate lifted beside what opened it), [ApplianceTooltip] (a
/// word lit in a smoked window), [ApplianceMenu] and [ApplianceContextMenu]
/// (a plate of rows), and [ApplianceBanner] (a lit strip across a page).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/glyphs.dart';
import 'internal/menu_paint.dart';
import 'material.dart';
import 'menus.dart';
import 'select.dart';
import 'theme.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart' show DesignOverlayAnchor;

/// A plate lifted off the panel, holding [child] with room round it.
class _Plate extends StatelessWidget {
  const _Plate({required this.child, required this.style, this.maxHeight});

  final Widget child;
  final ApplianceStyle? style;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.popoverStyle], const {});
    return Padding(
      padding: const EdgeInsets.only(bottom: ApplianceSpacing.tight),
      child: ApplianceSurface(
        face: layered.on(
          ApplianceFace(
            top: c.keyTop,
            bottom: c.face,
            lift: 1.4,
            radius: BorderRadius.circular(ApplianceMetrics.troughRadius),
            foreground: c.print,
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
          child: SingleChildScrollView(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.all(ApplianceSpacing.regular),
            child: DefaultTextStyle.merge(
              style: theme.textTheme.body.copyWith(color: c.print),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A popover: a small plate lifted beside what opened it, holding more
/// (a note, a short form). [builder] makes the opener from the anchor
/// (press it to toggle); Escape or a press outside closes it.
///
/// ```dart
/// AppliancePopover(semanticLabel: 'Delivery note', builder: (context, anchor) => ApplianceButton('Note', onPressed: anchor.toggle), content: (context, close) => const Text('Leave by the back door.'))
/// ```
class AppliancePopover extends StatelessWidget {
  /// A popover opened from [builder]'s widget.
  const AppliancePopover({
    super.key,
    required this.builder,
    required this.content,
    this.semanticLabel,
    this.width = 300,
    this.style,
  });

  /// Builds the opener; `anchor.toggle` opens and closes it.
  final Widget Function(BuildContext context, DesignOverlayAnchor anchor)
  builder;

  /// Builds what it holds; `close` shuts it.
  final Widget Function(BuildContext context, VoidCallback close) content;

  /// Its name for a screen reader.
  final String? semanticLabel;

  /// The plate's width.
  final double width;

  /// The plate's style, over [ApplianceThemeData.popoverStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    semanticLabel: semanticLabel,
    placement: RawPopoverPlacement(
      gap: ApplianceSpacing.small,
      margin: ApplianceSpacing.small,
      matchAnchorWidth: false,
      maxWidth: width,
      preferredExtent: 240,
    ),
    dampingRatio: ApplianceMotion.lid.dampingRatio,
    stiffness: ApplianceMotion.lid.stiffness,
    anchorBuilder: builder,
    overlayBuilder: (context, info) => ApplianceMenuReveal(
      animation: info.animation,
      below: info.side != RawPopoverSide.above,
      child: SizedBox(
        width: width,
        child: _Plate(
          style: style,
          maxHeight: info.maxSize.height,
          child: content(context, info.close),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('width', width));
  }
}

/// A hover card: the popover's plate, opened by resting the pointer on
/// [child] (or the keyboard's focus, or a long press), with more about it.
///
/// ```dart
/// ApplianceHoverCard(card: (context) => const Text('Ships in two days'), child: const Text('Kettle'))
/// ```
class ApplianceHoverCard extends StatelessWidget {
  /// A hover card over [child].
  const ApplianceHoverCard({
    super.key,
    required this.child,
    required this.card,
    this.width = 280,
    this.style,
  });

  /// What it is about.
  final Widget child;

  /// Builds what it says.
  final WidgetBuilder card;

  /// The plate's width.
  final double width;

  /// The plate's style, over [ApplianceThemeData.popoverStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    trigger: RawPopoverTrigger.hover,
    focusOnOpen: false,
    placement: RawPopoverPlacement(
      gap: ApplianceSpacing.small,
      margin: ApplianceSpacing.small,
      matchAnchorWidth: false,
      maxWidth: width,
    ),
    dampingRatio: ApplianceMotion.lid.dampingRatio,
    stiffness: ApplianceMotion.lid.stiffness,
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) => ApplianceMenuReveal(
      animation: info.animation,
      below: info.side != RawPopoverSide.above,
      child: SizedBox(
        width: width,
        child: _Plate(
          style: style,
          child: Builder(builder: card),
        ),
      ),
    ),
  );
}

/// A tooltip: [message] lit in a small smoked window over [child] while
/// the pointer rests on it, while the keyboard is on it, or after a long
/// press. The pointer may move onto it; Escape hides it; one shows at a
/// time. A screen reader hears [message] as [child]'s tooltip.
///
/// Built on Flutter's RawTooltip, with ui_core's RawTooltipFocusFix (it
/// shows on the keyboard's focus) and RawTooltipPlacement (above [child],
/// below where there is no room); Appliance paints the window, fading it
/// in and out with the tooltip.
///
/// ```dart
/// const ApplianceTooltip(message: 'Keeps warm for 30 minutes', child: Text('Keep warm'))
/// ```
class ApplianceTooltip extends StatelessWidget {
  /// [message] over [child].
  const ApplianceTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
  });

  /// What it says.
  final String message;

  /// What it is about.
  final Widget child;

  /// Its style, over [ApplianceThemeData.tooltipStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tooltipStyle], const {});
    return RawTooltipPlacement(
      placement: const RawPopoverPlacement(
        side: RawPopoverSide.above,
        align: RawPopoverAlign.center,
        gap: ApplianceSpacing.tight + ApplianceSpacing.nudge,
        matchAnchorWidth: false,
        maxWidth: 260,
        preferredExtent: 48,
      ),
      builder: (context, positionDelegate) => MergeSemantics(
        // One node for the control and its tip, as the published tooltip
        // made: a screen reader hears the tip with the control. RawTooltip's
        // own tooltip semantics do not merge, and went to the node above.
        child: RawTooltip(
          semanticsTooltip: message,
          hoverDelay: const Duration(milliseconds: 500),
          positionDelegate: positionDelegate,
          tooltipBuilder: (context, animation) => FadeTransition(
            opacity: animation,
            // The window's widest; the placement keeps it on the screen.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Container(
                padding:
                    layered.padding(Directionality.of(context)) ??
                    const EdgeInsets.symmetric(
                      horizontal: ApplianceSpacing.small + 2,
                      vertical: ApplianceSpacing.tight + 2,
                    ),
                decoration: _tooltipGlass(c, layered.fill ?? c.display),
                child: Text(
                  message,
                  style: layered.text(
                    theme.textTheme.secondary.copyWith(
                      color: layered.foreground ?? c.onDisplay,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: RawTooltipFocusFix(child: child),
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

// A tooltip's glass: by night smoked glass in a metal bezel; by day a pale
// LCD in a dark bezel, standing off the panel on a soft shadow.
BoxDecoration _tooltipGlass(ApplianceColors c, Color glass) {
  final lcd = glass.computeLuminance() > 0.4;
  return BoxDecoration(
    color: glass,
    borderRadius: BorderRadius.circular(ApplianceSpacing.tight),
    border: Border.all(
      color: lcd ? Color.lerp(glass, c.onDisplay, 0.55)! : c.metalDark,
      width: 1.5,
    ),
    boxShadow: lcd
        ? [
            BoxShadow(
              color: c.shade.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
        : null,
  );
}

/// A menu's rows on a plate, each closing it and running its entry.
class _MenuRows extends StatelessWidget {
  const _MenuRows({required this.entries, required this.info, this.style});

  final List<RawMenuEntry> entries;
  final RawPopoverInfo info;
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    return ApplianceMenuReveal(
      animation: info.animation,
      below: info.side != RawPopoverSide.above,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200),
        child: ApplianceMenuPlate(
          maxHeight: info.maxSize.height,
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in entries)
                  if (entry.divider)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(
                        vertical: ApplianceSpacing.tight,
                        horizontal: ApplianceSpacing.small,
                      ),
                      color: c.seamShade,
                    )
                  else
                    RawButton(
                      onPressed: entry.onPressed == null
                          ? null
                          : () {
                              info.close();
                              entry.onPressed!();
                            },
                      checked: entry.checked,
                      semanticLabel: entry.label,
                      excludeSemantics: true,
                      builder: (context, states, _) => ApplianceMenuRow(
                        style: style,
                        label: entry.label,
                        states: states,
                        enabled: entry.onPressed != null,
                        chosen: entry.checked,
                        trailing: entry.shortcut == null
                            ? null
                            : Text(entry.shortcut!),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A menu: a plate of rows opened from [builder]'s key (press it, or Down
/// on it); the arrows walk the rows, Enter runs one, Escape closes it.
/// Entries are [RawMenuEntry]s: a command, a check (its lamp), or a
/// divider.
///
/// ```dart
/// ApplianceMenu(entries: [RawMenuEntry(label: 'Rename', onPressed: () {})], builder: (context, anchor) => ApplianceIconButton(icon: const Icon(IconData(0x2026)), semanticLabel: 'More', onPressed: anchor.toggle))
/// ```
class ApplianceMenu extends StatelessWidget {
  /// A menu of [entries] opened from [builder]'s key.
  const ApplianceMenu({
    super.key,
    required this.entries,
    required this.builder,
    this.semanticLabel,
    this.style,
  });

  /// The rows.
  final List<RawMenuEntry> entries;

  /// Builds the key that opens it; `anchor.toggle` opens and closes it.
  final Widget Function(BuildContext context, DesignOverlayAnchor anchor)
  builder;

  /// Its name for a screen reader.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.menuStyle]: fill, foreground, textStyle (the rows).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    arrowKeyNavigation: true,
    semanticLabel: semanticLabel,
    placement: const RawPopoverPlacement(
      gap: ApplianceSpacing.tight + 2,
      margin: ApplianceSpacing.small,
      matchAnchorWidth: false,
      maxWidth: 320,
    ),
    dampingRatio: ApplianceMotion.lid.dampingRatio,
    stiffness: ApplianceMotion.lid.stiffness,
    anchorBuilder: builder,
    overlayBuilder: (context, info) =>
        _MenuRows(entries: entries, info: info, style: style),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('entries', entries.length));
  }
}

/// A context menu: [child], whose menu of [entries] opens at the pointer on
/// a secondary click or a long press (with its haptic), and at the focused
/// widget on Shift+F10 or the menu key. The rows are a menu bar's (a
/// submenu's chevron, a shortcut's key caps, a check's lamp); a screen
/// reader finds "Show menu" among [child]'s actions. On the web the
/// browser's own menu stays shut over [child].
///
/// ```dart
/// ApplianceContextMenu(entries: [RawMenuEntry(label: 'Remove', onPressed: () {})], child: const Text('Kettle'))
/// ```
class ApplianceContextMenu extends StatelessWidget {
  /// [child] with a context menu of [entries].
  const ApplianceContextMenu({
    super.key,
    required this.entries,
    required this.child,
    this.semanticLabel,
    this.style,
  });

  /// The rows.
  final List<RawMenuEntry> entries;

  /// What it is the menu of.
  final Widget child;

  /// The menu's name for a screen reader.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.menuStyle]: fill, foreground, textStyle (the rows).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => RawContextMenu(
    menuChildren: entries,
    semanticLabel: semanticLabel,
    dampingRatio: ApplianceMotion.lid.dampingRatio,
    stiffness: ApplianceMotion.lid.stiffness,
    itemBuilder: (context, entry, level, states) =>
        applianceMenuEntryRow(context, entry, states, style: style),
    surfaceBuilder: (context, info, items) =>
        applianceMenuPanel(info, items, minWidth: 200),
    dividerBuilder: applianceMenuSeam,
    // The whole child is its target (a row's bezel inset too), and the
    // pointer says a menu is there.
    child: MouseRegion(
      cursor: SystemMouseCursors.contextMenu,
      hitTestBehavior: HitTestBehavior.opaque,
      child: child,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('entries', entries.length));
  }
}

/// What an [ApplianceBanner] reports.
enum ApplianceBannerTone {
  /// Something to know: the signal's lamp.
  info,

  /// All done: the ready lamp.
  ready,

  /// Something wrong: the danger lamp, its strip edged red.
  danger,
}

/// A banner: a strip sunk across the page with its lamp lit, a heading,
/// what it is about, a key to act on it and a key to close it.
///
/// ```dart
/// ApplianceBanner(title: 'Card expiring', message: 'Your card on file runs out this month.', action: ApplianceButton.text('Update', onPressed: () {}))
/// ```
class ApplianceBanner extends StatelessWidget {
  /// A banner headed [title].
  const ApplianceBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = ApplianceBannerTone.info,
    this.action,
    this.onClose,
    this.closeLabel = 'Dismiss',
    this.style,
  });

  /// The heading.
  final String title;

  /// What it is about.
  final String? message;

  /// What it reports.
  final ApplianceBannerTone tone;

  /// A key to act on it.
  final Widget? action;

  /// Closes it; null: no close key.
  final VoidCallback? onClose;

  /// The close key's name for a screen reader.
  final String closeLabel;

  /// Its style, over [ApplianceThemeData.bannerStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layered = DesignStyleOf([style, theme.bannerStyle], const {});
    final lamp = switch (tone) {
      ApplianceBannerTone.info => c.signal,
      ApplianceBannerTone.ready => c.ready,
      ApplianceBannerTone.danger => c.danger,
    };
    final close = onClose;
    const keyInset = ApplianceSpacing.small;
    final verticalInset = close == null ? ApplianceSpacing.medium : keyInset;
    final singleLine = close != null && message == null && action == null;
    return Semantics(
      container: true,
      liveRegion: tone == ApplianceBannerTone.danger,
      child: ApplianceSurface(
        face: layered.on(
          ApplianceFace.well(
            c,
            radius: ApplianceMetrics.troughRadius,
            fill: c.trough,
          ).copyWith(
            edge: tone == ApplianceBannerTone.danger ? c.danger : null,
          ),
        ),
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              EdgeInsetsDirectional.fromSTEB(
                ApplianceSpacing.regular,
                verticalInset,
                keyInset,
                verticalInset,
              ),
          child: Row(
            crossAxisAlignment: singleLine
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: singleLine ? 0 : ApplianceSpacing.tight,
                ),
                child: ApplianceLamp(lit: true, color: lamp, size: 10),
              ),
              const SizedBox(width: ApplianceSpacing.medium),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: layered.text(
                        t.body.copyWith(
                          color: c.print,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (message != null)
                      Text(
                        message!,
                        style: t.secondary.copyWith(color: c.printMuted),
                      ),
                    if (action != null) ...[
                      const SizedBox(height: ApplianceSpacing.small),
                      action!,
                    ],
                  ],
                ),
              ),
              if (close != null)
                RawButton(
                  onPressed: close,
                  semanticLabel: closeLabel,
                  excludeSemantics: true,
                  builder: (context, states, _) {
                    final pressed = states.contains(WidgetState.pressed);
                    return AnimatedApplianceSurface(
                      face: ApplianceFace(
                        top: pressed
                            ? c.keyDownTop
                            : c.keyDownTop.withValues(alpha: 0),
                        bottom: pressed
                            ? c.keyDownBottom
                            : c.keyDownBottom.withValues(alpha: 0),
                        radius: BorderRadius.circular(
                          ApplianceMetrics.troughRadius - keyInset,
                        ),
                        lift: pressed ? -.6 : 0,
                        focus: states.contains(WidgetState.focused)
                            ? c.focus
                            : c.focus.withValues(alpha: 0),
                      ),
                      child: TapTargetPadding(
                        child: SizedBox.square(
                          dimension: 32,
                          child: Center(
                            child: IconTheme(
                              data: IconThemeData(
                                size: 16,
                                color: states.contains(WidgetState.pressed)
                                    ? c.print
                                    : c.printMuted,
                              ),
                              child: const ApplianceGlyph(
                                ApplianceCrossPainter.new,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty<ApplianceBannerTone>('tone', tone));
  }
}
