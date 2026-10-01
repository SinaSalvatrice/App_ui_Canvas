import '../model/ui_rect.dart';

class ComponentDefinition {
  const ComponentDefinition({
    required this.type,
    required this.label,
    required this.category,
    required this.defaultFrame,
    this.defaultProperties = const {},
  });

  final String type;
  final String label;
  final String category;
  final UiRect defaultFrame;
  final Map<String, Object?> defaultProperties;
}
