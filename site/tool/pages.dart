part of 'generate.dart';

final componentTemplate = File.fromUri(site.uri.resolve('tool/component.html'))
    .readAsStringSync();

String fill(String source, Map<String, String> values) => source
    .replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (match) => values[match[1]]!);

String plainText(String markdownText) => markdownText
    .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!)
    .replaceAll('`', '')
    .replaceAll('**', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String lookOptions({String? selected}) {
  String option(MapEntry<String, Json> entry) {
    final look = entry.value;
    final name = escape(look['name']);
    return '<option value="${entry.key}"${entry.key == selected ? ' selected' : ''} data-name="$name" data-swatch="${look['swatch']}" data-package="${look['package']}" data-study="${studyPackages.containsKey(entry.key)}"${look['stintDensity'] == false ? ' data-density="false"' : ''}>$name</option>';
  }

  final ours = looks.entries.where((e) => !isReference(e.key)).map(option);
  final flutter = looks.entries.where((e) => isReference(e.key)).map(option);
  return '<optgroup label="Design systems">${ours.join()}</optgroup>'
      '<optgroup label="$referenceHeading">${flutter.join()}</optgroup>';
}

/// The design-system picker on component pages, look pages and Stint: its
/// label, the chosen look's swatch, the select and its chevron. [id] names the
/// select: site.js and stint.js read `#look`; a look's page navigates from
/// `#look-directory`.
String lookPicker(String id, {String? selected}) {
  final swatch = selected == null
      ? ''
      : ' style="background:${looks[selected]!['swatch']}"';
  return '<label for="$id">Design system</label>'
      '<div class="look-select"><span id="swatch"$swatch aria-hidden="true"></span>'
      '<select id="$id">${lookOptions(selected: selected)}</select>'
      '<span class="chevron" aria-hidden="true"></span></div>';
}

/// The Desktop and Phone frame widths, for an example and for Stint.
String frameButtons(String label, {required bool desktopPressed}) =>
    '<div class="frame-options" role="group" aria-label="$label">'
    '<button type="button" data-width="1440" aria-pressed="$desktopPressed" title="Use the available preview width"><i class="monitor" aria-hidden="true"></i>Desktop</button>'
    '<button type="button" data-width="390" aria-pressed="false" title="390 px phone frame"><i class="phone" aria-hidden="true"></i>Phone</button>'
    '</div>';

/// A row of page actions.
String actions(List<String> links) =>
    '<div class="home-actions">${links.join()}</div>';

/// A link that leaves the docs, marked with an arrow.
String external(String href, String text) =>
    '<a href="$href">$text <span aria-hidden="true">↗</span></a>';

/// The design systems of this collection, or Flutter's own libraries.
Iterable<MapEntry<String, Json>> looksIn({required bool reference}) =>
    looks.entries.where((e) => isReference(e.key) == reference);

String numberWord(int n) => 'Zero One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve Thirteen Fourteen Fifteen Sixteen Seventeen Eighteen Nineteen Twenty'
    .split(' ')[n];

void pageFile(
  String file, {
  required String root,
  required String slug,
  required String title,
  required String description,
  required String content,
  String? script,
  String? fixedLook,
  String base = '',
}) {
  write(
    File.fromUri(output.uri.resolve(file)),
    fill(template, {
      'root': root,
      'base': base,
      'slug': slug,
      'title': escape(title),
      'description': escape(description),
      'firstLook': looks.keys.first,
      'fixedLook': fixedLook ?? '',
      'nav': nav(slug, root),
      'scripts': script == null
          ? ''
          : '<script defer src="$root$script"></script>',
      'content': content,
    }),
  );
}

String componentDirectory(String root, {String? look}) {
  final groups = <String, List<Component>>{};
  for (final component in components.values) {
    if (look != null && component.api[look]!.containsKey('gap')) continue;
    (groups[component.group] ??= []).add(component);
  }
  final sections = groups.entries.map((entry) {
    final links = entry.value
        .map(
          (c) =>
              '<li><a data-component="${c.slug}" href="$root${c.slug}/${look == null ? '' : '$look/'}">${escape(c.title)}</a></li>',
        )
        .join();
    return '<section><h3>${escape(entry.key)}</h3><ul>$links</ul></section>';
  }).join();
  return '<div class="directory">$sections</div>';
}

String lookCards(String root) {
  String cards(bool reference) => looksIn(reference: reference).map((e) {
    final name = escape(e.value['name']);
    return '<li><a href="${root}looks/${e.key}/" data-look-id="${e.key}"><i aria-hidden="true" style="background:${e.value['swatch']}"></i>$name<span aria-hidden="true">→</span></a></li>';
  }).join();
  return '<ul class="look-grid">${cards(false)}</ul>'
      '<h3 class="look-group">$referenceHeading</h3>'
      '<p class="look-group-note">Flutter’s Material and Cupertino libraries, for comparison. They are Flutter’s packages, not part of this collection.</p>'
      '<ul class="look-grid">${cards(true)}</ul>';
}

void renderDirectories() {
  final ours = looksIn(reference: false).toList();
  // The look the start steps open on: the one the reader chose last
  // (home.js), else Minimal.
  final start = looks.containsKey('minimal') ? 'minimal' : ours.first.key;
  final startName = escape(looks[start]!['name']);
  final startPackage = looks[start]!['package'] as String;
  final chips = ours
      .map(
        (e) =>
            '<button type="button" data-look="${e.key}" data-name="${escape(e.value['name'])}" data-package="${e.value['package']}" aria-pressed="${e.key == start}"><i aria-hidden="true" style="background:${e.value['swatch']}"></i>${escape(e.value['name'])}</button>',
      )
      .join();
  final setups = {
    for (final e in ours) e.key: lookSetup(e.value['package'] as String),
  };
  final fallbacks = [
    for (final e in setups.entries)
      if (e.value == null) e.key,
  ];
  stdout.writeln(
    'Home setup code inline for ${ours.length - fallbacks.length} of ${ours.length} looks; the sentence for ${fallbacks.isEmpty ? 'none' : fallbacks.join(', ')}',
  );
  final setupBlocks = setups.entries
      .where((e) => e.value != null)
      .map(
        (e) =>
            '<pre class="setup" data-setup="${e.key}"${e.key == start ? '' : ' hidden'} tabindex="0" aria-label="${escape(looks[e.key]!['name'])} setup"><code>${highlight.parse(e.value!, language: 'dart').toHtml()}</code></pre>',
      )
      .join();
  final intro =
      '${numberWord(ours.length)} design systems for Flutter, one package per look, all built on one foundation, ui_core. Try each one’s components side by side, then add it to your app.';
  pageFile(
    'index.html',
    root: './',
    slug: 'home',
    title: 'Documentation',
    description: intro,
    script: 'home.js',
    content:
        '''
      <div class="home-intro"><div>
      <h1>Flutter Design Systems</h1>
      <p class="lead">${numberWord(ours.length)} design systems for Flutter, one package per look, all built on one foundation, <code>ui_core</code>. Each works under a <code>MaterialApp</code>, <code>CupertinoApp</code> or <code>WidgetsApp</code>, on phones and desktops, by day and by night.</p>
      <ol class="start" data-start="$start">
        <li><h2>Pick a look</h2><div class="look-chips" role="group" aria-label="Design system">$chips</div></li>
        <li><h2>Add its package</h2><div class="pub-add"><code>flutter pub add <span data-start-package>$startPackage</span></code><button type="button" class="copy">Copy</button></div></li>
        <li><h2>Build with its widgets</h2><div><p data-start-note${setups[start] == null ? '' : ' hidden'}>Wrap your app in the look’s theme as its README shows, then use its components:</p>$setupBlocks<p><a data-start-readme href="https://pub.dev/packages/$startPackage">$startName on pub.dev</a> · <a data-start-page href="looks/$start/">$startName components</a></p></div></li>
      </ol>
      ${actions(['<a class="primary-link" href="#components">Browse components <span aria-hidden="true">↓</span></a>', '<a data-follow-look href="stint/">Try Stint <span aria-hidden="true">→</span></a>', external(repository, 'GitHub'), external('https://pub.dev/packages/ui_core', 'ui_core on pub.dev')])}
      </div>
      <a class="study-card" data-follow-look href="stint/"><img src="assets/stint-today.webp" width="864" height="576" alt="The Today workspace in Minimal, with open tasks and weekly hours"><span><strong>Try Stint</strong><span>One team planner, built in every look <i aria-hidden="true">→</i></span></span></a></div>
      <section class="directory-section" id="looks"><h2>Design systems</h2>${lookCards('./')}</section>
      <section class="directory-section" id="components"><h2>Components</h2>${componentDirectory('./')}</section>''',
  );
  pageFile(
    'looks/index.html',
    root: '../',
    slug: 'looks',
    title: 'Design systems',
    description: 'Browse Flutter components in each design system.',
    content: '<h1>Design systems</h1>${lookCards('../')}',
  );
  for (final e in looks.entries) {
    final name = escape(e.value['name']);
    final id = e.key;
    final package = e.value['package'] as String;
    final reference = e.value['reference'] as String?;
    final lead = reference == null
        ? 'Explore the controls in $name and the Dart code behind them.'
        : 'Flutter’s own $reference library, <code>$package</code>, shown beside the design systems for comparison. Each component page shows the $reference widget a Flutter developer would reach for, or says that $reference has none.';
    pageFile(
      'looks/$id/index.html',
      root: '../../',
      slug: 'looks/$id',
      fixedLook: id,
      title: e.value['name'],
      description:
          'Explore Flutter components and examples in ${e.value['name']}.',
      content:
          '''
      <div class="breadcrumb"><a href="../">Design systems</a></div>
      <h1>$name</h1>
      <p class="lead">$lead</p>
      <div class="look-bar">${lookPicker('look-directory', selected: id)}</div>
      ${actions(['<a class="primary-link" data-follow-look href="../../stint/?look=$id">${studyPackages.containsKey(id) ? 'Try Stint' : 'Explore Stint editions'} <span aria-hidden="true">→</span></a>', external('https://pub.dev/packages/$package', 'Package on pub.dev'), if (reference == null) external('$repository/tree/main/packages/$package', 'Source on GitHub')])}
      ${lookFacts(id, e.value)}
      <section class="directory-section"><h2>Components in $name</h2>${componentDirectory('../../', look: id)}</section>''',
    );
  }
}

/// A look's palettes, corners and sheets, as its README gives them: the six
/// palette names and the corner sentence from looks.json (a test holds the
/// names to the package's), the README's first Dart block that sets a
/// `shapeScheme`, and a line where the look's bottom sheet stands on the
/// shell's bar. Empty for the reference libraries.
String lookFacts(String id, Json look) {
  final palettes = (look['palettes'] as List?)?.cast<String>();
  if (palettes == null) return '';
  final name = escape(look['name']);
  final theme = look['theme'] as String;
  final code = shapeBlock(look['package'] as String);
  final sheet = look['sheetOnBar'] == true
      ? '<h3>Sheets on the bar</h3><p>On ui_core 0.8.7 or later, a bottom sheet opened over the app shell’s places stands on the shell’s bar: the bar stays in view under the barrier, and a tap on it closes the sheet. A full-screen sheet and a dialog still cover the whole screen. <a href="../../bottom-sheet/$id/">Bottom sheet in $name</a></p>'
      : '';
  return '''
<section class="look-facts" id="theme"><h2>Theme</h2>
  <h3>Palettes</h3>
  <p>Six palettes, each by day and by night: <code>$theme.palettes</code>, each a <code>RawNamedPalette</code> with an id to store and a label to show. <code>$theme.preset(id, brightness)</code> builds a stored id’s theme again.</p>
  <ul class="palette-names">${palettes.map((p) => '<li>${escape(p)}</li>').join()}</ul>
  <h3>Corners</h3>
  ${html(look['corners'] as String)}${code == null ? '' : '<pre tabindex="0" aria-label="$name corners"><code>${highlight.parse(code, language: 'dart').toHtml()}</code></pre>'}
  $sheet
</section>''';
}

/// The README's first Dart block that sets a `shapeScheme`, at most 20 lines.
String? shapeBlock(String package) {
  final root = packageRoots[package];
  if (root == null) return null;
  final readme = File.fromUri(root.resolve('README.md'));
  if (!readme.existsSync()) return null;
  for (final match in RegExp(
    r'^```dart\n(.*?)^```',
    multiLine: true,
    dotAll: true,
  ).allMatches(readme.readAsStringSync())) {
    final block = match.group(1)!.trimRight();
    if (block.contains('shapeScheme:') && block.split('\n').length <= 20) {
      return block;
    }
  }
  return null;
}

void renderStint() {
  if (studyPackages.isEmpty) throw StateError('No Stint studies found');
  final first = studyPackages.containsKey('minimal')
      ? 'minimal'
      : studyPackages.keys.first;
  const intro =
      'Plan the studio’s day, edit tasks and log time. Switch design systems to try the same workspace with different controls and layouts.';
  pageFile(
    'stint/index.html',
    root: '../',
    slug: 'stint',
    title: 'Stint',
    description: intro,
    script: 'stint.js',
    content:
        '''
      <h1>Stint</h1>
      <p class="lead">$intro</p>
      <div class="look-bar">${lookPicker('look')}
        <a class="look-details" id="look-details" href="../looks/$first/">About this look</a>
      </div>
      <noscript><p><a href="../examples/?stint=$first">Open the ${escape(looks[first]!['name'])} app</a>. Stint requires JavaScript.</p></noscript>
      <div id="unavailable" hidden><p role="status"></p>
        <ul class="editions">${studyPackages.keys.map((id) => '<li><a href="?look=$id">${escape(looks[id]!['name'])}</a></li>').join()}</ul>
      </div>
      <div class="workbench study" id="study" data-start="$first" hidden>
        <div class="tools">${frameButtons('App frame width', desktopPressed: false)}<div class="study-display"><span class="frame-size"></span><a class="open-preview" href="../examples/?stint=$first" target="_blank" rel="noopener">Open full app <span aria-hidden="true">↗</span></a></div></div>
        ${quickControls()}
        <div class="stage"><div class="viewport"><div class="frame"><iframe title="Stint app"></iframe></div></div></div>
      </div>''',
  );
}

/// The Stint page's quick controls: each changes the running app in place.
/// Theme, text size and language stay in view on a phone; the rest open
/// under More.
String quickControls() {
  String choices(String key, String label, List<List<String>> options) =>
      '<div class="seg" role="group" aria-labelledby="quick-$key" data-set="$key">'
      '<span class="seg-label" id="quick-$key">$label</span>'
      '${options.map((o) => '<button type="button" data-value="${o[0]}" aria-pressed="false"${o.length > 2 ? ' lang="${o[2]}"' : ''}>${o[1]}</button>').join()}'
      '</div>';
  String toggle(String key, String label) =>
      '<button type="button" data-toggle="$key" aria-pressed="false"><i class="check" aria-hidden="true"></i>$label</button>';
  String toggles(String id, String label, List<String> buttons) =>
      '<div class="seg" role="group" aria-labelledby="quick-$id">'
      '<span class="seg-label" id="quick-$id">$label</span>${buttons.join()}</div>';
  return '<div class="tools quick" role="group" aria-label="App settings">'
      '${choices('theme', 'Theme', [
        ['day', 'Day'],
        ['night', 'Night'],
      ])}'
      '${choices('scale', 'Text', [
        ['1', '100%'],
        ['1.5', '150%'],
        ['2', '200%'],
      ])}'
      '${choices('lang', 'Language', [
        ['en', 'English', 'en'],
        ['ar', 'العربية', 'ar'],
        ['ja', '日本語', 'ja'],
        ['de', 'Deutsch', 'de'],
      ])}'
      '<button type="button" class="quick-more" aria-expanded="false" aria-controls="quick-extra">More</button>'
      '<div class="quick-extra" id="quick-extra">'
      '${accentChoices()}'
      '${choices('density', 'Density', [
        ['standard', 'Standard'],
        ['compact', 'Compact'],
      ]).replaceFirst('</div>', '<span class="seg-off" hidden></span></div>')}'
      '${toggles('access', 'Accessibility', [toggle('motion', 'Reduce motion'), toggle('bold', 'Bold text')])}'
      '${toggles('show', 'Show', [toggle('targets', 'Tap targets'), toggle('reader', 'Screen reader')])}'
      '</div></div>'
      '<p class="quick-note" id="quick-note" hidden></p>';
}

/// The accent control: empty and hidden until the running edition names its
/// palettes (the look's own first), which stint.js lists here.
String accentChoices() =>
    '<div class="seg" role="group" aria-labelledby="quick-accent" data-set="accent" hidden>'
    '<span class="seg-label" id="quick-accent">Accent</span></div>';

void renderNotFound() {
  pageFile(
    '404.html',
    root: './',
    slug: '404',
    title: 'Page not found',
    description: 'Find a component, design system or the Stint app in the documentation.',
    // Static hosts serve this same document at the missing URL, at any depth.
    base: '''
      <meta name="robots" content="noindex">
      <script>
        const path = location.pathname.split('/');
        const docs = path.indexOf('docs');
        const root = docs >= 0 ? path.slice(0, docs + 1).join('/') + '/'
          : location.hostname.endsWith('.github.io') ? '/flutter_design_systems/docs/' : '/docs/';
        const base = document.createElement('base');
        base.href = root;
        document.head.append(base);
      </script>''',
    content:
        '''
      <h1>Page not found</h1>
      <p class="lead">This address has no documentation page. Search the directory or return to the component list.</p>
      ${actions(['<a class="primary-link" href="./#components">Browse components</a>', '<a href="stint/">Open Stint</a>'])}
      <noscript><p><a href="$docsUrl">Flutter Design Systems documentation</a></p></noscript>''',
  );
}
