import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:canoto/data/repositories/weighing_ticket_repository.dart';

/// SQLite implementation của WeighingTicketRepository
/// Sử dụng sqflite_common_ffi cho Windows
class WeighingTicketRepositoryImpl implements WeighingTicketRepository {
  // TODO: Inject Database instance
  // final Database _db;
  // WeighingTicketRepositoryImpl(this._db);

  // Singleton for demo
  static WeighingTicketRepositoryImpl? _instance;
  static WeighingTicketRepositoryImpl get instance => 
      _instance ??= WeighingTicketRepositoryImpl._();
  WeighingTicketRepositoryImpl._();

  // In-memory storage for demo (replace with actual SQLite)
  final List<WeighingTicket> _tickets = [];
  int _nextId = 1;

  @override
  Future<List<WeighingTicket>> getAll() async {
    return List.from(_tickets);
  }

  @override
  Future<WeighingTicket?> getById(int id) async {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WeighingTicket?> getByTicketNumber(String ticketNumber) async {
    try {
      return _tickets.firstWhere((t) => t.ticketNumber == ticketNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WeighingTicket>> getByLicensePlate(String licensePlate) async {
    return _tickets.where((t) => t.licensePlate == licensePlate).toList();
  }

  @override
  Future<List<WeighingTicket>> getByDateRange(DateTime from, DateTime to) async {
    return _tickets.where((t) => 
      t.createdAt.isAfter(from) && t.createdAt.isBefore(to)
    ).toList();
  }

  @override
  Future<List<WeighingTicket>> getByStatus(String status) async {
    return _tickets.where((t) => t.status.value == status).toList();
  }

  @override
  Future<int> insert(WeighingTicket ticket) async {
    final newTicket = ticket.copyWith(id: _nextId);
    _tickets.add(newTicket);
    return _nextId++;
  }

  @override
  Future<int> update(WeighingTicket ticket) async {
    final index = _tickets.indexWhere((t) => t.id == ticket.id);
    if (index >= 0) {
      _tickets[index] = ticket.copyWith(updatedAt: DateTime.now());
      return 1;
    }
    return 0;
  }

  @override
  Future<int> delete(int id) async {
    final lengthBefore = _tickets.length;
    _tickets.removeWhere((t) => t.id == id);
    return lengthBefore - _tickets.length;
  }

  @override
  Future<String> generateTicketNumber() async {
    final now = DateTime.now();
    final todayCount = await countToday();
    final sequence = (todayCount + 1).toString().padLeft(4, '0');
    return 'PC${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$sequence';
  }

  @override
  Future<int> countToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _tickets.where((t) => t.createdAt.isAfter(startOfDay)).length;
  }

  @override
  Future<double> totalWeightToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    double total = 0.0;
    for (final t in _tickets.where((t) => t.createdAt.isAfter(startOfDay))) {
      total += t.netWeight ?? 0;
    }
    return total;
  }

  // ============ SYNC METHODS ============

  @override
  Future<List<WeighingTicket>> getUnsynced() async {
    // Query: SELECT * FROM weighing_tickets WHERE is_synced = 0
    return _tickets.where((t) => !t.isSynced).toList();
  }

  @override
  Future<int> countUnsynced() async {
    return _tickets.where((t) => !t.isSynced).length;
  }

  @override
  Future<int> countSynced() async {
    return _tickets.where((t) => t.isSynced).length;
  }

  @override
  Future<void> markAsSynced(List<int> localIds, List<int?>? azureIds) async {
    // UPDATE weighing_tickets SET is_synced = 1, azure_id = ?, synced_at = ? WHERE id IN (?)
    for (var i = 0; i < localIds.length; i++) {
      final localId = localIds[i];
      final azureId = azureIds != null && i < azureIds.length ? azureIds[i] : null;
      await markOneSynced(localId, azureId);
    }
  }

  @override
  Future<void> markOneSynced(int localId, int? azureId) async {
    final index = _tickets.indexWhere((t) => t.id == localId);
    if (index >= 0) {
      _tickets[index] = _tickets[index].copyWith(
        isSynced: true,
        azureId: azureId,
        syncedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<WeighingTicket>> getLast30Days() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _tickets
        .where((t) => t.createdAt.isAfter(thirtyDaysAgo))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ============ DEMO DATA ============
  
  /// Add sample data for testing
  void addSampleData() {
    final now = DateTime.now();
    
    _tickets.addAll([
      WeighingTicket(
        id: _nextId++,
        ticketNumber: 'PC2601070001',
        licensePlate: '51A-12345',
        customerName: 'Bê tông Bảo An',
        productName: 'Cát xây dựng',
        firstWeight: 25000,
        firstWeightTime: now.subtract(const Duration(hours: 2)),
        secondWeight: 10000,
        secondWeightTime: now.subtract(const Duration(hours: 1)),
        netWeight: 15000,
        isSynced: true,
        azureId: 5001,
        syncedAt: now.subtract(const Duration(hours: 1)),
      ),
      WeighingTicket(
        id: _nextId++,
        ticketNumber: 'PC2601070002',
        licensePlate: '30H-67890',
        customerName: 'Công ty ABC',
        productName: 'Đá 1x2',
        firstWeight: 32000,
        firstWeightTime: now.subtract(const Duration(hours: 1)),
        secondWeight: 12000,
        secondWeightTime: now.subtract(const Duration(minutes: 30)),
        netWeight: 20000,
        isSynced: false,
      ),
      WeighingTicket(
        id: _nextId++,
        ticketNumber: 'PC2601070003',
        licensePlate: '51B-11111',
        customerName: 'Công ty XYZ',
        productName: 'Xi măng',
        firstWeight: 28000,
        firstWeightTime: now.subtract(const Duration(minutes: 45)),
        secondWeight: 9000,
        secondWeightTime: now.subtract(const Duration(minutes: 15)),
        netWeight: 19000,
        isSynced: false,
      ),
    ]);
  }
}
