import 'package:flutter/material.dart';
import '../auth/login_view.dart'; 

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _step = 1;
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Selamat Datang!",
      "desc": "Aplikasi pencatat counter terbaik untuk produktivitas Anda.",
      // "image": "assets/image/first-page.png",
      "image": "lib/assets/gif/first.gif",
    },
    {
      "title": "Fitur Canggih",
      "desc": "Dukungan riwayat, kustomisasi langkah, dan warna interaktif.",
      "image": "lib/assets/gif/second.gif",
    },
    {
      "title": "Mulai Sekarang",
      "desc": "Siapkan diri Anda untuk menghitung segala hal dengan mudah.",
      "image": "lib/assets/gif/third.gif",
    },
  ];

  void _handleNext() {
    if (_step < 3) {
      setState(() {
        _step++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil data saat ini
    final currentData = _onboardingData[_step - 1];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Langkah $_step dari 3",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              Expanded(
                flex: 2,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Image.asset(
                    currentData["image"]!,
                    key: ValueKey<int>(_step),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Judul
              Text(
                currentData["title"]!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Deskripsi
              Text(
                currentData["desc"]!,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Tombol
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _step == 3 ? "Mulai Aplikasi" : "Lanjut",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
