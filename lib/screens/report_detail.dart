import 'package:flutter/material.dart';

import '../services/sqlite_service.dart';
import 'report_form.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _loading = true;
  Map<String, Object?>? _row;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final row = await SqliteService.instance.getReportByIdJoin(widget.reportId);
    if (!mounted) return;
    setState(() {
      _row = row;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(editReportId: widget.reportId),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Report'),
          content: const Text('Are you sure you want to delete this report?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await SqliteService.instance.deleteReport(widget.reportId);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _item(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value?.toString().isNotEmpty == true ? value.toString() : '-'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report #${widget.reportId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _row == null
              ? const Center(child: Text('Report not found'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      _item('Reporter Name', _row!['reporter_name']),
                      _item('Polling Station', _row!['station_name']),
                      _item('Province', _row!['province']),
                      _item('Violation Type', _row!['type_name']),
                      _item('Severity', _row!['severity']),
                      _item('Description', _row!['description']),
                      _item('Evidence Photo', _row!['evidence_photo']),
                      _item('Timestamp', _row!['timestamp']),
                      _item('AI Result', _row!['ai_result']),
                      _item('AI Confidence', _row!['ai_confidence']),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _edit,
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _delete,
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
