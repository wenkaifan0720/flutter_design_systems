import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class ChooseInk extends StatefulWidget {
  const ChooseInk({super.key});
  @override
  State<ChooseInk> createState() => _ChooseInkState();
}

class _ChooseInkState extends State<ChooseInk> {
  final ink = RawColorController(const Color(0xff32628c));
  @override
  void dispose() {
    ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TermColorPicker(controller: ink),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: ink,
            builder: (context, _) => Text(
              "Ink: #${(ink.color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}",
            ),
          ),
        ],
      ),
    ),
  );
}
