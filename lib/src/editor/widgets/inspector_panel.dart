import 'package:flutter/material.dart';

import '../../model/ui_node.dart';
import '../editor_controller.dart';
import 'wheel_number_field.dart';

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({
    required this.controller,
    super.key,
  });

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final node = controller.selectedNode;
    if (node == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Select an element to edit its properties.'),
      );
    }

    final editable = !node.locked;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (controller.selectedCount > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Chip(
              label: Text('${controller.selectedCount} selected'),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                node.name ?? node.type,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: node.visible ? 'Hide' : 'Show',
              onPressed: () =>
                  controller.setNodeVisible(node.id, !node.visible),
              icon: Icon(
                node.visible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            IconButton(
              tooltip: node.locked ? 'Unlock' : 'Lock',
              onPressed: () =>
                  controller.setNodeLocked(node.id, !node.locked),
              icon: Icon(
                node.locked ? Icons.lock : Icons.lock_open,
              ),
            ),
          ],
        ),
        Text(node.id, style: Theme.of(context).textTheme.labelSmall),
        const Divider(height: 24),
        Text('Geometry', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: WheelNumberField(
                label: 'X',
                value: node.frame.x,
                enabled: editable,
                onChanged: (value) => controller.updatePrimaryFrame(x: value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WheelNumberField(
                label: 'Y',
                value: node.frame.y,
                enabled: editable,
                onChanged: (value) => controller.updatePrimaryFrame(y: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: WheelNumberField(
                label: 'Width',
                value: node.frame.width,
                min: 24,
                enabled: editable,
                onChanged: (value) =>
                    controller.updatePrimaryFrame(width: value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WheelNumberField(
                label: 'Height',
                value: node.frame.height,
                min: 24,
                enabled: editable,
                onChanged: (value) =>
                    controller.updatePrimaryFrame(height: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WheelNumberField(
          label: 'Rotation',
          value: node.rotation,
          min: 0,
          max: 359,
          enabled: editable,
          onChanged: controller.updatePrimaryRotation,
        ),
        const SizedBox(height: 14),
        Text('Align', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _AlignButton(
              tooltip: 'Align left',
              icon: Icons.align_horizontal_left,
              onPressed: () =>
                  controller.alignSelected(EditorAlignment.left),
            ),
            _AlignButton(
              tooltip: 'Center horizontally',
              icon: Icons.align_horizontal_center,
              onPressed: () =>
                  controller.alignSelected(EditorAlignment.horizontalCenter),
            ),
            _AlignButton(
              tooltip: 'Align right',
              icon: Icons.align_horizontal_right,
              onPressed: () =>
                  controller.alignSelected(EditorAlignment.right),
            ),
            _AlignButton(
              tooltip: 'Align top',
              icon: Icons.align_vertical_top,
              onPressed: () =>
                  controller.alignSelected(EditorAlignment.top),
            ),
            _AlignButton(
              tooltip: 'Center vertically',
              icon: Icons.align_vertical_center,
              onPressed: () =>
                  controller.alignSelected(EditorAlignment.verticalCenter),
            ),
            _AlignButton(
              tooltip: 'Align bottom',
              icon: Icons.align_vertical_bottom,
              onPressed: () =>
                  controller.alignSelected(EditorAlignment.bottom),
            ),
          ],
        ),
        if (node.properties.containsKey('text')) ...[
          const Divider(height: 26),
          Text('Content', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('text-${node.id}-${node.properties['text']}'),
            initialValue: (node.properties['text'] ?? '').toString(),
            enabled: editable,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Text',
              border: OutlineInputBorder(),
            ),
            onFieldSubmitted: (value) =>
                controller.updatePrimaryProperty('text', value),
          ),
        ],
        const Divider(height: 26),
        _NodeActions(controller: controller, node: node),
      ],
    );
  }
}

class _AlignButton extends StatelessWidget {
  const _AlignButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}

class _NodeActions extends StatelessWidget {
  const _NodeActions({
    required this.controller,
    required this.node,
  });

  final EditorController controller;
  final UiNode node;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: controller.copySelected,
          icon: const Icon(Icons.copy, size: 17),
          label: const Text('Copy'),
        ),
        OutlinedButton.icon(
          onPressed: controller.duplicateSelected,
          icon: const Icon(Icons.copy_all, size: 17),
          label: const Text('Duplicate'),
        ),
        OutlinedButton.icon(
          onPressed: node.locked ? null : controller.deleteSelected,
          icon: const Icon(Icons.delete_outline, size: 17),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}
