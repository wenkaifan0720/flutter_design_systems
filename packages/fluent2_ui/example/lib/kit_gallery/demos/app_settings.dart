/// The Screens group's Northwind Settings: the owner, then grouped rows with switches and values, at most 720 wide.
/// The whole app stands around it: the tab bar on a phone, the nav pane
/// from 1024 wide, the other roots a tap away.
library;

import 'package:flutter/material.dart';

import '../kit.dart';

Widget kitAppSettingsDemo(Brightness brightness) =>
    KitNorthwind(brightness: brightness, root: KitNorthwindRoot.settings);
