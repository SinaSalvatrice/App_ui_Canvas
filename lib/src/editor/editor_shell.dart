import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/component_definition.dart';
import '../components/component_registry.dart';
import '../model/screen_preset.dart';
import '../model/ui_screen.dart';
import '../platform/designer_target.dart';
import 'canvas_view.dart';
import 'editor_controller.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/layers_panel.dart';

class EditorShell extends StatelessWidget {
  const EditorShell({
    required this.target,
    required this.controller,
    required this.onNewProject,
    required this.onOpenProject,
    required this.onOpenRecentProject,
    required this.onSaveProject,
    required this.onSaveProjectAs,
    this.projectPath,
    this.recentProjects = const [],
    super.key,
  });

  final DesignerTarget target;
  final EditorController controller;
  final String? projectPath;
  final List<String> recentProjects;
  final Future<void> Function() onNewProject;
  final Future<void> Function() onOpenProject;
  final Future<void> Function(String path) onOpenRecentProject;
  final Future<void> Function() onSaveProject;
  final Future<void> Function() onSaveProjectAs;

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
              projectPath: projectPath,
              recentProjects: recentProjects,
              onNewProject: onNewProject,
              onOpenProject: onOpenProject,
              onOpenRecentProject: onOpenRecentProject,
              onSaveProject: onSaveProject,
              onSaveProjectAs: onSaveProjectAs,
            ),
          DesignerTarget.android => _AndroidDesigner(
              controller: controller,
              components: components,
              projectPath: projectPath,
              recentProjects: recentProjects,
              onNewProject: onNewProject,
              onOpenProject: onOpenProject,
              onOpenRecentProject: onOpenRecentProject,
              onSaveProject: onSaveProject,
              onSaveProjectAs: onSaveProjectAs,
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
    required this.projectPath,
    required this.recentProjects,
    required this.onNewProject,
    required this.onOpenProject,
    required this.onOpenRecentProject,
    required this.onSaveProject,
    required this.onSaveProjectAs,
  });

  final EditorController controller;
  final List<ComponentDefinition> components;
  final String? projectPath;
  final List<String> recentProjects;
  final Future<void> Function() onNewProject;
  final Future<void> Function() onOpenProject;
  final Future<void> Function(String path) onOpenRecentProject;
  final Future<void> Function() onSaveProject;
  final Future<void> Function() onSaveProjectAs;

  void _nudgeIfCanvasFocused(double dx, double dy) {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final editing =
        focusContext?.findAncestorWidgetOfExactType<EditableText>() != null;
    if (editing) return;
    controller.nudgeSelected(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            () => onNewProject(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            () => onOpenProject(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            () => onSaveProject(),
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          control: true,
          shift: true,
        ): () => onSaveProjectAs(),
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
                _DesktopTopBar(
                  controller: controller,
                  projectPath: projectPath,
                  recentProjects: recentProjects,
                  onNewProject: onNewProject,
                  onOpenProject: onOpenProject,
                  onOpenRecentProject: onOpenRecentProject,
                  onSaveProject: onSaveProject,
                  onSaveProjectAs: onSaveProjectAs,
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 230,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 210,
                              child: ScreensPanel(controller: controller),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: _ComponentLibrary(
                                components: components,
                                onAdd: controller.addComponent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: CanvasView(
                          key: ValueKey(controller.activeScreenId),
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
    required this.projectPath,
    required this.recentProjects,
    required this.onNewProject,
    required this.onOpenProject,
    required this.onOpenRecentProject,
    required this.onSaveProject,
    required this.onSaveProjectAs,
  });

  final EditorController controller;
  final List<ComponentDefinition> components;
  final String? projectPath;
  final List<String> recentProjects;
  final Future<void> Function() onNewProject;
  final Future<void> Function() onOpenProject;
  final Future<void> Function(String path) onOpenRecentProject;
  final Future<void> Function() onSaveProject;
  final Future<void> Function() onSaveProjectAs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => _renameProjectDialog(context, controller),
          child: Tooltip(
            message: projectPath ?? 'Unsaved project',
            child: Text(
              controller.isDirty
                  ? '${controller.project.name} •'
                  : controller.project.name,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: () => onSaveProject(),
            icon: const Icon(Icons.save_outlined),
          ),
          IconButton(
            tooltip: 'Recent projects',
            onPressed: recentProjects.isEmpty
                ? null
                : () => _showRecentProjects(
                      context,
                      recentProjects,
                      onOpenRecentProject,
                    ),
            icon: const Icon(Icons.history),
          ),
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
          PopupMenuButton<_ProjectMenuAction>(
            tooltip: 'Project',
            onSelected: (action) {
              switch (action) {
                case _ProjectMenuAction.newProject:
                  onNewProject();
                  break;
                case _ProjectMenuAction.open:
                  onOpenProject();
                  break;
                case _ProjectMenuAction.saveAs:
                  onSaveProjectAs();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ProjectMenuAction.newProject,
                child: Text('New project'),
              ),
              PopupMenuItem(
                value: _ProjectMenuAction.open,
                child: Text('Open project'),
              ),
              PopupMenuItem(
                value: _ProjectMenuAction.saveAs,
                child: Text('Save as'),
              ),
            ],
          ),
        ],
      ),
      body: CanvasView(
        key: ValueKey(controller.activeScreenId),
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
                icon: Icons.dashboard_outlined,
                label: 'Screens',
                onTap: () => _showSheet(
                  context,
                  title: 'Screens',
                  child: ScreensPanel(controller: controller),
                ),
              ),
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
  const _DesktopTopBar({
    required this.controller,
    required this.projectPath,
    required this.recentProjects,
    required this.onNewProject,
    required this.onOpenProject,
    required this.onOpenRecentProject,
    required this.onSaveProject,
    required this.onSaveProjectAs,
  });

  final EditorController controller;
  final String? projectPath;
  final List<String> recentProjects;
  final Future<void> Function() onNewProject;
  final Future<void> Function() onOpenProject;
  final Future<void> Function(String path) onOpenRecentProject;
  final Future<void> Function() onSaveProject;
  final Future<void> Function() onSaveProjectAs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Text(
              'App UI Canvas',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            const Chip(label: Text('Windows')),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'New (Ctrl+N)',
              onPressed: () => onNewProject(),
              icon: const Icon(Icons.note_add_outlined),
            ),
            IconButton(
              tooltip: 'Open (Ctrl+O)',
              onPressed: () => onOpenProject(),
              icon: const Icon(Icons.folder_open),
            ),
            PopupMenuButton<String>(
              tooltip: 'Recent projects',
              enabled: recentProjects.isNotEmpty,
              icon: const Icon(Icons.history),
              onSelected: onOpenRecentProject,
              itemBuilder: (context) => [
                for (final path in recentProjects)
                  PopupMenuItem(
                    value: path,
                    child: Tooltip(
                      message: path,
                      child: Text(
                        _fileName(path),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              tooltip: 'Save (Ctrl+S)',
              onPressed: () => onSaveProject(),
              icon: const Icon(Icons.save_outlined),
            ),
            PopupMenuButton<_SaveMenuAction>(
              tooltip: 'Save options',
              onSelected: (action) {
                if (action == _SaveMenuAction.saveAs) {
                  onSaveProjectAs();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _SaveMenuAction.saveAs,
                  child: Text('Save as…  Ctrl+Shift+S'),
                ),
              ],
            ),
            const VerticalDivider(indent: 12, endIndent: 12),
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
            Tooltip(
              message: projectPath ?? 'Unsaved project',
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _renameProjectDialog(context, controller),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    controller.isDirty
                        ? '${controller.project.name} •'
                        : controller.project.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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

class ScreensPanel extends StatelessWidget {
  const ScreensPanel({
    required this.controller,
    super.key,
  });

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
          child: Row(
            children: [
              Text('Screens', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              IconButton(
                tooltip: 'Duplicate screen',
                visualDensity: VisualDensity.compact,
                onPressed: controller.duplicateActiveScreen,
                icon: const Icon(Icons.copy_outlined, size: 18),
              ),
              PopupMenuButton<ScreenPreset>(
                tooltip: 'Resize active screen',
                icon: const Icon(Icons.aspect_ratio, size: 18),
                onSelected: controller.applyScreenPreset,
                itemBuilder: (context) => [
                  for (final preset
                      in ScreenPreset.forTarget(controller.project.target))
                    PopupMenuItem(
                      value: preset,
                      child: Text('Resize: ${preset.label}'),
                    ),
                ],
              ),
              PopupMenuButton<ScreenPreset>(
                tooltip: 'Add screen',
                icon: const Icon(Icons.add, size: 20),
                onSelected: controller.addScreen,
                itemBuilder: (context) => [
                  for (final preset
                      in ScreenPreset.forTarget(controller.project.target))
                    PopupMenuItem(
                      value: preset,
                      child: Text(preset.label),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            children: [
              for (final screen in controller.project.screens)
                _ScreenTile(controller: controller, screen: screen),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScreenTile extends StatelessWidget {
  const _ScreenTile({
    required this.controller,
    required this.screen,
  });

  final EditorController controller;
  final UiScreen screen;

  @override
  Widget build(BuildContext context) {
    final active = controller.activeScreenId == screen.id;
    final initial = controller.project.initialScreenId == screen.id;

    return ListTile(
      dense: true,
      selected: active,
      leading: Icon(
        initial ? Icons.home_filled : Icons.crop_portrait,
        size: 18,
      ),
      title: Text(
        screen.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${screen.width.toInt()} × ${screen.height.toInt()}',
      ),
      onTap: () => controller.selectScreen(screen.id),
      onLongPress: () => _rename(context),
      trailing: PopupMenuButton<_ScreenMenuAction>(
        onSelected: (action) {
          switch (action) {
            case _ScreenMenuAction.rename:
              _rename(context);
              break;
            case _ScreenMenuAction.duplicate:
              controller.selectScreen(screen.id);
              controller.duplicateActiveScreen();
              break;
            case _ScreenMenuAction.makeStart:
              controller.setInitialScreen(screen.id);
              break;
            case _ScreenMenuAction.delete:
              controller.deleteScreen(screen.id);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _ScreenMenuAction.rename,
            child: Text('Rename'),
          ),
          const PopupMenuItem(
            value: _ScreenMenuAction.duplicate,
            child: Text('Duplicate'),
          ),
          PopupMenuItem(
            value: _ScreenMenuAction.makeStart,
            enabled: !initial,
            child: const Text('Make start screen'),
          ),
          PopupMenuItem(
            value: _ScreenMenuAction.delete,
            enabled: controller.project.screens.length > 1,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final textController = TextEditingController(text: screen.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename screen'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(textController.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (name != null) {
      controller.renameScreen(screen.id, name);
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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

enum _SaveMenuAction { saveAs }

enum _ProjectMenuAction {
  newProject,
  open,
  saveAs,
}

enum _ScreenMenuAction {
  rename,
  duplicate,
  makeStart,
  delete,
}


Future<void> _renameProjectDialog(
  BuildContext context,
  EditorController controller,
) async {
  final textController =
      TextEditingController(text: controller.project.name);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename project'),
      content: TextField(
        controller: textController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Project name'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(textController.text),
          child: const Text('Rename'),
        ),
      ],
    ),
  );
  textController.dispose();
  if (name != null) {
    controller.renameProject(name);
  }
}


Future<void> _showRecentProjects(
  BuildContext context,
  List<String> paths,
  Future<void> Function(String path) onOpen,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Text(
              'Recent projects',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final path in paths)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(_fileName(path)),
              subtitle: Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(context).pop();
                onOpen(path);
              },
            ),
        ],
      ),
    ),
  );
}

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1);
}
