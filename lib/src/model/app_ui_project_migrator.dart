class AppUiProjectMigrator {
  static const currentVersion = 2;

  static Map<String, Object?> migrate(Map<String, Object?> source) {
    final json = Map<String, Object?>.from(source);
    final rawVersion = json['schemaVersion'];
    if (rawVersion is! int) {
      throw const FormatException(
        '.appui project is missing a valid schemaVersion.',
      );
    }
    if (rawVersion > currentVersion) {
      throw FormatException(
        'This .appui project uses schema version $rawVersion, '
        'but this App UI Canvas build supports up to version '
        '$currentVersion.',
      );
    }

    var version = rawVersion;
    while (version < currentVersion) {
      switch (version) {
        case 1:
          _migrateV1ToV2(json);
          version = 2;
          break;
        default:
          throw FormatException(
            'No migration path from .appui schema version $version.',
          );
      }
    }

    return json;
  }

  static void _migrateV1ToV2(Map<String, Object?> json) {
    json['metadata'] = <String, Object?>{
      'description': '',
      'organization': '',
      'appIdentifier': '',
      'versionName': '1.0.0',
      'versionCode': 1,
    };
    json['schemaVersion'] = 2;
  }
}
