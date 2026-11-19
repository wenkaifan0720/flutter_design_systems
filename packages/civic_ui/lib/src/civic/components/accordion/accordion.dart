import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../internal/underline.dart';
import '../../theme.dart';

/// One section of a [CivicAccordion]: its [title] (a heading), a line of
/// [summary] under it, and the [child] it shows when open.
@immutable
class CivicAccordionSection {
  /// A section titled [title] holding [child].
  const CivicAccordionSection({
    required this.title,
    required this.child,
    this.summary,
  });

  /// What the section is about, as a heading.
  final String title;

  /// A line under the title saying what it holds, open or shut.
  final String? summary;

  /// What it shows when open.
  final Widget child;
}

/// Sections of one page a reader opens one at a time or all at once, as a
/// public service's guidance does: "Show all sections" over them, each
/// [sections]' heading a button (its title, its summary, then "Show" or
/// "Hide" with a chevron) between rules, its content folding open beneath
/// it on Civic's panel spring.
///
/// A pointer over a heading thickens the line under its "Show" and deepens
/// its colour; a keyboard focus lays the whole heading on the yellow plate
/// over the ink bar. A screen reader hears each heading as a heading and a
/// button with its state, shut or open. A shut section's content is gone
/// to the keys and to a screen reader.
///
/// Use it where readers come for one part of a long page; where most need
/// all of it, set it out in sight.
///
/// Open sections are [expanded] with [onExpandedChanged] (by index), or
/// the accordion's own from [initiallyExpanded].
///
/// Reads [CivicStyle]'s foreground (the "Show" words, by state) and
/// textStyle (the titles): its `style:`, then
/// [CivicThemeData.accordionStyle].
///
/// ```dart
/// CivicAccordion(
///   sections: [
///     CivicAccordionSection(
///       title: 'Who can apply',
///       child: Text('Anyone who lives in a permit zone.'),
///     ),
///     CivicAccordionSection(
///       title: 'What it costs',
///       child: Text('€60 a year.'),
///     ),
///   ],
/// )
/// ```
class CivicAccordion extends StatefulWidget {
  /// Sections with "Show all sections" over them.
  const CivicAccordion({
    super.key,
    required this.sections,
    this.expanded,
    this.onExpandedChanged,
    this.initiallyExpanded = const {},
    this.showAllLabel = 'Show all sections',
    this.hideAllLabel = 'Hide all sections',
    this.showLabel = 'Show',
    this.hideLabel = 'Hide',
    this.style,
  });

  /// The sections, in order.
  final List<CivicAccordionSection> sections;

  /// The open sections' indexes; null: the accordion's own.
  final Set<int>? expanded;

  /// Called with the open sections' indexes as a reader opens or shuts one
  /// or all.
  final ValueChanged<Set<int>>? onExpandedChanged;

  /// The sections open at first when [expanded] is null.
  final Set<int> initiallyExpanded;

  /// The words over the sections while any is shut.
  final String showAllLabel;

  /// The words over the sections while all are open.
  final String hideAllLabel;

  /// A shut section's words.
  final String showLabel;

  /// An open section's words.
  final String hideLabel;

  /// Overrides for this accordion's look.
  final CivicStyle? style;

  @override
  State<CivicAccordion> createState() => _CivicAccordionState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('sections', sections.map((s) => s.title)))
      ..add(IterableProperty<int>('expanded', expanded, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<Set<int>>>.has(
          'onExpandedChanged',
          onExpandedChanged,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicAccordionState extends State<CivicAccordion> {
  late Set<int> _own = {...widget.initiallyExpanded};

  Set<int> get _open => widget.expanded ?? _own;

  void _set(Set<int> next) {
    if (widget.expanded == null) setState(() => _own = next);
    widget.onExpandedChanged?.call(next);
  }

  void _toggle(int i) {
    final open = _open;
    _set(open.contains(i) ? ({...open}..remove(i)) : {...open, i});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final all =
        widget.sections.isNotEmpty &&
        _open.containsAll([for (var i = 0; i < widget.sections.length; i++) i]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.only(bottom: CivicSpacing.s8),
            child: _ShowWords(
              words: all ? widget.hideAllLabel : widget.showAllLabel,
              open: all,
              style: widget.style,
              onPressed: () => _set(
                all
                    ? <int>{}
                    : {for (var i = 0; i < widget.sections.length; i++) i},
              ),
            ),
          ),
        ),
        for (final (i, section) in widget.sections.indexed)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: t.rule),
                bottom: i == widget.sections.length - 1
                    ? BorderSide(color: t.rule)
                    : BorderSide.none,
              ),
            ),
            child: _Section(
              section: section,
              open: _open.contains(i),
              onToggle: () => _toggle(i),
              showLabel: widget.showLabel,
              hideLabel: widget.hideLabel,
              style: widget.style,
            ),
          ),
      ],
    );
  }
}

/// "Show all sections": a pressable line of words with its chevron, a
/// link's look.
class _ShowWords extends StatelessWidget {
  const _ShowWords({
    required this.words,
    required this.open,
    required this.onPressed,
    required this.style,
  });

  final String words;
  final bool open;
  final VoidCallback onPressed;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) => DesignPressable(
    onPressed: onPressed,
    expanded: open,
    semanticLabel: words,
    excludeSemantics: true,
    minimumSize: const Size(0, CivicMetrics.controlHeight),
    mouseCursor: SystemMouseCursors.click,
    builder: (context, states, _) => _Focusable(
      states: states,
      child: _Toggle(words: words, open: open, states: states, style: style),
    ),
  );
}

/// A section: its heading as a button, its content folding under it.
class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.open,
    required this.onToggle,
    required this.showLabel,
    required this.hideLabel,
    required this.style,
  });

  final CivicAccordionSection section;
  final bool open;
  final VoidCallback onToggle;
  final String showLabel;
  final String hideLabel;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final summary = section.summary;
    // The heading and its button are one node to a screen reader: a
    // heading that opens, saying whether it is open.
    final heading = MergeSemantics(
      child: Semantics(
        header: true,
        child: DesignPressable(
          onPressed: onToggle,
          expanded: open,
          semanticLabel: summary == null
              ? section.title
              : '${section.title}, $summary',
          excludeSemantics: true,
          mouseCursor: SystemMouseCursors.click,
          builder: (context, states, _) {
            final so = DesignStyleOf([style, t.accordionStyle], states);
            return _Focusable(
              states: states,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: CivicSpacing.s4,
                  children: [
                    _Ink(
                      states: states,
                      rest: so.textStyle?.color ?? t.textPrimary,
                      builder: (ink) => Text(
                        section.title,
                        style: text.headingS
                            .merge(so.textStyle)
                            .copyWith(color: ink),
                      ),
                    ),
                    if (summary != null)
                      _Ink(
                        states: states,
                        rest: t.textSecondary,
                        builder: (ink) => Text(
                          summary,
                          style: text.body.copyWith(color: ink),
                        ),
                      ),
                    _Toggle(
                      words: open ? hideLabel : showLabel,
                      open: open,
                      states: states,
                      style: style,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        heading,
        CivicSpringValue(
          value: open ? 1 : 0,
          spring: CivicMotion.panel,
          child: Padding(
            padding: const EdgeInsets.only(bottom: CivicSpacing.s24),
            child: DefaultTextStyle.merge(
              style: text.body.copyWith(color: t.textPrimary),
              child: section.child,
            ),
          ),
          builder: (context, reveal, content) {
            final shown = reveal.clamp(0.0, 1.0);
            if (!open && shown < 0.001) return const SizedBox.shrink();
            // Shutting, the content is gone to a screen reader and the
            // keys at once; only its picture folds away.
            return ExcludeFocus(
              excluding: !open,
              child: ExcludeSemantics(
                excluding: !open,
                child: ClipRect(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    heightFactor: shown,
                    child: content,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The yellow plate over the ink bar behind a focused heading, on its
/// spring.
class _Focusable extends StatelessWidget {
  const _Focusable({required this.states, required this.child});

  final Set<WidgetState> states;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return CivicSpringValue(
      value: states.contains(WidgetState.focused) ? 1 : 0,
      spring: CivicMotion.focus,
      effects: true,
      builder: (context, focus, _) => CustomPaint(
        painter: CivicFacePainter(
          fill: t.focus.withValues(alpha: 0),
          edgeColor: t.onFocus,
          edgeHeight: 0,
          press: 0,
          focus: focus,
          focusColor: t.focus,
          barColor: t.focusBar,
          // The plate reaches past the words, so they stand inset on it.
          outset: CivicSpacing.s8,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: CivicMetrics.bar),
          child: child,
        ),
      ),
    );
  }
}

/// Words in [rest]'s colour that turn to the focus's ink on a focus: on
/// the yellow plate words are always ink, by day and by night.
class _Ink extends StatelessWidget {
  const _Ink({required this.states, required this.rest, required this.builder});

  final Set<WidgetState> states;
  final Color rest;
  final Widget Function(Color ink) builder;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return CivicSpringValue(
      value: states.contains(WidgetState.focused) ? 1 : 0,
      spring: CivicMotion.focus,
      effects: true,
      builder: (context, focus, _) =>
          builder(Color.lerp(rest, t.onFocus, focus)!),
    );
  }
}

/// "Show" or "Hide" with its chevron: underlined in the action colour, the
/// line thickening under a pointer, the chevron turning as it opens.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.words,
    required this.open,
    required this.states,
    required this.style,
  });

  final String words;
  final bool open;
  final Set<WidgetState> states;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.accordionStyle], states);
    final held = states.contains(WidgetState.pressed);
    final over = held || states.contains(WidgetState.hovered);
    return CivicSpringValue(
      value: over ? 1 : 0,
      spring: CivicMotion.press,
      builder: (context, press, _) => CivicSpringValue(
        value: states.contains(WidgetState.focused) ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) {
          final ink = Color.lerp(
            Color.lerp(
              so.foreground ?? t.action,
              t.textPrimary,
              held ? 1 : 0.45 * press,
            ),
            t.onFocus,
            focus,
          )!;
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: CivicSpacing.s8,
            children: [
              CivicSpringValue(
                value: open ? 1 : 0,
                spring: CivicMotion.state,
                builder: (context, turn, _) => Transform.rotate(
                  angle: turn * math.pi,
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: ink,
                    applyTextScaling: true,
                  ),
                ),
              ),
              Flexible(
                child: CivicUnderlined(
                  style: text.body.copyWith(
                    color: ink,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.2 + 1.8 * press,
                    decorationColor: Color.lerp(
                      ink,
                      t.onFocus.withValues(alpha: 0),
                      focus,
                    ),
                  ),
                  child: Text(words),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
