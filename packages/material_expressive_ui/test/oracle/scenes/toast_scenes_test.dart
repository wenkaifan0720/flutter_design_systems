/// The `toast` oracle group (Compose twin: `ToastScenes.kt`): the snackbar
/// 344dp wide in its layouts — one line, with an action, with the action
/// and the close button, two lines, the action on its own line — and the
/// host's enter motion (fade and scale from 0.8) as per-frame geometry.
///
/// The oracle app bundles no symbol font: its close button holds an empty
/// 24dp slot where Expressive draws the close glyph, the one expected pixel
/// difference.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/snackbar_tokens.g.dart';

import '../harness/oracle.dart';

void _none() {}

/// The width every snackbar scene gives its snackbar.
const double _width = 344;

/// The enter scene's snackbar: narrow enough that its unscaled box at 0.8
/// stays inside the 400dp crop, which fits the capture device (411dp).
const double _enterWidth = 320;

Widget _snackbar(
  BuildContext context,
  String message, {
  String? actionLabel,
  bool withDismissAction = false,
  bool actionOnNewLine = false,
  double width = _width,
}) => SizedBox(
  width: width,
  child: OracleTag(
    'container',
    shape: context.expressiveTheme.shapes.of(SnackbarTokens.containerShape),
    child: ExpressiveSnackBar(
      message,
      content: OracleTag('message', child: Text(message)),
      actionLabel: actionLabel,
      onAction: actionLabel == null ? null : _none,
      withDismissAction: withDismissAction,
      onDismiss: _none,
      actionOnNewLine: actionOnNewLine,
    ),
  ),
);

/// The host's item entering (`FadeInFadeOutWithScale`): the transition
/// starts its springs after the first frame, as the twin's
/// `LaunchedEffect`, around `Snackbar(snackbarData)`'s margin.
Widget _enter(BuildContext context) => ExpressiveSnackBarTransition(
  child: Padding(
    padding: const EdgeInsets.all(SnackbarBehavior.margin),
    child: _snackbar(
      context,
      'Draft saved',
      actionLabel: 'Undo',
      width: _enterWidth,
    ),
  ),
);

final OracleGroup toastScenes = OracleGroup(
  id: 'toast',
  // The host gives the buttons the platform ripple.
  frame: (context, scene) => ExpressiveHost(
    light: context.expressiveTheme,
    dark: context.expressiveTheme,
    brightness: context.expressiveTheme.brightness,
    child: scene,
  ),
  scenes: [
    OracleScene(
      key: 'toast/snackbar/one-line',
      size: const Size(360, 64),
      build: (context) => _snackbar(context, 'Draft saved'),
    ),
    OracleScene(
      key: 'toast/snackbar/action',
      size: const Size(360, 64),
      build: (context) =>
          _snackbar(context, 'Photo moved to the archive', actionLabel: 'Undo'),
    ),
    OracleScene(
      key: 'toast/snackbar/dismiss',
      size: const Size(360, 64),
      build: (context) => _snackbar(
        context,
        'Back online',
        actionLabel: 'Refresh',
        withDismissAction: true,
      ),
    ),
    OracleScene(
      key: 'toast/snackbar/two-line',
      size: const Size(360, 88),
      build: (context) => _snackbar(
        context,
        'Evening Run was shared with Priya, Tomás and two others',
        actionLabel: 'View',
      ),
    ),
    OracleScene(
      key: 'toast/snackbar/new-line',
      size: const Size(360, 128),
      build: (context) => _snackbar(
        context,
        'Two of your notes changed on another device',
        actionLabel: 'Review changes',
        withDismissAction: true,
        actionOnNewLine: true,
      ),
    ),
    OracleScene(
      key: 'toast/motion/enter',
      size: const Size(400, 96),
      motion: const OracleMotion(tags: ['container'], frames: 40),
      build: _enter,
    ),
  ],
);

void main() => runOracleGroup(toastScenes);
