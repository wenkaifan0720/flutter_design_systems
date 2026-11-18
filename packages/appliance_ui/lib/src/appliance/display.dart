/// Appliance's display parts: [ApplianceAvatar] and [ApplianceAvatarGroup]
/// (round portholes), [ApplianceTag] (a printed rating-plate label),
/// [ApplianceMedia] (a picture behind a window), [ApplianceEmptyState] (a
/// dark display with nothing on it yet) and [ApplianceDescriptionList]
/// (terms and their values, as a rating plate reads).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'lists.dart';
import 'material.dart';
import 'theme.dart';

/// A name's initials, at most two.
String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = [for (final w in words) w.characters.first.toUpperCase()];
  if (letters.isEmpty) return '';
  if (letters.length == 1) return letters.first;
  return '${letters.first}${letters.last}';
}

/// An avatar: a round porthole sunk in the panel, the person's picture
/// behind it or, until it comes (or when there is none), their initials
/// printed on the porthole's floor.
///
/// ```dart
/// const ApplianceAvatar(name: 'Ada Brook')
/// ```
class ApplianceAvatar extends StatelessWidget {
  /// [name]'s avatar.
  const ApplianceAvatar({
    super.key,
    required this.name,
    this.slotId,
    this.size = 40,
    this.style,
  });

  /// Whose: their initials, and their name for a screen reader.
  final String name;

  /// Their picture's media slot; null shows the initials.
  final String? slotId;

  /// Its diameter.
  final double size;

  /// Its style, over [ApplianceThemeData.avatarStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.avatarStyle], const {});
    final initials = Center(
      child: Text(
        _initials(name),
        style: layered.text(
          theme.textTheme.label.copyWith(
            color: c.printMuted,
            fontSize: size * 0.36,
            height: 1,
          ),
        ),
      ),
    );
    final slot = slotId;
    // The ring round the picture: two hairlines on a large one, one on a
    // small one.
    final ring = size >= 40 ? ApplianceSpacing.nudge : ApplianceSpacing.hair;
    return Semantics(
      label: name,
      image: slot != null,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: ApplianceSurface(
            face: layered.on(
              ApplianceFace.well(
                c,
                fill: c.trough,
              ).copyWith(radius: BorderRadius.circular(size / 2)),
            ),
            child: Padding(
              padding: EdgeInsets.all(ring),
              child: ClipOval(
                child: slot == null
                    ? initials
                    : MediaSlotImage(slotId: slot, fallback: initials),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(DoubleProperty('size', size, defaultValue: 40));
  }
}

/// An avatar group: portholes overlapping in a row, each ringed in the
/// panel's face; past [max], a last one counts the rest.
///
/// ```dart
/// const ApplianceAvatarGroup(names: ['Ada Brook', 'Sam Lee', 'Kit Ward'])
/// ```
class ApplianceAvatarGroup extends StatelessWidget {
  /// Avatars for [names].
  const ApplianceAvatarGroup({
    super.key,
    required this.names,
    this.slotIds = const {},
    this.max = 4,
    this.size = 32,
    this.style,
  }) : assert(max > 1);

  /// Whose, in order.
  final List<String> names;

  /// Their pictures' media slots, by name.
  final Map<String, String> slotIds;

  /// The most portholes, the last counting the rest.
  final int max;

  /// Each one's diameter.
  final double size;

  /// Its style, over [ApplianceThemeData.avatarStyle]: fill (the overflow badge).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).avatarStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final over = names.length > max;
    final shown = over ? names.take(max - 1).toList() : names;
    final rest = names.length - shown.length;
    final step = size * 0.7;
    final count = shown.length + (over ? 1 : 0);
    Widget ringed(Widget child) => Container(
      padding: const EdgeInsets.all(ApplianceSpacing.nudge),
      decoration: BoxDecoration(
        color: look.fill ?? c.face,
        shape: BoxShape.circle,
      ),
      child: child,
    );
    return Semantics(
      label: names.join(', '),
      child: ExcludeSemantics(
        child: SizedBox(
          height: size + 4,
          width: count == 0 ? 0 : step * (count - 1) + size + 4,
          child: Stack(
            children: [
              for (final (i, name) in shown.indexed)
                PositionedDirectional(
                  start: step * i,
                  child: ringed(
                    ApplianceAvatar(
                      name: name,
                      slotId: slotIds[name],
                      size: size,
                    ),
                  ),
                ),
              if (over)
                PositionedDirectional(
                  start: step * shown.length,
                  child: ringed(
                    SizedBox.square(
                      dimension: size,
                      child: ApplianceSurface(
                        face: ApplianceFace.key(c, circle: true),
                        child: Center(
                          child: Text(
                            '+$rest',
                            style: theme.textTheme.legend.copyWith(
                              color: c.print,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('names', names))
      ..add(IntProperty('max', max, defaultValue: 4));
  }
}

/// What an [ApplianceTag] says about its subject.
enum ApplianceTagTone {
  /// Plain: printed on the plate.
  neutral,

  /// Worth noticing: the signal's ink, its lamp lit.
  signal,

  /// All well: the ready lamp lit.
  ready,

  /// Wrong or gone: the danger colour, its lamp lit red.
  danger,
}

/// A tag: a small label plate stuck to the panel, its words in small
/// capitals; a tone other than [ApplianceTagTone.neutral] lights a lamp
/// on it. It only shows (a chip is the one you press).
///
/// ```dart
/// const ApplianceTag('In stock', tone: ApplianceTagTone.ready)
/// ```
class ApplianceTag extends StatelessWidget {
  /// A tag reading [label].
  const ApplianceTag(
    this.label, {
    super.key,
    this.tone = ApplianceTagTone.neutral,
    this.style,
  });

  /// Its words.
  final String label;

  /// What it says about its subject.
  final ApplianceTagTone tone;

  /// Its style, over [ApplianceThemeData.tagStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tagStyle], const {});
    final (ink, lamp) = switch (tone) {
      ApplianceTagTone.neutral => (c.printMuted, null),
      ApplianceTagTone.signal => (c.signalInk, c.signal),
      ApplianceTagTone.ready => (c.print, c.ready),
      ApplianceTagTone.danger => (c.danger, c.danger),
    };
    return Container(
      padding:
          layered.padding(Directionality.of(context)) ??
          const EdgeInsets.symmetric(
            horizontal: ApplianceSpacing.small,
            vertical: ApplianceSpacing.nudge,
          ),
      decoration: BoxDecoration(
        color: layered.fill ?? c.well,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lamp != null) ...[
            ApplianceLamp(lit: true, size: 6, color: lamp),
            const SizedBox(width: ApplianceSpacing.tight),
          ],
          Text(
            label.toUpperCase(),
            maxLines: 1,
            style: layered.text(theme.textTheme.legend.copyWith(color: ink)),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<ApplianceTagTone>('tone', tone));
  }
}

/// A picture behind a window: sunk in the panel with a thin frame, the
/// picture from its media slot filling it; until it comes, the window's
/// floor and [placeholder] (a glyph) stand in.
///
/// ```dart
/// const ApplianceMedia(slotId: 'kettle', semanticLabel: 'A cream kettle', aspectRatio: 4 / 3)
/// ```
class ApplianceMedia extends StatelessWidget {
  /// A window on [slotId]'s picture.
  const ApplianceMedia({
    super.key,
    required this.slotId,
    required this.semanticLabel,
    this.aspectRatio = 16 / 9,
    this.placeholder,
    this.style,
  });

  /// The picture's media slot.
  final String slotId;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// Its width over its height.
  final double aspectRatio;

  /// What stands in until it comes.
  final Widget? placeholder;

  /// Its style, over [ApplianceThemeData.panelStyle]: fill (the well).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).panelStyle,
    ], const {});
    final c = ApplianceTheme.of(context).colors;
    final floor = ColoredBox(
      color: c.trough,
      child: Center(
        child: IconTheme.merge(
          data: IconThemeData(size: 32, color: c.printDisabled),
          child: placeholder ?? const SizedBox.shrink(),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ApplianceSurface(
            face: ApplianceFace.well(c, fill: look.fill ?? c.trough),
            child: Padding(
              padding: const EdgeInsets.all(ApplianceMetrics.windowInset),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  ApplianceMetrics.wellRadius - ApplianceMetrics.windowInset,
                ),
                child: MediaSlotImage(slotId: slotId, fallback: floor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('slotId', slotId))
      ..add(DoubleProperty('aspectRatio', aspectRatio));
  }
}

/// An empty state: a dark display window with only dashes lit in it, a
/// heading, a line on what goes here, and the key that puts something
/// there.
///
/// ```dart
/// ApplianceEmptyState(title: 'Your basket is empty', message: 'Things you add stand here until you check out.')
/// ```
class ApplianceEmptyState extends StatelessWidget {
  /// An empty state headed [title].
  const ApplianceEmptyState({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.reading = '- - -',
    this.style,
  });

  /// The heading.
  final String title;

  /// What goes here.
  final String? message;

  /// The key that puts something here.
  final Widget? action;

  /// What the window reads.
  final String reading;

  /// Its style, over [ApplianceThemeData.displayStyle]: fill (the window), foreground and textStyle (the title).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).displayStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    return Semantics(
      container: true,
      child: AppliancePanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, minHeight: 56),
                child: ApplianceSurface(
                  face: ApplianceFace.well(c, fill: look.fill ?? c.display),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(
                        reading,
                        style: t.display.copyWith(
                          color: c.onDisplay.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ApplianceSpacing.regular),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: look
                    .text(t.heading)
                    .copyWith(color: look.foreground ?? c.print),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: ApplianceSpacing.small),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ApplianceMetrics.readingWidth,
                ),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: t.body.copyWith(color: c.printMuted),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: ApplianceSpacing.large),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

/// A description list: each term in small capitals over its value, ruled
/// apart, as a rating plate reads; side by side where there is room.
///
/// ```dart
/// const ApplianceDescriptionList(items: [('Capacity', '1.7 litres'), ('Power', '3 kW')])
/// ```
class ApplianceDescriptionList extends StatelessWidget {
  /// Terms and their values.
  const ApplianceDescriptionList({super.key, required this.items, this.style});

  /// The terms and their values, in order.
  final List<(String term, String value)> items;

  /// Its style, over [ApplianceThemeData.listTileStyle]: foreground, textStyle (values).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).listTileStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 480;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (term, value)) in items.indexed)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: ApplianceSpacing.medium,
                ),
                decoration: BoxDecoration(
                  border: i == items.length - 1
                      ? null
                      : Border(bottom: BorderSide(color: c.hairline)),
                ),
                child: MergeSemantics(
                  child: Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: wide
                        ? CrossAxisAlignment.baseline
                        : CrossAxisAlignment.start,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      SizedBox(
                        width: wide ? 180 : null,
                        child: Text(
                          term.toUpperCase(),
                          style: t.legend.copyWith(color: c.printMuted),
                        ),
                      ),
                      if (!wide) const SizedBox(height: ApplianceSpacing.nudge),
                      if (wide)
                        Expanded(
                          child: Text(
                            value,
                            style: t.body.copyWith(color: c.print),
                          ),
                        )
                      else
                        Text(
                          value,
                          style: look
                              .text(t.body)
                              .copyWith(color: look.foreground ?? c.print),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}
