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
    if (coverPath == null ||
        coverPath.isEmpty ||
        coverPath == 'example.png' ||
        !(coverPath.startsWith('uploads/covers/') || coverPath.startsWith('uploads/images/'))) {
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
}