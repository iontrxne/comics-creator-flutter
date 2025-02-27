// lib/src/ui/comic/canvas/tool_panel.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../config/palette.dart';
import 'canvas_controller.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ToolPanel extends StatefulWidget {
  final DrawingTool selectedTool;
  final Function(DrawingTool) onToolChanged;
  final Function(Color) onColorChanged;
  final Function(double) onThicknessChanged;
  final Function(double) onFontSizeChanged;
  final double currentThickness;
  final double currentFontSize;
  final Color currentColor;

  const ToolPanel({
    super.key,
    required this.selectedTool,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onThicknessChanged,
    required this.onFontSizeChanged,
    this.currentThickness = 3.0,
    this.currentFontSize = 16.0,
    this.currentColor = Colors.black,
  });

  @override
  State<ToolPanel> createState() => _ToolPanelState();
}

class _ToolPanelState extends State<ToolPanel> {
  late Color _selectedColor;
  late double _currentThickness;
  late double _currentFontSize;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;

    // Установка корректных начальных значений в зависимости от инструмента
    if (widget.selectedTool == DrawingTool.eraser) {
      _currentThickness = math.max(5.0, math.min(widget.currentThickness, 30.0));
    } else {
      _currentThickness = math.max(1.0, math.min(widget.currentThickness, 15.0));
    }

    _currentFontSize = widget.currentFontSize;
  }

  @override
  void didUpdateWidget(ToolPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThickness != widget.currentThickness) {
      _currentThickness = widget.currentThickness;
    }
    if (oldWidget.currentFontSize != widget.currentFontSize) {
      _currentFontSize = widget.currentFontSize;
    }
    if (oldWidget.currentColor != widget.currentColor) {
      _selectedColor = widget.currentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Немного увеличиваем, чтобы помещался ползунок
      child: Stack(
        children: [
          // Основная панель инструментов (горизонтальная)
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildDrawToolsTypeButton(context: context),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.text_fields,
                  tool: DrawingTool.text,
                  tooltip: 'Текст',
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.image,
                  tool: DrawingTool.image,
                  tooltip: 'Изображение',
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.select_all,
                  tool: DrawingTool.selection,
                  tooltip: 'Выбор',
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.pan_tool,
                  tool: DrawingTool.hand,
                  tooltip: 'Перемещение',
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.format_color_fill,
                  tool: DrawingTool.fill,
                  tooltip: 'Заливка',
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.cleaning_services,
                  tool: DrawingTool.eraser,
                  tooltip: 'Ластик',
                ),
                const VerticalDivider(color: Colors.white30, width: 12),
                _buildColorButton(context),
                const Spacer(),
              ],
            ),
          ),

          // Всплывающий ползунок толщины - перемещен в основную область под панелью
          if (widget.selectedTool == DrawingTool.brush ||
              widget.selectedTool == DrawingTool.pencil ||
              widget.selectedTool == DrawingTool.marker ||
              widget.selectedTool == DrawingTool.eraser ||
              widget.selectedTool == DrawingTool.text)
            Positioned(
              right: 10,  // Фиксированное позиционирование справа
              top: 70,    // Размещаем под панелью инструментов
              child: Container(
                width: 200,  // Расширяем виджет ползунка
                child: _buildHorizontalThicknessSlider(),  // Используем горизонтальный ползунок вместо вертикального
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalThicknessSlider() {
    String label = 'Толщина';
    double minValue = 1.0;
    double maxValue = 15.0;

    if (widget.selectedTool == DrawingTool.eraser) {
      label = 'Ластик';
      minValue = 5.0;
      maxValue = 30.0;
    } else if (widget.selectedTool == DrawingTool.pencil) {
      label = 'Карандаш';
      minValue = 1.0;
      maxValue = 10.0;
    } else if (widget.selectedTool == DrawingTool.marker) {
      label = 'Маркер';
      minValue = 3.0;
      maxValue = 20.0;
    } else if (widget.selectedTool == DrawingTool.text) {
      label = 'Шрифт';
      minValue = 8.0;
      maxValue = 48.0;
    }

    // Убедимся, что текущее значение находится в допустимом диапазоне
    double safeValue = widget.selectedTool == DrawingTool.text
        ? _currentFontSize
        : _currentThickness;

    if (safeValue < minValue) safeValue = minValue;
    if (safeValue > maxValue) safeValue = maxValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок и значение
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                safeValue.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),

          // Визуализация размера (для инструментов рисования)
          if (widget.selectedTool != DrawingTool.text)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                width: safeValue,
                height: safeValue,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),

          // Горизонтальный слайдер
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: safeValue,
              min: minValue,
              max: maxValue,
              divisions: ((maxValue - minValue) * 2).round(),
              activeColor: Palette.orangeAccent,
              inactiveColor: Colors.white30,
              onChanged: (value) {
                setState(() {
                  if (widget.selectedTool == DrawingTool.text) {
                    _currentFontSize = value;
                    widget.onFontSizeChanged(value);
                  } else {
                    _currentThickness = value;
                    widget.onThicknessChanged(value);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  DrawingTool _selectedDrawTool = DrawingTool.brush;
  final Map<DrawingTool, Map<String, dynamic>> _toolIcons = {
    DrawingTool.fill: {'icon': Icons.format_color_fill, 'label': 'Заливка'},
    DrawingTool.eraser: {'icon': Icons.cleaning_services, 'label': 'Ластик'},
    DrawingTool.marker: {'icon': Icons.edit, 'label': 'Маркер'},
    DrawingTool.pencil: {'icon': Icons.create, 'label': 'Карандаш'},
    DrawingTool.brush: {'icon': Icons.brush, 'label': 'Кисть'},
  };

  void _openToolsMenu(BuildContext context, Function(DrawingTool tool) onChange) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    showMenu<DrawingTool>(
      color: Palette.white,
      context: context,
      position: RelativeRect.fromSize(
        Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
        size,
      ),
      items: _toolIcons.entries.map((entry) {
        return PopupMenuItem<DrawingTool>(
          value: entry.key,
          child: Row(
            children: [
              Icon(entry.value['icon'], color: _selectedDrawTool == entry.key ? Palette.orangeAccent : Colors.black),
              const SizedBox(width: 8),
              Text(entry.value['label'], style: TextStyle(color: _selectedDrawTool == entry.key ? Palette.orangeAccent : Colors.black),),
            ],
          ),
        );
      }).toList(),

    ).then((DrawingTool? selected) {
      if (selected != null) {
        onChange(selected);
        setState(() {
          _selectedDrawTool = selected;
        });
      }
    });
  }

  Widget _buildDrawToolsTypeButton({
    required BuildContext context
  }) {
    final isSelected = _toolIcons.keys.contains(widget.selectedTool);

    IconData iconToShow;
    String tooltip;

    if (isSelected) {
      iconToShow = _toolIcons[widget.selectedTool]!['icon'];
      tooltip = _toolIcons[widget.selectedTool]!['label'];
      _selectedDrawTool = widget.selectedTool;
    } else {
      iconToShow = _toolIcons[_selectedDrawTool]!['icon'];
      tooltip = _toolIcons[_selectedDrawTool]!['label'];
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _openToolsMenu(context, widget.onToolChanged),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Palette.orangeAccent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconToShow,
            color: isSelected ? Colors.white : Colors.white70,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String tooltip,
  }) {
    final isSelected = widget.selectedTool == tool;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => widget.onToolChanged(tool),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Palette.orangeAccent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context, _selectedColor),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _selectedColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, Color initialColor) {
    Color pickerColor = initialColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              showLabel: true,
              paletteType: PaletteType.hsv,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Выбрать'),
              onPressed: () {
                setState(() {
                  _selectedColor = pickerColor;
                });
                widget.onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Вертикальный ползунок толщины
  Widget _buildVerticalThicknessSlider() {
    String label = 'Толщина';
    double minValue = 1.0;
    double maxValue = 15.0;

    if (widget.selectedTool == DrawingTool.eraser) {
      label = 'Ластик';
      minValue = 5.0;
      maxValue = 30.0;
    } else if (widget.selectedTool == DrawingTool.pencil) {
      label = 'Карандаш';
      minValue = 1.0;
      maxValue = 10.0;
    } else if (widget.selectedTool == DrawingTool.marker) {
      label = 'Маркер';
      minValue = 3.0;
      maxValue = 20.0;
    } else if (widget.selectedTool == DrawingTool.text) {
      label = 'Шрифт';
      minValue = 8.0;
      maxValue = 48.0;
    }

    // Убедимся, что текущее значение находится в допустимом диапазоне
    double safeValue = widget.selectedTool == DrawingTool.text
        ? _currentFontSize
        : _currentThickness;

    if (safeValue < minValue) safeValue = minValue;
    if (safeValue > maxValue) safeValue = maxValue;

    return Container(
      width: 50,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Отображение текущего значения
          Container(
            padding: const EdgeInsets.all(4),
            child: Text(
              '$label\n${safeValue.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),

          // Индикатор толщины (визуальное представление)
          if (widget.selectedTool != DrawingTool.text)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: safeValue,
              height: safeValue,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
              ),
            ),

          // Вертикальный слайдер с оптимизированной шириной
          Expanded(
            child: RotatedBox(
              quarterTurns: 3, // Повернуть на 270 градусов (вверх)
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6, // Уменьшаем высоту трека
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8), // Уменьшаем размер ползунка
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16), // Уменьшаем размер оверлея
                ),
                child: Slider(
                  value: safeValue,
                  min: minValue,
                  max: maxValue,
                  divisions: ((maxValue - minValue) * 2).round(),
                  activeColor: Palette.orangeAccent,
                  inactiveColor: Colors.white30,
                  onChanged: (value) {
                    setState(() {
                      if (widget.selectedTool == DrawingTool.text) {
                        _currentFontSize = value;
                        widget.onFontSizeChanged(value);
                      } else {
                        _currentThickness = value;
                        widget.onThicknessChanged(value);
                      }
                    });
                  },
                ),
              ),
            ),
          ),

          // Кнопки "+" и "-" оптимизированы для экономии места
          SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    double newValue = safeValue - 1.0;
                    if (newValue < minValue) newValue = minValue;

                    setState(() {
                      if (widget.selectedTool == DrawingTool.text) {
                        _currentFontSize = newValue;
                        widget.onFontSizeChanged(newValue);
                      } else {
                        _currentThickness = newValue;
                        widget.onThicknessChanged(newValue);
                      }
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    child: const Icon(Icons.remove, color: Colors.white, size: 14),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    double newValue = safeValue + 1.0;
                    if (newValue > maxValue) newValue = maxValue;

                    setState(() {
                      if (widget.selectedTool == DrawingTool.text) {
                        _currentFontSize = newValue;
                        widget.onFontSizeChanged(newValue);
                      } else {
                        _currentThickness = newValue;
                        widget.onThicknessChanged(newValue);
                      }
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Сохраняем эти функции для совместимости со старым кодом
  Widget _buildThicknessSlider() {
    return Container(); // Пустой контейнер, т.к. используем вертикальный слайдер
  }

  Widget _buildFontSizeSlider() {
    return Container(); // Пустой контейнер, т.к. используем вертикальный слайдер
  }
}