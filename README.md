# db_navigator

A flutter navigation package.

It's allow you to have modular navigation. 

## Typed routes (1.1.0+)

Declare a route once on the page widget; arguments and results are checked at compile time.

**1. Install**

```yaml
dependencies:
  db_navigator:
    git:
      url: git@github.com:transport-exchange-group/db_navigator.git
      ref: release/0.2.0

dev_dependencies:
  build_runner: ^2.4.0
  db_navigator_generator:
    git:
      url: git@github.com:transport-exchange-group/db_navigator.git
      ref: release/0.2.0
      path: db_navigator_generator
```

**2. Annotate**

```dart
part 'confirm_load_screen.g.dart';

@DBRoute<bool>(path: '/loads/confirm', feature: 'loads', isFeatureEntry: true)
class ConfirmLoadScreen extends StatelessWidget {
  const ConfirmLoadScreen({required this.loadId, this.note = '', super.key});
  final int loadId;
  final String note;
  // ... ConfirmLoadRoute.close(context, true);
}
```

**3. Generate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**4. Register** the generated feature unit from `lib/db_routes.g.dart`:

```dart
DBRouterDelegate(
  initialPage: ...,
  pageBuilders: <DBPageBuilder>[const LoadsRoutes(), ...legacyBuilders],
);
```

**5. Push and await**

```dart
final bool? confirmed = await ConfirmLoadRoute(loadId: 42).push(context);
```

Legacy page builders keep working alongside generated ones. Moving an existing app: [doc/migration-guide.md](doc/migration-guide.md).
