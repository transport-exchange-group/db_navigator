// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_screen.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

class SettingsRoute extends DBTypedRoute<void> {
  const SettingsRoute();

  static const String path = '/settings';

  static const DBRouteDefinition definition = DBRouteDefinition(
    path: path,
    decode: SettingsRoute.fromJson,
    defaultRoute: SettingsRoute._defaultRoute,
  );

  @override
  String get location => path;

  @override
  bool get isRestorable => true;

  static void close(BuildContext context) =>
      DBRouterDelegate.of(context).close<Object?>();

  static SettingsRoute fromJson(Map<String, Object?> json) => SettingsRoute();

  static SettingsRoute _defaultRoute() => SettingsRoute();

  @override
  Map<String, Object?>? toJson() => <String, Object?>{};

  @override
  Widget buildWidget() => SettingsScreen();
}
