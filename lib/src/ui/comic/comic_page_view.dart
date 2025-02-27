// lib/src/ui/comic/comic_page_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/palette.dart';
import '../../logic/comic/editor_provider.dart' as editor; // Добавляем префикс
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
      color: Palette.orangeDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Страница ${page.pageNumber}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),

          // Переключатель типа расположения
          Container(
            padding: EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 1), // Белая рамка только снизу
              ),
            ),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // Убираем отступы внутри кнопки
                minimumSize: const Size(0, 0), // Убираем минимальный размер
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Уменьшаем область нажатия
                visualDensity: const VisualDensity(horizontal: -4), // Уменьшаем расстояние между иконкой и текстом
              ),
            icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 20), // Уменьшаем иконку
            onPressed: () {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;
              showMenu<editor.CellLayoutType>(
                color: Palette.white,
                context: context,
                position: RelativeRect.fromSize(
                  Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
                  size,
                ),
                items: [
                  PopupMenuItem(
                    value: editor.CellLayoutType.free,
                    child: Text(
                      'Свободное',
                      style: TextStyle(
                          color: page.layoutType == editor.CellLayoutType.free
                              ? Palette.orangeAccent
                              : Colors.black),
                    ),
                  ),
                  PopupMenuItem(
                    value: editor.CellLayoutType.grid,
                    child: Text(
                      'По сетке',
                      style: TextStyle(
                          color: page.layoutType == editor.CellLayoutType.grid
                              ? Palette.orangeAccent
                              : Colors.black),
                    ),
                  ),
                ]
              ).then((editor.CellLayoutType? newValue) {
                if (newValue != null) {
                  ref.read(editor.comicEditorProvider.notifier).setPageLayoutType(newValue);
                }
              });
            },
            label: const Text(
              'Тип расположения',
              style: TextStyle(color: Colors.white)
            ),
          ),
          ),



          // Кнопки для добавления ячеек
          if (page.layoutType == editor.CellLayoutType.grid)
            ElevatedButton.icon(
              icon: const Icon(Icons.grid_on, color: Palette.orangeDark,),
              label: const Text('Добавить ячейку', style: TextStyle(color: Palette.orangeDark),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.white,
              ),
              onPressed: () => _showGridCellDialog(),
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.add_box, color: Palette.orangeDark,),
              label: const Text('Добавить ячейку', style: TextStyle(color: Palette.orangeDark),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.white,
              ),
              onPressed: () {
                ref.read(editor.comicEditorProvider.notifier).addCell();
              },
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
        backgroundColor: Colors.white,
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
                            border: isSelected ? null : Border.all(color: Colors.black),
                          ),
                          child: Center(
                            child: Text(
                              isSelected ? 'Выбрано' : '',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
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
            child: const Text('Отмена', style: TextStyle(color: Colors.black),),
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
            child: const Text('Добавить', style: TextStyle(color: Colors.white),),
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
        // Здесь можно предварительно отрисовать содержимое ячейки
        // Для простоты просто покажем цветную ячейку, если в ней есть контент
        cellContent = Container(
          color: Colors.white,
          child: Center(
            child: Text(
              'Ячейка ${cell.id}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      }
    } catch (e) {
      print("Ошибка при отрисовке содержимого ячейки: $e");
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

            // Рамка для выделенной ячейки
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

  // Создание маркеров для изменения размера ячейки
  List<Widget> _buildResizeHandles(editor.Cell cell) {
    const double handleSize = 12;

    // Угловые маркеры
    return [
      // Нижний правый угол
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
              _resizeStartPosition = details.localPosition;
            });
          },
          onPanUpdate: (details) {
            if (_resizingCellId == cell.id) {
              final delta = details.localPosition - _resizeStartPosition!;

              // Применяем визуальное изменение размера
              setState(() {});
            }
          },
          onPanEnd: (details) {
            if (_resizingCellId == cell.id) {
              // Вычисляем новый размер
              final newWidth = math.max(_initialWidth! + 10, 100.0); // Минимальная ширина 100
              final newHeight = math.max(_initialHeight! + 10, 100.0); // Минимальная высота 100

              // Применяем изменения через провайдер
              ref.read(editor.comicEditorProvider.notifier).resizeCell(
                  cell.id!,
                  newWidth,
                  newHeight
              );

              setState(() {
                _resizingCellId = null;
                _initialWidth = null;
                _initialHeight = null;
                _resizeStartPosition = null;
              });
            }
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Palette.orangeAccent,
              shape: BoxShape.circle,
            ),
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
      // Обновляем масштаб
      _scale = details.scale * (_scale);

      // Ограничиваем масштаб
      _scale = math.max(0.5, math.min(_scale, 3.0));

      // Обновляем смещение
      if (_lastFocalPoint != null) {
        _offset += details.focalPoint - _lastFocalPoint!;
      }
      _lastFocalPoint = details.focalPoint;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _startPanPosition = null;
  }
}