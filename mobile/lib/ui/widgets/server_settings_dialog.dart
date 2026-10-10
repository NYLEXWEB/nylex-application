import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/auth_storage.dart';

void showServerSettingsDialog(BuildContext context) {
  final urlController = TextEditingController(text: ApiConstants.baseUrl);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Server / API Settings"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Backend API Base URL:",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: "https://nylex-application.onrender.com",
                labelText: "API Base URL",
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => urlController.text = "https://nylex-application.onrender.com",
                  child: const Text("Render Cloud"),
                ),
                OutlinedButton(
                  onPressed: () => urlController.text = "http://localhost:8000",
                  child: const Text("Localhost"),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            final newUrl = urlController.text.trim();
            if (newUrl.isNotEmpty) {
              ApiConstants.baseUrl = newUrl;
              await AuthStorage.saveCustomBaseUrl(newUrl);
            }
            if (context.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Backend URL saved: ${ApiConstants.baseUrl}"),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
