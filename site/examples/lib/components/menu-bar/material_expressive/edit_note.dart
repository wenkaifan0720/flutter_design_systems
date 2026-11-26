import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
        ExpressiveMenuBar(
          menus: [
            ExpressiveMenuBarEntry(
              'Edit',
              children: [
                ExpressiveMenuBarEntry(
                  'Mark reviewed',
                  onPressed: () => setState(() => reviewed = true),
                ),
                ExpressiveMenuBarEntry(
                  'Clear review',
                  onPressed: () => setState(() => reviewed = false),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(reviewed ? 'Reviewed' : 'Draft'),
      ],
    ),
  );
}
