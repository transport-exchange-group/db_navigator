import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';

part 'stale_constructor.g.dart';

@DBRoute(path: '/stale', feature: 'stale')
class StaleScreen extends StatelessWidget {
  const StaleScreen({required this.loadId, super.key});

  final int loadId;

  @override
  Widget build(BuildContext context) => const Text('');
}
