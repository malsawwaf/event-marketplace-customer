import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _emailSent = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? AppLocalizations.of(context).errorSendingResetLink),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Icon
          Icon(
            Icons.lock_reset,
            size: 80,
            color: Colors.blue[700],
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            AppLocalizations.of(context).resetYourPassword,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).enterEmailToResetPassword,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).email,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context).pleaseEnterYourEmail;
              }
              if (!value.contains('@')) {
                return AppLocalizations.of(context).pleaseEnterValidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Reset button
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return ElevatedButton(
                onPressed:
                    authProvider.isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context).sendResetLink,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Back to login
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).backToSignIn),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        // Success icon
        Icon(
          Icons.mark_email_read,
          size: 100,
          color: Colors.green[600],
        ),
        const SizedBox(height: 24),
        // Title
        Text(
          AppLocalizations.of(context).checkYourEmail,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Message
        Text(
          AppLocalizations.of(context).resetLinkSentTo,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).didNotReceiveEmail,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Back to login button
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            AppLocalizations.of(context).backToSignIn,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Resend link
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(AppLocalizations.of(context).resendLink),
        ),
      ],
    );
  }
}
