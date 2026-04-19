import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Hapus import mongo_dart dan mongo_service
import '../models/log_model.dart';
import '../../helpers/log_helper.dart';

class LogController {
  // Notifier utama untuk data asli
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  // Notifier untuk pencarian agar tidak null
  final ValueNotifier<List<LogModel>> filteredLogsNotifier =
      ValueNotifier<List<LogModel>>([]);

  String lastQuery = "";

  // Kunci storage untuk SharedPreferences
  static const String _storageKey = 'user_logs_data';

  List<LogModel> get logs => logsNotifier.value;

  LogController() {
    // Setiap kali logsNotifier berubah, filter otomatis dijalankan
    logsNotifier.addListener(() {
      _applyFilter();
    });
  }

  // Fungsi pencarian untuk dipanggil dari UI
  void searchLogs(String query) {
    lastQuery = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (lastQuery.isEmpty) {
      filteredLogsNotifier.value = logsNotifier.value;
    } else {
      filteredLogsNotifier.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(lastQuery.toLowerCase()) ||
                log.description.toLowerCase().contains(lastQuery.toLowerCase()),
          )
          .toList();
    }
  }

  // 1. Menambah data (Lokal)
  Future<void> addLog(String title, String desc, String kategori) async {
    final newLog = LogModel(
      // Menggunakan timestamp sebagai Unique ID String pengganti ObjectId
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      title: title,
      description: desc,
      kategori: kategori,
      date: DateTime.now(),
    );

    try {
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(newLog);

      // Update state dan simpan ke disk
      logsNotifier.value = currentLogs;
      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Tambah data lokal Berhasil",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal menambah data - $e", level: 1);
    }
  }

  // 2. Memperbarui data (Lokal)
  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
    String tempKategori,
  ) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id,
      title: newTitle,
      description: newDesc,
      kategori: tempKategori,
      date: DateTime.now(), // Memperbarui waktu modifikasi
    );

    try {
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;
      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Update lokal Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Update lokal Gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // 3. Menghapus data (Lokal)
  Future<void> removeLog(LogModel targetLog) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);

    try {
      if (targetLog.id == null) throw Exception("ID Log tidak ditemukan.");

      currentLogs.removeWhere((element) => element.id == targetLog.id);
      logsNotifier.value = currentLogs;
      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Hapus lokal Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Hapus lokal Gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // --- PERSISTENCE (PENYIMPANAN LOKAL) ---

  // Menyimpan data ke SharedPreferences
  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<Map<String, dynamic>> mappedData = logsNotifier.value.map((log) {
        final map = log.toMap();
        // ID sekarang sudah menjadi String, tidak perlu toHexString() lagi
        // Ubah DateTime menjadi ISO String agar bisa masuk JSON
        map['date'] = log.date.toIso8601String();
        return map;
      }).toList();

      final String encodedData = jsonEncode(mappedData);
      await prefs.setString(_storageKey, encodedData);

      await LogHelper.writeLog(
        "SUCCESS: Penyimpanan Lokal diperbarui",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal saveToDisk - $e", level: 1);
    }
  }

  // Membaca data murni dari SharedPreferences
  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localData = prefs.getString(_storageKey);

      if (localData != null) {
        final List<dynamic> decoded = jsonDecode(localData);
        logsNotifier.value = decoded.map((m) => LogModel.fromMap(m)).toList();
      }

      await LogHelper.writeLog(
        "INFO: Data lokal berhasil dimuat",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal memuat data lokal - $e", level: 1);
    }
  }
}