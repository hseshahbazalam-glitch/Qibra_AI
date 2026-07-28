import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryService {
  static const String _key = 'halal_scan_history';
  static const int _maxHistory = 50;

  static Future<List<ScanHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => ScanHistoryItem.fromJson(e)).toList();
  }

  static Future<void> addScan(ScanHistoryItem item) async {
    final history = await getHistory();
    history.insert(0, item);
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> toggleFavorite(int index) async {
    final history = await getHistory();
    if (index < history.length) {
      history[index] = history[index].copyWith(
        isFavorite: !history[index].isFavorite,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(history.map((e) => e.toJson()).toList()));
    }
  }
}

class ScanHistoryItem {
  final String barcode;
  final String productName;
  final String brand;
  final String status;
  final String verdictText;
  final int confidence;
  final String imageUrl;
  final DateTime scannedAt;
  final bool isFavorite;

  const ScanHistoryItem({
    required this.barcode,
    required this.productName,
    required this.brand,
    required this.status,
    required this.verdictText,
    required this.confidence,
    required this.imageUrl,
    required this.scannedAt,
    this.isFavorite = false,
  });

  ScanHistoryItem copyWith({bool? isFavorite}) {
    return ScanHistoryItem(
      barcode: barcode,
      productName: productName,
      brand: brand,
      status: status,
      verdictText: verdictText,
      confidence: confidence,
      imageUrl: imageUrl,
      scannedAt: scannedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'productName': productName,
        'brand': brand,
        'status': status,
        'verdictText': verdictText,
        'confidence': confidence,
        'imageUrl': imageUrl,
        'scannedAt': scannedAt.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) =>
      ScanHistoryItem(
        barcode: json['barcode'] ?? '',
        productName: json['productName'] ?? '',
        brand: json['brand'] ?? '',
        status: json['status'] ?? '',
        verdictText: json['verdictText'] ?? '',
        confidence: json['confidence'] ?? 0,
        imageUrl: json['imageUrl'] ?? '',
        scannedAt: DateTime.parse(json['scannedAt']),
        isFavorite: json['isFavorite'] ?? false,
      );
}
