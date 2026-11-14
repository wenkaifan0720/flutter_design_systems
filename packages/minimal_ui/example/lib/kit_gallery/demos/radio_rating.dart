/// A single choice in view, and a score out of five.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

Widget kitRadioRatingDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Radio & rating',
  sections: [
    kitSection('Radio group', children: [_LivePlan()]),
    kitSection('In a row', children: [_LiveSpeed()]),
    kitSection('Rating', children: [_LiveRating()]),
    kitSection(
      'Read-only',
      children: [
        const MinimalRating(value: 4.5, label: 'Average rating'),
        kitNote('A mark shows halves; a control sets whole stars.'),
      ],
    ),
  ],
);

class _LivePlan extends StatefulWidget {
  @override
  State<_LivePlan> createState() => _LivePlanState();
}

class _LivePlanState extends State<_LivePlan> {
  String _plan = 'pro';

  @override
  Widget build(BuildContext context) => MinimalRadioGroup<String>(
    label: 'Plan',
    value: _plan,
    onChanged: (v) => setState(() => _plan = v),
    options: const [
      MinimalRadioOption(
        value: 'free',
        label: 'Free',
        description: 'Up to 3 projects',
      ),
      MinimalRadioOption(
        value: 'pro',
        label: 'Pro',
        description: 'Unlimited projects, \$12 a month',
      ),
      MinimalRadioOption(
        value: 'team',
        label: 'Team',
        description: 'Shared billing and roles',
      ),
      MinimalRadioOption(
        value: 'ent',
        label: 'Enterprise',
        description: 'Talk to sales',
        enabled: false,
      ),
    ],
  );
}

class _LiveSpeed extends StatefulWidget {
  @override
  State<_LiveSpeed> createState() => _LiveSpeedState();
}

class _LiveSpeedState extends State<_LiveSpeed> {
  String _speed = 'standard';

  @override
  Widget build(BuildContext context) => MinimalRadioGroup<String>(
    label: 'Delivery',
    direction: Axis.horizontal,
    value: _speed,
    onChanged: (v) => setState(() => _speed = v),
    options: const [
      MinimalRadioOption(value: 'standard', label: 'Standard'),
      MinimalRadioOption(value: 'express', label: 'Express'),
    ],
  );
}

class _LiveRating extends StatefulWidget {
  @override
  State<_LiveRating> createState() => _LiveRatingState();
}

class _LiveRatingState extends State<_LiveRating> {
  int _stars = 3;

  @override
  Widget build(BuildContext context) => MinimalRating(
    value: _stars.toDouble(),
    label: 'Your rating',
    onChanged: (v) => setState(() => _stars = v),
  );
}

// --- catalog specimens -------------------------------------------------------

/// Three plans, Pro chosen.
Widget kitSpecimenRadioGroupPlans() => MinimalRadioGroup<String>(
  label: 'Plan',
  value: 'pro',
  onChanged: (_) {},
  options: const [
    MinimalRadioOption(
      value: 'free',
      label: 'Free',
      description: 'Up to 3 projects',
    ),
    MinimalRadioOption(
      value: 'pro',
      label: 'Pro',
      description: 'Unlimited projects',
    ),
    MinimalRadioOption(
      value: 'team',
      label: 'Team',
      description: 'Shared billing and roles',
    ),
  ],
);

/// Four stars of five, as a control.
Widget kitSpecimenRatingFour() =>
    MinimalRating(value: 4, label: 'Your rating', onChanged: (_) {});
