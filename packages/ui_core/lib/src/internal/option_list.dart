/// The options list a combobox and a tag input show under their field, and
/// the highlight that keeps a list item in view. Inside ui_core; not
/// exported.
library;

import 'package:flutter/widgets.dart';

import '../combobox.dart';
import '../pressable.dart';
import 'announce.dart';

/// A scrolling list of options with a keyboard highlight: what a combobox
/// and a tag input show under their field, as a [RawAutocomplete]'s options
/// view. The highlight is [AutocompleteHighlightedOption]'s; the item under
/// it scrolls into view and is announced.
class DesignOptionList<T extends Object> extends StatefulWidget {
  /// A list of [options]; a tap or Enter on one calls [onSelected].
  const DesignOptionList({
    super.key,
    required this.options,
    required this.onSelected,
    required this.value,
    required this.displayStringForOption,
    required this.optionBuilder,
    required this.surfaceBuilder,
    required this.maxHeight,
    required this.semanticLabel,
  });

  /// The options shown.
  final List<T> options;

  /// Takes an option.
  final ValueChanged<T> onSelected;

  /// The option already taken, shown as [WidgetState.selected].
  final T? value;

  /// An option's text, for the announcement.
  final String Function(T option) displayStringForOption;

  /// Paints one option.
  final DesignOptionBuilder<T> optionBuilder;

  /// Paints the surface around the list.
  final DesignListSurfaceBuilder? surfaceBuilder;

  /// The list's greatest height.
  final double maxHeight;

  /// What a screen reader calls the list.
  final String? semanticLabel;

  @override
  State<DesignOptionList<T>> createState() => _OptionListState<T>();
}

class _OptionListState<T extends Object> extends State<DesignOptionList<T>> {
  int? _announced;

  @override
  Widget build(BuildContext context) {
    final highlighted = AutocompleteHighlightedOption.of(context);
    if (_announced != highlighted &&
        highlighted < widget.options.length &&
        _announced != null) {
      final message = widget.displayStringForOption(
        widget.options[highlighted],
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) designAnnounce(context, message);
      });
    }
    _announced = highlighted;
    final list = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final lit = index == highlighted;
          return DesignHighlightVisible(
            highlighted: lit,
            child: DesignPressable(
              onPressed: () => widget.onSelected(option),
              selected: option == widget.value,
              semanticSelected: option == widget.value,
              builder: (context, states, _) => widget.optionBuilder(
                context,
                option,
                {...states, if (lit) WidgetState.focused},
              ),
            ),
          );
        },
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: widget.surfaceBuilder?.call(context, list) ?? list,
    );
  }
}

/// Scrolls [child] into view in its scrollable when [highlighted] turns
/// true: a list item the keyboard's highlight moved to.
class DesignHighlightVisible extends StatefulWidget {
  /// Keeps [child] in view while [highlighted].
  const DesignHighlightVisible({
    super.key,
    required this.highlighted,
    required this.child,
  });

  /// Whether the keyboard's highlight is on [child].
  final bool highlighted;

  /// The item.
  final Widget child;

  @override
  State<DesignHighlightVisible> createState() => _DesignHighlightVisibleState();
}

class _DesignHighlightVisibleState extends State<DesignHighlightVisible> {
  @override
  void initState() {
    super.initState();
    if (widget.highlighted) _reveal();
  }

  @override
  void didUpdateWidget(DesignHighlightVisible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlighted && !oldWidget.highlighted) _reveal();
  }

  // Only the list the item sits in moves. Scrollable.ensureVisible would move every scrollable around it too, so an
  // inline list below the fold (a command palette on a page) pulled its page down to it when first built.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final list = Scrollable.maybeOf(context);
      final item = context.findRenderObject();
      if (list == null || item == null || !item.attached) return;
      list.position
          .ensureVisible(
            item,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          )
          .ignore();
      list.position
          .ensureVisible(
            item,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          )
          .ignore();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
