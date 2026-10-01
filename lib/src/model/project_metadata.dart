class ProjectMetadata {
  const ProjectMetadata({
    this.description = '',
    this.organization = '',
    this.appIdentifier = '',
    this.versionName = '1.0.0',
    this.versionCode = 1,
  });

  final String description;
  final String organization;
  final String appIdentifier;
  final String versionName;
  final int versionCode;

  ProjectMetadata copyWith({
    String? description,
    String? organization,
    String? appIdentifier,
    String? versionName,
    int? versionCode,
  }) {
    return ProjectMetadata(
      description: description ?? this.description,
      organization: organization ?? this.organization,
      appIdentifier: appIdentifier ?? this.appIdentifier,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
    );
  }

  Map<String, Object?> toJson() => {
        'description': description,
        'organization': organization,
        'appIdentifier': appIdentifier,
        'versionName': versionName,
        'versionCode': versionCode,
      };

  factory ProjectMetadata.fromJson(Map<String, Object?> json) =>
      ProjectMetadata(
        description: json['description'] as String? ?? '',
        organization: json['organization'] as String? ?? '',
        appIdentifier: json['appIdentifier'] as String? ?? '',
        versionName: json['versionName'] as String? ?? '1.0.0',
        versionCode: (json['versionCode'] as num?)?.toInt() ?? 1,
      );
}
