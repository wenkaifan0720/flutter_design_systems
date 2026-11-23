/// A docked date picker keeps its whole calendar on a phone's screen
/// wherever its field stands, never shrunk or cut by the window's edge:
/// below the field while the calendar fits there inside the menus' 48dp
/// window margin, else above it, else centred on it, as Compose's
/// `DropdownMenuPositionProvider` places a popup.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData baseline = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _host(double top) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => ExpressiveHost(
    theme: baseline,
    brightness: Brightness.light,
    child: app!,
  ),
  home: Stack(
    children: [
      Positioned(
        top: top,
        left: 16,
        right: 16,
        child: ExpressiveDockedDatePicker(
          label: 'Due',
          value: DateTime(2026, 9, 18),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
      ),
    ],
  ),
);

void main() {
  for (final top in const [300.0, 400.0, 500.0, 600.0]) {
    testWidgets('a docked date picker ${top.toInt()} pt down a phone shows '
        'its whole calendar', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(top));
      await tester.tap(find.byType(ExpressiveTextField));
      await tester.pumpAndSettle();

      final field = tester.getRect(find.byType(ExpressiveTextField));
      final calendar = tester.getRect(
        find.byType(ExpressivePopoverSurface).last,
      );
      final picker = tester.getRect(find.byType(ExpressiveDatePicker).last);
      // The calendar stands whole inside the window.
      expect(calendar.top, greaterThanOrEqualTo(0));
      expect(calendar.bottom, lessThanOrEqualTo(844));
      // Nothing of the month is clipped: the surface holds the picker whole.
      expect(calendar.height, greaterThanOrEqualTo(picker.height - .5));
      const margin = 48.0;
      if (field.bottom + calendar.height <= 844 - margin) {
        expect(calendar.top, moreOrLessEquals(field.bottom, epsilon: .5));
      } else if (field.top - calendar.height >= margin) {
        expect(calendar.bottom, moreOrLessEquals(field.top, epsilon: .5));
      } else {
        expect(calendar.top, greaterThanOrEqualTo(margin));
        expect(calendar.bottom, lessThanOrEqualTo(844 - margin));
      }
    });
  }
}
