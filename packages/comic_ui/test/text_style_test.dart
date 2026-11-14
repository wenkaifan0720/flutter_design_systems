// No text in Comic ever falls back to Flutter's unstyled text (Material's yellow double underline). Every gallery page
// is built under a bare WidgetsApp whose root text style IS that fallback, with only Comic's theme installed in its
// builder. Then every press on the page is pressed once, so each menu, dialog, sheet, picker, toast and tooltip it
// opens is drawn in an Overlay or a new route, and every paragraph and edited line on screen must carry a Comic face.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/design_review.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'gallery_support.dart';
import 'support.dart';

/// Material's fallback for text with no style above it.
const _fallback = TextStyle(
  color: Color(0xD0FF0000),
  fontFamily: 'monospace',
  fontSize: 48,
  fontWeight: FontWeight.w900,
  decoration: TextDecoration.underline,
  decorationColor: Color(0xFFFFFF00),
  decorationStyle: TextDecorationStyle.double,
);

final _navigator = GlobalKey<NavigatorState>();

Widget _bare(ComicThemeData theme, Widget page) => WidgetsApp(
  navigatorKey: _navigator,
  color: theme.colors.primary,
  textStyle: _fallback,
  debugShowCheckedModeBanner: false,
  builder: (context, child) => ComicTheme(data: theme, child: child!),
  pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
  home: KitGalleryScope(child: page),
);

/// Every unstyled run of text on screen, described.
List<String> _unstyled(WidgetTester tester) {
  final found = <String>[];
  void check(InlineSpan span, String where) {
    span.visitChildren((child) {
      final style = child.style;
      if (child is TextSpan && (child.text ?? '').trim().isNotEmpty) {
        // The span's own style has the inherited one merged in by Text/RichText; walk up through the tree.
        if (style != null &&
            (style.decorationStyle == TextDecorationStyle.double ||
                style.decorationColor == _fallback.decorationColor ||
                style.fontFamily == 'monospace')) {
          found.add('$where: "${child.text}" wears the fallback');
        }
      }
      return true;
    });
  }

  for (final element
      in find
          .byWidgetPredicate((w) => w is RichText || w is EditableText)
          .evaluate()) {
    final ro = element.renderObject;
    final owner =
        element.findAncestorWidgetOfExactType<ComicPressable>()?.label ??
        element.toStringShort();
    if (ro is RenderParagraph) {
      final style = ro.text.style;
      final family = style?.fontFamily;
      if (family == null || family == 'monospace') {
        // A span tree whose root is unstyled is fine only if every leaf styles itself.
        var leavesStyled = true;
        ro.text.visitChildren((s) {
          if (s is TextSpan &&
              (s.text ?? '').trim().isNotEmpty &&
              (s.style?.fontFamily ?? family) == null) {
            leavesStyled = false;
          }
          return true;
        });
        if (!leavesStyled || family == 'monospace') {
          found.add('$owner: "${ro.text.toPlainText()}" has no Comic face');
        }
      }
      check(ro.text, owner);
    } else if (ro is RenderEditable) {
      final text = ro.text;
      if (text != null) {
        if (text.style?.fontFamily == null) {
          found.add('$owner: edited "${text.toPlainText()}" has no Comic face');
        }
        check(text, owner);
      }
    }
  }
  return found;
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });
  final pages = [
    ...galleryPages,
    ...reviewPages,
    (id: 'review-corners', title: 'Corners', build: reviewCorners),
  ];
  for (final mode in Brightness.values) {
    final theme = ComicThemeData.preset('offset', mode);
    for (final page in pages) {
      testWidgets('${mode.name}: ${page.id} and all it opens are styled', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 2400);
        addTearDown(tester.view.reset);
        Future<void> pump() async {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(_bare(theme, page.build(mode)));
          await settle(tester);
        }

        await pump();
        final failures = <String>{..._unstyled(tester)};
        final count = find.byType(ComicPressable).evaluate().length;
        for (var i = 0; i < count; i++) {
          final presses = find.byType(ComicPressable);
          if (i >= presses.evaluate().length) break;
          final press = presses.at(i);
          final widget = tester.widget<ComicPressable>(press);
          if (widget.onPressed == null) continue;
          final rect = tester.getRect(press);
          if (rect.center.dy < 0 || rect.center.dy > 2400) continue;
          await tester.tapAt(rect.center);
          await settle(tester);
          failures.addAll(_unstyled(tester));
          // A route it pushed (a dialog, a sheet, a menu, a picker) is closed by building the page afresh.
          if (_navigator.currentState?.canPop() ?? false) await pump();
        }
        // A tooltip and the text field's own editing menu are opened by holding.
        for (final tip in find.byType(ComicTooltip).evaluate().toList()) {
          if (!tip.mounted) continue;
          final box = tip.renderObject as RenderBox?;
          if (box == null || !box.attached) continue;
          final gesture = await tester.startGesture(
            box.localToGlobal(box.size.center(Offset.zero)),
          );
          await tester.pump(const Duration(seconds: 1));
          failures.addAll(_unstyled(tester));
          await gesture.up();
          await settle(tester);
        }
        for (final field in find.byType(EditableText).evaluate().toList()) {
          if (!field.mounted) continue;
          final state = (field as StatefulElement).state as EditableTextState;
          if (state.widget.controller.text.isEmpty) continue;
          state.widget.focusNode.requestFocus();
          await tester.pump();
          state.selectAll(SelectionChangedCause.toolbar);
          state.showToolbar();
          await settle(tester);
          failures.addAll(_unstyled(tester));
          state.hideToolbar();
          state.widget.focusNode.unfocus();
          await settle(tester);
        }
        expect(tester.takeException(), isNull);
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
    testWidgets('${mode.name}: raised surfaces shown from code are styled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _bare(
          theme,
          Builder(
            builder: (context) => ComicColumn(
              children: [
                ComicButton.filled(
                  'Snack',
                  onPressed: () => showComicSnackBar(
                    context,
                    'Saved to drafts',
                    actionLabel: 'Undo',
                    onAction: () {},
                  ),
                ),
                ComicButton.filled(
                  'Toast',
                  onPressed: () => showComicToast(context, 'Link copied'),
                ),
              ],
            ),
          ),
        ),
      );
      await settle(tester);
      // Each button by its press's own node: a filled button's room spans the column, its face at the start.
      await tester.tap(find.bySemanticsLabel('Snack'));
      await settle(tester);
      expect(find.text('Saved to drafts'), findsOneWidget);
      expect(_unstyled(tester), isEmpty);
      await tester.tap(find.bySemanticsLabel('Toast'));
      await settle(tester);
      expect(find.text('Link copied'), findsOneWidget);
      expect(_unstyled(tester), isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
    });
  }
}
