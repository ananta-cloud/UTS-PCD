import 'package:flutter/material.dart';

class EmptyLog extends StatelessWidget {
  const EmptyLog({super.key, this.isSearchMode = false, this.searchQuery = ""});
  final bool isSearchMode;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            isSearchMode ? "lib/assets/gif/empty_search.gif" : "lib/assets/gif/empty_page.gif",
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 20),
          Text(
            isSearchMode
                ? "Tidak ada hasil untuk '$searchQuery'"
                : "Belum ada catatan",
          ),
          if (isSearchMode)
            const Text(
              "Coba gunakan kata kunci lain atau pastikan ejaan benar.",
              style: TextStyle(color: Colors.grey),
            )
          else
            const Text(
              "Mulai buat catatan dengan menekan tombol tambah!",
              style: TextStyle(color: Colors.grey),
            ),
          ],
      ),
    );
  }
}
