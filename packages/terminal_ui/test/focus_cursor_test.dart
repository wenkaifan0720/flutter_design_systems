// Terminal's keyboard focus is the cursor: on every part the keys reach,
// an accent block over the part with its words and edge glyphs cut out of
// it (a chosen or filled part goes hollow; a field shows its caret and its
// frame's line heavy in the accent).
// For each part, on each theme by night and by day, at 100% and 200% text,
// left to right and right to left:
//
// - the focus a Tab brings changes, at 3:1 or more against the part at
//   rest, at least as many pixels as a 2 px line round the part would
//   cover (WCAG 2.4.13's area), and the cursor's words stay legible on it;
//   a field's, beside its caret, a 1 px line's, as Material's outline adds
//   going from 1 to 2 px;
// - a mouse click on the part leaves no focus showing: what is drawn after
//   the click is what is drawn once the focus is taken away.
//
// TERM_FOCUS_PROOF=1 writes each part's picture at rest, under the keys
// and after a click into build/focus_proof/, with the numbers measured.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';
import 'flutter_test_config.dart' show longWalkLeakTesting;

final _proof = Platform.environment['TERM_FOCUS_PROOF'] == '1';

final _themes = <String, TermThemeData Function()>{
  'night': TermThemeData.dark,
  'paper': TermThemeData.light,
  'mono-night': TermThemeData.monochrome,
  'mono-paper': () => TermThemeData.monochrome(brightness: Brightness.light),
};

/// A part, how many Tabs reach the stop measured, and whether a click
/// focuses it by design (a field shows its focus on a click).
typedef _Part = ({String name, Widget Function() build, int tabs, bool field});

List<_Part> _parts(List<VoidCallback> disposers) {
  T own<T extends ChangeNotifier>(T value) {
    disposers.add(value.dispose);
    return value;
  }

  void none() {}
  final destinations = const [
    TermNavigationDestination(label: 'home'),
    TermNavigationDestination(label: 'runs'),
  ];
  _Part part(
    String name,
    Widget Function() build, {
    int tabs = 1,
    bool field = false,
  }) => (name: name, build: build, tabs: tabs, field: field);
  return [
    part('button', () => TermButton(label: 'rerun', onPressed: none)),
    part(
      'button-filled',
      () => TermButton.filled(label: 'deploy', onPressed: none),
    ),
    part(
      'icon-button',
      () => TermIconButton(glyph: '?', semanticLabel: 'help', onPressed: none),
    ),
    part(
      'chip',
      () => TermChip(label: 'failed', selected: false, onSelected: (_) {}),
    ),
    part(
      'chip-chosen',
      () => TermChip(label: 'failed', selected: true, onSelected: (_) {}),
    ),
    part('tag-remove', () => TermTag(label: 'production', onDeleted: none)),
    part(
      'segment',
      () => TermToggleGroup<String>(
        options: const ['list', 'tiles'],
        selected: const {'tiles'},
        labelOf: (v) => v,
        onSelectionChanged: (_) {},
      ),
    ),
    part(
      'segment-chosen',
      () => TermToggleGroup<String>(
        options: const ['list', 'tiles'],
        selected: const {'list'},
        labelOf: (v) => v,
        onSelectionChanged: (_) {},
      ),
    ),
    part(
      'tab',
      () => TermTabBar(
        tabs: const ['steps', 'log', 'env'],
        selectedIndex: 0,
        onTap: (_) {},
      ),
    ),
    part(
      'checkbox',
      () => TermCheckbox(value: false, label: 'auto merge', onChanged: (_) {}),
    ),
    part(
      'radio',
      () => TermRadio<String>(
        value: 'production',
        groupValue: 'staging',
        label: 'production',
        onChanged: (_) {},
      ),
    ),
    // Radios grouped at their owner: one Tab stop, on the chosen one.
    part(
      'radio-group',
      () => DesignRadioGroup<String>(
        options: const ['staging', 'production'],
        value: 'production',
        onChanged: (_) {},
        itemBuilder: (context, v, node, select) => TermRadio<String>(
          value: v,
          groupValue: 'production',
          label: v,
          focusNode: node,
          onChanged: select == null ? null : (_) => select(),
        ),
      ),
    ),
    part(
      'switch',
      () => TermSwitch(value: true, label: 'notify', onChanged: (_) {}),
    ),
    part(
      'slider',
      () => TermSlider(semanticLabel: 'share', value: 0.4, onChanged: (_) {}),
    ),
    part(
      'range-slider',
      () => TermRangeSlider(
        values: const DesignRangeValues(200, 800),
        max: 1000,
        onChanged: (_) {},
      ),
    ),
    part(
      'rating',
      () => TermRating(semanticLabel: 'stars', value: 3, onChanged: (_) {}),
    ),
    part(
      'list-row',
      () => TermListTile(
        title: const Text('atlas-api'),
        subtitle: const Text('main · 2m 14s'),
        onTap: none,
      ),
    ),
    part(
      'list-row-chosen',
      () => TermListTile(
        title: const Text('atlas-api'),
        selected: true,
        onTap: none,
      ),
    ),
    part(
      'menu-row',
      () => DesignPressable(
        onPressed: none,
        semanticLabel: 'rerun',
        excludeSemantics: true,
        builder: (context, states, _) =>
            TermMenuRow(label: 'rerun', states: states),
      ),
    ),
    part('link', () => TermLink(label: 'the docs', onPressed: none)),
    part(
      'breadcrumb',
      () => TermBreadcrumb(
        crumbs: [
          (label: '~', onPressed: none),
          (label: 'atlas-api', onPressed: none),
          (label: '#1482', onPressed: null),
        ],
      ),
    ),
    part(
      'pagination',
      () => TermPagination(page: 5, pageCount: 21, onChanged: (_) {}),
      tabs: 2,
    ),
    part(
      'page-dots',
      () => TermPageDots(count: 5, index: 0, onChanged: (_) {}),
    ),
    part(
      'menu-bar',
      () => TermMenuBar(
        menus: [
          DesignMenuEntry(
            label: 'run',
            children: [DesignMenuEntry(label: 'rerun', onPressed: none)],
          ),
        ],
      ),
    ),
    part(
      'navigation-bar',
      () => TermNavigationBar(
        destinations: destinations,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
    part(
      'side-bar',
      () => SizedBox(
        height: 200,
        child: TermSideBar(
          title: 'slipway',
          destinations: destinations,
          selectedIndex: 1,
          onDestinationSelected: (_) {},
        ),
      ),
    ),
    part(
      'rail',
      () => SizedBox(
        height: 200,
        child: TermNavigationRail(
          destinations: destinations,
          selectedIndex: 1,
          onDestinationSelected: (_) {},
        ),
      ),
    ),
    part('calendar', () {
      final calendar = own(
        DesignCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          selectedDate: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 18),
        ),
      );
      return TermCalendar(controller: calendar);
    }, tabs: 3),
    part('color-picker', () {
      final colour = own(DesignColorController());
      return TermColorPicker(controller: colour);
    }),
    part('table-row', () {
      final table = own(
        DesignTableController<Map<String, String>>(
          rows: const [
            {'id': '1482', 'took': '2m 14s'},
            {'id': '1481', 'took': '1m 58s'},
          ],
          columns: const [
            DesignTableColumn(id: 'id', label: 'run'),
            DesignTableColumn(id: 'took', label: 'took'),
          ],
        ),
      );
      return TermDataTable<Map<String, String>>(
        controller: table,
        widths: const {'id': 6, 'took': 7},
        cellBuilder: (context, run, column) => Text(run[column.id] ?? ''),
      );
    }),
    part('tree-row', () {
      final tree = own(
        DesignTreeController<String>(
          roots: const ['lib', 'test'],
          childrenOf: (path) =>
              path == 'lib' ? const ['lib/main.dart'] : const [],
        ),
      );
      return TermTree<String>(
        controller: tree,
        labelOf: (path) => path.split('/').last,
      );
    }),
    part(
      'disclosure',
      () => const TermDisclosure(title: 'environment', child: Text('NODE_ENV')),
    ),
    part(
      'split-divider',
      () => const SizedBox(
        height: 120,
        child: TermSplitView(
          first: Text('files'),
          second: Text('preview'),
          initialFraction: 0.4,
        ),
      ),
    ),
    part(
      'chart',
      () => const TermLineChart(
        series: [
          TermSeries(label: 'p95 ms', values: [120, 135, 128, 160, 142]),
        ],
        xLabels: ('mon', 'fri'),
      ),
    ),
    part(
      'number-field',
      () => TermNumberField(
        semanticLabel: 'replicas',
        value: 3,
        min: 1,
        max: 9,
        onChanged: (_) {},
      ),
    ),
    part(
      'text-field',
      () => const TermTextField(labelText: 'branch', hintText: 'main'),
      field: true,
    ),
    part(
      'select',
      () => TermSelect<String>(
        labelText: 'environment',
        value: 'staging',
        items: const [
          TermSelectItem(value: 'staging', label: 'staging'),
          TermSelectItem(value: 'production', label: 'production'),
        ],
        onChanged: (_) {},
      ),
      field: true,
    ),
    part(
      'card',
      () => TermPane(
        title: 'atlas-api',
        child: TermButton(label: 'rerun', onPressed: none),
      ),
    ),
  ];
}

const _shot = ValueKey('part');

Widget _host(
  TermThemeData theme,
  double scale,
  TextDirection direction,
  Widget part,
) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: TermTheme(
        data: theme,
        child: Directionality(
          textDirection: direction,
          child: ColoredBox(
            color: theme.background,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: RepaintBoundary(
                  key: _shot,
                  child: ColoredBox(
                    color: theme.background,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(width: 380 * scale, child: part),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<(ui.Image, Uint8List)> _picture(WidgetTester t) async {
  final box = t.renderObject<RenderRepaintBoundary>(find.byKey(_shot));
  return (await t.runAsync(() async {
    final image = await box.toImage();
    final bytes = await image.toByteData();
    return (image, bytes!.buffer.asUint8List());
  }))!;
}

double _luminance(int r, int g, int b) {
  double c(int v) {
    final s = v / 255;
    return s <= 0.04045
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * c(r) + 0.7152 * c(g) + 0.0722 * c(b);
}

double _ratio(Color a, Color b) {
  int ch(double v) => (v * 255).round();
  final la = _luminance(ch(a.r), ch(a.g), ch(a.b));
  final lb = _luminance(ch(b.r), ch(b.g), ch(b.b));
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The pixels that differ at all, and those that differ at 3:1 or more.
({int changed, int strong}) _compare(Uint8List a, Uint8List b) {
  var changed = 0;
  var strong = 0;
  for (var i = 0; i + 3 < a.length && i + 3 < b.length; i += 4) {
    if (a[i] == b[i] && a[i + 1] == b[i + 1] && a[i + 2] == b[i + 2]) {
      continue;
    }
    changed++;
    final la = _luminance(a[i], a[i + 1], a[i + 2]);
    final lb = _luminance(b[i], b[i + 1], b[i + 2]);
    if ((math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05) >= 3) strong++;
  }
  return (changed: changed, strong: strong);
}

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(seconds: 1));
  await t.pump(const Duration(seconds: 1));
}

Future<void> _write(String path, ui.Image image, WidgetTester t) async {
  final png = await t.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(loadFaces);

  for (final MapEntry(key: themeName, value: themeOf) in _themes.entries) {
    for (final scale in const [1.0, 2.0]) {
      for (final direction in TextDirection.values) {
        final config = '$themeName ${(scale * 100).round()}% ${direction.name}';
        testWidgets('$config: the cursor shows for the keys alone, at 3:1 '
            'over a 2 px line round each part', (t) async {
          final theme = themeOf();
          // The cursor's words on the cursor stay legible.
          expect(
            _ratio(theme.onAccent, theme.accent),
            greaterThanOrEqualTo(4.5),
          );
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = Size(1000 * scale, 1000 * scale);
          addTearDown(t.view.reset);
          final disposers = <VoidCallback>[];
          addTearDown(() {
            for (final d in disposers) {
              d();
            }
          });
          final faults = <String>[];
          final proof = <Map<String, Object?>>[];
          for (final part in _parts(disposers)) {
            await t.pumpWidget(const SizedBox.shrink());
            await t.pumpWidget(_host(theme, scale, direction, part.build()));
            await _settle(t);
            final (restImage, rest) = await _picture(t);

            for (var i = 0; i < part.tabs; i++) {
              await t.sendKeyEvent(LogicalKeyboardKey.tab);
            }
            await _settle(t);
            final node = FocusManager.instance.primaryFocus;
            final at = node?.rect ?? Rect.zero;
            final (keysImage, keys) = await _picture(t);
            final shown = _compare(rest, keys);
            final need = ((part.field ? 2 : 4) * (at.width + at.height))
                .round();

            // Away from the keys: a click on the stop the keys reached.
            node?.unfocus();
            await _settle(t);
            final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
            await mouse.addPointer(location: Offset.zero);
            await mouse.moveTo(at.center);
            await t.pump();
            await mouse.down(at.center);
            await t.pump();
            await mouse.up();
            await mouse.moveTo(Offset(t.view.physicalSize.width - 2, 2));
            await _settle(t);
            final (clickImage, clicked) = await _picture(t);
            FocusManager.instance.primaryFocus?.unfocus();
            await _settle(t);
            final (_, away) = await _picture(t);
            final left = _compare(clicked, away);
            await mouse.removePointer();

            final ok =
                shown.strong >= need && (part.field || left.changed == 0);
            proof.add({
              'part': part.name,
              'focus': '${at.width.round()}x${at.height.round()}',
              'need': need,
              'changed': shown.changed,
              'strong': shown.strong,
              'clickLeft': left.changed,
              'ok': ok,
            });
            // ignore: avoid_print
            print(
              'FOCUS $config ${part.name} on=${node?.context?.widget.runtimeType} '
              'focus=${at.width.round()}x'
              '${at.height.round()} need=$need strong=${shown.strong} '
              'changed=${shown.changed} clickLeft=${left.changed}'
              '${ok ? '' : ' FAULT'}',
            );
            if (shown.strong < need) {
              faults.add(
                '${part.name}: the keys change ${shown.strong} px at 3:1, '
                '${part.field ? 'a 1' : 'a 2'} px line round it is $need',
              );
            }
            if (!part.field && left.changed != 0) {
              faults.add(
                '${part.name}: a click leaves ${left.changed} px of focus',
              );
            }
            if (_proof) {
              final dir = 'build/focus_proof/${config.replaceAll(' ', '_')}';
              await _write('$dir/${part.name}_rest.png', restImage, t);
              await _write('$dir/${part.name}_keys.png', keysImage, t);
              await _write('$dir/${part.name}_click.png', clickImage, t);
            }
          }
          if (_proof) {
            File(
                'build/focus_proof/${config.replaceAll(' ', '_')}/numbers.json',
              )
              ..parent.createSync(recursive: true)
              ..writeAsStringSync(jsonEncode(proof));
          }
          expect(faults, isEmpty, reason: faults.join('\n'));
          await t.pumpWidget(const SizedBox.shrink());
        }, experimentalLeakTesting: longWalkLeakTesting);
      }
    }
  }
}
