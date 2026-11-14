/// The `motion` oracle group (Compose twin: `MotionScenes.kt`): a step
/// response per spring of both schemes.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../harness/oracle.dart';

/// How far the box springs, in dp.
const double motionTravel = 200;

/// Frames recorded per spring (1.92 s): every spring settles inside it.
const int motionFrames = 120;

/// `fastSpatial` → `fast-spatial`.
String motionSegment(ExpressiveMotionKey key) => key.name
    .replaceAllMapped(RegExp('([a-z])([A-Z])'), (m) => '${m[1]}-${m[2]}')
    .toLowerCase();

/// The springs in the oracle's order: spatial fast/default/slow, then
/// effects.
const List<ExpressiveMotionKey> motionKeys = [
  ExpressiveMotionKey.fastSpatial,
  ExpressiveMotionKey.defaultSpatial,
  ExpressiveMotionKey.slowSpatial,
  ExpressiveMotionKey.fastEffects,
  ExpressiveMotionKey.defaultEffects,
  ExpressiveMotionKey.slowEffects,
];

/// A 32 dp `primary` box (tag `box`) springing [motionTravel] dp right on a
/// 280 dp track, from its first frame, on [scheme]'s spring for [spring].
class _Step extends StatefulWidget {
  const _Step(this.scheme, this.spring);

  final ExpressiveMotionScheme scheme;
  final ExpressiveMotionKey spring;

  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> with SingleTickerProviderStateMixin {
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    // The oracle starts its spring from a LaunchedEffect: after the first
    // frame, so its clock starts on the second. A spring started here, in
    // the first frame's build, would count that frame's time; started after
    // it, both springs start at frame 1 and the scene measures the springs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _x.springTo(
        motionTravel,
        ExpressiveMotion(scheme: widget.scheme).spring(widget.spring),
      );
    });
  }

  @override
  void dispose() {
    _x.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    height: 32,
    child: AnimatedBuilder(
      animation: _x,
      builder: (context, child) => Stack(
        // Snapped to device pixels, as the oracle's `offset { roundToPx }`.
        children: [
          Positioned(
            left: (_x.value * oracleDensity).roundToDouble() / oracleDensity,
            top: 0,
            child: child!,
          ),
        ],
      ),
      child: OracleTag(
        'box',
        child: SizedBox.square(
          dimension: 32,
          child: ColoredBox(color: context.expressiveTheme.colors.primary),
        ),
      ),
    ),
  );
}

final OracleGroup motionScenes = OracleGroup(
  id: 'motion',
  scenes: [
    for (final scheme in ExpressiveMotionScheme.values)
      for (final spring in motionKeys)
        OracleScene(
          key: 'motion/${scheme.name}/${motionSegment(spring)}',
          size: const Size(336, 64),
          motion: const OracleMotion(tags: ['box'], frames: motionFrames),
          build: (context) => _Step(scheme, spring),
        ),
  ],
);

void main() => runOracleGroup(motionScenes);
