import 'package:app_ui_designer/src/model/app_ui_project.dart';
import 'package:app_ui_designer/src/model/project_metadata.dart';
import 'package:app_ui_designer/src/platform/designer_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema v1 project migrates to current version', () {
    final legacy = <String, Object?>{
      'schemaVersion': 1,
      'id': 'legacy_project',
      'name': 'Legacy',
      'target': 'windows',
      'initialScreenId': 'screen_home',
      'screens': <Object?>[
        <String, Object?>{
          'id': 'screen_home',
          'name': 'Home',
          'width': 1280,
          'height': 720,
          'nodes': <Object?>[],
        },
      ],
    };

    final project = AppUiProject.fromJson(legacy);

    expect(project.schemaVersion, AppUiProject.currentSchemaVersion);
    expect(project.name, 'Legacy');
    expect(project.target, DesignerTarget.windows);
    expect(project.metadata.versionName, '1.0.0');
    expect(project.metadata.versionCode, 1);
  });

  test('project metadata survives json roundtrip', () {
    final project = AppUiProject.empty(DesignerTarget.android).copyWith(
      metadata: const ProjectMetadata(
        description: 'Demo app',
        organization: 'Example Studio',
        appIdentifier: 'com.example.demo',
        versionName: '2.4.1',
        versionCode: 17,
      ),
    );

    final restored = AppUiProject.fromJson(project.toJson());

    expect(restored.metadata.description, 'Demo app');
    expect(restored.metadata.organization, 'Example Studio');
    expect(restored.metadata.appIdentifier, 'com.example.demo');
    expect(restored.metadata.versionName, '2.4.1');
    expect(restored.metadata.versionCode, 17);
  });

  test('future schema versions are rejected clearly', () {
    final future = AppUiProject.empty(DesignerTarget.windows).toJson();
    future['schemaVersion'] = AppUiProject.currentSchemaVersion + 1;

    expect(
      () => AppUiProject.fromJson(future),
      throwsA(isA<FormatException>()),
    );
  });
  test('schema v2 nodes migrate to responsive layout defaults', () {
    final v2 = <String, Object?>{
      'schemaVersion': 2,
      'id': 'v2_project',
      'name': 'V2',
      'target': 'windows',
      'initialScreenId': 'screen_home',
      'metadata': <String, Object?>{},
      'screens': <Object?>[
        <String, Object?>{
          'id': 'screen_home',
          'name': 'Home',
          'width': 1280,
          'height': 720,
          'nodes': <Object?>[
            <String, Object?>{
              'id': 'node_1',
              'type': 'text',
              'frame': <String, Object?>{
                'x': 10,
                'y': 20,
                'width': 100,
                'height': 40,
              },
              'properties': <String, Object?>{'text': 'Hello'},
              'children': <Object?>[],
            },
          ],
        },
      ],
    };

    final project = AppUiProject.fromJson(v2);
    final node = project.screens.first.nodes.first;

    expect(project.schemaVersion, AppUiProject.currentSchemaVersion);
    expect(node.layout.widthMode.name, 'fixed');
    expect(node.layout.heightMode.name, 'fixed');
  });
}
