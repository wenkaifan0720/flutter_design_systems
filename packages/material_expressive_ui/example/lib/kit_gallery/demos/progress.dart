/// The progress group's demo: linear and circular indicators, determinate
/// (a live upload you advance) and indeterminate, the wavy hero variants,
/// and the step indicator in both styles on a checkout flow.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The progress group's demo, in [brightness].
Widget kitProgressDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Progress',
  sections: const <Widget>[
    _Linear(),
    SizedBox(height: kitGap * 3),
    _Circular(),
    SizedBox(height: kitGap * 3),
    _Wavy(),
    SizedBox(height: kitGap * 3),
    _Meters(),
    SizedBox(height: kitGap * 3),
    _Steps(),
  ],
);

/// A caption and its value, over a control.
Widget _caption(BuildContext context, String text, [String? value]) {
  final t = context.expressiveTheme;
  return Row(
    children: <Widget>[
      Expanded(
        child: Text(
          text,
          style: t.type.bodyMedium.copyWith(color: t.colors.onSurface),
        ),
      ),
      if (value != null)
        Text(
          value,
          style: t.type.labelLarge.copyWith(color: t.colors.onSurfaceVariant),
        ),
    ],
  );
}

String _percent(double v) => '${(v * 100).round()}%';

/// The upload the determinate indicators follow: each tap sends another
/// photo, and the indicators spring to the new share.
class _Upload extends StatefulWidget {
  const _Upload({required this.builder});

  final Widget Function(BuildContext context, double value) builder;

  @override
  State<_Upload> createState() => _UploadState();
}

class _UploadState extends State<_Upload> {
  static const int _photos = 12;
  int _sent = 5;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ExpressiveSpringValue(
        value: _sent / _photos,
        motion: ExpressiveMotionKey.slowEffects,
        builder: (context, value, _) => widget.builder(context, value),
      ),
      const SizedBox(height: kitGap),
      Wrap(
        spacing: kitGap,
        runSpacing: kitGap,
        children: <Widget>[
          ExpressiveFilledButton.tonal(
            _sent == _photos ? 'Start over' : 'Send a photo',
            icon: _sent == _photos
                ? ExpressiveSymbols.refresh
                : ExpressiveSymbols.upload,
            onPressed: () =>
                setState(() => _sent = _sent == _photos ? 0 : _sent + 1),
          ),
        ],
      ),
    ],
  );
}

class _Linear extends StatelessWidget {
  const _Linear();

  @override
  Widget build(BuildContext context) => kitSection(
    'Linear',
    children: <Widget>[
      _Upload(
        builder: (context, value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _caption(context, 'Uploading “Lake weekend”', _percent(value)),
            const SizedBox(height: kitGap),
            ExpressiveLinearProgressIndicator(
              value: value,
              expand: true,
              semanticLabel: 'Upload',
            ),
          ],
        ),
      ),
      const SizedBox(height: kitGap),
      _caption(context, 'Storage used', '72%'),
      const ExpressiveLinearProgressIndicator(
        value: 0.72,
        expand: true,
        semanticLabel: 'Storage used',
      ),
      const SizedBox(height: kitGap),
      _caption(context, 'Checking for updates'),
      const ExpressiveLinearProgressIndicator(
        expand: true,
        semanticLabel: 'Checking for updates',
      ),
    ],
  );
}

class _Circular extends StatelessWidget {
  const _Circular();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    Widget labelled(Widget indicator, String label) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        indicator,
        const SizedBox(height: kitGap),
        Text(
          label,
          style: t.type.labelMedium.copyWith(color: t.colors.onSurfaceVariant),
        ),
      ],
    );
    return kitSection(
      'Circular',
      children: <Widget>[
        Wrap(
          spacing: kitGap * 3,
          runSpacing: kitGap * 2,
          children: <Widget>[
            labelled(
              const ExpressiveCircularProgressIndicator(
                value: 0.25,
                semanticLabel: 'Steps',
              ),
              'Steps 25%',
            ),
            labelled(
              const ExpressiveCircularProgressIndicator(
                value: 0.6,
                semanticLabel: 'Water',
              ),
              'Water 60%',
            ),
            labelled(
              const ExpressiveCircularProgressIndicator(
                value: 0.9,
                semanticLabel: 'Sleep',
              ),
              'Sleep 90%',
            ),
            labelled(
              const ExpressiveCircularProgressIndicator(
                semanticLabel: 'Syncing',
              ),
              'Syncing',
            ),
          ],
        ),
      ],
    );
  }
}

/// The wavy variants: one hero moment for the page.
class _Wavy extends StatelessWidget {
  const _Wavy();

  @override
  Widget build(BuildContext context) => kitSection(
    'Wavy · hero',
    children: <Widget>[
      ExpressiveHeroMoment(
        label: 'wavy progress',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Upload(
              builder: (context, value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _caption(context, 'Exporting your film', _percent(value)),
                  const SizedBox(height: kitGap),
                  ExpressiveLinearProgressIndicator(
                    value: value,
                    wavy: true,
                    expand: true,
                    semanticLabel: 'Export',
                  ),
                  const SizedBox(height: kitGap),
                  Row(
                    children: <Widget>[
                      ExpressiveCircularProgressIndicator(
                        value: value,
                        wavy: true,
                        semanticLabel: 'Export',
                      ),
                      const SizedBox(width: kitGap * 2),
                      const ExpressiveCircularProgressIndicator(
                        wavy: true,
                        semanticLabel: 'Rendering',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: kitGap),
            _caption(context, 'Preparing preview'),
            const SizedBox(height: kitGap),
            const ExpressiveLinearProgressIndicator(
              wavy: true,
              expand: true,
              semanticLabel: 'Preparing preview',
            ),
          ],
        ),
      ),
    ],
  );
}

class _Steps extends StatefulWidget {
  const _Steps();

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  static const List<String> _labels = <String>[
    'Basket',
    'Delivery',
    'Payment',
    'Review',
  ];
  int _step = 1;

  @override
  Widget build(BuildContext context) => kitSection(
    'Step indicator',
    children: <Widget>[
      ExpressiveStepProgress(
        count: _labels.length,
        currentStep: _step,
        labels: _labels,
      ),
      const SizedBox(height: kitGap * 2),
      ExpressiveStepProgress(
        count: _labels.length,
        currentStep: _step,
        labels: _labels,
        kind: ExpressiveStepProgressKind.segmented,
      ),
      const SizedBox(height: kitGap),
      Wrap(
        spacing: kitGap,
        runSpacing: kitGap,
        children: <Widget>[
          ExpressiveTextButton(
            'Back',
            onPressed: _step == 0 ? null : () => setState(() => _step -= 1),
          ),
          ExpressiveFilledButton(
            _step >= _labels.length ? 'Start over' : 'Continue',
            onPressed: () =>
                setState(() => _step = _step >= _labels.length ? 0 : _step + 1),
          ),
        ],
      ),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md): determinate
// values, so a still shows what a reader sees.

/// Two thirds done, flat over wavy (a hero widget, so in its hero).
Widget kitSpecimenLinearProgressWavy() => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    ExpressiveLinearProgressIndicator(value: 0.66, expand: true),
    SizedBox(height: ExpressiveSpacing.s24),
    ExpressiveHeroMoment(
      child: ExpressiveLinearProgressIndicator(
        value: 0.66,
        wavy: true,
        expand: true,
      ),
    ),
  ],
);

/// A ring two thirds full, flat beside wavy (in its hero).
Widget kitSpecimenCircularProgressWavy() => const Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: <Widget>[
    ExpressiveCircularProgressIndicator(value: 0.66),
    ExpressiveHeroMoment(
      child: ExpressiveCircularProgressIndicator(value: 0.66, wavy: true),
    ),
  ],
);

/// The second of four labelled steps.
Widget kitSpecimenStepIndicatorLabelled() => const ExpressiveStepProgress(
  count: 4,
  currentStep: 1,
  labels: <String>['Cart', 'Address', 'Payment', 'Review'],
);

class _Meters extends StatelessWidget {
  const _Meters();

  @override
  Widget build(BuildContext context) =>
      kitSection('Meters', children: <Widget>[kitSpecimenMeter()]);
}

/// A meter with room left, and one past its limit.
Widget kitSpecimenMeter() => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    ExpressiveMeter(
      label: 'Storage',
      value: 148,
      limit: 200,
      note: '52 GB left',
    ),
    SizedBox(height: ExpressiveSpacing.s24),
    ExpressiveMeter(
      label: 'Data this month',
      value: 23,
      limit: 20,
      note: '3 GB over, at the slower speed',
    ),
  ],
);
