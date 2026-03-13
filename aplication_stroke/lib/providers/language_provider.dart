import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplication_stroke/l10n/app_localizations.dart';

/// Provider untuk mengelola bahasa aplikasi (Indonesia, Inggris, Melayu).
/// Menyimpan preferensi bahasa menggunakan SharedPreferences.
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  // Default language: Indonesia
  String _currentLanguage = 'id';

  String get currentLanguage => _currentLanguage;

  Locale get locale => Locale(_currentLanguage);

  LanguageProvider() {
    _loadLanguage();
  }

  /// Memuat bahasa yang tersimpan dari SharedPreferences.
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null) {
        _currentLanguage = savedLanguage;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Mengatur bahasa aplikasi dan menyimpannya.
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;
    _currentLanguage = languageCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (_) {}
  }

  /// Mendapatkan nama bahasa yang ramah pengguna.
  String get languageName {
    switch (_currentLanguage) {
      case 'en':
        return 'English';
      case 'ms':
        return 'Melayu';
      case 'id':
      default:
        return 'Bahasa Indonesia';
    }
  }

  /// Backward compatible translate method using map.
  /// Use this for simple key-value translations.
  String translate(Map<String, String> values) {
    return values[_currentLanguage] ?? values['id'] ?? '';
  }

  /// ARB-based translate method using AppLocalizations.
  /// Use this for full localization support.
  /// Returns the translated string based on the key.
  String translateWithContext(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;

    // Map keys to localization methods
    switch (key) {
      // App
      case 'appTitle':
        return l10n.appTitle;
      case 'home':
        return l10n.home;
      case 'menu':
        return l10n.menu;
      case 'chat':
        return l10n.chat;
      case 'profile':
        return l10n.profile;
      case 'settings':
        return l10n.settings;
      case 'darkMode':
        return l10n.darkMode;
      case 'lightMode':
        return l10n.lightMode;
      case 'language':
        return l10n.language;
      case 'fontSize':
        return l10n.fontSize;
      case 'fontFamily':
        return l10n.fontFamily;
      case 'save':
        return l10n.save;
      case 'cancel':
        return l10n.cancel;
      case 'delete':
        return l10n.delete;
      case 'edit':
        return l10n.edit;
      case 'add':
        return l10n.add;
      case 'search':
        return l10n.search;
      case 'noData':
        return l10n.noData;
      case 'error':
        return l10n.error;
      case 'success':
        return l10n.success;
      case 'loading':
        return l10n.loading;
      case 'welcome':
        return l10n.welcome;
      case 'welcomeBack':
        return l10n.welcomeBack;
      case 'login':
        return l10n.login;
      case 'logout':
        return l10n.logout;
      case 'register':
        return l10n.register;
      case 'email':
        return l10n.email;
      case 'password':
        return l10n.password;
      case 'confirmPassword':
        return l10n.confirmPassword;
      case 'forgotPassword':
        return l10n.forgotPassword;
      case 'dontHaveAccount':
        return l10n.dontHaveAccount;
      case 'alreadyHaveAccount':
        return l10n.alreadyHaveAccount;
      case 'medicationReminder':
        return l10n.medicationReminder;
      case 'medicine':
        return l10n.medicine;
      case 'exercise':
        return l10n.exercise;
      case 'addMedication':
        return l10n.addMedication;
      case 'medicationName':
        return l10n.medicationName;
      case 'dosage':
        return l10n.dosage;
      case 'frequency':
        return l10n.frequency;
      case 'compliance':
        return l10n.compliance;
      case 'stock':
        return l10n.stock;
      case 'remaining':
        return l10n.remaining;
      case 'taken':
        return l10n.taken;
      case 'disabled':
        return l10n.disabled;
      case 'enabled':
        return l10n.enabled;
      case 'sos':
        return l10n.sos;
      case 'emergencyContact':
        return l10n.emergencyContact;
      case 'callNow':
        return l10n.callNow;
      case 'dashboard':
        return l10n.dashboard;
      case 'consultation':
        return l10n.consultation;
      case 'community':
        return l10n.community;
      case 'education':
        return l10n.education;
      case 'healthLog':
        return l10n.healthLog;
      case 'strokeEducation':
        return l10n.strokeEducation;
      case 'quickActions':
        return l10n.quickActions;
      case 'recentActivity':
        return l10n.recentActivity;
      case 'notifications':
        return l10n.notifications;
      case 'about':
        return l10n.about;
      case 'version':
        return l10n.version;
      case 'privacyPolicy':
        return l10n.privacyPolicy;
      case 'termsOfService':
        return l10n.termsOfService;
      case 'help':
        return l10n.help;
      case 'logoutConfirmation':
        return l10n.logoutConfirmation;
      case 'yes':
        return l10n.yes;
      case 'no':
        return l10n.no;
      case 'ok':
        return l10n.ok;
      case 'small':
        return l10n.small;
      case 'medium':
        return l10n.medium;
      case 'large':
        return l10n.large;
      case 'extraLarge':
        return l10n.extraLarge;
      case 'generalSettings':
        return l10n.generalSettings;
      case 'appearance':
        return l10n.appearance;
      case 'displaySettings':
        return l10n.displaySettings;
      case 'accountSettings':
        return l10n.accountSettings;
      case 'notificationSettings':
        return l10n.notificationSettings;
      case 'alarmType':
        return l10n.alarmType;
      case 'reminderTime':
        return l10n.reminderTime;
      case 'startTime':
        return l10n.startTime;
      case 'endTime':
        return l10n.endTime;
      case 'everyDay':
        return l10n.everyDay;
      case 'customDays':
        return l10n.customDays;
      case 'monday':
        return l10n.monday;
      case 'tuesday':
        return l10n.tuesday;
      case 'wednesday':
        return l10n.wednesday;
      case 'thursday':
        return l10n.thursday;
      case 'friday':
        return l10n.friday;
      case 'saturday':
        return l10n.saturday;
      case 'sunday':
        return l10n.sunday;
      case 'selectTime':
        return l10n.selectTime;
      case 'noReminders':
        return l10n.noReminders;
      case 'tapToAdd':
        return l10n.tapToAdd;
      case 'reminderSaved':
        return l10n.reminderSaved;
      case 'reminderDeleted':
        return l10n.reminderDeleted;
      case 'confirmDelete':
        return l10n.confirmDelete;
      default:
        return key;
    }
  }

  /// Helper untuk mendapatkan teks berdasarkan bahasa (Placeholder sederhana)
  /// Dalam skala besar, sebaiknya menggunakan flutter_localizations atau arb files.
  String translateSimple(Map<String, String> values) {
    return values[_currentLanguage] ?? values['id'] ?? '';
  }
}
