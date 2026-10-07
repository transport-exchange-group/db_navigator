// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_screen.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

class ProfileRoute extends DBTypedRoute<void> {
  const ProfileRoute({
    required this.userId,
    this.visits = 0,
  });

  static const String path = '/profile';

  static const DBRouteDefinition definition = DBRouteDefinition(
    path: path,
    decode: ProfileRoute.fromJson,
  );

  final String userId;

  final int visits;

  @override
  String get location => path;

  @override
  bool get isRestorable => true;

  static void close(BuildContext context) =>
      DBRouterDelegate.of(context).close<Object?>();

  static ProfileRoute fromJson(Map<String, Object?> json) => ProfileRoute(
      userId: json['userId'] as String,
      visits: json.containsKey('visits') ? (json['visits'] as num).toInt() : 0);

  @override
  Map<String, Object?>? toJson() =>
      <String, Object?>{'userId': userId, 'visits': visits};

  @override
  Widget buildWidget() => ProfileScreen(userId: userId, visits: visits);
}
