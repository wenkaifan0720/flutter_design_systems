// A screen reader reaches the whole page. A Navigator or an app nested in
// another puts a modal barrier in the semantics tree that hides whatever was
// painted before it in the same semantics container, unless it stands in a
// container of its own: StudioPreview's app does, and so does Roomtone's desk
// (a Navigator in StudioScaffold's body), so every section heading of every
// gallery page is read, and on a desk the app's places beside it.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/roomtone/roomtone.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : studioRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Finder _said(String words) =>
    find.bySemanticsLabel(RegExp(RegExp.escape(words)));

void main() {
  setUpAll(_loadFonts);

  // StudioPreview stands a page in an app of its own: set in a page of
  // another app, it hides nothing painted before it.
  for (final presentation in StudioPresentation.values) {
    testWidgets('a ${presentation.name} StudioPreview hides nothing above it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => StudioHost(child: app!),
          home: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: const Text('Above the preview')),
              SizedBox(
                height: 900,
                child: StudioPreview(
                  presentation: presentation,
                  child: const StudioScreen(
                    body: Text('Recorded in one take.'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_said('Above the preview'), findsWidgets);
      expect(_said('Recorded in one take.'), findsWidgets);
      semantics.dispose();
    });
  }

  for (final width in const [390.0, 1440.0]) {
    for (final (i, page) in galleryPages.indexed) {
      testWidgets(
        '${page.id} at ${width.toInt()}: a screen reader reaches every heading',
        (tester) async {
          final semantics = tester.ensureSemantics();
          // Tall enough that every section is laid out.
          tester.view.physicalSize = Size(width, 16000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            RoomtoneApp(
              initialPlace: RoomtonePlace.overview,
              initialAppearance: RoomtoneAppearance.light,
              initialDirection: TextDirection.ltr,
              parts: [
                for (final p in galleryPages) (title: p.title, build: p.build),
              ],
              initialPart: i,
            ),
          );
          // A spinner never settles: let the page arrive, then read it.
          await tester.pump();
          await tester.pump(const Duration(seconds: 3));
          final headings = [
            for (final e in find.byType(KitSection).evaluate())
              (e.widget as KitSection).title,
          ];
          expect(headings, isNotEmpty);
          for (final heading in headings) {
            expect(
              _said(heading),
              findsWidgets,
              reason: '"$heading" on ${page.id} at ${width.toInt()}',
            );
          }
          // On a desk the app's places stand beside the page, painted
          // before it (on a phone the page is pushed over them).
          if (width >= StudioMetrics.desk) {
            for (final place in const ['Home', 'Library', 'Record']) {
              expect(
                _said(place),
                findsWidgets,
                reason: 'the place "$place" beside ${page.id}',
              );
            }
          }
          semantics.dispose();
        },
      );
    }
  }
}
