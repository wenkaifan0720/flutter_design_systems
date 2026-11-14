import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../menu/menu.dart';

import 'package:ui_core/ui_core.dart';

/// A toolbar's size, Fluent's `size`, which sets its room alone (Fluent's
/// ToolbarButton is a medium button, 32, at every size): [small] 4 at its
/// sides and none over and under; [medium] 4 over and under and 8 at its
/// sides (the default); [large] 4 over and under and 20 at its sides.
enum Fluent2ToolbarSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,
}

enum _ToolbarKind { button, toggle, divider }

/// One part of a [Fluent2Toolbar]: a command ([Fluent2ToolbarItem.button]),
/// an on/off command ([Fluent2ToolbarItem.toggle]) or Fluent's
/// `ToolbarDivider` between groups ([Fluent2ToolbarItem.divider]). A
/// command is its glyph alone (named by its label for a screen reader) or,
/// with [showLabel], its glyph and its words.
///
/// ```dart
/// Fluent2ToolbarItem.button(icon: Fluent2Icons.share, label: 'Share', onPressed: share)
/// ```
@immutable
class Fluent2ToolbarItem {
  /// A command: [icon], named by [label], doing [onTap].
  const Fluent2ToolbarItem.button({
    required IconData this.icon,
    required String this.label,
    required this.onPressed,
    this.showLabel = false,
  }) : _kind = _ToolbarKind.button,
       checked = false,
       onChanged = null,
       checkedIcon = null;

  /// An on/off command: [checked] wears [checkedIcon] on the subtle
  /// selected face; a press asks [onChanged] for the other state.
  const Fluent2ToolbarItem.toggle({
    required IconData this.icon,
    required String this.label,
    required this.checked,
    required this.onChanged,
    this.checkedIcon,
    this.showLabel = false,
  }) : _kind = _ToolbarKind.toggle,
       onPressed = null;

  /// The hairline between two groups of commands.
  const Fluent2ToolbarItem.divider()
    : _kind = _ToolbarKind.divider,
      icon = null,
      label = null,
      onPressed = null,
      checked = false,
      onChanged = null,
      checkedIcon = null,
      showLabel = false;

  final _ToolbarKind _kind;

  /// The item's glyph; null for a word-only item.
  final IconData? icon;

  /// The item's words, shown or read as its name.
  final String? label;

  /// Called when the item is pressed; null puts it out of use.
  final VoidCallback? onPressed;

  /// Whether a toggle item is on.
  final bool checked;

  /// Called with a toggle item's new state; null makes the item a plain button.
  final ValueChanged<bool>? onChanged;

  /// The glyph a toggle item shows while on; null keeps [icon].
  final IconData? checkedIcon;

  /// Draws the words after the glyph.
  final bool showLabel;

  bool get _isDivider => _kind == _ToolbarKind.divider;
}

/// Fluent 2's Toolbar: a row of subtle commands (icon buttons, toggles
/// that stay pressed, labelled buttons) in groups split by its dividers,
/// 4 over and under it and 8 at its sides. When the row runs out of room
/// its last commands fold into the more button at its end, which opens a
/// [Fluent2Menu] of them (a toggle a checkable item). [vertical] stacks it
/// in a column. 44 tall on a phone. Read as a toolbar of buttons.
///
/// ```dart
/// Fluent2Toolbar(items: [Fluent2ToolbarItem.button(icon: Fluent2Icons.add, label: 'New', onPressed: create), const Fluent2ToolbarItem.divider(), Fluent2ToolbarItem.button(icon: Fluent2Icons.share, label: 'Share', onPressed: share)])
/// ```
class Fluent2Toolbar extends StatelessWidget {
  /// A toolbar of [items].
  const Fluent2Toolbar({
    required this.items,
    this.size = Fluent2ToolbarSize.medium,
    this.vertical = false,
    this.label,
    super.key,
  });

  /// The toolbar's buttons, toggles and dividers, in order.
  final List<Fluent2ToolbarItem> items;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2ToolbarSize size;

  /// Whether the items stand one under another.
  final bool vertical;

  /// What a screen reader calls the toolbar; null is "Toolbar" in the app's
  /// language.
  final String? label;

  Fluent2ButtonSize get _buttonSize => Fluent2ButtonSize.medium;

  EdgeInsets _padding(bool wide, bool touch) {
    final side = switch (size) {
      Fluent2ToolbarSize.small => Fluent2Spacing.xs,
      Fluent2ToolbarSize.medium => Fluent2Spacing.s,
      Fluent2ToolbarSize.large => Fluent2Spacing.xl,
    };
    final m = Fluent2ButtonMetrics.of(_buttonSize);
    final base = size == Fluent2ToolbarSize.small ? 0.0 : Fluent2Spacing.xs;
    // A narrow toolbar is a touch row: its commands' 44 targets fit in it.
    // Under a finger the commands stand in their own 48 already.
    final over = wide || touch
        ? base
        : math.max(base, (Fluent2Layout.minHitTarget - m.height) / 2);
    return EdgeInsets.symmetric(horizontal: side, vertical: over);
  }

  /// The width [item] takes in the row at [scaler]; under a finger
  /// ([touch]) a command is at least its 48 target wide.
  double _widthOf(
    Fluent2ToolbarItem item,
    Fluent2ThemeData t,
    TextScaler scaler,
    TextDirection direction,
    bool touch,
  ) {
    final m = Fluent2ButtonMetrics.of(_buttonSize);
    final least = touch ? Fluent2Layout.touchHitTarget : 0.0;
    if (item._isDivider) return 25;
    if (!item.showLabel) return math.max(m.height, least);
    final painter = TextPainter(
      text: TextSpan(
        text: item.label,
        style: Fluent2ButtonMetrics.typeOf(t, _buttonSize),
      ),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = math.max(
      math.max(m.minWidth, least),
      painter.width + 2 * m.side + m.glyph + m.gap + 1,
    );
    painter.dispose();
    return w;
  }

  Widget _part(Fluent2ToolbarItem item) {
    if (item._isDivider) {
      return vertical
          ? const _ToolbarDivider(vertical: false)
          : const _ToolbarDivider(vertical: true);
    }
    final label = item.label!;
    final icon = item.icon!;
    if (item._kind == _ToolbarKind.toggle) {
      final change = item.onChanged;
      if (item.showLabel) {
        return Fluent2ToggleButton(
          label,
          value: item.checked,
          appearance: Fluent2ButtonAppearance.subtle,
          size: _buttonSize,
          icon: icon,
          checkedIcon: item.checkedIcon,
          onChanged: change,
        );
      }
      return Fluent2IconButton(
        icon,
        label: label,
        size: _buttonSize,
        selected: item.checked,
        filled: item.checkedIcon,
        onPressed: change == null ? null : () => change(!item.checked),
      );
    }
    if (item.showLabel) {
      return Fluent2Button(
        label,
        icon: icon,
        appearance: Fluent2ButtonAppearance.subtle,
        size: _buttonSize,
        onPressed: item.onPressed,
      );
    }
    return Fluent2IconButton(
      icon,
      label: label,
      size: _buttonSize,
      onPressed: item.onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final wide = Fluent2Layout.isWide(context);
    final touch = Fluent2Layout.padded(context);
    final padding = _padding(wide, touch);
    final label = this.label ?? Fluent2Localizations.of(context).toolbar;
    if (vertical) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: label,
        child: Padding(
          padding: EdgeInsets.all(padding.top),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final item in items) _part(item)],
          ),
        ),
      );
    }
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final room = box.maxWidth - padding.horizontal;
        final widths = [
          for (final item in items) _widthOf(item, t, scaler, direction, touch),
        ];
        var shown = items.length;
        if (room.isFinite &&
            widths.fold<double>(0, (s, w) => s + w) > room + 0.5) {
          final more = math.max(
            Fluent2ButtonMetrics.of(_buttonSize).height,
            touch ? Fluent2Layout.touchHitTarget : 0.0,
          );
          var used = more;
          shown = 0;
          for (final w in widths) {
            if (used + w > room) break;
            used += w;
            shown += 1;
          }
          // A divider never ends the row before the more button.
          while (shown > 0 && items[shown - 1]._isDivider) {
            shown -= 1;
          }
        }
        final folded = items.skip(shown).toList();
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: label,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items.take(shown)) _part(item),
                if (shown < items.length)
                  _More(items: folded, size: _buttonSize),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The more button a toolbar folds its last commands into.
class _More extends StatelessWidget {
  const _More({required this.items, required this.size});

  final List<Fluent2ToolbarItem> items;
  final Fluent2ButtonSize size;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (anchor) => Fluent2IconButton(
      Fluent2Icons.moreHorizontal,
      label: DesignLocalizations.of(anchor).moreButtonTooltip,
      size: size,
      onPressed: () async {
        final menu = <Fluent2MenuItem<int>>[];
        var divider = false;
        for (final (i, item) in items.indexed) {
          if (item._isDivider) {
            divider = menu.isNotEmpty;
            continue;
          }
          final toggle = item._kind == _ToolbarKind.toggle;
          menu.add(
            Fluent2MenuItem(
              i,
              item.label!,
              icon: item.icon,
              checked: toggle ? item.checked : null,
              divider: divider,
              enabled: toggle ? item.onChanged != null : item.onPressed != null,
            ),
          );
          divider = false;
        }
        final picked = await Fluent2Menu.show<int>(anchor, items: menu);
        if (picked == null) return;
        final item = items[picked];
        if (item._kind == _ToolbarKind.toggle) {
          item.onChanged?.call(!item.checked);
        } else {
          item.onPressed?.call();
        }
      },
    ),
  );
}

/// Fluent's `ToolbarDivider`: a vertical hairline in the default divider's
/// stroke with 12 either side (a horizontal one in a vertical toolbar).
class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final line = ColoredBox(color: fluent2Step(t, t.colors.neutralStroke2));
    return vertical
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: Fluent2Spacing.m),
            child: SizedBox(width: 1, height: 20, child: line),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.m),
            child: SizedBox(width: 20, height: 1, child: line),
          );
  }
}
