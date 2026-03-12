import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:barcodereader/l10n/app_localizations.dart';
import 'package:barcodereader/ad_manager.dart';
import 'package:barcodereader/ad_banner_widget.dart';
import 'package:barcodereader/ad_ump_status.dart';
import 'package:barcodereader/model.dart';
import 'package:barcodereader/loading_screen.dart';
import 'package:barcodereader/theme_color.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late AdManager _adManager;
  late UmpConsentController _adUmp;
  AdUmpState _adUmpState = AdUmpState.initial;
  int _themeNumber = 0;
  String _languageCode = '';
  late ThemeColor _themeColor;
  final _inAppReview = InAppReview.instance;
  bool _isReady = false;
  bool _isFirst = true;
  late bool _continuousScan;
  late double _scanInterval;
  late int _scanAreaRestrictionLevel;
  late String _selectedBarcodeFormat;
  late double _snackBarTime;
  late bool _startScanOnLaunch;
  late bool _beepOnScan;
  late double _beepVolume;
  late int _selectedBeepSound;
  late bool _flashOnScan;
  late bool _lockOrientation;
  late int _colorHue;
  late double _colorSaturation;
  late double _colorBrightness;
  late Color _accentColor;

  final List<BarcodeFormat> _supportedFormats =
    BarcodeFormat.values
      .where((format) => format != BarcodeFormat.unknown && format != BarcodeFormat.all)
      .toList();

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _continuousScan = Model.continuousScan;
    _scanInterval = Model.scanInterval;
    _scanAreaRestrictionLevel = Model.scanAreaRestrictionLevel;
    _selectedBarcodeFormat = Model.selectedBarcodeFormat;
    _snackBarTime = Model.snackBarTime;
    _startScanOnLaunch = Model.startScanOnLaunch;
    _beepOnScan = Model.beepOnScan;
    _beepVolume = Model.beepVolume;
    _selectedBeepSound = Model.selectedBeepSound;
    _flashOnScan = Model.flashOnScan;
    _lockOrientation = Model.lockOrientation;
    _colorHue = Model.colorHue;
    _colorSaturation = Model.colorSaturation;
    _colorBrightness = Model.colorBrightness;
    _themeNumber = Model.themeNumber;
    _languageCode = Model.languageCode;
    _adUmp = UmpConsentController();
    _refreshConsentInfo();
    _accentColor = _getRainbowAccentColor(_colorHue, _colorSaturation, _colorBrightness);
    setState(() {
      _isReady = true;
    });
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  void _onApply() async {
    await Model.setContinuousScan(_continuousScan);
    await Model.setScanInterval(_scanInterval);
    await Model.setScanAreaRestrictionLevel(_scanAreaRestrictionLevel);
    await Model.setSelectedBarcodeFormat(_selectedBarcodeFormat);
    await Model.setSnackBarTime(_snackBarTime);
    await Model.setStartScanOnLaunch(_startScanOnLaunch);
    await Model.setBeepOnScan(_beepOnScan);
    await Model.setBeepVolume(_beepVolume);
    await Model.setSelectedBeepSound(_selectedBeepSound);
    await Model.setFlashOnScan(_flashOnScan);
    await Model.setLockOrientation(_lockOrientation);
    await Model.setColorHue(_colorHue);
    await Model.setColorSaturation(_colorSaturation);
    await Model.setColorBrightness(_colorBrightness);
    await Model.setThemeNumber(_themeNumber);
    await Model.setLanguageCode(_languageCode);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String _scanAreaRestrictionLabel(AppLocalizations l, int value) {
    return value <= 0 ? l.scanAreaRestrictionNone : value.toString();
  }

  Future<void> _refreshConsentInfo() async {
    _adUmpState = await _adUmp.updateConsentInfo(current: _adUmpState);
    if (mounted) {
      setState(() {});
    }
  }

  Color _getRainbowAccentColor(int hue, double saturation, double brightness) {
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
  }

  Future<void> _onTapPrivacyOptions() async {
    final err = await _adUmp.showPrivacyOptions();
    await _refreshConsentInfo();
    if (err != null && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.cmpErrorOpeningSettings} ${err.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    final AppLocalizations l = AppLocalizations.of(context)!;
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: _themeColor.backColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l.setting),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _onApply),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child:Column(children:[
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 100),
                  child: Column(children: [
                    _buildContinuousScan(l, t),
                    _buildLimitAreaScan(l, t),
                    _buildBarcodeFormatSelector(l, t),
                    _buildSnackBarTime(l, t),
                    _buildLaunch(l, t),
                    _buildBeep(l, t),
                    _buildOrientation(l, t),
                    _buildColorScheme(l, t),
                    _buildTheme(l, t),
                    _buildLanguage(l, t),
                    _buildReview(l, t),
                    _buildCmp(l, t),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildContinuousScan(AppLocalizations l, TextTheme t) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(children: [
          SwitchListTile(
            title: Text(l.continuousScan, style: t.bodyMedium),
            value: _continuousScan,
            onChanged: (value) => setState(() => _continuousScan = value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.scanInterval(_scanInterval.toStringAsFixed(1))),
                Slider(
                  value: _scanInterval,
                  min: 0.0,
                  max: 3.0,
                  divisions: 15,
                  label: '${_scanInterval.toStringAsFixed(1)}s',
                  onChanged: (value) {
                    setState(() {
                      _scanInterval = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ])
      )
    );
  }

  Widget _buildLimitAreaScan(AppLocalizations l, TextTheme t) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l.scanAreaRestriction}: ${_scanAreaRestrictionLabel(l, _scanAreaRestrictionLevel)}',
              ),
              Slider(
                value: _scanAreaRestrictionLevel.toDouble(),
                min: 0,
                max: 8,
                divisions: 8,
                label: _scanAreaRestrictionLabel(l, _scanAreaRestrictionLevel),
                onChanged: (value) {
                  setState(() {
                    _scanAreaRestrictionLevel = value.round();
                  });
                },
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildBarcodeFormatSelector(AppLocalizations l, TextTheme t) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: ListTile(
          title: Text(l.detectableBarcodeFormat, style: t.bodyMedium),
          trailing: DropdownButton<String>(
            value: _selectedBarcodeFormat,
            items: [
              const DropdownMenuItem(value: 'all', child: Text('all')),
              ..._supportedFormats.map((format) => DropdownMenuItem(
                value: format.name,
                child: Text(format.name),
              )),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedBarcodeFormat = value);
              }
            },
          ),
        ),
      )
    );
  }

  Widget _buildSnackBarTime(AppLocalizations l, TextTheme t) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.snackBarTime,
                    style: t.bodyMedium,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_snackBarTime.toStringAsFixed(1)),
                Expanded(
                  child: Slider(
                    value: _snackBarTime,
                    min: 0.0,
                    max: 10.0,
                    divisions: 20,
                    label: _snackBarTime.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        _snackBarTime = value;
                      });
                    }
                  ),
                )
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildLaunch(AppLocalizations l, TextTheme t) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: SwitchListTile(
          title: Text(l.startScanOnLaunch, style: t.bodyMedium),
          value: _startScanOnLaunch,
          onChanged: (value) =>
            setState(() => _startScanOnLaunch = value),
        ),
      )
    );
  }

  Widget _buildBeep(AppLocalizations l, TextTheme t) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(children: [
          SwitchListTile(
            title: Text(l.beepOnScan, style: t.bodyMedium),
            value: _beepOnScan,
            onChanged: (value) => setState(() => _beepOnScan = value),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.beepVolume,
                    style: t.bodyMedium,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_beepVolume.toStringAsFixed(1)),
                Expanded(
                  child: Slider(
                      value: _beepVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: _beepVolume.toStringAsFixed(1),
                      onChanged: (double value) {
                        setState(() {
                          _beepVolume = value;
                        });
                      }
                  ),
                )
              ],
            ),
          ),
          ListTile(
            title: Text(l.beepSound, style: t.bodyMedium),
            trailing: DropdownButton<int>(
              value: _selectedBeepSound,
              items: List.generate(14, (index) {
                final soundNum = index + 1;
                return DropdownMenuItem(
                  value: soundNum,
                  child: Text(
                    l.beepSoundName(
                      soundNum.toString(),
                    ),
                  ),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedBeepSound = value);
                  AudioPlayer().play(AssetSource('sound/beep$value.mp3'));
                }
              },
            ),
          ),
          SwitchListTile(
            title: Text(l.flashOnScan, style: t.bodyMedium),
            value: _flashOnScan,
            onChanged: (value) => setState(() => _flashOnScan = value),
          ),
        ])
      )
    );
  }

  Widget _buildOrientation(AppLocalizations l, TextTheme t) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: SwitchListTile(
          title: Text(l.lockOrientation, style: t.bodyMedium),
          value: _lockOrientation,
          onChanged: (value) => setState(() => _lockOrientation = value),
        ),
      )
    );
  }

  Widget _buildColorScheme(AppLocalizations l, TextTheme t) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.colorScheme,
                    style: t.bodyMedium,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.colorScheme1,
                    style: t.bodySmall,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_colorHue.toStringAsFixed(0)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _accentColor,
                      inactiveTrackColor: _accentColor.withValues(alpha: 0.3),
                      thumbColor: _accentColor,
                      overlayColor: _accentColor.withValues(alpha: 0.2),
                      valueIndicatorColor: _accentColor,
                    ),
                    child: Slider(
                      value: _colorHue.toDouble(),
                      min: 0,
                      max: 360,
                      divisions: 360,
                      label: _colorHue.toString(),
                      onChanged: (double value) {
                        setState(() {
                          _colorHue = value.toInt();
                          _accentColor = _getRainbowAccentColor(_colorHue, _colorSaturation, _colorBrightness);
                        });
                      }
                    ),
                  )
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_colorSaturation.toStringAsFixed(1)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _accentColor,
                      inactiveTrackColor: _accentColor.withValues(alpha: 0.3),
                      thumbColor: _accentColor,
                      overlayColor: _accentColor.withValues(alpha: 0.2),
                      valueIndicatorColor: _accentColor,
                    ),
                    child: Slider(
                      value: _colorSaturation,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: _colorSaturation.toStringAsFixed(1),
                      onChanged: (double value) {
                        setState(() {
                          _colorSaturation = value;
                          _accentColor = _getRainbowAccentColor(_colorHue, _colorSaturation, _colorBrightness);
                        });
                      }
                    ),
                  )
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_colorBrightness.toStringAsFixed(1)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _accentColor,
                      inactiveTrackColor: _accentColor.withValues(alpha: 0.3),
                      thumbColor: _accentColor,
                      overlayColor: _accentColor.withValues(alpha: 0.2),
                      valueIndicatorColor: _accentColor,
                    ),
                    child: Slider(
                      value: _colorBrightness,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: _colorBrightness.toStringAsFixed(1),
                      onChanged: (double value) {
                        setState(() {
                          _colorBrightness = value;
                          _accentColor = _getRainbowAccentColor(_colorHue, _colorSaturation, _colorBrightness);
                        });
                      }
                    ),
                  )
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildTheme(AppLocalizations l, TextTheme t) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(l.theme, style: t.bodyMedium),
            ),
            DropdownButton<int>(
              value: _themeNumber,
              items: [
                DropdownMenuItem(value: 0, child: Text(l.systemSetting)),
                DropdownMenuItem(value: 1, child: Text(l.lightTheme)),
                DropdownMenuItem(value: 2, child: Text(l.darkTheme)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _themeNumber = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguage(AppLocalizations l, TextTheme t) {
    final Map<String,String> languageNames = {
      'af': 'af: Afrikaans',
      'ar': 'ar: العربية',
      'bg': 'bg: Български',
      'bn': 'bn: বাংলা',
      'bs': 'bs: Bosanski',
      'ca': 'ca: Català',
      'cs': 'cs: Čeština',
      'da': 'da: Dansk',
      'de': 'de: Deutsch',
      'el': 'el: Ελληνικά',
      'en': 'en: English',
      'es': 'es: Español',
      'et': 'et: Eesti',
      'fa': 'fa: فارسی',
      'fi': 'fi: Suomi',
      'fil': 'fil: Filipino',
      'fr': 'fr: Français',
      'gu': 'gu: ગુજરાતી',
      'he': 'he: עברית',
      'hi': 'hi: हिन्दी',
      'hr': 'hr: Hrvatski',
      'hu': 'hu: Magyar',
      'id': 'id: Bahasa Indonesia',
      'it': 'it: Italiano',
      'ja': 'ja: 日本語',
      'km': 'km: ខ្មែរ',
      'kn': 'kn: ಕನ್ನಡ',
      'ko': 'ko: 한국어',
      'lt': 'lt: Lietuvių',
      'lv': 'lv: Latviešu',
      'ml': 'ml: മലയാളം',
      'mr': 'mr: मराठी',
      'ms': 'ms: Bahasa Melayu',
      'my': 'my: မြန်မာ',
      'ne': 'ne: नेपाली',
      'nl': 'nl: Nederlands',
      'or': 'or: ଓଡ଼ିଆ',
      'pa': 'pa: ਪੰਜਾਬੀ',
      'pl': 'pl: Polski',
      'pt': 'pt: Português',
      'ro': 'ro: Română',
      'ru': 'ru: Русский',
      'si': 'si: සිංහල',
      'sk': 'sk: Slovenčina',
      'sr': 'sr: Српски',
      'sv': 'sv: Svenska',
      'sw': 'sw: Kiswahili',
      'ta': 'ta: தமிழ்',
      'te': 'te: తెలుగు',
      'th': 'th: ไทย',
      'tl': 'tl: Tagalog',
      'tr': 'tr: Türkçe',
      'uk': 'uk: Українська',
      'ur': 'ur: اردو',
      'uz': 'uz: Oʻzbekcha',
      'vi': 'vi: Tiếng Việt',
      'zh': 'zh: 中文',
      'zu': 'zu: isiZulu',
    };
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(l.language, style: t.bodyMedium),
            ),
            DropdownButton<String?>(
              value: _languageCode,
              items: [
                DropdownMenuItem(value: '', child: Text('Default')),
                ...languageNames.entries.map((entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                )),
              ],
              onChanged: (String? value) {
                setState(() {
                  _languageCode = value ?? '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(AppLocalizations l, TextTheme t) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.reviewApp, style: t.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: Text(l.reviewStore, style: t.bodySmall),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await _inAppReview.openStoreListing(
                      appStoreId: 'YOUR_APP_STORE_ID',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCmp(AppLocalizations l, TextTheme t) {
    final showButton = _adUmpState.privacyStatus == PrivacyOptionsRequirementStatus.required;
    String statusLabel = l.cmpCheckingRegion;
    IconData statusIcon = Icons.help_outline;
    switch (_adUmpState.privacyStatus) {
      case PrivacyOptionsRequirementStatus.required:
        statusLabel = l.cmpRegionRequiresSettings;
        statusIcon = Icons.privacy_tip_outlined;
        break;
      case PrivacyOptionsRequirementStatus.notRequired:
        statusLabel = l.cmpRegionNoSettingsRequired;
        statusIcon = Icons.check_circle_outline;
        break;
      case PrivacyOptionsRequirementStatus.unknown:
        statusLabel = l.cmpRegionCheckFailed;
        statusIcon = Icons.error_outline;
        break;
    }
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.cmpSettingsTitle,
              style: t.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.cmpConsentDescription,
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Chip(
                    avatar: Icon(statusIcon, size: 18),
                    label: Text(statusLabel),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l.cmpConsentStatusLabel} ${_adUmpState.consentStatus.localized(context)}',
                    style: t.bodySmall,
                  ),
                  if (showButton) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _adUmpState.isChecking
                          ? null
                          : _onTapPrivacyOptions,
                      icon: const Icon(Icons.settings),
                      label: Text(
                        _adUmpState.isChecking
                            ? l.cmpConsentStatusChecking
                            : l.cmpOpenConsentSettings,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _adUmpState.isChecking
                          ? null
                          : _refreshConsentInfo,
                      icon: const Icon(Icons.refresh),
                      label: Text(l.cmpRefreshStatus),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final message = l.cmpResetStatusDone;
                        await ConsentInformation.instance.reset();
                        await _refreshConsentInfo();
                        if (!mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: Text(l.cmpResetStatus),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}
