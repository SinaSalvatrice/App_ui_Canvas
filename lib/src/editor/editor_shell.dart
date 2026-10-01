import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/component_definition.dart';
import '../components/component_registry.dart';
import '../platform/designer_target.dart';
import 'canvas_view.dart';
import 'editor_controller.dart';

class EditorShell extends StatelessWidget {
  const EditorShell({
    required this.target,
    required this.controller,
    super.key,
  });

  final DesignerTarget target;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final components = ComponentRegistry.forTarget(target);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return switch (target) {
          DesignerTarget.windows => _WindowsDesigner(
              controller: controller,
              components: components,
            ),
          DesignerTarget.android => _AndroidDesigner(
              controller: controller,
              components: components,
            ),
        };
      },
    );
  }
}

class _WindowsDesigner extends StatelessWidget {
  const _WindowsDesigner({
    required this.controller,
    required this.components,
  });

  final EditorController controller;
  final List<ComponentDefinition> components;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true):
            controller.redo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): controller.redo,
        const SingleActivator(LogicalKeyboardKey.delete):
            controller.deleteSelected,
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            controller.duplicateSelected,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _DesktopTopBar(controller: controller),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 220,
                        child: _ComponentLibrary(
                          components: components,
                          onAdd: controller.addComponent,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: CanvasView(
                          controller: controller,
                          target: DesignerTarget.windows,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: 280,
                        child: _RightPanel(controller: controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AndroidDesigner extends StatelessWidget {
  const _AndroidDesigner({
    required this.controller,
    required this.components,
  });

  final EditorController controller;
  final List<ComponentDefinition> components;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('App UI Designer'),
            if (controller.isDirty) ...[
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: controller.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: controller.canRedo ? controller.redo : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Preview',
            onPressed: null,
            icon: const Icon(Icons.play_arrow),
          ),
        ],
      ),
      body: CanvasView(
        controller: controller,
        target: DesignerTarget.android,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomTool(
                icon: Icons.add_box_outlined,
                label: 'Components',
                onTap: () => _showSheet(
                  context,
                  title: 'Components',
                  child: _ComponentLibrary(
                    components: components,
                    onAdd: (component) {
                      controller.addComponent(component);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              _BottomTool(
                icon: Icons.layers_outlined,
                label: 'Layers',
                onTap: () => _showSheet(
                  context,
                  title: 'Layers',
                  child: _Layers(controller: controller),
                ),
              ),
              _BottomTool(
                icon: Icons.tune,
                label: 'Inspector',
                onTap: () => _showSheet(
                  context,
                  title: 'Inspector',
                  child: _Inspector(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSheet(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Text(
              'App UI Canvas',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 14),
            const Chip(label: Text('Windows')),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Undo',
              onPressed: controller.canUndo ? controller.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: controller.canRedo ? controller.redo : null,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: 'Duplicate',
              onPressed:
                  controller.selectedCount == 0 ? null : controller.duplicateSelected,
              icon: const Icon(Icons.copy_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed:
                  controller.selectedCount == 0 ? null : controller.deleteSelected,
              icon: const Icon(Icons.delete_outline),
            ),
            const Spacer(),
            Text(
              controller.isDirty
                  ? '${controller.project.name} •'
                  : controller.project.name,
            ),
            const SizedBox(width: 12),
            const OutlinedButton(
              onPressed: null,
              child: Text('Preview'),
            ),
            const SizedBox(width: 8),
            const FilledButton(
              onPressed: null,
              child: Text('Export shell'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTool extends StatelessWidget {
  const _BottomTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ComponentLibrary extends StatelessWidget {
  const _ComponentLibrary({
    required this.components,
    required this.onAdd,
  });

  final List<ComponentDefinition> components;
  final ValueChanged<ComponentDefinition> onAdd;

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<ComponentDefinition>>{};
    for (final component in components) {
      categories.putIfAbsent(component.category, () => []).add(component);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Components', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final entry in categories.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final component in entry.value)
            ListTile(
              dense: true,
              leading: const Icon(Icons.widgets_outlined, size: 18),
              title: Text(component.label),
              onTap: () => onAdd(component),
            ),
        ],
      ],
    );
  }
}

class _RightPanel extends StatefulWidget {
  const _RightPanel({required this.controller});

  final EditorController controller;

  @override
  State<_RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<_RightPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Inspector'),
              icon: Icon(Icons.tune, size: 17),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Layers'),
              icon: Icon(Icons.layers_outlined, size: 17),
            ),
          ],
          selected: {_tab},
          onSelectionChanged: (selection) {
            setState(() => _tab = selection.first);
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: _tab == 0
              ? _Inspector(controller: widget.controller)
              : _Layers(controller: widget.controller),
        ),
      ],
    );
  }
}

class _Layers extends StatelessWidget {
  const _Layers({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final nodes = controller.activeScreen.nodes;
    if (nodes.isEmpty) {
      return const Center(child: Text('No elements yet.'));
    }

    return ListView(
      children: [
        for (final node in nodes.reversed)
          ListTile(
            leading: Icon(
              controller.isSelected(node.id)
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              size: 19,
            ),
            title: Text(node.name ?? node.type),
            subtitle: Text(node.id),
            selected: controller.isSelected(node.id),
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
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({required this.controller});

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (controller.selectedCount > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Chip(
              label: Text('${controller.selectedCount} selected'),
            ),
          ),
        Text(
          node.name ?? node.type,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text('ID: ${node.id}'),
        Text('Type: ${node.type}'),
        const Divider(),
        Text('X: ${node.frame.x.toStringAsFixed(0)}'),
        Text('Y: ${node.frame.y.toStringAsFixed(0)}'),
        Text('W: ${node.frame.width.toStringAsFixed(0)}'),
        Text('H: ${node.frame.height.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        const Text(
          'Editable numeric controls are the next inspector step.',
        ),
      ],
    );
  }
}
