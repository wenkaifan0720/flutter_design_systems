/// Sign-in buttons: the provider stack as a page offers it, led by one
/// provider or not, every bundled mark's mono cut on the accent fill,
/// email, single sign-on's monogram, a hugging button, and the
/// disabled stack while a request is in flight.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

Widget kitSignInDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Sign-in',
  sections: [
    kitSection('On a page', children: const [_SignInCard()]),
    kitSection(
      'Stack',
      children: [
        MinimalSignInStack(const [
          'apple',
          'google',
          'email',
        ], onPressed: (_) {}),
      ],
    ),
    kitSection(
      'Lead with the first',
      children: [
        MinimalSignInStack(
          const ['github', 'google'],
          leadWithFirst: true,
          onPressed: (_) {},
        ),
      ],
    ),
    kitSection(
      'Emphasis, per mark',
      children: [
        // The three the hugging row shows: one line on a phone, even at the
        // largest text.
        kitRow([
          for (final (provider, name) in const [
            ('apple', 'Apple'),
            ('google', 'Google'),
            ('github', 'GitHub'),
          ])
            MinimalSignInButton(
              provider,
              label: name,
              emphasis: true,
              expand: false,
              onPressed: () {},
            ),
        ]),
        kitNote(
          'Each mark\'s mono cut on the accent, side by side only to show '
          'them: a page emphasises one provider, the one it leads with.',
        ),
      ],
    ),
    kitSection(
      'Other providers',
      children: [
        // Only a way in that no brand owns: a brand's sign-in is drawn with
        // its real mark or not shown.
        MinimalSignInButton(
          'sso',
          label: 'Continue with SAML SSO',
          onPressed: () {},
        ),
        kitNote(
          'A way in with no bundled mark, such as single sign-on, gets its '
          'monogram, never another brand\'s.',
        ),
      ],
    ),
    kitSection(
      'Hugging',
      children: [
        kitRow([
          MinimalSignInButton(
            'apple',
            label: 'Apple',
            expand: false,
            onPressed: () {},
          ),
          MinimalSignInButton(
            'google',
            label: 'Google',
            expand: false,
            onPressed: () {},
          ),
          MinimalSignInButton(
            'github',
            label: 'GitHub',
            expand: false,
            onPressed: () {},
          ),
        ]),
      ],
    ),
    kitSection(
      'Disabled',
      children: [
        const MinimalSignInStack(['apple', 'google', 'email']),
        kitNote(
          'While a sign-in is under way, the other ways in wait, dimmed.',
        ),
      ],
    ),
  ],
);

/// A sign-in panel the way a page composes it: the heading, the stack,
/// and the line under it saying which provider was chosen.
class _SignInCard extends StatefulWidget {
  const _SignInCard();

  @override
  State<_SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends State<_SignInCard> {
  String? _chosen;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final chosen = _chosen;
    // The card is the stack's measure and its padding, on the column's
    // start: a wide column leaves no empty half inside it.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: MinimalLayout.controlMax + 2 * MinimalSpacing.s20,
        ),
        child: _card(context, t, chosen),
      ),
    );
  }

  Widget _card(BuildContext context, MinimalThemeData t, String? chosen) {
    return Container(
      padding: const EdgeInsets.all(MinimalSpacing.s20),
      decoration: ShapeDecoration(
        color: t.card,
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign in to Ritual', style: t.h2),
          const MinimalGap(MinimalSpacing.s4),
          Text(
            'Keep your habits and streaks on every device.',
            style: t.bodySmall.c(t.mutedForeground),
          ),
          const MinimalGap(MinimalSpacing.s20),
          // The line under the stack keeps the stack's measure, so it is
          // centred under the buttons, not across the card.
          MinimalLayout.capControl(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MinimalSignInStack(const [
                  'apple',
                  'google',
                  'email',
                ], onPressed: (provider) => setState(() => _chosen = provider)),
                const MinimalGap(MinimalSpacing.s16),
                Text(
                  chosen == null
                      ? 'By continuing you accept the terms and privacy '
                            'notice.'
                      : 'Signing in with $chosen…',
                  style: t.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// One provider on the neutral surface, its mark in its own colours.
Widget kitSpecimenSignInButtonNeutral() =>
    MinimalSignInButton('google', onPressed: () {});

/// The provider a page leads with, its mono mark on the accent fill.
Widget kitSpecimenSignInButtonEmphasis() =>
    MinimalSignInButton('apple', emphasis: true, onPressed: () {});

/// Every way in a sign-in page offers, stacked full width.
Widget kitSpecimenSignInStack() =>
    MinimalSignInStack(const ['apple', 'google', 'email'], onPressed: (_) {});

/// The stack leading with its first provider in emphasis.
Widget kitSpecimenSignInStackLead() => MinimalSignInStack(
  const ['github', 'google', 'email'],
  leadWithFirst: true,
  onPressed: (_) {},
);
