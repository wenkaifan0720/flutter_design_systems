/// How Appliance paints a menu's rows, its plate and its seams: one
/// painting for a menu bar's menus and a context menu, both ui_core's
/// (RawMenuBar, RawContextMenu), so the two read as one menu.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../actions.dart';
import '../lists.dart';
import '../menus.dart';
import '../select.dart';
import '../theme.dart';

/// A row of a menu ([RawMenuLevel.menu]) for [states]: a submenu's
/// chevron or a command's shortcut in key caps at its end, a check's lamp.
Widget applianceMenuEntryRow(
  BuildContext context,
  RawMenuEntry entry,
  Set<WidgetState> states, {
  ApplianceStyle? style,
}) {
  final c = ApplianceTheme.of(context).colors;
  return ApplianceMenuRow(
    style: style,
    label: entry.label,
    states: states,
    enabled: entry.enabled,
    chosen: entry.checked,
    destructive: entry.isDestructiveAction,
    trailing: entry.isSubmenu
        ? MenuChevron(color: c.printMuted)
        : entry.shortcut == null
        ? null
        : MenuShortcut(entry.shortcut!),
  );
}

/// A menu's plate round its [items], rising from its anchor on [info]'s
/// animation; at least [minWidth] wide, its rows scrolling when the room
/// ([RawPopoverInfo.maxSize]) is short.
Widget applianceMenuPanel(
  RawPopoverInfo info,
  List<Widget> items, {
  double minWidth = 220,
}) => ApplianceMenuReveal(
  animation: info.animation,
  below: info.side != RawPopoverSide.above,
  child: ConstrainedBox(
    constraints: BoxConstraints(minWidth: minWidth),
    child: ApplianceMenuPlate(
      maxHeight: info.maxSize.height,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        ),
      ),
    ),
  ),
);

/// The parting line between a menu's groups.
Widget applianceMenuSeam(BuildContext context) => Container(
  height: ApplianceSpacing.hair,
  margin: const EdgeInsets.symmetric(
    vertical: ApplianceSpacing.tight,
    horizontal: ApplianceSpacing.small,
  ),
  color: ApplianceTheme.of(context).colors.seamShade,
);

/// A submenu's chevron, pointing to the reading end.
class MenuChevron extends StatelessWidget {
  /// A chevron in [color].
  const MenuChevron({super.key, required this.color});

  /// Its ink.
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.flip(
    flipX: Directionality.of(context) == TextDirection.rtl,
    child: CustomPaint(
      size: const Size.square(16),
      painter: ApplianceChevronPainter(color),
    ),
  );
}

/// A shortcut's keys as small caps ("Ctrl+P": two caps; "⇧⌘N", Apple's
/// way with no separator: three).
class MenuShortcut extends StatelessWidget {
  /// The caps of [keys].
  const MenuShortcut(this.keys, {super.key});

  /// The shortcut's label, as `designShortcutLabel` writes it.
  final String keys;

  /// [keys] cut into its caps: at each `+` between two keys; with none, at
  /// each of Apple's modifier symbols, the key after them one cap.
  static List<String> capsOf(String keys) {
    if (keys.length > 1 && keys.contains('+')) {
      final parts = <String>[];
      var start = 0;
      // A `+` that is a key itself ("Ctrl++") stays a cap.
      for (var i = 1; i < keys.length; i++) {
        if (keys[i] == '+' && i > start) {
          parts.add(keys.substring(start, i));
          start = i + 1;
        }
      }
      if (start < keys.length) parts.add(keys.substring(start));
      return parts;
    }
    const apple = {'⌃', '⌥', '⇧', '⌘'};
    final runes = keys.runes.map(String.fromCharCode).toList();
    final mods = runes.takeWhile(apple.contains).toList();
    if (mods.isEmpty) return [keys];
    final rest = runes.skip(mods.length).join();
    return [...mods, if (rest.isNotEmpty) rest];
  }

  @override
  Widget build(BuildContext context) {
    final caps = capsOf(keys);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, k) in caps.indexed) ...[
          if (i > 0) const SizedBox(width: ApplianceSpacing.nudge),
          ApplianceKbd(k),
        ],
      ],
    );
  }
}
