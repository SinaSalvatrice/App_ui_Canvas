# Export pipeline

## The product

The canonical editable artifact is MyApp.appui.

Export App Shell creates a real, runnable source project for the same target platform. It contains screens, layout, theme, navigation, visual states, stable IDs, generated actions and user-owned action/service hooks.

## Safe re-export

- generated/ may be replaced.
- app_logic/ is user-owned.
- user logic is never silently deleted.
- stable node IDs survive re-export.
- schema changes use migrations.

## Optional build output

Android:
- APK
- AAB

Windows:
- executable build folder
- MSIX

Source export remains the important output.

## Actions

Visual events reference typed actions:

    onPressed -> Navigate(screen_settings)
    onPressed -> OpenDialog(dialog_delete)
    onPressed -> InvokeAction(saveProject)

Built-in actions are generated. InvokeAction enters handwritten code. This is how the designer can create useful finished app shells without pretending to visually generate arbitrary APIs, databases or Bluetooth protocols.
