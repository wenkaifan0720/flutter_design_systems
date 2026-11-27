import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _shot = ValueKey('painted control');
const _dpr = 2;
const _screen = ValueKey('captured screen');

class _Pixels {
  const _Pixels(this.width, this.height, this.bytes);
  final int width;
  final int height;
  final Uint8List bytes;

  bool near(int x, int y, Color color, [int tolerance = 8]) {
    final i = (y * width + x) * 4;
    final argb = color.toARGB32();
    return (bytes[i] - ((argb >> 16) & 255)).abs() < tolerance &&
        (bytes[i + 1] - ((argb >> 8) & 255)).abs() < tolerance &&
        (bytes[i + 2] - (argb & 255)).abs() < tolerance;
  }

  int differentPixels(_Pixels other) {
    var count = 0;
    for (var i = 0; i < bytes.length; i += 4) {
      if ((bytes[i] - other.bytes[i]).abs() >= 5 ||
          (bytes[i + 1] - other.bytes[i + 1]).abs() >= 5 ||
          (bytes[i + 2] - other.bytes[i + 2]).abs() >= 5) {
        count++;
      }
    }
    return count;
  }

  double contrastIn(Rect rect) {
    final colors = <int>{};
    for (
      var y = (rect.top * _dpr).ceil();
      y < (rect.bottom * _dpr).floor();
      y++
    ) {
      for (
        var x = (rect.left * _dpr).ceil();
        x < (rect.right * _dpr).floor();
        x++
      ) {
        final i = (y * width + x) * 4;
        colors.add(
          0xff000000 | bytes[i] << 16 | bytes[i + 1] << 8 | bytes[i + 2],
        );
      }
    }
    final levels = colors.map((argb) => Color(argb).computeLuminance()).toList()
      ..sort();
    return (levels.last + .05) / (levels.first + .05);
  }

  Rect bounds(Color color, {int tolerance = 8, Rect? within}) {
    int l = width, r = -1, t = height, b = -1;
    final area = (within ?? Rect.fromLTWH(0, 0, width / _dpr, height / _dpr))
        .intersect(Rect.fromLTWH(0, 0, width / _dpr, height / _dpr));
    for (
      var y = (area.top * _dpr).ceil();
      y < (area.bottom * _dpr).floor();
      y++
    ) {
      for (
        var x = (area.left * _dpr).ceil();
        x < (area.right * _dpr).floor();
        x++
      ) {
        if (near(x, y, color, tolerance)) {
          if (x < l) {
            l = x;
          }
          if (x > r) {
            r = x;
          }
          if (y < t) {
            t = y;
          }
          b = y;
        }
      }
    }
    expect(r, greaterThanOrEqualTo(l));
    return Rect.fromLTRB(l / _dpr, t / _dpr, (r + 1) / _dpr, (b + 1) / _dpr);
  }
}

Future<_Pixels> _pixels(WidgetTester t, {Rect? overlay}) async {
  final box = t.renderObject<RenderRepaintBoundary>(
    find.byKey(overlay == null ? _shot : _screen),
  );
  return (await t.runAsync(() async {
    final image = overlay == null
        ? await box.toImage(pixelRatio: _dpr.toDouble())
        : await (box.debugLayer! as OffsetLayer).toImage(
            overlay,
            pixelRatio: _dpr.toDouble(),
          );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return _Pixels(image.width, image.height, data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }))!;
}

Future<void> _stage(
  WidgetTester t,
  Widget child,
  MinimalThemeData theme,
  double width,
  TextDirection direction,
  double scale,
) async {
  t.view.physicalSize = Size(width, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    RepaintBoundary(
      key: _screen,
      child: MaterialApp(
        builder: (context, child) =>
            Directionality(textDirection: direction, child: child!),
        home: MinimalTheme(
          data: theme,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                textDirection: direction,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: _shot,
                    child: ColoredBox(
                      color: theme.background,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(width: 270, child: child),
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
  await t.pumpAndSettle();
}

void main() {
  for (final (width, scale, direction) in [
    (390.0, 2.0, TextDirection.rtl),
    (1440.0, 1.0, TextDirection.ltr),
  ]) {
    for (final light in Brightness.values) {
      for (final selected in [false, true]) {
        for (final isSwitch in [false, true]) {
          testWidgets(
            'Painted pointer states: switch $isSwitch, selected $selected, $light, $width',
            (t) async {
              final theme = MinimalThemeData.preset('standard', light);
              final control = isSwitch
                  ? MinimalSwitch(
                      value: selected,
                      label: 'Reminders',
                      onChanged: (_) {},
                    )
                  : MinimalFilter(
                      'Open',
                      count: 6,
                      selected: selected,
                      onPressed: () {},
                    );
              await _stage(
                t,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: control,
                ),
                theme,
                width,
                direction,
                scale,
              );
              final rest = await _pixels(t);
              final pointer = await t.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await pointer.addPointer(location: Offset.zero);
              final center = t.getCenter(find.byWidget(control));
              await pointer.moveTo(center);
              await t.pumpAndSettle();
              final hover = await _pixels(t);
              expect(rest.differentPixels(hover), greaterThan(100));
              await pointer.down(center);
              await t.pump(const Duration(milliseconds: 220));
              await t.pumpAndSettle();
              final held = await _pixels(t);
              expect(hover.differentPixels(held), greaterThan(100));
              await pointer.up();
              await pointer.moveTo(Offset.zero);
              await t.pumpAndSettle();
              expect(rest.differentPixels(await _pixels(t)), 0);
              await pointer.removePointer();
            },
          );
        }
      }
    }
  }

  for (final preset in [
    for (final palette in MinimalThemeData.palettes) palette.id,
  ]) {
    for (final light in Brightness.values) {
      testWidgets(
        'field hints and disabled labels have readable contrast in $preset $light',
        (t) async {
          final theme = MinimalThemeData.preset(preset, light);
          await _stage(
            t,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MinimalTextField(bare: true, hintText: 'Habit name'),
                for (final variant in MinimalButtonVariant.values)
                  MinimalButton(variant.name, variant: variant),
              ],
            ),
            theme,
            390,
            TextDirection.ltr,
            1,
          );
          final image = await _pixels(t);
          final origin = t.getTopLeft(find.byKey(_shot));
          for (final label in [
            'Habit name',
            ...MinimalButtonVariant.values.map((v) => v.name),
          ]) {
            final region = t.getRect(find.text(label)).shift(-origin);
            expect(
              image.contrastIn(region),
              greaterThanOrEqualTo(4.5),
              reason: label,
            );
          }
        },
      );
    }
  }
  // Every field's prompt: what an empty field, select, picker or property
  // prints before the user fills it.
  final prompts = <(String, Widget)>[
    (
      'Stretch before bed',
      const MinimalTextField(labelText: 'Name', hintText: 'Stretch before bed'),
    ),
    ('Search habits', const MinimalSearchField(hintText: 'Search habits')),
    (
      'Search tasks',
      MinimalSearchEntry(label: 'Search tasks', onPressed: () {}),
    ),
    (
      'Pick a city',
      MinimalCombobox<String>(
        labelText: 'City',
        hintText: 'Pick a city',
        options: const ['Lisbon', 'London'],
        onSelected: (_) {},
      ),
    ),
    (
      'Add labels',
      MinimalMultiSelect<String>(
        labelText: 'Labels',
        hintText: 'Add labels',
        values: const [],
        options: const ['Bug', 'Docs'],
        onChanged: (_) {},
      ),
    ),
    (
      'example',
      const MinimalInputGroup(
        labelText: 'Website',
        prefixText: 'https://',
        hintText: 'example',
      ),
    ),
    (
      'Your password',
      const MinimalPasswordField(
        labelText: 'Password',
        hintText: 'Your password',
      ),
    ),
    ('Write a note', MinimalComposer(hintText: 'Write a note', onSend: (_) {})),
    (
      'Pick your stay',
      MinimalDateRangePicker(
        labelText: 'Stay',
        hintText: 'Pick your stay',
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: (_) {},
      ),
    ),
    (
      'Not set',
      MinimalDescriptionList(
        properties: [
          MinimalProperty(
            icon: LucideIcons.bell,
            label: 'Reminder',
            placeholder: 'Not set',
            onPressed: () {},
          ),
        ],
      ),
    ),
    (
      'Choose one',
      MinimalSelect<String>(
        labelText: 'Repeats',
        value: null,
        hintText: 'Choose one',
        options: const [MinimalSelectOption('daily', 'Daily')],
        onChanged: (_) {},
      ),
    ),
    (
      'Morning run',
      const MinimalInputRow(labelText: 'Habit', hintText: 'Morning run'),
    ),
  ];
  for (final preset in [
    for (final palette in MinimalThemeData.palettes) palette.id,
  ]) {
    for (final light in Brightness.values) {
      for (final (prompt, field) in prompts) {
        testWidgets('the prompt "$prompt" reads at 4.5:1 in $preset $light', (
          t,
        ) async {
          await _stage(
            t,
            field,
            MinimalThemeData.preset(preset, light),
            390,
            TextDirection.ltr,
            1,
          );
          final image = await _pixels(t);
          final origin = t.getTopLeft(find.byKey(_shot));
          final region = t.getRect(find.text(prompt).last).shift(-origin);
          expect(image.contrastIn(region), greaterThanOrEqualTo(4.5));
        });
      }
    }
  }
  for (final width in [390.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      for (final direction in TextDirection.values) {
        testWidgets('focused reorder grip at $width $brightness $direction', (
          t,
        ) async {
          final theme = MinimalThemeData.preset('standard', brightness);
          await _stage(
            t,
            MinimalReorderableListView<String>(
              items: const ['Alpha', 'Beta'],
              labelOf: (item) => item,
              itemBuilder: (context, item) => Text(item),
              onReorder: (_, _) {},
            ),
            theme,
            width,
            direction,
            1,
          );
          await t.sendKeyEvent(LogicalKeyboardKey.tab);
          await t.pumpAndSettle();
          final image = await _pixels(t);
          final bounds = image.bounds(theme.ring);
          final handle = t
              .getRect(find.byType(ReorderableDragStartListener).first)
              .shift(-t.getTopLeft(find.byKey(_shot)));
          expect(bounds.center, handle.center);
          expect(bounds.size, const Size(28, 28));
          final x = (bounds.center.dx * _dpr).round();
          final y = (bounds.top * _dpr).round();
          for (var i = 0; i < 2 * _dpr; i++) {
            expect(image.near(x, y + i, theme.ring), isTrue);
          }
          expect(image.near(x, y + 2 * _dpr, theme.ring), isFalse);
        });
        testWidgets('nested choice plates at $width $brightness $direction', (
          t,
        ) async {
          const well = Color(0xffd92929), plate = Color(0xff26d838);
          final base = MinimalThemeData.preset('standard', brightness);
          final theme = base.copyWith(
            colors: base.colors.copyWith(border: well, foreground: plate),
          );
          const style = MinimalStyle(
            fill: WidgetStatePropertyAll(well),
            foreground: WidgetStatePropertyAll(plate),
          );
          Future<(Rect, Rect)> measure(Widget part) async {
            await _stage(
              t,
              Align(alignment: AlignmentDirectional.centerStart, child: part),
              theme,
              width,
              direction,
              1,
            );
            final photo = await _pixels(t);
            return (
              photo.bounds(well, tolerance: 80),
              photo.bounds(plate, tolerance: 80),
            );
          }

          for (final on in [false, true]) {
            final (outer, inner) = await measure(
              MinimalSwitch(value: on, onChanged: (_) {}, style: style),
            );
            expect(outer.width, closeTo(32, .5));
            expect(outer.height, closeTo(18, .5));
            expect(inner.width, closeTo(14, .5));
            expect(inner.height, closeTo(14, .5));
            expect(inner.top - outer.top, closeTo(2, .5));
            expect(outer.bottom - inner.bottom, closeTo(2, .5));
            final right = on == (direction == TextDirection.ltr);
            expect(
              right ? outer.right - inner.right : inner.left - outer.left,
              closeTo(2, .5),
            );
          }
          final (circle, dot) = await measure(
            const MinimalRadio.mark(
              selected: true,
              style: MinimalStyle(
                fill: WidgetStatePropertyAll(well),
                edge: WidgetStatePropertyAll(well),
                foreground: WidgetStatePropertyAll(plate),
              ),
            ),
          );
          expect(circle.width, closeTo(16, .5));
          expect(circle.height, closeTo(16, .5));
          expect((dot.center - circle.center).distance, lessThanOrEqualTo(.5));
          expect(dot.size.width, closeTo(6.4, .5));
          final (track, thumb) = await measure(
            MinimalSegmentedButton<int>(
              segments: const [
                MinimalButtonSegment(0, 'One'),
                MinimalButtonSegment(1, 'Two'),
              ],
              value: 0,
              onChanged: (_) {},
            ),
          );
          expect(thumb.top - track.top, 2);
          expect(track.bottom - thumb.bottom, 2);
          expect(
            direction == TextDirection.ltr
                ? thumb.left - track.left
                : track.right - thumb.right,
            2,
          );
        });
        testWidgets(
          'menu rows follow the popup at $width $brightness $direction',
          (t) async {
            const surface = Color(0xffed3229), row = Color(0xff26d838);
            final base = MinimalThemeData.preset('standard', brightness);
            // The keys' row wears the focus ring inside its edge; painted in
            // the row's colour, the two read as the row's whole outline.
            final theme = base.copyWith(
              colors: base.colors.copyWith(
                card: surface,
                border: surface,
                muted: row,
                ring: row,
              ),
            );
            await _stage(
              t,
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => showMinimalMenu(
                    context,
                    anchor: const Rect.fromLTWH(48, 64, 200, 32),
                    items: [
                      MinimalMenuItem('First choice', onPressed: () {}),
                      MinimalMenuItem('Last choice', onPressed: () {}),
                    ],
                    style: const MinimalStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(19)),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Actions'),
                ),
              ),
              theme,
              width,
              direction,
              1,
            );
            await t.tap(find.text('Actions'));
            await t.pumpAndSettle();
            await t.sendKeyEvent(LogicalKeyboardKey.home);
            await t.pumpAndSettle();
            final first = t.getCenter(find.text('First choice'));
            final capture = Rect.fromLTWH(
              0,
              first.dy.floorToDouble() - 47,
              365,
              160,
            );
            final photo = await _pixels(t, overlay: capture);
            final outer = photo.bounds(surface), inner = photo.bounds(row);
            final inset = inner.left - outer.left;
            expect(outer.right - inner.right, closeTo(inset, .5));
            expect(inner.top - outer.top, closeTo(inset, .5));
            expect(inset, 5);
            final radius = 19 - inset;
            for (var y = 0; y < radius; y++) {
              for (var x = 0; x < radius; x++) {
                final distance = Offset(
                  radius - x - .25,
                  radius - y - .25,
                ).distance;
                if ((distance - radius).abs() < .9 ||
                    (distance - radius).abs() > 2) {
                  continue;
                }
                expect(
                  photo.near(
                    (inner.left * _dpr).round() + x * _dpr,
                    (inner.top * _dpr).round() + y * _dpr,
                    row,
                  ),
                  distance < radius,
                  reason: 'first menu row, boundary at ($x,$y)',
                );
              }
            }
            await t.sendKeyEvent(LogicalKeyboardKey.end);
            await t.pumpAndSettle();
            final last = (await _pixels(t, overlay: capture)).bounds(row);
            expect(outer.bottom - last.bottom, closeTo(inset, .5));
            await t.sendKeyEvent(LogicalKeyboardKey.escape);
            await t.pumpAndSettle();
          },
        );
        testWidgets(
          'keyboard action geometry at $width $brightness $direction',
          (t) async {
            const surface = Color(0xffe93429), ring = Color(0xff4322f0);
            final base = MinimalThemeData.preset('standard', brightness);
            final theme = base.copyWith(
              colors: base.colors.copyWith(
                card: surface,
                border: surface,
                ring: ring,
              ),
            );
            for (final part in <Widget>[
              MinimalSnackBar('Saved', actionLabel: 'Undo', onAction: () {}),
              MinimalBanner(title: 'Ready', onDismissed: () {}),
            ]) {
              await _stage(
                t,
                part,
                theme,
                width,
                direction,
                direction == TextDirection.ltr ? 1 : 2,
              );
              await t.sendKeyEvent(LogicalKeyboardKey.tab);
              await t.pumpAndSettle();
              final photo = await _pixels(t);
              final outer = photo.bounds(surface), action = photo.bounds(ring);
              final end = direction == TextDirection.ltr
                  ? outer.right - action.right
                  : action.left - outer.left;
              expect(
                action.top - outer.top,
                closeTo(end, .5),
                reason: '${part.runtimeType}, trailing upper corner',
              );
              if (part is MinimalSnackBar) {
                expect(
                  outer.bottom - action.bottom,
                  closeTo(end, .5),
                  reason: 'snack bar trailing lower corner',
                );
              }
              await t.pumpWidget(const SizedBox.shrink());
              await t.pumpAndSettle();
            }
            final node = FocusNode();
            addTearDown(node.dispose);
            await _stage(
              t,
              MinimalInputOtp(
                length: 4,
                errorText: 'Invalid code',
                focusNode: node,
              ),
              theme,
              width,
              direction,
              1,
            );
            await t.sendKeyEvent(LogicalKeyboardKey.tab);
            node.requestFocus();
            await t.pumpAndSettle();
            final photo = await _pixels(t);
            final cell = photo.bounds(ring);
            final y = (cell.center.dy * _dpr).floor();
            final stroke = [
              for (
                var x = (cell.left * _dpr).round();
                x < (cell.right * _dpr).round();
                x++
              )
                if (photo.near(x, y, ring)) x,
            ];
            expect(
              stroke.length,
              (2 * 1.5 * _dpr).round(),
              reason: '1.5 logical pixels of accent on both sides of the active code cell',
            );
          },
        );
        testWidgets('the tag fits its field at $width $brightness $direction', (
          t,
        ) async {
          const well = Color(0xffd92929), tag = Color(0xff26d838);
          final base = MinimalThemeData.preset('standard', brightness);
          final theme = base.copyWith(
            density: width == 390
                ? MinimalDensity.standard
                : MinimalDensity.compact,
            colors: base.colors.copyWith(card: well, border: well, muted: tag),
          );
          final scale = brightness == Brightness.dark ? 2.0 : 1.0;
          await _stage(
            t,
            MinimalMultiSelect<String>(
              values: const ['Tea'],
              fieldStyle: const MinimalStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              onChanged: (_) {},
            ),
            theme,
            width,
            direction,
            scale,
          );
          final photo = await _pixels(t);
          final outer = photo.bounds(well);
          final inner = photo.bounds(tag);
          final end = direction == TextDirection.ltr
              ? inner.left - outer.left
              : outer.right - inner.right;
          expect(
            inner.top - outer.top,
            closeTo(end, .5),
            reason: 'top and start insets',
          );
          expect(
            outer.bottom - inner.bottom,
            closeTo(end, .5),
            reason: 'bottom and start insets',
          );
          // Sample the chip's leading corner, bit by bit. Its fill begins a
          // further hairline inside the chip's own concentric outline.
          final radius = 16 - end;
          for (var y = 0; y < radius; y++) {
            for (var x = 0; x < radius; x++) {
              final dx = radius - (x + .25), dy = radius - (y + .25);
              final distance = Offset(dx, dy).distance;
              if ((distance - radius).abs() < .85 ||
                  (distance - radius).abs() > 2) {
                continue;
              }
              final px = direction == TextDirection.ltr
                  ? (inner.left * _dpr).round() + x * _dpr
                  : (inner.right * _dpr).round() - x * _dpr - 1;
              expect(
                photo.near(px, (inner.top * _dpr).round() + y * _dpr, tag),
                distance < radius,
                reason: 'concentric corner at ($x, $y)',
              );
            }
          }
        });
        testWidgets(
          'a focused field shows focus by its own edge, 1.5 px of accent and nothing outside it, at $width $brightness $direction',
          (t) async {
            final theme = MinimalThemeData.preset('standard', brightness);
            final focus = FocusNode();
            addTearDown(focus.dispose);
            final scale = direction == TextDirection.rtl ? 2.0 : 1.0;
            // Every boxed field, as the gallery shows them: plain, with
            // add-ons (a Price, and one in error), a mono figure
            // with a unit, search, chips, a combobox, a password, a text
            // area and the composer.
            final fields = <String, Widget>{
              'text field': MinimalTextField(
                labelText: 'Name',
                focusNode: focus,
              ),
              'add-ons': MinimalInputGroup(
                labelText: 'Price',
                prefixText: '\$',
                suffixText: 'USD',
                hintText: '0.00',
                mono: true,
                focusNode: focus,
              ),
              'add-ons in error': MinimalInputGroup(
                labelText: 'Price',
                prefixText: '\$',
                suffixText: 'USD',
                hintText: '0.00',
                errorText: 'Enter a price',
                focusNode: focus,
              ),
              'figure and unit': MinimalTextField(
                labelText: 'Daily goal',
                mono: true,
                suffix: 'pages',
                keyboardType: TextInputType.number,
                focusNode: focus,
              ),
              'search': MinimalSearchField(focusNode: focus),
              'chips': MinimalMultiSelect<String>(
                values: const ['Bug'],
                options: const ['Bug', 'Docs'],
                onChanged: (_) {},
                focusNode: focus,
              ),
              'combobox': MinimalCombobox<String>(
                labelText: 'City',
                options: const ['Lisbon', 'London'],
                onSelected: (_) {},
                focusNode: focus,
              ),
              'password': MinimalPasswordField(
                labelText: 'Password',
                focusNode: focus,
              ),
              'text area': MinimalTextArea(labelText: 'Note', focusNode: focus),
              'composer': MinimalComposer(onSend: (_) {}, focusNode: focus),
            };
            // The rule's 1.5 px, in device pixels.
            const edge = 3;
            assert(edge == 1.5 * _dpr);
            for (final MapEntry(key: name, value: field) in fields.entries) {
              await _stage(t, field, theme, width, direction, scale);
              final caret = t.getCenter(find.byType(EditableText));
              final y = ((caret.dy - t.getTopLeft(find.byKey(_shot)).dy) * _dpr)
                  .floor();
              // From the shot's side to the field's outline, then the accent
              // run that starts there.
              // A field in error keeps its danger edge when focused.
              final ink = name.endsWith('in error')
                  ? theme.destructive
                  : theme.ring;
              (int, int) band(_Pixels shot, {required bool left}) {
                int at(int i) => left ? i : shot.width - 1 - i;
                var i = 0;
                while (shot.near(at(i), y, theme.background)) {
                  i++;
                }
                final outline = i;
                while (shot.near(at(i), y, ink)) {
                  i++;
                }
                return (outline, i - outline);
              }

              final rest = await _pixels(t);
              // Tab, as the keyboard brings it, then a pointer's way.
              await t.sendKeyEvent(LogicalKeyboardKey.tab);
              focus.requestFocus();
              await t.pumpAndSettle();
              final keyed = await _pixels(t);
              for (final left in [true, false]) {
                final side = left ? 'start' : 'end';
                final (outline, accent) = band(keyed, left: left);
                expect(
                  outline,
                  band(rest, left: left).$1,
                  reason: '$name: nothing drawn outside the $side outline',
                );
                expect(
                  accent,
                  edge,
                  reason:
                      '$name: 1.5 px of accent at the $side edge, at DPR $_dpr',
                );
                // At rest a field in error wears its danger hairline; any
                // other wears no accent.
                expect(
                  band(rest, left: left).$2,
                  name.endsWith('in error')
                      ? (theme.hairline * _dpr).round()
                      : 0,
                  reason: '$name: no focus edge at rest',
                );
              }
              focus.unfocus();
              await t.pumpAndSettle();
              final pointer = await t.startGesture(
                caret,
                kind: PointerDeviceKind.mouse,
              );
              await pointer.up();
              await t.pumpAndSettle();
              expect(focus.hasFocus, isTrue, reason: '$name: a click focuses');
              final clicked = await _pixels(t);
              expect(
                clicked.differentPixels(keyed),
                0,
                reason: '$name: a click shows focus as Tab does',
              );
              await t.pumpWidget(const SizedBox.shrink());
              await t.pumpAndSettle();
            }
          },
        );
      }
    }
  }
  group('Painted label alignment', () {
    setUpAll(minimalLoadFonts);
    for (final width in [390.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        for (final direction in TextDirection.values) {
          testWidgets(
            'picker capitals sit on the row center at $width $brightness $direction',
            (t) async {
              final theme = MinimalThemeData.preset('standard', brightness);
              await _stage(
                t,
                MinimalSelect<int>(
                  labelText: 'HH',
                  value: 1,
                  options: const [MinimalSelectOption(1, 'II')],
                  onChanged: (_) {},
                ),
                theme,
                width,
                direction,
                1,
              );
              final origin = t.getTopLeft(find.byKey(_shot));
              final row = t
                  .getRect(find.byType(MinimalSelect<int>))
                  .shift(-origin);
              final photo = await _pixels(t);
              for (final (label, color) in [
                ('HH', theme.mutedForeground),
                ('II', theme.foreground),
              ]) {
                final text = t.getRect(find.text(label)).shift(-origin);
                final ink = photo.bounds(
                  color,
                  within: Rect.fromLTRB(
                    text.left,
                    row.top,
                    text.right,
                    row.bottom,
                  ),
                );
                expect(ink.center.dy, closeTo(row.center.dy, 1), reason: label);
              }
            },
          );
          testWidgets(
            'dialog action capitals share the face center at $width $brightness $direction',
            (t) async {
              final theme = MinimalThemeData.preset('standard', brightness);
              await _stage(
                t,
                Builder(
                  builder: (context) => MinimalButton(
                    'Open',
                    onPressed: () => showMinimalDialog<bool>(
                      context,
                      builder: (_) => const MinimalDialog(
                        title: 'Continue?',
                        confirmLabel: 'SAVE',
                        cancelLabel: 'KEEP',
                      ),
                    ),
                  ),
                ),
                theme,
                width,
                direction,
                1,
              );
              await t.tap(find.text('Open'));
              await t.pumpAndSettle();
              final save = t.getRect(find.text('SAVE'));
              final keep = t.getRect(find.text('KEEP'));
              final region = save.expandToInclude(keep).inflate(10);
              final image = await _pixels(t, overlay: region);
              final saveX = save.center.dx - region.left;
              final face = image.bounds(
                theme.primary,
                within: Rect.fromLTWH(saveX - 2, 0, 4, region.height),
              );
              for (final (rect, color) in [
                (save, theme.primaryForeground),
                (keep, theme.foreground),
              ]) {
                final area = Rect.fromCenter(
                  center: Offset(rect.center.dx - region.left, face.center.dy),
                  width: 32,
                  height: face.height - 4,
                );
                final ink = image.bounds(color, within: area);
                expect(ink.center.dy, closeTo(face.center.dy, 1));
              }
            },
          );
        }
      }
    }
  });
}
