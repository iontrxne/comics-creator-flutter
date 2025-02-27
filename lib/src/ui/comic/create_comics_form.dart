// lib/src/ui/comic/create_comics_form.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../../../config/palette.dart';
import '../../logic/comic/comic_provider.dart';
import '../../logic/image/image_provider.dart';

class CreateComicForm extends ConsumerStatefulWidget {
  final String? title;
  final bool? isEdit;
  final int? comicId;

  const CreateComicForm({this.title, this.isEdit, this.comicId, super.key});

  @override
  _CreateComicFormState createState() => _CreateComicFormState();
}

class _CreateComicFormState extends ConsumerState<CreateComicForm> {
  final titleController = TextEditingController();

  @override
  void initState() {
    if (widget.isEdit == true) titleController.text = widget.title ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit == true ? 'Редактировать комикс' : 'Создать новый комикс!'),
          centerTitle: true,
          backgroundColor: Palette.orangeDark,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Palette.orangeDark, Palette.orangeAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Название твоего комикса',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer(builder: (context, ref, child) {
                    final imageFile = ref.watch(imageProvider);
                    return Column(
                      children: [
                        Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                                if (pickedFile != null) {
                                  CroppedFile? croppedFile = await ImageCropper().cropImage(
                                    sourcePath: pickedFile.path,
                                    uiSettings: [
                                      AndroidUiSettings(
                                        toolbarTitle: 'Cropper',
                                        toolbarColor: Colors.deepOrange,
                                        toolbarWidgetColor: Colors.white,
                                        initAspectRatio: CropAspectRatioPreset.square,
                                        lockAspectRatio: false,
                                        aspectRatioPresets: [
                                          CropAspectRatioPreset.original,
                                          CropAspectRatioPreset.square,
                                          CropAspectRatioPreset.ratio4x3,
                                        ],
                                      ),
                                      IOSUiSettings(
                                        title: 'Cropper',
                                        aspectRatioPresets: [
                                          CropAspectRatioPreset.original,
                                          CropAspectRatioPreset.square,
                                          CropAspectRatioPreset.ratio4x3,
                                        ],
                                      ),
                                    ],
                                  );

                                  if (croppedFile != null) {
                                    ref.read(imageProvider.notifier).state = File(croppedFile.path);
                                  }
                                }
                              },
                              child: Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: imageFile == null
                                    ? const Center(
                                  child: Text(
                                    'Загрузи обложку',
                                    style: TextStyle(color: Colors.white, fontSize: 24),
                                  ),
                                )
                                    : Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(imageFile, fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            )),
                        if (imageFile != null)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                ref.read(imageProvider.notifier).state = null;
                              },
                              child: const Text(
                                'Очистить изображение',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (widget.isEdit == null || widget.isEdit == false)
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Введи название комикса!',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.black,
                          ),
                        );
                        return;
                      }

                      // Показываем индикатор загрузки
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: LoadingIndicator(
                          indicatorType: Indicator.ballClipRotateMultiple,
                          colors: [
                            Palette.white,
                          ],
                          strokeWidth: 3,
                          backgroundColor: Colors.transparent,
                          pathBackgroundColor: Colors.black,
                        ),),
                      );

                      final imageFile = ref.watch(imageProvider);
                      try {
                        final comicId = await ref.read(uploadComicProvider({
                          'title': titleController.text,
                        }).future);

                        if (comicId != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Комикс успешно создан!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }

                          // Загружаем обложку только если она была выбрана
                          if (imageFile != null) {
                            await ref.read(uploadComicCoverProvider({
                              "id": comicId,
                              "imageFile": imageFile
                            }).future);
                          }

                          ref.read(imageProvider.notifier).state = null;
                          ref.refresh(comicsListProvider);

                          // Закрываем диалог загрузки
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          // Возвращаем ID созданного комикса
                          if (context.mounted) {
                            Navigator.of(context).pop(comicId);
                          }
                        } else {
                          // Закрываем диалог загрузки
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Не удалось создать комикс',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        // Закрываем диалог загрузки
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ошибка: ${e.toString()}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Создать',
                      style: TextStyle(fontSize: 20, color: Palette.orangeAccent),
                    ),
                  ),
                if (widget.isEdit == true && widget.comicId != null)
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Введи название комикса!',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.black,
                          ),
                        );
                        return;
                      }

                      // Показываем индикатор загрузки
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: LoadingIndicator(
                          indicatorType: Indicator.ballClipRotateMultiple,
                          colors: [
                            Palette.white,
                          ],
                          strokeWidth: 3,
                          backgroundColor: Colors.transparent,
                          pathBackgroundColor: Colors.black,
                        ),),
                      );

                      final imageFile = ref.watch(imageProvider);
                      try {
                        // Обновляем заголовок комикса
                        final success = await ref.read(updateComicProvider({
                          'id': widget.comicId!,
                          'title': titleController.text,
                        }).future);

                        if (success) {
                          // Если была выбрана новая обложка, обновляем ее
                          if (imageFile != null) {
                            await ref.read(uploadComicCoverProvider({
                              "id": widget.comicId!,
                              "imageFile": imageFile
                            }).future);
                          }

                          ref.read(imageProvider.notifier).state = null;
                          ref.refresh(comicsListProvider);

                          // Закрываем диалог загрузки
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Комикс успешно обновлен!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }

                          // Возвращаемся назад
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } else {
                          // Закрываем диалог загрузки
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Не удалось обновить комикс',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        // Закрываем диалог загрузки
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ошибка: ${e.toString()}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Обновить',
                      style: TextStyle(fontSize: 20, color: Palette.orangeAccent),
                    ),
                  )
              ],
            ),
          ),
        ));
  }
}