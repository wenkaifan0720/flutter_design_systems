/// The `sliders` oracle group (Compose twin: `SlidersScenes.kt`): the five
/// track sizes, stops and ticks, the centred track, the range slider,
/// vertical sliders both ways, disabled states, and the handle narrowed by
/// a press and by keyboard focus (CONTRACT §7 "sliders 5 sizes, range,
/// vertical"). Every slider is 272 dp wide (vertical: 200 dp tall) and
/// tagged whole, its 48 dp touch target included.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

const double _width = 272;

void _ignore(double _) {}

void _ignoreRange(double _, double _) {}

/// Sliders stacked 8 dp apart, centred.
Widget _stack(List<Widget> children) =>
    Column(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);

/// A 272 dp slider tagged [tag].
Widget _slider(String tag, Widget slider) => OracleTag(
  tag,
  child: SizedBox(width: _width, child: slider),
);

final OracleGroup slidersScenes = OracleGroup(
  id: 'sliders',
  frame: (context, scene) => ExpressiveHost(
    light: context.expressiveTheme,
    dark: context.expressiveTheme,
    brightness: context.expressiveTheme.brightness,
    child: scene,
  ),
  scenes: [
    OracleScene(
      key: 'sliders/sizes',
      size: const Size(288, 360),
      build: (context) => _stack([
        for (final (tag, size) in const [
          ('xs', ExpressiveSliderSize.extraSmall),
          ('s', ExpressiveSliderSize.small),
          ('m', ExpressiveSliderSize.medium),
          ('l', ExpressiveSliderSize.large),
          ('xl', ExpressiveSliderSize.extraLarge),
        ])
          _slider(
            tag,
            ExpressiveSlider(value: 0.5, size: size, onChanged: _ignore),
          ),
      ]),
    ),
    OracleScene(
      key: 'sliders/stops',
      size: const Size(288, 168),
      build: (context) => _stack([
        _slider(
          'stepped',
          const ExpressiveSlider(value: 0.6, steps: 4, onChanged: _ignore),
        ),
        _slider(
          'stepped-disabled',
          const ExpressiveSlider(value: 0.2, steps: 4, onChanged: null),
        ),
        _slider(
          'disabled',
          const ExpressiveSlider(value: 0.5, onChanged: null),
        ),
      ]),
    ),
    OracleScene(
      key: 'sliders/centred',
      size: const Size(288, 104),
      build: (context) => _stack([
        _slider(
          'centred-after',
          const ExpressiveSlider(
            value: 0.4,
            min: -1,
            max: 1,
            centered: true,
            onChanged: _ignore,
          ),
        ),
        _slider(
          'centred-before',
          const ExpressiveSlider(
            value: -0.5,
            min: -1,
            max: 1,
            centered: true,
            onChanged: _ignore,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'sliders/range',
      size: const Size(288, 168),
      build: (context) => _stack([
        _slider(
          'range',
          const ExpressiveRangeSlider(
            start: 0.2,
            end: 0.7,
            onChanged: _ignoreRange,
          ),
        ),
        _slider(
          'range-stepped',
          const ExpressiveRangeSlider(
            start: 0.2,
            end: 0.8,
            steps: 4,
            onChanged: _ignoreRange,
          ),
        ),
        _slider(
          'range-disabled',
          const ExpressiveRangeSlider(start: 0.3, end: 0.6, onChanged: null),
        ),
      ]),
    ),
    OracleScene(
      key: 'sliders/vertical',
      size: const Size(128, 216),
      build: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final (tag, topToBottom) in const [
            ('top-to-bottom', true),
            ('bottom-to-top', false),
          ])
            OracleTag(
              tag,
              child: SizedBox(
                height: 200,
                child: ExpressiveVerticalSlider(
                  value: 0.3,
                  topToBottom: topToBottom,
                  onChanged: _ignore,
                ),
              ),
            ),
        ],
      ),
    ),
    OracleScene(
      key: 'sliders/pressed',
      size: const Size(288, 64),
      interaction: const OraclePress('slider'),
      build: (context) => _slider(
        'slider',
        const ExpressiveSlider(value: 0.5, onChanged: _ignore),
      ),
    ),
    OracleScene(
      key: 'sliders/focused',
      size: const Size(288, 64),
      interaction: const OracleFocus('slider'),
      build: (context) => _slider(
        'slider',
        const ExpressiveSlider(value: 0.5, onChanged: _ignore),
      ),
    ),
  ],
);

void main() => runOracleGroup(slidersScenes);
