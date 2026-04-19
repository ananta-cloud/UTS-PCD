class User {
  final String username;
  final String password;
  final String role; 
  User({required this.username, required this.password, required this.role});
}

class LoginController {
  final List<User> _users = [
    User(username: "admin", password: "123", role: "admin"),
    User(username: "admin1", password: "123", role: "user"),
    User(username: "agus", password: "123", role: "admin"),
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
