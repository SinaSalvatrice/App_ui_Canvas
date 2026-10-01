import 'package:app_ui_designer/src/components/component_registry.dart';
import 'package:app_ui_designer/src/editor/editor_controller.dart';
import 'package:app_ui_designer/src/model/app_ui_project.dart';
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
}
