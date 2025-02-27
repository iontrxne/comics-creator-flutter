// lib/src/ui/comic/comic_page_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/palette.dart';
import '../../logic/comic/editor_provider.dart' as editor; // Добавляем префикс
import 'canvas/canvas_controller.dart';
import 'canvas/comic_canvas.dart';
import 'canvas/tool_panel.dart';

/// Виджет для отображения всей страницы комикса с ячейками
class ComicPageView extends ConsumerStatefulWidget {
  final int pageId;
  final Function(int cellId) onCellSelected;

  const ComicPageView({
    Key? key,
    required this.pageId,
    required this.onCellSelected,
  }) : super(key: key);

  @override
  _ComicPageViewState createState() => _ComicPageViewState();
}

class _ComicPageViewState extends ConsumerState<ComicPageView> {
  // Для масштабирования страницы
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _startPanPosition;
  Offset? _lastFocalPoint;

  // Для перемещения ячеек
  int? _draggingCellId;
  Offset? _cellStartPosition;
  Offset? _dragStartPosition;

  // Для изменения размера ячеек
  int? _resizingCellId;
  double? _initialWidth;
  double? _initialHeight;
  Offset? _resizeStartPosition;

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editor.comicEditorProvider);
    final currentPage = editorState.pages.firstWhere(
          (page) => page.id == widget.pageId,
      orElse: () => editor.Page(pageNumber: 0, cells: []), // Используем префикс
    );

    if (currentPage.id == null) {
      return const Center(
        child: Text('Страница не найдена', style: TextStyle(color: Colors.white)),
      );
    }

    // Виджет для всей страницы с масштабированием
    return Column(
      children: [
        // Панель инструментов для страницы
        _buildPageToolbar(currentPage),

        // Основной холст страницы
        Expanded(
          child: GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Масштабируемая страница
                  Transform(
                    transform: Matrix4.identity()
                      ..translate(_offset.dx, _offset.dy)
                      ..scale(_scale),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 800, // Ширина страницы
                      height: 1200, // Высота страницы
                      child: Container(
                        color: Colors.white,
                        child: Stack(
                          children: [
                            // Фон страницы
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),

                            // Отображение сетки для grid layout
                            if (currentPage.layoutType == editor.CellLayoutType.grid)
                              _buildGridLayout(),

                            // Ячейки комикса
                            ...currentPage.cells.map((cell) => _buildCell(cell, currentPage.layoutType)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Панель инструментов страницы
  Widget _buildPageToolbar(editor.Page page) {
    return Container(
      height: 50,
      color: Colors.black.withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 8), // Уменьшил отступы
      child: Row(
        children: [
          // Информация о странице
          Expanded(
            flex: 1,
            child: Text(
              'Страница ${page.pageNumber}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis, // Добавил эллипсис при переполнении
            ),
          ),
          const SizedBox(width: 8), // Уменьшил отступ

          // Переключатель типа расположения
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Тип:', style: TextStyle(color: Colors.white)), // Сократил текст
                const SizedBox(width: 4), // Уменьшил отступ
                DropdownButton<editor.CellLayoutType>(
                  value: page.layoutType,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  underline: Container(
                    height: 2,
                    color: Palette.orangeAccent,
                  ),
                  onChanged: (editor.CellLayoutType? newValue) {
                    if (newValue != null) {
                      ref.read(editor.comicEditorProvider.notifier).setPageLayoutType(newValue);
                    }
                  },
                  items: [
                    DropdownMenuItem<editor.CellLayoutType>(
                      value: editor.CellLayoutType.free,
                      child: Text(
                        'Свободное',
                        style: TextStyle(color: page.layoutType == editor.CellLayoutType.free
                            ? Palette.orangeAccent
                            : Colors.white),
                      ),
                    ),
                    DropdownMenuItem<editor.CellLayoutType>(
                      value: editor.CellLayoutType.grid,
                      child: Text(
                        'По сетке',
                        style: TextStyle(color: page.layoutType == editor.CellLayoutType.grid
                            ? Palette.orangeAccent
                            : Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Кнопки для добавления ячеек
          Expanded(
            flex: 2,
            child: page.layoutType == editor.CellLayoutType.grid
                ? ElevatedButton.icon(
              icon: const Icon(Icons.grid_on, size: 16), // Уменьшил размер иконки
              label: const Text('В сетку', style: TextStyle(fontSize: 12)), // Сократил текст и уменьшил шрифт
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.orangeAccent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Уменьшил padding
              ),
              onPressed: () => _showGridCellDialog(),
            )
                : ElevatedButton.icon(
              icon: const Icon(Icons.add_box, size: 16), // Уменьшил размер иконки
              label: const Text('Ячейка', style: TextStyle(fontSize: 12)), // Сократил текст и уменьшил шрифт
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.orangeAccent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Уменьшил padding
              ),
              onPressed: () {
                ref.read(editor.comicEditorProvider.notifier).addCell();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Диалог для добавления ячейки по сетке
  void _showGridCellDialog() {
    int selectedRow = 0;
    int selectedCol = 0;
    int rowCount = 4; // Количество строк в сетке по умолчанию
    int colCount = 4; // Количество столбцов в сетке по умолчанию

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить ячейку в сетку'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Выбор размера сетки
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

                // Визуализация сетки для выбора позиции
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
            );
          },
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
              ref.read(editor.comicEditorProvider.notifier).addCellToGrid(
                  selectedRow,
                  selectedCol,
                  rowCount,
                  colCount
              );
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  // Виджет для отображения сетки
  Widget _buildGridLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const int rowCount = 6; // Фиксированное количество строк
        const int colCount = 4; // Фиксированное количество столбцов

        final cellWidth = constraints.maxWidth / colCount;
        final cellHeight = constraints.maxHeight / rowCount;

        // Создаем линии сетки
        List<Widget> gridLines = [];

        // Вертикальные линии
        for (int i = 1; i < colCount; i++) {
          gridLines.add(
            Positioned(
              left: cellWidth * i,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          );
        }

        // Горизонтальные линии
        for (int i = 1; i < rowCount; i++) {
          gridLines.add(
            Positioned(
              left: 0,
              right: 0,
              top: cellHeight * i,
              child: Container(
                height: 1,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          );
        }

        // Добавляем номера ячеек для удобства
        for (int row = 0; row < rowCount; row++) {
          for (int col = 0; col < colCount; col++) {
            gridLines.add(
              Positioned(
                left: cellWidth * col + 5,
                top: cellHeight * row + 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${row+1}x${col+1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        // Добавляем интерактивные области для быстрого добавления ячеек
        for (int row = 0; row < rowCount; row++) {
          for (int col = 0; col < colCount; col++) {
            final int currentRow = row;
            final int currentCol = col;

            gridLines.add(
              Positioned(
                left: cellWidth * col,
                top: cellHeight * row,
                width: cellWidth,
                height: cellHeight,
                child: GestureDetector(
                  onDoubleTap: () {
                    // Двойной тап для добавления ячейки в этой позиции
                    ref.read(editor.comicEditorProvider.notifier).addCellToGrid(
                        currentRow,
                        currentCol,
                        rowCount,
                        colCount
                    );
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            );
          }
        }

        // Создаем подсказку как использовать сетку
        gridLines.add(
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Двойной тап для добавления ячейки',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );

        return Stack(children: gridLines);
      },
    );
  }

  // Виджет для отображения ячейки
  Widget _buildCell(editor.Cell cell, editor.CellLayoutType layoutType) {
    final editorState = ref.watch(editor.comicEditorProvider);
    final isSelected = editorState.currentCell?.id == cell.id;

    // Обработка содержимого ячейки
    Widget cellContent = Container(color: Colors.grey.shade100);
    try {
      if (cell.contentJson.isNotEmpty && cell.contentJson != '{"elements":[]}') {
        // Отображаем содержимое ячейки через CellContent и CanvasPainter
        final content = CellContent.fromJsonString(cell.contentJson);
        cellContent = CustomPaint(
          painter: CanvasPainter(
            cell: cell,
            content: content,
            currentPoints: [],
            currentTool: DrawingTool.brush,
            eraserSize: 3.0,
          ),
          size: Size(cell.width, cell.height),
        );
      }
    } catch (e) {
      print("Ошибка при отрисовке содержимого ячейки: $e");
      cellContent = Container(
        color: Colors.white,
        child: Center(
          child: Text(
            'Ошибка отображения ячейки ${cell.id}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // Выбираем тип виджета в зависимости от типа расположения
    return Positioned(
      left: cell.positionX,
      top: cell.positionY,
      width: cell.width,
      height: cell.height,
      child: GestureDetector(
        onTap: () {
          // Выбор ячейки для редактирования
          widget.onCellSelected(cell.id!);
        },
        // Добавлен обработчик долгого нажатия
        onLongPress: () {
          _showCellCoordinatesDialog(cell);
        },
        onPanStart: layoutType == editor.CellLayoutType.free ? (details) {
          if (isSelected) {
            setState(() {
              _draggingCellId = cell.id;
              _cellStartPosition = Offset(cell.positionX, cell.positionY);
              _dragStartPosition = details.localPosition;
            });
          }
        } : null,
        onPanUpdate: layoutType == editor.CellLayoutType.free ? (details) {
          if (_draggingCellId == cell.id) {
            final delta = details.localPosition - _dragStartPosition!;
            final newPosition = _cellStartPosition! + delta;

            // Применяем новую позицию на экране для отзывчивости
            setState(() {});
          }
        } : null,
        onPanEnd: layoutType == editor.CellLayoutType.free ? (details) {
          if (_draggingCellId == cell.id) {
            final delta = Offset(
                _cellStartPosition!.dx - cell.positionX,
                _cellStartPosition!.dy - cell.positionY
            );

            // Применяем изменения через провайдер
            ref.read(editor.comicEditorProvider.notifier).moveCell(
                cell.id!,
                cell.positionX + delta.dx,
                cell.positionY + delta.dy
            );

            setState(() {
              _draggingCellId = null;
              _cellStartPosition = null;
              _dragStartPosition = null;
            });
          }
        } : null,
        child: Stack(
          children: [
            // Содержимое ячейки
            Positioned.fill(child: cellContent),

            // Рамка для всех ячеек (добавлено)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
              ),
            ),

            // Усиленная рамка для выделенной ячейки
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Palette.orangeAccent,
                      width: 2,
                    ),
                  ),
                ),
              ),

            // Маркеры изменения размера для свободного режима
            if (isSelected && layoutType == editor.CellLayoutType.free)
              ..._buildResizeHandles(cell),
          ],
        ),
      ),
    );
  }

  void _showCellCoordinatesDialog(editor.Cell cell) {
    // Контроллеры для полей ввода
    final TextEditingController posXController = TextEditingController(text: cell.positionX.toString());
    final TextEditingController posYController = TextEditingController(text: cell.positionY.toString());
    final TextEditingController widthController = TextEditingController(text: cell.width.toString());
    final TextEditingController heightController = TextEditingController(text: cell.height.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактировать ячейку ${cell.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: posXController,
                  decoration: const InputDecoration(labelText: 'Позиция X'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: posYController,
                  decoration: const InputDecoration(labelText: 'Позиция Y'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: widthController,
                  decoration: const InputDecoration(labelText: 'Ширина'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(labelText: 'Высота'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                // Парсинг введенных значений
                try {
                  final double newPosX = double.parse(posXController.text);
                  final double newPosY = double.parse(posYController.text);
                  final double newWidth = double.parse(widthController.text);
                  final double newHeight = double.parse(heightController.text);

                  // Применить изменения с проверкой минимальных размеров
                  if (newWidth >= 100 && newHeight >= 100) {
                    // Обновляем позицию ячейки
                    ref.read(editor.comicEditorProvider.notifier).moveCell(
                        cell.id!,
                        newPosX,
                        newPosY
                    );

                    // Обновляем размер ячейки
                    ref.read(editor.comicEditorProvider.notifier).resizeCell(
                        cell.id!,
                        newWidth,
                        newHeight
                    );

                    Navigator.pop(context);
                  } else {
                    // Показать ошибку, если размеры слишком малы
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Минимальный размер ячейки: 100x100'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  // Показать ошибку при неверном формате данных
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Проверьте введенные значения, должны быть числа'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  // Создание маркеров для изменения размера ячейки
  List<Widget> _buildResizeHandles(editor.Cell cell) {
    const double handleSize = 22; // Увеличил размер для более удобного захвата

    // Создаем маркеры для всех углов и сторон
    return [
      // Нижний правый угол (увеличение/уменьшение по диагонали)
      Positioned(
        right: 0,
        bottom: 0,
        width: handleSize,
        height: handleSize,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _resizingCellId = cell.id;
              _initialWidth = cell.width;
              _initialHeight = cell.height;
              _resizeStartPosition = details.globalPosition;
            });
          },
          onPanUpdate: (details) {
            if (_resizingCellId == cell.id && _initialWidth != null && _initialHeight != null && _resizeStartPosition != null) {
              final delta = details.globalPosition - _resizeStartPosition!;

              // Рассчитываем новые размеры с учетом смещения
              final newWidth = math.max(_initialWidth! + delta.dx, 100.0); // Минимальная ширина 100
              final newHeight = math.max(_initialHeight! + delta.dy, 100.0); // Минимальная высота 100

              // Предварительно отображаем изменение размера
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Используем провайдер для изменения размера через модель
                ref.read(editor.comicEditorProvider.notifier).resizeCell(
                    cell.id!,
                    newWidth,
                    newHeight
                );
              });
            }
          },
          onPanEnd: (details) {
            if (_resizingCellId == cell.id) {
              setState(() {
                _resizingCellId = null;
                _initialWidth = null;
                _initialHeight = null;
                _resizeStartPosition = null;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Palette.orangeAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.open_in_full, color: Colors.white, size: 14),
          ),
        ),
      ),

      // Правый край (изменение ширины)
      Positioned(
        right: 0,
        top: cell.height / 2 - handleSize / 2,
        width: handleSize,
        height: handleSize,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _resizingCellId = cell.id;
              _initialWidth = cell.width;
              _resizeStartPosition = details.globalPosition;
            });
          },
          onPanUpdate: (details) {
            if (_resizingCellId == cell.id && _initialWidth != null && _resizeStartPosition != null) {
              final delta = details.globalPosition - _resizeStartPosition!;

              // Рассчитываем новую ширину с учетом смещения
              final newWidth = math.max(_initialWidth! + delta.dx, 100.0); // Минимальная ширина 100

              // Применяем изменения через провайдер
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(editor.comicEditorProvider.notifier).resizeCell(
                    cell.id!,
                    newWidth,
                    cell.height
                );
              });
            }
          },
          onPanEnd: (details) {
            if (_resizingCellId == cell.id) {
              setState(() {
                _resizingCellId = null;
                _initialWidth = null;
                _resizeStartPosition = null;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Palette.orangeAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.keyboard_double_arrow_right, color: Colors.white, size: 14),
          ),
        ),
      ),

      // Нижний край (изменение высоты)
      Positioned(
        bottom: 0,
        left: cell.width / 2 - handleSize / 2,
        width: handleSize,
        height: handleSize,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _resizingCellId = cell.id;
              _initialHeight = cell.height;
              _resizeStartPosition = details.globalPosition;
            });
          },
          onPanUpdate: (details) {
            if (_resizingCellId == cell.id && _initialHeight != null && _resizeStartPosition != null) {
              final delta = details.globalPosition - _resizeStartPosition!;

              // Рассчитываем новую высоту с учетом смещения
              final newHeight = math.max(_initialHeight! + delta.dy, 100.0); // Минимальная высота 100

              // Применяем изменения через провайдер
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(editor.comicEditorProvider.notifier).resizeCell(
                    cell.id!,
                    cell.width,
                    newHeight
                );
              });
            }
          },
          onPanEnd: (details) {
            if (_resizingCellId == cell.id) {
              setState(() {
                _resizingCellId = null;
                _initialHeight = null;
                _resizeStartPosition = null;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Palette.orangeAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.keyboard_double_arrow_down, color: Colors.white, size: 14),
          ),
        ),
      ),

      // Маркер перемещения (для всей ячейки)
      Positioned(
        left: 8,
        top: 8,
        width: handleSize,
        height: handleSize,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _draggingCellId = cell.id;
              _cellStartPosition = Offset(cell.positionX, cell.positionY);
              _dragStartPosition = details.globalPosition;
            });
          },
          onPanUpdate: (details) {
            if (_draggingCellId == cell.id && _cellStartPosition != null && _dragStartPosition != null) {
              final delta = details.globalPosition - _dragStartPosition!;

              // Рассчитываем новую позицию
              final newPosX = _cellStartPosition!.dx + delta.dx;
              final newPosY = _cellStartPosition!.dy + delta.dy;

              // Применяем позицию через провайдер
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(editor.comicEditorProvider.notifier).moveCell(
                    cell.id!,
                    math.max(0, newPosX),
                    math.max(0, newPosY)
                );
              });
            }
          },
          onPanEnd: (details) {
            if (_draggingCellId == cell.id) {
              setState(() {
                _draggingCellId = null;
                _cellStartPosition = null;
                _dragStartPosition = null;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Palette.orangeAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.open_with, color: Colors.white, size: 14),
          ),
        ),
      ),
    ];
  }

  // Обработка жестов масштабирования
  void _handleScaleStart(ScaleStartDetails details) {
    _startPanPosition = details.focalPoint;
    _lastFocalPoint = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Предыдущее значение масштаба для сравнения
      final double oldScale = _scale;

      // Обновляем масштаб с учетом ограничений
      final double newScale = details.scale;
      _scale = math.max(0.5, math.min(newScale * oldScale, 2.0)); // Более строгое ограничение масштаба

      // Обновляем смещение с ограничениями
      if (_lastFocalPoint != null) {
        final Offset delta = details.focalPoint - _lastFocalPoint!;

        // Получаем размеры видимой области
        final Size viewportSize = context.size ?? const Size(800, 600);

        // Рассчитываем размеры масштабированной страницы
        final double scaledPageWidth = 800 * _scale;
        final double scaledPageHeight = 1200 * _scale;

        // Рассчитываем максимальное допустимое смещение
        final double maxOffsetX = math.max(0, (scaledPageWidth - viewportSize.width) / 2);
        final double maxOffsetY = math.max(0, (scaledPageHeight - viewportSize.height) / 2);

        // Вычисляем новое смещение с учетом того, что оно может меняться при изменении масштаба
        final Offset newOffset = _offset + delta;

        // Ограничиваем смещение, чтобы страница не выходила за пределы видимой области
        _offset = Offset(
          newOffset.dx.clamp(-maxOffsetX, maxOffsetX),
          newOffset.dy.clamp(-maxOffsetY, maxOffsetY),
        );
      }
      _lastFocalPoint = details.focalPoint;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _startPanPosition = null;
  }
}