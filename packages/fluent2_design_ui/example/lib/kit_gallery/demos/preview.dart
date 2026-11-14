/// The host, the materials and the isolated page preview: one page standing
/// as a nav root over the tab bar, pushed with its derived way back, and
/// raised as a sheet with its close; the acrylic over a busy page beside the
/// ground and the acrylic's solid fallback; and the host's own scope (a nested host in
/// the other appearance) with its text-scale clamp. [Fluent2Host] mounts
/// the theme once; [Fluent2Preview] stands one page the way the app gives
/// it.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

import '../kit.dart';

Widget kitPreviewDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Host & preview',
  sections: [
    kitSection(
      'Root, pushed, sheet',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Fluent2Spacing.s,
          children: [
            for (final presentation in Fluent2Presentation.values)
              Expanded(
                child: _Phone(
                  brightness: brightness,
                  presentation: presentation,
                  child: switch (presentation) {
                    Fluent2Presentation.root => const _Files(),
                    Fluent2Presentation.pushed => const _Folder(),
                    Fluent2Presentation.sheet => const _Share(),
                  },
                ),
              ),
          ],
        ),
      ],
    ),
    kitSection('Materials', children: [const _Materials()]),
    kitSection(
      'Host scope',
      children: [
        Fluent2Host(
          light: kitTheme(Brightness.light),
          darkData: kitTheme(Brightness.dark),
          brightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          child: Builder(
            builder: (context) {
              final t = context.fluent2Theme;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: t.background,
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(Fluent2Radius.medium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Fluent2Spacing.xl),
                  child: Text(
                    'A nested host in the other appearance',
                    style: t.subtitle1,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
    kitSection(
      'The largest text the host allows',
      children: [
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: Fluent2Host(
              light: kitTheme(Brightness.light),
              darkData: kitTheme(Brightness.dark),
              brightness: brightness,
              child: Builder(
                builder: (context) {
                  final t = context.fluent2Theme;
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  return Text(
                    'Text at 200% reads at ${(scale * 100).round()}%',
                    style: t.body1,
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

/// One preview, shrunk into a phone-shaped frame: a picture of the page at
/// a third of its size, so neither a touch nor a screen reader reaches into
/// it (its controls would be a third of their targets).
class _Phone extends StatelessWidget {
  const _Phone({
    required this.brightness,
    required this.presentation,
    required this.child,
  });

  final Brightness brightness;
  final Fluent2Presentation presentation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(Fluent2Radius.medium),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Fluent2Radius.medium),
        child: AspectRatio(
          aspectRatio: 390 / 844,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: FittedBox(
                child: SizedBox(
                  width: 390,
                  height: 844,
                  child: Fluent2Preview(
                    light: kitTheme(Brightness.light),
                    darkData: kitTheme(Brightness.dark),
                    brightness: brightness,
                    presentation: presentation,
                    tabs: presentation == Fluent2Presentation.root
                        ? kitTabs
                        : const [],
                    selectedIndex: 3,
                    child: Fluent2AccountScope(account: kitInes, child: child),
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

class _Line extends StatelessWidget {
  const _Line(this.icon, this.title, this.meta);

  final IconData icon;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.s),
      child: Row(
        spacing: Fluent2Spacing.m,
        children: [
          Icon(icon, size: Fluent2IconSize.i24, color: t.accentText),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.body1),
                Text(meta, style: t.caption1.c(t.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Files extends StatelessWidget {
  const _Files();

  @override
  Widget build(BuildContext context) => const Fluent2Scaffold(
    topBar: Fluent2AppBar(title: 'Files'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(Fluent2Icons.folder, 'Launch plan', 'Edited by Kai, 2h ago'),
        _Line(Fluent2Icons.folder, 'Design reviews', 'Edited by Mara, Mon'),
        _Line(Fluent2Icons.documentText, 'Q4 notes.docx', 'You, Oct 28'),
      ],
    ),
  );
}

class _Folder extends StatelessWidget {
  const _Folder();

  @override
  Widget build(BuildContext context) => Fluent2Scaffold(
    topBar: Fluent2AppBar(
      title: 'Launch plan',
      backLabel: 'Files',
      actions: [
        Fluent2IconButton(Fluent2Icons.share, label: 'Share', onPressed: () {}),
      ],
    ),
    body: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(Fluent2Icons.documentText, 'Timeline.docx', 'Kai, 2h ago'),
        _Line(Fluent2Icons.image, 'Hero art.png', 'Mara, yesterday'),
      ],
    ),
  );
}

class _Share extends StatelessWidget {
  const _Share();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Fluent2Scaffold(
      topBar: const Fluent2AppBar(title: 'Share'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Fluent2Spacing.m,
        children: [
          const Fluent2Gap(Fluent2Spacing.s),
          Text('People with access', style: t.caption1Strong),
          for (final person in kitPeople.take(3))
            Fluent2Persona(name: person.name, secondary: 'Can edit'),
        ],
      ),
    );
  }
}

/// The acrylic over a busy strip (the page behind it blurred, its tint and
/// noise over), its solid fallback, and the page's ground.
class _Materials extends StatelessWidget {
  const _Materials();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    Widget tile(
      String name, {
      bool solid = false,
      bool ground = false,
    }) => SizedBox(
      height: 96,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Fluent2Radius.medium),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The busy page the acrylic stands over.
            Row(
              children: [
                for (var shade = 20; shade <= 160; shade += 20)
                  Expanded(child: ColoredBox(color: t.brand(shade))),
              ],
            ),
            Positioned.fill(
              top: 24,
              child: ground
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Fluent2Radius.medium),
                      ),
                      child: ColoredBox(
                        color: t.background,
                        child: Center(child: Text(name, style: t.body1Strong)),
                      ),
                    )
                  : Fluent2Acrylic(
                      solid: solid,
                      radius: const BorderRadius.vertical(
                        top: Radius.circular(Fluent2Radius.medium),
                      ),
                      child: Center(child: Text(name, style: t.body1Strong)),
                    ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Fluent2Spacing.m,
      children: [
        tile('Acrylic'),
        tile('Acrylic, solid', solid: true),
        tile('Ground', ground: true),
      ],
    );
  }
}
