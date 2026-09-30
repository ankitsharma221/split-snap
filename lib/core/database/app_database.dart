import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/split.dart';
import '../../models/split_member.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _db;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'splitsnap.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE splits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        bank_name TEXT,
        upi_ref TEXT,
        note TEXT,
        category TEXT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        wifi_name TEXT,
        photo_path TEXT,
        is_complete INTEGER NOT NULL DEFAULT 0,
        is_settled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE split_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        split_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        amount_owed REAL NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (split_id) REFERENCES splits (id) ON DELETE CASCADE
      )
    ''');
  }

  // ─── Splits ───────────────────────────────────────────────────────────────

  Future<int> insertSplit(Split split) async {
    final db = await database;
    return db.insert('splits', split.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Split>> getAllSplits() async {
    final db = await database;
    final maps = await db.query('splits', orderBy: 'created_at DESC');
    return maps.map((m) => Split.fromMap(m)).toList();
  }

  Future<List<Split>> getIncompleteSplits() async {
    final db = await database;
    final maps = await db.query('splits',
        where: 'is_complete = ?', whereArgs: [0], orderBy: 'created_at DESC');
    return maps.map((m) => Split.fromMap(m)).toList();
  }

  Future<Split?> getSplitById(int id) async {
    final db = await database;
    final maps =
        await db.query('splits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Split.fromMap(maps.first);
  }

  Future<void> updateSplit(Split split) async {
    final db = await database;
    await db.update('splits', split.toMap(),
        where: 'id = ?', whereArgs: [split.id]);
  }

  Future<void> deleteSplit(int id) async {
    final db = await database;
    await db.delete('splits', where: 'id = ?', whereArgs: [id]);
  }

  // Update only context fields (location, wifi) without overwriting user data
  Future<void> updateSplitContext({
    required int id,
    double? latitude,
    double? longitude,
    String? locationName,
    String? wifiName,
  }) async {
    final db = await database;
    final data = <String, dynamic>{};
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (locationName != null) data['location_name'] = locationName;
    if (wifiName != null) data['wifi_name'] = wifiName;
    if (data.isEmpty) return;
    await db.update('splits', data, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Split Members ─────────────────────────────────────────────────────────

  Future<int> insertMember(SplitMember member) async {
    final db = await database;
    return db.insert('split_members', member.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SplitMember>> getMembersForSplit(int splitId) async {
    final db = await database;
    final maps = await db.query('split_members',
        where: 'split_id = ?', whereArgs: [splitId]);
    return maps.map((m) => SplitMember.fromMap(m)).toList();
  }

  Future<void> updateMember(SplitMember member) async {
    final db = await database;
    await db.update('split_members', member.toMap(),
        where: 'id = ?', whereArgs: [member.id]);
  }

  Future<void> deleteMembersForSplit(int splitId) async {
    final db = await database;
    await db.delete('split_members',
        where: 'split_id = ?', whereArgs: [splitId]);
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  Future<double> getTotalOwed() async {
    final db = await database;
    // Sum of amount_owed for all unsettled members across all my splits
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(sm.amount_owed), 0) as total
      FROM split_members sm
      INNER JOIN splits s ON sm.split_id = s.id
      WHERE sm.is_settled = 0
    ''');
    return (result.first['total'] as num).toDouble();
  }
}
