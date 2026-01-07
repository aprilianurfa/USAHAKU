import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/routes.dart';

void main() {
  runApp(const UsahakuApp());
}

class UsahakuApp extends StatelessWidget {
  const UsahakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usahaku POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: AppRoutes.routes,
    );
  }
}
