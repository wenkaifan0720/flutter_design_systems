// A swipe row's actions on the row's own semantics node: the row's render
// object, and the target a row's node holds to take them.
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../semantics_proxy.dart';

/// Marks a swipe row's content, so a [RawButton]-like control in it adds a
/// [RowActionsTarget] inside its node.
class RowActionsScope extends InheritedWidget {
  /// Marks [child].
  const RowActionsScope({super.key, required super.child});

  /// Whether [context] is inside a swipe row's content.
  static bool isIn(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RowActionsScope>() != null;

  @override
  bool updateShouldNotify(RowActionsScope oldWidget) => false;
}

/// The render objects a row's single-child chain runs through from [from],
/// [from] first.
Iterable<RenderObject> _chainDown(RenderObject? from) sync* {
  var node = from;
  while (node != null) {
    yield node;
    node = node is RenderObjectWithChildMixin<RenderObject> ? node.child : null;
  }
}

/// The row a swipe row's [actions] belong to.
///
/// When the row's content holds a [RenderRowActionsTarget] in its
/// single-child chain, the target's node (the row's own) offers the actions
/// and this adds nothing. Otherwise this is the row's node: it offers the
/// actions and takes the words of the content that has no node of its own,
/// while a control in the row (a trailing button) keeps its node; a row that
/// merges its whole content into one node is merged with the actions.
class RenderRowActions extends RenderSemanticsProxy {
  /// The row round [child], offering [actions].
  RenderRowActions({required this._actions, RenderBox? child}) : super(child);

  /// The row's actions, as a screen reader offers them.
  Map<CustomSemanticsAction, VoidCallback> get actions => _actions;
  Map<CustomSemanticsAction, VoidCallback> _actions;
  set actions(Map<CustomSemanticsAction, VoidCallback> value) {
    if (mapEquals(value, _actions)) return;
    _actions = value;
    markNeedsSemanticsUpdate();
    _target?.markNeedsSemanticsUpdate();
  }

  RenderRowActionsTarget? _target;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_actions.isEmpty) return;
    final chain = _chainDown(child);
    if (chain.any((n) => n is RenderRowActionsTarget)) return;
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = chain.any(
        (n) => n is RenderMergeSemantics,
      )
      ..customSemanticsActions = _actions;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty<String>('actions', [
        for (final a in _actions.keys) a.label ?? '',
      ]),
    );
  }
}

/// Gives the node it stands in the actions of the swipe row it is the
/// content of: its own walk up to the row runs through one child at a time
/// (no row, column or stack between), with no other target nearer the row.
class RenderRowActionsTarget extends RenderSemanticsProxy {
  /// A target round [child].
  RenderRowActionsTarget([super.child]);

  RenderRowActions? _row;

  RenderRowActions? _findRow() {
    var node = parent;
    while (node != null) {
      if (node is RenderRowActions) return node;
      if (node is RenderRowActionsTarget ||
          node is! RenderObjectWithChildMixin<RenderObject>) {
        return null;
      }
      node = node.parent;
    }
    return null;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _row = _findRow();
    if (_row != null) {
      _row!._target = this;
      _row!.markNeedsSemanticsUpdate();
    }
  }

  @override
  void detach() {
    final row = _row;
    if (row != null && row._target == this) {
      row._target = null;
      row.markNeedsSemanticsUpdate();
    }
    _row = null;
    super.detach();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    final row = _findRow();
    if (row == null || row.actions.isEmpty) return;
    config.customSemanticsActions = row.actions;
  }
}

/// The widget of a [RenderRowActionsTarget].
class RowActionsTarget extends SingleChildRenderObjectWidget {
  /// A target round [child].
  const RowActionsTarget({super.key, super.child});

  @override
  RenderRowActionsTarget createRenderObject(BuildContext context) =>
      RenderRowActionsTarget();
}

/// The widget of a [RenderRowActions].
class RowActions extends SingleChildRenderObjectWidget {
  /// The row round [child], offering [actions].
  const RowActions({super.key, required this.actions, super.child});

  /// The row's actions.
  final Map<CustomSemanticsAction, VoidCallback> actions;

  @override
  RenderRowActions createRenderObject(BuildContext context) =>
      RenderRowActions(actions: actions);

  @override
  void updateRenderObject(BuildContext context, RenderRowActions renderObject) {
    renderObject.actions = actions;
  }
}
