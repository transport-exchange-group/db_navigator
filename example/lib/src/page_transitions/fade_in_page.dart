import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/widgets.dart';

/// Page factory for `@DBRoute(pageFactory:)` that fades the page in.
DBPage fadeInPage(Destination destination, Widget child) {
  return DBMaterialPage(
    key: UniqueKey(),
    destination: destination,
    child: child,
    customPageRouteFactory: (DBMaterialPage page) {
      return FadeInMaterialPageTransitionRoute(page: page);
    },
  );
}
