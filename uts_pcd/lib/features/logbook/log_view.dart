import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'log_controller.dart';
import '../models/log_model.dart';
import '../../services/mongo_service.dart';
import 'log_editor_page.dart';
import '../widgets/search_log.dart';
import '../../services/access_policy.dart';
import '../../services/access_control_services.dart';
import '../../services/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/empty_log.dart';
import 'package:uuid/uuid.dart';
import '../auth/login_view.dart';
import '../image_processing/image_processing_view.dart'; 

class LogView extends StatefulWidget {
  final dynamic currentUser;
  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> with SingleTickerProviderStateMixin {
  late LogController _controller;
  late AnimationController _rotationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = LogController();

    // Konfigurasi animasi icon refresh
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _controller.isSyncingNotifier.addListener(() {
      if (_controller.isSyncingNotifier.value) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    _initData();
  }

  void _confirmDelete(LogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Logbook?"),
        content: const Text("Tindakan ini akan menghapus data secara permanen dari lokal dan cloud."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await _controller.removeLog(log);
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Log berhasil dihapus")),
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _goToEditor({LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _initData() async {
    final String teamId = widget.currentUser['teamId'] ?? "";
    final String uid = widget.currentUser['uid'] ?? "";
    final String role = widget.currentUser['role'] ?? "Anggota";

    final String? mongoUri = dotenv.env['MONGODB_URI'];
    if (mongoUri != null) await MongoService().connect(mongoUri);
    await _controller.loadLogs(teamId, uid, role);
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Mechanical': return Colors.green.shade50;
      case 'Electronic': return Colors.blue.shade50;
      case 'Software': return Colors.purple.shade50;
      default: return Colors.white;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal")
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = widget.currentUser['uid'] ?? '';
    final String role = widget.currentUser['role'] ?? 'Anggota';
    // Menggunakan currentUser untuk mengambil nama, fallback ke 'User' jika tidak ada
    final String username = widget.currentUser['username'] ?? widget.currentUser['name'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 
            ? "LogBook: $username" 
            : "Vision PCD: $username"
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Tombol sinkronisasi hanya muncul jika berada di tab Logbook
          if (_currentIndex == 0)
            ValueListenableBuilder<bool>(
              valueListenable: _controller.isSyncingNotifier,
              builder: (context, syncing, _) {
                return RotationTransition(
                  turns: _rotationController,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: syncing
                        ? null
                        : () => _controller.loadLogs(
                              widget.currentUser['teamId'],
                              widget.currentUser['uid'],
                              widget.currentUser['role'],
                            ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: _showLogoutConfirmation
          ),
        ],
      ),
      
      // Navigasi isi halaman berdasarkan tab
      body: _currentIndex == 0 ? _buildLogbookBody(currentUid, role) : const ImageProcessingView(),
      
      // Floating Action Button hanya muncul di tab Logbook DAN jika role-nya sesuai
      floatingActionButton: (_currentIndex == 0 && (role == 'Ketua' || role == 'Anggota')) 
        ? FloatingActionButton(
            onPressed: () => _goToEditor(), // Menggunakan _goToEditor tanpa parameter untuk log baru
            child: const Icon(Icons.add),
          ) 
        : null,
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Logbook',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_search),
            label: 'PCD',
          ),
        ],
      ),
    );
  }

  // Isi dari tab Logbook dipisahkan ke sini
  Widget _buildLogbookBody(String currentUid, String role) {
    return Column(
      children: [
        // Bar Status Reconnect
        ValueListenableBuilder<bool>(
          valueListenable: MongoService().isOnline,
          builder: (context, online, _) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: online ? 0 : 35, // Langsung menciut jika online
              width: double.infinity,
              color: online ? Colors.green : Colors.orange,
              child: Center(
                child: Text(
                  online
                      ? "Koneksi Cloud Aktif"
                      : "⚠️ Mode Offline: Data disimpan di HP",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        
        SearchBarWidget(onSearch: (v) => _controller.searchLogs(v)),
        
        Expanded(
          child: ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.filteredLogsNotifier,
            builder: (context, logs, _) {
              if (logs.isEmpty) {
                return EmptyLog(
                  isSearchMode: _controller.lastQuery.isNotEmpty,
                  searchQuery: _controller.lastQuery,
                );
              }
              
              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, i) {
                  final log = logs[i];
                  final bool isOwner = log.authorId == currentUid;
                  final bool isPublic = log.isPublic;
                  
                  return Card(
                    color: _getCategoryColor(log.category),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: Icon(
                        log.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                        color: log.isSynced ? Colors.green : Colors.orange,
                      ),
                      title: Text(log.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            "${isPublic ? "🌐 Publik" : "🔒 Privat"} • ${log.category}",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // EDIT BUTTON
                          if (AccessControlService.canPerform(
                            role,
                            AccessControlService.actionUpdate,
                            isOwner: isOwner,
                            isPublic: isPublic,
                          ))
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                              ),
                              onPressed: () => _goToEditor(log: log),
                            ),

                          // DELETE BUTTON
                          if (AccessControlService.canPerform(
                            role,
                            AccessControlService.actionDelete,
                            isOwner: isOwner,
                            isPublic: isPublic,
                          ))
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(log),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}