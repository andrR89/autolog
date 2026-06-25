// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AutoLog';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Try again';

  @override
  String get authLoginTitle => 'Sign in to your account';

  @override
  String get authSignupTitle => 'Create your account';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordShow => 'Show password';

  @override
  String get authPasswordHide => 'Hide password';

  @override
  String get authLoginCta => 'Sign in';

  @override
  String get authSignupCta => 'Sign up';

  @override
  String get authGoogleCta => 'Sign in with Google';

  @override
  String get authNoAccount => 'Don\'t have an account yet?';

  @override
  String get authHasAccount => 'Already have an account?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutSubtitle => 'Logs out from this device.';

  @override
  String get premiumGoCta => 'Go Premium';

  @override
  String get premiumGoSubtitle => 'Unlimited scans and insights.';

  @override
  String get premiumActive => 'You\'re Premium 💚';

  @override
  String get premiumActiveSubtitle =>
      'Everything unlocked. Thanks for the support!';
}
