import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  // final ObjectId? id;
  final String id;
  final String title;
  final String description;
  final String kategori;
  final DateTime date;

  LogModel({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.kategori,
  });

  Color get categoryColor {
    switch (kategori) {
      case 'Urgent':
        return Colors.red;
      case 'Kerja':
        return Colors.blue;
      case 'Pribadi':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), // Pastikan selalu ada ID, buat baru jika null
      'title': title,
      'description': description,
      'kategori': kategori,
      'date': date,
    };
  }

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] is ObjectId
          ? map['_id']
          : ObjectId.fromHexString(map['_id']?.toString() ?? ''),
      title: map['title'],
      description: map['description'],
      kategori: map['kategori'] ?? "Kerja",
      date: map['date'] is DateTime
          ? map['date']
          : DateTime.parse(map['date'] ?? DateTime.now().toString()),
    );
  }
}
