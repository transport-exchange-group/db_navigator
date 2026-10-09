import 'package:db_navigator/db_navigator.dart';
import 'package:flutter/material.dart';

part 'confirm_load_screen.g.dart';

enum LoadStatus { open, booked }

class Driver {
  const Driver(this.name);

  factory Driver.fromJson(Map<String, dynamic> json) =>
      Driver(json['name'] as String);

  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{'name': name};
}

@DBRoute<bool>(path: '/loads/confirm', feature: 'loads', isFeatureEntry: true)
class ConfirmLoadScreen extends StatelessWidget {
  const ConfirmLoadScreen({
    required this.loadId,
    required this.status,
    required this.pickupAt,
    required this.stops,
    required this.weights,
    required this.driver,
    this.note = '',
    super.key,
  });

  final int loadId;
  final LoadStatus status;
  final DateTime pickupAt;
  final List<DateTime> stops;
  final Map<String, double> weights;
  final Driver driver;
  final String note;

  @override
  Widget build(BuildContext context) => Text(note);
}
