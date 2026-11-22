/// A loss reads as one: a menu's or a menu bar's destructive item and a
/// dialog's destructive action set their words in the `error` role (a
/// filled one fills in it),
/// and the error state stands its glyph on a round `errorContainer` ground,
/// the empty state's sibling.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

Widget host(Widget child) => MaterialApp(
  builder: (context, app) =>
      ExpressiveHost(light: bloom, brightness: Brightness.light, child: app!),
  home: Padding(
    padding: const EdgeInsets.all(24),
    child: Align(alignment: AlignmentDirectional.topStart, child: child),
  ),
);

/// The round ground a state's glyph stands on: the nearest surface round it.
ExpressiveSurface groundOf(WidgetTester tester, IconData glyph) =>
    tester.widget<ExpressiveSurface>(
      find
          .ancestor(
            of: find.byIcon(glyph),
            matching: find.byType(ExpressiveSurface),
          )
          .first,
    );

void main() {
  testWidgets("a menu's destructive item is set in the error role", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => ExpressiveTextButton(
            'Actions',
            onPressed: () => showExpressiveMenu(
              context,
              entries: [
                ExpressiveMenuItem('Mark done', onPressed: () {}),
                ExpressiveMenuItem(
                  'Delete',
                  icon: ExpressiveSymbols.delete,
                  destructive: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    // The colour the words are painted in.
    Color? colour(String label) => tester
        .widget<RichText>(
          find.descendant(
            of: find.text(label),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style
        ?.color;
    expect(colour('Delete'), bloom.colors.error);
    expect(colour('Mark done'), isNot(bloom.colors.error));
  });

  testWidgets("a menu bar's destructive entry is set in the error role", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        ExpressiveMenuBar(
          menus: [
            ExpressiveMenuBarEntry(
              'File',
              children: [
                ExpressiveMenuBarEntry('Rename', onPressed: () {}),
                ExpressiveMenuBarEntry(
                  'Delete',
                  destructive: true,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    Color? colour(String label) => tester
        .widget<RichText>(
          find.descendant(
            of: find.text(label),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style
        ?.color;
    expect(colour('Delete'), bloom.colors.error);
    expect(colour('Rename'), isNot(bloom.colors.error));
  });

  testWidgets("a dialog's destructive action is set in the error role", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 360,
          child: Column(
            children: [
              ExpressiveDialog(
                title: 'Unsaved changes',
                actions: [
                  ExpressiveDialogAction('Cancel'),
                  ExpressiveDialogAction('Discard', destructive: true),
                ],
              ),
              ExpressiveDialog(
                title: 'Delete this trip?',
                actions: [
                  ExpressiveDialogAction('Keep'),
                  ExpressiveDialogAction(
                    'Delete',
                    filled: true,
                    destructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    Color? words(String label) => tester
        .renderObject<RenderParagraph>(find.text(label))
        .text
        .style
        ?.color;
    expect(words('Discard'), bloom.colors.error);
    expect(words('Cancel'), isNot(bloom.colors.error));
    // A filled one: `error` under `onError`.
    final fill = tester.widget<ExpressiveSurface>(
      find
          .ancestor(
            of: find.text('Delete'),
            matching: find.byType(ExpressiveSurface),
          )
          .first,
    );
    expect(fill.color, bloom.colors.error);
    expect(words('Delete'), bloom.colors.onError);
  });

  testWidgets("the error state stands on the empty state's round ground", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 360,
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: ExpressiveEmptyState(
                  icon: ExpressiveSymbols.inbox,
                  title: 'No tasks here',
                ),
              ),
              SizedBox(
                height: 290,
                child: ExpressiveErrorState(
                  title: 'Couldn’t load the workspace',
                  message: 'Try again to load the team’s latest work.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final empty = groundOf(tester, ExpressiveSymbols.inbox);
    final error = groundOf(tester, ExpressiveSymbols.error);
    expect(error.shape, empty.shape);
    expect(error.color, bloom.colors.errorContainer);
    expect(
      tester.getSize(find.byWidget(error)),
      tester.getSize(find.byWidget(empty)),
    );
  });
}
