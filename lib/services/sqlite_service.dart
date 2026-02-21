import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/incident_report.dart';
import '../models/polling_station.dart';
import '../models/violation_type.dart';

class SqliteService {
  SqliteService._();
  static final SqliteService instance = SqliteService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pre_exam.db');
    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
    return _db!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE polling_station (
        station_id TEXT PRIMARY KEY,
        station_name TEXT NOT NULL,
        zone TEXT NOT NULL,
        province TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE violation_type (
        type_id TEXT PRIMARY KEY,
        type_name TEXT NOT NULL,
        severity TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incident_report (
        report_id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id TEXT NOT NULL,
        type_id TEXT NOT NULL,
        reporter_name TEXT NOT NULL,
        description TEXT,
        evidence_photo TEXT,
        timestamp TEXT NOT NULL,
        ai_result TEXT,
        ai_confidence REAL,
        FOREIGN KEY (station_id) REFERENCES polling_station(station_id),
        FOREIGN KEY (type_id) REFERENCES violation_type(type_id)
      )
    ''');
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();

    batch.insert('polling_station', {
      'station_id': 'S001',
      'station_name': 'Polling Station 1',
      'zone': 'Zone A',
      'province': 'Trang',
    });
    batch.insert('polling_station', {
      'station_id': 'S002',
      'station_name': 'Polling Station 2',
      'zone': 'Zone B',
      'province': 'Trang',
    });

    batch.insert('violation_type', {
      'type_id': 'V001',
      'type_name': 'Vote Buying',
      'severity': 'High',
    });
    batch.insert('violation_type', {
      'type_id': 'V002',
      'type_name': 'Illegal Campaigning',
      'severity': 'Medium',
    });
    batch.insert('violation_type', {
      'type_id': 'V003',
      'type_name': 'Obstructing Voting',
      'severity': 'High',
    });
    batch.insert('violation_type', {
      'type_id': 'V004',
      'type_name': 'Misinformation',
      'severity': 'Low',
    });

    batch.insert('incident_report', {
      'station_id': 'S001',
      'type_id': 'V001',
      'reporter_name': 'Niti',
      'description': 'Observed suspected cash distribution near polling unit',
      'evidence_photo': null,
      'timestamp': '2026-02-20 09:00:00',
      'ai_result': 'fraud',
      'ai_confidence': 0.92,
    });
    batch.insert('incident_report', {
      'station_id': 'S002',
      'type_id': 'V004',
      'reporter_name': 'Awa',
      'description': 'Found a social post with misleading candidate information',
      'evidence_photo': null,
      'timestamp': '2026-02-20 09:05:00',
      'ai_result': 'normal',
      'ai_confidence': 0.35,
    });

    await batch.commit(noResult: true);
  }

  Future<List<PollingStation>> getStations() async {
    final db = await database;
    final rows = await db.query('polling_station', orderBy: 'station_id ASC');
    return rows.map(PollingStation.fromMap).toList();
  }

  Future<List<ViolationType>> getViolationTypes() async {
    final db = await database;
    final rows = await db.query('violation_type', orderBy: 'type_id ASC');
    return rows.map(ViolationType.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> getReportsJoin({String keyword = ''}) async {
    final db = await database;
    const selectClause = '''
      SELECT
        r.report_id,
        r.station_id,
        r.type_id,
        r.reporter_name,
        r.description,
        r.evidence_photo,
        r.timestamp,
        r.ai_result,
        r.ai_confidence,
        s.station_name,
        s.province,
        v.type_name,
        v.severity
      FROM incident_report r
      JOIN polling_station s ON s.station_id = r.station_id
      JOIN violation_type v ON v.type_id = r.type_id
    ''';

    if (keyword.trim().isEmpty) {
      return db.rawQuery('$selectClause ORDER BY r.report_id DESC');
    }

    return db.rawQuery(
      '''
      $selectClause
      WHERE
        r.reporter_name LIKE ? OR
        r.description LIKE ? OR
        s.station_name LIKE ? OR
        v.type_name LIKE ?
      ORDER BY r.report_id DESC
      ''',
      List.filled(4, '%${keyword.trim()}%'),
    );
  }

  Future<Map<String, Object?>?> getReportByIdJoin(int reportId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        r.report_id,
        r.station_id,
        r.type_id,
        r.reporter_name,
        r.description,
        r.evidence_photo,
        r.timestamp,
        r.ai_result,
        r.ai_confidence,
        s.station_name,
        s.province,
        v.type_name,
        v.severity
      FROM incident_report r
      JOIN polling_station s ON s.station_id = r.station_id
      JOIN violation_type v ON v.type_id = r.type_id
      WHERE r.report_id = ?
      LIMIT 1
      ''',
      [reportId],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> insertReport(IncidentReport report) async {
    final db = await database;
    return db.insert('incident_report', report.toMap());
  }

  Future<int> updateReport(IncidentReport report) async {
    final db = await database;
    if (report.reportId == null) return 0;
    return db.update(
      'incident_report',
      report.toMap(),
      where: 'report_id = ?',
      whereArgs: [report.reportId],
    );
  }

  Future<int> deleteReport(int reportId) async {
    final db = await database;
    return db.delete(
      'incident_report',
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
  }
}
