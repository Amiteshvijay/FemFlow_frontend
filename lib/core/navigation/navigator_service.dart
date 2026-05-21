import 'package:flutter/material.dart';

class NavigatorService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?> push<T>(Route<T> route) {
    return navigatorKey.currentState!.push(route);
  }

  static Future<T?> pushReplacement<T, TO>(Route<T> route) {
    return navigatorKey.currentState!.pushReplacement(route);
  }

  static void pop<T>([T? result]) {
    return navigatorKey.currentState!.pop(result);
  }
}
