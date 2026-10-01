import '../platform/designer_target.dart';
import 'app_ui_project_migrator.dart';
import 'project_metadata.dart';
import 'ui_screen.dart';

class AppUiProject {
  const AppUiProject({
    required this.schemaVersion,
    required this.id,
    required this.name,
    required this.target,
    required this.initialScreenId,
    required this.screens,
    this.metadata = const ProjectMetadata(),
  });

  static const currentSchemaVersion = AppUiProjectMigrator.currentVersion;

  final int schemaVersion;
  final String id;
  final String name;
  final DesignerTarget target;
  final String initialScreenId;
  final List<UiScreen> screens;
  final ProjectMetadata metadata;

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
    ProjectMetadata? metadata,
  }) =>
      AppUiProject(
        schemaVersion: currentSchemaVersion,
        id: id ?? this.id,
        name: name ?? this.name,
        target: target,
        initialScreenId: initialScreenId ?? this.initialScreenId,
        screens: screens ?? this.screens,
        metadata: metadata ?? this.metadata,
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'id': id,
        'name': name,
        'target': target.name,
        'initialScreenId': initialScreenId,
        'metadata': metadata.toJson(),
        'screens': screens.map((screen) => screen.toJson()).toList(),
      };

  factory AppUiProject.fromJson(Map<String, Object?> json) {
    final migrated = AppUiProjectMigrator.migrate(json);
    final screens = (migrated['screens']! as List)
        .map(
          (item) => UiScreen.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList();
    if (screens.isEmpty) {
      throw const FormatException('.appui project has no screens.');
    }

    final initialScreenId = migrated['initialScreenId']! as String;
    if (!screens.any((screen) => screen.id == initialScreenId)) {
      throw const FormatException(
        '.appui initialScreenId does not reference an existing screen.',
      );
    }

    final metadataJson =
        Map<String, Object?>.from(migrated['metadata']! as Map);

    return AppUiProject(
      schemaVersion: currentSchemaVersion,
      id: migrated['id']! as String,
      name: migrated['name']! as String,
      target: DesignerTarget.values.byName(
        migrated['target']! as String,
      ),
      initialScreenId: initialScreenId,
      metadata: ProjectMetadata.fromJson(metadataJson),
      screens: screens,
    );
  }
}
