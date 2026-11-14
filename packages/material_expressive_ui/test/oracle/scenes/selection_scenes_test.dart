/// The `selection` oracle group (Compose twin: `SelectionScenes.kt`): the
/// checkbox, the radio button and the switch in every state, the switch's
/// pressed thumb, and the switch's toggle as per-frame geometry (CONTRACT §7
/// "selection controls every state", motion "switch").
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

/// Controls in a row 8 dp apart, centred.
Widget _row(List<Widget> children) =>
    Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);

/// An [OracleTag] that measures a control's visual box, not the 48 dp
/// touch target [ExpressiveMinimumInteractiveSize] lays around it: the
/// oracle's tag bounds are Compose's semantics bounds, which for these
/// controls are the visual container (checkbox and radio 24 dp, switch and
/// chips 32 dp tall). The harness measures a tag's first render box; this
/// hands it the first box down the tag's single-child chain that is smaller
/// than that one (the touch target's child), or the box itself when none
/// is. The harness has no inset option; see the item report.
class VisualTag extends OracleTag {
  const VisualTag(super.tag, {required super.child, super.shape, super.key});

  @override
  StatelessElement createElement() => _VisualTagElement(this);
}

class _VisualTagElement extends StatelessElement {
  _VisualTagElement(VisualTag super.widget);

  @override
  RenderObject? get renderObject {
    final outer = super.renderObject;
    if (outer is! RenderBox || !outer.hasSize) return outer;
    RenderObject node = outer;
    while (node is RenderObjectWithChildMixin<RenderBox>) {
      final child = node.child;
      if (child == null || !child.hasSize) break;
      if (child.size != outer.size) return child;
      node = child;
    }
    return outer;
  }
}

void _ignore(bool _) {}

void _none() {}

/// The thumb content both sides use: an empty 16 dp box, tagged (the
/// oracle carries no icon font; the box has the icon's geometry).
Widget _thumbIcon() =>
    const OracleTag('thumb-icon', child: SizedBox.square(dimension: 16));

/// A switch that turns on as the oracle's `LaunchedEffect` does, its spring
/// starting on the same frame.
class _Toggle extends StatefulWidget {
  const _Toggle();

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    // The oracle's LaunchedEffect sets `checked` after frame 0; frame 1
    // recomposes and the thumb's measure launches `animateTo`, whose clock
    // starts at its first `withFrameNanos`: frame 2. A Flutter spring
    // started in a build takes that build's frame time, so the switch is
    // rebuilt on frame 2 and both springs start there (one frame of
    // Compose's coroutine latency, not a component difference).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (mounted) setState(() => _on = true);
        })
        ..scheduleFrame();
    });
  }

  @override
  Widget build(BuildContext context) => VisualTag(
    'switch',
    child: ExpressiveSwitch(
      value: _on,
      onChanged: _ignore,
      checkedIcon: _thumbIcon(),
      uncheckedIcon: _thumbIcon(),
    ),
  );
}

final OracleGroup selectionScenes = OracleGroup(
  id: 'selection',
  frame: (context, scene) => ExpressiveHost(
    light: context.expressiveTheme,
    dark: context.expressiveTheme,
    brightness: context.expressiveTheme.brightness,
    child: scene,
  ),
  scenes: [
    OracleScene(
      key: 'selection/checkbox',
      size: const Size(288, 64),
      build: (context) => _row([
        VisualTag(
          'checkbox-off',
          child: ExpressiveCheckbox(value: false, onChanged: _ignore),
        ),
        VisualTag(
          'checkbox-on',
          child: ExpressiveCheckbox(value: true, onChanged: _ignore),
        ),
        VisualTag(
          'checkbox-mixed',
          child: ExpressiveCheckbox(
            value: null,
            tristate: true,
            onChanged: _ignore,
          ),
        ),
        VisualTag(
          'checkbox-error-off',
          child: ExpressiveCheckbox(
            value: false,
            isError: true,
            onChanged: _ignore,
          ),
        ),
        VisualTag(
          'checkbox-error-on',
          child: ExpressiveCheckbox(
            value: true,
            isError: true,
            onChanged: _ignore,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'selection/checkbox/disabled',
      size: const Size(176, 64),
      build: (context) => _row([
        VisualTag(
          'checkbox-off',
          child: ExpressiveCheckbox(value: false, onChanged: null),
        ),
        VisualTag(
          'checkbox-on',
          child: ExpressiveCheckbox(value: true, onChanged: null),
        ),
        VisualTag(
          'checkbox-mixed',
          child: ExpressiveCheckbox(
            value: null,
            tristate: true,
            onChanged: null,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'selection/radio',
      size: const Size(232, 64),
      build: (context) => _row(const [
        VisualTag(
          'radio-on',
          child: ExpressiveRadio(selected: true, onPressed: _none),
        ),
        VisualTag(
          'radio-off',
          child: ExpressiveRadio(selected: false, onPressed: _none),
        ),
        VisualTag(
          'radio-disabled-on',
          child: ExpressiveRadio(
            selected: true,
            enabled: false,
            onPressed: _none,
          ),
        ),
        VisualTag(
          'radio-disabled-off',
          child: ExpressiveRadio(
            selected: false,
            enabled: false,
            onPressed: _none,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'selection/switch',
      size: const Size(248, 64),
      build: (context) => _row([
        const VisualTag(
          'switch-off',
          child: ExpressiveSwitch(value: false, onChanged: _ignore),
        ),
        const VisualTag(
          'switch-on',
          child: ExpressiveSwitch(value: true, onChanged: _ignore),
        ),
        VisualTag(
          'switch-icon-off',
          child: ExpressiveSwitch(
            value: false,
            onChanged: _ignore,
            uncheckedIcon: const SizedBox.square(dimension: 16),
          ),
        ),
        VisualTag(
          'switch-icon-on',
          child: ExpressiveSwitch(
            value: true,
            onChanged: _ignore,
            checkedIcon: const SizedBox.square(dimension: 16),
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'selection/switch/disabled',
      size: const Size(128, 64),
      build: (context) => _row(const [
        VisualTag(
          'switch-off',
          child: ExpressiveSwitch(value: false, onChanged: null),
        ),
        VisualTag(
          'switch-on',
          child: ExpressiveSwitch(value: true, onChanged: null),
        ),
      ]),
    ),
    OracleScene(
      key: 'selection/switch/pressed',
      size: const Size(96, 64),
      interaction: const OraclePress('switch'),
      build: (context) => const VisualTag(
        'switch',
        child: ExpressiveSwitch(value: true, onChanged: _ignore),
      ),
    ),
    OracleScene(
      key: 'selection/switch/toggle',
      size: const Size(96, 64),
      motion: const OracleMotion(tags: ['thumb-icon'], frames: 40),
      build: (context) => const _Toggle(),
    ),
  ],
);

void main() => runOracleGroup(selectionScenes);
