import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

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
      // The picker prints the chosen colour's hex under its plane.
      child: ClayColorPicker(
        value: ink,
        onChanged: (next) => setState(() => ink = next),
      ),
    ),
  );
}
