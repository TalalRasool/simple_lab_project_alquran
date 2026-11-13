import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/reading_position.dart';
import '../data/translation_edition.dart';
import '../data/translation_text.dart';

/// Offline Urdu and English translations. The Arabic Mushaf text is separate.
class TranslationDatabase {
  TranslationDatabase._();

  static final instance = TranslationDatabase._();

  /// Set by tests so they can open an in-memory database.
  static DatabaseFactory? debugFactory;
  static String? debugPath;

  Database? _database;
  Future<void>? _opening;

  Future<void> ensureReady() {
    return _opening ??= _open();
  }

  Future<TranslationAyah?> ayah(String language, int surah, int ayah) async {
    await ensureReady();
    final database = _database;
    if (database == null) {
      throw StateError('Translation database is not open.');
    }
    final rows = await database.query(
      'translations',
      columns: ['ayah_number', 'translation_text', 'footnotes'],
      where: 'language_code = ? AND surah_number = ? AND ayah_number = ?',
      whereArgs: [language, surah, ayah],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final footnote = row['footnotes'] as String?;
    return TranslationAyah(
      surah: surah,
      ayah: row['ayah_number'] as int,
      text: row['translation_text'] as String,
      footnote: footnote == null || footnote.isEmpty ? null : footnote,
    );
  }

  Future<List<TranslationAyah>> surah(String language, int surah) async {
    await ensureReady();
    final database = _database;
    if (database == null) {
      throw StateError('Translation database is not open.');
    }
    final rows = await database.query(
      'translations',
      columns: ['ayah_number', 'translation_text', 'footnotes'],
      where: 'language_code = ? AND surah_number = ?',
      whereArgs: [language, surah],
      orderBy: 'ayah_number',
    );
    return [
      for (final row in rows)
        TranslationAyah(
          surah: surah,
          ayah: row['ayah_number'] as int,
          text: row['translation_text'] as String,
          footnote: row['footnotes'] as String?,
        ),
    ];
  }

  Future<void> _open() async {
    try {
      final factory = debugFactory;
      final database = factory == null
          ? await openDatabase(
              p.join(await getDatabasesPath(), 'quran_translations.db'),
              version: 3,
              onCreate: (db, version) => _create(db),
              onUpgrade: (db, oldVersion, newVersion) =>
                  _upgrade(db, oldVersion),
            )
          : await factory.openDatabase(
              debugPath ?? ':memory:',
              options: OpenDatabaseOptions(
                version: 3,
                onCreate: (db, version) => _create(db),
                onUpgrade: (db, oldVersion, newVersion) =>
                    _upgrade(db, oldVersion),
              ),
            );
      _database = database;
      await _importIfNeeded(database);
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> _create(Database db) async {
    await db.execute('''
      CREATE TABLE translation_sources (
        language_code TEXT PRIMARY KEY,
        translator TEXT NOT NULL,
        source TEXT NOT NULL,
        version TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE translations (
        language_code TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        translation_text TEXT NOT NULL,
        footnotes TEXT,
        PRIMARY KEY (language_code, surah_number, ayah_number)
      )
    ''');
    await _createReadingTables(db);
    await _createHadithBookmarks(db);
  }

  Future<void> _upgrade(Database db, int oldVersion) async {
    if (oldVersion < 2) await _createReadingTables(db);
    if (oldVersion < 3) await _createHadithBookmarks(db);
  }

  Future<void> _createHadithBookmarks(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hadith_bookmarks (
        collection_id TEXT NOT NULL,
        hadith_number INTEGER NOT NULL,
        arabic_number TEXT NOT NULL,
        chapter_number INTEGER NOT NULL,
        chapter_hadith INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (
          collection_id,
          hadith_number,
          arabic_number,
          chapter_number,
          chapter_hadith
        )
      )
    ''');
  }

  Future<void> _createReadingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayah_bookmarks (
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (surah_number, ayah_number)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS last_read (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        juz_number INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        mode TEXT NOT NULL
      )
    ''');
  }

  Future<List<AyahBookmark>> bookmarks() async {
    await ensureReady();
    final database = _required();
    final rows = await database.query(
      'ayah_bookmarks',
      orderBy: 'created_at DESC',
    );
    return [
      for (final row in rows)
        AyahBookmark(
          surah: row['surah_number'] as int,
          ayah: row['ayah_number'] as int,
          createdAt: row['created_at'] as int,
        ),
    ];
  }

  /// Returns true when the ayah is bookmarked after the change.
  Future<bool> toggleBookmark(int surah, int ayah) async {
    await ensureReady();
    final database = _required();
    return database.transaction((txn) async {
      final existing = await txn.query(
        'ayah_bookmarks',
        columns: ['surah_number'],
        where: 'surah_number = ? AND ayah_number = ?',
        whereArgs: [surah, ayah],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await txn.delete(
          'ayah_bookmarks',
          where: 'surah_number = ? AND ayah_number = ?',
          whereArgs: [surah, ayah],
        );
        return false;
      }
      await txn.insert('ayah_bookmarks', {
        'surah_number': surah,
        'ayah_number': ayah,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    });
  }

  Future<void> saveLastRead(ReadingPosition position) async {
    await ensureReady();
    await _required().insert('last_read', {
      'id': 1,
      'surah_number': position.surah,
      'ayah_number': position.ayah,
      'juz_number': position.juz,
      'page_number': position.page,
      'mode': position.mode.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ReadingPosition?> lastRead() async {
    await ensureReady();
    final rows = await _required().query(
      'last_read',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ReadingPosition(
      surah: row['surah_number'] as int,
      ayah: row['ayah_number'] as int,
      juz: row['juz_number'] as int,
      page: row['page_number'] as int,
      mode: row['mode'] == ReadingMode.mushaf.name
          ? ReadingMode.mushaf
          : ReadingMode.quran,
    );
  }

  Future<List<Map<String, Object?>>> hadithBookmarks() async {
    await ensureReady();
    return _required().query('hadith_bookmarks', orderBy: 'created_at DESC');
  }

  Future<bool> isHadithBookmarked({
    required String collectionId,
    required int hadithNumber,
    required String arabicNumber,
    required int chapterNumber,
    required int chapterHadith,
  }) async {
    await ensureReady();
    final rows = await _required().query(
      'hadith_bookmarks',
      columns: ['collection_id'],
      where:
          'collection_id = ? AND hadith_number = ? AND arabic_number = ? AND chapter_number = ? AND chapter_hadith = ?',
      whereArgs: [
        collectionId,
        hadithNumber,
        arabicNumber,
        chapterNumber,
        chapterHadith,
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Returns true when the Hadith is bookmarked after the change.
  Future<bool> toggleHadithBookmark({
    required String collectionId,
    required int hadithNumber,
    required String arabicNumber,
    required int chapterNumber,
    required int chapterHadith,
  }) async {
    await ensureReady();
    final database = _required();
    return database.transaction((txn) async {
      final existing = await txn.query(
        'hadith_bookmarks',
        columns: ['collection_id'],
        where:
            'collection_id = ? AND hadith_number = ? AND arabic_number = ? AND chapter_number = ? AND chapter_hadith = ?',
        whereArgs: [
          collectionId,
          hadithNumber,
          arabicNumber,
          chapterNumber,
          chapterHadith,
        ],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await txn.delete(
          'hadith_bookmarks',
          where:
              'collection_id = ? AND hadith_number = ? AND arabic_number = ? AND chapter_number = ? AND chapter_hadith = ?',
          whereArgs: [
            collectionId,
            hadithNumber,
            arabicNumber,
            chapterNumber,
            chapterHadith,
          ],
        );
        return false;
      }
      await txn.insert('hadith_bookmarks', {
        'collection_id': collectionId,
        'hadith_number': hadithNumber,
        'arabic_number': arabicNumber,
        'chapter_number': chapterNumber,
        'chapter_hadith': chapterHadith,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    });
  }

  Database _required() {
    final database = _database;
    if (database == null) {
      throw StateError('Translation database is not open.');
    }
    return database;
  }

  Future<void> _importIfNeeded(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM translations'),
        ) ??
        0;
    if (count == 6236 * TranslationEdition.all.length) return;
    final parsed = <TranslationEdition, List<TranslationAyah>>{};
    for (final edition in TranslationEdition.all) {
      parsed[edition] = parseTranslationLines(
        await rootBundle.loadString(edition.asset),
      );
    }
    await db.transaction((txn) async {
      await txn.delete('translations');
      await txn.delete('translation_sources');
      for (final edition in TranslationEdition.all) {
        final ayat = parsed[edition]!;
        await txn.insert('translation_sources', {
          'language_code': edition.code,
          'translator': edition.translator,
          'source': edition.source,
          'version': edition.version,
        });
        final batch = txn.batch();
        for (final ayah in ayat) {
          batch.insert('translations', {
            'language_code': edition.code,
            'surah_number': ayah.surah,
            'ayah_number': ayah.ayah,
            'translation_text': ayah.text,
            'footnotes': ayah.footnote,
          });
        }
        await batch.commit(noResult: true);
      }
    });
  }
}
