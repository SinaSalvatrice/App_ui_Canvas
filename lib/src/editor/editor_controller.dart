import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../components/component_definition.dart';
import '../model/app_ui_project.dart';
import '../model/ui_node.dart';
import '../model/ui_screen.dart';

class EditorController extends ChangeNotifier {
  EditorController(this._project)
      : _cleanProjectJson = jsonEncode(_project.toJson()) {
    _history.add(_project);
  }

  AppUiProject _project;
  final List<AppUiProject> _history = [];
  int _historyIndex = 0;
  String _cleanProjectJson;

  final Set<String> _selectedNodeIds = <String>{};
  String? _primarySelectedNodeId;
  int _nextNodeNumber = 1;

  bool gridEnabled = true;
  bool snapEnabled = false;
  bool guidesEnabled = true;
  double gridStep = 8;

  AppUiProject get project => _project;
  Set<String> get selectedNodeIds => Set<String>.unmodifiable(_selectedNodeIds);
  String? get selectedNodeId => _primarySelectedNodeId;
  int get selectedCount => _selectedNodeIds.length;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;
  bool get isDirty => jsonEncode(_project.toJson()) != _cleanProjectJson;

  UiScreen get activeScreen => _project.screens.firstWhere(
        (screen) => screen.id == _project.initialScreenId,
      );

  UiNode? get selectedNode {
    final id = _primarySelectedNodeId;
    if (id == null) return null;
    return _nodeById(id);
  }

  bool isSelected(String id) => _selectedNodeIds.contains(id);

  void markClean() {
    _cleanProjectJson = jsonEncode(_project.toJson());
    notifyListeners();
  }

  void setGridEnabled(bool value) {
    if (gridEnabled == value) return;
    gridEnabled = value;
    notifyListeners();
  }

  void setSnapEnabled(bool value) {
    if (snapEnabled == value) return;
    snapEnabled = value;
    notifyListeners();
  }

  void setGuidesEnabled(bool value) {
    if (guidesEnabled == value) return;
    guidesEnabled = value;
    notifyListeners();
  }

  void selectNode(
    String? id, {
    bool additive = false,
    bool toggle = false,
  }) {
    if (id == null) {
      if (_selectedNodeIds.isEmpty) return;
      _selectedNodeIds.clear();
      _primarySelectedNodeId = null;
      notifyListeners();
      return;
    }

    if (!additive) {
      _selectedNodeIds
        ..clear()
        ..add(id);
      _primarySelectedNodeId = id;
      notifyListeners();
      return;
    }

    if (toggle && _selectedNodeIds.contains(id)) {
      _selectedNodeIds.remove(id);
      if (_primarySelectedNodeId == id) {
        _primarySelectedNodeId =
            _selectedNodeIds.isEmpty ? null : _selectedNodeIds.last;
      }
    } else {
      _selectedNodeIds.add(id);
      _primarySelectedNodeId = id;
    }
    notifyListeners();
  }

  void addComponent(ComponentDefinition definition) {
    final offset = (activeScreen.nodes.length % 8) * 12.0;
    final node = UiNode(
      id: 'node_${_nextNodeNumber++}',
      type: definition.type,
      name: definition.label,
      frame: definition.defaultFrame.copyWith(
        x: definition.defaultFrame.x + offset,
        y: definition.defaultFrame.y + offset,
      ),
      properties: Map<String, Object?>.from(definition.defaultProperties),
    );

    _replaceActiveScreen(
      activeScreen.copyWith(nodes: [...activeScreen.nodes, node]),
      commit: true,
    );
    _selectedNodeIds
      ..clear()
      ..add(node.id);
    _primarySelectedNodeId = node.id;
    notifyListeners();
  }

  void moveSelectedBy(double dx, double dy) {
    if (_selectedNodeIds.isEmpty) return;
    final selected = _selectedNodeIds;

    final nodes = activeScreen.nodes.map((node) {
      if (!selected.contains(node.id)) return node;
      return node.copyWith(
        frame: node.frame.copyWith(
          x: _snap(node.frame.x + dx),
          y: _snap(node.frame.y + dy),
        ),
      );
    }).toList();

    _replaceActiveScreen(
      activeScreen.copyWith(nodes: nodes),
      commit: false,
    );
  }

  void resizeNodeBy(
    String id, {
    required double dx,
    required double dy,
    required bool left,
    required bool right,
    required bool top,
    required bool bottom,
  }) {
    final source = _nodeById(id);
    if (source == null) return;

    var x = source.frame.x;
    var y = source.frame.y;
    var width = source.frame.width;
    var height = source.frame.height;

    if (left) {
      final rightEdge = x + width;
      width = (width - dx).clamp(24.0, activeScreen.width).toDouble();
      width = _snapSize(width, min: 24);
      x = rightEdge - width;
    } else if (right) {
      width = (width + dx).clamp(24.0, activeScreen.width).toDouble();
      width = _snapSize(width, min: 24);
    }

    if (top) {
      final bottomEdge = y + height;
      height = (height - dy).clamp(24.0, activeScreen.height).toDouble();
      height = _snapSize(height, min: 24);
      y = bottomEdge - height;
    } else if (bottom) {
      height = (height + dy).clamp(24.0, activeScreen.height).toDouble();
      height = _snapSize(height, min: 24);
    }

    final next = source.copyWith(
      frame: source.frame.copyWith(
        x: snapEnabled ? _snap(x) : x,
        y: snapEnabled ? _snap(y) : y,
        width: width,
        height: height,
      ),
    );
    _replaceNode(next, commit: false);
  }

  void commitLiveEdit() {
    _pushHistory();
    notifyListeners();
  }

  void deleteSelected() {
    if (_selectedNodeIds.isEmpty) return;
    final selected = Set<String>.from(_selectedNodeIds);
    _replaceActiveScreen(
      activeScreen.copyWith(
        nodes: activeScreen.nodes
            .where((node) => !selected.contains(node.id))
            .toList(),
      ),
      commit: true,
    );
    _selectedNodeIds.clear();
    _primarySelectedNodeId = null;
    notifyListeners();
  }

  void duplicateSelected() {
    if (_selectedNodeIds.isEmpty) return;
    final selected = activeScreen.nodes
        .where((node) => _selectedNodeIds.contains(node.id))
        .toList();
    if (selected.isEmpty) return;

    final duplicates = <UiNode>[];
    for (final source in selected) {
      duplicates.add(
        UiNode(
          id: 'node_${_nextNodeNumber++}',
          type: source.type,
          name: source.name,
          frame: source.frame.copyWith(
            x: source.frame.x + 16,
            y: source.frame.y + 16,
          ),
          properties: Map<String, Object?>.from(source.properties),
          children: source.children,
        ),
      );
    }

    _replaceActiveScreen(
      activeScreen.copyWith(nodes: [...activeScreen.nodes, ...duplicates]),
      commit: true,
    );
    _selectedNodeIds
      ..clear()
      ..addAll(duplicates.map((node) => node.id));
    _primarySelectedNodeId = duplicates.last.id;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _historyIndex -= 1;
    _project = _history[_historyIndex];
    _ensureSelectionExists();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex += 1;
    _project = _history[_historyIndex];
    _ensureSelectionExists();
    notifyListeners();
  }

  double _snap(double value) {
    if (!snapEnabled) return value;
    return (value / gridStep).round() * gridStep;
  }

  double _snapSize(double value, {required double min}) {
    if (!snapEnabled) return value;
    return ((value / gridStep).round() * gridStep)\n        .clamp(min, double.infinity)\n        .toDouble();
  }

  UiNode? _nodeById(String id) {
    for (final node in activeScreen.nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  void _replaceNode(UiNode replacement, {required bool commit}) {
    _replaceActiveScreen(
      activeScreen.copyWith(
        nodes: activeScreen.nodes
            .map((node) => node.id == replacement.id ? replacement : node)
            .toList(),
      ),
      commit: commit,
    );
  }

  void _replaceActiveScreen(
    UiScreen replacement, {
    required bool commit,
  }) {
    _project = _project.copyWith(
      screens: _project.screens
          .map((screen) => screen.id == replacement.id ? replacement : screen)
          .toList(),
    );
    if (commit) _pushHistory();
    notifyListeners();
  }

  void _pushHistory() {
    final current = jsonEncode(_project.toJson());
    final historical = jsonEncode(_history[_historyIndex].toJson());
    if (current == historical) return;

    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(_project);
    if (_history.length > 100) {
      _history.removeAt(0);
    }
    _historyIndex = _history.length - 1;
  }

  void _ensureSelectionExists() {
    final ids = activeScreen.nodes.map((node) => node.id).toSet();
    _selectedNodeIds.removeWhere((id) => !ids.contains(id));
    if (_primarySelectedNodeId != null &&
        !_selectedNodeIds.contains(_primarySelectedNodeId)) {
      _primarySelectedNodeId =
          _selectedNodeIds.isEmpty ? null : _selectedNodeIds.last;
    }
  }
}
