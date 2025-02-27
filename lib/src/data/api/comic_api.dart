import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../config/environment.dart';
import '../models/comic_model.dart';

class ComicApi {
  final Dio _dio = Dio();

  ComicApi() {
    // Нормализация базового URL
    String baseUrl = Environment.API_URL;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    _dio.options.baseUrl = baseUrl;
    _dio.options.followRedirects = true;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
    _dio.options.validateStatus = (status) {
      return status! < 500; // Принимать коды ответа до 500
    };

    // Добавляем интерцептор для обеспечения наличия слеша в конце URL
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Убеждаемся, что URL заканчивается на "/" для всех запросов кроме загрузки файлов
        if (!options.path.endsWith('/') && !options.path.contains('upload')) {
          options.path = "${options.path}/";
        }
        debugPrint("Отправка запроса: ${options.method} ${options.baseUrl}${options.path}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint("Получен ответ: ${response.statusCode} от ${response.requestOptions.path}");
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint("Ошибка запроса: ${error.response?.statusCode} ${error.message} от ${error.requestOptions.path}");
        return handler.next(error);
      },
    ));
  }

  Future<List<Comic>> getAllComics() async {
    try {
      // Явно добавляем слеш в конце URL согласно документации
      final response = await _dio.get("/comics/");
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

      // Явно добавляем слеш в конце URL согласно документации
      final response = await _dio.post(
        "/comics/$id/cover/",
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

      // Явно добавляем слеш в конце URL согласно документации
      final response = await _dio.post(
        "/comics/",
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