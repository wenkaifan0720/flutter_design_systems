/// Shared host for the Studio gallery's demo pages.
///
/// Every demo renders inside the environment a Studio page gets live: an app
/// with the theme the lab applied (theme.dart's [kitPreset]) over its
/// navigator, toasts above it, the appearance pinned because the preview
/// host ignores the shell's simulated platform brightness. A page the
/// example's Overview opens shares the example's app instead
/// ([KitGalleryScope]).
///
/// Demos import only the Studio barrel, this file, Flutter and the packages
/// Studio depends on.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import 'theme.dart';

/// The preset the gallery shows, unless the example or a test chooses
/// another.
String kitShownPreset = kitPreset;

/// A live theme override, for a test or the example.
StudioThemeData Function(Brightness brightness)? kitShownTheme;

/// The shown preset in either appearance.
StudioThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    StudioThemeData.preset(kitShownPreset, brightness);

/// Marks pages that share the example's app and navigator.
class KitGalleryScope extends InheritedWidget {
  /// Marks the embedded gallery [child].
  const KitGalleryScope({super.key, required super.child});

  /// Whether this page belongs to a shared app.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitGalleryScope>() != null;

  @override
  bool updateShouldNotify(KitGalleryScope oldWidget) => false;
}

/// [home] as an app of its own, lit by [brightness]: the theme over the
/// navigator, toasts over the app.
Widget kitApp({required Brightness brightness, required Widget home}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: studioPageTransitions,
        ),
      ),
      localizationsDelegates: const [
        StudioLocalizations.delegate,
        RawWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      builder: (context, child) => StudioTheme(
        data: kitTheme(brightness),
        child: StudioToaster(child: child ?? const SizedBox.shrink()),
      ),
      home: home,
    );

/// A demo page titled [title]: its [sections] down a column, each a
/// [KitSection]. Opened by the example's Overview, it is pushed in the
/// example's app with a back key; on its own it is an app.
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
    final margin = StudioSpacing.pageMargin(width);
    return StudioScaffold(
      appBar: StudioAppBar(title: title),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          StudioSpacing.large,
          margin,
          StudioSpacing.huge,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in sections.indexed) ...[
                    if (i > 0) const SizedBox(height: StudioSpacing.extraLarge),
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

/// One section of a demo page: its legend, a line saying what it shows,
/// then its examples, each starting on the column's edge.
class KitSection extends StatelessWidget {
  /// A section captioned [title].
  const KitSection({
    super.key,
    required this.title,
    this.note,
    required this.children,
    this.gap = StudioSpacing.regular,
  });

  /// The caption.
  final String title;

  /// What the section shows, in a line.
  final String? note;

  /// The examples.
  final List<Widget> children;

  /// The room between examples.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    return DesignKeylineRegion(
      label: title,
      startAligned: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioSectionHeader(title),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.regular),
              child: Text(
                note!,
                // The gallery's descriptions are English in both layout directions.
                textDirection: TextDirection.ltr,
                textAlign: Directionality.of(context) == TextDirection.rtl
                    ? TextAlign.right
                    : TextAlign.left,
                style: theme.textTheme.secondary.copyWith(
                  color: theme.colors.legendMuted,
                ),
              ),
            ),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) SizedBox(height: gap),
            child,
          ],
        ],
      ),
    );
  }
}

/// [children] side by side, wrapping, [StudioSpacing.medium] apart.
class KitRow extends StatelessWidget {
  /// A wrapping row of [children].
  const KitRow({super.key, required this.children});

  /// What stands in the row.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: StudioSpacing.medium,
    runSpacing: StudioSpacing.medium,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// Local state for a live demo: [initial] keeps its still the same every
/// time, and every callback updates the mounted part.
Widget kitState<T>(
  T initial,
  Widget Function(BuildContext context, T value, ValueChanged<T> change)
  builder,
) => _KitState<T>(initial: initial, builder: builder);

class _KitState<T> extends StatefulWidget {
  const _KitState({required this.initial, required this.builder});

  final T initial;
  final Widget Function(BuildContext, T, ValueChanged<T>) builder;

  @override
  State<_KitState<T>> createState() => _KitStateValue<T>();
}

class _KitStateValue<T> extends State<_KitState<T>> {
  late T value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, value, (next) => setState(() => value = next));
}

/// A visible answer for an action whose destination is outside the gallery.
void kitFeedback(BuildContext context, String message) =>
    showStudioToast(context, message);
