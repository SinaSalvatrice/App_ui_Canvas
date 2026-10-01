# App UI Designer

Visual editor for building platform-specific application shells.

- Windows build -> designs Windows apps.
- Android build -> designs Android apps.
- Editable source of truth -> .appui project.
- Main export -> runnable source app shell for the same platform.
- Later convenience export -> APK/AAB or EXE/MSIX.

Generated source and handwritten application logic stay separated so re-exporting a design never destroys custom code.

## Bootstrap

After cloning:

    ./tool/bootstrap_platform_hosts.ps1
    flutter pub get
    flutter run -d windows

or select an Android device/emulator.

See docs/ARCHITECTURE.md, docs/EXPORT_PIPELINE.md and docs/ROADMAP.md.
