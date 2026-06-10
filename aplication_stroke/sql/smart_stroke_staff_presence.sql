-- ============================================================
-- SMART STROKE – Staff presence & duty shifts (realtime jaga)
-- Jalankan setelah smart_stroke_schema.sql + admin_extension.sql
-- AMAN dijalankan ulang (idempotent)
-- ============================================================

-- ── 1. PRESENCE (heartbeat online) ───────────────────────────
CREATE TABLE IF NOT EXISTS staff_presence (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id     UUID NOT NULL,
  staff_type   TEXT NOT NULL CHECK (staff_type IN ('pharmacist','doctor')),
  is_online    BOOLEAN NOT NULL DEFAULT FALSE,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (staff_id, staff_type)
);

CREATE INDEX IF NOT EXISTS idx_staff_presence_type ON staff_presence(staff_type);
CREATE INDEX IF NOT EXISTS idx_staff_presence_seen  ON staff_presence(last_seen_at DESC);

-- ── 2. JADWAL JAGA ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS staff_duty_shifts (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id     UUID NOT NULL,
  staff_type   TEXT NOT NULL CHECK (staff_type IN ('pharmacist','doctor')),
  day_of_week  INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time   TIME NOT NULL,
  end_time     TIME NOT NULL,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_staff_shifts_lookup
  ON staff_duty_shifts(staff_type, day_of_week, is_active);

-- ── 3. RLS ───────────────────────────────────────────────────
ALTER TABLE staff_presence    ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_duty_shifts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS staff_presence_read ON staff_presence;
CREATE POLICY staff_presence_read ON staff_presence
  FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS staff_presence_pharm_manage ON staff_presence;
CREATE POLICY staff_presence_pharm_manage ON staff_presence
  FOR ALL TO authenticated
  USING (
    staff_type = 'pharmacist'
    AND staff_id IN (SELECT id FROM pharmacists WHERE auth_id = auth.uid())
  )
  WITH CHECK (
    staff_type = 'pharmacist'
    AND staff_id IN (SELECT id FROM pharmacists WHERE auth_id = auth.uid())
  );

DROP POLICY IF EXISTS staff_presence_doctor_manage ON staff_presence;
CREATE POLICY staff_presence_doctor_manage ON staff_presence
  FOR ALL TO authenticated
  USING (
    staff_type = 'doctor'
    AND staff_id IN (SELECT id FROM doctors WHERE auth_id = auth.uid())
  )
  WITH CHECK (
    staff_type = 'doctor'
    AND staff_id IN (SELECT id FROM doctors WHERE auth_id = auth.uid())
  );

DROP POLICY IF EXISTS staff_shifts_read ON staff_duty_shifts;
CREATE POLICY staff_shifts_read ON staff_duty_shifts
  FOR SELECT TO authenticated USING (TRUE);

-- ── 4. SEED JADWAL & PRESENCE (dummy) ────────────────────────
-- day_of_week: 0=Minggu … 6=Sabtu (sama dengan PostgreSQL EXTRACT(DOW))

DELETE FROM staff_duty_shifts
WHERE staff_id IN (
  'b0000001-0000-4000-8000-000000000001',
  'b0000002-0000-4000-8000-000000000002',
  'd0000001-0000-4000-8000-000000000001',
  'd0000002-0000-4000-8000-000000000002'
);

INSERT INTO staff_duty_shifts (staff_id, staff_type, day_of_week, start_time, end_time)
SELECT v.staff_id, v.staff_type, d.dow, v.start_time, v.end_time
FROM (VALUES
  ('b0000001-0000-4000-8000-000000000001'::UUID, 'pharmacist', TIME '08:00', TIME '16:00'),
  ('b0000002-0000-4000-8000-000000000002'::UUID, 'pharmacist', TIME '10:00', TIME '18:00'),
  ('d0000001-0000-4000-8000-000000000001'::UUID, 'doctor',     TIME '07:00', TIME '15:00'),
  ('d0000002-0000-4000-8000-000000000002'::UUID, 'doctor',     TIME '09:00', TIME '17:00')
) AS v(staff_id, staff_type, start_time, end_time)
CROSS JOIN generate_series(1, 5) AS d(dow);

INSERT INTO staff_duty_shifts (staff_id, staff_type, day_of_week, start_time, end_time) VALUES
  ('b0000002-0000-4000-8000-000000000002', 'pharmacist', 6, '10:00', '14:00'),
  ('d0000002-0000-4000-8000-000000000002', 'doctor',     6, '09:00', '13:00');

-- Presence awal: apoteker & dokter "online" untuk demo
INSERT INTO staff_presence (staff_id, staff_type, is_online, last_seen_at) VALUES
  ('b0000001-0000-4000-8000-000000000001', 'pharmacist', TRUE, NOW()),
  ('b0000002-0000-4000-8000-000000000002', 'pharmacist', FALSE, NOW() - INTERVAL '2 hours'),
  ('d0000001-0000-4000-8000-000000000001', 'doctor',     TRUE, NOW()),
  ('d0000002-0000-4000-8000-000000000002', 'doctor',     FALSE, NOW() - INTERVAL '30 minutes')
ON CONFLICT (staff_id, staff_type) DO UPDATE SET
  is_online    = EXCLUDED.is_online,
  last_seen_at = EXCLUDED.last_seen_at;
