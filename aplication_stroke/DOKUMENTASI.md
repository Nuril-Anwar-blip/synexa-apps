# Dokumentasi Aplikasi Synexa - Aplikasi Pemulihan Stroke

## 📱 Gambaran Umum

**Synexa** adalah aplikasi mobile Flutter untuk membantu pasien stroke dalam proses pemulihan mereka. Aplikasi ini menyediakan berbagai fitur seperti:
- Monitoring kesehatan
- Pengingat obat
- Konsultasi dengan apoteker/dokter
- Latihan rehabilitasi
- Komunitas dukungan
- Panggilan darurat

---

## 📂 Struktur Folder dan File

### 1. Folder Utama (`lib/`)

| File | Deskripsi |
|------|-----------|
| [`main.dart`](lib/main.dart) | Entry point aplikasi, inisialisasi tema, bahasa, dan provider |
| [`global.dart`](lib/global.dart) | Variabel global dan konstanta aplikasi |
| [`debug_preview.dart`](lib/debug_preview.dart) | Widget untuk debugging |

---

### 2. Folder `auth/` - Autentikasi Pengguna

| File | Deskripsi |
|------|-----------|
| [`auth/auth_layout.dart`](lib/auth/auth_layout.dart) | Layout dasar untuk halaman autentikasi (login/register) |
| [`auth/login_screen.dart`](lib/auth/login_screen.dart) | Halaman login pengguna |
| [`auth/register_screen.dart`](lib/auth/register_screen.dart) | Halaman pilihan register (pasien/apoteker) |
| [`auth/register_patient_screen.dart`](lib/auth/register_patient_screen.dart) | Halaman registrasi pasien |
| [`auth/register_pharmacist_screen.dart`](lib/auth/register_pharmacist_screen.dart) | Halaman registrasi apoteker |

#### Widgets Autentikasi:
| File | Deskripsi |
|------|-----------|
| [`auth/widgets/splash_screen.dart`](lib/auth/widgets/splash_screen.dart) | Layar pembuka dengan animasi logo |
| [`auth/widgets/login_form.dart`](lib/auth/widgets/login_form.dart) | Formulir login dengan validasi |
| [`auth/widgets/register_form.dart`](lib/auth/widgets/register_form.dart) | Formulir registrasi lengkap |
| [`auth/widgets/text_form_field_with_label.dart`](lib/auth/widgets/text_form_field_with_label.dart) | Input teks dengan label |
| [`auth/widgets/password_form_field_with_label.dart`](lib/auth/widgets/password_form_field_with_label.dart) | Input password dengan toggle visibility |
| [`auth/widgets/gender_radio_form.dart`](lib/auth/widgets/gender_radio_form.dart) | Pilihan gender |
| [`auth/widgets/multi_select_form.dart`](lib/auth/widgets/multi_select_form.dart) | Multi-select untuk penyakit/etc |
| [`auth/widgets/auth_bottom_section.dart`](lib/auth/widgets/auth_bottom_section.dart) | Bagian bawah (CTA ke login/register) |
| [`auth/widgets/auth_redirect_text.dart`](lib/auth/widgets/auth_redirect_text.dart) | Teks pengalihan (belum punya akun?) |

#### Services Autentikasi:
| File | Deskripsi |
|------|-----------|
| [`auth/services/social_auth_service.dart`](lib/auth/services/social_auth_service.dart) | Integrasi login Google/Facebook |

---

### 3. Folder `models/` - Model Data

| File | Deskripsi |
|------|-----------|
| [`models/user_model.dart`](lib/models/user_model.dart) | Model data pengguna (pasien/apoteker) |
| [`models/emergency_contact_model.dart`](lib/models/emergency_contact_model.dart) | Model kontak darurat |
| [`models/health_log_model.dart`](lib/models/health_log_model.dart) | Model catatan kesehatan |
| [`models/education_model.dart`](lib/models/education_model.dart) | Model konten edukasi stroke |
| [`models/post_model.dart`](lib/models/post_model.dart) | Model post di komunitas |
| [`models/rehab_models.dart`](lib/models/rehab_models.dart) | Model latihan rehabilitasi |

---

### 4. Folder `modules/` - Fitur Utama Aplikasi

#### Dashboard & Home:
| File | Deskripsi |
|------|-----------|
| [`modules/dashboard/unified_main_screen.dart`](lib/modules/dashboard/unified_main_screen.dart) | Layar utama dengan navigasi bottom navbar |
| [`modules/dashboard/dashboard_screen.dart`](lib/modules/dashboard/dashboard_screen.dart) | Layar dashboard sederhana |
| [`modules/dashboard/widgets/enhanced_home_tab.dart`](lib/modules/dashboard/widgets/enhanced_home_tab.dart) | Tab home yang ditingkatkan dengan greeting, stats, medication |
| [`modules/dashboard/widgets/feature_card.dart`](lib/modules/dashboard/widgets/feature_card.dart) | Card untuk fitur utama |
| [`modules/dashboard/widgets/quick_action_card.dart`](lib/modules/dashboard/widgets/quick_action_card.dart) | Card aksi cepat |
| [`modules/dashboard/widgets/greeting_heart_rate_card.dart`](lib/modules/dashboard/widgets/greeting_heart_rate_card.dart) | Card sapaan dan detak jantung |
| [`modules/dashboard/widgets/stroke_education_card.dart`](lib/modules/dashboard/widgets/stroke_education_card.dart) | Card edukasi stroke |
| [`modules/dashboard/models/dashboard_stats.dart`](lib/modules/dashboard/models/dashboard_stats.dart) | Model statistik dashboard |

#### Profile:
| File | Deskripsi |
|------|-----------|
| [`modules/profile/profile_screen.dart`](lib/modules/profile/profile_screen.dart) | Halaman profil pengguna |
| [`modules/profile/edit_profile_screen.dart`](lib/modules/profile/edit_profile_screen.dart) | Halaman edit profil |

#### Komunitas:
| File | Deskripsi |
|------|-----------|
| [`modules/community/community_screen.dart`](lib/modules/community/community_screen.dart) | Halaman komunitas/donasi |
| [`modules/community/create_post_screen.dart`](lib/modules/community/create_post_screen.dart) | Halaman buat post baru |
| [`modules/community/post_detail_screen.dart`](lib/modules/community/post_detail_screen.dart) | Halaman detail post |
| [`modules/community/video_player_screen.dart`](lib/modules/community/video_player_screen.dart) | Pemutar video |
| [`modules/community/widgets/post_card.dart`](lib/modules/community/widgets/post_card.dart) | Widget card untuk post |

#### Konsultasi:
| File | Deskripsi |
|------|-----------|
| [`modules/consultation/consultation_screen.dart`](lib/modules/consultation/consultation_screen.dart) | Halaman konsultasi |
| [`modules/consultation/patient_chat_dashboard_screen.dart`](lib/modules/consultation/patient_chat_dashboard_screen.dart) | Dashboard chat pasien dengan apoteker |

#### Pengingat Obat:
| File | Deskripsi |
|------|-----------|
| [`modules/medication_reminder/medication_reminder_screen.dart`](lib/modules/medication_reminder/medication_reminder_screen.dart) | Halaman pengingat obat |
| [`modules/medication_reminder/medication_history_screen.dart`](lib/modules/medication_reminder/medication_history_screen.dart) | Riwayat obat |
| [`modules/medication_reminder/models/medication_reminder.dart`](lib/modules/medication_reminder/models/medication_reminder.dart) | Model pengingat obat |
| [`modules/medication_reminder/models/common_medications.dart`](lib/modules/medication_reminder/models/common_medications.dart) | Daftar obat umum |
| [`modules/medication_reminder/widgets/add_medication_dialog_v2.dart`](lib/modules/medication_reminder/widgets/add_medication_dialog_v2.dart) | Dialog tambah obat |

#### Rehabilitasi:
| File | Deskripsi |
|------|-----------|
| [`modules/rehab/rehab_dashboard_screen.dart`](lib/modules/rehab/rehab_dashboard_screen.dart) | Dashboard rehabilitasi |
| [`modules/rehab/exercise_session_screen.dart`](lib/modules/rehab/exercise_session_screen.dart) | Halaman sesi latihan |

#### Kesehatan:
| File | Deskripsi |
|------|-----------|
| [`modules/health/health_monitoring_screen.dart`](lib/modules/health/health_monitoring_screen.dart) | Monitoring kesehatan |

#### Edukasi:
| File | Deskripsi |
|------|-----------|
| [`modules/education/stroke_education_screen.dart`](lib/modules/education/stroke_education_screen.dart) | Edukasi tentang stroke |

#### Latihan/Exercise:
| File | Deskripsi |
|------|-----------|
| [`modules/exercise/exercise_screen.dart`](lib/modules/exercise/exercise_screen.dart) | Halaman latihan fisik |

#### Darurat:
| File | Deskripsi |
|------|-----------|
| [`modules/emergency_call/emergency_call_screen.dart`](lib/modules/emergency_call/emergency_call_screen.dart) | Panggilan darurat |
| [`modules/emergency_location/emergency_location_screen.dart`](lib/modules/emergency_location/emergency_location_screen.dart) | Lokasi darurat |

#### Admin & Apoteker:
| File | Deskripsi |
|------|-----------|
| [`modules/admin/admin_dashboard_screen.dart`](lib/modules/admin/admin_dashboard_screen.dart) | Dashboard admin |
| [`modules/pharmacist/apoteker_dashboard_screen.dart`](lib/modules/pharmacist/apoteker_dashboard_screen.dart) | Dashboard apoteker |

#### Pengaturan:
| File | Deskripsi |
|------|-----------|
| [`modules/settings/settings_screen.dart`](lib/modules/settings/settings_screen.dart) | Halaman pengaturan (tema, bahasa, font) |

#### Scanner:
| File | Deskripsi |
|------|-----------|
| [`modules/pairing_scanner/pairing_scanner_screen.dart`](lib/modules/pairing_scanner/pairing_scanner_screen.dart) | Scanner untuk pairing device |

---

### 5. Folder `providers/` - State Management

| File | Deskripsi |
|------|-----------|
| [`providers/theme_provider.dart`](lib/providers/theme_provider.dart) | Provider untuk管理 tema (dark/light) |
| [`providers/language_provider.dart`](lib/providers/language_provider.dart) | Provider untuk管理 bahasa (EN/ID/MS) |

---

### 6. Folder `services/` - Layanan Backend

#### Local Services:
| File | Deskripsi |
|------|-----------|
| [`services/local/auth_local_service.dart`](lib/services/local/auth_local_service.dart) | Penyimpanan data autentikasi lokal |
| [`services/local/notification_service.dart`](lib/services/local/notification_service.dart) | Layanan notifikasi lokal |

#### Remote Services:
| File | Deskripsi |
|------|-----------|
| [`services/remote/auth_service.dart`](lib/services/remote/auth_service.dart) | Layanan autentikasi ke Supabase |
| [`services/remote/education_service.dart`](lib/services/remote/education_service.dart) | Layanan data edukasi |
| [`services/remote/health_service.dart`](lib/services/remote/health_service.dart) | Layanan data kesehatan |
| [`services/remote/rehab_service.dart`](lib/services/remote/rehab_service.dart) | Layanan rehabilitasi |

---

### 7. Folder `styles/` - Tema dan Styling

#### Colors:
| File | Deskripsi |
|------|-----------|
| [`styles/colors/app_color.dart`](lib/styles/colors/app_color.dart) | Definisi warna aplikasi |

#### Themes:
| File | Deskripsi |
|------|-----------|
| [`styles/themes/app_theme.dart`](lib/styles/themes/app_theme.dart) | Konfigurasi tema utama |
| [`styles/themes/widgets/app_app_bar_theme.dart`](lib/styles/themes/widgets/app_app_bar_theme.dart) | Tema AppBar |
| [`styles/themes/widgets/app_elevated_button_theme.dart`](lib/styles/themes/widgets/app_elevated_button_theme.dart) | Tema tombol |
| [`styles/themes/widgets/app_input_decoration_theme.dart`](lib/styles/themes/widgets/app_input_decoration_theme.dart) | Tema input |
| [`styles/themes/widgets/app_outlined_button_theme.dart`](lib/styles/themes/widgets/app_outlined_button_theme.dart) | Tema tombol outline |
| [`styles/themes/widgets/app_progress_indicator_theme.dart`](lib/styles/themes/widgets/app_progress_indicator_theme.dart) | Tema loading indicator |
| [`styles/themes/widgets/app_text_selection_theme.dart`](lib/styles/themes/widgets/app_text_selection_theme.dart) | Tema seleksi teks |

---

### 8. Folder `widgets/` - Widget Bersama

| File | Deskripsi |
|------|-----------|
| [`widgets/navbar.dart`](lib/widgets/navbar.dart) | **Navigasi bottom bar** (icon-only floating navbar) |
| [`widgets/app_bar_with_actions.dart`](lib/widgets/app_bar_with_actions.dart) | AppBar dengan tombol settings |
| [`widgets/base_screen.dart`](lib/widgets/base_screen.dart) | Layar dasar dengan padding |
| [`widgets/global_search_bar.dart`](lib/widgets/global_search_bar.dart) | Search bar global |
| [`widgets/healthcare_provider_card.dart`](lib/widgets/healthcare_provider_card.dart) | Card penyedia layanan kesehatan |
| [`widgets/medication_checklist_card.dart`](lib/widgets/medication_checklist_card.dart) | Card checklist obat |
| [`widgets/pop_up_loading.dart`](lib/widgets/pop_up_loading.dart) | Popup loading |
| [`widgets/quick_settings_sheet.dart`](lib/widgets/quick_settings_sheet.dart) | Bottom sheet pengaturan cepat (tema, bahasa, font) |
| [`widgets/weekly_exercise_card.dart`](lib/widgets/weekly_exercise_card.dart) | Card latihan mingguan |

---

### 9. Folder `extensions/` - Ekstensi Model

| File | Deskripsi |
|------|-----------|
| [`extensions/user_model_extension.dart`](lib/extensions/user_model_extension.dart) | Ekstensi untuk UserModel |
| [`extensions/emergency_contact_model_extension.dart`](lib/extensions/emergency_contact_model_extension.dart) | Ekstensi untuk EmergencyContactModel |

---

### 10. Folder `utils/` - Fungsi Utilitas

| File | Deskripsi |
|------|-----------|
| [`utils/util.dart`](lib/utils/util.dart) | Fungsi utilitas umum |
| [`utils/input_validator.dart`](lib/utils/input_validator.dart) | Validasi input formulir |
| [`utils/chat_helper.dart`](lib/utils/chat_helper.dart) | Helper untuk fitur chat |

---

### 11. Folder `supabase/` - Konfigurasi Supabase

| File | Deskripsi |
|------|-----------|
| [`supabase/supabase_client.dart`](lib/supabase/supabase_client.dart) | Inisialisasi klien Supabase |

---

## 🔧 Fitur Utama Aplikasi

### 1. Theme Switching (Dark/Light)
- Dikelola oleh [`ThemeProvider`](lib/providers/theme_provider.dart)
- Tema bisa diubah di [`SettingsScreen`](lib/modules/settings/settings_screen.dart) atau [`QuickSettingsSheet`](lib/widgets/quick_settings_sheet.dart)

### 2. Language Switching (Multi-language)
- Mendukung: English (en), Indonesian (id), Malay (ms)
- Dikelola oleh [`LanguageProvider`](lib/providers/language_provider.dart)
- bisa diakses dari pengaturan

### 3. Font Size Adjustment
- Pengaturan font size di QuickSettingsSheet (80%-150%)
- Terapkan ke seluruh aplikasi via `MediaQuery.textScaler` di main.dart

### 4. Font Family Selection
- Opsi: Default, Roboto, Poppins, Montserrat, Serif
- Dikontrol via QuickSettingsSheet

### 5. Bottom Navigation
- [`CustomNavbar`](lib/widgets/navbar.dart) - Navigasi icon-only
- 4 tab: Home, Forum, Chat, Profile

---

## 📱 Cara Menggunakan

### Menjalankan Aplikasi:
```bash
cd aplication_stroke
flutter run
```

### Build APK:
```bash
flutter build apk --release
```

---

## 🛠️ Teknologi yang Digunakan

- **Framework**: Flutter
- **Backend**: Supabase (Firebase alternative)
- **State Management**: Provider
- **Authentication**: Supabase Auth + Social Auth (Google)
- **Database**: PostgreSQL (via Supabase)
- **Notifications**: Local notifications

---

## 📝 Catatan

- Aplikasi ini dirancang untuk pasien stroke dengan antarmuka yang sederhana dan mudah digunakan
- Fitur utama mencakup monitoring kesehatan, pengingat obat, dan konsultasi dengan profesional medis
- Support untuk mode gelap (dark mode) untuk kenyamanan pengguna

---

*Dokumentasi ini dibuat untuk Aplikasi Synexa - Stroke Recovery Application*
