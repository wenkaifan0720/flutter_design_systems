/// Badges: the dot and the count, and where `BadgedBox` stands them on an
/// anchor — held to Compose material3 1.5.0-alpha29 `Badge.kt` and
/// `BadgeTokens` (dot 6dp, count 16dp tall with 4dp padding, `error` /
/// `onError`, `labelSmall`; offsets 6dp for a dot, 12dp in and 14dp down for
/// a count).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/badge_anchor.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

const ValueKey<String> _anchor = ValueKey<String>('anchor');
const ValueKey<String> _badge = ValueKey<String>('badge');

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    ExpressiveHost(
      light: _theme,
      brightness: Brightness.light,
      child: Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Center(child: child),
        ),
      ),
    );

Widget _badged(Widget badge) => ExpressiveBadgeAnchor(
  badge: KeyedSubtree(key: _badge, child: badge),
  child: const SizedBox(key: _anchor, width: 24, height: 24),
);

void main() {
  testWidgets('a narrow tag stays one line and keeps its full spoken label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const label = 'A longer label for this item';
    await tester.pumpWidget(
      _app(
        ExpressiveTheme(
          data: _theme,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: const SizedBox(
              width: 120,
              child: ExpressiveTag(label, icon: ExpressiveSymbols.star),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.text(label)).maxLines, 1);
    expect(find.bySemanticsLabel(label), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a dot is 6dp of error, 6dp in from the end and 6dp down', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_badged(const ExpressiveBadge())));
    final anchor = tester.getRect(find.byKey(_anchor));
    final badge = tester.getRect(find.byKey(_badge));
    expect(badge.size, const Size(6, 6));
    expect(badge.left, anchor.right - 6);
    // BadgedBox: y = -height + 6 = 0.
    expect(badge.top, anchor.top);
    final box = tester.widget<ExpressiveSurface>(
      find.descendant(
        of: find.byKey(_badge),
        matching: find.byType(ExpressiveSurface),
      ),
    );
    expect(box.color, _theme.colors.error);
    // The box is the anchor's size.
    expect(
      tester.getSize(find.byType(ExpressiveBadgeAnchor)),
      const Size(24, 24),
    );
  });

  testWidgets('a count is a 16dp pill of labelSmall onError on error, 12dp '
      'in from the end and 14dp down to its bottom', (tester) async {
    await tester.pumpWidget(_app(_badged(ExpressiveBadge.count(3))));
    final anchor = tester.getRect(find.byKey(_anchor));
    final badge = tester.getRect(find.byKey(_badge));
    expect(badge.height, 16);
    final label = tester.getRect(find.text('3'));
    // At least as wide as it is tall; its label plus 4dp a side.
    expect(badge.width, label.width + 8 < 16 ? 16 : label.width + 8);
    expect(badge.left, anchor.right - 12);
    expect(badge.bottom, anchor.top + 14);
    final text = tester.widget<Text>(find.text('3'));
    expect(text.style!.color, _theme.colors.onError);
    expect(text.style!.fontSize, _theme.type.labelSmall.fontSize);
    final box = tester.widget<ExpressiveSurface>(
      find.descendant(
        of: find.byKey(_badge),
        matching: find.byType(ExpressiveSurface),
      ),
    );
    expect(box.color, _theme.colors.error);
  });

  testWidgets('a longer count grows by its label plus 4dp a side, and caps '
      'at "999+"', (tester) async {
    await tester.pumpWidget(_app(_badged(ExpressiveBadge.count(1204))));
    expect(find.text('999+'), findsOneWidget);
    final label = tester.getRect(find.text('999+'));
    final badge = tester.getRect(find.byKey(_badge));
    expect(badge.width, label.width + 8);
    expect(ExpressiveBadge.count(999).label, '999');
    expect(ExpressiveBadge.count(42, max: 9).label, '9+');
  });

  testWidgets('right to left, the badge stands on the start corner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_badged(ExpressiveBadge.count(3)), direction: TextDirection.rtl),
    );
    final anchor = tester.getRect(find.byKey(_anchor));
    final badge = tester.getRect(find.byKey(_badge));
    expect(badge.right, anchor.left + 12);
  });

  testWidgets('the badge is announced by its own label and takes no touch', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _app(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: ExpressiveBadge.count(
            5,
            semanticLabel: '5 unread',
            child: const SizedBox(width: 48, height: 48),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('5 unread'), findsOneWidget);
    await tester.tap(find.text('5'), warnIfMissed: false);
    expect(taps, 1, reason: 'the touch falls through to the anchor');
    semantics.dispose();
  });
}
