import 'package:app_ui_designer/src/model/project_template.dart';
import 'package:app_ui_designer/src/model/ui_node.dart';
import 'package:app_ui_designer/src/platform/designer_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final target in DesignerTarget.values) {
    test('${target.name} templates create valid unique node ids', () {
      for (final template in ProjectTemplate.forTarget(target)) {
        final project = template.createProject('Template Test');
        final ids = <String>[];

        void collect(UiNode node) {
          ids.add(node.id);
          for (final child in node.children) {
            collect(child);
          }
        }

        for (final screen in project.screens) {
          for (final node in screen.nodes) {
            collect(node);
          }
        }

        expect(project.target, target);
        expect(project.screens, isNotEmpty);
        expect(
          project.screens.any(
            (screen) => screen.id == project.initialScreenId,
          ),
          isTrue,
        );
        expect(ids.toSet().length, ids.length);
      }
    });
  }

  test('Windows sidebar template creates Home and Settings', () {
    final template = ProjectTemplate.forTarget(DesignerTarget.windows)
        .firstWhere(
      (item) => item.kind == ProjectTemplateKind.windowsSidebar,
    );

    final project = template.createProject('Desktop App');

    expect(project.screens.map((screen) => screen.name), [
      'Home',
      'Settings',
    ]);
  });

  test('Android bottom navigation template creates three screens', () {
    final template = ProjectTemplate.forTarget(DesignerTarget.android)
        .firstWhere(
      (item) => item.kind == ProjectTemplateKind.androidBottomNavigation,
    );

    final project = template.createProject('Mobile App');

    expect(project.screens.map((screen) => screen.name), [
      'Home',
      'Search',
      'Settings',
    ]);
  });
}
