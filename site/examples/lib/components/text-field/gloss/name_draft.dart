import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

class NameDraft extends StatefulWidget {
  const NameDraft({super.key});

  @override
  State<NameDraft> createState() => _NameDraftState();
}

class _NameDraftState extends State<NameDraft> {
  String title = '';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlossTextField(
          labelText: 'Draft title',
          onChanged: (value) => setState(() => title = value.trim()),
        ),
        const SizedBox(height: 12),
        Text(
          title.isEmpty ? 'Untitled' : title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
