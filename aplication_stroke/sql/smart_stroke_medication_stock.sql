-- ============================================================
-- SMART STROKE – Stok obat pasien (quantity tracking)
-- Jalankan setelah smart_stroke_schema.sql
-- AMAN dijalankan ulang (idempotent)
-- ============================================================

ALTER TABLE user_medications
  ADD COLUMN IF NOT EXISTS quantity_total     INT NOT NULL DEFAULT 30,
  ADD COLUMN IF NOT EXISTS quantity_remaining INT NOT NULL DEFAULT 30;

-- Set stok awal untuk data dummy yang sudah ada
UPDATE user_medications
SET
  quantity_total = 30,
  quantity_remaining = 30
WHERE quantity_remaining IS NULL OR quantity_remaining = 30;
