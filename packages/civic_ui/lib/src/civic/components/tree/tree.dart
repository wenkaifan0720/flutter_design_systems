import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

// A tree's caller builds its controller and reads what is open and
// selected.
export 'package:ui_core/ui_core.dart' show RawTreeController;

/// Nested things a reader opens level by level (a service's sections, a
/// council's departments): [controller]'s open rows, at least 48 tall,
/// each level indented 24, a chevron before a row with rows under it that
/// turns as it opens, a glyph from [iconOf] when it has one, then its
/// words.
///
/// The selected row stands on the pale action wash with the action
/// colour's bar at its start and its words bold. A pointer greys a row; a
/// press greys it further; a keyboard focus lays the row on the yellow
/// plate over the ink bar. The tree is one tab stop: Up and Down move,
/// Right opens or steps in, Left shuts or steps out (mirrored right to
/// left), Home and End go to the ends, Enter follows a row, Space selects
/// it. A screen reader hears each row's level, place and whether it is
/// open. ui_core's [RawTree], Civic's painting.
///
/// Reads [CivicStyle]'s fill (a row, by state: selected for the selected
/// one), foreground and textStyle (its words): its `style:`, then
/// [CivicThemeData.treeStyle].
///
/// ```dart
/// CivicTree<String>(
///   controller: services,
///   labelOf: (s) => s,
///   onActivate: (s) => openService(s),
/// )
/// ```
class CivicTree<T extends Object> extends StatelessWidget {
  /// A tree view of [controller].
  const CivicTree({
    super.key,
    required this.controller,
    required this.labelOf,
    this.iconOf,
    this.onActivate,
    this.semanticLabel,
    this.style,
  });

  /// The nodes, and which are open and selected; the caller's, who keeps
  /// and disposes it.
  final RawTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A node's glyph; null, or null for a node: none.
  final IconData? Function(T node)? iconOf;

  /// A press on a row with nothing under it, or its Enter.
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls the tree.
  final String? semanticLabel;

  /// Overrides for this tree's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RawTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: semanticLabel,
      rowBuilder: (context, item) {
        final states = {
          ...item.states,
          if (item.selected) WidgetState.selected,
        };
        final so = RawStyleOf([style, t.treeStyle], states);
        final wash = states.contains(WidgetState.pressed)
            ? 1.0
            : states.contains(WidgetState.hovered)
            ? 0.5
            : 0.0;
        final glyph = iconOf?.call(item.row.node);
        return CivicSpringValue(
          value: item.selected ? 1 : 0,
          spring: CivicMotion.state,
          builder: (context, sel, _) => CivicSpringValue(
            value: wash,
            spring: CivicMotion.press,
            builder: (context, w, _) => CivicSpringValue(
              value: states.contains(WidgetState.focused) ? 1 : 0,
              spring: CivicMotion.focus,
              effects: true,
              builder: (context, focus, _) {
                final rest =
                    so.fill ??
                    Color.lerp(
                      t.background,
                      t.action.withValues(alpha: 0.12),
                      sel,
                    )!;
                final face = Color.lerp(
                  Color.alphaBlend(
                    t.textPrimary.withValues(alpha: 0.06 * w),
                    Color.alphaBlend(rest, t.background),
                  ),
                  t.focus,
                  focus,
                )!;
                final ink = Color.lerp(
                  so.foreground ?? t.textPrimary,
                  t.onFocus,
                  focus,
                )!;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: face,
                    border: Border(
                      bottom: BorderSide(
                        color: t.focusBar.withValues(alpha: focus),
                        width: CivicMetrics.bar,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // The selected row's bar at its start.
                      SizedBox(
                        width: CivicMetrics.bar,
                        height: CivicMetrics.controlHeight - CivicMetrics.bar,
                        child: ColoredBox(
                          color: t.action.withValues(alpha: sel * (1 - focus)),
                        ),
                      ),
                      SizedBox(width: CivicSpacing.s8 + 24.0 * item.row.depth),
                      SizedBox(
                        width: 24,
                        child: item.hasChildren
                            ? CivicSpringValue(
                                value: item.expanded ? 1 : 0,
                                spring: CivicMotion.state,
                                builder: (context, turn, _) => Transform.rotate(
                                  angle:
                                      (rtl ? -1 : 1) * (turn - 1) * math.pi / 2,
                                  child: Icon(
                                    LucideIcons.chevronDown,
                                    size: 20,
                                    color: ink,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: CivicSpacing.s4),
                      if (glyph != null) ...[
                        Icon(glyph, size: 20, color: ink),
                        const SizedBox(width: CivicSpacing.s8),
                      ],
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: CivicSpacing.s12,
                          ),
                          child: Text(
                            labelOf(item.row.node),
                            // Selected, the words go bold at the body's
                            // size and line, so the row keeps its height.
                            style: text.body
                                .copyWith(
                                  fontWeight: item.selected
                                      ? text.label.fontWeight
                                      : null,
                                )
                                .merge(so.textStyle)
                                .copyWith(color: ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: CivicSpacing.s16),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawTreeController<T>>('controller', controller))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
