import 'package:flutter/material.dart';

import '../services/sqlite_service.dart';
import '../widgets/search_bar.dart';
import 'report_detail.dart';
import 'report_form.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final _searchCtl = TextEditingController();
  bool _loading = true;
  List<Map<String, Object?>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load({String keyword = ''}) async {
    setState(() => _loading = true);
    final rows = await SqliteService.instance.getReportsJoin(keyword: keyword);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ReportFormScreen()),
    );
    if (changed == true) {
      await _load(keyword: _searchCtl.text);
    }
  }

  Future<void> _openDetail(int reportId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReportDetailScreen(reportId: reportId)),
    );
    if (changed == true) {
      await _load(keyword: _searchCtl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident Reports')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppSearchBar(
              controller: _searchCtl,
              onChanged: (v) => _load(keyword: v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                      ? const Center(child: Text('No reports found'))
                      : ListView.separated(
                          itemCount: _rows.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final row = _rows[index];
                            final reportId = row['report_id'] as int;
                            final reporterName = (row['reporter_name'] ?? '').toString();
                            final typeName = (row['type_name'] ?? '').toString();
                            final stationName = (row['station_name'] ?? '').toString();
                            final timestamp = (row['timestamp'] ?? '').toString();

                            return Card(
                              child: ListTile(
                                title: Text('$reporterName - $typeName'),
                                subtitle: Text('$stationName\n$timestamp'),
                                isThreeLine: true,
                                onTap: () => _openDetail(reportId),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
