import 'package:material_ui/material_ui.dart';

class CheckSecret extends StatefulWidget {
  const CheckSecret({super.key});
  @override
  State<CheckSecret> createState() => _CheckSecretState();
}

class _CheckSecretState extends State<CheckSecret> {
  bool entered = false;
  bool hidden = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          obscureText: hidden,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Sample password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: hidden ? 'Show password' : 'Hide password',
              icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => hidden = !hidden),
            ),
          ),
          onChanged: (value) => setState(() => entered = value.isNotEmpty),
        ),
        const SizedBox(height: 12),
        Text(entered ? 'Sample entered' : 'Enter a sample word'),
      ],
    ),
  );
}
