class UiRect {
  const UiRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  UiRect copyWith({double? x, double? y, double? width, double? height}) {
    return UiRect(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, Object> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  factory UiRect.fromJson(Map<String, Object?> json) => UiRect(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );
}
