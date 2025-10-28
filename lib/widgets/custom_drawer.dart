import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Center(
                  child: Text(
                    'appTitle'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: Text('homeTitle'.tr()),
                onTap: () {
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('language'.tr()),
                subtitle: Text('changeLanguage'.tr()),
                onTap: () {
                  _showLanguageDialog(context);
                },
              ),
              ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                title: Text('themeToggle'.tr()),
                onTap: () {
                  themeProvider.toggleTheme();
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  '© ${DateTime.now().year}',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final current = context.locale;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<Locale>(
                value: const Locale('es', 'ES'),
                groupValue: current,
                title: Text('spanish'.tr()),
                onChanged: (loc) {
                  if (loc != null) {
                    context.setLocale(loc);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
              RadioListTile<Locale>(
                value: const Locale('en', 'US'),
                groupValue: current,
                title: Text('english'.tr()),
                onChanged: (loc) {
                  if (loc != null) {
                    context.setLocale(loc);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('close'.tr()),
            ),
          ],
        );
      },
    );
  }
}
