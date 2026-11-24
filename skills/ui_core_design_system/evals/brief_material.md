# Brief 3, material-heavy: Porcelain

A look made of a physical material, where every state must stay true to it.

## The brief, as given to the agent

> Build `porcelain_ui`, a Flutter design-system package on ui_core ^0.6.0,
> made of glazed porcelain: white bodies with a soft glaze highlight, cobalt
> blue painted lines and fills, parts that sit slightly raised from a
> matt bisque ground, gentle rounded edges. Light falls from the top left;
> glaze catches it. By night the ground is a deep cobalt and the bodies a
> warm grey glaze. Motion is calm and weighted.
>
> Every state must be something porcelain can do: glaze brightens, a body
> presses down onto the ground, a painted line thickens. Nothing glows that
> porcelain could not.
>
> It must be complete: every row of ui_core's inventory present, or absent
> with a designer's reason. Day and night themes; a compact density for
> desktop. Use the `ui_core_design_system` skill.
>
> Deliver the package at `porcelain_ui/` with an example app at
> `porcelain_ui/example/` whose `lib/inventory.dart` defines
> `final RawInventory inventory` (the look's answers) and
> `Widget lookHost(BuildContext context, Widget child, Brightness brightness)`
> (the look's theme round `child`, as the app's `MaterialApp.builder` puts
> it). Finish when the skill's checks pass and you have read every picture.

## What a pass looks like

- Every gate in [rubric.md](rubric.md), and 80 or more review points.
- Material truth (R2) and focus (R3) carry this brief: focus as the glaze
  catching more light or a painted line thickening, visible and findable at
  a glance beside material_ui's focused part at the same size and theme, and
  something porcelain can do: never a coloured halo, never a shadow
  sharpened to stand out; an inset part (a field) stays inset when focused.
  No part has a painted outline at rest that glazed porcelain wouldn't.
- Shadows are never cut by a clip (`DesignShadowClipCheck` in its tests) and
  stay within the raised parts' rows.
- Nested shapes are concentric (a chosen segment inside its track, a list's
  rows inside its card).
- Under Reduce Motion a press still reads (the body's shade changes) without
  travel.

## Which checks score it

| What | Gate or item |
|---|---|
| Completeness, essentials | G3, G4 |
| Every reader at every size | G5 |
| Cut shadows, labels on their middles | `DesignShadowClipCheck`, `DesignLabelCheck` in its tests; R5 |
| States in the material, focus contrast | R2, R3, from Tab, hover, press, selected, disabled and error crops of eleven parts, day and night, at 1440 |
| Weighted motion, Reduce Motion | R4 |
