// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_screen.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

// In-memory only (onSent: VoidCallback): not restored, not deep-linkable.
class FeedbackRoute extends DBTypedRoute<void> {
  const FeedbackRoute({required this.onSent});

  static const String path = '/settings/feedback';

  static const DBRouteDefinition definition = DBRouteDefinition(
    path: path,
    decode: FeedbackRoute.fromJson,
  );

  final VoidCallback onSent;

  @override
  String get location => path;

  @override
  bool get isRestorable => false;

  static void close(BuildContext context) =>
      DBRouterDelegate.of(context).close<Object?>();

  static FeedbackRoute fromJson(Map<String, Object?> json) =>
      throw UnsupportedError('FeedbackRoute is in-memory only');

  @override
  Map<String, Object?>? toJson() => null;

  @override
  Widget buildWidget() => FeedbackScreen(onSent: onSent);
}
