import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/tasks_provider.dart';
import '../../../providers/projects_provider.dart';

class TaskFormDialog extends StatefulWidget {
  final String? projectId;

  const TaskFormDialog({Key? key, this.projectId}) : super(key: key);

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _dueDateController;

  String? _selectedProjectId;
  String _priority = "Medium";
  String _status = "Todo";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _dueDateController = TextEditingController();
    _selectedProjectId = widget.projectId;

    if (_selectedProjectId == null) {
      final projs = Provider.of<ProjectsProvider>(context, listen: false).projects;
      if (projs.isNotEmpty) _selectedProjectId = projs.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a project")));
      return;
    }

    setState(() => _isSaving = true);
    final payload = {
      "projectId": _selectedProjectId,
      "title": _titleController.text.trim(),
      "description": _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      "dueDate": _dueDateController.text.trim().isEmpty ? null : _dueDateController.text.trim(),
      "priority": _priority,
      "status": _status,
    };

    try {
      await Provider.of<TasksProvider>(context, listen: false).createTask(payload);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projs = Provider.of<ProjectsProvider>(context).projects;

    return AlertDialog(
      title: const Text("Create Task"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: const InputDecoration(labelText: "Project *"),
                items: projs.map((p) => DropdownMenuItem(value: p.id, child: Text(p.projectName))).toList(),
                onChanged: (val) => setState(() => _selectedProjectId = val),
                validator: (v) => v == null ? "Select project" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Task Title *"),
                validator: (v) => Validators.required(v, "Task title is required"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDateController,
                decoration: const InputDecoration(labelText: "Due Date (YYYY-MM-DD)"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: "Priority"),
                      items: ["Low", "Medium", "High", "Urgent"]
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: "Status"),
                      items: ["Todo", "In Progress", "Completed", "Blocked"]
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                  ),
                ],
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
              : const Text("Save Task"),
        ),
      ],
    );
  }
}
