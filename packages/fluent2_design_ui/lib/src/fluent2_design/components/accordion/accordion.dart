import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// An accordion header's size, Fluent's `size`: [small] 32 tall in
/// caption1 (44 on a phone), [medium] 44 in body1 (the default), [large]
/// 44 in body2, [extraLarge] 44 in subtitle1's 20/28 regular.
enum Fluent2AccordionSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,

  /// The extra-large size.
  extraLarge,
}

/// Which end of a header its chevron stands at, Fluent's
/// `expandIconPosition`: at the [start], pointing at its words and turning
/// down when open (the default), or at the [end], down when shut and up
/// when open.
enum Fluent2ExpandIconPosition {
  /// The chevron at the header's start.
  start,

  /// The chevron at the header's end.
  end,
}

/// One section of a [Fluent2Accordion]: its [value], the [title] its header
/// says (an [icon] before it), the [child] its panel shows while open, and
/// whether it can be opened ([enabled]).
///
/// ```dart
/// Fluent2AccordionItem(value: 'agenda', title: 'Agenda', icon: Fluent2Icons.textBulletListLtr, child: Text('Roadmap review, then Q&A'))
/// ```
@immutable
class Fluent2AccordionItem {
  /// An accordion section for [value], headed [title].
  const Fluent2AccordionItem({
    required this.value,
    required this.title,
    required this.child,
    this.icon,
    this.enabled = true,
  });

  /// The value that names the section in the accordion's open set.
  final Object value;

  /// The header's words.
  final String title;

  /// What the section shows while open.
  final Widget child;

  /// The glyph before [title]; null shows none.
  final IconData? icon;

  /// False draws the header disabled; it does not open or shut.
  final bool enabled;
}

/// Fluent 2's Accordion: [items] as sections that open and shut, each a
/// header (the chevron, the title, 10 in at the start and 12 at the end, 44
/// tall) over its panel 12 in from either side. One open at a time unless
/// [multiple]; the open one shuts again only when [collapsible]. Open
/// state is the caller's ([openItems], told through [onToggle]) or the
/// accordion's own from [initiallyOpen]. Panels open with Fluent's collapse
/// motion (`durationNormal`), at once under Reduce Motion.
/// Read as headers that say whether they are expanded.
///
/// ```dart
/// Fluent2Accordion(items: [Fluent2AccordionItem(value: 'agenda', title: 'Agenda', child: Text('Roadmap review')), Fluent2AccordionItem(value: 'notes', title: 'Notes', child: Text('Shared after the call'))], initiallyExpanded: const {'agenda'})
/// ```
class Fluent2Accordion extends StatefulWidget {
  /// An accordion of [items].
  const Fluent2Accordion({
    required this.items,
    this.multiple = false,
    this.collapsible = true,
    this.expanded,
    this.initiallyExpanded = const <Object>{},
    this.onExpansionChanged,
    this.size = Fluent2AccordionSize.medium,
    this.expandIconPosition = Fluent2ExpandIconPosition.start,
    super.key,
  });

  /// The sections, in order.
  final List<Fluent2AccordionItem> items;

  /// Whether more than one section may stand open.
  final bool multiple;

  /// Whether the open section may be shut again (with none open after).
  final bool collapsible;

  /// The open sections' values when the caller keeps them; null keeps them
  /// here, starting from [initiallyOpen].
  final Set<Object>? expanded;

  /// The sections open at first, by value.
  final Set<Object> initiallyExpanded;

  /// Told the section pressed and whether it is now open.
  final void Function(Object value, bool open)? onExpansionChanged;

  /// Fluent's `size`: the headers' height and type.
  final Fluent2AccordionSize size;

  /// Fluent's `expandIconPosition`: the chevron at the start or the end.
  final Fluent2ExpandIconPosition expandIconPosition;

  @override
  State<Fluent2Accordion> createState() => _Fluent2AccordionState();
}

class _Fluent2AccordionState extends State<Fluent2Accordion> {
  late Set<Object> _open = {...widget.initiallyExpanded};

  Set<Object> get _current => widget.expanded ?? _open;

  void _toggle(Object value) {
    final open = _current.contains(value);
    if (open && !widget.collapsible) {
      final others = _current.where((v) => v != value);
      if (!widget.multiple || others.isEmpty) return;
    }
    final next = {..._current};
    if (open) {
      next.remove(value);
    } else {
      if (!widget.multiple) next.clear();
      next.add(value);
    }
    if (widget.expanded == null) setState(() => _open = next);
    widget.onExpansionChanged?.call(value, !open);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in widget.items)
        _Section(
          item: item,
          open: _current.contains(item.value),
          size: widget.size,
          position: widget.expandIconPosition,
          onTap: item.enabled ? () => _toggle(item.value) : null,
        ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.item,
    required this.open,
    required this.size,
    required this.position,
    required this.onTap,
  });

  final Fluent2AccordionItem item;
  final bool open;
  final Fluent2AccordionSize size;
  final Fluent2ExpandIconPosition position;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final wide = Fluent2Layout.isWide(context);
    final atEnd = position == Fluent2ExpandIconPosition.end;
    // A row is a target (48 under a finger, 44 elsewhere); a small one is
    // 32 under a desk pointer.
    final height =
        size == Fluent2AccordionSize.small &&
            wide &&
            !Fluent2Layout.padded(context)
        ? 32.0
        : Fluent2Layout.hitTargetOf(context);
    final type = switch (size) {
      Fluent2AccordionSize.small => t.caption1,
      Fluent2AccordionSize.medium => t.body1,
      Fluent2AccordionSize.large => t.body2,
      Fluent2AccordionSize.extraLarge => t.subtitle1.regular,
    };
    // Fluent turns ChevronRight: at the start 0 shut and 90 open; at the
    // end 90 shut and -90 open. Right to left the glyph is mirrored (it
    // points the reading way), so it turns the other way to point down and
    // up as it does left to right.
    final way = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final turns = way * (atEnd ? (open ? -0.25 : 0.25) : (open ? 0.25 : 0.0));
    final duration = Fluent2Motion.on(context)
        ? Fluent2Motion.normal
        : Duration.zero;
    final header = MergeSemantics(
      child: Fluent2Pressable(
        onPressed: onTap,
        label: item.title,
        expanded: open,
        radius: Fluent2Radius.medium,
        builder: (context, states) {
          final press = states.press;
          final ink = press == Fluent2Press.disabled
              ? t.textDisabled
              : t.textPrimary;
          final chevron = AnimatedRotation(
            turns: turns,
            duration: duration,
            curve: Fluent2Motion.easyEaseMax,
            child: Icon(
              Fluent2Icons.chevronRight,
              size: Fluent2IconSize.i20,
              color: ink,
            ),
          );
          return Container(
            constraints: BoxConstraints(minHeight: height),
            padding: EdgeInsetsDirectional.only(
              start: atEnd && item.icon == null
                  ? Fluent2Spacing.m
                  : Fluent2Spacing.mNudge,
              end: atEnd ? Fluent2Spacing.mNudge : Fluent2Spacing.m,
            ),
            decoration: BoxDecoration(
              color: t.colors.transparentBackground,
              borderRadius: BorderRadius.circular(Fluent2Radius.medium),
            ),
            child: Row(
              children: [
                if (!atEnd)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: Fluent2Spacing.s,
                    ),
                    child: chevron,
                  ),
                if (item.icon != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: Fluent2Spacing.s,
                    ),
                    child: Icon(
                      item.icon,
                      size: Fluent2IconSize.i20,
                      color: ink,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Fluent2Spacing.xs,
                    ),
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.c(ink),
                    ),
                  ),
                ),
                if (atEnd)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: Fluent2Spacing.s,
                    ),
                    child: chevron,
                  ),
              ],
            ),
          );
        },
      ),
    );
    final Widget panel = open
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: Fluent2Spacing.m),
            child: DefaultTextStyle.merge(
              style: t.body1.c(t.textPrimary),
              child: item.child,
            ),
          )
        : const SizedBox(width: double.infinity);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        // With motion off the panel settles at once: no AnimatedSize at
        // all, since one of zero duration re-dirties itself in layout.
        if (!Fluent2Motion.on(context))
          panel
        else
          ClipRect(
            child: AnimatedSize(
              duration: duration,
              curve: Fluent2Motion.decelerateMid,
              alignment: Alignment.topCenter,
              child: panel,
            ),
          ),
      ],
    );
  }
}
