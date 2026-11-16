/// The host every Terminal gallery page and every slipway screen renders
/// in: a MaterialApp under [TermTheme], night or paper, its toasts hosted,
/// a finger's floors under 600 wide and a pointer's above.
///
/// Demos import only the Terminal barrel, this file, Flutter and slipway's
/// data.
library;

import 'package:flutter/material.dart';
import 'package:terminal_ui/terminal_ui.dart';

export 'slipway_data.dart';

/// The direction every page is shown in; a test sets it to sweep right to
/// left.
TextDirection kitShownDirection = TextDirection.ltr;

/// The text scale the example shows at (a link's `scale=2`); 1: the
/// platform's own.
double kitTextScale = 1;

/// What a gallery page's back key does (the example sets it while a part's
/// page shows); null: no back key.
VoidCallback? kitOnBack;

/// [home] in Terminal's [brightness] preset (night or paper), laid out
/// [direction] (null: [kitShownDirection]).
Widget kitApp({
  required Brightness brightness,
  required Widget home,
  TextDirection? direction,
  TermThemeData? theme,
}) {
  final data = theme ?? TermThemeData.of(brightness);
  final dir = direction ?? kitShownDirection;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'slipway',
    color: data.background,
    // A MaterialPageRoute from Flutter's own Material reads this theme, not
    // the one TermTheme sets on the Material the package draws on: every
    // route pushed in the gallery changes screens as Terminal does.
    theme: ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: termPageTransitions,
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: kitTextScale == 1
          ? MediaQuery.of(context)
          : MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(kitTextScale)),
      child: Directionality(
        textDirection: dir,
        child: TermTheme(
          data: data,
          child: Builder(
            builder: (context) {
              // A phone's width is reached by a finger, a desk's by a pointer.
              final narrow = MediaQuery.sizeOf(context).width < 600;
              return DesignTapTargetScope(
                targets: DesignTapTargets.of(context).copyWith(
                  input: narrow ? DesignInput.touch : DesignInput.pointer,
                ),
                child: TermToaster(
                  child: ColoredBox(color: data.background, child: child!),
                ),
              );
            },
          ),
        ),
      ),
    ),
    home: home,
  );
}

/// A gallery page: a title line and [sections] down a scroll, one page
/// margin (a cell) round them.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  required List<Widget> sections,
}) => kitApp(
  brightness: brightness,
  home: _KitPage(title: title, sections: sections),
);

class _KitPage extends StatelessWidget {
  const _KitPage({required this.title, required this.sections});

  final String title;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TermTopBar(
            leading: kitOnBack == null
                ? null
                : TermIconButton(
                    glyph: Directionality.of(context) == TextDirection.rtl
                        ? '→'
                        : '←',
                    semanticLabel: 'back to the overview',
                    onPressed: kitOnBack,
                  ),
            title: 'terminal_ui',
            subtitle: title,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: grid.cellWidth,
                vertical: grid.lineHeight,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: grid.cols(96)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final section in sections) ...[
                        section,
                        SizedBox(height: grid.lineHeight),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section of a gallery page: [title] over [children], a line between
/// each.
Widget kitSection(String title, {required List<Widget> children}) => Builder(
  builder: (context) {
    final grid = context.termGrid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TermSectionHeader(title: title),
        SizedBox(height: grid.lineHeight),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: grid.lineHeight),
          children[i],
        ],
      ],
    );
  },
);

/// [children] in a row, a cell between each, wrapping.
Widget kitRow(List<Widget> children) => Builder(
  builder: (context) {
    final grid = context.termGrid;
    return Wrap(
      spacing: grid.cellWidth,
      runSpacing: grid.lineHeight,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  },
);

/// A section per part in [parts], each its title over the part, live, as
/// the inventory builds it (one specimen per part, the gallery's and the
/// inventory's alike).
List<Widget> kitParts(List<(String, String)> parts) => [
  for (final (title, row) in parts)
    kitSection(
      title,
      children: [
        Builder(
          builder: (context) => termInventory.entryFor(row)!.builder!(context),
        ),
      ],
    ),
];
