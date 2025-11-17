import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/language_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.language),
        title: Text(l10n.settings_language),
        subtitle: Text(
          languageProvider.isArabic
              ? l10n.language_arabic
              : l10n.language_english,
        ),
        trailing: DropdownButton<String>(
          value: languageProvider.locale.languageCode,
          underline: const SizedBox(),
          items: [
            DropdownMenuItem(
              value: 'ar',
              child: Text(l10n.language_arabic),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text(l10n.language_english),
            ),
          ],
          onChanged: (String? value) {
            if (value != null) {
              if (value == 'ar') {
                languageProvider.setArabic();
              } else {
                languageProvider.setEnglish();
              }
            }
          },
        ),
      ),
    );
  }
}

/// Simple language switch button for toolbar/appbar
class LanguageSwitchButton extends StatelessWidget {
  const LanguageSwitchButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return IconButton(
      icon: const Icon(Icons.language),
      tooltip: languageProvider.isArabic ? 'English' : 'العربية',
      onChanged: () {
        if (languageProvider.isArabic) {
          languageProvider.setEnglish();
        } else {
          languageProvider.setArabic();
        }
      },
    );
  }
}

/// Language selection dialog
class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LanguageSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.language_selectLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: Row(
              children: [
                const Text('العربية'),
                if (languageProvider.isArabic) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, color: Colors.green, size: 20),
                ],
              ],
            ),
            value: 'ar',
            groupValue: languageProvider.locale.languageCode,
            onChanged: (value) {
              languageProvider.setArabic();
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: Row(
              children: [
                const Text('English'),
                if (languageProvider.isEnglish) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, color: Colors.green, size: 20),
                ],
              ],
            ),
            value: 'en',
            groupValue: languageProvider.locale.languageCode,
            onChanged: (value) {
              languageProvider.setEnglish();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }
}
