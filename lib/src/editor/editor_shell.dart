import 'package:flutter/material.dart';

import '../components/component_definition.dart';
import '../components/component_registry.dart';
import '../model/ui_node.dart';
import '../platform/designer_target.dart';
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
    return Scaffold(
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
                  Expanded(child: _Canvas(controller: controller)),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 260,
                    child: _Inspector(controller: controller),
                  ),
                ],
              ),
            ),
          ],
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
        title: const Text('App UI Designer'),
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: null,
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Export shell',
            onPressed: null,
            icon: const Icon(Icons.output),
          ),
        ],
      ),
      body: _Canvas(controller: controller),
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
              'App UI Designer',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 16),
            const Chip(label: Text('Windows designer')),
            const Spacer(),
            Text(controller.project.name),
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
            leading: const Icon(Icons.layers_outlined),
            title: Text(node.name ?? node.type),
            subtitle: Text(node.id),
            selected: node.id == controller.selectedNodeId,
            onTap: () => controller.selectNode(node.id),
          ),
      ],
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final screen = controller.activeScreen;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: InteractiveViewer(
        minScale: 0.25,
        maxScale: 3,
        boundaryMargin: const EdgeInsets.all(800),
        constrained: false,
        child: Center(
          child: Container(
            width: screen.width,
            height: screen.height,
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
                for (final node in screen.nodes)
                  _NodeView(
                    node: node,
                    selected: node.id == controller.selectedNodeId,
                    onSelect: () => controller.selectNode(node.id),
                    onMove: (dx, dy) => controller.moveNode(node.id, dx, dy),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeView extends StatelessWidget {
  const _NodeView({
    required this.node,
    required this.selected,
    required this.onSelect,
    required this.onMove,
  });

  final UiNode node;
  final bool selected;
  final VoidCallback onSelect;
  final void Function(double dx, double dy) onMove;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: node.frame.x,
      top: node.frame.y,
      width: node.frame.width,
      height: node.frame.height,
      child: GestureDetector(
        onTap: onSelect,
        onPanStart: (_) => onSelect(),
        onPanUpdate: (details) => onMove(
          details.delta.dx,
          details.delta.dy,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border.all(
              color: selected ? Colors.blue : Colors.black26,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              (node.properties['text'] ?? node.name ?? node.type).toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
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
      ],
    );
  }
}
