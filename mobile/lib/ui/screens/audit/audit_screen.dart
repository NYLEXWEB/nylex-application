import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/audit_model.dart';
import '../../widgets/empty_view.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({Key? key}) : super(key: key);

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<AuditLogModel> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get(ApiConstants.auditLogs);
      if (res is List) {
        setState(() {
          _logs = res.map((item) => AuditLogModel.fromJson(item)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audit Trail & History"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLogs),
        ],
      ),
      body: _isLoading && _logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const EmptyView(
                  title: "No Audit Logs",
                  subtitle: "System actions and status changes are recorded here.",
                  icon: Icons.history,
                )
              : RefreshIndicator(
                  onRefresh: () async => _fetchLogs(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = _logs[index];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    log.action.replaceAll("_", " "),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accent),
                                  ),
                                  Text(
                                    Formatters.formatDateTime(log.timestamp),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(log.description, style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(
                                "By: ${log.userName} • Entity: ${log.entityType}",
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
