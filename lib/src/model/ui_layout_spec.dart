enum UiSizeMode {
  fixed,
  fill,
  hug,
}

enum UiHorizontalAnchor {
  left,
  center,
  right,
}

enum UiVerticalAnchor {
  top,
  center,
  bottom,
}

class UiLayoutSpec {
  const UiLayoutSpec({
    this.widthMode = UiSizeMode.fixed,
    this.heightMode = UiSizeMode.fixed,
    this.horizontalAnchor = UiHorizontalAnchor.left,
    this.verticalAnchor = UiVerticalAnchor.top,
    this.minWidth = 24,
    this.minHeight = 24,
    this.maxWidth,
    this.maxHeight,
    this.leftInset,
    this.rightInset,
    this.topInset,
    this.bottomInset,
  });

  final UiSizeMode widthMode;
  final UiSizeMode heightMode;
  final UiHorizontalAnchor horizontalAnchor;
  final UiVerticalAnchor verticalAnchor;
  final double minWidth;
  final double minHeight;
  final double? maxWidth;
  final double? maxHeight;
  final double? leftInset;
  final double? rightInset;
  final double? topInset;
  final double? bottomInset;

  UiLayoutSpec copyWith({
    UiSizeMode? widthMode,
    UiSizeMode? heightMode,
    UiHorizontalAnchor? horizontalAnchor,
    UiVerticalAnchor? verticalAnchor,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    bool clearMaxWidth = false,
    double? maxHeight,
    bool clearMaxHeight = false,
    double? leftInset,
    double? rightInset,
    double? topInset,
    double? bottomInset,
  }) {
    return UiLayoutSpec(
      widthMode: widthMode ?? this.widthMode,
      heightMode: heightMode ?? this.heightMode,
      horizontalAnchor: horizontalAnchor ?? this.horizontalAnchor,
      verticalAnchor: verticalAnchor ?? this.verticalAnchor,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: clearMaxWidth ? null : maxWidth ?? this.maxWidth,
      maxHeight: clearMaxHeight ? null : maxHeight ?? this.maxHeight,
      leftInset: leftInset ?? this.leftInset,
      rightInset: rightInset ?? this.rightInset,
      topInset: topInset ?? this.topInset,
      bottomInset: bottomInset ?? this.bottomInset,
    );
  }

  double constrainWidth(double value) {
    var result = value < minWidth ? minWidth : value;
    final max = maxWidth;
    if (max != null && max >= minWidth && result > max) result = max;
    return result;
  }

  double constrainHeight(double value) {
    var result = value < minHeight ? minHeight : value;
    final max = maxHeight;
    if (max != null && max >= minHeight && result > max) result = max;
    return result;
  }

  Map<String, Object?> toJson() => {
        'widthMode': widthMode.name,
        'heightMode': heightMode.name,
        'horizontalAnchor': horizontalAnchor.name,
        'verticalAnchor': verticalAnchor.name,
        'minWidth': minWidth,
        'minHeight': minHeight,
        if (maxWidth != null) 'maxWidth': maxWidth,
        if (maxHeight != null) 'maxHeight': maxHeight,
        if (leftInset != null) 'leftInset': leftInset,
        if (rightInset != null) 'rightInset': rightInset,
        if (topInset != null) 'topInset': topInset,
        if (bottomInset != null) 'bottomInset': bottomInset,
      };

  factory UiLayoutSpec.fromJson(Map<String, Object?> json) => UiLayoutSpec(
        widthMode: UiSizeMode.values.byName(
          json['widthMode'] as String? ?? UiSizeMode.fixed.name,
        ),
        heightMode: UiSizeMode.values.byName(
          json['heightMode'] as String? ?? UiSizeMode.fixed.name,
        ),
        horizontalAnchor: UiHorizontalAnchor.values.byName(
          json['horizontalAnchor'] as String? ??
              UiHorizontalAnchor.left.name,
        ),
        verticalAnchor: UiVerticalAnchor.values.byName(
          json['verticalAnchor'] as String? ?? UiVerticalAnchor.top.name,
        ),
        minWidth: (json['minWidth'] as num?)?.toDouble() ?? 24,
        minHeight: (json['minHeight'] as num?)?.toDouble() ?? 24,
        maxWidth: (json['maxWidth'] as num?)?.toDouble(),
        maxHeight: (json['maxHeight'] as num?)?.toDouble(),
        leftInset: (json['leftInset'] as num?)?.toDouble(),
        rightInset: (json['rightInset'] as num?)?.toDouble(),
        topInset: (json['topInset'] as num?)?.toDouble(),
        bottomInset: (json['bottomInset'] as num?)?.toDouble(),
      );
}
