// lib/src/ui/home/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animation_plus/animations/pulsing_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../../../config/palette.dart';
import '../../data/models/comic_model.dart';
import '../../logic/comic/comic_provider.dart';
import '../comic/create_comics_form.dart';
import 'package:intl/intl.dart';
import '../comic/comic_editor_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    }
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
                              child: comics.isEmpty
                                  ? _buildEmptyState(context, ref)
                                  : ListView.builder(
                                  itemCount: comics.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => ComicEditorPage(
                                                comicId: comics[index].id!,
                                                comicTitle: comics[index].title ?? 'Без названия',
                                              ),
                                            ),
                                          ).then((_) {
                                            // Обновляем список комиксов после возврата
                                            ref.refresh(comicsListProvider);
                                          });
                                        },
                                        child: Card(
                                          margin: const EdgeInsets.all(8.0),
                                          elevation: 4.0,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildComicCover(comics[index]),
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
                                                        _formatDate(comics[index].updatedAt),
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                    ],
                                                  ))
                                            ],
                                          ),
                                        ));
                                  }))),
                      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
                      floatingActionButton: PulsingAnimation(
                        duration: const Duration(seconds: 1),
                        repeat: true,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.white,
                          ),
                          onPressed: () async {
                            final comicId = await Navigator.of(context).push<int?>(
                                MaterialPageRoute(builder: (c) => const CreateComicForm())
                            );

                            if (comicId != null && context.mounted) {
                              // Если успешно создан комикс, сразу переходим в редактор
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ComicEditorPage(
                                    comicId: comicId,
                                    comicTitle: 'Новый комикс',
                                  ),
                                ),
                              );
                              // Обновляем список комиксов после возврата из редактора
                              ref.refresh(comicsListProvider);
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 40, color: Palette.orangeAccent
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Создай новый комикс!',
                                style: TextStyle(
                                  fontSize: 20, color: Palette.orangeAccent
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Произошла ошибка: ${error.toString()}",
                          style: const TextStyle(
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

  // Метод для отображения обложки комикса
  Widget _buildComicCover(Comic comic) {
    // Проверяем наличие обложки
    if (comic.coverImagePath == null || comic.coverImagePath!.isEmpty) {
      return _buildNoCoverPlaceholder("У этого комикса пока что нет обложки");
    }

    // Проверяем, существует ли файл
    final coverFile = File(comic.coverImagePath!);
    if (!coverFile.existsSync()) {
      return _buildNoCoverPlaceholder("Файл обложки не найден");
    }

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12)
          ),
          image: DecorationImage(
              image: FileImage(coverFile),
              fit: BoxFit.cover
          )
      ),
    );
  }

  // Вспомогательный метод для создания заглушки
  Widget _buildNoCoverPlaceholder(String message) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Center(
          child: SizedBox(
              width: 200,
              height: 200,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo, size: 64, color: Colors.black),
                    Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black)
                    )
                  ]
              )
          )
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'У тебя пока нет комиксов',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Создай свой первый комикс прямо сейчас!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          // const SizedBox(height: 24),
          // ElevatedButton(
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Palette.white,
          //     padding: const EdgeInsets.symmetric(
          //       horizontal: 24,
          //       vertical: 12,
          //     ),
          //   ),
          //   onPressed: () async {
          //     final comicId = await Navigator.of(context).push<int?>(
          //         MaterialPageRoute(builder: (c) => const CreateComicForm())
          //     );
          //
          //     if (comicId != null && context.mounted) {
          //       // Если успешно создан комикс, сразу переходим в редактор
          //       await Navigator.of(context).push(
          //         MaterialPageRoute(
          //           builder: (context) => ComicEditorPage(
          //             comicId: comicId,
          //             comicTitle: 'Новый комикс',
          //           ),
          //         ),
          //       );
          //       // Обновляем список комиксов после возврата из редактора
          //       ref.refresh(comicsListProvider);
          //     }
          //   },
          //   child: const Text(
          //     'Создать комикс',
          //     style: TextStyle(
          //       color: Palette.orangeDark,
          //       fontSize: 18,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}