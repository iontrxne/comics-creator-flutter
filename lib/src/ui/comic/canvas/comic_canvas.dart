// lib/src/ui/comic/canvas/comic_canvas.dart
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'canvas_controller.dart';
import '../../../logic/comic/editor_provider.dart';

class ComicCanvas extends StatefulWidget {
  final Cell currentCell;
  final DrawingTool tool;
  final Color color;
  final double thickness;
  final double fontSize;
  final Function(CellContent, [CellContent?]) onContentChanged;

  const ComicCanvas({
    super.key,
    required this.currentCell,
    required this.tool,
    required this.color,
    required this.thickness,
    required this.fontSize,
    required this.onContentChanged,
  });

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
    print("Инициализация контроллера для ячейки ${widget.currentCell.id} с contentJson: ${widget.currentCell.contentJson.length > 30 ? '${widget.currentCell.contentJson.substring(0, 30)}...' : widget.currentCell.contentJson}");

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
        onContentChanged: (content, [previousContent]) {
          _lastContent = content;
          widget.onContentChanged(content, previousContent);
        },
      );
      print("Контроллер успешно инициализирован");
    } catch (e) {
      print("ОШИБКА при инициализации контроллера: $e");
      // Создаем контроллер с пустым контентом
      _controller = CanvasController(
        initialContentJson: '{"elements":[]}',
        onContentChanged: (content, [previousContent]) {
          _lastContent = content;
          widget.onContentChanged(content, previousContent);
        },
      );
    }

    // Рассчитываем масштаб для наилучшего отображения ячейки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final Size viewportSize = MediaQuery.of(context).size;
        final double cellWidth = widget.currentCell.width;
        final double cellHeight = widget.currentCell.height;

        // Вычисляем масштаб, чтобы ячейка помещалась в видимую область с учетом отступов
        double scaleX = (viewportSize.width * 0.8) / cellWidth;
        double scaleY = (viewportSize.height * 0.6) / cellHeight;
        double newScale = math.min(scaleX, scaleY);

        // Ограничиваем масштаб разумными пределами
        newScale = math.max(0.5, math.min(newScale, 2.0));

        setState(() {
          _scale = newScale;
          // Центрируем ячейку
          _offset = Offset(
              (viewportSize.width - cellWidth * _scale) / 2,
              (viewportSize.height - cellHeight * _scale) / 4
          );
        });
      }
    });

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
                        (widget.tool == DrawingTool.brush ||
                            widget.tool == DrawingTool.pencil ||
                            widget.tool == DrawingTool.marker)
                        ? [Point(_lastPosition!.dx, _lastPosition!.dy)]
                        : [],
                    currentTool: widget.tool,
                    eraserSize: widget.thickness,
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

              // Отображение координат для отладки (можно удалить в релизе)
              if (_lastPosition != null)
                Positioned(
                  bottom: 60,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Координаты: ${_lastPosition!.dx.toStringAsFixed(1)}, ${_lastPosition!.dy.toStringAsFixed(1)}\n'
                          'Масштаб: ${(_scale * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
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

  double _lastScale = 1.0;

  // Обработка жестов масштабирования
  void _handleScaleStart(ScaleStartDetails details) {
    // Сохраняем текущее состояние при начале жеста
    _startPanPosition = details.focalPoint;
    _lastFocalPoint = details.focalPoint;
    _lastScale = 1.0; // Сбрасываем относительный масштаб при новом жесте

    if (_controller == null) return;

    // Проверяем, используется ли инструмент для перемещения холста
    if (widget.tool == DrawingTool.hand) {
      return; // Только перемещение, не рисуем
    }

    // Переводим координаты экрана в координаты холста
    final localPosition = _transformPosition(details.localFocalPoint);

    // Сохраняем позицию для отображения
    setState(() {
      _lastPosition = localPosition;
    });

    // Начинаем рисование, если используется соответствующий инструмент
    if (widget.tool == DrawingTool.brush ||
        widget.tool == DrawingTool.pencil ||
        widget.tool == DrawingTool.marker) {
      _controller!.startDrawing(localPosition);
    } else if (widget.tool == DrawingTool.eraser) {
      _controller!.startDrawing(localPosition);
    } else if (widget.tool == DrawingTool.text) {
      _showTextInputDialog(localPosition);
    } else if (widget.tool == DrawingTool.selection) {
      _controller!.startDrawing(localPosition);
    } else if (widget.tool == DrawingTool.fill) {
      _controller!.startDrawing(localPosition);
    }
  }


  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_controller == null) return;

    // Обнаруживаем тип жеста: масштабирование или перемещение
    final bool isScaling = details.scale != 1.0;
    final bool isPanning = (widget.tool == DrawingTool.hand) || isScaling;

    if (isPanning) {
      if (isScaling) {
        // МАСШТАБИРОВАНИЕ
        // Очень важно: отделяем абсолютный масштаб (_scale) от относительного (details.scale)

        // Находим фокальную точку в координатах холста
        final focalPoint = details.localFocalPoint;

        // Рассчитываем положение фокальной точки относительно холста до масштабирования
        final double dx = (focalPoint.dx - _offset.dx) / _scale;
        final double dy = (focalPoint.dy - _offset.dy) / _scale;

        // ОЧЕНЬ плавное масштабирование с малым коэффициентом
        const double smoothFactor = 0.2;
        double scaleDelta = (details.scale / _lastScale) - 1.0;
        scaleDelta *= smoothFactor;

        // Ограничиваем новый масштаб разумными пределами
        final double newScale = _scale * (1.0 + scaleDelta);

        // Жестко ограничиваем диапазон масштаба
        if (newScale >= 0.5 && newScale <= 3.0) {
          _scale = newScale;

          // Коррекция смещения, чтобы точка под пальцем оставалась на месте
          _offset = Offset(
              focalPoint.dx - dx * _scale,
              focalPoint.dy - dy * _scale
          );
        }

        // Сохраняем относительный масштаб для следующего кадра
        _lastScale = details.scale;

        setState(() {});
        return; // Выходим, так как обработали масштабирование
      } else {
        // ПЕРЕМЕЩЕНИЕ (инструмент руки или режим просмотра)
        if (_lastFocalPoint != null) {
          // Обычное перемещение холста
          _offset += details.focalPoint - _lastFocalPoint!;
          _lastFocalPoint = details.focalPoint;
          setState(() {});
        }

        // Если используется инструмент руки, то прекращаем обработку
        if (widget.tool == DrawingTool.hand) return;
      }
    }

    // РИСОВАНИЕ (если не выполняем масштабирование или перемещение)
    // Переводим координаты экрана в координаты холста
    final localPosition = _transformPosition(details.localFocalPoint);

    setState(() {
      _lastPosition = localPosition;
    });

    // Продолжаем рисование соответствующим инструментом
    if (widget.tool == DrawingTool.brush ||
        widget.tool == DrawingTool.pencil ||
        widget.tool == DrawingTool.marker) {
      _controller!.continueDrawing(localPosition);
    } else if (widget.tool == DrawingTool.eraser) {
      _controller!.continueDrawing(localPosition);
    } else if (widget.tool == DrawingTool.selection) {
      _controller!.continueDrawing(localPosition);
    }
  }




  void _handleScaleEnd(ScaleEndDetails details) {
    if (_controller == null) return;
    if (widget.tool == DrawingTool.brush ||
        widget.tool == DrawingTool.pencil ||
        widget.tool == DrawingTool.marker ||
        widget.tool == DrawingTool.eraser ||
        widget.tool == DrawingTool.selection) {
      _controller!.endDrawing();
    }
    setState(() {
      _lastPosition = null;
    });
    _startPanPosition = null;
    _lastScale = 1.0;
  }



  // Преобразование экранных координат в координаты холста
  Offset _transformPosition(Offset screenPosition) {
    double x = (screenPosition.dx - _offset.dx) / _scale;
    double y = (screenPosition.dy - _offset.dy) / _scale;
    x = x.clamp(0.0, widget.currentCell.width);
    y = y.clamp(0.0, widget.currentCell.height);
    return Offset(x, y);
  }



  // Показ диалога для ввода текста
  void _showTextInputDialog(Offset position) {
    if (_controller == null) return;
    _textEditingController?.text = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Введите текст'),
        content: TextField(
          controller: _textEditingController,
          focusNode: _textFocusNode,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final text = _textEditingController?.text.trim() ?? '';
              if (text.isNotEmpty) {
                _controller!.addText(text, position);
              }
              Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
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
            // Сохраняем текущее состояние перед изменением
            final previousContent = _controller!.content.copy();

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
            widget.onContentChanged(updatedContent, previousContent);
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
      case DrawingTool.pencil:
        return 'Карандаш';
      case DrawingTool.marker:
        return 'Маркер';
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
      case DrawingTool.fill:
        return 'Заливка';
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
  final DrawingTool currentTool;
  final double eraserSize;

  CanvasPainter({
    required this.cell,
    required this.content,
    this.currentPoints = const [],
    this.currentTool = DrawingTool.brush,
    this.eraserSize = 3.0,
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
      } else if (element is FillElement) {
        _drawFill(canvas, element);
      }
    }

    // Отрисовка текущей линии рисования
    if (currentPoints.isNotEmpty) {
      if (currentTool == DrawingTool.eraser) {
        // Отображение ластика как круга
        final eraserPaint = Paint()
          ..color = Colors.red.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
            Offset(currentPoints.last.x, currentPoints.last.y),
            eraserSize,
            eraserPaint
        );
      } else {
        // Цвет и толщина в зависимости от инструмента
        Color brushColor = Colors.black;
        double strokeWidth = 3.0;

        if (currentTool == DrawingTool.pencil) {
          strokeWidth = 1.5;
        } else if (currentTool == DrawingTool.marker) {
          brushColor = Colors.black.withOpacity(0.5);
          strokeWidth = 5.0;
        }

        final paint = Paint()
          ..color = brushColor
          ..strokeWidth = strokeWidth
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
  }

  void _drawBrush(Canvas canvas, BrushElement element) {
    if (element.points.length < 2) return;

    final Color color = Color(int.parse(element.color.substring(1), radix: 16) + 0xFF000000);
    final paint = Paint()
      ..color = color
      ..strokeWidth = element.thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Разные настройки для разных типов кисти
    if (element.brushType == 'pencil') {
      paint.strokeWidth = element.thickness * 0.7;
      paint.strokeCap = StrokeCap.square;
    } else if (element.brushType == 'marker') {
      paint.strokeWidth = element.thickness * 1.5;
      // Маркер уже имеет прозрачность в самом цвете
    }

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

  void _drawFill(Canvas canvas, FillElement element) {
    // Заливка реализована как прямоугольник размером с весь холст
    final fillPaint = Paint()
      ..color = Color(int.parse(element.color.substring(1), radix: 16) + 0xFF000000)
      ..style = PaintingStyle.fill;

    // Рисуем прямоугольник на всю площадь холста
    canvas.drawRect(
        Rect.fromLTWH(0, 0, cell.width, cell.height),
        fillPaint
    );
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.content != content ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.currentTool != currentTool ||
        oldDelegate.eraserSize != eraserSize ||
        oldDelegate.cell.id != cell.id;
  }
}