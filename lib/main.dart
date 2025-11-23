import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_theme.dart';
import 'config/env.dart';
import 'config/router.dart';
import 'data/services/local_storage_service.dart';
import 'utils/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initializeDateFormatting('id_ID');
  await Future.wait([
    Hive.openBox<dynamic>(HiveBoxes.appCache),
    Hive.openBox<dynamic>(HiveBoxes.productCache),
    Hive.openBox<dynamic>(HiveBoxes.offlineTransactions),
  ]);

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SmartPosApp(),
    ),
  );
}

class SmartPosApp extends ConsumerWidget {
  const SmartPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppEnv.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
