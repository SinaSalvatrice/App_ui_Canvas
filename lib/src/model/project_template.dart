import '../platform/designer_target.dart';
import 'app_ui_project.dart';
import 'project_metadata.dart';
import 'ui_node.dart';
import 'ui_rect.dart';
import 'ui_screen.dart';

enum ProjectTemplateKind {
  blank,
  windowsSidebar,
  androidBottomNavigation,
}

class ProjectTemplate {
  const ProjectTemplate({
    required this.kind,
    required this.label,
    required this.description,
    required this.target,
  });

  final ProjectTemplateKind kind;
  final String label;
  final String description;
  final DesignerTarget target;

  AppUiProject createProject(String name) {
    final projectId =
        'project_${DateTime.now().microsecondsSinceEpoch.toString()}';
    return switch (kind) {
      ProjectTemplateKind.blank => _blank(projectId, name, target),
      ProjectTemplateKind.windowsSidebar =>
        _windowsSidebar(projectId, name),
      ProjectTemplateKind.androidBottomNavigation =>
        _androidBottomNavigation(projectId, name),
    };
  }

  static List<ProjectTemplate> forTarget(DesignerTarget target) =>
      switch (target) {
        DesignerTarget.windows => const [
            ProjectTemplate(
              kind: ProjectTemplateKind.blank,
              label: 'Blank',
              description: 'One empty Windows screen.',
              target: DesignerTarget.windows,
            ),
            ProjectTemplate(
              kind: ProjectTemplateKind.windowsSidebar,
              label: 'Sidebar shell',
              description:
                  'Home and Settings with menu bar and navigation rail.',
              target: DesignerTarget.windows,
            ),
          ],
        DesignerTarget.android => const [
            ProjectTemplate(
              kind: ProjectTemplateKind.blank,
              label: 'Blank',
              description: 'One empty Android screen.',
              target: DesignerTarget.android,
            ),
            ProjectTemplate(
              kind: ProjectTemplateKind.androidBottomNavigation,
              label: 'Bottom navigation',
              description:
                  'Home, Search and Settings with app bar and bottom navigation.',
              target: DesignerTarget.android,
            ),
          ],
      };

  static AppUiProject _blank(
    String id,
    String name,
    DesignerTarget target,
  ) {
    final screen = UiScreen.empty(
      id: 'screen_home',
      name: 'Home',
      target: target,
    );
    return AppUiProject(
      schemaVersion: AppUiProject.currentSchemaVersion,
      id: id,
      name: name,
      target: target,
      initialScreenId: screen.id,
      screens: [screen],
      metadata: const ProjectMetadata(),
    );
  }

  static AppUiProject _windowsSidebar(String id, String name) {
    UiScreen screen(String screenId, String title) => UiScreen(
          id: screenId,
          name: title,
          width: 1280,
          height: 720,
          nodes: [
            const UiNode(
              id: 'node_menu_bar_\$screenId',
              type: 'menuBar',
              name: 'Menu bar',
              frame: UiRect(x: 0, y: 0, width: 1280, height: 40),
            ),
            const UiNode(
              id: 'node_navigation_\$screenId',
              type: 'navigationRail',
              name: 'Navigation rail',
              frame: UiRect(x: 0, y: 40, width: 220, height: 680),
            ),
            UiNode(
              id: 'node_title_$screenId',
              type: 'text',
              name: 'Title',
              frame: const UiRect(
                x: 260,
                y: 80,
                width: 360,
                height: 54,
              ),
              properties: {'text': title},
            ),
            UiNode(
              id: 'node_content_$screenId',
              type: 'container',
              name: 'Content',
              frame: const UiRect(
                x: 260,
                y: 160,
                width: 940,
                height: 480,
              ),
            ),
          ],
        );

    final home = screen('screen_home', 'Home');
    final settings = screen('screen_settings', 'Settings');

    return AppUiProject(
      schemaVersion: AppUiProject.currentSchemaVersion,
      id: id,
      name: name,
      target: DesignerTarget.windows,
      initialScreenId: home.id,
      screens: [home, settings],
      metadata: const ProjectMetadata(),
    );
  }

  static AppUiProject _androidBottomNavigation(String id, String name) {
    UiScreen screen(String screenId, String title) => UiScreen(
          id: screenId,
          name: title,
          width: 412,
          height: 915,
          nodes: [
            const UiNode(
              id: 'node_app_bar_\$screenId',
              type: 'appBar',
              name: 'App bar',
              frame: UiRect(x: 0, y: 0, width: 412, height: 64),
            ),
            UiNode(
              id: 'node_title_$screenId',
              type: 'text',
              name: 'Title',
              frame: const UiRect(
                x: 24,
                y: 96,
                width: 280,
                height: 48,
              ),
              properties: {'text': title},
            ),
            const UiNode(
              id: 'node_bottom_navigation_\$screenId',
              type: 'bottomNavigation',
              name: 'Bottom navigation',
              frame: UiRect(x: 0, y: 835, width: 412, height: 80),
            ),
          ],
        );

    final home = screen('screen_home', 'Home');
    final search = screen('screen_search', 'Search');
    final settings = screen('screen_settings', 'Settings');

    return AppUiProject(
      schemaVersion: AppUiProject.currentSchemaVersion,
      id: id,
      name: name,
      target: DesignerTarget.android,
      initialScreenId: home.id,
      screens: [home, search, settings],
      metadata: const ProjectMetadata(),
    );
  }
}
