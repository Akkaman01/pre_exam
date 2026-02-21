import 'package:flutter/material.dart';

import '../models/incident_report.dart';
import '../models/polling_station.dart';
import '../models/violation_type.dart';
import '../services/sqlite_service.dart';
import '../widgets/form_text_field.dart';

class ReportFormScreen extends StatefulWidget {
  final int? editReportId;

  const ReportFormScreen({super.key, this.editReportId});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _reporterCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _photoCtl = TextEditingController();
  final _aiResultCtl = TextEditingController();
  final _aiConfCtl = TextEditingController();

  List<PollingStation> _stations = [];
  List<ViolationType> _types = [];

  String? _stationId;
  String? _typeId;

  bool _loading = true;
  int? _reportId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _reporterCtl.dispose();
    _descCtl.dispose();
    _photoCtl.dispose();
    _aiResultCtl.dispose();
    _aiConfCtl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);

    final stations = await SqliteService.instance.getStations();
    final types = await SqliteService.instance.getViolationTypes();

    _stations = stations;
    _types = types;

    if (widget.editReportId != null) {
      final row = await SqliteService.instance.getReportByIdJoin(
        widget.editReportId!,
      );
      if (row != null) {
        _reportId = row['report_id'] as int;
        _stationId = row['station_id'] as String;
        _typeId = row['type_id'] as String;
        _reporterCtl.text = (row['reporter_name'] ?? '').toString();
        _descCtl.text = (row['description'] ?? '').toString();
        _photoCtl.text = (row['evidence_photo'] ?? '').toString();
        _aiResultCtl.text = (row['ai_result'] ?? '').toString();
        _aiConfCtl.text = row['ai_confidence']?.toString() ?? '';
      }
    } else {
      _stationId = _stations.isNotEmpty ? _stations.first.stationId : null;
      _typeId = _types.isNotEmpty ? _types.first.typeId : null;
    }

    setState(() => _loading = false);
  }

  String _nowText() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stationId == null || _typeId == null) return;

    final aiConf = _aiConfCtl.text.trim().isEmpty
        ? null
        : double.tryParse(_aiConfCtl.text.trim());

    final report = IncidentReport(
      reportId: _reportId,
      stationId: _stationId!,
      typeId: _typeId!,
      reporterName: _reporterCtl.text.trim(),
      description: _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
      evidencePhoto: _photoCtl.text.trim().isEmpty
          ? null
          : _photoCtl.text.trim(),
      timestamp: _nowText(),
      aiResult: _aiResultCtl.text.trim().isEmpty
          ? null
          : _aiResultCtl.text.trim(),
      aiConfidence: aiConf,
    );

    if (_reportId == null) {
      await SqliteService.instance.insertReport(report);
    } else {
      await SqliteService.instance.updateReport(report);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editReportId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Report' : 'Create Report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _stationId,
                      decoration: const InputDecoration(
                        labelText: 'Polling Station',
                        border: OutlineInputBorder(),
                      ),
                      items: _stations
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.stationId,
                              child: Text('${s.stationName} (${s.province})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _stationId = v),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please select a polling station'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _typeId,
                      decoration: const InputDecoration(
                        labelText: 'Violation Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _types
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.typeId,
                              child: Text('${t.typeName} (${t.severity})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _typeId = v),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please select a violation type'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      label: 'Reporter Name',
                      controller: _reporterCtl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter reporter name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      label: 'Description',
                      controller: _descCtl,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      label: 'Evidence Photo (path or file name)',
                      controller: _photoCtl,
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      label: 'AI Result (optional)',
                      controller: _aiResultCtl,
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      label: 'AI Confidence (optional, e.g. 0.92)',
                      controller: _aiConfCtl,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
