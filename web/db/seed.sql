INSERT INTO polling_station(station_id, station_name, zone, province) VALUES
('S001','Polling Station 1','Zone A','Trang'),
('S002','Polling Station 2','Zone B','Trang');

INSERT INTO violation_type(type_id, type_name, severity) VALUES
('V001','Vote Buying','High'),
('V002','Illegal Campaigning','Medium'),
('V003','Obstructing Voting','High'),
('V004','Misinformation','Low');

INSERT INTO incident_report(station_id, type_id, reporter_name, description, evidence_photo, timestamp, ai_result, ai_confidence) VALUES
('S001','V001','Niti','Observed suspected cash distribution near polling unit',NULL,'2026-02-20 09:00:00','fraud',0.92),
('S002','V004','Awa','Found a social post with misleading candidate information',NULL,'2026-02-20 09:05:00','normal',0.35);
