import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'image_processing_controller.dart';
import '../widgets/histogram_bar.dart';

class ImageProcessingView extends StatefulWidget {
  const ImageProcessingView({super.key});
  @override
  State<ImageProcessingView> createState() => _ImageProcessingViewState();
}

class _ImageProcessingViewState extends State<ImageProcessingView> {
  final _controller = ImageProcessingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _controller.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _controller.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showSlider =
        _controller.activeFilter == ImageFilterType.citraBiner ||
        _controller.activeFilter == ImageFilterType.histSpec ||
        _controller.activeFilter == ImageFilterType.histAdaptive;

    return Scaffold(
      // AppBar tidak disertakan di sini karena sudah ditangani oleh log_view.dart
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Frame Pratinjau Citra
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _controller.isProcessing
                          ? const CircularProgressIndicator()
                          : _controller.processedBytes != null
                          ? Image.memory(_controller.processedBytes!)
                          : const Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey,
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Preview Histogram (Sekarang selalu tampil)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Histogram Intensitas",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors
                              .white, // Tambahkan warna latar putih agar bingkai terlihat jelas
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Menampilkan efek loading khusus untuk kotak histogram jika sedang diproses
                        child: _controller.isProcessing
                            ? const Center(child: LinearProgressIndicator())
                            : CustomPaint(
                                // Jika histogramData null, beri data list kosong bernilai 0
                                painter: HistogramPainter(
                                  _controller.histogramData ??
                                      List.filled(256, 0),
                                ),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Slider Dinamis
                  if (showSlider)
                    Column(
                      children: [
                        Text(
                          _controller.activeFilter == ImageFilterType.citraBiner
                              ? "Threshold Binarisasi: ${_controller.sliderValue.toInt()}"
                              : "Parameter Ekualisasi/Vq Target: ${_controller.sliderValue.toInt()}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: _controller.sliderValue,
                          min: 0,
                          max: 255,
                          divisions: 255,
                          label: _controller.sliderValue.toInt().toString(),
                          onChanged: (val) => _controller.updateSlider(val),
                          onChangeEnd: (val) =>
                              _controller.applyFilter(_controller.activeFilter),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Deretan Menu Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                _buildFilterChip("Normal", ImageFilterType.none),
                _buildFilterChip("Grayscale", ImageFilterType.grayscale),
                _buildFilterChip("Citra Biner", ImageFilterType.citraBiner),
                _buildFilterChip("Hist. Equalization", ImageFilterType.histEq),
                _buildFilterChip(
                  "Adaptive Hist.",
                  ImageFilterType.histAdaptive,
                ),
                _buildFilterChip("Hist. Spec", ImageFilterType.histSpec),
                _buildFilterChip("Low Pass", ImageFilterType.lowPass),
                _buildFilterChip("High Pass", ImageFilterType.highPass),
                _buildFilterChip("Band Pass", ImageFilterType.bandPass),
                _buildFilterChip("Median", ImageFilterType.median),
              ],
            ),
          ),

          // Tombol Tunggal Utama
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showImagePickerOptions,
                icon: const Icon(Icons.add_a_photo),
                label: const Text(
                  'Tambah Foto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ImageFilterType filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: _controller.activeFilter == filter,
        onSelected: (_) => _controller.applyFilter(filter),
      ),
    );
  }
}

// Widget CustomPainter untuk menggambar Grafik Batang Histogram
class HistogramPainter extends CustomPainter {
  final List<int> data;
  HistogramPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final double widthPerBar = size.width / 256;
    final int maxVal = data.reduce((curr, next) => curr > next ? curr : next);

    // Mencegah pembagian dengan nol jika gambar hitam sepenuhnya
    if (maxVal == 0) return;

    for (int i = 0; i < data.length; i++) {
      final double barHeight = (data[i] / maxVal) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(
          i * widthPerBar,
          size.height - barHeight,
          widthPerBar,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
