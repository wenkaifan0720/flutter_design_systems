/// The spacing scale: w1-tokens' test, with `spacing.dart`, its generated
/// `internal/spacing/` part and the generator's `emit/spacing.ts`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/spacing/spacing.g.dart';

void main() {
  test('is Material\'s 8dp scale, space0 to space900', () {
    expect(ExpressiveSpacing.scale, <double>[
      0, 2, 4, 6, 8, 10, 12, 14, 16, 20, 24, 32, 36, 40, 48, 56, 64, 72, //
    ]);
    expect(ExpressiveSpacing.scale, SpacingTokens.scale);
  });

  test('each member is named for its length', () {
    final members = <String, double>{
      's0': ExpressiveSpacing.s0,
      's2': ExpressiveSpacing.s2,
      's4': ExpressiveSpacing.s4,
      's6': ExpressiveSpacing.s6,
      's8': ExpressiveSpacing.s8,
      's10': ExpressiveSpacing.s10,
      's12': ExpressiveSpacing.s12,
      's14': ExpressiveSpacing.s14,
      's16': ExpressiveSpacing.s16,
      's20': ExpressiveSpacing.s20,
      's24': ExpressiveSpacing.s24,
      's32': ExpressiveSpacing.s32,
      's36': ExpressiveSpacing.s36,
      's40': ExpressiveSpacing.s40,
      's48': ExpressiveSpacing.s48,
      's56': ExpressiveSpacing.s56,
      's64': ExpressiveSpacing.s64,
      's72': ExpressiveSpacing.s72,
    };
    expect(members.values, ExpressiveSpacing.scale);
    for (final MapEntry(:key, :value) in members.entries) {
      expect(key, 's${value.round()}');
    }
  });

  test('the steps rise and the screen margin is one of them', () {
    final scale = ExpressiveSpacing.scale;
    for (var i = 1; i < scale.length; i++) {
      expect(scale[i], greaterThan(scale[i - 1]));
    }
    expect(scale, contains(ExpressiveChromeMetrics.margin));
  });
}
