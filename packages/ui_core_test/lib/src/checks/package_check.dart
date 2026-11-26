part of '../alignment.dart';

/// One palette's status tones, by day or by night, as a look's theme gives
/// them: what [DesignToneCheck] reads.
@immutable
class DesignToneSet {
  /// The [tones] of [palette] in [brightness].
  const DesignToneSet({
    required this.palette,
    required this.brightness,
    required this.tones,
  });

  /// The palette's name, for messages ("Mint").
  final String palette;

  /// Day or night.
  final Brightness brightness;

  /// Each status tone by its name, as the look paints it (a badge's ink, a
  /// lamp, a banner's mark): info, success, warning, danger and the look's
  /// own.
  final Map<String, Color> tones;
}

/// Whether a look's status tones stay apart in each of its palettes, by day
/// and by night, so that a reader tells a success from a warning by its
/// colour.
///
/// Two tones are held at least [minDistance] apart in Material's HCT colour
/// space, the distance counting tone (light to dark, 0 to 100) and the
/// chroma along the hue as one straight line, so that two greens of one
/// lightness are near while a red and an orange are not (Material's error
/// red and an orange 600 stand about 25 apart): `Mint by day: signal
/// (#1F8A70) and ready (#2E8540) are 23 apart (at least 24)`.
///
/// A test lists each palette's tones by day and by night, from the look's
/// theme, then:
///
/// ```dart
/// const DesignToneCheck(look: 'Appliance').check([
///   for (final palette in ['warm', 'mint'])
///     for (final brightness in Brightness.values)
///       DesignToneSet(
///         palette: palette,
///         brightness: brightness,
///         tones: ApplianceTones.of(palette, brightness),
///       ),
/// ]).verify();
/// ```
@immutable
class DesignToneCheck {
  /// A check for [look].
  const DesignToneCheck({required this.look, this.minDistance = 24});

  /// The look's name, for messages.
  final String look;

  /// The least distance two tones keep, in HCT's units.
  final double minDistance;

  /// The distance between [a] and [b]: their tones and their chromas along
  /// their hues, in HCT, as one straight line.
  static double distance(Color a, Color b) {
    final x = RawHct.fromColor(a);
    final y = RawHct.fromColor(b);
    final dt = x.tone - y.tone;
    final da =
        x.chroma * math.cos(x.hue * math.pi / 180) -
        y.chroma * math.cos(y.hue * math.pi / 180);
    final db =
        x.chroma * math.sin(x.hue * math.pi / 180) -
        y.chroma * math.sin(y.hue * math.pi / 180);
    return math.sqrt(dt * dt + da * da + db * db);
  }

  /// Checks each set's tones, two by two.
  DesignAlignmentReport check(Iterable<DesignToneSet> sets) {
    final found = <String>[];
    for (final set in sets) {
      final when = set.brightness == Brightness.dark ? 'by night' : 'by day';
      final names = set.tones.keys.toList();
      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          final a = set.tones[names[i]]!;
          final b = set.tones[names[j]]!;
          final d = distance(a, b);
          if (d >= minDistance) continue;
          found.add(
            '${set.palette} $when: ${names[i]} (${_hex(a)}) and ${names[j]} '
            '(${_hex(b)}) are ${d.round()} apart (at least '
            '${_px(minDistance)})',
          );
        }
      }
    }
    return DesignAlignmentReport(look, found);
  }

  static String _hex(Color c) {
    final rgb = (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '#${rgb.toUpperCase()}';
  }
}

/// Whether a package's public docs speak to the people who use it: no word
/// of the design its look was drawn from, and each public class, enum,
/// mixin and extension opening with a plain sentence.
///
/// - **The design's words**: a doc line that names a style sheet's class (a
///   dot before a hyphened name, in code or not), or says "DERIVED", "the
///   source's" or "decision" and a number outside code, or matches one of
///   [vocabulary]: `lib/src/metrics.dart:173: the docs say
///   "DERIVED", a design source's word`.
/// - **A plain first sentence**: each public type's doc opens with a
///   sentence that starts with a capital letter (or a reference in square
///   brackets) and ends with a full stop in its first paragraph, or a first
///   paragraph that ends with a colon before a list:
///   `lib/src/rows.dart:12: FrostedRow opens with "(the row) 52 tall", not a
///   plain sentence`; one with no doc is named too.
///
/// A test reads the package's libraries and checks them:
///
/// ```dart
/// test('the docs speak to the people who use the package', () {
///   const DesignDocsCheck(look: 'Frosted').check({
///     for (final f in Directory('lib').listSync(recursive: true))
///       if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
///   }).verify();
/// });
/// ```
@immutable
class DesignDocsCheck {
  /// A check for [look].
  const DesignDocsCheck({required this.look, this.vocabulary = const []});

  /// The look's name, for messages.
  final String look;

  /// More of the design's words, beside the ones every check reads.
  final List<RegExp> vocabulary;

  // A style sheet's class: a dot before a hyphened name (.set-row,
  // .rows--mark), which no Dart name is.
  static final RegExp _selector = RegExp(
    r'(?<![\w/.\-])\.[a-z][a-z0-9]*(?:--?[a-z0-9]+)+',
  );

  // The design's words, read outside code.
  static final List<RegExp> _words = [
    RegExp(r'\bDERIVED\b'),
    RegExp(r"\bthe source's\b", caseSensitive: false),
    RegExp(r'\bdecision \d+\b', caseSensitive: false),
  ];

  static final RegExp _type = RegExp(
    r'^(?:(?:abstract|sealed|final|base|interface|mixin)\s+)*'
    r'(?:class|enum|mixin|extension(?:\s+type)?)\s+([A-Z]\w*)',
  );

  /// Checks [libraries], each a library's source by its path.
  DesignAlignmentReport check(Map<String, String> libraries) {
    final found = <String>[];
    for (final MapEntry(key: path, value: source) in libraries.entries) {
      final lines = source.split('\n');
      var i = 0;
      while (i < lines.length) {
        if (!_isDoc(lines[i])) {
          i++;
          continue;
        }
        final start = i;
        final block = <String>[];
        while (i < lines.length && _isDoc(lines[i])) {
          block.add(_docText(lines[i]));
          i++;
        }
        _readWords(path, start, block, found);
      }
      for (var i = 0; i < lines.length; i++) {
        final name = _type.firstMatch(lines[i])?[1];
        if (name == null) continue;
        final doc = _docAbove(lines, i);
        if (doc.isEmpty) {
          found.add('$path:${i + 1}: $name has no doc');
          continue;
        }
        final paragraph = doc.takeWhile((l) => l.trim().isNotEmpty).join(' ');
        final end =
            RegExp(r'\.(?=\s|$)').firstMatch(paragraph) ??
            RegExp(r':\s*$').firstMatch(paragraph);
        final first = paragraph
            .substring(0, end == null ? paragraph.length : end.end)
            .trim();
        if (end == null || !RegExp(r'^[A-Z\[]').hasMatch(first)) {
          final shown = first.length > 48
              ? '${first.substring(0, 47)}…'
              : first;
          found.add(
            '$path:${i + 1}: $name opens with "$shown", not a plain sentence',
          );
        }
      }
    }
    return DesignAlignmentReport(look, found);
  }

  static bool _isDoc(String line) => line.trimLeft().startsWith('///');

  static String _docText(String line) {
    final text = line.trimLeft().substring(3);
    return text.startsWith(' ') ? text.substring(1) : text;
  }

  // Notes the design's words in one doc comment, [block], whose first line
  // is line [start] of [path].
  void _readWords(
    String path,
    int start,
    List<String> block,
    List<String> found,
  ) {
    // A fenced block is code, its lines left out.
    final lines = List<String>.of(block);
    var fenced = false;
    for (var j = 0; j < lines.length; j++) {
      final fence = lines[j].trimLeft().startsWith('```');
      if (fence || fenced) lines[j] = '';
      if (fence) fenced = !fenced;
    }
    // The words outside inline code, which may run over a line's end.
    final prose = lines
        .join('\n')
        .replaceAllMapped(
          RegExp('`[^`]*`'),
          (m) => m[0]!.replaceAll(RegExp(r'[^\n]'), ' '),
        )
        .split('\n');
    for (var j = 0; j < lines.length; j++) {
      final word =
          _selector.firstMatch(lines[j]) ??
          [
            ..._words,
            ...vocabulary,
          ].map((w) => w.firstMatch(prose[j])).nonNulls.firstOrNull;
      if (word == null) continue;
      found.add(
        '$path:${start + j + 1}: the docs say "${word[0]!.trim()}", a design '
        "source's word",
      );
    }
  }

  // The doc comment over the declaration on line [i], its annotations and
  // plain comments skipped, a line of its words each.
  static List<String> _docAbove(List<String> lines, int i) {
    var j = i - 1;
    while (j >= 0) {
      final line = lines[j].trimLeft();
      if (line.startsWith('@') ||
          (line.startsWith('//') && !line.startsWith('///'))) {
        j--;
      } else if (line == ')' || line == '),') {
        // The end of an annotation over several lines: back to its start.
        while (j >= 0 && !lines[j].trimLeft().startsWith('@')) {
          j--;
        }
        j--;
      } else {
        break;
      }
    }
    final doc = <String>[];
    while (j >= 0 && _isDoc(lines[j])) {
      doc.insert(0, _docText(lines[j]));
      j--;
    }
    return doc;
  }
}

/// Whether a package's README works as an adopter follows it: its install
/// line adds the package at the version it is, its Dart blocks import what
/// the install lines add (and the libraries latest stable keeps), and each
/// Dart block compiles as written once those are added.
///
/// - **The install line**: a yaml block naming the package with a version
///   range that takes the package's version: `the README's install line asks
///   for frosted_ui ^0.7.0, not 0.8.0`; `the README has no install line for
///   frosted_ui`.
/// - **What the blocks import**: a package no install line adds (a new app
///   has Flutter's own, material_ui and cupertino_ui): `a Dart block (the
///   3rd) imports package:lucide_icons_flutter, which no install line
///   adds`; Flutter's Material or Cupertino library, which latest stable
///   deprecates for material_ui and cupertino_ui: `a Dart block (the 1st)
///   imports flutter/material.dart, which Flutter deprecates for
///   package:material_ui`.
/// - **Each block compiles**: [libraries] gives each Dart block as a
///   library for the test to write and analyse; [analysis] reads the
///   analyser's errors and deprecations: `a Dart block (the 2nd) does not
///   compile: Undefined name 'LucideIcons'`. Each block takes what a
///   reader following the README has: Flutter's widgets, every library the
///   README's blocks import (a package's library is never guessed from its
///   name) and the declarations of the blocks before it; its code after its
///   imports, when it declares nothing, is the body of a function given a
///   `BuildContext context` (an expression, its value).
///
/// ```dart
/// test('the README works as an adopter follows it', () async {
///   const check = DesignReadmeCheck(look: 'Frosted');
///   final readme = File('README.md').readAsStringSync();
///   final pubspec = File('pubspec.yaml').readAsStringSync();
///   check.check(readme, pubspec: pubspec).verify();
///   final dir = Directory('test/readme_blocks')..createSync();
///   addTearDown(() => dir.deleteSync(recursive: true));
///   for (final MapEntry(:key, :value) in check.libraries(readme).entries) {
///     File('${dir.path}/$key').writeAsStringSync(value);
///   }
///   final analysis = await Process.run('dart', ['analyze', dir.path]);
///   check.analysis('${analysis.stdout}').verify();
/// });
/// ```
@immutable
class DesignReadmeCheck {
  /// A check for [look].
  const DesignReadmeCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  static final RegExp _fence = RegExp(r'```(\w*)\n([\s\S]*?)```');

  static final RegExp _declaration = RegExp(
    r'^(?:(?:abstract|sealed|final|base|interface|mixin)\s+)*'
    r'(?:class|enum|mixin|extension|typedef)\b|^@|'
    r'^[A-Za-z_][\w<>?, ]*\s+[a-zA-Z_]\w*\s*\([^;]*\)\s*(?:async\s*)?(?:\{|=>)',
    multiLine: true,
  );

  // The packages a new app has: Flutter's, and the libraries latest stable
  // moved out of it.
  static const Set<String> _given = {
    'flutter',
    'flutter_test',
    'flutter_localizations',
    'material_ui',
    'cupertino_ui',
  };

  /// The packages the README's install lines add, each with its version
  /// range: a yaml block's `dependencies` and `dev_dependencies`, and a
  /// shell block's `flutter pub add` (`any` for a package added without a
  /// range; empty for one from the SDK, a path or git).
  static Map<String, String> installs(String readme) {
    final added = <String, String>{};
    for (final m in _fence.allMatches(readme)) {
      if (m[1] == 'yaml') {
        String? block;
        for (final line in m[2]!.split('\n')) {
          if (RegExp(r'^(\w+):').firstMatch(line) case final top?) {
            block = top[1];
            continue;
          }
          if (block != 'dependencies' && block != 'dev_dependencies') continue;
          final d = RegExp(r'^  ([a-z_][a-z0-9_]*):[ \t]*(.*)$')
              .firstMatch(line);
          if (d != null) added[d[1]!] = d[2]!.trim();
        }
        continue;
      }
      for (final add in RegExp(
        r'^\$?\s*(?:flutter|dart) pub add ([^\n]+)$',
        multiLine: true,
      ).allMatches(m[2]!)) {
        final words = add[1]!.trim().split(RegExp(r'\s+'));
        final fromSdk = words.any((w) => w.startsWith('--sdk'));
        for (final word in words) {
          if (word.startsWith('-')) continue;
          final spec = word.replaceFirst(RegExp(r'^(?:dev|override):'), '');
          final colon = spec.indexOf(':');
          final name = colon < 0 ? spec : spec.substring(0, colon);
          final range = colon < 0
              ? 'any'
              : spec.substring(colon + 1).replaceAll(RegExp(r'''["']'''), '');
          added[name] = fromSdk ? '' : range;
        }
      }
    }
    return added;
  }

  static List<String> _dartBlocks(String readme) => [
    for (final m in _fence.allMatches(readme))
      if (m[1] == 'dart') m[2]!,
  ];

  static String _nth(int i) => switch (i + 1) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    final n => '${n}th',
  };

  /// Checks [readme]'s install line against [pubspec] (the package's own)
  /// and what its Dart blocks import.
  DesignAlignmentReport check(String readme, {required String pubspec}) {
    final name = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)?[1];
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)?[1];
    final found = <String>[];
    final added = installs(readme);
    if (name != null && version != null) {
      final asked = added[name];
      if (asked == null) {
        found.add('the README has no install line for $name');
      } else if (!_takes(asked, version)) {
        found.add(
          "the README's install line asks for $name $asked, not $version",
        );
      }
    }
    final known = {...added.keys, ?name, ..._given};
    for (final (i, block) in _dartBlocks(readme).indexed) {
      for (final m in RegExp(
        r'''^import\s+['"]package:([a-z_][a-z0-9_]*)/([\w/]+\.dart)''',
        multiLine: true,
      ).allMatches(block)) {
        final package = m[1]!;
        final library = m[2]!;
        if (package == 'flutter' &&
            (library == 'material.dart' || library == 'cupertino.dart')) {
          final moved = library == 'material.dart'
              ? 'material_ui'
              : 'cupertino_ui';
          found.add(
            'a Dart block (the ${_nth(i)}) imports flutter/$library, '
            'which Flutter deprecates for package:$moved',
          );
        } else if (!known.contains(package)) {
          found.add(
            'a Dart block (the ${_nth(i)}) imports package:$package, which '
            'no install line adds',
          );
        }
      }
    }
    return DesignAlignmentReport(look, found);
  }

  // Whether the range [asked] ("^0.8.0", "0.8.0", ">=0.8.0 <0.9.0", "any")
  // takes [version].
  static bool _takes(String asked, String version) {
    List<int> parts(String v) => [
      for (final p in v.split('-').first.split('+').first.split('.'))
        int.tryParse(p) ?? 0,
    ];
    int compare(List<int> a, List<int> b) {
      for (var i = 0; i < 3; i++) {
        final d = (i < a.length ? a[i] : 0) - (i < b.length ? b[i] : 0);
        if (d != 0) return d;
      }
      return 0;
    }

    final v = parts(version);
    final range = asked.replaceAll(RegExp(r'''["']'''), '').trim();
    if (range == 'any') return true;
    if (range.startsWith('^')) {
      final low = parts(range.substring(1));
      final high = low[0] > 0
          ? [low[0] + 1, 0, 0]
          : low.length > 1 && low[1] > 0
          ? [0, low[1] + 1, 0]
          : [0, 0, (low.length > 2 ? low[2] : 0) + 1];
      return compare(v, low) >= 0 && compare(v, high) < 0;
    }
    final bounds = RegExp(r'(>=|<=|>|<)?\s*(\d[\w.+-]*)').allMatches(range);
    if (bounds.isEmpty) return false;
    return bounds.every((m) {
      final c = compare(v, parts(m[2]!));
      return switch (m[1]) {
        '>=' => c >= 0,
        '>' => c > 0,
        '<=' => c <= 0,
        '<' => c < 0,
        _ => c == 0,
      };
    });
  }

  /// [readme]'s Dart blocks, each a library to analyse, by a file name
  /// (`readme_block_1.dart` and on).
  Map<String, String> libraries(String readme) {
    final blocks = [for (final block in _dartBlocks(readme)) _split(block)];
    // What a reader following the README has imported: Flutter's widgets and
    // each library a block imports. A package's library is never guessed
    // from its name: lucide_icons_flutter's is lucide_icons.dart.
    final stated = [
      "import 'package:flutter/widgets.dart';",
      for (final (own, _) in blocks)
        for (final directive in own)
          if (RegExp(r'''^import\s+['"](?:package|dart):''')
              .hasMatch(directive))
            directive,
    ];
    // A block sees the declarations of the blocks before it, as the reader
    // has them.
    final libraries = <String, String>{};
    final declared = <String>[];
    for (final (i, (own, code)) in blocks.indexed) {
      final name = 'readme_block_${i + 1}.dart';
      final head = [
        '// ignore_for_file: unused_import, unused_element, '
            'unused_local_variable',
        ...{...stated, ...own, ...declared},
        '',
        '',
      ].join('\n');
      final declares = _declaration.hasMatch(code);
      libraries[name] = code.isEmpty || declares
          ? '$head$code\n'
          : code.endsWith(';') || code.endsWith('}')
          ? '${head}Future<void> readmeBlock(BuildContext context) async {\n'
                '$code\n}\n'
          : '${head}Object? readmeBlock(BuildContext context) =>\n$code;\n';
      if (declares) declared.add("import '$name';");
    }
    return libraries;
  }

  // A block's leading directives, each on one line, and its code after them.
  static (List<String>, String) _split(String block) {
    final lines = block.split('\n');
    final own = <String>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        i++;
      } else if (RegExp(r'^(?:import|export)\s').hasMatch(line)) {
        var directive = line;
        while (!directive.endsWith(';') && ++i < lines.length) {
          directive = '$directive ${lines[i].trim()}';
        }
        own.add(directive);
        i++;
      } else {
        break;
      }
    }
    return (own, lines.skip(i).join('\n').trimRight());
  }

  /// The errors and deprecations in the analyser's [output] (`dart analyze`
  /// over [libraries]), as problems; a warning such as an unused import
  /// still compiles.
  DesignAlignmentReport analysis(String output) => DesignAlignmentReport(look, [
    for (final m in RegExp(
      r'^\s*(error|warning|info) - [^\n]*?readme_block_(\d+)\.dart:\d+:\d+ - '
      r'([^\n]*?)(?: - ([\w_]+))?$',
      multiLine: true,
    ).allMatches(output))
      if (m[1] == 'error' || (m[4] ?? '').startsWith('deprecated'))
        'a Dart block (the ${_nth(int.parse(m[2]!) - 1)}) does not compile: '
            '${m[3]!.split(RegExp(r'\.\s')).first.replaceAll(RegExp(r'\.$'), '')}',
  ]);
}

/// Whether a package's example resolves from pub.dev alone, as an adopter
/// who opens it gets it: every dependency of its pubspec is Flutter's, the
/// package itself, or one pub.dev serves.
///
/// - **No path or git**: a dependency by path (the package's own aside) or
///   by git: `the example depends on ui_core_review by path, which an
///   adopter does not have`.
/// - **Nothing unpublished**: a package of [check]'s `unpublished` (one
///   whose own pubspec says `publish_to: none`, which a test reads from its
///   workspace): `the example depends on ui_core_review, which pub.dev does
///   not serve`.
/// - **No overrides**: `the example overrides ui_core, which an adopter's
///   pub get does not`.
///
/// ```dart
/// test('the example resolves from pub.dev alone', () {
///   const DesignExampleDepsCheck(look: 'Keycap').check(
///     File('example/pubspec.yaml').readAsStringSync(),
///     package: 'keycap_ui',
///     unpublished: {'ui_core_review'},
///   ).verify();
/// });
/// ```
@immutable
class DesignExampleDepsCheck {
  /// A check for [look].
  const DesignExampleDepsCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks the example's [pubspec] for [package]'s example, [unpublished]
  /// naming the packages pub.dev does not serve.
  DesignAlignmentReport check(
    String pubspec, {
    required String package,
    Set<String> unpublished = const {},
  }) {
    final found = <String>[];
    final lines = pubspec.split('\n');
    String? block;
    for (var i = 0; i < lines.length; i++) {
      if (RegExp(r'^(\w+):').firstMatch(lines[i]) case final top?) {
        block = top[1];
        continue;
      }
      final name = RegExp(r'^  ([a-z_][a-z0-9_]*):').firstMatch(lines[i])?[1];
      if (name == null) continue;
      if (block == 'dependency_overrides') {
        found.add(
          "the example overrides $name, which an adopter's pub get does not",
        );
        continue;
      }
      if (block != 'dependencies' && block != 'dev_dependencies') continue;
      final source = [
        for (
          var j = i + 1;
          j < lines.length &&
              (lines[j].startsWith('    ') || lines[j].trim().startsWith('#'));
          j++
        )
          ?RegExp(r'^\s+(path|git|sdk):').firstMatch(lines[j])?[1],
      ].firstOrNull;
      switch (source) {
        case 'sdk':
          continue;
        case 'path' when name == package:
          continue;
        case 'path':
          found.add(
            'the example depends on $name by path, which an adopter does not '
            'have',
          );
        case 'git':
          found.add(
            "the example depends on $name by git, which an adopter's pub get "
            'does not take from pub.dev',
          );
        default:
          if (unpublished.contains(name)) {
            found.add(
              'the example depends on $name, which pub.dev does not serve',
            );
          }
      }
    }
    return DesignAlignmentReport(look, found);
  }
}
