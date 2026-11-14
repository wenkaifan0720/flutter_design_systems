/// The motion group's demo (w1-motion): the theme's scheme, the step
/// response of each of its six springs — spatial and effects, fast, default
/// and slow — then the spatial springs pinned to Standard and under Reduce
/// Motion, and one live spring to try.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The motion group's demo, in [brightness].
Widget kitMotionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Motion',
  sections: <Widget>[
    const _Scheme(),
    kitSection('Spatial', children: _responses(_spatial)),
    kitSection('Effects', children: _responses(_effects)),
    kitSection(
      'Pinned to Standard',
      children: <Widget>[
        ExpressiveStandardMotion(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _responses(_spatial),
          ),
        ),
      ],
    ),
    kitSection(
      'Reduce Motion',
      children: <Widget>[
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _responses(_spatial),
            ),
          ),
        ),
      ],
    ),
    const _Live(),
  ],
);

const List<ExpressiveMotionKey> _spatial = <ExpressiveMotionKey>[
  ExpressiveMotionKey.fastSpatial,
  ExpressiveMotionKey.defaultSpatial,
  ExpressiveMotionKey.slowSpatial,
];

const List<ExpressiveMotionKey> _effects = <ExpressiveMotionKey>[
  ExpressiveMotionKey.fastEffects,
  ExpressiveMotionKey.defaultEffects,
  ExpressiveMotionKey.slowEffects,
];

List<Widget> _responses(List<ExpressiveMotionKey> keys) => <Widget>[
  for (final key in keys) _StepResponse(key),
];

class _Scheme extends StatelessWidget {
  const _Scheme();

  @override
  Widget build(BuildContext context) {
    final motion = ExpressiveMotion.of(context);
    return kitSection(
      'Scheme',
      children: <Widget>[
        Text(
          'The ${motion.scheme.name} motion scheme'
          '${motion.reduceMotion ? ', with Reduce Motion on' : ''}',
        ),
      ],
    );
  }
}

/// How long a step response is drawn for: every Material spring has
/// settled well inside it.
const double _window = 0.8;

/// One spring's step response 0 → 1 over [_window] seconds, with the target
/// line, labelled with its key, damping ratio and stiffness as run here.
class _StepResponse extends StatelessWidget {
  const _StepResponse(this.motionKey);

  final ExpressiveMotionKey motionKey;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final motion = ExpressiveMotion.of(context);
    final spring = motion.spring(motionKey);
    final ratio =
        spring.damping / (2 * math.sqrt(spring.mass * spring.stiffness));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '${motionKey.name} · damping ${ratio.toStringAsFixed(1)}'
          ' · k ${spring.stiffness.round()}',
          style: TextStyle(color: t.colors.onSurfaceVariant),
        ),
        const SizedBox(height: kitGap / 2),
        SizedBox(
          height: 56,
          child: CustomPaint(
            painter: _StepPainter(
              spring: spring,
              curve: t.colors.primary,
              target: t.colors.outlineVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepPainter extends CustomPainter {
  const _StepPainter({
    required this.spring,
    required this.curve,
    required this.target,
  });

  final SpringDescription spring;
  final Color curve;
  final Color target;

  @override
  void paint(Canvas canvas, Size size) {
    // 0 at the bottom, 1 at 80 % height: room above for the overshoot.
    double y(double x) => size.height * (1 - 0.8 * x);
    canvas.drawLine(
      Offset(0, y(1)),
      Offset(size.width, y(1)),
      Paint()
        ..color = target
        ..strokeWidth = 1,
    );
    final sim = designSpringSimulation(spring, from: 0, to: 1);
    final path = Path()..moveTo(0, y(0));
    const samples = 160;
    for (var i = 1; i <= samples; i++) {
      final seconds = _window * i / samples;
      path.lineTo(size.width * i / samples, y(sim.x(seconds)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = curve
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_StepPainter oldDelegate) =>
      oldDelegate.spring.stiffness != spring.stiffness ||
      oldDelegate.spring.damping != spring.damping ||
      oldDelegate.curve != curve ||
      oldDelegate.target != target;
}

/// A dot that springs across on the default spatial spring each tap.
class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  bool _across = false;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    const dot = 24.0;
    return kitSection(
      'Try it',
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) => ExpressiveSpringValue(
            value: _across ? constraints.maxWidth - dot : 0,
            motion: ExpressiveMotionKey.defaultSpatial,
            builder: (context, x, child) => SizedBox(
              height: dot,
              child: Stack(
                children: <Widget>[
                  PositionedDirectional(start: x, top: 0, child: child!),
                ],
              ),
            ),
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: t.colors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        KitAction(
          _across ? 'Spring back' : 'Spring across',
          onTap: () => setState(() => _across = !_across),
        ),
      ],
    );
  }
}
