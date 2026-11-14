/// The preview group's demo: [ExpressivePreview] on both registers — each
/// register's device with its system bars (Android's gesture and
/// three-button navigation; iOS's home indicator, light and dark) — and
/// the three presentations a page is previewed alone in (root, pushed,
/// sheet). Every demo in this gallery is itself one preview, in the ambient
/// register; the phones here are previews nested in it, in the same
/// register (the lab's platform toggle shows the other).
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit.dart';

/// The preview group's demo, in [brightness].
Widget kitPreviewDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Preview',
  sections: <Widget>[
    const _Register(),
    // Only the ambient register: the smoke matrix holds every preview
    // frame a demo draws to the platform under test, and the lab's
    // platform toggle shows the other.
    kitSection(
      'System bars',
      children: <Widget>[
        _Phones(
          phones: switch (kitPlatform) {
            PreviewPlatform.android => <_Phone>[
              _Phone(
                'Gesture navigation',
                brightness: brightness,
                child: const _TrailLog(),
              ),
              _Phone(
                'Three-button navigation',
                brightness: brightness,
                navigationMode: ExpressiveNavigationMode.threeButton,
                child: const _TrailLog(),
              ),
            ],
            PreviewPlatform.ios => <_Phone>[
              for (final shade in Brightness.values)
                _Phone(
                  'Home indicator, ${shade.name}',
                  brightness: shade,
                  child: const _TrailLog(),
                ),
            ],
          },
        ),
      ],
    ),
    kitSection(
      'Presentations',
      children: <Widget>[
        _Phones(
          phones: <_Phone>[
            for (final register in RoutePresentation.values)
              _Phone(
                switch (register) {
                  RoutePresentation.root => 'Root',
                  RoutePresentation.pushed => 'Pushed',
                  RoutePresentation.sheet => 'Sheet',
                },
                brightness: brightness,
                presentation: register,
                child: switch (register) {
                  RoutePresentation.root => const _TrailLog(),
                  RoutePresentation.pushed => const _Trail(),
                  RoutePresentation.sheet => const _NewEntry(),
                },
              ),
          ],
        ),
      ],
    ),
  ],
);

/// The register this very page is previewed in, and what its bars take.
class _Register extends StatelessWidget {
  const _Register();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final insets = ExpressivePreview.systemInsetsOf(kitPlatform);
    final device = kitPlatform.device;
    return kitSection(
      'This page',
      children: <Widget>[
        Text(
          'Previewed in the ${kitPlatform.name} register, '
          '${t.brightness.name}: ${device.size.width.toStringAsFixed(0)} × '
          '${device.size.height.toStringAsFixed(0)} at '
          '${device.devicePixelRatio}×.',
        ),
        Text(
          'The system bars above and below are drawn for the register and '
          'reserved as the safe area: ${insets.top.toStringAsFixed(0)} top, '
          '${insets.bottom.toStringAsFixed(0)} bottom.',
          style: TextStyle(color: t.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// One phone: a preview nested in the demo, at its register's device,
/// over its caption.
class _Phone {
  const _Phone(
    this.label, {
    required this.brightness,
    required this.child,
    this.navigationMode = ExpressiveNavigationMode.gesture,
    this.presentation = RoutePresentation.root,
  });

  final String label;
  final Brightness brightness;
  final Widget child;
  final ExpressiveNavigationMode navigationMode;
  final RoutePresentation presentation;

  Widget get preview => ExpressivePreview(
    platform: kitPlatform,
    brightness: brightness,
    light: kitTheme(Brightness.light),
    dark: kitTheme(Brightness.dark),
    device: true,
    navigationMode: navigationMode,
    presentation: presentation,
    under: const _TrailLog(),
    child: child,
  );
}

/// Phones side by side, each at its device's proportions.
class _Phones extends StatelessWidget {
  const _Phones({required this.phones});

  final List<_Phone> phones;

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    final corner = BorderRadius.circular(ExpressiveSpacing.s16);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final (index, phone) in phones.indexed) ...<Widget>[
          if (index > 0) const SizedBox(width: ExpressiveSpacing.s12),
          Expanded(
            child: Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: kitPlatform.device.size.aspectRatio,
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: c.outlineVariant),
                        borderRadius: corner,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: corner,
                      child: phone.preview,
                    ),
                  ),
                ),
                const SizedBox(height: ExpressiveSpacing.s8),
                Text(
                  phone.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A root page: a hiking log, clear of the bars.
class _TrailLog extends StatelessWidget {
  const _TrailLog();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ExpressiveChromeMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Trail log',
              style: t.type.headlineMedium.copyWith(color: t.colors.onSurface),
            ),
            const SizedBox(height: ExpressiveSpacing.s16),
            for (final (name, detail) in const <(String, String)>[
              ('Ridge loop', '11.2 km · 640 m climb'),
              ('Cedar falls', '6.8 km · 210 m climb'),
              ('Lookout spur', '4.1 km · 380 m climb'),
            ]) ...<Widget>[
              _Entry(name: name, detail: detail),
              const SizedBox(height: ExpressiveSpacing.s8),
            ],
          ],
        ),
      ),
    );
  }
}

/// One walk in the log.
class _Entry extends StatelessWidget {
  const _Entry({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExpressiveSpacing.s16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ExpressiveSpacing.s16),
        child: Row(
          children: <Widget>[
            ExpressiveIcon(
              ExpressiveSymbols.directionsWalk,
              color: t.colors.primary,
            ),
            const SizedBox(width: ExpressiveSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: t.type.titleMedium.copyWith(
                      color: t.colors.onSurface,
                    ),
                  ),
                  Text(
                    detail,
                    style: t.type.bodyMedium.copyWith(
                      color: t.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pushed page: one walk, under the back arrow its register derives.
class _Trail extends StatelessWidget {
  const _Trail();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ExpressiveChromeMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExpressiveIcon(
              ExpressiveSymbols.arrowBack,
              color: t.colors.onSurface,
            ),
            const SizedBox(height: ExpressiveSpacing.s24),
            Text(
              'Ridge loop',
              style: t.type.headlineMedium.copyWith(color: t.colors.onSurface),
            ),
            const SizedBox(height: ExpressiveSpacing.s8),
            Text(
              'A long climb through the cedars to the lookout, then down '
              'the open ridge.',
              style: t.type.bodyLarge.copyWith(
                color: t.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sheet page: a new entry for the log.
class _NewEntry extends StatelessWidget {
  const _NewEntry();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Padding(
      padding: const EdgeInsets.all(ExpressiveChromeMetrics.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'New entry',
            style: t.type.headlineSmall.copyWith(color: t.colors.onSurface),
          ),
          const SizedBox(height: ExpressiveSpacing.s8),
          Text(
            'Where did you walk today?',
            style: t.type.bodyLarge.copyWith(color: t.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
