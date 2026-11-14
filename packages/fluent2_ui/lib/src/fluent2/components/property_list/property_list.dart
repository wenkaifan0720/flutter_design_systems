import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/well.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// How a [Fluent2DescriptionList] lays its pairs: [columns] the label at the
/// start and the value beside it, [stacked] the label over the value (a
/// narrow details pane), or [auto]: columns from 360 wide, stacked under.
enum Fluent2DescriptionListLayout {
  /// Columns where there is room, stacked where there is not.
  auto,

  /// Each term beside its value.
  columns,

  /// Each term over its value.
  stacked,
}

/// One fact of a [Fluent2DescriptionList]: its [label] and its [value] (or a
/// [child] standing as the value: a persona, a tag), a glyph before the
/// value ([icon]), and what a press on it opens ([onTap], its chevron at
/// the end).
///
/// ```dart
/// Fluent2DescriptionItem('Owner', 'Kai Tanaka', icon: Fluent2Icons.person)
/// ```
@immutable
class Fluent2DescriptionItem {
  /// A term called [label] with its value.
  const Fluent2DescriptionItem(
    this.label,
    this.value, {
    this.child,
    this.icon,
    this.onPressed,
  });

  /// The term.
  final String label;

  /// The value's words; null shows [child].
  final String? value;

  /// The value as a widget, when it is more than words.
  final Widget? child;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// Called when the item is pressed; null makes it still.
  final VoidCallback? onPressed;
}

/// A record's facts as a Fluent 2 details pane draws them (a file's type,
/// size, owner and dates): each [Fluent2DescriptionItem] a pair, the label in
/// caption1 and the third ink, the value in body1, laid in [layout]; a
/// hairline between pairs with [dividers]. An optional [title] heads it in
/// subtitle2. Read as label and value, pair by pair.
///
/// ```dart
/// Fluent2DescriptionList(title: 'Details', properties: const [Fluent2DescriptionItem('Type', 'Document'), Fluent2DescriptionItem('Size', '2.4 MB'), Fluent2DescriptionItem('Owner', 'Kai Tanaka')])
/// ```
class Fluent2DescriptionList extends StatelessWidget {
  /// A list of [properties].
  const Fluent2DescriptionList({
    required this.properties,
    this.title,
    this.layout = Fluent2DescriptionListLayout.auto,
    this.dividers = false,
    this.labelWidth = 128,
    super.key,
  });

  /// The terms and values, in order.
  final List<Fluent2DescriptionItem> properties;

  /// The list's heading; null shows none.
  final String? title;

  /// Each term beside its value, over it, or picked by the room.
  final Fluent2DescriptionListLayout layout;

  /// Whether a hairline stands between items.
  final bool dividers;

  /// The label column's width in the [Fluent2DescriptionListLayout.columns] layout.
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final title = this.title;
    return LayoutBuilder(
      builder: (context, box) {
        final stacked = switch (layout) {
          Fluent2DescriptionListLayout.stacked => true,
          Fluent2DescriptionListLayout.columns => false,
          Fluent2DescriptionListLayout.auto => box.maxWidth < 360,
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Fluent2Spacing.s),
                child: Semantics(
                  header: true,
                  child: Text(title, style: t.subtitle2),
                ),
              ),
            for (final (i, p) in properties.indexed) ...[
              if (i > 0 && dividers)
                SizedBox(
                  height: 1,
                  child: ColoredBox(
                    color: fluent2Step(t, t.colors.neutralStroke2),
                  ),
                ),
              _Pair(property: p, stacked: stacked, labelWidth: labelWidth),
            ],
          ],
        );
      },
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({
    required this.property,
    required this.stacked,
    required this.labelWidth,
  });

  final Fluent2DescriptionItem property;
  final bool stacked;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final p = property;
    final value = p.value;
    Widget pair(Fluent2Press press) {
      final label = Text(
        p.label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.caption1.c(t.textTertiary).line(stacked ? 16 : 20),
      );
      final Widget shown =
          p.child ??
          Text(
            value ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: t.body1.c(
              p.onPressed == null
                  ? t.textPrimary
                  : press.pick(
                      t.colors.neutralForeground1,
                      t.colors.neutralForeground1Hover,
                      t.colors.neutralForeground1Pressed,
                    ),
            ),
          );
      final valueRow = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Fluent2Spacing.s,
        children: [
          if (p.icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                p.icon,
                size: Fluent2IconSize.i16,
                color: t.textSecondary,
              ),
            ),
          Expanded(child: shown),
          if (p.onPressed != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Fluent2Icons.chevronRight16,
                size: Fluent2IconSize.i16,
                color: t.textTertiary,
              ),
            ),
        ],
      );
      final body = stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Fluent2Spacing.xxs,
              children: [label, valueRow],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Fluent2Spacing.m,
              children: [
                SizedBox(width: labelWidth, child: label),
                Expanded(child: valueRow),
              ],
            );
      return Container(
        constraints: BoxConstraints(
          minHeight: p.onPressed == null
              ? 0
              : Fluent2Layout.hitTargetOf(context),
        ),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.sNudge),
        decoration: BoxDecoration(
          color: p.onPressed == null
              ? null
              : press.pick(
                  t.colors.subtleBackground,
                  t.colors.subtleBackgroundHover,
                  t.colors.subtleBackgroundPressed,
                ),
          borderRadius: BorderRadius.circular(Fluent2Radius.medium),
        ),
        child: body,
      );
    }

    final spoken = '${p.label}, ${value ?? ''}';
    if (p.onPressed == null) {
      return MergeSemantics(child: pair(Fluent2Press.rest));
    }
    return Semantics(
      container: true,
      child: Fluent2Pressable(
        onPressed: p.onPressed,
        label: p.child == null ? spoken : p.label,
        excludeChild: p.child == null,
        radius: Fluent2Radius.medium,
        builder: (context, states) => pair(states.press),
      ),
    );
  }
}
