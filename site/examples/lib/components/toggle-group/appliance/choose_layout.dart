import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
      ApplianceToggleGroup<String>(
        semanticLabel: 'Layout',
        options: const [
          ApplianceToggleOption(value: 'List', label: 'List'),
          ApplianceToggleOption(value: 'Grid', label: 'Grid'),
        ],
        selected: layout,
        onSelectionChanged: (next) => setState(() => layout = next),
      ),
      const SizedBox(height: 12),
      Text('Layout: ${layout.single}'),
    ],
  );
}
