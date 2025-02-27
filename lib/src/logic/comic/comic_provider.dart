// lib/src/logic/comic/comic_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/database/database_service.dart';
import '../../data/models/comic_model.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

// Провайдер для получения списка комиксов
final comicsListProvider = FutureProvider.autoDispose<List<Comic>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  try {
    final comics = await db.getAllComics();
    debugPrint("Загружено комиксов: ${comics.length}");
    return comics;
  } catch (e) {
    debugPrint("Ошибка загрузки списка комиксов: $e");
    return [];
  }
});

// Провайдер для создания комикса
final uploadComicProvider = FutureProvider.autoDispose.family<int?, Map<String, dynamic>>((ref, params) async {
  final title = params['title'];
  final db = ref.read(databaseServiceProvider);

  try {
    return await db.createComic(title);
  } catch (e) {
    debugPrint("Ошибка создания комикса: $e");
    return null;
  }
});

// Провайдер для обновления обложки комикса
final uploadComicCoverProvider = FutureProvider.autoDispose.family<void, Map<String, dynamic>>((ref, params) async {
  final id = params['id'];
  final imageFile = params['imageFile'] as File;
  final db = ref.read(databaseServiceProvider);

  try {
    // Сохраняем изображение в локальное хранилище приложения
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'comic_${id}_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${directory.path}/$fileName');

    // Обновляем путь в базе данных
    await db.updateComicCover(id, savedImage.path);
  } catch (e) {
    debugPrint("Ошибка при загрузке обложки: $e");
    return;
  }
});

// Провайдер для удаления комикса
final deleteComicProvider = FutureProvider.autoDispose.family<bool, int>((ref, comicId) async {
  final db = ref.read(databaseServiceProvider);
  try {
    final result = await db.deleteComic(comicId);
    return result;
  } catch (e) {
    debugPrint("Ошибка при удалении комикса: $e");
    return false;
  }
});

// Провайдер для обновления информации о комиксе
final updateComicProvider = FutureProvider.autoDispose.family<bool, Map<String, dynamic>>((ref, params) async {
  final id = params['id'] as int;
  final title = params['title'] as String;
  final db = ref.read(databaseServiceProvider);

  try {
    await db.updateComicTitle(id, title);
    return true;
  } catch (e) {
    debugPrint("Ошибка при обновлении комикса: $e");
    return false;
  }
});