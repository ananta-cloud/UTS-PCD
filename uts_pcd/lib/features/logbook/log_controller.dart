import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController {
  // Notifier utama untuk data asli
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  // PERBAIKAN: Inisialisasi notifier untuk pencarian agar tidak null
  final ValueNotifier<List<LogModel>> filteredLogsNotifier =
      ValueNotifier<List<LogModel>>([]);

  String lastQuery = "";

  // PERBAIKAN: Tambahkan kunci storage yang hilang
  static const String _storageKey = 'user_logs_data';

  List<LogModel> get logs => logsNotifier.value;

  LogController() {
    loadFromDisk();
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

  // 1. Menambah data
  Future<void> addLog(String title, String desc, String kategori) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      kategori: kategori,
      date: DateTime.now(),
    );

    try {
      await MongoService().insertLog(newLog);

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(newLog);

      // PERBAIKAN: Update state dan simpan ke disk di dalam blok try
      logsNotifier.value = currentLogs;
      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Tambah data Berhasil",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal sinkronisasi Add - $e", level: 1);
    }
  }

  // 2. Memperbarui data
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
      kategori: tempKategori, // Gunakan kategori baru dari dialog
      date: DateTime.now(),
    );

    try {
      await MongoService().updateLog(updatedLog);

      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;
      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Update Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Update Gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // 3. Menghapus data (Sekarang menggunakan objek Log agar lebih aman)
  Future<void> removeLog(LogModel targetLog) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);

    try {
      if (targetLog.id == null) throw Exception("ID Log tidak ditemukan.");

      await MongoService().deleteLog(targetLog.id!);

      currentLogs.removeWhere((element) => element.id == targetLog.id);
      logsNotifier.value = currentLogs;
      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Hapus Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Hapus Gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // --- PERSISTENCE ---

  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // PERBAIKAN: Sebelum jsonEncode, pastikan semua data menjadi tipe dasar (String/Int)
      final List<Map<String, dynamic>> mappedData = logsNotifier.value.map((
        log,
      ) {
        final map = log.toMap();
        // Ubah ObjectId menjadi String Hex agar bisa masuk JSON
        map['_id'] = (map['_id'] as ObjectId).toHexString();
        // Ubah DateTime menjadi ISO String agar bisa masuk JSON
        map['date'] = (map['date'] as DateTime).toIso8601String();
        return map;
      }).toList();

      final String encodedData = jsonEncode(mappedData);
      await prefs.setString(_storageKey, encodedData);

      await LogHelper.writeLog(
        "SUCCESS: Backup Lokal diperbarui",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal saveToDisk - $e", level: 1);
    }
  }

  // 2. Fungsi Load Data (Cloud & Lokal)
  Future<void> loadFromDisk() async {
    try {
      // Coba ambil data terbaru dari Cloud
      final cloudData = await MongoService().getLogs();
      logsNotifier.value = cloudData;

      // Update cache lokal setiap kali berhasil ambil dari Cloud
      await saveToDisk();
    } catch (e) {
      // Jika Offline/Gagal Cloud, ambil dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? localData = prefs.getString(_storageKey);

      if (localData != null) {
        final List<dynamic> decoded = jsonDecode(localData);
        // factory LogModel.fromMap Anda sudah bisa menangani konversi String ke ObjectId
        logsNotifier.value = decoded.map((m) => LogModel.fromMap(m)).toList();
      }

      await LogHelper.writeLog(
        "INFO: Berjalan dalam mode Offline/Local",
        level: 2,
      );
    }
  }
}
