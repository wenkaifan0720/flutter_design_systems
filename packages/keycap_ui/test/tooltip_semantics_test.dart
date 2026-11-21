// A tooltip reads on the control it explains: one node, the control's role
// and name with the tooltip's words, as Flutter's IconButton(tooltip:) reads.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('a tooltip reads on its key, one node', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: RawWidgetsLocalizations.supportedLocales,
        builder: (context, child) => KeycapTheme(
          data: KeycapThemeData.of(Brightness.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Material(
          child: Center(
            child: KeycapTooltip(
              message: 'Copy a link to share',
              child: KeycapIconButton(
                icon: const Icon(LucideIcons.share),
                semanticLabel: 'Share',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Share')),
      isSemantics(
        label: 'Share',
        tooltip: 'Copy a link to share',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
