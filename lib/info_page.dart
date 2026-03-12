import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:barcodereader/l10n/app_localizations.dart';
import 'package:barcodereader/scan_provider.dart';
import 'package:barcodereader/ad_manager.dart';
import 'package:barcodereader/ad_banner_widget.dart';
import 'package:barcodereader/model.dart';
import 'package:barcodereader/theme_color.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});
  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  late AdManager _adManager;
  late ThemeColor _themeColor;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _adManager = AdManager();
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.backColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l.information),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<ScanProvider>(
          builder: (context, scanProvider, child) {
            final results = scanProvider.scanResults;
            if (results.isEmpty) {
              return Center(
                child: Text(l.noData),
              );
            }
            final breakdown = _calculateBreakdown(results);
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTotal(results.length),
                const Divider(height: 40),
                for (final entry in breakdown)
                  _buildEntry(entry.key, entry.value)
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  List<MapEntry<String, int>> _calculateBreakdown(List<String> scanResults) {
    final counts = <String, int>{};
    for (final result in scanResults) {
      final parts = result.split(',');
      String format;
      if (parts.length >= 2) {
        final formatPart = parts[1];
        final normalizedFormat = formatPart.split('.').last;
        format = normalizedFormat.isEmpty ? 'unknown' : normalizedFormat;
      } else {
        format = 'unknown';
      }
      counts.update(format, (value) => value + 1, ifAbsent: () => 1);
    }
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.key.compareTo(b.key);
      });
    return sortedEntries;
  }

  Widget _buildTotal(int count) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Total: $count', style: Theme.of(context).textTheme.titleLarge),
        )
      )
    );
  }

  Widget _buildEntry(String format, int count) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('$format: $count', style: Theme.of(context).textTheme.titleLarge),
        )
      )
    );
  }

}
