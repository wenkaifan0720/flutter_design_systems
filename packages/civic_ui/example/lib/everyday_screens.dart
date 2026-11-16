// Brindlemere parking permits' everyday screens, each the whole app opened
// on it, by day or by night, left to right or right to left (in Arabic):
// what ui_core's sweep reads as everyday/<id>, at every width.
import 'package:flutter/widgets.dart';

import 'kit_gallery/permits/permits.dart';

/// The screens, by their ids in the look's decisions.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      (id: 'start', app: (b, d) => _app(PermitsPage.start, b, d)),
      (id: 'tasks', app: (b, d) => _app(PermitsPage.tasks, b, d)),
      (id: 'question', app: (b, d) => _app(PermitsPage.vehicle, b, d)),
      (id: 'details', app: (b, d) => _app(PermitsPage.details, b, d)),
      (
        id: 'details-errors',
        app: (b, d) => _app(PermitsPage.details, b, d, showErrors: true),
      ),
      (id: 'check', app: (b, d) => _app(PermitsPage.check, b, d)),
      (id: 'confirmation', app: (b, d) => _app(PermitsPage.sent, b, d)),
      (id: 'applications', app: (b, d) => _app(PermitsPage.applications, b, d)),
      (
        id: 'applications-empty',
        app: (b, d) => _app(
          PermitsPage.applications,
          b,
          d,
          condition: PermitsCondition.empty,
        ),
      ),
      (
        id: 'applications-unavailable',
        app: (b, d) => _app(
          PermitsPage.applications,
          b,
          d,
          condition: PermitsCondition.unavailable,
        ),
      ),
      (id: 'application', app: (b, d) => _app(PermitsPage.application, b, d)),
      (id: 'search', app: (b, d) => _app(PermitsPage.zones, b, d)),
      (
        id: 'search-empty',
        app: (b, d) =>
            _app(PermitsPage.zones, b, d, condition: PermitsCondition.empty),
      ),
      (
        id: 'search-unavailable',
        app: (b, d) => _app(
          PermitsPage.zones,
          b,
          d,
          condition: PermitsCondition.unavailable,
        ),
      ),
      (id: 'settings', app: (b, d) => _app(PermitsPage.settings, b, d)),
    ];

/// The service opened on [page] by [brightness], in [direction].
Widget _app(
  PermitsPage page,
  Brightness brightness,
  TextDirection direction, {
  bool showErrors = false,
  PermitsCondition condition = PermitsCondition.usual,
}) => PermitsApp(
  initialPage: page,
  showErrors: showErrors,
  condition: condition,
  initialAppearance: brightness == Brightness.dark
      ? PermitsAppearance.dark
      : PermitsAppearance.light,
  initialDirection: direction,
);
