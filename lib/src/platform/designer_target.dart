import 'package:flutter/foundation.dart';

enum DesignerTarget {
  windows,
  android;

  static DesignerTarget get current {
    if (kIsWeb) {
      throw UnsupportedError('Only Windows and Android are supported.');
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows => DesignerTarget.windows,
      TargetPlatform.android => DesignerTarget.android,
      _ => throw UnsupportedError('Only Windows and Android are supported.'),
    };
  }

  String get label => switch (this) {
        DesignerTarget.windows => 'Windows',
        DesignerTarget.android => 'Android',
      };
}
