/// Shared host for the Appliance gallery's demo pages.
///
/// Every demo renders inside the environment an Appliance page gets live:
/// an app with the theme over its navigator, toasts above it, the
/// appearance set by the gallery rather than taken from the platform. A
/// page the example's Overview opens shares the example's app instead
/// ([KitGalleryScope]).
///
/// Demos import only the Appliance barrel, this file, Flutter and the
/// packages Appliance depends on.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:appliance_ui/appliance_ui.dart';

import 'theme.dart';

/// The palette the gallery shows (an id of ApplianceThemeData.palettes).
String kitShownPreset = kitPreset;

/// A live theme override, for a test or the example.
ApplianceThemeData Function(Brightness brightness)? kitShownTheme;

/// The shown theme in either appearance.
ApplianceThemeData kitTheme(Brightness brightness) =>
    kitShownTheme?.call(brightness) ??
    ApplianceThemeData.preset(kitShownPreset, brightness);

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

/// [key] with the platform's main modifier: Cmd on Apple's platforms,
/// Ctrl elsewhere.
SingleActivator kitShortcut(LogicalKeyboardKey key) {
  final apple = switch (defaultTargetPlatform) {
    TargetPlatform.macOS || TargetPlatform.iOS => true,
    _ => false,
  };
  return SingleActivator(key, meta: apple, control: !apple);
}

/// [kitShortcut]'s words, as a menu's or a command's shortcut: Appliance's
/// face draws no ⌘, so Apple's keys go by their names.
String kitShortcutLabel(BuildContext context, LogicalKeyboardKey key) =>
    rawShortcutLabel(context, kitShortcut(key), appleSymbols: false);

/// [home] as an app of its own, lit by [brightness]: the theme over the
/// navigator, toasts over the app. It stands in a semantics container, so
/// that inside a host's preview its first page's barrier hides nothing of the
/// host's.
Widget kitApp({required Brightness brightness, required Widget home}) =>
    Semantics(
      container: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: appliancePageTransitions,
          ),
        ),
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: RawWidgetsLocalizations.supportedLocales,
        builder: (context, child) => ApplianceTheme(
          data: kitTheme(brightness),
          child: ApplianceToaster(child: child ?? const SizedBox.shrink()),
        ),
        home: home,
      ),
    );

/// A demo page titled [title]: its [sections] down a column, each a
/// [KitSection]. Opened by the example's Overview, it is pushed in the
/// example's app with a way back; on its own it is an app.
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
    return ApplianceScreen(
      topBar: ApplianceAppBar(
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
                if (i > 0) const SizedBox(height: ApplianceSpacing.extraLarge),
                s,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One section of a demo page: its caps legend, a line saying what it
/// shows, then its examples on a faceplate.
class KitSection extends StatelessWidget {
  /// A section captioned [title].
  const KitSection({
    super.key,
    required this.title,
    this.note,
    required this.children,
    this.gap = ApplianceSpacing.regular,
    this.plate = true,
  });

  /// The caption.
  final String title;

  /// What the section shows, in a line.
  final String? note;

  /// The examples.
  final List<Widget> children;

  /// The room between examples.
  final double gap;

  /// Whether the examples stand on a faceplate.
  final bool plate;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) SizedBox(height: gap),
          child,
        ],
      ],
    );
    return RawKeylineRegion(
      label: title,
      startAligned: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ApplianceSectionHeader(title),
          if (note != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: ApplianceSpacing.regular,
                end: ApplianceSpacing.regular,
                bottom: ApplianceSpacing.medium,
              ),
              child: Text(note!, style: theme.textTheme.secondary),
            ),
          if (plate) AppliancePanel(child: body) else body,
        ],
      ),
    );
  }
}

/// [children] side by side, wrapping, [ApplianceSpacing.regular] apart.
class KitRow extends StatelessWidget {
  /// A wrapping row of [children].
  const KitRow({super.key, required this.children});

  /// What stands in the row.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: ApplianceSpacing.regular,
    runSpacing: ApplianceSpacing.regular,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}
