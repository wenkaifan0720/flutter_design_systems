// Every Ledger part a person types into keeps its line where it is drawn: the
// typed words and the hint in the middle of the box, the hint on the words'
// baseline, and the same size and line as Android, iOS and macOS (design6 I3
// and its desktop rule: a field 8 px shorter on a Mac is the fault this finds).
// Read through the foundation's check, under the look at each density, at a 1.5
// text scale, and under a host InputDecorationTheme that would move a field
// which left its padding or its minimum to the theme.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    // The look names its faces as the package that bundles them registers
    // them (ledgerFontFamily); a family a package already names keeps it.
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// The look as an app's page gets it, at [density], with [scale] text and a
/// host's [decorations] above it.
DesignAlignmentTheme _under({
  LedgerDensity density = LedgerDensity.standard,
  double scale = 1,
  InputDecorationTheme? decorations,
}) =>
    (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: decorations == null
          ? null
          : ThemeData(inputDecorationTheme: decorations),
      builder: (context, page) => LedgerHost(
        light: LedgerThemeData.light(density: density),
        dark: LedgerThemeData.dark(density: density),
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: page!,
        ),
      ),
      home: Material(
        type: MaterialType.transparency,
        child: Center(child: SizedBox(width: 320, child: child)),
      ),
    );

void main() {
  setUpAll(_loadFonts);

  testWidgets('every text entry keeps its line on every platform', (t) async {
    final report = await DesignTextEntryCheck(
      look: 'Ledger',
      themes: {
        'standard': _under(),
        'comfortable': _under(density: LedgerDensity.comfortable),
        'compact': _under(density: LedgerDensity.compact),
        'text 1.5': _under(scale: 1.5),
        'host decorations': _under(
          decorations: const InputDecorationTheme(
            contentPadding: EdgeInsets.fromLTRB(4, 18, 12, 2),
            constraints: BoxConstraints(minHeight: 64),
            isDense: true,
          ),
        ),
      },
      entries: {
        'LedgerTextField': (context, controller, hint) =>
            LedgerTextField(controller: controller, hint: hint),
        'LedgerTextField, a sum': (context, controller, hint) =>
            LedgerTextField(prefix: r'$', controller: controller, hint: hint),
        'LedgerSearchField': (context, controller, hint) =>
            LedgerSearchField(controller: controller, hint: hint),
        'LedgerComposer': (context, controller, hint) =>
            LedgerComposer(controller: controller, hint: hint),
      },
    ).check(pump: t.pumpWidget);
    report.verify();
  });

  // The check measures an entry's line against the entry's whole box, so a
  // field with its label over the rule is measured here instead: its typed
  // line in the middle of the line it is written on (the 48 entry box under
  // the label), as Android and as macOS, the same size on both.
  testWidgets('a labelled field writes its words in the middle of its line', (
    t,
  ) async {
    final sizes = <TargetPlatform, Size>{};
    for (final platform in const [
      TargetPlatform.android,
      TargetPlatform.macOS,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      final words = TextEditingController(text: 'Blue Fern Café');
      await t.pumpWidget(
        _under()(
          t.binding.rootElement!,
          LedgerTextField(
            label: 'Payee',
            helper: 'Who was paid',
            controller: words,
          ),
        ),
      );
      final field = t.renderObject<RenderBox>(find.byType(LedgerTextField));
      final editable = t.allRenderObjects.whereType<RenderEditable>().single;
      // The line it is written on: the editable's nearest box of the line's
      // height (48 at the standard density the host sets; a theme left to
      // its default density would read the platform's, compact on macOS).
      final height = LedgerTextField.heightOf(
        LedgerThemeData.light(density: LedgerDensity.standard),
      );
      var up = editable.parent!;
      while (up is! RenderBox || up.size.height != height) {
        up = up.parent!;
      }
      final line = up;
      final middle = line.localToGlobal(line.size.center(Offset.zero)).dy;
      final typed = editable
          .localToGlobal(editable.size.center(Offset.zero))
          .dy;
      expect(
        (typed - middle).abs(),
        lessThanOrEqualTo(.5),
        reason: platform.name,
      );
      sizes[platform] = field.size;
      await t.pumpWidget(const SizedBox());
      words.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
    expect(sizes[TargetPlatform.macOS], sizes[TargetPlatform.android]);
  });
}
