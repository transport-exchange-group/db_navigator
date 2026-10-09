// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_logout_screen.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

class ConfirmLogoutRoute extends DBTypedRoute<bool> {
  const ConfirmLogoutRoute();

  static const String path = '/profile/logout';

  static const DBRouteDefinition definition = DBRouteDefinition(
    path: path,
    decode: ConfirmLogoutRoute.fromJson,
    defaultRoute: ConfirmLogoutRoute._defaultRoute,
  );

  @override
  String get location => path;

  @override
  bool get isRestorable => true;

  static void close(
    BuildContext context, [
    bool? result,
  ]) =>
      DBRouterDelegate.of(context).close<bool?>(result);

  static ConfirmLogoutRoute fromJson(Map<String, Object?> json) =>
      ConfirmLogoutRoute();

  static ConfirmLogoutRoute _defaultRoute() => ConfirmLogoutRoute();

  @override
  Map<String, Object?>? toJson() => <String, Object?>{};

  @override
  Widget buildWidget() => ConfirmLogoutScreen();
}
