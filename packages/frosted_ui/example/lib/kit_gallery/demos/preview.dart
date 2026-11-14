/// The host and the isolated page preview: one page standing as a nav root
/// over the tab bar, pushed with its derived way back, and raised as a page
/// sheet with its close, plus the host's own scope (a nested host in the
/// other appearance) and its text-scale clamp. [FrostedHost] mounts the
/// theme once; [FrostedPreview] stands one page the way the app gives it.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
          spacing: FrostedSpacing.s12,
          children: [
            Expanded(
              child: _Phone(
                brightness: brightness,
                presentation: FrostedPresentation.root,
                child: const _Spending(),
              ),
            ),
            Expanded(
              child: _Phone(
                brightness: brightness,
                presentation: FrostedPresentation.pushed,
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
          spacing: FrostedSpacing.s12,
          children: [
            Expanded(
              child: _Phone(
                brightness: brightness,
                presentation: FrostedPresentation.sheet,
                child: const _Category(),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    ),
    // A part of the page in the other appearance: FrostedTheme scopes it,
    // and the part keeps its own glass over the page's backdrop (a second
    // FrostedHost would paint a ground of its own).
    kitSection(
      'A part in the other appearance',
      children: [
        FrostedTheme(
          data: kitTheme(
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          ),
          child: Builder(
            builder: (context) => FrostedCard(
              child: Text(
                'This card wears the other appearance',
                style: context.frostedTheme.textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ],
    ),
    // The host's clamp: text asked at 300% lays out at
    // FrostedHost.maxTextScale.
    kitSection(
      'Text scale clamp',
      children: [
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(3)),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: FrostedHost.maxTextScale,
              child: Builder(
                builder: (context) {
                  final t = context.frostedTheme;
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  return FrostedCard(
                    child: Text(
                      'Asked for 3.0, laid out at ${scale.toStringAsFixed(1)}',
                      style: t.textTheme.titleMedium,
                    ),
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

/// One preview, shrunk into a phone-shaped frame at most [_widest] wide: a
/// picture of the page, read as one image by what it shows. Its controls,
/// drawn under their size, take no touch and no focus; the app's own
/// preview stands the page at full size.
class _Phone extends StatelessWidget {
  const _Phone({
    required this.brightness,
    required this.presentation,
    required this.child,
  });

  final Brightness brightness;
  final FrostedPresentation presentation;
  final Widget child;

  String get _says => switch (presentation) {
    FrostedPresentation.root =>
      'Preview: Spending, a nav root over the tab bar',
    FrostedPresentation.pushed =>
      'Preview: Everyday, pushed, with its way back to Home',
    FrostedPresentation.sheet => 'Preview: Category, raised as a page sheet',
  };

  /// A phone's width on the page: shrunk on a phone, never blown up past a
  /// phone's own size on the desktop.
  static const double _widest = 300;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _widest),
      child: Semantics(
        container: true,
        image: true,
        label: _says,
        child: ExcludeSemantics(
          child: IgnorePointer(child: ExcludeFocus(child: _frame(context))),
        ),
      ),
    ),
  );

  Widget _frame(BuildContext context) {
    final t = context.frostedTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: t.colorScheme.border),
        borderRadius: BorderRadius.circular(FrostedCorners.r18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FrostedCorners.r18),
        child: AspectRatio(
          aspectRatio: 390 / 844,
          child: FittedBox(
            child: SizedBox(
              width: 390,
              height: 844,
              child: FrostedPreview(
                light: kitTheme(Brightness.light),
                dark: kitTheme(Brightness.dark),
                brightness: brightness,
                presentation: presentation,
                tabs: presentation == FrostedPresentation.root
                    ? sampleTabs
                    : const [],
                activeIndex: 1,
                child: FrostedAccountScope(account: kitMaren, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A page's one figure, set in the figure type until the money parts
/// land (Stage C).
class _Figure extends StatelessWidget {
  const _Figure(this.amount, {this.note});

  final double amount;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostedSpacing.s4,
      children: [
        Text(
          FrostedFormat.money(amount),
          style: t.textTheme.displaySmall.tabular,
        ),
        if (note case final note?)
          Text(
            note,
            style: t.textTheme.bodyMedium.c(t.colorScheme.textTertiary),
          ),
      ],
    );
  }
}

class _Spending extends StatelessWidget {
  const _Spending();

  @override
  Widget build(BuildContext context) => const FrostedScaffold(
    topBar: FrostedAppBar(title: 'Spending', caption: 'October 2026'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrostedGap(FrostedSpacing.s24),
        _Figure(2486.12, note: '\$213.88 left of \$2,700'),
      ],
    ),
  );
}

class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) => FrostedScaffold(
    topBar: FrostedAppBar(
      title: 'Everyday',
      backLabel: 'Home',
      actions: [
        FrostedIconButton(LucideIcons.share, label: 'Share', onPressed: () {}),
      ],
    ),
    body: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [FrostedGap(FrostedSpacing.s24), _Figure(6248.30)],
    ),
  );
}

class _Category extends StatelessWidget {
  const _Category();

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return FrostedScaffold(
      topBar: const FrostedAppBar(title: 'Category'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrostedOption(label: 'Groceries', hue: t.hue(1).a, onPressed: () {}),
          FrostedOption(
            label: 'Dining out',
            hue: t.hue(2).a,
            selected: true,
            onPressed: () {},
          ),
          FrostedOption(label: 'Transport', hue: t.hue(5).a, onPressed: () {}),
        ],
      ),
    );
  }
}
