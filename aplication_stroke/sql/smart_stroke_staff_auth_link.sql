-- ============================================================
-- SMART STROKE – Staff auth link + role resolution
-- Jalankan setelah smart_stroke_schema.sql & admin_extension.sql
-- AMAN dijalankan ulang (idempotent)
-- ============================================================

-- Apoteker boleh update auth_id sendiri saat email cocok (seed / login pertama)
DROP POLICY IF EXISTS pharm_update_own ON pharmacists;
CREATE POLICY pharm_update_own ON pharmacists
  FOR UPDATE
  USING (
    auth_id = auth.uid()
    OR (
      auth_id IS NULL
      AND lower(trim(email)) = lower(trim(coalesce(auth.jwt() ->> 'email', '')))
    )
  )
  WITH CHECK (auth_id = auth.uid());

-- Dokter boleh update auth_id sendiri saat email cocok
DROP POLICY IF EXISTS doctors_self_update ON doctors;
CREATE POLICY doctors_self_update ON doctors
  FOR UPDATE
  USING (
    auth_id = auth.uid()
    OR (
      auth_id IS NULL
      AND lower(trim(email)) = lower(trim(coalesce(auth.jwt() ->> 'email', '')))
    )
  )
  WITH CHECK (auth_id = auth.uid());

-- RPC: tentukan peran + auto-link auth_id via email (bypass RLS read issues)
CREATE OR REPLACE FUNCTION public.resolve_my_app_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid   UUID := auth.uid();
  v_email TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RETURN 'patient';
  END IF;

  IF EXISTS (SELECT 1 FROM admins WHERE auth_id = v_uid) THEN
    RETURN 'admin';
  END IF;

  v_email := lower(trim(coalesce(auth.jwt() ->> 'email', '')));

  IF EXISTS (
    SELECT 1 FROM pharmacists
    WHERE auth_id = v_uid
       OR (v_email <> '' AND lower(trim(email)) = v_email)
  ) THEN
    IF v_email <> '' THEN
      UPDATE pharmacists
      SET auth_id = v_uid
      WHERE lower(trim(email)) = v_email
        AND auth_id IS DISTINCT FROM v_uid;
    END IF;
    RETURN 'pharmacist';
  END IF;

  IF EXISTS (
    SELECT 1 FROM doctors
    WHERE auth_id = v_uid
       OR (v_email <> '' AND lower(trim(email)) = v_email)
  ) THEN
    IF v_email <> '' THEN
      UPDATE doctors
      SET auth_id = v_uid
      WHERE lower(trim(email)) = v_email
        AND auth_id IS DISTINCT FROM v_uid;
    END IF;
    RETURN 'doctor';
  END IF;

  RETURN 'patient';
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_my_app_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_my_app_role() TO authenticated;
