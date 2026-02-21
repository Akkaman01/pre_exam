CREATE TABLE IF NOT EXISTS polling_station (
  station_id TEXT PRIMARY KEY,
  station_name TEXT NOT NULL,
  zone TEXT NOT NULL,
  province TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS violation_type (
  type_id TEXT PRIMARY KEY,
  type_name TEXT NOT NULL,
  severity TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS incident_report (
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
);
