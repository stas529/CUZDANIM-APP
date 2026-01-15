import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // database_helper.dart içine ekle
  Future<List<Map<String, dynamic>>> getDailyReport(int userId) async {
    final db = await instance.database;
    // Bu sorgu: Günleri gruplar, o gündeki Gelir ve Giderleri toplar.
    return await db.rawQuery(
      '''
    SELECT 
      strftime('%d', date) as gun, 
      SUM(CASE WHEN type = 'Gelir' THEN amount ELSE 0 END) as toplamGelir,
      SUM(CASE WHEN type = 'Gider' THEN amount ELSE 0 END) as toplamGider
    FROM transactions 
    WHERE strftime('%m', date) = strftime('%m', 'now')
     AND userId = ?
    GROUP BY gun
    ORDER BY gun ASC
  ''',
      [userId],
    );
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance.db');
    return await openDatabase(path, version: 2, onCreate: _onCreate);
  } // Kategoriyi silmek için bu metodu DatabaseHelper sınıfının içine ekle

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _onCreate(Database db, int version) async {
    // --- 1. ÖNCE TABLOLARI OLUŞTURUYORUZ ---

    // İşlemler Tablosu
    await db.execute('''
    CREATE TABLE transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL,
      type TEXT,
      category TEXT,
      date TEXT,
      description TEXT,
      isRecurring INTEGER,
      userId INTEGER
    )
  ''');

    // Kategoriler Tablosu
    await db.execute('''
    CREATE TABLE categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      type TEXT,
      userId INTEGER
    )
  ''');

    // Bütçeler Tablosu
    await db.execute('''
    CREATE TABLE budgets(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT,
      budget_limit REAL,
      month TEXT
    )
  ''');

    // Kullanıcı Tablosu
    await db.execute('''
    CREATE TABLE user(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      email TEXT UNIQUE,
      password TEXT
    )
  ''');

    // --- 2. TABLOLAR BİTTİ, ŞİMDİ İÇİNE VERİLERİ ATIYORUZ ---
    // (Artık tablolar hazır olduğu için hata vermez)

    await db.insert('categories', {'name': 'Food', 'type': 'Gider'});
    await db.insert('categories', {'name': 'Bills', 'type': 'Gider'});
    await db.insert('categories', {'name': 'Transport', 'type': 'Gider'});
    await db.insert('categories', {'name': 'Entertainment', 'type': 'Gider'});

    debugPrint("Varsayılan kategoriler başarıyla eklendi! ✅");
  }

  // --- KULLANICI İŞLEMLERİ (YENİ EKLENENLER) ---

  // Yeni Kullanıcı Kaydı
  Future<int> registerUser(String name, String email, String password) async {
    final db = await database;
    return await db.insert('user', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  // Fonksiyona userId parametresi ekledik
  Future<List<Map<String, dynamic>>> getTransactions(int userId) async {
    final db = await database;

    // 'where' ve 'whereArgs' kullanarak filtreleme yapıyoruz
    return await db.query(
      'transactions',
      where: 'userId = ?', // Sadece bu ID'ye sahip olanları seç
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<int> updatePassword(String email, String newPassword) async {
    final db =
        await database; // database getter'ının ismini kontrol et, db de olabilir
    return await db.update(
      'user', // Tablo adın 'user' değilse onu düzelt
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // database_helper.dart içine ekle
  Future<int> resetPassword(String email, String newPassword) async {
    final db = await database;
    return await db.update(
      'user',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // 1. GİRİŞ YAPMA (Sadece bu tek fonksiyon kalacak!)
  Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    final db = await database;

    List<Map<String, dynamic>> results = await db.query(
      'user',
      where: 'LOWER(name) = ?',
      whereArgs: [username.trim().toLowerCase()],
    );

    if (results.isNotEmpty) {
      String dbPass = results.first['password'].toString().trim();
      if (dbPass == password.trim()) {
        return results.first;
      }
    }
    return null;
  }

  // Tüm kategorileri getir
  // EĞER SORUN getCategories FONKSİYONUNDAYSA:
  Future<List<Map<String, dynamic>>> getCategories(int userId) async {
    // <-- Parantez içine bunu ekledik
    final db = await database;
    return await db.query(
      'categories',
      where: 'userId = ?',
      whereArgs: [userId], // <-- Hata veren yer burasıydı, artık tanımlı!
    );
  }

  // Bu iki fonksiyonu DatabaseHelper class'ının içine ekle
  Future<double> getTotalIncome(int userId) async {
    final db = await database;
    // Sorguyu küçük harfe duyarlı (LOWER) ve senin loglardaki 'income' ismine göre güncelledik
    var result = await db.rawQuery(
      "SELECT SUM(amount) FROM transactions WHERE LOWER(type) = 'income' AND userId = ?",
      [userId],
    );

    return (result.first.values.first != null)
        ? double.parse(result.first.values.first.toString())
        : 0.0;
  }

  Future<double> getTotalExpense(int userId) async {
    final db = await database;
    // Sorguyu senin loglardaki 'expense' ismine göre güncelledik
    var result = await db.rawQuery(
      "SELECT SUM(amount) FROM transactions WHERE LOWER(type) = 'expense' AND userId = ?",
      [userId],
    );

    return (result.first.values.first != null)
        ? double.parse(result.first.values.first.toString())
        : 0.0;
  }

  // Yeni kategori ekle
  Future<int> insertCategory(String name, String type, int userId) async {
    // <-- Buraya da ekledik
    final db = await database;
    return await db.insert('categories', {
      'name': name,
      'type': type,
      'userId': userId,
    });
  }

  // 2. ŞİFRE HATIRLATICI FONKSİYONU (Hata aldığın eksik metod)
  Future<String?> getPasswordByEmail(String email) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'user',
      columns: ['password'],
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (results.isNotEmpty) {
      return results.first['password'].toString();
    }
    return null;
  }

  // Kullanıcı bilgilerini güncelleme fonksiyonu
  Future<int> updateUser(
    int id,
    String name,
    String email,
    String password,
  ) async {
    final db = await database;

    // Güncelleme yapmadan önce bu mailin BAŞKASINA ait olup olmadığını kontrol edebiliriz
    // Ama SQLite 'update' komutu zaten 'where id = ?' dediğinde sadece o satıra bakar.

    return await db.update(
      'user',
      {'name': name, 'email': email, 'password': password},
      where: 'id = ?',
      whereArgs: [id], // Bu ID'ye sahip satırı bul ve değiştir
    );
  }

  // database_helper.dart dosyasının içine ekle:
  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user', // Veritabanındaki tablo adın 'users' ise böyle kalsın
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}
