import 'confirm_load_screen.dart';

ConfirmLoadRoute route() {
  return ConfirmLoadRoute(
    loadId: 'one', // expect-error: argument_type_not_assignable
    status: LoadStatus.open,
    pickupAt: DateTime(2026),
    stops: const <DateTime>[],
    weights: const <String, double>{},
    driver: const Driver('Sam'),
  );
}
