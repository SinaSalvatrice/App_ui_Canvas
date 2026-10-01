import 'ui_rect.dart';

class UiNode {
  const UiNode({
    required this.id,
    required this.type,
    required this.frame,
    this.name,
    this.rotation = 0,
    this.visible = true,
    this.locked = false,
    this.properties = const {},
    this.children = const [],
  });

  final String id;
  final String type;
  final String? name;
  final UiRect frame;
  final double rotation;
  final bool visible;
  final bool locked;
  final Map<String, Object?> properties;
  final List<UiNode> children;

  UiNode copyWith({
    String? name,
    UiRect? frame,
    double? rotation,
    bool? visible,
    bool? locked,
    Map<String, Object?>? properties,
    List<UiNode>? children,
  }) {
    return UiNode(
      id: id,
      type: type,
      name: name ?? this.name,
      frame: frame ?? this.frame,
      rotation: rotation ?? this.rotation,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      properties: properties ?? this.properties,
      children: children ?? this.children,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type,
        if (name != null) 'name': name,
        'frame': frame.toJson(),
        'rotation': rotation,
        'visible': visible,
        'locked': locked,
        'properties': properties,
        'children': children.map((node) => node.toJson()).toList(),
      };

  factory UiNode.fromJson(Map<String, Object?> json) => UiNode(
        id: json['id']! as String,
        type: json['type']! as String,
        name: json['name'] as String?,
        frame: UiRect.fromJson(json['frame']! as Map<String, Object?>),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        visible: json['visible'] as bool? ?? true,
        locked: json['locked'] as bool? ?? false,
        properties: Map<String, Object?>.from(
          (json['properties'] as Map?) ?? const {},
        ),
        children: ((json['children'] as List?) ?? const [])
            .map(
              (item) => UiNode.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
      );
}
