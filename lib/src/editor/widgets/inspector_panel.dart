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
