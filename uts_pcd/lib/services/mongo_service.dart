import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  Db? _db;
  DbCollection? _collection;
  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  // Getter untuk mengecek status koneksi (berguna untuk test)
  Db? get db => _db;

  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3,
      );
      await connect(); // Memanggil tanpa argumen agar menggunakan .env
    }
    return _collection!;
  }

  /// Inisialisasi Koneksi ke MongoDB Atlas
  Future<void> connect([String? uri]) async {
    try {
      // Logika Fallback: Gunakan parameter jika ada, jika tidak gunakan .env
      final dbUri = (uri != null && uri.isNotEmpty)
          ? uri
          : (dotenv.env['MONGODB_URI'] ?? dotenv.env['MONGO_URI']);

      if (dbUri == null || dbUri.isEmpty) {
        throw Exception(
          "MONGODB_URI tidak ditemukan di .env maupun parameter.",
        );
      }

      _db = await Db.create(dbUri);
      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw Exception("Koneksi Timeout. Cek IP Whitelist atau Sinyal."),
      );

      _collection = _db!.collection('logs');
      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Koneksi - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// READ: Mengambil data dari Cloud
  Future<List<LogModel>> getLogs() async {
    try {
      final collection = await _getSafeCollection(); // Gunakan jalur aman

      await LogHelper.writeLog(
        "INFO: Fetching data from Cloud...",
        source: _source,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await collection.find().toList();
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      // return [];
      rethrow;
    }
  }

  /// CREATE: Menambahkan data baru
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection.insertOne(log.toMap());

      await LogHelper.writeLog(
        "SUCCESS: Data '${log.title}' Saved to Cloud",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// UPDATE: Memperbarui data berdasarkan ID
  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      if (log.id == null) {
        throw Exception("ID Log tidak ditemukan untuk update");
      }

      await collection.replaceOne(where.id(log.id!), log.toMap());

      await LogHelper.writeLog(
        "DATABASE: Update '${log.title}' Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Update Gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// DELETE: Menghapus dokumen
  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));

      await LogHelper.writeLog(
        "DATABASE: Hapus ID $id Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Hapus Gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _collection = null;
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }
}
