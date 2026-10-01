import '../platform/designer_target.dart';
import 'ui_node.dart';

class UiScreen {
  const UiScreen({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    this.nodes = const [],
  });

  final String id;
  final String name;
  final double width;
  final double height;
  final List<UiNode> nodes;

  factory UiScreen.empty({
    required String id,
    required String name,
    required DesignerTarget target,
  }) {
    return switch (target) {
      DesignerTarget.windows => UiScreen(
          id: id,
          name: name,
          width: 1280,
          height: 720,
        ),
      DesignerTarget.android => UiScreen(
          id: id,
          name: name,
          width: 412,
          height: 915,
        ),
    };
  }

  UiScreen copyWith({
    String? name,
    double? width,
    double? height,
    List<UiNode>? nodes,
  }) =>
      UiScreen(
        id: id,
        name: name ?? this.name,
        width: width ?? this.width,
        height: height ?? this.height,
        nodes: nodes ?? this.nodes,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'nodes': nodes.map((node) => node.toJson()).toList(),
      };

  factory UiScreen.fromJson(Map<String, Object?> json) => UiScreen(
        id: json['id']! as String,
        name: json['name']! as String,
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        nodes: ((json['nodes'] as List?) ?? const [])
            .map(
              (item) => UiNode.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
      );
}
