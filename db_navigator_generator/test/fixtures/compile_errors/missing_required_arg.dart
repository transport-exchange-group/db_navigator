import 'confirm_load_screen.dart';

ConfirmLoadRoute route() {
  return ConfirmLoadRoute( // expect-error: missing_required_argument
    status: LoadStatus.open,
    pickupAt: DateTime(2026),
    stops: const <DateTime>[],
    weights: const <String, double>{},
    driver: const Driver('Sam'),
  );
}
