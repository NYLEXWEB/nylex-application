import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_view.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({Key? key}) : super(key: key);

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  Map<String, List<dynamic>> _results = {};
  bool _isSearching = false;
  String _lastQuery = "";

  void _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _isSearching = true;
      _lastQuery = q;
    });

    try {
      final res = await ApiClient.get("${ApiConstants.search}?q=$q");
      if (res is Map<String, dynamic>) {
        setState(() {
          _results = res.map((k, v) => MapEntry(k, v as List<dynamic>));
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  int get _totalCount => _results.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search clients, leads, projects, invoices...",
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _lastQuery.isEmpty
              ? const EmptyView(
                  title: "Global Business Search",
                  subtitle: "Search across all 7 NYLEX entity records in one place.",
                  icon: Icons.search,
                )
              : _totalCount == 0
                  ? EmptyView(
                      title: "No Results for '$_lastQuery'",
                      subtitle: "Try searching with a business name, contact, or ID.",
                      icon: Icons.search_off,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildCategorySection("Clients", _results['clients']),
                        _buildCategorySection("Leads", _results['leads']),
                        _buildCategorySection("Projects", _results['projects']),
                        _buildCategorySection("Tasks", _results['tasks']),
                        _buildCategorySection("Invoices", _results['invoices']),
                        _buildCategorySection("Quotations", _results['quotations']),
                        _buildCategorySection("Payments", _results['payments']),
                      ],
                    ),
    );
  }

  Widget _buildCategorySection(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "$title (${items.length})",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
          ),
        ),
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(item['subtitle'] ?? ''),
                trailing: item['status'] != null ? StatusChip(status: item['status']) : null,
              ),
            )),
        const SizedBox(height: 12),
      ],
    );
  }
}
