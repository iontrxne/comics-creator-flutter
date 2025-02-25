import 'dart:io';

import 'package:comisc_creator/src/ui/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/palette.dart';
import '../../logic/comic/comic_provider.dart';
import '../../logic/image/image_provider.dart';

class CreateComicForm extends ConsumerWidget {
  const CreateComicForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создай новый комикс!'),
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
                  final imageFile = ref.watch(imageProvider);
                  try {
                    await ref.read(uploadComicProvider({
                      'title': titleController.text,
                    }).future).then((value) async {
                      if (value != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Комикс успешно создан!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }

                        if (imageFile != null) {
                          await ref.read(uploadComicCoverProvider({
                            "id": value,
                            "imageFile": imageFile
                          }).future);
                        }

                        ref.read(imageProvider.notifier).state = null;
                        ref.refresh(comicsListProvider);
                        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => const HomePage()), (route) => false);
                      } else {
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
                    }).catchError((err) {
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
                    });
                  } catch (e) {
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Создать',
                  style: TextStyle(fontSize: 20, color: Colors.brown),
                ),
              )
            ],
          ),
        ),
      ));
  }
}
