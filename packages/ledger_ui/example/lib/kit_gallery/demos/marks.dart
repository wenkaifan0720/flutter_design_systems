/// The ledger's small marks: the round glyph that leads an account's,
/// a category's or a goal's row ([LedgerGlyph]: plain, a move's dashed
/// ring, the green of money in, the ink of what stops), a merchant's or a
/// person's initials in the italic serif ([LedgerMonogram]), a bill's date
/// tab ([LedgerDateTab]), a figure's change or a record's state on its wash
/// ([LedgerPill]), the word ringed after a title ([LedgerTag]) and the
/// dashes round what is not yet there ([LedgerDashedFrame]). Every word is
/// the pilot's (keel.dart, else the source line named beside it).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitMarksDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Marks',
  sections: [
    kitSection('Glyphs', children: [kitSpecimenGlyphs()]),
    kitSection('Glyph tones', children: [kitSpecimenGlyphTones()]),
    kitSection('Chosen glyph', children: [kitSpecimenGlyphChosen()]),
    kitSection(
      'Glyph sizes',
      children: [
        // Smallest to largest.
        kitRow([
          for (final size in const [
            LedgerGlyphSize.small,
            LedgerGlyphSize.dense,
            LedgerGlyphSize.pick,
            LedgerGlyphSize.row,
            LedgerGlyphSize.record,
          ])
            LedgerGlyph(LucideIcons.wallet, size: size),
        ]),
      ],
    ),
    kitSection('Monograms', children: [kitSpecimenMonograms()]),
    kitSection(
      'Monogram sizes',
      children: [
        // Smallest to largest, the person's chosen beside it.
        kitRow([
          for (final size in const [
            LedgerMonogramSize.dense,
            LedgerMonogramSize.row,
            LedgerMonogramSize.person,
          ])
            LedgerMonogram(kitBlueFern.title, size: size),
          LedgerMonogram(
            kitPaycheck.title,
            size: LedgerMonogramSize.person,
            selected: true,
          ),
          for (final size in const [
            LedgerMonogramSize.record,
            LedgerMonogramSize.member,
          ])
            LedgerMonogram(kitBlueFern.title, size: size),
        ]),
      ],
    ),
    kitSection('Inked monogram', children: [kitSpecimenMonogramInked()]),
    kitSection('Date tabs', children: [kitSpecimenDateTabs()]),
    kitSection('Pills', children: [kitSpecimenPills()]),
    kitSection('Tags', children: [kitSpecimenTags()]),
    kitSection(
      'Dashed frames',
      children: [kitSpan(KitSpan.margin, kitSpecimenDashedFrames())],
    ),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Home's five accounts, each its own glyph.
Widget kitSpecimenGlyphs() =>
    kitRow([for (final a in kitAccounts) LedgerGlyph(a.icon)]);

/// A move between the owner's accounts (the dashed ring), a card payment
/// (the same), an unread notification's green and a freeze's firm ink.
Widget kitSpecimenGlyphTones() => kitRow(const [
  LedgerGlyph(LucideIcons.arrowRightLeft, tone: LedgerGlyphTone.move),
  LedgerGlyph(LucideIcons.creditCard, tone: LedgerGlyphTone.move),
  LedgerGlyph(LucideIcons.receipt, tone: LedgerGlyphTone.moneyIn),
  LedgerGlyph(
    LucideIcons.ban,
    tone: LedgerGlyphTone.inked,
    size: LedgerGlyphSize.dense,
  ),
]);

/// The recent merchants' initials, and the paycheck's in the green.
Widget kitSpecimenMonograms() => kitRow([
  for (final t in kitRecent.take(4)) LedgerMonogram(t.title, initials: t.lead),
  LedgerMonogram(
    kitPaycheck.title,
    initials: kitPaycheck.lead,
    tone: LedgerMonogramTone.moneyIn,
  ),
]);

/// The bills of the next 15 days, as their rows lead.
Widget kitSpecimenDateTabs() =>
    kitRow([for (final b in kitUpcoming) LedgerDateTab(b.due)]);

/// The net worth's change, Spending's against September, the bills on
/// autopay, and two goals' standing.
Widget kitSpecimenPills() => kitRow([
  const LedgerPill(kitNetWorthChangePct),
  const LedgerPill(kitVsPill),
  LedgerPill(
    '${kitBills.where((b) => b.autopay).length} on autopay',
    tone: LedgerPillTone.plain,
  ),
  for (final g in kitGoals.take(2))
    LedgerPill(
      g.status,
      tone: g.behind ? LedgerPillTone.plain : LedgerPillTone.success,
      size: LedgerPillSize.small,
    ),
]);

/// A purchase not yet posted, and an unread notification.
Widget kitSpecimenTags() => kitRow(const [
  LedgerTag('Pending'),
  LedgerTag('New', tone: LedgerTagTone.unread),
]);

/// A category option's glyph, plain and chosen (the category sheet's
/// Groceries and Dining out).
Widget kitSpecimenGlyphChosen() => kitRow([
  for (final c in kitCategories.skip(1).take(2))
    LedgerGlyph(
      c.icon,
      size: LedgerGlyphSize.pick,
      tone: c.name == kitBlueFernCategory
          ? LedgerGlyphTone.selected
          : LedgerGlyphTone.plain,
    ),
]);

/// The account holder's initials, inked on the member card (the sample data
/// person: Maren Holt, MH).
Widget kitSpecimenMonogramInked() => kitRow(const [
  LedgerMonogram(
    'Maren Holt',
    initials: 'MH',
    tone: LedgerMonogramTone.inked,
    size: LedgerMonogramSize.member,
  ),
]);

/// What is not yet there: Goals' new goal and the
/// blank goal the new goal's form previews.
Widget kitSpecimenDashedFrames() => Builder(
  builder: (context) {
    final t = context.ledgerTheme;
    final sub = t.bodySmall.colored(t.textTertiary);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LedgerSpacing.s24,
      children: [
        // `.goal-new`: 18 inside, 4 apart; its ring 40 in the ink, 8 under.
        LedgerDashedFrame(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t.textPrimary),
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: LedgerIconSize.i18,
                    color: t.textPrimary,
                  ),
                ),
              ),
              Text('New goal', style: t.barTitle.line(26)),
              Text('Name it, set a target, pick a date', style: sub),
            ],
          ),
        ),
        // `.goal-blank`: 16 18 inside, the goal's line in the third ink.
        LedgerDashedFrame(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: const LedgerGoalLine(
            icon: LucideIcons.plane,
            name: 'Your goal',
            saved: 0,
            target: 0,
            by: 'by a date',
          ),
        ),
      ],
    );
  },
);
