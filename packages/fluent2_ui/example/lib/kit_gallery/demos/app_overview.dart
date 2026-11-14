/// The Screens group's Northwind Home, the overview: today, what waits on you, storage and recent files; two columns from 760 wide.
/// The whole app stands around it: the tab bar on a phone, the nav pane
/// from 1024 wide, the other roots a tap away.
library;

import 'package:flutter/material.dart';

import '../kit.dart';

Widget kitAppOverviewDemo(Brightness brightness) =>
    KitNorthwind(brightness: brightness, root: KitNorthwindRoot.home);
