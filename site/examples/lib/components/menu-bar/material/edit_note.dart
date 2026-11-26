import 'package:material_ui/material_ui.dart';

class EditNote extends StatefulWidget {
  const EditNote({super.key});
  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  bool reviewed = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 460),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MenuBar(
          children: [
            SubmenuButton(
              menuChildren: [
                MenuItemButton(
                  onPressed: () => setState(() => reviewed = true),
                  child: const Text('Mark reviewed'),
                ),
                MenuItemButton(
                  onPressed: () => setState(() => reviewed = false),
                  child: const Text('Clear review'),
                ),
              ],
              child: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(reviewed ? 'Reviewed' : 'Draft'),
      ],
    ),
  );
}
