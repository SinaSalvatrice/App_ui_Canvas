import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../components/component_definition.dart';
import '../model/app_ui_project.dart';
import '../model/project_metadata.dart';
import '../model/ui_layout_spec.dart';
import '../model/ui_node.dart';
import '../model/ui_rect.dart';
import '../model/ui_screen.dart';
import '../model/screen_preset.dart';

enum EditorAlignment {
  left,
  horizontalCenter,
  right,
  top,
  verticalCenter,
  bottom,
}

class EditorController extends ChangeNotifier {
  EditorController(this._project)
      : _activeScreenId = _project.initialScreenId,
        _cleanProjectJson = jsonEncode(_project.toJson()) {
    _history.add(_project);
  }

  static const double _smartGuideThreshold = 6;

  AppUiProject _project;
  final List<AppUiProject> _history = [];
  int _historyIndex = 0;
  String _cleanProjectJson;
  String _activeScreenId;

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

  double? _activeGuideX;
  double? _activeGuideY;

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
  double? get activeGuideX => _activeGuideX;
  double? get activeGuideY => _activeGuideY;

  String get activeScreenId => _activeScreenId;

  UiScreen get activeScreen => _project.screens.firstWhere(
        (screen) => screen.id == _activeScreenId,
      );

  UiNode? get selectedNode {
    final id = _primarySelectedNodeId;
    if (id == null) return null;
    return _nodeById(id);
  }

  UiRect? get selectionBounds {
    final frames = activeScreen.nodes
        .where((node) => _selectedNodeIds.contains(node.id) && node.visible)
        .map((node) => node.frame)
        .toList();
    return _boundsOf(frames);
  }

  bool isSelected(String id) => _selectedNodeIds.contains(id);

  void replaceProject(
    AppUiProject project, {
    bool markClean = true,
  }) {
    _project = project;
    _activeScreenId = project.initialScreenId;
    _history
      ..clear()
      ..add(project);
    _historyIndex = 0;
    _cleanProjectJson =
        markClean ? jsonEncode(project.toJson()) : '__recovered_project__';
    _selectedNodeIds.clear();
    _primarySelectedNodeId = null;
    _clipboard = const [];
    _resetLiveTransform();
    notifyListeners();
  }

  void selectScreen(String id) {
    if (id == _activeScreenId ||
        !_project.screens.any((screen) => screen.id == id)) {
      return;
    }
    _activeScreenId = id;
    _selectedNodeIds.clear();
    _primarySelectedNodeId = null;
    _resetLiveTransform();
    notifyListeners();
  }

  void addScreen([ScreenPreset? preset]) {
    final selectedPreset = preset ?? ScreenPreset.defaultFor(_project.target);
    final id = _newScreenId();
    final screen = UiScreen(
      id: id,
      name: 'Screen ' + (_project.screens.length + 1).toString(),
      width: selectedPreset.width,
      height: selectedPreset.height,
    );
    _project = _project.copyWith(screens: [..._project.screens, screen]);
    _activeScreenId = id;
    _selectedNodeIds.clear();
    _primarySelectedNodeId = null;
    _pushHistory();
    notifyListeners();
  }

  void applyScreenPreset(ScreenPreset preset) {
    resizeActiveScreen(preset.width, preset.height);
  }

  void toggleScreenOrientation() {
    final screen = activeScreen;
    resizeActiveScreen(screen.height, screen.width);
  }

  void resizeActiveScreen(
    double width,
    double height, {
    bool commit = true,
  }) {
    final screen = activeScreen;
    final nextWidth = width.clamp(240.0, 10000.0).toDouble();
    final nextHeight = height.clamp(240.0, 10000.0).toDouble();
    if (screen.width == nextWidth && screen.height == nextHeight) return;

    final nodes = screen.nodes
        .map(
          (node) => _reflowNodeForScreenResize(
            node,
            oldWidth: screen.width,
            oldHeight: screen.height,
            newWidth: nextWidth,
            newHeight: nextHeight,
          ),
        )
        .toList();

    _replaceActiveScreen(
      screen.copyWith(
        width: nextWidth,
        height: nextHeight,
        nodes: nodes,
      ),
      commit: commit,
    );
  }

  void duplicateActiveScreen() {
    final source = activeScreen;
    final id = _newScreenId();
    final copy = UiScreen(
      id: id,
      name: source.name + ' Copy',
      width: source.width,
      height: source.height,
      nodes: source.nodes
          .map((node) => _cloneWithNewIds(node, offset: 0))
          .toList(),
    );
    _project = _project.copyWith(screens: [..._project.screens, copy]);
    _activeScreenId = id;
    _selectedNodeIds.clear();
    _primarySelectedNodeId = null;
    _pushHistory();
    notifyListeners();
  }

  void renameScreen(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        !_project.screens.any((screen) => screen.id == id)) {
      return;
    }
    _project = _project.copyWith(
      screens: _project.screens
          .map(
            (screen) => screen.id == id
                ? screen.copyWith(name: trimmed)
                : screen,
          )
          .toList(),
    );
    _pushHistory();
    notifyListeners();
  }

  void setInitialScreen(String id) {
    if (id == _project.initialScreenId ||
        !_project.screens.any((screen) => screen.id == id)) {
      return;
    }
    _project = _project.copyWith(initialScreenId: id);
    _pushHistory();
    notifyListeners();
  }

  void deleteScreen(String id) {
    if (_project.screens.length <= 1 ||
        !_project.screens.any((screen) => screen.id == id)) {
      return;
    }

    final remaining =
        _project.screens.where((screen) => screen.id != id).toList();
    final nextInitial = _project.initialScreenId == id
        ? remaining.first.id
        : _project.initialScreenId;
    _project = _project.copyWith(
      initialScreenId: nextInitial,
      screens: remaining,
    );
    if (_activeScreenId == id) {
      _activeScreenId = remaining.first.id;
    }
    _selectedNodeIds.clear();
    _primarySelectedNodeId = null;
    _pushHistory();
    notifyListeners();
  }

  void renameProject(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _project.name) return;
    _project = _project.copyWith(name: trimmed);
    _pushHistory();
    notifyListeners();
  }

  void updateProjectSettings({
    required String name,
    required ProjectMetadata metadata,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final next = _project.copyWith(
      name: trimmed,
      metadata: metadata,
    );
    if (jsonEncode(next.toJson()) == jsonEncode(_project.toJson())) return;
    _project = next;
    _pushHistory();
    notifyListeners();
  }

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
    if (!value) _clearActiveGuides();
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
      _selectOnly(id);
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

  void selectAll() {
    final ids = activeScreen.nodes
        .where((node) => node.visible)
        .map((node) => node.id)
        .toList();
    _selectedNodeIds
      ..clear()
      ..addAll(ids);
    _primarySelectedNodeId = ids.isEmpty ? null : ids.last;
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

  void nudgeSelected(double dx, double dy) {
    if (_selectedNodeIds.isEmpty) return;
    final nodes = activeScreen.nodes.map((node) {
      if (!_selectedNodeIds.contains(node.id) || node.locked) return node;
      return _nodeWithSyncedInsets(
        node.copyWith(
          frame: node.frame.copyWith(
            x: node.frame.x + dx,
            y: node.frame.y + dy,
          ),
        ),
      );
    }).toList();
    _replaceActiveScreen(
      activeScreen.copyWith(nodes: nodes),
      commit: true,
    );
  }

  void beginMove() {
    _moveStartFrames = {
      for (final node in activeScreen.nodes)
        if (_selectedNodeIds.contains(node.id) && !node.locked)
          node.id: node.frame,
    };
    _moveDeltaX = 0;
    _moveDeltaY = 0;
    _clearActiveGuides();
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
    final startBounds = _boundsOf(starts.values);
    if (startBounds == null) return;

    var appliedDx = _moveDeltaX;
    var appliedDy = _moveDeltaY;

    if (snapEnabled) {
      appliedDx = _snap(startBounds.x + appliedDx) - startBounds.x;
      appliedDy = _snap(startBounds.y + appliedDy) - startBounds.y;
    }

    if (guidesEnabled) {
      final proposed = startBounds.copyWith(
        x: startBounds.x + appliedDx,
        y: startBounds.y + appliedDy,
      );
      final xMatch = _findSmartGuide(
        moving: [proposed.x, proposed.x + proposed.width / 2, proposed.x + proposed.width],
        targets: _verticalGuideTargets(),
      );
      final yMatch = _findSmartGuide(
        moving: [proposed.y, proposed.y + proposed.height / 2, proposed.y + proposed.height],
        targets: _horizontalGuideTargets(),
      );
      _activeGuideX = xMatch?.target;
      _activeGuideY = yMatch?.target;
      if (xMatch != null) appliedDx += xMatch.correction;
      if (yMatch != null) appliedDy += yMatch.correction;
    }

    final nodes = activeScreen.nodes.map((node) {
      final start = starts[node.id];
      if (start == null) return node;
      return _nodeWithSyncedInsets(
        node.copyWith(
          frame: node.frame.copyWith(
            x: start.x + appliedDx,
            y: start.y + appliedDy,
          ),
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
    _clearActiveGuides();
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

    if (guidesEnabled) {
      if (left || right) {
        final edge = left ? x : x + width;
        final match = _findSmartGuide(
          moving: [edge],
          targets: _verticalGuideTargets(excludingId: id),
        );
        _activeGuideX = match?.target;
        if (match != null) {
          if (left) {
            final fixedRight = x + width;
            x += match.correction;
            width = (fixedRight - x).clamp(24.0, 10000.0).toDouble();
          } else {
            width = (width + match.correction)
                .clamp(24.0, 10000.0)
                .toDouble();
          }
        }
      }
      if (top || bottom) {
        final edge = top ? y : y + height;
        final match = _findSmartGuide(
          moving: [edge],
          targets: _horizontalGuideTargets(excludingId: id),
        );
        _activeGuideY = match?.target;
        if (match != null) {
          if (top) {
            final fixedBottom = y + height;
            y += match.correction;
            height = (fixedBottom - y).clamp(24.0, 10000.0).toDouble();
          } else {
            height = (height + match.correction)
                .clamp(24.0, 10000.0)
                .toDouble();
          }
        }
      }
    }

    if (source.layout.widthMode == UiSizeMode.hug) {
      x = start.x;
      width = start.width;
    } else {
      final constrainedWidth = source.layout.constrainWidth(width);
      if (left) x += width - constrainedWidth;
      width = constrainedWidth;
    }

    if (source.layout.heightMode == UiSizeMode.hug) {
      y = start.y;
      height = start.height;
    } else {
      final constrainedHeight = source.layout.constrainHeight(height);
      if (top) y += height - constrainedHeight;
      height = constrainedHeight;
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

  void rotateNodeTo(String id, double degrees, {bool snap15 = false}) {
    final node = _nodeById(id);
    if (node == null || node.locked) return;
    var next = degrees % 360;
    if (next < 0) next += 360;
    if (snap15) next = (next / 15).round() * 15.0;
    _replaceNode(node.copyWith(rotation: next), commit: false);
  }

  void updatePrimaryRotation(double degrees) {
    final node = selectedNode;
    if (node == null || node.locked) return;
    var next = degrees % 360;
    if (next < 0) next += 360;
    _replaceNode(node.copyWith(rotation: next), commit: true);
  }

  void alignSelected(EditorAlignment alignment) {
    final selected = activeScreen.nodes
        .where((node) => _selectedNodeIds.contains(node.id) && !node.locked)
        .toList();
    if (selected.isEmpty) return;

    final bounds = selected.length == 1
        ? UiRect(
            x: 0,
            y: 0,
            width: activeScreen.width,
            height: activeScreen.height,
          )
        : _boundsOf(selected.map((node) => node.frame));
    if (bounds == null) return;

    final nodes = activeScreen.nodes.map((node) {
      if (!selected.any((item) => item.id == node.id)) return node;
      var x = node.frame.x;
      var y = node.frame.y;

      switch (alignment) {
        case EditorAlignment.left:
          x = bounds.x;
          break;
        case EditorAlignment.horizontalCenter:
          x = bounds.x + (bounds.width - node.frame.width) / 2;
          break;
        case EditorAlignment.right:
          x = bounds.x + bounds.width - node.frame.width;
          break;
        case EditorAlignment.top:
          y = bounds.y;
          break;
        case EditorAlignment.verticalCenter:
          y = bounds.y + (bounds.height - node.frame.height) / 2;
          break;
        case EditorAlignment.bottom:
          y = bounds.y + bounds.height - node.frame.height;
          break;
      }
      return node.copyWith(frame: node.frame.copyWith(x: x, y: y));
    }).toList();

    _replaceActiveScreen(activeScreen.copyWith(nodes: nodes), commit: true);
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

    final nextFrame = node.frame.copyWith(
      x: x,
      y: y,
      width: width == null ? null : node.layout.constrainWidth(width),
      height: height == null ? null : node.layout.constrainHeight(height),
    );
    _replaceNode(
      _nodeWithSyncedInsets(node.copyWith(frame: nextFrame)),
      commit: true,
    );
  }

  void updatePrimaryLayout(UiLayoutSpec layout) {
    final node = selectedNode;
    if (node == null || node.locked) return;

    var nextLayout = layout;
    if (layout.widthMode == UiSizeMode.fill) {
      nextLayout = nextLayout.copyWith(
        leftInset: node.frame.x,
        rightInset:
            activeScreen.width - node.frame.x - node.frame.width,
      );
    }
    if (layout.heightMode == UiSizeMode.fill) {
      nextLayout = nextLayout.copyWith(
        topInset: node.frame.y,
        bottomInset:
            activeScreen.height - node.frame.y - node.frame.height,
      );
    }

    final nextNode = _resolveNodeLayout(
      node.copyWith(layout: nextLayout),
      previousFrame: node.frame,
    );
    _replaceNode(nextNode, commit: true);
  }

  void updatePrimaryProperty(String key, Object? value) {
    final node = selectedNode;
    if (node == null || node.locked) return;
    final properties = Map<String, Object?>.from(node.properties);
    properties[key] = value;
    final updated = node.copyWith(properties: properties);
    _replaceNode(
      _resolveNodeLayout(updated, previousFrame: node.frame),
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
    _ensureActiveScreenExists();
    _resetLiveTransform();
    _ensureSelectionExists();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex += 1;
    _project = _history[_historyIndex];
    _ensureActiveScreenExists();
    _resetLiveTransform();
    _ensureSelectionExists();
    notifyListeners();
  }

  String _newNodeId() {
    final existing = _allNodeIds();
    String id;
    do {
      id = 'node_' + (_nextNodeNumber++).toString();
    } while (existing.contains(id));
    return id;
  }

  String _newScreenId() {
    var number = _project.screens.length + 1;
    String id;
    do {
      id = 'screen_' + number.toString();
      number += 1;
    } while (_project.screens.any((screen) => screen.id == id));
    return id;
  }

  Set<String> _allNodeIds() {
    final ids = <String>{};

    void visit(UiNode node) {
      ids.add(node.id);
      for (final child in node.children) {
        visit(child);
      }
    }

    for (final screen in _project.screens) {
      for (final node in screen.nodes) {
        visit(node);
      }
    }
    return ids;
  }

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

  List<double> _verticalGuideTargets({String? excludingId}) {
    final targets = <double>[0, activeScreen.width / 2, activeScreen.width];
    for (final node in activeScreen.nodes) {
      if (!node.visible ||
          node.id == excludingId ||
          _selectedNodeIds.contains(node.id)) {
        continue;
      }
      targets.addAll([
        node.frame.x,
        node.frame.x + node.frame.width / 2,
        node.frame.x + node.frame.width,
      ]);
    }
    return targets;
  }

  List<double> _horizontalGuideTargets({String? excludingId}) {
    final targets = <double>[0, activeScreen.height / 2, activeScreen.height];
    for (final node in activeScreen.nodes) {
      if (!node.visible ||
          node.id == excludingId ||
          _selectedNodeIds.contains(node.id)) {
        continue;
      }
      targets.addAll([
        node.frame.y,
        node.frame.y + node.frame.height / 2,
        node.frame.y + node.frame.height,
      ]);
    }
    return targets;
  }

  _SnapMatch? _findSmartGuide({
    required List<double> moving,
    required List<double> targets,
  }) {
    _SnapMatch? best;
    for (final movingValue in moving) {
      for (final target in targets) {
        final correction = target - movingValue;
        if (correction.abs() > _smartGuideThreshold) continue;
        if (best == null || correction.abs() < best.correction.abs()) {
          best = _SnapMatch(correction: correction, target: target);
        }
      }
    }
    return best;
  }

  UiRect? _boundsOf(Iterable<UiRect> frames) {
    final list = frames.toList();
    if (list.isEmpty) return null;
    var left = list.first.x;
    var top = list.first.y;
    var right = list.first.x + list.first.width;
    var bottom = list.first.y + list.first.height;

    for (final frame in list.skip(1)) {
      if (frame.x < left) left = frame.x;
      if (frame.y < top) top = frame.y;
      if (frame.x + frame.width > right) right = frame.x + frame.width;
      if (frame.y + frame.height > bottom) bottom = frame.y + frame.height;
    }
    return UiRect(
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
  }

  UiNode _reflowNodeForScreenResize(
    UiNode node, {
    required double oldWidth,
    required double oldHeight,
    required double newWidth,
    required double newHeight,
  }) {
    final layout = node.layout;
    final oldFrame = node.frame;

    var width = oldFrame.width;
    var height = oldFrame.height;

    if (layout.widthMode == UiSizeMode.fill) {
      final left = layout.leftInset ?? oldFrame.x;
      final right =
          layout.rightInset ?? oldWidth - oldFrame.x - oldFrame.width;
      width = layout.constrainWidth(newWidth - left - right);
    } else if (layout.widthMode == UiSizeMode.hug) {
      width = layout.constrainWidth(_hugWidth(node));
    } else {
      width = layout.constrainWidth(width);
    }

    if (layout.heightMode == UiSizeMode.fill) {
      final top = layout.topInset ?? oldFrame.y;
      final bottom =
          layout.bottomInset ?? oldHeight - oldFrame.y - oldFrame.height;
      height = layout.constrainHeight(newHeight - top - bottom);
    } else if (layout.heightMode == UiSizeMode.hug) {
      height = layout.constrainHeight(_hugHeight(node));
    } else {
      height = layout.constrainHeight(height);
    }

    final x = layout.widthMode == UiSizeMode.fill
        ? layout.leftInset ?? oldFrame.x
        : switch (layout.horizontalAnchor) {
            UiHorizontalAnchor.left => oldFrame.x,
            UiHorizontalAnchor.center =>
              oldFrame.x +
                  (newWidth - oldWidth) / 2 +
                  (oldFrame.width - width) / 2,
            UiHorizontalAnchor.right =>
              oldFrame.x +
                  (newWidth - oldWidth) +
                  oldFrame.width -
                  width,
          };

    final y = layout.heightMode == UiSizeMode.fill
        ? layout.topInset ?? oldFrame.y
        : switch (layout.verticalAnchor) {
            UiVerticalAnchor.top => oldFrame.y,
            UiVerticalAnchor.center =>
              oldFrame.y +
                  (newHeight - oldHeight) / 2 +
                  (oldFrame.height - height) / 2,
            UiVerticalAnchor.bottom =>
              oldFrame.y +
                  (newHeight - oldHeight) +
                  oldFrame.height -
                  height,
          };

    return node.copyWith(
      frame: oldFrame.copyWith(
        x: x,
        y: y,
        width: width,
        height: height,
      ),
    );
  }

  UiNode _resolveNodeLayout(
    UiNode node, {
    required UiRect previousFrame,
  }) {
    final layout = node.layout;
    var width = node.frame.width;
    var height = node.frame.height;

    if (layout.widthMode == UiSizeMode.fill) {
      final left = layout.leftInset ?? node.frame.x;
      final right = layout.rightInset ??
          activeScreen.width - node.frame.x - node.frame.width;
      width = layout.constrainWidth(activeScreen.width - left - right);
    } else if (layout.widthMode == UiSizeMode.hug) {
      width = layout.constrainWidth(_hugWidth(node));
    } else {
      width = layout.constrainWidth(width);
    }

    if (layout.heightMode == UiSizeMode.fill) {
      final top = layout.topInset ?? node.frame.y;
      final bottom = layout.bottomInset ??
          activeScreen.height - node.frame.y - node.frame.height;
      height = layout.constrainHeight(activeScreen.height - top - bottom);
    } else if (layout.heightMode == UiSizeMode.hug) {
      height = layout.constrainHeight(_hugHeight(node));
    } else {
      height = layout.constrainHeight(height);
    }

    final x = switch (layout.horizontalAnchor) {
      UiHorizontalAnchor.left => node.frame.x,
      UiHorizontalAnchor.center =>
        node.frame.x + (previousFrame.width - width) / 2,
      UiHorizontalAnchor.right =>
        node.frame.x + previousFrame.width - width,
    };
    final y = switch (layout.verticalAnchor) {
      UiVerticalAnchor.top => node.frame.y,
      UiVerticalAnchor.center =>
        node.frame.y + (previousFrame.height - height) / 2,
      UiVerticalAnchor.bottom =>
        node.frame.y + previousFrame.height - height,
    };

    return _nodeWithSyncedInsets(
      node.copyWith(
        frame: node.frame.copyWith(
          x: layout.widthMode == UiSizeMode.fill
              ? layout.leftInset ?? x
              : x,
          y: layout.heightMode == UiSizeMode.fill
              ? layout.topInset ?? y
              : y,
          width: width,
          height: height,
        ),
      ),
    );
  }

  UiNode _nodeWithSyncedInsets(UiNode node) {
    var layout = node.layout;
    if (layout.widthMode == UiSizeMode.fill) {
      layout = layout.copyWith(
        leftInset: node.frame.x,
        rightInset:
            activeScreen.width - node.frame.x - node.frame.width,
      );
    }
    if (layout.heightMode == UiSizeMode.fill) {
      layout = layout.copyWith(
        topInset: node.frame.y,
        bottomInset:
            activeScreen.height - node.frame.y - node.frame.height,
      );
    }
    return node.copyWith(layout: layout);
  }

  double _hugWidth(UiNode node) {
    final text = node.properties['text']?.toString();
    if (text == null || text.isEmpty) return node.frame.width;
    final padding = switch (node.type) {
      'button' || 'filledButton' => 40.0,
      'textField' => 32.0,
      _ => 20.0,
    };
    return text.length * 8.0 + padding;
  }

  double _hugHeight(UiNode node) {
    return switch (node.type) {
      'button' || 'filledButton' => 40.0,
      'textField' => 48.0,
      'switch' => 40.0,
      'text' => 32.0,
      _ => node.frame.height,
    };
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
      rotation: source.rotation,
      visible: source.visible,
      locked: source.locked,
      layout: source.layout,
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
    final normalized = _nodeWithSyncedInsets(replacement);
    _replaceActiveScreen(
      activeScreen.copyWith(
        nodes: activeScreen.nodes
            .map((node) => node.id == normalized.id ? normalized : node)
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

  void _clearActiveGuides() {
    _activeGuideX = null;
    _activeGuideY = null;
  }

  void _resetLiveTransform() {
    _moveStartFrames = null;
    _moveDeltaX = 0;
    _moveDeltaY = 0;
    _resizeNodeId = null;
    _resizeStartFrame = null;
    _resizeDeltaX = 0;
    _resizeDeltaY = 0;
    _clearActiveGuides();
  }

  void _ensureActiveScreenExists() {
    if (_project.screens.any((screen) => screen.id == _activeScreenId)) {
      return;
    }
    _activeScreenId = _project.screens.first.id;
    _selectedNodeIds.clear();
    _primarySelectedNodeId = null;
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

class _SnapMatch {
  const _SnapMatch({
    required this.correction,
    required this.target,
  });

  final double correction;
  final double target;
}
