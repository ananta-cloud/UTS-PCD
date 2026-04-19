import 'package:flutter/material.dart';
import '../logbook/counter_view.dart';
import '../logbook/log_view.dart';
import 'login_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Controller
  final LoginController _auth = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _handleLogin() {
    final username = _userController.text;
    final password = _passController.text;

    // Memanggil logic login
    final user = _auth.login(username, password);

    if (user != null) {
      // Jika berhasil, bungkus data ke map (sesuai kebutuhan LogView kamu sebelumnya)
      final currentUser = {
        'uid': user.username.toLowerCase(),
        'username': user.username,
        'role': user.role,
        'teamId': 'MEKTRA_KLP_01',
      };

      Navigator.pushReplacement(
        context,
        // MaterialPageRoute(builder: (context) => LogView(currentUser: currentUser)),
        MaterialPageRoute(
          builder: (context) => LogView(currentUser: currentUser),
        ),
      );
    } else {
      // Jika gagal, tampilkan pesan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username atau Password salah!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logbook Login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: "Username",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              obscureText: true, // Menyembunyikan password
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("MASUK"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
