# Architecture

## Product rule

One shared codebase produces two restricted products:

- Windows binary designs Windows applications.
- Android binary designs Android applications.

A project permanently records its target platform. There is no silent platform conversion.

## Core layers

1. Project model: versioned .appui source of truth.
2. Component registry: semantic, platform-specific UI building blocks.
3. Editor engine: selection, transforms, zoom/pan, snapping, layers, undo/redo, clipboard, context menus and dirty state.
4. Preview runtime: interprets .appui before export.
5. Exporters: consume the project model, never editor widgets.

## Generated vs handwritten code

    lib/
      generated/       # App UI Designer owns this
      app_logic/       # user/developer owns this
      main.dart

Re-export may replace generated code but must preserve app_logic.

Flutter is the first implementation target. The .appui model stays framework-neutral.
