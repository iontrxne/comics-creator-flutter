import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../ui/comic/canvas/canvas_controller.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../../../config/environment.dart';

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
      'position_x': positionX,
      'position_y': positionY,
      'width': width,
      'height': height,
      'z_index': zIndex,
      'content_json': contentJson,
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
      return pages.isEmpty ?
      null :
      pages.first;
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
  final Dio _dio = Dio();
  final Ref _ref;

  ComicEditorNotifier(this._ref) : super(EditorState()) {
    _initDio();
  }

  // Инициализация Dio с правильной обработкой URL
  void _initDio() {
    String baseUrl = Environment.API_URL;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    _dio.options.baseUrl = baseUrl;
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 5;
    _dio.options.validateStatus = (status) {
      return status! < 500; // Принимать коды ответа до 500
    };

    // Добавляем интерцептор для обеспечения наличия слеша в конце URL
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Убеждаемся, что URL заканчивается на "/", если это не запрос на загрузку файла
        if (!options.path.endsWith('/') && !options.path.contains('upload')) {
          options.path = "${options.path}/";
        }
        print("Отправка запроса: ${options.method} ${options.baseUrl}${options.path}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print("Получен ответ: ${response.statusCode} от ${response.requestOptions.path}");
        return handler.next(response);
      },
      onError: (error, handler) {
        print("Ошибка запроса: ${error.response?.statusCode} ${error.message} от ${error.requestOptions.path}");
        return handler.next(error);
      },
    ));
  }

  @override
  void resetState() {
    _saveDebounceTimer?.cancel();
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
      // Получение полной структуры комикса
      final response = await _dio.get('/comics/$comicId/full/');
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        // Преобразуем Map<dynamic, dynamic> в Map<String, dynamic>
        final Map<String, dynamic> comicData = Map<String, dynamic>.from(response.data);
        print("Получены данные комикса: ${comicData['title']}");

        // Обработка страниц
        final List<Page> pages = [];
        if (comicData['pages'] != null && comicData['pages'] is List) {
          for (var rawPageData in comicData['pages']) {
            try {
              // Преобразуем Map<dynamic, dynamic> в Map<String, dynamic>
              final Map<String, dynamic> pageData = Map<String, dynamic>.from(rawPageData);
              final page = Page.fromJson(pageData);
              // Добавляем только страницы с корректным ID
              if (page.id != null && page.id! > 0) {
                pages.add(page);
              }
            } catch (e) {
              print("Ошибка при парсинге страницы: $e");
            }
          }
        }

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
      } else {
        throw Exception("Ошибка загрузки комикса: ${response.statusCode}");
      }
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
    print("Попытка добавить страницу для комикса ${state.comicId}");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Получим список всех страниц комикса с сервера
      final pagesResponse = await _dio.get('/comics/${state.comicId}/pages/');

      // Парсим страницы из ответа
      List<Page> serverPages = [];
      if (pagesResponse.statusCode! >= 200 && pagesResponse.statusCode! < 300 && pagesResponse.data is List) {
        for (var rawPageData in pagesResponse.data) {
          try {
            // Преобразуем Map<dynamic, dynamic> в Map<String, dynamic>
            final Map<String, dynamic> pageData = Map<String, dynamic>.from(rawPageData);
            final page = Page.fromJson(pageData);
            if (page.id != null && page.id! > 0) {
              serverPages.add(page);
            }
          } catch (e) {
            print("Ошибка при парсинге страницы из ответа: $e");
          }
        }
      }

      // Если нашли страницы на сервере, которых нет в нашем state
      if (serverPages.isNotEmpty) {
        // Найдем страницы, которых нет в нашем состоянии
        List<Page> newPages = [];
        for (var serverPage in serverPages) {
          bool found = false;
          for (var localPage in state.pages) {
            if (localPage.id == serverPage.id) {
              found = true;
              break;
            }
          }
          if (!found) {
            newPages.add(serverPage);
          }
        }

        // Если нашли новые страницы, обновим состояние
        if (newPages.isNotEmpty) {
          final updatedPages = [...state.pages, ...newPages];
          updatedPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

          // Устанавливаем первую новую страницу как текущую
          final newPage = newPages.first;

          // Получим ячейки страницы
          final cellsResponse = await _dio.get('/pages/${newPage.id}/cells/');
          List<Cell> cells = [];

          if (cellsResponse.statusCode! >= 200 && cellsResponse.statusCode! < 300 && cellsResponse.data is List) {
            for (var rawCellData in cellsResponse.data) {
              try {
                // Преобразуем Map<dynamic, dynamic> в Map<String, dynamic>
                final Map<String, dynamic> cellData = Map<String, dynamic>.from(rawCellData);
                cells.add(Cell.fromJson(cellData));
              } catch (e) {
                print("Ошибка при парсинге ячейки: $e");
              }
            }
          }

          // Устанавливаем текущую ячейку, если они есть
          Cell? currentCell;
          if (cells.isNotEmpty) {
            currentCell = cells.first;
          }

          state = state.copyWith(
            isLoading: false,
            pages: updatedPages,
            currentPageId: newPage.id,
            currentCell: currentCell,
            errorMessage: null,
          );

          print("Найдены существующие страницы на сервере. Обновлено состояние.");
          return;
        }
      }

      // Если не нашли существующие страницы, создаем новую
      // Найдем существующие номера страниц из локального состояния и с сервера
      Set<int> existingPageNumbers = {};
      for (var page in [...state.pages, ...serverPages]) {
        existingPageNumbers.add(page.pageNumber);
      }

      // Ищем первый доступный номер страницы, которого еще нет
      int pageNumber = 1;
      while (existingPageNumbers.contains(pageNumber)) {
        pageNumber++;
      }

      print("Создаем страницу с номером: $pageNumber");

      // Создание страницы на сервере
      final response = await _dio.post(
        '/comics/${state.comicId}/pages/',
        data: jsonEncode({'page_number': pageNumber}),
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      print("Ответ сервера: ${response.data}");

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final pageId = response.data['page_id'];

        // Получение созданной страницы
        final pageResponse = await _dio.get('/pages/$pageId/');
        final newPage = Page.fromJson(pageResponse.data);

        // Обновление списка страниц
        final updatedPages = [...state.pages, newPage];

        state = state.copyWith(
          isLoading: false,
          pages: updatedPages,
          currentPageId: newPage.id,
          currentCell: null,
          errorMessage: null,
        );
        print("Страница создана успешно с ID: $pageId");
      } else {
        // Если получили 500 с сообщением о дублировании страницы
        if (response.statusCode == 500 &&
            response.data is Map<dynamic, dynamic> &&
            response.data['error'] != null) {
          String errorMsg = response.data['error'].toString();
          if (errorMsg.contains('страница с таким номером уже существует')) {

            // Попробуем получить все страницы комикса и установить найденную
            await _reloadAndSetExistingPage(pageNumber);
          }
        } else {
          throw Exception("Ошибка создания страницы: ${response.statusCode} ${response.data}");
        }
      }
    } catch (e) {
      print("ОШИБКА при добавлении страницы: $e");
      String errorMsg = 'Ошибка добавления страницы: ${e.toString()}';

      if (e is DioException) {
        print("Статус код: ${e.response?.statusCode}");
        print("Данные ответа: ${e.response?.data}");

        if (e.response?.statusCode == 307) {
          errorMsg = 'Ошибка перенаправления. Проверьте настройки URL в приложении.';
        } else if (e.response?.statusCode == 500) {
          // Если ошибка связана с существующей страницей
          if (e.response?.data is Map<dynamic, dynamic> &&
              e.response?.data['error'] != null) {
            String errorMsg = e.response?.data['error'].toString() ?? '';
            if (errorMsg.contains('страница с таким номером уже существует')) {

              // Извлекаем номер страницы из текущей попытки создания
              int pageNumber = 1;
              try {
                if (e.requestOptions.data is String) {
                  final requestData = jsonDecode(e.requestOptions.data);
                  if (requestData is Map && requestData['page_number'] != null) {
                    pageNumber = requestData['page_number'];
                  }
                }
              } catch (_) {}

              // Пробуем получить существующую страницу
              _reloadAndSetExistingPage(pageNumber);
              return;
            }
          } else {
            errorMsg = 'Ошибка сервера: ${e.response?.data is Map ? (e.response?.data['error'] ?? "Неизвестная ошибка") : "Неизвестная ошибка"}';
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    }
  }

  // Метод для загрузки и установки существующей страницы
  Future<void> _reloadAndSetExistingPage(int pageNumber) async {
    try {
      print("Пытаемся найти существующую страницу с номером $pageNumber");

      // Получаем список всех страниц комикса
      final response = await _dio.get('/comics/${state.comicId}/pages/');

      if (response.statusCode! >= 200 && response.statusCode! < 300 && response.data is List) {
        // Ищем страницу с нужным номером
        for (var pageData in response.data) {
          if (pageData is Map<dynamic, dynamic> && pageData['page_number'] == pageNumber) {
            // Преобразуем Map<dynamic, dynamic> в Map<String, dynamic>
            final Map<String, dynamic> typedPageData = Map<String, dynamic>.from(pageData);
            final existingPage = Page.fromJson(typedPageData);

            // Получаем ячейки для этой страницы
            final cellsResponse = await _dio.get('/pages/${existingPage.id}/cells/');
            List<Cell> cells = [];

            if (cellsResponse.statusCode! >= 200 && cellsResponse.statusCode! < 300 &&
                cellsResponse.data is List) {
              for (var rawCellData in cellsResponse.data) {
                try {
                  // Преобразуем Map<dynamic, dynamic> в Map<String, dynamic>
                  final Map<String, dynamic> cellData = Map<String, dynamic>.from(rawCellData);
                  cells.add(Cell.fromJson(cellData));
                } catch (e) {
                  print("Ошибка при парсинге ячейки: $e");
                }
              }
            }

            // Обновляем состояние
            final updatedPages = [...state.pages];
            bool pageExists = false;

            // Проверяем, есть ли уже такая страница в списке
            for (int i = 0; i < updatedPages.length; i++) {
              if (updatedPages[i].id == existingPage.id) {
                updatedPages[i] = existingPage;
                pageExists = true;
                break;
              }
            }

            // Если страницы нет в списке, добавляем её
            if (!pageExists) {
              updatedPages.add(existingPage);
            }

            // Сортируем страницы
            updatedPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

            // Выбираем первую ячейку, если они есть
            Cell? currentCell;
            if (cells.isNotEmpty) {
              currentCell = cells.first;
            }

            state = state.copyWith(
              isLoading: false,
              pages: updatedPages,
              currentPageId: existingPage.id,
              currentCell: currentCell,
              errorMessage: null,
            );

            print("Найдена и установлена существующая страница с ID: ${existingPage.id}");
            return;
          }
        }
      }

      // Если страница не найдена
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Не удалось найти страницу с номером $pageNumber',
      );
    } catch (e) {
      print("ОШИБКА при поиске существующей страницы: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка при поиске существующей страницы: ${e.toString()}',
      );
    }
  }

  // Установка текущей страницы
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

      // Получение ячеек для этой страницы с сервера, чтобы быть уверенным, что используем актуальные данные
      final cellsResponse = await _dio.get('/pages/$pageId/cells/');
      List<Cell> cells = [];

      if (cellsResponse.statusCode! >= 200 && cellsResponse.statusCode! < 300 &&
          cellsResponse.data is List) {
        for (var rawCellData in cellsResponse.data) {
          try {
            // Преобразуем Map<dynamic, dynamic> в Map<String, dynamic>
            final Map<String, dynamic> cellData = Map<String, dynamic>.from(rawCellData);
            cells.add(Cell.fromJson(cellData));
          } catch (e) {
            print("Ошибка при парсинге ячейки: $e");
          }
        }
      }

      // Сортируем ячейки по z-index
      cells.sort((a, b) => a.zIndex.compareTo(b.zIndex));

      // Выбираем первую ячейку, если они есть
      Cell? currentCell;
      bool canUndo = false;
      bool canRedo = false;

      if (cells.isNotEmpty) {
        currentCell = cells.first;
        print("Установлена текущая ячейка: ${currentCell.id}");

        // ИСПРАВЛЕНИЕ: Проверяем, можно ли делать undo/redo для этой ячейки
        if (currentCell.contentJson.isNotEmpty &&
            currentCell.contentJson != '{"elements":[]}') {
          canUndo = true;
          // Возможно также нужно проверить наличие истории redo,
          // но для простоты оставляем false
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
      // Создание новой ячейки на сервере
      final response = await _dio.post(
        '/pages/${state.currentPageId}/cells/',
        data: jsonEncode({
          'position_x': 50,
          'position_y': 50,
          'width': 300,  // Увеличил размер по умолчанию
          'height': 200,
          'z_index': 1,
          'content_json': '{"elements":[]}'
        }),
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      print("Ответ сервера: ${response.data}");

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final cellId = response.data['cell_id'];

        // Получение созданной ячейки
        final cellResponse = await _dio.get('/cells/$cellId/');
        final newCell = Cell.fromJson(cellResponse.data);

        // Обновление текущей страницы
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

        state = state.copyWith(
          isLoading: false,
          pages: updatedPages,
          currentCell: newCell,
          errorMessage: null,
        );
        print("Ячейка создана успешно с ID: $cellId");
      } else {
        throw Exception("Ошибка создания ячейки: ${response.statusCode} ${response.data}");
      }
    } catch (e) {
      print("ОШИБКА при добавлении ячейки: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка добавления ячейки: ${e.toString()}',
      );
    }
  }
  Timer? _saveDebounceTimer;
  // Исправленный метод updateCurrentCellContent()
  void updateCurrentCellContent(CellContent content) {
    if (state.currentCell == null) {
      print("Нет текущей ячейки для обновления");
      return;
    }

    // Получаем текущее содержимое
    CellContent? oldContent;
    try {
      oldContent = CellContent.fromJsonString(state.currentCell!.contentJson);
    } catch (e) {
      print("Ошибка при парсинге текущего содержимого: $e");
    }

    // Проверяем, изменилось ли содержимое
    bool contentChanged = true;
    if (oldContent != null) {
      // Проверяем изменения путем сравнения количества элементов
      contentChanged = oldContent.elements.length != content.elements.length;
    }

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
      canUndo: hasContent,  // Можно отменить только если есть содержимое
      canRedo: state.canRedo,
    );

    // Если содержимое изменилось, автоматически сохраняем ячейку с дебаунсингом
    if (contentChanged) {
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

  // Исправленный метод saveCurrentCell()
  // Модифицированный метод saveCurrentCell()
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
      // Получаем базовый URL без слеша в конце
      String baseUrl = Environment.API_URL;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      String domain = baseUrl.split('/').sublist(0, 3).join('/');

      // Формируем URL точно в том формате, который требует сервер (БЕЗ слеша в конце)
      final String url = "$baseUrl/cells/${state.currentCell!.id}";
      print("Отправка запроса на URL (без слеша в конце): $url");

      // Подготавливаем данные для отправки
      final Map<String, dynamic> cellData = {
        'position_x': state.currentCell!.positionX,
        'position_y': state.currentCell!.positionY,
        'width': state.currentCell!.width,
        'height': state.currentCell!.height,
        'z_index': state.currentCell!.zIndex,
        'content_json': state.currentCell!.contentJson,
      };

      // Создаем HTTP клиент напрямую, чтобы избежать проблем с Dio и перенаправлениями
      final client = http.Client();

      try {
        // Используем HTTP напрямую без библиотек с автоматическим перенаправлением
        final response = await client.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(cellData),
        );

        print("Получен ответ: ${response.statusCode}");
        print("Заголовки ответа: ${response.headers}");

        // Проверяем статус ответа
        if (response.statusCode >= 200 && response.statusCode < 300) {
          print("Ячейка сохранена успешно: ${response.statusCode}");

          // Запрашиваем обновленную ячейку с сервера
          await _refreshCurrentCell();

          // ИСПРАВЛЕНИЕ: устанавливаем флаги canUndo и canRedo в true
          // после успешного сохранения ячейки, так как теперь есть история изменений
          state = state.copyWith(
            isLoading: false,
            errorMessage: null,
            canUndo: true,  // Устанавливаем возможность отмены
            canRedo: false, // Redo пока не доступен, так как мы только что сохранили
          );

          return true;
        }
        // Если это не успешный ответ, но и не перенаправление
        else if (response.statusCode != 301 && response.statusCode != 302 &&
            response.statusCode != 307 && response.statusCode != 308) {
          throw Exception("Ошибка сохранения ячейки: ${response.statusCode}, ${response.body}");
        }
        // Обрабатываем перенаправление только один раз
        else {
          final String? redirectUrl = response.headers['location'];
          print("Получено перенаправление на: $redirectUrl");

          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            // Важно! Не добавляем слеш в конце, если его нет в заголовке Location
            String fullRedirectUrl;

            if (redirectUrl.startsWith('http')) {
              // Абсолютный URL
              fullRedirectUrl = redirectUrl;
            } else {
              // Относительный URL
              String cleanRedirectUrl = redirectUrl.startsWith('/')
                  ? redirectUrl.substring(1)
                  : redirectUrl;
              fullRedirectUrl = "$domain/$cleanRedirectUrl";
            }

            print("Отправка запроса на перенаправленный URL: $fullRedirectUrl");

            // Выполняем запрос по URL перенаправления без модификаций
            final redirectResponse = await client.put(
              Uri.parse(fullRedirectUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(cellData),
            );

            print("Получен ответ после перенаправления: ${redirectResponse.statusCode}");

            if (redirectResponse.statusCode >= 200 && redirectResponse.statusCode < 300) {
              print("Ячейка сохранена успешно после перенаправления: ${redirectResponse.statusCode}");

              // Запрашиваем обновленную ячейку с сервера
              await _refreshCurrentCell();

              // ИСПРАВЛЕНИЕ: устанавливаем флаги canUndo и canRedo в true
              // после успешного сохранения ячейки
              state = state.copyWith(
                isLoading: false,
                errorMessage: null,
                canUndo: true,  // Устанавливаем возможность отмены
                canRedo: false, // Redo пока не доступен, так как мы только что сохранили
              );

              return true;
            } else {
              throw Exception("Ошибка сохранения ячейки после перенаправления: ${redirectResponse.statusCode}, ${redirectResponse.body}");
            }
          }
        }

        throw Exception("Неожиданное поведение при сохранении ячейки");
      } finally {
        // Закрываем HTTP клиент
        client.close();
      }
    } catch (e) {
      print("ОШИБКА при сохранении ячейки: $e");
      state = state.copyWith(
        isLoading: false,  // Всегда сбрасываем статус загрузки
        errorMessage: 'Ошибка сохранения ячейки: ${e.toString()}',
      );
      return false;
    }
  }

  // Обновление текущей ячейки с сервера
  Future<void> _refreshCurrentCell() async {
    if (state.currentCell == null) return;

    try {
      // Получаем базовый URL без слеша в конце
      String baseUrl = Environment.API_URL;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      // Получаем только домен
      String domain = baseUrl.split('/').sublist(0, 3).join('/');

      // Формируем URL БЕЗ слеша в конце, как ожидает сервер
      final String url = "$baseUrl/cells/${state.currentCell!.id}";
      print("Получение обновленной ячейки с URL: $url");

      // Используем HTTP клиент без автоматических перенаправлений
      final client = http.Client();
      try {
        final response = await client.get(Uri.parse(url));

        print("Статус ответа при получении ячейки: ${response.statusCode}");

        // Обрабатываем успешный ответ
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final Map<String, dynamic> cellData = jsonDecode(response.body);
          final updatedCell = Cell.fromJson(cellData);

          // ИСПРАВЛЕНИЕ: проверяем, есть ли в ответе информация о возможности undo/redo
          // Это зависит от API вашего бэкенда
          bool canUndo = false;
          bool canRedo = false;

          // Проверяем, есть ли в ячейке содержимое - если есть, предполагаем,
          // что можно делать Undo (это упрощенная логика)
          if (updatedCell.contentJson.isNotEmpty &&
              updatedCell.contentJson != '{"elements":[]}') {
            canUndo = true;
          }

          // Обновляем ячейку в состоянии
          _updateCellInState(updatedCell);

          // ИСПРАВЛЕНИЕ: обновляем флаги undo/redo
          state = state.copyWith(
            canUndo: canUndo,
            canRedo: canRedo,
          );

          print("Ячейка успешно обновлена с сервера");
          return;
        }
        // Если это не успешный ответ, но и не перенаправление
        else if (response.statusCode != 301 && response.statusCode != 302 &&
            response.statusCode != 307 && response.statusCode != 308) {
          print("Ошибка при обновлении ячейки с сервера: ${response.statusCode}, ${response.body}");
          return;
        }
        // Обрабатываем перенаправление
        else {
          final String? redirectUrl = response.headers['location'];
          print("Получено перенаправление на: $redirectUrl");

          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            // Формируем полный URL для перенаправления
            String fullRedirectUrl;

            if (redirectUrl.startsWith('http')) {
              // Абсолютный URL
              fullRedirectUrl = redirectUrl;
            } else {
              // Относительный URL
              String cleanRedirectUrl = redirectUrl.startsWith('/')
                  ? redirectUrl.substring(1)
                  : redirectUrl;
              fullRedirectUrl = "$domain/$cleanRedirectUrl";
            }

            print("Получение ячейки с перенаправленного URL: $fullRedirectUrl");

            // Выполняем запрос по URL перенаправления
            final redirectResponse = await client.get(Uri.parse(fullRedirectUrl));

            if (redirectResponse.statusCode >= 200 && redirectResponse.statusCode < 300) {
              final Map<String, dynamic> cellData = jsonDecode(redirectResponse.body);
              final updatedCell = Cell.fromJson(cellData);

              // ИСПРАВЛЕНИЕ: та же логика проверки возможности undo/redo
              bool canUndo = false;
              bool canRedo = false;

              if (updatedCell.contentJson.isNotEmpty &&
                  updatedCell.contentJson != '{"elements":[]}') {
                canUndo = true;
              }

              // Обновляем ячейку в состоянии
              _updateCellInState(updatedCell);

              // ИСПРАВЛЕНИЕ: обновляем флаги undo/redo
              state = state.copyWith(
                canUndo: canUndo,
                canRedo: canRedo,
              );

              print("Ячейка успешно обновлена с сервера после перенаправления");
              return;
            } else {
              print("Ошибка при обновлении ячейки с сервера после перенаправления: ${redirectResponse.statusCode}, ${redirectResponse.body}");
              return;
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print("Ошибка при обновлении ячейки с сервера: $e");
    }
  }

// Вспомогательный метод для обновления ячейки в состоянии (остается без изменений)
  void _updateCellInState(Cell updatedCell) {
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

    state = state.copyWith(
      pages: updatedPages,
      currentCell: updatedCell,
    );
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

  // Функция отмены последнего действия (Undo)
  Future<void> undo() async {
    if (state.currentCell == null) {
      print("Нет текущей ячейки для отмены действия");
      return;
    }

    print("Отмена последнего действия для ячейки: ${state.currentCell!.id}");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Получаем базовый URL без слеша в конце
      String baseUrl = Environment.API_URL;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      // Получаем только домен (https://example.com)
      String domain = baseUrl.split('/').sublist(0, 3).join('/');

      // Формируем URL точно в том формате, который требует сервер (БЕЗ слеша в конце)
      final String url = "$baseUrl/cells/${state.currentCell!.id}/undo";
      print("Отправка запроса на URL (без слеша в конце): $url");

      // Создаем HTTP клиент напрямую для корректной обработки перенаправлений
      final client = http.Client();

      try {
        // Используем HTTP напрямую
        final response = await client.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        );

        print("Получен ответ: ${response.statusCode}");
        print("Заголовки ответа: ${response.headers}");

        // Проверяем статус ответа
        if (response.statusCode >= 200 && response.statusCode < 300) {
          print("Undo выполнен успешно: ${response.statusCode}");

          // Парсим ответ с обновленной ячейкой
          final Map<String, dynamic> cellData = jsonDecode(response.body);
          final updatedCell = Cell.fromJson(cellData);

          // Обновляем ячейку в списке
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

          // Проверяем содержимое ячейки, чтобы определить, можно ли выполнить еще одну отмену
          bool canUndoMore = false;
          try {
            final contentJson = updatedCell.contentJson;
            if (contentJson.isNotEmpty && contentJson != '{"elements":[]}') {
              final content = CellContent.fromJsonString(contentJson);
              canUndoMore = content.elements.isNotEmpty;
            }
          } catch (e) {
            print("Ошибка при проверке содержимого ячейки: $e");
          }

          // После undo, нужно установить, что теперь можно сделать redo
          state = state.copyWith(
            isLoading: false,
            pages: updatedPages,
            currentCell: updatedCell,
            canUndo: canUndoMore,  // Можно отменить еще только если есть содержимое
            canRedo: true,         // После undo всегда можно сделать redo
            errorMessage: null,
          );
          print("Действие отменено успешно. Можно отменить еще: $canUndoMore");
          return;
        }
        // Если это не успешный ответ, но и не перенаправление
        else if (response.statusCode != 301 && response.statusCode != 302 &&
            response.statusCode != 307 && response.statusCode != 308) {
          throw Exception("Ошибка отмены действия: ${response.statusCode}, ${response.body}");
        }
        // Обрабатываем перенаправление
        else {
          final String? redirectUrl = response.headers['location'];
          print("Получено перенаправление на: $redirectUrl");

          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            // Формируем полный URL для перенаправления
            String fullRedirectUrl;

            if (redirectUrl.startsWith('http')) {
              // Абсолютный URL
              fullRedirectUrl = redirectUrl;
            } else {
              // Относительный URL
              String cleanRedirectUrl = redirectUrl.startsWith('/')
                  ? redirectUrl.substring(1)
                  : redirectUrl;
              fullRedirectUrl = "$domain/$cleanRedirectUrl";
            }

            print("Отправка запроса на перенаправленный URL: $fullRedirectUrl");

            // Выполняем запрос по URL перенаправления
            final redirectResponse = await client.post(
              Uri.parse(fullRedirectUrl),
              headers: {'Content-Type': 'application/json'},
            );

            print("Получен ответ после перенаправления: ${redirectResponse.statusCode}");

            if (redirectResponse.statusCode >= 200 && redirectResponse.statusCode < 300) {
              print("Undo выполнен успешно после перенаправления: ${redirectResponse.statusCode}");

              // Парсим ответ с обновленной ячейкой
              final Map<String, dynamic> cellData = jsonDecode(redirectResponse.body);
              final updatedCell = Cell.fromJson(cellData);

              // Обновляем ячейку в списке
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

              // Проверяем содержимое ячейки после отмены
              bool canUndoMore = false;
              try {
                final contentJson = updatedCell.contentJson;
                if (contentJson.isNotEmpty && contentJson != '{"elements":[]}') {
                  final content = CellContent.fromJsonString(contentJson);
                  canUndoMore = content.elements.isNotEmpty;
                }
              } catch (e) {
                print("Ошибка при проверке содержимого ячейки: $e");
              }

              // После undo, нужно установить, что теперь можно сделать redo
              state = state.copyWith(
                isLoading: false,
                pages: updatedPages,
                currentCell: updatedCell,
                canUndo: canUndoMore,  // Можно отменить еще только если есть содержимое
                canRedo: true,         // После undo всегда можно сделать redo
                errorMessage: null,
              );

              print("Действие отменено успешно после перенаправления. Можно отменить еще: $canUndoMore");
              return;
            } else {
              throw Exception("Ошибка отмены действия после перенаправления: ${redirectResponse.statusCode}, ${redirectResponse.body}");
            }
          }
        }

        throw Exception("Неожиданное поведение при отмене действия");
      } finally {
        // Закрываем HTTP клиент
        client.close();
      }
    } catch (e) {
      print("ОШИБКА при отмене действия: $e");
      state = state.copyWith(
        isLoading: false,  // Обязательно сбрасываем статус загрузки
        errorMessage: 'Ошибка отмены действия: ${e.toString()}',
      );
    }
  }

  // Функция повтора отмененного действия (Redo) с поддержкой перенаправлений
  Future<void> redo() async {
    if (state.currentCell == null) {
      print("Нет текущей ячейки для повтора действия");
      return;
    }

    print("Повтор действия для ячейки: ${state.currentCell!.id}");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Получаем базовый URL без слеша в конце
      String baseUrl = Environment.API_URL;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      // Получаем только домен (https://example.com)
      String domain = baseUrl.split('/').sublist(0, 3).join('/');

      // Формируем URL точно в том формате, который требует сервер (БЕЗ слеша в конце)
      final String url = "$baseUrl/cells/${state.currentCell!.id}/redo";
      print("Отправка запроса на URL (без слеша в конце): $url");

      // Создаем HTTP клиент напрямую для корректной обработки перенаправлений
      final client = http.Client();

      try {
        // Используем HTTP напрямую
        final response = await client.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        );

        print("Получен ответ: ${response.statusCode}");
        print("Заголовки ответа: ${response.headers}");

        // Проверяем статус ответа
        if (response.statusCode >= 200 && response.statusCode < 300) {
          print("Redo выполнен успешно: ${response.statusCode}");

          // Парсим ответ с обновленной ячейкой
          final Map<String, dynamic> cellData = jsonDecode(response.body);
          final updatedCell = Cell.fromJson(cellData);

          // Обновляем ячейку в списке
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

          // Проверяем, возможно ли дальнейшее redo
          // Согласно документации API, нам нужно предположить, что после redo
          // может не быть дальнейших действий для повтора, т.к. API не возвращает
          // эту информацию напрямую
          bool canRedoMore = false;

          // Всегда можно выполнить undo после redo
          bool canUndoNow = true;

          // После redo, должна быть возможность undo, но redo может быть недоступен
          state = state.copyWith(
            isLoading: false,
            pages: updatedPages,
            currentCell: updatedCell,
            canUndo: canUndoNow,  // После redo всегда можно сделать undo
            canRedo: canRedoMore, // После redo может не быть возможности дальнейшего redo
            errorMessage: null,
          );
          print("Действие повторено успешно");
          return;
        }
        // Если это не успешный ответ, но и не перенаправление
        else if (response.statusCode != 301 && response.statusCode != 302 &&
            response.statusCode != 307 && response.statusCode != 308) {
          throw Exception("Ошибка повтора действия: ${response.statusCode}, ${response.body}");
        }
        // Обрабатываем перенаправление
        else {
          final String? redirectUrl = response.headers['location'];
          print("Получено перенаправление на: $redirectUrl");

          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            // Формируем полный URL для перенаправления
            String fullRedirectUrl;

            if (redirectUrl.startsWith('http')) {
              // Абсолютный URL
              fullRedirectUrl = redirectUrl;
            } else {
              // Относительный URL
              String cleanRedirectUrl = redirectUrl.startsWith('/')
                  ? redirectUrl.substring(1)
                  : redirectUrl;
              fullRedirectUrl = "$domain/$cleanRedirectUrl";
            }

            print("Отправка запроса на перенаправленный URL: $fullRedirectUrl");

            // Выполняем запрос по URL перенаправления
            final redirectResponse = await client.post(
              Uri.parse(fullRedirectUrl),
              headers: {'Content-Type': 'application/json'},
            );

            print("Получен ответ после перенаправления: ${redirectResponse.statusCode}");

            if (redirectResponse.statusCode >= 200 && redirectResponse.statusCode < 300) {
              print("Redo выполнен успешно после перенаправления: ${redirectResponse.statusCode}");

              // Парсим ответ с обновленной ячейкой
              final Map<String, dynamic> cellData = jsonDecode(redirectResponse.body);
              final updatedCell = Cell.fromJson(cellData);

              // Обновляем ячейку в списке
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

              // По умолчанию предполагаем, что после redo нет возможности дальнейшего redo
              bool canRedoMore = false;

              // Всегда можно выполнить undo после успешного redo
              bool canUndoNow = true;

              state = state.copyWith(
                isLoading: false,
                pages: updatedPages,
                currentCell: updatedCell,
                canUndo: canUndoNow,  // После redo всегда можно сделать undo
                canRedo: canRedoMore, // После redo может не быть возможности дальнейшего redo
                errorMessage: null,
              );

              print("Действие повторено успешно после перенаправления");
              return;
            } else {
              throw Exception("Ошибка повтора действия после перенаправления: ${redirectResponse.statusCode}, ${redirectResponse.body}");
            }
          }
        }

        throw Exception("Неожиданное поведение при повторе действия");
      } finally {
        // Закрываем HTTP клиент
        client.close();
      }
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

        // Загрузка изображения на сервер
        var formData = FormData.fromMap({
          "image": await MultipartFile.fromFile(
            imageFile.path,
          ),
        });

        final response = await _dio.post(
          '/upload/',
          data: formData,
        );

        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          // Получение пути к загруженному изображению
          final imagePath = response.data['image_path'];
          print("Изображение загружено успешно: $imagePath");

          // Здесь должна быть логика добавления изображения в ячейку
          // Это будет обрабатываться в UI
        } else {
          throw Exception("Ошибка загрузки изображения: ${response.statusCode} ${response.data}");
        }
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
}