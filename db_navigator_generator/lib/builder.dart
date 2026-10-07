import 'package:build/build.dart';
import 'package:db_navigator_generator/src/feature_routes_builder.dart';
import 'package:db_navigator_generator/src/route_descriptor_builder.dart';
import 'package:db_navigator_generator/src/route_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder dbRouteBuilder(BuilderOptions options) {
  return SharedPartBuilder(<Generator>[RouteGenerator()], 'db_route');
}

Builder dbRouteDescriptorBuilder(BuilderOptions options) {
  return RouteDescriptorBuilder();
}

Builder dbFeatureRoutesBuilder(BuilderOptions options) {
  return FeatureRoutesBuilder();
}
