import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/workspace/domain/card_model.dart';
import '../../features/workspace/domain/game_spec.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._();
  factory LocalDbService() => _instance;
  LocalDbService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/gameforge_cache.db';

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE projects (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT 'draft',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cards (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            type TEXT NOT NULL,
            content TEXT NOT NULL,
            parent_id TEXT,
            order_index INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE game_builds (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            version INTEGER NOT NULL,
            html_code TEXT NOT NULL,
            spec_snapshot TEXT NOT NULL,
            created_at TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_cards_project ON cards(project_id)');
        await db.execute(
            'CREATE INDEX idx_builds_project ON game_builds(project_id)');
      },
    );
  }

  // ---- Connectivity ----

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ---- Projects ----

  Future<void> cacheProjects(List<ProjectModel> projects) async {
    final d = await db;
    final batch = d.batch();
    final now = DateTime.now().toIso8601String();
    for (final p in projects) {
      batch.insert(
        'projects',
        {
          'id': p.id,
          'user_id': p.userId,
          'title': p.title,
          'description': p.description,
          'status': p.status,
          'created_at': p.createdAt.toIso8601String(),
          'updated_at': p.updatedAt.toIso8601String(),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheProject(ProjectModel project) async {
    final d = await db;
    await d.insert(
      'projects',
      {
        'id': project.id,
        'user_id': project.userId,
        'title': project.title,
        'description': project.description,
        'status': project.status,
        'created_at': project.createdAt.toIso8601String(),
        'updated_at': project.updatedAt.toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProjectModel>> getLocalProjects() async {
    final d = await db;
    final rows = await d.query('projects', orderBy: 'updated_at DESC');
    return rows.map((r) => ProjectModel.fromJson(_rowToJson(r))).toList();
  }

  Future<void> deleteLocalProject(String id) async {
    final d = await db;
    await d.delete('projects', where: 'id = ?', whereArgs: [id]);
    await d.delete('cards', where: 'project_id = ?', whereArgs: [id]);
    await d.delete('game_builds', where: 'project_id = ?', whereArgs: [id]);
  }

  // ---- Cards ----

  Future<void> cacheCards(String projectId, List<CardModel> cards) async {
    final d = await db;
    final batch = d.batch();
    final now = DateTime.now().toIso8601String();
    // Clear old cards for this project then re-insert
    batch.delete('cards', where: 'project_id = ?', whereArgs: [projectId]);
    for (final c in cards) {
      batch.insert(
        'cards',
        {
          'id': c.id,
          'project_id': c.projectId,
          'type': c.type.apiValue,
          'content': jsonEncode(c.content),
          'parent_id': c.parentId,
          'order_index': c.orderIndex,
          'created_at': c.createdAt.toIso8601String(),
          'updated_at': c.updatedAt.toIso8601String(),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheCard(CardModel card) async {
    final d = await db;
    await d.insert(
      'cards',
      {
        'id': card.id,
        'project_id': card.projectId,
        'type': card.type.apiValue,
        'content': jsonEncode(card.content),
        'parent_id': card.parentId,
        'order_index': card.orderIndex,
        'created_at': card.createdAt.toIso8601String(),
        'updated_at': card.updatedAt.toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CardModel>> getLocalCards(String projectId) async {
    final d = await db;
    final rows = await d.query(
      'cards',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'order_index ASC',
    );
    return rows.map((r) {
      final json = _rowToJson(r);
      json['content'] = jsonDecode(r['content'] as String);
      return CardModel.fromJson(json);
    }).toList();
  }

  // ---- Game Builds ----

  Future<void> cacheBuild(
      String projectId, String htmlCode, GameSpec spec) async {
    final d = await db;
    // Get next version from local DB
    final rows = await d.query(
      'game_builds',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'version DESC',
      limit: 1,
    );
    final version = rows.isEmpty ? 1 : ((rows.first['version'] as int) + 1);

    await d.insert(
      'game_builds',
      {
        'id': const Uuid().v4(),
        'project_id': projectId,
        'version': version,
        'html_code': htmlCode,
        'spec_snapshot': jsonEncode(spec.toJson()),
        'created_at': DateTime.now().toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getLatestLocalBuild(String projectId) async {
    final d = await db;
    final rows = await d.query(
      'game_builds',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'version DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['html_code'] as String;
  }

  Map<String, dynamic> _rowToJson(Map<String, dynamic> row) {
    return row.map((k, v) => MapEntry(k, v));
  }
}
