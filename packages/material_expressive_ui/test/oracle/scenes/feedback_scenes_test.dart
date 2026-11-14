/// The `feedback` oracle group (Compose twin: `FeedbackScenes.kt`): the
/// progress indicators (CONTRACT §7 "progress") — linear at 0, 30, 70 and
/// 100 %, circular at 30 and 70 %, both indeterminate over 60 frames, the
/// wavy ones determinate (one frame: their wave travels forever) and
/// indeterminate. Every indicator keeps its default size. The banner,
/// skeleton, step indicator and screen states have no Compose counterpart.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

/// [children] stacked 8 dp apart, centred.
Widget _stack(List<Widget> children) =>
    Column(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);

final OracleGroup feedbackScenes = OracleGroup(
  id: 'feedback',
  frame: (context, scene) => ExpressiveHost(
    light: context.expressiveTheme,
    dark: context.expressiveTheme,
    brightness: context.expressiveTheme.brightness,
    // The wavy indicators are hero widgets.
    child: ExpressiveHeroMoment(child: scene),
  ),
  scenes: [
    OracleScene(
      key: 'feedback/linear',
      size: const Size(256, 64),
      build: (context) => _stack([
        for (final (tag, value) in const [
          ('p0', 0.0),
          ('p30', 0.3),
          ('p70', 0.7),
          ('p100', 1.0),
        ])
          OracleTag(
            tag,
            child: ExpressiveLinearProgressIndicator(value: value),
          ),
      ]),
    ),
    OracleScene(
      key: 'feedback/circular',
      size: const Size(112, 56),
      build: (context) => const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          OracleTag(
            'c30',
            child: ExpressiveCircularProgressIndicator(value: 0.3),
          ),
          OracleTag(
            'c70',
            child: ExpressiveCircularProgressIndicator(value: 0.7),
          ),
        ],
      ),
    ),
    OracleScene(
      key: 'feedback/linear-indeterminate',
      size: const Size(256, 24),
      build: (context) => const OracleTag(
        'indicator',
        child: ExpressiveLinearProgressIndicator(),
      ),
      motion: const OracleMotion(tags: ['indicator'], frames: 60, images: true),
    ),
    OracleScene(
      key: 'feedback/circular-indeterminate',
      size: const Size(56, 56),
      build: (context) => const OracleTag(
        'indicator',
        child: ExpressiveCircularProgressIndicator(),
      ),
      motion: const OracleMotion(tags: ['indicator'], frames: 60, images: true),
    ),
    OracleScene(
      key: 'feedback/wavy',
      size: const Size(256, 88),
      build: (context) => _stack(const [
        OracleTag(
          'linear',
          child: ExpressiveLinearProgressIndicator(value: 0.5, wavy: true),
        ),
        OracleTag(
          'circular',
          child: ExpressiveCircularProgressIndicator(value: 0.6, wavy: true),
        ),
      ]),
      motion: const OracleMotion(
        tags: ['linear', 'circular'],
        frames: 1,
        images: true,
      ),
    ),
    OracleScene(
      key: 'feedback/wavy-indeterminate',
      size: const Size(256, 88),
      build: (context) => _stack(const [
        OracleTag(
          'linear',
          child: ExpressiveLinearProgressIndicator(wavy: true),
        ),
        OracleTag(
          'circular',
          child: ExpressiveCircularProgressIndicator(wavy: true),
        ),
      ]),
      motion: const OracleMotion(
        tags: ['linear', 'circular'],
        frames: 60,
        images: true,
      ),
    ),
  ],
);

void main() => runOracleGroup(feedbackScenes);
