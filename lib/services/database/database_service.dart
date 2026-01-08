import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:canoto/services/logging/logging_service.dart';

/// Service quản lý SQLite Database
class DatabaseService {
  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;
  final LoggingService _logger = LoggingService.instance;

  static const String _databaseName = 'canoto.db';
  static const int _databaseVersion = 1;

  bool get isInitialized => _database != null;

  /// Khởi tạo database
  Future<void> initialize() async {
    if (_database != null) return;

    try {
      _logger.info('Database', 'Initializing SQLite database...');

      // Initialize FFI for Windows/Linux/macOS
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // Get database path
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory('${documentsDir.path}/CanOTo');
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      
      final dbPath = path.join(dbDir.path, _databaseName);
      _logger.info('Database', 'Database path: $dbPath');

      // Open database
      _database = await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _logger.info('Database', 'Database initialized successfully');
    } catch (e) {
      _logger.error('Database', 'Failed to initialize database', error: e);
      rethrow;
    }
  }

  /// Tạo các bảng khi database được tạo mới
  Future<void> _onCreate(Database db, int version) async {
    _logger.info('Database', 'Creating database tables...');

    // Bảng phiếu cân
    await db.execute('''
      CREATE TABLE weighing_tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_number TEXT NOT NULL UNIQUE,
        license_plate TEXT NOT NULL,
        vehicle_type TEXT,
        driver_name TEXT,
        driver_phone TEXT,
        customer_id INTEGER,
        customer_name TEXT,
        product_id INTEGER,
        product_name TEXT,
        first_weight REAL,
        first_weight_time TEXT,
        second_weight REAL,
        second_weight_time TEXT,
        net_weight REAL,
        deduction REAL DEFAULT 0,
        actual_weight REAL,
        unit_price REAL,
        total_amount REAL,
        weighing_type TEXT NOT NULL DEFAULT 'incoming',
        status TEXT NOT NULL DEFAULT 'pending',
        note TEXT,
        first_weight_image TEXT,
        second_weight_image TEXT,
        license_plate_image TEXT,
        scale_id INTEGER,
        operator_id TEXT,
        operator_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        azure_id INTEGER,
        synced_at TEXT
      )
    ''');

    // Index cho tìm kiếm nhanh
    await db.execute('CREATE INDEX idx_ticket_number ON weighing_tickets(ticket_number)');
    await db.execute('CREATE INDEX idx_license_plate ON weighing_tickets(license_plate)');
    await db.execute('CREATE INDEX idx_created_at ON weighing_tickets(created_at)');
    await db.execute('CREATE INDEX idx_is_synced ON weighing_tickets(is_synced)');

    // Bảng khách hàng
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        tax_code TEXT,
        contact_person TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Bảng sản phẩm
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name TEXT NOT NULL,
        category TEXT,
        unit TEXT DEFAULT 'kg',
        unit_price REAL,
        deduction_rate REAL DEFAULT 0,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Bảng xe
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        license_plate TEXT NOT NULL UNIQUE,
        vehicle_type TEXT,
        owner_name TEXT,
        owner_phone TEXT,
        tare_weight REAL,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Bảng cấu hình
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Bảng log hoạt động
    await db.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        table_name TEXT,
        record_id INTEGER,
        old_value TEXT,
        new_value TEXT,
        user_id TEXT,
        user_name TEXT,
        ip_address TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    _logger.info('Database', 'Database tables created successfully');
  }

  /// Upgrade database khi version thay đổi
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.info('Database', 'Upgrading database from v$oldVersion to v$newVersion...');
    
    // Thêm các migration scripts ở đây khi cần upgrade
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE weighing_tickets ADD COLUMN new_column TEXT');
    // }
  }

  /// Lấy database instance
  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Đóng database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.info('Database', 'Database closed');
    }
  }

  /// Xóa toàn bộ database (dùng cho reset/testing)
  Future<void> deleteDatabase() async {
    try {
      await close();
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDir.path, 'CanOTo', _databaseName);
      final dbFile = File(dbPath);
      
      if (await dbFile.exists()) {
        await dbFile.delete();
        _logger.info('Database', 'Database deleted');
      }
    } catch (e) {
      _logger.error('Database', 'Failed to delete database', error: e);
    }
  }

  /// Backup database
  Future<String?> backupDatabase() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDir.path, 'CanOTo', _databaseName);
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        _logger.warning('Database', 'Database file not found for backup');
        return null;
      }

      final backupDir = Directory('${documentsDir.path}/CanOTo/Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = '${backupDir.path}/canoto_backup_$timestamp.db';
      
      await dbFile.copy(backupPath);
      _logger.info('Database', 'Database backed up to: $backupPath');
      
      return backupPath;
    } catch (e) {
      _logger.error('Database', 'Failed to backup database', error: e);
      return null;
    }
  }

  /// Restore database từ backup
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        _logger.error('Database', 'Backup file not found: $backupPath');
        return false;
      }

      await close();

      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDir.path, 'CanOTo', _databaseName);
      
      await backupFile.copy(dbPath);
      
      await initialize();
      _logger.info('Database', 'Database restored from: $backupPath');
      
      return true;
    } catch (e) {
      _logger.error('Database', 'Failed to restore database', error: e);
      return false;
    }
  }

  /// Lấy kích thước database
  Future<int> getDatabaseSize() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDir.path, 'CanOTo', _databaseName);
      final dbFile = File(dbPath);
      
      if (await dbFile.exists()) {
        return await dbFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Thực hiện VACUUM để tối ưu database
  Future<void> vacuum() async {
    try {
      await database.execute('VACUUM');
      _logger.info('Database', 'Database vacuumed successfully');
    } catch (e) {
      _logger.error('Database', 'Failed to vacuum database', error: e);
    }
  }
}
