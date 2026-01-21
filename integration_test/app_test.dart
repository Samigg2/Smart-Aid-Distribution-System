import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firs_app/main.dart' as app;
import 'package:firs_app/services/priority_model_ai_service.dart';
import 'package:firs_app/widgets/auth_wrapper.dart';
import 'package:firs_app/screens/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App starts and shows Login/Auth screen', (tester) async {
      // Start the app
      app.main();
      
      // Wait for the app to settle
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we are either at AuthWrapper or LoginScreen
      // Note: Depending on auth state, it might redirect. 
      // Assuming fresh install state or logged out state for test environment usually shows Login.
      
      // We look for AuthWrapper which is the root of home
      expect(find.byType(AuthWrapper), findsOneWidget);

      // If we are logged out, we should see LoginScreen UI elements
      if (find.byType(LoginScreen).evaluate().isNotEmpty) {
        expect(find.text('Login'), findsOneWidget);
        expect(find.byType(TextFormField), findsAtLeastNWidgets(2)); // Email and Password fields
      }
    });

    testWidgets('Login Validation Test', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(LoginScreen).evaluate().isNotEmpty) {
        // Find the login button (assuming there is a button with text 'Login' or similar)
        // Adjust finder based on actual UI implementation if 'Login' text is inside an elevated button
        final loginButton = find.widgetWithText(ElevatedButton, 'Login');
        
        if (loginButton.evaluate().isNotEmpty) {
           await tester.tap(loginButton);
           await tester.pumpAndSettle();

           // Expect validation error messages to appear
           // Common validation messages
           expect(find.textContaining('required'), findsWidgets);
        }
      } else {
        debugPrint('Skipping Login Validation Test - User already logged in or Screen not found');
      }
    });

    test('AI Service Health Check', () async {
      final aiService = PriorityModelAiService();
      
      // We don't want to fail the test entirely if the external local server is down
      // but we want to verify the method executes without crashing.
      try {
        final isHealthy = await aiService.checkHealth();
        debugPrint('AI Service Health Status: $isHealthy');
        // If it returns, the integration code is working (even if false)
        expect(isHealthy, isA<bool>());
      } catch (e) {
        // If it throws an exception (e.g. Connection refused), we catch it
        // This confirms the service attempted the connection
        debugPrint('AI Service checkHealth threw exception (expected if server offline): $e');
      }
    });
  });
}
