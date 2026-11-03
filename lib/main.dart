import 'dart:convert';
import 'package:flutter/material.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/models/user_model.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check persisted user session
  final token = await SecureStorageService.getToken();
  final userDataString = await SecureStorageService.getUserData();

  UserModel? initialUser;
  if (token != null && userDataString != null) {
    try {
      final data = jsonDecode(userDataString);
      final userJson = data['user'];
      final employeeJson = data['employee'];
      final permissions = List<String>.from(data['permissions'] ?? []);

      final employee = employeeJson != null ? EmployeeModel.fromJson(employeeJson) : null;
      initialUser = UserModel.fromJson(userJson, permissions: permissions, employee: employee);
    } catch (_) {
      await SecureStorageService.clearAll();
    }
  }

  runApp(HimaloyInventoryApp(initialUser: initialUser));
}

class HimaloyInventoryApp extends StatelessWidget {
  final UserModel? initialUser;

  const HimaloyInventoryApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Himaloy Agro Care Inventory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialUser != null
          ? DashboardScreen(currentUser: initialUser!)
          : const LoginScreen(),
    );
  }
}

