// lib/src/data/models/comic_model.dart
class Comic {
  int? id;
  String? title;
  String? coverImagePath;
  DateTime? createdAt;
  DateTime? updatedAt;

  Comic({
    this.id,
    this.title,
    this.coverImagePath,
    this.createdAt,
    this.updatedAt,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    // Проверяем и фильтруем некорректные пути к обложке
    String? coverPath = json["cover_image_path"];

    // Отфильтровываем некорректные пути обложки
    if (coverPath == null || coverPath.isEmpty) {
      coverPath = '';
    }

    return Comic(
      id: json['id'] != null ? json['id'] as int : null,
      title: json['title'],
      coverImagePath: coverPath,
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"])
          : null,
    );
  }

  // Преобразование в Map для сохранения в базу данных
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_image_path': coverImagePath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}