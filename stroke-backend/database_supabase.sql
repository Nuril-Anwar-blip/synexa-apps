-- Pastikan ekstensi pembuat UUID aktif di database lokal Anda
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Users Table
CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email character varying UNIQUE,
  password_hash text,
  full_name text DEFAULT ''::text,
  phone_number text DEFAULT ''::text,
  age integer DEFAULT 0,
  height double precision DEFAULT 0.0,
  weight double precision DEFAULT 0.0,
  gender text DEFAULT 'male'::text,
  role text DEFAULT 'pasien'::text,
  photo_url text,
  medical_history jsonb DEFAULT '[]'::jsonb,
  drug_allergy jsonb DEFAULT '[]'::jsonb,
  emergency_contact jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- 2. Chat System
CREATE TABLE IF NOT EXISTS public.chat_rooms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES public.users(id),
  pharmacist_id uuid NOT NULL REFERENCES public.users(id),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT chat_rooms_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.chat_rooms(id),
  sender_id uuid NOT NULL REFERENCES public.users(id),
  content text NOT NULL,
  metadata jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id)
);

-- 3. Medication Reminders (Obat)
CREATE TABLE IF NOT EXISTS public.medication_reminders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id),
  name text NOT NULL,
  dose text,
  note text,
  time time without time zone NOT NULL,
  period text NOT NULL CHECK (period = ANY (ARRAY['Pagi'::text, 'Siang'::text, 'Sore'::text, 'Malam'::text])),
  frequency integer DEFAULT 1,
  taken boolean NOT NULL DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT medication_reminders_pkey PRIMARY KEY (id)
);

-- 4. Rehab Exercise Logs (Latihan)
CREATE TABLE IF NOT EXISTS public.rehab_exercises (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text,
  media_url text,
  instructions jsonb DEFAULT '[]'::jsonb,
  CONSTRAINT rehab_exercises_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.rehab_exercise_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  exercise_id uuid REFERENCES public.rehab_exercises(id),
  duration_actual_seconds integer,
  is_aborted boolean DEFAULT false,
  abort_reason text,
  completed_at timestamp with time zone DEFAULT now(),
  CONSTRAINT rehab_exercise_logs_pkey PRIMARY KEY (id)
);

-- 5. Community System
CREATE TABLE IF NOT EXISTS public.posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  content text,
  media_url text,
  media_type text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT posts_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES public.posts(id),
  user_id uuid REFERENCES public.users(id),
  content text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT comments_pkey PRIMARY KEY (id)
);

-- 6. Emergency Logs
CREATE TABLE IF NOT EXISTS public.emergency_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  location_lat double precision,
  location_long double precision,
  status text DEFAULT 'active'::text,
  triggered_at timestamp with time zone DEFAULT now(),
  CONSTRAINT emergency_logs_pkey PRIMARY KEY (id)
);
