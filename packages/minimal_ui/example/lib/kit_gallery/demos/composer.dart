/// The composer in both registers — the one-line message box and the issue
/// comment box — through every state a draft passes: empty, drafted and
/// grown, with a file, streaming, disabled, a flow-owned action, and a
/// live thread docked over its transcript.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitComposerDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Composer',
  sections: [
    kitSection('In a thread', children: const [_Thread()]),
    kitSection(
      'Messages',
      children: [
        MinimalComposer(onAttach: () {}, onSend: (_) {}),
        const _Drafted(
          text: 'Moved the reminder to 07:00 — does that still work?',
        ),
        const _Drafted(
          text:
              'Ran 5.2 km before 8. Knee felt fine on the hills, slower on '
              'the flat. Keeping the streak going tomorrow, weather '
              'permitting.',
        ),
        kitNote('Empty, drafted, and grown line by line with the draft.'),
      ],
    ),
    kitSection(
      'Voice and attachment',
      children: [
        MinimalComposer(
          hint: 'Message, or hold to talk',
          onAttach: () {},
          onVoice: () {},
          onSend: (_) {},
        ),
        MinimalComposer(
          attachment: 'run-2026-08-28.gpx',
          onAttach: () {},
          onRemoveAttachment: () {},
          onSend: (_) {},
        ),
      ],
    ),
    kitSection(
      'Busy and disabled',
      children: [
        // Attach stays while a reply streams, so the hint keeps the column
        // every composer's text stands on.
        MinimalComposer(
          busy: true,
          onAttach: () {},
          onStop: () {},
          onSend: (_) {},
        ),
        MinimalComposer(
          enabled: false,
          // Short enough for one line between the glyphs at the largest
          // text: a hint is a single line.
          hint: 'Archived: no comments',
          onAttach: () {},
          onSend: (_) {},
        ),
      ],
    ),
    kitSection(
      'Comment box',
      children: [
        MinimalComposer(
          style: MinimalComposerStyle.assistant,
          model: 'Team only',
          onAttach: () {},
          onModel: () {},
          onDictate: () {},
          onSend: (_) {},
        ),
        const _Drafted(
          style: MinimalComposerStyle.assistant,
          text:
              'Streak broke on the 19th because the reminder fired at '
              '20:15. Moved it to 07:00 so it lands before the run.',
        ),
      ],
    ),
    kitSection(
      'Flow-owned action',
      children: [
        MinimalComposer(
          hint: 'Reply to HAB-4',
          onSend: (_) {},
          action: MinimalComposerAction(
            icon: LucideIcons.cornerDownLeft,
            label: 'Reply',
            onPressed: () {},
          ),
        ),
        // One row per composer, so each row holds one size: the messages
        // box's send, then the comment box's smaller one.
        const Row(
          children: [
            MinimalComposerAction(onPressed: _noop),
            MinimalGap(MinimalSpacing.s8),
            MinimalComposerAction(),
          ],
        ),
        kitNote('The messages send on its own: ready, nothing to send yet.'),
        const Row(
          children: [
            MinimalComposerAction(
              style: MinimalComposerStyle.assistant,
              onPressed: _noop,
            ),
            MinimalGap(MinimalSpacing.s8),
            MinimalComposerAction(
              style: MinimalComposerStyle.assistant,
              icon: MinimalComposerAction.stop,
              label: 'Stop response',
              onPressed: _noop,
            ),
          ],
        ),
        kitNote(
          'The comment box\'s send, and Stop while a reply is on its way.',
        ),
      ],
    ),
  ],
);

void _noop() {}

/// A composer holding a draft, so the send square is live.
class _Drafted extends StatefulWidget {
  const _Drafted({
    required this.text,
    this.style = MinimalComposerStyle.messages,
  });

  final String text;
  final MinimalComposerStyle style;

  @override
  State<_Drafted> createState() => _DraftedState();
}

class _DraftedState extends State<_Drafted> {
  late final TextEditingController _draft = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MinimalComposer(
    controller: _draft,
    style: widget.style,
    model: 'Team only',
    onAttach: () {},
    onModel: widget.style == MinimalComposerStyle.assistant ? () {} : null,
    onSend: (_) {},
  );
}

typedef _Comment = ({String who, String at, String text});

/// A live comment thread on HAB-4: the composer docked under the
/// transcript; sending appends a comment stamped at a fixed time.
class _Thread extends StatefulWidget {
  const _Thread();

  @override
  State<_Thread> createState() => _ThreadState();
}

class _ThreadState extends State<_Thread> {
  /// The frame's height at the default text scale.
  static const double _height = 280;

  final List<_Comment> _comments = [
    (who: 'Ada', at: '27 Aug 07:40', text: 'Marked done · note added'),
    (who: 'You', at: '27 Aug 07:52', text: 'Knee held up on the hills.'),
    (who: 'Ada', at: '28 Aug 07:12', text: 'Twelve days. Best is 21.'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final mq = MediaQuery.of(context);
    // Larger text grows only the comments' lines: two of the small body in
    // each of the three. The bar and the one-line composer keep their size.
    final line = t.bodySmall.fontSize! * t.bodySmall.height!;
    final grown = mq.textScaler.scale(line) - line;
    return Container(
      // Tall enough for the bar, three comments and the docked composer:
      // the transcript fills the frame with no dead band under the bar. It
      // grows by what the text adds to those comments; a fourth comment
      // scrolls, as a chat does.
      height: _height + 3 * 2 * grown,
      clipBehavior: Clip.antiAlias,
      // The shape clips; the hairline paints over the content, so the bar's
      // square corners never cover the rim's curve.
      decoration: ShapeDecoration(shape: t.shapes.medium),
      foregroundDecoration: ShapeDecoration(
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      // The frame is a page of its own: no device insets inside it.
      child: MediaQuery(
        data: mq.copyWith(
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
        ),
        child: MinimalComposerLayout(
          topBar: const MinimalAppBar(
            title: 'Comments',
            subtitle: 'HAB-4',
            large: false,
          ),
          composer: MinimalComposer(
            hint: 'Comment on Morning run',
            onAttach: () {},
            onSend: (text) => setState(
              () => _comments.add((who: 'You', at: '28 Aug 07:20', text: text)),
            ),
          ),
          bodyBuilder: (context, bottomInset) => ListView(
            reverse: true,
            padding: EdgeInsets.only(
              top: MinimalSpacing.s8,
              bottom: bottomInset,
            ),
            children: [
              for (final comment in _comments.reversed) _CommentRow(comment),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow(this.comment);

  final _Comment comment;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MinimalChromeMetrics.gutter,
        MinimalSpacing.s8,
        MinimalChromeMetrics.gutter,
        MinimalSpacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  comment.who,
                  style: t.bodySmall.semibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const MinimalGap(MinimalSpacing.s8),
              Text(comment.at, style: t.mono.c(t.mutedForeground)),
            ],
          ),
          const MinimalGap(MinimalSpacing.s2),
          Text(comment.text, style: t.bodySmall.c(t.mutedForeground)),
        ],
      ),
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// The one-line message box at rest, attach and send inside it.
Widget kitSpecimenComposerMessages() =>
    MinimalComposer(hint: 'Message Ada', onAttach: () {}, onSend: (_) {});

/// A draft grown line by line, with a file attached; send is live.
Widget kitSpecimenComposerDrafted() => MinimalComposer(
  controller: TextEditingController(
    text:
        'Ran 5.2 km before 8. Knee felt fine on the hills, slower on the '
        'flat. Route file attached.',
  ),
  attachment: 'run-2026-08-28.gpx',
  onAttach: () {},
  onRemoveAttachment: () {},
  onSend: (_) {},
);

/// The issue-comment box: the writing area over its own toolbar.
Widget kitSpecimenComposerAssistant() => MinimalComposer(
  style: MinimalComposerStyle.assistant,
  hint: 'Leave a comment',
  model: 'Team only',
  onAttach: () {},
  onModel: () {},
  onDictate: () {},
  onSend: (_) {},
);

/// A comment thread: the transcript over the composer docked on the
/// bottom edge.
Widget kitSpecimenComposerLayoutThread() => MinimalComposerLayout(
  topBar: const MinimalAppBar(title: 'Comments', subtitle: 'HAB-4'),
  composer: MinimalComposer(
    hint: 'Comment on Morning run',
    onAttach: () {},
    onSend: (_) {},
  ),
  bodyBuilder: (context, bottomInset) => ListView(
    reverse: true,
    padding: EdgeInsets.only(top: MinimalSpacing.s8, bottom: bottomInset),
    children: const [
      _CommentRow((
        who: 'Ada',
        at: '28 Aug 07:12',
        text: 'Twelve days. Best is 21.',
      )),
      _CommentRow((
        who: 'You',
        at: '27 Aug 07:52',
        text: 'Knee held up on the hills. Slower on the flat.',
      )),
      _CommentRow((
        who: 'Ada',
        at: '27 Aug 07:40',
        text: 'Marked done · note added',
      )),
      _CommentRow((
        who: 'Ines',
        at: '26 Aug 21:04',
        text: 'Moved the reminder to 07:00 so it lands before the run.',
      )),
    ],
  ),
);
