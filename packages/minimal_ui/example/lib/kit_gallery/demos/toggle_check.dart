/// Minimal's two-state controls: the compact switch in a settings list
/// and on its own in every state, and the 16 px checkbox as a live
/// checklist, in its states and sizes, as a read-only mark, and as the
/// required agreement that shows its error.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../kit.dart';

Widget kitToggleCheckDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Toggle & check',
  sections: [
    kitSection('Toggle · in rows', children: const [_Settings()]),
    kitSection(
      'Toggle · states',
      children: [
        _Strip([
          _Labeled(
            'On',
            MinimalSwitch(value: true, label: 'On', onChanged: (_) {}),
          ),
          _Labeled(
            'Off',
            MinimalSwitch(value: false, label: 'Off', onChanged: (_) {}),
          ),
          const _Labeled(
            'Disabled on',
            MinimalSwitch(value: true, label: 'Disabled on'),
          ),
          const _Labeled(
            'Disabled off',
            MinimalSwitch(value: false, label: 'Disabled off'),
          ),
        ]),
        kitNote('Tap, drag the thumb, or focus it and press Space.'),
      ],
    ),
    kitSection('Toggle · labelled', children: const [_Another()]),
    kitSection('Check · checklist', children: const [_Checklist()]),
    kitSection(
      'Check · states',
      children: [
        _Strip([
          _Labeled(
            'Off',
            MinimalCheckbox(value: false, label: 'Off', onChanged: (_) {}),
          ),
          _Labeled(
            'On',
            MinimalCheckbox(value: true, label: 'On', onChanged: (_) {}),
          ),
          const _Labeled(
            'Disabled',
            MinimalCheckbox(value: false, label: 'Disabled', onChanged: null),
          ),
          const _Labeled(
            'Disabled on',
            MinimalCheckbox(value: true, label: 'Disabled on', onChanged: null),
          ),
          const _Labeled(
            'Read-only',
            MinimalCheckMark(value: true, label: 'Kept'),
          ),
          _Labeled(
            'Large',
            MinimalCheckbox(
              value: true,
              label: 'Large',
              size: 20,
              onChanged: (_) {},
            ),
          ),
        ]),
        kitNote(
          'A read-only check marks a fact: it stays at full strength and '
          'cannot be changed here.',
        ),
      ],
    ),
    kitSection('Check · required', children: const [_Agreement()]),
  ],
);

/// A states strip: its columns align at the top, so every control stands
/// on one line however many lines a caption wraps to.
class _Strip extends StatelessWidget {
  const _Strip(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: MinimalSpacing.s8,
    runSpacing: MinimalSpacing.s8,
    children: children,
  );
}

/// A control over its caption, both on the column's start, so the first
/// stands on the page's keyline. The control stands as near its section's
/// label as any other specimen does (it pads its own hit area to 44 px).
class _Labeled extends StatelessWidget {
  const _Labeled(this.caption, this.control);

  final String caption;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // One slot as tall as the tallest control (a 20 px switch or a
          // large check), so every caption in the strip shares a line.
          SizedBox(
            height: MinimalSpacing.s24,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: control,
            ),
          ),
          const MinimalGap(MinimalSpacing.s8),
          Text(
            caption,
            style: t.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A full-bleed list: rows between hairlines, no card around them; edge to
/// edge on a phone, on the column's keylines in a wider window.
Widget _list(BuildContext context, List<Widget> rows) {
  final t = context.minimalTheme;
  return KitBleed(
    child: DecoratedBox(
      decoration: BoxDecoration(border: Border(top: t.rule)),
      child: Column(children: rows),
    ),
  );
}

/// A 44 px list row on the column's keyline: a title, a quiet caption, a
/// control.
class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    this.caption,
    required this.trailing,
    this.leading,
  });

  final String title;
  final String? caption;
  final Widget trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final caption = this.caption;
    final leading = this.leading;
    return Container(
      constraints: BoxConstraints(minHeight: t.rowHeight),
      padding: KitBleed.inset(context),
      decoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const MinimalGap(MinimalSpacing.s12),
          ],
          Expanded(
            child: Text(
              title,
              style: t.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (caption != null) ...[
            const MinimalGap(MinimalSpacing.s8),
            Text(
              caption,
              // A time is a figure: mono. A word is not.
              style: RegExp(r'\d').hasMatch(caption)
                  ? t.mono.c(t.mutedForeground)
                  : t.caption,
              maxLines: 1,
            ),
          ],
          const MinimalGap(MinimalSpacing.s12),
          trailing,
        ],
      ),
    );
  }
}

/// Ritual's notification settings: live switches, one a policy has locked.
class _Settings extends StatefulWidget {
  const _Settings();

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  bool _reminders = true;
  bool _digest = false;
  bool _another = false;

  @override
  Widget build(BuildContext context) => _list(context, [
    _Row(
      title: 'Reminders',
      caption: _reminders ? '21:30' : null,
      trailing: MinimalSwitch(
        value: _reminders,
        label: 'Reminders',
        onChanged: (v) => setState(() => _reminders = v),
      ),
    ),
    _Row(
      title: 'Weekly digest',
      trailing: MinimalSwitch(
        value: _digest,
        label: 'Weekly digest',
        onChanged: (v) => setState(() => _digest = v),
      ),
    ),
    _Row(
      title: 'Create another',
      trailing: MinimalSwitch(
        value: _another,
        label: 'Create another',
        onChanged: (v) => setState(() => _another = v),
      ),
    ),
    const _Row(
      title: 'Sync over cellular',
      caption: 'managed',
      trailing: MinimalSwitch(value: true, label: 'Sync over cellular'),
    ),
  ]);
}

/// Today's habits as a checklist whose tally follows the ticks.
class _Checklist extends StatefulWidget {
  const _Checklist();

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  final Map<String, bool> _done = {
    'Meditate': true,
    'Morning run': true,
    'Drink water': false,
    'Journal': false,
    'Read 20 pages': true,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final kept = _done.values.where((v) => v).length;
    final names = _done.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _list(context, [
          for (final name in names)
            _Row(
              title: name,
              leading: MinimalCheckbox(
                value: _done[name]!,
                label: name,
                onChanged: (v) => setState(() => _done[name] = v),
              ),
              trailing: Text(
                _done[name]! ? 'Kept' : 'Open',
                style: t.caption.c(
                  _done[name]! ? t.successInk : t.mutedForeground,
                ),
              ),
            ),
        ]),
        const MinimalGap(MinimalSpacing.s12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$kept/${names.length}', style: t.mono),
              TextSpan(text: ' kept', style: t.bodySmall.c(t.mutedForeground)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The one check a form will not go on without, with its error until it is
/// ticked.
class _Agreement extends StatefulWidget {
  const _Agreement();

  @override
  State<_Agreement> createState() => _AgreementState();
}

class _AgreementState extends State<_Agreement> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MinimalCheckbox(
              value: _agreed,
              label: 'Agree to the guidelines',
              onChanged: (v) => setState(() => _agreed = v),
            ),
            const MinimalGap(MinimalSpacing.s12),
            Expanded(
              child: Text(
                'I agree to the shared-habit guidelines',
                style: t.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s4),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 28),
          child: Text(
            _agreed ? 'Agreed · 28 Aug' : 'Required to join a shared habit.',
            style: t.caption.c(_agreed ? t.mutedForeground : t.destructiveInk),
          ),
        ),
      ],
    );
  }
}

/// The labelled register: the words print before the track, and a tap on
/// either flips it.
class _Another extends StatefulWidget {
  const _Another();

  @override
  State<_Another> createState() => _AnotherState();
}

class _AnotherState extends State<_Another> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: MinimalSwitch(
      value: _on,
      label: 'Create another',
      showLabel: true,
      onChanged: (on) => setState(() => _on = on),
    ),
  );
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// A switch that is on, its label printed beside it.
Widget kitSpecimenToggleOn() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalSwitch(
      value: true,
      label: 'Reminders',
      showLabel: true,
      onChanged: (_) {},
    ),
  ],
);

/// A switch that is off, its label printed beside it.
Widget kitSpecimenToggleOff() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalSwitch(
      value: false,
      label: 'Create another',
      showLabel: true,
      onChanged: (_) {},
    ),
  ],
);

/// Checked items leading a checklist's rows.
Widget kitSpecimenCheckChecklist() => _Body(
  bleed: true,
  child: MinimalListSection(
    children: [
      MinimalListTile(
        leading: MinimalCheckbox(
          value: true,
          label: 'Meditate',
          onChanged: (_) {},
        ),
        title: 'Meditate',
        muted: true,
        meta: 'Kept',
      ),
      MinimalListTile(
        leading: MinimalCheckbox(
          value: true,
          label: 'Morning run',
          onChanged: (_) {},
        ),
        title: 'Morning run',
        muted: true,
        meta: 'Kept',
      ),
    ],
  ),
);

/// A lone agreement, not yet given: the large square beside its words.
Widget kitSpecimenCheckConsent() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Row(
      children: [
        MinimalCheckbox(
          value: false,
          size: 20,
          label: 'Agree to the guidelines',
          onChanged: (_) {},
        ),
        const MinimalGap(MinimalSpacing.s12),
        Expanded(
          child: Text(
            'I agree to the community guidelines and the privacy terms.',
            style: t.bodySmall,
          ),
        ),
      ],
    );
  },
);

/// Lays a specimen out as a scrolling page body does: its own height,
/// however tall the stage — and with [bleed] edge to edge past the stage's
/// gutter, as on a `MinimalScaffold(padding: EdgeInsets.zero)` page.
class _Body extends StatelessWidget {
  const _Body({required this.child, this.bleed = false});

  final Widget child;
  final bool bleed;

  @override
  Widget build(BuildContext context) => UnconstrainedBox(
    constrainedAxis: Axis.horizontal,
    child: !bleed
        ? child
        : LayoutBuilder(
            builder: (context, c) => FractionallySizedBox(
              widthFactor:
                  (c.maxWidth + 2 * MinimalChromeMetrics.gutter) / c.maxWidth,
              child: child,
            ),
          ),
  );
}
