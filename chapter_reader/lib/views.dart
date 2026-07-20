import 'package:flutter/material.dart';
import 'app_strings.dart';

// User Dashboard View
class UserDashboardView extends StatelessWidget {
  final String currentLang;
  const UserDashboardView({super.key, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          AppStrings.get('chapters_list', currentLang),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.menu_book, color: Colors.white),
            ),
            title: const Text("अध्याय १ (Chapter 1)"),
            subtitle: Text(AppStrings.get('read_now', currentLang)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Tap functionality for PDF
            },
          ),
        ),
      ],
    );
  }
}

// Admin Dashboard View
class AdminDashboardView extends StatelessWidget {
  final String currentLang;
  const AdminDashboardView({super.key, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          AppStrings.get('admin_controls', currentLang),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: () {},
          icon: const Icon(Icons.upload_file),
          label: Text(AppStrings.get('upload_pdf', currentLang)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: () {},
          icon: const Icon(Icons.bar_chart),
          label: Text(AppStrings.get('analytics', currentLang)),
        ),
      ],
    );
  }
}