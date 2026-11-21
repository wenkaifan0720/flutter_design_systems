/// What every Keycap gallery page stands on: the app round a page, its
/// screen, its sections and rows.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';

import 'theme.dart';

/// The preset the gallery shows.
String kitShownPreset = kitPreset;

/// A theme the gallery shows instead of the preset (a brand's).
KeycapThemeData Function(Brightness brightness)? kitShownTheme;

/// The theme a gallery page wears.
KeycapThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ?? KeycapThemeData.of(brightness);

/// Marks a page as shown inside the gallery's own app, so it builds no app
/// of its own.
class KitGalleryScope extends InheritedWidget {
  /// Marks [child].
  const KitGalleryScope({super.key, required super.child});

  /// Whether [context] is inside the gallery's app.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitGalleryScope>() != null;

  @override
  bool updateShouldNotify(KitGalleryScope oldWidget) => false;
}

/// An app round [home], in Keycap by [brightness].
Widget kitApp({required Brightness brightness, required Widget home}) =>
    Semantics(
      container: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: keycapPageTransitions,
          ),
        ),
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: RawWidgetsLocalizations.supportedLocales,
        builder: (context, child) => KeycapTheme(
          data: kitTheme(brightness),
          child: KeycapToaster(child: child ?? const SizedBox.shrink()),
        ),
        home: home,
      ),
    );

/// A gallery page named [title], its [sections] down it.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
}) => Builder(
  builder: (context) {
    final page = _KitPage(title: title, sections: sections);
    if (KitGalleryScope.of(context)) return page;
    return kitApp(brightness: brightness, home: page);
  },
);

class _KitPage extends StatelessWidget {
  const _KitPage({required this.title, required this.sections});

  final String title;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    return KeycapScreen(
      topBar: KeycapAppBar(
        title: title,
        onBack: route?.canPop ?? false
            ? () => Navigator.of(context).maybePop()
            : null,
      ),
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, s) in sections.indexed) ...[
                if (i > 0) const SizedBox(height: KeycapSpacing.extraLarge),
                s,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A section of a gallery page: its [title] printed over a well holding
/// [children] (on the case when not [well]).
class KitSection extends StatelessWidget {
  /// A section.
  const KitSection({
    super.key,
    required this.title,
    this.note,
    required this.children,
    this.gap = KeycapSpacing.regular,
    this.well = true,
  });

  /// Its title.
  final String title;

  /// A line under the title.
  final String? note;

  /// What it shows.
  final List<Widget> children;

  /// The space between [children].
  final double gap;

  /// Whether they stand in a well.
  final bool well;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) SizedBox(height: gap),
          child,
        ],
      ],
    );
    return DesignKeylineRegion(
      label: title,
      startAligned: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // In a well the header insets to the rows' words; on the case it
          // stands flush with the parts below it.
          KeycapSectionHeader(
            title,
            style: well
                ? null
                : const KeycapStyle(
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: KeycapSpacing.small),
                    ),
                  ),
          ),
          if (note != null)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: well ? KeycapSpacing.regular : 0,
                end: well ? KeycapSpacing.regular : 0,
                bottom: KeycapSpacing.medium,
              ),
              child: Text(note!, style: theme.textTheme.secondary),
            ),
          if (well) KeycapCard(child: body) else body,
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

/// The inventory's live specimens for [rows] (ids of ui_core's shared
/// list), each a section on the case named as the list names it: the
/// gallery and the registry show the same parts.
List<Widget> kitSpecimens(List<String> rows) => [
  for (final id in rows)
    if (keycapInventory.entryFor(id)?.builder case final build?)
      KitSection(
        title: DesignInventoryRow.byId(id)?.name ?? id,
        well: false,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              height: keycapInventoryHeights[id],
              child: Builder(builder: build),
            ),
          ),
        ],
      ),
];

/// A row of parts that wraps.
class KitRow extends StatelessWidget {
  /// A row.
  const KitRow({super.key, required this.children});

  /// The parts.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: KeycapSpacing.small,
    runSpacing: KeycapSpacing.small,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}
