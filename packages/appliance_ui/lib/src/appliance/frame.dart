/// The app's frame: a tab ([ApplianceTab]), the app's one act
/// ([ApplianceShellAction]), a page while its data comes and when it
/// cannot ([ApplianceLoadingState], [ApplianceErrorState]), a one-line
/// field in short form ([ApplianceInput]) and a page's preview as the app
/// frames it ([AppliancePreview]). The router's pages are [AppliancePage]
/// and [ApplianceSheetPage].
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'app.dart';
import 'button.dart';
import 'feedback.dart';
import 'internal/state_plate.dart';
import 'navigation.dart';
import 'overlays.dart';
import 'page_transitions.dart';
import 'text_field.dart';
import 'theme.dart';

/// One tab as an app declares it: its glyph, its name and the key on its
/// hit target (a test finds and presses it by that key).
///
/// ```dart
/// ApplianceTab(LucideIcons.house, 'Home', key: ValueKey('open-home'))
/// ```
@immutable
class ApplianceTab {
  /// The tab [label], marked by [icon].
  const ApplianceTab(this.icon, this.label, {this.key});

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// The key on its hit target.
  final Key? key;

  /// The place it is in [ApplianceScaffold]'s navigation.
  ApplianceDestination get destination =>
      ApplianceDestination(icon: icon, label: label, key: key);
}

/// The app's one act beside its places (add, write, capture): on a phone a
/// square key at the end of the key strip, on a tablet a key at the top of
/// the rail, on a desk a wide key at the top of the side panel. The signal
/// key when [accent], a plain key otherwise.
///
/// ```dart
/// ApplianceShellAction(icon: LucideIcons.plus, label: 'New list', accent: true, onPressed: (context) {})
/// ```
class ApplianceShellAction extends ShellAction {
  /// The act [onPressed], wearing [icon].
  const ApplianceShellAction({
    required super.icon,
    required super.onPressed,
    super.label,
    super.accent,
    super.key,
  });
}

/// A page's data on its way: the look's turning ring in a sunk bezel, and
/// what is loading.
///
/// ```dart
/// ApplianceScreen(body: const ApplianceLoadingState(label: 'Loading orders'))
/// ```
class ApplianceLoadingState extends StatelessWidget {
  /// A page loading [label] (the words' "Loading" when null).
  const ApplianceLoadingState({super.key, this.label});

  /// What is loading.
  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: ApplianceSpacing.huge),
      child: ApplianceStatusView(
        status: ApplianceStatus.working,
        title: label ?? RawWidgetsLocalizations.of(context).loadingLabel,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }
}

/// A page's data that could not load, the [ApplianceEmptyState]'s sibling:
/// the same faceplate and display window, the window reading a fault code
/// at full strength, the danger lamp lit beside what happened, and a key to
/// try again.
///
/// ```dart
/// ApplianceErrorState(title: 'Could not load the orders', message: 'Check the connection.', onRetry: () {})
/// ```
class ApplianceErrorState extends StatelessWidget {
  /// A failure titled [title].
  const ApplianceErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.reading = 'Err',
  });

  /// What failed.
  final String title;

  /// Why, or what to do.
  final String? message;

  /// Tries again; null: no key.
  final VoidCallback? onRetry;

  /// What the window reads: an appliance's fault code.
  final String reading;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: ApplianceStatePlate(
      reading: reading,
      lit: true,
      lamp: ApplianceTheme.of(context).colors.danger,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : ApplianceButton(
              RawWidgetsLocalizations.of(context).retryButtonLabel,
              onPressed: onRetry,
            ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('retry', value: onRetry != null, ifTrue: 'retry'));
  }
}

/// A one-line field in short form: an [ApplianceTextField] with its
/// [labelText] or [hintText], hidden letters when [obscureText], and an
/// [errorText] under its well.
///
/// ```dart
/// ApplianceInput(key: const ValueKey('postcode'), labelText: 'Postcode', onChanged: (text) {})
/// ```
class ApplianceInput extends StatelessWidget {
  /// A field.
  const ApplianceInput({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  /// Its name, over the well.
  final String? labelText;

  /// What it asks for, in the empty well.
  final String? hintText;

  /// Its text, owned by the caller; null: its own.
  final TextEditingController? controller;

  /// Whether its letters are hidden (a password).
  final bool obscureText;

  /// What is wrong with what was typed; null: nothing.
  final String? errorText;

  /// Called with the text as it changes.
  final ValueChanged<String>? onChanged;

  /// Called with the text when it is sent.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => ApplianceTextField(
    labelText: labelText,
    hintText: hintText,
    controller: controller,
    obscureText: obscureText,
    errorText: errorText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscure'));
  }
}

/// How a page stands in its [AppliancePreview].
enum AppliancePresentation {
  /// A place: its page with the app's navigation.
  root,

  /// A page pushed over a place.
  pushed,

  /// A page raised as a sheet.
  sheet,
}

/// One page's preview as the app frames it, without the router: the host,
/// the places and the act round a [AppliancePresentation.root] page, the
/// page change under a pushed one, the sheet round a sheet.
///
/// ```dart
/// AppliancePreview(tabs: const [ApplianceTab(LucideIcons.house, 'Home')], child: ApplianceScreen(topBar: const ApplianceAppBar(title: 'Home'), body: const Text('Today')))
/// ```
class AppliancePreview extends StatelessWidget {
  /// [child] framed as [presentation].
  const AppliancePreview({
    super.key,
    required this.child,
    this.light,
    this.dark,
    this.presentation = AppliancePresentation.root,
    this.tabs = const [],
    this.selectedIndex = 0,
    this.action,
    this.drawer = false,
    this.platform = PreviewPlatform.android,
    this.brightness = Brightness.light,
  });

  /// The page.
  final Widget child;

  /// The theme by day; [ApplianceThemeData.light] when null.
  final ApplianceThemeData? light;

  /// The theme by night; [ApplianceThemeData.dark] when null.
  final ApplianceThemeData? dark;

  /// How the page stands.
  final AppliancePresentation presentation;

  /// The app's places, round a root page.
  final List<ApplianceTab> tabs;

  /// The place the page is.
  final int selectedIndex;

  /// The app's act, beside its places.
  final ShellAction? action;

  /// Whether a sheet stands only as tall as a drawer.
  final bool drawer;

  /// The platform whose behaviour applies.
  final PreviewPlatform platform;

  /// Day or night.
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    Widget framed(Widget page) => tabs.isEmpty
        ? page
        : ApplianceScaffold(
            destinations: [for (final tab in tabs) tab.destination],
            selectedIndex: selectedIndex,
            onSelected: (_) {},
            action: action,
            body: page,
          );
    // The previewed app stands in a semantics container of its own: its first
    // page's modal barrier would otherwise hide from a screen reader
    // everything its host painted before it.
    return PreviewFrame(
      platform: platform,
      brightness: brightness,
      child: Semantics(
        container: true,
        child: MaterialApp(
          key: ValueKey<Object>((presentation, drawer)),
          debugShowCheckedModeBanner: false,
          builder: (context, app) => ApplianceHost(
            light: light,
            dark: dark,
            brightness: brightness,
            child: app ?? const SizedBox.shrink(),
          ),
          home: switch (presentation) {
            AppliancePresentation.root => framed(child),
            AppliancePresentation.pushed => PreviewStage(
              route: (context, page) => AppliancePage<void>(
                key: const ValueKey<String>('appliance-preview'),
                child: page,
              ).createRoute(context),
              child: child,
            ),
            AppliancePresentation.sheet => PreviewStage(
              route: (context, page) => ApplianceSheetPage<void>(
                key: const ValueKey<String>('appliance-preview'),
                size: drawer
                    ? ApplianceSheetSize.drawer
                    : ApplianceSheetSize.standard,
                child: page,
              ).createRoute(context),
              child: child,
            ),
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty('presentation', presentation))
      ..add(IntProperty('tabs', tabs.length))
      ..add(EnumProperty('brightness', brightness));
  }
}
