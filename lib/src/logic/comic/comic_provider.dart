import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/comic_api.dart';
import '../../data/models/comic_model.dart';

final comicsApiProvider = Provider<ComicApi>((ref) => ComicApi());

final comicsListProvider = FutureProvider.autoDispose<List<Comic>>((ref) async {
  final api = ref.read(comicsApiProvider);
  return api.getAllComics();
});

final uploadComicProvider = FutureProvider.autoDispose.family<int?, Map<String, dynamic>>((ref, params) async {
  final title = params['title'];
  final api = ref.read(comicsApiProvider);

  try {
    return await api.uploadComic(title);
  } catch (e) {
    debugPrint("Upload error: \$e");
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
    debugPrint("Upload error: \$e");
    return;
  }
});