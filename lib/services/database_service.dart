import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../config/security_config.dart';
import 'encryption_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final EncryptionService _encryptionService = EncryptionService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'password_vault.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
    
    // Set journal mode to WAL for better concurrency
    await db.execute('PRAGMA journal_mode = WAL');
    
    // Set synchronous mode to NORMAL for better performance
    await db.execute('PRAGMA synchronous = NORMAL');
    
    // Set busy timeout to 5 seconds
    await db.execute('PRAGMA busy_timeout = 5000');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE password_entries(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_accessed_at INTEGER,
        category TEXT,
        tags TEXT,
        favorite INTEGER DEFAULT 0,
        version INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE password_entry_tags(
        entry_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (entry_id, tag_id),
        FOREIGN KEY (entry_id) REFERENCES password_entries(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_password_entries_category ON password_entries(category)');
    await db.execute('CREATE INDEX idx_password_entries_favorite ON password_entries(favorite)');
    await db.execute('CREATE INDEX idx_password_entries_last_accessed ON password_entries(last_accessed_at)');
  }

  // Insert or update a password entry
  Future<void> upsertPasswordEntry(Map<String, dynamic> entry, Uint8List encryptionKey) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Encrypt sensitive data
    final encryptedPassword = _encryptionService.encryptData(entry['password'], encryptionKey);
    final encryptedNotes = entry['notes'] != null 
        ? _encryptionService.encryptData(entry['notes'], encryptionKey)
        : null;

    final data = {
      ...entry,
      'password': encryptedPassword,
      'notes': encryptedNotes,
      'updated_at': now,
    };

    if (entry['id'] == null) {
      data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      data['created_at'] = now;
    }

    await db.insert(
      'password_entries',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get a password entry by ID
  Future<Map<String, dynamic>?> getPasswordEntry(String id, Uint8List encryptionKey) async {
    final db = await database;
    final entry = await db.query(
      'password_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (entry.isEmpty) return null;

    // Update last accessed timestamp
    await db.update(
      'password_entries',
      {'last_accessed_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Decrypt sensitive data
    final decryptedEntry = Map<String, dynamic>.from(entry.first);
    decryptedEntry['password'] = _encryptionService.decryptData(
      decryptedEntry['password'],
      encryptionKey,
    );
    
    if (decryptedEntry['notes'] != null) {
      decryptedEntry['notes'] = _encryptionService.decryptData(
        decryptedEntry['notes'],
        encryptionKey,
      );
    }

    return decryptedEntry;
  }

  // Get all password entries
  Future<List<Map<String, dynamic>>> getAllPasswordEntries(Uint8List encryptionKey) async {
    final db = await database;
    final entries = await db.query('password_entries', orderBy: 'name ASC');
    
    return entries.map((entry) {
      final decryptedEntry = Map<String, dynamic>.from(entry);
      decryptedEntry['password'] = _encryptionService.decryptData(
        decryptedEntry['password'],
        encryptionKey,
      );
      
      if (decryptedEntry['notes'] != null) {
        decryptedEntry['notes'] = _encryptionService.decryptData(
          decryptedEntry['notes'],
          encryptionKey,
        );
      }
      
      return decryptedEntry;
    }).toList();
  }

  // Delete a password entry
  Future<void> deletePasswordEntry(String id) async {
    final db = await database;
    await db.delete(
      'password_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search password entries
  Future<List<Map<String, dynamic>>> searchPasswordEntries(
    String query,
    Uint8List encryptionKey,
  ) async {
    final db = await database;
    final entries = await db.query(
      'password_entries',
      where: 'name LIKE ? OR username LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return entries.map((entry) {
      final decryptedEntry = Map<String, dynamic>.from(entry);
      decryptedEntry['password'] = _encryptionService.decryptData(
        decryptedEntry['password'],
        encryptionKey,
      );
      
      if (decryptedEntry['notes'] != null) {
        decryptedEntry['notes'] = _encryptionService.decryptData(
          decryptedEntry['notes'],
          encryptionKey,
        );
      }
      
      return decryptedEntry;
    }).toList();
  }

  // Get entries by category
  Future<List<Map<String, dynamic>>> getEntriesByCategory(
    String category,
    Uint8List encryptionKey,
  ) async {
    final db = await database;
    final entries = await db.query(
      'password_entries',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );

    return entries.map((entry) {
      final decryptedEntry = Map<String, dynamic>.from(entry);
      decryptedEntry['password'] = _encryptionService.decryptData(
        decryptedEntry['password'],
        encryptionKey,
      );
      
      if (decryptedEntry['notes'] != null) {
        decryptedEntry['notes'] = _encryptionService.decryptData(
          decryptedEntry['notes'],
          encryptionKey,
        );
      }
      
      return decryptedEntry;
    }).toList();
  }

  // Get favorite entries
  Future<List<Map<String, dynamic>>> getFavoriteEntries(Uint8List encryptionKey) async {
    final db = await database;
    final entries = await db.query(
      'password_entries',
      where: 'favorite = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return entries.map((entry) {
      final decryptedEntry = Map<String, dynamic>.from(entry);
      decryptedEntry['password'] = _encryptionService.decryptData(
        decryptedEntry['password'],
        encryptionKey,
      );
      
      if (decryptedEntry['notes'] != null) {
        decryptedEntry['notes'] = _encryptionService.decryptData(
          decryptedEntry['notes'],
          encryptionKey,
        );
      }
      
      return decryptedEntry;
    }).toList();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'password_entries',
      {'favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
} 