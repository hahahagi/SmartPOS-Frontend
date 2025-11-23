import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const String routeName = 'splash';
  static const String routePath = '/';

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authNotifierProvider.notifier).hydrateSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _messageForStatus(state.status),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _messageForStatus(AuthStatus status) {
    switch (status) {
      case AuthStatus.authenticating:
        return 'Mengecek sesi...';
      case AuthStatus.error:
        return 'Terjadi kesalahan. Mengalihkan...';
      default:
        return 'Menyiapkan aplikasi kasir';
    }
  }
}
