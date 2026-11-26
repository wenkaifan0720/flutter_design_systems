import 'package:cupertino_ui/cupertino_ui.dart';

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
        CupertinoTextField(
          placeholder: 'Sample password',
          obscureText: hidden,
          enableSuggestions: false,
          autocorrect: false,
          suffix: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => setState(() => hidden = !hidden),
            child: Icon(
              hidden ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
              semanticLabel: hidden ? 'Show password' : 'Hide password',
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
