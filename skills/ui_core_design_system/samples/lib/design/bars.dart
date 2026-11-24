import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'overlays.dart';
import 'theme.dart';
import 'transitions.dart';

/// A screen of the app: its top bar, its body, and a bar along its foot when
/// it has actions there, on the design's ground.
///
/// The top bar holds the key that leaves the screen ([TendDismissKey]: back
/// on a pushed page, close on a sheet, nothing on a root), the title, which
/// names the route for a screen reader, and [actions] at its end.
class TendScaffold extends StatelessWidget {
  /// A screen titled [title] showing [body].
  const TendScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottomBar,
  });

  /// The screen's name, in its top bar.
  final String title;

  /// What the screen shows.
  final Widget body;

  /// Icon buttons at the top bar's end.
  final List<Widget> actions;

  /// What stands along the screen's foot, in a [TendBottomBar].
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    final c = theme.colors;
    final foot = bottomBar;
    return ColoredBox(
      color: c.ground,
      child: Padding(
        // The keyboard covers the foot: the bar stands above it.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.rule)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                  child: Row(
                    children: [
                      const TendDismissKey(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: Semantics(
                            header: true,
                            namesRoute: true,
                            child: Text(title, style: theme.title),
                          ),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: body),
            if (foot != null) TendBottomBar(child: foot),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

/// A screen's body at a readable width: the full width on a phone, a column
/// of at most [maxWidth] in the middle of a wider window, scrolling.
class TendColumn extends StatelessWidget {
  /// [children] in a scrolling column.
  const TendColumn({super.key, required this.children, this.maxWidth = 640});

  /// What the column holds, top to bottom.
  final List<Widget> children;

  /// The widest the column stands.
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// A section's heading inside a screen.
class TendHeading extends StatelessWidget {
  /// A heading saying [text].
  const TendHeading(this.text, {super.key});

  /// What it says.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          // A group's name reads as a field's label does: one voice for
          // every name on a form.
          style: theme.label.copyWith(color: theme.colors.ink),
        ),
      ),
    );
  }
}
