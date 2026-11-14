// The host and an app's words and direction: under FrostedHost a page keeps
// the Material words its app gives (a translation stands), and the
// direction the app sets around the host. An app with no Material words
// (a WidgetsApp) gets Flutter's English ones from the host, and still keeps
// its direction: a Localizations sets its own locale's direction under it,
// which once turned every page under the host left to right.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_host.dart';

class _Fine extends DefaultMaterialLocalizations {
  @override
  String get okButtonLabel => 'Fine';
}

class _FineDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _FineDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(_Fine());

  @override
  bool shouldReload(_FineDelegate old) => false;
}

void main() {
  late BuildContext page;
  final probe = Builder(
    builder: (context) {
      page = context;
      return const SizedBox.shrink();
    },
  );

  testWidgets('an app\'s own Material words stand under the host', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_FineDelegate()],
        builder: (context, child) =>
            FrostedHost(brightness: Brightness.light, child: child!),
        home: probe,
      ),
    );
    expect(MaterialLocalizations.of(page).okButtonLabel, 'Fine');
  });

  testWidgets('the direction set around the host reaches the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: FrostedHost(brightness: Brightness.light, child: child!),
        ),
        home: probe,
      ),
    );
    expect(Directionality.of(page), TextDirection.rtl);
  });

  testWidgets('an app with no Material words gets them and keeps its '
      'direction', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: FrostedHost(brightness: Brightness.light, child: probe),
        ),
      ),
    );
    expect(MaterialLocalizations.of(page).okButtonLabel, 'OK');
    expect(Directionality.of(page), TextDirection.rtl);
  });
}
