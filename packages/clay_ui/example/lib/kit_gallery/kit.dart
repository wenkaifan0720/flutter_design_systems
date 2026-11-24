/// The Clay gallery's frame: the theme every demo shows in, the app round
/// a demo shown on its own, and the page, section and row every demo is
/// laid out with.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';

import 'theme.dart';

/// The preset the gallery shows; its picker changes it.
String kitShownPreset = kitPreset;

/// A theme the gallery shows instead of a preset (a brand's), when set.
ClayThemeData Function(Brightness brightness)? kitShownTheme;

/// The theme a demo shows in.
ClayThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    ClayThemeData.preset(kitShownPreset, brightness);

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

/// An app round [home], in Clay at [brightness].
Widget kitApp({required Brightness brightness, required Widget home}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: clayPageTransitions,
        ),
      ),
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      builder: (context, child) => ClayTheme(
        data: kitTheme(brightness),
        child: ClayToaster(child: child ?? const SizedBox.shrink()),
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
    final margin = ClaySpacing.pageMargin(width);
    final route = ModalRoute.of(context);
    // The bar spans the content column and its margins, so the page's title
    // starts where the sections do at every width.
    const column = 720.0;
    return ClayScaffold(
      topBar: ColoredBox(
        color: context.clayTheme.colors.ground,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: column + 2 * margin),
            child: ClayTopBar(
              title: title,
              onBack: route?.canPop ?? false
                  ? () => Navigator.of(context).maybePop()
                  : null,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          ClaySpacing.regular,
          margin,
          ClaySpacing.huge,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: column),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in sections.indexed) ...[
                    if (i > 0) const SizedBox(height: ClaySpacing.extraLarge),
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

/// A demo's section: a [title], a [note] under it, then [children] [gap]
/// apart.
class KitSection extends StatelessWidget {
  /// A section titled [title].
  const KitSection({
    super.key,
    required this.title,
    this.note,
    required this.children,
    this.gap = ClaySpacing.regular,
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
    final theme = ClayTheme.of(context);
    return RawKeylineRegion(
      label: title,
      startAligned: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: ClaySpacing.small,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.title.copyWith(color: theme.colors.ink),
              ),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: ClaySpacing.regular,
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
    spacing: ClaySpacing.regular,
    runSpacing: ClaySpacing.regular,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// A value a demo keeps, so its part answers as it will in an app.
class KitLive<T> extends StatefulWidget {
  /// [builder] over a value that starts at [initial].
  const KitLive(this.initial, this.builder, {super.key});

  /// The value it starts at.
  final T initial;

  /// The part, given the value and a way to change it.
  final Widget Function(BuildContext context, T value, ValueChanged<T> set)
  builder;

  @override
  State<KitLive<T>> createState() => _KitLiveState<T>();
}

class _KitLiveState<T> extends State<KitLive<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, (next) => setState(() => _value = next));
}
