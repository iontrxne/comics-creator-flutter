import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart' as DioReq;
import 'package:dio/dio.dart';

import '../../../config/environment.dart';
import '../models/comic_model.dart';

class ComicApi {
  final Dio _dio = Dio();

  ComicApi() {
    _dio.options.followRedirects = true;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
  }

  Future<List<Comic>> getAllComics() async {
    try {
      final response = await _dio.get("${Environment.API_URL}/comics/");
      return (response.data as List).map((json) => Comic.fromJson(json)).toList();
    } catch(e) {
      debugPrint("getAllComics error: \$e");
      return [];
    }
  }

  Future<void> uploadComicCover(int id, File imageFile) async {
    try {
      var formData = FormData.fromMap({
        "cover": await MultipartFile.fromFile(
          imageFile.path,
          // filename: "${DateTime.now().millisecondsSinceEpoch}.${path.extension(imageFile.path)}",
        ),
      });

      final response = await Dio().post(
        "${Environment.API_URL}/comics/$id/cover",
        data: formData,
      );
    } catch (e) {
      throw Exception("Ошибка загрузки обложки комикса");
    }
  }

  Future<int?> uploadComic(String title) async {
    try {
      final data = {
        "title": title,
        "cover_image_path": "",
      };

      final response = await Dio().post(
        "${Environment.API_URL}/comics/",
        data: jsonEncode(data),
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );
      return response.data["comic_id"] as int;
    } catch (e) {
      return null;
    }
  }
}