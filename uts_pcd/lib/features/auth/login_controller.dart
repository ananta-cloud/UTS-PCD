class User {
  final String username;
  final String password;
  final String role; 
  User({required this.username, required this.password, required this.role});
}

class LoginController {
  final List<User> _users = [
    User(username: "Ketua", password: "123", role: "Ketua"),
    User(username: "Anggota", password: "123", role: "Anggota"),
    User(username: "Asisten", password: "123", role: "Asisten"),
  ];

  User? login(String username, String password) {
    try {
      return _users.firstWhere(
        (user) => user.username == username && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}
