// The row contract ("the outline a person sees is the box"): controls that share a row show one
// top and one bottom by their visible outline, read from pixels, under a
// finger (Android, 3 device pixels to the point) and a pointer (macOS, 2),
// at each density step, by day and by night, at each size. A variant may
// differ in fill, never in the size it shows. Under a finger every face
// stands the 48 target; with a pointer Fluent's 24, 32 and 40 at the
// density. The subtle and transparent appearances show no outline at rest
// and are not read.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

const _registers = <String, (TargetPlatform, double)>{
  'touch': (TargetPlatform.android, 3),
  'pointer': (TargetPlatform.macOS, 2),
};

const _densities = <String, Fluent2Density>{
  'standard': Fluent2Density.standard,
  'comfortable': Fluent2Density.comfortable,
  'compact': Fluent2Density.compact,
};

const _shot = ValueKey('shot');

/// The controls that take the width they are given (a field's line).
const _entries = {'text field', 'select', 'date picker'};

void _none() {}

void _drop(Object? _) {}

/// Every control that stands in a row at [size], by name, the first the
/// one the rest are held to.
Map<String, Widget> _row(int size) {
  final b = Fluent2ButtonSize.values[size];
  final i = Fluent2InputSize.values[size];
  final s = Fluent2SegmentedButtonSize.values[size];
  return {
    'primary button': Fluent2Button(
      'Save',
      onPressed: _none,
      appearance: Fluent2ButtonAppearance.primary,
      size: b,
    ),
    'secondary button': Fluent2Button('Cancel', onPressed: _none, size: b),
    'outline button': Fluent2Button(
      'Later',
      onPressed: _none,
      appearance: Fluent2ButtonAppearance.outline,
      size: b,
    ),
    'toggle button': Fluent2ToggleButton(
      'Bold',
      value: true,
      onChanged: _drop,
      size: b,
    ),
    'icon button': Fluent2IconButton(
      Fluent2Icons.add,
      label: 'Add',
      onPressed: _none,
      appearance: Fluent2ButtonAppearance.secondary,
      size: b,
    ),
    'menu button': Fluent2MenuButton('Sort', onPressed: _none, size: b),
    'split button': Fluent2SplitButton(
      'Reply',
      onPressed: _none,
      size: b,
      actions: const [Fluent2SplitAction('Reply all', onPressed: _none)],
    ),
    'segmented': Fluent2SegmentedButton<String>(
      label: 'View',
      size: s,
      value: 'list',
      onChanged: _drop,
      segments: const [
        Fluent2ButtonSegment('list', 'List'),
        Fluent2ButtonSegment('board', 'Board'),
      ],
    ),
    'text field': Fluent2TextField(hint: 'Name', onChanged: _drop, size: i),
    'select': Fluent2Select<String>(
      prompt: 'Pick a size',
      value: null,
      size: i,
      options: const [Fluent2Option('s', 'Small'), Fluent2Option('m', 'Mid')],
      onChanged: _drop,
    ),
    'date picker': Fluent2DatePicker(
      value: null,
      hint: 'Choose a date',
      size: i,
      onChanged: _drop,
    ),
  };
}

/// A picture of the stage, its pixels in RGBA, [ratio] device pixels to the
/// point.
class _Picture {
  _Picture(this.bytes, this.width, this.height, this.ratio, this.origin);

  final Uint8List bytes;
  final int width;
  final int height;
  final double ratio;
  final Offset origin;

  Color at(int x, int y) {
    final i = (y.clamp(0, height - 1) * width + x.clamp(0, width - 1)) * 4;
    return Color.fromARGB(bytes[i + 3], bytes[i], bytes[i + 1], bytes[i + 2]);
  }

  double x(double logical) => (logical - origin.dx) * ratio;
  double y(double logical) => (logical - origin.dy) * ratio;
}

double _apart(Color a, Color b) =>
    [(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()].reduce(math.max);

/// The top and bottom, in device pixels, of what differs from [ground]
/// inside [r] (its first and its last row past [faint]): the outline a
/// person sees, a stroke's or a fill's, whichever is outermost.
(double, double)? _outline(_Picture p, Rect r, Color ground) {
  const faint = .015;
  final x0 = p.x(r.left).floor(), x1 = p.x(r.right).ceil();
  final y0 = p.y(r.top).floor(), y1 = p.y(r.bottom).ceil();
  int? first, last;
  for (var y = y0; y < y1; y++) {
    var most = 0.0;
    for (var x = x0; x < x1; x++) {
      most = math.max(most, _apart(p.at(x, y), ground));
    }
    if (most > faint) {
      first ??= y;
      last = y;
    }
  }
  if (first == null) return null;
  return (first.toDouble(), last! + 1.0);
}

void main() {
  for (final size in [0, 1, 2]) {
    final name = Fluent2ButtonSize.values[size].name;
    testWidgets('$name controls in a row show one top and one bottom', (
      t,
    ) async {
      addTearDown(t.view.reset);
      final faults = <String>[];
      try {
        for (final MapEntry(key: register, value: (platform, ratio))
            in _registers.entries) {
          debugDefaultTargetPlatformOverride = platform;
          for (final MapEntry(key: step, value: density)
              in _densities.entries) {
            for (final brightness in Brightness.values) {
              final what = '$register, $step, ${brightness.name}';
              final row = _row(size);
              t.view.physicalSize = const Size(2800, 240);
              t.view.devicePixelRatio = 1;
              final theme = Fluent2ThemeData.preset(
                'lapis',
                brightness,
              ).copyWith(density: density);
              await t.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  builder: (context, route) => Fluent2Host(
                    light: theme,
                    darkData: theme,
                    brightness: brightness,
                    child: route!,
                  ),
                  home: Builder(
                    builder: (context) => RepaintBoundary(
                      key: _shot,
                      child: ColoredBox(
                        color: context.fluent2Theme.background,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 16,
                              children: [
                                for (final MapEntry(key: k, value: w)
                                    in row.entries)
                                  // A row that leaves the width open, as
                                  // a toolbar's does: a joined strip
                                  // stands its natural width in it; an
                                  // entry is given its width, as it is in
                                  // any Flutter row.
                                  KeyedSubtree(
                                    key: ValueKey(k),
                                    child: _entries.contains(k)
                                        ? SizedBox(width: 240, child: w)
                                        : w,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await t.pumpAndSettle();
              final ground = Fluent2ThemeData.preset(
                'lapis',
                brightness,
              ).background;
              final box = t.renderObject<RenderRepaintBoundary>(
                find.byKey(_shot),
              );
              final origin = box.localToGlobal(Offset.zero);
              final shot = await t.runAsync(() async {
                final image = await box.toImage(pixelRatio: ratio);
                try {
                  final data = await image.toByteData();
                  return (
                    data!.buffer.asUint8List(),
                    image.width,
                    image.height,
                  );
                } finally {
                  image.dispose();
                }
              });
              final p = _Picture(shot!.$1, shot.$2, shot.$3, ratio, origin);
              (double, double)? first;
              for (final k in row.keys) {
                // Read clear of the hit slop's sides: the outline's top
                // and bottom only.
                final r = t.getRect(find.byKey(ValueKey(k)));
                final read = _outline(
                  p,
                  Rect.fromLTRB(
                    r.left + 4,
                    r.top - 8,
                    r.right - 4,
                    r.bottom + 8,
                  ),
                  ground,
                );
                if (read == null) {
                  faults.add('$what: the $k shows no outline');
                  continue;
                }
                first ??= read;
                final top = (read.$1 - first.$1) / ratio;
                final bottom = (read.$2 - first.$2) / ratio;
                if ((read.$1 - first.$1).abs() > 1 ||
                    (read.$2 - first.$2).abs() > 1) {
                  faults.add(
                    '$what: the $k shows ${top.toStringAsFixed(2)} at its top '
                    'and ${bottom.toStringAsFixed(2)} at its bottom against '
                    'the primary button (${((read.$2 - read.$1) / ratio).toStringAsFixed(1)} '
                    'tall against ${((first.$2 - first.$1) / ratio).toStringAsFixed(1)})',
                  );
                }
              }
            }
          }
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
      // Read from drawn pixels (the rasterizer's, as a golden's): run where
      // the goldens run.
    }, tags: const ['goldens']);
  }
}
