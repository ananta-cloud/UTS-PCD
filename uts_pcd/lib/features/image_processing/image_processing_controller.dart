import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

enum ImageFilterType { 
  none, grayscale, invert, citraBiner, lowPass, highPass, bandPass, median, mean, gaussian, 
  histEq, histAdaptive, histSpec 
}

class ImageProcessingController extends ChangeNotifier {
  File? _selectedFile;
  Uint8List? _processedBytes;
  List<int>? _histogramData;
  ImageFilterType _activeFilter = ImageFilterType.none;
  bool _isProcessing = false;
  double _sliderValue = 128.0;

  File? get selectedFile => _selectedFile;
  Uint8List? get processedBytes => _processedBytes;
  List<int>? get histogramData => _histogramData;
  ImageFilterType get activeFilter => _activeFilter;
  bool get isProcessing => _isProcessing;
  double get sliderValue => _sliderValue;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      _selectedFile = File(picked.path);
      _sliderValue = 128.0; // Reset nilai slider ke default tengah
      await applyFilter(ImageFilterType.none);
    }
  }

  void updateSlider(double value) {
    _sliderValue = value;
    notifyListeners();
  }

  Future<void> applyFilter(ImageFilterType filter) async {
    if (_selectedFile == null) return;
    _activeFilter = filter;
    _isProcessing = true;
    notifyListeners();

    final originalBytes = await _selectedFile!.readAsBytes();
    
    // Hasil komputasi di background thread akan mengembalikan gambar dan histogram
    final result = await compute(_processImageIsolate, {
      'bytes': originalBytes,
      'filter': filter,
      'sliderValue': _sliderValue,
    });

    _processedBytes = result['bytes'];
    _histogramData = result['histogram'];
    _isProcessing = false;
    notifyListeners();
  }
}

// Fungsi komputasi Isolate (Tidak memblokir UI Thread)
Future<Map<String, dynamic>> _processImageIsolate(Map<String, dynamic> params) async {
  final bytes = params['bytes'] as Uint8List;
  final filter = params['filter'] as ImageFilterType;
  final double sliderVal = params['sliderValue'];
  
  img.Image? image = img.decodeImage(bytes);
  if (image == null) return {'bytes': bytes, 'histogram': List<int>.filled(256, 0)};

  // Optimasi resolusi agar komputasi konvolusi dan histogram berjalan lancar
  if (image.width > 800) {
    image = img.copyResize(image, width: 800);
  }

  switch (filter) {
    case ImageFilterType.grayscale: 
      img.grayscale(image); 
      break;
      
    case ImageFilterType.invert: 
      img.invert(image); 
      break;
      
    case ImageFilterType.citraBiner: 
      img.grayscale(image);
      final int threshold = sliderVal.toInt();
      for (final p in image) {
        // Karena sudah grayscale, intensitas warna sama rata, ambil dari p.r
        final int bw = p.r >= threshold ? 255 : 0;
        p.r = p.g = p.b = bw;
      }
      break;
      
    case ImageFilterType.gaussian: 
      img.gaussianBlur(image, radius: 3); 
      break;
      
    case ImageFilterType.lowPass: 
    case ImageFilterType.mean:
      img.gaussianBlur(image, radius: 2); 
      break;
      
    case ImageFilterType.highPass: 
      img.convolution(image, filter: [-1, -1, -1, -1, 8, -1, -1, -1, -1]); 
      break;
      
    case ImageFilterType.bandPass:
      img.convolution(image, filter: [0, -1, 0, -1, 4, -1, 0, -1, 0]);
      img.gaussianBlur(image, radius: 1);
      break;
      
    case ImageFilterType.median:
      img.pixelate(image, size: 2); 
      break;

    case ImageFilterType.histEq:
      img.grayscale(image);
      List<int> hist = List.filled(256, 0);
      for (final p in image) { hist[p.r.toInt()]++; }
      
      int totalPixels = image.width * image.height;
      List<int> cdf = List.filled(256, 0);
      cdf[0] = hist[0];
      for (int i = 1; i < 256; i++) { cdf[i] = cdf[i - 1] + hist[i]; }
      
      List<int> map = List.filled(256, 0);
      int minCdf = 0;
      for (int c in cdf) { if (c > 0) { minCdf = c; break; } }
      
      if (totalPixels - minCdf > 0) {
        for (int i = 0; i < 256; i++) {
          map[i] = ((cdf[i] - minCdf) / (totalPixels - minCdf) * 255).round().clamp(0, 255);
        }
        for (final p in image) {
          int newVal = map[p.r.toInt()];
          p.r = p.g = p.b = newVal;
        }
      }
      break;

    case ImageFilterType.histAdaptive:
      img.grayscale(image);
      img.adjustColor(image, contrast: 1.5 + (sliderVal / 255));
      break;

    case ImageFilterType.histSpec:
      img.grayscale(image);
      
      // 1. Kalkulasi histogram asli
      List<int> histSrc = List.filled(256, 0);
      for (final p in image) { histSrc[p.r.toInt()]++; }
      List<double> cdfSrc = List.filled(256, 0.0);
      int sumSrc = 0;
      for (int i = 0; i < 256; i++) {
        sumSrc += histSrc[i];
        cdfSrc[i] = sumSrc / (image.width * image.height);
      }

      // 2. Definisi distribusi target
      List<double> cdfTarget = List.filled(256, 0.0);
      double sumTarget = 0;
      for (int i = 0; i < 256; i++) {
        double vqTarget = exp(-pow(i - sliderVal, 2) / (2 * pow(50, 2))); 
        sumTarget += vqTarget;
        cdfTarget[i] = sumTarget;
      }
      for (int i = 0; i < 256; i++) { cdfTarget[i] /= sumTarget; }

      // 3. Pencarian nilai ekualisasi Vq
      List<int> mapping = List.filled(256, 0);
      for (int i = 0; i < 256; i++) {
        double minDiff = double.infinity;
        int vqMatch = 0; 
        for (int j = 0; j < 256; j++) {
          double diff = (cdfSrc[i] - cdfTarget[j]).abs();
          if (diff < minDiff) {
            minDiff = diff;
            vqMatch = j;
          }
        }
        mapping[i] = vqMatch;
      }

      // 4. Menerapkan pemetaan Vq
      for (final p in image) {
        int newVal = mapping[p.r.toInt()];
        p.r = p.g = p.b = newVal;
      }
      break;

    default: break;
  }
  
  // Kalkulasi data pratinjau Histogram pasca-proses filter
  List<int> finalHistogram = List.filled(256, 0);
  for (final p in image) {
    int intensity = ((p.r + p.g + p.b) / 3).round().clamp(0, 255);
    finalHistogram[intensity]++;
  }

  return {
    'bytes': Uint8List.fromList(img.encodeJpg(image)),
    'histogram': finalHistogram,
  };
}