import '../features/models/log_model.dart';

class AccessPolicy {
  static bool canEdit(String userRole, String userId, LogModel log) {
    // 1. Jika dia Ketua, dia bisa edit SEMUA log yang publik
    if (userRole == 'Ketua' && log.isPublic) {
      return true;
    }

    // 2. Jika dia pemilik log tersebut (baik Ketua maupun Anggota)
    if (log.authorId == userId) {
      return true;
    }

    // 3. Selain itu, tidak punya akses edit
    return false;
  }

  static bool canDelete(String userRole, String userId, LogModel log) {
    // Biasanya hapus lebih ketat, hanya Ketua atau Pemilik
    return userRole == 'Ketua' || log.authorId == userId;
  }
}