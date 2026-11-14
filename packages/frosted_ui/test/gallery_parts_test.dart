// Every gallery section is one component in its states. For each, in every preset by day and by night, a golden of its
// pixels; and for each, once, its semantics: it says something, every node that acts states a role and a name, and the
// tree matches the one recorded beside its goldens. `flutter test --update-goldens` records both.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frosted_ui/frosted_ui.dart';

import 'gallery_support.dart';

/// The page's sections; a live app with none (the screen and shell demos) is one section, the whole page, keyed by
/// [pageKey].
List<(String, Finder)> sectionsOrPage(String pageKey) {
  final found = sections();
  return found.isNotEmpty
      ? found
      : [('page', find.byKey(ValueKey<String>(pageKey)))];
}

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
    await frostedLoadFonts();
    await loadBundledFonts();
  });

  for (final page in galleryPages) {
    for (final (preset, b) in presetsAndModes) {
      testWidgets(
        '${page.id} in $preset ${b.name}: each section matches its golden',
        (tester) async {
          if (!_recorded) return;
          await pumpGalleryPage(tester, page, preset, b);
          final found = sectionsOrPage('${page.id}/$preset/${b.name}');
          for (final (label, section) in found) {
            await expectLater(
              section,
              matchesGoldenFile(
                'goldens/${page.id}/${slug(label)}/${preset}_${b.name}.png',
              ),
            );
          }
        },
        tags: const ['goldens'],
      );
    }

    testWidgets(
      '${page.id}: each section says what it is, and every control its role and name',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpGalleryPage(tester, page, 'opal', Brightness.light);
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
        for (final (label, section) in sectionsOrPage(
          '${page.id}/opal/light',
        )) {
          // A section under an open sheet is not read until the sheet closes: the sheet demo opens with one raised.
          if (ModalRoute.of(tester.element(section))?.isCurrent == false) {
            continue;
          }
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
            reason:
                '$label says nothing (${inside.length} nodes in $rect of '
                '${nodes.length}: ${lines.take(6).join('; ')})',
          );
          for (final d in inside) {
            if (!_acts.any(d.hasAction)) continue;
            final f = d.flagsCollection;
            // A node that steps up and down is adjustable: that is its role, as a page control's is. A node whose one
            // act is a long press with a tooltip is a tooltip's anchor (Compose's `TooltipBox` `onLongClick`), around
            // the control it names, which has its own. A node that taps and dismisses is a modal barrier (Flutter's
            // `ModalBarrier`, Compose's sheet `Scrim`): it closes the route it lies under, neither gives it a role,
            // and its label says what it does.
            final anchor =
                d.tooltip.isNotEmpty &&
                _acts.where(d.hasAction).toSet().difference({
                  SemanticsAction.longPress,
                }).isEmpty;
            final barrier =
                d.hasAction(SemanticsAction.dismiss) &&
                _acts.where(d.hasAction).toSet().difference({
                  SemanticsAction.tap,
                }).isEmpty;
            final role =
                anchor ||
                barrier ||
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
              d.label.isNotEmpty || d.value.isNotEmpty || anchor,
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
        handle.dispose();
      },
    );
  }
}
