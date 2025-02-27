// lib/src/ui/comic/canvas/tool_panel.dart
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
    _currentThickness = widget.currentThickness;
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
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDrawToolsTypeButton(
              context: context
          ),
          _buildToolButton(
            icon: Icons.text_fields,
            tool: DrawingTool.text,
            tooltip: 'Текст',
          ),
          _buildToolButton(
            icon: Icons.image,
            tool: DrawingTool.image,
            tooltip: 'Изображение',
          ),
          _buildToolButton(
            icon: Icons.select_all,
            tool: DrawingTool.selection,
            tooltip: 'Выбор',
          ),
          _buildToolButton(
            icon: Icons.pan_tool,
            tool: DrawingTool.hand,
            tooltip: 'Перемещение',
          ),
          _buildToolButton(
            icon: Icons.format_color_fill,
            tool: DrawingTool.fill,
            tooltip: 'Заливка',
          ),
          _buildToolButton(
            icon: Icons.cleaning_services,
            tool: DrawingTool.eraser,
            tooltip: 'Ластик',
          ),
          const VerticalDivider(color: Colors.white30, width: 16),
          _buildColorButton(context),
          const VerticalDivider(color: Colors.white30, width: 16),
          if (widget.selectedTool == DrawingTool.brush ||
              widget.selectedTool == DrawingTool.pencil ||
              widget.selectedTool == DrawingTool.marker ||
              widget.selectedTool == DrawingTool.eraser)
            _buildThicknessSlider(),
          if (widget.selectedTool == DrawingTool.text)
            _buildFontSizeSlider(),
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

  Widget _buildThicknessSlider() {
    String label = 'Толщина';
    if (widget.selectedTool == DrawingTool.eraser) {
      label = 'Размер ластика';
    } else if (widget.selectedTool == DrawingTool.pencil) {
      label = 'Толщина карандаша';
    } else if (widget.selectedTool == DrawingTool.marker) {
      label = 'Толщина маркера';
    }

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: Slider(
              value: _currentThickness,
              min: widget.selectedTool == DrawingTool.eraser ? 5 : 1,
              max: widget.selectedTool == DrawingTool.eraser ? 30 : 15,
              divisions: widget.selectedTool == DrawingTool.eraser ? 5 : 14,
              activeColor: Palette.orangeAccent,
              inactiveColor: Colors.white30,
              onChanged: (value) {
                setState(() {
                  _currentThickness = value;
                });
                widget.onThicknessChanged(value);
              },
            ),
          ),
          SizedBox(
            height: 12,
            child: Text(
              '$label: ${_currentThickness.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: Slider(
              value: _currentFontSize,
              min: 8,
              max: 48,
              divisions: 20,
              activeColor: Palette.orangeAccent,
              inactiveColor: Colors.white30,
              onChanged: (value) {
                setState(() {
                  _currentFontSize = value;
                });
                widget.onFontSizeChanged(value);
              },
            ),
          ),
          SizedBox(
            height: 12,
            child: Text(
              'Размер: ${_currentFontSize.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}