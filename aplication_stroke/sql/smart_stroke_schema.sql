-- ============================================================
-- SMART STROKE – Complete Supabase Database Schema v2
-- Urutan CREATE TABLE diperbaiki: tidak ada forward reference
--
-- HANYA untuk database BARU (sekali saja).
-- Jika sudah pernah dijalankan, LEWATI file ini dan lanjut ke
-- smart_stroke_admin_extension.sql
-- ============================================================

DO $$
BEGIN
  IF to_regclass('public.admins') IS NOT NULL THEN
    RAISE EXCEPTION
      'Schema sudah terpasang (tabel admins ada). Lewati smart_stroke_schema.sql dan jalankan file SQL berikutnya saja.';
  END IF;
END $$;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. ADMINS (tidak ada FK ke tabel lain)
CREATE TABLE admins (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id    UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email      TEXT UNIQUE NOT NULL,
  name       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. PHARMACISTS (tidak ada FK ke users/admins)
CREATE TABLE pharmacists (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id          UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email            TEXT UNIQUE NOT NULL,
  name             TEXT NOT NULL,
  phone            TEXT,
  profile_picture  TEXT,
  license_number   TEXT UNIQUE,
  pharmacy_name    TEXT,
  pharmacy_address TEXT,
  pharmacy_lat     DOUBLE PRECISION,
  pharmacy_lng     DOUBLE PRECISION,
  is_verified      BOOLEAN NOT NULL DEFAULT FALSE,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  fcm_token        TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. USERS (FK ke pharmacists — dibuat setelah pharmacists)
CREATE TABLE users (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id                 UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email                   TEXT UNIQUE NOT NULL,
  name                    TEXT NOT NULL,
  phone                   TEXT,
  date_of_birth           DATE,
  gender                  TEXT CHECK (gender IN ('male','female','other')),
  profile_picture         TEXT,
  address                 TEXT,
  emergency_contact_name  TEXT,
  emergency_contact_phone TEXT,
  stroke_date             DATE,
  stroke_type             TEXT CHECK (stroke_type IN ('ischemic','hemorrhagic','tia','unknown')),
  blood_type              TEXT CHECK (blood_type IN ('A','B','AB','O','unknown')),
  height_cm               NUMERIC(5,2),
  weight_kg               NUMERIC(5,2),
  paired_pharmacist_id    UUID REFERENCES pharmacists(id) ON DELETE SET NULL,
  role                    TEXT NOT NULL DEFAULT 'patient' CHECK (role IN ('patient','pharmacist','admin')),
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  fcm_token               TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. PHARMACIST_INVITATIONS (FK ke admins & pharmacists)
CREATE TABLE pharmacist_invitations (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  token      TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  email      TEXT,
  created_by UUID NOT NULL REFERENCES admins(id),
  used_by    UUID REFERENCES pharmacists(id),
  used_at    TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  is_used    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. PAIRINGS (FK ke users & pharmacists)
CREATE TABLE pairings (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pharmacist_id UUID NOT NULL REFERENCES pharmacists(id) ON DELETE CASCADE,
  status        TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','accepted','rejected','ended')),
  requested_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at  TIMESTAMPTZ,
  ended_at      TIMESTAMPTZ,
  notes         TEXT,
  UNIQUE(patient_id, pharmacist_id)
);

-- 6. CHAT_ROOMS (last_message_id ditambah via ALTER setelah messages dibuat)
CREATE TABLE chat_rooms (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pharmacist_id        UUID NOT NULL REFERENCES pharmacists(id) ON DELETE CASCADE,
  last_message_id      UUID,
  unread_by_patient    INT NOT NULL DEFAULT 0,
  unread_by_pharmacist INT NOT NULL DEFAULT 0,
  is_active            BOOLEAN NOT NULL DEFAULT TRUE,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(patient_id, pharmacist_id)
);

-- 7. MESSAGES (FK ke chat_rooms)
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_room_id    UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL,
  sender_role     TEXT NOT NULL CHECK (sender_role IN ('patient','pharmacist')),
  content         TEXT,
  attachment_url  TEXT,
  attachment_type TEXT CHECK (attachment_type IN ('image','document','audio')),
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE chat_rooms
  ADD CONSTRAINT fk_last_message
  FOREIGN KEY (last_message_id) REFERENCES messages(id) ON DELETE SET NULL;

-- 8. POSTS
CREATE TABLE posts (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content        TEXT NOT NULL,
  image_url      TEXT,
  category       TEXT DEFAULT 'general'
                 CHECK (category IN ('general','tips','story','question','motivation')),
  likes_count    INT NOT NULL DEFAULT 0,
  comments_count INT NOT NULL DEFAULT 0,
  is_pinned      BOOLEAN NOT NULL DEFAULT FALSE,
  is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. LIKES
CREATE TABLE likes (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 10. COMMENTS
CREATE TABLE comments (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_id  UUID REFERENCES comments(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. MEDICATIONS (master, tidak ada FK ke tabel lain)
CREATE TABLE medications (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name              TEXT NOT NULL,
  generic_name      TEXT,
  category          TEXT,
  dosage_form       TEXT CHECK (dosage_form IN ('tablet','kapsul','sirup','injeksi','patch','inhaler','tetes','salep')),
  strength          TEXT,
  manufacturer      TEXT,
  description       TEXT,
  side_effects      TEXT,
  contraindications TEXT,
  image_url         TEXT,
  bpom_number       TEXT,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. USER_MEDICATIONS (FK ke users, medications, pharmacists)
CREATE TABLE user_medications (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  medication_id UUID REFERENCES medications(id) ON DELETE SET NULL,
  custom_name   TEXT,
  dosage        TEXT NOT NULL,
  unit          TEXT,
  instructions  TEXT,
  prescribed_by UUID REFERENCES pharmacists(id) ON DELETE SET NULL,
  start_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date      DATE,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. MEDICATION_REMINDERS
CREATE TABLE medication_reminders (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_medication_id UUID REFERENCES user_medications(id) ON DELETE CASCADE,
  medication_name    TEXT NOT NULL,
  dosage             TEXT NOT NULL,
  reminder_times     JSONB NOT NULL DEFAULT '[]',
  days_of_week       INT[] DEFAULT '{0,1,2,3,4,5,6}',
  is_active          BOOLEAN NOT NULL DEFAULT TRUE,
  sound_enabled      BOOLEAN NOT NULL DEFAULT TRUE,
  vibration_enabled  BOOLEAN NOT NULL DEFAULT TRUE,
  notes              TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. MEDICATION_LOGS
CREATE TABLE medication_logs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reminder_id     UUID REFERENCES medication_reminders(id) ON DELETE SET NULL,
  medication_name TEXT NOT NULL,
  scheduled_time  TIMESTAMPTZ NOT NULL,
  taken_at        TIMESTAMPTZ,
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','taken','skipped','missed')),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. HEALTH_LOGS
CREATE TABLE health_logs (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  log_date           DATE NOT NULL DEFAULT CURRENT_DATE,
  log_time           TIMETZ,
  systolic_bp        INT,
  diastolic_bp       INT,
  heart_rate         INT,
  blood_sugar        NUMERIC(6,2),
  oxygen_saturation  NUMERIC(5,2),
  temperature        NUMERIC(4,1),
  weight_kg          NUMERIC(5,2),
  has_headache       BOOLEAN DEFAULT FALSE,
  has_dizziness      BOOLEAN DEFAULT FALSE,
  has_nausea         BOOLEAN DEFAULT FALSE,
  has_weakness       BOOLEAN DEFAULT FALSE,
  has_vision_problem BOOLEAN DEFAULT FALSE,
  has_speech_problem BOOLEAN DEFAULT FALSE,
  pain_level         INT CHECK (pain_level BETWEEN 0 AND 10),
  mood               TEXT CHECK (mood IN ('very_bad','bad','neutral','good','very_good')),
  notes              TEXT,
  input_method       TEXT DEFAULT 'manual' CHECK (input_method IN ('manual','sensor','wearable')),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 16. SENSOR_DATA
CREATE TABLE sensor_data (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id     TEXT,
  sensor_type   TEXT NOT NULL CHECK (sensor_type IN ('heart_rate','blood_pressure','spo2','temperature','accelerometer','gyroscope')),
  value_raw     JSONB NOT NULL,
  value_numeric NUMERIC,
  unit          TEXT,
  recorded_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  synced_at     TIMESTAMPTZ
);

-- 17. REHAB_PHASES (master)
CREATE TABLE rehab_phases (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phase_number   INT UNIQUE NOT NULL,
  name           TEXT NOT NULL,
  description    TEXT,
  duration_weeks INT,
  required_score INT DEFAULT 0,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 18. REHAB_EXERCISES
CREATE TABLE rehab_exercises (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phase_id         UUID NOT NULL REFERENCES rehab_phases(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  description      TEXT,
  instructions     TEXT,
  video_url        TEXT,
  thumbnail_url    TEXT,
  duration_seconds INT,
  repetitions      INT,
  sets             INT DEFAULT 1,
  category         TEXT CHECK (category IN ('motorik','kognitif','keseimbangan','pernapasan','bicara','lainnya')),
  difficulty       TEXT CHECK (difficulty IN ('mudah','sedang','sulit')),
  order_index      INT DEFAULT 0,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 19. REHAB_USER_PROGRESS
CREATE TABLE rehab_user_progress (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  current_phase_id  UUID NOT NULL REFERENCES rehab_phases(id),
  total_score       INT NOT NULL DEFAULT 0,
  total_sessions    INT NOT NULL DEFAULT 0,
  total_minutes     INT NOT NULL DEFAULT 0,
  streak_days       INT NOT NULL DEFAULT 0,
  last_session_date DATE,
  started_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 20. REHAB_EXERCISE_LOGS
CREATE TABLE rehab_exercise_logs (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_id      UUID NOT NULL REFERENCES rehab_exercises(id),
  session_date     DATE NOT NULL DEFAULT CURRENT_DATE,
  duration_seconds INT,
  repetitions_done INT,
  sets_done        INT,
  score            INT DEFAULT 0,
  is_completed     BOOLEAN NOT NULL DEFAULT FALSE,
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 21. REHAB_QUIZ_QUESTIONS
CREATE TABLE rehab_quiz_questions (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phase_id       UUID REFERENCES rehab_phases(id) ON DELETE CASCADE,
  question_text  TEXT NOT NULL,
  question_type  TEXT NOT NULL CHECK (question_type IN ('multiple_choice','true_false','fill_blank','image_choice')),
  options        JSONB,
  correct_answer TEXT NOT NULL,
  explanation    TEXT,
  points         INT NOT NULL DEFAULT 10,
  difficulty     TEXT CHECK (difficulty IN ('mudah','sedang','sulit')),
  category       TEXT,
  order_index    INT DEFAULT 0,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 22. REHAB_QUIZ_ATTEMPTS
CREATE TABLE rehab_quiz_attempts (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  phase_id           UUID NOT NULL REFERENCES rehab_phases(id),
  answers            JSONB NOT NULL DEFAULT '{}',
  score              INT NOT NULL DEFAULT 0,
  total_questions    INT NOT NULL,
  correct_answers    INT NOT NULL DEFAULT 0,
  time_taken_seconds INT,
  is_passed          BOOLEAN NOT NULL DEFAULT FALSE,
  attempted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 23. EDUCATION_CONTENTS
CREATE TABLE education_contents (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title         TEXT NOT NULL,
  slug          TEXT UNIQUE,
  category      TEXT NOT NULL CHECK (category IN ('pencegahan','penanganan','rehabilitasi','nutrisi','olahraga','obat','lainnya')),
  content_type  TEXT NOT NULL CHECK (content_type IN ('article','video','infographic','quiz')),
  summary       TEXT,
  content       TEXT,
  video_url     TEXT,
  thumbnail_url TEXT,
  author        TEXT,
  source        TEXT,
  tags          TEXT[],
  view_count    INT NOT NULL DEFAULT 0,
  is_published  BOOLEAN NOT NULL DEFAULT TRUE,
  published_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 24. NOTIFICATIONS
CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('medication','health','rehab','chat','community','pairing','system','emergency')),
  data       JSONB,
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  read_at    TIMESTAMPTZ,
  sent_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 25. EMERGENCY_LOGS
CREATE TABLE emergency_logs (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_type       TEXT NOT NULL CHECK (event_type IN ('call','location_share','sos','fall_detected')),
  latitude         DOUBLE PRECISION,
  longitude        DOUBLE PRECISION,
  address          TEXT,
  contacted_number TEXT,
  contacted_name   TEXT,
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 26. USER_SETTINGS
CREATE TABLE user_settings (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id              UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  language             TEXT NOT NULL DEFAULT 'id' CHECK (language IN ('id','en')),
  theme                TEXT NOT NULL DEFAULT 'light' CHECK (theme IN ('light','dark','system')),
  font_size            TEXT NOT NULL DEFAULT 'medium' CHECK (font_size IN ('small','medium','large')),
  notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  medication_notif     BOOLEAN NOT NULL DEFAULT TRUE,
  health_notif         BOOLEAN NOT NULL DEFAULT TRUE,
  rehab_notif          BOOLEAN NOT NULL DEFAULT TRUE,
  community_notif      BOOLEAN NOT NULL DEFAULT TRUE,
  sound_enabled        BOOLEAN NOT NULL DEFAULT TRUE,
  vibration_enabled    BOOLEAN NOT NULL DEFAULT TRUE,
  biometric_enabled    BOOLEAN NOT NULL DEFAULT FALSE,
  data_sharing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 27. APP_CONFIG
CREATE TABLE app_config (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key         TEXT UNIQUE NOT NULL,
  value       TEXT NOT NULL,
  description TEXT,
  is_public   BOOLEAN NOT NULL DEFAULT FALSE,
  updated_by  UUID REFERENCES admins(id),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_users_auth_id            ON users(auth_id);
CREATE INDEX idx_users_paired_pharmacist  ON users(paired_pharmacist_id);
CREATE INDEX idx_pharmacists_auth_id      ON pharmacists(auth_id);
CREATE INDEX idx_pairings_patient         ON pairings(patient_id);
CREATE INDEX idx_pairings_pharmacist      ON pairings(pharmacist_id);
CREATE INDEX idx_pairings_status          ON pairings(status);
CREATE INDEX idx_chat_rooms_patient       ON chat_rooms(patient_id);
CREATE INDEX idx_chat_rooms_pharmacist    ON chat_rooms(pharmacist_id);
CREATE INDEX idx_messages_chat_room       ON messages(chat_room_id);
CREATE INDEX idx_messages_created_at      ON messages(created_at DESC);
CREATE INDEX idx_posts_user_id            ON posts(user_id);
CREATE INDEX idx_posts_created_at         ON posts(created_at DESC);
CREATE INDEX idx_posts_category           ON posts(category);
CREATE INDEX idx_likes_post_user          ON likes(post_id, user_id);
CREATE INDEX idx_comments_post_id         ON comments(post_id);
CREATE INDEX idx_med_reminders_user       ON medication_reminders(user_id);
CREATE INDEX idx_med_logs_user            ON medication_logs(user_id);
CREATE INDEX idx_med_logs_scheduled       ON medication_logs(scheduled_time);
CREATE INDEX idx_health_logs_user_date    ON health_logs(user_id, log_date DESC);
CREATE INDEX idx_sensor_data_user         ON sensor_data(user_id);
CREATE INDEX idx_sensor_data_recorded     ON sensor_data(recorded_at DESC);
CREATE INDEX idx_rehab_ex_logs_user       ON rehab_exercise_logs(user_id);
CREATE INDEX idx_rehab_ex_logs_date       ON rehab_exercise_logs(session_date DESC);
CREATE INDEX idx_quiz_attempts_user       ON rehab_quiz_attempts(user_id);
CREATE INDEX idx_notifications_user       ON notifications(user_id);
CREATE INDEX idx_notifications_unread     ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_emergency_logs_user      ON emergency_logs(user_id);

-- ============================================================
-- TRIGGERS
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at         BEFORE UPDATE ON users               FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_pharmacists_updated_at   BEFORE UPDATE ON pharmacists         FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_chat_rooms_updated_at    BEFORE UPDATE ON chat_rooms          FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_posts_updated_at         BEFORE UPDATE ON posts               FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_comments_updated_at      BEFORE UPDATE ON comments            FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_user_medications_updated BEFORE UPDATE ON user_medications     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_med_reminders_updated    BEFORE UPDATE ON medication_reminders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_rehab_progress_updated   BEFORE UPDATE ON rehab_user_progress  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_education_updated        BEFORE UPDATE ON education_contents   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_user_settings_updated    BEFORE UPDATE ON user_settings        FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_likes_count AFTER INSERT OR DELETE ON likes FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_comments_count AFTER INSERT OR DELETE ON comments FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

CREATE OR REPLACE FUNCTION update_chat_room_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_rooms
  SET
    last_message_id      = NEW.id,
    updated_at           = NOW(),
    unread_by_patient    = CASE WHEN NEW.sender_role = 'pharmacist' THEN unread_by_patient + 1    ELSE unread_by_patient    END,
    unread_by_pharmacist = CASE WHEN NEW.sender_role = 'patient'    THEN unread_by_pharmacist + 1 ELSE unread_by_pharmacist END
  WHERE id = NEW.chat_room_id;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_chat_room_message AFTER INSERT ON messages FOR EACH ROW EXECUTE FUNCTION update_chat_room_on_message();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE admins                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacists             ENABLE ROW LEVEL SECURITY;
ALTER TABLE users                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacist_invitations  ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairings                ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms              ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages                ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments                ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications             ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_medications        ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_reminders    ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_logs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_data             ENABLE ROW LEVEL SECURITY;
ALTER TABLE rehab_phases            ENABLE ROW LEVEL SECURITY;
ALTER TABLE rehab_exercises         ENABLE ROW LEVEL SECURITY;
ALTER TABLE rehab_user_progress     ENABLE ROW LEVEL SECURITY;
ALTER TABLE rehab_exercise_logs     ENABLE ROW LEVEL SECURITY;
ALTER TABLE rehab_quiz_questions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE rehab_quiz_attempts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE education_contents      ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications           ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_logs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings           ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_config              ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION auth_user_id() RETURNS UUID AS $$
  SELECT id FROM users WHERE auth_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION auth_pharmacist_id() RETURNS UUID AS $$
  SELECT id FROM pharmacists WHERE auth_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION auth_is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM admins WHERE auth_id = auth.uid());
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- USERS
CREATE POLICY users_select_own    ON users FOR SELECT USING (auth_id = auth.uid() OR auth_is_admin());
CREATE POLICY users_insert_own    ON users FOR INSERT WITH CHECK (auth_id = auth.uid());
CREATE POLICY users_update_own    ON users FOR UPDATE USING (auth_id = auth.uid());
CREATE POLICY users_select_paired ON users FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM pairings p
    WHERE p.patient_id = users.id
      AND p.pharmacist_id = auth_pharmacist_id()
      AND p.status = 'accepted'
  ));

-- PHARMACISTS
CREATE POLICY pharm_select_all ON pharmacists FOR SELECT USING (TRUE);
CREATE POLICY pharm_insert_own ON pharmacists FOR INSERT WITH CHECK (auth_id = auth.uid());
CREATE POLICY pharm_update_own ON pharmacists FOR UPDATE USING (auth_id = auth.uid());

-- ADMINS
CREATE POLICY admins_select_own ON admins FOR SELECT USING (auth_id = auth.uid());

-- PHARMACIST_INVITATIONS
CREATE POLICY inv_admin    ON pharmacist_invitations FOR ALL USING (auth_is_admin());
CREATE POLICY inv_read_all ON pharmacist_invitations FOR SELECT USING (TRUE);

-- PAIRINGS
CREATE POLICY pair_select ON pairings FOR SELECT
  USING (patient_id = auth_user_id() OR pharmacist_id = auth_pharmacist_id() OR auth_is_admin());
CREATE POLICY pair_insert ON pairings FOR INSERT
  WITH CHECK (patient_id = auth_user_id() OR pharmacist_id = auth_pharmacist_id());
CREATE POLICY pair_update ON pairings FOR UPDATE
  USING (patient_id = auth_user_id() OR pharmacist_id = auth_pharmacist_id());

-- CHAT
CREATE POLICY chat_rooms_select ON chat_rooms FOR SELECT
  USING (patient_id = auth_user_id() OR pharmacist_id = auth_pharmacist_id());
CREATE POLICY chat_rooms_insert ON chat_rooms FOR INSERT
  WITH CHECK (patient_id = auth_user_id() OR pharmacist_id = auth_pharmacist_id());
CREATE POLICY messages_select ON messages FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM chat_rooms cr WHERE cr.id = messages.chat_room_id
      AND (cr.patient_id = auth_user_id() OR cr.pharmacist_id = auth_pharmacist_id())
  ));
CREATE POLICY messages_insert ON messages FOR INSERT
  WITH CHECK (sender_id = auth_user_id() OR sender_id = auth_pharmacist_id());

-- POSTS
CREATE POLICY posts_select ON posts FOR SELECT USING (is_deleted = FALSE OR user_id = auth_user_id() OR auth_is_admin());
CREATE POLICY posts_insert ON posts FOR INSERT WITH CHECK (user_id = auth_user_id());
CREATE POLICY posts_update ON posts FOR UPDATE USING (user_id = auth_user_id() OR auth_is_admin());
CREATE POLICY posts_delete ON posts FOR DELETE USING (user_id = auth_user_id() OR auth_is_admin());

-- LIKES & COMMENTS
CREATE POLICY likes_select  ON likes    FOR SELECT USING (TRUE);
CREATE POLICY likes_insert  ON likes    FOR INSERT WITH CHECK (user_id = auth_user_id());
CREATE POLICY likes_delete  ON likes    FOR DELETE USING (user_id = auth_user_id());
CREATE POLICY comments_select ON comments FOR SELECT USING (TRUE);
CREATE POLICY comments_insert ON comments FOR INSERT WITH CHECK (user_id = auth_user_id());
CREATE POLICY comments_update ON comments FOR UPDATE USING (user_id = auth_user_id());

-- HEALTH DATA
CREATE POLICY health_logs_own ON health_logs FOR ALL
  USING (user_id = auth_user_id() OR EXISTS (
    SELECT 1 FROM pairings p WHERE p.patient_id = health_logs.user_id
      AND p.pharmacist_id = auth_pharmacist_id()
      AND p.status = 'accepted'
  ));
CREATE POLICY sensor_data_own ON sensor_data FOR ALL USING (user_id = auth_user_id());

-- MEDICATIONS
CREATE POLICY medications_read_all ON medications      FOR SELECT USING (TRUE);
CREATE POLICY user_meds_own        ON user_medications FOR ALL
  USING (user_id = auth_user_id() OR prescribed_by = auth_pharmacist_id());

-- REMINDERS & LOGS
CREATE POLICY med_rem_own ON medication_reminders FOR ALL USING (user_id = auth_user_id());
CREATE POLICY med_log_own ON medication_logs      FOR ALL USING (user_id = auth_user_id());

-- REHAB
CREATE POLICY rehab_phases_read    ON rehab_phases        FOR SELECT USING (TRUE);
CREATE POLICY rehab_exercises_read ON rehab_exercises      FOR SELECT USING (TRUE);
CREATE POLICY rehab_progress_own   ON rehab_user_progress  FOR ALL USING (user_id = auth_user_id());
CREATE POLICY rehab_ex_logs_own    ON rehab_exercise_logs  FOR ALL USING (user_id = auth_user_id());
CREATE POLICY rehab_quiz_q_read    ON rehab_quiz_questions FOR SELECT USING (TRUE);
CREATE POLICY rehab_quiz_att_own   ON rehab_quiz_attempts  FOR ALL USING (user_id = auth_user_id());

-- EDUCATION
CREATE POLICY edu_read_published ON education_contents FOR SELECT USING (is_published = TRUE OR auth_is_admin());
CREATE POLICY edu_manage_admin   ON education_contents FOR ALL    USING (auth_is_admin());

-- NOTIFICATIONS, EMERGENCY, SETTINGS, CONFIG
CREATE POLICY notif_own     ON notifications FOR ALL USING (user_id = auth_user_id());
CREATE POLICY emergency_own ON emergency_logs FOR ALL USING (user_id = auth_user_id());
CREATE POLICY settings_own  ON user_settings  FOR ALL USING (user_id = auth_user_id());
CREATE POLICY config_public ON app_config     FOR SELECT USING (is_public = TRUE);
CREATE POLICY config_admin  ON app_config     FOR ALL    USING (auth_is_admin());

-- ============================================================
-- SEED DATA
-- ============================================================
INSERT INTO rehab_phases (phase_number, name, description, duration_weeks) VALUES
  (1, 'Fase Akut',         'Latihan ringan untuk pasien yang baru pulih dari stroke', 4),
  (2, 'Fase Sub-akut',     'Latihan peningkatan kekuatan dan koordinasi motorik',    8),
  (3, 'Fase Kronis',       'Latihan mandiri dan peningkatan fungsi kognitif',         12),
  (4, 'Fase Pemeliharaan', 'Menjaga kondisi dan mencegah stroke berulang',           NULL);

INSERT INTO app_config (key, value, description, is_public) VALUES
  ('app_version',           '1.0.0', 'Versi aplikasi saat ini',              TRUE),
  ('maintenance_mode',      'false', 'Mode maintenance',                      TRUE),
  ('max_pairing_per_pharm', '50',    'Maks pasien per apoteker',             FALSE),
  ('emergency_number',      '119',   'Nomor darurat nasional Indonesia',     TRUE),
  ('min_systolic_bp',       '90',    'Batas bawah tekanan sistolik (mmHg)', FALSE),
  ('max_systolic_bp',       '180',   'Batas atas tekanan sistolik (mmHg)',  FALSE);

INSERT INTO medications (name, generic_name, category, dosage_form, strength) VALUES
  ('Aspirin',          'Asam Asetilsalisilat', 'antiplatelet',   'tablet', '80mg'),
  ('Clopidogrel',      'Clopidogrel',          'antiplatelet',   'tablet', '75mg'),
  ('Amlodipine',       'Amlodipine Besilat',   'antihipertensi', 'tablet', '5mg'),
  ('Atorvastatin',     'Atorvastatin Kalsium', 'statin',         'tablet', '20mg'),
  ('Warfarin',         'Warfarin Natrium',     'antikoagulan',   'tablet', '2mg'),
  ('Lisinopril',       'Lisinopril',           'ACE inhibitor',  'tablet', '10mg'),
  ('Metformin',        'Metformin HCl',        'antidiabetik',   'tablet', '500mg'),
  ('Vitamin B Complex','Vitamin B1+B6+B12',    'neurotropik',    'tablet', NULL);