import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade800;

    final lower = status.toLowerCase();
    if (lower == 'won' || lower == 'active' || lower == 'completed' || lower == 'delivered' || lower == 'paid') {
      bg = AppColors.successLight;
      text = AppColors.success;
    } else if (lower == 'pending' || lower == 'proposal' || lower == 'negotiation' || lower == 'partially paid' || lower == 'in progress') {
      bg = AppColors.warningLight;
      text = AppColors.warning;
    } else if (lower == 'urgent' || lower == 'overdue' || lower == 'rejected' || lower == 'cancelled' || lower == 'lost') {
      bg = AppColors.dangerLight;
      text = AppColors.danger;
    } else if (lower == 'new' || lower == 'planning' || lower == 'draft') {
      bg = AppColors.purpleLight;
      text = AppColors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
