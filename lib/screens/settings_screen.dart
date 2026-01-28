import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../services/export_service.dart';
import '../services/backup_service.dart';
import '../screens/auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader(context, 'Appearance'),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Enable dark theme'),
                secondary: Icon(
                  settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                value: settings.isDarkMode,
                onChanged: (_) => settings.toggleDarkMode(),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Currency'),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Default Currency'),
                subtitle: Text('${settings.currencySymbol} (${settings.defaultCurrency})'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCurrencyPicker(context, settings),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export to CSV'),
            subtitle: const Text('Export all expenses to CSV file'),
            onTap: () => _exportToCSV(context),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Export to Excel'),
            subtitle: const Text('Export all expenses to Excel file'),
            onTap: () => _exportToExcel(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Cloud Backup'),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Backup to Cloud'),
            subtitle: const Text('Save data to cloud storage'),
            onTap: () => _backupToCloud(context),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Restore from Cloud'),
            subtitle: const Text('Restore data from cloud backup'),
            onTap: () => _showBackupList(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            subtitle: const Text('Sign out from your account'),
            onTap: () => _logout(context),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Developed with Flutter'),
            subtitle: Text('Personal Expense Tracker'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        settings.setCurrency(currency.code, currency.symbol);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Currency changed to ${currency.code}')),
        );
      },
    );
  }

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final expenses = context.read<ExpenseProvider>().expenses;
      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }

      await ExportService.exportToCSV(expenses);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported to CSV successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      final expenses = context.read<ExpenseProvider>().expenses;
      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }

      await ExportService.exportToExcel(expenses);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported to Excel successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _backupToCloud(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final expenses = context.read<ExpenseProvider>().expenses;
      String? url = await BackupService.backupToCloud(expenses);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup successful!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup failed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup error: $e')),
        );
      }
    }
  }

  Future<void> _showBackupList(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      List<String> backups = await BackupService.listBackups();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        if (backups.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backups found')),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Backup'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.cloud),
                    title: Text(backups[index]),
                    onTap: () {
                      Navigator.pop(context);
                      _restoreBackup(context, backups[index]);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, String fileName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Restoring backup...'),
          ],
        ),
      ),
    );

    // Implementation would parse the Excel file and restore data
    // This is a simplified version
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore functionality coming soon')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}