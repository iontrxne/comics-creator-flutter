import 'package:flutter/material.dart';
import 'package:flutter_animation_plus/animations/pulsing_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/palette.dart';
import '../../data/models/comic_model.dart';
import '../../logic/comic/comic_provider.dart';
import 'create_comics_form.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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
                body: Container(
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
                             CachedNetworkImage(
                               imageUrl: comics[index].coverImagePath ?? '',
                               imageBuilder: (context, imageProvider) => Container(
                                   width: double.infinity,
                                   height: 200,
                                   decoration: BoxDecoration(
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
                                       width: 200,
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
                             const Padding(
                               padding: EdgeInsets.all(8.0),
                               child: Text('Комикс',
                                   style: TextStyle(fontWeight: FontWeight.bold)),
                             ),
                           ],
                         ),
                       );
                     })),
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
