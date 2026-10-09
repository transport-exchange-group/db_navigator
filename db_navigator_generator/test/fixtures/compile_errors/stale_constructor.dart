// generated-from: stale_constructor_before.dart
// expect-error-in-part: undefined_named_parameter
import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';

part 'stale_constructor.g.dart';

@DBRoute(path: '/stale', feature: 'stale')
class StaleScreen extends StatelessWidget {
  const StaleScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) => const Text('');
}
