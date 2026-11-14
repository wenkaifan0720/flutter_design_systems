/// [FrostedSignInButton] in each face (Apple's, Google's, email on the glass
/// and in the ink, a custom label, busy) and [FrostedSignInStack], a welcome's
/// ways in.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitSignInDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Sign-in',
  sections: [
    kitSection(
      'Each way in',
      children: [
        FrostedSignInButton('apple', onPressed: () {}),
        kitSpecimenSignInOne(),
        FrostedSignInButton('email', onPressed: () {}),
        FrostedSignInButton('email', emphasis: true, onPressed: () {}),
        FrostedSignInButton(
          'sso',
          label: 'Use single sign-on',
          onPressed: () {},
        ),
        FrostedSignInButton('google', busy: true, onPressed: () {}),
        const FrostedSignInButton('apple', onPressed: null),
      ],
    ),
    kitSection('A welcome', children: [kitSpecimenSignInStack()]),
  ],
);

/// Google's own face with its mark.
Widget kitSpecimenSignInOne() =>
    FrostedSignInButton('google', onPressed: () {});

/// A welcome's three ways in, email leading in the ink.
Widget kitSpecimenSignInStack() => FrostedSignInStack(
  const ['email', 'apple', 'google'],
  leadWithFirst: true,
  onPressed: (_) {},
);
