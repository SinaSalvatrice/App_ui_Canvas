# Roadmap

## M0 - Foundation
- [x] architecture
- [x] Windows / Android target detection
- [x] versioned project model
- [x] screen + semantic node model
- [x] target-specific component registries
- [x] first editor shell
- [x] first select/move interaction
- [x] exporter contract
- [x] generated/user-code separation
- [ ] bootstrap native host folders locally

## M1 - Real editor core
Undo/redo, multi-select, resize handles, Windows mouse/keyboard transforms, Android touch transforms, central zoom/pan, snapping, guides, grid, layers, copy/paste, duplicate/delete, context menus, editable inspector and dirty-state handling.

## M2 - Project system
Create/open/save .appui, autosave/recovery, multiple screens, presets, stable IDs, migrations and templates.

## M3 - Layout
Fixed/fill/hug, anchors, constraints, rows/columns/stacks, Android orientation preview and resizable Windows preview.

## M4 - Component libraries
Windows: title/menu bars, navigation, split views, toolbars, context menus, tree/list/grid and dialogs.
Android: app bar, bottom navigation, drawer, FAB, bottom sheet, snackbar, inputs, dialogs and tabs.

## M5 - Interactions + preview
Navigation graph, show/hide, set value, toggle, dialogs, state, InvokeAction and interactive preview.

## M6 - App shell source export
Output picker, target Flutter scaffold, widget/screen/navigation/theme generation, action hooks, safe re-export and analyzer/formatter.

## M7 - Direct build
Android APK/AAB. Windows executable/MSIX.

## M8 - Advanced
Reusable components, packages, data binding, localization, accessibility, design systems and exporter/plugin API.
