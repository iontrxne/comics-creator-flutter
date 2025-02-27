import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/comic_api.dart';
import '../../data/models/comic_model.dart';

final comicsApiProvider = Provider<ComicApi>((ref) => ComicApi());

// Изменяем провайдер, чтобы отлавливать ошибки связанные с типами
final comicsListProvider = FutureProvider.autoDispose<List<Comic>>((ref) async {
  final api = ref.read(comicsApiProvider);
  try {
    final comics = await api.getAllComics();
    debugPrint("Загружено комиксов: ${comics.length}");
    return comics;
  } catch (e) {
    debugPrint("Ошибка загрузки списка комиксов: $e");
    // Возвращаем пустой список вместо ошибки
    return [];
  }
});

final uploadComicProvider = FutureProvider.autoDispose.family<int?, Map<String, dynamic>>((ref, params) async {
  final title = params['title'];
  final api = ref.read(comicsApiProvider);

  try {
    return await api.uploadComic(title);
  } catch (e) {
    debugPrint("Upload error: $e");
    return null;
  }
});

final uploadComicCoverProvider = FutureProvider.autoDispose.family<void, Map<String, dynamic>>((ref, params) async {
  final id = params['id'];
  final imageFile = params['imageFile'];
  final api = ref.read(comicsApiProvider);

  try {
    return await api.uploadComicCover(id, imageFile);
  } catch (e) {
    debugPrint("Upload error: $e");
    return;
  }
});