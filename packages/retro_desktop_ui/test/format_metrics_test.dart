import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('English formatters work before a delegate loads date symbols', () {
    expect(RetroDesktopFormat.number(1234.5), '1,234.5');
    expect(RetroDesktopFormat.integer(7, digits: 2), '07');
    expect(
      RetroDesktopFormat.monthYear(DateTime(2026, 11, 7)),
      'November 2026',
    );
    expect(RetroDesktopFormat.date(DateTime(2026, 11, 7)), 'November 7, 2026');
    expect(RetroDesktopFormat.percent(.42), '42%');
  });
  test('formatters honor explicitly loaded locale symbols', () async {
    await initializeDateFormatting('de');
    expect(RetroDesktopFormat.number(1234.5, locale: 'de'), '1.234,5');
    expect(
      RetroDesktopFormat.monthYear(DateTime(2026, 3), locale: 'de'),
      'März 2026',
    );
  });
  testWidgets('chrome minimum follows the host platform', (tester) async {
    late double minimum;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => RetroDesktopTheme(
          data: RetroDesktopThemeData.classic(Brightness.light),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            minimum = RetroDesktopChromeMetrics.targetOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final touch = [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ].contains(defaultTargetPlatform);
    expect(minimum, touch ? 48 : 44);
  }, variant: TargetPlatformVariant.all());
}
