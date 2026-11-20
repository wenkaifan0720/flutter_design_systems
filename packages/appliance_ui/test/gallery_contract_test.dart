// Gallery controls use the exported widgets and respond to interaction.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Parts the example builds only through another: the part that builds
/// each, which must itself be live and must build it.
const _builtBy = {
  'ApplianceActionSheet': 'showApplianceActionSheet',
  'ApplianceSideSheet': 'showApplianceSideSheet',
  'ApplianceNavigationRail': 'ApplianceScaffold',
  'ApplianceHousing': 'ApplianceScreen',
  'ApplianceFieldMessage': 'ApplianceTextField',
  'ApplianceMenuPlate': 'ApplianceSelect',
  'ApplianceMenuReveal': 'ApplianceSelect',
  'ApplianceMenuRow': 'ApplianceMenu',
};

Iterable<File> _dart(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

void main() {
  test('every exported widget is live in the example', () {
    final declaration = RegExp(
      r'^class (Appliance\w+)(?:<[^>]*>)? extends (?:StatelessWidget|StatefulWidget)\b',
      multiLine: true,
    );
    final source = <String, String>{};
    for (final f in _dart('lib')) {
      if (f.path.contains('/internal/')) continue;
      final text = f.readAsStringSync();
      for (final m in declaration.allMatches(text)) {
        source[m.group(1)!] = text;
      }
    }
    expect(source.length, greaterThan(90), reason: 'the parts were found');
    final example = _dart('example/lib')
        .map((f) => f.readAsStringSync())
        .join();
    bool live(String name) => RegExp('\\b$name\\b').hasMatch(example);
    final library = _dart('lib').map((f) => f.readAsStringSync()).join();
    final hidden = <String>[];
    for (final name in source.keys) {
      if (live(name)) continue;
      final by = _builtBy[name];
      final builds =
          by != null && live(by) && RegExp('\\b$name\\(').hasMatch(library);
      if (!builds) hidden.add(name);
    }
    hidden.sort();
    expect(hidden, isEmpty, reason: 'exported, and built by no live page');
  });
}
