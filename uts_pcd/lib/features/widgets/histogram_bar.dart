import 'package:flutter/material.dart';

class HistogramPainter extends CustomPainter {
  final List<int> data;
  HistogramPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final double widthPerBar = size.width / 256;
    
    // Cari nilai frekuensi tertinggi
    final int maxVal = data.reduce((curr, next) => curr > next ? curr : next);

    // Cegah error pembagian dengan nol jika gambar belum ada (semua nilai = 0)
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