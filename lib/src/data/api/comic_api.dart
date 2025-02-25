import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../config/environment.dart';
import '../models/comic_model.dart';

class ComicApi {
  final Dio _dio = Dio();

  ComicApi() {
    _dio.options.followRedirects = true;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
    _dio.options.validateStatus = (status) {
      return status! < 500; // Принимать коды ответа до 500
    };
  }

  Future<List<Comic>> getAllComics() async {
    try {
      final response = await _dio.get("${Environment.API_URL}/comics/");
      debugPrint("Получен ответ от сервера: ${response.statusCode}");

      if (response.statusCode! >= 200 && response.statusCode! < 300 && response.data is List) {
        return (response.data as List).map((json) {
          try {
            return Comic.fromJson(json);
          } catch (e) {
            debugPrint("Ошибка при парсинге комикса: $e");
            // Создаем "заглушку" с минимальными данными
            return Comic(
              id: 0,
              title: "Ошибка загрузки",
              coverImagePath: "",
            );
          }
        }).toList();
      } else {
        debugPrint("Некорректный ответ сервера: ${response.data}");
        return [];
      }
    } catch(e) {
      debugPrint("getAllComics error: $e");
      return [];
    }
  }

  Future<void> uploadComicCover(int id, File imageFile) async {
    try {
      var formData = FormData.fromMap({
        "cover": await MultipartFile.fromFile(
          imageFile.path,
        ),
      });

      final response = await _dio.post(
        "${Environment.API_URL}/comics/$id/cover/",
        data: formData,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        debugPrint("Обложка успешно загружена");
      } else {
        debugPrint("Ошибка загрузки обложки: ${response.statusCode}, ${response.data}");
        throw Exception("Ошибка загрузки обложки комикса: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Ошибка загрузки обложки: $e");
      throw Exception("Ошибка загрузки обложки комикса");
    }
  }

  Future<int?> uploadComic(String title) async {
    try {
      final data = {
        "title": title,
        "cover_image_path": "",
      };

      final response = await _dio.post(
        "${Environment.API_URL}/comics/",
        data: jsonEncode(data),
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300 && response.data is Map && response.data["comic_id"] != null) {
        return response.data["comic_id"] as int;
      } else {
        debugPrint("Некорректный ответ при создании комикса: ${response.data}");
        return null;
      }
    } catch (e) {
      debugPrint("Ошибка создания комикса: $e");
      return null;
    }
  }
}