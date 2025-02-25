import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/comic_api.dart';
import '../../data/models/comic_model.dart';

final comicsApiProvider = Provider<ComicApi>((ref) => ComicApi());

final comicsListProvider = FutureProvider.autoDispose<List<Comic>>((ref) async {
  final api = ref.read(comicsApiProvider);
  return api.getAllComics();
});
