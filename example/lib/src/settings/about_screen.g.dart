// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'about_screen.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

class AboutRoute extends DBTypedRoute<void> {
  const AboutRoute({this.version = 'unknown'});

  static const String path = '/settings/about';

  static const DBRouteDefinition definition = DBRouteDefinition(
    path: path,
    decode: AboutRoute.fromJson,
    defaultRoute: AboutRoute._defaultRoute,
    pageFactory: fadeInPage,
  );

  final String version;

  @override
  String get location => path;

  @override
  bool get isRestorable => true;

  static void close(BuildContext context) =>
      DBRouterDelegate.of(context).close<Object?>();

  static AboutRoute fromJson(Map<String, Object?> json) => AboutRoute(
      version:
          json.containsKey('version') ? json['version'] as String : 'unknown');

  static AboutRoute _defaultRoute() => AboutRoute();

  @override
  Map<String, Object?>? toJson() => <String, Object?>{'version': version};

  @override
  Widget buildWidget() => AboutScreen(version: version);
}
