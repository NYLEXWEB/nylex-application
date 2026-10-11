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

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);

  String _method = "Call";
  int _reminderMinutes = 15;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
    _timeController = TextEditingController(
      text: "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: DateTime(2035),
      helpText: "SELECT FUTURE FOLLOW-UP DATE",
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: "SELECT FOLLOW-UP TIME",
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Follow-up scheduled for ${_dateController.text} at ${_timeController.text} with notification reminder",
            ),
          ),
        );
        Navigator.pop(context);
      }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_callback, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.leadName != null ? "Follow-up: ${widget.leadName}" : "Schedule Follow-up",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Visual Future Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: "Follow-up Date *",
                      hintText: "Select future date",
                      prefixIcon: Icon(Icons.calendar_month, color: AppColors.accent, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    validator: (v) => Validators.required(v),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Visual Time Picker
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(10),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: "Follow-up Time *",
                      hintText: "Select time",
                      prefixIcon: Icon(Icons.access_time, color: AppColors.accent, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    validator: (v) => Validators.required(v),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Contact Method
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(
                  labelText: "Contact Method",
                  prefixIcon: Icon(Icons.contact_phone_outlined, size: 20),
                ),
                items: ["Call", "WhatsApp", "Email", "Meeting", "Other"]
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => _method = val!),
              ),
              const SizedBox(height: 12),

              // Phone Notification Reminder
              DropdownButtonFormField<int>(
                value: _reminderMinutes,
                decoration: const InputDecoration(
                  labelText: "Phone Notification Alert",
                  prefixIcon: Icon(Icons.notifications_active_outlined, color: AppColors.warning, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text("At event time")),
                  DropdownMenuItem(value: 15, child: Text("15 minutes before")),
                  DropdownMenuItem(value: 30, child: Text("30 minutes before")),
                  DropdownMenuItem(value: 60, child: Text("1 hour before")),
                ],
                onChanged: (val) => setState(() => _reminderMinutes = val!),
              ),
              const SizedBox(height: 12),

              // Agenda / Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Agenda / Discussion Notes",
                  prefixIcon: Icon(Icons.notes, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Schedule & Alert"),
        ),
      ],
    );
  }
}
