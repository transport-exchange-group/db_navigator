class RouteDescriptor {
  final String path;
  final String feature;
  final String routeClass;
  final String library;
  final bool isFeatureEntry;
  final bool isRestorable;

  const RouteDescriptor({
    required this.path,
    required this.feature,
    required this.routeClass,
    required this.library,
    required this.isFeatureEntry,
    required this.isRestorable,
  });

  factory RouteDescriptor.fromJson(Map<String, Object?> json) {
    return RouteDescriptor(
      path: json['path']! as String,
      feature: json['feature']! as String,
      routeClass: json['routeClass']! as String,
      library: json['library']! as String,
      isFeatureEntry: json['isFeatureEntry']! as bool,
      isRestorable: json['isRestorable']! as bool,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'path': path,
      'feature': feature,
      'routeClass': routeClass,
      'library': library,
      'isFeatureEntry': isFeatureEntry,
      'isRestorable': isRestorable,
    };
  }
}
