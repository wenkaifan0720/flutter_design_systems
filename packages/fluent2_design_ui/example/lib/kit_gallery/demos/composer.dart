/// The message composer in Fluent's family: a chat's compose box (empty,
/// with a draft, growing to its lines, disabled) and an assistant's prompt box,
/// sending into a Northwind chat, live.
library;

import 'package:material_ui/material_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

Widget kitComposerDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Composer',
  sections: [
    kitSection(
      'Messages, live',
      children: [
        _Live<List<String>>(
          [kitW('Kai: the launch deck is in Files.')],
          (sent, set) => Builder(
            builder: (context) {
              final t = context.fluent2Theme;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Fluent2Spacing.s,
                children: [
                  for (final line in sent)
                    Text(line, style: t.body1.c(t.textPrimary)),
                  Fluent2Composer(
                    hintText: kitW('Message Design'),
                    onAttach: () {},
                    onEmoji: () {},
                    onSend: (text) => set([
                      ...sent,
                      kitArabic ? 'إينيس: $text' : 'Ines: $text',
                    ]),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
    kitSection('Messages', children: [kitSpecimenComposer()]),
    kitSection('Messages, a draft', children: [kitSpecimenComposerDraft()]),
    kitSection(
      'Messages, disabled',
      children: [
        Fluent2Composer(
          hintText: kitW("You can't reply in this channel"),
          onSend: null,
        ),
      ],
    ),
    kitSection('Assistant', children: [kitSpecimenComposerAssistant()]),
  ],
);

Widget kitSpecimenComposer() => Fluent2Composer(
  hintText: kitW('Message Design'),
  onAttach: () {},
  onEmoji: () {},
  onSend: (_) {},
);

Widget kitSpecimenComposerDraft() => KitOwned(
  () => TextEditingController(
    text: kitW(
      'Mara, can you check the press notes before Thursday? The launch '
      'deck is final.',
    ),
  ),
  (context, draft) => Fluent2Composer(
    controller: draft,
    hintText: kitW('Message Design'),
    onAttach: () {},
    onEmoji: () {},
    onSend: (_) {},
  ),
);

Widget kitSpecimenComposerAssistant() => Fluent2Composer(
  style: Fluent2ComposerAppearance.assistant,
  semanticLabel: kitW('Ask the assistant'),
  hintText: kitW('Ask about your files, chats and meetings'),
  onAttach: () {},
  actions: [
    Fluent2IconButton(
      Fluent2Icons.sparkle,
      semanticLabel: kitW('Prompts'),
      size: Fluent2ButtonSize.small,
      onPressed: () {},
    ),
  ],
  onSend: (_) {},
);
