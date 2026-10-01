import 'package:app_ui_designer/src/components/component_registry.dart';
import 'package:app_ui_designer/src/editor/editor_controller.dart';
import 'package:app_ui_designer/src/model/app_ui_project.dart';
import 'package:app_ui_designer/src/model/ui_node.dart';
import 'package:app_ui_designer/src/model/ui_rect.dart';
import 'package:app_ui_designer/src/model/screen_preset.dart';
import 'package:app_ui_designer/src/platform/designer_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('add, undo and redo preserve project history', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );
    final component = ComponentRegistry.forTarget(DesignerTarget.windows).first;

    expect(controller.activeScreen.nodes, isEmpty);
    expect(controller.isDirty, isFalse);

    controller.addComponent(component);
    expect(controller.activeScreen.nodes, hasLength(1));
    expect(controller.canUndo, isTrue);
    expect(controller.isDirty, isTrue);

    controller.undo();
    expect(controller.activeScreen.nodes, isEmpty);

    controller.redo();
    expect(controller.activeScreen.nodes, hasLength(1));
  });

  test('multi selection moves selected nodes together', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );
    final components = ComponentRegistry.forTarget(DesignerTarget.windows);

    controller.addComponent(components[0]);
    final first = controller.selectedNodeId!;
    controller.addComponent(components[1]);
    final second = controller.selectedNodeId!;

    controller.selectNode(first);
    controller.selectNode(second, additive: true);
    expect(controller.selectedCount, 2);

    final before = {
      for (final node in controller.activeScreen.nodes)
        node.id: (node.frame.x, node.frame.y),
    };

    controller.beginMove();
    controller.moveSelectedBy(10, 6);
    controller.commitLiveEdit();

    for (final node in controller.activeScreen.nodes) {
      expect(node.frame.x, before[node.id]!.$1 + 10);
      expect(node.frame.y, before[node.id]!.$2 + 6);
    }
  });

  test('resize keeps minimum node size', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );
    final component = ComponentRegistry.forTarget(DesignerTarget.windows).first;
    controller.addComponent(component);

    final id = controller.selectedNodeId!;
    controller.beginResizeNode(id);
    controller.resizeNodeBy(
      id,
      dx: -10000,
      dy: -10000,
      left: false,
      right: true,
      top: false,
      bottom: true,
    );
    controller.commitLiveEdit();

    expect(controller.selectedNode!.frame.width, 24);
    expect(controller.selectedNode!.frame.height, 24);
  });

  test('lock and visibility survive node json roundtrip', () {
    const node = UiNode(
      id: 'node_a',
      type: 'text',
      frame: UiRect(x: 1, y: 2, width: 30, height: 40),
      visible: false,
      locked: true,
    );

    final restored = UiNode.fromJson(node.toJson());
    expect(restored.visible, isFalse);
    expect(restored.locked, isTrue);
  });

  test('rotation survives node json roundtrip', () {
    const node = UiNode(
      id: 'node_rotate',
      type: 'text',
      frame: UiRect(x: 1, y: 2, width: 30, height: 40),
      rotation: 37.5,
    );

    final restored = UiNode.fromJson(node.toJson());
    expect(restored.rotation, 37.5);
  });

  test('rotation snap rounds to fifteen degrees', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );
    final component = ComponentRegistry.forTarget(DesignerTarget.windows).first;
    controller.addComponent(component);
    final id = controller.selectedNodeId!;

    controller.rotateNodeTo(id, 22, snap15: true);
    controller.commitLiveEdit();

    expect(controller.selectedNode!.rotation, 15);
  });

  test('copy paste creates new ids and keeps source', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );
    final component = ComponentRegistry.forTarget(DesignerTarget.windows).first;
    controller.addComponent(component);

    final originalId = controller.selectedNodeId!;
    controller.copySelected();
    expect(controller.canPaste, isTrue);
    controller.pasteClipboard();

    expect(controller.activeScreen.nodes, hasLength(2));
    expect(controller.selectedNodeId, isNot(originalId));
    expect(
      controller.activeScreen.nodes.map((node) => node.id).toSet(),
      hasLength(2),
    );
  });

  test('locked nodes do not move', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );
    final component = ComponentRegistry.forTarget(DesignerTarget.windows).first;
    controller.addComponent(component);
    final id = controller.selectedNodeId!;
    final before = controller.selectedNode!.frame;

    controller.setNodeLocked(id, true);
    controller.beginMove();
    controller.moveSelectedBy(50, 50);
    controller.commitLiveEdit();

    expect(controller.selectedNode!.frame.x, before.x);
    expect(controller.selectedNode!.frame.y, before.y);
  });
  test('select all selects every visible node', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );
    final components = ComponentRegistry.forTarget(DesignerTarget.windows);
    controller.addComponent(components[0]);
    controller.addComponent(components[1]);

    controller.selectAll();

    expect(controller.selectedCount, 2);
    expect(controller.selectionBounds, isNotNull);
  });
  test('screen operations preserve a valid active screen', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );

    controller.addScreen();
    expect(controller.project.screens, hasLength(2));
    final addedId = controller.activeScreenId;

    controller.renameScreen(addedId, 'Settings');
    expect(controller.activeScreen.name, 'Settings');

    controller.duplicateActiveScreen();
    expect(controller.project.screens, hasLength(3));
    final duplicateId = controller.activeScreenId;
    expect(duplicateId, isNot(addedId));

    controller.deleteScreen(duplicateId);
    expect(controller.project.screens, hasLength(2));
    expect(
      controller.project.screens.any(
        (screen) => screen.id == controller.activeScreenId,
      ),
      isTrue,
    );
  });

  test('replacing a project resets dirty state and history', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );
    final component = ComponentRegistry.forTarget(DesignerTarget.windows).first;
    controller.addComponent(component);
    expect(controller.isDirty, isTrue);

    final loaded = AppUiProject.empty(DesignerTarget.windows);
    controller.replaceProject(loaded);

    expect(controller.isDirty, isFalse);
    expect(controller.canUndo, isFalse);
    expect(controller.activeScreenId, loaded.initialScreenId);
  });
  test('screen presets create and resize screens', () {
    final controller = EditorController(
      AppUiProject.empty(DesignerTarget.windows),
    );

    controller.addScreen(ScreenPreset.windowsCompact);
    expect(controller.activeScreen.width, 1024);
    expect(controller.activeScreen.height, 640);

    controller.applyScreenPreset(ScreenPreset.windowsFullHd);
    expect(controller.activeScreen.width, 1920);
    expect(controller.activeScreen.height, 1080);
  });
}
