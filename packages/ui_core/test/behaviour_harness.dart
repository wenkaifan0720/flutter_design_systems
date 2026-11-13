// A bare app for the behaviour tests: no Material, no Cupertino. WidgetsApp
// gives MediaQuery, focus, the default shortcuts (Enter, Space, Escape, Tab)
// and a Navigator with an Overlay; [harness] sets the reader's settings.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// [home] in a bare app, as a reader with [textDirection], [textScale],
/// Reduce Motion ([reduceMotion]) and a screen reader
/// ([accessibleNavigation]) sees it. [wrap] goes around the navigator
/// (a toaster).
Widget harness(
  Widget home, {
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1,
  bool reduceMotion = false,
  bool accessibleNavigation = false,
  TransitionBuilder? wrap,
}) {
  return WidgetsApp(
    color: const Color(0xFF000000),
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
    home: home,
    builder: (context, navigator) {
      final data = MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
        accessibleNavigation: accessibleNavigation,
      );
      return MediaQuery(
        data: data,
        child: Directionality(
          textDirection: textDirection,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
            child: wrap?.call(context, navigator) ?? navigator!,
          ),
        ),
      );
    },
  );
}

/// A plain face for a pressable in the reference painters: [label] in a box.
Widget plainFace(String label, {Key? key}) => Container(
  key: key,
  color: const Color(0xFFE0E0E0),
  padding: const EdgeInsets.all(8),
  child: Text(label),
);

/// A plain text input for the reference painters.
Widget plainField({
  required TextEditingController controller,
  required FocusNode focusNode,
  VoidCallback? onSubmitted,
  ValueChanged<String>? onChanged,
  bool obscureText = false,
  Key? key,
  double width = 200,
}) => SizedBox(
  key: key,
  width: width,
  child: EditableText(
    controller: controller,
    focusNode: focusNode,
    obscureText: obscureText,
    style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
    cursorColor: const Color(0xFF000000),
    backgroundCursorColor: const Color(0xFF808080),
    onChanged: onChanged,
    onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
  ),
);

/// The semantics tree's owner, for performing a screen reader's action:
/// the one view's.
SemanticsOwner semanticsOwner() =>
    WidgetsBinding.instance.renderViews.first.owner!.semanticsOwner!;
