import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barcodereader/l10n/app_localizations.dart';

class Model {
  Model._();

  static const String _prefContinuousScan = 'continuousScan';
  static const String _prefScanInterval = 'scanInterval';
  static const String _prefScanAreaRestrictionLevel = 'scanAreaRestrictionLevel';
  static const String _prefSelectedBarcodeFormat = 'selectedBarcodeFormat';
  static const String _prefSnackBarTime = 'snackBarTime';
  static const String _prefStartScanOnLaunch = 'startScanOnLaunch';
  static const String _prefBeepOnScan = 'beepOnScan';
  static const String _prefBeepVolume = 'beepVolume';
  static const String _prefSelectedBeepSound = 'selectedBeepSound';
  static const String _prefFlashOnScan = 'flashOnScan';
  static const String _prefLockOrientation = 'lockOrientation';
  static const String _prefColorHue = 'colorHue';
  static const String _prefColorSaturation = 'colorSaturation';
  static const String _prefColorBrightness = 'colorBrightness';
  static const String _prefThemeNumber = 'themeNumber';
  static const String _prefLanguageCode = 'languageCode';

  static bool _ready = false;
  static bool _continuousScan = false;
  static double _scanInterval = 1.0;
  static int _scanAreaRestrictionLevel = 0;
  static String _selectedBarcodeFormat = 'all';
  static double _snackBarTime = 1.0;
  static bool _startScanOnLaunch = false;
  static bool _beepOnScan = true;
  static double _beepVolume = 1.0;
  static int _selectedBeepSound = 1;
  static bool _flashOnScan = true;
  static bool _lockOrientation = false;
  static int _colorHue = 250;
  static double _colorSaturation = 0.6;
  static double _colorBrightness = 1.0;
  static int _themeNumber = 0;
  static String _languageCode = '';

  static bool get continuousScan => _continuousScan;
  static double get scanInterval => _scanInterval;
  static int get scanAreaRestrictionLevel => _scanAreaRestrictionLevel;
  static String get selectedBarcodeFormat => _selectedBarcodeFormat;
  static double get snackBarTime => _snackBarTime;
  static bool get startScanOnLaunch => _startScanOnLaunch;
  static bool get beepOnScan => _beepOnScan;
  static double get beepVolume => _beepVolume;
  static int get selectedBeepSound => _selectedBeepSound;
  static bool get flashOnScan => _flashOnScan;
  static bool get lockOrientation => _lockOrientation;
  static int get colorHue => _colorHue;
  static double get colorSaturation => _colorSaturation;
  static double get colorBrightness => _colorBrightness;
  static int get themeNumber => _themeNumber;
  static String get languageCode => _languageCode;

  static Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _continuousScan = prefs.getBool(_prefContinuousScan) ?? false;
    _scanInterval = (prefs.getDouble(_prefScanInterval) ?? 1.0).clamp(0.0, 3.0);
    _scanAreaRestrictionLevel = prefs.getInt(_prefScanAreaRestrictionLevel) ?? 0;
    _selectedBarcodeFormat = prefs.getString(_prefSelectedBarcodeFormat) ?? 'all';
    _snackBarTime = (prefs.getDouble(_prefSnackBarTime) ?? 1.0).clamp(0.0, 10.0);
    _startScanOnLaunch = prefs.getBool(_prefStartScanOnLaunch) ?? false;
    _beepOnScan = prefs.getBool(_prefBeepOnScan) ?? true;
    _beepVolume = (prefs.getDouble(_prefBeepVolume) ?? 1.0).clamp(0.0, 1.0);
    _selectedBeepSound = prefs.getInt(_prefSelectedBeepSound) ?? 1;
    _flashOnScan = prefs.getBool(_prefFlashOnScan) ?? true;
    _lockOrientation = prefs.getBool(_prefLockOrientation) ?? false;
    _colorHue = (prefs.getInt(_prefColorHue) ?? 250).clamp(0, 360);
    _colorSaturation = (prefs.getDouble(_prefColorSaturation) ?? 0.6).clamp(0.0, 1.0);
    _colorBrightness = (prefs.getDouble(_prefColorBrightness) ?? 1.0).clamp(0.0, 1.0);
    _themeNumber = (prefs.getInt(_prefThemeNumber) ?? 0).clamp(0, 2);
    _languageCode = prefs.getString(_prefLanguageCode) ?? ui.PlatformDispatcher.instance.locale.languageCode;
    _languageCode = _resolveLanguageCode(_languageCode);
    _ready = true;
  }

  static String _resolveLanguageCode(String code) {
    final supported = AppLocalizations.supportedLocales;
    if (supported.any((l) => l.languageCode == code)) {
      return code;
    } else {
      return '';
    }
  }

  static Future<void> setContinuousScan(bool value) async {
    _continuousScan = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefContinuousScan, value);
  }

  static Future<void> setScanInterval(double value) async {
    _scanInterval = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefScanInterval, value);
  }

  static Future<void> setScanAreaRestrictionLevel(int value) async {
    _scanAreaRestrictionLevel = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefScanAreaRestrictionLevel, value);
  }

  static Future<void> setSelectedBarcodeFormat(String value) async {
    _selectedBarcodeFormat = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSelectedBarcodeFormat, value);
  }

  static Future<void> setSnackBarTime(double value) async {
    _snackBarTime = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefSnackBarTime, value);
  }

  static Future<void> setStartScanOnLaunch(bool value) async {
    _startScanOnLaunch = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefStartScanOnLaunch, value);
  }

  static Future<void> setBeepOnScan(bool value) async {
    _beepOnScan = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBeepOnScan, value);
  }

  static Future<void> setBeepVolume(double value) async {
    _beepVolume = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefBeepVolume, value);
  }

  static Future<void> setSelectedBeepSound(int value) async {
    _selectedBeepSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefSelectedBeepSound, value);
  }

  static Future<void> setFlashOnScan(bool value) async {
    _flashOnScan = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefFlashOnScan, value);
  }

  static Future<void> setLockOrientation(bool value) async {
    _lockOrientation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefLockOrientation, value);
  }

  static Future<void> setColorHue(int value) async {
    _colorHue = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefColorHue, value);
  }

  static Future<void> setColorSaturation(double value) async {
    _colorSaturation = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefColorSaturation, value);
  }

  static Future<void> setColorBrightness(double value) async {
    _colorBrightness = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefColorBrightness, value);
  }

  static Future<void> setThemeNumber(int value) async {
    _themeNumber = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeNumber, value);
  }

  static Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, value);
  }

}
