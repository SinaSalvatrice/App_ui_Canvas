import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../components/component_definition.dart';
import '../model/app_ui_project.dart';
import '../model/ui_node.dart';
import '../model/ui_rect.dart';
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
  List<UiNode> _clipboard = const [];

  Map<String, UiRect>? _moveStartFrames;
  double _moveDeltaX = 0;
  double _moveDeltaY = 0;
  String? _resizeNodeId;
  UiRect? _resizeStartFrame;
  double _resizeDeltaX = 0;
  double _resizeDeltaY = 0;

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
  bool get canPaste => _clipboard.isNotEmpty;
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
      id: _newNodeId(),
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
    _selectOnly(node.id);
    notifyListeners();
  }

  void beginMove() {
    _moveStartFrames = {
      for (final node in activeScreen.nodes)
        if (_selectedNodeIds.contains(node.id) && !node.locked)
          node.id: node.frame,
    };
    _moveDeltaX = 0;
    _moveDeltaY = 0;
  }

  void moveSelectedBy(double dx, double dy) {
    if (_selectedNodeIds.isEmpty) return;
    _moveStartFrames ??= {
      for (final node in activeScreen.nodes)
        if (_selectedNodeIds.contains(node.id) && !node.locked)
          node.id: node.frame,
    };
    if (_moveStartFrames!.isEmpty) return;

    _moveDeltaX += dx;
    _moveDeltaY += dy;
    final starts = _moveStartFrames!;

    final nodes = activeScreen.nodes.map((node) {
      final start = starts[node.id];
      if (start == null) return node;
      return node.copyWith(
        frame: node.frame.copyWith(
          x: _snap(start.x + _moveDeltaX),
          y: _snap(start.y + _moveDeltaY),
        ),
      );
    }).toList();

    _replaceActiveScreen(
      activeScreen.copyWith(nodes: nodes),
      commit: false,
    );
  }

  void beginResizeNode(String id) {
    final source = _nodeById(id);
    if (source == null || source.locked) return;
    _resizeNodeId = id;
    _resizeStartFrame = source.frame;
    _resizeDeltaX = 0;
    _resizeDeltaY = 0;
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
    if (source == null || source.locked) return;

    if (_resizeNodeId != id || _resizeStartFrame == null) {
      beginResizeNode(id);
    }
    final start = _resizeStartFrame;
    if (start == null) return;

    _resizeDeltaX += dx;
    _resizeDeltaY += dy;

    var x = start.x;
    var y = start.y;
    var width = start.width;
    var height = start.height;

    if (left) {
      final rightEdge = x + width;
      width = (width - _resizeDeltaX)
          .clamp(24.0, activeScreen.width)
          .toDouble();
      width = _snapSize(width, min: 24);
      x = rightEdge - width;
    } else if (right) {
      width = (width + _resizeDeltaX)
          .clamp(24.0, activeScreen.width)
          .toDouble();
      width = _snapSize(width, min: 24);
    }

    if (top) {
      final bottomEdge = y + height;
      height = (height - _resizeDeltaY)
          .clamp(24.0, activeScreen.height)
          .toDouble();
      height = _snapSize(height, min: 24);
      y = bottomEdge - height;
    } else if (bottom) {
      height = (height + _resizeDeltaY)
          .clamp(24.0, activeScreen.height)
          .toDouble();
      height = _snapSize(height, min: 24);
    }

    _replaceNode(
      source.copyWith(
        frame: source.frame.copyWith(
          x: snapEnabled ? _snap(x) : x,
          y: snapEnabled ? _snap(y) : y,
          width: width,
          height: height,
        ),
      ),
      commit: false,
    );
  }

  void commitLiveEdit() {
    _resetLiveTransform();
    _pushHistory();
    notifyListeners();
  }

  void updatePrimaryFrame({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    final node = selectedNode;
    if (node == null || node.locked) return;

    _replaceNode(
      node.copyWith(
        frame: node.frame.copyWith(
          x: x,
          y: y,
          width: width == null ? null : width.clamp(24.0, 10000.0).toDouble(),
          height:
              height == null ? null : height.clamp(24.0, 10000.0).toDouble(),
        ),
      ),
      commit: true,
    );
  }

  void updatePrimaryProperty(String key, Object? value) {
    final node = selectedNode;
    if (node == null || node.locked) return;
    final properties = Map<String, Object?>.from(node.properties);
    properties[key] = value;
    _replaceNode(
      node.copyWith(properties: properties),
      commit: true,
    );
  }

  void setNodeVisible(String id, bool visible) {
    final node = _nodeById(id);
    if (node == null || node.visible == visible) return;
    _replaceNode(node.copyWith(visible: visible), commit: true);
  }

  void setNodeLocked(String id, bool locked) {
    final node = _nodeById(id);
    if (node == null || node.locked == locked) return;
    _replaceNode(node.copyWith(locked: locked), commit: true);
  }

  void deleteSelected() {
    if (_selectedNodeIds.isEmpty) return;
    final selected = Set<String>.from(_selectedNodeIds);
    final deletable = activeScreen.nodes
        .where((node) => selected.contains(node.id) && !node.locked)
        .map((node) => node.id)
        .toSet();
    if (deletable.isEmpty) return;

    _replaceActiveScreen(
      activeScreen.copyWith(
        nodes: activeScreen.nodes
            .where((node) => !deletable.contains(node.id))
            .toList(),
      ),
      commit: true,
    );
    _selectedNodeIds.removeAll(deletable);
    _primarySelectedNodeId =
        _selectedNodeIds.isEmpty ? null : _selectedNodeIds.last;
    notifyListeners();
  }

  void copySelected() {
    if (_selectedNodeIds.isEmpty) return;
    _clipboard = activeScreen.nodes
        .where((node) => _selectedNodeIds.contains(node.id))
        .map(_deepCopyNode)
        .toList();
    notifyListeners();
  }

  void cutSelected() {
    copySelected();
    deleteSelected();
  }

  void pasteClipboard() {
    if (_clipboard.isEmpty) return;
    final pasted = _clipboard
        .map((node) => _cloneWithNewIds(node, offset: 16))
        .toList();

    _replaceActiveScreen(
      activeScreen.copyWith(nodes: [...activeScreen.nodes, ...pasted]),
      commit: true,
    );
    _selectedNodeIds
      ..clear()
      ..addAll(pasted.map((node) => node.id));
    _primarySelectedNodeId = pasted.last.id;
    notifyListeners();
  }

  void duplicateSelected() {
    if (_selectedNodeIds.isEmpty) return;
    final selected = activeScreen.nodes
        .where((node) => _selectedNodeIds.contains(node.id))
        .toList();
    if (selected.isEmpty) return;

    final duplicates = selected
        .map((node) => _cloneWithNewIds(node, offset: 16))
        .toList();

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

  void moveSelectedLayer(int delta) {
    if (_selectedNodeIds.isEmpty || delta == 0) return;
    final nodes = [...activeScreen.nodes];

    if (delta > 0) {
      for (var i = nodes.length - 2; i >= 0; i--) {
        if (_selectedNodeIds.contains(nodes[i].id) &&
            !_selectedNodeIds.contains(nodes[i + 1].id)) {
          final item = nodes[i];
          nodes[i] = nodes[i + 1];
          nodes[i + 1] = item;
        }
      }
    } else {
      for (var i = 1; i < nodes.length; i++) {
        if (_selectedNodeIds.contains(nodes[i].id) &&
            !_selectedNodeIds.contains(nodes[i - 1].id)) {
          final item = nodes[i];
          nodes[i] = nodes[i - 1];
          nodes[i - 1] = item;
        }
      }
    }

    _replaceActiveScreen(activeScreen.copyWith(nodes: nodes), commit: true);
  }

  void bringSelectedToFront() {
    if (_selectedNodeIds.isEmpty) return;
    final back = activeScreen.nodes
        .where((node) => !_selectedNodeIds.contains(node.id))
        .toList();
    final front = activeScreen.nodes
        .where((node) => _selectedNodeIds.contains(node.id))
        .toList();
    _replaceActiveScreen(
      activeScreen.copyWith(nodes: [...back, ...front]),
      commit: true,
    );
  }

  void sendSelectedToBack() {
    if (_selectedNodeIds.isEmpty) return;
    final back = activeScreen.nodes
        .where((node) => _selectedNodeIds.contains(node.id))
        .toList();
    final front = activeScreen.nodes
        .where((node) => !_selectedNodeIds.contains(node.id))
        .toList();
    _replaceActiveScreen(
      activeScreen.copyWith(nodes: [...back, ...front]),
      commit: true,
    );
  }

  void undo() {
    if (!canUndo) return;
    _historyIndex -= 1;
    _project = _history[_historyIndex];
    _resetLiveTransform();
    _ensureSelectionExists();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex += 1;
    _project = _history[_historyIndex];
    _resetLiveTransform();
    _ensureSelectionExists();
    notifyListeners();
  }

  String _newNodeId() => 'node_${_nextNodeNumber++}';

  double _snap(double value) {
    if (!snapEnabled) return value;
    return (value / gridStep).round() * gridStep;
  }

  double _snapSize(double value, {required double min}) {
    if (!snapEnabled) return value;
    return ((value / gridStep).round() * gridStep)
        .clamp(min, double.infinity)
        .toDouble();
  }

  UiNode? _nodeById(String id) {
    for (final node in activeScreen.nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  UiNode _deepCopyNode(UiNode node) =>
      UiNode.fromJson(Map<String, Object?>.from(node.toJson()));

  UiNode _cloneWithNewIds(UiNode source, {required double offset}) {
    return UiNode(
      id: _newNodeId(),
      type: source.type,
      name: source.name,
      frame: source.frame.copyWith(
        x: source.frame.x + offset,
        y: source.frame.y + offset,
      ),
      visible: source.visible,
      locked: source.locked,
      properties: Map<String, Object?>.from(source.properties),
      children: source.children
          .map((child) => _cloneWithNewIds(child, offset: 0))
          .toList(),
    );
  }

  void _selectOnly(String id) {
    _selectedNodeIds
      ..clear()
      ..add(id);
    _primarySelectedNodeId = id;
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

  void _resetLiveTransform() {
    _moveStartFrames = null;
    _moveDeltaX = 0;
    _moveDeltaY = 0;
    _resizeNodeId = null;
    _resizeStartFrame = null;
    _resizeDeltaX = 0;
    _resizeDeltaY = 0;
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
