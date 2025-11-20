import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../l10n/app_localizations.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  Map<String, dynamic>? _adminSettings;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdminSettings();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminSettings() async {
    try {
      final response = await supabase
          .from('admin_settings')
          .select('support_phone, support_email, support_whatsapp')
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _adminSettings = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading admin settings: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('customers')
          .select('first_name, last_name, email')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        _nameController.text = '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim();
        _emailController.text = response['email'] ?? user.email ?? '';
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: Could not make phone call')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Customer Support Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: Could not send email')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    // Remove any non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception(l10n.userNotAuthenticated);

      await supabase.from('support_messages').insert({
        'customer_id': user.id,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageSentSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpAndSupport),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Methods Section
                  _buildSectionHeader(l10n.contactUs),
                  _buildContactMethods(),

                  const Divider(height: 32),

                  // Contact Form Section
                  _buildSectionHeader(l10n.sendUsMessage),
                  _buildContactForm(),

                  const Divider(height: 32),

                  // FAQ Section
                  _buildSectionHeader(l10n.frequentlyAskedQuestions),
                  _buildFAQSection(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryNavy,
        ),
      ),
    );
  }

  Widget _buildContactMethods() {
    final l10n = AppLocalizations.of(context);
    final phone = _adminSettings?['support_phone'] as String?;
    final email = _adminSettings?['support_email'] as String?;
    final whatsapp = _adminSettings?['support_whatsapp'] as String?;

    return Column(
      children: [
        if (phone != null && phone.isNotEmpty)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
              child: Icon(Icons.phone, color: AppTheme.primaryNavy),
            ),
            title: Text(l10n.phone),
            subtitle: Text(phone),
            trailing: IconButton(
              icon: const Icon(Icons.call),
              onPressed: () => _makePhoneCall(phone),
              color: Colors.green,
            ),
          ),
        if (email != null && email.isNotEmpty)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
              child: Icon(Icons.email, color: AppTheme.primaryNavy),
            ),
            title: Text(l10n.email),
            subtitle: Text(email),
            trailing: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _sendEmail(email),
              color: AppTheme.primaryNavy,
            ),
          ),
        if (whatsapp != null && whatsapp.isNotEmpty)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(Icons.chat, color: Colors.green),
            ),
            title: const Text('WhatsApp'),
            subtitle: Text(whatsapp),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openWhatsApp(whatsapp),
              color: Colors.green,
            ),
          ),
        if ((phone == null || phone.isEmpty) &&
            (email == null || email.isEmpty) &&
            (whatsapp == null || whatsapp.isEmpty))
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.noContactInfoAvailable,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildContactForm() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterYourName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterYourEmail;
                }
                if (!value.contains('@')) {
                  return l10n.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: l10n.message,
                prefixIcon: const Icon(Icons.message_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterMessage;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitContactForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.sendMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _buildFAQItem(
          question: l10n.howToPlaceOrder,
          answer: l10n.howToPlaceOrderAnswer,
        ),
        _buildFAQItem(
          question: l10n.howToCancelOrder,
          answer: l10n.howToCancelOrderAnswer,
        ),
        _buildFAQItem(
          question: l10n.howToTrackOrder,
          answer: l10n.howToTrackOrderAnswer,
        ),
        _buildFAQItem(
          question: l10n.whatPaymentMethods,
          answer: l10n.whatPaymentMethodsAnswer,
        ),
        _buildFAQItem(
          question: l10n.howToContactProvider,
          answer: l10n.howToContactProviderAnswer,
        ),
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
        ),
      ],
    );
  }
}
