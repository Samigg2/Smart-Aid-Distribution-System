import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../screens/login_screen.dart';
import '../screens/admin_dashboard.dart';
import '../screens/staff_dashboard.dart';
import 'loading_widget.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        // User is not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // User is logged in - get user data and route accordingly
        return FutureBuilder<UserModel?>(
          future: authService.getCurrentUserData(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            if (!userSnapshot.hasData) {
              return const LoginScreen();
            }

            UserModel user = userSnapshot.data!;

            // Route based on user role
            if (user.isAdmin) {
              return const AdminDashboard();
            } else {
              return const StaffDashboard();
            }
          },
        );
      },
    );
  }
}

