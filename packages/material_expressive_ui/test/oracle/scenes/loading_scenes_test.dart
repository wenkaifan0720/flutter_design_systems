/// The `loading` oracle group (Compose twin: `LoadingScenes.kt`): the
/// indeterminate loading indicator's first 60 frames, plain and contained
/// (the loading cycle's motion row), and the determinate indicator at 0,
/// 30, 60 and 100 % beside the contained one at 50 % (CONTRACT §7 "loading
/// indicators", motion "loading cycle").
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

final OracleGroup loadingScenes = OracleGroup(
  id: 'loading',
  frame: (context, scene) => ExpressiveHost(
    light: context.expressiveTheme,
    dark: context.expressiveTheme,
    brightness: context.expressiveTheme.brightness,
    child: scene,
  ),
  scenes: [
    OracleScene(
      key: 'loading/indicator',
      size: const Size(96, 96),
      build: (context) =>
          const OracleTag('indicator', child: ExpressiveLoadingIndicator()),
      motion: const OracleMotion(tags: ['indicator'], frames: 60, images: true),
    ),
    OracleScene(
      key: 'loading/contained',
      size: const Size(96, 96),
      build: (context) => const OracleTag(
        'indicator',
        child: ExpressiveLoadingIndicator(contained: true),
      ),
      motion: const OracleMotion(tags: ['indicator'], frames: 60, images: true),
    ),
    OracleScene(
      key: 'loading/determinate',
      size: const Size(288, 64),
      build: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final (tag, value) in const [
            ('d0', 0.0),
            ('d30', 0.3),
            ('d60', 0.6),
            ('d100', 1.0),
          ])
            OracleTag(tag, child: ExpressiveLoadingIndicator(progress: value)),
          const OracleTag(
            'contained',
            child: ExpressiveLoadingIndicator(progress: 0.5, contained: true),
          ),
        ],
      ),
    ),
  ],
);

void main() => runOracleGroup(loadingScenes);
