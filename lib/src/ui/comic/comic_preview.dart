
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/palette.dart';
import '../../logic/comic/editor_provider.dart' as editor;
import '../comic/canvas/canvas_controller.dart';
import '../comic/canvas/comic_canvas.dart';

/// Виджет для предпросмотра готового комикса
class ComicPreviewPage extends ConsumerStatefulWidget {
  final int comicId;
  final String comicTitle;

  const ComicPreviewPage({
    Key? key,
    required this.comicId,
    required this.comicTitle,
  }) : super(key: key);

  @override
  _ComicPreviewPageState createState() => _ComicPreviewPageState();
}

class _ComicPreviewPageState extends ConsumerState<ComicPreviewPage> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editor.comicEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Предпросмотр: ${widget.comicTitle}'),
        backgroundColor: Palette.orangeDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться',
            onPressed: () {
              // Реализация функции "Поделиться"
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Функция "Поделиться" будет доступна в следующей версии'),
                ),
              );
            },
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
        child: editorState.pages.isEmpty
            ? const Center(
          child: Text(
            'В комиксе нет страниц',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        )
            : Column(
          children: [
            // Индикатор страницы
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Страница ${_currentPage + 1} из ${editorState.pages.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),

            // Основная область для просмотра страниц
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: editorState.pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPagePreview(editorState.pages[index]);
                },
              ),
            ),
          ],
        ),
      ),
      // Кнопки навигации
      bottomNavigationBar: BottomAppBar(
        color: Palette.orangeAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: Colors.white,
              onPressed: _currentPage > 0
                  ? () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              color: Colors.white,
              onPressed: _currentPage < editorState.pages.length - 1
                  ? () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // Построение предпросмотра страницы
  Widget _buildPagePreview(editor.Page page) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Фон страницы
            Container(color: Colors.white),

            // Ячейки
            ...page.cells.map((cell) => Positioned(
              left: cell.positionX,
              top: cell.positionY,
              width: cell.width,
              height: cell.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                // Отображаем фактическое содержимое ячейки вместо номера
                child: _buildCellContent(cell),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Новый метод для отображения содержимого ячейки
  Widget _buildCellContent(editor.Cell cell) {
    try {
      // Если JSON пустой или некорректный, показываем заглушку
      if (cell.contentJson.isEmpty || cell.contentJson == '{"elements":[]}') {
        return Center(
          child: Text(
            'Пустая ячейка ${cell.id}',
            style: const TextStyle(color: Colors.black54),
          ),
        );
      }

      // Парсим JSON и отображаем содержимое
      final content = CellContent.fromJsonString(cell.contentJson);
      return CustomPaint(
        painter: CanvasPainter(
          cell: cell,
          content: content,
          currentPoints: [],
          currentTool: DrawingTool.brush,
          eraserSize: 3.0,
        ),
        size: Size(cell.width, cell.height),
      );
    } catch (e) {
      // В случае ошибки показываем сообщение
      return const Center(
        child: Text(
          'Ошибка отображения',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }
}