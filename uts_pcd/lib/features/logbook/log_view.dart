import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Pastikan path import ini sesuai dengan lokasi file image_processing_view.dart Anda
import '../image_processing/image_processing_view.dart'; 

import 'log_controller.dart';
import '../onboarding/onboarding_view.dart';
import '../models/log_model.dart';
import '../auth/login_controller.dart';
import '../widgets/search_log.dart';
import '../widgets/empty_log.dart';
import '../../helpers/log_helper.dart';

class LogView extends StatefulWidget {
  final User user;

  const LogView({super.key, required this.user});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  bool _isLoading = true;
  int _currentIndex = 0;

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "Baru saja";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} menit yang lalu";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} jam yang lalu";
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    _initLocalDatabase();
  }

  // Fungsi inisialisasi yang hanya berfokus pada penyimpanan lokal
  Future<void> _initLocalDatabase() async {
    setState(() => _isLoading = true);
    try {
      await LogHelper.writeLog("UI: Memulai inisialisasi penyimpanan offline...", source: "log_view.dart");

      // Memuat data secara offline dari disk lokal
      await _controller.loadFromDisk();
      
      await LogHelper.writeLog("UI: Data offline berhasil dimuat.", source: "log_view.dart");
    } catch (e) {
      await LogHelper.writeLog("UI: Error memuat data lokal - $e", source: "log_view.dart", level: 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Masalah saat membaca data lokal: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditLogDialog(LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    String tempKategori = log.kategori;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Catatan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Judul")),
              TextField(controller: _contentController, decoration: const InputDecoration(labelText: "Deskripsi")),
              const SizedBox(height: 15),
              DropdownButton<String>(
                value: tempKategori,
                isExpanded: true,
                items: ["Kerja", "Pribadi", "Urgent"].map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (val) => setDialogState(() => tempKategori = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                int currentIndex = _controller.logsNotifier.value.indexOf(log);
                
                await _controller.updateLog(
                  currentIndex,
                  _titleController.text, 
                  _contentController.text, 
                  tempKategori
                );
                
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLogDialog() {
    _titleController.clear();
    _contentController.clear();
    String tempKategori = "Kerja";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Catatan Baru"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(hintText: "Judul")),
              TextField(controller: _contentController, decoration: const InputDecoration(hintText: "Isi Deskripsi")),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: tempKategori,
                isExpanded: true,
                items: ["Kerja", "Pribadi", "Urgent"].map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (val) => setDialogState(() => tempKategori = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty) {
                  await _controller.addLog(
                    _titleController.text,
                    _contentController.text,
                    tempKategori,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 
            ? "LogBook (Offline): ${widget.user.username}" 
            : "Vision PCD: ${widget.user.username}"
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: _showLogoutConfirmation
          ),
        ],
      ),
      
      // Navigasi isi halaman berdasarkan tab
      body: _currentIndex == 0 ? _buildLogbookBody() : const ImageProcessingView(),
      
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
      ) : null,
      
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

  // Tampilan halaman catatan
  Widget _buildLogbookBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        SearchBarWidget(onSearch: (value) => _controller.searchLogs(value)),
        Expanded(
          // Menggunakan ValueListenableBuilder untuk reaktivitas secara real-time
          // terhadap perubahan data pada penyimpanan lokal.
          child: ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.logsNotifier,
            builder: (context, logs, child) {
              if (logs.isEmpty) {
                return const EmptyLog(isSearchMode: false);
              }

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Dismissible(
                    key: Key(log.date.toString()),
                    direction: DismissDirection.endToStart,
                    background: _buildDeleteBackground(),
                    onDismissed: (direction) => _controller.removeLog(log), 
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: VerticalDivider(color: log.categoryColor, thickness: 6),
                        title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Text(log.description),
                            const SizedBox(height: 4), 
                            Text(
                              _formatTimestamp(log.date),
                              style: const TextStyle(
                                fontSize: 12, 
                                color: Colors.blueGrey, 
                                fontStyle: FontStyle.italic
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditLogDialog(log),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _controller.removeLog(log), 
                            ),
                          ],
                        ),
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

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingView()),
              (route) => false,
            ),
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}