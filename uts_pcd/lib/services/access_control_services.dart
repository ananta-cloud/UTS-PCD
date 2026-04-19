import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota', 'Ketua', 'Asisten'];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix perizinan dasar
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Asisten': [actionRead, actionUpdate], // Asisten tidak punya 'create' & 'delete'
  };

  static bool canPerform(
    String role,
    String action, {
    bool isOwner = false,
    bool isPublic = false,
  }) {
    final permissions = _rolePermissions[role] ?? [];
    bool hasBasicPermission = permissions.contains(action);

    // Jika secara dasar tidak punya izin (seperti Asisten mau 'delete'), langsung tolak
    if (!hasBasicPermission) return false;

    // --- LOGIC KHUSUS BERDASARKAN ROLE ---

    // 1. KETUA: Full Power pada data publik atau miliknya sendiri
    if (role == 'Ketua') {
      if (action == actionUpdate || action == actionDelete) {
        return isOwner || isPublic;
      }
    }

    // 2. ASISTEN: Bisa EDIT (Update) data publik atau miliknya sendiri,
    // tapi tidak bisa DELETE (karena tidak ada di _rolePermissions)
    if (role == 'Asisten') {
      if (action == actionUpdate) {
        return isOwner || isPublic;
      }
    }

    // 3. ANGGOTA: Hanya bisa otak-atik data miliknya sendiri
    if (role == 'Anggota') {
      if (action == actionUpdate || action == actionDelete) {
        return isOwner;
      }
    }

    return hasBasicPermission;
  }
}
