import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/button_ends.dart';
import '../../internal/cap_center.dart';
import '../../format.dart';
import '../../internal/engraving.dart';
import '../../internal/even_acts.dart';
import '../../internal/face.dart';
import '../../internal/narrow.dart';
import '../../internal/per_line.dart';
import '../../internal/whole_pixel.dart';
import '../../theme.dart';
import '../gauge/gauge.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';

// --- The menu ----------------------------------------------------------------

/// One item of a [LedgerMenu]: its [label], an [amount] at its end, and
/// whether it is the one [selected] (checked, on the paper, semibold).
///
/// ```dart
/// LedgerMenuItem('October 2026', amount: 2486.12, selected: true, onTap: () {})
/// ```
///
/// ```dart
/// LedgerMenuItem('October 2026', key: const ValueKey('keep-month'), selected: true, onTap: () {})
/// ```
class LedgerMenuItem {
  /// An item worded [label], with an optional [amount].
  const LedgerMenuItem(
    this.label, {
    this.amount,
    this.selected = false,
    this.onTap,
    this.key,
  });

  /// The item's words.
  final String label;

  /// An amount at the item's end, in the mono.
  final num? amount;

  /// Whether this is the chosen item.
  final bool selected;

  /// What choosing it does; null leaves it inert.
  final VoidCallback? onTap;

  /// The item's own key (its press target).
  final Key? key;
}

/// A menu (`.menu`): a slip of the raised paper 300 wide, lifted on the
/// menu's shadow, a mono [head] over its [items], one choice of a set
/// (the months Spending can show): each 46 tall, the chosen one checked
/// in the green on the paper. Stand it 10 under the control that opens it
/// (centred under it on a phone, at its start from 1024). Read as its
/// [semanticLabel], each item a button that says whether it is chosen.
///
/// ```dart
/// LedgerMenu(head: 'Spent by month', semanticLabel: 'Months', items: [LedgerMenuItem('October 2026', amount: 2486.12, selected: true, onTap: () {})])
/// ```
class LedgerMenu extends StatelessWidget {
  /// A menu of [items] under a [head].
  const LedgerMenu({
    required this.items,
    this.head,
    this.semanticLabel,
    super.key,
  });

  /// The choices, in order.
  final List<LedgerMenuItem> items;

  /// The mono words over the items, set in capitals.
  final String? head;

  /// What a screen reader says the menu is.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Container(
        width: _width,
        padding: const EdgeInsets.symmetric(vertical: _padY),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.cardRadius),
          boxShadow: t.menuShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (head case final h?)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _padX,
                  vertical: _headPad,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.hairline)),
                ),
                // `.menu-head` is a block of running copy holding a `.meta`
                // span: its line is the body's 21.75.
                child: Text(
                  h.toUpperCase(),
                  style: t.meta,
                  strutStyle: StrutStyle.fromTextStyle(t.body),
                ),
              ),
            for (final (i, item) in items.indexed)
              _item(t, item, first: i == 0, larger: larger),
          ],
        ),
      ),
    );
  }

  Widget _item(
    LedgerThemeData t,
    LedgerMenuItem item, {
    required bool first,
    required bool larger,
  }) {
    final on = item.selected;
    final amount = item.amount;
    final words = on ? t.rowTitle.semibold : t.rowTitle;
    // At a large text size the item grows rather than cut its label: the
    // label wraps whole, and the amount turns under it when the two do not
    // fit one line.
    final Widget body = larger
        ? Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: _gap,
            children: [
              Text(item.label, style: words),
              if (amount != null)
                LedgerAmount(amount, size: LedgerAmountSize.small),
            ],
          )
        : Row(
            spacing: _gap,
            children: [
              Expanded(
                child: ledgerCapCenter(
                  t.rowTitle,
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: words,
                  ),
                ),
              ),
              if (amount != null)
                ledgerCapCenter(
                  t.amount,
                  LedgerAmount(amount, size: LedgerAmountSize.small),
                ),
            ],
          );
    return LedgerPressable(
      key: item.key,
      onTap: item.onTap,
      label: item.label,
      value: amount == null ? null : LedgerFormat.money(amount),
      selected: on,
      child: Container(
        height: larger ? null : _itemHeight,
        constraints: larger
            ? const BoxConstraints(minHeight: _itemHeight)
            : null,
        padding: larger
            ? const EdgeInsets.symmetric(horizontal: _padX, vertical: _grownPad)
            : const EdgeInsets.symmetric(horizontal: _padX),
        color: on ? t.menuSelected : null,
        // The rule between items drawn over the item's top, so its row keeps
        // the item's whole 46 and stands on its middle.
        foregroundDecoration: first
            ? null
            : BoxDecoration(
                border: Border(top: BorderSide(color: t.hairline)),
              ),
        child: Row(
          spacing: _gap,
          children: [
            SizedBox(
              width: _check,
              child: on
                  ? Icon(LucideIcons.check, size: _checkGlyph, color: t.accent)
                  : null,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  // `.menu`: 300 wide, 6 0; `.menu-head` 8 16 8; `.menu-item` 46 tall,
  // 0 16, 12 apart; `.menu-check` 18 wide, its glyph 16.
  static const double _width = 300;
  static const double _padY = 6;
  static const double _padX = 16;
  static const double _headPad = 8;
  static const double _itemHeight = 46;
  static const double _gap = 12;
  // Grown with a large text, an item's words stand 3 clear of its rules (a
  // label of one line keeps the 46).
  static const double _grownPad = 3;
  static const double _check = 18;
  static const double _checkGlyph = 16;
}

// --- The suggestion ----------------------------------------------------------

/// A suggested figure to take (`.suggest`): the [amount] in the green
/// serif, its [title] (semibold) over the [text] that says where it comes
/// from, and a round [action] in the green mono capitals, on the green's
/// faint wash in a green rule. The whole line is one button.
///
/// ```dart
/// LedgerSuggestion(amount: 275, text: 'Your September and October average, rounded to \$5.', onTap: () {})
/// ```
class LedgerSuggestion extends StatelessWidget {
  /// A suggested [amount], explained by [text].
  const LedgerSuggestion({
    required this.amount,
    required this.text,
    required this.onTap,
    this.title = 'Suggested',
    this.action = 'Use',
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The suggested sum, in whole dollars.
  final num amount;

  /// Where the figure comes from.
  final String text;

  /// Takes the figure; null disables it.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// The suggestion's name, over its [text].
  final String title;

  /// The act's words, in the green mono capitals.
  final String action;

  /// The spoken name; "Use the suggested $275" when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final figureText = LedgerFormat.money(amount, showCents: false);
    final words = t.bodySmall;
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final figure = Text(
      figureText,
      maxLines: 1,
      softWrap: false,
      style: t.figureSmall
          .sized(_figure)
          .line(_figure)
          .tracked(0)
          .colored(t.accent),
    );
    final why = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: words.semibold.colored(t.textPrimary)),
        Text(text, style: words.colored(t.textSecondary)),
      ],
    );
    final goWords = t.link.tracked(_goTracking).colored(t.accent);
    // At a large text size the act grows with its word rather than cut it.
    final go = Container(
      height: larger ? null : _goHeight,
      constraints: larger ? const BoxConstraints(minHeight: _goHeight) : null,
      padding: const EdgeInsets.symmetric(horizontal: _goPad),
      decoration: BoxDecoration(
        border: Border.all(color: t.accent),
        borderRadius: BorderRadius.circular(t.controlRadius),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: larger ? 1 : null,
        child: Text(
          action.toUpperCase(),
          maxLines: 1,
          softWrap: false,
          style: larger ? goWords : goWords.line(_goHeight - 2),
        ),
      ),
    );
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      label: semanticLabel ?? '$action the ${title.toLowerCase()} $figureText',
      radius: t.cardRadius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: _padY, horizontal: _padX),
        decoration: BoxDecoration(
          // rgba(222, 231, 221, .55): the green's wash at .55.
          color: t.accentSubtle.withValues(alpha: _wash),
          border: Border.all(color: t.accentRule),
          borderRadius: BorderRadius.circular(t.cardRadius),
        ),
        // At a large text size the words stand under the figure and its act,
        // at the line's whole width, rather than squeezed between them.
        child: larger
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: _gap / 2,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: _gap,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: figure,
                        ),
                      ),
                      go,
                    ],
                  ),
                  why,
                ],
              )
            : Row(
                spacing: _gap,
                children: [
                  figure,
                  Expanded(child: why),
                  go,
                ],
              ),
      ),
    );
  }

  // `.suggest`: 12 14, 14 apart, the wash at .55; `.suggest-fig` 400 32/1
  // serif; `.suggest-go` 32 tall, 0 14, 500 11/30 mono, .06em.
  static const double _padY = 12;
  static const double _padX = 14;
  static const double _gap = 14;
  static const double _wash = .55;
  static const double _figure = 32;
  static const double _goHeight = 32;
  static const double _goPad = 14;
  static const double _goTracking = .06;
}

// --- Categories: the tile, the option, the mini -------------------------------

/// A category as a tile (`.cat-tile`): its glyph, its [name] and what it
/// spent this month, vermilion when [overBudget] its budget, on the raised
/// paper in a fine rule. One link to the category. Stand them two by two
/// in [LedgerCategoryTiles].
///
/// ```dart
/// LedgerCategoryTile(icon: LucideIcons.utensils, name: 'Dining out', spent: 286.40, overBudget: true, onTap: () {})
/// ```
class LedgerCategoryTile extends StatelessWidget {
  /// A category's tile: its [icon], [name] and what it [spent].
  const LedgerCategoryTile({
    required this.icon,
    required this.name,
    required this.spent,
    this.overBudget = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The category's glyph.
  final IconData icon;

  /// The category's name.
  final String name;

  /// What the category spent this month.
  final num spent;

  /// Whether it spent past its budget: the figure in the vermilion.
  final bool overBudget;

  /// Opens the category.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      role: LedgerPressRole.link,
      label: '$name, ${LedgerFormat.money(spent)}',
      radius: t.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(_pad),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(t.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _gap,
          children: [
            LedgerGlyph(icon, size: LedgerGlyphSize.small),
            Text(name, style: t.rowTitle.sized(_name).line(_nameLine)),
            LedgerAmount(
              spent,
              tone: overBudget ? LedgerTone.over : LedgerTone.plain,
              size: LedgerAmountSize.small,
            ),
          ],
        ),
      ),
    );
  }

  // `.cat-tile`: 14 all round, 10 apart; `.cat-tile-t` 500 14/18.
  static const double _pad = 14;
  static const double _gap = 10;
  static const double _name = 14;
  static const double _nameLine = 18;
}

/// Category tiles two to a line on a phone (`.cat-tiles`), sharing the
/// column; from 600 each [tile] wide (its glyph, its name and its sum
/// whole, never a word broken), as many to a line as the column holds up to
/// four, from the column's start: a wide column never stretches them. 8
/// apart each way, the tiles of a line as tall as its tallest. No tile is
/// left alone on its line: three stand one per line on a phone and on one
/// line from 600.
///
/// ```dart
/// LedgerCategoryTiles(tiles: [for (final c in categories) LedgerCategoryTile(icon: c.icon, name: c.name, spent: c.spent, onTap: () {})])
/// ```
class LedgerCategoryTiles extends StatelessWidget {
  /// Lays out [tiles].
  const LedgerCategoryTiles({required this.tiles, super.key});

  /// The tiles, usually [LedgerCategoryTile]s.
  final List<Widget> tiles;

  /// A tile's width from 600.
  static const double tile = 144;

  @override
  Widget build(BuildContext context) {
    final roomy =
        MediaQuery.sizeOf(context).width >= LedgerLayout.measuredFrom &&
        !LedgerNarrowScope.isIn(context);
    // At a large text size a tile grows with its words (a name is never
    // broken), and a phone stands them one to a line.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (!roomy) {
      return _lines(ledgerPerLine(tiles.length, scale > 1 ? 1 : _phone), null);
    }
    final width = scale > 1 ? tile * scale : tile;
    return LayoutBuilder(
      builder: (context, c) {
        final fits = math.max(
          1,
          ((c.maxWidth + _gap) / (width + _gap)).floor(),
        );
        return _lines(
          ledgerPerLine(tiles.length, math.min(_roomy, fits)),
          math.min(width, c.maxWidth),
        );
      },
    );
  }

  /// [perLine] to a line: sharing the line, or each [width] wide from the
  /// line's start.
  Widget _lines(int perLine, double? width) => Column(
    crossAxisAlignment: width == null
        ? CrossAxisAlignment.stretch
        : CrossAxisAlignment.start,
    spacing: _gap,
    children: [
      for (var i = 0; i < tiles.length; i += perLine)
        IntrinsicHeight(
          child: Row(
            mainAxisSize: width == null ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: _gap,
            children: [
              for (var j = i; j < i + perLine; j++)
                if (width == null)
                  Expanded(
                    child: j < tiles.length
                        ? tiles[j]
                        : const SizedBox.shrink(),
                  )
                else if (j < tiles.length)
                  SizedBox(width: width, child: tiles[j]),
            ],
          ),
        ),
    ],
  );

  // `.cat-tiles`: two 1fr columns, gap 8; four from 600.
  static const double _gap = 8;
  static const int _phone = 2;
  static const int _roomy = 4;
}

/// One option of a choice (`.opt`): its glyph, its [label] and a round
/// check at its end, 10 above and below; the [selected] one green (its
/// glyph ringed and washed, the check filled). Stand them in `LedgerRows`
/// for the hairlines between (a sheet's categories). Each is a button that
/// says whether it is chosen.
///
/// ```dart
/// LedgerOption(icon: LucideIcons.utensils, label: 'Dining out', selected: true, onTap: () {})
/// ```
class LedgerOption extends StatelessWidget {
  /// An option worded [label] with its [icon].
  const LedgerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The option's glyph.
  final IconData icon;

  /// The option's words.
  final String label;

  /// Chooses the option; null disables it.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Whether this is the chosen option.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      label: label,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _pad),
        child: Row(
          spacing: _gap,
          children: [
            LedgerGlyph(
              icon,
              size: LedgerGlyphSize.pick,
              tone: selected ? LedgerGlyphTone.selected : LedgerGlyphTone.plain,
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.rowTitle,
              ),
            ),
            // The check fills green and its tick inks in, in Ledger's one
            // motion.
            LedgerFace(
              style: LedgerFaceStyle(
                ink: selected ? t.onAccent : t.onAccent.withValues(alpha: 0),
                ground: BoxDecoration(
                  color: selected ? t.accent : null,
                  shape: BoxShape.circle,
                ),
              ),
              builder: (context, s, _) => Container(
                width: _check,
                height: _check,
                decoration: s.ground,
                // No tick at all once it has faded out: an unchosen option
                // carries none.
                child: s.ink.a == 0
                    ? null
                    : Icon(LucideIcons.check, size: _checkGlyph, color: s.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // `.opt`: 10 0, 14 apart; `.opt-check` 24 round, its glyph 14.
  static const double _pad = 10;
  static const double _gap = 14;
  static const double _check = 24;
  static const double _checkGlyph = 14;
}

/// A category's month in a record's margin (`.cat-mini`): its [name] on
/// the leader to what it [spent], the gauge to its [budget] under them
/// with the month's [pace], then its [subtitle] and [trailingSubtitle] (the end
/// vermilion over budget). With no [budget] (a month gone by) the gauge
/// is left out and only the sub line follows. Unlike `LedgerCategoryLine`
/// it keeps one shape at every width. Stand it 16 under its head; [onTap]
/// makes it one link to the category.
///
/// ```dart
/// LedgerCategoryMini(name: 'Dining out', spent: 286.40, budget: 250, pace: 28 / 31, subtitle: 'Budget \$250', trailingSubtitle: 'Over by \$36.40', onTap: () {})
/// ```
class LedgerCategoryMini extends StatelessWidget {
  /// A category's month: [name], what it [spent] against its [budget].
  const LedgerCategoryMini({
    required this.name,
    required this.spent,
    this.budget,
    this.pace,
    this.subtitle,
    this.trailingSubtitle,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The category's name.
  final String name;

  /// What the category spent.
  final num spent;

  /// The category's budget; null leaves the gauge out (a month gone by).
  final num? budget;

  /// How far through the month it is, 0 to 1, marked on the gauge.
  final double? pace;

  /// The sub line's start words (the budget).
  final String? subtitle;

  /// The sub line's end words, vermilion over budget.
  final String? trailingSubtitle;

  /// Opens the category.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final budget = this.budget;
    final over = budget != null && spent > budget;
    final base = t.bodySmall;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LedgerLeaderLine(
          start: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.rowTitle,
          ),
          end: LedgerAmount(
            spent,
            tone: over ? LedgerTone.over : LedgerTone.plain,
          ),
        ),
        if (budget != null) ...[
          const SizedBox(height: _gaugeTop),
          LedgerGauge(
            // A budget of 0 reads as nothing spent against it.
            ratio: budget > 0 ? (spent / budget).toDouble() : 0,
            // The budget at 250 of 300, as the category's line stands it:
            // room past it for the overspend in the vermilion.
            budgetAt: 250 / 300,
            pace: pace,
            semanticLabel: '$name spent',
          ),
        ],
        if (subtitle != null || trailingSubtitle != null) ...[
          const SizedBox(height: _subTop),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: _subGap,
            children: [
              if (subtitle case final s?)
                Flexible(child: Text(s, style: base.colored(t.textTertiary))),
              if (trailingSubtitle case final e?)
                Text(e, style: base.colored(over ? t.over : t.textTertiary)),
            ],
          ),
        ],
      ],
    );
    final words = [
      name,
      LedgerFormat.money(spent),
      ?subtitle,
      ?trailingSubtitle,
    ].join(', ');
    if (onTap == null) {
      return Semantics(label: words, excludeSemantics: true, child: body);
    }
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      role: LedgerPressRole.link,
      label: words,
      child: body,
    );
  }

  // `.cat-mini .gauge` 10 under the line, `.sub` 6 under it, 12 apart.
  static const double _gaugeTop = 10;
  static const double _subTop = 6;
  static const double _subGap = 12;
}

// --- The icon picker ---------------------------------------------------------

/// One glyph a [LedgerIconPicker] offers, and the [name] it is read by.
///
/// ```dart
/// LedgerIconChoice(LucideIcons.plane, 'plane')
/// ```
class LedgerIconChoice {
  /// A choice of [icon], read as [name].
  const LedgerIconChoice(this.icon, this.name);

  /// The glyph offered.
  final IconData icon;

  /// The glyph's name, read as "Icon: name".
  final String name;
}

/// A form's choice of one glyph (`.icon-grid`): its [choices] in rounds of
/// 48, five to a line spread across it on a phone (16 apart from its start
/// from 600), 10 between lines; the [selectedIndex]
/// one green on its wash, ringed out in the green past the paper. Read as
/// a group ([semanticLabel]), each glyph a button named "Icon: plane"
/// that says whether it is chosen.
///
/// ```dart
/// LedgerIconPicker(choices: const [LedgerIconChoice(LucideIcons.plane, 'plane'), LedgerIconChoice(LucideIcons.shield, 'shield')], selectedIndex: 0, onSelected: (i) {})
/// ```
class LedgerIconPicker extends StatelessWidget {
  /// A choice among [choices], the [selectedIndex] one chosen.
  const LedgerIconPicker({
    required this.choices,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabel = 'Icon',
    super.key,
  });

  /// The glyphs offered, in order.
  final List<LedgerIconChoice> choices;

  /// The chosen glyph's index.
  final int selectedIndex;

  /// Called with the index of the glyph pressed; null disables the picker.
  final ValueChanged<int>? onSelected;

  /// What a screen reader says the group is.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final onSelect = onSelected;
    Widget round(int i) {
      final c = choices[i];
      final on = i == selectedIndex;
      return LedgerPressable(
        onTap: onSelect == null ? null : () => onSelect(i),
        label: '$semanticLabel: ${c.name.replaceAll('-', ' ')}',
        selected: on,
        radius: _round / 2,
        child: Container(
          width: _round,
          height: _round,
          decoration: BoxDecoration(
            color: on ? t.accentSubtle : t.background,
            shape: BoxShape.circle,
            border: Border.all(color: on ? t.accent : t.border),
            // `.icon-opt.is-on`: 0 0 0 3px paper-hi, 0 0 0 4px green (CSS
            // lays its first shadow on top; Flutter paints them in order).
            boxShadow: on
                ? [
                    BoxShadow(color: t.accent, spreadRadius: _ringGap + 1),
                    BoxShadow(color: t.surface, spreadRadius: _ringGap),
                  ]
                : null,
          ),
          child: Icon(
            c.icon,
            size: _glyph,
            color: on ? t.accent : t.textSecondary,
          ),
        ),
      );
    }

    // From 600 the rounds stand 16 apart from the column's start; a phone's
    // spread across it.
    final packed =
        MediaQuery.sizeOf(context).width >= LedgerLayout.measuredFrom &&
        !LedgerNarrowScope.isIn(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.only(top: _padTop, bottom: _padBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _rowGap,
          children: [
            for (var i = 0; i < choices.length; i += _columns)
              Row(
                mainAxisAlignment: packed
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.spaceBetween,
                spacing: packed ? _packedGap : 0,
                children: [
                  for (var j = i; j < i + _columns; j++)
                    j < choices.length
                        ? round(j)
                        // A short last line keeps the grid's columns.
                        : const SizedBox(width: _round),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // `.icon-grid`: repeat(5, 48px) spread, row-gap 10, 8 0 6; `.icon-opt`
  // 48 round, its glyph 20. DERIVED: 16 apart from 600.
  static const double _packedGap = 16;
  static const int _columns = 5;
  static const double _round = 48;
  static const double _glyph = 20;
  static const double _rowGap = 10;
  static const double _padTop = 8;
  static const double _padBottom = 6;
  static const double _ringGap = 3;
}

// --- Move's ways ---------------------------------------------------------------

/// One of [LedgerWays]: its glyph, its [title] in the serif and the [text]
/// under it (what it moves, or what waits).
///
/// ```dart
/// LedgerWay(icon: LucideIcons.arrowRightLeft, title: 'Transfer', text: 'Between your accounts', onTap: () {})
/// ```
class LedgerWay {
  /// A way titled [title] with its [icon] and [text].
  const LedgerWay({
    required this.icon,
    required this.title,
    required this.text,
    this.onTap,
    this.key,
  });

  /// The way's glyph.
  final IconData icon;

  /// The way's name, in the serif.
  final String title;

  /// What the way moves, or what waits.
  final String text;

  /// Opens the way.
  final VoidCallback? onTap;

  /// The way's own key (its press target).
  final Key? key;
}

/// The ways to move money, large (`.bigs`): under an ink rule, two to a
/// line on a phone (each its glyph ringed in the ink beside its title in
/// the serif 24, its words under both, ruled apart), four in a line from
/// 1024 (the glyph over the title over the words); from 600 each at most
/// [cell] across, from the column's start. Each way is one link.
///
/// ```dart
/// LedgerWays(ways: const [LedgerWay(icon: LucideIcons.arrowRightLeft, title: 'Transfer', text: 'Between your accounts')])
/// ```
class LedgerWays extends StatelessWidget {
  /// The [ways], laid out for the window.
  const LedgerWays({
    required this.ways,
    this.semanticLabel = 'Ways to move money',
    super.key,
  });

  /// The ways, in order.
  final List<LedgerWay> ways;

  /// What a screen reader says the group is.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    // Four to a line from 1024, two on a phone, none left alone on its
    // line (three stand one per line on a phone, on one line from 1024).
    // At a large text size, half as many: a way's title is never broken.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final larger = scale > 1;
    final perLine = ledgerPerLine(
      ways.length,
      wide ? (larger ? 2 : 4) : (larger ? 1 : 2),
    );
    final lines = [
      for (var i = 0; i < ways.length; i += perLine)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + perLine; j++)
                Expanded(
                  child: j < ways.length
                      ? _way(t, ways[j], j % perLine, perLine, wide)
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
    ];
    final band = Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.headRule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: lines,
      ),
    );
    // From 600 the band keeps to its ways' measure, each [cell] wide at
    // most, from the column's start: a wide column never draws them as
    // banners. A phone's share its width.
    final measured =
        MediaQuery.sizeOf(context).width >= LedgerLayout.measuredFrom &&
        !LedgerNarrowScope.isIn(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: measured
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: perLine * cell * (larger ? scale : 1),
                ),
                child: band,
              ),
            )
          : band,
    );
  }

  /// The most a way takes across from 600.
  static const double cell = 208;

  Widget _way(LedgerThemeData t, LedgerWay w, int at, int perLine, bool wide) {
    final first = at == 0;
    final last = at == perLine - 1;
    final ring = wide ? _deskRing : _ring;
    final glyph = Container(
      width: ring,
      height: ring,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: t.textPrimary),
      ),
      child: Icon(
        w.icon,
        size: wide ? _deskGlyph : _glyph,
        color: t.textPrimary,
      ),
    );
    final title = Text(w.title, style: t.barTitle.line(_titleLine));
    final words = Text(w.text, style: t.bodySmall.colored(t.textTertiary));
    // Start and end, not left and right: in a right-to-left page the rule
    // between two ways still parts them rather than close the row.
    final EdgeInsetsDirectional pad;
    final Widget body;
    if (wide) {
      // `.big` from 1024: 20 18 18, the first's start 0 and the last's end.
      pad = EdgeInsetsDirectional.fromSTEB(
        first ? 0 : _deskSide,
        _deskTop,
        last ? 0 : _deskSide,
        _deskBottom,
      );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _deskGap,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: _deskRingBelow),
            child: glyph,
          ),
          title,
          words,
        ],
      );
    } else {
      // `.big:nth-child(odd)` keeps 14 at its end, `(even)` 16 at its start.
      pad = EdgeInsetsDirectional.fromSTEB(
        first ? 0 : _evenStart,
        _top,
        last ? 0 : _oddEnd,
        _bottom,
      );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _rowGap,
        children: [
          Row(
            spacing: _colGap,
            children: [
              glyph,
              Expanded(child: title),
            ],
          ),
          words,
        ],
      );
    }
    return LedgerPressable(
      key: w.key,
      onTap: w.onTap,
      role: LedgerPressRole.link,
      label: '${w.title}, ${w.text}',
      child: Container(
        padding: pad,
        decoration: BoxDecoration(
          border: BorderDirectional(
            bottom: BorderSide(color: t.border),
            end: last ? BorderSide.none : BorderSide(color: t.border),
          ),
        ),
        child: body,
      ),
    );
  }

  // `.big`: 16 0 14, columns 36 and the rest 10 apart, rows 6; the odd's
  // end 14, the even's start 16; `.ring` 36, its glyph 17; `.big-t` 400
  // 24/26 serif. From 1024: 20 18 18, 3 apart, `.ring` 44 with 10 under,
  // its glyph 19.
  static const double _top = 16;
  static const double _bottom = 14;
  static const double _oddEnd = 14;
  static const double _evenStart = 16;
  static const double _colGap = 10;
  static const double _rowGap = 6;
  static const double _ring = 36;
  static const double _glyph = 17;
  static const double _titleLine = 26;
  static const double _deskTop = 20;
  static const double _deskSide = 18;
  static const double _deskBottom = 18;
  static const double _deskGap = 3;
  static const double _deskRing = 44;
  static const double _deskRingBelow = 10;
  static const double _deskGlyph = 19;
}

// --- Allocation and holdings ---------------------------------------------------

/// One kind of an allocation (`.alloc-row`): its hatched swatch (the
/// [tone] its part wears in the [LedgerStackBar] over it), its [name] on
/// the leader to its [amount], and its [share] of the whole in the quiet
/// mono, 11 above and below. Stand them in `LedgerRows` under the bar.
///
/// ```dart
/// LedgerAllocationRow(tone: LedgerStackTone.ink, name: 'Stocks', amount: 39432.60, share: '80.6%')
/// ```
class LedgerAllocationRow extends StatelessWidget {
  /// A kind named [name] holding [amount], swatched in [tone].
  const LedgerAllocationRow({
    required this.tone,
    required this.name,
    required this.amount,
    required this.share,
    super.key,
  });

  /// The tone the kind's part wears in the stack bar.
  final LedgerStackTone tone;

  /// The kind's name.
  final String name;

  /// What the kind holds.
  final num amount;

  /// Its share of the whole, as the page writes it ("80.6%").
  final String share;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final pct = t.amount
        .sized(_pct)
        .tracked(0)
        .line(_line)
        .copyWith(fontWeight: FontWeight.w400)
        .colored(t.textTertiary);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _pad),
        child: Row(
          spacing: _gap,
          children: [
            ExcludeSemantics(
              child: CustomPaint(
                size: const Size.square(_swatch),
                painter: _AllocSwatch(tone, t),
              ),
            ),
            Expanded(
              // The sans, the mono and the share on one baseline stand
              // 20.96 tall: held to a whole pixel, as every row.
              child: LedgerWholeHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: _gap,
                  children: [
                    Expanded(
                      child: LedgerLeaderLine(
                        // `.alloc-row .leader { margin: 0 }`: the row's 10
                        // gap.
                        inset: _gap,
                        start: Text(name, style: t.rowTitle),
                        end: LedgerAmount(amount),
                      ),
                    ),
                    // At a large text size the share grows past its 52
                    // rather than break inside its figure.
                    if (MediaQuery.textScalerOf(context).scale(1) > 1)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: _pctWidth),
                        child: Text(
                          share,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.right,
                          style: pct,
                        ),
                      )
                    else
                      SizedBox(
                        width: _pctWidth,
                        child: Text(
                          share,
                          textAlign: TextAlign.right,
                          style: pct,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // `.alloc-row`: 11 0, 10 apart; `.sw-alloc` 12 square; `.alloc-pct` 52
  // wide, 400 12/20 mono.
  static const double _pad = 11;
  static const double _gap = 10;
  static const double _swatch = 12;
  static const double _pct = 12;
  static const double _line = 20;
  static const double _pctWidth = 52;
}

/// `.sw-ink`, `.sw-green`, `.sw-pale`: a 1 px frame round CSS's repeating
/// stripes (120° 0 .7 of 2.6; 60° .7 of 3 in the green; 120° .6 of 4.4 in
/// the faint ink).
class _AllocSwatch extends CustomPainter {
  _AllocSwatch(this.tone, this.t);

  final LedgerStackTone tone;
  final LedgerThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final (deg, period, width, color) = switch (tone) {
      LedgerStackTone.ink => (120.0, 2.6, .7, t.textPrimary),
      LedgerStackTone.green => (60.0, 3.0, .7, t.pace),
      LedgerStackTone.pale => (120.0, 4.4, .6, t.textFaint),
    };
    final a = deg * math.pi / 180;
    final u = Offset(math.sin(a), -math.cos(a));
    final half = (box.width * u.dx.abs() + box.height * u.dy.abs()) / 2;
    final start = box.center - u * half;
    final across = Offset(-u.dy, u.dx) * (box.width + box.height);
    final paint = ledgerStroke(color, width);
    canvas
      ..save()
      ..clipRect(box);
    for (var d = width / 2; d < 2 * half + width; d += period) {
      final c = start + u * d;
      canvas.drawLine(c - across, c + across, paint);
    }
    canvas
      ..restore()
      ..drawRect(box.deflate(.5), ledgerStroke(color, 1));
  }

  @override
  bool shouldRepaint(_AllocSwatch old) => old.tone != tone || old.t != t;
}

/// One fund of a portfolio (`.holding`): its monogram, its [name] over
/// its [symbol] and [shares], its [value] over what it moved [today]
/// (green when it rose). From 1024 one line: name, symbol, [kind],
/// shares, value and today in their columns under [LedgerHoldings]'
/// heads. Stand them in [LedgerHoldings].
///
/// ```dart
/// LedgerHoldingRow(name: 'Keel Total Market', symbol: 'KTMX', kind: 'Stocks', shares: '182.4 shares', value: 26410.20, today: 262.10)
/// ```
class LedgerHoldingRow extends StatelessWidget {
  /// A fund named [name] ([symbol]) worth [value].
  const LedgerHoldingRow({
    required this.name,
    required this.symbol,
    required this.kind,
    required this.shares,
    required this.value,
    required this.today,
    this.initials,
    super.key,
  });

  /// The fund's name.
  final String name;

  /// The fund's ticker symbol.
  final String symbol;

  /// The fund's kind (Stocks, Bonds, Cash), shown from 1024.
  final String kind;

  /// Its shares as the page writes them ("182.4 shares", "Settled cash").
  final String shares;

  /// What the holding is worth.
  final num value;

  /// What the holding moved today; green when it rose.
  final num today;

  /// The monogram's letters, when not the name's own.
  final String? initials;

  // A table's row where the holdings stand as one (LedgerHoldings.tableIn);
  // a phone's two lines where the room is short of it.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) =>
        _build(context, LedgerHoldings.tableIn(context, c.maxWidth)),
  );

  Widget _build(BuildContext context, bool wide) {
    final t = context.ledgerTheme;
    final mark = LedgerMonogram(name, initials: initials);
    // At a large text size the two lines grow rather than cut their words:
    // the name wraps whole, the symbol and the shares stand on their line
    // or turn under one another.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final title = larger
        ? Text(name, style: t.rowTitle)
        : Text(
            name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: t.rowTitle,
          );
    final moved = _Today(today);
    final worth = LedgerAmount(value, textAlign: TextAlign.right);
    final Widget row;
    if (wide) {
      final quiet = t.body.sized(_deskWords).colored(t.textSecondary);
      final sym = t.amount
          .sized(_deskSymbol)
          .tracked(0)
          .copyWith(fontWeight: FontWeight.w400, height: quiet.height)
          .colored(t.textSecondary);
      Widget cell(double w, Widget child) => SizedBox(width: w, child: child);
      row = Padding(
        padding: const EdgeInsets.symmetric(vertical: _deskPad),
        child: Row(
          spacing: _deskGap,
          children: [
            mark,
            Expanded(child: title),
            for (final (w, words, style) in [
              (LedgerHoldings._symbol, symbol, sym),
              (LedgerHoldings._kind, kind, quiet),
              (LedgerHoldings._shares, shares, quiet),
            ])
              cell(
                w,
                Text(
                  words,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            cell(LedgerHoldings._value, worth),
            cell(
              LedgerHoldings._today,
              Align(alignment: AlignmentDirectional.centerEnd, child: moved),
            ),
          ],
        ),
      );
    } else {
      final sub = t.bodySmall.colored(t.textTertiary);
      final sym = t.amount
          .sized(_symbol)
          .tracked(0)
          .line(sub.fontSize! * sub.height!)
          .copyWith(fontWeight: FontWeight.w400)
          .colored(t.textSecondary);
      row = Padding(
        padding: const EdgeInsets.symmetric(vertical: _pad),
        child: Row(
          spacing: _gap,
          children: [
            mark,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  if (larger)
                    Wrap(
                      spacing: _symbolGap,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(symbol, style: sym),
                        Text(shares, style: sub),
                      ],
                    )
                  else
                    // The sub's 18 stands centred in `.h-sub`'s line, the
                    // row's body strut (15 on 1.45): the live `.holding` is
                    // 70.75, 14 + 20 + 21.75 + 14 and its rule; here 71, the
                    // line the whole 22 a Text of the body takes.
                    SizedBox(
                      height: _subLine,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          spacing: _symbolGap,
                          children: [
                            Text(symbol, style: sym),
                            Flexible(
                              child: Text(
                                shares,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // At a large text size the worth turns under the name,
                  // at the line's end, leaving the name the whole line.
                  if (larger)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [worth, moved],
                      ),
                    ),
                ],
              ),
            ),
            if (!larger)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [worth, moved],
              ),
          ],
        ),
      );
    }
    return MergeSemantics(child: row);
  }

  // `.row` 14 0, 14 apart; `.h-sub .mono` 11, 6 before the shares; the title's
  // line 20, the sub's 22 (21.75 in the browser). From 1024: 12 0, 16 apart;
  // `.h-sym` mono 12, the rest 14.
  static const double _pad = 14;
  static const double _gap = 14;
  static const double _subLine = 22;
  static const double _symbol = 11;
  static const double _symbolGap = 6;
  static const double _deskPad = 12;
  static const double _deskGap = 16;
  static const double _deskSymbol = 12;
  static const double _deskWords = 14;
}

/// What a fund moved today (`.h-today .amt`): the mono amount at 12 on 20,
/// signed, green when it rose, quiet when it held.
class _Today extends StatelessWidget {
  const _Today(this.amount);

  final num amount;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // `amt(h['today'], 'in' if h['today'] > 0 else 'move', sign=True)`.
    final tone = amount > 0 ? LedgerTone.moneyIn : LedgerTone.move;
    final inks = t.inks(tone);
    final base = t.amount;
    final style = base
        .sized(_size)
        .line(base.fontSize! * base.height!)
        .copyWith(
          fontWeight: tone == LedgerTone.move
              ? FontWeight.w400
              : FontWeight.w500,
          color: inks.ink,
        );
    final parts = LedgerFormat.moneyParts(amount, showSign: true);
    return Semantics(
      label: '${LedgerFormat.money(amount, showSign: true)} today',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: '${parts.sign}\$${parts.whole}'),
            TextSpan(
              text: '.${parts.cents}',
              style: TextStyle(color: inks.cents, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  // `.holding .h-today .amt { font-size: 12px }` on the amount's 20.
  static const double _size = 12;
}

/// A portfolio's funds (`.holdings`): from 1024 the column heads over
/// them (Fund, Symbol, Kind, Shares, Value, Today, the last two at their
/// ends) on a rule; then its [rows], the hairline between each.
///
/// ```dart
/// LedgerHoldings(rows: const [LedgerHoldingRow(name: 'Cash', symbol: 'CASH', kind: 'Cash', shares: 'Settled cash', value: 2152, today: 0)])
/// ```
class LedgerHoldings extends StatelessWidget {
  /// A portfolio's [rows] under their column heads.
  const LedgerHoldings({
    required this.rows,
    this.heads = const ['Fund', 'Symbol', 'Kind', 'Shares', 'Value', 'Today'],
    super.key,
  });

  /// The funds, usually [LedgerHoldingRow]s.
  final List<Widget> rows;

  /// The six column heads from 1024, set in capitals.
  final List<String> heads;

  /// Whether holdings [width] wide stand as the table: from 1024, where
  /// the five set columns, the mark and their gaps (720) leave the fund's
  /// name 160 at least; short of that (a column beside the side bar at
  /// 1024), or at a large text size (the set columns would cut their
  /// words), each row takes a phone's two lines.
  static bool tableIn(BuildContext context, double width) =>
      LedgerLayout.isWide(context) &&
      width >= _tableFrom &&
      MediaQuery.textScalerOf(context).scale(1) <= 1;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => _build(context, tableIn(context, c.maxWidth)),
  );

  Widget _build(BuildContext context, bool wide) {
    final t = context.ledgerTheme;
    Widget head(int i, {bool end = false}) => Text(
      i < heads.length ? heads[i].toUpperCase() : '',
      maxLines: 1,
      softWrap: false,
      textAlign: end ? TextAlign.right : null,
      style: t.meta,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide)
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.only(bottom: _headPad),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border)),
              ),
              child: Row(
                spacing: LedgerHoldingRow._deskGap,
                children: [
                  const SizedBox(width: _mark),
                  Expanded(child: head(0)),
                  SizedBox(width: _symbol, child: head(1)),
                  SizedBox(width: _kind, child: head(2)),
                  SizedBox(width: _shares, child: head(3)),
                  SizedBox(width: _value, child: head(4, end: true)),
                  SizedBox(width: _today, child: head(5, end: true)),
                ],
              ),
            ),
          ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            ColoredBox(color: t.hairline, child: const SizedBox(height: 1)),
          rows[i],
        ],
      ],
    );
  }

  // `.colheads-h`: 40 1fr 96 104 132 132 120, 16 apart, 0 0 8 on a rule.
  static const double _headPad = 8;
  static const double _mark = 40;
  static const double _symbol = 96;
  static const double _kind = 104;
  static const double _shares = 132;
  static const double _value = 132;
  static const double _today = 120;

  // DERIVED: the table's set columns and six gaps (720), the name 160.
  static const double _tableFrom =
      _mark + _symbol + _kind + _shares + _value + _today + 6 * 16 + 160;
}

// --- A row of two acts -----------------------------------------------------------

/// Two acts side by side (`.form-actions-row`): each [children] item half
/// the row, 12 apart (a sent transfer's Back to Home and View transfer).
/// Give it `LedgerButton`s with `expand: true`.
///
/// ```dart
/// LedgerButtonRow(children: [LedgerButton.filled('Back to Home', icon: LucideIcons.house, expand: true, onPressed: () {}), LedgerButton('View transfer', icon: LucideIcons.receipt, expand: true, onPressed: () {})])
/// ```
class LedgerButtonRow extends StatelessWidget {
  /// Two acts side by side.
  const LedgerButtonRow({required this.children, super.key});

  /// The acts, each taking half the row.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LedgerLayout.atMeasure(
    context,
    // From 600 each act at most the measure: the row stands at the start
    // of its slot, never stretched across a wide column.
    most:
        children.length * LedgerLayout.fieldMeasure +
        (children.length - 1) * _gap,
    // Where an act's words would not fit its half, the two stand one
    // above the other, the first on top, rather than cut.
    LedgerButtonEnds(
      child: LedgerEvenActs(gap: _gap, lastOnTop: false, children: children),
    ),
  );

  // `.form-actions { gap: 12px }`, `.form-actions-row .btn { flex: 1;
  // padding: 0 16px }` (the 16 through LedgerButtonEnds).
  static const double _gap = 12;
}
