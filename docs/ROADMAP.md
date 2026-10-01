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

### State and history
- [x] snapshot history
- [x] undo / redo
- [x] dirty-state tracking
- [x] multi-selection model
- [x] duplicate / delete
- [x] internal copy / cut / paste
- [ ] command objects for complex grouped edits

### Transform engine
- [x] move one or multiple selected nodes
- [x] eight resize handles
- [x] zoom-independent handle hit targets
- [x] minimum sizes
- [x] resize at canvas zoom
- [x] locked nodes protected from move / resize / delete
- [x] rotation + 15 degree Shift snapping
- [ ] group resize
- [x] keyboard nudging (1 unit, Shift = 10)
- [x] multi-selection bounding frame
- [x] align left / center / right / top / middle / bottom
- [x] Ctrl+A select all

### Canvas
- [x] central TransformationController
- [x] Windows Ctrl + wheel zoom
- [x] Windows wheel pan
- [x] Windows Shift + wheel horizontal pan
- [x] Android pinch zoom / pan
- [x] zoom percentage
- [x] zoom in / out
- [x] fit screen
- [x] grid
- [x] grid snapping
- [x] center guides
- [x] smart alignment guides
- [ ] ruler

### Editor operations
- [x] layer forward / backward
- [x] bring to front / send to back
- [x] visibility
- [x] lock
- [x] Windows context menu
- [x] Android long-press menu
- [x] editable X / Y / width / height
- [x] numeric mouse-wheel stepping at 1 unit per notch
- [x] editable text property
- [x] safe close / unsaved dialog
- [ ] system clipboard interoperability

## M2 - Project system
- [x] create new project
- [x] open .appui
- [x] save / save as
- [x] native project file picker
- [x] Windows safe-close with save / discard / cancel
- [x] Android back protection for dirty projects
- [x] multiple screens
- [x] add / duplicate / rename / delete screen
- [x] choose start screen
- [x] active screen independent from start screen
- [x] stable node and screen IDs after loading
- [x] project rename
- [x] project metadata
- [x] recent projects
- [x] autosave / recovery
- [x] screen presets
- [x] schema migrations (v1 -> v2)
- [x] project templates

## M3 - Layout
- [x] persistent responsive layout spec
- [x] Fixed / Fill / Hug sizing
- [x] horizontal left / center / right anchors
- [x] vertical top / center / bottom anchors
- [x] min / max size constraints
- [x] responsive reflow when screen preset changes
- [x] Hug reflow when text content changes
- [x] arbitrary resizable Windows preview
- [x] Android portrait / landscape preview toggle
- [ ] Row / Column / Stack containers
- [ ] nested parent-relative constraints

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
