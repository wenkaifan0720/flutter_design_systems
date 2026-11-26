import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ChooseInk extends StatefulWidget {
  const ChooseInk({super.key});
  @override
  State<ChooseInk> createState() => _ChooseInkState();
}

class _ChooseInkState extends State<ChooseInk> {
  Color ink = const Color(0xff32628c);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpressiveColorPicker(
            value: ink,
            onChanged: (next) => setState(() => ink = next),
          ),
          const SizedBox(height: 12),
          Text(
            "Ink: #${(ink.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}",
          ),
        ],
      ),
    ),
  );
}
