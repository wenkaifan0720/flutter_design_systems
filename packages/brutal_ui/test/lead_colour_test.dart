// The palette's lead block colour has a role's name, lead: it was lime, a
// name a palette broke (Zine's is peach). The old name still answers as the
// same colour wherever it was taken or given.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _peach = Color(0xFFFFC2A1);

BrutalColors _made({Color? lead, Color? lime}) {
  const c = BrutalColors.light();
  return BrutalColors(
    brightness: c.brightness,
    paper: c.paper,
    surface: c.surface,
    ink: c.ink,
    inkMuted: c.inkMuted,
    disabled: c.disabled,
    signal: c.signal,
    onSignal: c.onSignal,
    danger: c.danger,
    onDanger: c.onDanger,
    lead: lead,
    lime: lime,
    blue: c.blue,
    pink: c.pink,
    violet: c.violet,
    onBlock: c.onBlock,
    scrim: c.scrim,
  );
}

void main() {
  test("each palette's lead is its own block colour", () {
    final zine = BrutalThemeData.preset('zine', Brightness.light).colors;
    expect(zine.lead, _peach);
    expect(zine.onColor(zine.lead), zine.onBlock);
    expect(const BrutalColors.light().lead, const Color(0xFFB8F229));
  });

  test('the old name answers as the lead', () {
    for (final id in BrutalThemeData.presets) {
      for (final b in Brightness.values) {
        final c = BrutalThemeData.preset(id, b).colors;
        expect(c.lime, c.lead, reason: '$id ${b.name}');
      }
    }
  });

  test('a lead given by the old name is the lead', () {
    expect(_made(lime: _peach).lead, _peach);
    expect(const BrutalColors.light().copyWith(lime: _peach).lead, _peach);
    expect(
      BrutalThemeData.from(
        signal: const Color(0xFF2F5BFF),
        lime: _peach,
      ).colors.lead,
      _peach,
    );
  });

  test('the new name wins over the old', () {
    const yellow = Color(0xFFFFE066);
    expect(_made(lead: yellow, lime: _peach).lead, yellow);
    expect(
      const BrutalColors.light().copyWith(lead: yellow, lime: _peach).lead,
      yellow,
    );
  });

  test("given neither, the lead is the look's own lime", () {
    expect(_made().lead, const Color(0xFFB8F229));
  });

  test('the colours describe the lead by its name', () {
    final words = const BrutalColors.light().toDiagnosticsNode().toStringDeep();
    expect(words, contains('lead:'));
    expect(words, isNot(contains('lime:')));
  });
}
