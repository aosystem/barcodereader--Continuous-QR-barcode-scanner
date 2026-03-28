import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barcodereader/l10n/app_localizations.dart';
import 'package:barcodereader/ad_manager.dart';
import 'package:barcodereader/ad_banner_widget.dart';
import 'package:barcodereader/info_page.dart';
import 'package:barcodereader/history_page.dart';
import 'package:barcodereader/scan_provider.dart';
import 'package:barcodereader/scanner_page.dart';
import 'package:barcodereader/image_scanner_page.dart';
import 'package:barcodereader/settings_page.dart';
import 'package:barcodereader/model.dart';
import 'package:barcodereader/loading_screen.dart';
import 'package:barcodereader/main.dart';
import 'package:barcodereader/parse_locale_tag.dart';
import 'package:barcodereader/theme_color.dart';
import 'package:barcodereader/theme_mode_number.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  late AdManager _adManager;
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ScanProvider _scanProvider;
  VoidCallback? _settingsListener;
  bool _hasAutoStartedScan = false;
  static const double _buttonHeight1 = 100.0;
  static const double _buttonHeight2 = 80.0;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _scanProvider = context.read<ScanProvider>();
    _scanProvider.loadScanResults().then((_) {
      _updateTextField();
    });
    _scanProvider.addListener(_updateTextField);
    _settingsListener = _handleSettingsChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartScanOnLaunch();
    });
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _scanProvider.removeListener(_updateTextField);
    _textController.dispose();
    _scrollController.dispose();
    _adManager.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScannerPage(
          onScan: (result) async {
            await _scanProvider.addScanResult(result);
          },
        ),
      ),
    );
  }

  void _handleSettingsChanged() {
    _maybeStartScanOnLaunch();
  }

  void _maybeStartScanOnLaunch() {
    if (_hasAutoStartedScan) {
      return;
    }
    if (!Model.startScanOnLaunch) {
      return;
    }
    _hasAutoStartedScan = true;
    if (_settingsListener != null) {
      _settingsListener = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_scanBarcode());
      }
    });
  }

  void _updateTextField() {
    _textController.text = _scanProvider.getFormattedResults();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) {
      return;
    }
    final l = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.copiedToClipboard),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareText(String text) {
    if (text.isEmpty) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  void _launchUrlOrShare(String text) async {
    if (text.isEmpty) {
      return;
    }
    final l = AppLocalizations.of(context)!;
    Uri uri;
    final parsedUri = Uri.tryParse(text);
    if (parsedUri != null &&
        (parsedUri.scheme == 'http' || parsedUri.scheme == 'https')) {
      uri = parsedUri;
    } else {
      uri = Uri.parse(
        'https://www.google.com/search?q=${Uri.encodeComponent(text)}',
      );
    }
    try {
      if (!await launchUrl(uri)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.couldNotLaunchBrowserFor(uri.toString())),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(l.errorLaunchingBrowser(e.toString())),
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog(String title) async {
    final l = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.ok),
          ),
        ],
      ),
    ) ??
    false;
  }

  Future<void> _showMessageDialog({String? title, required List<String> messages}) async {
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : null,
        content: messages.length == 1
          ? Text(messages.first)
          : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < messages.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == messages.length - 1 ? 0 : 8.0),
                  child: Text(messages[i]),
                ),
            ],
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteDuplicates() async {
    final l = AppLocalizations.of(context)!;
    if (!await _showConfirmDialog(l.deleteDuplicatesConfirmation)) {
      return;
    }
    final results = await _scanProvider.removeDuplicateScanResults();
    if (!mounted) {
      return;
    }
    if (results.isEmpty) {
      await _showMessageDialog(
        title: l.deleteDuplicates,
        messages: [l.noDuplicateDataFound],
      );
      return;
    }
    await _showMessageDialog(
      title: l.duplicateRemovalResultTitle,
      messages: results
        .map(
          (entry) => l.duplicateRemovalEntry(
            entry.removedCount,
            entry.data,
          ),
        )
        .toList(),
    );
  }

  Future<void> _onOpenSetting() async {
    final bool? updated = await Navigator.push<bool>(context,MaterialPageRoute(builder: (_) => const SettingPage()));
    if (!mounted) {
      return;
    }
    if (updated == true) {
      final mainState = context.findAncestorStateOfType<MainAppState>();
      if (mainState != null) {
        mainState
          ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
          ..locale = parseLocaleTag(Model.languageCode)
          ..seedColor = HSVColor.fromAHSV(1,Model.colorHue.toDouble(),Model.colorSaturation,Model.colorBrightness).toColor()
          ..setState(() {});
      }
      _isFirst = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady == false) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.mainButtonColor2,
      appBar: AppBar(
        backgroundColor: _themeColor.mainButtonColor2,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.image_search_outlined),
            tooltip: l.imageScan,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageScannerPage(
                  onScan: (result) async {
                    await _scanProvider.addScanResult(result);
                  },
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const InfoPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: _themeColor.mainForeColor,
            tooltip: l.setting,
            onPressed: _onOpenSetting,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFullWidthButton(
                l.scan,
                _scanBarcode,
                backColor: _themeColor.mainButtonColor1,
                foreColor: _themeColor.mainForeColor,
                height: _buttonHeight1,
              ),
              Row(children:[
                _buildHalfWidthButton(
                  l.copy,
                  () async {
                    if (await _showConfirmDialog(l.copyAll)) {
                      _copyToClipboard(_scanProvider.toCsv());
                    }
                  },
                  backColor: _themeColor.mainButtonColor2,
                  foreColor: _themeColor.mainForeColor,
                  height: _buttonHeight2,
                ),
                _buildHalfWidthButton(
                  l.send,
                  () async {
                    if (await _showConfirmDialog(l.sendAll)) {
                      _shareText(_scanProvider.toCsv());
                    }
                  },
                  backColor: _themeColor.mainButtonColor2,
                  foreColor: _themeColor.mainForeColor,
                  height: _buttonHeight2,
                ),
              ]),
              Row(children:[
                _buildHalfWidthButton(
                  l.deleteDuplicates,
                  () {
                    unawaited(_handleDeleteDuplicates());
                  },
                  backColor: _themeColor.mainButtonColor2,
                  foreColor: _themeColor.mainForeColor,
                  height: _buttonHeight2,
                ),
                _buildHalfWidthButton(
                  l.deleteAll,
                  () async {
                    if (await _showConfirmDialog(l.deleteAll)) {
                      _scanProvider.deleteAllScanResults();
                    }
                  },
                  backColor: _themeColor.mainButtonColor2,
                  foreColor: _themeColor.mainForeColor,
                  height: _buttonHeight2,
                ),
              ]),
              Row(children:[
                _buildHalfWidthButton(
                  l.copyLast,
                  () => _copyToClipboard(_scanProvider.getLastScanContent()),
                  backColor: _themeColor.mainButtonColor3,
                  foreColor: _themeColor.mainForeColor,
                  height: _buttonHeight2,
                ),
                _buildHalfWidthButton(
                  l.sendLast,
                  () => _shareText(_scanProvider.getLastScanContent()),
                  backColor: _themeColor.mainButtonColor3,
                  foreColor: _themeColor.mainForeColor,
                  height: _buttonHeight2,
                ),
              ]),
              Row(children:[
                _buildHalfWidthButton(
                  l.browserLast,
                  () => _launchUrlOrShare(_scanProvider.getLastScanContent()),
                  backColor: _themeColor.mainButtonColor3,
                  foreColor: _themeColor.mainForeColor,
                  height: _buttonHeight2,
                ),
                _buildHalfWidthButton(
                  l.deleteLast,
                  () async {
                    if (await _showConfirmDialog(l.deleteLastConfirmation)) {
                      _scanProvider.deleteLastScanResult();
                    }
                  },
                  backColor: _themeColor.mainButtonColor3,
                  foreColor: _themeColor.mainForeColor,
                  height: _buttonHeight2,
                ),
              ]),
              TextField(
                controller: _textController,
                scrollController: _scrollController,
                readOnly: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  filled: true,
                  contentPadding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 20),
                  fillColor: _themeColor.mainResultBackColor,
                ),
                style: const TextStyle(fontSize: 12.0),
              )
            ],
          )
        )
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildFullWidthButton(
    String text,
    VoidCallback onPressed, {
      required Color backColor,
      required Color foreColor,
      required double height,
    }) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: backColor),
      child: SizedBox.expand(
        child: TextButton(
          onPressed: onPressed,
          child: Text(text, style: TextStyle(color: foreColor))
        ),
      ),
    );
  }

  Widget _buildHalfWidthButton(
      String text,
      VoidCallback onPressed, {
        required Color backColor,
        required Color foreColor,
        required double height,
      }) {
    return Expanded(
      child: SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(color: backColor),
          child: TextButton(
            onPressed: onPressed,
            child: Text(text, style: TextStyle(color: foreColor)),
          ),
        ),
      )
    );
  }

}
