import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:barcodereader/l10n/app_localizations.dart';
import 'package:barcodereader/scan_provider.dart';
import 'package:barcodereader/ad_manager.dart';
import 'package:barcodereader/ad_banner_widget.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ScrollController _scrollController = ScrollController();
  late AdManager _adManager;

  @override
  void initState() {
    super.initState();
    _adManager = AdManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 50), _scrollToBottom);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _adManager.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<ScanProvider>(
      builder: (context, scanProvider, child) {
        if (scanProvider.scanResults.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(l.history),
              centerTitle: true,
            ),
            body: Center(
              child: Text(l.noData),
            ),
            bottomNavigationBar: AdBannerWidget(adManager: _adManager),
          );
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(l.history),
            centerTitle: true,
          ),
          body: SafeArea(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: scanProvider.scanResults.length,
              itemBuilder: (context, index) {
                final result = scanProvider.scanResults[index];
                final parts = result.split(',');
                final timestamp =
                    parts.isNotEmpty
                        ? parts[0]
                        : l.noDate;
                final format = parts.length > 1
                    ? parts[1].split('.').last
                    : l.unknownFormat;
                final content = parts.length > 2
                    ? parts.sublist(2).join(',')
                    : l.noContent;

                final textTheme = Theme.of(context).textTheme;
                final titleStyle = textTheme.titleMedium;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text('$timestamp - $format'),
                    subtitle: Text(content, style: titleStyle),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(content),
                          actions: <Widget>[
                            TextButton(
                              child: Text(l.sendAction),
                              onPressed: () {
                                Navigator.of(context).pop();
                                SharePlus.instance.share(ShareParams(text: content));
                              },
                            ),
                            TextButton(
                              child: Text(l.deleteAction),
                              onPressed: () {
                                Navigator.of(context).pop();
                                scanProvider.deleteScanResult(index);
                              },
                            ),
                            TextButton(
                              child: Text(l.cancel),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: AdBannerWidget(adManager: _adManager),
        );
      },
    );
  }

}
