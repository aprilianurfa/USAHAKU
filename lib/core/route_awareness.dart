import 'package:flutter/material.dart';

/// A simple global notifier to track the current active route name.
/// This allows the Sidebar and other UI elements to stay in sync
/// regardless of how navigation was triggered.
class RouteAwareness extends ChangeNotifier {
  static final RouteAwareness _instance = RouteAwareness._internal();
  factory RouteAwareness() => _instance;
  RouteAwareness._internal();

  String _currentRoute = '/dashboard';
  String get currentRoute => _currentRoute;

  void updateRoute(String? routeName) {
    if (routeName != null && _currentRoute != routeName) {
      _currentRoute = routeName;
      notifyListeners();
    }
  }
}

/// A NavigatorObserver to push route changes to the RouteAwareness notifier.
class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    RouteAwareness().updateRoute(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    RouteAwareness().updateRoute(newRoute?.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    RouteAwareness().updateRoute(previousRoute?.settings.name);
  }
}
