import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
        KeycapMenuBar(
          menus: [
            RawMenuEntry(
              label: 'Edit',
              children: [
                RawMenuEntry(
                  label: 'Mark reviewed',
                  onPressed: () => setState(() => reviewed = true),
                ),
                RawMenuEntry(
                  label: 'Clear review',
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
