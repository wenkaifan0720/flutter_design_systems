import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../menu/menu.dart';
import '../pressable/pressable.dart';

/// A breadcrumb's size, Fluent's `size`: [small] 24 tall in caption1 with
/// 12 chevrons, [medium] 32 in body1 with 16 chevrons (the default),
/// [large] 40 in body2 with 20 chevrons.
enum Fluent2BreadcrumbSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// One place on a [Fluent2Breadcrumb]'s path: its [label], a glyph before
/// it ([icon]) and where a press leads ([onTap]).
///
/// ```dart
/// Fluent2BreadcrumbItem('Files', icon: Fluent2Icons.folder, onPressed: openFiles)
/// ```
@immutable
class Fluent2BreadcrumbItem {
  /// A crumb labelled [label].
  const Fluent2BreadcrumbItem(this.label, {this.onPressed, this.icon});

  /// The crumb's words.
  final String label;

  /// Called when the crumb is pressed; null for the current page.
  final VoidCallback? onPressed;

  /// The glyph before [label]; null shows none.
  final IconData? icon;
}

/// Fluent 2's Breadcrumb: the path to the current page as its [items]
/// with a chevron between each pair, every ancestor a subtle button in the
/// second ink and the last, the current page, in the strong cut and inert.
/// When the path is longer than its room (or than [maxDisplayedItems]) the
/// middle folds into Fluent's overflow button (the more glyph) after the
/// first item, which opens a [Fluent2Menu] of the hidden places. Read as a
/// navigation path of links, the current page said.
///
/// ```dart
/// Fluent2Breadcrumb(items: [Fluent2BreadcrumbItem('Northwind', onPressed: openRoot), Fluent2BreadcrumbItem('Design', onPressed: openDesign), const Fluent2BreadcrumbItem('Brand guidelines.pdf')])
/// ```
class Fluent2Breadcrumb extends StatelessWidget {
  /// A breadcrumb of [items].
  const Fluent2Breadcrumb({
    required this.items,
    this.size = Fluent2BreadcrumbSize.medium,
    this.maxDisplayedItems,
    this.label,
    super.key,
  });

  /// The path, the current page last.
  final List<Fluent2BreadcrumbItem> items;

  /// Fluent's `size`: the crumbs' height and type.
  final Fluent2BreadcrumbSize size;

  /// At most this many places shown (the overflow button aside); null
  /// shows as many as the room holds.
  final int? maxDisplayedItems;

  /// What a screen reader calls the path; null is "Breadcrumb" in the app's
  /// language.
  final String? label;

  double get _height => switch (size) {
    Fluent2BreadcrumbSize.small => 24,
    Fluent2BreadcrumbSize.medium => 32,
    Fluent2BreadcrumbSize.large => 40,
  };

  double get _side => size == Fluent2BreadcrumbSize.large
      ? Fluent2Spacing.s
      : Fluent2Spacing.sNudge;

  double get _chevron => switch (size) {
    Fluent2BreadcrumbSize.small => 12,
    Fluent2BreadcrumbSize.medium => 16,
    Fluent2BreadcrumbSize.large => 20,
  };

  IconData get _chevronGlyph => switch (size) {
    Fluent2BreadcrumbSize.small => Fluent2Icons.chevronRight12,
    Fluent2BreadcrumbSize.medium => Fluent2Icons.chevronRight16,
    Fluent2BreadcrumbSize.large => Fluent2Icons.chevronRight,
  };

  TextStyle _type(Fluent2ThemeData t, bool current) => switch (size) {
    Fluent2BreadcrumbSize.small => current ? t.caption1Strong : t.caption1,
    Fluent2BreadcrumbSize.medium => current ? t.body1Strong : t.body1,
    Fluent2BreadcrumbSize.large => current ? t.subtitle2 : t.body2,
  };

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty, 'a path of at least one place');
    final t = context.fluent2Theme;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final last = items.length - 1;
        double widthOf(int i) {
          final item = items[i];
          final painter = TextPainter(
            text: TextSpan(text: item.label, style: _type(t, i == last)),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final w =
              painter.width +
              2 * _side +
              (item.icon == null ? 0 : _chevron + Fluent2Spacing.xs) +
              1;
          painter.dispose();
          return w;
        }

        final widths = [for (var i = 0; i <= last; i++) widthOf(i)];
        final overflowWidth = _height;
        final room = box.maxWidth;
        var shown = <int>[for (var i = 0; i <= last; i++) i];
        var folded = <int>[];
        double total(List<int> at, bool more) =>
            at.fold<double>(0, (s, i) => s + widths[i]) +
            (at.length - 1 + (more ? 1 : 0)) * _chevron +
            (more ? overflowWidth : 0);
        final cap = maxDisplayedItems;
        if (cap != null && items.length > cap && cap >= 1) {
          shown = [0, for (var i = last - cap + 2; i <= last; i++) i];
          if (cap == 1) shown = [last];
          folded = [
            for (var i = 0; i <= last; i++)
              if (!shown.contains(i)) i,
          ];
        }
        if (room.isFinite && total(shown, folded.isNotEmpty) > room) {
          // Keep the first place and as many of the last as fit.
          final tail = <int>[last];
          for (var i = last - 1; i >= 1; i--) {
            if (!shown.contains(i)) continue;
            if (total([0, i, ...tail], true) > room) break;
            tail.insert(0, i);
          }
          shown = total([0, ...tail], true) <= room || items.length == 1
              ? [if (last > 0) 0, ...tail]
              : tail;
          folded = [
            for (var i = 0; i <= last; i++)
              if (!shown.contains(i)) i,
          ];
        }
        final parts = <Widget>[];
        void divider() => parts.add(
          ExcludeSemantics(
            child: Icon(_chevronGlyph, size: _chevron, color: t.textSecondary),
          ),
        );
        for (final (n, i) in shown.indexed) {
          if (n > 0) divider();
          final current = i == last;
          final crumb = _Crumb(
            item: items[i],
            current: current,
            height: _height,
            side: _side,
            glyph: _chevron,
            style: _type(t, current),
          );
          parts.add(current && room.isFinite ? Flexible(child: crumb) : crumb);
          if (folded.isNotEmpty && n == 0 && shown.length > 1) {
            divider();
            parts.add(_overflow(folded));
          }
        }
        if (folded.isNotEmpty && shown.length == 1) {
          parts.insert(0, _overflow(folded));
          parts.insert(
            1,
            ExcludeSemantics(
              child: Icon(
                _chevronGlyph,
                size: _chevron,
                color: t.textSecondary,
              ),
            ),
          );
        }
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: label ?? Fluent2Localizations.of(context).breadcrumb,
          child: Row(mainAxisSize: MainAxisSize.min, children: parts),
        );
      },
    );
  }

  Widget _overflow(List<int> folded) => Builder(
    builder: (anchor) => Fluent2IconButton(
      Fluent2Icons.moreHorizontal,
      label: Fluent2Localizations.of(anchor).morePlacesCount(folded.length),
      size: switch (size) {
        Fluent2BreadcrumbSize.small => Fluent2ButtonSize.small,
        Fluent2BreadcrumbSize.medium => Fluent2ButtonSize.medium,
        Fluent2BreadcrumbSize.large => Fluent2ButtonSize.large,
      },
      onPressed: () async {
        final picked = await Fluent2Menu.show<int>(
          anchor,
          label: Fluent2Localizations.of(anchor).morePlaces,
          items: [
            for (final i in folded)
              Fluent2MenuItem(
                i,
                items[i].label,
                icon: items[i].icon,
                enabled: items[i].onPressed != null,
              ),
          ],
        );
        if (picked != null) items[picked].onPressed?.call();
      },
    ),
  );
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.item,
    required this.current,
    required this.height,
    required this.side,
    required this.glyph,
    required this.style,
  });

  final Fluent2BreadcrumbItem item;
  final bool current;
  final double height;
  final double side;
  final double glyph;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    // Fluent's BreadcrumbButton is a button: its room stands inside a 1
    // stroke (transparent here).
    Widget face(Color ink, Color fill) => Container(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsets.symmetric(horizontal: side + Fluent2Stroke.thin),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Fluent2Radius.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Fluent2Spacing.xs,
        children: [
          if (item.icon != null) Icon(item.icon, size: glyph, color: ink),
          // A place's name stays whole: the current place, given what room
          // the path leaves it, is drawn smaller where it is longer, never
          // cut.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: fluent2CapCentred(
                Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  style: style.c(ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (current) {
      return Semantics(
        container: true,
        label: '${item.label}, current page',
        excludeSemantics: true,
        child: face(t.textSecondary, t.colors.transparentBackground),
      );
    }
    return Fluent2HitSlop(
      child: Fluent2Pressable(
        onPressed: item.onPressed,
        label: item.label,
        role: Fluent2PressRole.link,
        radius: Fluent2Radius.medium,
        builder: (context, states) {
          final press = states.press;
          final f = Fluent2ButtonFace.of(
            t,
            Fluent2ButtonAppearance.subtle,
            press,
          );
          return face(f.ink, f.fill);
        },
      ),
    );
  }
}
