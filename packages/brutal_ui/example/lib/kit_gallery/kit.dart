/// Shared host for the Brutal gallery's demo pages.
///
/// Every demo renders inside the environment a Brutal page gets live: an app
/// with the theme the lab applied (theme.dart's [kitPreset]) over its
/// navigator, toasts above it, the appearance pinned because the preview
/// host ignores the shell's simulated platform brightness. A page the
/// example's Overview opens shares the example's app instead
/// ([KitGalleryScope]).
///
/// Demos import only the Brutal barrel, this file, Flutter and the packages
/// Brutal depends on.
library;

import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';

import 'theme.dart';

/// The preset the gallery shows, unless the example or a test chooses
/// another.
String kitShownPreset = kitPreset;

/// A live theme override, for a test or the example.
BrutalThemeData Function(Brightness brightness)? kitShownTheme;

/// The shown preset in either appearance.
BrutalThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    BrutalThemeData.preset(kitShownPreset, brightness);

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
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      builder: (context, child) => BrutalTheme(
        data: kitTheme(brightness),
        child: BrutalToaster(child: child ?? const SizedBox.shrink()),
      ),
      home: home,
    );

/// A demo page titled [title]: its [sections] down a column, each a
/// [KitSection]. Opened by the example's Overview, it is pushed in the
/// example's app with a back cell; on its own it is an app.
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
    final margin = BrutalSpacing.pageMargin(width);
    final route = ModalRoute.of(context);
    return BrutalScaffold(
      appBar: BrutalAppBar(
        title: title,
        onBack: route?.canPop ?? false
            ? () => Navigator.of(context).maybePop()
            : null,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          BrutalSpacing.large,
          margin,
          BrutalSpacing.huge,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in sections.indexed) ...[
                    if (i > 0) const SizedBox(height: BrutalSpacing.extraLarge),
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

/// One section of a demo page: its caption, a line saying what it shows,
/// then its examples, each starting on the column's edge.
class KitSection extends StatelessWidget {
  /// A section captioned [title].
  const KitSection({
    super.key,
    required this.title,
    this.note,
    required this.children,
    this.gap = BrutalSpacing.regular,
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
    final theme = BrutalTheme.of(context);
    return RawKeylineRegion(
      label: title,
      startAligned: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrutalSectionHeader(title),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: BrutalSpacing.regular),
              child: Text(note!, style: theme.textTheme.secondary),
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

/// [children] side by side, wrapping, [BrutalSpacing.regular] apart (and
/// room for the hard shadow under each row).
class KitRow extends StatelessWidget {
  /// A wrapping row of [children].
  const KitRow({super.key, required this.children});

  /// What stands in the row.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: BrutalSpacing.regular,
    runSpacing: BrutalSpacing.regular + BrutalMetrics.shadowOffset,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// Places a gallery example at the top, middle or bottom of the screen,
/// or lets it fill the screen.
class KitFrame {
  /// A band [height] tall on the phone's bottom edge.
  const KitFrame.bottom(double this.height) : _place = _KitPlace.bottom;

  /// A band [height] tall on the phone's top edge.
  const KitFrame.top(double this.height) : _place = _KitPlace.top;

  /// A band [height] tall across the middle, in the page's margins.
  const KitFrame.band(double this.height) : _place = _KitPlace.band;

  /// The whole phone; the builder draws its own screen.
  const KitFrame.screen() : height = null, _place = _KitPlace.screen;

  /// The band's height in logical px; null for the whole phone.
  final double? height;
  final _KitPlace _place;
}

enum _KitPlace { bottom, top, band, screen }

/// Applies the requested preset and brightness to a gallery example and
/// positions [child] in its [frame].
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  builder: (context, home) => BrutalTheme(
    data: BrutalThemeData.preset(style, brightness),
    child: BrutalToaster(child: home ?? const SizedBox.shrink()),
  ),
  home: _KitStage(frame: frame, child: child),
);

class _KitStage extends StatelessWidget {
  const _KitStage({required this.frame, required this.child});

  final KitFrame frame;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final margin = BrutalSpacing.pageMargin(MediaQuery.sizeOf(context).width);
    return ColoredBox(
      color: BrutalTheme.of(context).colors.paper,
      child: switch (frame._place) {
        _KitPlace.bottom => Stack(
          fit: StackFit.expand,
          children: [Positioned(left: 0, right: 0, bottom: 0, child: child)],
        ),
        _KitPlace.top => Stack(
          fit: StackFit.expand,
          children: [Positioned(left: 0, right: 0, top: 0, child: child)],
        ),
        // A band sits in the page's own margins, as it would in a body.
        _KitPlace.band => Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: child,
          ),
        ),
        _KitPlace.screen => child,
      },
    );
  }
}

/// Local state for a live specimen: [initial] keeps its still the same
/// every time, and every callback updates the mounted part.
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

/// A controller a live specimen owns: made once by [create], handed to
/// [builder], disposed by [dispose] with the specimen.
Widget kitOwned<T>({
  required T Function() create,
  required void Function(T owned) dispose,
  required Widget Function(BuildContext context, T owned) builder,
}) => _KitOwned<T>(create: create, dispose: dispose, builder: builder);

class _KitOwned<T> extends StatefulWidget {
  const _KitOwned({
    required this.create,
    required this.dispose,
    required this.builder,
  });

  final T Function() create;
  final void Function(T) dispose;
  final Widget Function(BuildContext, T) builder;

  @override
  State<_KitOwned<T>> createState() => _KitOwnedState<T>();
}

class _KitOwnedState<T> extends State<_KitOwned<T>> {
  late final T _owned = widget.create();

  @override
  void dispose() {
    widget.dispose(_owned);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _owned);
}

/// A visible answer for an action whose destination is outside the gallery.
void kitFeedback(BuildContext context, String message) =>
    showBrutalToast(context, message);
