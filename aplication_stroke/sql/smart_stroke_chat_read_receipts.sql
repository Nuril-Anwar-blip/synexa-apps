-- ============================================================
-- SMART STROKE – Chat read receipts & realtime update policies
-- Jalankan di Supabase SQL Editor setelah smart_stroke_schema.sql
-- ============================================================

DROP POLICY IF EXISTS messages_update ON messages;
CREATE POLICY messages_update ON messages FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM chat_rooms cr
    WHERE cr.id = messages.chat_room_id
      AND (cr.patient_id = auth_user_id() OR cr.pharmacist_id = auth_pharmacist_id())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM chat_rooms cr
    WHERE cr.id = messages.chat_room_id
      AND (cr.patient_id = auth_user_id() OR cr.pharmacist_id = auth_pharmacist_id())
  ));

DROP POLICY IF EXISTS chat_rooms_update ON chat_rooms;
CREATE POLICY chat_rooms_update ON chat_rooms FOR UPDATE
  USING (patient_id = auth_user_id() OR pharmacist_id = auth_pharmacist_id())
  WITH CHECK (patient_id = auth_user_id() OR pharmacist_id = auth_pharmacist_id());
