-- ============================================================
-- SMART STROKE – Supabase Storage buckets
-- Jalankan di SQL Editor (butuh hak admin project)
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('post_images', 'post_images', true, 5242880, ARRAY['image/jpeg','image/png','image/webp','image/gif']),
  ('post_videos', 'post_videos', true, 52428800, ARRAY['video/mp4','video/webm']),
  ('post_files', 'post_files', true, 10485760, ARRAY['application/pdf','text/plain']),
  ('chat_attachments', 'chat_attachments', true, 10485760, NULL),
  ('profile_pictures', 'profile_pictures', true, 2097152, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit;

-- Policy: user terautentikasi boleh upload ke folder sendiri (auth uid)
DO $$ BEGIN
  CREATE POLICY "storage_auth_upload" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id IN ('post_images','post_videos','post_files','chat_attachments','profile_pictures'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "storage_public_read" ON storage.objects
    FOR SELECT TO public
    USING (bucket_id IN ('post_images','post_videos','post_files','chat_attachments','profile_pictures'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
