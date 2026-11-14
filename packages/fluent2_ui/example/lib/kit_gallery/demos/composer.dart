/// The message composer in Fluent's family: a chat's compose box (empty,
/// with a draft, growing to its lines, disabled) and an assistant's prompt box,
/// sending into a Northwind chat, live.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

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
          const ['Kai: the launch deck is in Files.'],
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
                    hint: 'Message Design',
                    onAttach: () {},
                    onEmoji: () {},
                    onSend: (text) => set([...sent, 'Ines: $text']),
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
        const Fluent2Composer(
          hint: 'You can\'t reply in this channel',
          onSend: null,
        ),
      ],
    ),
    kitSection('Assistant', children: [kitSpecimenComposerAssistant()]),
  ],
);

Widget kitSpecimenComposer() => Fluent2Composer(
  hint: 'Message Design',
  onAttach: () {},
  onEmoji: () {},
  onSend: (_) {},
);

Widget kitSpecimenComposerDraft() => Fluent2Composer(
  controller: TextEditingController(
    text:
        'Mara, can you check the press notes before Thursday? The launch '
        'deck is final.',
  ),
  hint: 'Message Design',
  onAttach: () {},
  onEmoji: () {},
  onSend: (_) {},
);

Widget kitSpecimenComposerAssistant() => Fluent2Composer(
  style: Fluent2ComposerAppearance.assistant,
  label: 'Ask the assistant',
  hint: 'Ask about your files, chats and meetings',
  onAttach: () {},
  actions: [
    Fluent2IconButton(
      Fluent2Icons.sparkle,
      label: 'Prompts',
      size: Fluent2ButtonSize.small,
      onPressed: () {},
    ),
  ],
  onSend: (_) {},
);
