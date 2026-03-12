import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import 'package:barcodereader/l10n/app_localizations.dart';
import 'package:barcodereader/model.dart';

class ScannerPage extends StatefulWidget {
  final Function(String result) onScan;
  const ScannerPage({super.key, required this.onScan});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final MobileScannerController _scannerController;
  bool _isScanPaused = false;
  bool _isFlashing = false;
  final Color _flashColor = HSVColor.fromAHSV(1,Model.colorHue.toDouble(),0.5,1).toColor();

  @override
  void initState() {
    super.initState();
    _scannerController = _createScannerController();
    _setOrientation();
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
      return BarcodeFormat.values
          .firstWhere((format) => format.name == selection);
    } catch (_) {
      return null;
    }
  }

  void _setOrientation() {
    if (Model.lockOrientation) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final scanWindow = _calculateScanWindow(mediaSize, Model.scanAreaRestrictionLevel);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isFlashing ? _flashColor : Colors.grey[700],
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return Icon(
                      Icons.flash_off,
                      color: _isFlashing ? Colors.grey : Colors.white,
                    );
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.no_flash, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          scanWindow: scanWindow,
          controller: _scannerController,
          onDetect: (capture) {
            if (_isScanPaused) {
              return;
            }
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final Barcode? matchingBarcode =
                  _pickMatchingBarcode(barcodes);
              if (matchingBarcode == null) {
                return;
              }
              if (mounted) {
                setState(() {
                  _isScanPaused = true;
                });
              }
              final String code = matchingBarcode.rawValue ??
                  AppLocalizations.of(context)!.noData;
              final String format = matchingBarcode.format.name;
              final String result =
                  '${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())},$format,$code';
              widget.onScan(result);
              if (Model.beepOnScan && Model.beepVolume > 0.0) {
                final soundId = Model.selectedBeepSound;
                final audio = AudioPlayer();
                audio.setVolume(Model.beepVolume);
                audio.play(AssetSource('sound/beep$soundId.mp3'));
              }
              if (Model.flashOnScan) {
                if (mounted) {
                  setState(() {
                    _isFlashing = true;
                  });
                }
              }
              if (Model.snackBarTime > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(code),
                    duration: Duration(milliseconds: (Model.snackBarTime * 1000).toInt()),
                  ),
                );
              }
              if (Model.continuousScan) {
                if (Model.flashOnScan) {
                  Timer(const Duration(milliseconds: 250), () {
                    if (mounted) {
                      setState(() {
                        _isFlashing = false;
                      });
                    }
                  });
                }
                final interval = (Model.scanInterval * 1000).toInt();
                Timer(Duration(milliseconds: interval), () {
                  if (mounted) {
                    setState(() {
                      _isScanPaused = false;
                    });
                  }
                });
              } else {
                final popDelay = Model.flashOnScan ? 200 : 50;
                Timer(Duration(milliseconds: popDelay), () {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              }
            }
          }),
        if (scanWindow != null) _buildScanWindowOverlay(context, scanWindow),
      ]),
    );
  }

  Rect? _calculateScanWindow(Size size, int restrictionLevel) {
    if (restrictionLevel <= 0) {
      return null;
    }
    double heightDivisor;
    double widthFactor;
    switch (restrictionLevel) {
      case 1:
        heightDivisor = 1;
        widthFactor = 1;
        break;
      case 2:
        heightDivisor = 1.5;
        widthFactor = 1;
        break;
      case 3:
        heightDivisor = 2;
        widthFactor = 1;
        break;
      case 4:
        heightDivisor = 2.5;
        widthFactor = 1;
        break;
      case 5:
        heightDivisor = 3;
        widthFactor = 1;
        break;
      case 6:
        heightDivisor = 3.5;
        widthFactor = 1;
        break;
      case 7:
        heightDivisor = 4;
        widthFactor = 1;
        break;
      case 8:
        heightDivisor = 4.5;
        widthFactor = 1;
        break;
      default:
        return null;
    }
    final double width = size.width * widthFactor;
    final double height = size.width / heightDivisor;
    final Offset center = Offset(size.width / 2, size.height / 3);
    final double clampedWidth = width.clamp(0.0, size.width);
    final double clampedHeight = height.clamp(0.0, size.height);
    return Rect.fromCenter(
      center: center,
      width: clampedWidth,
      height: clampedHeight,
    );
  }

  Widget _buildScanWindowOverlay(BuildContext context, Rect scanWindow) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        return CustomPaint(
          size: Size(screenWidth, screenHeight),
          painter: _ScanWindowOverlayPainter(scanWindow),
        );
      },
    );
  }

  Barcode? _pickMatchingBarcode(List<Barcode> barcodes) {
    final selection = Model.selectedBarcodeFormat;
    if (selection == 'all' || selection.isEmpty) {
      return barcodes.first;
    }
    for (final barcode in barcodes) {
      if (barcode.format.name == selection) {
        return barcode;
      }
    }
    return barcodes.first;
  }
}

class _ScanWindowOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  _ScanWindowOverlayPainter(this.scanWindow);
  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final Path path = Path()
      ..addRect(screenRect)
      ..addRect(scanWindow);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanWindowOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }

}
