import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/keys.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';

/// One act of a [FrostedButtonGroup]: its [label] (spoken, and printed
/// unless it has only an [icon]), what a press does, and whether it is
/// [selected] (a group that toggles a view).
class FrostedButtonGroupItem {
  /// An act named [label].
  const FrostedButtonGroupItem({
    required this.label,
    this.icon,
    this.onPressed,
    this.selected,
    this.showLabel = true,
    this.key,
  });

  /// The act's words.
  final String label;

  /// Its glyph, before the words.
  final IconData? icon;

  /// What a press does; null makes this act inert.
  final VoidCallback? onPressed;

  /// Whether it stands chosen; null for a plain act.
  final bool? selected;

  /// Whether the words are printed (an icon-only act keeps them spoken).
  final bool showLabel;

  /// A key for its target.
  final Key? key;
}

/// Acts that belong together on one glass capsule (a toolbar's undo and
/// redo, a zoom out and in, bold, italic and underline): the brighter
/// glass with its rim of light and hairline edge round all of them, a
/// hairline between each two, each act its glyph and word in the ink, 44
/// tall, the chosen one on the wash. Each act is its own target; Tab moves
/// between them.
///
/// ```dart
/// FrostedButtonGroup(items: [FrostedButtonGroupItem(label: 'Undo', icon: FrostedGlyphs.back, showLabel: false, onPressed: undo), FrostedButtonGroupItem(label: 'Redo', icon: FrostedGlyphs.forward, showLabel: false, onPressed: redo)])
/// ```
class FrostedButtonGroup extends StatelessWidget {
  /// A group of [items].
  const FrostedButtonGroup({required this.items, this.label, super.key});

  /// The acts, start to end.
  final List<FrostedButtonGroupItem> items;

  /// What a screen reader calls the group.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const h = FrostedChromeMetrics.buttonHeight;
    final rule = ColoredBox(color: t.colorScheme.border);
    final children = <Widget>[];
    for (final (i, item) in items.indexed) {
      if (i > 0) {
        children.add(
          SizedBox(width: FrostedStrokes.hairline, height: h * .5, child: rule),
        );
      }
      final enabled = item.onPressed != null;
      final ink = t.colorScheme.textPrimary;
      Widget face = Container(
        height: h,
        constraints: const BoxConstraints(minWidth: h),
        padding: EdgeInsets.symmetric(
          horizontal: item.showLabel ? FrostedSpacing.s14 : FrostedSpacing.s10,
        ),
        decoration: item.selected == true
            ? ShapeDecoration(shape: FrostedCorners.full, color: t.glass.wash)
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: FrostedSpacing.s6,
          children: [
            if (item.icon case final icon?)
              Icon(icon, size: FrostedChromeMetrics.buttonGlyph, color: ink),
            if (item.showLabel || item.icon == null)
              Text(
                item.label,
                maxLines: 1,
                style: t.textTheme.labelLarge.c(ink),
              ),
          ],
        ),
      );
      face = FrostedDim(off: !enabled, child: face);
      children.add(
        FrostedPressable(
          key: item.key,
          onPressed: item.onPressed,
          label: item.label,
          selected: item.selected,
          radius: h / 2,
          child: face,
        ),
      );
    }
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: FocusTraversalGroup(
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(h / 2),
          color: t.glass.fillHigh,
          edge: t.glass.edge,
          sheen: t.glass.rim,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A key of the keyboard, as a shortcut names it (⌘, K, Esc): a keycap of
/// the brighter glass in its hairline (no foot: light falls from above), the
/// key's [label] in the small mono type. [FrostedKbd.combo] sets several
/// keys pressed together with a quiet plus between. Read aloud as its
/// words ([semanticsLabel] for a glyph: "Command").
///
/// ```dart
/// FrostedKbd('Esc')
/// ```
///
/// ```dart
/// FrostedKbd.combo(['⌘', 'K'], semanticsLabel: 'Command K')
/// ```
class FrostedKbd extends StatelessWidget {
  /// One key.
  const FrostedKbd(String label, {this.semanticsLabel, super.key})
    : keys = const [],
      _label = label;

  /// Keys pressed together.
  const FrostedKbd.combo(this.keys, {this.semanticsLabel, super.key})
    : _label = null;

  final String? _label;

  /// The keys of a combination, in the order they are held.
  final List<String> keys;

  /// What a screen reader says; null says the keys.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Directionality(
    // Figures, codes and marks read left to right in any language.
    textDirection: TextDirection.ltr,
    child: Builder(builder: _ltrBuild),
  );

  Widget _ltrBuild(BuildContext context) {
    final t = context.frostedTheme;
    Widget cap(String key) {
      final r = FrostedCorners.r10;
      return Container(
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: t.glass.fillHigh,
          borderRadius: BorderRadius.circular(r.clamp(4, 8)),
          border: Border.all(
            color: t.glass.edge,
            width: FrostedStrokes.hairline,
          ),
        ),
        // As wide as its key: a lone keycap in a wrap or a column is
        // offered the whole width, and an aligned box would take it.
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: FrostedKeys(
            key,
            style: t.textTheme.monoSmall.c(t.colorScheme.textPrimary),
          ),
        ),
      );
    }

    final label = _label;
    final words = [
      for (final key in label == null ? keys : [label]) frostedKeysSpoken(key),
    ].join(' ');
    return Semantics(
      label: semanticsLabel ?? words,
      excludeSemantics: true,
      child: label != null
          ? cap(label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedSpacing.s4,
              children: [
                for (final (i, k) in keys.indexed) ...[
                  if (i > 0)
                    Text(
                      '+',
                      style: t.textTheme.monoSmall.c(
                        t.colorScheme.textTertiary,
                      ),
                    ),
                  cap(k),
                ],
              ],
            ),
    );
  }
}
