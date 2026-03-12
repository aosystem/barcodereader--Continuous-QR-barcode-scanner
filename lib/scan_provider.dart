import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DuplicateRemovalEntry {
  const DuplicateRemovalEntry({required this.data, required this.removedCount});

  final String data;
  final int removedCount;
}

class ScanProvider extends ChangeNotifier {
  List<String> _scanResults = [];
  static const String _scanResultsKey = 'scan_results';
  List<String> get scanResults => _scanResults;

  Future<void> loadScanResults() async {
    final prefs = await SharedPreferences.getInstance();
    _scanResults = prefs.getStringList(_scanResultsKey) ?? [];
    notifyListeners();
  }

  Future<void> addScanResult(String result) async {
    _scanResults.add(result);
    await _saveResults();
  }

  Future<void> deleteScanResult(int index) async {
    if (index >= 0 && index < _scanResults.length) {
      _scanResults.removeAt(index);
      await _saveResults();
    }
  }

  Future<void> deleteLastScanResult() async {
    if (_scanResults.isNotEmpty) {
      _scanResults.removeLast();
      await _saveResults();
    }
  }

  Future<void> deleteAllScanResults() async {
    _scanResults.clear();
    await _saveResults();
  }

  Future<List<DuplicateRemovalEntry>> removeDuplicateScanResults() async {
    final seenKeys = <String>{};
    final removalCounts = <String, int>{};
    final displayTexts = <String, String>{};
    final indexesToRemove = <int>[];

    for (var i = 0; i < _scanResults.length; i++) {
      final entry = _scanResults[i];
      final parts = entry.split(',');

      final hasContent = parts.length >= 3;
      final format = hasContent ? parts[1] : '';
      final content = hasContent ? parts.sublist(2).join(',') : entry;
      final key = hasContent ? '$format::$content' : entry;

      displayTexts.putIfAbsent(key, () => content);

      if (!seenKeys.add(key)) {
        removalCounts.update(key, (value) => value + 1, ifAbsent: () => 1);
        indexesToRemove.add(i);
      }
    }

    if (indexesToRemove.isEmpty) {
      return const <DuplicateRemovalEntry>[];
    }

    indexesToRemove.sort((a, b) => b.compareTo(a));
    for (final index in indexesToRemove) {
      _scanResults.removeAt(index);
    }

    await _saveResults();

    return removalCounts.entries
        .map(
          (entry) => DuplicateRemovalEntry(
            data: displayTexts[entry.key] ?? entry.key,
            removedCount: entry.value,
          ),
        )
        .toList();
  }

  Future<void> _saveResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scanResultsKey, _scanResults);
    notifyListeners();
  }

  String getFormattedResults() {
    return _scanResults.map((res) {
      final parts = res.split(',');
      if (parts.length >= 2) {
        parts[1] = parts[1].split('.').last;
        return parts.join(',');
      }
      return res;
    }).join('\n');
  }

  String getLastScanContent() {
    if (_scanResults.isEmpty) return '';
    final parts = _scanResults.last.split(',');
    if (parts.length >= 3) {
      return parts.sublist(2).join(',');
    }
    return _scanResults.last;
  }

  String toCsv() {
    return _scanResults
        .map((line) {
          final parts = line.split(',');
          if (parts.length >= 3) {
            final timestamp = parts[0];
            final format = parts[1];
            final content =
                '"${parts.sublist(2).join(',').replaceAll('"', '""')}"';
            return '"$timestamp","$format",$content';
          }
          return line;
        })
        .join('\n');
  }
}
