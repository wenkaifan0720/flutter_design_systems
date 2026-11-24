import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The skill's folder: this package's parent.
final Directory skill = Directory.current.parent;

/// One fenced `dart` block of a page, with the source it says it is from.
class Block {
  Block(this.page, this.line, this.code, this.source);

  final String page;
  final int line;
  final String code;

  /// The path in a `<!-- source: ... -->` line just above the block, or null.
  final String? source;

  @override
  String toString() => '$page:$line';
}

/// Every fenced `dart` block in [page].
List<Block> blocksOf(File page) {
  final lines = page.readAsLinesSync();
  final name = page.path.substring(skill.path.length + 1);
  final blocks = <Block>[];
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() != '```dart') continue;
    final start = i;
    final code = <String>[];
    for (i++; i < lines.length && lines[i].trim() != '```'; i++) {
      code.add(lines[i]);
    }
    String? source;
    for (var j = start - 1; j >= 0 && j >= start - 3; j--) {
      final match = RegExp(r'<!-- source: (\S+) -->').firstMatch(lines[j]);
      if (match != null) {
        source = match.group(1);
        break;
      }
    }
    blocks.add(Block(name, start + 1, code.join('\n'), source));
  }
  return blocks;
}

String _flat(String code) => code.replaceAll(RegExp(r'\s+'), ' ').trim();

/// The runs of [block] between its `// ...` lines, each whitespace-flattened.
List<String> runsOf(String block) {
  final runs = <String>[];
  final run = <String>[];
  for (final line in block.split('\n')) {
    final t = line.trim();
    if (t == '// ...' || t == '...') {
      if (run.isNotEmpty) runs.add(_flat(run.join('\n')));
      run.clear();
    } else {
      run.add(line);
    }
  }
  if (run.isNotEmpty) runs.add(_flat(run.join('\n')));
  return runs.where((r) => r.isNotEmpty).toList();
}

/// Whether every run of [block] stands in [source], in order.
bool standsIn(String block, String source) {
  final flat = _flat(source);
  var from = 0;
  for (final run in runsOf(block)) {
    final at = flat.indexOf(run, from);
    if (at < 0) return false;
    from = at + run.length;
  }
  return true;
}

/// The Dart files under [dir].
Iterable<File> dartFilesIn(Directory dir) => dir
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  final pages = [
    File('${skill.path}/SKILL.md'),
    ...Directory('${skill.path}/references')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .where((f) => !f.path.endsWith('examples.md')),
  ];

  test('every Dart block in the skill is code this package compiles', () {
    final sources = [
      for (final dir in ['lib', 'test'])
        for (final f in dartFilesIn(Directory(dir))) f.readAsStringSync(),
    ];
    final blocks = [for (final page in pages) ...blocksOf(page)];
    expect(blocks, isNotEmpty);
    final strays = [
      for (final block in blocks)
        if (!sources.any((s) => standsIn(block.code, s))) '$block',
    ];
    expect(strays, isEmpty, reason: 'blocks not found in samples/lib or test');
  });

  test('every excerpt of a published look matches its source', () {
    // The packages folders that hold the published designs the excerpts quote: the
    // repository's own by default, others colon-separated in LOOK_SOURCES.
    final roots = (Platform.environment['LOOK_SOURCES'] ?? '../../../packages')
        .split(':')
        .where((r) => r.isNotEmpty)
        .toList();
    final blocks = blocksOf(File('${skill.path}/references/examples.md'));
    expect(blocks, isNotEmpty);
    final problems = <String>[];
    for (final block in blocks) {
      final path = block.source;
      if (path == null) {
        problems.add('$block names no source');
        continue;
      }
      final file = roots
          .map((r) => File('$r/$path'))
          .where((f) => f.existsSync())
          .firstOrNull;
      if (file == null) {
        problems.add('$block: $path is in none of $roots');
      } else if (!standsIn(block.code, file.readAsStringSync())) {
        problems.add('$block no longer matches $path');
      }
    }
    expect(problems, isEmpty);
  });
}
