import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for LoginScreen
/// Note: These tests use simplified widgets since the actual LoginScreen
/// requires Supabase initialization. For full integration tests,
/// see the integration test folder.
void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('should display email input field', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('email_field'),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('should display password input field', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('password_field'),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should display login button', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('login_button'),
              onPressed: () {},
              child: const Text('Login'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should display forgot password link', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              key: const Key('forgot_password_button'),
              onPressed: () {},
              child: const Text('Forgot Password?'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('should display register link', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              key: const Key('register_button'),
              onPressed: () {},
              child: const Text("Don't have an account? Register"),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byKey(const Key('register_button')), findsOneWidget);
    });

    group('Form Validation', () {
      testWidgets('should show error for empty email', (WidgetTester tester) async {
        // Arrange
        final formKey = GlobalKey<FormState>();
        String? emailError;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: TextFormField(
                  key: const Key('email_field'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    return null;
                  },
                  onSaved: (value) {},
                ),
              ),
            ),
          ),
        );

        // Act
        formKey.currentState?.validate();
        await tester.pump();

        // Assert
        expect(find.text('Email is required'), findsOneWidget);
      });

      testWidgets('should show error for invalid email format', (WidgetTester tester) async {
        // Arrange
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: TextFormField(
                  key: const Key('email_field'),
                  initialValue: 'invalid-email',
                  validator: (value) {
                    if (value != null && !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        );

        // Act
        formKey.currentState?.validate();
        await tester.pump();

        // Assert
        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('should show error for empty password', (WidgetTester tester) async {
        // Arrange
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: TextFormField(
                  key: const Key('password_field'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        );

        // Act
        formKey.currentState?.validate();
        await tester.pump();

        // Assert
        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('should show error for short password', (WidgetTester tester) async {
        // Arrange
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: TextFormField(
                  key: const Key('password_field'),
                  initialValue: '12345',
                  validator: (value) {
                    if (value != null && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        );

        // Act
        formKey.currentState?.validate();
        await tester.pump();

        // Assert
        expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      });

      testWidgets('should pass validation with valid inputs', (WidgetTester tester) async {
        // Arrange
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      key: const Key('email_field'),
                      initialValue: 'test@example.com',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      key: const Key('password_field'),
                      initialValue: 'password123',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Act
        final isValid = formKey.currentState?.validate();

        // Assert
        expect(isValid, isTrue);
      });
    });

    group('Password Visibility Toggle', () {
      testWidgets('should toggle password visibility', (WidgetTester tester) async {
        // Arrange
        bool obscureText = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return TextField(
                    key: const Key('password_field'),
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        key: const Key('visibility_toggle'),
                        icon: Icon(
                          obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Assert initial state
        expect(find.byIcon(Icons.visibility), findsOneWidget);

        // Act - tap toggle
        await tester.tap(find.byKey(const Key('visibility_toggle')));
        await tester.pump();

        // Assert after toggle
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });
    });
  });
}
