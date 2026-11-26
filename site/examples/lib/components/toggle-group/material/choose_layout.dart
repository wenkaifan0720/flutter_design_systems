import 'package:material_ui/material_ui.dart';

class ChooseLayout extends StatefulWidget {
  const ChooseLayout({super.key});
  @override
  State<ChooseLayout> createState() => _ChooseLayoutState();
}

class _ChooseLayoutState extends State<ChooseLayout> {
  String layout = 'List';
  static const layouts = ['List', 'Grid'];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ToggleButtons(
        isSelected: [for (final choice in layouts) choice == layout],
        onPressed: (index) => setState(() => layout = layouts[index]),
        children: [
          for (final choice in layouts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(choice),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Layout: $layout'),
    ],
  );
}
