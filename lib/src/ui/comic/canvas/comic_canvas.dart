import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_controller.dart';
import '../../../logic/comic/editor_provider.dart';

class ComicCanvas extends StatefulWidget {
  final Cell currentCell;
  final DrawingTool tool;
  final Color color;
  final double thickness;
  final double fontSize;
  final Function(CellContent) onContentChanged;

  const ComicCanvas({
    Key? key,
    required this.currentCell,
    required this.tool,
    required this.color,
    required this.thickness,
    required this.fontSize,
    required this.onContentChanged,
  }) : super(key: key);

  @override
  ComicCanvasState createState() => ComicCanvasState();
}

class ComicCanvasState extends State<ComicCanvas> {
  CanvasController? _controller;
  Offset? _lastPosition;
  CellContent? _lastContent;
  TextEditingController? _textEditingController;
  FocusNode? _textFocusNode;
  int? _editingTextIndex;

  // Масштабирование и панорамирование
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _startPanPosition;
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _textEditingController = TextEditingController();
    _textFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ComicCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Обновляем контроллер при смене ячейки
    if (oldWidget.currentCell.id != widget.currentCell.id) {
      print("Ячейка изменилась с ID=${oldWidget.currentCell.id} на ID=${widget.currentCell.id}");
      _initializeController();
    }

    // Обновляем инструмент рисования если контроллер существует
    if (_controller != null) {
      _controller!.currentTool = widget.tool;
      _controller!.currentColor = widget.color;
      _controller!.currentThickness = widget.thickness;
      _controller!.currentFontSize = widget.fontSize;
    }
  }

  @override
  void dispose() {
    _textEditingController?.dispose();
    _textFocusNode?.dispose();
    _controller = null; // Явно очищаем контроллер
    super.dispose();
  }

  void _initializeController() {
    print("Инициализация контроллера для ячейки ${widget.currentCell.id} с contentJson: ${widget.currentCell.contentJson.length > 30 ? widget.currentCell.contentJson.substring(0, 30) + '...' : widget.currentCell.contentJson}");

    // Явно очищаем старый контроллер перед созданием нового
    _controller = null;

    // Проверяем валидность JSON
    String initialContentJson = widget.currentCell.contentJson;
    if (initialContentJson.isEmpty) {
      initialContentJson = '{"elements":[]}';
    } else {
      try {
        // Проверка валидности JSON
        final json = jsonDecode(initialContentJson);
        if (!json.containsKey('elements')) {
          initialContentJson = '{"elements":[]}';
          print("JSON не содержит ключа 'elements', используем пустой JSON");
        }
      } catch (e) {
        initialContentJson = '{"elements":[]}';
        print("Невалидный JSON: $e, используем пустой JSON");
      }
    }

    try {
      _controller = CanvasController(
        initialContentJson: initialContentJson,
        onContentChanged: (content) {
          _lastContent = content;
          widget.onContentChanged(content);
        },
      );
      print("Контроллер успешно инициализирован");
    } catch (e) {
      print("ОШИБКА при инициализации контроллера: $e");
      // Создаем контроллер с пустым контентом
      _controller = CanvasController(
        initialContentJson: '{"elements":[]}',
        onContentChanged: (content) {
          _lastContent = content;
          widget.onContentChanged(content);
        },
      );
    }

    // Сбрасываем состояние масштабирования и панорамирования
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _lastPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      print("Контроллер не инициализирован");
      return const Center(
        child: Text(
          'Ошибка инициализации холста',
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
      );
    }

    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: ClipRect(
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Трансформируемый холст
              Transform(
                transform: Matrix4.identity()
                  ..translate(_offset.dx, _offset.dy)
                  ..scale(_scale),
                alignment: Alignment.center,
                child: CustomPaint(
                  painter: CanvasPainter(
                    cell: widget.currentCell,
                    content: _controller!.content,
                    currentPoints: _lastPosition != null &&
                        widget.tool == DrawingTool.brush
                        ? [Point(_lastPosition!.dx, _lastPosition!.dy)]
                        : [],
                  ),
                  child: Container(
                    width: widget.currentCell.width,
                    height: widget.currentCell.height,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Отображение редактируемого текста
              if (_editingTextIndex != null)
                _buildTextEditor(),

              // Информационная панель с информацией о холсте
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID ячейки: ${widget.currentCell.id}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Инструмент: ${_getToolName(widget.tool)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Масштаб: ${(_scale * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Обработка жестов масштабирования
  void _handleScaleStart(ScaleStartDetails details) {
    _startPanPosition = details.focalPoint;
    _lastFocalPoint = details.focalPoint;

    if (_controller == null) return;

    if (widget.tool == DrawingTool.brush) {
      final localPosition = _transformPosition(details.localFocalPoint);
      _lastPosition = localPosition;
      _controller!.startDrawing(localPosition);
    } else if (widget.tool == DrawingTool.text) {
      final localPosition = _transformPosition(details.localFocalPoint);
      _showTextInputDialog(localPosition);
    } else if (widget.tool == DrawingTool.hand) {
      // Ничего не делаем, просто запоминаем начальную позицию
    } else if (widget.tool == DrawingTool.selection) {
      final localPosition = _transformPosition(details.localFocalPoint);
      _controller!.startDrawing(localPosition);
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_controller == null) return;

    if (widget.tool == DrawingTool.hand) {
      // Панорамирование холста
      setState(() {
        _offset += details.focalPoint - _lastFocalPoint!;
        _lastFocalPoint = details.focalPoint;
      });
    } else if (widget.tool == DrawingTool.brush) {
      // Рисование
      final localPosition = _transformPosition(details.localFocalPoint);
      setState(() {
        _lastPosition = localPosition;
      });
      _controller!.continueDrawing(localPosition);
    } else if (widget.tool == DrawingTool.selection) {
      // Перемещение выбранного элемента
      final localPosition = _transformPosition(details.localFocalPoint);
      _controller!.continueDrawing(localPosition);
    } else {
      // Масштабирование холста для других инструментов
      setState(() {
        // Ограничение масштаба между 0.5 и 3.0
        _scale = max(0.5, min(details.scale * _scale, 3.0));

        // Обновление смещения при масштабировании
        final newFocalPoint = details.focalPoint;
        _offset += newFocalPoint - _lastFocalPoint!;
        _lastFocalPoint = newFocalPoint;
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_controller == null) return;

    if (widget.tool == DrawingTool.brush) {
      _controller!.endDrawing();
      setState(() {
        _lastPosition = null;
      });
    } else if (widget.tool == DrawingTool.selection) {
      _controller!.endDrawing();
    }
  }

  // Преобразование экранных координат в координаты холста
  Offset _transformPosition(Offset screenPosition) {
    // Учитываем смещение и масштаб
    final x = (screenPosition.dx - _offset.dx) / _scale;
    final y = (screenPosition.dy - _offset.dy) / _scale;
    return Offset(x, y);
  }

  // Показ диалога для ввода текста
  void _showTextInputDialog(Offset position) {
    if (_controller == null) return;

    _textEditingController!.text = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Введите текст'),
          content: TextField(
            controller: _textEditingController,
            focusNode: _textFocusNode,
            decoration: const InputDecoration(
              hintText: 'Текст',
            ),
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final text = _textEditingController!.text;
                if (text.isNotEmpty) {
                  _controller!.addText(text, position);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    ).then((_) {
      _textFocusNode!.requestFocus();
    });
  }

  // Виджет для редактирования текста
  Widget _buildTextEditor() {
    if (_controller == null || _editingTextIndex == null ||
        _editingTextIndex! >= _controller!.content.elements.length) {
      return const SizedBox();
    }

    final element = _controller!.content.elements[_editingTextIndex!] as TextElement;

    return Positioned(
      left: element.x * _scale + _offset.dx,
      top: element.y * _scale + _offset.dy,
      child: SizedBox(
        width: 200 * _scale,
        child: TextField(
          controller: _textEditingController,
          focusNode: _textFocusNode,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          style: TextStyle(
            color: Color(int.parse(element.color.substring(1), radix: 16) + 0xFF000000),
            fontSize: element.fontSize * _scale,
          ),
          maxLines: null,
          onChanged: (value) {
            // Обновление текста в реальном времени
            final updatedElement = TextElement(
              text: value,
              fontSize: element.fontSize,
              color: element.color,
              x: element.x,
              y: element.y,
              fontFamily: element.fontFamily,
            );

            final updatedContent = _controller!.content;
            updatedContent.elements[_editingTextIndex!] = updatedElement;
            widget.onContentChanged(updatedContent);
          },
        ),
      ),
    );
  }

  // Получение названия инструмента
  String _getToolName(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.brush:
        return 'Кисть';
      case DrawingTool.eraser:
        return 'Ластик';
      case DrawingTool.text:
        return 'Текст';
      case DrawingTool.image:
        return 'Изображение';
      case DrawingTool.selection:
        return 'Выбор';
      case DrawingTool.hand:
        return 'Рука';
      default:
        return 'Неизвестно';
    }
  }
}

// Класс для отрисовки холста
class CanvasPainter extends CustomPainter {
  final Cell cell;
  final CellContent content;
  final List<Point> currentPoints;

  CanvasPainter({
    required this.cell,
    required this.content,
    this.currentPoints = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Отрисовка фона
    final backgroundPaint = Paint()
      ..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, cell.width, cell.height), backgroundPaint);

    // Отрисовка всех элементов
    for (var element in content.elements) {
      if (element is BrushElement) {
        _drawBrush(canvas, element);
      } else if (element is TextElement) {
        _drawText(canvas, element);
      } else if (element is ImageElement) {
        // Изображения отрисовываются в виджете
      } else if (element is RectangleElement) {
        _drawRectangle(canvas, element);
      }
    }

    // Отрисовка текущей линии рисования
    if (currentPoints.isNotEmpty) {
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(
          Offset(currentPoints[i].x, currentPoints[i].y),
          Offset(currentPoints[i + 1].x, currentPoints[i + 1].y),
          paint,
        );
      }
    }
  }

  void _drawBrush(Canvas canvas, BrushElement element) {
    if (element.points.length < 2) return;

    final paint = Paint()
      ..color = Color(int.parse(element.color.substring(1), radix: 16) + 0xFF000000)
      ..strokeWidth = element.thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < element.points.length - 1; i++) {
      canvas.drawLine(
        Offset(element.points[i].x, element.points[i].y),
        Offset(element.points[i + 1].x, element.points[i + 1].y),
        paint,
      );
    }
  }

  void _drawText(Canvas canvas, TextElement element) {
    final textStyle = TextStyle(
      color: Color(int.parse(element.color.substring(1), radix: 16) + 0xFF000000),
      fontSize: element.fontSize,
      fontFamily: element.fontFamily,
    );

    final textSpan = TextSpan(
      text: element.text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(element.x, element.y));
  }

  void _drawRectangle(Canvas canvas, RectangleElement element) {
    final rect = Rect.fromLTWH(
      element.x,
      element.y,
      element.width,
      element.height,
    );

    // Заливка
    if (element.fillColor != null) {
      final fillPaint = Paint()
        ..color = Color(int.parse(element.fillColor!.substring(1), radix: 16) + 0xFF000000)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, fillPaint);
    }

    // Обводка
    final strokePaint = Paint()
      ..color = Color(int.parse(element.strokeColor.substring(1), radix: 16) + 0xFF000000)
      ..strokeWidth = element.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.content != content ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.cell.id != cell.id;
  }
}