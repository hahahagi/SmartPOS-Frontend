import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStatusProvider = StreamProvider.autoDispose<bool>((
  ref,
) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield _hasConnection(initial);
  yield* connectivity.onConnectivityChanged.map(_hasConnection);
});

bool _hasConnection(dynamic result) {
  if (result is ConnectivityResult) {
    return result != ConnectivityResult.none;
  }
  if (result is List<ConnectivityResult>) {
    return result.any((status) => status != ConnectivityResult.none);
  }
  return false;
}
