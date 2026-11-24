/// The move the arrow keys make in a [RawSegmentedButton], a [RawTabBar] or
/// any [RawRovingFocusGroup], as an [Intent], so an app changes a key the
/// Flutter way.
library;

import 'package:flutter/widgets.dart';

import 'roving_focus.dart' show RawRovingFocusGroup;
import 'tabs.dart' show RawTabBar;
import 'toggle_group.dart' show RawSegmentedButton;

/// Where a [RawRovingFocusIntent] moves the focus in its group.
enum RawRovingFocusMove {
  /// To the next enabled item, in the group's order.
  next,

  /// To the previous enabled item.
  previous,

  /// To the first enabled item.
  first,

  /// To the last enabled item.
  last,
}

/// Moves the focus to another item of a [RawSegmentedButton] or a
/// [RawTabBar] (and, in a one-choice toggle group, chooses it).
///
/// The group binds its arrows, Home and End to it, with a [Shortcuts] inside
/// it, as Flutter's `RadioGroup` binds its arrows. To change what a move does, put an [Actions] with an action for
/// this intent round the group: the group's own action is
/// [Action.overridable], so the app's runs in its place. To add a key, bind
/// it to this intent in a [Shortcuts] round the group: the intent is
/// invoked where the focus is, inside the group.
///
/// ```dart
/// Actions(actions: {RawRovingFocusIntent: DoNothingAction(consumesKey: false)}, child: RawTabBar(controller: controller, tabs: const [RawTab(label: 'Inbox'), RawTab(label: 'Sent')], tabBuilder: (context, tab, details) => Text(tab.label)))
/// ```
class RawRovingFocusIntent extends Intent {
  /// An intent to make [move].
  const RawRovingFocusIntent(this.move);

  /// Where the focus goes.
  final RawRovingFocusMove move;
}
