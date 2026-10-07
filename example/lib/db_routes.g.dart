// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:db_navigator/db_navigator.dart';
import 'package:example/src/profile/confirm_logout_screen.dart';
import 'package:example/src/profile/profile_screen.dart';
import 'package:example/src/settings/about_screen.dart';
import 'package:example/src/settings/feedback_screen.dart';
import 'package:example/src/settings/settings_screen.dart';

class ProfileRoutes extends DBFeatureRoutes {
  const ProfileRoutes({super.onEntered, super.onExited});

  @override
  String get scopeName => 'profile';

  @override
  Destination get initialDestination =>
      const Destination(path: ProfileRoute.path);

  @override
  List<DBRouteDefinition> get definitions => const <DBRouteDefinition>[
    ConfirmLogoutRoute.definition,
    ProfileRoute.definition,
  ];
}

class SettingsRoutes extends DBFeatureRoutes {
  const SettingsRoutes({super.onEntered, super.onExited});

  @override
  String get scopeName => 'settings';

  @override
  Destination get initialDestination =>
      const Destination(path: SettingsRoute.path);

  @override
  List<DBRouteDefinition> get definitions => const <DBRouteDefinition>[
    AboutRoute.definition,
    FeedbackRoute.definition,
    SettingsRoute.definition,
  ];
}
