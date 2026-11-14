/// The `chips` oracle group (Compose twin: `ChipsScenes.kt`): assist,
/// filter, input and suggestion chips, flat and elevated, selected and
/// disabled, and the Expressive filter chip's morphing shape at rest,
/// selected and pressed (CONTRACT §7 "chips").
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';
import 'selection_scenes_test.dart' show VisualTag;

/// Chips in a row 8 dp apart, centred.
Widget _row(List<Widget> children) =>
    Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);

void _none() {}

void _ignore() {}

final OracleGroup chipsScenes = OracleGroup(
  id: 'chips',
  frame: (context, scene) => ExpressiveHost(
    light: context.expressiveTheme,
    dark: context.expressiveTheme,
    brightness: context.expressiveTheme.brightness,
    child: scene,
  ),
  scenes: [
    OracleScene(
      key: 'chips/assist',
      size: const Size(256, 64),
      build: (context) => _row(const [
        VisualTag(
          'assist-flat',
          child: ExpressiveChip.assist('Share', onPressed: _none),
        ),
        VisualTag(
          'assist-elevated',
          child: ExpressiveChip.assist(
            'Share',
            elevated: true,
            onPressed: _none,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'chips/filter',
      size: const Size(336, 64),
      build: (context) => _row(const [
        VisualTag(
          'filter-off',
          child: ExpressiveChip.filter(
            'Jazz',
            selected: false,
            onPressed: _ignore,
          ),
        ),
        VisualTag(
          'filter-on',
          child: ExpressiveChip.filter(
            'Soul',
            selected: true,
            onPressed: _ignore,
          ),
        ),
        VisualTag(
          'filter-elevated-on',
          child: ExpressiveChip.filter(
            'Folk',
            selected: true,
            elevated: true,
            onPressed: _ignore,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'chips/input',
      size: const Size(256, 64),
      build: (context) => _row(const [
        VisualTag(
          'input-off',
          child: ExpressiveChip.input('Lisbon', onPressed: _none),
        ),
        VisualTag(
          'input-on',
          child: ExpressiveChip.input(
            'Porto',
            selected: true,
            onPressed: _none,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'chips/suggestion',
      size: const Size(256, 64),
      build: (context) => _row(const [
        VisualTag(
          'suggestion-flat',
          child: ExpressiveChip.suggestion('Reply', onPressed: _none),
        ),
        VisualTag(
          'suggestion-elevated',
          child: ExpressiveChip.suggestion(
            'Reply',
            elevated: true,
            onPressed: _none,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'chips/disabled',
      size: const Size(336, 64),
      build: (context) => _row(const [
        VisualTag(
          'assist',
          child: ExpressiveChip.assist('Share', enabled: false),
        ),
        VisualTag(
          'filter-on',
          child: ExpressiveChip.filter('Soul', selected: true, enabled: false),
        ),
        VisualTag(
          'suggestion-elevated',
          child: ExpressiveChip.suggestion(
            'Reply',
            elevated: true,
            enabled: false,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'chips/filter/morph',
      size: const Size(256, 64),
      build: (context) => _row(const [
        VisualTag(
          'filter-off',
          child: ExpressiveChip.filter(
            'Jazz',
            selected: false,
            morph: true,
            onPressed: _ignore,
          ),
        ),
        VisualTag(
          'filter-on',
          child: ExpressiveChip.filter(
            'Soul',
            selected: true,
            morph: true,
            onPressed: _ignore,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'chips/filter/morph/pressed',
      size: const Size(160, 64),
      interaction: const OraclePress('filter'),
      build: (context) => const VisualTag(
        'filter',
        child: ExpressiveChip.filter(
          'Jazz',
          selected: false,
          morph: true,
          onPressed: _ignore,
        ),
      ),
    ),
  ],
);

void main() => runOracleGroup(chipsScenes);
