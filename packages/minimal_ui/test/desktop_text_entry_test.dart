import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderEditable, RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/padded_host.dart';

/// Geist's cap height over its em: the capitals Minimal centres a line by.
const double _capHeight = 0.710;

/// Where the capitals of the line under [root] (its editable, or its
/// paragraph) are drawn, their middle in global coordinates: the baseline on
/// the whole logical pixel the engine puts it on, the capitals' height above
/// it, wherever the line is painted (a cap label moves what it paints).
double _capitalsMiddle(RenderObject root) {
  RenderBox? line;
  void visit(RenderObject node) {
    if (line != null) return;
    if (node is RenderEditable || node is RenderParagraph) {
      line = node as RenderBox;
      return;
    }
    node.visitChildren(visit);
  }

  visit(root);
  final box = line!;
  // The size the first words are set in, the spans' styles merged down to
  // them (an empty line's own style's), as ui_core reads it.
  double? sizeOf(InlineSpan? span, [TextStyle? inherited]) {
    if (span == null) return null;
    final own = inherited == null ? span.style : inherited.merge(span.style);
    if (span is TextSpan) {
      if (span.text?.isNotEmpty ?? false) return own?.fontSize;
      for (final child in span.children ?? const <InlineSpan>[]) {
        final found = sizeOf(child, own);
        if (found != null) return found;
      }
    }
    return inherited == null ? own?.fontSize : null;
  }

  final (size, scaler) = switch (box) {
    final RenderParagraph p => (sizeOf(p.text), p.textScaler),
    final RenderEditable e => (sizeOf(e.text), e.textScaler),
    _ => (null, TextScaler.noScaling),
  };
  final fontSize = scaler.scale(size ?? 14);
  final laid = box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;
  final baseline = (laid + 0.5).floorToDouble();
  return box.localToGlobal(Offset(0, baseline - _capHeight * fontSize / 2)).dy;
}

void main() {
  // Material's density is compact on a desktop (a web build opened on one
  // too), and tests run as Android unless told otherwise. Every part you
  // type into, under a desktop platform: the size it has on a phone, its
  // words where they stand on a phone, and a single line's words (the hint,
  // then what was typed) centred in their box within half a pixel.
  group('text entry on a desktop platform', () {
    const entry = Key('entry');
    final parts =
        <
          String,
          ({Widget part, List<String> words, String? type, bool centred})
        >{
          'MinimalTextField': (
            part: const MinimalTextField(hintText: 'Ana Ruiz'),
            words: ['Ana Ruiz'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalTextArea': (
            part: const MinimalTextArea(hintText: 'Anything'),
            words: ['Anything'],
            type: 'Bo',
            centred: false,
          ),
          'MinimalSearchField': (
            part: const MinimalSearchField(hintText: 'Search habits'),
            words: ['Search habits'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalCombobox': (
            part: const MinimalCombobox<String>(
              options: ['Lisbon', 'London'],
              hintText: 'City',
            ),
            words: ['City'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalInputGroup': (
            part: const MinimalInputGroup(
              hintText: 'site',
              prefixText: 'https://',
            ),
            words: ['site', 'https://'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalPasswordField': (
            part: const MinimalPasswordField(hintText: 'Password'),
            words: ['Password'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalInputOtp': (
            part: const MinimalInputOtp(length: 4),
            words: [],
            type: '12',
            centred: true,
          ),
          'MinimalComposer': (
            part: const MinimalComposer(hintText: 'Comment on Morning run'),
            words: ['Comment on Morning run'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalComposer assistant': (
            part: const MinimalComposer(
              hintText: 'Ask anything',
              variant: MinimalComposerVariant.assistant,
            ),
            words: ['Ask anything'],
            type: 'Bo',
            centred: false,
          ),
          'MinimalNumberField': (
            part: MinimalNumberField(
              value: 2,
              min: 0,
              max: 9,
              onChanged: (_) {},
            ),
            words: ['2'],
            type: null,
            centred: true,
          ),
          'MinimalInputRow': (
            part: const MinimalInputRow(
              labelText: 'Name',
              hintText: 'Ana Ruiz',
            ),
            words: ['Ana Ruiz'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalSelect': (
            part: MinimalSelect<String>(
              labelText: 'Plan',
              value: 'pro',
              options: const [
                MinimalSelectOption('free', 'Free'),
                MinimalSelectOption('pro', 'Pro'),
              ],
              onChanged: (_) {},
            ),
            words: ['Pro'],
            type: null,
            centred: true,
          ),
          'MinimalMultiSelect': (
            part: MinimalMultiSelect<String>(
              values: const [],
              options: const ['Lisbon', 'London'],
              hintText: 'Add cities',
              onChanged: (_) {},
            ),
            words: ['Add cities'],
            type: 'Bo',
            centred: true,
          ),
          'MinimalColorPicker': (
            part: MinimalColorPicker(
              value: const Color(0xFF3B82F6),
              onChanged: (_) {},
            ),
            words: [],
            type: '#ABCDEF',
            centred: true,
          ),
        };

    /// Whether [d] draws a frame: the box a field's words stand in.
    bool frames(Decoration d) => switch (d) {
      ShapeDecoration(:final shape) =>
        shape is OutlinedBorder && shape.side.style != BorderStyle.none,
      BoxDecoration(:final border) => border != null,
      _ => false,
    };

    /// The part's size, and for each of its words their place in the part
    /// and their centre's distance from their box's (and, in the composer,
    /// the send seat's centre's distance from the line's), with the part
    /// wrapped in [wrap]: larger text, or an app's own Material theme.
    Future<
      ({
        Size size,
        Map<String, Offset> at,
        Map<String, double> off,
        double? seat,
      })
    >
    see(
      WidgetTester tester,
      String name,
      ({Widget part, List<String> words, String? type, bool centred}) c, {
      Widget Function(BuildContext context, Widget part)? wrap,
    }) async {
      await tester.pumpWidget(const SizedBox());
      // A fresh theme each time: the look builds its Material bridge once
      // per theme, under the platform of the moment.
      await tester.pumpWidget(
        paddedHost(
          // Pinned: this compares platforms at one density, and an unset
          // density is compact on a desktop by design; and for one input, a
          // finger's, as a touch screen on a desktop is (a pointer's 24 px
          // floor lays out less room round the same faces).
          density: MinimalDensity.standard,
          RawTapTargetScope(
            targets: const RawTapTargets(input: RawInput.touch),
            child: SizedBox(
              width: 320,
              child: KeyedSubtree(
                key: entry,
                child: wrap == null
                    ? c.part
                    : Builder(builder: (context) => wrap(context, c.part)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final root = find.byKey(entry);
      final origin = tester.getTopLeft(root);
      final at = <String, Offset>{};
      final off = <String, double>{};
      double? seat;
      void read(String words) {
        final text = find.descendant(of: root, matching: find.text(words));
        final rect = tester.getRect(text.first);
        final box = tester.getRect(
          find
              .ancestor(
                of: text.first,
                matching: find.byWidgetPredicate(
                  (w) => w is DecoratedBox && frames(w.decoration),
                ),
              )
              .first,
        );
        at[words] = rect.topLeft - origin;
        // A one-line line by its capitals; an entry that may wrap by its
        // line, as ui_core keeps it (it moves as lines come and go).
        final field = find.ancestor(
          of: text.first,
          matching: find.byType(TextField),
        );
        final wraps =
            field.evaluate().isNotEmpty &&
            (tester.widget<TextField>(field.first).maxLines ?? 0) != 1;
        final middle = wraps
            ? rect.center.dy
            : _capitalsMiddle(tester.renderObject(text.first));
        off[words] = middle - box.center.dy;
        final send = find.descendant(
          of: root,
          matching: find.byType(MinimalComposerAction),
        );
        if (name == 'MinimalComposer' && seat == null) {
          seat = tester.getRect(send).center.dy - middle;
        }
      }

      c.words.forEach(read);
      final type = c.type;
      if (type != null) {
        await tester.enterText(
          find.descendant(of: root, matching: find.byType(EditableText)).first,
          type,
        );
        await tester.pumpAndSettle();
        // A code field shows each digit in a cell of its own.
        read(name == 'MinimalInputOtp' ? type[0] : type);
      }
      final size = tester.getSize(root);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      return (size: size, at: at, off: off, seat: seat);
    }

    /// An app's own Material theme between the look and the part, setting
    /// what a text field's decoration would otherwise take from it.
    Widget hostTheme(BuildContext context, Widget part) => Theme(
      data: Theme.of(context).copyWith(
        visualDensity: VisualDensity.compact,
        inputDecorationTheme: const InputDecorationThemeData(
          contentPadding: EdgeInsets.all(20),
          isDense: true,
          constraints: BoxConstraints(minHeight: 56),
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      child: part,
    );

    /// Text half as large again, as a reader's setting makes it.
    Widget largerText(BuildContext context, Widget part) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.5)),
      child: part,
    );

    void sameAs(
      ({
        Size size,
        Map<String, Offset> at,
        Map<String, double> off,
        double? seat,
      })
      phone,
      ({
        Size size,
        Map<String, Offset> at,
        Map<String, double> off,
        double? seat,
      })
      other,
      String where,
    ) {
      expect(
        other.size,
        phone.size,
        reason: 'the size it has on a phone $where',
      );
      for (final words in phone.at.keys) {
        expect(
          (other.at[words]! - phone.at[words]!).distance,
          lessThan(0.5),
          reason: '"$words" where it stands on a phone $where',
        );
      }
    }

    void centred(
      ({
        Size size,
        Map<String, Offset> at,
        Map<String, double> off,
        double? seat,
      })
      seen,
      ({Widget part, List<String> words, String? type, bool centred}) c,
      String where,
    ) {
      if (c.centred) {
        for (final MapEntry(key: words, value: off) in seen.off.entries) {
          expect(
            off.abs(),
            lessThanOrEqualTo(0.5),
            reason: '"$words" centred in its box $where',
          );
        }
      }
      final seat = seen.seat;
      if (seat != null) {
        expect(
          seat.abs(),
          lessThanOrEqualTo(0.5),
          reason: 'the send seat centred on the line $where',
        );
      }
    }

    for (final MapEntry(key: name, value: c) in parts.entries) {
      testWidgets('$name stands as on a phone, its line centred', (
        tester,
      ) async {
        final phone = await see(tester, name, c);
        centred(phone, c, 'on a phone');
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final desk = await see(tester, name, c);
          sameAs(phone, desk, 'on a desktop');
          centred(desk, c, 'on a desktop');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('$name keeps its line under an app\'s Material theme', (
        tester,
      ) async {
        final phone = await see(tester, name, c);
        final hosted = await see(tester, name, c, wrap: hostTheme);
        sameAs(phone, hosted, 'under an app\'s theme');
        centred(hosted, c, 'under an app\'s theme');
      });

      testWidgets('$name keeps its line centred in larger text', (
        tester,
      ) async {
        centred(
          await see(tester, name, c, wrap: largerText),
          c,
          'at text scale 1.5',
        );
      });
    }
  });
}
