// DesignTextEntryCheck over DesignTextEntryBox: both of its forms pass the
// text entry check. Split from ui_core's control_box_test.dart, which tests
// the box itself.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

// A line exactly as tall as the type, so the numbers are the box's.
const _field = TextStyle(fontSize: 16, height: 1, color: Color(0xFF000000));

// The second form: the decoration draws its own hint.
InputDecoration _pinned(String hint) => InputDecoration(
  isCollapsed: true,
  isDense: false,
  contentPadding: EdgeInsets.zero,
  hintText: hint,
  hintStyle: _field,
  filled: false,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  visualDensity: VisualDensity.standard,
  constraints: const BoxConstraints(),
);

void main() {
  testWidgets('both forms pass the text entry check on every platform, '
      'density, Material 2 and 3, text size and under a host theme', (
    tester,
  ) async {
    const host = InputDecorationTheme(
      contentPadding: EdgeInsets.fromLTRB(20, 24, 20, 8),
      isDense: true,
      constraints: BoxConstraints(minHeight: 56),
    );
    final report = await DesignTextEntryCheck(
      look: 'Bare',
      themes: {
        for (final (name, density) in [
          ('compact', VisualDensity.compact),
          ('standard', VisualDensity.standard),
          ('comfortable', VisualDensity.comfortable),
        ])
          for (final m3 in [true, false])
            for (final scale in [1.0, 1.5])
              '$name M${m3 ? 3 : 2} ×$scale': (context, child) => MaterialApp(
                theme: ThemeData(
                  useMaterial3: m3,
                  visualDensity: density,
                  inputDecorationTheme: host,
                ),
                home: Material(
                  child: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: child,
                    ),
                  ),
                ),
              ),
      },
      entries: {
        // Each wrapped in a cap center (the test font's capitals stand
        // 0.75 em high), as a look puts its line's capitals on the middle.
        'Bare': (context, controller, hint) => SizedBox(
          width: 200,
          child: DesignCapCenter(
            capHeightFactor: 0.75,
            child: DesignTextEntryBox(
              minHeight: 40,
              controller: controller,
              hint: Text(hint, style: _field),
              child: TextField(
                controller: controller,
                style: _field,
                decoration: null,
              ),
            ),
          ),
        ),
        'Pinned': (context, controller, hint) => SizedBox(
          width: 200,
          child: DesignCapCenter(
            capHeightFactor: 0.75,
            child: DesignTextEntryBox(
              minHeight: 40,
              child: TextField(
                controller: controller,
                style: _field,
                decoration: _pinned(hint),
              ),
            ),
          ),
        ),
      },
    ).check(pump: tester.pumpWidget);
    expect(report.problems, isEmpty);
  });
}
