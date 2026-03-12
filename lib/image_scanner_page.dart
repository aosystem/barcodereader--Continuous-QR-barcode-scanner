import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:barcodereader/l10n/app_localizations.dart';
import 'package:barcodereader/model.dart';
import 'package:barcodereader/ad_manager.dart';
import 'package:barcodereader/ad_banner_widget.dart';
import 'package:barcodereader/theme_color.dart';

class ImageScannerPage extends StatefulWidget {
  const ImageScannerPage({super.key, required this.onScan});

  final FutureOr<void> Function(String result) onScan;

  @override
  State<ImageScannerPage> createState() => _ImageScannerPageState();
}

class _ImageScannerPageState extends State<ImageScannerPage> {
  late final MobileScannerController _scannerController;
  late final TransformationController _transformationController;
  late final AdManager _adManager;
  final GlobalKey _imageBoundaryKey = GlobalKey();
  XFile? _selectedImage;
  String? _statusMessage;
  bool _isProcessing = false;
  double _contrast = 1.0;
  late ThemeColor _themeColor;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _scannerController = _createScannerController();
    _transformationController = TransformationController();
    _adManager = AdManager();
  }

  MobileScannerController _createScannerController() {
    final BarcodeFormat? selectedFormat = _selectedBarcodeFormat();
    final List<BarcodeFormat> formats = selectedFormat == null
        ? const <BarcodeFormat>[]
        : <BarcodeFormat>[selectedFormat];
    return MobileScannerController(formats: formats);
  }

  BarcodeFormat? _selectedBarcodeFormat() {
    final selection = Model.selectedBarcodeFormat;
    if (selection == 'all') {
      return null;
    }
    try {
      return BarcodeFormat.values.firstWhere((format) => format.name == selection);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _adManager.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      return;
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    _transformationController.value = Matrix4.identity();
    setState(() {
      _selectedImage = image;
      _statusMessage = null;
      _contrast = 1.0;
    });
  }

  Future<void> _scanSelectedImage() async {
    if (kIsWeb || _selectedImage == null) {
      return;
    }
    String? tempPath;
    setState(() {
      _statusMessage = null;
      _isProcessing = true;
    });
    try {
      final String imagePath = await _prepareImagePathForScan();
      if (imagePath != _selectedImage!.path) {
        tempPath = imagePath;
      }
      final BarcodeCapture? capture = await _scannerController.analyzeImage(
        imagePath,
      );
      if (!mounted) {
        return;
      }
      final Barcode? matchingBarcode = capture?.barcodes.isNotEmpty ?? false
          ? _pickMatchingBarcode(capture!.barcodes)
          : null;
      if (matchingBarcode == null) {
        setState(() {
          _statusMessage = AppLocalizations.of(context)!.imageScanNotFound;
          _isProcessing = false;
        });
        return;
      }
      final l = AppLocalizations.of(context)!;
      final String code = matchingBarcode.rawValue ?? l.noData;
      final String format = matchingBarcode.format.name;
      final String result = '${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())},$format,$code';
      await Future.sync(() => widget.onScan(result));
      if (Model.beepOnScan && Model.beepVolume > 0.0) {
        final soundId = Model.selectedBeepSound;
        final audio = AudioPlayer();
        audio.setVolume(Model.beepVolume);
        audio.play(AssetSource('sound/beep$soundId.mp3'));
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = code;
        _isProcessing = false;
      });
      if (Model.snackBarTime > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(code),
            duration: Duration(
              milliseconds: (Model.snackBarTime * 1000).toInt(),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = error.toString();
        _isProcessing = false;
      });
    } finally {
      if (tempPath != null) {
        try {
          File(tempPath).delete();
        } catch (_) {
          // ignore cleanup errors
        }
      }
    }
  }

  Barcode? _pickMatchingBarcode(List<Barcode> barcodes) {
    final selection = Model.selectedBarcodeFormat;
    if (selection == 'all') {
      return barcodes.first;
    }
    for (final barcode in barcodes) {
      if (barcode.format.name == selection) {
        return barcode;
      }
    }
    return null;
  }

  ColorFilter _contrastFilter() {
    final c = _contrast;
    final t = (1 - c) / 2;
    return ColorFilter.matrix(<double>[
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, 1, 0,
    ]);
  }

  Future<String> _prepareImagePathForScan() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _imageBoundaryKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return _selectedImage!.path;
    }
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final ui.Image captured =
        await boundary.toImage(pixelRatio: pixelRatio);
    final byteData =
        await captured.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return _selectedImage!.path;
    }
    final tempPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}image_scan_${DateTime.now().millisecondsSinceEpoch}.png';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(
      byteData.buffer.asUint8List(),
      flush: true,
    );
    return tempPath;
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    final l = AppLocalizations.of(context)!;
    final statusStyle = Theme.of(context).textTheme.bodyMedium;
    final double statusHeight = (statusStyle?.fontSize ?? 14) * (statusStyle?.height ?? 1.2);
    return Scaffold(
      backgroundColor: _themeColor.mainBackColor,
      appBar: AppBar(
        backgroundColor: _themeColor.mainBackColor,
        title: Text(l.imageScan),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children:[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l.selectImage),
                  )
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _selectedImage == null || _isProcessing
                        ? null
                        : _scanSelectedImage,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(l.scan),
                  )
                ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                height: 4,
                child: _isProcessing
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _selectedImage == null
                  ? Center(child: Text(l.noData))
                  : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RepaintBoundary(
                      key: _imageBoundaryKey,
                      child: Container(
                        color: Colors.white,
                        child: kIsWeb
                            ? const SizedBox()
                            : InteractiveViewer(
                          transformationController: _transformationController,
                          panEnabled: true,
                          minScale: 0.8,
                          maxScale: 4,
                          child: ColorFiltered(
                            colorFilter: _contrastFilter(),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_selectedImage != null && !kIsWeb) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.tonality),
                    Expanded(
                      child: Slider(
                        value: _contrast,
                        onChanged: (value) {
                          setState(() {
                            _contrast = value;
                          });
                        },
                        min: 0,
                        max: 2,
                        divisions: 40,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: statusHeight,
                child: _statusMessage == null
                  ? const SizedBox.shrink()
                  : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _statusMessage!,
                      style: statusStyle,
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }
}
