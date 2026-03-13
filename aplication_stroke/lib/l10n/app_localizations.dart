import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('ms'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Synexa - Stroke Recovery'**
  String get appTitle;

  /// Home navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Menu navigation label
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Chat navigation label
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Light mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Language selection label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Font size setting label
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// Font family setting label
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Welcome greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Welcome back greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Sign up prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign in prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Medication reminder screen title
  ///
  /// In en, this message translates to:
  /// **'Medication Reminder'**
  String get medicationReminder;

  /// Medicine tab label
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicine;

  /// Exercise tab label
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// Add medication button
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// Medication name field
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// Dosage field label
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// Frequency field label
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// Times per day format
  ///
  /// In en, this message translates to:
  /// **'{count} times per day'**
  String timesPerDay(int count);

  /// Compliance rate label
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get compliance;

  /// Stock quantity label
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// Remaining quantity label
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// Taken label
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// Disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Enabled status
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Emergency SOS button
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// Emergency contact section
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// Call now button
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Consultation screen title
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultation;

  /// Community screen title
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// Education screen title
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// Health log screen title
  ///
  /// In en, this message translates to:
  /// **'Health Log'**
  String get healthLog;

  /// Stroke education title
  ///
  /// In en, this message translates to:
  /// **'Stroke Education'**
  String get strokeEducation;

  /// Quick actions section
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Recent activity section
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// Notifications title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Terms of service link
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Help section
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Yes button
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Small font size
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// Medium font size
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// Large font size
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// Extra large font size
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get extraLarge;

  /// General settings section
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// Appearance section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Display settings section
  ///
  /// In en, this message translates to:
  /// **'Display Settings'**
  String get displaySettings;

  /// Account settings section
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// Notification settings section
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Alarm type label
  ///
  /// In en, this message translates to:
  /// **'Alarm Type'**
  String get alarmType;

  /// Reminder time label
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// Start time label
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// End time label
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// Every day option
  ///
  /// In en, this message translates to:
  /// **'Every Day'**
  String get everyDay;

  /// Custom days option
  ///
  /// In en, this message translates to:
  /// **'Custom Days'**
  String get customDays;

  /// Monday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Thursday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Friday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Saturday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Sunday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Select time prompt
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No reminders message
  ///
  /// In en, this message translates to:
  /// **'No reminders set'**
  String get noReminders;

  /// Tap to add hint
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a reminder'**
  String get tapToAdd;

  /// Reminder saved message
  ///
  /// In en, this message translates to:
  /// **'Reminder saved successfully'**
  String get reminderSaved;

  /// Reminder deleted message
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get reminderDeleted;

  /// Confirm delete message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reminder?'**
  String get confirmDelete;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
