import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel extends HiveObject {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final String authorId;
  @HiveField(5)
  final String teamId;
  @HiveField(6)
  final bool isPublic;
  @HiveField(7)
  final String category;
  @HiveField(8)
  bool isSynced;
  @HiveField(9)
  bool isDeleted;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    this.isPublic = false, 
    this.category = 'Software',
    this.isSynced = true,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
    '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
    'title': title,
    'description': description,
    'date': date,
    'authorId': authorId,
    'teamId': teamId,
    'isPublic': isPublic,
    'category': category,
    'isSynced': isSynced,
  };

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
      category: map['category'] ?? 'Software',
      isSynced: map['isSynced'] ?? true,
    );
  }
}
