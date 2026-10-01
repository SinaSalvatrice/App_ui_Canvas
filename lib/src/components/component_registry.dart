import '../model/ui_rect.dart';
import '../platform/designer_target.dart';
import 'component_definition.dart';

class ComponentRegistry {
  static List<ComponentDefinition> forTarget(DesignerTarget target) {
    const shared = <ComponentDefinition>[
      ComponentDefinition(
        type: 'text',
        label: 'Text',
        category: 'Basic',
        defaultFrame: UiRect(x: 40, y: 40, width: 180, height: 40),
        defaultProperties: {'text': 'Text'},
      ),
      ComponentDefinition(
        type: 'image',
        label: 'Image',
        category: 'Basic',
        defaultFrame: UiRect(x: 40, y: 100, width: 220, height: 160),
      ),
      ComponentDefinition(
        type: 'container',
        label: 'Container',
        category: 'Layout',
        defaultFrame: UiRect(x: 40, y: 280, width: 300, height: 180),
      ),
      ComponentDefinition(
        type: 'textField',
        label: 'Text field',
        category: 'Input',
        defaultFrame: UiRect(x: 40, y: 480, width: 260, height: 52),
      ),
      ComponentDefinition(
        type: 'switch',
        label: 'Switch',
        category: 'Input',
        defaultFrame: UiRect(x: 40, y: 550, width: 120, height: 48),
      ),
      ComponentDefinition(
        type: 'slider',
        label: 'Slider',
        category: 'Input',
        defaultFrame: UiRect(x: 40, y: 620, width: 260, height: 48),
      ),
    ];

    final specific = switch (target) {
      DesignerTarget.windows => const <ComponentDefinition>[
          ComponentDefinition(
            type: 'button',
            label: 'Button',
            category: 'Windows',
            defaultFrame: UiRect(x: 360, y: 40, width: 140, height: 40),
            defaultProperties: {'text': 'Button'},
          ),
          ComponentDefinition(
            type: 'menuBar',
            label: 'Menu bar',
            category: 'Windows',
            defaultFrame: UiRect(x: 0, y: 0, width: 1280, height: 40),
          ),
          ComponentDefinition(
            type: 'navigationRail',
            label: 'Navigation rail',
            category: 'Windows',
            defaultFrame: UiRect(x: 0, y: 40, width: 220, height: 680),
          ),
          ComponentDefinition(
            type: 'splitView',
            label: 'Split view',
            category: 'Windows',
            defaultFrame: UiRect(x: 240, y: 80, width: 760, height: 520),
          ),
          ComponentDefinition(
            type: 'contextMenu',
            label: 'Context menu',
            category: 'Windows',
            defaultFrame: UiRect(x: 360, y: 100, width: 220, height: 200),
          ),
        ],
      DesignerTarget.android => const <ComponentDefinition>[
          ComponentDefinition(
            type: 'filledButton',
            label: 'Filled button',
            category: 'Android',
            defaultFrame: UiRect(x: 24, y: 100, width: 160, height: 48),
            defaultProperties: {'text': 'Button'},
          ),
          ComponentDefinition(
            type: 'appBar',
            label: 'App bar',
            category: 'Android',
            defaultFrame: UiRect(x: 0, y: 0, width: 412, height: 64),
          ),
          ComponentDefinition(
            type: 'bottomNavigation',
            label: 'Bottom navigation',
            category: 'Android',
            defaultFrame: UiRect(x: 0, y: 835, width: 412, height: 80),
          ),
          ComponentDefinition(
            type: 'navigationDrawer',
            label: 'Navigation drawer',
            category: 'Android',
            defaultFrame: UiRect(x: 0, y: 0, width: 300, height: 915),
          ),
          ComponentDefinition(
            type: 'floatingActionButton',
            label: 'Floating action button',
            category: 'Android',
            defaultFrame: UiRect(x: 332, y: 755, width: 56, height: 56),
          ),
          ComponentDefinition(
            type: 'bottomSheet',
            label: 'Bottom sheet',
            category: 'Android',
            defaultFrame: UiRect(x: 0, y: 615, width: 412, height: 300),
          ),
        ],
    };
    return [...shared, ...specific];
  }
}
