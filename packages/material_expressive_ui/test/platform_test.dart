/// Platform policy (CONTRACT §5, decision F8): Material look on both
/// platforms, behaviour by `Theme.of(context).platform`, never pinned by
/// the host. Under each platform, inside [ExpressiveHost]: a screen's
/// scroll overscrolls the platform's way (Android's stretch, iOS's
/// rubber band), a text field's long press raises the platform's selection
/// handles and edit menu, and the back glyph is Material's arrow on both.
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoNavigationBarBackButton,
        CupertinoTextSelectionControls,
        CupertinoTextSelectionToolbar;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

Widget _app(Widget home) => MaterialApp(
  builder: (context, app) => ExpressiveHost(child: app!),
  home: home,
);

Widget _rows() => Column(
  children: <Widget>[
    for (var i = 0; i < 40; i++)
      SizedBox(height: ExpressiveSpacing.s48, child: Text('Row $i')),
  ],
);

/// Runs [body] with the platform overridden to [platform].
Future<void> _on(TargetPlatform platform, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

/// Whether [physics] or any physics it applies to is [T].
bool _has<T extends ScrollPhysics>(ScrollPhysics? physics) {
  for (var p = physics; p != null; p = p.parent) {
    if (p is T) return true;
  }
  return false;
}

void main() {
  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    final android = platform == TargetPlatform.android;

    testWidgets('${platform.name}: a screen overscrolls the platform\'s way '
        '(${android ? 'stretch' : 'rubber band'}), collapsing or not', (
      tester,
    ) async {
      await _on(platform, () async {
        for (final title in <String?>['Journal', null]) {
          await tester.pumpWidget(
            _app(
              ExpressiveScaffold(
                key: ValueKey<String?>(title),
                title: title,
                body: _rows(),
              ),
            ),
          );
          final scrollable = find.byType(Scrollable).first;
          final physics = tester
              .state<ScrollableState>(scrollable)
              .position
              .physics;
          expect(
            find.byType(StretchingOverscrollIndicator),
            android ? findsWidgets : findsNothing,
            reason: 'title: $title',
          );
          expect(find.byType(GlowingOverscrollIndicator), findsNothing);
          expect(
            _has<BouncingScrollPhysics>(physics),
            !android,
            reason: 'title: $title',
          );
          expect(
            _has<ClampingScrollPhysics>(physics),
            android,
            reason: 'title: $title',
          );
        }
      });
    });

    testWidgets('${platform.name}: a long press in a text field raises the '
        '${android ? 'Material' : 'Cupertino'} selection handles and menu', (
      tester,
    ) async {
      await _on(platform, () async {
        final controller = TextEditingController(text: 'Morning pages');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _app(
            ExpressiveScaffold(
              title: 'Entry',
              body: ExpressiveTextField(controller: controller, label: 'Note'),
            ),
          ),
        );
        final editable = find.byType(EditableText);
        await tester.longPress(editable);
        await tester.pumpAndSettle();

        final state = tester.state<EditableTextState>(editable);
        expect(state.selectionOverlay?.toolbarIsVisible, isTrue);
        expect(state.selectionOverlay?.handlesAreVisible, isTrue);
        final controls = tester
            .widget<EditableText>(editable)
            .selectionControls;
        if (android) {
          expect(controls, isA<MaterialTextSelectionControls>());
          expect(find.byType(TextSelectionToolbar), findsOneWidget);
          expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        } else {
          expect(controls, isA<CupertinoTextSelectionControls>());
          expect(find.byType(CupertinoTextSelectionToolbar), findsOneWidget);
          expect(find.byType(TextSelectionToolbar), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('${platform.name}: the back glyph is Material\'s arrow', (
      tester,
    ) async {
      await _on(platform, () async {
        await tester.pumpWidget(
          _app(const ExpressiveScaffold(body: SizedBox())),
        );
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(
              PageRouteBuilder<void>(
                pageBuilder: (context, _, _) =>
                    const ExpressiveScaffold(title: 'Entry', body: SizedBox()),
              ),
            );
        await tester.pumpAndSettle();
        expect(find.byIcon(ExpressiveSymbols.arrowBack), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
        expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
        expect(find.byType(BackButtonIcon), findsNothing);
        expect(find.byType(CupertinoNavigationBarBackButton), findsNothing);
      });
    });
  }
}
