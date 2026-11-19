import 'package:flutter/widgets.dart';

/// Builds with whether [node] holds the focus the keyboard gave it: the
/// focus shows (the yellow plate) only while the keyboard is in use, as a
/// pressable's does; a press that focuses a part shows none.
class CivicKeyFocus extends StatefulWidget {
  /// Follows [node].
  const CivicKeyFocus({super.key, required this.node, required this.builder});

  /// The node to follow.
  final FocusNode node;

  /// Builds with whether the focus shows.
  final Widget Function(BuildContext context, bool shown) builder;

  @override
  State<CivicKeyFocus> createState() => _CivicKeyFocusState();
}

class _CivicKeyFocusState extends State<CivicKeyFocus> {
  @override
  void initState() {
    super.initState();
    widget.node.addListener(_changed);
    FocusManager.instance.addHighlightModeListener(_mode);
  }

  @override
  void didUpdateWidget(CivicKeyFocus old) {
    super.didUpdateWidget(old);
    if (old.node != widget.node) {
      old.node.removeListener(_changed);
      widget.node.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.node.removeListener(_changed);
    FocusManager.instance.removeHighlightModeListener(_mode);
    super.dispose();
  }

  void _changed() => setState(() {});
  void _mode(FocusHighlightMode _) => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    widget.node.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional,
  );
}
