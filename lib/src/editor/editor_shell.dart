import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/component_definition.dart';
import '../components/component_registry.dart';
import '../platform/designer_target.dart';
import 'canvas_view.dart';
import 'editor_controller.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/layers_panel.dart';

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

  void _nudgeIfCanvasFocused(double dx, double dy) {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final editing = focusContext?.findAncestorWidgetOfExactType<EditableText>() != null;
    if (editing) return;
    controller.nudgeSelected(dx, dy);
  }

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
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            controller.copySelected,
        const SingleActivator(LogicalKeyboardKey.keyX, control: true):
            controller.cutSelected,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true):
            controller.pasteClipboard,
        const SingleActivator(LogicalKeyboardKey.delete):
            controller.deleteSelected,
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            controller.duplicateSelected,
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            controller.selectAll,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            () => _nudgeIfCanvasFocused(-1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            () => _nudgeIfCanvasFocused(1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            () => _nudgeIfCanvasFocused(0, -1),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            () => _nudgeIfCanvasFocused(0, 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
            () => _nudgeIfCanvasFocused(-10, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
            () => _nudgeIfCanvasFocused(10, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            () => _nudgeIfCanvasFocused(0, -10),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            () => _nudgeIfCanvasFocused(0, 10),
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
                        width: 300,
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
            const Text('App UI Canvas'),
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
            tooltip: 'Paste',
            onPressed: controller.canPaste ? controller.pasteClipboard : null,
            icon: const Icon(Icons.paste),
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
                  child: LayersPanel(controller: controller),
                ),
              ),
              _BottomTool(
                icon: Icons.tune,
                label: 'Inspector',
                onTap: () => _showSheet(
                  context,
                  title: 'Inspector',
                  child: InspectorPanel(controller: controller),
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
      builder: (context) => FractionallySizedBox(
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
      ),
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
              tooltip: 'Copy',
              onPressed:
                  controller.selectedCount == 0 ? null : controller.copySelected,
              icon: const Icon(Icons.copy),
            ),
            IconButton(
              tooltip: 'Paste',
              onPressed: controller.canPaste ? controller.pasteClipboard : null,
              icon: const Icon(Icons.paste),
            ),
            IconButton(
              tooltip: 'Duplicate',
              onPressed: controller.selectedCount == 0
                  ? null
                  : controller.duplicateSelected,
              icon: const Icon(Icons.copy_all),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: controller.selectedCount == 0
                  ? null
                  : controller.deleteSelected,
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
              ? InspectorPanel(controller: widget.controller)
              : LayersPanel(controller: widget.controller),
        ),
      ],
    );
  }
}
