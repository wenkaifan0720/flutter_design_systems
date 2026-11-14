import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/key_focus.dart';
import '../../internal/own_size.dart';
import '../../internal/press_face.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../avatar/avatar.dart';
import '../pressable/pressable.dart';
import '../money/money.dart';
import '../../localizations.dart';
import '../../internal/dim.dart';
import '../../internal/rest_ring.dart';
import '../../internal/cap.dart';

/// How large a mark stands: a row's (36, `.mono`, `.tok`), a ticket's or a
/// browse card's (32), a record's (56, `.mono--lg`, `.tok--lg`).
enum FrostedMarkSize {
  /// 32 across, corners 10, its glyph 16 and its letters 12.
  small(
    FrostedChromeMetrics.markSmall,
    FrostedChromeMetrics.markSmallRadius,
    FrostedChromeMetrics.markSmallGlyph,
    FrostedChromeMetrics.markSmallType,
  ),

  /// 36 across, corners 11, its glyph 18 and its letters 13.
  regular(
    FrostedChromeMetrics.mark,
    FrostedChromeMetrics.markRadius,
    FrostedChromeMetrics.markGlyph,
    FrostedChromeMetrics.markType,
  ),

  /// 56 across, corners 17, its glyph 24 and its letters 20.
  large(
    FrostedChromeMetrics.markLarge,
    FrostedChromeMetrics.markLargeRadius,
    FrostedChromeMetrics.markLargeGlyph,
    FrostedChromeMetrics.markLargeType,
  );

  const FrostedMarkSize(this.side, this.radius, this.glyph, this.type);

  /// How wide the mark is.
  final double side;

  /// Its corner.
  final double radius;

  /// Its glyph's size.
  final double glyph;

  /// Its letters' size.
  final double type;
}

/// The tinted squircle a monogram or a token sits on: the hue's small
/// solid with its hairline inside the edge, or the wash with no edge when
/// there is no hue (`.mono`, `.tok`; `.tok--q`).
class _Squircle extends StatelessWidget {
  const _Squircle({required this.size, required this.hue, required this.child});

  final FrostedMarkSize size;
  final FrostedHue? hue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return SizedBox.square(
      dimension: size.side,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(size.radius),
        color: hue?.tintSolid ?? t.glass.wash,
        ring: hue?.edge,
        child: Center(child: child),
      ),
    );
  }
}

/// A merchant's or a payer's monogram (logo): the initials from [name] on
/// a squircle of the category's [hue] (its small solid, its hairline, its
/// ink for the letters), or on the wash in the tertiary ink when the hue is
/// null. 36 in a row, 32 on a ticket, 56 on a record. Read aloud as
/// [label], else as the name.
///
/// ```dart
/// FrostedMonogram('Blue Fern Café', hue: context.frostedTheme.hues.coral)
/// ```
class FrostedMonogram extends StatelessWidget {
  /// Creates a [FrostedMonogram].
  const FrostedMonogram(
    this.name, {
    this.hue,
    this.size = FrostedMarkSize.regular,
    this.label,
    super.key,
  });

  /// Whose monogram it is: the merchant's or the payer's name.
  final String name;

  /// The hue it is set in; null is the quiet mark on the wash.
  final FrostedHue? hue;

  /// How large it stands.
  final FrostedMarkSize size;

  /// What a screen reader says; null says the name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      label: label ?? name,
      image: true,
      child: ExcludeSemantics(
        child: _Squircle(
          size: size,
          hue: hue,
          child: frostedCapCentred(
            Text(
              FrostedFormat.initials(name),
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              // `.mono`: 600 13/1 in the display face.
              style: t.textTheme.monogram
                  .at(size.type)
                  .copyWith(height: 1)
                  .c(hue?.ink ?? t.colorScheme.textTertiary),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glyph on a tinted squircle (icon-tile): an account's, a goal's or a
/// category's mark in its [hue] (the glass of its small solid, its hairline,
/// the Lucide glyph in its ink), 36 in a row, 32 on a browse card, 56 on a
/// record. [quiet] is the plain token (`.tok--q`): the wash, the tertiary
/// ink, no hairline, its glyph 16. Read aloud as [label]; without one it
/// is decoration beside the words that name it.
///
/// ```dart
/// FrostedIconMark(FrostedGlyphs.wallet, hue: context.frostedTheme.hues.cyan, label: 'Everyday')
/// ```
class FrostedIconMark extends StatelessWidget {
  /// Creates a [FrostedIconMark].
  const FrostedIconMark(
    this.icon, {
    this.hue,
    this.size = FrostedMarkSize.regular,
    this.quiet = false,
    this.label,
    super.key,
  });

  /// The glyph, from the Lucide set.
  final IconData icon;

  /// The hue it is set in; null is the mark on the wash.
  final FrostedHue? hue;

  /// How large it stands.
  final FrostedMarkSize size;

  /// The plain token: the wash, the tertiary ink, no hairline.
  final bool quiet;

  /// What a screen reader says; null leaves it out as decoration.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final tinted = quiet ? null : hue;
    final token = _Squircle(
      size: size,
      hue: tinted,
      child: Icon(
        icon,
        size: quiet ? FrostedChromeMetrics.markSmallGlyph : size.glyph,
        color: tinted?.ink ?? t.colorScheme.textTertiary,
      ),
    );
    if (label == null) return ExcludeSemantics(child: token);
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(child: token),
    );
  }
}

/// A date as a block (date-block): the month over the day on a 40 by 44
/// round of the wash, as a bill's row leads (`.date`). [soon] with its
/// [hue] is a bill due within days: the hue's small solid, its hairline, its
/// ink for both lines (the month at 0.75). Read aloud as the date.
///
/// ```dart
/// FrostedDateBlock(DateTime(2026, 11, 1))
/// ```
///
/// ```dart
/// FrostedDateBlock(DateTime(2026, 11, 1), soon: true, hue: context.frostedTheme.hues.periwinkle)
/// ```
class FrostedDateBlock extends StatelessWidget {
  /// Creates a [FrostedDateBlock].
  const FrostedDateBlock(this.date, {this.soon = false, this.hue, super.key});

  /// The day it shows.
  final DateTime date;

  /// Whether the date is close: the block takes its hue.
  final bool soon;

  /// The hue of what is due; read only when [soon].
  final FrostedHue? hue;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final lit = soon ? hue : null;
    return Semantics(
      label: FrostedFormat.date(date),
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.fromSize(
          size: FrostedChromeMetrics.dateBlock,
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.dateBlockRadius),
            color: lit?.tintSolid ?? t.glass.wash,
            ring: lit?.edge,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: FrostedChromeMetrics.dateGap,
              children: [
                // `.date b`: 500 12/1 in the text face, the tertiary ink
                // (the hue's ink at 0.75 when soon).
                Text(
                  FrostedFormat.month(date, short: true),
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: t.textTheme.labelMedium
                      .copyWith(height: 1)
                      .c(
                        lit == null
                            ? t.colorScheme.textTertiary
                            : lit.ink.withValues(alpha: 0.75),
                      ),
                ),
                // `.date span`: 500 16/1 in the display face, -.01em.
                Text(
                  '${date.day}',
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: t.textTheme.titleLarge.medium
                      .copyWith(height: 1)
                      .tracked(-0.01)
                      .c(lit?.ink ?? t.colorScheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A transaction's leading mark (icon-tile), by what the money did: a
/// purchase is the merchant's monogram in its category's hue, money in the
/// payer's in the green, a move between the owner's own accounts the
/// arrows' token in the quiet grey of a move, a card payment the card's.
///
/// ```dart
/// FrostedTransactionMark.purchase('Blue Fern Café', hue: context.frostedTheme.hues.coral)
/// ```
///
/// ```dart
/// FrostedTransactionMark.move()
/// ```
class FrostedTransactionMark extends StatelessWidget {
  /// A purchase from [name], in its category's [hue].
  const FrostedTransactionMark.purchase(
    String this.name, {
    required FrostedHue this.hue,
    this.size = FrostedMarkSize.regular,
    super.key,
  }) : _kind = _MarkKind.purchase;

  /// Money in from [name], in the green of money in.
  const FrostedTransactionMark.income(
    String this.name, {
    this.size = FrostedMarkSize.regular,
    super.key,
  }) : _kind = _MarkKind.income,
       hue = null;

  /// A move between the owner's own accounts: the arrows.
  const FrostedTransactionMark.move({
    this.size = FrostedMarkSize.regular,
    super.key,
  }) : _kind = _MarkKind.move,
       name = null,
       hue = null;

  /// A payment to the owner's card.
  const FrostedTransactionMark.payment({
    this.size = FrostedMarkSize.regular,
    super.key,
  }) : _kind = _MarkKind.payment,
       name = null,
       hue = null;

  final _MarkKind _kind;

  /// The merchant or the payer.
  final String? name;

  /// The mark's hue; null is the quiet glass.
  final FrostedHue? hue;

  /// How large it stands.
  final FrostedMarkSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return switch (_kind) {
      _MarkKind.purchase => FrostedMonogram(name!, hue: hue, size: size),
      _MarkKind.income => FrostedMonogram(
        name!,
        hue: t.hues.emerald,
        size: size,
      ),
      _MarkKind.move => FrostedIconMark(
        FrostedGlyphs.arrowLeftRight,
        hue: t.hues.slate,
        size: size,
        label: FrostedLocalizations.of(context).move,
      ),
      _MarkKind.payment => FrostedIconMark(
        FrostedGlyphs.creditCard,
        hue: t.hues.slate,
        size: size,
        label: FrostedLocalizations.of(context).cardPayment,
      ),
    };
  }
}

enum _MarkKind { purchase, income, move, payment }

/// What a [FrostedTag] stands on.
enum FrostedTagVariant {
  /// `.chip`: the wash (or its tone's tint) on the page.
  wash,

  /// `.glass`: the card's pill, glass with a light ring inside its hairline
  /// (the theme's sheens: white glass on the day's pearl, a dark glass on
  /// the night's smoked one).
  glass,
}

/// A small statement (tag): a 24 pill of words in the text face, 10 in,
/// with an optional glyph before them; the wash in the secondary ink by
/// default, or its [tone]'s tint and ink (money in's green, over budget's
/// red, the warning's amber, a frozen card's cold). [figure] sets figures
/// after the words at 14 in the display face ("13 results"), [lead]
/// figures before them ("+$73.42 interest in October", or with [figure]
/// round a dot: "$1,259.82 · 0.53%"), 4 apart as `.chip`'s gap sets them.
/// It states; it does not act. Read aloud as its words.
///
/// ```dart
/// FrostedTag('On track', icon: FrostedGlyphs.check, tone: FrostedTone.success)
/// ```
///
/// ```dart
/// FrostedTag('·', lead: '\$1,259.82', figure: '0.53%', icon: FrostedGlyphs.arrowUpRight, tone: FrostedTone.success)
/// ```
///
/// ```dart
/// FrostedTag('Credit', variant: FrostedTagVariant.glass)
/// ```
class FrostedTag extends StatelessWidget {
  /// Creates a [FrostedTag].
  const FrostedTag(
    this.label, {
    this.icon,
    this.tone = FrostedTone.quiet,
    this.variant = FrostedTagVariant.wash,
    this.figure,
    this.lead,
    super.key,
  });

  /// The tag's words.
  final String label;

  /// A glyph before the words; null for none.
  final IconData? icon;

  /// Its tone (info, success, warning, danger).
  final FrostedTone tone;

  /// Its face.
  final FrostedTagVariant variant;

  /// Figures after the words, in the display face at 14.
  final String? figure;

  /// Figures before the words, in the display face at 14.
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final glass = variant == FrostedTagVariant.glass;
    final ink = glass ? t.pearl.textSecondary : t.toneInk(tone);
    final words = t.textTheme.labelSmall.copyWith(height: 1).c(ink);
    return Semantics(
      label: [?lead, label, ?figure].join(' '),
      excludeSemantics: true,
      child: SizedBox(
        height: FrostedChromeMetrics.chipHeight,
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(FrostedChromeMetrics.chipHeight / 2),
          color: glass ? t.sheens.pillFill : t.toneTint(tone),
          ring: glass ? t.sheens.pillRing : null,
          shadows: glass
              ? [BoxShadow(color: t.sheens.pillEdge, spreadRadius: 1)]
              : const <BoxShadow>[],
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedChromeMetrics.chipInset,
          ),
          // A tag keeps its size at large text, its figures with its words
          // (a "13" at 200% stood out of its pill beside a 100% "results").
          child: MediaQuery.withNoTextScaling(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedChromeMetrics.chipGap,
              children: [
                if (icon != null)
                  Icon(icon, size: FrostedChromeMetrics.chipGlyph, color: ink),
                if (lead != null)
                  // `.chip .num` first: the figures lead the words.
                  FrostedNumberText(lead!, style: words.at(14)),
                Text(label, maxLines: 1, softWrap: false, style: words),
                if (figure != null)
                  // `.chip .num`: the figures a size up, in the display face.
                  FrostedNumberText(figure!, style: words.at(14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A swatch of a hue: an 8 round of its two stops at 135 degrees (`.sw`),
/// before a legend's name; [part] is the quiet share of a split (`.sw--
/// part`): the hue's small solid in its hairline. Decoration.
///
/// ```dart
/// FrostedSwatch(context.frostedTheme.hues.orchid)
/// ```
class FrostedSwatch extends StatelessWidget {
  /// Creates a [FrostedSwatch].
  const FrostedSwatch(
    this.hue, {
    this.size = FrostedChromeMetrics.swatch,
    this.part = false,
    super.key,
  });

  /// The swatch's hue.
  final FrostedHue hue;

  /// How wide it is.
  final double size;

  /// The quiet share: the small solid in its hairline instead of the stops.
  final bool part;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: part ? null : hue.dot,
          color: part ? hue.tintSolid : null,
          border: part ? Border.all(color: hue.edge) : null,
        ),
      ),
    ),
  );
}

/// A person to send to or split with (avatar): their initials on the 52
/// pearl over their first name, and an optional [note] under it (what they
/// owe). [selected] rings the pearl in white and ink and lights the name;
/// [dimmed] steps the pearl back (one not chosen in a pick). With
/// [onChanged] a tap turns the choice; without, they are a picture.
///
/// ```dart
/// FrostedPerson('Jonah Reyes', selected: picked == 'jonah', onChanged: (_) => pick('jonah'))
/// ```
class FrostedPerson extends StatelessWidget {
  /// Creates a [FrostedPerson].
  const FrostedPerson(
    this.name, {
    this.note,
    this.selected = false,
    this.dimmed = false,
    this.onChanged,
    super.key,
  });

  /// Their full name; the first word is shown.
  final String name;

  /// A line under the name.
  final String? note;

  /// Whether the person is chosen (ringed).
  final bool selected;

  /// Whether the person is set back.
  final bool dimmed;

  /// Turns the choice; null makes the person a picture.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final first = name.trim().split(RegExp(r'\s+')).first;
    // `.person-n`: 500 12/1.2 in the secondary ink; chosen, the page ink
    // at 600.
    var nameStyle = t.textTheme.labelSmall
        .copyWith(height: 1.2)
        .c(t.colorScheme.textSecondary);
    if (selected) nameStyle = nameStyle.semibold.c(t.colorScheme.textPrimary);
    final Widget person = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.personGap,
      children: [
        // One not chosen steps back in its pearl; its words keep their ink
        // (the source dims the whole person to 0.55, which put a name that
        // still takes a press under 4.5:1, law 8).
        Opacity(
          opacity: dimmed ? FrostedChromeMetrics.personDimOpacity : 1,
          child: FrostedAvatar(
            FrostedFormat.initials(name),
            size: FrostedAvatarSize.large,
            selected: selected,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: nameStyle,
            ),
            if (note != null)
              Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: t.textTheme.bodySmall,
              ),
          ],
        ),
      ],
    );
    final spoken = note == null ? name : '$name, $note';
    if (onChanged == null) {
      return Semantics(
        label: spoken,
        selected: selected,
        child: ExcludeSemantics(child: person),
      );
    }
    return FrostedPressable(
      onPressed: () => onChanged!(!selected),
      label: spoken,
      selected: selected,
      radius: FrostedChromeMetrics.avatarLarge / 2,
      child: person,
    );
  }
}

/// A row of [FrostedPerson]s across the width, 8 apart, each given an equal
/// share (`.people`).
///
/// ```dart
/// FrostedPeople(children: [FrostedPerson('Jonah Reyes'), FrostedPerson('Ines Park')])
/// ```
class FrostedPeople extends StatelessWidget {
  /// Creates a [FrostedPeople].
  const FrostedPeople({required this.children, super.key});

  /// The people, in order.
  final List<FrostedPerson> children;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FrostedChromeMetrics.peopleGap,
    children: [for (final person in children) Expanded(child: person)],
  );
}

/// A completion check: the 24 round an option wears (`.opt-c`), a ring of
/// the strong hairline at rest and the ink act with a white tick once it is
/// done (a white dash when [value] is null, the mixed state of a check over
/// several). With [onChanged] a press, Enter or Space flips it; without, it
/// is a mark that only reports. [label] is what a screen reader calls it;
/// [error] draws the ring in the over ink and says so. The ring at rest is
/// drawn from the tokens: the source draws nothing there.
///
/// ```dart
/// FrostedCheckbox(value: kept, label: 'Walk 5,000 steps', onChanged: (v) => setState(() => kept = v!))
/// ```
class FrostedCheckbox extends StatelessWidget {
  /// Creates a [FrostedCheckbox].
  const FrostedCheckbox({
    required this.value,
    required this.label,
    this.onChanged,
    this.error = false,
    this.tristate = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(tristate || value != null, 'Only a tristate check is mixed.');

  /// Whether the thing is done; null is the mixed state, for a check that
  /// stands over several.
  final bool? value;

  /// What a press does with the new state; null disables the check (drawn
  /// off and announced disabled), as Flutter's `Checkbox`.
  /// It reports true from the mixed state, and with [tristate] it goes
  /// round false, true, null.
  final ValueChanged<bool?>? onChanged;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// What the thing is, for a screen reader.
  final String label;

  /// Whether what it stands for is wrong as it is (a term not agreed to).
  final bool error;

  /// Whether a press may leave it mixed, as `Checkbox(tristate:)` does.
  final bool tristate;

  /// This check's own style, over `FrostedThemeData.components.checkbox`:
  /// its fill (in place of the ink act; selected while done), the tick's
  /// colour and size (foreground, icon size), the ring's colour or whole
  /// side at rest, and its shape, each per state.
  ///
  /// ```dart
  /// FrostedCheckbox(
  ///   value: kept,
  ///   label: 'Walk 5,000 steps',
  ///   onChanged: keep,
  ///   style: const FrostedStyle(
  ///     shape: WidgetStatePropertyAll(
  ///       RoundedRectangleBorder(
  ///         borderRadius: BorderRadius.all(Radius.circular(6)),
  ///       ),
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  bool? get _next => switch (value) {
    false => true,
    true => tristate ? null : false,
    null => tristate ? false : true,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final live = onChanged != null;
    void flip() => onChanged?.call(_next);
    final motion = FrostedMotion.of(context);
    final duration = motion.fast;
    final on = value ?? true;
    final s = FrostedStyleLayers(style, t.components.checkbox, {
      if (on) WidgetState.selected,
      if (error) WidgetState.error,
      if (!live) WidgetState.disabled,
    });
    final cut = s.cut(FrostedCorners.full);
    final fill = s.fill;
    // At rest the ring reads 3:1 on its ground, so an empty check is seen.
    final ring = on && !error
        ? null
        : s.side ??
              BorderSide(
                color: error
                    ? t.colorScheme.over
                    : s.edge ?? frostedRestRing(t),
                width: FrostedChromeMetrics.checkRing,
              );
    final gradient = on && fill == null ? t.colorScheme.buttonFill : null;
    // Under a finger an empty check fills with the strong hairline's ink, as
    // a done one fades: the press shows on both.
    Widget disc(bool down) => AnimatedContainer(
      duration: duration,
      curve: motion.curve,
      width: FrostedChromeMetrics.check,
      height: FrostedChromeMetrics.check,
      decoration: cut == null
          ? BoxDecoration(
              shape: BoxShape.circle,
              color: fill ?? (down && !on ? t.colorScheme.borderStrong : null),
              gradient: gradient,
              border: ring == null ? null : Border.fromBorderSide(ring),
            )
          : ShapeDecoration(
              shape: cut.copyWith(side: ring ?? BorderSide.none),
              color: fill ?? (down && !on ? t.colorScheme.borderStrong : null),
              gradient: gradient,
            ),
      child: Center(
        child: AnimatedScale(
          scale: on ? 1 : 0,
          duration: duration,
          curve: motion.curve,
          child: Icon(
            value == null ? FrostedGlyphs.remove : FrostedGlyphs.check,
            size: s.iconSize ?? FrostedChromeMetrics.checkGlyph,
            color: s.foreground ?? t.colorScheme.onButton,
          ),
        ),
      ),
    );
    // The slop is the outermost box: a parent's bounds would stop a tap
    // outside the 24 disc before it reached the slop. The node, the press
    // and the pointer span the target; the focus ring hugs the disc. A mark
    // that takes no press reaches no further than itself, so it never takes
    // a press meant for the control beside it.
    return FrostedOwnSize(
      child: FrostedHitSlop(
        target: live ? null : 0,
        child: Semantics(
          label: label,
          checked: value ?? false,
          mixed: value == null,
          enabled: live,
          focusable: live,
          onTap: live ? flip : null,
          validationResult: error
              ? SemanticsValidationResult.invalid
              : SemanticsValidationResult.none,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: live ? flip : null,
            child: FrostedPressArea(
              enabled: live,
              child: MouseRegion(
                cursor: live ? SystemMouseCursors.click : MouseCursor.defer,
                child: FrostedSlopFace(
                  child: FrostedKeyFocus(
                    focusNode: focusNode,
                    autofocus: autofocus,
                    enabled: live,
                    radius: FrostedStyleLayers.radiusOf(
                      cut,
                      FrostedChromeMetrics.check,
                      FrostedChromeMetrics.check / 2,
                    ),
                    keys: {
                      if (live) ...{
                        LogicalKeyboardKey.enter: flip,
                        LogicalKeyboardKey.space: flip,
                      },
                    },
                    child: FrostedPressedFace(
                      child: Builder(
                        builder: (context) => FrostedDim(
                          off: !live,
                          child: disc(FrostedPressArea.isDown(context)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
