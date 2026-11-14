/// The host and the isolated page preview: one page standing as a nav root
/// over the tab bar, pushed with its derived way back, and raised as a page
/// sheet with its close, plus the host's own scope (a nested host in the
/// other appearance) and its text-scale clamp. [LedgerHost] mounts the
/// theme once; [LedgerPreview] stands one page the way the app gives it.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

import '../kit.dart';

Widget kitPreviewDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Host & preview',
  sections: [
    kitSection(
      'Root, pushed',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: LedgerSpacing.s12,
          children: [
            Expanded(
              child: _Phone(
                brightness: brightness,
                presentation: LedgerPresentation.root,
                child: const _Spending(),
              ),
            ),
            Expanded(
              child: _Phone(
                brightness: brightness,
                presentation: LedgerPresentation.pushed,
                child: const _Account(),
              ),
            ),
          ],
        ),
      ],
    ),
    kitSection(
      'Sheet',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: LedgerSpacing.s12,
          children: [
            Expanded(
              child: _Phone(
                brightness: brightness,
                presentation: LedgerPresentation.sheet,
                child: const _Details(),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    ),
    kitSection(
      'Host scope',
      children: [
        LedgerHost(
          light: kitTheme(Brightness.light),
          dark: kitTheme(Brightness.dark),
          brightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          child: Builder(
            builder: (context) {
              final t = context.ledgerTheme;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: t.background,
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(t.cardRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(LedgerSpacing.s20),
                  child: Text(
                    'A nested host in the other appearance',
                    style: t.sheetTitle,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
    kitSection(
      'Text scale clamp',
      children: [
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(3)),
            child: LedgerHost(
              light: kitTheme(Brightness.light),
              dark: kitTheme(Brightness.dark),
              brightness: brightness,
              child: Builder(
                builder: (context) {
                  final t = context.ledgerTheme;
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  return Text(
                    'Asked for 3.0, laid out at ${scale.toStringAsFixed(1)}',
                    style: t.body,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);

/// One preview, shrunk into a phone-shaped frame.
class _Phone extends StatelessWidget {
  const _Phone({
    required this.brightness,
    required this.presentation,
    required this.child,
  });

  final Brightness brightness;
  final LedgerPresentation presentation;
  final Widget child;

  /// A short phone's height, at a phone's 390 width.
  static const double _height = 560;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // The phone's edge drawn over its page (under it, the page's own paper
    // would cover it), and the phone cut short: the page's head and its
    // foot, without a phone's height of empty paper between. At most a
    // phone's own width, at the start of its slot: blown up to half a
    // desktop column its words stood larger than the page's.
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(border: Border.all(color: t.border)),
          child: ClipRect(
            child: AspectRatio(
              aspectRatio: 390 / _height,
              child: FittedBox(
                child: SizedBox(
                  width: 390,
                  height: _height,
                  child: LedgerPreview(
                    light: kitTheme(Brightness.light),
                    dark: kitTheme(Brightness.dark),
                    brightness: brightness,
                    presentation: presentation,
                    tabs: presentation == LedgerPresentation.root
                        ? keelTabs
                        : const [],
                    activeIndex: 1,
                    child: LedgerAccountScope(account: kitMaren, child: child),
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

/// Spending's head: October's spend against its budget (the sample data's
/// spending).
class _Spending extends StatelessWidget {
  const _Spending();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerScreen(
      topBar: LedgerTopBar(title: 'Spending', meta: LedgerFormat.today(kitNow)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OCTOBER SO FAR', style: t.label),
          const LedgerGap(LedgerSpacing.s12),
          const LedgerFigure(2486.12, size: LedgerFigureSize.section),
          Text(
            'spent of ${LedgerFormat.money(2700, showCents: false)}',
            style: t.bodySmall.colored(t.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The Everyday account, pushed from Home: its balance as the page's figure.
class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerScreen(
      topBar: const LedgerTopBar(title: 'Account', backLabel: 'Home'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Everyday', style: t.rowTitle),
          Text('CHECKING ··4821', style: t.meta),
          const LedgerGap(LedgerSpacing.s8),
          const LedgerFigure(6248.30, size: LedgerFigureSize.hero),
        ],
      ),
    );
  }
}

/// The card's details, as the Cards page raises them.
class _Details extends StatelessWidget {
  const _Details();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerScreen(
      topBar: const LedgerTopBar(title: 'Card details'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CARD NUMBER', style: t.label),
          const LedgerGap(LedgerSpacing.s8),
          Text('4242 4242 4242 7730', style: t.figureSmall),
          const LedgerGap(LedgerSpacing.s20),
          Text(
            'Only you can see this. It hides again when you close it.',
            style: t.bodySmall.colored(t.textSecondary),
          ),
        ],
      ),
    );
  }
}
