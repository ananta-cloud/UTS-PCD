import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/log_model.dart';
import '../../services/mongo_service.dart';
import '../../services/access_control_services.dart';
import '../../helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  // HiveBox
  final Box<LogModel> _logBox = Hive.box<LogModel>('offline_logs');

  String currentUserId = "";
  String currentTeamId = "";
  String userRole = "";
  String lastQuery = "";

  LogController() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      bool isOffline =
          results.isEmpty ||
          results.every((result) => result == ConnectivityResult.none);

      if (isOffline) {
        MongoService().isOnline.value = false;
        debugPrint("KONEKSI TERPUTUS: Masuk ke Mode Offline");
      } else {
        _handleAutoReconnect();
      }
    });

    logsNotifier.addListener(() => _applyFilters());
  }

  Future<void> _handleAutoReconnect() async {
    final String? uri = dotenv.env['MONGODB_URI'];

    if (uri != null) {
      try {
        await MongoService().connect(uri);
        if (MongoService().isOnline.value && currentTeamId.isNotEmpty) {
          await loadLogs(currentTeamId, currentUserId, userRole);
        }
      } catch (e) {
        debugPrint("Gagal Auto Reconnect: $e");
      }
    }
  }

  // Filter untuk Pencarian dan Privasi
  void _applyFilters() {
    List<LogModel> visibleLogs = logsNotifier.value.where((log) {
      bool isNotDeleted = !log.isDeleted;
      bool hasAccess = log.authorId == currentUserId || log.isPublic == true;
      return hasAccess && isNotDeleted;
    }).toList();

    if (lastQuery.isNotEmpty) {
      visibleLogs = visibleLogs
          .where(
            (log) =>
                log.title.toLowerCase().contains(lastQuery) ||
                log.description.toLowerCase().contains(lastQuery),
          )
          .toList();
    }
    filteredLogsNotifier.value = visibleLogs;
  }

  Future<void> loadLogs(String teamId, String userId, String role) async {
    currentTeamId = teamId;
    currentUserId = userId;
    userRole = role;
    isSyncingNotifier.value = true;

    _updateLocalList();

    try {
      final String? uri = dotenv.env['MONGODB_URI'];
      if (uri != null) {
        await MongoService().connect(uri);
      }

      if (MongoService().db != null && MongoService().db!.isConnected) {
        final pendingLogs = _logBox.values
            .where((log) => !log.isSynced)
            .toList();
        for (var log in pendingLogs) {
          if (log.isDeleted) {
            await MongoService().deleteLog(log.id!);
            await log.delete();
          } else {
            await MongoService().insertLog(log);
            log.isSynced = true;
            await log.save();
          }
        }

        final List<Map<String, dynamic>> data = await MongoService().getLogs(
          teamId,
        );
        for (var json in data) {
          var cloudLog = LogModel.fromMap(json);
          final local = _logBox.get(cloudLog.id);
          if (local == null || local.isSynced) {
            cloudLog.isSynced = true;
            await _logBox.put(cloudLog.id, cloudLog);
          }
        }
      }
    } catch (e) {
      debugPrint("Refresh Gagal: $e");
      MongoService().isOnline.value = false;
    } finally {
      isSyncingNotifier.value = false;
      _updateLocalList();
    }
  }

  Future<void> addLog({
    required String title,
    required String description,
    required String category,
    required bool isPublic,
  }) async {
    var newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: description,
      date: DateTime.now(),
      authorId: currentUserId,
      teamId: currentTeamId,
      category: category,
      isPublic: isPublic,
      isSynced: false,
    );

    await _logBox.put(newLog.id, newLog);
    _updateLocalList();

    try {
      await MongoService().insertLog(newLog);
      newLog.isSynced = true;
      await newLog.save();
      _updateLocalList();
    } catch (e) {
      await LogHelper.writeLog("Tambah Offline: Disimpan di lokal", level: 1);
    }
  }

  Future<void> updateLog({
    required LogModel oldLog,
    required String newTitle,
    required String newDesc,
    required String newCategory,
    required bool newIsPublic,
  }) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: newTitle,
      description: newDesc,
      date: DateTime.now(),
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      category: newCategory,
      isPublic: newIsPublic,
      isSynced: false, 
    );

    await _logBox.put(updatedLog.id, updatedLog);
    _updateLocalList();

    try {
      await MongoService().updateLog(updatedLog);
      updatedLog.isSynced = true;
      await _logBox.put(updatedLog.id, updatedLog);
      _updateLocalList();
    } catch (e) {
      await LogHelper.writeLog("Update Offline: Disimpan di lokal", level: 1);
    }
  }

  Future<void> removeLog(LogModel targetLog) async {
    bool isOwner = targetLog.authorId == currentUserId;
    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized Delete",
        level: 1,
      );
      return;
    }

    try {
      targetLog.isDeleted = true;
      targetLog.isSynced = false;
      await targetLog.save();
      _updateLocalList();
      await MongoService().deleteLog(targetLog.id!);
      await targetLog.delete();
    } catch (e) {
      await LogHelper.writeLog(
        "Hapus Offline: Menunggu sinkronisasi",
        level: 1,
      );
    }
  }

  void _updateLocalList() {
    logsNotifier.value = _logBox.values
        .where((log) => log.teamId == currentTeamId)
        .toList();
  }

  void searchLogs(String query) {
    lastQuery = query.toLowerCase();
    _applyFilters();
  }
}
