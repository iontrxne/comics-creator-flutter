import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/palette.dart';
import '../../data/models/comic_model.dart';
import '../../logic/comic/editor_provider.dart';
import 'canvas/comic_canvas.dart';
import 'canvas/tool_panel.dart';

class ComicEditorPage extends ConsumerStatefulWidget {
  final int comicId;
  final String comicTitle;

  const ComicEditorPage({
    Key? key,
    required this.comicId,
    required this.comicTitle,
  }) : super(key: key);

  @override
  ComicEditorPageState createState() => ComicEditorPageState();
}

class ComicEditorPageState extends ConsumerState<ComicEditorPage> {
  int currentPageIndex = 0;
  Key _canvasKey = UniqueKey(); // Ключ для пересоздания холста

  @override
  void initState() {
    super.initState();
    // Загрузка комикса и его страниц при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Инициализация редактора для комикса ${widget.comicId}");
      // Сначала сбрасываем состояние, затем загружаем новый комикс
      ref.read(comicEditorProvider.notifier).resetState();
      ref.read(comicEditorProvider.notifier).loadComic(widget.comicId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(comicEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.comicTitle} (ID: ${widget.comicId})"),
        backgroundColor: Palette.orangeDark,
        actions: [
          // Кнопка Undo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: editorState.canUndo
                ? () => ref.read(comicEditorProvider.notifier).undo()
                : null,
          ),
          // Кнопка Redo
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: editorState.canRedo
                ? () => ref.read(comicEditorProvider.notifier).redo()
                : null,
          ),
          // Кнопка сохранения
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => ref.read(comicEditorProvider.notifier).saveCurrentCell(),
          ),
          // Кнопка обновления холста
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _canvasKey = UniqueKey(); // Обновляем ключ для пересоздания холста
              });
            },
            tooltip: 'Обновить холст',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.orangeDark, Palette.orangeAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Индикатор загрузки
            if (editorState.isLoading)
              const LinearProgressIndicator(),

            // Сообщение об ошибке
            if (editorState.errorMessage != null)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        editorState.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(comicEditorProvider.notifier).state =
                            editorState.copyWith(errorMessage: null);
                      },
                    ),
                  ],
                ),
              ),

            // Информация о текущей странице и ячейке
            if (editorState.currentPageId != null)
              Container(
                color: Colors.black45,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Text(
                      'Комикс: ${widget.comicId}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Страница: ${editorState.currentPageId}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Ячейка: ${editorState.currentCell?.id ?? "Нет"}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

            // Панель инструментов
            ToolPanel(
              selectedTool: editorState.currentTool,
              currentColor: editorState.currentColor,
              currentThickness: editorState.currentThickness,
              currentFontSize: editorState.currentFontSize,
              onToolChanged: (tool) =>
                  ref.read(comicEditorProvider.notifier).setCurrentTool(tool),
              onColorChanged: (color) =>
                  ref.read(comicEditorProvider.notifier).setCurrentColor(color),
              onThicknessChanged: (thickness) =>
                  ref.read(comicEditorProvider.notifier).setCurrentThickness(thickness),
              onFontSizeChanged: (fontSize) =>
                  ref.read(comicEditorProvider.notifier).setCurrentFontSize(fontSize),
            ),

            // Основной холст для рисования
            Expanded(
              child: editorState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : editorState.pages.isEmpty
                  ? _buildEmptyState()
                  : editorState.currentCell == null
                  ? _buildNoCellState()
                  : ComicCanvas(
                key: _canvasKey,  // Используем уникальный ключ для пересоздания холста
                currentCell: editorState.currentCell!,
                tool: editorState.currentTool,
                color: editorState.currentColor,
                thickness: editorState.currentThickness,
                fontSize: editorState.currentFontSize,
                onContentChanged: (content) =>
                    ref.read(comicEditorProvider.notifier).updateCurrentCellContent(content),
              ),
            ),

            // Панель выбора страниц
            if (editorState.pages.isNotEmpty)
              _buildPageSelector(editorState),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Palette.white,
        child: const Icon(Icons.add, color: Palette.orangeDark),
        onPressed: () {
          _showAddOptions(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    // Убедимся, что состояние редактора очищается при закрытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(comicEditorProvider.notifier).resetState();
      }
    });
    super.dispose();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
              Icons.add_box_outlined,
              size: 80,
              color: Colors.white
          ),
          const SizedBox(height: 16),
          const Text(
            'Здесь пока ничего нет',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавь страницу, чтобы начать создавать комикс',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12
              ),
            ),
            onPressed: () {
              print("Нажата кнопка 'Добавить страницу' (пустой стейт)");
              ref.read(comicEditorProvider.notifier).addPage();
            },
            child: const Text(
              'Добавить страницу',
              style: TextStyle(
                color: Palette.orangeDark,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCellState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
              Icons.grid_4x4,
              size: 80,
              color: Colors.white
          ),
          const SizedBox(height: 16),
          const Text(
            'Выберите ячейку или создайте новую',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Нажмите на + и выберите тип содержимого',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12
              ),
            ),
            onPressed: () {
              print("Нажата кнопка 'Добавить ячейку'");
              ref.read(comicEditorProvider.notifier).addCell();
            },
            child: const Text(
              'Добавить ячейку',
              style: TextStyle(
                color: Palette.orangeDark,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSelector(EditorState state) {
    return Container(
      height: 60,
      color: Colors.black.withOpacity(0.2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.pages.length + 1, // +1 для кнопки добавления
        itemBuilder: (context, index) {
          if (index == state.pages.length) {
            // Кнопка добавления новой страницы
            return GestureDetector(
              onTap: () {
                print("Нажата кнопка добавления страницы в селекторе");
                // Сначала сохраняем текущую ячейку, затем добавляем новую страницу
                if (state.currentCell != null) {
                  ref.read(comicEditorProvider.notifier).saveCurrentCell().then((_) {
                    ref.read(comicEditorProvider.notifier).addPage();
                  });
                } else {
                  ref.read(comicEditorProvider.notifier).addPage();
                }
              },
              child: Container(
                width: 50,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            );
          }

          // Миниатюра страницы
          return GestureDetector(
            onTap: () {
              print("Выбрана страница ${state.pages[index].pageNumber}");
              // Сначала сохраняем текущую ячейку, затем меняем страницу
              setState(() {
                _canvasKey = UniqueKey(); // Обновляем ключ при смене страницы
              });
              // Автоматически сохраняем текущую ячейку при переключении страницы
              ref.read(comicEditorProvider.notifier).setCurrentPage(state.pages[index].id ?? 0);
            },
            child: Container(
              width: 50,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: state.currentPageId == state.pages[index].id
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: state.currentPageId == state.pages[index].id
                    ? Border.all(color: Palette.orangeDark, width: 2)
                    : null,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${state.pages[index].pageNumber}',  // Отображаем правильный номер страницы
                      style: TextStyle(
                        color: state.currentPageId == state.pages[index].id
                            ? Palette.orangeDark
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${state.pages[index].id}',  // Отображаем ID страницы
                      style: TextStyle(
                        color: state.currentPageId == state.pages[index].id
                            ? Palette.orangeDark
                            : Colors.black,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.orangeDark,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_photo_alternate, color: Colors.white),
              title: const Text('Добавить изображение', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                print("Выбрано добавление изображения");
                ref.read(comicEditorProvider.notifier).addImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.white),
              title: const Text('Добавить текст', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                print("Выбрано добавление текста");
                ref.read(comicEditorProvider.notifier).addText();
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_square, color: Colors.white),
              title: const Text('Добавить ячейку', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                print("Выбрано добавление ячейки");
                setState(() {
                  _canvasKey = UniqueKey(); // Обновляем ключ при добавлении ячейки
                });
                ref.read(comicEditorProvider.notifier).addCell();
              },
            ),
            const Divider(color: Colors.white30),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.white),
              title: const Text('Обновить холст', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _canvasKey = UniqueKey(); // Обновляем ключ для пересоздания холста
                });
              },
            ),
          ],
        );
      },
    );
  }
}