import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class AddADay extends StatefulWidget {
  const AddADay({super.key});

  @override
  State<AddADay> createState() => _AddADayState();
}

class _AddADayState extends State<AddADay> {
  int days = 7;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RetroDesktopIconButton(
        RetroDesktopGlyphs.plus,
        label: 'Add a day',
        onPressed: () => setState(() => days++),
      ),
      const SizedBox(height: 12),
      Text('Loan period: $days days'),
    ],
  );
}
