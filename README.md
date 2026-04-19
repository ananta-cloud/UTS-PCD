# Aplikasi Logbook Offline & Vision PCD (Evaluasi Tengah Semester)

Aplikasi ini merupakan penggabungan fungsionalitas pencatatan cerdas yang telah dikonfigurasi untuk berjalan secara *offline* (penyimpanan lokal) dengan modul *image processing* (PCD) yang dibangun menggunakan manipulasi *pixel native* Dart.

## Prasyarat Instalasi
1. Pastikan **Flutter SDK** (versi stabil terbaru) sudah terinstal dan terkonfigurasi di *environment path* komputer Anda.
2. Pastikan **Dart SDK** sudah terinstal.
3. Code Editor seperti VS Code atau Android Studio dengan ekstensi Flutter.

## Langkah-langkah Instalasi (Dari Awal)
Ikuti instruksi berikut untuk menjalankan program hanya dengan mengandalkan folder `lib` dan pustaka lokal.

**Langkah 1: Siapkan Proyek**
1. Ekstrak *file* arsip `.zip` proyek ini.
2. Buka terminal atau CMD, lalu buat proyek Flutter baru (jika Anda belum memilikinya) dengan menjalankan perintah:
   `flutter create uts_pcd`
3. Masuk ke dalam direktori proyek tersebut:
   `cd uts_pcd`
4. Hapus folder `lib/` bawaan instalasi, lalu tempelkan (*paste*) folder `lib/` dari arsip yang baru saja Anda ekstrak ke dalam direktori proyek ini.

**Langkah 2: Konfigurasi Pustaka (Dependencies)**
Buka file `pubspec.yaml`. Karena aplikasi telah dimodifikasi menjadi murni *offline*, pastikan Anda menghapus dependensi basis data *cloud* (`mongo_dart` dan `flutter_dotenv`). Tambahkan *package* pemrosesan citra berikut:

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.7
  image: ^4.1.7
  intl: ^0.19.0
  hive_flutter: ^1.1.0
  connectivity_plus: ^5.0.2
  uuid: ^4.3.3
  shared_preferences: ^2.2.2

**Langkah 3: Sinkronisasi Package**
```
flutter pub get
```

**Langkah 4: Jalankan Aplikasi**
```
flutter run
```
