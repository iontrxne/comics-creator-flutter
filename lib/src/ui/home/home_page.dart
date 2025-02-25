import 'package:flutter/material.dart';
import 'package:flutter_animation_plus/animations/pulsing_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/environment.dart';
import '../../../config/palette.dart';
import '../../data/models/comic_model.dart';
import '../../logic/comic/comic_provider.dart';
import '../comic/create_comics_form.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _formatDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(comicsListProvider);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Palette.orangeDark, Palette.orangeAccent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: provider.when(
        data: (List<Comic> comics) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 1),
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Твои комиксы'),
                  centerTitle: true,
                ),
                body: SafeArea(
            child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Palette.orangeDark, Palette.orangeAccent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ListView.builder(
                     itemCount: comics.length,
                     itemBuilder: (context, index) {
                       return Card(
                         margin: const EdgeInsets.all(8.0),
                         elevation: 4.0,
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             comics[index].coverImagePath?.isEmpty ?? true
                               ? const SizedBox(
                                   width: double.infinity,
                                   height: 200,
                                   child: Center(
                                       child: SizedBox(
                                           width: 200,
                                           height: 200,
                                           child: Column(
                                               mainAxisAlignment: MainAxisAlignment.center,
                                               children: [
                                                 Icon(Icons.photo,
                                                     size: 64,
                                                     color: Colors.black),
                                                 Text(
                                                     'У этого комикса пока что нет обложки',
                                                     textAlign: TextAlign.center,
                                                     style: TextStyle(color: Colors.black))
                                               ]))),
                                 )
                               : CachedNetworkImage(
                                   imageUrl: '${Environment.API_URL}/images/${comics[index].coverImagePath}',
                               imageBuilder: (context, imageProvider) => Container(
                                   width: double.infinity,
                                   height: 300,
                                   decoration: BoxDecoration(
                                       borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                       image: DecorationImage(
                                           image: imageProvider,
                                           fit: BoxFit.cover))),
                               placeholder: (context, url) => const Center(
                                   child: SizedBox(
                                       width: 200,
                                       height: 200,
                                       child: LoadingIndicator(
                                           indicatorType: Indicator.ballClipRotateMultiple,
                                           colors: [
                                             Palette.orangeAccent,
                                           ],
                                           strokeWidth: 3,
                                           backgroundColor: Colors.transparent,
                                           pathBackgroundColor: Colors.black))),
                               errorWidget: (context, url, error) => const Center(
                                   child: SizedBox(
                                       width: double.infinity,
                                       height: 200,
                                       child: Column(
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                             Icon(Icons.error, size: 64, color: Colors.red),
                                             Text(
                                                 'Не удалось загрузить изображение',
                                                 style: TextStyle(color: Colors.red))
                                           ]))),
                             ),
                             // Container(
                             //   height: 1,
                             //   width: double.infinity,
                             //   color: Palette.black,
                             // ),
                             Padding(
                               padding:
                                   const EdgeInsets.all(8.0),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                       comics[index].title ?? 'Без названия',
                                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                   Text(
                                     _formatDate(comics[index].updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String()),
                                     style: const TextStyle(fontSize: 14),
                                   ),
                                 ],
                               ))
                            ],
                         ),
                       );
                     }))),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
                floatingActionButton: PulsingAnimation(
                  duration: const Duration(seconds: 1),
                  repeat: true,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.white,
                    ),
                    onPressed: () {
                      //todo подумать, этот экран добавлять после сохранения комикса т.к. на бэке есть история
                      //todo тут можно перенаправлять на редактор
                      Navigator.of(context).push(MaterialPageRoute(builder: (c) => const CreateComicForm()));
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+',
                          style: TextStyle(
                            fontSize: 40,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Создай новый комикс!',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              )
            );
        },
      ),
      loading: () => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.orangeDark, Palette.orangeAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: LoadingIndicator(
            indicatorType: Indicator.ballClipRotateMultiple,
            colors: [
              Palette.white,
            ],
            strokeWidth: 3,
            backgroundColor: Colors.transparent,
            pathBackgroundColor: Colors.black,
          ),
        )),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.red.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 30,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Произошла ошибка :(",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
