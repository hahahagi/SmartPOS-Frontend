import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/pages/admin/category_management_page.dart';
import '../ui/pages/admin/product_management_page.dart';
import '../ui/pages/admin/report_overview_page.dart';
import '../ui/pages/admin/stock_adjustment_page.dart';
import '../ui/pages/dashboard/dashboard_page.dart';
import '../ui/pages/history/history_page.dart';
import '../ui/pages/login/login_page.dart';
import '../ui/pages/payment/payment_page.dart';
import '../ui/pages/receipt/receipt_page.dart';
import '../ui/pages/product_search/product_search_page.dart';
import '../ui/pages/scanner/scanner_page.dart';
import '../ui/pages/splash/splash_page.dart';
import '../ui/pages/start_transaction/start_transaction_page.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: SplashPage.routePath,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    redirect: notifier.handleRedirect,
    routes: [
      GoRoute(
        path: SplashPage.routePath,
        name: SplashPage.routeName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: LoginPage.routePath,
        name: LoginPage.routeName,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: DashboardPage.routePath,
        name: DashboardPage.routeName,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: StartTransactionPage.routePath,
        name: StartTransactionPage.routeName,
        builder: (context, state) => const StartTransactionPage(),
      ),
      GoRoute(
        path: ScannerPage.routePath,
        name: ScannerPage.routeName,
        builder: (context, state) => const ScannerPage(),
      ),
      GoRoute(
        path: ProductSearchPage.routePath,
        name: ProductSearchPage.routeName,
        builder: (context, state) => const ProductSearchPage(),
      ),
      GoRoute(
        path: PaymentPage.routePath,
        name: PaymentPage.routeName,
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: ReceiptPage.routePath,
        name: ReceiptPage.routeName,
        builder: (context, state) => const ReceiptPage(),
      ),
      GoRoute(
        path: HistoryPage.routePath,
        name: HistoryPage.routeName,
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: ProductManagementPage.routePath,
        name: ProductManagementPage.routeName,
        builder: (context, state) => const ProductManagementPage(),
      ),
      GoRoute(
        path: CategoryManagementPage.routePath,
        name: CategoryManagementPage.routeName,
        builder: (context, state) => const CategoryManagementPage(),
      ),
      GoRoute(
        path: StockAdjustmentPage.routePath,
        name: StockAdjustmentPage.routeName,
        builder: (context, state) => const StockAdjustmentPage(),
      ),
      GoRoute(
        path: ReportOverviewPage.routePath,
        name: ReportOverviewPage.routeName,
        builder: (context, state) => const ReportOverviewPage(),
      ),
    ],
  );
  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });
  return router;
});

final _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

const _adminOnlyPaths = <String>{
  ProductManagementPage.routePath,
  CategoryManagementPage.routePath,
  StockAdjustmentPage.routePath,
  ReportOverviewPage.routePath,
};

const _managerPaths = <String>{
  StockAdjustmentPage.routePath,
  ReportOverviewPage.routePath,
};

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _subscription = _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  String? handleRedirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final loggingIn = state.matchedLocation == LoginPage.routePath;
    final atSplash = state.matchedLocation == SplashPage.routePath;

    if (authState.status == AuthStatus.unknown ||
        authState.status == AuthStatus.authenticating) {
      return atSplash ? null : SplashPage.routePath;
    }

    if (!authState.isAuthenticated) {
      return loggingIn ? null : LoginPage.routePath;
    }

    if (loggingIn || atSplash) {
      return DashboardPage.routePath;
    }

    if (_adminOnlyPaths.contains(state.uri.path)) {
      if (authState.isAdmin) return null;
      if (authState.isManager && _managerPaths.contains(state.uri.path)) {
        return null;
      }
      return DashboardPage.routePath;
    }

    return null;
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
