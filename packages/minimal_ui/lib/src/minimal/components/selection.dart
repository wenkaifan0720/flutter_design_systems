/// Single-choice rows and the hairline group that holds them.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../internal/cap_label.dart';
import '../internal/field.dart';
import '../theme.dart';
import 'pressable.dart';

/// One option of a single choice: a 44 px hairline row — an optional
/// leading glyph or mark, the title (and a quiet subtitle), and the accent
/// check at the end when it is the choice. The row draws its own bottom
/// rule, like every Minimal row; stack them in a [MinimalSelectionGroup].
/// A null [onPressed] disables the option.
///
/// It announces itself as one of a mutually exclusive set, checked or not.
/// It draws its own rule: stand it in a [MinimalSelectionGroup], never in a
/// `MinimalListSection`.
///
/// ```dart
/// MinimalChoiceRow(title: 'Every day', selected: repeat == 'daily', onPressed: () => setRepeat('daily'))
/// ```
class MinimalChoiceRow extends StatelessWidget {
  /// A row that can be chosen.
  const MinimalChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    this.subtitle,
    this.leading,
    this.content,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it is.
  final String title;

  /// A line under the title.
  final String? subtitle;

  /// Whether it is chosen.
  final bool selected;

  /// A glyph, a swatch or an avatar before the title.
  final Widget? leading;

  /// Replaces the title and subtitle with richer content; the row keeps its
  /// padding, its check and its hit target, and [title] stays what a
  /// screen reader hears.
  final Widget? content;

  /// Chooses it; null disables it.
  final VoidCallback? onPressed;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final subtitle = this.subtitle;
    final leading = this.leading;
    final content = this.content;
    final inset =
        context.dependOnInheritedWidgetOfExactType<_ChoiceInset>()?.padding ??
        EdgeInsets.zero;
    // Painted over the row's foot, so the row's words and check are centred
    // on the whole row. Outside the press, so a disabled row dims its words
    // and keeps its rule as strong as its neighbours'.
    return Container(
      foregroundDecoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: MinimalPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        enabled: onPressed != null,
        radius: 0,
        outset: MinimalFieldMetrics.rowReach,
        child: Semantics(
          checked: selected,
          inMutuallyExclusiveGroup: true,
          label: content == null ? null : title,
          child: Container(
            constraints: BoxConstraints(minHeight: t.rowHeight),
            padding: inset.add(
              const EdgeInsets.symmetric(vertical: MinimalSpacing.s8),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const MinimalGap(MinimalFieldMetrics.rowIconGap),
                ],
                Expanded(
                  child:
                      content ??
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          minimalCapLabel(
                            Text(
                              title,
                              style: selected ? t.body.medium : t.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (subtitle != null)
                            Text(subtitle, style: t.caption, maxLines: 2),
                        ],
                      ),
                ),
                const MinimalGap(MinimalSpacing.s12),
                SizedBox(
                  width: MinimalIconSize.i18,
                  child: selected
                      ? MinimalIcon(LucideIcons.check, color: t.primaryInk)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single choice set out as hairline rows: a rule over the first
/// [MinimalChoiceRow], each row's own rule under it, no card and no inset of
/// its own (the page's gutter is the inset). Where the group runs edge to
/// edge (a phone page's lists do), [padding] insets the rows' words and
/// checks while the rules still span the screen. The arrow keys walk the
/// options. Keep the chosen value in page state and wire every available
/// option to update it.
///
/// ```dart
/// MinimalSelectionGroup(children: [MinimalChoiceRow(title: 'Morning', selected: part == 'am', onPressed: () => setPart('am'))])
/// ```
class MinimalSelectionGroup extends StatelessWidget {
  /// A group of choice rows.
  const MinimalSelectionGroup({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  /// The rows.
  final List<Widget> children;

  /// The side padding of every row's words and check; the rules run the
  /// group's whole width. None by default: pass the screen's gutter when the
  /// group runs edge to edge.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      },
      child: FocusTraversalGroup(
        child: Container(
          decoration: BoxDecoration(border: Border(top: t.rule)),
          child: _ChoiceInset(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// The side padding a [MinimalSelectionGroup] hands its rows.
class _ChoiceInset extends InheritedWidget {
  const _ChoiceInset({required this.padding, required super.child});

  final EdgeInsetsGeometry padding;

  @override
  bool updateShouldNotify(_ChoiceInset old) => padding != old.padding;
}
