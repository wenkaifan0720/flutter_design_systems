import 'package:cupertino_ui/cupertino_ui.dart';

/// Cupertino draws with the platform's text face and the preloaded
/// CupertinoIcons font.
Future<void> cupertinoLoadFonts() async {}

Widget wrapLook(Brightness brightness, Widget child) => CupertinoTheme(
  data: CupertinoThemeData(brightness: brightness),
  child: Builder(
    builder: (context) => ColoredBox(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle,
        child: child,
      ),
    ),
  ),
);
