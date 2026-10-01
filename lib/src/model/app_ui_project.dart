import '../platform/designer_target.dart';
import 'ui_screen.dart';

class AppUiProject {
  const AppUiProject({
    required this.schemaVersion,
    required this.id,
    required this.name,
    required this.target,
    required this.initialScreenId,
    required this.screens,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final String id;
  final String name;
  final DesignerTarget target;
  final String initialScreenId;
  final List<UiScreen> screens;

  factory AppUiProject.empty(DesignerTarget target) {
    final screen = UiScreen.empty(
      id: 'screen_home',
      name: 'Home',
      target: target,
    );
    return AppUiProject(
      schemaVersion: currentSchemaVersion,
      id: 'project_untitled',
      name: 'Untitled App',
      target: target,
      initialScreenId: screen.id,
      screens: [screen],
    );
  }

  AppUiProject copyWith({
    String? id,
    String? name,
    String? initialScreenId,
    List<UiScreen>? screens,
  }) =>
      AppUiProject(
        schemaVersion: schemaVersion,
        id: id ?? this.id,
        name: name ?? this.name,
        target: target,
        initialScreenId: initialScreenId ?? this.initialScreenId,
        screens: screens ?? this.screens,
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'target': target.name,
        'initialScreenId': initialScreenId,
        'screens': screens.map((screen) => screen.toJson()).toList(),
      };

  factory AppUiProject.fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'] as int;
    if (version != currentSchemaVersion) {
      throw FormatException('Unsupported .appui schema version: $version');
    }
    final screens = (json['screens']! as List)
        .map(
          (item) => UiScreen.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList();
    if (screens.isEmpty) {
      throw const FormatException('.appui project has no screens.');
    }

    final initialScreenId = json['initialScreenId']! as String;
    if (!screens.any((screen) => screen.id == initialScreenId)) {
      throw const FormatException(
        '.appui initialScreenId does not reference an existing screen.',
      );
    }

    return AppUiProject(
      schemaVersion: version,
      id: json['id']! as String,
      name: json['name']! as String,
      target: DesignerTarget.values.byName(json['target']! as String),
      initialScreenId: initialScreenId,
      screens: screens,
    );
  }
}
