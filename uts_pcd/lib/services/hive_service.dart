import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/models/log_model.dart';
import 'package:uuid/uuid.dart';

class HiveService {
  static const String boxName = 'logbookBox';

  // Inisialisasi Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LogModelAdapter());
    await Hive.openBox<LogModel>(boxName);
  }

  // Simpan Data (Offline First)
  static Future<void> saveLogbook(String content) async {
    var box = Hive.box<LogModel>(boxName);
    final id = const Uuid().v4();

    final newLog = LogModel(
      id: id, 
      title: "Log $id", 
      description: content,
      date: DateTime.now(),
      isSynced: false, 
      authorId: 'currentUserId', 
      teamId: 'currentTeamId',
    );

    await box.put(id, newLog);
    syncData();
  }

  // Fungsi Sinkronisasi ke "Database Online" (Simulasi)
  static Future<void> syncData() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) return;

    var box = Hive.box<LogModel>(boxName);
    var unsyncedLogs = box.values.where((log) => !log.isSynced).toList();

    if (unsyncedLogs.isEmpty) return;

    print("Sedang menyelaraskan ${unsyncedLogs.length} data...");

    for (var log in unsyncedLogs) {
      try {
        // SIMULASI API CALL (Ganti dengan http.post atau Firebase kamu)
        await Future.delayed(const Duration(seconds: 1)); 
        
        // Jika sukses kirim ke server:
        log.isSynced = true;
        await log.save(); // Update status di lokal Hive
        print("Log ${log.id} tersinkronisasi.");
      } catch (e) {
        print("Gagal sinkron: $e");
      }
    }
  }
}