import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../features/models/log_model.dart';
import '../helpers/log_helper.dart'; // Import LogHelper

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();

  Db? db;
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);

  static const String _source = "mongo_service.dart"; 

  Future<void> connect(String uri) async {
    try {
      // Tutup paksa koneksi lama yang nyangkut saat offline
      if (db != null) {
        try {
          await db!.close();
        } catch (_) {}
        db = null; 
      }

      // BUAT KONEKSI BARU YANG SEGAR
      db = await Db.create(uri);
      await db!.open().timeout(const Duration(seconds: 10)); 
      
      // UPDATE UI MENJADI ONLINE (Bar Hijau)
      isOnline.value = true; 
      await LogHelper.writeLog("DATABASE: Berhasil terhubung kembali", level: 2);

    } catch (e) {
      // JIKA GAGAL, TETAPKAN SEBAGAI OFFLINE (Bar Oranye)
      isOnline.value = false;
      db = null; 
      await LogHelper.writeLog("ERROR: Gagal terhubung - $e", level: 1);
    }
  }

  Future<List<Map<String, dynamic>>> getLogs(String teamId) async {
    if (db == null || !db!.isConnected) {
      await LogHelper.writeLog("WARNING: Mencoba getLogs saat offline", source: _source, level: 1);
      throw Exception("Offline");
    }
    
    await LogHelper.writeLog("INFO: Mengambil data untuk Team: $teamId", source: _source, level: 3);
    return await db!
        .collection('logs')
        .find(where.eq('teamId', teamId))
        .toList();
  }

  Future<void> insertLog(LogModel log) async {
    if (db == null || !db!.isConnected) {
      await LogHelper.writeLog("WARNING: Mencoba insertLog saat offline", source: _source, level: 1);
      throw Exception("Offline");
    }
    
    await db!.collection('logs').insert(log.toMap());
    await LogHelper.writeLog("SUCCESS: Data baru ditambahkan ke Cloud", source: _source, level: 2);
  }

  Future<void> updateLog(LogModel log) async {
    if (db == null || !db!.isConnected || log.id == null) {
      await LogHelper.writeLog("ERROR: Update gagal (Offline atau ID Null)", source: _source, level: 1);
      throw Exception("Offline or Null ID");
    }
    
    await db!
        .collection('logs')
        .update(where.id(ObjectId.fromHexString(log.id!)), log.toMap());
    await LogHelper.writeLog("SUCCESS: Data berhasil diperbarui di Cloud", source: _source, level: 2);
  }

  Future<void> deleteLog(String id) async {
    if (db == null || !db!.isConnected) {
      await LogHelper.writeLog("ERROR: Hapus data gagal (Offline)", source: _source, level: 1);
      throw Exception("Offline");
    }
    
    await db!.collection('logs').remove(where.id(ObjectId.fromHexString(id)));
    await LogHelper.writeLog("SUCCESS: Data berhasil dihapus dari Cloud", source: _source, level: 2);
  }

  Future<void> close() async {
    if (db != null) {
      await db!.close();
      db = null;
      isOnline.value = false;
      
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }
}