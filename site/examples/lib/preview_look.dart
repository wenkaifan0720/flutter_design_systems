import 'package:flutter/widgets.dart';

/// The route table and application theme of one deferred example library.
class PreviewLook {
  const PreviewLook(this.name, this.wrapTheme, this.examples);

  final String name;
  final Widget Function(Brightness, Widget) wrapTheme;
  final Map<String, WidgetBuilder> examples;
}
