import 'ui_rect.dart';

class UiNode {
  const UiNode({
    required this.id,
    required this.type,
    required this.frame,
    this.name,
    this.properties = const {},
    this.children = const [],
  });

  final String id;
  final String type;
  final String? name;
  final UiRect frame;
  final Map<String, Object?> properties;
  final List<UiNode> children;

  UiNode copyWith({UiRect? frame, Map<String, Object?>? properties}) => UiNode(
        id: id,
        type: type,
        name: name,
        frame: frame ?? this.frame,
        properties: properties ?? this.properties,
        children: children,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type,
        if (name != null) 'name': name,
        'frame': frame.toJson(),
        'properties': properties,
        'children': children.map((node) => node.toJson()).toList(),
      };

  factory UiNode.fromJson(Map<String, Object?> json) => UiNode(
        id: json['id']! as String,
        type: json['type']! as String,
        name: json['name'] as String?,
        frame: UiRect.fromJson(json['frame']! as Map<String, Object?>),
        properties: Map<String, Object?>.from(
          (json['properties'] as Map?) ?? const {},
        ),
        children: ((json['children'] as List?) ?? const [])
            .map((item) => UiNode.fromJson(Map<String, Object?>.from(item as Map)))
            .toList(),
      );
}
