import 'package:material_ui/material_ui.dart';

class SortFiles extends StatefulWidget {
  const SortFiles({super.key});
  @override
  State<SortFiles> createState() => _SortFilesState();
}

class _SortFilesState extends State<SortFiles> {
  String order = 'Name';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MenuAnchor(
        builder: (context, controller, child) => OutlinedButton.icon(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.sort),
          label: const Text('Sort files'),
        ),
        menuChildren: [
          for (final sort in ['Name', 'Date'])
            MenuItemButton(
              leadingIcon: Icon(
                Icons.check,
                color: order == sort ? null : Colors.transparent,
              ),
              onPressed: () => setState(() => order = sort),
              child: Text(sort),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}
