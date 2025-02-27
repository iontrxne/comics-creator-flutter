// lib/src/ui/comic/canvas/canvas_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';

// Перечисление инструментов рисования
enum DrawingTool {
  brush,    // Кисть для рисования
  pencil,   // Карандаш (тоньше и точнее кисти)
  marker,   // Маркер (толще и полупрозрачный)
  eraser,   // Ластик
  text,     // Текст
  image,    // Изображение
  selection, // Выбор элемента
  hand,     // Перемещение холста
  fill,     // Заливка
}

// Класс для хранения информации о точке на холсте
class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
  };

  factory Point.fromJson(Map<String, dynamic> json) =>
      Point(json['x'] as double, json['y'] as double);
}

// Базовый класс для всех элементов на холсте
abstract class CanvasElement {
  String get type;
  Map<String, dynamic> toJson();
}

// Класс для линий (кисть, карандаш, маркер)
class BrushElement implements CanvasElement {
  final String color;
  final double thickness;
  final List<Point> points;
  final String brushType; // 'brush', 'pencil', или 'marker'

  BrushElement({
    required this.color,
    required this.thickness,
    required this.points,
    this.brushType = 'brush',
  });

  @override
  String get type => 'brush';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'color': color,
    'thickness': thickness,
    'points': points.map((p) => p.toJson()).toList(),
    'brushType': brushType,
  };

  factory BrushElement.fromJson(Map<String, dynamic> json) {
    return BrushElement(
      color: json['color'] as String,
      thickness: (json['thickness'] as num).toDouble(),
      points: (json['points'] as List)
          .map((p) => Point.fromJson(p as Map<String, dynamic>))
          .toList(),
      brushType: json['brushType'] as String? ?? 'brush',
    );
  }
}

// Класс для текстовых элементов
class TextElement implements CanvasElement {
  final String text;
  final double fontSize;
  final String color;
  final double x;
  final double y;
  final String? fontFamily;

  TextElement({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.x,
    required this.y,
    this.fontFamily,
  });

  @override
  String get type => 'text';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
    'fontSize': fontSize,
    'color': color,
    'x': x,
    'y': y,
    if (fontFamily != null) 'fontFamily': fontFamily,
  };

  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      text: json['text'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      color: json['color'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      fontFamily: json['fontFamily'] as String?,
    );
  }
}

// Класс для изображений
class ImageElement implements CanvasElement {
  final String path;
  final double x;
  final double y;
  final double? width;
  final double? height;

  ImageElement({
    required this.path,
    required this.x,
    required this.y,
    this.width,
    this.height,
  });

  @override
  String get type => 'image';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'path': path,
    'x': x,
    'y': y,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
  };

  factory ImageElement.fromJson(Map<String, dynamic> json) {
    return ImageElement(
      path: json['path'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
    );
  }
}

// Класс для прямоугольников
class RectangleElement implements CanvasElement {
  final double x;
  final double y;
  final double width;
  final double height;
  final String strokeColor;
  final double strokeWidth;
  final String? fillColor;

  RectangleElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.strokeColor,
    required this.strokeWidth,
    this.fillColor,
  });

  @override
  String get type => 'rectangle';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'strokeColor': strokeColor,
    'strokeWidth': strokeWidth,
    if (fillColor != null) 'fillColor': fillColor,
  };

  factory RectangleElement.fromJson(Map<String, dynamic> json) {
    return RectangleElement(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      strokeColor: json['strokeColor'] as String,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      fillColor: json['fillColor'] as String?,
    );
  }
}

// Класс для заливки
class FillElement implements CanvasElement {
  final String color;
  final double x;
  final double y;

  FillElement({
    required this.color,
    required this.x,
    required this.y,
  });

  @override
  String get type => 'fill';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'color': color,
    'x': x,
    'y': y,
  };

  factory FillElement.fromJson(Map<String, dynamic> json) {
    return FillElement(
      color: json['color'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}

// Класс для содержимого ячейки
class CellContent {
  List<CanvasElement> elements;

  CellContent({
    required this.elements,
  });

  Map<String, dynamic> toJson() => {
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());

  factory CellContent.fromJson(Map<String, dynamic> json) {
    final elementsList = (json['elements'] as List);
    return CellContent(
      elements: elementsList.map((elementJson) {
        final Map<String, dynamic> data = elementJson as Map<String, dynamic>;
        final String type = data['type'] as String;

        switch (type) {
          case 'brush':
            return BrushElement.fromJson(data);
          case 'text':
            return TextElement.fromJson(data);
          case 'image':
            return ImageElement.fromJson(data);
          case 'rectangle':
            return RectangleElement.fromJson(data);
          case 'fill':
            return FillElement.fromJson(data);
          default:
            throw Exception('Unknown element type: $type');
        }
      }).toList(),
    );
  }

  factory CellContent.fromJsonString(String jsonString) {
    if (jsonString.isEmpty) {
      return CellContent(elements: []);
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CellContent.fromJson(json);
    } catch (e) {
      print('Error parsing JSON: $e');
      return CellContent(elements: []);
    }
  }

  // Создание копии объекта
  CellContent copy() {
    return CellContent(
      elements: List.from(elements),
    );
  }

  // Добавление нового элемента
  void addElement(CanvasElement element) {
    elements.add(element);
  }

  // Удаление элемента
  void removeElement(int index) {
    if (index >= 0 && index < elements.length) {
      elements.removeAt(index);
    }
  }

  // Очистка всех элементов
  void clear() {
    elements.clear();
  }
}

// Контроллер для работы с холстом
class CanvasController {
  CellContent _content;
  final Function(CellContent content, [CellContent? previousContent]) onContentChanged;

  // Текущие настройки рисования
  DrawingTool currentTool = DrawingTool.brush;
  Color currentColor = Colors.black;
  double currentThickness = 3.0;
  double currentFontSize = 16.0;
  double eraserSize = 15.0; // Размер ластика

  // Текущие элементы рисования
  List<Point> _currentPoints = [];
  int? _selectedElementIndex;

  CanvasController({
    required String initialContentJson,
    required this.onContentChanged,
  }) : _content = CellContent.fromJsonString(initialContentJson.isEmpty
      ? '{"elements":[]}'
      : initialContentJson);

  // Геттер для доступа к содержимому
  CellContent get content => _content;

  // Обновление содержимого из JSON
  void updateFromJson(String jsonString) {
    _content = CellContent.fromJsonString(jsonString.isEmpty
        ? '{"elements":[]}'
        : jsonString);
    notifyContentChanged();
  }

  // Обновленный метод уведомления об изменении содержимого
  void notifyContentChanged([CellContent? previousContent]) {
    onContentChanged(_content, previousContent);
  }

  // Обработка начала рисования
  void startDrawing(Offset position) {
    if (currentTool == DrawingTool.brush ||
        currentTool == DrawingTool.pencil ||
        currentTool == DrawingTool.marker) {
      _currentPoints = [Point(position.dx, position.dy)];
    } else if (currentTool == DrawingTool.eraser) {
      // Начало стирания
      _startErasing(position);
    } else if (currentTool == DrawingTool.selection) {
      _selectedElementIndex = _findElementAtPosition(position);
    } else if (currentTool == DrawingTool.fill) {
      // Использование заливки
      _useFillTool(position);
    }
  }

  // Обработка продолжения рисования
  void continueDrawing(Offset position) {
    if (currentTool == DrawingTool.brush ||
        currentTool == DrawingTool.pencil ||
        currentTool == DrawingTool.marker) {
      _currentPoints.add(Point(position.dx, position.dy));
    } else if (currentTool == DrawingTool.eraser) {
      // Продолжение стирания
      _continueErasing(position);
    } else if (currentTool == DrawingTool.selection && _selectedElementIndex != null) {
      // Перемещение выбранного элемента
      _moveSelectedElement(position);
    }
  }

  // Обработка окончания рисования
  void endDrawing() {
    if ((currentTool == DrawingTool.brush ||
        currentTool == DrawingTool.pencil ||
        currentTool == DrawingTool.marker) &&
        _currentPoints.length > 1) {
      // Сохраняем текущее состояние перед изменением
      final previousContent = _content.copy();

      // Устанавливаем разную толщину и прозрачность в зависимости от типа инструмента
      double toolThickness = currentThickness;
      String colorHex = '#${currentColor.value.toRadixString(16).substring(2)}';
      String brushType = 'brush';

      if (currentTool == DrawingTool.pencil) {
        toolThickness = currentThickness * 0.7; // Тоньше для карандаша
        brushType = 'pencil';
      } else if (currentTool == DrawingTool.marker) {
        toolThickness = currentThickness * 1.5; // Толще для маркера
        // Добавляем прозрачность для маркера (80% непрозрачности)
        int alpha = 204; // ~80% от 255
        int r = currentColor.red;
        int g = currentColor.green;
        int b = currentColor.blue;
        colorHex = '#${alpha.toRadixString(16).padLeft(2, '0')}${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
        brushType = 'marker';
      }

      final element = BrushElement(
        color: colorHex,
        thickness: toolThickness,
        points: _currentPoints,
        brushType: brushType,
      );
      _content.addElement(element);

      // Передаем предыдущее состояние при уведомлении об изменении
      notifyContentChanged(previousContent);
    }

    _currentPoints = [];
    _selectedElementIndex = null;
  }

  // Начало стирания
  void _startErasing(Offset position) {
    // Сохраняем текущее состояние перед стиранием
    final previousContent = _content.copy();

    // Находим элементы для стирания в этой позиции
    _eraseAtPosition(position);

    // Уведомляем с предыдущим состоянием
    notifyContentChanged(previousContent);
  }

  // Продолжение стирания
  void _continueErasing(Offset position) {
    // Для непрерывного стирания не нужно сохранять предыдущее состояние для каждой точки
    _eraseAtPosition(position);
    notifyContentChanged();
  }

  // Стирание в определенной позиции
  void _eraseAtPosition(Offset position) {
    // Сохраняем список элементов для удаления
    List<int> elementsToRemove = [];

    // Проходим по всем элементам и проверяем, находятся ли они под ластиком
    for (int i = 0; i < _content.elements.length; i++) {
      final element = _content.elements[i];

      if (element is BrushElement) {
        // Для мазков кисти проверяем, близка ли любая точка к ластику
        for (var point in element.points) {
          if ((position.dx - point.x).abs() < eraserSize &&
              (position.dy - point.y).abs() < eraserSize) {
            elementsToRemove.add(i);
            break;
          }
        }
      } else if (element is TextElement) {
        // Для текста проверяем, перекрывает ли ластик позицию текста
        if ((position.dx - element.x).abs() < eraserSize &&
            (position.dy - element.y).abs() < eraserSize) {
          elementsToRemove.add(i);
        }
      } else if (element is ImageElement) {
        // Для изображений проверяем, находится ли ластик внутри границ изображения
        final width = element.width ?? 100;
        final height = element.height ?? 100;

        if (position.dx >= element.x &&
            position.dx <= element.x + width &&
            position.dy >= element.y &&
            position.dy <= element.y + height) {
          elementsToRemove.add(i);
        }
      } else if (element is RectangleElement) {
        // Для прямоугольников проверяем, находится ли ластик внутри прямоугольника
        if (position.dx >= element.x &&
            position.dx <= element.x + element.width &&
            position.dy >= element.y &&
            position.dy <= element.y + element.height) {
          elementsToRemove.add(i);
        }
      } else if (element is FillElement) {
        // Для элементов заливки проверяем, близок ли ластик к точке заливки
        if ((position.dx - element.x).abs() < eraserSize &&
            (position.dy - element.y).abs() < eraserSize) {
          elementsToRemove.add(i);
        }
      }
    }

    // Удаляем элементы сзади наперед, чтобы избежать проблем со смещением индексов
    elementsToRemove.sort((a, b) => b.compareTo(a));
    for (var index in elementsToRemove) {
      _content.elements.removeAt(index);
    }
  }

  // Реализация инструмента заливки
  void _useFillTool(Offset position) {
    // Сохраняем текущее состояние перед заливкой
    final previousContent = _content.copy();

    // Создаем элемент заливки в месте клика
    final element = FillElement(
      color: '#${currentColor.value.toRadixString(16).substring(2)}',
      x: position.dx,
      y: position.dy,
    );

    // Добавляем элемент заливки в содержимое
    _content.addElement(element);

    // Уведомляем с предыдущим состоянием
    notifyContentChanged(previousContent);
  }

  void addText(String text, Offset position) {
    // Сохраняем текущее состояние перед изменением
    final previousContent = _content.copy();

    final element = TextElement(
      text: text,
      fontSize: currentFontSize,
      color: '#${currentColor.value.toRadixString(16).substring(2)}',
      x: position.dx,
      y: position.dy,
    );
    _content.addElement(element);

    // Передаем предыдущее состояние
    notifyContentChanged(previousContent);
  }

  // Добавление изображения
  void addImage(String path, Offset position, {double? width, double? height}) {
    // Сохраняем текущее состояние перед изменением
    final previousContent = _content.copy();

    final element = ImageElement(
      path: path,
      x: position.dx,
      y: position.dy,
      width: width,
      height: height,
    );
    _content.addElement(element);

    // Передаем предыдущее состояние
    notifyContentChanged(previousContent);
  }

  // Очистка содержимого
  void clear() {
    // Сохраняем текущее состояние перед изменением
    final previousContent = _content.copy();

    _content.clear();

    // Передаем предыдущее состояние
    notifyContentChanged(previousContent);
  }

  // Поиск элемента по позиции
  int? _findElementAtPosition(Offset position) {
    // Упрощенная реализация. В реальном приложении нужно учитывать
    // размеры элементов и более точное определение границ
    for (int i = _content.elements.length - 1; i >= 0; i--) {
      final element = _content.elements[i];

      if (element is TextElement) {
        if ((position.dx - element.x).abs() < 50 &&
            (position.dy - element.y).abs() < 50) {
          return i;
        }
      } else if (element is ImageElement) {
        final width = element.width ?? 100;
        final height = element.height ?? 100;

        if (position.dx >= element.x &&
            position.dx <= element.x + width &&
            position.dy >= element.y &&
            position.dy <= element.y + height) {
          return i;
        }
      } else if (element is BrushElement) {
        // Проверяем близость к любой точке мазка кисти
        for (var point in element.points) {
          if ((position.dx - point.x).abs() < 10 &&
              (position.dy - point.y).abs() < 10) {
            return i;
          }
        }
      } else if (element is FillElement) {
        // Проверяем близость к точке заливки
        if ((position.dx - element.x).abs() < 10 &&
            (position.dy - element.y).abs() < 10) {
          return i;
        }
      }
    }

    return null;
  }

  // Перемещение выбранного элемента
  void _moveSelectedElement(Offset newPosition) {
    if (_selectedElementIndex == null) return;

    // Сохраняем текущее состояние перед изменением
    final previousContent = _content.copy();

    final element = _content.elements[_selectedElementIndex!];

    if (element is TextElement) {
      final updatedElement = TextElement(
        text: element.text,
        fontSize: element.fontSize,
        color: element.color,
        x: newPosition.dx,
        y: newPosition.dy,
        fontFamily: element.fontFamily,
      );
      _content.elements[_selectedElementIndex!] = updatedElement;
      notifyContentChanged(previousContent);
    } else if (element is ImageElement) {
      final updatedElement = ImageElement(
        path: element.path,
        x: newPosition.dx,
        y: newPosition.dy,
        width: element.width,
        height: element.height,
      );
      _content.elements[_selectedElementIndex!] = updatedElement;
      notifyContentChanged(previousContent);
    } else if (element is FillElement) {
      final updatedElement = FillElement(
        color: element.color,
        x: newPosition.dx,
        y: newPosition.dy,
      );
      _content.elements[_selectedElementIndex!] = updatedElement;
      notifyContentChanged(previousContent);
    }
    // Для элементов кисти перемещение было бы более сложным
  }
}