/// A titled row that opens to show more: a disclosure, an accordion's item.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';
import 'reveal.dart';

/// A row that opens to show what is under it — an FAQ's answer, advanced
/// settings, a group of details: the [title] (and a quiet [subtitle]) with
/// a chevron at the end that turns as it opens, then [child] growing into
/// place under it in [MinimalMotion.base]. Like every Minimal row it draws
/// its own bottom rule, so a column of them is an accordion.
///
/// It keeps its own open state from [initiallyExpanded]; pass [expanded]
/// and [onExpansionChanged] to hold it in the page instead (an accordion that
/// closes the others). The whole row is the control, a full-bleed one: its
/// press wash fills it and its focus ring runs inside its edge. A screen
/// reader hears the title and whether it is expanded.
///
/// ```dart
/// MinimalDisclosure(title: 'Advanced', child: Text('Webhooks, API keys and audit logs.'))
/// ```
class MinimalDisclosure extends StatefulWidget {
  /// A row titled [title] that opens [child] under it.
  const MinimalDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    this.padding = const EdgeInsets.only(bottom: MinimalSpacing.s12),
    this.focusNode,
    this.autofocus = false,
  });

  /// What it holds.
  final String title;

  /// A line under the title.
  final String? subtitle;

  /// A glyph before the title.
  final IconData? icon;

  /// What opens under the row.
  final Widget child;

  /// Open on first build, when the page does not hold the state.
  final bool initiallyExpanded;

  /// The open state, when the page holds it.
  final bool? expanded;

  /// Told when the row is pressed: the state to move to.
  final ValueChanged<bool>? onExpansionChanged;

  /// The air around [child] under the row.
  final EdgeInsetsGeometry padding;

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  State<MinimalDisclosure> createState() => _MinimalDisclosureState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(
        FlagProperty(
          'initiallyExpanded',
          value: initiallyExpanded,
          ifTrue: 'initiallyExpanded',
        ),
      )
      ..add(DiagnosticsProperty<bool>('expanded', expanded, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onExpansionChanged',
          onExpansionChanged,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: const EdgeInsets.only(bottom: MinimalSpacing.s12),
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _MinimalDisclosureState extends State<MinimalDisclosure> {
  late bool _open = widget.initiallyExpanded;

  bool get _expanded => widget.expanded ?? _open;

  void _toggle() {
    final next = !_expanded;
    if (widget.expanded == null) setState(() => _open = next);
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final open = _expanded;
    final duration = context.minimalStill ? Duration.zero : MinimalMotion.base;
    final subtitle = widget.subtitle;
    final leading = widget.icon;
    final l = MinimalLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MinimalPressable(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onPressed: _toggle,
            radius: 0,
            semanticLabel:
                '${widget.title}, ${l.expandedState(expanded: open)}',
            child: ExcludeSemantics(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: t.rowHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: MinimalSpacing.s8,
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        MinimalIcon(leading, size: MinimalIconSize.i16),
                        const MinimalGap(MinimalSpacing.s8 + 2),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: t.body.medium.c(t.foreground),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                style: t.bodySmall.c(t.mutedForeground),
                              ),
                          ],
                        ),
                      ),
                      const MinimalGap(MinimalSpacing.s8),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: duration,
                        curve: MinimalMotion.out,
                        child: const MinimalIcon(
                          LucideIcons.chevronDown,
                          size: MinimalIconSize.i16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          MinimalReveal(
            visible: open,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ],
      ),
    );
  }
}
