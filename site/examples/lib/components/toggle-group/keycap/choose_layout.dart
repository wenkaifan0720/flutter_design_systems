import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
      KeycapToggleGroup<String>(
        semanticLabel: 'Layout',
        options: const [
          KeycapToggleOption(value: 'List', label: 'List'),
          KeycapToggleOption(value: 'Grid', label: 'Grid'),
        ],
        selected: layout,
        onSelectionChanged: (next) => setState(() => layout = next),
      ),
      const SizedBox(height: 12),
      Text('Layout: ${layout.single}'),
    ],
  );
}
