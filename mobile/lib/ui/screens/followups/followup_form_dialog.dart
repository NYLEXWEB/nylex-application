import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/followups_provider.dart';

class FollowupFormDialog extends StatefulWidget {
  final String? leadId;
  final String? leadName;
  final String? clientId;

  const FollowupFormDialog({Key? key, this.leadId, this.leadName, this.clientId}) : super(key: key);

  @override
  State<FollowupFormDialog> createState() => _FollowupFormDialogState();
}

class _FollowupFormDialogState extends State<FollowupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _notesController;

  String _method = "Call";
  int _reminderMinutes = 15;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(now));
    _timeController = TextEditingController(text: DateFormat('HH:mm').format(now.add(const Duration(hours: 1))));
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = {
      "leadId": widget.leadId,
      "clientId": widget.clientId,
      "scheduledDate": _dateController.text.trim(),
      "scheduledTime": _timeController.text.trim(),
      "method": _method,
      "reminderMinutesBefore": _reminderMinutes,
      "notes": _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    try {
      await Provider.of<FollowupsProvider>(context, listen: false).createFollowup(payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.leadName != null ? "Follow-up: ${widget.leadName}" : "Schedule Follow-up"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
                      validator: (v) => Validators.required(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(labelText: "Time (HH:MM)"),
                      validator: (v) => Validators.required(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(labelText: "Contact Method"),
                items: ["Call", "WhatsApp", "Email", "Meeting", "Other"]
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => _method = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _reminderMinutes,
                decoration: const InputDecoration(labelText: "Reminder Notification"),
                items: const [
                  DropdownMenuItem(value: 15, child: Text("15 minutes before")),
                  DropdownMenuItem(value: 30, child: Text("30 minutes before")),
                  DropdownMenuItem(value: 60, child: Text("1 hour before")),
                ],
                onChanged: (val) => setState(() => _reminderMinutes = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Agenda / Notes"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Schedule"),
        ),
      ],
    );
  }
}
