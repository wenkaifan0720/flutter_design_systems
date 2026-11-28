import 'dart:convert';
import 'dart:io';

import 'package:highlight/highlight.dart' show highlight;
import 'package:markdown/markdown.dart' as markdown;

part 'pages.dart';

typedef Json = Map<String, dynamic>;

final site = File.fromUri(Platform.script).parent.parent;
late final Directory output;
final libraries = Directory.fromUri(site.uri.resolve('examples/lib/'));
final looks = readJson(site.uri.resolve('looks.json')).cast<String, Json>();
final studyPackages = discoverStudies();
final components = discoverComponents();
final template = File.fromUri(site.uri.resolve('tool/page.html'))
    .readAsStringSync();
const repository = 'https://github.com/wenkaifan0720/flutter_design_systems';
const docsUrl = 'https://wenkaifan0720.github.io/flutter_design_systems/docs/';
const referenceHeading = 'Flutter’s own libraries';

/// Flutter's Material and Cupertino libraries, shown beside the design systems
/// for comparison: they are not packages of this collection, and a row they
/// don't cover says so in a sentence of its own.
bool isReference(String id) => looks[id]!['reference'] != null;

/// Where each package the site builds against lives (the site workspace's
/// package config), so the home page reads the README of that very version.
final packageRoots = () {
  final config = File.fromUri(
    site.uri.resolve('.dart_tool/package_config.json'),
  );
  final packages = (readJson(config.uri)['packages'] as List).cast<Json>();
  return {
    for (final p in packages)
      p['name'] as String: config.uri.resolve(
        (p['rootUri'] as String).endsWith('/')
            ? p['rootUri'] as String
            : '${p['rootUri']}/',
      ),
  };
}();

/// A look's minimal setup for the home page's third step: the first Dart block
/// of its README when that block imports the package, calls runApp and is at
/// most 12 lines; else null, and the step keeps its sentence.
String? setupBlock(String readme, String package) {
  final block = RegExp(
    r'^```dart\n(.*?)^```',
    multiLine: true,
    dotAll: true,
  ).firstMatch(readme)?.group(1)?.trimRight();
  if (block == null) return null;
  final lines = block.split('\n');
  final imports = block.contains("import 'package:$package/");
  return imports && block.contains('runApp(') && lines.length <= 12
      ? block
      : null;
}

String? lookSetup(String package) {
  final root = packageRoots[package];
  if (root == null) return null;
  final readme = File.fromUri(root.resolve('README.md'));
  return readme.existsSync()
      ? setupBlock(readme.readAsStringSync(), package)
      : null;
}

String escape(String value) => const HtmlEscape().convert(value);
String html(String source) => markdown.markdownToHtml(
  source,
  inlineSyntaxes: [],
  extensionSet: markdown.ExtensionSet.gitHubFlavored,
);
String titleCase(String slug) =>
    slug.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join();
String sourcePath(String look, String component, String example) =>
    "components/$component/$look/${example.replaceAll('-', '_')}.dart";

Json readJson(Uri uri) {
  final file = File.fromUri(uri);
  if (!file.existsSync()) throw StateError('Missing ${file.path}');
  return jsonDecode(file.readAsStringSync()) as Json;
}

Map<String, String> discoverStudies() {
  final studies = <String, String>{};
  for (final MapEntry(key: id, value: look) in looks.entries) {
    final package = look['package'] as String;
    final name = 'stint_${package.replaceFirst(RegExp(r'_ui$'), '')}';
    final library = site.uri.resolve('study/$package/lib/$name.dart');
    if (File.fromUri(library).existsSync()) studies[id] = name;
  }
  return studies;
}

class Component {
  Component(this.slug, this.folder, Json data)
    : order = data['order'] as int,
      group = data['group'] as String,
      title = data['title'] as String,
      previewHeight = data['previewHeight'] as int?,
      examples = (data['examples'] as Json).cast<String, String>();

  final String slug;
  final Directory folder;
  final int order;
  final String group;
  final String title;
  final int? previewHeight;
  final Map<String, String> examples;
  late final api = {
    for (final look in looks.keys)
      look: readJson(folder.uri.resolve('$look/api.json')),
  };
}

Map<String, Component> discoverComponents() {
  final root = Directory.fromUri(libraries.uri.resolve('components/'));
  final entries = <Component>[];
  final orders = <int>{};
  final slugPattern = RegExp(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$');
  for (final folder in root.listSync().whereType<Directory>()) {
    final slug = folder.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final component = Component(
      slug,
      folder,
      readJson(folder.uri.resolve('component.json')),
    );
    if (!slugPattern.hasMatch(slug) ||
        component.examples.isEmpty ||
        !component.examples.keys.every(slugPattern.hasMatch)) {
      throw StateError(
        '$slug needs a component slug and example slugs in kebab-case',
      );
    }
    if (component.order < 1 || !orders.add(component.order)) {
      throw StateError(
        '$slug needs a unique positive inventory row number: ${component.order}',
      );
    }
    if (component.previewHeight case final height? when height <= 0) {
      throw StateError('$slug needs a positive previewHeight');
    }
    for (final entry in component.api.entries) {
      final config = entry.value;
      if (config.containsKey('gap')) {
        if (config.length == 1 &&
            config['gap'] is String &&
            (config['gap'] as String).trim().isNotEmpty) {
          continue;
        }
      } else if (config['widget'] is String && config['parameters'] is Json) {
        continue;
      }
      throw StateError(
        '$slug/${entry.key}/api.json needs widget and parameters, or a gap reason',
      );
    }
    entries.add(component);
  }
  if (entries.isEmpty) throw StateError('No components in ${root.path}');
  entries.sort((a, b) => a.order.compareTo(b.order));
  return {for (final component in entries) component.slug: component};
}

void write(File file, String content) {
  if (file.existsSync() && file.readAsStringSync() == content) return;
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void generateRoutes() {
  final imports = <String>[];
  final loaders = <String>[];
  write(
    File.fromUri(libraries.uri.resolve('generated/studies.dart')),
    [
      '// Generated by site/tool/generate.dart.',
      "import 'package:flutter/widgets.dart';",
      "import 'package:stint_core/stint_core.dart';",
      for (final MapEntry(key: id, value: package) in studyPackages.entries)
        "import 'package:$package/$package.dart' deferred as $id;",
      '',
      'Future<Widget?> openStudy(String look, StintLaunch launch) async {',
      '  switch (look) {',
      for (final MapEntry(key: id, value: package)
          in studyPackages.entries) ...[
        "    case '$id':",
        '      await $id.loadLibrary();',
        '      return $id.open${titleCase(package.replaceAll('_', '-'))}(launch);',
      ],
      '    default: return null;',
      '  }',
      '}',
      '',
    ].join('\n'),
  );
  for (final MapEntry(key: id, value: look) in looks.entries) {
    final exampleImports = <String>[];
    final builders = <String>[];
    for (final MapEntry(key: slug, value: component) in components.entries) {
      final config = component.api[id]!;
      if (config.containsKey('gap')) continue;
      for (final example in component.examples.keys) {
        final alias = 'example${builders.length}';
        final path = sourcePath(id, slug, example);
        if (!File.fromUri(libraries.uri.resolve(path)).existsSync()) {
          throw StateError('Missing example $path');
        }
        exampleImports.add("import '../$path' as $alias;");
        builders.add(
          "    '$slug/$example': (_) => const $alias.${titleCase(example)}(),",
        );
      }
    }
    write(
      File.fromUri(libraries.uri.resolve('generated/$id.dart')),
      [
        '// Generated by site/tool/generate.dart.',
        "import '../preview_look.dart';",
        "import '../$id/theme.dart';",
        ...exampleImports,
        '',
        'Future<PreviewLook> load() async {',
        "  await ${look['fontLoader']}();",
        "  return PreviewLook('${look['name']}', wrapLook, {",
        ...builders,
        '  });',
        '}',
        '',
      ].join('\n'),
    );
    imports.add("import 'generated/$id.dart' deferred as $id;");
    loaders.add(
      "  '$id': () async {\n    await $id.loadLibrary();\n    return $id.load();\n  },",
    );
  }
  write(
    File.fromUri(libraries.uri.resolve('main.dart')),
    [
      '// Generated by site/tool/generate.dart.',
      "import 'preview_app.dart';",
      "import 'preview_look.dart';",
      "import 'study_app.dart' deferred as study;",
      ...imports,
      '',
      'Future<void> main() async {',
      "  final look = Uri.base.queryParameters['stint'];",
      '  if (look != null) {',
      '    await study.loadLibrary();',
      '    study.runStudy(look);',
      '    return;',
      '  }',
      '  runPreview(<String, Future<PreviewLook> Function()>{',
      ...loaders,
      '  });',
      '}',
      '',
    ].join('\n'),
  );
  final names = {'studies.dart', for (final id in looks.keys) '$id.dart'};
  final generated = Directory.fromUri(libraries.uri.resolve('generated/'));
  for (final file in generated.listSync().whereType<File>()) {
    if (!names.contains(file.uri.pathSegments.last) &&
        file.readAsStringSync().startsWith(
          '// Generated by site/tool/generate.dart.',
        )) {
      file.deleteSync();
    }
  }
}

String nav(String current, String root) {
  final result = StringBuffer();
  String selected(String slug) => slug == current ? ' aria-current="page"' : '';
  result.write(
    '<section class="nav-group"><h3>Start here</h3>'
    '<a data-follow-look href="$root"${selected('home')}>Overview</a>'
    '<a data-follow-look href="${root}stint/"${selected('stint')}>Stint team planner</a></section>',
  );
  var previous = '';
  for (final MapEntry(key: slug, value: component) in components.entries) {
    final group = component.group;
    if (group != previous) {
      if (previous.isNotEmpty) result.write('</section>');
      result.write('<section class="nav-group"><h3>${escape(group)}</h3>');
      previous = group;
    }
    result.write(
      '<a data-component="$slug" href="$root$slug/"${selected(slug)}>${escape(component.title)}</a>',
    );
  }
  for (final (heading, reference) in [
    ('Design systems', false),
    (referenceHeading, true),
  ]) {
    result.write('</section><section class="nav-group"><h3>$heading</h3>');
    for (final entry in looksIn(reference: reference)) {
      final path = 'looks/${entry.key}';
      result.write(
        '<a href="$root$path/"${selected(path)}>${escape(entry.value['name'])}</a>',
      );
    }
  }
  return '${result.toString()}</section>';
}

String bodyFor(
  String id,
  String slug,
  Component component,
  Map<String, String> prose,
) {
  final look = looks[id]!;
  final entry = component.api[id]!;
  if (entry['gap'] case final String reason) {
    return isReference(id)
        ? '<p class="gap">${escape(reason)}</p>'
        : '<p class="gap">Not in ${escape(look['name'])}: ${escape(reason)}</p>';
  }
  final keyboardNote = entry['keyboardNote'] as String?;
  final result = StringBuffer();
  for (final MapEntry(key: example, value: heading)
      in component.examples.entries) {
    final path = sourcePath(id, slug, example);
    final source = File.fromUri(libraries.uri.resolve(path)).readAsStringSync();
    final code = highlight.parse(source, language: 'dart').toHtml();
    result.write('''
<section class="example" id="$example" data-example="$example">
  <div class="section-title"><h2>${escape(heading)}</h2><a class="permalink" href="#$example" aria-label="Link to ${escape(heading)}">#</a></div>
  ${html(prose[heading]!)}
  <p class="keyboard-note"${keyboardNote == null ? ' hidden' : ''}>${escape(keyboardNote ?? '')}</p>
  <div class="workbench">
    <div class="example-tabs" role="tablist" aria-label="${escape(heading)} example">
      <button type="button" role="tab" id="$example-preview-tab" aria-selected="true" aria-controls="$example-preview">Preview</button>
      <button type="button" role="tab" id="$example-code-tab" aria-selected="false" aria-controls="$example-code" tabindex="-1">Code</button>
    </div>
    <div role="tabpanel" id="$example-preview" aria-labelledby="$example-preview-tab">
    <div class="tools" aria-label="Preview settings">
      ${frameButtons('Frame width', desktopPressed: true)}
      <div class="environment">
        <button type="button" data-setting="theme" aria-label="Night theme" aria-pressed="false"><span aria-hidden="true" class="sun"></span><span data-value>Day</span></button>
        <button type="button" data-setting="dir" aria-label="Right-to-left direction" aria-pressed="false"><span data-value>LTR</span></button>
        <button type="button" data-setting="scale" aria-label="Double text size" aria-pressed="false"><span aria-hidden="true" class="type-icon">Aa</span><span data-value>100%</span></button>
      </div>
    </div>
    <div class="stage"><div class="viewport"${component.previewHeight == null ? '' : ' data-height="${component.previewHeight}"'}><div class="frame"><iframe loading="lazy" title="${escape(look['name'])} ${escape(component.title)} interactive example"></iframe></div></div></div>
    <div class="caption"><span><i class="status-dot" aria-hidden="true"></i>Flutter preview <span class="frame-size"></span></span><a class="open-preview" target="_blank" rel="noopener">Open preview <span aria-hidden="true">↗</span></a></div>
    </div>
    <div class="source" role="tabpanel" id="$example-code" aria-labelledby="$example-code-tab" hidden>
      <div class="source-head"><span class="filename">${escape(path)}</span><button type="button" class="copy">Copy code</button></div>
      <pre tabindex="0" aria-label="Dart source"><code>$code</code></pre>
    </div>
  </div>
</section>
''');
  }
  final params = entry['parameters'] as Json;
  final widget = entry['widget'] as String;
  final pkg = look['package'] as String;
  final library = entry['library'] as String? ?? pkg;
  final suffix = widget.startsWith(RegExp('[A-Z]')) ? '-class.html' : '.html';
  final reference =
      'https://pub.dev/documentation/$pkg/latest/$library/$widget$suffix';
  result.write('''
<section class="reference" id="parameters">
  <div class="section-title"><h2>Parameters</h2><a class="api" href="${escape(reference)}">$widget API ↗</a></div>
  <dl>${params.entries.map((p) => '<div><dt><code>${escape(p.key)}</code></dt><dd>${escape(p.value)}</dd></div>').join()}</dl>
</section>''');
  return result.toString();
}

void renderComponent(String slug, String root, String relativeFile) {
  final component = components[slug]!;
  final text = File.fromUri(component.folder.uri.resolve('content.md'))
      .readAsStringSync();
  final sections = text.trim().split(RegExp(r'^## ', multiLine: true));
  final lead = sections.removeAt(0).split('\n').skip(1).join('\n').trim();
  final prose = <String, String>{};
  for (final section in sections) {
    final newline = section.indexOf('\n');
    prose[section.substring(0, newline)] = section.substring(newline).trim();
  }
  for (final heading in [...component.examples.values, 'Shared behaviour']) {
    if (prose[heading]?.isNotEmpty != true) {
      throw StateError(
        '$slug/content.md needs a nonempty "## $heading" section',
      );
    }
  }
  final defaultLook = looks.keys.first;
  final bodies = {
    for (final id in looks.keys) id: bodyFor(id, slug, component, prose),
  };
  for (final entry in bodies.entries.where((e) => e.key != defaultLook)) {
    write(
      File.fromUri(output.uri.resolve('$slug/parts/${entry.key}.html')),
      entry.value,
    );
  }
  // The page itself carries the first look; `<slug>/<look>/` carries each
  // look in full, so a reader without JavaScript (or a fetch of the page)
  // reaches every look's code and parameters.
  void page(String id, String root, String file, {required bool own}) {
    final lookLinks = [
      for (final MapEntry(key: other, value: look) in looks.entries)
        '<a href="$root$slug/$other/"${other == id ? ' aria-current="page"' : ''}>${escape(look['name'])}</a>',
    ].join(', ');
    final fragment = fill(componentTemplate, {
      'root': root,
      'slug': slug,
      'title': escape(component.title),
      'group': escape(component.group),
      'lead': html(lead),
      'lookPicker': lookPicker('look', selected: own ? id : null),
      'firstLook': id,
      'firstLookName': escape(looks[id]!['name']),
      'firstLookPackage': looks[id]!['package'],
      'own': own ? ' data-own' : '',
      'lookLinks': lookLinks,
      'body': bodies[id]!,
      'behaviour': html(prose['Shared behaviour']!),
    });
    pageFile(
      file,
      root: root,
      slug: slug,
      title: own
          ? '${component.title} in ${looks[id]!['name']}'
          : component.title,
      description: plainText(lead),
      content: fragment,
      script: 'site.js',
    );
  }

  page(defaultLook, root, relativeFile, own: false);
  for (final id in looks.keys) {
    page(id, '$root../', '$slug/$id/index.html', own: true);
  }
}

void main(List<String> args) {
  output = args.isEmpty
      ? Directory.fromUri(site.parent.uri.resolve('build/site/docs/'))
      : Directory(args.single);
  final timer = Stopwatch()..start();
  generateRoutes();
  final assets = Directory.fromUri(output.uri.resolve('assets/'))
    ..createSync(recursive: true);
  for (final file in Directory.fromUri(
    site.uri.resolve('assets/'),
  ).listSync().whereType<File>()) {
    file.copySync(
      File.fromUri(assets.uri.resolve(file.uri.pathSegments.last)).path,
    );
  }
  for (final asset in [
    'site.css',
    'site.js',
    'navigation.js',
    'stint.js',
    'home.js',
  ]) {
    write(
      File.fromUri(output.uri.resolve(asset)),
      File.fromUri(site.uri.resolve('tool/$asset')).readAsStringSync(),
    );
  }
  for (final slug in components.keys) {
    renderComponent(slug, '../', '$slug/index.html');
  }
  renderDirectories();
  renderStint();
  renderNotFound();
  stdout.writeln(
    '${components.length} component pages, ${looks.length} looks, ${timer.elapsedMilliseconds} ms',
  );
}
