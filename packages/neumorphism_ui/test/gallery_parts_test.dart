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
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  for (final page in galleryPages) {
    for (final (preset, b) in presetsAndModes) {
      testWidgets(
        '${page.id} in $preset ${b.name}: each section matches its golden',
        (tester) async {
          if (!_recorded) return;
          await pumpGalleryPage(tester, page, preset, b);
          final found = sections();
          expect(found, isNotEmpty);
          for (final (label, section) in found) {
            await expectLater(
              section,
              matchesGoldenFile(
                'goldens/${page.id}/${slug(label)}/${preset}_${b.name}.png',
              ),
            );
          }
        },
        // Pixels recorded on macOS: `flutter test --exclude-tags goldens` leaves them out elsewhere.
        tags: const ['goldens'],
      );
    }

    // A nested app or Navigator (a demo app, a preview) puts up a modal barrier whose semantics hide what was painted
    // before it in the same container: the page above it goes silent. Every heading must be in the tree.
    testWidgets('${page.id}: a screen reader finds every section heading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpGalleryPage(tester, page, 'porcelain', Brightness.light);
        final labels = <String>[];
        bool visit(SemanticsNode node) {
          labels.addAll(node.getSemanticsData().label.split('\n'));
          node.visitChildren(visit);
          return true;
        }

        visit(
          RendererBinding
              .instance
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
        );
        for (final (label, _) in sections()) {
          expect(
            labels,
            contains(label),
            reason:
                '${page.id}: the heading "$label" is not in the semantics tree',
          );
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      '${page.id}: each section says what it is, and every control its role and name',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpGalleryPage(tester, page, 'porcelain', Brightness.light);
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
              // A region that offers its menu (NeumorphicContextMenu) is content, not a control: its only acts are the
              // long press and the custom action that show the menu, as a row or a picture with a menu is read. What
              // it holds keeps its own roles (the Hall lamp's switch).
              final menuOnly =
                  d.hasAction(SemanticsAction.longPress) &&
                  d.hasAction(SemanticsAction.customAction) &&
                  !d.hasAction(SemanticsAction.tap) &&
                  !d.hasAction(SemanticsAction.increase) &&
                  !d.hasAction(SemanticsAction.decrease);
              // A node that steps up and down is adjustable: that is its role, as a page control's is.
              final role =
                  menuOnly ||
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
              'test/goldens/${page.id}/${slug(label)}/semantics.txt',
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
        } finally {
          handle.dispose();
        }
      },
    );
  }
}
