-- ============================================================
-- SMART STROKE – Akun login dummy (Supabase Auth)
-- Jalankan SETELAH smart_stroke_seed_dummy.sql
--
-- PASSWORD SEMUA AKUN: SmartStroke123!
--
-- Akun:
--   Admin     : admin@smartstroke.id
--   Pasien 1  : pasien.ahmad@email.com
--   Pasien 2  : pasien.dewi@email.com
--   Pasien 3  : pasien.hasan@email.com
--   Apoteker 1: apoteker.sari@farmasi.id
--   Apoteker 2: apoteker.budi@farmasi.id
--   Dokter 1  : dr.andi@rsstroke.id
--   Dokter 2  : dr.rina@rsstroke.id
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_instance_id UUID;
  v_password    TEXT := 'SmartStroke123!';
  rec RECORD;
BEGIN
  SELECT COALESCE(
    (SELECT instance_id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
  ) INTO v_instance_id;

  -- Lepaskan FK sebelum hapus auth.users (hindari CASCADE ke admins/doctors)
  UPDATE app_config
    SET updated_by = NULL
    WHERE updated_by = 'a0000001-0000-4000-8000-000000000001';

  UPDATE doctor_invitations
    SET used_by = NULL
    WHERE used_by IN (
      'd0000001-0000-4000-8000-000000000001',
      'd0000002-0000-4000-8000-000000000002'
    );

  UPDATE pharmacist_invitations
    SET used_by = NULL
    WHERE used_by IN (
      'b0000001-0000-4000-8000-000000000001',
      'b0000002-0000-4000-8000-000000000002'
    );

  UPDATE admins      SET auth_id = NULL WHERE id = 'a0000001-0000-4000-8000-000000000001';
  UPDATE pharmacists SET auth_id = NULL WHERE id IN (
    'b0000001-0000-4000-8000-000000000001',
    'b0000002-0000-4000-8000-000000000002'
  );
  UPDATE users SET auth_id = NULL WHERE id IN (
    'c0000001-0000-4000-8000-000000000001',
    'c0000002-0000-4000-8000-000000000002',
    'c0000003-0000-4000-8000-000000000003'
  );
  UPDATE doctors SET auth_id = NULL WHERE id IN (
    'd0000001-0000-4000-8000-000000000001',
    'd0000002-0000-4000-8000-000000000002'
  );

  -- Hapus akun dummy lama (aman dijalankan ulang)
  DELETE FROM auth.identities WHERE user_id IN (
    'a0000001-0000-4000-8000-000000000001',
    'b0000001-0000-4000-8000-000000000001',
    'b0000002-0000-4000-8000-000000000002',
    'c0000001-0000-4000-8000-000000000001',
    'c0000002-0000-4000-8000-000000000002',
    'c0000003-0000-4000-8000-000000000003',
    'd0000001-0000-4000-8000-000000000001',
    'd0000002-0000-4000-8000-000000000002'
  );
  DELETE FROM auth.users WHERE id IN (
    'a0000001-0000-4000-8000-000000000001',
    'b0000001-0000-4000-8000-000000000001',
    'b0000002-0000-4000-8000-000000000002',
    'c0000001-0000-4000-8000-000000000001',
    'c0000002-0000-4000-8000-000000000002',
    'c0000003-0000-4000-8000-000000000003',
    'd0000001-0000-4000-8000-000000000001',
    'd0000002-0000-4000-8000-000000000002'
  );

  FOR rec IN
    SELECT * FROM (VALUES
      ('a0000001-0000-4000-8000-000000000001'::UUID, 'admin@smartstroke.id',           'Admin Smart Stroke'),
      ('b0000001-0000-4000-8000-000000000001'::UUID, 'apoteker.sari@farmasi.id',     'Sari Wulandari'),
      ('b0000002-0000-4000-8000-000000000002'::UUID, 'apoteker.budi@farmasi.id',     'Budi Santoso'),
      ('c0000001-0000-4000-8000-000000000001'::UUID, 'pasien.ahmad@email.com',       'Ahmad Rizki'),
      ('c0000002-0000-4000-8000-000000000002'::UUID, 'pasien.dewi@email.com',        'Dewi Lestari'),
      ('c0000003-0000-4000-8000-000000000003'::UUID, 'pasien.hasan@email.com',       'Hasan Basri'),
      ('d0000001-0000-4000-8000-000000000001'::UUID, 'dr.andi@rsstroke.id',          'dr. Andi Pratama'),
      ('d0000002-0000-4000-8000-000000000002'::UUID, 'dr.rina@rsstroke.id',          'dr. Rina Kusuma')
    ) AS t(id, email, full_name)
  LOOP
    INSERT INTO auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token,
      is_super_admin
    ) VALUES (
      rec.id,
      v_instance_id,
      'authenticated',
      'authenticated',
      rec.email,
      crypt(v_password, gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('name', rec.full_name),
      NOW(),
      NOW(),
      '',
      '',
      '',
      '',
      FALSE
    );

    INSERT INTO auth.identities (
      id,
      user_id,
      provider_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      rec.id,
      rec.id,
      rec.id::TEXT,
      jsonb_build_object(
        'sub', rec.id::TEXT,
        'email', rec.email,
        'email_verified', TRUE,
        'phone_verified', FALSE
      ),
      'email',
      NOW(),
      NOW(),
      NOW()
    );
  END LOOP;
END $$;

-- Hubungkan auth_id ke tabel profil
UPDATE admins      SET auth_id = 'a0000001-0000-4000-8000-000000000001' WHERE email = 'admin@smartstroke.id';
UPDATE pharmacists SET auth_id = 'b0000001-0000-4000-8000-000000000001' WHERE email = 'apoteker.sari@farmasi.id';
UPDATE pharmacists SET auth_id = 'b0000002-0000-4000-8000-000000000002' WHERE email = 'apoteker.budi@farmasi.id';
UPDATE users       SET auth_id = 'c0000001-0000-4000-8000-000000000001' WHERE email = 'pasien.ahmad@email.com';
UPDATE users       SET auth_id = 'c0000002-0000-4000-8000-000000000002' WHERE email = 'pasien.dewi@email.com';
UPDATE users       SET auth_id = 'c0000003-0000-4000-8000-000000000003' WHERE email = 'pasien.hasan@email.com';
UPDATE doctors     SET auth_id = 'd0000001-0000-4000-8000-000000000001' WHERE email = 'dr.andi@rsstroke.id';
UPDATE doctors     SET auth_id = 'd0000002-0000-4000-8000-000000000002' WHERE email = 'dr.rina@rsstroke.id';

-- Sinkronkan auth_id dari email (jika UUID auth.users tidak sama dengan seed di atas)
UPDATE pharmacists p
SET auth_id = u.id
FROM auth.users u
WHERE lower(trim(p.email)) = lower(trim(u.email))
  AND (p.auth_id IS DISTINCT FROM u.id);

UPDATE doctors d
SET auth_id = u.id
FROM auth.users u
WHERE lower(trim(d.email)) = lower(trim(u.email))
  AND (d.auth_id IS DISTINCT FROM u.id);

UPDATE users usr
SET auth_id = u.id
FROM auth.users u
WHERE lower(trim(usr.email)) = lower(trim(u.email))
  AND (usr.auth_id IS DISTINCT FROM u.id);

UPDATE admins a
SET auth_id = u.id
FROM auth.users u
WHERE lower(trim(a.email)) = lower(trim(u.email))
  AND (a.auth_id IS DISTINCT FROM u.id);
