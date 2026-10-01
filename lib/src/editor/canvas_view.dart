import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/ui_node.dart';
import '../model/ui_rect.dart';
import '../platform/designer_target.dart';
import 'editor_controller.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({
    required this.controller,
    required this.target,
    super.key,
  });

  final EditorController controller;
  final DesignerTarget target;

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  final TransformationController _transform = TransformationController();
  final GlobalKey _viewportKey = GlobalKey();

  double get _scale => _transform.value.getMaxScaleOnAxis();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = widget.controller.activeScreen;
    final isWindows = widget.target == DesignerTarget.windows;
    final multiBounds =
        widget.controller.selectedCount > 1 ? widget.controller.selectionBounds : null;

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            key: _viewportKey,
            onPointerSignal: isWindows ? _handlePointerSignal : null,
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: .20,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(1000),
              constrained: false,
              panEnabled: !isWindows,
              scaleEnabled: !isWindows,
              child: SizedBox(
                width: screen.width,
                height: screen.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.controller.selectNode(null),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black26),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 18,
                          color: Color(0x22000000),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (widget.controller.gridEnabled)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _GridPainter(
                                  step: widget.controller.gridStep,
                                ),
                              ),
                            ),
                          ),
                        if (widget.controller.guidesEnabled)
                          const Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _CenterGuidePainter(),
                              ),
                            ),
                          ),
                        for (final node in screen.nodes)
                          if (node.visible)
                            _NodeView(
                              node: node,
                              selected: widget.controller.isSelected(node.id),
                              primary:
                                  widget.controller.selectedNodeId == node.id,
                              scale: _scale,
                              onSelect: (additive) =>
                                  widget.controller.selectNode(
                                node.id,
                                additive: additive,
                                toggle: additive,
                              ),
                              onMoveStart: widget.controller.beginMove,
                              onMove: (dx, dy) =>
                                  widget.controller.moveSelectedBy(dx, dy),
                              onMoveEnd: widget.controller.commitLiveEdit,
                              onResizeStart: () =>
                                  widget.controller.beginResizeNode(node.id),
                              onResize: ({
                                required dx,
                                required dy,
                                required left,
                                required right,
                                required top,
                                required bottom,
                              }) =>
                                  widget.controller.resizeNodeBy(
                                node.id,
                                dx: dx,
                                dy: dy,
                                left: left,
                                right: right,
                                top: top,
                                bottom: bottom,
                              ),
                              onResizeEnd: widget.controller.commitLiveEdit,
                              onRotateGlobal: (globalPosition) =>
                                  _rotateNodeFromGlobal(node, globalPosition),
                              onRotateEnd: widget.controller.commitLiveEdit,
                              onContextMenu: (position) =>
                                  _showNodeMenu(context, position, node),
                            ),
                        if (multiBounds != null)
                          _MultiSelectionFrame(
                            bounds: multiBounds,
                            scale: _scale,
                            count: widget.controller.selectedCount,
                          ),
                        if (widget.controller.activeGuideX case final x?)
                          Positioned(
                            left: x,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                width: 1 / _scale,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                        if (widget.controller.activeGuideY case final y?)
                          Positioned(
                            top: y,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 1 / _scale,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: AnimatedBuilder(
            animation: _transform,
            builder: (context, _) {
              final percent = (_scale * 100).round();
              return Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: () => _setZoom(_scale / 1.15),
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 58,
                      child: Text(
                        '$percent%',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: () => _setZoom(_scale * 1.15),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: 'Fit screen',
                      onPressed: _fitScreen,
                      icon: const Icon(Icons.fit_screen),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilterChip(
                    label: const Text('Grid'),
                    selected: widget.controller.gridEnabled,
                    onSelected: widget.controller.setGridEnabled,
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Snap'),
                    selected: widget.controller.snapEnabled,
                    onSelected: widget.controller.setSnapEnabled,
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Guides'),
                    selected: widget.controller.guidesEnabled,
                    onSelected: widget.controller.setGuidesEnabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _rotateNodeFromGlobal(UiNode node, Offset globalPosition) {
    final render = _viewportKey.currentContext?.findRenderObject();
    if (render is! RenderBox) return;

    final viewportLocal = render.globalToLocal(globalPosition);
    final scene = _transform.toScene(viewportLocal);
    final center = Offset(
      node.frame.x + node.frame.width / 2,
      node.frame.y + node.frame.height / 2,
    );
    final radians =
        math.atan2(scene.dy - center.dy, scene.dx - center.dx) + math.pi / 2;
    final degrees = radians * 180 / math.pi;
    widget.controller.rotateNodeTo(
      node.id,
      degrees,
      snap15: HardwareKeyboard.instance.isShiftPressed,
    );
  }

  Future<void> _showNodeMenu(
    BuildContext context,
    Offset globalPosition,
    UiNode node,
  ) async {
    if (!widget.controller.isSelected(node.id)) {
      widget.controller.selectNode(node.id);
    }

    if (widget.target == DesignerTarget.android) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Wrap(
            children: _androidMenuItems(context, node),
          ),
        ),
      );
      return;
    }

    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final local = overlay.globalToLocal(globalPosition);

    final action = await showMenu<_NodeMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        local.dx,
        local.dy,
        overlay.size.width - local.dx,
        overlay.size.height - local.dy,
      ),
      items: _windowsMenuItems(node),
    );
    if (action != null) _runNodeAction(action, node);
  }

  List<Widget> _androidMenuItems(BuildContext context, UiNode node) {
    return _NodeMenuAction.values.map((action) {
      final enabled = _actionEnabled(action, node);
      return ListTile(
        enabled: enabled,
        leading: Icon(_actionIcon(action)),
        title: Text(_actionLabel(action, node)),
        onTap: !enabled
            ? null
            : () {
                Navigator.of(context).pop();
                _runNodeAction(action, node);
              },
      );
    }).toList();
  }

  List<PopupMenuEntry<_NodeMenuAction>> _windowsMenuItems(UiNode node) {
    return [
      for (final action in _NodeMenuAction.values)
        PopupMenuItem<_NodeMenuAction>(
          value: action,
          enabled: _actionEnabled(action, node),
          child: Row(
            children: [
              Icon(_actionIcon(action), size: 18),
              const SizedBox(width: 10),
              Text(_actionLabel(action, node)),
            ],
          ),
        ),
    ];
  }

  bool _actionEnabled(_NodeMenuAction action, UiNode node) {
    return switch (action) {
      _NodeMenuAction.paste => widget.controller.canPaste,
      _NodeMenuAction.delete => !node.locked,
      _ => true,
    };
  }

  String _actionLabel(_NodeMenuAction action, UiNode node) => switch (action) {
        _NodeMenuAction.copy => 'Copy',
        _NodeMenuAction.paste => 'Paste',
        _NodeMenuAction.duplicate => 'Duplicate',
        _NodeMenuAction.front => 'Bring to front',
        _NodeMenuAction.forward => 'Bring forward',
        _NodeMenuAction.backward => 'Send backward',
        _NodeMenuAction.back => 'Send to back',
        _NodeMenuAction.lock => node.locked ? 'Unlock' : 'Lock',
        _NodeMenuAction.visibility => node.visible ? 'Hide' : 'Show',
        _NodeMenuAction.delete => 'Delete',
      };

  IconData _actionIcon(_NodeMenuAction action) => switch (action) {
        _NodeMenuAction.copy => Icons.copy,
        _NodeMenuAction.paste => Icons.paste,
        _NodeMenuAction.duplicate => Icons.copy_all,
        _NodeMenuAction.front => Icons.vertical_align_top,
        _NodeMenuAction.forward => Icons.arrow_upward,
        _NodeMenuAction.backward => Icons.arrow_downward,
        _NodeMenuAction.back => Icons.vertical_align_bottom,
        _NodeMenuAction.lock => Icons.lock_outline,
        _NodeMenuAction.visibility => Icons.visibility_outlined,
        _NodeMenuAction.delete => Icons.delete_outline,
      };

  void _runNodeAction(_NodeMenuAction action, UiNode node) {
    switch (action) {
      case _NodeMenuAction.copy:
        widget.controller.copySelected();
        break;
      case _NodeMenuAction.paste:
        widget.controller.pasteClipboard();
        break;
      case _NodeMenuAction.duplicate:
        widget.controller.duplicateSelected();
        break;
      case _NodeMenuAction.front:
        widget.controller.bringSelectedToFront();
        break;
      case _NodeMenuAction.forward:
        widget.controller.moveSelectedLayer(1);
        break;
      case _NodeMenuAction.backward:
        widget.controller.moveSelectedLayer(-1);
        break;
      case _NodeMenuAction.back:
        widget.controller.sendSelectedToBack();
        break;
      case _NodeMenuAction.lock:
        widget.controller.setNodeLocked(node.id, !node.locked);
        break;
      case _NodeMenuAction.visibility:
        widget.controller.setNodeVisible(node.id, !node.visible);
        break;
      case _NodeMenuAction.delete:
        widget.controller.deleteSelected();
        break;
    }
  }

  void _handlePointerSignal(PointerSignalEvent signal) {
    if (signal is! PointerScrollEvent) return;

    GestureBinding.instance.pointerSignalResolver.register(signal, (event) {
      final scroll = event as PointerScrollEvent;
      final keyboard = HardwareKeyboard.instance;
      final primary =
          keyboard.isControlPressed || keyboard.isMetaPressed;

      if (primary) {
        final factor = scroll.scrollDelta.dy < 0 ? 1.12 : 1 / 1.12;
        _setZoom(_scale * factor, focalGlobal: scroll.position);
        return;
      }

      final matrix = _transform.value.clone();
      if (keyboard.isShiftPressed) {
        matrix.storage[12] -= scroll.scrollDelta.dy;
      } else {
        matrix.storage[13] -= scroll.scrollDelta.dy;
      }
      _transform.value = matrix;
    });
  }

  void _setZoom(double requested, {Offset? focalGlobal}) {
    final next = requested.clamp(.20, 4.0).toDouble();
    final render = _viewportKey.currentContext?.findRenderObject();
    if (render is! RenderBox) return;

    final focal = focalGlobal == null
        ? render.size.center(Offset.zero)
        : render.globalToLocal(focalGlobal);
    final scene = _transform.toScene(focal);

    final matrix = Matrix4.identity()
      ..setEntry(0, 0, next)
      ..setEntry(1, 1, next);
    matrix.storage[12] = focal.dx - scene.dx * next;
    matrix.storage[13] = focal.dy - scene.dy * next;
    _transform.value = matrix;
  }

  void _fitScreen() {
    final render = _viewportKey.currentContext?.findRenderObject();
    if (render is! RenderBox) return;

    final screen = widget.controller.activeScreen;
    const padding = 72.0;
    final widthScale = (render.size.width - padding) / screen.width;
    final heightScale = (render.size.height - padding) / screen.height;
    final scale = widthScale < heightScale ? widthScale : heightScale;
    final next = scale.clamp(.20, 4.0).toDouble();

    final matrix = Matrix4.identity()
      ..setEntry(0, 0, next)
      ..setEntry(1, 1, next);
    matrix.storage[12] = (render.size.width - screen.width * next) / 2;
    matrix.storage[13] = (render.size.height - screen.height * next) / 2;
    _transform.value = matrix;
  }
}

class _NodeView extends StatelessWidget {
  const _NodeView({
    required this.node,
    required this.selected,
    required this.primary,
    required this.scale,
    required this.onSelect,
    required this.onMoveStart,
    required this.onMove,
    required this.onMoveEnd,
    required this.onResizeStart,
    required this.onResize,
    required this.onResizeEnd,
    required this.onRotateGlobal,
    required this.onRotateEnd,
    required this.onContextMenu,
  });

  final UiNode node;
  final bool selected;
  final bool primary;
  final double scale;
  final ValueChanged<bool> onSelect;
  final VoidCallback onMoveStart;
  final void Function(double dx, double dy) onMove;
  final VoidCallback onMoveEnd;
  final VoidCallback onResizeStart;
  final void Function({
    required double dx,
    required double dy,
    required bool left,
    required bool right,
    required bool top,
    required bool bottom,
  }) onResize;
  final VoidCallback onResizeEnd;
  final ValueChanged<Offset> onRotateGlobal;
  final VoidCallback onRotateEnd;
  final ValueChanged<Offset> onContextMenu;

  bool get _additiveSelection {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: node.frame.x,
      top: node.frame.y,
      width: node.frame.width,
      height: node.frame.height,
      child: Transform.rotate(
        angle: node.rotation * math.pi / 180,
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(_additiveSelection),
          onSecondaryTapDown: (details) =>
              onContextMenu(details.globalPosition),
          onLongPressStart: (details) =>
              onContextMenu(details.globalPosition),
          onPanStart: node.locked
              ? null
              : (_) {
                  if (!selected) onSelect(_additiveSelection);
                  onMoveStart();
                },
          onPanUpdate: node.locked
              ? null
              : (details) => onMove(
                    details.delta.dx / scale,
                    details.delta.dy / scale,
                  ),
          onPanEnd: node.locked ? null : (_) => onMoveEnd(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: node.locked
                        ? const Color(0xFFEDEDED)
                        : const Color(0xFFF5F5F5),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black26,
                      width: selected ? 2 / scale : 1 / scale,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          (node.properties['text'] ?? node.name ?? node.type)
                              .toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (node.locked)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(Icons.lock, size: 14),
                        ),
                    ],
                  ),
                ),
              ),
              if (primary && !node.locked) ...[
                for (final handle in _ResizeHandle.values)
                  _ResizeGrip(
                    handle: handle,
                    scale: scale,
                    node: node,
                    onResizeStart: onResizeStart,
                    onResize: onResize,
                    onResizeEnd: onResizeEnd,
                  ),
                _RotationGrip(
                  scale: scale,
                  node: node,
                  onRotateGlobal: onRotateGlobal,
                  onRotateEnd: onRotateEnd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RotationGrip extends StatelessWidget {
  const _RotationGrip({
    required this.scale,
    required this.node,
    required this.onRotateGlobal,
    required this.onRotateEnd,
  });

  final double scale;
  final UiNode node;
  final ValueChanged<Offset> onRotateGlobal;
  final VoidCallback onRotateEnd;

  @override
  Widget build(BuildContext context) {
    final hitSize = 38 / scale;
    final visualSize = 14 / scale;
    final stem = 24 / scale;

    return Positioned(
      left: node.frame.width / 2 - hitSize / 2,
      top: -stem - hitSize,
      width: hitSize,
      height: hitSize + stem,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onRotateGlobal(details.globalPosition),
        onPanEnd: (_) => onRotateEnd(),
        child: Column(
          children: [
            Container(
              width: visualSize,
              height: visualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2 / scale,
                ),
              ),
            ),
            Container(
              width: 1 / scale,
              height: stem,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectionFrame extends StatelessWidget {
  const _MultiSelectionFrame({
    required this.bounds,
    required this.scale,
    required this.count,
  });

  final UiRect bounds;
  final double scale;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: bounds.x,
      top: bounds.y,
      width: bounds.width,
      height: bounds.height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary,
              width: 1.5 / scale,
            ),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(0, -24 / scale),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 / scale,
                  vertical: 2 / scale,
                ),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(
                  '$count selected',
                  style: TextStyle(fontSize: 10 / scale),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeGrip extends StatelessWidget {
  const _ResizeGrip({
    required this.handle,
    required this.scale,
    required this.node,
    required this.onResizeStart,
    required this.onResize,
    required this.onResizeEnd,
  });

  final _ResizeHandle handle;
  final double scale;
  final UiNode node;
  final VoidCallback onResizeStart;
  final void Function({
    required double dx,
    required double dy,
    required bool left,
    required bool right,
    required bool top,
    required bool bottom,
  }) onResize;
  final VoidCallback onResizeEnd;

  @override
  Widget build(BuildContext context) {
    final hitSize = 36 / scale;
    final visualSize = 12 / scale;

    final left = switch (handle.horizontal) {
      -1 => -hitSize / 2,
      0 => node.frame.width / 2 - hitSize / 2,
      _ => null,
    };
    final right = handle.horizontal == 1 ? -hitSize / 2 : null;
    final top = switch (handle.vertical) {
      -1 => -hitSize / 2,
      0 => node.frame.height / 2 - hitSize / 2,
      _ => null,
    };
    final bottom = handle.vertical == 1 ? -hitSize / 2 : null;

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: hitSize,
      height: hitSize,
      child: MouseRegion(
        cursor: handle.cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => onResizeStart(),
          onPanUpdate: (details) => onResize(
            dx: details.delta.dx / scale,
            dy: details.delta.dy / scale,
            left: handle.horizontal == -1,
            right: handle.horizontal == 1,
            top: handle.vertical == -1,
            bottom: handle.vertical == 1,
          ),
          onPanEnd: (_) => onResizeEnd(),
          child: Center(
            child: Container(
              width: visualSize,
              height: visualSize,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2 / scale,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _NodeMenuAction {
  copy,
  paste,
  duplicate,
  front,
  forward,
  backward,
  back,
  lock,
  visibility,
  delete,
}

enum _ResizeHandle {
  topLeft(-1, -1, SystemMouseCursors.resizeUpLeftDownRight),
  top(0, -1, SystemMouseCursors.resizeUpDown),
  topRight(1, -1, SystemMouseCursors.resizeUpRightDownLeft),
  right(1, 0, SystemMouseCursors.resizeLeftRight),
  bottomRight(1, 1, SystemMouseCursors.resizeUpLeftDownRight),
  bottom(0, 1, SystemMouseCursors.resizeUpDown),
  bottomLeft(-1, 1, SystemMouseCursors.resizeUpRightDownLeft),
  left(-1, 0, SystemMouseCursors.resizeLeftRight);

  const _ResizeHandle(this.horizontal, this.vertical, this.cursor);

  final int horizontal;
  final int vertical;
  final MouseCursor cursor;
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.step});

  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x12000000)
      ..strokeWidth = .75;

    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.step != step;
}

class _CenterGuidePainter extends CustomPainter {
  const _CenterGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x335A67D8)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
