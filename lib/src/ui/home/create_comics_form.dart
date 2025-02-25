import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../config/palette.dart';

class CreateComicForm extends ConsumerWidget {
  const CreateComicForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final imageProvider = StateProvider<File?>((ref) => null);

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
                final imageFile = ref.watch(imageProvider); //todo добавить кроппер
                return GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                        if (pickedFile != null) {
                          ref.read(imageProvider.notifier).state = File(pickedFile.path);
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
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(imageFile, fit: BoxFit.cover)
                            ),
                    ),
                );
              }),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
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

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Комикс сохранен!'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
