import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart'; 
import 'package:path_provider/path_provider.dart'; 

class LogHelper {
  static const int configLevel = 2;
  static const List<String> muteList = []; 

  static Future<void> writeLog(
    String message, {
    String source = "Unknown", 
    int level = 2,
  }) async {
    // 1. Filter Konfigurasi (Menggunakan konstanta lokal)
    if (level > configLevel) return;
    if (muteList.contains(source)) return;

    try {
      // 2. Format Waktu untuk Konsol
      String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      String label = _getLabel(level);
      String color = _getColor(level);
      String logLine = '[$timestamp][$label][$source] -> $message';

      // 3. Output ke VS Code Debug Console (Non-blocking)
      dev.log(message, name: source, time: DateTime.now(), level: level * 100);

      // 4. Output ke Terminal
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');
      await _writeToFile(logLine);
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static Future<void> _writeToFile(String logLine) async {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    String dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final file = File('${logDir.path}/$dateStr.log');

    // Menambah log ke baris baru tanpa menghapus yang lama
    await file.writeAsString('$logLine\n', mode: FileMode.append);
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}