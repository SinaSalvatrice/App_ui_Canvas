import '../platform/designer_target.dart';

class ScreenPreset {
  const ScreenPreset({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
  });

  final String id;
  final String label;
  final double width;
  final double height;

  static const windowsCompact = ScreenPreset(
    id: 'windows_compact',
    label: 'Windows Compact 1024 × 640',
    width: 1024,
    height: 640,
  );

  static const windowsStandard = ScreenPreset(
    id: 'windows_standard',
    label: 'Windows 1280 × 720',
    width: 1280,
    height: 720,
  );

  static const windowsFullHd = ScreenPreset(
    id: 'windows_full_hd',
    label: 'Windows Full HD 1920 × 1080',
    width: 1920,
    height: 1080,
  );

  static const androidCompact = ScreenPreset(
    id: 'android_compact',
    label: 'Android Compact 360 × 800',
    width: 360,
    height: 800,
  );

  static const androidStandard = ScreenPreset(
    id: 'android_standard',
    label: 'Android 412 × 915',
    width: 412,
    height: 915,
  );

  static const androidTablet = ScreenPreset(
    id: 'android_tablet',
    label: 'Android Tablet 800 × 1280',
    width: 800,
    height: 1280,
  );

  static const androidLandscape = ScreenPreset(
    id: 'android_landscape',
    label: 'Android Landscape 915 × 412',
    width: 915,
    height: 412,
  );

  static List<ScreenPreset> forTarget(DesignerTarget target) => switch (target) {
        DesignerTarget.windows => const [
            windowsCompact,
            windowsStandard,
            windowsFullHd,
          ],
        DesignerTarget.android => const [
            androidCompact,
            androidStandard,
            androidTablet,
            androidLandscape,
          ],
      };

  static ScreenPreset defaultFor(DesignerTarget target) => switch (target) {
        DesignerTarget.windows => windowsStandard,
        DesignerTarget.android => androidStandard,
      };
}
