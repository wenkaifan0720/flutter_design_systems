import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class ChooseLayout extends StatefulWidget {
  const ChooseLayout({super.key});

  @override
  State<ChooseLayout> createState() => _ChooseLayoutState();
}

class _ChooseLayoutState extends State<ChooseLayout> {
  Set<String> layout = {'List'};

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RetroDesktopToggleGroup<String>(
        semanticLabel: 'Layout',
        values: const ['List', 'Grid'],
        labelOf: (layout) => layout,
        selected: layout,
        onChanged: (next) => setState(() => layout = next),
      ),
      const SizedBox(height: 12),
      Text('Layout: ${layout.single}'),
    ],
  );
}
