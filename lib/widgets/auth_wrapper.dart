import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/login_screen.dart';
import '../screens/admin_dashboard.dart';
import '../screens/staff_dashboard.dart';
import '../providers/auth_provider.dart';
import 'loading_widget.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final userDataAsync = ref.watch(currentUserDataStreamProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        return userDataAsync.when(
          data: (userModel) {
            if (userModel == null) {
              return const LoginScreen();
            }

            // Route based on user role
            if (userModel.isAdmin) {
              return const AdminDashboard();
            } else {
              return const StaffDashboard();
            }
          },
          loading: () => const LoadingWidget(),
          error: (_, __) => const LoginScreen(),
        );
      },
      loading: () => const LoadingWidget(),
      error: (_, __) => const LoginScreen(),
    );
  }
}

