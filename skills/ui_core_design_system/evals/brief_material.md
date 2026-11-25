# Brief 3: material, Steep

A design made of a physical material, where every state must stay true to it.

## The brief, as given to the agent

> Build `steep`, a Flutter app for brewing tea and keeping a tasting
> journal, with a design of its own on ui_core ^0.7.0, made of glazed
> porcelain: white bodies with a soft glaze highlight, cobalt blue painted
> lines and fills, parts that sit slightly raised from a matt bisque ground,
> gentle rounded edges. Light falls from the top start; glaze catches it. By
> night the ground is a deep cobalt and the bodies a warm grey glaze. Motion
> is calm and weighted. Every state must be something porcelain can do: glaze
> brightens, a body presses down onto the ground, a painted line thickens.
> Nothing glows that porcelain could not. The app runs on phones and on
> tablets held either way. Use the `ui_core_design_system` skill.
>
> Screens: **Teas**, the visitor's teas with a filter by kind (green, black,
> oolong, herbal), each opening its brew. **Brew**: the steep time (a number
> of seconds, stepped in fives), the water's temperature on a slider (60 to
> 100 °C), and a key that starts and pauses the brew, with the time left.
> **Tasting**: a note for a brew: a rating of one to five, tasting words as
> tags (from suggestions or typed), the date, and words; deleting a note asks
> first.
>
> Deliver the app at `steep/`, its design in `lib/design/`. Its
> > `lib/screens.dart` defines `final Map<String, WidgetBuilder> screens` (each
> > screen by name, ready to pump with sample data) and
> > `Widget designHost(BuildContext context, Widget child, Brightness brightness)`
> > (the design's theme, and whatever the screens read, round `child`, as the
> > app's `MaterialApp.builder` puts it). Its tests run leak-tracked. Finish
> > when the skill's checks pass and you have read every picture.

## What a pass looks like

- Every gate in [rubric.md](rubric.md), and 80 or more review points.
- Material truth (R2) and focus (R3) carry this brief: focus as the glaze
  catching more light or a painted line thickening, never a coloured halo
  or a shadow sharpened to stand out; an inset part (a field) stays inset
  when focused. No part has a painted outline at rest that glazed porcelain
  wouldn't.
- Shadows are never cut by a clip (`DesignShadowClipCheck` in its tests).
- Under Reduce Motion a press still reads (the body's shade changes)
  without travel.
- The slider, the rating and the tags are built on ui_core's behaviours
  (`RawValueHandle`, `RawRating`, `RawTagInput`), not rebuilt.

## Which checks score it

| What | Gate or item |
|---|---|
| Every screen at every size, for every reader | G3 |
| Cut shadows, labels on their middles | `DesignShadowClipCheck`, `DesignLabelCheck` in its tests; R5 |
| States in the material, focus | R2, R3, from the focus pictures and crops of each part's states |
| Weighted motion, Reduce Motion | R4 |
| Slider, rating, tags on ui_core | G4, R9 |
