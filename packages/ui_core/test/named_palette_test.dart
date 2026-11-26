import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

const harbour = RawNamedPalette(
  id: 'harbour',
  label: 'Harbour',
  swatches: [Color(0xFF1F5F8B), Color(0xFFF4F1EA)],
  darkSwatches: [Color(0xFF7FB3D9), Color(0xFF14171A)],
);

void main() {
  test('a named palette gives its swatches for the brightness shown', () {
    expect(harbour.swatchesFor(Brightness.light), harbour.swatches);
    expect(harbour.swatchesFor(Brightness.dark), harbour.darkSwatches);
  });

  test('two palettes are equal when all they say is', () {
    const same = RawNamedPalette(
      id: 'harbour',
      label: 'Harbour',
      swatches: [Color(0xFF1F5F8B), Color(0xFFF4F1EA)],
      darkSwatches: [Color(0xFF7FB3D9), Color(0xFF14171A)],
    );
    expect(same, harbour);
    expect(same.hashCode, harbour.hashCode);
    for (final other in [
      const RawNamedPalette(
        id: 'harbor',
        label: 'Harbour',
        swatches: [Color(0xFF1F5F8B), Color(0xFFF4F1EA)],
        darkSwatches: [Color(0xFF7FB3D9), Color(0xFF14171A)],
      ),
      const RawNamedPalette(
        id: 'harbour',
        label: 'Harbor',
        swatches: [Color(0xFF1F5F8B), Color(0xFFF4F1EA)],
        darkSwatches: [Color(0xFF7FB3D9), Color(0xFF14171A)],
      ),
      const RawNamedPalette(
        id: 'harbour',
        label: 'Harbour',
        swatches: [Color(0xFF1F5F8C), Color(0xFFF4F1EA)],
        darkSwatches: [Color(0xFF7FB3D9), Color(0xFF14171A)],
      ),
      const RawNamedPalette(
        id: 'harbour',
        label: 'Harbour',
        swatches: [Color(0xFF1F5F8B), Color(0xFFF4F1EA)],
        darkSwatches: [Color(0xFF7FB3D9)],
      ),
    ]) {
      expect(other, isNot(harbour));
    }
  });

  test('it asks for one to four swatches, as many by night as by day', () {
    const none = RawNamedPalette(
      id: 'none',
      label: 'None',
      swatches: [],
      darkSwatches: [],
    );
    expect(() => none.swatchesFor(Brightness.light), throwsAssertionError);
    const uneven = RawNamedPalette(
      id: 'uneven',
      label: 'Uneven',
      swatches: [Color(0xFF000000), Color(0xFFFFFFFF)],
      darkSwatches: [Color(0xFF000000)],
    );
    expect(() => uneven.swatchesFor(Brightness.dark), throwsAssertionError);
  });

  test('it describes itself', () {
    final text = harbour.toDiagnosticsNode().toStringDeep();
    for (final s in [
      'id: "harbour"',
      'label: "Harbour"',
      'swatches:',
      'darkSwatches:',
    ]) {
      expect(text, contains(s));
    }
  });
}
