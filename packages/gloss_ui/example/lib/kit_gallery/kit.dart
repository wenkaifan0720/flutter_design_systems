/// The Gloss gallery's frame: the theme every demo shows in, the app round
/// a demo shown on its own, and the page, section and row every demo is
/// laid out with.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';

import 'theme.dart';

/// The preset the gallery shows; its picker changes it.
String kitShownPreset = kitPreset;

/// A theme the gallery shows instead of a preset (a brand's), when set.
GlossThemeData Function(Brightness brightness)? kitShownTheme;

/// The theme a demo shows in.
GlossThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    GlossThemeData.preset(kitShownPreset, brightness);

/// Marks a demo shown inside the gallery's own app, which brings its theme.
class KitGalleryScope extends InheritedWidget {
  /// The scope over [child].
  const KitGalleryScope({super.key, required super.child});

  /// Whether [context] is inside the gallery's app.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitGalleryScope>() != null;

  @override
  bool updateShouldNotify(KitGalleryScope oldWidget) => false;
}

/// An app round [home], in Gloss at [brightness].
Widget kitApp({required Brightness brightness, required Widget home}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: glossPageTransitions,
        ),
      ),
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      builder: (context, child) => GlossTheme(
        data: kitTheme(brightness),
        child: GlossToaster(child: child ?? const SizedBox.shrink()),
      ),
      home: home,
    );

/// A demo page titled [title] holding [sections].
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
    final width = MediaQuery.sizeOf(context).width;
    final margin = GlossSpacing.pageMargin(width);
    final route = ModalRoute.of(context);
    return GlossScaffold(
      topBar: GlossTopBar(
        title: title,
        onBack: route?.canPop ?? false
            ? () => Navigator.of(context).maybePop()
            : null,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          GlossSpacing.large,
          margin,
          GlossSpacing.huge,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in sections.indexed) ...[
                    if (i > 0) const SizedBox(height: GlossSpacing.extraLarge),
                    s,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A demo's section: a letterpressed [title], a [note] under it, then
/// [children] [gap] apart.
class KitSection extends StatelessWidget {
  /// A section titled [title].
  const KitSection({
    super.key,
    required this.title,
    this.note,
    required this.children,
    this.gap = GlossSpacing.regular,
    this.maxWidth = double.infinity,
  });

  /// The widest its [children] stand (a form's fields, near their words).
  final double maxWidth;

  /// Its head.
  final String title;

  /// A line under the head.
  final String? note;

  /// What it shows.
  final List<Widget> children;

  /// The room between [children].
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    return RawKeylineRegion(
      label: title,
      startAligned: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A demo section's head stands on the content's edge: the parts
          // under it are loose, not rows in a well (a well's own head is
          // inset to its rows' words).
          Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: GlossSpacing.small,
            ),
            child: Semantics(
              header: true,
              // A section's head outranks the labels in it: the label size,
              // heavier, in full ink, pressed into the page.
              child: Text(
                title,
                style: glossLetterpress(
                  theme.textTheme.label.copyWith(
                    color: theme.colors.ink,
                    fontWeight: FontWeight.w600,
                    fontVariations: glossWeightAxis(FontWeight.w600),
                  ),
                  theme.colors,
                ),
              ),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: GlossSpacing.regular,
              ),
              child: Text(note!, style: theme.textTheme.secondary),
            ),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) SizedBox(height: gap),
            if (maxWidth.isFinite)
              Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              )
            else
              child,
          ],
        ],
      ),
    );
  }
}

/// Parts side by side, wrapping.
class KitRow extends StatelessWidget {
  /// A row of [children].
  const KitRow({super.key, required this.children});

  /// The parts.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: GlossSpacing.regular,
    runSpacing: GlossSpacing.regular,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}
