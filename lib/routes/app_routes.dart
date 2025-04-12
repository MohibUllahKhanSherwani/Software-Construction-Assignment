import 'package:flutter/material.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/dashboard/presentation/admin_dashboard.dart';
import '../features/dashboard/presentation/parent_dashboard.dart';
import '../features/payments/presentation/payment_page.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String adminDashboard = '/admin-dashboard';
  static const String parentDashboard = '/parent-dashboard';
  static const String payment = '/payment';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    adminDashboard: (context) => const AdminDashboard(),
    parentDashboard: (context) => const ParentDashboard(),
    payment: (context) => const PaymentPage(),
  };
}
