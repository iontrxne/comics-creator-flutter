// lib/src/ui/comic/comic_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../../../config/palette.dart';
import '../../logic/comic/editor_provider.dart';
import '../../logic/comic/comic_provider.dart';
import 'canvas/comic_canvas.dart';
import 'canvas/tool_panel.dart';
import 'comic_preview.dart';
import 'create_comics_form.dart';
import 'comic_page_view.dart';

// Перечисление режимов редактора
enum EditorMode {
  pageView,      // Просмотр страницы с ячейками
  cellEdit       // Редактирование ячейки
}

class ComicEditorPage extends ConsumerStatefulWidget {
  final int comicId;
  final String comicTitle;

  const ComicEditorPage({
    super.key,
    required this.comicId,
    required this.comicTitle,
  });

  @override
  ComicEditorPageState createState() => ComicEditorPageState();
}

class ComicEditorPageState extends ConsumerState<ComicEditorPage> {
  Key _canvasKey = UniqueKey(); // Ключ для пересоздания холста
  EditorMode _currentMode = EditorMode.pageView; // Текущий режим редактора

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${widget.comicTitle} (ID: ${widget.comicId})"),
            // Отображаем информацию о ячейке в отдельной строке
            if (_currentMode == EditorMode.cellEdit && editorState.currentCell != null)
              Text(
                "Редактирование ячейки ${editorState.currentCell!.id}",
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: Palette.orangeDark,
        actions: [
          // Кнопки Undo/Redo доступны только в режиме редактирования ячейки
          if (_currentMode == EditorMode.cellEdit)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: editorState.canUndo
                  ? () => ref.read(comicEditorProvider.notifier).undo()
                  : null,
            ),
          if (_currentMode == EditorMode.cellEdit)
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: editorState.canRedo
                  ? () => ref.read(comicEditorProvider.notifier).redo()
                  : null,
            ),
          // Кнопка возврата к просмотру страницы из режима редактирования ячейки
          if (_currentMode == EditorMode.cellEdit)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Вернуться к странице',
              onPressed: () {
                // Сохраняем текущую ячейку перед возвратом
                if (editorState.currentCell != null) {
                  ref.read(comicEditorProvider.notifier).saveCurrentCell();
                }
                setState(() {
                  _currentMode = EditorMode.pageView;
                });
              },
            ),

          PopupMenuButton<int>(
            tooltip: "Меню",
            color: Palette.white,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 1: // Сохранить
                  if (editorState.currentCell != null) {
                    ref.read(comicEditorProvider.notifier).saveCurrentCell();
                  }
                  break;
                case 2: // Обновить холст
                  setState(() {
                    _canvasKey = UniqueKey(); // Обновляем ключ для пересоздания холста
                  });
                  break;
                case 3: // Удалить комикс
                  _showDeleteComicDialog();
                  break;
                case 4: // Редактировать название комикса
                  Navigator.of(context).push<int?>(
                      MaterialPageRoute(builder: (c) => CreateComicForm(title: widget.comicTitle, isEdit: true, comicId: widget.comicId)));
                  break;
                case 5: // Очистить ячейку
                  if (_currentMode == EditorMode.cellEdit && editorState.currentCell != null) {
                    ref.read(comicEditorProvider.notifier).clearCurrentCell();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Сначала выберите ячейку для очистки'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  break;
                case 6: // Экспорт комикса
                  _exportComic();
                  break;
                case 7: // Предпросмотр комикса
                  _showPreview();
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.save, color: Palette.black,),
                    SizedBox(width: 8),
                    Text('Сохранить'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Palette.black,),
                    SizedBox(width: 8),
                    Text('Обновить холст'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 5,
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Palette.black,),
                    SizedBox(width: 8),
                    Text('Очистить ячейку'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 7,
                child: Row(
                  children: [
                    Icon(Icons.preview, color: Palette.black,),
                    SizedBox(width: 8),
                    Text('Предпросмотр комикса'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 6,
                child: Row(
                  children: [
                    Icon(Icons.ios_share, color: Palette.black,),
                    SizedBox(width: 8),
                    Text('Экспорт комикса'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 4,
                child: Row(
                  children: [
                    Icon(Icons.mode_edit_outlined, color: Palette.black,),
                    SizedBox(width: 8),
                    Text('Редактировать описание'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red,),
                    SizedBox(width: 8),
                    Text('Удалить комикс', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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

            // Основной контент в зависимости от режима
            Expanded(
              child: editorState.isLoading
                  ? const Center(
                  child: LoadingIndicator(
                    indicatorType: Indicator.ballClipRotateMultiple,
                    colors: [
                      Palette.white,
                    ],
                    strokeWidth: 3,
                    backgroundColor: Colors.transparent,
                    pathBackgroundColor: Colors.black,
                  ))
                  : editorState.pages.isEmpty
                  ? _buildEmptyState()
                  : _buildEditorContent(editorState),
            ),

            // Панель выбора страниц
            if (editorState.pages.isNotEmpty)
              _buildPageSelector(editorState),
          ],
        ),
      ),
      // floatingActionButton: _buildFloatingActionButton(editorState),
    );
  }

  void _showPreview() {
    // Сначала сохраняем текущую ячейку, если она выбрана
    final editorState = ref.read(comicEditorProvider);
    if (editorState.currentCell != null) {
      ref.read(comicEditorProvider.notifier).saveCurrentCell();
    }

    // Переходим на экран предпросмотра
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComicPreviewPage(
          comicId: widget.comicId,
          comicTitle: widget.comicTitle,
        ),
      ),
    );
  }

  // Построение содержимого редактора в зависимости от режима
  Widget _buildEditorContent(EditorState editorState) {
    if (_currentMode == EditorMode.pageView) {
      // Режим просмотра страницы
      return ComicPageView(
        pageId: editorState.currentPageId!,
        onCellSelected: (cellId) {
          // При выборе ячейки переходим в режим редактирования
          ref.read(comicEditorProvider.notifier).setCurrentCell(cellId);
          setState(() {
            _currentMode = EditorMode.cellEdit;
          });
        },
      );
    } else {
      // Режим редактирования ячейки
      if (editorState.currentCell == null) {
        return const Center(
          child: Text(
            'Выберите ячейку для редактирования',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        );
      }

      return Column(
        children: [
          // Панель инструментов для редактирования ячейки
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

          // Холст для редактирования ячейки
          Expanded(
            child: ComicCanvas(
              key: _canvasKey,
              currentCell: editorState.currentCell!,
              tool: editorState.currentTool,
              color: editorState.currentColor,
              thickness: editorState.currentThickness,
              fontSize: editorState.currentFontSize,
              onContentChanged: (content, [previousContent]) =>
                  ref.read(comicEditorProvider.notifier).updateCurrentCellContent(content, previousContent),
            ),
          ),
        ],
      );
    }
  }

  // Плавающая кнопка действий
  Widget _buildFloatingActionButton(EditorState editorState) {
    // В режиме просмотра страницы - кнопка добавления страницы/ячейки
    if (_currentMode == EditorMode.pageView) {
      return FloatingActionButton(
        backgroundColor: Palette.white,
        child: const Icon(Icons.add, color: Palette.orangeDark),
        onPressed: () {
          _showAddOptions(context);
        },
      );
    }
    // В режиме редактирования ячейки - кнопка добавления элементов
    else {
      return FloatingActionButton(
        backgroundColor: Palette.white,
        child: const Icon(Icons.add, color: Palette.orangeDark),
        onPressed: () {
          _showAddContentOptions(context);
        },
      );
    }
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

  // Диалог удаления комикса
  void _showDeleteComicDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтвердите удаление'),
          content: const Text('Вы точно хотите удалить этот комикс?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Закрыть диалог без удаления
                Navigator.of(context).pop();
              },
              child: const Text('Отмена', style: TextStyle(color: Colors.black),),
            ),
            TextButton(
              onPressed: () async {
                // Закрываем диалог
                Navigator.of(context).pop();

                // Показываем индикатор загрузки
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: LoadingIndicator(
                      indicatorType: Indicator.ballClipRotateMultiple,
                      colors: [Palette.white],
                      strokeWidth: 3,
                      backgroundColor: Colors.transparent,
                      pathBackgroundColor: Colors.black,
                    ),
                  ),
                );

                try {
                  // Удаляем комикс
                  final success = await ref.read(deleteComicProvider(widget.comicId).future);

                  // Закрываем индикатор загрузки
                  if (context.mounted) Navigator.of(context).pop();

                  if (success) {
                    // Показываем сообщение об успехе
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Комикс успешно удален'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    // Возвращаемся на главный экран
                    if (context.mounted) {
                      // Обновляем список комиксов перед возвратом
                      ref.refresh(comicsListProvider);
                      Navigator.of(context).pop();
                    }
                  } else {
                    // Показываем сообщение об ошибке
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Не удалось удалить комикс'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Закрываем индикатор загрузки в случае ошибки
                  if (context.mounted) Navigator.of(context).pop();

                  // Показываем сообщение об ошибке
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red),),
            ),
          ],
        );
      },
    );
  }

  // Экспорт комикса
  void _exportComic() async {
    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: LoadingIndicator(
          indicatorType: Indicator.ballClipRotateMultiple,
          colors: [Palette.white],
          strokeWidth: 3,
          backgroundColor: Colors.transparent,
          pathBackgroundColor: Colors.black,
        ),
      ),
    );

    try {
      // Экспортируем комикс
      final imagePaths = await ref.read(comicEditorProvider.notifier).exportComicAsImages();

      // Закрываем индикатор загрузки
      if (context.mounted) Navigator.of(context).pop();

      if (imagePaths.isNotEmpty) {
        // Показываем сообщение об успехе
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Комикс успешно экспортирован (${imagePaths.length} страниц)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Показываем сообщение об ошибке
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось экспортировать комикс'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Закрываем индикатор загрузки в случае ошибки
      if (context.mounted) Navigator.of(context).pop();

      // Показываем сообщение об ошибке
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при экспорте: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Диалог удаления страницы
  void _showDeletePageDialog(int pageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтвердите удаление'),
          content: const Text('Вы точно хотите удалить эту страницу?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Закрыть диалог без удаления
                Navigator.of(context).pop();
              },
              child: const Text('Отмена', style: TextStyle(color: Colors.black),),
            ),
            TextButton(
              onPressed: () {
                // Закрываем диалог
                Navigator.of(context).pop();

                // Удаляем страницу
                ref.read(comicEditorProvider.notifier).deletePage(pageId);

                // В режиме редактирования ячейки возвращаемся к просмотру страницы
                if (_currentMode == EditorMode.cellEdit) {
                  setState(() {
                    _currentMode = EditorMode.pageView;
                  });
                }
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red),),
            ),
          ],
        );
      },
    );
  }

  // Когда нет страниц комикса
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

  // Панель выбора страниц внизу экрана
  Widget _buildPageSelector(EditorState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      height: 70,
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
                    // Переключаемся в режим просмотра страницы при создании новой страницы
                    setState(() {
                      _currentMode = EditorMode.pageView;
                    });
                  });
                } else {
                  ref.read(comicEditorProvider.notifier).addPage();
                  // Переключаемся в режим просмотра страницы при создании новой страницы
                  setState(() {
                    _currentMode = EditorMode.pageView;
                  });
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

              // Сначала сохраняем текущую ячейку, если она выбрана
              if (state.currentCell != null) {
                ref.read(comicEditorProvider.notifier).saveCurrentCell();
              }

              // Устанавливаем новую текущую страницу
              ref.read(comicEditorProvider.notifier).setCurrentPage(state.pages[index].id ?? 0);

              // Переключаемся в режим просмотра страницы
              setState(() {
                _currentMode = EditorMode.pageView;
                _canvasKey = UniqueKey(); // Обновляем ключ при смене страницы
              });
            },
            onLongPress: () {
              // Показываем опции страницы при длительном нажатии
              _showPageOptions(state.pages[index].id!);
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
                      '${state.pages[index].pageNumber}', // Отображаем номер страницы
                      style: TextStyle(
                        color: state.currentPageId == state.pages[index].id
                            ? Palette.orangeDark
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ячеек: ${state.pages[index].cells.length}', // Отображаем количество ячеек
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

  // Показать опции страницы
  void _showPageOptions(int pageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.orangeDark,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white),
              title: const Text('Удалить страницу', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showDeletePageDialog(pageId);
              },
            ),
          ],
        );
      },
    );
  }

  // Показать опции добавления при нажатии на плавающую кнопку в режиме просмотра страницы
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
              title: const Text('Добавить новую страницу', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(comicEditorProvider.notifier).addPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on, color: Colors.white),
              title: const Text('Добавить ячейку по сетке', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                final editorState = ref.read(comicEditorProvider);

                if (editorState.currentPageId != null) {
                  // Показываем диалог выбора позиции в сетке
                  showDialog(
                    context: context,
                    builder: (context) {
                      int selectedRow = 0;
                      int selectedCol = 0;
                      int rowCount = 4;
                      int colCount = 4;

                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text('Добавить ячейку в сетку'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Text('Размер сетки:'),
                                    const SizedBox(width: 16),
                                    DropdownButton<int>(
                                      value: rowCount,
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            rowCount = value;
                                            if (selectedRow >= rowCount) {
                                              selectedRow = rowCount - 1;
                                            }
                                          });
                                        }
                                      },
                                      items: [2, 3, 4, 6, 8].map((count) => DropdownMenuItem<int>(
                                        value: count,
                                        child: Text('$count строк'),
                                      )).toList(),
                                    ),
                                    const SizedBox(width: 8),
                                    DropdownButton<int>(
                                      value: colCount,
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            colCount = value;
                                            if (selectedCol >= colCount) {
                                              selectedCol = colCount - 1;
                                            }
                                          });
                                        }
                                      },
                                      items: [2, 3, 4, 6, 8].map((count) => DropdownMenuItem<int>(
                                        value: count,
                                        child: Text('$count столбцов'),
                                      )).toList(),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: colCount,
                                    ),
                                    itemCount: rowCount * colCount,
                                    itemBuilder: (context, index) {
                                      final row = index ~/ colCount;
                                      final col = index % colCount;
                                      final isSelected = row == selectedRow && col == selectedCol;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedRow = row;
                                            selectedCol = col;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Palette.orangeAccent : Colors.grey.shade300,
                                            border: Border.all(color: Colors.black),
                                          ),
                                          child: Center(
                                            child: Text(
                                              isSelected ? 'Выбрано' : '',
                                              style: const TextStyle(fontSize: 10),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Отмена'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.orangeAccent,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(comicEditorProvider.notifier).addCellToGrid(
                                      selectedRow,
                                      selectedCol,
                                      rowCount,
                                      colCount
                                  );
                                },
                                child: const Text('Добавить'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Сначала создайте страницу'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_square, color: Colors.white),
              title: const Text('Добавить ячейку', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                final editorState = ref.read(comicEditorProvider);

                if (editorState.currentPageId != null) {
                  ref.read(comicEditorProvider.notifier).addCell();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Сначала создайте страницу'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  // Показать опции добавления контента при нажатии на плавающую кнопку в режиме редактирования ячейки
  void _showAddContentOptions(BuildContext context) {
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
                ref.read(comicEditorProvider.notifier).addImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.white),
              title: const Text('Добавить текст', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(comicEditorProvider.notifier).addText();
              },
            ),
            const Divider(color: Colors.white30),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.white),
              title: const Text('Очистить ячейку', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(comicEditorProvider.notifier).clearCurrentCell();
              },
            ),
          ],
        );
      },
    );
  }
}