import 'package:dio/dio.dart';

import '../../../config/environment.dart';
import '../models/comic_model.dart';

class ComicApi {
  final Dio _dio = Dio();

  Future<List<Comic>> getAllComics() async {
    final response = await _dio.get("${Environment.API_URL}/comics");
    return (response.data as List).map((json) => Comic.fromJson(json)).toList();
  }
}