import 'package:flutter/foundation.dart';

import '../components/component_definition.dart';
import '../model/app_ui_project.dart';
import '../model/ui_node.dart';
import '../model/ui_screen.dart';

class EditorController extends ChangeNotifier {
  EditorController(this._project);

  AppUiProject _project;
  String? _selectedNodeId;
  int _nextNodeNumber = 1;

  AppUiProject get project => _project;
  String? get selectedNodeId => _selectedNodeId;

  UiScreen get activeScreen => _project.screens.firstWhere(
        (screen) => screen.id == _project.initialScreenId,
      );

  UiNode? get selectedNode {
    final id = _selectedNodeId;
    if (id == null) return null;
    for (final node in activeScreen.nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  void selectNode(String? id) {
    _selectedNodeId = id;
    notifyListeners();
  }

  void addComponent(ComponentDefinition definition) {
    final node = UiNode(
      id: 'node_${_nextNodeNumber++}',
      type: definition.type,
      name: definition.label,
      frame: definition.defaultFrame,
      properties: Map<String, Object?>.from(definition.defaultProperties),
    );
    _replaceActiveScreen(
      activeScreen.copyWith(nodes: [...activeScreen.nodes, node]),
    );
    _selectedNodeId = node.id;
    notifyListeners();
  }

  void moveNode(String id, double dx, double dy) {
    final nodes = activeScreen.nodes.map((node) {
      if (node.id != id) return node;
      return node.copyWith(
        frame: node.frame.copyWith(
          x: node.frame.x + dx,
          y: node.frame.y + dy,
        ),
      );
    }).toList();
    _replaceActiveScreen(activeScreen.copyWith(nodes: nodes));
    notifyListeners();
  }

  void _replaceActiveScreen(UiScreen replacement) {
    _project = _project.copyWith(
      screens: _project.screens
          .map((screen) => screen.id == replacement.id ? replacement : screen)
          .toList(),
    );
  }
}
