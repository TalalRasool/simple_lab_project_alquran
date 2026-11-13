import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Offline Kutub al-Sittah text. Quran data stays in its own database.
class HadithDatabase {
  HadithDatabase._();

  static final instance = HadithDatabase._();
  static const asset = 'assets/hadith/kutub.db';

  static DatabaseFactory? debugFactory;
  static String? debugPath;

  Database? _database;
  Future<void>? _opening;

  Future<void> ensureReady() {
    return _opening ??= _open();
  }

  Future<List<HadithCollectionStats>> collections() async {
    final database = await _ready();
    final rows = await database.query('collections', orderBy: 'name_en');
    return [for (final row in rows) HadithCollectionStats.fromRow(row)];
  }

  Future<List<HadithChapter>> chapters(String collectionId) async {
    final database = await _ready();
    final rows = await database.query(
      'chapters',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'number',
    );
    return [for (final row in rows) HadithChapter.fromRow(row)];
  }

  Future<List<HadithEntry>> chapterPage({
    required String collectionId,
    required int chapterNumber,
    required int limit,
    required int offset,
  }) async {
    final database = await _ready();
    final rows = await database.rawQuery(
      '''
      SELECT id, collection_id, hadith_number, arabic_number, chapter_number,
             chapter_hadith, substr(arabic_text, 1, 180) AS arabic_text
      FROM hadiths
      WHERE collection_id = ? AND chapter_number = ?
      ORDER BY hadith_number, id
      LIMIT ? OFFSET ?
      ''',
      [collectionId, chapterNumber, limit, offset],
    );
    return _hydrate(database, rows, preview: true);
  }

  /// [chapterNumber] limits the lookup to one chapter.
  ///
  /// A whole number inside a chapter matches `chapter_hadith` only.
  /// The same number on the collection matches `hadith_number`, not the
  /// database id and not every chapter's local number.
  Future<List<HadithEntry>> search({
    required String collectionId,
    required String query,
    int? chapterNumber,
    required int limit,
    required int offset,
  }) async {
    final database = await _ready();
    final trimmed = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return const [];
    final inChapter = chapterNumber != null;
    final wholeNumber = RegExp(r'^\d+$').hasMatch(trimmed);
    final arabicNumber = RegExp(r'^\d+\.\d+$').hasMatch(trimmed);
    final chapterSql = inChapter ? 'AND h.chapter_number = ?' : '';
    final args = <Object?>[collectionId];
    if (inChapter) args.add(chapterNumber);

    late final String where;
    if (wholeNumber) {
      final number = int.parse(trimmed);
      where = inChapter
          ? 'h.chapter_hadith = ?'
          : '(h.hadith_number = ? OR h.arabic_number = ?)';
      args.add(number);
      if (!inChapter) args.add(trimmed);
    } else if (arabicNumber) {
      where = 'h.arabic_number = ?';
      args.add(trimmed);
    } else {
      final like = '%${_escape(_foldArabic(trimmed))}%';
      final arabic = _foldSql('h.arabic_text');
      final englishName = _foldSql('c.name_en');
      final arabicName = _foldSql('c.name_ar');
      final urduName = _foldSql('c.name_ur');
      final translation = _foldSql('t.text');
      where =
          '''
        $arabic LIKE ? ESCAPE '\\'
        OR $englishName LIKE ? ESCAPE '\\'
        OR $arabicName LIKE ? ESCAPE '\\'
        OR $urduName LIKE ? ESCAPE '\\'
        OR EXISTS (
          SELECT 1 FROM translations t
          WHERE t.hadith_id = h.id AND $translation LIKE ? ESCAPE '\\'
        )
      ''';
      args.addAll([like, like, like, like, like]);
    }
    args.addAll([limit, offset]);
    final rows = await database.rawQuery('''
      SELECT h.id, h.collection_id, h.hadith_number, h.arabic_number,
             h.chapter_number, h.chapter_hadith,
             substr(h.arabic_text, 1, 180) AS arabic_text
      FROM hadiths h
      LEFT JOIN chapters c
        ON c.collection_id = h.collection_id AND c.number = h.chapter_number
      WHERE h.collection_id = ?
        $chapterSql
        AND ($where)
      ORDER BY h.chapter_number, h.chapter_hadith, h.id
      LIMIT ? OFFSET ?
      ''', args);
    return _hydrate(database, rows, preview: true);
  }

  Future<HadithEntry?> detail({
    required String collectionId,
    required int hadithNumber,
    required String arabicNumber,
    required int chapterNumber,
    required int chapterHadith,
  }) async {
    final database = await _ready();
    final rows = await database.query(
      'hadiths',
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
    if (rows.isEmpty) return null;
    final entries = await _hydrate(database, rows, preview: false);
    final chapter = await database.query(
      'chapters',
      where: 'collection_id = ? AND number = ?',
      whereArgs: [collectionId, chapterNumber],
      limit: 1,
    );
    final entry = entries.first;
    if (chapter.isEmpty) return entry;
    return entry.copyWith(chapter: HadithChapter.fromRow(chapter.first));
  }

  Future<Database> _ready() async {
    await ensureReady();
    final database = _database;
    if (database == null) {
      throw StateError('Hadith database is not open.');
    }
    return database;
  }

  Future<void> _open() async {
    try {
      final factory = debugFactory;
      if (factory != null) {
        _database = await factory.openDatabase(
          debugPath ?? ':memory:',
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
        );
        return;
      }
      final path = p.join(await getDatabasesPath(), 'kutub_sittah.db');
      final file = File(path);
      if (!file.existsSync()) {
        final bytes = await rootBundle.load(asset);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true,
        );
      }
      _database = await openDatabase(path);
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_hadith_in_chapter '
        'ON hadiths(collection_id, chapter_number, chapter_hadith)',
      );
      await _database!.execute(
        'CREATE INDEX IF NOT EXISTS idx_hadith_arabic '
        'ON hadiths(collection_id, arabic_number)',
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<List<HadithEntry>> _hydrate(
    Database database,
    List<Map<String, Object?>> rows, {
    required bool preview,
  }) async {
    if (rows.isEmpty) return const [];
    final ids = [for (final row in rows) row['id'] as int];
    final marks = List.filled(ids.length, '?').join(', ');
    final translationColumn = preview ? 'substr(text, 1, 180)' : 'text';
    final translationRows = await database.rawQuery(
      'SELECT hadith_id, language, $translationColumn AS text FROM translations WHERE hadith_id IN ($marks)',
      ids,
    );
    final gradeRows = await database.rawQuery(
      'SELECT hadith_id, scholar, grade FROM grades WHERE hadith_id IN ($marks) ORDER BY rowid',
      ids,
    );
    final english = <int, String>{};
    final urdu = <int, String>{};
    for (final row in translationRows) {
      final id = row['hadith_id'] as int;
      final text = row['text'] as String;
      if (row['language'] == 'ur') {
        urdu[id] = text;
      } else if (row['language'] == 'en') {
        english[id] = text;
      }
    }
    final grades = <int, List<HadithGrade>>{};
    for (final row in gradeRows) {
      final id = row['hadith_id'] as int;
      (grades[id] ??= []).add(
        HadithGrade(
          scholar: row['scholar'] as String,
          grade: row['grade'] as String,
        ),
      );
    }
    return [
      for (final row in rows)
        HadithEntry(
          id: row['id'] as int,
          collectionId: row['collection_id'] as String,
          hadithNumber: row['hadith_number'] as int,
          arabicNumber: row['arabic_number'] as String,
          chapterNumber: row['chapter_number'] as int,
          chapterHadith: row['chapter_hadith'] as int,
          arabic: row['arabic_text'] as String,
          english: english[row['id'] as int],
          urdu: urdu[row['id'] as int],
          grades: grades[row['id'] as int] ?? const [],
        ),
    ];
  }

  String _escape(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }
}

String _foldArabic(String value) {
  var text = value;
  for (final mark in _searchMarks) {
    text = text.replaceAll(mark, '');
  }
  return text
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
}

String _foldSql(String column) {
  var sql = column;
  for (final mark in _searchMarks) {
    sql = "REPLACE($sql, '$mark', '')";
  }
  const letters = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ٱ': 'ا',
    'ة': 'ه',
    'ى': 'ي',
    'ؤ': 'و',
    'ئ': 'ي',
  };
  for (final entry in letters.entries) {
    sql = "REPLACE($sql, '${entry.key}', '${entry.value}')";
  }
  return sql;
}

const _searchMarks = [
  '\u0640',
  '\u064B',
  '\u064C',
  '\u064D',
  '\u064E',
  '\u064F',
  '\u0650',
  '\u0651',
  '\u0652',
  '\u0653',
  '\u0654',
  '\u0655',
  '\u0670',
];

class HadithCollectionStats {
  const HadithCollectionStats({
    required this.id,
    required this.arabicCount,
    required this.urduCount,
    required this.englishCount,
    required this.gradeCount,
  });

  final String id;
  final int arabicCount;
  final int urduCount;
  final int englishCount;
  final int gradeCount;

  factory HadithCollectionStats.fromRow(Map<String, Object?> row) {
    return HadithCollectionStats(
      id: row['id'] as String,
      arabicCount: row['arabic_count'] as int,
      urduCount: row['urdu_count'] as int,
      englishCount: row['english_count'] as int,
      gradeCount: row['grade_count'] as int,
    );
  }
}

class HadithChapter {
  const HadithChapter({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.nameUr,
    required this.count,
  });

  final int number;
  final String nameAr;
  final String nameEn;
  final String nameUr;
  final int count;

  String get displayName {
    if (nameEn.trim().isNotEmpty) return nameEn.trim();
    if (_hasArabic(nameAr)) return nameAr.trim();
    if (_hasArabic(nameUr)) return nameUr.trim();
    return 'Chapter $number';
  }

  factory HadithChapter.fromRow(Map<String, Object?> row) {
    return HadithChapter(
      number: row['number'] as int,
      nameAr: row['name_ar'] as String? ?? '',
      nameEn: row['name_en'] as String? ?? '',
      nameUr: row['name_ur'] as String? ?? '',
      count: row['hadith_count'] as int? ?? 0,
    );
  }
}

class HadithGrade {
  const HadithGrade({required this.scholar, required this.grade});

  final String scholar;
  final String grade;
}

class HadithEntry {
  const HadithEntry({
    required this.id,
    required this.collectionId,
    required this.hadithNumber,
    required this.arabicNumber,
    required this.chapterNumber,
    required this.chapterHadith,
    required this.arabic,
    required this.grades,
    this.english,
    this.urdu,
    this.chapter,
  });

  final int id;
  final String collectionId;
  final int hadithNumber;
  final String arabicNumber;
  final int chapterNumber;
  final int chapterHadith;
  final String arabic;
  final String? english;
  final String? urdu;
  final List<HadithGrade> grades;
  final HadithChapter? chapter;

  String get referenceLabel {
    final arabic = arabicNumber.isEmpty || arabicNumber == '$hadithNumber'
        ? ''
        : ' · Arabic no. $arabicNumber';
    return 'Hadith $hadithNumber$arabic · Chapter $chapterNumber, narration $chapterHadith';
  }

  HadithEntry copyWith({HadithChapter? chapter}) {
    return HadithEntry(
      id: id,
      collectionId: collectionId,
      hadithNumber: hadithNumber,
      arabicNumber: arabicNumber,
      chapterNumber: chapterNumber,
      chapterHadith: chapterHadith,
      arabic: arabic,
      english: english,
      urdu: urdu,
      grades: grades,
      chapter: chapter ?? this.chapter,
    );
  }
}

bool _hasArabic(String value) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
}
