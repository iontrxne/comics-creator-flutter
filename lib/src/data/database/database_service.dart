import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../data/models/comic_model.dart';
import '../../logic/comic/editor_provider.dart';
import '../../ui/comic/canvas/canvas_controller.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'comics.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Создание таблицы комиксов
    await db.execute('''
      CREATE TABLE comics(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        cover_image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Создание таблицы страниц
    await db.execute('''
      CREATE TABLE pages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comic_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (comic_id) REFERENCES comics (id) ON DELETE CASCADE
      )
    ''');

    // Создание таблицы ячеек
    await db.execute('''
      CREATE TABLE cells(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page_id INTEGER NOT NULL,
        position_x REAL NOT NULL,
        position_y REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        z_index INTEGER NOT NULL,
        content_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
      )
    ''');

    // Создание таблицы истории для undo/redo
    await db.execute('''
      CREATE TABLE cell_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cell_id INTEGER NOT NULL,
        content_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (cell_id) REFERENCES cells (id) ON DELETE CASCADE
      )
    ''');
  }

  // Операции с комиксами
  Future<List<Comic>> getAllComics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('comics', orderBy: 'updated_at DESC');
    return List.generate(maps.length, (i) {
      return Comic(
        id: maps[i]['id'],
        title: maps[i]['title'],
        coverImagePath: maps[i]['cover_image_path'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
      );
    });
  }

  Future<int> createComic(String title) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('comics', {
      'title': title,
      'cover_image_path': '',
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> updateComicCover(int id, String imagePath) async {
    final db = await database;
    await db.update(
      'comics',
      {
        'cover_image_path': imagePath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateComicTitle(int id, String title) async {
    final db = await database;
    await db.update(
      'comics',
      {
        'title': title,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> deleteComic(int id) async {
    final db = await database;
    final count = await db.delete(
      'comics',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  // Операции со страницами
  Future<List<Page>> getPagesForComic(int comicId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pages',
      where: 'comic_id = ?',
      whereArgs: [comicId],
      orderBy: 'page_number ASC',
    );

    List<Page> pages = [];
    for (var pageMap in maps) {
      final List<Map<String, dynamic>> cellMaps = await db.query(
        'cells',
        where: 'page_id = ?',
        whereArgs: [pageMap['id']],
        orderBy: 'z_index ASC',
      );

      List<Cell> cells = cellMaps.map((cellMap) {
        return Cell(
          id: cellMap['id'],
          pageId: cellMap['page_id'],
          positionX: cellMap['position_x'],
          positionY: cellMap['position_y'],
          width: cellMap['width'],
          height: cellMap['height'],
          zIndex: cellMap['z_index'],
          contentJson: cellMap['content_json'],
          createdAt: DateTime.parse(cellMap['created_at']),
          updatedAt: DateTime.parse(cellMap['updated_at']),
        );
      }).toList();

      pages.add(Page(
        id: pageMap['id'],
        comicId: pageMap['comic_id'],
        pageNumber: pageMap['page_number'],
        createdAt: DateTime.parse(pageMap['created_at']),
        updatedAt: DateTime.parse(pageMap['updated_at']),
        cells: cells,
      ));
    }

    return pages;
  }

  Future<int> createPage(int comicId, int pageNumber) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('pages', {
      'comic_id': comicId,
      'page_number': pageNumber,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<bool> deletePage(int id) async {
    final db = await database;
    final count = await db.delete(
      'pages',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  // Операции с ячейками
  Future<List<Cell>> getCellsForPage(int pageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cells',
      where: 'page_id = ?',
      whereArgs: [pageId],
      orderBy: 'z_index ASC',
    );

    return List.generate(maps.length, (i) {
      return Cell(
        id: maps[i]['id'],
        pageId: maps[i]['page_id'],
        positionX: maps[i]['position_x'],
        positionY: maps[i]['position_y'],
        width: maps[i]['width'],
        height: maps[i]['height'],
        zIndex: maps[i]['z_index'],
        contentJson: maps[i]['content_json'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
      );
    });
  }

  Future<int> createCell(int pageId, double posX, double posY, double width, double height) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Находим максимальный z-index для этой страницы
    final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT MAX(z_index) as max_z FROM cells WHERE page_id = ?',
        [pageId]
    );

    int zIndex = 1;
    if (result.first['max_z'] != null) {
      zIndex = (result.first['max_z'] as int) + 1;
    }

    final id = await db.insert('cells', {
      'page_id': pageId,
      'position_x': posX,
      'position_y': posY,
      'width': width,
      'height': height,
      'z_index': zIndex,
      'content_json': '{"elements":[]}',
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> updateCell(Cell cell) async {
    final db = await database;
    await db.update(
      'cells',
      {
        'position_x': cell.positionX,
        'position_y': cell.positionY,
        'width': cell.width,
        'height': cell.height,
        'z_index': cell.zIndex,
        'content_json': cell.contentJson,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [cell.id],
    );
  }

  Future<bool> deleteCell(int id) async {
    final db = await database;
    final count = await db.delete(
      'cells',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  // Операции с историей для undo/redo
  Future<void> saveCellHistory(int cellId, String contentJson) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('cell_history', {
      'cell_id': cellId,
      'content_json': contentJson,
      'created_at': now,
    });
  }

  Future<String?> getLastCellHistory(int cellId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cell_history',
      where: 'cell_id = ?',
      whereArgs: [cellId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // Удаляем запись из истории после того, как получили ее
      await db.delete(
        'cell_history',
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
      return maps.first['content_json'];
    }

    return null;
  }

  Future<bool> canUndo(int cellId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM cell_history WHERE cell_id = ?',
      [cellId],
    ));
    return count! > 0;
  }

  Future<bool> canRedo(int cellId) async {
    // В настоящей реализации требуется более сложная система
    return false;
  }
}