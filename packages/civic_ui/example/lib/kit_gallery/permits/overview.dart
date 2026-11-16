// The look's Overview: the idea in a line, the three moves shown live, the
// palette in a line, and the index of every part's page.
import 'package:flutter/material.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';
import 'permits.dart';

/// The Overview.
class PermitsOverview extends StatelessWidget {
  /// The Overview, its index listing [parts].
  const PermitsOverview({super.key, required this.parts});

  /// The parts' pages.
  final List<PermitsPart> parts;

  @override
  Widget build(BuildContext context) {
    final text = context.civicText;
    final t = context.civicTheme;
    final wide = MediaQuery.sizeOf(context).width >= CivicLayout.expanded;
    final moves = <Widget>[
      _Move(
        number: '1',
        title: 'The focus bar',
        words:
            'Wherever the keyboard is, it shows: a button or a link floods '
            'yellow over a thick ink bar, a box keeps its white inside a '
            'yellow ring. Nothing else on the page is yellow.',
        specimen: Wrap(
          spacing: CivicSpacing.s16,
          runSpacing: CivicSpacing.s16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            KitFocused(
              builder: (c) => CivicButton(
                onPressed: () {},
                expand: false,
                statesController: c,
                child: const Text('Continue'),
              ),
            ),
            KitFocused(
              builder: (c) => CivicLink(
                onPressed: () {},
                statesController: c,
                child: const Text('Change your name'),
              ),
            ),
          ],
        ),
      ),
      _Move(
        number: '2',
        title: 'The question page',
        words:
            'One thing per page. The question is the heading, the answers '
            'stand under it with their hints, the button says what happens '
            'next, and the way back sits above it all.',
        specimen: _Framed(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CivicBackLink(onPressed: () {}),
              ),
              const SizedBox(height: CivicSpacing.s16),
              Text('Step 1 of 3', style: text.caption),
              const SizedBox(height: CivicSpacing.s4),
              CivicRadioGroup<String>(
                labelText: 'What kind of vehicle is the permit for?',
                isPageHeading: true,
                groupValue: 'car',
                onChanged: (_) {},
                children: const [
                  CivicRadio(value: 'car', labelText: 'Car or van'),
                  CivicRadio(
                    value: 'motorcycle',
                    labelText: 'Motorcycle',
                    helperText: 'Includes mopeds and scooters.',
                  ),
                ],
              ),
              const SizedBox(height: CivicSpacing.s24),
              CivicButton(
                onPressed: () {},
                expand: false,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
      _Move(
        number: '3',
        title: 'The answers summary',
        words:
            'Before anything is sent, every answer is set out to check, each '
            'with the way back to change it. A screen reader hears which '
            'answer each Change is for.',
        specimen: CivicSummaryList(
          rows: [
            for (final (label, value) in const [
              ('Vehicle', 'Car or van'),
              ('Name', 'Amara Okafor'),
              ('Date of birth', '27 March 1987'),
            ])
              CivicSummaryRow(
                label: label,
                value: Text(value),
                actionLabel: 'Change',
                actionSemanticLabel: 'Change ${label.toLowerCase()}',
                onActionPressed: () {},
              ),
          ],
        ),
      ),
    ];
    return CivicPageBody(
      caption: 'A design system for Flutter',
      title: 'Civic',
      maxWidth: wide ? CivicLayout.maxContentWidth : CivicLayout.readingWidth,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: CivicLayout.readingWidth,
            ),
            child: Text(
              'The plain, trustworthy look of public services, where the job '
              'is that anyone, on any device, in a hurry or with a '
              'disability, can finish the task.',
              style: text.headingS.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
        ),
        const SizedBox(height: CivicSpacing.s24),
        Wrap(
          spacing: CivicSpacing.s8,
          runSpacing: CivicSpacing.s8,
          children: [
            for (final (fill, name) in [
              (t.action, 'Act'),
              (t.danger, 'Error'),
              (t.success, 'Done'),
              (t.focus, 'Focus'),
            ])
              _Chip(fill: fill, name: name),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, m) in moves.indexed) ...[
                if (i > 0) const SizedBox(width: CivicSpacing.s40),
                Expanded(child: m),
              ],
            ],
          )
        else
          for (final (i, m) in moves.indexed) ...[
            if (i > 0) const SizedBox(height: CivicSpacing.s48),
            m,
          ],
        if (parts.isNotEmpty) ...[
          const SizedBox(height: CivicSpacing.s64),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CivicLayout.readingWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CivicSectionHeader(title: 'Every part', isLarge: true),
                  for (final part in parts)
                    CivicListRow(
                      title: Text(part.title),
                      onTap: () => openPermitsPart(context, part),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Move extends StatelessWidget {
  const _Move({
    required this.number,
    required this.title,
    required this.words,
    required this.specimen,
  });

  final String number;
  final String title;
  final String words;
  final Widget specimen;

  @override
  Widget build(BuildContext context) {
    final text = context.civicText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: text.headingXL.copyWith(color: context.civicTheme.action),
        ),
        Semantics(header: true, child: Text(title, style: text.headingM)),
        const SizedBox(height: CivicSpacing.s8),
        Text(words),
        const SizedBox(height: CivicSpacing.s24),
        specimen,
      ],
    );
  }
}

class _Framed extends StatelessWidget {
  const _Framed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: context.civicTheme.rule),
    ),
    child: Padding(
      padding: const EdgeInsets.all(CivicSpacing.s20),
      child: child,
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.fill, required this.name});

  final Color fill;
  final String name;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: CivicSpacing.s8,
    children: [
      SizedBox.square(dimension: 20, child: ColoredBox(color: fill)),
      Text(name, style: context.civicText.bodySmall),
    ],
  );
}
