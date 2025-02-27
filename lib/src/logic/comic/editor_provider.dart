// lib/src/logic/comic/editor_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../ui/comic/canvas/canvas_controller.dart';
import '../../data/database/database_service.dart';

// Модель страницы
class Page {
  final int? id;
  final int? comicId;
  final int pageNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Cell> cells;

  Page({
    this.id,
    this.comicId,
    required this.pageNumber,
    this.createdAt,
    this.updatedAt,
    this.cells = const [],
  });

  factory Page.fromJson(Map<String, dynamic> json) {
    try {
      // Безопасный парсинг с проверкой на null
      return Page(
        id: json['id'],
        comicId: json['comic_id'],
        pageNumber: json['page_number'] ?? 1,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        cells: json['cells'] != null
            ? (json['cells'] as List)
            .map((cell) => Cell.fromJson(cell))
            .toList()
            : [],
      );
    } catch (e) {
      print("Ошибка при парсинге страницы: $e");
      // Возвращаем страницу-заглушку при ошибке
      return Page(
        id: 0,
        comicId: json['comic_id'] ?? 0,
        pageNumber: json['page_number'] ?? 1,
        cells: [],
      );
    }
  }

  // Преобразование в Map для сохранения в базу данных
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comic_id': comicId,
      'page_number': pageNumber,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cells': cells.map((cell) => cell.toJson()).toList(),
    };
  }
}

// Модель ячейки
class Cell {
  final int? id;
  final int pageId;
  final double positionX;
  final double positionY;
  final double width;
  final double height;
  final int zIndex;
  final String contentJson;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cell({
    this.id,
    required this.pageId,
    required this.positionX,
    required this.positionY,
    required this.width,
    required this.height,
    required this.zIndex,
    required this.contentJson,
    this.createdAt,
    this.updatedAt,
  });

  factory Cell.fromJson(Map<String, dynamic> json) {
    try {
      return Cell(
        id: json['id'],
        pageId: json['page_id'] ?? 0,
        positionX: (json['position_x'] != null) ? (json['position_x'] as num).toDouble() : 0.0,
        positionY: (json['position_y'] != null) ? (json['position_y'] as num).toDouble() : 0.0,
        width: (json['width'] != null) ? (json['width'] as num).toDouble() : 300.0,
        height: (json['height'] != null) ? (json['height'] as num).toDouble() : 200.0,
        zIndex: json['z_index'] ?? 1,
        contentJson: json['content_json'] ?? '{"elements":[]}',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
    } catch (e) {
      print("Ошибка при парсинге ячейки: $e");
      // Возвращаем ячейку-заглушку при ошибке
      return Cell(
        id: 0,
        pageId: json['page_id'] ?? 0,
        positionX: 0.0,
        positionY: 0.0,
        width: 300.0,
        height: 200.0,
        zIndex: 1,
        contentJson: '{"elements":[]}',
      );
    }
  }

  // Создание копии объекта с измененными полями
  Cell copyWith({
    int? id,
    int? pageId,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    int? zIndex,
    String? contentJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cell(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      contentJson: contentJson ?? this.contentJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Преобразование в Map для API запросов
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_id': pageId,
      'position_x': positionX,
      'position_y': positionY,
      'width': width,
      'height': height,
      'z_index': zIndex,
      'content_json': contentJson,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// Модель состояния редактора
class EditorState {
  final bool isLoading;
  final int comicId;
  final List<Page> pages;
  final int? currentPageId;
  final Cell? currentCell;
  final DrawingTool currentTool;
  final Color currentColor;
  final double currentThickness;
  final double currentFontSize;
  final bool canUndo;
  final bool canRedo;
  final String? errorMessage;

  EditorState({
    this.isLoading = false,
    this.comicId = 0,
    this.pages = const [],
    this.currentPageId,
    this.currentCell,
    this.currentTool = DrawingTool.brush,
    this.currentColor = Colors.black,
    this.currentThickness = 3.0,
    this.currentFontSize = 16.0,
    this.canUndo = false,
    this.canRedo = false,
    this.errorMessage,
  });

  // Создание копии объекта с измененными полями
  EditorState copyWith({
    bool? isLoading,
    int? comicId,
    List<Page>? pages,
    int? currentPageId,
    Cell? currentCell,
    DrawingTool? currentTool,
    Color? currentColor,
    double? currentThickness,
    double? currentFontSize,
    bool? canUndo,
    bool? canRedo,
    String? errorMessage,
  }) {
    return EditorState(
      isLoading: isLoading ?? this.isLoading,
      comicId: comicId ?? this.comicId,
      pages: pages ?? this.pages,
      currentPageId: currentPageId ?? this.currentPageId,
      currentCell: currentCell ?? this.currentCell,
      currentTool: currentTool ?? this.currentTool,
      currentColor: currentColor ?? this.currentColor,
      currentThickness: currentThickness ?? this.currentThickness,
      currentFontSize: currentFontSize ?? this.currentFontSize,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      errorMessage: errorMessage,
    );
  }

  // Получение текущей страницы
  Page? get currentPage {
    if (currentPageId == null) return null;
    try {
      return pages.firstWhere(
            (page) => page.id == currentPageId,
      );
    } catch (e) {
      return pages.isEmpty ? null : pages.first;
    }
  }

  // Создание нового чистого состояния
  static EditorState cleanState() {
    return EditorState(
      isLoading: false,
      comicId: 0,
      pages: const [],
      currentPageId: null,
      currentCell: null,
      currentTool: DrawingTool.brush,
      currentColor: Colors.black,
      currentThickness: 3.0,
      currentFontSize: 16.0,
      canUndo: false,
      canRedo: false,
      errorMessage: null,
    );
  }
}

// Провайдер для сброса состояния редактора
final resetEditorProvider = Provider<bool>((ref) => false);

// Провайдер и нотифаер для редактора комикса
final comicEditorProvider = StateNotifierProvider<ComicEditorNotifier, EditorState>((ref) {
  final notifier = ComicEditorNotifier(ref);

  // Слушаем провайдер сброса без прямого обращения к comicEditorProvider
  ref.listen<bool>(resetEditorProvider, (_, __) {
    notifier.resetState();
  });

  // Добавляем очистку при удалении провайдера
  ref.onDispose(() {
    notifier.resetState();
  });

  return notifier;
});

class ComicEditorNotifier extends StateNotifier<EditorState> {
  final DatabaseService _db = DatabaseService();
  final Ref _ref;

  // Для хранения истории состояний ячеек для undo/redo
  final Map<int, List<String>> _undoHistory = {};
  final Map<int, List<String>> _redoHistory = {};

  ComicEditorNotifier(this._ref) : super(EditorState());

  @override
  void resetState() {
    _saveDebounceTimer?.cancel();
    _undoHistory.clear();
    _redoHistory.clear();
    state = EditorState.cleanState();
    print("Состояние редактора полностью сброшено");
  }

  // Загрузка комикса и его страниц
  Future<void> loadComic(int comicId) async {
    print("Загрузка комикса с ID: $comicId");

    // Сначала сбрасываем состояние, чтобы избежать смешивания данных
    resetState();

    state = state.copyWith(isLoading: true, comicId: comicId, errorMessage: null);

    try {
      // Получаем все страницы комикса
      final pages = await _db.getPagesForComic(comicId);

      // Сортировка страниц по номеру
      pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      // Установка текущей страницы и ячейки
      int? currentPageId;
      Cell? currentCell;

      if (pages.isNotEmpty) {
        currentPageId = pages.first.id;

        if (pages.first.cells.isNotEmpty) {
          currentCell = pages.first.cells.first;
        }
      }

      state = state.copyWith(
        isLoading: false,
        pages: pages,
        currentPageId: currentPageId,
        currentCell: currentCell,
        errorMessage: null,
      );
      print("Комикс загружен успешно. Страниц: ${pages.length}");
    } catch (e) {
      print("ОШИБКА при загрузке комикса: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка загрузки комикса: ${e.toString()}',
      );
    }
  }

  // Добавление новой страницы
  Future<void> addPage() async {
    print("Добавление страницы для комикса ${state.comicId}");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Находим свободный номер страницы
      int pageNumber = 1;
      final existingPages = state.pages;
      if (existingPages.isNotEmpty) {
        final maxPageNumber = existingPages.map((page) => page.pageNumber).reduce((a, b) => a > b ? a : b);
        pageNumber = maxPageNumber + 1;
      }

      // Создаем новую страницу в БД
      final pageId = await _db.createPage(state.comicId, pageNumber);

      // Создаем новую страницу для добавления в состояние
      final newPage = Page(
        id: pageId,
        comicId: state.comicId,
        pageNumber: pageNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cells: [],
      );

      // Обновляем список страниц
      final updatedPages = [...state.pages, newPage];
      updatedPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      state = state.copyWith(
        isLoading: false,
        pages: updatedPages,
        currentPageId: newPage.id,
        currentCell: null,
        errorMessage: null,
      );

      print("Страница создана успешно с ID: $pageId");
    } catch (e) {
      print("ОШИБКА при добавлении страницы: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка добавления страницы: ${e.toString()}',
      );
    }
  }

  // Удаление страницы
  Future<void> deletePage(int pageId) async {
    print("Удаление страницы с ID: $pageId");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Удаляем страницу из БД
      final success = await _db.deletePage(pageId);

      if (success) {
        // Получаем обновленный список страниц без удаленной
        final updatedPages = state.pages.where((page) => page.id != pageId).toList();

        // Выбираем новую текущую страницу и ячейку, если текущая была удалена
        int? newCurrentPageId = state.currentPageId;
        Cell? newCurrentCell = state.currentCell;

        if (state.currentPageId == pageId) {
          if (updatedPages.isNotEmpty) {
            newCurrentPageId = updatedPages.first.id;
            if (updatedPages.first.cells.isNotEmpty) {
              newCurrentCell = updatedPages.first.cells.first;
            } else {
              newCurrentCell = null;
            }
          } else {
            newCurrentPageId = null;
            newCurrentCell = null;
          }
        }

        state = state.copyWith(
          isLoading: false,
          pages: updatedPages,
          currentPageId: newCurrentPageId,
          currentCell: newCurrentCell,
          errorMessage: null,
        );

        print("Страница удалена успешно");
      } else {
        throw Exception("Не удалось удалить страницу");
      }
    } catch (e) {
      print("ОШИБКА при удалении страницы: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка удаления страницы: ${e.toString()}',
      );
    }
  }

  // Установка текущей страницы
  Future<void> setCurrentPage(int pageId) async {
    print("Установка текущей страницы: $pageId");

    // Сначала сохраняем текущую ячейку перед переключением страницы
    if (state.currentCell != null) {
      await saveCurrentCell();
    }

    try {
      // Находим страницу в списке страниц
      final page = state.pages.firstWhere(
            (page) => page.id == pageId,
      );

      // Получаем ячейки для этой страницы из БД
      final cells = await _db.getCellsForPage(pageId);

      // Сортируем ячейки по z-index
      cells.sort((a, b) => a.zIndex.compareTo(b.zIndex));

      // Выбираем первую ячейку, если они есть
      Cell? currentCell;
      bool canUndo = false;
      bool canRedo = false;

      if (cells.isNotEmpty) {
        currentCell = cells.first;
        print("Установлена текущая ячейка: ${currentCell.id}");

        // Проверяем, можно ли делать undo/redo для этой ячейки
        if (currentCell.contentJson.isNotEmpty && currentCell.contentJson != '{"elements":[]}') {
          // Проверяем, есть ли история для этой ячейки
          canUndo = _undoHistory[currentCell.id]?.isNotEmpty ?? false;
          canRedo = _redoHistory[currentCell.id]?.isNotEmpty ?? false;
        }
      } else {
        print("Страница не содержит ячеек");
      }

      // Обновляем страницу в списке
      final updatedPages = state.pages.map((p) {
        if (p.id == pageId) {
          // Создаем новую страницу с обновленным списком ячеек
          return Page(
            id: p.id,
            comicId: p.comicId,
            pageNumber: p.pageNumber,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
            cells: cells,
          );
        }
        return p;
      }).toList();

      state = state.copyWith(
        currentPageId: pageId,
        currentCell: currentCell,
        pages: updatedPages,
        canUndo: canUndo,
        canRedo: canRedo,
        errorMessage: null,
      );

      print("Текущая страница установлена: pageId=$pageId, ячеек=${cells.length}, текущая ячейка=${currentCell?.id}");
    } catch (e) {
      print("Ошибка при установке текущей страницы: $e");
      state = state.copyWith(
        errorMessage: 'Ошибка при выборе страницы: ${e.toString()}',
      );
    }
  }

  // Добавление новой ячейки
  Future<void> addCell() async {
    if (state.currentPageId == null) {
      print("Нет текущей страницы, создаем новую");
      await addPage();
      return;
    }

    print("Добавление ячейки на страницу ${state.currentPageId}");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Создаем новую ячейку в БД с уникальным ID
      final cellId = await _db.createCell(
          state.currentPageId!,
          50, // position_x
          50, // position_y
          300, // width
          200  // height
      );

      // Получаем информацию о созданной ячейке
      final cells = await _db.getCellsForPage(state.currentPageId!);
      final newCell = cells.firstWhere((cell) => cell.id == cellId);

      // Обновляем текущую страницу
      final updatedPages = state.pages.map((page) {
        if (page.id == state.currentPageId) {
          return Page(
            id: page.id,
            comicId: page.comicId,
            pageNumber: page.pageNumber,
            createdAt: page.createdAt,
            updatedAt: page.updatedAt,
            cells: [...page.cells, newCell],
          );
        }
        return page;
      }).toList();

      // Инициализируем историю для новой ячейки
      _undoHistory[cellId] = [];
      _redoHistory[cellId] = [];

      state = state.copyWith(
        isLoading: false,
        pages: updatedPages,
        currentCell: newCell,
        errorMessage: null,
      );
      print("Ячейка создана успешно с ID: $cellId");
    } catch (e) {
      print("ОШИБКА при добавлении ячейки: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка добавления ячейки: ${e.toString()}',
      );
    }
  }

  // Удаление ячейки
  Future<void> deleteCell(int cellId) async {
    print("Удаление ячейки с ID: $cellId");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Удаляем ячейку из БД
      final success = await _db.deleteCell(cellId);

      if (success) {
        // Очищаем историю для этой ячейки
        _undoHistory.remove(cellId);
        _redoHistory.remove(cellId);

        // Обновляем текущую страницу
        final updatedPages = state.pages.map((page) {
          if (page.id == state.currentPageId) {
            final updatedCells = page.cells.where((cell) => cell.id != cellId).toList();
            return Page(
              id: page.id,
              comicId: page.comicId,
              pageNumber: page.pageNumber,
              createdAt: page.createdAt,
              updatedAt: page.updatedAt,
              cells: updatedCells,
            );
          }
          return page;
        }).toList();

        // Выбираем новую текущую ячейку, если текущая была удалена
        Cell? newCurrentCell = state.currentCell;
        if (state.currentCell?.id == cellId) {
          final currentPage = updatedPages.firstWhere(
                (page) => page.id == state.currentPageId,
            orElse: () => Page(pageNumber: 0, cells: []),
          );

          if (currentPage.cells.isNotEmpty) {
            newCurrentCell = currentPage.cells.first;
          } else {
            newCurrentCell = null;
          }
        }

        state = state.copyWith(
          isLoading: false,
          pages: updatedPages,
          currentCell: newCurrentCell,
          errorMessage: null,
        );

        print("Ячейка удалена успешно");
      } else {
        throw Exception("Не удалось удалить ячейку");
      }
    } catch (e) {
      print("ОШИБКА при удалении ячейки: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка удаления ячейки: ${e.toString()}',
      );
    }
  }

  Timer? _saveDebounceTimer;

  // Обновление содержимого текущей ячейки
  void updateCurrentCellContent(CellContent content, [CellContent? previousContent]) {
    if (state.currentCell == null) {
      print("Нет текущей ячейки для обновления");
      return;
    }

    // Флаг для определения, нужно ли сохранить историю
    bool shouldSaveForHistory = previousContent != null;

    final updatedCell = state.currentCell!.copyWith(
      contentJson: content.toJsonString(),
    );

    // Обновление ячейки в списке
    final updatedPages = state.pages.map((page) {
      if (page.id == state.currentPageId) {
        final updatedCells = page.cells.map((cell) {
          if (cell.id == updatedCell.id) {
            return updatedCell;
          }
          return cell;
        }).toList();

        return Page(
          id: page.id,
          comicId: page.comicId,
          pageNumber: page.pageNumber,
          createdAt: page.createdAt,
          updatedAt: page.updatedAt,
          cells: updatedCells,
        );
      }
      return page;
    }).toList();

    // Проверяем, есть ли содержимое в ячейке
    bool hasContent = content.elements.isNotEmpty;

    state = state.copyWith(
      pages: updatedPages,
      currentCell: updatedCell,
      canUndo: hasContent || (_undoHistory[updatedCell.id]?.isNotEmpty ?? false),
      canRedo: state.canRedo,
    );

    // Если передано предыдущее состояние, сохраняем его в историю
    if (shouldSaveForHistory && previousContent != null) {
      print("Сохраняем предыдущее состояние для истории");

      // Добавляем предыдущее состояние в историю undo
      if (!_undoHistory.containsKey(updatedCell.id!)) {
        _undoHistory[updatedCell.id!] = [];
      }
      _undoHistory[updatedCell.id!]!.add(previousContent.toJsonString());

      // Очищаем историю redo при новом действии
      _redoHistory[updatedCell.id!] = [];

      // Сохраняем ячейку без дебаунсинга для точного сохранения истории
      saveCurrentCell(showLoading: false);
    } else {
      // Если это просто обновление без явных действий пользователя, используем стандартное сохранение с дебаунсингом
      _debouncedSave();
    }
  }

  // Модифицированный метод _debouncedSave()
  void _debouncedSave() {
    // Отменяем предыдущий таймер, если он активен
    if (_saveDebounceTimer?.isActive ?? false) {
      _saveDebounceTimer!.cancel();
    }

    // Создаем новый таймер
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      print("Автоматическое сохранение после изменения контента");
      // Вызываем сохранение БЕЗ показа индикатора загрузки
      saveCurrentCell(showLoading: false);
    });
  }

  // Не забудьте отменить таймер при сбросе состояния
  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }

  // Сохранение текущей ячейки
  Future<bool> saveCurrentCell({bool showLoading = true}) async {
    if (state.currentCell == null) {
      print("Нет текущей ячейки для сохранения");
      return false;
    }

    print("Сохранение ячейки: ${state.currentCell!.id}");

    // Показываем индикатор загрузки только если явно запрошено
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      // Обновляем ячейку в базе данных
      await _db.updateCell(state.currentCell!);

      // Обновление статусов undo/redo
      bool canUndo = (_undoHistory[state.currentCell!.id!]?.isNotEmpty ?? false);
      bool canRedo = (_redoHistory[state.currentCell!.id!]?.isNotEmpty ?? false);

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        canUndo: canUndo,
        canRedo: canRedo,
      );

      print("Ячейка сохранена успешно");
      return true;
    } catch (e) {
      print("ОШИБКА при сохранении ячейки: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка сохранения ячейки: ${e.toString()}',
      );
      return false;
    }
  }

  // Функция отмены последнего действия (Undo)
  Future<void> undo() async {
    if (state.currentCell == null) {
      print("Нет текущей ячейки для отмены действия");
      return;
    }

    final cellId = state.currentCell!.id!;
    if (!_undoHistory.containsKey(cellId) || _undoHistory[cellId]!.isEmpty) {
      print("Нет истории для отмены");
      return;
    }

    print("Отмена последнего действия для ячейки: $cellId");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Получаем последнее состояние из истории
      final previousContentJson = _undoHistory[cellId]!.removeLast();

      // Сохраняем текущее состояние для возможности redo
      if (!_redoHistory.containsKey(cellId)) {
        _redoHistory[cellId] = [];
      }
      _redoHistory[cellId]!.add(state.currentCell!.contentJson);

      // Создаем обновленную ячейку с предыдущим состоянием
      final updatedCell = state.currentCell!.copyWith(
        contentJson: previousContentJson,
      );

      // Обновляем ячейку в базе данных
      await _db.updateCell(updatedCell);

      // Обновляем ячейку в состоянии
      final updatedPages = state.pages.map((page) {
        if (page.id == state.currentPageId) {
          final updatedCells = page.cells.map((cell) {
            if (cell.id == cellId) {
              return updatedCell;
            }
            return cell;
          }).toList();

          return Page(
            id: page.id,
            comicId: page.comicId,
            pageNumber: page.pageNumber,
            createdAt: page.createdAt,
            updatedAt: page.updatedAt,
            cells: updatedCells,
          );
        }
        return page;
      }).toList();

      // Обновляем статусы undo/redo
      bool canUndo = _undoHistory[cellId]!.isNotEmpty;
      bool canRedo = _redoHistory[cellId]!.isNotEmpty;

      state = state.copyWith(
        isLoading: false,
        pages: updatedPages,
        currentCell: updatedCell,
        canUndo: canUndo,
        canRedo: canRedo,
        errorMessage: null,
      );

      print("Действие отменено успешно");
    } catch (e) {
      print("ОШИБКА при отмене действия: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка отмены действия: ${e.toString()}',
      );
    }
  }

  // Функция повтора отмененного действия (Redo)
  Future<void> redo() async {
    if (state.currentCell == null) {
      print("Нет текущей ячейки для повтора действия");
      return;
    }

    final cellId = state.currentCell!.id!;
    if (!_redoHistory.containsKey(cellId) || _redoHistory[cellId]!.isEmpty) {
      print("Нет истории для повтора");
      return;
    }

    print("Повтор действия для ячейки: $cellId");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Получаем последнее состояние из истории redo
      final nextContentJson = _redoHistory[cellId]!.removeLast();

      // Сохраняем текущее состояние для возможности undo
      if (!_undoHistory.containsKey(cellId)) {
        _undoHistory[cellId] = [];
      }
      _undoHistory[cellId]!.add(state.currentCell!.contentJson);

      // Создаем обновленную ячейку с новым состоянием
      final updatedCell = state.currentCell!.copyWith(
        contentJson: nextContentJson,
      );

      // Обновляем ячейку в базе данных
      await _db.updateCell(updatedCell);

      // Обновляем ячейку в состоянии
      final updatedPages = state.pages.map((page) {
        if (page.id == state.currentPageId) {
          final updatedCells = page.cells.map((cell) {
            if (cell.id == cellId) {
              return updatedCell;
            }
            return cell;
          }).toList();

          return Page(
            id: page.id,
            comicId: page.comicId,
            pageNumber: page.pageNumber,
            createdAt: page.createdAt,
            updatedAt: page.updatedAt,
            cells: updatedCells,
          );
        }
        return page;
      }).toList();

      // Обновляем статусы undo/redo
      bool canUndo = _undoHistory[cellId]!.isNotEmpty;
      bool canRedo = _redoHistory[cellId]!.isNotEmpty;

      state = state.copyWith(
        isLoading: false,
        pages: updatedPages,
        currentCell: updatedCell,
        canUndo: canUndo,
        canRedo: canRedo,
        errorMessage: null,
      );

      print("Действие повторено успешно");
    } catch (e) {
      print("ОШИБКА при повторе действия: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка повтора действия: ${e.toString()}',
      );
    }
  }

  // Добавление текста на холст
  Future<void> addText() async {
    print("Запрос на добавление текста");
    if (state.currentCell == null) {
      print("Нет текущей ячейки, создаем новую");
      await addCell();
    }
    // Эта функция будет вызываться из UI
    // Логика добавления текста находится в CanvasController
  }

  // Загрузка и добавление изображения
  Future<void> addImage() async {
    print("Запрос на добавление изображения");
    if (state.currentCell == null) {
      print("Нет текущей ячейки, создаем новую");
      await addCell();
    }

    try {
      // Выбор изображения из галереи
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        print("Изображение выбрано: ${pickedFile.path}");

        // Сохраняем изображение в локальную директорию приложения
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await imageFile.copy('${appDir.path}/$fileName');

        print("Изображение сохранено локально: ${savedImage.path}");

        // Здесь логика добавления изображения в ячейку обрабатывается в UI
      } else {
        print("Пользователь не выбрал изображение");
      }
    } catch (e) {
      print("ОШИБКА при загрузке изображения: $e");
      state = state.copyWith(
        errorMessage: 'Ошибка загрузки изображения: ${e.toString()}',
      );
    }
  }

  // Установка текущего инструмента
  void setCurrentTool(DrawingTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  // Установка текущего цвета
  void setCurrentColor(Color color) {
    state = state.copyWith(currentColor: color);
  }

  // Установка текущей толщины линии
  void setCurrentThickness(double thickness) {
    state = state.copyWith(currentThickness: thickness);
  }

  // Установка текущего размера шрифта
  void setCurrentFontSize(double fontSize) {
    state = state.copyWith(currentFontSize: fontSize);
  }
}