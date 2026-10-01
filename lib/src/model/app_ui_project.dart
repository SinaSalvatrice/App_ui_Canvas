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
    final screen = switch (target) {
      DesignerTarget.windows => const UiScreen(
          id: 'screen_home',
          name: 'Home',
          width: 1280,
          height: 720,
        ),
      DesignerTarget.android => const UiScreen(
          id: 'screen_home',
          name: 'Home',
          width: 412,
          height: 915,
        ),
    };
    return AppUiProject(
      schemaVersion: currentSchemaVersion,
      id: 'project_untitled',
      name: 'Untitled App',
      target: target,
      initialScreenId: screen.id,
      screens: [screen],
    );
  }

  AppUiProject copyWith({List<UiScreen>? screens}) => AppUiProject(
        schemaVersion: schemaVersion,
        id: id,
        name: name,
        target: target,
        initialScreenId: initialScreenId,
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
    return AppUiProject(
      schemaVersion: version,
      id: json['id']! as String,
      name: json['name']! as String,
      target: DesignerTarget.values.byName(json['target']! as String),
      initialScreenId: json['initialScreenId']! as String,
      screens: (json['screens']! as List)
          .map((item) => UiScreen.fromJson(Map<String, Object?>.from(item as Map)))
          .toList(),
    );
  }
}
