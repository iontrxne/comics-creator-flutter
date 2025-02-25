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
    return Comic(
      id: json['id'],
      title: json['title'],
      coverImagePath: json["cover_image_path"],
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"])
          : null,
    );
  }
}
