import 'dart:convert';
import 'package:flutter/material.dart';

enum DrawingTool {
  brush, // Кисть для рисования
  eraser, // Ластик
  text, // Текст
  image, // Изображение
  selection, // Выбор элемента
  hand, // Перемещение холста
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

// Класс для линий (кисть)
class BrushElement implements CanvasElement {
  final String color;
  final double thickness;
  final List<Point> points;

  BrushElement({
    required this.color,
    required this.thickness,
    required this.points,
  });

  @override
  String get type => 'brush';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'color': color,
    'thickness': thickness,
    'points': points.map((p) => p.toJson()).toList(),
  };

  factory BrushElement.fromJson(Map<String, dynamic> json) {
    return BrushElement(
      color: json['color'] as String,
      thickness: (json['thickness'] as num).toDouble(),
      points: (json['points'] as List)
          .map((p) => Point.fromJson(p as Map<String, dynamic>))
          .toList(),
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
  final Function(CellContent) onContentChanged;

  // Текущие настройки рисования
  DrawingTool currentTool = DrawingTool.brush;
  Color currentColor = Colors.black;
  double currentThickness = 3.0;
  double currentFontSize = 16.0;

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

  // Оповещение об изменении содержимого
  void notifyContentChanged() {
    onContentChanged(_content);
  }

  // Обработка начала рисования
  void startDrawing(Offset position) {
    if (currentTool == DrawingTool.brush) {
      _currentPoints = [Point(position.dx, position.dy)];
    } else if (currentTool == DrawingTool.selection) {
      _selectedElementIndex = _findElementAtPosition(position);
    }
  }

  // Обработка продолжения рисования
  void continueDrawing(Offset position) {
    if (currentTool == DrawingTool.brush) {
      _currentPoints.add(Point(position.dx, position.dy));
    } else if (currentTool == DrawingTool.selection && _selectedElementIndex != null) {
      // Перемещение выбранного элемента
      _moveSelectedElement(position);
    }
  }

// Метод endDrawing, который вызывается при завершении рисования
  void endDrawing() {
    if (currentTool == DrawingTool.brush && _currentPoints.length > 1) {
      final element = BrushElement(
        color: '#${currentColor.value.toRadixString(16).substring(2)}',
        thickness: currentThickness,
        points: _currentPoints,
      );
      _content.addElement(element);
      notifyContentChanged();
    }

    _currentPoints = [];
    _selectedElementIndex = null;
  }


  void addText(String text, Offset position) {
    final element = TextElement(
      text: text,
      fontSize: currentFontSize,
      color: '#${currentColor.value.toRadixString(16).substring(2)}',
      x: position.dx,
      y: position.dy,
    );
    _content.addElement(element);
    notifyContentChanged();
  }

  // Добавление изображения
  void addImage(String path, Offset position, {double? width, double? height}) {
    final element = ImageElement(
      path: path,
      x: position.dx,
      y: position.dy,
      width: width,
      height: height,
    );
    _content.addElement(element);
    notifyContentChanged();
  }

  // Очистка содержимого
  void clear() {
    _content.clear();
    notifyContentChanged();
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
      }
    }

    return null;
  }

  // Перемещение выбранного элемента
  void _moveSelectedElement(Offset newPosition) {
    if (_selectedElementIndex == null) return;

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
      notifyContentChanged();
    } else if (element is ImageElement) {
      final updatedElement = ImageElement(
        path: element.path,
        x: newPosition.dx,
        y: newPosition.dy,
        width: element.width,
        height: element.height,
      );
      _content.elements[_selectedElementIndex!] = updatedElement;
      notifyContentChanged();
    }
  }
}