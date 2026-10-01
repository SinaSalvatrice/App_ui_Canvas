class AppUiProjectMigrator {
  static const currentVersion = 3;

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
        case 2:
          _migrateV2ToV3(json);
          version = 3;
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

  static void _migrateV2ToV3(Map<String, Object?> json) {
    final rawScreens = json['screens'];
    if (rawScreens is List) {
      json['screens'] = [
        for (final rawScreen in rawScreens)
          if (rawScreen is Map)
            _screenWithLayout(
              Map<String, Object?>.from(rawScreen),
            )
          else
            rawScreen,
      ];
    }
    json['schemaVersion'] = 3;
  }

  static Map<String, Object?> _screenWithLayout(
    Map<String, Object?> screen,
  ) {
    final rawNodes = screen['nodes'];
    if (rawNodes is List) {
      screen['nodes'] = [
        for (final rawNode in rawNodes)
          if (rawNode is Map)
            _nodeWithLayout(
              Map<String, Object?>.from(rawNode),
            )
          else
            rawNode,
      ];
    }
    return screen;
  }

  static Map<String, Object?> _nodeWithLayout(
    Map<String, Object?> node,
  ) {
    node.putIfAbsent(
      'layout',
      () => <String, Object?>{
        'widthMode': 'fixed',
        'heightMode': 'fixed',
        'horizontalAnchor': 'left',
        'verticalAnchor': 'top',
        'minWidth': 24,
        'minHeight': 24,
      },
    );

    final rawChildren = node['children'];
    if (rawChildren is List) {
      node['children'] = [
        for (final rawChild in rawChildren)
          if (rawChild is Map)
            _nodeWithLayout(
              Map<String, Object?>.from(rawChild),
            )
          else
            rawChild,
      ];
    }
    return node;
  }
}
