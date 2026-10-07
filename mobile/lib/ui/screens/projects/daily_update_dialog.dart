import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/projects_provider.dart';

class DailyUpdateDialog extends StatefulWidget {
  final String projectId;

  const DailyUpdateDialog({Key? key, required this.projectId}) : super(key: key);

  @override
  State<DailyUpdateDialog> createState() => _DailyUpdateDialogState();
}

class _DailyUpdateDialogState extends State<DailyUpdateDialog> {
  final _completedController = TextEditingController();
  final _nextController = TextEditingController();
  final _blockerController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _completedController.dispose();
    _nextController.dispose();
    _blockerController.dispose();
    super.dispose();
  }

  void _post() async {
    final comp = _completedController.text.trim();
    final next = _nextController.text.trim();
    final block = _blockerController.text.trim();

    if (comp.isEmpty && next.isEmpty && block.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill at least one section")));
      return;
    }

    setState(() => _isPosting = true);

    final buffer = StringBuffer();
    if (comp.isNotEmpty) buffer.writeln("Completed:\n$comp\n");
    if (next.isNotEmpty) buffer.writeln("Next:\n$next\n");
    if (block.isNotEmpty) buffer.writeln("Blockers:\n$block");

    final payload = {
      "projectId": widget.projectId,
      "updateText": buffer.toString().trim(),
      "completedSection": comp.isEmpty ? null : comp,
      "nextSection": next.isEmpty ? null : next,
      "blockerSection": block.isEmpty ? null : block,
    };

    try {
      await Provider.of<ProjectsProvider>(context, listen: false).postDailyUpdate(payload);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.flash_on, color: AppColors.accent, size: 22),
          SizedBox(width: 8),
          Text("Post Daily Update", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick progress report for partners:", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: _completedController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Completed Today",
                hintText: "e.g. Built contact section & testing APIs",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nextController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Next Goals",
                hintText: "e.g. Payment gateway integration",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _blockerController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Blockers / Pending Items",
                hintText: "e.g. Waiting for client logo & domain DNS",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isPosting ? null : _post,
          child: _isPosting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Post Update"),
        ),
      ],
    );
  }
}
