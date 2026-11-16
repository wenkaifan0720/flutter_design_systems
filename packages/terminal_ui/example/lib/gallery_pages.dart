// Generated from the gallery's manifest: every page of the gallery, in its order.
import 'package:flutter/widgets.dart';

import 'kit_gallery/demos/overview.dart';
import 'kit_gallery/demos/home.dart';
import 'kit_gallery/demos/runs.dart';
import 'kit_gallery/demos/run_detail.dart';
import 'kit_gallery/demos/deploy.dart';
import 'kit_gallery/demos/settings.dart';
import 'kit_gallery/demos/foundations.dart';
import 'kit_gallery/demos/primitives.dart';
import 'kit_gallery/demos/buttons.dart';
import 'kit_gallery/demos/actions.dart';
import 'kit_gallery/demos/selection.dart';
import 'kit_gallery/demos/ranges.dart';
import 'kit_gallery/demos/fields.dart';
import 'kit_gallery/demos/inputs.dart';
import 'kit_gallery/demos/pickers.dart';
import 'kit_gallery/demos/lists.dart';
import 'kit_gallery/demos/containers.dart';
import 'kit_gallery/demos/charts.dart';
import 'kit_gallery/demos/inventory.dart';
import 'kit_gallery/demos/navigation.dart';
import 'kit_gallery/demos/wayfinding.dart';
import 'kit_gallery/demos/overlays.dart';
import 'kit_gallery/demos/surfaces.dart';

/// One page of the gallery: its title and the screen it shows, by day or by night.
typedef GalleryPage = ({
  String id,
  String title,
  Widget Function(Brightness) build,
});

/// Every page, in the gallery's order.
const List<GalleryPage> galleryPages = [
  (id: 'overview', title: 'Overview', build: kitOverviewDemo),
  (id: 'home', title: 'slipway · home', build: kitHomeDemo),
  (id: 'runs', title: 'slipway · runs', build: kitRunsDemo),
  (id: 'run-detail', title: 'slipway · a run', build: kitRunDetailDemo),
  (id: 'deploy', title: 'slipway · new deploy', build: kitDeployDemo),
  (id: 'settings', title: 'slipway · config', build: kitSettingsDemo),
  (id: 'foundations', title: 'Foundations', build: kitFoundationsDemo),
  (id: 'primitives', title: 'Make it yours', build: kitPrimitivesDemo),
  (id: 'buttons', title: 'Buttons & keys', build: kitButtonsDemo),
  (
    id: 'actions',
    title: 'Toggles, split buttons & links',
    build: kitActionsDemo,
  ),
  (id: 'selection', title: 'Checkbox, radio & switch', build: kitSelectionDemo),
  (id: 'ranges', title: 'Sliders & meters', build: kitRangesDemo),
  (id: 'fields', title: 'Text field & select', build: kitFieldsDemo),
  (
    id: 'inputs',
    title: 'Passwords, codes, numbers & tags',
    build: kitInputsDemo,
  ),
  (id: 'pickers', title: 'Dates, times & colour', build: kitPickersDemo),
  (id: 'lists', title: 'Lists & panes', build: kitListsDemo),
  (id: 'containers', title: 'Tables, trees & layout', build: kitContainersDemo),
  (id: 'charts', title: 'Charts', build: kitChartsDemo),
  (id: 'inventory', title: 'Inventory', build: kitInventoryDemo),
  (id: 'navigation', title: 'Navigation', build: kitNavigationDemo),
  (
    id: 'wayfinding',
    title: 'Paths, pages, steps & menus',
    build: kitWayfindingDemo,
  ),
  (id: 'overlays', title: 'Dialogs, toasts & progress', build: kitOverlaysDemo),
  (id: 'surfaces', title: 'Sheets, popovers & states', build: kitSurfacesDemo),
];
