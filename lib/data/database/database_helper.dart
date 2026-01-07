/// Database helper for SQLite
class DatabaseHelper {
  static const String databaseName = 'canoto.db';
  static const int databaseVersion = 2; // Updated version for sync fields

  // Singleton pattern
  static DatabaseHelper? _instance;
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();
  DatabaseHelper._();

  // Database instance
  // Database? _database;

  // Future<Database> get database async {
  //   _database ??= await _initDatabase();
  //   return _database!;
  // }

  // Future<Database> _initDatabase() async {
  //   final databasePath = await getDatabasesPath();
  //   final path = join(databasePath, databaseName);
  //   return await openDatabase(
  //     path,
  //     version: databaseVersion,
  //     onCreate: _onCreate,
  //     onUpgrade: _onUpgrade,
  //   );
  // }

  // Table creation SQL
  static const String createWeighingTicketsTable = '''
    CREATE TABLE IF NOT EXISTS weighing_tickets (
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
      deduction REAL,
      actual_weight REAL,
      unit_price REAL,
      total_amount REAL,
      weighing_type TEXT DEFAULT 'incoming',
      status TEXT DEFAULT 'pending',
      note TEXT,
      first_weight_image TEXT,
      second_weight_image TEXT,
      license_plate_image TEXT,
      scale_id INTEGER,
      operator_id TEXT,
      operator_name TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0,
      azure_id INTEGER,
      synced_at TEXT
    )
  ''';

  // Migration: Add sync columns to existing table
  static const String addSyncColumnsToWeighingTickets = '''
    ALTER TABLE weighing_tickets ADD COLUMN is_synced INTEGER DEFAULT 0;
    ALTER TABLE weighing_tickets ADD COLUMN azure_id INTEGER;
    ALTER TABLE weighing_tickets ADD COLUMN synced_at TEXT;
  ''';

  static const String createVehiclesTable = '''
    CREATE TABLE IF NOT EXISTS vehicles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      license_plate TEXT NOT NULL UNIQUE,
      vehicle_type TEXT,
      brand TEXT,
      model TEXT,
      color TEXT,
      tare_weight REAL,
      customer_id INTEGER,
      customer_name TEXT,
      driver_name TEXT,
      driver_phone TEXT,
      note TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String createCustomersTable = '''
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      contact_person TEXT,
      phone TEXT,
      email TEXT,
      address TEXT,
      tax_code TEXT,
      bank_account TEXT,
      bank_name TEXT,
      note TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String createProductsTable = '''
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      category TEXT,
      unit TEXT,
      unit_price REAL,
      description TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String createDeviceConfigsTable = '''
    CREATE TABLE IF NOT EXISTS device_configs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      connection_type TEXT,
      ip_address TEXT,
      port INTEGER,
      com_port TEXT,
      baud_rate INTEGER,
      username TEXT,
      password TEXT,
      extra_config TEXT,
      is_enabled INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String createAlertsTable = '''
    CREATE TABLE IF NOT EXISTS alerts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      type TEXT NOT NULL,
      severity TEXT DEFAULT 'info',
      source TEXT,
      is_read INTEGER DEFAULT 0,
      is_resolved INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      resolved_at TEXT
    )
  ''';

  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT,
      full_name TEXT,
      email TEXT,
      phone TEXT,
      role TEXT,
      permissions TEXT,
      is_active INTEGER DEFAULT 1,
      last_login TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  // void _onCreate(Database db, int version) async {
  //   await db.execute(createWeighingTicketsTable);
  //   await db.execute(createVehiclesTable);
  //   await db.execute(createCustomersTable);
  //   await db.execute(createProductsTable);
  //   await db.execute(createDeviceConfigsTable);
  //   await db.execute(createAlertsTable);
  //   await db.execute(createUsersTable);
  //   
  //   // Create indexes
  //   await db.execute('CREATE INDEX idx_tickets_license ON weighing_tickets(license_plate)');
  //   await db.execute('CREATE INDEX idx_tickets_date ON weighing_tickets(created_at)');
  //   await db.execute('CREATE INDEX idx_vehicles_license ON vehicles(license_plate)');
  //   await db.execute('CREATE INDEX idx_customers_code ON customers(code)');
  // }
  // 
  // void _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   // Handle database migrations
  // }
}
