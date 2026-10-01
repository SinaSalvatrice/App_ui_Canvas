import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../editor_controller.dart';

class LayersPanel extends StatelessWidget {
  const LayersPanel({
    required this.controller,
    super.key,
  });

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final nodes = controller.activeScreen.nodes;
    if (nodes.isEmpty) {
      return const Center(child: Text('No elements yet.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Wrap(
            spacing: 2,
            children: [
              IconButton(
                tooltip: 'Bring to front',
                onPressed: controller.selectedCount == 0
                    ? null
                    : controller.bringSelectedToFront,
                icon: const Icon(Icons.vertical_align_top),
              ),
              IconButton(
                tooltip: 'Bring forward',
                onPressed: controller.selectedCount == 0
                    ? null
                    : () => controller.moveSelectedLayer(1),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Send backward',
                onPressed: controller.selectedCount == 0
                    ? null
                    : () => controller.moveSelectedLayer(-1),
                icon: const Icon(Icons.arrow_downward),
              ),
              IconButton(
                tooltip: 'Send to back',
                onPressed: controller.selectedCount == 0
                    ? null
                    : controller.sendSelectedToBack,
                icon: const Icon(Icons.vertical_align_bottom),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              for (final node in nodes.reversed)
                ListTile(
                  dense: true,
                  selected: controller.isSelected(node.id),
                  leading: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: node.visible ? 'Hide' : 'Show',
                    onPressed: () =>
                        controller.setNodeVisible(node.id, !node.visible),
                    icon: Icon(
                      node.visible ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    node.name ?? node.type,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(node.id),
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: node.locked ? 'Unlock' : 'Lock',
                    onPressed: () =>
                        controller.setNodeLocked(node.id, !node.locked),
                    icon: Icon(
                      node.locked ? Icons.lock : Icons.lock_open,
                      size: 17,
                    ),
                  ),
                  onTap: () {
                    final keyboard = HardwareKeyboard.instance;
                    final additive =
                        keyboard.isControlPressed || keyboard.isMetaPressed;
                    controller.selectNode(
                      node.id,
                      additive: additive,
                      toggle: additive,
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
