// Every gallery section is one component in its states. For each, in every preset by day and by night, a golden of its
// pixels; and for each, once, its semantics: it says something, every node that acts states a role and a name, and the
// tree matches the one recorded beside its goldens. `flutter test --update-goldens` records both.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';
import 'support.dart';

/// Every semantics node in the tree, with its rect on the screen.
Iterable<(SemanticsNode, Rect)> placedNodes(
  SemanticsNode node,
  Matrix4 above,
) sync* {
  final at = above.clone();
  if (node.transform != null) at.multiply(node.transform!);
  yield (node, MatrixUtils.transformRect(at, node.rect));
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* placedNodes(child, at);
  }
}

const _acts = [
  SemanticsAction.tap,
  SemanticsAction.longPress,
  SemanticsAction.increase,
  SemanticsAction.decrease,
];

/// A node as one line of the record: its roles and states, its actions, and what it says.
String describe(SemanticsData d) {
  final f = d.flagsCollection;
  final roles = [
    if (f.isButton) 'button',
    if (f.isLink) 'link',
    if (f.isTextField) 'text field',
    if (f.isSlider) 'slider',
    if (f.isHeader) 'header',
    if (f.isImage) 'image',
    if (f.isLiveRegion) 'live',
    if (f.isInMutuallyExclusiveGroup) 'in group',
    if (f.isObscured) 'obscured',
    if (f.isChecked != CheckedState.none) 'checked ${f.isChecked.name}',
    if (f.isToggled != Tristate.none) 'toggled ${f.isToggled.name}',
    if (f.isSelected != Tristate.none) 'selected ${f.isSelected.name}',
    if (f.isExpanded != Tristate.none) 'expanded ${f.isExpanded.name}',
    if (f.isEnabled == Tristate.isFalse) 'disabled',
  ];
  final actions = [
    for (final a in SemanticsAction.values)
      if (d.hasAction(a) && a != SemanticsAction.focus) a.name,
  ]..sort();
  String q(String s) => jsonEncode(s);
  return [
    if (roles.isNotEmpty) roles.join(', '),
    if (actions.isNotEmpty) 'does ${actions.join(' ')}',
    if (d.label.isNotEmpty) 'label ${q(d.label)}',
    if (d.value.isNotEmpty) 'value ${q(d.value)}',
    if (d.hint.isNotEmpty) 'hint ${q(d.hint)}',
    if (d.tooltip.isNotEmpty) 'tooltip ${q(d.tooltip)}',
  ].join(' · ');
}

/// The goldens are kept beside the catalog and laid here by the package build; a published or vendored copy goes
/// without them, and compares nothing.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  for (final page in galleryPages) {
    for (final width in [galleryWidth, 1440.0]) {
      for (final (preset, b) in presetsAndModes) {
        // Every preset on the phone; the primary and an alternate print on desktop.
        if (width == 1440 && preset != 'offset' && preset != 'newsstand') {
          continue;
        }
        testWidgets(
          '${page.id} in $preset ${b.name} at $width: each section matches its golden',
          (tester) async {
            await pumpGalleryPage(tester, page, preset, b, width: width);
            expect(tester.takeException(), isNull);
            final found = sections();
            expect(found, isNotEmpty);
            for (final (label, section) in found) {
              await expectLater(
                section,
                matchesGoldenFile(
                  'goldens/${page.id}/${slug(label)}/${preset}_${b.name}_${width.toInt()}.png',
                ),
              );
            }
          },
          // Pixels recorded on macOS: `flutter test --exclude-tags goldens` leaves them out elsewhere.
          skip: !_recorded,
          tags: const ['goldens'],
        );
      }

      testWidgets(
        '${page.id} at $width: each section says what it is, and every control its role and name',
        (tester) async {
          await pumpGalleryPage(
            tester,
            page,
            'offset',
            Brightness.light,
            width: width,
          );
          expect(tester.takeException(), isNull);
          // The view's own tree, as the guidelines read it. The gallery runs at a pixel ratio of 1, so its rects are
          // the layout's.
          final root = tester
              .binding
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!;
          final nodes = placedNodes(root, Matrix4.identity()).toList();
          for (final (label, section) in sections()) {
            final rect = tester.getRect(section);
            final inside = [
              for (final (node, at) in nodes)
                if (!node.isMergedIntoParent && rect.contains(at.center))
                  node.getSemanticsData(),
            ];
            final lines = [
              for (final d in inside)
                if (describe(d).isNotEmpty) describe(d),
            ];
            expect(
              lines.where((l) => l.contains('label ') || l.contains('value ')),
              isNotEmpty,
              reason: '$label says nothing',
            );
            for (final d in inside) {
              if (!_acts.any(d.hasAction)) continue;
              final f = d.flagsCollection;
              // A node that steps up and down is adjustable: that is its role, as a page control's is.
              final role =
                  d.hasAction(SemanticsAction.increase) ||
                  d.hasAction(SemanticsAction.decrease) ||
                  f.isButton ||
                  f.isLink ||
                  f.isTextField ||
                  f.isSlider ||
                  f.isInMutuallyExclusiveGroup ||
                  f.isChecked != CheckedState.none ||
                  f.isToggled != Tristate.none ||
                  f.isSelected != Tristate.none ||
                  f.isExpanded != Tristate.none;
              expect(
                role,
                isTrue,
                reason: '$label: ${describe(d)} acts with no role',
              );
              expect(
                d.label.isNotEmpty || d.value.isNotEmpty,
                isTrue,
                reason: '$label: ${describe(d)} acts with no name',
              );
            }
            final record = File(
              'test/goldens/${page.id}/${slug(label)}/semantics_${width.toInt()}.txt',
            );
            final text = '${lines.join('\n')}\n';
            if (autoUpdateGoldenFiles) {
              record
                ..createSync(recursive: true)
                ..writeAsStringSync(text);
            } else if (_recorded) {
              expect(
                text,
                record.existsSync() ? record.readAsStringSync() : '(no record)',
                reason: '$label: semantics differ from ${record.path}',
              );
            }
          }
        },
      );
    }
  }
}
