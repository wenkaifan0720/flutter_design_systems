// Overlays on ui_core's behaviours: the popover and hover card, the side sheet, the command palette, the menu bar and
// the toaster. ui_core owns focus, keys, semantics and timing; every pixel here is the look's: the raised panel, the
// row pressed in, the keyboard's ring.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'controls.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'internal/panel.dart';
import 'internal/veil.dart';
import 'localizations.dart';
import 'ornaments.dart';
import 'raised.dart';
import 'theme.dart';
import 'internal/cap_label.dart';

/// Words or a small form on a raised panel beside its trigger, opened and closed by a press on it. Escape, a press
/// outside and Tab out close it, and focus goes back to the trigger.
///
/// ```dart
/// NeumorphicPopover(label: 'Opening hours', trigger: (context, toggle) => NeumorphicButton('Hours', onPressed: toggle), content: const Text('Nine to six'))
/// ```
class NeumorphicPopover extends StatelessWidget {
  /// A popover called [label].
  const NeumorphicPopover({
    super.key,
    required this.label,
    required this.trigger,
    required this.content,
    this.side = DesignOverlaySide.below,
    this.align = DesignOverlayAlign.start,
    this.width = 288,
    this.style,
  });

  /// What a screen reader calls it.
  final String label;

  /// Builds the control that opens it; call `toggle` from its press.
  final Widget Function(BuildContext context, VoidCallback toggle) trigger;

  /// What the popover holds.
  final Widget content;

  /// The side of the trigger it opens on; it flips when there is no room.
  final DesignOverlaySide side;

  /// How it lines up with the trigger along that side.
  final DesignOverlayAlign align;

  /// Its width, clamped to the screen.
  final double width;

  /// The panel's own style, before the menu theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    semanticLabel: label,
    // Words or a small form keep their own width, whatever the trigger's: not a list opened from a field.
    placement: DesignOverlayPlacement(
      side: side,
      align: align,
      gap: 10,
      matchAnchorWidth: false,
    ),
    anchorBuilder: (context, anchor) => Semantics(
      expanded: anchor.isOpen,
      child: trigger(context, anchor.toggle),
    ),
    overlayBuilder: (context, info) => NeumorphicPanel(
      presence: info.animation,
      side: info.side,
      style: style,
      width: math.min(width, info.maxSize.width),
      maxHeight: info.maxSize.height,
      padding: const EdgeInsets.all(18),
      child: SingleChildScrollView(child: content),
    ),
  );
}

/// A preview on a raised panel while the pointer rests on [child] (or focus reaches it), gone when both leave: a
/// person's card over their name. Touch has no hover: give the same words a page of their own.
///
/// ```dart
/// NeumorphicHoverCard(child: NeumorphicLink('Marta', onPressed: openMarta), content: const Text('Host since 2019'))
/// ```
class NeumorphicHoverCard extends StatelessWidget {
  /// A preview, [content], over [child].
  const NeumorphicHoverCard({
    super.key,
    required this.child,
    required this.content,
    this.label,
    this.width = 300,
    this.openDelay = const Duration(milliseconds: 600),
    this.style,
  });

  /// What the pointer rests on.
  final Widget child;

  /// The preview.
  final Widget content;

  /// What a screen reader calls the preview.
  final String? label;

  /// Its width, clamped to the screen.
  final double width;

  /// How long the pointer rests before it shows.
  final Duration openDelay;

  /// The panel's own style, before the menu theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    trigger: DesignOverlayTrigger.hover,
    focusOnOpen: false,
    hoverOpenDelay: openDelay,
    semanticLabel: label,
    // A person's card keeps its own width over a long name.
    placement: const DesignOverlayPlacement(gap: 10, matchAnchorWidth: false),
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) => NeumorphicPanel(
      presence: info.animation,
      side: info.side,
      style: style,
      width: math.min(width, info.maxSize.width),
      maxHeight: info.maxSize.height,
      padding: const EdgeInsets.all(18),
      child: content,
    ),
  );
}

/// A panel standing on one side of the page for filters, details or a form beside the work: a heading with a close
/// action, the body scrolling under it, the actions at its foot. [showNeumorphicSheet] opens one on a route that traps
/// focus, closes on Escape, a press on the scrim or a drag toward its edge, and gives focus back.
///
/// ```dart
/// NeumorphicSheet(title: 'Filters', child: filters, actions: [NeumorphicButton.filled('Show 12 rooms', onPressed: apply)])
/// ```
class NeumorphicSheet extends StatelessWidget {
  /// A sheet headed [title].
  const NeumorphicSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.onClose,
    this.edge = DesignSheetEdge.end,
    this.style,
  });

  /// The heading, also what a screen reader calls the panel.
  final String title;

  /// The body; it scrolls when taller than the panel.
  final Widget child;

  /// The actions at the panel's foot.
  final List<Widget> actions;

  /// The close action; null leaves it out.
  final VoidCallback? onClose;

  /// The page side it stands on: only its inner corners are rounded.
  final DesignSheetEdge edge;

  /// The panel's own style, before the sheet theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: NeumorphicSurface(
        cast: NeumorphicSurfaceLevel.slab,
        style: style,
        themeStyle: t.sheetTheme,
        radius: NeumorphicRadii.slab,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                // The close key's face ends on the body's keyline, 24 in, as the title starts on it.
                padding: const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: neumorphicLabel(
                          Text(title, style: t.textTheme.title),
                        ),
                      ),
                    ),
                    if (onClose != null)
                      NeumorphicIconButton(
                        NeumorphicGlyphs.close,
                        label: words.close,
                        onPressed: onClose,
                      ),
                  ],
                ),
              ),
              const NeumorphicEngraved(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: child,
                ),
              ),
              if (actions.isNotEmpty) ...[
                const NeumorphicEngraved(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 12,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a [NeumorphicSheet] from [builder] on the page's [edge], [width] wide (never wider than leaves 56 of the page
/// showing). The builder gets the sheet's close; the future completes with the value it closes with.
///
/// ```dart
/// showNeumorphicSheet(context, builder: (context, close) => NeumorphicSheet(title: 'Filters', onClose: close, child: filters))
/// ```
Future<T?> showNeumorphicSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, VoidCallback close) builder,
  DesignSheetEdge edge = DesignSheetEdge.end,
  double width = 380,
  bool useRootNavigator = true,
}) {
  final t = NeumorphicTheme.of(context);
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    DesignSideSheetRoute<T>(
      edge: edge,
      width: width,
      barrierColor: neumorphicVeil(t.colors),
      barrierLabel: NeumorphicLocalizations.of(context).close,
      builder: (inner, sheet) =>
          NeumorphicTheme(data: t, child: builder(inner, sheet.close)),
    ),
  );
}

/// A command palette: a search field over every command the app has, filtered as one types, grouped, with their
/// shortcuts; arrows move the highlight, Enter runs it. [showNeumorphicCommand] opens one over the page.
///
/// ```dart
/// NeumorphicCommand(commands: [DesignCommand(label: 'New booking', group: 'Bookings', onPressed: book)])
/// ```
class NeumorphicCommand extends StatelessWidget {
  /// A palette of [commands].
  const NeumorphicCommand({
    super.key,
    required this.commands,
    this.onRun,
    this.hint,
    this.maxHeight = 360,
    this.autofocus = false,
    this.focusNode,
  });

  /// The search field's keyboard focus; its own when null.
  final FocusNode? focusNode;

  /// Every command, in the order they list before a search.
  final List<DesignCommand> commands;

  /// Called with the command run, after its own `onRun`.
  final ValueChanged<DesignCommand>? onRun;

  /// The field's placeholder; null: the localized Search.
  final String? hint;

  /// The tallest the result list grows before it scrolls.
  final double maxHeight;

  /// Whether its field takes focus once built. Inline on a page it waits to be reached, so false by default.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => _palette(
    commands: commands,
    onRun: onRun,
    hint: hint ?? NeumorphicLocalizations.of(context).search,
    // The list holds as many rows at any text size: at twice the text a 240 list showed a group's name with its
    // one command cut off under it.
    maxHeight:
        maxHeight *
        (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 2.0),
    autofocus: autofocus,
    focusNode: focusNode,
  );
}

DesignCommandPalette _palette({
  required List<DesignCommand> commands,
  required String hint,
  ValueChanged<DesignCommand>? onRun,
  double maxHeight = 360,
  bool autofocus = true,
  FocusNode? focusNode,
}) => DesignCommandPalette(
  commands: commands,
  onSelected: onRun,
  maxHeight: maxHeight,
  autofocus: autofocus,
  focusNode: focusNode,
  fieldBuilder: (context, field) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: NeumorphicTextField(
      controller: field.controller,
      focusNode: field.focusNode,
      hint: hint,
      autofocus: autofocus,
      onSubmitted: (_) => field.submit(),
      leading: Icon(
        NeumorphicGlyphs.search,
        size: 18,
        color: NeumorphicTheme.of(context).colors.inkTertiary,
      ),
    ),
  ),
  groupBuilder: (context, group) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 8, 4),
    child: Semantics(
      header: true,
      child: Text(group, style: NeumorphicTheme.of(context).textTheme.micro),
    ),
  ),
  emptyBuilder: (context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Text(
      NeumorphicLocalizations.of(context).noResults,
      textAlign: TextAlign.center,
      style: NeumorphicTheme.of(context).textTheme.caption,
    ),
  ),
  itemBuilder: (context, command, states) => NeumorphicPanelRow(
    label: command.label,
    states: {...states, if (!command.enabled) WidgetState.disabled},
    icon: command.data is IconData ? command.data! as IconData : null,
    trailing: command.shortcut,
  ),
);

/// Opens a [NeumorphicCommand] of [commands] on a raised panel over the page; Escape or a press outside closes it, and
/// focus goes back.
///
/// ```dart
/// showNeumorphicCommand(context, commands: commands)
/// ```
Future<void> showNeumorphicCommand(
  BuildContext context, {
  required List<DesignCommand> commands,
  String? hint,
}) {
  final t = NeumorphicTheme.of(context);
  final words = NeumorphicLocalizations.of(context);
  return showDesignCommandPalette(
    context: context,
    barrierColor: neumorphicVeil(t.colors),
    barrierLabel: words.close,
    palette: (run) =>
        _palette(commands: commands, onRun: run, hint: hint ?? words.search),
    surfaceBuilder: (context, palette) => NeumorphicTheme(
      data: t,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: NeumorphicPanel(child: palette),
      ),
    ),
  );
}

/// A desktop menu bar: titles in a row along a window's top, each opening its menu of commands, checks and submenus.
/// Arrows move along the bar and through menus, Escape closes, and a letter jumps. A title whose menu is open, or which
/// is held, is pressed in.
///
/// ```dart
/// NeumorphicMenuBar(menus: [DesignMenuEntry(label: 'File', children: [DesignMenuEntry(label: 'New', onPressed: create)])])
/// ```
class NeumorphicMenuBar extends StatelessWidget {
  /// A bar of [menus].
  const NeumorphicMenuBar({super.key, required this.menus, this.label});

  /// The bar's menus, each with its entries.
  final List<DesignMenuEntry> menus;

  /// What a screen reader calls the bar; null: the localized Menu.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final words = NeumorphicLocalizations.of(context);
    final shape = t.shapes.corner(NeumorphicRadii.control);
    return DesignMenuBar(
      menus: menus,
      semanticLabel: label ?? words.menu,
      barBuilder: (context, items) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        // A column too narrow for every menu runs them on to a second line.
        child: Wrap(children: items),
      ),
      dividerBuilder: (context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: NeumorphicEngraved(),
      ),
      surfaceBuilder: (context, info, items) => NeumorphicPanel(
        presence: info.animation,
        side: info.side,
        width: math.min(260, info.maxSize.width),
        maxHeight: info.maxSize.height,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          ),
        ),
      ),
      itemBuilder: (context, entry, level, states) {
        if (level == DesignMenuLevel.menu) {
          return NeumorphicPanelRow(
            label: entry.label,
            states: {...states, if (!entry.enabled) WidgetState.disabled},
            trailing: entry.shortcut,
            checked: entry.checked ?? false,
            submenu: entry.isSubmenu,
          );
        }
        final open = states.contains(WidgetState.selected);
        final sunk =
            entry.enabled && (open || states.contains(WidgetState.pressed));
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            widthFactor: 1,
            child: CustomPaint(
              painter: sunk
                  ? NeumorphicPanelRowRelief(c, t.elevation, null, shape)
                  : null,
              foregroundPainter: states.contains(WidgetState.focused)
                  ? neumorphicFocusLift(t, shape)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: neumorphicLabel(
                  Text(
                    entry.label,
                    style: t.textTheme.body.copyWith(
                      color: entry.enabled ? c.ink : c.inkTertiary,
                      fontWeight: open ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The place transient messages queue in, above the whole app: up to three snack bars stacked at the foot, the newest
/// nearest, each with its time running out as a thin line of the pigment, held while pointed at or focused; F6 reaches
/// them from anywhere. [NeumorphicHost] installs one, so an app on the look has it; [showNeumorphicToast] and
/// [showNeumorphicSnackBar] queue into it from anywhere below.
///
/// ```dart
/// NeumorphicToaster(child: child)
/// ```
class NeumorphicToaster extends StatelessWidget {
  /// A toaster over [child].
  const NeumorphicToaster({
    super.key,
    required this.child,
    this.maxVisible = 3,
  });

  /// The app.
  final Widget child;

  /// How many show at once; the rest wait their turn.
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    return DesignToaster(
      maxVisible: maxVisible,
      regionLabel: NeumorphicLocalizations.of(context).notifications,
      constraints: const BoxConstraints(maxWidth: 520),
      toastBuilder: (context, v) => FadeTransition(
        // The spring can pass 1; the slide may overshoot, the fade can't.
        opacity: v.animation.drive(
          Animatable<double>.fromCallback((x) => x.clamp(0.0, 1.0)),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .35),
            end: Offset.zero,
          ).animate(v.animation),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Stack(
              children: [
                NeumorphicSnackBar(
                  v.toast.message,
                  title: v.toast.title,
                  tone: v.toast.data is NeumorphicTone
                      ? v.toast.data! as NeumorphicTone
                      : NeumorphicTone.info,
                  actionLabel: v.toast.actionLabel,
                  onAction: v.toast.actionLabel == null ? null : v.runAction,
                  onDismiss: v.dismiss,
                  live: false,
                ),
                // The time left: a line along the foot that shortens, and holds while the toast is paused.
                PositionedDirectional(
                  start: 18,
                  end: 18,
                  bottom: 6,
                  child: ValueListenableBuilder<double>(
                    valueListenable: v.remaining,
                    builder: (context, left, _) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: left.clamp(0.0, 1.0),
                        child: SizedBox(
                          height: 2,
                          child: ColoredBox(
                            color: c.pigment.withValues(
                              alpha: v.paused ? .4 : .8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Queues a snack bar in the [NeumorphicToaster] above [context]: [message] with an optional [title], one action, and
/// the [tone]'s mark. Returns its handle (`dismiss()`, `closed`).
///
/// ```dart
/// showNeumorphicToast(context, message: 'Table held', actionLabel: 'Undo', onAction: release)
/// ```
DesignToastHandle showNeumorphicToast(
  BuildContext context, {
  required String message,
  String? title,
  NeumorphicTone tone = NeumorphicTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 5),
}) => DesignToaster.of(context).show(
  DesignToast(
    message: message,
    title: title,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
    data: tone,
  ),
);
